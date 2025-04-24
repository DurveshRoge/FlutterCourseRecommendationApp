import os
import json
from datetime import timedelta
import pandas as pd
import numpy as np
import neattext.functions as nfx
from sklearn.feature_extraction.text import TfidfVectorizer, CountVectorizer
from sklearn.metrics.pairwise import cosine_similarity, linear_kernel
from bson.json_util import dumps
from functools import wraps

# Flask and extensions
from flask import Flask, request, render_template, jsonify, session
from flask_pymongo import PyMongo
from flask_bcrypt import Bcrypt
from flask_cors import CORS

# Local imports
from dashboard import getvaluecounts, getlevelcount, getsubjectsperlevel, yearwiseprofit
from integrate_recommendations import add_recommendation_routes

app = Flask(__name__)
CORS(app, resources={
    r"/*": {
        "origins": ["http://localhost:*"],
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization", "X-Requested-With"]
    }
})

# MongoDB Configuration
# Use environment variable or fallback to default
MONGO_URI = os.environ.get("MONGO_URI")
app.config["MONGO_URI"] = MONGO_URI

# Session Configuration
app.secret_key = os.environ.get("SECRET_KEY", os.urandom(24))
app.permanent_session_lifetime = timedelta(days=7)
app.config['SESSION_TYPE'] = os.environ.get("SESSION_TYPE", "filesystem")
app.config['SESSION_COOKIE_SECURE'] = os.environ.get("SESSION_COOKIE_SECURE", "False").lower() == "true"
app.config['SESSION_COOKIE_HTTPONLY'] = os.environ.get("SESSION_COOKIE_HTTPONLY", "True").lower() == "true"
app.config['SESSION_COOKIE_SAMESITE'] = os.environ.get("SESSION_COOKIE_SAMESITE", "Lax")
mongo = PyMongo(app)
bcrypt = Bcrypt(app)

# Add the recommendation routes to your app
add_recommendation_routes(app, mongo)

def getcosinemat(df):

    countvect = CountVectorizer()
    cvmat = countvect.fit_transform(df['Clean_title'])
    return cvmat

# getting the title which doesn't contain stopwords and all which we removed with the help of nfx


def getcleantitle(df):

    df['Clean_title'] = df['course_title'].apply(nfx.remove_stopwords)

    df['Clean_title'] = df['Clean_title'].apply(nfx.remove_special_characters)

    return df


def cosinesimmat(cv_mat):

    return cosine_similarity(cv_mat)


def readdata():

    df = pd.read_csv('UdemyCleanedTitle.csv')
    return df

# this is the main recommendation logic for a particular title which is choosen


def recommend_course(df, title, cosine_mat, numrec):

    course_index = pd.Series(
        df.index, index=df['course_title']).drop_duplicates()

    index = course_index[title]

    scores = list(enumerate(cosine_mat[index]))

    sorted_scores = sorted(scores, key=lambda x: x[1], reverse=True)

    selected_course_index = [i[0] for i in sorted_scores[1:]]

    selected_course_score = [i[1] for i in sorted_scores[1:]]

    rec_df = df.iloc[selected_course_index]

    rec_df['Similarity_Score'] = selected_course_score

    final_recommended_courses = rec_df[[
        'course_title', 'Similarity_Score', 'url', 'price', 'num_subscribers', 'level', 'subject']]

    return final_recommended_courses.head(numrec)

# this will be called when a part of the title is used,not the complete title!


