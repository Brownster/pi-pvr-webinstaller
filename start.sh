#!/bin/bash
# PI-PVR Ultimate Media Stack - Startup Script

# Set colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print banner
echo -e "${BLUE}"
echo "  _____   _____       _____  __      __  _____    "
echo " |  __ \ |_   _|     |  __ \ \ \    / / |  __ \   "
echo " | |__) |  | |       | |__) | \ \  / /  | |__) |  "
echo " |  ___/   | |       |  ___/   \ \/ /   |  _  /   "
echo " | |      _| |_      | |        \  /    | | \ \   "
echo " |_|     |_____|     |_|         \/     |_|  \_\  "
echo "                                                  "
echo -e "${GREEN}      Ultimate Media Stack Installer${NC}"
echo ""

# Check for dependencies
check_dep() {
  if ! command -v $1 &> /dev/null; then
    echo -e "${RED}[ERROR]${NC} $1 is required but not installed."
    echo -e "       Run: ${YELLOW}sudo apt install $2${NC}"
    return 1
  else
    echo -e "${GREEN}[OK]${NC} $1 is installed."
    return 0
  fi
}

echo "Checking dependencies..."
DEPS_MISSING=0

check_dep "docker" "docker.io" || DEPS_MISSING=1
check_dep "python3" "python3" || DEPS_MISSING=1
check_dep "pip3" "python3-pip" || DEPS_MISSING=1

if [ $DEPS_MISSING -eq 1 ]; then
  echo ""
  echo -e "${YELLOW}Would you like to automatically install missing dependencies? (y/n)${NC}"
  read -r INSTALL_DEPS
  if [[ "$INSTALL_DEPS" =~ ^[Yy]$ ]]; then
    echo "Installing dependencies..."
    sudo apt update
    if ! command -v docker &> /dev/null; then
      echo "Installing Docker..."
      curl -fsSL https://get.docker.com | sh
    fi
    if ! command -v python3 &> /dev/null; then
      echo "Installing Python3..."
      sudo apt install -y python3
    fi
    if ! command -v pip3 &> /dev/null; then
      echo "Installing pip3..."
      sudo apt install -y python3-pip
    fi
  else
    echo -e "${RED}Please install the missing dependencies and try again.${NC}"
    exit 1
  fi
fi

# Check Python packages
echo "Checking Python packages..."
if ! pip3 show flask &> /dev/null || ! pip3 show flask_cors &> /dev/null || ! pip3 show psutil &> /dev/null; then
  echo -e "${YELLOW}Installing required Python packages...${NC}"
  pip3 install --user -r requirements.txt
fi

# Make scripts executable
chmod +x pi-pvr.sh
chmod +x web-install.sh
chmod +x scripts/generate-compose.sh
chmod +x scripts/api.py

# Present options
echo ""
echo -e "${BLUE}Choose installation method:${NC}"
echo "1) Terminal-based installation"
echo "2) Web-based installation (recommended)"
echo "3) Exit"
read -r CHOICE

case $CHOICE in
  1)
    echo "Starting terminal-based installation..."
    ./pi-pvr.sh
    ;;
  2)
    echo "Starting web-based installation..."
    ./web-install.sh
    ;;
  3)
    echo "Exiting."
    exit 0
    ;;
  *)
    echo -e "${RED}Invalid choice. Exiting.${NC}"
    exit 1
    ;;
esac