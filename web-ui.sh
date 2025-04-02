#!/bin/bash
# PI-PVR Web UI Starter Script

# Define the web UI directory
WEB_UI_DIR="$(dirname "$(readlink -f "$0")")/web-ui"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "Node.js is not installed. Installing..."
    # Install NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    # Source NVM to use it
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    # Install Node.js LTS
    nvm install --lts
    nvm use --lts
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "npm is not installed. Please install Node.js and npm."
    exit 1
fi

# Check if dependencies are installed
if [ ! -d "$WEB_UI_DIR/node_modules" ]; then
    echo "Installing dependencies..."
    cd "$WEB_UI_DIR" && npm install
fi

# Start the web UI server
echo "Starting PI-PVR Web UI..."
echo "Access the UI at http://localhost:8080"
cd "$WEB_UI_DIR" && npm start