def searchterm(term, df):
    # Convert search term to lowercase
    term = term.lower()
    
    # Split search term into words
    search_words = term.split()
    
    # If no search words, return empty DataFrame
    if not search_words:
        return pd.DataFrame()
    
    # Create masks for different search criteria
    title_masks = []
    subject_masks = []
    
    for word in search_words:
        # Search in title (higher priority)
        title_mask = df['course_title'].str.lower().str.contains(word, na=False)
        title_masks.append(title_mask)
        
        # Search in subject (lower priority)
        subject_mask = df['subject'].str.lower().str.contains(word, na=False)
        subject_masks.append(subject_mask)
    
    # Combine masks
    title_match = title_masks[0]
    subject_match = subject_masks[0]
    
    for mask in title_masks[1:]:
        title_match = title_match | mask
    
    for mask in subject_masks[1:]:
        subject_match = subject_match | mask
    
    # Get courses that match in title or subject
    result_df = df[title_match | subject_match].copy()
    
    # Add a relevance score
    result_df['relevance_score'] = 0
    
    # Title matches get higher score
    result_df.loc[title_match, 'relevance_score'] += 2
    
    # Subject matches get lower score
    result_df.loc[subject_match, 'relevance_score'] += 1
    
    # Sort by relevance score first, then by number of subscribers
    result_df = result_df.sort_values(
        by=['relevance_score', 'num_subscribers'], 
        ascending=[False, False]
    ).head(10)
    
    # Drop the relevance score column
    result_df = result_df.drop('relevance_score', axis=1)
    
    return result_df


# extract features from the recommended dataframe

def extractfeatures(recdf):

    course_url = list(recdf['url'])
    course_title = list(recdf['course_title'])
    course_price = list(recdf['price'])

    return course_url, course_title, course_price


@app.route('/', methods=['GET', 'POST'])
def hello_world():
    if request.method == 'POST':
        try:
            # Get the course title from the request
            data = request.get_json()
            if data and 'course' in data:
                titlename = data['course']
            else:
                # For form submissions
                titlename = request.form.get('course')
                
            if not titlename:
                return jsonify({"error": "No course title provided"}), 400
                
            df = readdata()
            df = getcleantitle(df)
            
            # First try partial search
            resultdf = searchterm(titlename, df)
            
            if not resultdf.empty:
                # Ensure all required fields exist
                if 'image_url' not in resultdf.columns:
                    resultdf['image_url'] = None  # Set to None instead of generating paths
                
                # Ensure course_id is available
                if 'course_id' not in resultdf.columns and 'id' in resultdf.columns:
                    resultdf['course_id'] = resultdf['id']
                elif 'course_id' not in resultdf.columns:
                    # Create a course_id if none exists
                    resultdf['course_id'] = resultdf.index.astype(str)
                
                # Convert search results to a list of dictionaries
                search_results = resultdf.to_dict(orient='records')
                
                response_data = {
                    "success": True,
                    "query": titlename,
                    "search_results": search_results
                }
            else:
                # If no partial matches, try content-based recommendations
                cvmat = getcosinemat(df)
                cosine_mat = cosinesimmat(cvmat)
                num_rec = 10
                
                try:
                    recdf = recommend_course(df, titlename, cosine_mat, num_rec)
                    
                    # Ensure all required fields exist
                    if 'image_url' not in recdf.columns:
                        recdf['image_url'] = None  # Set to None instead of generating paths
                    
                    # Ensure course_id is available
                    if 'course_id' not in recdf.columns and 'id' in recdf.columns:
                        recdf['course_id'] = recdf['id']
                    elif 'course_id' not in recdf.columns:
                        # Create a course_id if none exists
                        recdf['course_id'] = recdf.index.astype(str)
                    
                    recommendations = recdf.to_dict(orient='records')
                    
                    if recommendations:
                        response_data = {
                            "success": True,
                            "query": titlename,
                            "recommendations": recommendations
                        }
                    else:
                        # If no results, return top trending courses
                        trending_df = df.sort_values(by='num_subscribers', ascending=False).head(10)
                        
                        # Ensure all required fields exist
                        if 'image_url' not in trending_df.columns:
                            trending_df['image_url'] = None  # Set to None instead of generating paths
                        
                        # Ensure course_id is available
                        if 'course_id' not in trending_df.columns and 'id' in trending_df.columns:
                            trending_df['course_id'] = trending_df['id']
                        elif 'course_id' not in trending_df.columns:
                            # Create a course_id if none exists
                            trending_df['course_id'] = trending_df.index.astype(str)
                        
                        trending_results = trending_df.to_dict(orient='records')
                        
                        response_data = {
                            "success": True,
                            "query": titlename,
                            "message": "No exact matches found, showing trending courses",
                            "recommendations": trending_results
                        }
                except Exception as e:
                    print(f"Error in content-based recommendations: {str(e)}")
                    # If no results, return top trending courses
                    trending_df = df.sort_values(by='num_subscribers', ascending=False).head(10)
                    
                    # Ensure all required fields exist
                    if 'image_url' not in trending_df.columns:
                        trending_df['image_url'] = None  # Set to None instead of generating paths
                    
                    # Ensure course_id is available
                    if 'course_id' not in trending_df.columns and 'id' in trending_df.columns:
                        trending_df['course_id'] = trending_df['id']
                    elif 'course_id' not in trending_df.columns:
                        # Create a course_id if none exists
                        trending_df['course_id'] = trending_df.index.astype(str)
                    
                    trending_results = trending_df.to_dict(orient='records')
                    
                    response_data = {
                        "success": True,
                        "query": titlename,
                        "message": "No exact matches found, showing trending courses",
                        "recommendations": trending_results
                    }
            
            return jsonify(response_data)
                    
        except Exception as e:
            print(f"Search error: {str(e)}")
            return jsonify({
                "success": False,
                "error": str(e)
            }), 500
            
    # For GET requests, return a simple message
    return jsonify({
        "message": "Welcome to the Udemy Course Recommendation API",
        "endpoints": {
            "POST /": "Get course recommendations by providing a course title",
            "GET /dashboard": "Get dashboard analytics data"
        }
    })


