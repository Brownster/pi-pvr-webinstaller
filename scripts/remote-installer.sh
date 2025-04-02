#!/bin/bash
# Remote installer for PI-PVR Ultimate Media Stack
# Allows installing on a remote machine via SSH

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
REMOTE_USER=""
REMOTE_HOST=""
REMOTE_PORT="22"
REMOTE_DIR="/home/pi/pi-pvr"
SSH_KEY=""
INSTALL_MODE="web"

# Print help
print_help() {
  echo "Remote installer for PI-PVR Ultimate Media Stack"
  echo ""
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -u, --user USER         Remote username (required)"
  echo "  -h, --host HOST         Remote hostname or IP address (required)"
  echo "  -p, --port PORT         SSH port (default: 22)"
  echo "  -d, --dir DIRECTORY     Installation directory (default: /home/pi/pi-pvr)"
  echo "  -k, --key SSH_KEY       Path to SSH private key"
  echo "  -m, --mode MODE         Installation mode: web or cli (default: web)"
  echo "  --help                  Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 -u pi -h raspberrypi.local -m web"
  echo "  $0 -u admin -h 192.168.1.100 -p 2222 -k ~/.ssh/my_key -d /opt/pi-pvr -m cli"
  echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -u|--user)
      REMOTE_USER="$2"
      shift 2
      ;;
    -h|--host)
      REMOTE_HOST="$2"
      shift 2
      ;;
    -p|--port)
      REMOTE_PORT="$2"
      shift 2
      ;;
    -d|--dir)
      REMOTE_DIR="$2"
      shift 2
      ;;
    -k|--key)
      SSH_KEY="$2"
      shift 2
      ;;
    -m|--mode)
      INSTALL_MODE="$2"
      shift 2
      ;;
    --help)
      print_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      print_help
      exit 1
      ;;
  esac
done

# Validate required arguments
if [ -z "$REMOTE_USER" ] || [ -z "$REMOTE_HOST" ]; then
  echo -e "${RED}Error: Remote user and host are required${NC}"
  print_help
  exit 1
fi

# Validate installation mode
if [ "$INSTALL_MODE" != "web" ] && [ "$INSTALL_MODE" != "cli" ]; then
  echo -e "${RED}Error: Installation mode must be 'web' or 'cli'${NC}"
  print_help
  exit 1
fi

# Prepare SSH options
SSH_OPTS="-p $REMOTE_PORT"
if [ -n "$SSH_KEY" ]; then
  SSH_OPTS="$SSH_OPTS -i $SSH_KEY"
fi

echo -e "${BLUE}PI-PVR Ultimate Media Stack - Remote Installer${NC}"
echo ""
echo -e "Remote User: ${GREEN}$REMOTE_USER${NC}"
echo -e "Remote Host: ${GREEN}$REMOTE_HOST${NC}"
echo -e "SSH Port:    ${GREEN}$REMOTE_PORT${NC}"
echo -e "Install Dir: ${GREEN}$REMOTE_DIR${NC}"
echo -e "Install Mode: ${GREEN}$INSTALL_MODE${NC}"
echo ""

# Function to check SSH connection
check_ssh_connection() {
  echo -e "${BLUE}Checking SSH connection...${NC}"
  if ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "echo 'Connection successful'" &> /dev/null; then
    echo -e "${GREEN}SSH connection successful${NC}"
    return 0
  else
    echo -e "${RED}Error: Could not connect to the remote host${NC}"
    echo "Please check your SSH settings and ensure the remote host is reachable"
    return 1
  fi
}

# Function to check system requirements
check_remote_system() {
  echo -e "${BLUE}Checking remote system requirements...${NC}"
  
  # Check if the remote system has the required packages
  echo "Checking for required packages..."
  MISSING_PACKAGES=()
  
  for PKG in curl git python3; do
    if ! ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "which $PKG" &> /dev/null; then
      MISSING_PACKAGES+=("$PKG")
    fi
  done
  
  if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo -e "${YELLOW}The following packages are missing on the remote system:${NC}"
    for PKG in "${MISSING_PACKAGES[@]}"; do
      echo "  - $PKG"
    done
    
    echo -e "${YELLOW}Do you want to install them automatically? (y/n)${NC}"
    read -r INSTALL_PACKAGES
    if [[ "$INSTALL_PACKAGES" =~ ^[Yy]$ ]]; then
      echo "Installing missing packages..."
      ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "sudo apt update && sudo apt install -y ${MISSING_PACKAGES[*]}"
    else
      echo -e "${RED}Required packages must be installed to continue${NC}"
      return 1
    fi
  else
    echo -e "${GREEN}All required packages are installed${NC}"
  fi
  
  # Check disk space
  echo "Checking disk space..."
  AVAILABLE_SPACE=$(ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "df -h / | awk 'NR==2 {print \$4}' | sed 's/G//'")
  if (( $(echo "$AVAILABLE_SPACE < 5" | bc -l) )); then
    echo -e "${YELLOW}Warning: Less than 5GB of free space available (${AVAILABLE_SPACE}GB)${NC}"
    echo -e "${YELLOW}It is recommended to have at least 5GB of free space${NC}"
    echo -e "${YELLOW}Do you want to continue anyway? (y/n)${NC}"
    read -r CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
      echo "Installation aborted"
      return 1
    fi
  else
    echo -e "${GREEN}Sufficient disk space available (${AVAILABLE_SPACE}GB)${NC}"
  fi
  
  return 0
}

