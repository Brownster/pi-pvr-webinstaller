#!/bin/bash
# Web installer starter for PI-PVR Ultimate Media Stack

set -e

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SERVER_IP=$(hostname -I | awk '{print $1}')
PORT=8080

echo "Starting PI-PVR Ultimate Media Stack Web Installer..."

# Check for dependencies
if ! command -v python3 &> /dev/null; then
    echo "Python3 is required but not installed. Installing..."
    sudo apt update
    sudo apt install -y python3 python3-pip
fi

# Check if flask is installed
if ! python3 -c "import flask" &> /dev/null; then
    echo "Flask is not installed. Installing required packages..."
    pip3 install --user -r "$SCRIPT_DIR/requirements.txt"
fi

# Create required directories
mkdir -p "$SCRIPT_DIR/config"
mkdir -p "$SCRIPT_DIR/logs"

# Make sure API script is executable
chmod +x "$SCRIPT_DIR/scripts/api.py"

# Start the API server
echo "Starting web interface at http://$SERVER_IP:$PORT"
echo "Press Ctrl+C to stop the server"

# Export environment variables for the server
export SERVER_IP
export PORT

# Start the server
cd "$SCRIPT_DIR"
python3 scripts/api.py