# Add admin authentication middleware
def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        try:
            # Get user email from session or request
            email = request.args.get('email') or request.json.get('email')
            if not email:
                return jsonify({
                    'success': False,
                    'message': 'Authentication required'
                }), 401

            # Find user in database
            user = mongo.db.users.find_one({'email': email})
            if not user or not user.get('is_admin', False):
                return jsonify({
                    'success': False,
                    'message': 'Admin access required'
                }), 403

            return f(*args, **kwargs)
        except Exception as e:
            print(f"Admin authentication error: {e}")
            return jsonify({
                'success': False,
                'message': 'Authentication failed'
            }), 401
    return decorated_function

@app.route('/dashboard', methods=['GET'])
@admin_required
def get_dashboard_data():
    try:
        # Get user email from query parameters
        email = request.args.get('email')
        if not email:
            return jsonify({
                'success': False,
                'message': 'Email is required'
            }), 400

        # Read the data first
        df = readdata()

        # Get dashboard data
        yearly_metrics = yearwiseprofit(df)
        
        # Format yearly metrics as a map
        formatted_yearly_metrics = {
            'profit': yearly_metrics[0],
            'subscribers': yearly_metrics[1],
            'monthly_profit': yearly_metrics[2],
            'monthly_subscribers': yearly_metrics[3]
        }

        dashboard_data = {
            'subject_distribution': getvaluecounts(df),
            'level_distribution': getlevelcount(df),
            'yearly_metrics': formatted_yearly_metrics,
            'monthly_metrics': getsubjectsperlevel(df)
        }

        return jsonify({
            'success': True,
            'data': dashboard_data
        })
    except Exception as e:
        print(f"Error getting dashboard data: {e}")
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500