# Function to prepare remote directory
prepare_remote_directory() {
  echo -e "${BLUE}Preparing remote directory...${NC}"
  
  # Create the directory if it doesn't exist
  ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_DIR"
  
  # Check if the directory is empty
  if ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "[ \$(ls -A $REMOTE_DIR 2>/dev/null | wc -l) -gt 0 ]"; then
    echo -e "${YELLOW}Warning: The remote directory is not empty${NC}"
    echo -e "${YELLOW}Do you want to clear its contents? (y/n)${NC}"
    read -r CLEAR_DIR
    if [[ "$CLEAR_DIR" =~ ^[Yy]$ ]]; then
      ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "rm -rf $REMOTE_DIR/*"
      echo "Directory cleared"
    fi
  fi
  
  return 0
}

# Function to upload project files
upload_project_files() {
  echo -e "${BLUE}Uploading project files...${NC}"
  
  # Get the project directory (with support for symlinks)
  PROJECT_DIR="$( cd -- "$(dirname -- "$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")")")" &> /dev/null && pwd )"
  
  # Create a temporary tar file
  TEMP_TAR="/tmp/pi-pvr-$(date +%s).tar.gz"
  echo "Creating archive of project files..."
  tar -czf "$TEMP_TAR" -C "$PROJECT_DIR" --exclude=".git" .
  
  # Upload the tar file
  echo "Uploading archive to remote host..."
  scp $SSH_OPTS "$TEMP_TAR" "$REMOTE_USER@$REMOTE_HOST:/tmp/"
  
  # Extract the tar file on the remote host
  echo "Extracting files on remote host..."
  ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "tar -xzf $(basename "$TEMP_TAR") -C $REMOTE_DIR"
  
  # Make scripts executable
  echo "Setting execution permissions..."
  ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "chmod +x $REMOTE_DIR/*.sh $REMOTE_DIR/scripts/*.sh $REMOTE_DIR/scripts/*.py"
  
  # Clean up
  rm -f "$TEMP_TAR"
  ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "rm -f /tmp/$(basename "$TEMP_TAR")"
  
  echo -e "${GREEN}Files uploaded successfully${NC}"
  return 0
}

# Function to start the installation
start_remote_installation() {
  echo -e "${BLUE}Starting remote installation...${NC}"
  
  if [ "$INSTALL_MODE" = "web" ]; then
    # Start web installer
    echo "Starting web installer..."
    REMOTE_IP=$(ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "hostname -I | awk '{print \$1}'")
    
    # Check if we need to set up port forwarding
    echo -e "${YELLOW}Do you want to set up port forwarding to access the web installer locally? (y/n)${NC}"
    read -r SETUP_FORWARDING
    if [[ "$SETUP_FORWARDING" =~ ^[Yy]$ ]]; then
      LOCAL_PORT=8080
      echo "Setting up port forwarding from remote port 8080 to local port $LOCAL_PORT..."
      echo "Press Ctrl+C to stop the installer and close the SSH tunnel"
      
      # Start the web installer and set up port forwarding
      ssh $SSH_OPTS -L "$LOCAL_PORT:localhost:8080" "$REMOTE_USER@$REMOTE_HOST" "cd $REMOTE_DIR && ./web-install.sh"
      
      echo "Access the web installer at: http://localhost:$LOCAL_PORT"
    else
      # Just start the web installer
      ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "cd $REMOTE_DIR && ./web-install.sh" &
      
      echo "The web installer is running on the remote system"
      echo "Access it at: http://$REMOTE_IP:8080"
    fi
  else
    # Start CLI installer
    echo "Starting command-line installer..."
    ssh $SSH_OPTS -t "$REMOTE_USER@$REMOTE_HOST" "cd $REMOTE_DIR && ./pi-pvr.sh"
  fi
  
  return 0
}

# Main function
main() {
  # Check SSH connection
  check_ssh_connection || exit 1
  
  # Check system requirements
  check_remote_system || exit 1
  
  # Prepare remote directory
  prepare_remote_directory || exit 1
  
  # Upload project files
  upload_project_files || exit 1
  
  # Start installation
  start_remote_installation || exit 1
  
  echo -e "${GREEN}Remote installation process completed successfully${NC}"
}

# Run main function
main