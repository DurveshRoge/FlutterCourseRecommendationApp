"""
Test script for collaborative filtering recommendations.
This script allows you to test the recommendation system without Flask integration.
"""

import os
import json
import pandas as pd
import numpy as np
import requests

def test_recommendations():
    """Test the recommendation system"""
    print("Testing collaborative filtering recommendations...")
    
    # Check if the required files exist
    if not os.path.exists('UdemyCleanedTitle.csv'):
        print("Error: UdemyCleanedTitle.csv not found!")
        return
    
    # Step 1: Generate user interactions if they don't exist
    if not os.path.exists('user_interactions.csv'):
        print("Generating user interactions...")
        try:
            from generate_user_interactions import generate_user_interactions
            interactions_df = generate_user_interactions()
            print(f"Generated {len(interactions_df)} interactions")
        except Exception as e:
            print(f"Error generating user interactions: {str(e)}")
            return
    else:
        print("User interactions file found.")
        interactions_df = pd.read_csv('user_interactions.csv')
        print(f"Loaded {len(interactions_df)} interactions")
    
    # Step 2: Train models if they don't exist
    if not os.path.exists('svd_model.pkl') or not os.path.exists('knn_model.pkl'):
        print("Training collaborative filtering models...")
        try:
            from train_collaborative_filtering import train_collaborative_filtering_models
            svd_model, knn_model, course_to_idx = train_collaborative_filtering_models(perform_hyperparameter_tuning=False)
            print("Models trained successfully")
        except Exception as e:
            print(f"Error training models: {str(e)}")
            return
    else:
        print("Trained models found.")
    
    # Step 3: Test recommendations
    try:
        from recommendation_functions import get_recommendations_for_user, get_hybrid_recommendations
        
        # Get a sample user
        sample_user = interactions_df['user_id'].iloc[0]
        print(f"\nGetting recommendations for user: {sample_user}")
        
        # Get collaborative filtering recommendations
        cf_recs = get_recommendations_for_user(sample_user, n=5)
        print("\nCollaborative filtering recommendations:")
        for i, (course_id, score) in enumerate(cf_recs, 1):
            print(f"{i}. Course ID: {course_id}, Score: {score:.2f}")
        
        # Get hybrid recommendations
        hybrid_recs = get_hybrid_recommendations(sample_user, n=5)
        print("\nHybrid recommendations:")
        for i, (course_id, score) in enumerate(hybrid_recs, 1):
            print(f"{i}. Course ID: {course_id}, Score: {score:.2f}")
        
        # Get course details
        print("\nRecommended course details:")
        courses_df = pd.read_csv('UdemyCleanedTitle.csv')
        for course_id, score in hybrid_recs[:3]:  # Show details for top 3
            course = courses_df[courses_df['course_id'] == course_id]
            if not course.empty:
                course = course.iloc[0]
                print(f"\nCourse: {course['course_title']}")
                print(f"Subject: {course['subject']}")
                print(f"Level: {course['level']}")
                print(f"Price: ${course['price']}")
                print(f"Subscribers: {course['num_subscribers']}")
                print(f"Recommendation Score: {score:.2f}")
        
        print("\nRecommendation system is working correctly!")
        
    except Exception as e:
        print(f"Error testing recommendations: {str(e)}")
        import traceback
        traceback.print_exc()

# Test with a hardcoded user ID
USER_ID = "67d82564c981bf22fedc2ca5"  # Replace with your test user ID

def test_personalized_recommendations():
    url = f"http://localhost:5000/recommendations/personalized?user_id={USER_ID}"
    
    # Send the GET request
    response = requests.get(url)
    
    # Print the results
    print(f"Status code: {response.status_code}")
    print(f"Response headers: {response.headers}")
    
    # Try to parse the JSON response
    try:
        result = response.json()
        print(f"Success: {result.get('success', False)}")
        
        # Check for recommendations
        if 'recommendations' in result:
            recs = result['recommendations']
            print(f"Found {len(recs)} recommendations")
            if recs:
                print("First course:", recs[0].get('course_title', recs[0].get('title', 'Unknown')))
        elif 'personalized_recommendations' in result:
            recs = result['personalized_recommendations']
            print(f"Found {len(recs)} personalized_recommendations")
            if recs:
                print("First course:", recs[0].get('course_title', recs[0].get('title', 'Unknown')))
        else:
            print("No recommendations found")
        
        # Print raw response for debugging
        print("\nRaw response:")
        print(json.dumps(result, indent=2))
    except Exception as e:
        print(f"Error parsing response: {e}")
        print("Raw content:", response.content)

def test_collaborative_recommendations():
    url = f"http://localhost:5000/collaborative_recommendations?user_id={USER_ID}"
    
    # Send the GET request
    response = requests.get(url)
    
    # Print the results
    print(f"Status code: {response.status_code}")
    print(f"Response headers: {response.headers}")
    
    # Try to parse the JSON response
    try:
        result = response.json()
        print(f"Success: {result.get('success', False)}")
        
        # Check for recommendations
        if 'recommendations' in result:
            recs = result['recommendations']
            print(f"Found {len(recs)} recommendations")
            if recs:
                print("First course:", recs[0].get('course_title', recs[0].get('title', 'Unknown')))
        else:
            print("No recommendations found")
        
        # Print raw response for debugging
        print("\nRaw response:")
        print(json.dumps(result, indent=2))
    except Exception as e:
        print(f"Error parsing response: {e}")
        print("Raw content:", response.content)

def test_trending():
    url = "http://localhost:5000/api/trending"
    
    # Send the GET request
    response = requests.get(url)
    
    # Print the results
    print(f"Status code: {response.status_code}")
    
    # Try to parse the JSON response
    try:
        result = response.json()
        print(f"Success: {result.get('success', False)}")
        
        # Check for trending courses
        if 'trending' in result:
            trending = result['trending']
            print(f"Found {len(trending)} trending courses")
            if trending:
                print("First course:", trending[0].get('course_title', trending[0].get('title', 'Unknown')))
        else:
            print("No trending courses found")
        
        # Print raw response for debugging
        print("\nRaw response:")
        print(json.dumps(result, indent=2))
    except Exception as e:
        print(f"Error parsing response: {e}")
        print("Raw content:", response.content)

if __name__ == "__main__":
    print("=== Testing personalized recommendations ===")
    test_personalized_recommendations()
    
    print("\n=== Testing collaborative recommendations ===")
    test_collaborative_recommendations()
    
    print("\n=== Testing trending courses ===")
    test_trending() 