#!/bin/bash
# Simple Web UI startup script for PI-PVR
# This script provides a reliable way to start the web UI

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}PI-PVR Simple Web UI Starter${NC}"
echo "===================================="

# Get script directory with support for symlinks
SCRIPT_DIR="$( cd -- "$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")")" &> /dev/null && pwd )"
WEB_UI_DIR="$SCRIPT_DIR/web-ui"

# Make sure Node.js is installed
if ! command -v npm &>/dev/null; then
    echo -e "${YELLOW}Node.js not found. Installing Node.js via NVM...${NC}"
    # Install NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    
    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install Node.js LTS version
    nvm install --lts
    nvm use --lts
    
    # Verify Node.js is installed
    if ! command -v node &>/dev/null; then
        echo -e "${RED}Failed to install Node.js. Please install it manually.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Node.js installed successfully!${NC}"
fi

# Make sure web-ui directory exists
if [ ! -d "$WEB_UI_DIR" ]; then
    echo -e "${RED}Web UI directory not found at $WEB_UI_DIR${NC}"
    exit 1
fi

# Install dependencies if needed
if [ ! -d "$WEB_UI_DIR/node_modules" ]; then
    echo -e "${BLUE}Installing web UI dependencies...${NC}"
    cd "$WEB_UI_DIR" && npm install
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install dependencies. Please check error messages above.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Dependencies installed successfully!${NC}"
fi

# Get local IP address
SERVER_IP=$(hostname -I | awk '{print $1}')

# Start the web UI server
echo -e "${BLUE}Starting PI-PVR Web UI server...${NC}"
echo -e "${GREEN}Web UI will be available at:${NC} http://${SERVER_IP}:8080"
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
echo "===================================="

# Start the server
cd "$WEB_UI_DIR" && npm start