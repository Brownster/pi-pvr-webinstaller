#!/bin/bash
# Script to continue the setup process after mount errors

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}PI-PVR Setup Continuation Script${NC}"
echo -e "${BLUE}This script will help you continue the setup after mount errors${NC}"
echo

# Variables
STORAGE_MOUNT="/mnt/storage"
DOWNLOAD_MOUNT="/mnt/downloads"
MOVIES_DIR="$STORAGE_MOUNT/Movies"
TVSHOWS_DIR="$STORAGE_MOUNT/TVShows"
DOWNLOADS_DIR="$STORAGE_MOUNT/downloads"

# Create directories if they don't exist
echo -e "${BLUE}Creating necessary directories...${NC}"
sudo mkdir -p "$MOVIES_DIR" "$TVSHOWS_DIR" "$DOWNLOADS_DIR"

# Set permissions
echo -e "${BLUE}Setting directory permissions...${NC}"
sudo chmod -R 775 "$STORAGE_MOUNT"
sudo chown -R "$USER:$USER" "$STORAGE_MOUNT"

# Check Samba installation
echo -e "${BLUE}Checking and configuring Samba...${NC}"
if ! command -v smbd &> /dev/null; then
    echo -e "${YELLOW}Installing Samba...${NC}"
    sudo apt-get update
    sudo apt-get install -y samba samba-common-bin
fi

# Configure Samba shares
SAMBA_CONFIG="/etc/samba/smb.conf"
if ! grep -q "\[Movies\]" "$SAMBA_CONFIG"; then
    echo -e "${BLUE}Adding Samba shares to configuration...${NC}"
    sudo bash -c "cat >> $SAMBA_CONFIG" <<EOF

[Movies]
   path = $MOVIES_DIR
   browseable = yes
   read only = no
   guest ok = yes

[TVShows]
   path = $TVSHOWS_DIR
   browseable = yes
   read only = no
   guest ok = yes

[Downloads]
   path = $DOWNLOADS_DIR
   browseable = yes
   read only = no
   guest ok = yes
EOF
    sudo systemctl restart smbd
    echo -e "${GREEN}Samba configured and restarted${NC}"
else
    echo -e "${BLUE}Samba shares already configured${NC}"
fi

# Network setup
SERVER_IP=$(hostname -I | awk '{print $1}')
DOCKER_DIR="$HOME/docker"
CONTAINER_NETWORK="vpn_network"

# Setup Docker network
echo -e "${BLUE}Setting up Docker network...${NC}"
if ! docker network ls | grep -q "$CONTAINER_NETWORK"; then
    echo -e "${YELLOW}Creating Docker network: $CONTAINER_NETWORK${NC}"
    docker network create "$CONTAINER_NETWORK"
else 
    echo -e "${BLUE}Docker network $CONTAINER_NETWORK already exists${NC}"
fi

# Deploy or restart Docker stack
echo -e "${BLUE}Checking Docker Compose stack...${NC}"
if [ -f "$DOCKER_DIR/docker-compose.yml" ]; then
    echo -e "${YELLOW}Docker Compose file found. Starting services...${NC}"
    cd "$DOCKER_DIR" && docker-compose up -d
else
    echo -e "${RED}Docker Compose file not found at $DOCKER_DIR/docker-compose.yml${NC}"
    echo -e "${RED}Please run the setup script again to generate the compose file${NC}"
fi

# Print summary
echo
echo -e "${GREEN}Setup continuation completed!${NC}"
echo -e "${GREEN}==============================================${NC}"
echo -e "${BLUE}Storage mounted at:${NC} $STORAGE_MOUNT"
echo -e "${BLUE}Samba shares:${NC}"
echo -e "  \\\\${SERVER_IP}\\Movies"
echo -e "  \\\\${SERVER_IP}\\TVShows"
echo -e "  \\\\${SERVER_IP}\\Downloads"
echo
echo -e "${BLUE}Web UI should be available at:${NC} http://${SERVER_IP}:8080"
echo -e "${GREEN}==============================================${NC}"