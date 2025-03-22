import requests
import json

# Test the search endpoint
def test_search():
    url = "http://localhost:5000/"
    data = {"course": "python"}
    
    # Send the POST request
    response = requests.post(url, json=data)
    
    # Print the results
    print(f"Status code: {response.status_code}")
    print(f"Response headers: {response.headers}")
    
    # Try to parse the JSON response
    try:
        result = response.json()
        print(f"Success: {result.get('success', False)}")
        print(f"Query: {result.get('query', '')}")
        
        # Check for recommendations or search results
        if 'recommendations' in result:
            recs = result['recommendations']
            print(f"Found {len(recs)} recommendations")
            if recs:
                print("First course:", recs[0].get('course_title', recs[0].get('title', 'Unknown')))
        elif 'search_results' in result:
            results = result['search_results']
            print(f"Found {len(results)} search results")
            if results:
                print("First course:", results[0].get('course_title', results[0].get('title', 'Unknown')))
        else:
            print("No recommendations or search results found")
        
        # Print raw response for debugging
        print("\nRaw response:")
        print(json.dumps(result, indent=2))
    except Exception as e:
        print(f"Error parsing response: {e}")
        print("Raw content:", response.content)

if __name__ == "__main__":
    test_search() 