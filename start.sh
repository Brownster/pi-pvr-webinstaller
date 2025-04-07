#!/bin/bash
# PI-PVR Ultimate Media Stack Starter Script

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Display header
echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                    ║${NC}"
echo -e "${GREEN}║   🐳 PI-PVR Ultimate Media Stack Installer 🐳    ║${NC}"
echo -e "${GREEN}║                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if the pi-pvr.sh script exists
if [ ! -f "$SCRIPT_DIR/pi-pvr.sh" ]; then
    echo -e "${YELLOW}Error: pi-pvr.sh not found in the current directory!${NC}"
    exit 1
fi

# Make the script executable
chmod +x "$SCRIPT_DIR/pi-pvr.sh"

# Display menu options
echo -e "${BLUE}Please choose an option:${NC}"
echo ""
echo "1) Command Line Installation"
echo "2) Web UI Only"
echo "3) API Server Only"
echo "4) Complete Web Interface (API + UI)"
echo "5) Remote Installation"
echo "6) Update Existing Installation"
echo "7) Reset Configuration (Fix Errors)"
echo "8) Exit"
echo ""

# Read user choice
read -p "Enter your choice (1-8): " choice

# Process user choice
case $choice in
    1)
        echo -e "${GREEN}Starting Command Line Installation...${NC}"
        "$SCRIPT_DIR/pi-pvr.sh"
        ;;
    2)
        echo -e "${GREEN}Starting Web UI...${NC}"
        "$SCRIPT_DIR/pi-pvr.sh" --web-ui
        ;;
    3)
        echo -e "${GREEN}Starting API Server...${NC}"
        "$SCRIPT_DIR/pi-pvr.sh" --api-server
        ;;
    4)
        echo -e "${GREEN}Starting Complete Web Interface (API + UI)...${NC}"
        "$SCRIPT_DIR/pi-pvr.sh" --complete-ui
        ;;
    5)
        echo -e "${GREEN}Starting Remote Installation...${NC}"
        echo -e "${YELLOW}This feature is coming soon.${NC}"
        sleep 2
        "$SCRIPT_DIR/start.sh"
        ;;
    6)
        echo -e "${GREEN}Updating Existing Installation...${NC}"
        "$SCRIPT_DIR/pi-pvr.sh" --update
        ;;
    7)
        echo -e "${GREEN}Resetting Configuration...${NC}"
        "$SCRIPT_DIR/pi-pvr.sh" --reset-env
        sleep 2
        "$SCRIPT_DIR/start.sh"
        ;;
    8)
        echo -e "${GREEN}Exiting. Thank you for using PI-PVR Ultimate Media Stack!${NC}"
        exit 0
        ;;
    *)
        echo -e "${YELLOW}Invalid choice. Please try again.${NC}"
        sleep 2
        "$SCRIPT_DIR/start.sh"
        ;;
esac