#!/bin/bash
# PI-PVR API Server Startup Script

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}PI-PVR API Server Starter${NC}"
echo "===================================="

# Get script directory with support for symlinks
SCRIPT_DIR="$( cd -- "$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")")" &> /dev/null && pwd )"
API_SCRIPT="$SCRIPT_DIR/scripts/api.py"

# Make sure Python is installed
if ! command -v python3 &>/dev/null; then
    echo -e "${RED}Python3 not found. Please install Python 3.${NC}"
    exit 1
fi

# Make sure pip is installed
if ! command -v pip3 &>/dev/null; then
    echo -e "${YELLOW}pip3 not found. Installing pip...${NC}"
    sudo apt-get update
    sudo apt-get install -y python3-pip
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install pip. Please install it manually.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}pip installed successfully!${NC}"
fi

# Make sure the API script exists
if [ ! -f "$API_SCRIPT" ]; then
    echo -e "${RED}API script not found at $API_SCRIPT${NC}"
    exit 1
fi

# Install requirements if needed
echo -e "${BLUE}Installing API server dependencies...${NC}"
pip3 install --user -r "$SCRIPT_DIR/requirements.txt"

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to install dependencies. Please check error messages above.${NC}"
    exit 1
fi

echo -e "${GREEN}Dependencies installed successfully!${NC}"

# Get local IP address
SERVER_IP=$(hostname -I | awk '{print $1}')

# Start the API server
echo -e "${BLUE}Starting PI-PVR API server...${NC}"
echo -e "${GREEN}API server will be available at:${NC} http://${SERVER_IP}:8080"
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
echo "===================================="

# Start the server
python3 "$API_SCRIPT"