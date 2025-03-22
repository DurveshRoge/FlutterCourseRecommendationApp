import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta
import json
import os

# Set random seed for reproducibility
np.random.seed(42)
random.seed(42)

def generate_user_interactions(num_users=500, interactions_per_user_range=(5, 30)):
    """
    Generate fake user interactions for collaborative filtering.
    
    Args:
        num_users: Number of fake users to generate
        interactions_per_user_range: Range of interactions per user (min, max)
    
    Returns:
        DataFrame with user interactions
    """
    print("Loading course data...")
    # Check if the course data exists
    if not os.path.exists('UdemyCleanedTitle.csv'):
        print("Error: UdemyCleanedTitle.csv not found!")
        print("Please make sure the course data file is in the current directory.")
        return None
    
    # Load the course data
    try:
        courses_df = pd.read_csv('UdemyCleanedTitle.csv')
    except Exception as e:
        print(f"Error loading course data: {str(e)}")
        return None
    
    # Extract course IDs
    course_ids = courses_df['course_id'].unique()
    
    print(f"Found {len(course_ids)} unique courses")
    
    # Generate fake user data
    print(f"Generating {num_users} fake users...")
    users = []
    for i in range(1, num_users + 1):
        user_id = f"user_{i}"
        name = f"User {i}"
        email = f"user{i}@example.com"
        
        users.append({
            "user_id": user_id,
            "name": name,
            "email": email
        })
    
    # Generate interactions
    print("Generating user interactions...")
    interactions = []
    
    for user in users:
        # Randomly decide how many interactions this user will have
        num_interactions = random.randint(*interactions_per_user_range)
        
        # Randomly select courses for this user
        selected_courses = random.sample(list(course_ids), min(num_interactions, len(course_ids)))
        
        for course_id in selected_courses:
            # Generate a random rating (1-5)
            rating = random.randint(1, 5)
            
            # Higher ratings have higher chance of being favorited
            is_favorite = random.random() < (rating / 10)  # 10-50% chance based on rating
            
            # Generate a random timestamp within the last year
            days_ago = random.randint(1, 365)
            timestamp = (datetime.now() - timedelta(days=days_ago)).isoformat()
            
            interactions.append({
                "user_id": user["user_id"],
                "course_id": course_id,
                "rating": rating,
                "is_favorite": is_favorite,
                "timestamp": timestamp
            })
    
    # Convert to DataFrame
    interactions_df = pd.DataFrame(interactions)
    
    print(f"Generated {len(interactions)} interactions for {num_users} users")
    
    # Save users to JSON
    with open('fake_users.json', 'w') as f:
        json.dump(users, f)
    
    # Save interactions to CSV
    interactions_df.to_csv('user_interactions.csv', index=False)
    
    return interactions_df

if __name__ == "__main__":
    try:
        print("Starting user interactions generation...")
        interactions_df = generate_user_interactions()
        
        if interactions_df is not None:
            # Print some statistics
            print("\nInteraction Statistics:")
            print(f"Total interactions: {len(interactions_df)}")
            print(f"Unique users: {interactions_df['user_id'].nunique()}")
            print(f"Unique courses: {interactions_df['course_id'].nunique()}")
            print(f"Average rating: {interactions_df['rating'].mean():.2f}")
            print(f"Favorited courses: {interactions_df['is_favorite'].sum()} ({interactions_df['is_favorite'].mean()*100:.2f}%)")
            print("\nUser interactions generated successfully!")
    except Exception as e:
        print(f"Error generating user interactions: {str(e)}")
        import traceback
        traceback.print_exc() 