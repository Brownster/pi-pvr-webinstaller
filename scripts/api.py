#!/usr/bin/env python3
"""
API server for PI-PVR Ultimate Media Stack
Provides endpoints for the web UI to interact with the system
"""

import os
import json
import subprocess
import threading
import time
import re
import platform
import psutil
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Set paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_DIR = os.path.join(BASE_DIR, "config")
DOCKER_COMPOSE_DIR = os.path.join(BASE_DIR, "docker-compose")
LOGS_DIR = os.path.join(BASE_DIR, "logs")

# Ensure directories exist
os.makedirs(CONFIG_DIR, exist_ok=True)
os.makedirs(LOGS_DIR, exist_ok=True)

# Configuration file paths
CONFIG_FILE = os.path.join(CONFIG_DIR, "config.json")
SERVICES_FILE = os.path.join(CONFIG_DIR, "services.json")
INSTALLATION_LOG = os.path.join(LOGS_DIR, "installation.log")

# Default configuration
DEFAULT_CONFIG = {
    "puid": 1000,
    "pgid": 1000,
    "timezone": "Europe/London",
    "media_dir": "/mnt/media",
    "downloads_dir": "/mnt/downloads",
    "docker_dir": os.path.join(os.path.expanduser("~"), "docker"),
    "vpn": {
        "enabled": True,
        "provider": "private internet access",
        "username": "",
        "password": "",
        "region": "Netherlands"
    },
    "tailscale": {
        "enabled": False,
        "auth_key": ""
    },
    "installation_status": "not_started"
}

# Default services configuration
DEFAULT_SERVICES = {
    "arr_apps": {
        "sonarr": True,
        "radarr": True,
        "prowlarr": True,
        "lidarr": False,
        "readarr": False,
        "bazarr": False
    },
    "download_clients": {
        "transmission": True,
        "qbittorrent": False,
        "nzbget": True,
        "sabnzbd": False,
        "jdownloader": False
    },
    "media_servers": {
        "jellyfin": True,
        "plex": False,
        "emby": False
    },
    "utilities": {
        "heimdall": False,
        "overseerr": False,
        "tautulli": False,
        "portainer": True,
        "nginx_proxy_manager": False,
        "get_iplayer": True
    }
}

# Load configuration
def load_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)
    return DEFAULT_CONFIG

# Save configuration
def save_config(config):
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f, indent=2)

# Load services
def load_services():
    if os.path.exists(SERVICES_FILE):
        with open(SERVICES_FILE, "r") as f:
            return json.load(f)
    return DEFAULT_SERVICES

# Save services
def save_services(services):
    with open(SERVICES_FILE, "w") as f:
        json.dump(services, f, indent=2)

# Log to installation log
def log_installation(message):
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    with open(INSTALLATION_LOG, "a") as f:
        f.write(f"[{timestamp}] {message}\n")

