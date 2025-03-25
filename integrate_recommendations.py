"""
Integration script for collaborative filtering recommendations with Flask API.
This script provides functions to integrate recommendations with the Flask API
using user interaction data directly from CSV.
"""

import pandas as pd
import numpy as np
from flask import jsonify, request
import pickle
import os
from collections import defaultdict

# Check if models exist
SVD_MODEL_PATH = 'svd_model.pkl'
KNN_MODEL_PATH = 'knn_model.pkl'
COURSE_MAPPING_PATH = 'course_mapping.pkl'

def get_collaborative_filtering_recommendations(email, limit=10, max_per_subject=3):
    """
    Get recommendations for a user using a simplified collaborative filtering approach.
    This version uses user similarity based on course interactions and ratings.
    
    Args:
        email: User's email address
        limit: Maximum number of recommendations to return
        max_per_subject: Maximum number of courses per subject for diversity
        
    Returns:
        List of course recommendations with scores
    """
    try:
        # Load interactions and course data
        interactions_df = pd.read_csv('user_interactions.csv')
        courses_df = pd.read_csv('UdemyCleanedTitle.csv')
        
        # Convert email to user_id format
        if '@' in email:
            username = email.split('@')[0]
            if username.startswith('test'):
                user_id = f"user_{username.replace('test', '')}"
            else:
                matching_users = interactions_df[interactions_df['user_id'].str.contains(username)]
                if not matching_users.empty:
                    user_id = matching_users['user_id'].iloc[0]
                else:
                    user_id = f"user_{username}"
        else:
            user_id = email
            
        print(f"Using user_id: {user_id} for collaborative filtering")
        
        # Check if this user has interactions
        user_interactions = interactions_df[interactions_df['user_id'] == user_id]
        
        if user_interactions.empty:
            print(f"No interactions found for user {user_id}. Falling back to trending courses with diversity.")
            trending_recs = get_trending_recommendations(limit=limit*3)
            return diversify_recommendations(trending_recs, courses_df, max_per_subject)
            
        # Get courses the user has already interacted with
        user_courses = user_interactions['course_id'].tolist()
        print(f"User has interacted with {len(user_courses)} courses")
        
        # Get the subjects of courses the user has interacted with
        user_subjects = []
        for course_id in user_courses:
            course_data = courses_df[courses_df['course_id'] == course_id]
            if not course_data.empty:
                subject = course_data.iloc[0]['subject']
                if subject not in user_subjects:
                    user_subjects.append(subject)
        
        print(f"User has interacted with courses from {len(user_subjects)} subjects: {user_subjects}")
        
        # Find similar users based on course interactions
        similar_users = []
        for other_user in interactions_df['user_id'].unique():
            if other_user != user_id:
                other_interactions = interactions_df[interactions_df['user_id'] == other_user]
                common_courses = set(user_courses) & set(other_interactions['course_id'].tolist())
                
                if len(common_courses) > 0:
                    # Calculate similarity score based on common courses and ratings
                    similarity_score = 0
                    for course_id in common_courses:
                        user_rating = user_interactions[user_interactions['course_id'] == course_id]['rating'].iloc[0]
                        other_rating = other_interactions[other_interactions['course_id'] == course_id]['rating'].iloc[0]
                        similarity_score += 1 - abs(user_rating - other_rating) / 5
                    
                    similarity_score = similarity_score / len(common_courses)
                    similar_users.append((other_user, similarity_score))
        
        # Sort similar users by similarity score
        similar_users.sort(key=lambda x: x[1], reverse=True)
        similar_users = similar_users[:10]  # Take top 10 similar users
        
        # Get courses liked by similar users
        recommended_courses = []
        for similar_user, _ in similar_users:
            similar_user_interactions = interactions_df[
                (interactions_df['user_id'] == similar_user) & 
                (interactions_df['rating'] >= 4) &  # Only consider highly rated courses
                (~interactions_df['course_id'].isin(user_courses))  # Exclude user's courses
            ]
            
            for _, interaction in similar_user_interactions.iterrows():
                course_id = interaction['course_id']
                rating = interaction['rating']
                recommended_courses.append((course_id, rating))
        
        # Sort by rating and apply diversity
        recommended_courses.sort(key=lambda x: x[1], reverse=True)
        diversified_recommendations = diversify_recommendations(recommended_courses, courses_df, max_per_subject)
        
        # Return top N recommendations
        return diversified_recommendations[:limit]
        
    except Exception as e:
        print(f"Error generating collaborative filtering recommendations: {e}")
        import traceback
        traceback.print_exc()
        # Fall back to trending with diversity
        try:
            return diversify_recommendations(get_trending_recommendations(limit*2), courses_df, max_per_subject)[:limit]
        except:
            return []

