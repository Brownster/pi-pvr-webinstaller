#!/bin/bash
# Web-based installer for PI-PVR
# This script creates a lightweight web server to guide users through setup

set -euo pipefail

# Variables
PORT=8080
SERVER_IP=$(hostname -I | awk '{print $1}')
DOCKER_DIR="$HOME/docker"
ENV_FILE="$DOCKER_DIR/.env"
INSTALLER_DIR="$HOME/.pi-pvr-installer"
INSTALLER_LOG="$INSTALLER_DIR/installer.log"

# Create installer directory
mkdir -p "$INSTALLER_DIR"
mkdir -p "$INSTALLER_DIR/templates"
mkdir -p "$INSTALLER_DIR/assets"

# Function to log messages
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$INSTALLER_LOG"
}

# Check dependencies
check_dependencies() {
  log "Checking dependencies..."
  
  # Check for Python3
  if ! command -v python3 &> /dev/null; then
    log "Python3 is required but not installed. Installing..."
    sudo apt update
    sudo apt install -y python3 python3-pip
  fi
  
  # Install required Python packages
  log "Installing required Python packages..."
  python3 -m pip install flask
  
  log "Dependencies installed successfully"
}

# Create web templates
create_templates() {
  log "Creating web templates..."
  
  # Create main layout template
  cat > "$INSTALLER_DIR/templates/layout.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PI-PVR Web Installer</title>
  <style>
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 1200px;
      margin: 0 auto;
      padding: 20px;
    }
    header {
      background-color: #2c3e50;
      color: white;
      padding: 20px;
      border-radius: 5px;
      margin-bottom: 20px;
    }
    .step {
      background-color: #f9f9f9;
      border: 1px solid #ddd;
      border-radius: 5px;
      padding: 20px;
      margin-bottom: 20px;
    }
    .step h2 {
      border-bottom: 2px solid #2c3e50;
      padding-bottom: 10px;
      margin-top: 0;
    }
    .step.current {
      border-left: 5px solid #27ae60;
    }
    button, .button {
      background-color: #27ae60;
      color: white;
      border: none;
      padding: 10px 15px;
      border-radius: 5px;
      cursor: pointer;
      text-decoration: none;
      display: inline-block;
    }
    button:hover, .button:hover {
      background-color: #2ecc71;
    }
    input[type="text"], input[type="password"], select {
      width: 100%;
      padding: 10px;
      margin: 10px 0;
      border-radius: 5px;
      border: 1px solid #ddd;
    }
    .success {
      color: #27ae60;
    }
    .error {
      color: #e74c3c;
    }
    .notification {
      padding: 15px;
      margin: 10px 0;
      border-radius: 5px;
    }
    .success-bg {
      background-color: #d4edda;
      border: 1px solid #c3e6cb;
    }
    .error-bg {
      background-color: #f8d7da;
      border: 1px solid #f5c6cb;
    }
    .progress-container {
      width: 100%;
      background-color: #ddd;
      border-radius: 5px;
      margin: 20px 0;
    }
    .progress-bar {
      height: 30px;
      background-color: #27ae60;
      border-radius: 5px;
      text-align: center;
      line-height: 30px;
      color: white;
    }
    .service-card {
      border: 1px solid #ddd;
      border-radius: 5px;
      padding: 10px;
      margin: 10px 0;
    }
    .service-card h3 {
      margin-top: 0;
    }
    .service-url {
      color: #3498db;
      text-decoration: none;
    }
    .service-url:hover {
      text-decoration: underline;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
      gap: 20px;
    }
  </style>
</head>
<body>
  <header>
    <h1>🐳 PI-PVR Web Installer</h1>
    <p>Raspberry Pi Docker Stack with VPN, Tailscale, and Media Management</p>
  </header>
  
  <div class="content">
    {% block content %}{% endblock %}
  </div>
  
  <footer>
    <p>PI-PVR Web Installer &copy; 2025</p>
  </footer>
</body>
</html>
EOF

  # Create welcome page
  cat > "$INSTALLER_DIR/templates/welcome.html" <<'EOF'
{% extends "layout.html" %}

{% block content %}
<div class="step current">
  <h2>Welcome to PI-PVR Web Installer</h2>
  <p>This web installer will guide you through setting up your PI-PVR media server stack.</p>
  
  <div class="notification success-bg">
    <p>The installer has started on your system at http://{{ server_ip }}:{{ port }}</p>
  </div>
  
  <h3>Installation Steps:</h3>
  <ol>
    <li>System Requirements Check</li>
    <li>VPN Configuration (PIA)</li>
    <li>Tailscale Setup</li>
    <li>Storage Configuration</li>
    <li>Media Folders Setup</li>
    <li>Service Configuration</li>
    <li>Installation</li>
    <li>Dashboard and Management</li>
  </ol>
  
  <a href="/system-check" class="button">Begin Installation</a>
</div>
{% endblock %}
EOF

  # Create system check page
  cat > "$INSTALLER_DIR/templates/system_check.html" <<'EOF'
{% extends "layout.html" %}

{% block content %}
<div class="step current">
  <h2>System Requirements Check</h2>
  
  <div class="progress-container">
    <div class="progress-bar" style="width: 10%">10%</div>
  </div>
  
  <h3>Checking your system...</h3>
  <ul>
    {% for check in checks %}
    <li>{{ check.name }}: 
      {% if check.status %}
      <span class="success">✓ Passed</span>
      {% else %}
      <span class="error">✗ Failed</span> - {{ check.message }}
      {% endif %}
    </li>
    {% endfor %}
  </ul>
  
  {% if all_passed %}
  <div class="notification success-bg">
    <p>All system checks passed! You can proceed with the installation.</p>
  </div>
  <a href="/vpn-setup" class="button">Continue to VPN Setup</a>
  {% else %}
  <div class="notification error-bg">
    <p>Please resolve the issues above before continuing.</p>
  </div>
  <a href="/system-check" class="button">Recheck System</a>
  {% endif %}
</div>
{% endblock %}
EOF

  # Create VPN setup page
  cat > "$INSTALLER_DIR/templates/vpn_setup.html" <<'EOF'
{% extends "layout.html" %}

