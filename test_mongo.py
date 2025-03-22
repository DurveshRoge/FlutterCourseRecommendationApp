from flask import Flask
from flask_pymongo import PyMongo
import pymongo
import sys

# Create a simple Flask app
app = Flask(__name__)

# Configure MongoDB connection
app.config["MONGO_URI"] = "mongodb+srv://Durveshroge:durvesh123@cluster0.kxdlj.mongodb.net/Udemydatabase?retryWrites=true&w=majority&appName=Cluster0"

try:
    # Initialize PyMongo
    mongo = PyMongo(app)
    
    # Print connection information
    print("Connection successful!")
    print(f"Database name: {mongo.db.name}")
    
    # List all collections in the database
    collections = mongo.db.list_collection_names()
    print(f"Collections in {mongo.db.name}: {collections}")
    
    # Try to access the users collection
    users_count = mongo.db.users.count_documents({})
    print(f"Number of documents in users collection: {users_count}")
    
    # Try direct connection with pymongo
    print("\nTrying direct connection with pymongo...")
    client = pymongo.MongoClient("mongodb+srv://Durveshroge:durvesh123@cluster0.kxdlj.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0")
    
    # List all databases
    print("Available databases:")
    for db_name in client.list_database_names():
        print(f"- {db_name}")
        
except Exception as e:
    print(f"Error connecting to MongoDB: {e}", file=sys.stderr) 