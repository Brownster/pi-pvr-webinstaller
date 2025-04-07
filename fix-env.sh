#!/bin/bash
# Emergency script to fix corrupted .env file

# Define .env file location
ENV_FILE="$HOME/docker/.env"

echo "PI-PVR Emergency Configuration Fix"
echo "=================================="
echo 

# Force remove the file
if [[ -f "$ENV_FILE" ]]; then
    echo "Found corrupted .env file at $ENV_FILE"
    echo "Removing file..."
    rm -f "$ENV_FILE"
    echo "Corrupted .env file has been removed."
else
    echo "No .env file found at $ENV_FILE"
fi

echo
echo "Environment cleanup complete."
echo "Now you can run ./start.sh again and select option 2."
echo "=================================="