{% block content %}
<div class="step current">
  <h2>VPN Configuration</h2>
  
  <div class="progress-container">
    <div class="progress-bar" style="width: 20%">20%</div>
  </div>
  
  <p>Configure your Private Internet Access (PIA) VPN credentials.</p>
  
  <form action="/vpn-save" method="post">
    <div>
      <label for="pia_username">PIA Username:</label>
      <input type="text" id="pia_username" name="pia_username" required value="{{ pia_username }}">
    </div>
    
    <div>
      <label for="pia_password">PIA Password:</label>
      <input type="password" id="pia_password" name="pia_password" required value="{{ pia_password }}">
    </div>
    
    <div>
      <label for="server_region">Server Region:</label>
      <select id="server_region" name="server_region">
        <option value="Netherlands" {% if server_region == "Netherlands" %}selected{% endif %}>Netherlands</option>
        <option value="Switzerland" {% if server_region == "Switzerland" %}selected{% endif %}>Switzerland</option>
        <option value="Sweden" {% if server_region == "Sweden" %}selected{% endif %}>Sweden</option>
        <option value="France" {% if server_region == "France" %}selected{% endif %}>France</option>
        <option value="Germany" {% if server_region == "Germany" %}selected{% endif %}>Germany</option>
        <option value="UK" {% if server_region == "UK" %}selected{% endif %}>UK</option>
        <option value="US East" {% if server_region == "US East" %}selected{% endif %}>US East</option>
        <option value="US West" {% if server_region == "US West" %}selected{% endif %}>US West</option>
      </select>
    </div>
    
    <button type="submit">Save VPN Configuration</button>
  </form>
</div>
{% endblock %}
EOF

  # Create Tailscale setup page
  cat > "$INSTALLER_DIR/templates/tailscale_setup.html" <<'EOF'
{% extends "layout.html" %}

{% block content %}
<div class="step current">
  <h2>Tailscale Setup</h2>
  
  <div class="progress-container">
    <div class="progress-bar" style="width: 30%">30%</div>
  </div>
  
  <p>Tailscale provides secure remote access to your services.</p>
  
  <form action="/tailscale-save" method="post">
    <div>
      <label for="tailscale_auth_key">Tailscale Auth Key (optional):</label>
      <input type="text" id="tailscale_auth_key" name="tailscale_auth_key" value="{{ tailscale_auth_key }}">
      <p><small>You can leave this blank if you want to authorize manually later.</small></p>
    </div>
    
    <button type="submit">Save Tailscale Configuration</button>
  </form>
</div>
{% endblock %}
EOF

  # Create Storage setup page
  cat > "$INSTALLER_DIR/templates/storage_setup.html" <<'EOF'
{% extends "layout.html" %}

{% block content %}
<div class="step current">
  <h2>Storage Configuration</h2>
  
  <div class="progress-container">
    <div class="progress-bar" style="width: 40%">40%</div>
  </div>
  
  <p>Configure storage drives for media and downloads.</p>
  
  <form action="/storage-save" method="post">
    <div>
      <h3>Available Drives:</h3>
      <table style="width: 100%; border-collapse: collapse;">
        <tr style="background-color: #f2f2f2;">
          <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Device</th>
          <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Size</th>
          <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Type</th>
          <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Use For</th>
        </tr>
        {% for drive in drives %}
        <tr>
          <td style="padding: 10px; border: 1px solid #ddd;">{{ drive.device }}</td>
          <td style="padding: 10px; border: 1px solid #ddd;">{{ drive.size }}</td>
          <td style="padding: 10px; border: 1px solid #ddd;">{{ drive.type }}</td>
          <td style="padding: 10px; border: 1px solid #ddd;">
            <select name="drive_use_{{ drive.device | replace('/', '_') }}">
              <option value="">Not Used</option>
              <option value="media">Media Storage</option>
              <option value="downloads">Downloads</option>
              <option value="both">Both Media & Downloads</option>
            </select>
          </td>
        </tr>
        {% endfor %}
      </table>
    </div>
    
    <div>
      <h3>Share Method:</h3>
      <select id="share_method" name="share_method">
        <option value="samba" {% if share_method == "samba" %}selected{% endif %}>Samba (Windows, Mac, Linux)</option>
        <option value="nfs" {% if share_method == "nfs" %}selected{% endif %}>NFS (Linux only)</option>
      </select>
    </div>
    
    <button type="submit">Save Storage Configuration</button>
  </form>
</div>
{% endblock %}
EOF

  # Create Media folders setup page
  cat > "$INSTALLER_DIR/templates/media_setup.html" <<'EOF'
{% extends "layout.html" %}

{% block content %}
<div class="step current">
  <h2>Media Folders Setup</h2>
  
  <div class="progress-container">
    <div class="progress-bar" style="width: 50%">50%</div>
  </div>
  
  <p>Configure your media folder structure.</p>
  
  <form action="/media-save" method="post">
    <div>
      <label for="movies_folder">Movies Folder Name:</label>
      <input type="text" id="movies_folder" name="movies_folder" required value="{{ movies_folder }}">
    </div>
    
    <div>
      <label for="tvshows_folder">TV Shows Folder Name:</label>
      <input type="text" id="tvshows_folder" name="tvshows_folder" required value="{{ tvshows_folder }}">
    </div>
    
    <div>
      <label for="downloads_folder">Downloads Folder Path:</label>
      <input type="text" id="downloads_folder" name="downloads_folder" required value="{{ downloads_folder }}">
    </div>
    
    <button type="submit">Save Media Configuration</button>
  </form>
</div>
{% endblock %}
EOF

  # Create Services setup page
  cat > "$INSTALLER_DIR/templates/services_setup.html" <<'EOF'
{% extends "layout.html" %}

{% block content %}
<div class="step current">
  <h2>Services Configuration</h2>
  
  <div class="progress-container">
    <div class="progress-bar" style="width: 60%">60%</div>
  </div>
  
  <p>Configure ports and settings for your media services.</p>
  
  <form action="/services-save" method="post">
    <h3>Service Ports:</h3>
    
    <div>
      <label for="jacket_port">Jackett Port:</label>
      <input type="text" id="jacket_port" name="jacket_port" required value="{{ jacket_port }}">
    </div>
    
    <div>
      <label for="sonarr_port">Sonarr Port:</label>
      <input type="text" id="sonarr_port" name="sonarr_port" required value="{{ sonarr_port }}">
    </div>
    
    <div>
      <label for="radarr_port">Radarr Port:</label>
      <input type="text" id="radarr_port" name="radarr_port" required value="{{ radarr_port }}">
    </div>
    
    <div>
      <label for="transmission_port">Transmission Port:</label>
      <input type="text" id="transmission_port" name="transmission_port" required value="{{ transmission_port }}">
    </div>
    
    <div>
      <label for="nzbget_port">NZBGet Port:</label>
      <input type="text" id="nzbget_port" name="nzbget_port" required value="{{ nzbget_port }}">
    </div>
    
    <div>
      <label for="get_iplayer_port">Get iPlayer Port:</label>
      <input type="text" id="get_iplayer_port" name="get_iplayer_port" required value="{{ get_iplayer_port }}">
    </div>
    
    <div>
      <label for="jellyfin_port">Jellyfin HTTP Port:</label>
      <input type="text" id="jellyfin_port" name="jellyfin_port" required value="{{ jellyfin_port }}">
    </div>
    
    <div>
      <label for="jellyfin_https_port">Jellyfin HTTPS Port:</label>
      <input type="text" id="jellyfin_https_port" name="jellyfin_https_port" required value="{{ jellyfin_https_port }}">
    </div>
    
    <h3>Other Settings:</h3>
    
    <div>
      <label for="timezone">Timezone:</label>
      <input type="text" id="timezone" name="timezone" required value="{{ timezone }}">
    </div>
    
    <button type="submit">Save Service Configuration</button>
  </form>
