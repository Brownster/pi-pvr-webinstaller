#!/bin/bash
# Script to start the PI-PVR Web UI

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}PI-PVR Web UI Starter${NC}"
echo "=================================="

# Get script directory with support for symlinks
SCRIPT_DIR="$( cd -- "$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")")" &> /dev/null && pwd )"
WEB_UI_DIR="$SCRIPT_DIR/web-ui"
API_SCRIPT="$SCRIPT_DIR/scripts/api.py"

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

# Check for Python
if ! command -v python3 &>/dev/null; then
    echo -e "${YELLOW}Python not found. Installing...${NC}"
    sudo apt update
    sudo apt install -y python3 python3-pip
fi

# Install required Python packages
echo -e "${BLUE}Installing required Python packages...${NC}"
python3 -m pip install flask flask-cors psutil requests

# Start the API server
echo -e "${BLUE}Starting API server...${NC}"
if [ -f "$API_SCRIPT" ]; then
    # Check if API is already running
    if pgrep -f "python3 $API_SCRIPT" &>/dev/null; then
        echo -e "${YELLOW}API server is already running${NC}"
    else
        # Start API server in the background
        cd "$SCRIPT_DIR"
        python3 "$API_SCRIPT" &
        API_PID=$!
        echo -e "${GREEN}API server started with PID: $API_PID${NC}"
        
        # Save PID to file for later cleanup
        echo $API_PID > "$SCRIPT_DIR/.api_pid"
    fi
else
    echo -e "${RED}API script not found at $API_SCRIPT${NC}"
    exit 1
fi

# Get local IP address
SERVER_IP=$(hostname -I | awk '{print $1}')

# Print access instructions
echo -e "\n${GREEN}Web UI should now be accessible at:${NC}"
echo -e "${BLUE}http://${SERVER_IP}:8080${NC}"
echo -e "\n${YELLOW}Press Ctrl+C to stop the server${NC}"
echo "=================================="

# Keep script running to show logs
tail -f "$SCRIPT_DIR/logs/api.log" 2>/dev/null || sleep infinity