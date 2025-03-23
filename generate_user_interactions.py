import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta
import json
import os
from collections import defaultdict

# Set random seed for reproducibility
np.random.seed(42)
random.seed(42)

def generate_user_interactions(num_users=500, interactions_per_user_range=(5, 20), subjects_per_user_range=(1, 3)):
    """
    Generate fake user interactions for collaborative filtering.
    Users will primarily interact with courses in their preferred subject domains.
    
    Args:
        num_users: Number of fake users to generate
        interactions_per_user_range: Range of interactions per user (min, max)
        subjects_per_user_range: How many subject domains a user is interested in (min, max)
    
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
        print(f"Loaded {len(courses_df)} courses")
        
        # Ensure required columns exist
        required_columns = ['course_id', 'course_title', 'subject']
        for col in required_columns:
            if col not in courses_df.columns:
                print(f"Error: Required column '{col}' not found in dataset!")
                return None
        
    except Exception as e:
        print(f"Error loading course data: {str(e)}")
        return None
    
    # Group courses by subject domain
    subject_to_courses = defaultdict(list)
    for _, course in courses_df.iterrows():
        subject = course['subject']
        if pd.notna(subject) and subject != '':
            subject_to_courses[subject].append(course['course_id'])
    
    # Filter out subjects with too few courses
    min_courses_per_subject = 5
    valid_subjects = {subj: courses for subj, courses in subject_to_courses.items() 
                      if len(courses) >= min_courses_per_subject}
    
    print(f"Found {len(valid_subjects)} subject domains with at least {min_courses_per_subject} courses each")
    
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
    user_subject_summary = {}
    
    for user in users:
        # Randomly decide how many subject domains this user is interested in
        num_subjects = random.randint(*subjects_per_user_range)
        
        # Randomly select subjects for this user
        if len(valid_subjects) > 0:
            user_subjects = random.sample(list(valid_subjects.keys()), 
                                        min(num_subjects, len(valid_subjects)))
        else:
            print("Error: No valid subjects found!")
            return None
        
        # Store which subjects each user is interested in (for reporting)
        user_subject_summary[user['user_id']] = user_subjects
        
        # Decide how many interactions this user will have
        num_interactions = random.randint(*interactions_per_user_range)
        
        # Collect all courses from user's preferred subjects
        available_courses = []
        for subject in user_subjects:
            available_courses.extend(valid_subjects[subject])
        
        # Handle case when there aren't enough courses in preferred subjects
        if len(available_courses) < num_interactions:
            # Add some courses from other subjects (with 20% probability for diversity)
            other_courses = []
            for subj, courses in valid_subjects.items():
                if subj not in user_subjects:
                    other_courses.extend(courses)
            
            # Add up to 20% additional courses from other domains
            additional_needed = min(num_interactions - len(available_courses), 
                                   int(num_interactions * 0.2))
            if additional_needed > 0 and other_courses:
                additional_courses = random.sample(other_courses, 
                                                 min(additional_needed, len(other_courses)))
                available_courses.extend(additional_courses)
        
        # If we still don't have enough, reduce the number of interactions
        actual_interactions = min(num_interactions, len(available_courses))
        
        # Ensure we don't pick the same course twice
        if actual_interactions > 0:
            selected_courses = random.sample(available_courses, actual_interactions)
            
            for course_id in selected_courses:
                # Find the subject of this course
                course_subject = None
                for subj, courses in subject_to_courses.items():
                    if course_id in courses:
                        course_subject = subj
                        break
                
                # Generate a random rating with bias toward preferred subjects
                if course_subject in user_subjects:
                    # Preferred subjects get higher ratings (3-5)
                    rating = random.choices([3, 4, 5], weights=[0.2, 0.3, 0.5])[0]
                    # Higher chance of being favorited
                    is_favorite = random.random() < (rating / 7.5)  # ~40-67% chance
                else:
                    # Non-preferred subjects get lower ratings (1-4)
                    rating = random.choices([1, 2, 3, 4], weights=[0.2, 0.3, 0.3, 0.2])[0]
                    # Lower chance of being favorited
                    is_favorite = random.random() < (rating / 15)  # ~7-27% chance
                
                # Generate a random timestamp within the last year
                days_ago = random.randint(1, 365)
                timestamp = (datetime.now() - timedelta(days=days_ago)).isoformat()
                
                interactions.append({
                    "user_id": user["user_id"],
                    "course_id": int(course_id),  # Ensure it's an integer
                    "rating": rating,
                    "is_favorite": bool(is_favorite),  # Ensure it's a boolean
                    "timestamp": timestamp,
                    "subject": course_subject  # Include subject for analysis
                })
    
    # Convert to DataFrame
    interactions_df = pd.DataFrame(interactions)
    
    print(f"Generated {len(interactions)} interactions for {num_users} users")
    
    # Save users to JSON
    with open('fake_users.json', 'w') as f:
        json.dump(users, f)
    
    # Save user subject preferences for analysis
    with open('user_subject_preferences.json', 'w') as f:
        json.dump(user_subject_summary, f)
    
    # Save interactions to CSV
    interactions_df.to_csv('user_interactions.csv', index=False)
    
    return interactions_df, user_subject_summary

def analyze_interactions(interactions_df, user_subject_summary):
    """
    Analyze the generated interactions to verify domain consistency.
    """
    print("\n--- INTERACTION ANALYSIS ---")
    
    # Basic statistics
    print(f"Total interactions: {len(interactions_df)}")
    print(f"Unique users: {interactions_df['user_id'].nunique()}")
    print(f"Unique courses: {interactions_df['course_id'].nunique()}")
    print(f"Average rating: {interactions_df['rating'].mean():.2f}")
    print(f"Favorited courses: {interactions_df['is_favorite'].sum()} ({interactions_df['is_favorite'].mean()*100:.2f}%)")
    
    # Domain consistency analysis
    domain_consistency = {}
    for user_id, preferred_subjects in user_subject_summary.items():
        # Get all interactions for this user
        user_interactions = interactions_df[interactions_df['user_id'] == user_id]
        
        # Count interactions by subject
        subject_counts = user_interactions['subject'].value_counts().to_dict()
        
        # Calculate what percentage of interactions are with preferred subjects
        preferred_count = sum(count for subj, count in subject_counts.items() 
                             if subj in preferred_subjects)
        total_count = len(user_interactions)
        
        if total_count > 0:
            consistency = (preferred_count / total_count) * 100
        else:
            consistency = 0
            
        domain_consistency[user_id] = consistency
    
    # Calculate average domain consistency
    avg_consistency = np.mean(list(domain_consistency.values()))
    print(f"Domain consistency: {avg_consistency:.2f}% (higher = more interactions within preferred domains)")
    
    # Subject distribution
    subject_distribution = interactions_df['subject'].value_counts()
    print("\nTop 10 most popular subjects:")
    print(subject_distribution.head(10))
    
    # Rating analysis by preferred vs non-preferred
    avg_rating_preferred = []
    avg_rating_nonpreferred = []
    
    for user_id, preferred_subjects in user_subject_summary.items():
        user_interactions = interactions_df[interactions_df['user_id'] == user_id]
        
        for _, interaction in user_interactions.iterrows():
            if interaction['subject'] in preferred_subjects:
                avg_rating_preferred.append(interaction['rating'])
            else:
                avg_rating_nonpreferred.append(interaction['rating'])
    
    if avg_rating_preferred:
        print(f"\nAverage rating for courses in preferred domains: {np.mean(avg_rating_preferred):.2f}")
    if avg_rating_nonpreferred:
        print(f"Average rating for courses outside preferred domains: {np.mean(avg_rating_nonpreferred):.2f}")

if __name__ == "__main__":
    try:
        print("Starting user interactions generation...")
        interactions_df, user_subject_summary = generate_user_interactions()
        
        if interactions_df is not None:
            analyze_interactions(interactions_df, user_subject_summary)
            print("\nUser interactions generated successfully!")
    except Exception as e:
        print(f"Error generating user interactions: {str(e)}")
        import traceback
        traceback.print_exc()