</div>
{% endblock %}
EOF

  # Create Installation page
  cat > "$INSTALLER_DIR/templates/installation.html" <<'EOF'
{% extends "layout.html" %}

{% block content %}
<div class="step current">
  <h2>Installation</h2>
  
  <div class="progress-container">
    <div class="progress-bar" style="width: 80%">80%</div>
  </div>
  
  <div id="status">
    <p>Ready to install. Click the button below to begin installation.</p>
  </div>
  
  <div>
    <button id="install-button" onclick="startInstallation()">Start Installation</button>
  </div>
  
  <div id="log-container" style="display: none;">
    <h3>Installation Log:</h3>
    <pre id="install-log" style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; max-height: 300px; overflow-y: auto;"></pre>
  </div>
  
  <script>
    function startInstallation() {
      document.getElementById('install-button').disabled = true;
      document.getElementById('status').innerHTML = '<p>Installation in progress...</p>';
      document.getElementById('log-container').style.display = 'block';
      
      // Start polling for log updates
      fetch('/install-start').then(() => {
        pollInstallStatus();
      });
    }
    
    function pollInstallStatus() {
      fetch('/install-status')
        .then(response => response.json())
        .then(data => {
          document.getElementById('install-log').textContent = data.log;
          
          if (data.status === 'completed') {
            document.getElementById('status').innerHTML = '<p class="success">Installation completed successfully!</p>';
            window.location.href = '/dashboard';
          } else if (data.status === 'failed') {
            document.getElementById('status').innerHTML = '<p class="error">Installation failed. Please check the logs.</p>';
          } else {
            // Continue polling
            setTimeout(pollInstallStatus, 2000);
          }
        })
        .catch(error => {
          console.error('Error fetching installation status:', error);
          document.getElementById('status').innerHTML = '<p class="error">Error checking installation status. Please refresh the page.</p>';
        });
    }
  </script>
</div>
{% endblock %}
EOF

  # Create Dashboard page
  cat > "$INSTALLER_DIR/templates/dashboard.html" <<'EOF'
{% extends "layout.html" %}

{% block content %}
<div class="step current">
  <h2>PI-PVR Dashboard</h2>
  
  <div class="progress-container">
    <div class="progress-bar" style="width: 100%">Installation Complete!</div>
  </div>
  
  <div class="notification success-bg">
    <p>Your PI-PVR installation is complete and services are running!</p>
  </div>
  
  <h3>Services:</h3>
  <div class="grid">
    {% for service in services %}
    <div class="service-card">
      <h3>{{ service.name }}</h3>
      {% if service.url %}
      <p><a href="{{ service.url }}" target="_blank" class="service-url">{{ service.url }}</a></p>
      {% else %}
      <p><em>No web interface</em></p>
      {% endif %}
      <p>Status: <span class="{% if service.status == 'running' %}success{% else %}error{% endif %}">{{ service.status }}</span></p>
    </div>
    {% endfor %}
  </div>
  
  <h3>File Shares:</h3>
  <div>
    {% if share_type == 'samba' %}
    <p>Samba Shares:</p>
    <ul>
      <li>Movies: <code>\\{{ server_ip }}\Movies</code></li>
      <li>TV Shows: <code>\\{{ server_ip }}\TVShows</code></li>
      <li>Downloads: <code>\\{{ server_ip }}\Downloads</code></li>
    </ul>
    {% else %}
    <p>NFS Shares:</p>
    <ul>
      <li>Storage: <code>{{ server_ip }}:{{ storage_mount }}</code></li>
      <li>Downloads: <code>{{ server_ip }}:{{ downloads_mount }}</code></li>
    </ul>
    {% endif %}
  </div>
  
  <h3>Management:</h3>
  <div>
    <a href="/reconfigure" class="button">Reconfigure Settings</a>
    <a href="/update" class="button">Check for Updates</a>
    <a href="/restart" class="button">Restart Services</a>
  </div>
</div>
{% endblock %}
EOF

  # Create reconfiguration menu
  cat > "$INSTALLER_DIR/templates/reconfigure.html" <<'EOF'
{% extends "layout.html" %}

{% block content %}
<div class="step current">
  <h2>Reconfigure PI-PVR</h2>
  
  <p>Choose what you want to reconfigure:</p>
  
  <div class="grid">
    <div class="service-card">
      <h3>VPN Settings</h3>
      <p>Change PIA credentials or server region</p>
      <a href="/vpn-setup" class="button">Reconfigure</a>
    </div>
    
    <div class="service-card">
      <h3>Tailscale</h3>
      <p>Update Tailscale authentication</p>
      <a href="/tailscale-setup" class="button">Reconfigure</a>
    </div>
    
    <div class="service-card">
      <h3>Storage</h3>
      <p>Change storage drives and sharing method</p>
      <a href="/storage-setup" class="button">Reconfigure</a>
    </div>
    
    <div class="service-card">
      <h3>Media Folders</h3>
      <p>Update media folder structure</p>
      <a href="/media-setup" class="button">Reconfigure</a>
    </div>
    
    <div class="service-card">
      <h3>Services</h3>
      <p>Change ports and service settings</p>
      <a href="/services-setup" class="button">Reconfigure</a>
    </div>
  </div>
  
  <div style="margin-top: 20px;">
    <a href="/dashboard" class="button">Back to Dashboard</a>
  </div>
</div>
{% endblock %}
EOF

  log "Web templates created successfully"
}