# Check if Docker is installed
def is_docker_installed():
    try:
        subprocess.run(["docker", "--version"], capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False

# Get system information
def get_system_info():
    info = {
        "hostname": platform.node(),
        "platform": platform.system(),
        "platform_version": platform.version(),
        "architecture": platform.machine(),
        "processor": platform.processor(),
        "python_version": platform.python_version(),
        "memory_total": psutil.virtual_memory().total,
        "memory_available": psutil.virtual_memory().available,
        "disk_total": psutil.disk_usage('/').total,
        "disk_free": psutil.disk_usage('/').free,
        "docker_installed": is_docker_installed(),
        "tailscale_installed": os.path.exists("/usr/bin/tailscale")
    }
    return info

# Get docker container status
def get_container_status():
    containers = {}
    try:
        result = subprocess.run(["docker", "ps", "-a", "--format", "{{.Names}}|{{.Status}}|{{.Ports}}"], 
                               capture_output=True, text=True, check=True)
        lines = result.stdout.strip().split("\n")
        for line in lines:
            if line:
                parts = line.split("|")
                if len(parts) >= 2:
                    name = parts[0]
                    status = "running" if "Up" in parts[1] else "stopped"
                    ports = parts[2] if len(parts) > 2 else ""
                    
                    # Extract port mappings
                    port_mappings = []
                    if ports:
                        port_pattern = r'(\d+\.\d+\.\d+\.\d+:)?(\d+)->(\d+)'
                        matches = re.findall(port_pattern, ports)
                        for match in matches:
                            host_port = match[1]
                            container_port = match[2]
                            port_mappings.append({"host": host_port, "container": container_port})
                    
                    containers[name] = {
                        "status": status,
                        "ports": port_mappings
                    }
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    return containers

# Generate docker-compose file
def generate_docker_compose(config, services):
    # Build command based on selected services
    cmd = [os.path.join(BASE_DIR, "scripts", "generate-compose.sh")]
    
    # Add Arr Apps
    if any(services["arr_apps"].values()):
        cmd.append("--arr-apps")
    
    # Add media server
    media_servers = services["media_servers"]
    if media_servers["jellyfin"]:
        cmd.extend(["--media-server", "jellyfin"])
    elif media_servers["plex"]:
        cmd.extend(["--media-server", "plex"])
    elif media_servers["emby"]:
        cmd.extend(["--media-server", "emby"])
    
    # Add download client
    download_clients = services["download_clients"]
    if download_clients["transmission"]:
        cmd.extend(["--torrent-client", "transmission"])
    elif download_clients["qbittorrent"]:
        cmd.extend(["--torrent-client", "qbittorrent"])
    
    if download_clients["nzbget"]:
        cmd.extend(["--usenet-client", "nzbget"])
    elif download_clients["sabnzbd"]:
        cmd.extend(["--usenet-client", "sabnzbd"])
    
    if download_clients["jdownloader"]:
        cmd.append("--direct-download")
    
    # Add utilities
    utilities = services["utilities"]
    if utilities["heimdall"]:
        cmd.append("--dashboard")
    if utilities["overseerr"]:
        cmd.append("--requests")
    if utilities["tautulli"]:
        cmd.append("--monitoring")
    if utilities["nginx_proxy_manager"]:
        cmd.append("--proxy")
    
    # Run the command
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return {"success": True, "output": result.stdout}
    except subprocess.CalledProcessError as e:
        return {"success": False, "error": e.stderr}

# Create .env file
def create_env_file(config):
    env_content = f"""# Generated by PI-PVR Web Installer
# Base Configuration
PUID={config['puid']}
PGID={config['pgid']}
TIMEZONE={config['timezone']}
IMAGE_RELEASE=latest
DOCKER_DIR={config['docker_dir']}

# Media and Download Directories
MEDIA_DIR={config['media_dir']}
DOWNLOADS_DIR={config['downloads_dir']}
WATCH_DIR={config['downloads_dir']}/watch

# VPN Configuration
VPN_CONTAINER=vpn
VPN_IMAGE=qmcgaw/gluetun
VPN_SERVICE_PROVIDER={config['vpn']['provider']}
OPENVPN_USER={config['vpn']['username']}
OPENVPN_PASSWORD={config['vpn']['password']}
SERVER_REGIONS={config['vpn']['region']}

# Tailscale
TAILSCALE_AUTH_KEY={config['tailscale']['auth_key']}

# Network Configuration
CONTAINER_NETWORK=vpn_network
"""

    env_file_path = os.path.join(BASE_DIR, ".env")
    with open(env_file_path, "w") as f:
        f.write(env_content)
    
    return env_file_path

# Run installation in a separate thread
def run_installation(config, services):
    try:
        # Update installation status
        config["installation_status"] = "in_progress"
        save_config(config)
        
        # Generate docker-compose file
        log_installation("Generating docker-compose.yml...")
        result = generate_docker_compose(config, services)
        if not result["success"]:
            log_installation(f"Failed to generate docker-compose.yml: {result['error']}")
            config["installation_status"] = "failed"
            save_config(config)
            return
        
        # Create .env file
        log_installation("Creating .env file...")
        env_file_path = create_env_file(config)
        
        # Install Docker if not installed
        if not is_docker_installed():
            log_installation("Installing Docker...")
            try:
                subprocess.run([
                    "curl", "-fsSL", "https://get.docker.com", "-o", "get-docker.sh"
                ], check=True)
                subprocess.run(["sh", "get-docker.sh"], check=True)
                os.remove("get-docker.sh")
            except subprocess.CalledProcessError as e:
                log_installation(f"Failed to install Docker: {str(e)}")
                config["installation_status"] = "failed"
                save_config(config)
                return
        
        # Install Tailscale if enabled
        if config["tailscale"]["enabled"]:
            log_installation("Installing Tailscale...")
            try:
                subprocess.run([
                    "curl", "-fsSL", "https://tailscale.com/install.sh", "-o", "install-tailscale.sh"
                ], check=True)
                subprocess.run(["sh", "install-tailscale.sh"], check=True)
                os.remove("install-tailscale.sh")
                
                # Set up Tailscale if auth key provided
                if config["tailscale"]["auth_key"]:
                    subprocess.run([
                        "sudo", "tailscale", "up", 
                        "--authkey", config["tailscale"]["auth_key"],
                        "--accept-routes=false"
                    ], check=True)
            except subprocess.CalledProcessError as e:
                log_installation(f"Failed to install Tailscale: {str(e)}")
        
        # Start Docker Compose stack
        log_installation("Starting Docker Compose stack...")
        try:
            subprocess.run([
                "docker", "compose", 
                "-f", os.path.join(BASE_DIR, "docker-compose.yml"),
                "up", "-d"
            ], check=True)
            log_installation("Docker Compose stack started successfully")
            config["installation_status"] = "completed"
        except subprocess.CalledProcessError as e:
            log_installation(f"Failed to start Docker Compose stack: {str(e)}")
            config["installation_status"] = "failed"
        
        save_config(config)
    except Exception as e:
        log_installation(f"Installation failed with error: {str(e)}")
        config["installation_status"] = "failed"
        save_config(config)

# API routes
@app.route('/api/system', methods=['GET'])
def api_system_info():
    return jsonify(get_system_info())

@app.route('/api/config', methods=['GET'])
def api_get_config():
    return jsonify(load_config())

@app.route('/api/config', methods=['POST'])
def api_save_config():
    config = request.json
    save_config(config)
    return jsonify({"status": "success"})

@app.route('/api/services', methods=['GET'])
def api_get_services():
    return jsonify(load_services())

@app.route('/api/services', methods=['POST'])
def api_save_services():
    services = request.json
    save_services(services)
    return jsonify({"status": "success"})

@app.route('/api/status', methods=['GET'])
def api_status():
    config = load_config()
    containers = get_container_status()
    return jsonify({
        "installation_status": config["installation_status"],
        "containers": containers
    })

@app.route('/api/install', methods=['POST'])
def api_install():
    config = load_config()
    services = load_services()
    
    # Start installation in a separate thread
    threading.Thread(target=run_installation, args=(config, services)).start()
    
    return jsonify({
        "status": "started",
        "message": "Installation started"
    })

@app.route('/api/logs', methods=['GET'])
def api_logs():
    if os.path.exists(INSTALLATION_LOG):
        with open(INSTALLATION_LOG, "r") as f:
            logs = f.read()
        return jsonify({"logs": logs})
    return jsonify({"logs": ""})

@app.route('/api/generate-compose', methods=['POST'])
def api_generate_compose():
    config = load_config()
    services = load_services()
    result = generate_docker_compose(config, services)
    return jsonify(result)

@app.route('/api/restart', methods=['POST'])
def api_restart():
    try:
        subprocess.run([
            "docker", "compose", 
            "-f", os.path.join(BASE_DIR, "docker-compose.yml"),
            "restart"
        ], check=True)
        return jsonify({"status": "success"})
    except subprocess.CalledProcessError as e:
        return jsonify({"status": "error", "message": str(e)})

@app.route('/api/restart/<container>', methods=['POST'])
def api_restart_container(container):
    try:
        subprocess.run([
            "docker", "restart", container
        ], check=True)
        return jsonify({"status": "success"})
    except subprocess.CalledProcessError as e:
        return jsonify({"status": "error", "message": str(e)})

@app.route('/api/start/<container>', methods=['POST'])
def api_start_container(container):
    try:
        subprocess.run([
            "docker", "start", container
        ], check=True)
        return jsonify({"status": "success"})
    except subprocess.CalledProcessError as e:
        return jsonify({"status": "error", "message": str(e)})

@app.route('/api/stop/<container>', methods=['POST'])
def api_stop_container(container):
    try:
        subprocess.run([
            "docker", "stop", container
        ], check=True)
        return jsonify({"status": "success"})
    except subprocess.CalledProcessError as e:
        return jsonify({"status": "error", "message": str(e)})

# Serve the front-end
@app.route('/')
def index():
    return send_from_directory('../web-ui', 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    return send_from_directory('../web-ui', path)

# Main entry point
if __name__ == '__main__':
    # Ensure config and services files exist
    if not os.path.exists(CONFIG_FILE):
        save_config(DEFAULT_CONFIG)
    
    if not os.path.exists(SERVICES_FILE):
        save_services(DEFAULT_SERVICES)
    
    # Start the server
    app.run(host='0.0.0.0', port=8080, debug=True)