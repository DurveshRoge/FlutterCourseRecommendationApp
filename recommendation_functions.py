
import pickle
import pandas as pd
import numpy as np
from collections import defaultdict
import os

# Check if models exist before loading
if not os.path.exists('svd_model.pkl') or not os.path.exists('knn_model.pkl'):
    print("Models not found. Please run train_collaborative_filtering.py first.")
    exit(1)

# Load models and mappings
with open('svd_model.pkl', 'rb') as f:
    svd_model = pickle.load(f)

with open('knn_model.pkl', 'rb') as f:
    knn_model = pickle.load(f)

with open('course_mapping.pkl', 'rb') as f:
    course_to_idx = pickle.load(f)

# Load interactions and course data
interactions_df = pd.read_csv('user_interactions.csv')
courses_df = pd.read_csv('UdemyCleanedTitle.csv')

def get_content_based_similarity(course_id, n=10):
    """Get content-based similar courses using course features"""
    try:
        course = courses_df[courses_df['course_id'] == course_id].iloc[0]
        
        # Calculate similarity based on subject and level
        similar_courses = courses_df[
            (courses_df['subject'] == course['subject']) &
            (courses_df['level'] == course['level']) &
            (courses_df['course_id'] != course_id)
        ]
        
        # Sort by number of subscribers as a proxy for quality
        similar_courses = similar_courses.sort_values('num_subscribers', ascending=False)
        return similar_courses['course_id'].head(n).tolist()
    except (IndexError, KeyError):
        # If course not found or error occurs, return popular courses
        return courses_df.nlargest(n, 'num_subscribers')['course_id'].tolist()

def get_hybrid_recommendations(user_id, n=10, cf_weight=0.7):
    """Get hybrid recommendations combining collaborative and content-based filtering"""
    # Get collaborative filtering recommendations
    cf_recs = get_recommendations_for_user(user_id, n=n*2, model='svd')
    
    # Get content-based recommendations from user's highly rated courses
    user_interactions = interactions_df[interactions_df['user_id'] == user_id]
    if not user_interactions.empty:
        # Get user's highest rated courses
        top_courses = user_interactions.nlargest(3, 'rating')['course_id'].tolist()
        content_recs = []
        for course_id in top_courses:
            similar_courses = get_content_based_similarity(course_id, n=5)
            content_recs.extend(similar_courses)
    else:
        # For new users, get popular courses in each subject
        content_recs = courses_df.nlargest(n, 'num_subscribers')['course_id'].tolist()
    
    # Combine recommendations
    cf_dict = dict(cf_recs)
    content_dict = {course_id: 1.0 for course_id in content_recs}
    
    # Calculate hybrid scores
    hybrid_scores = defaultdict(float)
    for course_id in set(list(cf_dict.keys()) + content_recs):
        cf_score = cf_dict.get(course_id, 0) * cf_weight
        content_score = content_dict.get(course_id, 0) * (1 - cf_weight)
        hybrid_scores[course_id] = cf_score + content_score
    
    # Sort and return top N recommendations
    sorted_recs = sorted(hybrid_scores.items(), key=lambda x: x[1], reverse=True)
    return sorted_recs[:n]

def get_recommendations_for_user(user_id, n=10, model='svd'):
    """Get top N recommendations for a user using collaborative filtering"""
    # Get all courses
    all_courses = list(course_to_idx.keys())
    
    # Get courses the user has already interacted with
    user_interactions = interactions_df[interactions_df['user_id'] == user_id]
    user_courses = user_interactions['course_id'].tolist() if not user_interactions.empty else []
    
    # Filter out courses the user has already interacted with
    courses_to_predict = [c for c in all_courses if c not in user_courses]
    
    # If the user is new, return popular courses
    if not user_courses:
        popular_courses = courses_df.nlargest(n, 'num_subscribers')
        return [(course_id, 3.0) for course_id in popular_courses['course_id']]
    
    # Make predictions
    predictions = []
    selected_model = svd_model if model == 'svd' else knn_model
    
    for course_id in courses_to_predict:
        try:
            pred = selected_model.predict(user_id, course_id)
            predictions.append((course_id, pred.est))
        except:
            continue
    
    # Sort by predicted rating
    predictions.sort(key=lambda x: x[1], reverse=True)
    return predictions[:n]

# Example usage
if __name__ == "__main__":
    # Test with a sample user
    sample_user = interactions_df['user_id'].iloc[0] if not interactions_df.empty else "user_1"
    print(f"Sample recommendations for user {sample_user}:")
    recs = get_hybrid_recommendations(sample_user, n=5)
    for course_id, score in recs:
        course_info = courses_df[courses_df['course_id'] == course_id].iloc[0]
        print(f"- {course_info['title']} (Score: {score:.2f})")