# Create Python Flask application
create_flask_app() {
  log "Creating Flask application..."
  
  cat > "$INSTALLER_DIR/app.py" <<'EOF'
#!/usr/bin/env python3
from flask import Flask, render_template, request, redirect, url_for, jsonify
import os
import subprocess
import json
import time
import re
import threading
import shutil

app = Flask(__name__)

# Get environment variables
HOME_DIR = os.path.expanduser("~")
SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
SERVER_IP = os.environ.get('SERVER_IP', 'localhost')
PORT = int(os.environ.get('PORT', 8080))
DOCKER_DIR = os.path.join(HOME_DIR, "docker")
ENV_FILE = os.path.join(DOCKER_DIR, ".env")
INSTALLER_DIR = os.path.join(HOME_DIR, ".pi-pvr-installer")
INSTALLER_LOG = os.path.join(INSTALLER_DIR, "installer.log")
ORIG_SCRIPT_PATH = os.path.join(os.path.dirname(SCRIPT_DIR), "pi-pvr.sh")

# Global config object
config = {
    "pia_username": "",
    "pia_password": "",
    "server_region": "Netherlands",
    "tailscale_auth_key": "",
    "share_method": "samba",
    "movies_folder": "Movies",
    "tvshows_folder": "TVShows",
    "downloads_folder": "/mnt/storage/downloads",
    "timezone": "Europe/London",
    "jacket_port": "9117",
    "sonarr_port": "8989",
    "radarr_port": "7878",
    "transmission_port": "9091",
    "nzbget_port": "6789",
    "get_iplayer_port": "1935",
    "jellyfin_port": "8096",
    "jellyfin_https_port": "8920",
    "storage_drive": "",
    "download_drive": "",
    "storage_mount": "/mnt/storage",
    "download_mount": "/mnt/downloads",
    "installation_status": "not_started"
}

# Load existing config if available
def load_config():
    global config
    config_file = os.path.join(INSTALLER_DIR, "config.json")
    if os.path.exists(config_file):
        with open(config_file, "r") as f:
            config.update(json.load(f))

# Save config
def save_config():
    config_file = os.path.join(INSTALLER_DIR, "config.json")
    with open(config_file, "w") as f:
        json.dump(config, f, indent=2)

# Initialize by loading config
load_config()

# Welcome page
@app.route('/')
def welcome():
    return render_template('welcome.html', server_ip=SERVER_IP, port=PORT)

# System check page
@app.route('/system-check')
def system_check():
    checks = [
        {"name": "Docker", "status": check_docker(), "message": "Docker is not installed."},
        {"name": "Disk Space", "status": check_disk_space(), "message": "Insufficient disk space."},
        {"name": "Memory", "status": check_memory(), "message": "Insufficient memory."},
        {"name": "Python", "status": True, "message": ""}  # Python is already running this app
    ]
    
    all_passed = all(check["status"] for check in checks)
    
    return render_template('system_check.html', checks=checks, all_passed=all_passed)

# VPN setup page
@app.route('/vpn-setup')
def vpn_setup():
    return render_template('vpn_setup.html', 
                          pia_username=config["pia_username"],
                          pia_password=config["pia_password"],
                          server_region=config["server_region"])

# Save VPN config
@app.route('/vpn-save', methods=['POST'])
def vpn_save():
    config["pia_username"] = request.form.get("pia_username", "")
    config["pia_password"] = request.form.get("pia_password", "")
    config["server_region"] = request.form.get("server_region", "Netherlands")
    save_config()
    return redirect(url_for('tailscale_setup'))

# Tailscale setup page
@app.route('/tailscale-setup')
def tailscale_setup():
    return render_template('tailscale_setup.html', tailscale_auth_key=config["tailscale_auth_key"])

# Save Tailscale config
@app.route('/tailscale-save', methods=['POST'])
def tailscale_save():
    config["tailscale_auth_key"] = request.form.get("tailscale_auth_key", "")
    save_config()
    return redirect(url_for('storage_setup'))

# Storage setup page
@app.route('/storage-setup')
def storage_setup():
    drives = get_available_drives()
    return render_template('storage_setup.html', 
                          drives=drives, 
                          share_method=config["share_method"])

# Save Storage config
@app.route('/storage-save', methods=['POST'])
def storage_save():
    config["share_method"] = request.form.get("share_method", "samba")
    
    drives = get_available_drives()
    for drive in drives:
        drive_key = drive["device"].replace("/", "_")
        drive_use = request.form.get(f"drive_use_{drive_key}", "")
        
        if drive_use == "media":
            config["storage_drive"] = drive["device"]
        elif drive_use == "downloads":
            config["download_drive"] = drive["device"]
        elif drive_use == "both":
            config["storage_drive"] = drive["device"]
            config["download_drive"] = drive["device"]
    
    save_config()
    return redirect(url_for('media_setup'))

# Media setup page
@app.route('/media-setup')
def media_setup():
    return render_template('media_setup.html',
                          movies_folder=config["movies_folder"],
                          tvshows_folder=config["tvshows_folder"],
                          downloads_folder=config["downloads_folder"])

# Save Media config
@app.route('/media-save', methods=['POST'])
def media_save():
    config["movies_folder"] = request.form.get("movies_folder", "Movies")
    config["tvshows_folder"] = request.form.get("tvshows_folder", "TVShows")
    config["downloads_folder"] = request.form.get("downloads_folder", "/mnt/storage/downloads")
    save_config()
    return redirect(url_for('services_setup'))

# Services setup page
@app.route('/services-setup')
def services_setup():
    return render_template('services_setup.html',
                          jacket_port=config["jacket_port"],
                          sonarr_port=config["sonarr_port"],
                          radarr_port=config["radarr_port"],
                          transmission_port=config["transmission_port"],
                          nzbget_port=config["nzbget_port"],
                          get_iplayer_port=config["get_iplayer_port"],
                          jellyfin_port=config["jellyfin_port"],
                          jellyfin_https_port=config["jellyfin_https_port"],
                          timezone=config["timezone"])

# Save Services config
@app.route('/services-save', methods=['POST'])
def services_save():
    config["jacket_port"] = request.form.get("jacket_port", "9117")
    config["sonarr_port"] = request.form.get("sonarr_port", "8989")
    config["radarr_port"] = request.form.get("radarr_port", "7878")
    config["transmission_port"] = request.form.get("transmission_port", "9091")
    config["nzbget_port"] = request.form.get("nzbget_port", "6789")
    config["get_iplayer_port"] = request.form.get("get_iplayer_port", "1935")
    config["jellyfin_port"] = request.form.get("jellyfin_port", "8096")
    config["jellyfin_https_port"] = request.form.get("jellyfin_https_port", "8920")
    config["timezone"] = request.form.get("timezone", "Europe/London")
    save_config()
    return redirect(url_for('installation'))

# Installation page
@app.route('/installation')
def installation():
    return render_template('installation.html')

# Start installation
@app.route('/install-start')
def install_start():
    # Set installation status
    config["installation_status"] = "in_progress"
    save_config()
    
    # Start installation in a separate thread
    thread = threading.Thread(target=run_installation)
    thread.daemon = True
    thread.start()
    
    return jsonify({"status": "started"})

# Installation status
@app.route('/install-status')
def install_status():
    # Read the installation log
    log_content = ""
    if os.path.exists(INSTALLER_LOG):
        with open(INSTALLER_LOG, "r") as f:
            log_content = f.read()
    
    return jsonify({
        "status": config["installation_status"],
        "log": log_content
    })

# Dashboard page
@app.route('/dashboard')
def dashboard():
    services = get_services_status()
    
    return render_template('dashboard.html',
                          services=services,
                          share_type=config["share_method"],
                          server_ip=SERVER_IP,
                          storage_mount=config["storage_mount"],
                          downloads_mount=config["download_mount"])

# Reconfiguration menu
@app.route('/reconfigure')
def reconfigure():
    return render_template('reconfigure.html')

# Update check
@app.route('/update')
def update():
    # Run the update command
    try:
        subprocess.run([ORIG_SCRIPT_PATH, "--update"], check=True)
        return redirect(url_for('dashboard'))
    except subprocess.CalledProcessError:
        return "Error running update", 500

# Restart services
@app.route('/restart')
def restart():
    # Restart the Docker containers
    try:
        subprocess.run(["docker", "compose", "-f", os.path.join(DOCKER_DIR, "docker-compose.yml"), "restart"], check=True)
        return redirect(url_for('dashboard'))
    except subprocess.CalledProcessError:
        return "Error restarting services", 500

# Helper Functions
def check_docker():
    try:
        result = subprocess.run(["docker", "--version"], capture_output=True, text=True)
        return result.returncode == 0
    except:
        return False

def check_disk_space():
    # Check for at least 5GB of free space
    try:
        result = subprocess.run(["df", "-BG", "/"], capture_output=True, text=True)
        lines = result.stdout.strip().split('\n')
        if len(lines) >= 2:
            parts = lines[1].split()
            if len(parts) >= 4:
                free_space = int(parts[3].replace('G', ''))
                return free_space >= 5
    except:
        pass
    return False

def check_memory():
    # Check for at least 2GB of RAM
    try:
        with open("/proc/meminfo", "r") as f:
            meminfo = f.read()
        match = re.search(r'MemTotal:\s+(\d+)', meminfo)
        if match:
            mem_kb = int(match.group(1))
            mem_gb = mem_kb / 1024 / 1024
            return mem_gb >= 2
    except:
        pass
    return False

def get_available_drives():
    drives = []
    try:
        result = subprocess.run(["lsblk", "-o", "NAME,SIZE,TYPE,FSTYPE", "-J"], capture_output=True, text=True)
        data = json.loads(result.stdout)
        for device in data.get("blockdevices", []):
            if device.get("type") == "disk":
                for partition in device.get("children", []):
                    if partition.get("type") == "part" and partition.get("fstype"):
                        drives.append({
                            "device": f"/dev/{partition['name']}",
                            "size": partition["size"],
                            "type": partition["fstype"]
                        })
    except:
        # Fallback to manual parsing if JSON output fails
        try:
            result = subprocess.run(["lsblk", "-o", "NAME,SIZE,TYPE,FSTYPE"], capture_output=True, text=True)
            lines = result.stdout.strip().split('\n')[1:]  # Skip header
            for line in lines:
                parts = line.split()
                if len(parts) >= 4 and parts[2] == "part" and parts[3]:
                    drives.append({
                        "device": f"/dev/{parts[0]}",
                        "size": parts[1],
                        "type": parts[3]
                    })
        except:
            pass
    return drives

def get_services_status():
    services = [
        {"name": "VPN (Gluetun)", "url": None, "status": "unknown"},
        {"name": "Jackett", "url": f"http://{SERVER_IP}:{config['jacket_port']}", "status": "unknown"},
        {"name": "Sonarr", "url": f"http://{SERVER_IP}:{config['sonarr_port']}", "status": "unknown"},
        {"name": "Radarr", "url": f"http://{SERVER_IP}:{config['radarr_port']}", "status": "unknown"},
        {"name": "Transmission", "url": f"http://{SERVER_IP}:{config['transmission_port']}", "status": "unknown"},
        {"name": "NZBGet", "url": f"http://{SERVER_IP}:{config['nzbget_port']}", "status": "unknown"},
        {"name": "Get iPlayer", "url": f"http://{SERVER_IP}:{config['get_iplayer_port']}", "status": "unknown"},
        {"name": "Jellyfin", "url": f"http://{SERVER_IP}:{config['jellyfin_port']}", "status": "unknown"},
        {"name": "Watchtower", "url": None, "status": "unknown"}
    ]
    
    # Check container status
    try:
        result = subprocess.run(["docker", "ps", "--format", "{{.Names}}"], capture_output=True, text=True)
        running_containers = result.stdout.strip().split('\n')
        
        container_map = {
            "VPN (Gluetun)": "vpn",
            "Jackett": "jackett",
            "Sonarr": "sonarr",
            "Radarr": "radarr",
            "Transmission": "transmission",
            "NZBGet": "nzbget",
            "Get iPlayer": "get_iplayer",
            "Jellyfin": "jellyfin",
            "Watchtower": "watchtower"
        }
        
        for service in services:
            container_name = container_map.get(service["name"])
            if container_name and container_name in running_containers:
                service["status"] = "running"
            else:
                service["status"] = "stopped"
    except:
        pass  # Keep status as "unknown"
    
    return services

def run_installation():
    try:
        with open(INSTALLER_LOG, "w") as f:
            f.write("Starting installation...\n")
        
        # Create the .env file
        create_env_file()
        
        # Run installation steps
        if config["tailscale_auth_key"]:
            setup_tailscale()
        
        install_dependencies()
        setup_pia_vpn()
        create_docker_compose()
        
        if config["share_method"] == "samba":
            setup_usb_and_samba()
        else:
            setup_usb_and_nfs()
        
        setup_docker_network()
        deploy_docker_compose()
        
        # Mark installation as completed
        config["installation_status"] = "completed"
        save_config()
        
        with open(INSTALLER_LOG, "a") as f:
            f.write("Installation completed successfully!\n")
    except Exception as e:
        # Log the error
        with open(INSTALLER_LOG, "a") as f:
            f.write(f"Installation failed: {str(e)}\n")
        
        # Mark installation as failed
        config["installation_status"] = "failed"
        save_config()

def create_env_file():
    # Create docker directory if it doesn't exist
    os.makedirs(DOCKER_DIR, exist_ok=True)
    
    with open(INSTALLER_LOG, "a") as log:
        log.write("Creating .env file...\n")
    
    # Create .env file with proper quoting
    env_content = f"""#General Docker
DOCKER_DIR="{DOCKER_DIR}"
DOCKER_COMPOSE_URL="https://raw.githubusercontent.com/Brownster/docker-compose-pi/refs/heads/main/docker-compose.yml"

# Docker Configuration
TIMEZONE="{config["timezone"]}"
IMAGE_RELEASE="latest"
PUID=1000
PGID=1000

# Media folder names
MOVIES_FOLDER="{config["movies_folder"]}"
TVSHOWS_FOLDER="{config["tvshows_folder"]}"
DOWNLOADS="{config["downloads_folder"]}"
STORAGE_MOUNT="{config["storage_mount"]}"

# Samba Variable
SAMBA_CONFIG="/etc/samba/smb.conf"

#Tailscale
TAILSCALE_AUTH_KEY="{config["tailscale_auth_key"]}"

#PORTS
JACKET_PORT="{config["jacket_port"]}"
SONARR_PORT="{config["sonarr_port"]}"
RADARR_PORT="{config["radarr_port"]}"
TRANSMISSION_PORT="{config["transmission_port"]}"
NZBGET="{config["nzbget_port"]}"
GET_IPLAYER_PORT="{config["get_iplayer_port"]}"
MEDIASERVER_HTTP="{config["jellyfin_port"]}"
MEDIASERVER_HTTPS="{config["jellyfin_https_port"]}"

# VPN Configuration
PIA_USERNAME="{config["pia_username"]}"
PIA_PASSWORD="{config["pia_password"]}"
VPN_CONTAINER="vpn"
VPN_IMAGE="qmcgaw/gluetun"
CONTAINER_NETWORK="vpn_network"

#Jacket
JACKETT_CONTAINER="jackett"
JACKETT_IMAGE="linuxserver/jackett"

#Sonarr
SONARR_CONTAINER="sonarr"
SONARR_IMAGE="linuxserver/sonarr"
SONARR_API_KEY="your_sonarr_api_key"

#Radarr
RADARR_CONTAINER="radarr"
RADARR_IMAGE="linuxserver/radarr"
RADARR_API_KEY="your_radarr_api_key"

#Transmission
TRANSMISSION_CONTAINER="transmission"
TRANSMISSION_IMAGE="linuxserver/transmission"

#NZBGet
NZBGET_CONTAINER="nzbget"
NZBGET_IMAGE="linuxserver/nzbget"

#Get Iplayer
GET_IPLAYER="get_iplayer"
GET_IPLAYER_IMAGE="ghcr.io/thespad/get_iplayer"
INCLUDERADIO="true"
ENABLEIMPORT="true"

#JellyFin
JELLYFIN_CONTAINER="jellyfin"
JELLYFIN_IMAGE="linuxserver/jellyfin"

#WatchTower
WATCHTOWER_CONTAINER="watchtower"
WATCHTOWER_IMAGE="containrrr/watchtower"

#Track runs
tailscale_install_success=0
PIA_SETUP_SUCCESS=0
SHARE_SETUP_SUCCESS=0
docker_install_success=0
pia_vpn_setup_success=0
docker_compose_success=0
CREATE_CONFIG_SUCCESS=0
INSTALL_DEPENDANCIES_SUCCESS=0
DOCKER_NETWORK_SUCCESS=0
"""
    
    with open(ENV_FILE, "w") as f:
        f.write(env_content)
    
    # Set permissions
    os.chmod(ENV_FILE, 0o600)
    
    with open(INSTALLER_LOG, "a") as log:
        log.write("Created .env file successfully\n")

def setup_tailscale():
    with open(INSTALLER_LOG, "a") as log:
        log.write("Installing Tailscale...\n")
    
    # Install Tailscale
    try:
        subprocess.run("curl -fsSL https://tailscale.com/install.sh | bash", shell=True, check=True)
        
        # Start Tailscale with auth key if provided
        if config["tailscale_auth_key"]:
            cmd = f"sudo tailscale up --accept-routes=false --authkey={config['tailscale_auth_key']}"
        else:
            cmd = "sudo tailscale up --accept-routes=false"
        
        subprocess.run(cmd, shell=True, check=True)
        
        with open(INSTALLER_LOG, "a") as log:
            log.write("Tailscale installed and running\n")
    except subprocess.CalledProcessError as e:
        with open(INSTALLER_LOG, "a") as log:
            log.write(f"Tailscale installation failed: {str(e)}\n")
        raise

def install_dependencies():
    with open(INSTALLER_LOG, "a") as log:
        log.write("Installing dependencies...\n")
    
    try:
        # Update package list
        subprocess.run("sudo apt update", shell=True, check=True)
        
        # Install required packages
        subprocess.run("sudo apt install -y curl jq git", shell=True, check=True)
        
        # Remove conflicting Docker packages
        subprocess.run("for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove -y $pkg; done", shell=True)
        
        # Install Docker
        subprocess.run("""
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
""", shell=True, check=True)
        
        # Verify Docker installation
        subprocess.run("sudo docker run hello-world", shell=True, check=True)
        
        with open(INSTALLER_LOG, "a") as log:
            log.write("Dependencies installed successfully\n")
    except subprocess.CalledProcessError as e:
        with open(INSTALLER_LOG, "a") as log:
            log.write(f"Dependency installation failed: {str(e)}\n")
        raise

def setup_pia_vpn():
    with open(INSTALLER_LOG, "a") as log:
        log.write("Setting up PIA VPN...\n")
    
    try:
        # Create gluetun directory
        gluetun_dir = os.path.join(DOCKER_DIR, "vpn")
        os.makedirs(gluetun_dir, exist_ok=True)
        
        # Create gluetun .env file
        vpn_env_content = f"""VPN_SERVICE_PROVIDER=private internet access
OPENVPN_USER={config["pia_username"]}
OPENVPN_PASSWORD={config["pia_password"]}
SERVER_REGIONS={config["server_region"]}
"""
        with open(os.path.join(gluetun_dir, ".env"), "w") as f:
            f.write(vpn_env_content)
        
        with open(INSTALLER_LOG, "a") as log:
            log.write("PIA VPN setup completed\n")
    except Exception as e:
        with open(INSTALLER_LOG, "a") as log:
            log.write(f"PIA VPN setup failed: {str(e)}\n")
        raise

def create_docker_compose():
    with open(INSTALLER_LOG, "a") as log:
        log.write("Creating Docker Compose file...\n")
    
    try:
        # Create the docker-compose.yml content directly
        compose_content = f"""version: "3.8"
services:
  vpn:
    image: qmcgaw/gluetun:latest
    container_name: vpn
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    volumes:
      - "{DOCKER_DIR}/vpn:/gluetun"
    env_file:
      - {DOCKER_DIR}/vpn/.env
    healthcheck:
      test: curl --fail http://localhost:8000 || exit 1
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped
    ports:
      - {config["jacket_port"]}:{config["jacket_port"]}
      - {config["sonarr_port"]}:{config["sonarr_port"]}
      - {config["radarr_port"]}:{config["radarr_port"]}
      - {config["transmission_port"]}:{config["transmission_port"]}
      - {config["nzbget_port"]}:{config["nzbget_port"]}
    networks:
      - vpn_network

  jackett:
    image: linuxserver/jackett:latest
    container_name: jackett
    network_mode: "service:vpn"
    environment:
      - TZ={config["timezone"]}
      - PUID=1000
      - PGID=1000
    volumes:
      - {DOCKER_DIR}/jackett:/config
      - {config["downloads_folder"]}:/downloads
    restart: unless-stopped

  sonarr:
    image: linuxserver/sonarr:latest
    container_name: sonarr
    network_mode: "service:vpn"
    environment:
      - TZ={config["timezone"]}
      - PUID=1000
      - PGID=1000
    volumes:
      - {DOCKER_DIR}/sonarr:/config
      - {config["storage_mount"]}/{config["tvshows_folder"]}:/tv
      - {config["downloads_folder"]}:/downloads
    restart: unless-stopped

  radarr:
    image: linuxserver/radarr:latest
    container_name: radarr
    network_mode: "service:vpn"
    environment:
      - TZ={config["timezone"]}
      - PUID=1000
      - PGID=1000
    volumes:
      - {DOCKER_DIR}/radarr:/config
      - {config["storage_mount"]}/{config["movies_folder"]}:/movies
      - {config["downloads_folder"]}:/downloads
    restart: unless-stopped

  transmission:
    image: linuxserver/transmission:latest
    container_name: transmission
    network_mode: "service:vpn"
    environment:
      - TZ={config["timezone"]}
      - PUID=1000
      - PGID=1000
    volumes:
      - {DOCKER_DIR}/transmission:/config
      - {config["downloads_folder"]}:/downloads
    restart: unless-stopped

  nzbget:
    image: linuxserver/nzbget:latest
    container_name: nzbget
    network_mode: "service:vpn"
    environment:
      - TZ={config["timezone"]}
      - PUID=1000
      - PGID=1000
    volumes:
      - {DOCKER_DIR}/nzbget:/config
      - {config["downloads_folder"]}/incomplete:/incomplete
      - {config["downloads_folder"]}/complete:/complete
    restart: unless-stopped

  get_iplayer:
    image: ghcr.io/thespad/get_iplayer:latest
    container_name: get_iplayer
    network_mode: bridge
    environment:
      - TZ={config["timezone"]}
      - PUID=1000
      - PGID=1000
      - INCLUDERADIO=true
      - ENABLEIMPORT=true
    volumes:
      - {DOCKER_DIR}/get_iplayer/config:/config
      - {config["downloads_folder"]}/complete:/downloads
    ports:
      - {config["get_iplayer_port"]}:{config["get_iplayer_port"]}
    restart: unless-stopped

  jellyfin:
    image: linuxserver/jellyfin:latest
    container_name: jellyfin
    network_mode: bridge
    environment:
      - TZ={config["timezone"]}
      - PUID=1000
      - PGID=1000
    volumes:
      - {DOCKER_DIR}/jellyfin:/config
      - {config["storage_mount"]}:/media
    ports:
      - {config["jellyfin_port"]}:{config["jellyfin_port"]}
      - {config["jellyfin_https_port"]}:{config["jellyfin_https_port"]}
    restart: unless-stopped

  watchtower:
    image: containrrr/watchtower:latest
    container_name: watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_POLL_INTERVAL=3600
    restart: unless-stopped

networks:
  vpn_network:
    driver: bridge
"""
        
        # Write the docker-compose.yml file
        with open(os.path.join(DOCKER_DIR, "docker-compose.yml"), "w") as f:
            f.write(compose_content)
        
        with open(INSTALLER_LOG, "a") as log:
            log.write("Docker Compose file created successfully\n")
    except Exception as e:
        with open(INSTALLER_LOG, "a") as log:
            log.write(f"Docker Compose creation failed: {str(e)}\n")
        raise

def setup_usb_and_samba():
    with open(INSTALLER_LOG, "a") as log:
        log.write("Setting up Samba shares...\n")
    
    try:
        if not config["storage_drive"]:
            raise Exception("No storage drive selected")
        
        # Mount the storage drive
        subprocess.run(f"sudo mkdir -p {config['storage_mount']}", shell=True, check=True)
        subprocess.run(f"sudo mount {config['storage_drive']} {config['storage_mount']}", shell=True, check=True)
        
        # Mount the download drive if different
        if config['download_drive'] and config['download_drive'] != config['storage_drive']:
            subprocess.run(f"sudo mkdir -p {config['download_mount']}", shell=True, check=True)
            subprocess.run(f"sudo mount {config['download_drive']} {config['download_mount']}", shell=True, check=True)
        elif not config['download_drive']:
            # If no download drive specified, use the storage drive and create a downloads folder
            config['download_mount'] = os.path.join(config['storage_mount'], 'downloads')
        
        # Create media directories
        movies_dir = os.path.join(config['storage_mount'], config['movies_folder'])
        tvshows_dir = os.path.join(config['storage_mount'], config['tvshows_folder'])
        downloads_dir = config['download_mount']
        
        subprocess.run(f"sudo mkdir -p {movies_dir} {tvshows_dir} {downloads_dir}", shell=True, check=True)
        
        # Install Samba
        subprocess.run("sudo apt-get install -y samba samba-common-bin", shell=True, check=True)
        
        # Add shares to smb.conf
        with open("/tmp/smb_shares.conf", "w") as f:
            f.write(f"""
[Movies]
   path = {movies_dir}
   browseable = yes
   read only = no
   guest ok = yes

[TVShows]
   path = {tvshows_dir}
   browseable = yes
   read only = no
   guest ok = yes

[Downloads]
   path = {downloads_dir}
   browseable = yes
   read only = no
   guest ok = yes
""")
        
        subprocess.run("sudo bash -c 'cat /tmp/smb_shares.conf >> /etc/samba/smb.conf'", shell=True, check=True)
        subprocess.run("sudo systemctl restart smbd", shell=True, check=True)
        
        # Update fstab for persistence
        try:
            storage_uuid = subprocess.run(f"sudo blkid -s UUID -o value {config['storage_drive']}", 
                                       shell=True, check=True, capture_output=True, text=True).stdout.strip()
            
            fstab_entry = f"UUID={storage_uuid} {config['storage_mount']} auto defaults 0 2"
            
            with open("/tmp/fstab_entry", "w") as f:
                f.write(fstab_entry + "\n")
            
            subprocess.run("sudo bash -c 'cat /tmp/fstab_entry >> /etc/fstab'", shell=True, check=True)
            
            # If separate download drive
            if config['download_drive'] and config['download_drive'] != config['storage_drive']:
                download_uuid = subprocess.run(f"sudo blkid -s UUID -o value {config['download_drive']}", 
                                           shell=True, check=True, capture_output=True, text=True).stdout.strip()
                
                fstab_entry = f"UUID={download_uuid} {config['download_mount']} auto defaults 0 2"
                
                with open("/tmp/fstab_entry_dl", "w") as f:
                    f.write(fstab_entry + "\n")
                
                subprocess.run("sudo bash -c 'cat /tmp/fstab_entry_dl >> /etc/fstab'", shell=True, check=True)
        except Exception as e:
            with open(INSTALLER_LOG, "a") as log:
                log.write(f"Warning: Could not update fstab: {str(e)}\n")
        
        with open(INSTALLER_LOG, "a") as log:
            log.write("Samba shares setup completed\n")
    except Exception as e:
        with open(INSTALLER_LOG, "a") as log:
            log.write(f"Samba setup failed: {str(e)}\n")
        raise

def setup_usb_and_nfs():
    with open(INSTALLER_LOG, "a") as log:
        log.write("Setting up NFS shares...\n")
    
    try:
        if not config["storage_drive"]:
            raise Exception("No storage drive selected")
        
        # Install NFS server
        subprocess.run("sudo apt-get install -y nfs-kernel-server", shell=True, check=True)
        
        # Mount the storage drive
        subprocess.run(f"sudo mkdir -p {config['storage_mount']}", shell=True, check=True)
        subprocess.run(f"sudo mount {config['storage_drive']} {config['storage_mount']}", shell=True, check=True)
        
        # Mount the download drive if different
        if config['download_drive'] and config['download_drive'] != config['storage_drive']:
            subprocess.run(f"sudo mkdir -p {config['download_mount']}", shell=True, check=True)
            subprocess.run(f"sudo mount {config['download_drive']} {config['download_mount']}", shell=True, check=True)
        elif not config['download_drive']:
            # If no download drive specified, use the storage drive and create a downloads folder
            config['download_mount'] = os.path.join(config['storage_mount'], 'downloads')
        
        # Create media directories
        movies_dir = os.path.join(config['storage_mount'], config['movies_folder'])
        tvshows_dir = os.path.join(config['storage_mount'], config['tvshows_folder'])
        downloads_dir = config['download_mount']
        
        subprocess.run(f"sudo mkdir -p {movies_dir} {tvshows_dir} {downloads_dir}", shell=True, check=True)
        
        # Add exports
        with open("/tmp/exports", "w") as f:
            f.write(f"{config['storage_mount']} *(rw,sync,no_subtree_check,no_root_squash)\n")
            f.write(f"{config['download_mount']} *(rw,sync,no_subtree_check,no_root_squash)\n")
        
        subprocess.run("sudo bash -c 'cat /tmp/exports >> /etc/exports'", shell=True, check=True)
        
        # Export and restart NFS
        subprocess.run("sudo exportfs -ra", shell=True, check=True)
        subprocess.run("sudo systemctl restart nfs-kernel-server", shell=True, check=True)
        
        # Update fstab for persistence
        try:
            storage_uuid = subprocess.run(f"sudo blkid -s UUID -o value {config['storage_drive']}", 
                                       shell=True, check=True, capture_output=True, text=True).stdout.strip()
            
            fstab_entry = f"UUID={storage_uuid} {config['storage_mount']} auto defaults 0 2"
            
            with open("/tmp/fstab_entry", "w") as f:
                f.write(fstab_entry + "\n")
            
            subprocess.run("sudo bash -c 'cat /tmp/fstab_entry >> /etc/fstab'", shell=True, check=True)
            
            # If separate download drive
            if config['download_drive'] and config['download_drive'] != config['storage_drive']:
                download_uuid = subprocess.run(f"sudo blkid -s UUID -o value {config['download_drive']}", 
                                           shell=True, check=True, capture_output=True, text=True).stdout.strip()
                
                fstab_entry = f"UUID={download_uuid} {config['download_mount']} auto defaults 0 2"
                
                with open("/tmp/fstab_entry_dl", "w") as f:
                    f.write(fstab_entry + "\n")
                
                subprocess.run("sudo bash -c 'cat /tmp/fstab_entry_dl >> /etc/fstab'", shell=True, check=True)
        except Exception as e:
            with open(INSTALLER_LOG, "a") as log:
                log.write(f"Warning: Could not update fstab: {str(e)}\n")
        
        with open(INSTALLER_LOG, "a") as log:
            log.write("NFS shares setup completed\n")
    except Exception as e:
        with open(INSTALLER_LOG, "a") as log:
            log.write(f"NFS setup failed: {str(e)}\n")
        raise

def setup_docker_network():
    with open(INSTALLER_LOG, "a") as log:
        log.write("Setting up Docker network...\n")
    
    try:
        # Ensure Docker is running
        subprocess.run("sudo systemctl start docker", shell=True, check=True)
        
        # Create VPN network if it doesn't exist
        network_check = subprocess.run("docker network ls | grep vpn_network", shell=True, capture_output=True, text=True)
        if "vpn_network" not in network_check.stdout:
            subprocess.run("docker network create vpn_network", shell=True, check=True)
        
        with open(INSTALLER_LOG, "a") as log:
            log.write("Docker network setup completed\n")
    except subprocess.CalledProcessError as e:
        with open(INSTALLER_LOG, "a") as log:
            log.write(f"Docker network setup failed: {str(e)}\n")
        raise

def deploy_docker_compose():
    with open(INSTALLER_LOG, "a") as log:
        log.write("Deploying Docker Compose stack...\n")
    
    try:
        # Add current user to docker group if not already
        groups_result = subprocess.run("groups", shell=True, capture_output=True, text=True)
        if "docker" not in groups_result.stdout:
            subprocess.run("sudo usermod -aG docker $USER", shell=True, check=True)
            with open(INSTALLER_LOG, "a") as log:
                log.write("Added user to docker group. You may need to log out and log back in.\n")
        
        # Deploy the stack with sudo to avoid permission issues
        subprocess.run(f"sudo docker compose -f {DOCKER_DIR}/docker-compose.yml up -d", shell=True, check=True)
        
        with open(INSTALLER_LOG, "a") as log:
            log.write("Docker Compose stack deployed successfully\n")
    except subprocess.CalledProcessError as e:
        with open(INSTALLER_LOG, "a") as log:
            log.write(f"Docker Compose deployment failed: {str(e)}\n")
        raise

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT, debug=True)
EOF

  # Make the app executable
  chmod +x "$INSTALLER_DIR/app.py"
  
  log "Flask application created successfully"
}