def get_course_recommendations(user_id, limit=10, mongo=None, max_per_subject=2):
    """
    Get course recommendations for a user based on their interactions and preferences.
    Focuses explicitly on content-based recommendations from user preferences.
    
    Args:
        user_id: The user ID to get recommendations for
        limit: Maximum number of recommendations to return
        mongo: MongoDB connection object
        max_per_subject: Maximum courses per subject for diversity
    
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
        
        print(f"Getting personalized recommendations for {user_id} (email: {email})")
        
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
                
                # If user has no explicit preferences, try to extract from interactions
                if not preferred_topics and user_id in interactions_df['user_id'].values:
                    print("No explicit topic preferences found. Deriving from interactions.")
                    user_interactions = interactions_df[interactions_df['user_id'] == user_id]
                    
                    # Get highly-rated or favorited courses
                    liked_courses = user_interactions[
                        (user_interactions['rating'] >= 4) | 
                        (user_interactions['is_favorite'] == True)
                    ]['course_id'].unique().tolist()
                    
                    if liked_courses:
                        # Find subjects of liked courses
                        for course_id in liked_courses:
                            course_data = courses_df[courses_df['course_id'] == course_id]
                            if not course_data.empty:
                                subject = course_data.iloc[0]['subject']
                                if subject not in preferred_topics:
                                    preferred_topics.append(subject)
                        print(f"Derived topic preferences from interactions: {preferred_topics}")
        
        # Initialize an empty DataFrame for filtered courses
        filtered_df = pd.DataFrame()
        
        # If we have explicit user preferences, prioritize those
        if preferred_topics:
            print(f"Finding courses matching user's preferred topics: {preferred_topics}")
            # Convert topics to lowercase for case-insensitive matching
            preferred_topics_lower = [topic.lower() for topic in preferred_topics]
            
            # Create a mask for subject matching
            subject_mask = courses_df['subject'].str.lower().apply(lambda x: any(topic in x.lower() for topic in preferred_topics_lower))
            filtered_df = courses_df[subject_mask].copy()
            print(f"Found {len(filtered_df)} courses matching preferred topics")
        else:
            # If no preferred topics, use all courses
            filtered_df = courses_df.copy()
        
        # If user has interaction data, use it to enhance recommendations
        interacted_courses = []
        if user_id in interactions_df['user_id'].values:
            user_interactions = interactions_df[interactions_df['user_id'] == user_id]
            interacted_courses = user_interactions['course_id'].unique().tolist()
            
            # Get highly-rated or favorited courses
            liked_courses = user_interactions[
                (user_interactions['rating'] >= 4) | 
                (user_interactions['is_favorite'] == True)
            ]['course_id'].unique().tolist()
            
            if liked_courses:
                print(f"User has {len(liked_courses)} liked courses")
                # Find subjects of liked courses
                liked_subjects = []
                for course_id in liked_courses:
                    course_data = courses_df[courses_df['course_id'] == course_id]
                    if not course_data.empty:
                        subject = course_data.iloc[0]['subject']
                        if subject not in liked_subjects:
                            liked_subjects.append(subject)
                
                # If no filtered courses yet OR no explicit preferences but we have liked subjects,
                # focus on courses from subjects the user has liked
                if filtered_df.empty or (not preferred_topics and liked_subjects):
                    liked_df = courses_df[courses_df['subject'].isin(liked_subjects)]
                    if liked_df.empty:
                        filtered_df = courses_df.copy()
                    else:
                        filtered_df = liked_df.copy()
                    print(f"Using {len(filtered_df)} courses from liked subjects")
        
        # Remove courses the user has already interacted with
        if interacted_courses:
            filtered_df = filtered_df[~filtered_df['course_id'].isin(interacted_courses)]
            print(f"Removed {len(interacted_courses)} already interacted courses")
        
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
        
        # If still no recommendations or very few, fall back to popular courses
        if len(filtered_df) < 5:
            print(f"Not enough personalized courses ({len(filtered_df)}), falling back to popular courses")
            popular_df = courses_df.sort_values(by='num_subscribers', ascending=False)
            
            # Still exclude courses the user has interacted with
            if interacted_courses:
                popular_df = popular_df[~popular_df['course_id'].isin(interacted_courses)]
                
            # Combine with any existing filtered results
            if not filtered_df.empty:
                filtered_df = pd.concat([filtered_df, popular_df]).drop_duplicates(subset=['course_id'])
            else:
                filtered_df = popular_df
        
        # Ensure diversity across subjects
        filtered_df = filtered_df.sort_values(by='num_subscribers', ascending=False)
        top_courses_raw = filtered_df.head(limit * 3)  # Get more to allow for diversity
        
        # Convert to recommendations format
        recs_raw = []
        for _, course in top_courses_raw.iterrows():
            # Simple relevance score (0-5) based on subscribers
            sub_score = min(5.0, course['num_subscribers'] / 100000)
            recs_raw.append((int(course['course_id']), sub_score))
        
        # Apply diversification
        diversified_recs = diversify_recommendations(recs_raw, courses_df, max_per_subject)
        
        # Take top N recommendations
        recommended_courses = diversified_recs[:limit]
        
        print(f"Final personalized recommendations: {len(recommended_courses)} courses")
        return recommended_courses
        
    except Exception as e:
        print(f"Error getting recommendations: {str(e)}")
        import traceback
        traceback.print_exc()
        
        # Fall back to trending recommendations
        try:
            print("Falling back to trending recommendations due to error")
            return get_trending_recommendations(limit=limit)
        except:
            return []

def format_recommendations_response(recommendations, include_details=True, recommendation_type="general"):
    """
    Format recommendations for API response.
    
    Args:
        recommendations: List of (course_id, score) tuples
        include_details: Whether to include course details
        recommendation_type: Type of recommendation ("collaborative", "personalized", "trending", etc.)
    
    Returns:
        Formatted response dictionary
    """
    try:
        # Try to load from cleaner file first, fall back to old file if needed
        try:
            courses_df = pd.read_csv('UdemyCleanedTitle.csv')
        except:
            print("Using fallback udemy_course_data.csv")
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
                    
                    # Create basic course info dictionary with mandatory fields
                    course_info = {
                        "course_title": course.get('course_title', ''),
                        "url": course.get('url', ''),
                        "price": course.get('price', 0),
                        "num_subscribers": int(course.get('num_subscribers', 0)),
                        "num_reviews": int(course.get('num_reviews', 0)),
                        "num_lectures": int(course.get('num_lectures', 0)),
                        "level": course.get('level', 'All Levels'),
                        "subject": course.get('subject', 'General'),
                        "image_url": ''  # Empty string instead of None for consistent handling
                    }
                    
                    # Add optional fields if they exist
                    if 'is_paid' in course:
                        is_paid_val = course['is_paid']
                        if isinstance(is_paid_val, str):
                            course_info["is_paid"] = is_paid_val.upper() == 'TRUE'
                        else:
                            course_info["is_paid"] = bool(is_paid_val)
                    else:
                        course_info["is_paid"] = course.get('price', 0) > 0
                    
                    if 'content_duration' in course:
                        course_info["content_duration"] = course['content_duration']
                        
                    if 'published_timestamp' in course:
                        course_info["published_timestamp"] = course['published_timestamp']
                        
                    if 'Clean_title' in course:
                        course_info["clean_title"] = course['Clean_title']
                    elif 'clean_title' in course:
                        course_info["clean_title"] = course['clean_title']
                    else:
                        # Generate a clean title if missing
                        course_info["clean_title"] = course_info["course_title"].replace(' ', '')
                    
                    # Add course info to recommendation
                    rec.update(course_info)
            
            formatted_recs.append(rec)
        
        return {
            "success": True,
            "courses": formatted_recs,
            "count": len(formatted_recs),
            "recommendation_type": recommendation_type
        }
    except Exception as e:
        print(f"Error formatting recommendations: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            "success": False,
            "error": str(e),
            "recommendations": [],
            "count": 0,
            "recommendation_type": recommendation_type
        }

def add_recommendation_routes(app, mongo=None):
    """Add recommendation routes to the Flask app."""
    
    @app.route('/recommendations/trending', methods=['GET'])
    def get_trending_recommendations_route():
        """Get trending courses based on subscriber count."""
        try:
            # Get limit from query parameters
            limit = int(request.args.get('limit', 10))
            
            # Get email for filtering out subjects (optional)
            email = request.args.get('email')
            exclude_subjects = []
            
            # If email is provided, we might exclude subjects to provide more diverse recommendations
            if email and mongo:
                # Get user's preferred subjects
                user = mongo.db.users.find_one({"email": email})
                if user and user.get("preferred_topics"):
                    # Get subjects the user already has in preferences (optional)
                    # Uncomment if you want to exclude these from trending
                    # exclude_subjects = user.get("preferred_topics", [])
                    pass
            
            # Get trending recommendations
            trending_recs = get_trending_recommendations(limit, exclude_subjects)
            
            # Format the response
            response = format_recommendations_response(
                trending_recs, 
                recommendation_type="trending"
            )
            
            return jsonify(response)
        except Exception as e:
            print(f"Error getting trending recommendations: {e}")
            import traceback
            traceback.print_exc()
            return jsonify({
                "success": False,
                "message": str(e),
                "recommendation_type": "trending"
            }), 500
    
    @app.route('/recommendations', methods=['GET'])
    def get_recommendations():
        try:
            # Get user_id from query parameters
            user_id = request.args.get('user_id')
            limit = int(request.args.get('limit', 10))
            
            # If no user_id provided, return trending recommendations instead
            if not user_id:
                print("No user ID provided, returning trending recommendations")
                trending_recs = get_trending_recommendations(limit)
                response = format_recommendations_response(
                    trending_recs, 
                    recommendation_type="trending"
                )
                return jsonify(response)
                
            # Get recommendations with explicit user_id
            recommended_courses = get_course_recommendations(user_id, limit=limit, mongo=mongo)
            
            # Format the response
            response = format_recommendations_response(
                recommended_courses, 
                recommendation_type="general"
            )
            
            return jsonify(response)
            
        except Exception as e:
            print(f"Error in recommendations: {str(e)}")
            import traceback
            traceback.print_exc()
            return jsonify({
                "success": False, 
                "message": str(e),
                "recommendation_type": "general"
            }), 500
    
    @app.route('/recommendations/for_user', methods=['GET'])
    def get_recommendations_for_email():
        try:
            # Get email from query parameters
            email = request.args.get('email')
            limit = int(request.args.get('limit', 10))
            
            # If no email provided, return error
            if not email:
                return jsonify({
                    "success": False,
                    "message": "Email is required",
                    "recommendation_type": "personalized"
                }), 400
                
            # Extract user_id from email
            user_id = f"user_{email.split('@')[0].replace('test', '')}"
            print(f"Derived user_id: {user_id}")
            
            # Get recommendations
            recommended_courses = get_course_recommendations(user_id, limit=limit, mongo=mongo)
            
            # Format the response
            response = format_recommendations_response(
                recommended_courses, 
                recommendation_type="personalized"
            )
            
            return jsonify(response)
            
        except Exception as e:
            print(f"Error in recommendations for user: {str(e)}")
            import traceback
            traceback.print_exc()
            return jsonify({
                "success": False, 
                "message": str(e),
                "recommendation_type": "personalized"
            }), 500
    
    @app.route('/recommendations/collaborative', methods=['GET'])
    def get_collaborative_recommendations():
        try:
            # Get email from query parameters
            email = request.args.get('email')
            limit = int(request.args.get('limit', 10))
            
            # If no email provided, return error
            if not email:
                return jsonify({
                    "success": False,
                    "message": "Email is required",
                    "recommendation_type": "collaborative"
                }), 400
                
            # Get collaborative filtering recommendations
            recommended_courses = get_collaborative_filtering_recommendations(
                email, 
                limit=limit, 
                max_per_subject=3
            )
            
            # Format the response
            response = format_recommendations_response(
                recommended_courses, 
                recommendation_type="collaborative"
            )
            
            return jsonify(response)
            
        except Exception as e:
            print(f"Error in collaborative filtering recommendations: {str(e)}")
            import traceback
            traceback.print_exc()
            return jsonify({
                "success": False, 
                "message": str(e),
                "recommendation_type": "collaborative"
            }), 500

def diversify_recommendations(recommendations, courses_df, max_per_subject=3):
    """
    Ensure recommendations aren't all from the same subject.
    
    Args:
        recommendations: List of (course_id, score) tuples
        courses_df: DataFrame containing course information
        max_per_subject: Maximum number of courses per subject
        
    Returns:
        List of (course_id, score) tuples with subject diversity
    """
    if not recommendations:
        return []
        
    subject_counts = {}
    diversified = []
    
    # Sort by predicted rating first
    sorted_recs = sorted(recommendations, key=lambda x: x[1], reverse=True)
    
    for course_id, score in sorted_recs:
        # Get course subject
        course_data = courses_df[courses_df['course_id'] == course_id]
        if course_data.empty:
            continue
            
        subject = course_data.iloc[0]['subject']
        
        # Check if we already have max courses from this subject
        if subject in subject_counts and subject_counts[subject] >= max_per_subject:
            continue
            
        # Add to diversified list
        diversified.append((course_id, score))
        subject_counts[subject] = subject_counts.get(subject, 0) + 1
    
    print(f"Diversified recommendations: {len(diversified)} courses across {len(subject_counts)} subjects")
    for subject, count in subject_counts.items():
        print(f"  - {subject}: {count} courses")
    
    return diversified

def get_trending_recommendations(limit=10, exclude_subjects=None):
    """
    Get trending courses based on subscriber count.
    
    Args:
        limit: Maximum number of recommendations to return
        exclude_subjects: List of subjects to exclude (optional)
        
    Returns:
        List of course recommendations with scores
    """
    try:
        # Load course data
        courses_df = pd.read_csv('UdemyCleanedTitle.csv')
        
        # Apply subject exclusion if provided
        if exclude_subjects and len(exclude_subjects) > 0:
            before_count = len(courses_df)
            courses_df = courses_df[~courses_df['subject'].isin(exclude_subjects)]
            after_count = len(courses_df)
            print(f"Excluded {before_count - after_count} courses from {len(exclude_subjects)} subjects")
        
        # Sort by subscribers (descending)
        trending_df = courses_df.sort_values(by='num_subscribers', ascending=False)
        
        # Get top N courses
        top_courses = trending_df.head(limit)
        
        # Format as (course_id, score) tuples
        trending_recommendations = []
        for _, course in top_courses.iterrows():
            # Use normalized subscriber count as relevance score (0-5 scale)
            # This keeps the format consistent with other recommendation functions
            subscriber_score = min(5.0, float(course['num_subscribers'])/100000)
            trending_recommendations.append((int(course['course_id']), subscriber_score))
        
        print(f"Generated {len(trending_recommendations)} trending recommendations")
        return trending_recommendations
    
    except Exception as e:
        print(f"Error getting trending recommendations: {e}")
        import traceback
        traceback.print_exc()
        return []

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
    
    # Test collaborative filtering
    print("\nTesting collaborative filtering...")
    cf_recommendations = get_collaborative_filtering_recommendations("test1@example.com", limit=5)
    cf_response = format_recommendations_response(cf_recommendations, recommendation_type="collaborative")
    print(json.dumps(cf_response, indent=2)) 