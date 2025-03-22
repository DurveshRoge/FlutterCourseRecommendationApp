import pandas as pd
import numpy as np
import os
import pickle
from collections import defaultdict

# Check for required libraries and install if missing
try:
    from surprise import Dataset, Reader, SVD, KNNBasic, accuracy
    from surprise.model_selection import train_test_split, GridSearchCV, cross_validate
except ImportError:
    print("The 'surprise' library is required but not installed.")
    print("Installing required packages...")
    import subprocess
    subprocess.check_call(["pip", "install", "scikit-surprise", "scikit-learn"])
    from surprise import Dataset, Reader, SVD, KNNBasic, accuracy
    from surprise.model_selection import train_test_split, GridSearchCV, cross_validate

try:
    from sklearn.metrics import precision_score, recall_score
except ImportError:
    print("Installing scikit-learn...")
    import subprocess
    subprocess.check_call(["pip", "install", "scikit-learn"])
    from sklearn.metrics import precision_score, recall_score

def precision_recall_at_k(predictions, k=10, threshold=3.5):
    """
    Compute precision and recall at k for predictions
    """
    user_est_true = defaultdict(list)
    for uid, _, true_r, est, _ in predictions:
        user_est_true[uid].append((est, true_r))

    precisions = dict()
    recalls = dict()

    for uid, user_ratings in user_est_true.items():
        user_ratings.sort(key=lambda x: x[0], reverse=True)
        n_rel = sum((true_r >= threshold) for (_, true_r) in user_ratings)
        n_rec_k = sum((est >= threshold) for (est, _) in user_ratings[:k])
        n_rel_and_rec_k = sum(((true_r >= threshold) and (est >= threshold))
                              for (est, true_r) in user_ratings[:k])
        
        precisions[uid] = n_rel_and_rec_k / n_rec_k if n_rec_k != 0 else 0
        recalls[uid] = n_rel_and_rec_k / n_rel if n_rel != 0 else 0

    return np.mean(list(precisions.values())), np.mean(list(recalls.values()))

def train_collaborative_filtering_models(perform_hyperparameter_tuning=False):
    """
    Train collaborative filtering models (SVD and KNN) on user interactions.
    Includes hyperparameter tuning and comprehensive evaluation.
    """
    print("Loading user interactions...")
    if not os.path.exists('user_interactions.csv'):
        print("User interactions file not found. Generating fake interactions...")
        from generate_user_interactions import generate_user_interactions
        interactions_df = generate_user_interactions()
    else:
        interactions_df = pd.read_csv('user_interactions.csv')
    
    print(f"Loaded {len(interactions_df)} interactions")
    
    # Create a Surprise dataset
    reader = Reader(rating_scale=(1, 5))
    data = Dataset.load_from_df(interactions_df[['user_id', 'course_id', 'rating']], reader)
    
    if perform_hyperparameter_tuning:
        print("Performing hyperparameter tuning (this may take a while)...")
        # SVD parameter grid
        svd_param_grid = {
            'n_factors': [50, 100],
            'n_epochs': [20],
            'lr_all': [0.005],
            'reg_all': [0.02, 0.04]
        }
        
        # KNN parameter grid
        knn_param_grid = {
            'k': [20, 40],
            'min_k': [1],
            'sim_options': {
                'name': ['pearson_baseline', 'cosine'],
                'user_based': [False]
            }
        }
        
        # Perform grid search for SVD
        gs_svd = GridSearchCV(SVD, svd_param_grid, measures=['rmse'], cv=3)
        gs_svd.fit(data)
        
        # Perform grid search for KNN
        gs_knn = GridSearchCV(KNNBasic, knn_param_grid, measures=['rmse'], cv=3)
        gs_knn.fit(data)
        
        # Get best parameters
        svd_best_params = gs_svd.best_params['rmse']
        knn_best_params = gs_knn.best_params['rmse']
        
        # Initialize models with best parameters
        svd_model = SVD(**svd_best_params)
        knn_model = KNNBasic(**knn_best_params)
        
        print(f"Best SVD parameters: {svd_best_params}")
        print(f"Best KNN parameters: {knn_best_params}")
    else:
        # Use default parameters
        print("Using default model parameters...")
        svd_model = SVD(n_factors=100, n_epochs=20, lr_all=0.005, reg_all=0.02)
        knn_model = KNNBasic(k=40, min_k=1, sim_options={'name': 'pearson_baseline', 'user_based': False})
    
    # Split data for final evaluation
    trainset, testset = train_test_split(data, test_size=0.2, random_state=42)
    
    # Train models
    print("Training models...")
    svd_model.fit(trainset)
    knn_model.fit(trainset)
    
    # Comprehensive evaluation
    print("Performing evaluation...")
    
    # Test set evaluation
    svd_predictions = svd_model.test(testset)
    knn_predictions = knn_model.test(testset)
    
    # Calculate precision and recall at k
    svd_precision, svd_recall = precision_recall_at_k(svd_predictions, k=10)
    knn_precision, knn_recall = precision_recall_at_k(knn_predictions, k=10)
    
    print("\nTest set metrics:")
    print(f"SVD - RMSE: {accuracy.rmse(svd_predictions):.4f}")
    print(f"SVD - MAE: {accuracy.mae(svd_predictions):.4f}")
    print(f"SVD - Precision@10: {svd_precision:.4f}")
    print(f"SVD - Recall@10: {svd_recall:.4f}")
    
    print(f"KNN - RMSE: {accuracy.rmse(knn_predictions):.4f}")
    print(f"KNN - MAE: {accuracy.mae(knn_predictions):.4f}")
    print(f"KNN - Precision@10: {knn_precision:.4f}")
    print(f"KNN - Recall@10: {knn_recall:.4f}")
    
    # Save models and mappings
    print("Saving models and mappings...")
    with open('svd_model.pkl', 'wb') as f:
        pickle.dump(svd_model, f)
    
    with open('knn_model.pkl', 'wb') as f:
        pickle.dump(knn_model, f)
    
    # Create and save course mappings
    course_ids = interactions_df['course_id'].unique()
    course_to_idx = {course_id: i for i, course_id in enumerate(course_ids)}
    
    with open('course_mapping.pkl', 'wb') as f:
        pickle.dump(course_to_idx, f)
    
    # Save the enhanced recommendation function
    with open('recommendation_functions.py', 'w') as f:
        f.write("""
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
    \"\"\"Get content-based similar courses using course features\"\"\"
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
    \"\"\"Get hybrid recommendations combining collaborative and content-based filtering\"\"\"
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
    \"\"\"Get top N recommendations for a user using collaborative filtering\"\"\"
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
""")
    
    print("Enhanced recommendation functions saved to recommendation_functions.py")
    return svd_model, knn_model, course_to_idx

if __name__ == "__main__":
    print("Starting collaborative filtering model training...")
    try:
        train_collaborative_filtering_models(perform_hyperparameter_tuning=False)
        print("Training completed successfully!")
    except Exception as e:
        print(f"Error during training: {str(e)}")
        import traceback
        traceback.print_exc() 