# Create a custom web-installer option for the pi-pvr.sh script
create_web_installer_option() {
  log "Adding web installer option to pi-pvr.sh..."
  
  # Check if pi-pvr.sh exists
  if [[ -f "/home/marc/Documents/github/PI-PVR-0.1/pi-pvr.sh" ]]; then
    # Create a function to start the web installer
    START_WEB_INSTALLER_FUNCTION='# Start the web-based installer
start_web_installer() {
    echo "Starting PI-PVR Web Installer..."
    $HOME/.pi-pvr-installer/app.py
}'
    
    # We'll modify the script manually to avoid awk issues
    # The main pi-pvr.sh should already have the web-installer option added
    log "Web installer integration complete"
    
    # Make the script executable
    chmod +x "/home/marc/Documents/github/PI-PVR-0.1/pi-pvr.sh"
    
    log "Web installer option added to pi-pvr.sh"
  else
    log "Could not find pi-pvr.sh. Please manually add the web installer option."
  fi
}

# Start the web installer
start_installer() {
  log "Starting the web installer..."
  
  # Create the web templates and Flask app
  check_dependencies
  create_templates
  create_flask_app
  create_web_installer_option
  
  # Export environment variables for the Flask app
  export SERVER_IP="$SERVER_IP"
  export PORT="$PORT"
  
  # Start the Flask app
  cd "$INSTALLER_DIR"
  python3 app.py
}

# Main function
main() {
  start_installer
}

main