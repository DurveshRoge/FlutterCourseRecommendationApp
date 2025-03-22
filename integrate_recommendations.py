"""
Integration script for collaborative filtering recommendations with Flask API.
This script provides functions to integrate recommendations with the Flask API
using user interaction data directly from CSV.
"""

import pandas as pd
import numpy as np
from flask import jsonify, request

def get_course_recommendations(user_id, limit=10, mongo=None):
    """
    Get course recommendations for a user based on their interactions and preferences.
    
    Args:
        user_id: The user ID to get recommendations for
        limit: Maximum number of recommendations to return
        mongo: MongoDB connection object
    
    Returns:
        List of recommended course IDs with scores
    """
    try:
        # Load user interactions and course data
        interactions_df = pd.read_csv('user_interactions.csv')
        courses_df = pd.read_csv('UdemyCleanedTitle.csv')
        
        # Extract email from user_id (e.g., "user_2" -> "test2@gmail.com")
        user_number = user_id.replace('user_', '')
        email = f"test{user_number}@gmail.com"
        
        # Get user preferences from MongoDB
        preferred_topics = []
        preferred_level = "All Levels"
        preferred_type = "All"
        
        if mongo:
            user = mongo.db.users.find_one({"email": email})
            if user:
                preferred_topics = user.get("preferred_topics", [])
                preferred_level = user.get("skill_level", "All Levels")
                preferred_type = user.get("course_type", "All")
                print(f"Found preferences for {email}: topics={preferred_topics}, level={preferred_level}, type={preferred_type}")
        
        # Initialize an empty DataFrame for filtered courses
        filtered_df = pd.DataFrame()
        
        # First, try to get courses based on user's explicit preferences
        if preferred_topics:
            # Convert topics to lowercase for case-insensitive matching
            preferred_topics_lower = [topic.lower() for topic in preferred_topics]
            
            # Create a mask for subject matching
            subject_mask = courses_df['subject'].str.lower().apply(lambda x: any(topic in x for topic in preferred_topics_lower))
            filtered_df = courses_df[subject_mask]
            print(f"Found {len(filtered_df)} courses matching preferred topics")
            
        # If we have interaction data, use it to refine recommendations
        if user_id in interactions_df['user_id'].values:
            user_interactions = interactions_df[interactions_df['user_id'] == user_id]
            
            # Get highly-rated or favorited courses
            liked_courses = user_interactions[
                (user_interactions['rating'] >= 4) | 
                (user_interactions['is_favorite'] == True)
            ]['course_id'].unique().tolist()
            
            if liked_courses:
                # Find subjects of liked courses
                liked_subjects = []
                for course_id in liked_courses:
                    course_data = courses_df[courses_df['course_id'] == course_id]
                    if not course_data.empty:
                        subject = course_data.iloc[0]['subject']
                        if subject not in liked_subjects:
                            liked_subjects.append(subject)
                
                # Add courses from liked subjects if not already in filtered_df
                if liked_subjects:
                    liked_df = courses_df[courses_df['subject'].isin(liked_subjects)]
                    if filtered_df.empty:
                        filtered_df = liked_df
                    else:
                        filtered_df = pd.concat([filtered_df, liked_df]).drop_duplicates()
                    print(f"Added {len(liked_df)} courses from liked subjects")
        
        # If still no recommendations, fall back to popular courses
        if filtered_df.empty:
            print("No personalized recommendations found, falling back to popular courses")
            filtered_df = courses_df
        
        # Apply level filter if specified
        if preferred_level and preferred_level != "No preference" and preferred_level != "All Levels":
            level_filtered = filtered_df[filtered_df['level'].str.lower().str.contains(preferred_level.lower(), na=False)]
            if not level_filtered.empty:
                filtered_df = level_filtered
                print(f"Applied level filter, {len(filtered_df)} courses remaining")
        
        # Apply course type filter
        if preferred_type and preferred_type != "All":
            # Convert is_paid to boolean
            filtered_df['is_paid'] = filtered_df['is_paid'].astype(str).str.upper() == 'TRUE'
            
            if preferred_type == "Free":
                filtered_df = filtered_df[~filtered_df['is_paid']]
            elif preferred_type == "Paid":
                filtered_df = filtered_df[filtered_df['is_paid']]
            print(f"Applied type filter, {len(filtered_df)} courses remaining")
        
        # Remove courses the user has already interacted with
        if user_id in interactions_df['user_id'].values:
            interacted_courses = interactions_df[interactions_df['user_id'] == user_id]['course_id'].unique().tolist()
            filtered_df = filtered_df[~filtered_df['course_id'].isin(interacted_courses)]
            print(f"Removed {len(interacted_courses)} already interacted courses")
        
        # Sort by popularity and relevance score
        filtered_df = filtered_df.sort_values(by='num_subscribers', ascending=False)
        
        # Take top N courses
        top_courses = filtered_df.head(limit)
        print(f"Selected top {len(top_courses)} courses")
        
        # Return recommendations with a relevance score
        recommended_courses = []
        for _, course in top_courses.iterrows():
            # Calculate a relevance score based on multiple factors
            relevance_score = 1.0
            
            # Increase score if subject matches user's preferred topics
            if preferred_topics and course['subject'] in preferred_topics:
                relevance_score *= 1.5
            
            # Increase score if level matches user's preferred level
            if preferred_level != "All Levels" and preferred_level in course['level']:
                relevance_score *= 1.2
                
            recommended_courses.append((int(course['course_id']), relevance_score))
        
        return recommended_courses
        
    except Exception as e:
        print(f"Error getting recommendations: {str(e)}")
        import traceback
        traceback.print_exc()
        return []