# User registration endpoint
@app.route('/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        
        # Check if required fields are provided
        if not data or not data.get('email') or not data.get('password') or not data.get('name'):
            return jsonify({
                "success": False,
                "message": "Missing required fields"
            }), 400
            
        # Check if user already exists
        existing_user = mongo.db.users.find_one({"email": data['email']})
        if existing_user:
            return jsonify({
                "success": False,
                "message": "User already exists"
            }), 409
            
        # Hash the password
        hashed_password = bcrypt.generate_password_hash(data['password']).decode('utf-8')
        
        # Create new user
        new_user = {
            "name": data['name'],
            "email": data['email'],
            "password": hashed_password,
            "favorites": [],  # For storing favorite courses
            "preferred_topics": [],  # For storing preferred topics
            "skill_level": "",  # For storing skill level
            "course_type": "",  # For storing course type preference
            "preferred_duration": "",  # For storing preferred duration
            "popularity_importance": ""  # For storing popularity importance
        }
        
        # Insert user into database
        mongo.db.users.insert_one(new_user)
        
        # Remove password before returning user data
        new_user.pop('password', None)
        
        return jsonify({
            "success": True,
            "message": "User registered successfully",
            "user": json.loads(dumps(new_user))
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

# User login endpoint
@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        print(f"Login attempt with data: {data}")
        
        # Check if required fields are provided
        if not data or not data.get('email') or not data.get('password'):
            print("Missing email or password in request")
            return jsonify({
                "success": False,
                "message": "Missing email or password"
            }), 400
            
        # Find user by email
        user = mongo.db.users.find_one({"email": data['email']})
        print(f"User found: {user is not None}")
        
        # Check if user exists and password is correct
        if user and bcrypt.check_password_hash(user['password'], data['password']):
            # Create session
            session.permanent = True
            session['user_id'] = str(user['_id'])
            print(f"Login successful for user: {data['email']}")
            
            # Remove password before returning user data
            user_data = json.loads(dumps(user))
            user_data.pop('password', None)
            
            return jsonify({
                "success": True,
                "message": "Login successful",
                "user": user_data
            })
        else:
            if not user:
                print(f"User not found with email: {data['email']}")
                return jsonify({
                    "success": False,
                    "message": "Invalid email or password"
                }), 401
            else:
                print(f"Invalid password for user: {data['email']}")
                return jsonify({
                    "success": False,
                    "message": "Invalid email or password"
                }), 401
            
    except Exception as e:
        print(f"Login error: {str(e)}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

# Get current user endpoint
@app.route('/user', methods=['GET'])
def get_user():
    try:
        # Check if user is logged in
        if 'user_id' not in session:
            return jsonify({
                "success": False,
                "message": "Not logged in"
            }), 401
            
        # Find user by ID
        user = mongo.db.users.find_one({"_id": session['user_id']})
        
        if user:
            # Remove password before returning user data
            user_data = json.loads(dumps(user))
            user_data.pop('password', None)
            
            return jsonify({
                "success": True,
                "user": user_data
            })
        else:
            return jsonify({
                "success": False,
                "message": "User not found"
            }), 404
            
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

# Logout endpoint
@app.route('/logout', methods=['POST'])
def logout():
    try:
        # Clear session
        session.clear()
        
        return jsonify({
            "success": True,
            "message": "Logged out successfully"
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

# Save user preferences endpoint
@app.route('/user/preferences', methods=['GET', 'POST'])
def user_preferences():
    try:
        # Get valid topics from dataset
        courses_df = pd.read_csv('UdemyCleanedTitle.csv')
        valid_topics = courses_df['subject'].unique().tolist()
        print(f"Valid topics from dataset: {valid_topics}")
        
        if request.method == 'POST':
            # This handles saving preferences (existing code)
            data = request.get_json()
            
            # Check for required fields
            if not data or not data.get('email'):
                return jsonify({
                    "success": False,
                    "message": "Email is required"
                }), 400
                
            # Get all preference fields
            email = data.get('email')
            topics = data.get('topics', [])
            
            # Validate topics against dataset
            invalid_topics = [topic for topic in topics if topic not in valid_topics]
            if invalid_topics:
                print(f"Warning: Invalid topics detected: {invalid_topics}")
                # Filter out invalid topics
                topics = [topic for topic in topics if topic in valid_topics]
                print(f"Filtered topics: {topics}")
            
            level = data.get('level', 'All Levels')
            course_type = data.get('type', 'All')
            duration = data.get('duration', 'Any')
            popularity = data.get('popularity', 'Medium')
            
            # Debug
            print(f"Saving preferences for user: {email}")
            print(f"Topics: {topics}")
            print(f"Level: {level}")
            print(f"Type: {course_type}")
            print(f"Duration: {duration}")
            print(f"Popularity: {popularity}")
            
            # Find the user by email
            user = mongo.db.users.find_one({"email": email})
            if not user:
                return jsonify({
                    "success": False,
                    "message": "User not found"
                }), 404
                
            # Update user preferences
            mongo.db.users.update_one(
                {"email": email},
                {"$set": {
                    "preferred_topics": topics,
                    "skill_level": level,
                    "course_type": course_type,
                    "preferred_duration": duration,
                    "popularity_importance": popularity
                }}
            )
            
            return jsonify({
                "success": True,
                "message": "Preferences updated successfully",
                "valid_topics": valid_topics
            })
        
        else:  # GET request to retrieve preferences
            # Get user email from query parameters
            email = request.args.get('email')
            if not email:
                return jsonify({
                    "success": False,
                    "message": "Email is required"
                }), 400
            
            # Find the user by email
            user = mongo.db.users.find_one({"email": email})
            if not user:
                return jsonify({
                    "success": False,
                    "message": "User not found"
                }), 404
            
            # Extract user preferences
            preferences = {
                "topics": user.get("preferred_topics", []),
                "level": user.get("skill_level", "All Levels"),
                "course_type": user.get("course_type", "All"),
                "duration": user.get("preferred_duration", "Any"),
                "popularity": user.get("popularity_importance", "Medium")
            }
            
            print(f"Retrieved preferences for {email}: {preferences}")
            
            return jsonify({
                "success": True,
                "preferences": preferences,
                "valid_topics": valid_topics
            })
    
    except Exception as e:
        import traceback
        print(f"Error in user preferences: {str(e)}")
        print(traceback.format_exc())
        return jsonify({
            "success": False,
            "message": str(e)
        }), 500

# Test MongoDB connection
@app.route('/test-db', methods=['GET'])
def test_db_connection():
    try:
        # Check if we can list collections
        collections = mongo.db.list_collection_names()
        
        # Get database name
        db_name = mongo.db.name
        
        # Get server info
        server_info = mongo.cx.server_info()
        
        return jsonify({
            "success": True,
            "message": "MongoDB connection successful",
            "database_name": db_name,
            "collections": collections,
            "server_version": server_info.get("version", "Unknown")
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "message": "MongoDB connection failed",
            "error": str(e)
        }), 500

# Create test user for development
@app.route('/create-test-user', methods=['GET'])
def create_test_user():
    if not app.debug:
        return jsonify({
            "success": False,
            "message": "This endpoint is only available in debug mode"
        }), 403
        
    try:
        # Check if test user already exists
        test_email = 'test@example.com'
        existing_user = mongo.db.users.find_one({"email": test_email})
        
        if existing_user:
            return jsonify({
                "success": True,
                "message": "Test user already exists",
                "user": {
                    "email": test_email,
                    "password": "password123"
                }
            })
            
        # Create test user
        hashed_password = bcrypt.generate_password_hash("password123").decode('utf-8')
        
        new_user = {
            "name": "Test User",
            "email": test_email,
            "password": hashed_password,
            "favorites": [],
            "preferred_topics": ["Web Development", "Data Science"],
            "skill_level": "Beginner",
            "course_type": "No preference",
            "preferred_duration": "No preference",
            "popularity_importance": "Somewhat important"
        }
        
        mongo.db.users.insert_one(new_user)
        
        return jsonify({
            "success": True,
            "message": "Test user created successfully",
            "user": {
                "email": test_email,
                "password": "password123"
            }
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "message": "Failed to create test user",
            "error": str(e)
        }), 500

# Add API routes for handling user favorites

@app.route('/user/favorites', methods=['GET'])
def get_user_favorites():
    """Get user's favorite courses."""
    try:
        # Get user email from query parameters
        email = request.args.get('email')
        if not email:
            print("No email provided in request")
            return jsonify({
                'success': False,
                'message': 'Email is required'
            }), 400
        
        print(f"Getting favorites for user: {email}")
        
        # Find the user by email
        users_collection = mongo.db.users
        user = users_collection.find_one({'email': email})
        
        if not user:
            print(f"User not found: {email}")
            return jsonify({
                'success': False,
                'message': 'User not found'
            }), 404
            
        favorite_course_ids = user.get('favorites', [])
        # Convert all to strings for consistency
        favorite_course_ids = [str(fav) for fav in favorite_course_ids]
        
        print(f"User favorite course IDs: {favorite_course_ids}")
        
        if not favorite_course_ids:
            print("No favorites found for user")
            return jsonify({
                'success': True,
                'courses': []
            })
            
        # Get course details for favorites
        df = readdata()
        
        # Ensure we have the course_id column and convert to string
        df['course_id'] = df['course_id'].astype(str)
        
        # Check if any favorites match course IDs in the dataframe
        matching_ids = set(favorite_course_ids).intersection(set(df['course_id'].values))
        print(f"Matching course IDs found in dataset: {matching_ids}")
        
        # Filter dataframe to only include matching courses
        favorite_courses = df[df['course_id'].isin(favorite_course_ids)].to_dict(orient='records')
        
        print(f"Found {len(favorite_courses)} favorite courses in the dataset")
        
        # Mark all returned courses as favorites
        for course in favorite_courses:
            course['is_favorite'] = True
            
        return jsonify({
            'success': True,
            'courses': favorite_courses
        })
        
    except Exception as e:
        print(f"Error getting user favorites: {e}")
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/user/favorites', methods=['POST'])
def toggle_favorite():
    """Toggle favorite status for a course."""
    try:
        data = request.get_json()
        
        # Validate required data
        if not data:
            return jsonify({
                'success': False,
                'message': 'No data provided'
            }), 400
        
        # Get email directly from request
        email = data.get('email')
        if not email:
            return jsonify({
                'success': False,
                'message': 'Email is required'
            }), 400
            
        # Get and validate course_id
        course_id = str(data.get('course_id'))
        if not course_id:
            return jsonify({
                'success': False,
                'message': 'Course ID is required'
            }), 400
            
        # Get favorite status (default to True if adding favorite)
        is_favorite = data.get('is_favorite', True)
        
        print(f"Toggle favorite request for user {email}, course {course_id}, status {is_favorite}")
        
        # Find user in MongoDB
        users_collection = mongo.db.users
        user = users_collection.find_one({'email': email})
        
        if not user:
            print(f"User not found with email {email}")
            return jsonify({
                'success': False,
                'message': 'User not found'
            }), 404
            
        # Get current favorites and ensure they're strings
        favorites = user.get('favorites', [])
        favorites = [str(fav) for fav in favorites]
        
        print(f"Current favorites for user {email}: {favorites}")
        
        # Check if course exists in the dataset
        df = readdata()
        df['course_id'] = df['course_id'].astype(str)
        course_exists = course_id in df['course_id'].values
        
        if not course_exists:
            print(f"Warning: Course ID {course_id} not found in dataset")
            # Continue anyway since we store IDs regardless of dataset presence
        
        modified = False
        if is_favorite and course_id not in favorites:
            # Add to favorites
            favorites.append(course_id)
            print(f"Added course {course_id} to favorites for user {email}")
            modified = True
        elif not is_favorite and course_id in favorites:
            # Remove from favorites
            favorites.remove(course_id)
            print(f"Removed course {course_id} from favorites for user {email}")
            modified = True
        else:
            print(f"No change needed: course {course_id} is already {'in' if is_favorite else 'not in'} favorites")
            
        if modified:
            # Update user document
            update_result = users_collection.update_one(
                {'email': email},
                {'$set': {'favorites': favorites}}
            )
            
            print(f"MongoDB update result: {update_result.modified_count} document(s) modified")
            
            # Verify the update
            updated_user = users_collection.find_one({'email': email})
            updated_favorites = updated_user.get('favorites', [])
            updated_favorites = [str(fav) for fav in updated_favorites]
            print(f"Updated favorites in DB: {updated_favorites}")
            
            # Check if the update was successful
            if (is_favorite and course_id in updated_favorites) or (not is_favorite and course_id not in updated_favorites):
                print("Database updated successfully")
            else:
                print("Warning: Database may not have updated correctly")
        
        return jsonify({
            'success': True,
            'is_favorite': is_favorite,
            'message': f"Course {'added to' if is_favorite else 'removed from'} favorites"
        })
        
    except Exception as e:
        print(f"Error toggling favorite: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

# Helper function to get user preferences by email
def get_user_preferences(email):
    """
    Retrieve a user's preferences from the database by email.
    Returns a dictionary of preferences or None if user not found.
    """
    try:
        # Find the user by email
        user = mongo.db.users.find_one({"email": email})
        if not user:
            print(f"User not found with email: {email}")
            return None
        
        # Extract preferences
        preferences = {
            "topics": user.get("preferred_topics", []),
            "level": user.get("skill_level", "All Levels"),
            "course_type": user.get("course_type", "All"),
            "duration": user.get("preferred_duration", "Any"),
            "popularity": user.get("popularity_importance", "Medium")
        }
        
        print(f"Retrieved preferences for {email}: {preferences}")
        return preferences
        
    except Exception as e:
        print(f"Error retrieving user preferences: {str(e)}")
        return None

# Personalized recommendations endpoint
@app.route('/recommendations/personalized', methods=['GET', 'OPTIONS'])
def get_personalized_recommendations():
    if request.method == 'OPTIONS':
        response = jsonify({'status': 'success'})
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
        response.headers.add('Access-Control-Allow-Methods', 'GET,POST,OPTIONS')
        return response
        
    try:
        # Get user email from query parameters
        email = request.args.get('email')
        
        if not email:
            return jsonify({
                "success": False,
                "message": "Email is required"
            }), 400
            
        print(f"Getting recommendations for user: {email}")
        
        # Get user preferences from MongoDB
        user = mongo.db.users.find_one({"email": email})
        if not user:
            print(f"User not found with email: {email}")
            return jsonify({
                "success": False,
                "message": "User not found"
            }), 404
            
        # Load course data
        courses_df = pd.read_csv('udemy_course_data.csv')
        print(f"Total courses in dataset: {len(courses_df)}")
        
        # Get user preferences
        preferred_topics = user.get("preferred_topics", [])
        preferred_level = user.get("skill_level", "All Levels")
        preferred_type = user.get("course_type", "All")
        
        print(f"User preferences: topics={preferred_topics}, level={preferred_level}, type={preferred_type}")
        
        # Initialize filtered dataframe
        filtered_df = courses_df.copy()
        
        # Filter by topics if specified
        if preferred_topics:
            # Convert topics to lowercase for case-insensitive matching
            preferred_topics_lower = [topic.lower() for topic in preferred_topics]
            print(f"Looking for courses with subjects (case-insensitive): {preferred_topics_lower}")
            
            # Create a mask for subject matching
            filtered_df['subject_lower'] = filtered_df['subject'].str.lower()
            topic_mask = filtered_df['subject_lower'].apply(lambda x: any(topic in x or x in topic for topic in preferred_topics_lower))
            filtered_df = filtered_df[topic_mask]
            filtered_df = filtered_df.drop('subject_lower', axis=1)
            
            print(f"Found {len(filtered_df)} courses matching topics")
            if len(filtered_df) > 0:
                print("Sample matched courses:")
                print(filtered_df[['course_title', 'subject', 'level']].head())
        
        # Apply level filter if specified
        if preferred_level and preferred_level != "No preference" and preferred_level != "All Levels":
            level_mask = filtered_df['level'].str.lower().str.contains(preferred_level.lower(), na=False)
            filtered_df = filtered_df[level_mask]
            print(f"After level filter: {len(filtered_df)} courses")
        
        # Apply course type filter
        if preferred_type and preferred_type != "All":
            # Convert is_paid to boolean, handling both string and boolean values
            filtered_df['is_paid'] = filtered_df['is_paid'].astype(str).str.upper() == 'TRUE'
            
            if preferred_type == "Free":
                filtered_df = filtered_df[~filtered_df['is_paid']]
            elif preferred_type == "Paid":
                filtered_df = filtered_df[filtered_df['is_paid']]
            print(f"After type filter: {len(filtered_df)} courses")
        
        # If no courses match filters, fall back to topic matching only
        if len(filtered_df) == 0:
            print("No courses match all filters, falling back to topic matching only")
            if preferred_topics:
                topic_mask = courses_df['subject'].str.lower().apply(lambda x: any(topic in x or x in topic for topic in preferred_topics_lower))
                filtered_df = courses_df[topic_mask]
            else:
                filtered_df = courses_df
        
        # Sort by popularity
        filtered_df = filtered_df.sort_values(by='num_subscribers', ascending=False)
        
        # Take top 10 courses
        top_courses = filtered_df.head(10)
        
        # Format the response
        recommendations = []
        for _, course in top_courses.iterrows():
            course_dict = {
                "course_id": int(course['course_id']),
                "course_title": course['course_title'],
                "url": course['url'],
                "is_paid": str(course['is_paid']).upper() == 'TRUE',
                "price": course['price'],
                "num_subscribers": int(course['num_subscribers']),
                "num_reviews": int(course['num_reviews']),
                "num_lectures": int(course['num_lectures']),
                "level": course['level'],
                "content_duration": course['content_duration'],
                "published_timestamp": course['published_timestamp'],
                "subject": course['subject'],
                "Clean_title": course.get('Clean_title', course['course_title'].replace(' ', '')),
                "image_url": None
            }
            recommendations.append(course_dict)
        
        print(f"Returning {len(recommendations)} recommendations")
        return jsonify({
            "success": True,
            "courses": recommendations,
            "count": len(recommendations),
            "preferred_topics": preferred_topics
        })
        
    except Exception as e:
        print(f"Error getting personalized recommendations: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({
            "success": False,
            "message": f"Failed to get recommendations: {str(e)}"
        }), 500

@app.route('/search', methods=['GET', 'POST'])
def search_courses():
    try:
        # Get search query from either query parameters or JSON body
        if request.method == 'GET':
            query = request.args.get('query', '').lower()
        else:
            data = request.get_json()
            query = data.get('query', '').lower()
        
        if not query:
            return jsonify({
                "success": False,
                "message": "No search query provided"
            }), 400
            
        print(f"Searching for courses with query: {query}")
        
        # Load course data
        courses_df = pd.read_csv('udemy_course_data.csv')
        
        # Search in course titles and subjects
        filtered_df = courses_df[
            courses_df['course_title'].str.lower().str.contains(query, na=False) |
            courses_df['subject'].str.lower().str.contains(query, na=False)
        ]
        
        # Sort by popularity
        filtered_df = filtered_df.sort_values(by='num_subscribers', ascending=False)
        
        # Take top 10 results
        top_results = filtered_df.head(10)
        
        # Format results
        search_results = []
        for _, course in top_results.iterrows():
            result = {
                "course_id": str(course['course_id']),
                "course_title": course['course_title'],
                "url": course['url'],
                "is_paid": str(course['is_paid']).upper() == 'TRUE',
                "price": float(course['price']),
                "num_subscribers": int(course['num_subscribers']),
                "num_reviews": int(course['num_reviews']),
                "num_lectures": int(course['num_lectures']),
                "level": course['level'],
                "subject": course['subject'],
                "image_url": None  # You can add image URLs if available
            }
            search_results.append(result)
            
        print(f"Found {len(search_results)} matching courses")
        
        return jsonify({
            "success": True,
            "query": query,
            "search_results": search_results
        })
        
    except Exception as e:
        print(f"Error searching courses: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({
            "success": False,
            "message": f"Failed to search courses: {str(e)}"
        }), 500

# Admin registration endpoint
@app.route('/register-admin', methods=['POST'])
def register_admin():
    try:
        data = request.get_json()
        
        # Check if required fields are provided
        if not data or not data.get('email') or not data.get('password') or not data.get('name'):
            return jsonify({
                "success": False,
                "message": "Missing required fields"
            }), 400
            
        # Check if user already exists
        existing_user = mongo.db.users.find_one({"email": data['email']})
        if existing_user:
            return jsonify({
                "success": False,
                "message": "User already exists"
            }), 409
            
        # Hash the password
        hashed_password = bcrypt.generate_password_hash(data['password']).decode('utf-8')
        
        # Create new admin user
        new_admin = {
            "name": data['name'],
            "email": data['email'],
            "password": hashed_password,
            "favorites": [],
            "preferred_topics": [],
            "skill_level": "",
            "course_type": "",
            "preferred_duration": "",
            "popularity_importance": "",
            "is_admin": True  # Set as admin
        }
        
        # Insert admin into database
        mongo.db.users.insert_one(new_admin)
        
        # Remove password before returning user data
        new_admin.pop('password', None)
        
        return jsonify({
            "success": True,
            "message": "Admin registered successfully",
            "user": json.loads(dumps(new_admin))
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

if __name__ == '__main__':
    app.run(debug=True)
