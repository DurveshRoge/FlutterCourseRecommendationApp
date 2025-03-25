import requests
import json

BASE_URL = "http://localhost:5000"

def print_route_structure(route_name, response):
    print(f"\n=== {route_name} Route Structure ===")
    print(f"Status Code: {response.status_code}")
    data = response.json()
    print("Response Structure:")
    print(json.dumps(data, indent=2))
    print("=" * 50)

def test_main_recommendation():
    print("\nTesting main recommendation route...")
    response = requests.post(
        f"{BASE_URL}/",
        json={"course": "Python"}
    )
    print_route_structure("Main Recommendation", response)

def test_personalized_recommendations():
    print("\nTesting personalized recommendations...")
    response = requests.get(
        f"{BASE_URL}/recommendations/personalized",
        params={"email": "test@example.com"}
    )
    print_route_structure("Personalized Recommendations", response)

def test_search_courses():
    print("\nTesting search courses...")
    response = requests.get(
        f"{BASE_URL}/search",
        params={"query": "Python"}
    )
    print_route_structure("Search Courses", response)

def test_user_preferences():
    print("\nTesting user preferences...")
    # Test GET preferences
    response = requests.get(
        f"{BASE_URL}/user/preferences",
        params={"email": "test@example.com"}
    )
    print_route_structure("GET User Preferences", response)

    # Test POST preferences
    preferences_data = {
        "email": "test@example.com",
        "topics": ["Web Development", "Data Science"],
        "level": "Beginner",
        "type": "All",
        "duration": "Any",
        "popularity": "Medium"
    }
    response = requests.post(
        f"{BASE_URL}/user/preferences",
        json=preferences_data
    )
    print_route_structure("POST User Preferences", response)

def test_user_favorites():
    print("\nTesting user favorites...")
    # Test GET favorites
    response = requests.get(
        f"{BASE_URL}/user/favorites",
        params={"email": "test@example.com"}
    )
    print_route_structure("GET User Favorites", response)

    # Test POST favorites
    favorite_data = {
        "email": "test@example.com",
        "course_id": "123",
        "is_favorite": True
    }
    response = requests.post(
        f"{BASE_URL}/user/favorites",
        json=favorite_data
    )
    print_route_structure("POST User Favorites", response)

def main():
    print("Starting API route tests...")
    
    # Test all routes
    test_main_recommendation()
    test_personalized_recommendations()
    test_search_courses()
    test_user_preferences()
    test_user_favorites()
    
    print("\nAll tests completed!")

if __name__ == "__main__":
    main() 