#!/bin/bash
# Simple starter script for the PI-PVR web installer

echo "Starting PI-PVR Web Installer..."
    
# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
INSTALLER_DIR="$HOME/.pi-pvr-installer"

# Check if the installer directory exists
if [[ ! -d "$INSTALLER_DIR" ]]; then
    echo "Setting up web installer for the first time..."
    bash "$SCRIPT_DIR/web-installer.sh"
else
    # Check if Python is installed
    if ! command -v python3 &> /dev/null; then
        echo "Python3 is required but not installed. Installing..."
        sudo apt update
        sudo apt install -y python3 python3-pip
        
        # Install required Python packages
        echo "Installing required Python packages..."
        python3 -m pip install flask
    fi
    
    # Start the installer
    python3 "$INSTALLER_DIR/app.py"
fi

echo "Web installer has been launched."
echo "Please open your browser to http://$(hostname -I | awk '{print $1}'):8080"