def format_recommendations_response(recommendations, include_details=True):
    """
    Format recommendations for API response.
    
    Args:
        recommendations: List of (course_id, score) tuples
        include_details: Whether to include course details
    
    Returns:
        Formatted response dictionary
    """
    try:
        courses_df = pd.read_csv('udemy_course_data.csv')
        
        formatted_recs = []
        for course_id, score in recommendations:
            rec = {
                "course_id": course_id,
                "score": float(score)
            }
            
            if include_details:
                # Find course details
                course_data = courses_df[courses_df['course_id'] == course_id]
                if not course_data.empty:
                    course = course_data.iloc[0]
                    
                    rec.update({
                        "course_title": course['course_title'],
                        "url": course['url'],
                        "is_paid": course['is_paid'] == 'TRUE',
                        "price": course['price'],
                        "num_subscribers": int(course['num_subscribers']),
                        "num_reviews": int(course['num_reviews']),
                        "num_lectures": int(course['num_lectures']),
                        "level": course['level'],
                        "content_duration": course['content_duration'],
                        "published_timestamp": course['published_timestamp'],
                        "subject": course['subject'],
                        "Clean_title": course['Clean_title'],
                        "image_url": None
                    })
            
            formatted_recs.append(rec)
        
        return {
            "success": True,
            "recommendations": formatted_recs,
            "count": len(formatted_recs)
        }
    except Exception as e:
        print(f"Error formatting recommendations: {str(e)}")
        return {
            "success": False,
            "error": str(e),
            "recommendations": [],
            "count": 0
        }

def add_recommendation_routes(app, mongo=None):
    """Add recommendation routes to the Flask app."""
    
    @app.route('/recommendations', methods=['GET'])
    def get_recommendations():
        try:
            # Get user_id from query parameters
            user_id = request.args.get('user_id')
            limit = int(request.args.get('limit', 10))
            
            # If no user_id provided, return error
            if not user_id:
                return jsonify({"success": False, "message": "User ID is required"}), 400
                
            # Get recommendations
            recommended_courses = get_course_recommendations(user_id, limit=limit, mongo=mongo)
            
            # Format the response
            response = format_recommendations_response(recommended_courses)
            
            return jsonify(response)
            
        except Exception as e:
            print(f"Error in recommendations: {str(e)}")
            import traceback
            traceback.print_exc()
            return jsonify({"success": False, "message": str(e)}), 500
    
    @app.route('/recommendations/for_user', methods=['GET'])
    def get_recommendations_for_email():
        try:
            # Get email from query parameters
            email = request.args.get('email')
            limit = int(request.args.get('limit', 10))
            
            # If no email provided, return error
            if not email:
                return jsonify({"success": False, "message": "Email is required"}), 400
                
            # Extract user_id from email
            user_id = f"user_{email.split('@')[0].replace('test', '')}"
            print(f"Derived user_id: {user_id}")
            
            # Get recommendations
            recommended_courses = get_course_recommendations(user_id, limit=limit, mongo=mongo)
            
            # Format the response
            response = format_recommendations_response(recommended_courses)
            
            return jsonify(response)
            
        except Exception as e:
            print(f"Error in recommendations for user: {str(e)}")
            import traceback
            traceback.print_exc()
            return jsonify({"success": False, "message": str(e)}), 500

# Testing
if __name__ == "__main__":
    # Test the recommendation functions
    print("Testing recommendation integration...")
    
    # Example user ID
    test_user = "user_1"
    
    # Get recommendations
    recommendations = get_course_recommendations(test_user, limit=5)
    
    # Format the response
    response = format_recommendations_response(recommendations)
    
    # Print the formatted recommendations
    import json
    print(json.dumps(response, indent=2)) 