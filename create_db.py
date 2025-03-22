import pymongo
from flask_bcrypt import Bcrypt
from flask import Flask

# Create Flask app for bcrypt
app = Flask(__name__)
bcrypt = Bcrypt(app)

# Connect to MongoDB
client = pymongo.MongoClient("mongodb+srv://Durveshroge:durvesh123@cluster0.kxdlj.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0")

# Access the Udemydatabase
db = client["Udemydatabase"]

# Check if users collection exists and is empty
users_count = db.users.count_documents({})
print(f"Current users in database: {users_count}")

if users_count == 0:
    # Create a test user
    hashed_password = bcrypt.generate_password_hash("testpassword123").decode('utf-8')
    test_user = {
        "name": "Test User",
        "email": "test@example.com",
        "password": hashed_password,
        "favorites": []
    }
    
    # Insert the test user
    result = db.users.insert_one(test_user)
    
    if result.acknowledged:
        print(f"Test user created with ID: {result.inserted_id}")
        print("The Udemydatabase should now be visible in MongoDB Atlas!")
    else:
        print("Failed to insert test user")
else:
    print("Users collection already has documents. No need to create test user.")

# Verify the database now exists
print("\nAvailable databases:")
for db_name in client.list_database_names():
    print(f"- {db_name}")

# List collections in Udemydatabase
collections = db.list_collection_names()
print(f"\nCollections in Udemydatabase: {collections}")

# Close the connection
client.close() 