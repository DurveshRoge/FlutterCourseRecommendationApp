#!/bin/bash

# Initialize Git LFS
git lfs install

# Track large files (add more extensions as needed)
git lfs track "*.csv"
git lfs track "*.zip"
git lfs track "*.pkl"
git lfs track "*.h5"

# Add all files to staging
git add .

# Commit changes
git commit -m "Updated repository with latest changes"

# Set the main branch
git branch -M main

# Push to GitHub with force flag
git push -f origin main

echo "Push completed!"
