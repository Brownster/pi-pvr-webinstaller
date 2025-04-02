#!/bin/bash
# PI-PVR Ultimate Media Stack - Startup Script

# Set colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

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

# Detect system information
echo "Detecting system information..."
if [[ -x "$SCRIPT_DIR/scripts/detect-system.sh" ]]; then
  SYSTEM_INFO=$(bash "$SCRIPT_DIR/scripts/detect-system.sh")
  
  # Extract architecture
  ARCH=$(echo "$SYSTEM_INFO" | grep -o '"architecture": "[^"]*"' | cut -d'"' -f4)
  
  # Extract OS information
  OS_NAME=$(echo "$SYSTEM_INFO" | grep -o '"name": "[^"]*"' | head -n1 | cut -d'"' -f4)
  OS_VERSION=$(echo "$SYSTEM_INFO" | grep -o '"version": "[^"]*"' | head -n1 | cut -d'"' -f4)
  
  # Extract Raspberry Pi information
  IS_RASPBERRY_PI=$(echo "$SYSTEM_INFO" | grep -o '"is_raspberry_pi": [^,]*' | cut -d' ' -f2)
  PI_MODEL=$(echo "$SYSTEM_INFO" | grep -o '"model": "[^"]*"' | head -n1 | cut -d'"' -f4)
  
  # Extract memory
  MEM_TOTAL=$(echo "$SYSTEM_INFO" | grep -o '"total_gb": [^,]*' | cut -d' ' -f2)
  
  # Display system information
  echo -e "${BLUE}System Information:${NC}"
  echo -e "  Architecture: ${GREEN}$ARCH${NC}"
  echo -e "  OS: ${GREEN}$OS_NAME $OS_VERSION${NC}"
  if [ "$IS_RASPBERRY_PI" = "true" ]; then
    echo -e "  Device: ${GREEN}$PI_MODEL${NC}"
  fi
  echo -e "  Memory: ${GREEN}${MEM_TOTAL}GB${NC}"
  echo ""
  
  # Check minimum requirements
  REQUIREMENTS_MET=true
  REQUIREMENTS_WARNINGS=""
  
  # Check memory
  if (( $(echo "$MEM_TOTAL < 2" | bc -l) )); then
    REQUIREMENTS_MET=false
    REQUIREMENTS_WARNINGS+="  - Insufficient memory: ${RED}${MEM_TOTAL}GB${NC} (minimum 2GB recommended)\n"
  fi
  
  # If requirements not met, show warning
  if [ "$REQUIREMENTS_MET" = "false" ]; then
    echo -e "${YELLOW}Warning: Your system does not meet the minimum requirements:${NC}"
    echo -e "$REQUIREMENTS_WARNINGS"
    echo -e "${YELLOW}You can still continue, but performance may be affected.${NC}"
    echo -e "${YELLOW}Continue anyway? (y/n)${NC}"
    read -r CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
      echo "Installation aborted."
      exit 1
    fi
  fi
fi

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
    
    # Detect package manager
    if command -v apt &> /dev/null; then
      PKG_MANAGER="apt"
    elif command -v dnf &> /dev/null; then
      PKG_MANAGER="dnf"
    elif command -v yum &> /dev/null; then
      PKG_MANAGER="yum"
    else
      echo -e "${RED}Unsupported package manager. Please install dependencies manually.${NC}"
      exit 1
    fi
    
    # Install dependencies based on package manager
    case $PKG_MANAGER in
      apt)
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
        ;;
      dnf|yum)
        if ! command -v docker &> /dev/null; then
          echo "Installing Docker..."
          curl -fsSL https://get.docker.com | sh
        fi
        if ! command -v python3 &> /dev/null; then
          echo "Installing Python3..."
          sudo $PKG_MANAGER install -y python3
        fi
        if ! command -v pip3 &> /dev/null; then
          echo "Installing pip3..."
          sudo $PKG_MANAGER install -y python3-pip
        fi
        ;;
    esac
  else
    echo -e "${RED}Please install the missing dependencies and try again.${NC}"
    exit 1
  fi
fi

# Check Python packages
echo "Checking Python packages..."
if ! python3 -c "import flask" &> /dev/null || ! python3 -c "import flask_cors" &> /dev/null || ! python3 -c "import psutil" &> /dev/null; then
  echo -e "${YELLOW}Installing required Python packages...${NC}"
  pip3 install --user -r "$SCRIPT_DIR/requirements.txt"
fi

# Make scripts executable
chmod +x "$SCRIPT_DIR/pi-pvr.sh"
chmod +x "$SCRIPT_DIR/web-install.sh"
chmod +x "$SCRIPT_DIR/scripts/generate-compose.sh"
chmod +x "$SCRIPT_DIR/scripts/api.py"
chmod +x "$SCRIPT_DIR/scripts/detect-system.sh"
chmod +x "$SCRIPT_DIR/scripts/remote-installer.sh"

# Present options
echo ""
echo -e "${BLUE}Choose installation method:${NC}"
echo "1) Terminal-based installation"
echo "2) Web-based installation (recommended)"
echo "3) Remote installation"
echo "4) Exit"
read -r CHOICE

case $CHOICE in
  1)
    echo "Starting terminal-based installation..."
    "$SCRIPT_DIR/pi-pvr.sh"
    ;;
  2)
    echo "Starting web-based installation..."
    "$SCRIPT_DIR/web-install.sh"
    ;;
  3)
    echo "Starting remote installation..."
    # Prompt for remote details
    echo -e "${BLUE}Remote Installation Setup${NC}"
    echo -e "Please enter the details of the remote system:"
    
    read -p "Remote username: " REMOTE_USER
    read -p "Remote hostname or IP: " REMOTE_HOST
    read -p "SSH port (default: 22): " REMOTE_PORT
    REMOTE_PORT=${REMOTE_PORT:-22}
    read -p "Installation directory (default: /home/pi/pi-pvr): " REMOTE_DIR
    REMOTE_DIR=${REMOTE_DIR:-/home/pi/pi-pvr}
    read -p "Installation mode (web/cli, default: web): " INSTALL_MODE
    INSTALL_MODE=${INSTALL_MODE:-web}
    
    # Run remote installer
    "$SCRIPT_DIR/scripts/remote-installer.sh" -u "$REMOTE_USER" -h "$REMOTE_HOST" \
      -p "$REMOTE_PORT" -d "$REMOTE_DIR" -m "$INSTALL_MODE"
    ;;
  4)
    echo "Exiting."
    exit 0
    ;;
  *)
    echo -e "${RED}Invalid choice. Exiting.${NC}"
    exit 1
    ;;
esac