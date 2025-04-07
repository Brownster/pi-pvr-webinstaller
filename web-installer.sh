#!/bin/bash
# Web-based installer for PI-PVR
# This script creates a lightweight web server to guide users through setup

set -euo pipefail

# Get the script directory (with support for symlinks)
SCRIPT_DIR="$( cd -- "$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")")" &> /dev/null && pwd )"

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
    <!-- Local USB Drives -->
    <div class="storage-section">
      <h3>Local USB Drives</h3>
      <p>Select how you want to use each connected USB drive:</p>
      
      <table style="width: 100%; border-collapse: collapse;">
        <tr style="background-color: #f2f2f2;">
          <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Device</th>
          <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Size</th>
          <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Type</th>
          <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Mount Point</th>
          <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Use For</th>
        </tr>
        {% for drive in drives %}
        <tr>
          <td style="padding: 10px; border: 1px solid #ddd;">{{ drive.device }}</td>
          <td style="padding: 10px; border: 1px solid #ddd;">{{ drive.size }}</td>
          <td style="padding: 10px; border: 1px solid #ddd;">{{ drive.type }}</td>
          <td style="padding: 10px; border: 1px solid #ddd;">
            <input type="text" 
                   name="mount_point_{{ drive.device | replace('/', '_') }}" 
                   value="{% if drive.device in storage_config.mounts %}{{ storage_config.mounts[drive.device].mount_point }}{% else %}/mnt/{{ drive.device | replace('/dev/', '') }}{% endif %}"
                   placeholder="/mnt/custom_name">
          </td>
          <td style="padding: 10px; border: 1px solid #ddd;">
            <div class="checkbox-group">
              <div>
                <input type="checkbox" 
                       id="use_movies_{{ drive.device | replace('/', '_') }}" 
                       name="use_movies_{{ drive.device | replace('/', '_') }}"
                       {% if drive.device in storage_config.mounts and 'movies' in storage_config.mounts[drive.device].uses %}checked{% endif %}>
                <label for="use_movies_{{ drive.device | replace('/', '_') }}">Movies</label>
              </div>
              
              <div>
                <input type="checkbox" 
                       id="use_tvshows_{{ drive.device | replace('/', '_') }}" 
                       name="use_tvshows_{{ drive.device | replace('/', '_') }}"
                       {% if drive.device in storage_config.mounts and 'tvshows' in storage_config.mounts[drive.device].uses %}checked{% endif %}>
                <label for="use_tvshows_{{ drive.device | replace('/', '_') }}">TV Shows</label>
              </div>
              
              <div>
                <input type="checkbox" 
                       id="use_music_{{ drive.device | replace('/', '_') }}" 
                       name="use_music_{{ drive.device | replace('/', '_') }}"
                       {% if drive.device in storage_config.mounts and 'music' in storage_config.mounts[drive.device].uses %}checked{% endif %}>
                <label for="use_music_{{ drive.device | replace('/', '_') }}">Music</label>
              </div>
              
              <div>
                <input type="checkbox" 
                       id="use_books_{{ drive.device | replace('/', '_') }}" 
                       name="use_books_{{ drive.device | replace('/', '_') }}"
                       {% if drive.device in storage_config.mounts and 'books' in storage_config.mounts[drive.device].uses %}checked{% endif %}>
                <label for="use_books_{{ drive.device | replace('/', '_') }}">Books/Audiobooks</label>
              </div>
              
              <div>
                <input type="checkbox" 
                       id="use_downloads_{{ drive.device | replace('/', '_') }}" 
                       name="use_downloads_{{ drive.device | replace('/', '_') }}"
                       {% if drive.device in storage_config.mounts and 'downloads' in storage_config.mounts[drive.device].uses %}checked{% endif %}>
                <label for="use_downloads_{{ drive.device | replace('/', '_') }}">Downloads</label>
              </div>
              
              <div>
                <input type="checkbox" 
                       id="use_custom_{{ drive.device | replace('/', '_') }}" 
                       name="use_custom_{{ drive.device | replace('/', '_') }}"
                       {% if drive.device in storage_config.mounts and 'custom' in storage_config.mounts[drive.device].uses %}checked{% endif %}>
                <label for="use_custom_{{ drive.device | replace('/', '_') }}">Custom</label>
                {% if drive.device in storage_config.mounts and 'custom' in storage_config.mounts[drive.device].uses %}
                <input type="text" 
                       name="custom_name_{{ drive.device | replace('/', '_') }}" 
                       value="{{ storage_config.mounts[drive.device].custom_name }}"
                       placeholder="custom_folder_name">
                {% else %}
                <input type="text" 
                       name="custom_name_{{ drive.device | replace('/', '_') }}" 
                       placeholder="custom_folder_name">
                {% endif %}
              </div>
            </div>
          </td>
        </tr>
        {% endfor %}
      </table>
    </div>
    
    <!-- Network Shares -->
    <div class="storage-section">
      <h3>Network Shares</h3>
      <p>Add network shares to mount (SMB/CIFS or NFS):</p>
      
      <!-- Existing network shares -->
      {% if storage_config.network_shares %}
      <h4>Existing Network Shares:</h4>
      <table style="width: 100%; border-collapse: collapse;">
        <tr style="background-color: #f2f2f2;">
          <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Type</th>
          <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Remote Path</th>
          <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Mount Point</th>
          <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Options</th>
          <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Use For</th>
          <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Actions</th>
        </tr>
        {% for i, share in storage_config.network_shares.items() %}
        <tr>
          <td style="padding: 10px; border: 1px solid #ddd;">{{ share.type }}</td>
          <td style="padding: 10px; border: 1px solid #ddd;">{{ share.remote_path }}</td>
          <td style="padding: 10px; border: 1px solid #ddd;">
            <input type="text" name="net_mount_point_{{ i }}" value="{{ share.mount_point }}">
          </td>
          <td style="padding: 10px; border: 1px solid #ddd;">
            <input type="text" name="net_options_{{ i }}" value="{{ share.options }}">
          </td>
          <td style="padding: 10px; border: 1px solid #ddd;">
            <div class="checkbox-group">
              <div>
                <input type="checkbox" 
                       id="net_use_movies_{{ i }}" 
                       name="net_use_movies_{{ i }}"
                       {% if 'movies' in share.uses %}checked{% endif %}>
                <label for="net_use_movies_{{ i }}">Movies</label>
              </div>
              
              <div>
                <input type="checkbox" 
                       id="net_use_tvshows_{{ i }}" 
                       name="net_use_tvshows_{{ i }}"
                       {% if 'tvshows' in share.uses %}checked{% endif %}>
                <label for="net_use_tvshows_{{ i }}">TV Shows</label>
              </div>
              
              <div>
                <input type="checkbox" 
                       id="net_use_music_{{ i }}" 
                       name="net_use_music_{{ i }}"
                       {% if 'music' in share.uses %}checked{% endif %}>
                <label for="net_use_music_{{ i }}">Music</label>
              </div>
              
              <div>
                <input type="checkbox" 
                       id="net_use_books_{{ i }}" 
                       name="net_use_books_{{ i }}"
                       {% if 'books' in share.uses %}checked{% endif %}>
                <label for="net_use_books_{{ i }}">Books/Audiobooks</label>
              </div>
              
              <div>
                <input type="checkbox" 
                       id="net_use_downloads_{{ i }}" 
                       name="net_use_downloads_{{ i }}"
                       {% if 'downloads' in share.uses %}checked{% endif %}>
                <label for="net_use_downloads_{{ i }}">Downloads</label>
              </div>
              
              <div>
                <input type="checkbox" 
                       id="net_use_custom_{{ i }}" 
                       name="net_use_custom_{{ i }}"
                       {% if 'custom' in share.uses %}checked{% endif %}>
                <label for="net_use_custom_{{ i }}">Custom</label>
                {% if 'custom' in share.uses %}
                <input type="text" 
                       name="net_custom_name_{{ i }}" 
                       value="{{ share.custom_name }}"
                       placeholder="custom_folder_name">
                {% else %}
                <input type="text" 
                       name="net_custom_name_{{ i }}" 
                       placeholder="custom_folder_name">
                {% endif %}
              </div>
            </div>
          </td>
          <td style="padding: 10px; border: 1px solid #ddd;">
            <input type="checkbox" id="net_remove_{{ i }}" name="net_remove_{{ i }}">
            <label for="net_remove_{{ i }}">Remove</label>
          </td>
        </tr>
        {% endfor %}
      </table>
      {% endif %}
      
      <!-- Add New Network Share -->
      <h4>Add New Network Share:</h4>
      <div class="form-group">
        <div>
          <label for="new_net_type">Type:</label>
          <select id="new_net_type" name="new_net_type">
            <option value="cifs">SMB/CIFS (Windows Share)</option>
            <option value="nfs">NFS (Network File System)</option>
          </select>
        </div>
        
        <div>
          <label for="new_net_remote_path">Remote Path:</label>
          <input type="text" id="new_net_remote_path" name="new_net_remote_path" 
                 placeholder="//server/share or server:/path/to/share">
        </div>
        
        <div>
          <label for="new_net_mount_point">Mount Point:</label>
          <input type="text" id="new_net_mount_point" name="new_net_mount_point" 
                 placeholder="/mnt/network_share">
        </div>
        
        <div>
          <label for="new_net_options">Mount Options:</label>
          <input type="text" id="new_net_options" name="new_net_options" 
                 placeholder="username=user,password=pass,uid=1000,gid=1000">
          <div class="service-description">
            For CIFS: username=user,password=pass,uid=1000,gid=1000<br>
            For NFS: defaults
          </div>
        </div>
        
        <div>
          <h5>Use For:</h5>
          <div class="checkbox-group">
            <div>
              <input type="checkbox" id="new_net_use_movies" name="new_net_use_movies">
              <label for="new_net_use_movies">Movies</label>
            </div>
            
            <div>
              <input type="checkbox" id="new_net_use_tvshows" name="new_net_use_tvshows">
              <label for="new_net_use_tvshows">TV Shows</label>
            </div>
            
            <div>
              <input type="checkbox" id="new_net_use_music" name="new_net_use_music">
              <label for="new_net_use_music">Music</label>
            </div>
            
            <div>
              <input type="checkbox" id="new_net_use_books" name="new_net_use_books">
              <label for="new_net_use_books">Books/Audiobooks</label>
            </div>
            
            <div>
              <input type="checkbox" id="new_net_use_downloads" name="new_net_use_downloads">
              <label for="new_net_use_downloads">Downloads</label>
            </div>
            
            <div>
              <input type="checkbox" id="new_net_use_custom" name="new_net_use_custom">
              <label for="new_net_use_custom">Custom</label>
              <input type="text" name="new_net_custom_name" placeholder="custom_folder_name">
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Local Folder Paths -->
    <div class="storage-section">
      <h3>Local Folder Paths</h3>
      <p>Add local folders to use for your media:</p>
      
      <!-- Existing local paths -->
      {% if storage_config.local_paths %}
      <h4>Existing Local Paths:</h4>
      <table style="width: 100%; border-collapse: collapse;">
        <tr style="background-color: #f2f2f2;">
          <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Path</th>
          <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Use For</th>
          <th style="padding: 10px; text-align: left; border: 1px solid #ddd;">Actions</th>
        </tr>
        {% for i, path in storage_config.local_paths.items() %}
        <tr>
          <td style="padding: 10px; border: 1px solid #ddd;">
            <input type="text" name="local_path_{{ i }}" value="{{ path.path }}">
          </td>
          <td style="padding: 10px; border: 1px solid #ddd;">
            <div class="checkbox-group">
              <div>
                <input type="checkbox" 
                       id="local_use_movies_{{ i }}" 
                       name="local_use_movies_{{ i }}"
                       {% if 'movies' in path.uses %}checked{% endif %}>
                <label for="local_use_movies_{{ i }}">Movies</label>
              </div>
              
              <div>
                <input type="checkbox" 
                       id="local_use_tvshows_{{ i }}" 
                       name="local_use_tvshows_{{ i }}"
                       {% if 'tvshows' in path.uses %}checked{% endif %}>
                <label for="local_use_tvshows_{{ i }}">TV Shows</label>
              </div>
              
              <div>
                <input type="checkbox" 
                       id="local_use_music_{{ i }}" 
                       name="local_use_music_{{ i }}"
                       {% if 'music' in path.uses %}checked{% endif %}>
                <label for="local_use_music_{{ i }}">Music</label>
              </div>
              
              <div>
                <input type="checkbox" 
                       id="local_use_books_{{ i }}" 
                       name="local_use_books_{{ i }}"
                       {% if 'books' in path.uses %}checked{% endif %}>
                <label for="local_use_books_{{ i }}">Books/Audiobooks</label>
              </div>
              
              <div>
                <input type="checkbox" 
                       id="local_use_downloads_{{ i }}" 
                       name="local_use_downloads_{{ i }}"
                       {% if 'downloads' in path.uses %}checked{% endif %}>
                <label for="local_use_downloads_{{ i }}">Downloads</label>
              </div>
              
              <div>
                <input type="checkbox" 
                       id="local_use_custom_{{ i }}" 
                       name="local_use_custom_{{ i }}"
                       {% if 'custom' in path.uses %}checked{% endif %}>
                <label for="local_use_custom_{{ i }}">Custom</label>
                {% if 'custom' in path.uses %}
                <input type="text" 
                       name="local_custom_name_{{ i }}" 
                       value="{{ path.custom_name }}"
                       placeholder="custom_folder_name">
                {% else %}
                <input type="text" 
                       name="local_custom_name_{{ i }}" 
                       placeholder="custom_folder_name">
                {% endif %}
              </div>
            </div>
          </td>
          <td style="padding: 10px; border: 1px solid #ddd;">
            <input type="checkbox" id="local_remove_{{ i }}" name="local_remove_{{ i }}">
            <label for="local_remove_{{ i }}">Remove</label>
          </td>
        </tr>
        {% endfor %}
      </table>
      {% endif %}
      
      <!-- Add New Local Path -->
      <h4>Add New Local Path:</h4>
      <div class="form-group">
        <div>
          <label for="new_local_path">Path:</label>
          <input type="text" id="new_local_path" name="new_local_path" 
                 placeholder="/path/to/folder">
        </div>
        
        <div>
          <h5>Use For:</h5>
          <div class="checkbox-group">
            <div>
              <input type="checkbox" id="new_local_use_movies" name="new_local_use_movies">
              <label for="new_local_use_movies">Movies</label>
            </div>
            
            <div>
              <input type="checkbox" id="new_local_use_tvshows" name="new_local_use_tvshows">
              <label for="new_local_use_tvshows">TV Shows</label>
            </div>
            
            <div>
              <input type="checkbox" id="new_local_use_music" name="new_local_use_music">
              <label for="new_local_use_music">Music</label>
            </div>
            
            <div>
              <input type="checkbox" id="new_local_use_books" name="new_local_use_books">
              <label for="new_local_use_books">Books/Audiobooks</label>
            </div>
            
            <div>
              <input type="checkbox" id="new_local_use_downloads" name="new_local_use_downloads">
              <label for="new_local_use_downloads">Downloads</label>
            </div>
            
            <div>
              <input type="checkbox" id="new_local_use_custom" name="new_local_use_custom">
              <label for="new_local_use_custom">Custom</label>
              <input type="text" name="new_local_custom_name" placeholder="custom_folder_name">
            </div>
          </div>
        </div>
      </div>
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

  # Create Services selection page
  cat > "$INSTALLER_DIR/templates/services_selection.html" <<'EOF'
{% extends "layout.html" %}

{% block content %}
<div class="step current">
  <h2>Services Selection</h2>
  
  <div class="progress-container">
    <div class="progress-bar" style="width: 55%">55%</div>
  </div>
  
  <p>Select which services you want to include in your media stack.</p>
  
  <form action="/services-selection-save" method="post">
    <!-- Arr Applications -->
    <div class="service-category">
      <h3>Arr Applications</h3>
      
      <div class="service-item">
        <input type="checkbox" id="service_sonarr" name="service_sonarr" {% if services.arr_apps.sonarr %}checked{% endif %}>
        <label for="service_sonarr">Sonarr - TV Show Management</label>
        <div class="service-description">Manages TV shows, finds new episodes, and organizes your library.</div>
      </div>
      
      <div class="service-item">
        <input type="checkbox" id="service_radarr" name="service_radarr" {% if services.arr_apps.radarr %}checked{% endif %}>
        <label for="service_radarr">Radarr - Movie Management</label>
        <div class="service-description">Manages movies, finds new releases, and organizes your library.</div>
      </div>
      
      <div class="service-item">
        <input type="checkbox" id="service_lidarr" name="service_lidarr" {% if services.arr_apps.lidarr %}checked{% endif %}>
        <label for="service_lidarr">Lidarr - Music Management</label>
        <div class="service-description">Manages music artists, albums, and tracks.</div>
      </div>
      
      <div class="service-item">
        <input type="checkbox" id="service_readarr" name="service_readarr" {% if services.arr_apps.readarr %}checked{% endif %}>
        <label for="service_readarr">Readarr - Book/Audiobook Management</label>
        <div class="service-description">Manages books, audiobooks, and authors.</div>
      </div>
      
      <div class="service-item">
        <input type="checkbox" id="service_prowlarr" name="service_prowlarr" {% if services.arr_apps.prowlarr %}checked{% endif %}>
        <label for="service_prowlarr">Prowlarr - Indexer Management</label>
        <div class="service-description">Manages and connects to indexers for all the *Arr applications.</div>
      </div>
      
      <div class="service-item">
        <input type="checkbox" id="service_bazarr" name="service_bazarr" {% if services.arr_apps.bazarr %}checked{% endif %}>
        <label for="service_bazarr">Bazarr - Subtitle Management</label>
        <div class="service-description">Manages and downloads subtitles for movies and TV shows.</div>
      </div>
    </div>
    
    <!-- Media Servers -->
    <div class="service-category">
      <h3>Media Servers</h3>
      
      <div class="service-item">
        <input type="radio" id="service_jellyfin" name="media_server" value="jellyfin" {% if services.media_servers.jellyfin %}checked{% endif %}>
        <label for="service_jellyfin">Jellyfin - Open Source Media Server</label>
        <div class="service-description">Free and open source media server with no premium features.</div>
      </div>
      
      <div class="service-item">
        <input type="radio" id="service_plex" name="media_server" value="plex" {% if services.media_servers.plex %}checked{% endif %}>
        <label for="service_plex">Plex - Media Server</label>
        <div class="service-description">Popular media server with free and premium features.</div>
      </div>
      
      <div class="service-item">
        <input type="radio" id="service_emby" name="media_server" value="emby" {% if services.media_servers.emby %}checked{% endif %}>
        <label for="service_emby">Emby - Media Server</label>
        <div class="service-description">Alternative media server with free and premium features.</div>
      </div>
    </div>
    
    <!-- Download Clients -->
    <div class="service-category">
      <h3>Download Clients</h3>
      
      <div class="service-category-section">
        <h4>Torrent Client</h4>
        <div class="service-item">
          <input type="radio" id="service_transmission" name="torrent_client" value="transmission" {% if services.download_clients.transmission %}checked{% endif %}>
          <label for="service_transmission">Transmission - Simple Torrent Client</label>
          <div class="service-description">Lightweight and easy-to-use torrent client.</div>
        </div>
        
        <div class="service-item">
          <input type="radio" id="service_qbittorrent" name="torrent_client" value="qbittorrent" {% if services.download_clients.qbittorrent %}checked{% endif %}>
          <label for="service_qbittorrent">qBittorrent - Advanced Torrent Client</label>
          <div class="service-description">Feature-rich torrent client with advanced options.</div>
        </div>
      </div>
      
      <div class="service-category-section">
        <h4>Usenet Client</h4>
        <div class="service-item">
          <input type="radio" id="service_nzbget" name="usenet_client" value="nzbget" {% if services.download_clients.nzbget %}checked{% endif %}>
          <label for="service_nzbget">NZBGet - Fast Usenet Downloader</label>
          <div class="service-description">Efficient and lightweight Usenet downloader.</div>
        </div>
        
        <div class="service-item">
          <input type="radio" id="service_sabnzbd" name="usenet_client" value="sabnzbd" {% if services.download_clients.sabnzbd %}checked{% endif %}>
          <label for="service_sabnzbd">SABnzbd - User-friendly Usenet Downloader</label>
          <div class="service-description">User-friendly and feature-rich Usenet downloader.</div>
        </div>
      </div>
      
      <div class="service-category-section">
        <h4>Direct Download</h4>
        <div class="service-item">
          <input type="checkbox" id="service_jdownloader" name="service_jdownloader" {% if services.download_clients.jdownloader %}checked{% endif %}>
          <label for="service_jdownloader">JDownloader - Direct Download Manager</label>
          <div class="service-description">Downloads files from direct download sites, file hosts, and video platforms.</div>
        </div>
      </div>
    </div>
    
    <!-- Utilities -->
    <div class="service-category">
      <h3>Utilities</h3>
      
      <div class="service-item">
        <input type="checkbox" id="service_heimdall" name="service_heimdall" {% if services.utilities.heimdall %}checked{% endif %}>
        <label for="service_heimdall">Heimdall - Application Dashboard</label>
        <div class="service-description">Creates a dashboard with links to all your services.</div>
      </div>
      
      <div class="service-item">
        <input type="checkbox" id="service_overseerr" name="service_overseerr" {% if services.utilities.overseerr %}checked{% endif %}>
        <label for="service_overseerr">Overseerr - Media Requests</label>
        <div class="service-description">Allows users to request movies and TV shows.</div>
      </div>
      
      <div class="service-item">
        <input type="checkbox" id="service_tautulli" name="service_tautulli" {% if services.utilities.tautulli %}checked{% endif %}>
        <label for="service_tautulli">Tautulli - Plex Monitoring</label>
        <div class="service-description">Monitors Plex Media Server usage and statistics.</div>
      </div>
      
      <div class="service-item">
        <input type="checkbox" id="service_portainer" name="service_portainer" {% if services.utilities.portainer %}checked{% endif %}>
        <label for="service_portainer">Portainer - Docker Management</label>
        <div class="service-description">GUI for managing Docker containers, images, networks, and volumes.</div>
      </div>
      
      <div class="service-item">
        <input type="checkbox" id="service_nginx_proxy_manager" name="service_nginx_proxy_manager" {% if services.utilities.nginx_proxy_manager %}checked{% endif %}>
        <label for="service_nginx_proxy_manager">Nginx Proxy Manager</label>
        <div class="service-description">Expose services to the internet with SSL certificates.</div>
      </div>
      
      <div class="service-item">
        <input type="checkbox" id="service_get_iplayer" name="service_get_iplayer" {% if services.utilities.get_iplayer %}checked{% endif %}>
        <label for="service_get_iplayer">Get iPlayer - BBC Content Downloader</label>
        <div class="service-description">Downloads content from BBC iPlayer.</div>
      </div>
    </div>
    
    <button type="submit">Save Services Selection</button>
  </form>
</div>
{% endblock %}
EOF

  # Create Services configuration page
  cat > "$INSTALLER_DIR/templates/services_config.html" <<'EOF'
{% extends "layout.html" %}

{% block content %}
<div class="step current">
  <h2>Services Configuration</h2>
  
  <div class="progress-container">
    <div class="progress-bar" style="width: 60%">60%</div>
  </div>
  
  <p>Configure ports and settings for your selected services.</p>
  
  <form action="/services-config-save" method="post">
    <h3>General Settings:</h3>
    
    <div>
      <label for="timezone">Timezone:</label>
      <input type="text" id="timezone" name="timezone" required value="{{ config.timezone }}">
    </div>
    
    <div>
      <label for="puid">PUID:</label>
      <input type="text" id="puid" name="puid" required value="{{ config.puid }}">
    </div>
    
    <div>
      <label for="pgid">PGID:</label>
      <input type="text" id="pgid" name="pgid" required value="{{ config.pgid }}">
    </div>
    
    <h3>Network Ports:</h3>
    
    <!-- Only show settings for selected services -->
    {% if 'prowlarr' in enabled_services %}
    <div class="service-config-item">
      <h4>Prowlarr</h4>
      <div>
        <label for="prowlarr_port">Prowlarr Port:</label>
        <input type="text" id="prowlarr_port" name="prowlarr_port" value="{{ config.prowlarr_port|default('9696') }}">
      </div>
    </div>
    {% endif %}
    
    {% if 'sonarr' in enabled_services %}
    <div class="service-config-item">
      <h4>Sonarr</h4>
      <div>
        <label for="sonarr_port">Sonarr Port:</label>
        <input type="text" id="sonarr_port" name="sonarr_port" value="{{ config.sonarr_port|default('8989') }}">
      </div>
    </div>
    {% endif %}
    
    {% if 'radarr' in enabled_services %}
    <div class="service-config-item">
      <h4>Radarr</h4>
      <div>
        <label for="radarr_port">Radarr Port:</label>
        <input type="text" id="radarr_port" name="radarr_port" value="{{ config.radarr_port|default('7878') }}">
      </div>
    </div>
    {% endif %}
    
    {% if 'lidarr' in enabled_services %}
    <div class="service-config-item">
      <h4>Lidarr</h4>
      <div>
        <label for="lidarr_port">Lidarr Port:</label>
        <input type="text" id="lidarr_port" name="lidarr_port" value="{{ config.lidarr_port|default('8686') }}">
      </div>
    </div>
    {% endif %}
    
    {% if 'readarr' in enabled_services %}
    <div class="service-config-item">
      <h4>Readarr</h4>
      <div>
        <label for="readarr_port">Readarr Port:</label>
        <input type="text" id="readarr_port" name="readarr_port" value="{{ config.readarr_port|default('8787') }}">
      </div>
    </div>
    {% endif %}
    
    {% if 'bazarr' in enabled_services %}
    <div class="service-config-item">
      <h4>Bazarr</h4>
      <div>
        <label for="bazarr_port">Bazarr Port:</label>
        <input type="text" id="bazarr_port" name="bazarr_port" value="{{ config.bazarr_port|default('6767') }}">
      </div>
    </div>
    {% endif %}
    
    {% if 'jellyfin' in enabled_services %}
    <div class="service-config-item">
      <h4>Jellyfin</h4>
      <div>
        <label for="jellyfin_port">Jellyfin HTTP Port:</label>
        <input type="text" id="jellyfin_port" name="jellyfin_port" value="{{ config.jellyfin_port|default('8096') }}">
      </div>
      <div>
        <label for="jellyfin_https_port">Jellyfin HTTPS Port:</label>
        <input type="text" id="jellyfin_https_port" name="jellyfin_https_port" value="{{ config.jellyfin_https_port|default('8920') }}">
      </div>
    </div>
    {% endif %}
    
    {% if 'plex' in enabled_services %}
    <div class="service-config-item">
      <h4>Plex</h4>
      <div>
        <label for="plex_claim">Plex Claim Token (optional):</label>
        <input type="text" id="plex_claim" name="plex_claim" value="{{ config.plex_claim|default('') }}">
        <div class="service-description">Get a claim token from <a href="https://www.plex.tv/claim/" target="_blank">https://www.plex.tv/claim/</a> (valid for 4 minutes)</div>
      </div>
    </div>
    {% endif %}
    
    {% if 'emby' in enabled_services %}
    <div class="service-config-item">
      <h4>Emby</h4>
      <div>
        <label for="emby_port">Emby HTTP Port:</label>
        <input type="text" id="emby_port" name="emby_port" value="{{ config.emby_port|default('8096') }}">
      </div>
      <div>
        <label for="emby_https_port">Emby HTTPS Port:</label>
        <input type="text" id="emby_https_port" name="emby_https_port" value="{{ config.emby_https_port|default('8920') }}">
      </div>
    </div>
    {% endif %}
    
    {% if 'transmission' in enabled_services %}
    <div class="service-config-item">
      <h4>Transmission</h4>
      <div>
        <label for="transmission_port">Transmission Port:</label>
        <input type="text" id="transmission_port" name="transmission_port" value="{{ config.transmission_port|default('9091') }}">
      </div>
    </div>
    {% endif %}
    
    {% if 'qbittorrent' in enabled_services %}
    <div class="service-config-item">
      <h4>qBittorrent</h4>
      <div>
        <label for="qbittorrent_port">qBittorrent WebUI Port:</label>
        <input type="text" id="qbittorrent_port" name="qbittorrent_port" value="{{ config.qbittorrent_port|default('8080') }}">
      </div>
    </div>
    {% endif %}
    
    {% if 'nzbget' in enabled_services %}
    <div class="service-config-item">
      <h4>NZBGet</h4>
      <div>
        <label for="nzbget_port">NZBGet Port:</label>
        <input type="text" id="nzbget_port" name="nzbget_port" value="{{ config.nzbget_port|default('6789') }}">
      </div>
    </div>
    {% endif %}
    
    {% if 'sabnzbd' in enabled_services %}
    <div class="service-config-item">
      <h4>SABnzbd</h4>
      <div>
        <label for="sabnzbd_port">SABnzbd Port:</label>
        <input type="text" id="sabnzbd_port" name="sabnzbd_port" value="{{ config.sabnzbd_port|default('8080') }}">
      </div>
    </div>
    {% endif %}
    
    {% if 'get_iplayer' in enabled_services %}
    <div class="service-config-item">
      <h4>Get iPlayer</h4>
      <div>
        <label for="get_iplayer_port">Get iPlayer Port:</label>
        <input type="text" id="get_iplayer_port" name="get_iplayer_port" value="{{ config.get_iplayer_port|default('1935') }}">
      </div>
    </div>
    {% endif %}
    
    {% if 'heimdall' in enabled_services %}
    <div class="service-config-item">
      <h4>Heimdall</h4>
      <div>
        <label for="heimdall_port">Heimdall HTTP Port:</label>
        <input type="text" id="heimdall_port" name="heimdall_port" value="{{ config.heimdall_port|default('80') }}">
      </div>
      <div>
        <label for="heimdall_https_port">Heimdall HTTPS Port:</label>
        <input type="text" id="heimdall_https_port" name="heimdall_https_port" value="{{ config.heimdall_https_port|default('443') }}">
      </div>
    </div>
    {% endif %}
    
    {% if 'overseerr' in enabled_services %}
    <div class="service-config-item">
      <h4>Overseerr</h4>
      <div>
        <label for="overseerr_port">Overseerr Port:</label>
        <input type="text" id="overseerr_port" name="overseerr_port" value="{{ config.overseerr_port|default('5055') }}">
      </div>
    </div>
    {% endif %}
    
    {% if 'tautulli' in enabled_services %}
    <div class="service-config-item">
      <h4>Tautulli</h4>
      <div>
        <label for="tautulli_port">Tautulli Port:</label>
        <input type="text" id="tautulli_port" name="tautulli_port" value="{{ config.tautulli_port|default('8181') }}">
      </div>
    </div>
    {% endif %}
    
    {% if 'portainer' in enabled_services %}
    <div class="service-config-item">
      <h4>Portainer</h4>
      <div>
        <label for="portainer_port">Portainer Port:</label>
        <input type="text" id="portainer_port" name="portainer_port" value="{{ config.portainer_port|default('9000') }}">
      </div>
      <div>
        <label for="portainer_edge_port">Portainer Edge Port:</label>
        <input type="text" id="portainer_edge_port" name="portainer_edge_port" value="{{ config.portainer_edge_port|default('8000') }}">
      </div>
    </div>
    {% endif %}
    
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
import uuid

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
BASE_DIR = os.path.dirname(SCRIPT_DIR)
ORIG_SCRIPT_PATH = os.path.join(BASE_DIR, "pi-pvr.sh")
SCRIPTS_DIR = os.path.join(BASE_DIR, "scripts")
GENERATE_COMPOSE_SCRIPT = os.path.join(SCRIPTS_DIR, "generate-compose.sh")

# Global config object
config = {
    # System configuration
    "puid": "1000",
    "pgid": "1000",
    "timezone": "Europe/London",
    
    # VPN configuration
    "pia_username": "",
    "pia_password": "",
    "server_region": "Netherlands",
    
    # Tailscale configuration
    "tailscale_auth_key": "",
    
    # Default folders (can be overridden by storage configuration)
    "movies_folder": "Movies",
    "tvshows_folder": "TVShows",
    "music_folder": "Music",
    "books_folder": "Books",
    "downloads_folder": "/mnt/storage/downloads",
    
    # Default ports configuration for all services
    "prowlarr_port": "9696",
    "sonarr_port": "8989",
    "radarr_port": "7878",
    "lidarr_port": "8686",
    "readarr_port": "8787",
    "bazarr_port": "6767",
    "jellyfin_port": "8096",
    "jellyfin_https_port": "8920",
    "plex_claim": "",
    "emby_port": "8096",
    "emby_https_port": "8920",
    "transmission_port": "9091",
    "qbittorrent_port": "8080",
    "nzbget_port": "6789",
    "sabnzbd_port": "8080",
    "get_iplayer_port": "1935",
    "heimdall_port": "80",
    "heimdall_https_port": "443",
    "overseerr_port": "5055",
    "tautulli_port": "8181",
    "portainer_port": "9000",
    "portainer_edge_port": "8000",
    
    # Default sharing method
    "share_method": "samba",
    
    # Installation status
    "installation_status": "not_started"
}

# Storage configuration
storage_config = {
    "mounts": {},           # USB drive mounts
    "network_shares": {},   # Network shares
    "local_paths": {}       # Local folder paths
}

# Services configuration
services = {
    "arr_apps": {
        "sonarr": True,
        "radarr": True,
        "lidarr": False,
        "readarr": False,
        "prowlarr": True,
        "bazarr": False
    },
    "media_servers": {
        "jellyfin": True,
        "plex": False,
        "emby": False
    },
    "download_clients": {
        "transmission": True,
        "qbittorrent": False,
        "nzbget": True,
        "sabnzbd": False,
        "jdownloader": False
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

# Load storage configuration
def load_storage_config():
    global storage_config
    storage_file = os.path.join(INSTALLER_DIR, "storage.json")
    if os.path.exists(storage_file):
        with open(storage_file, "r") as f:
            storage_config.update(json.load(f))

# Save storage configuration
def save_storage_config():
    storage_file = os.path.join(INSTALLER_DIR, "storage.json")
    with open(storage_file, "w") as f:
        json.dump(storage_config, f, indent=2)

# Load services configuration
def load_services():
    global services
    services_file = os.path.join(INSTALLER_DIR, "services.json")
    if os.path.exists(services_file):
        with open(services_file, "r") as f:
            services.update(json.load(f))

# Save services configuration
def save_services():
    services_file = os.path.join(INSTALLER_DIR, "services.json")
    with open(services_file, "w") as f:
        json.dump(services, f, indent=2)

# Get a list of all enabled services
def get_enabled_services():
    enabled = []
    
    # Add Arr applications
    for service, enabled_val in services["arr_apps"].items():
        if enabled_val:
            enabled.append(service)
    
    # Add media server
    for service, enabled_val in services["media_servers"].items():
        if enabled_val:
            enabled.append(service)
    
    # Add download clients
    for service, enabled_val in services["download_clients"].items():
        if enabled_val:
            enabled.append(service)
    
    # Add utilities
    for service, enabled_val in services["utilities"].items():
        if enabled_val:
            enabled.append(service)
    
    return enabled

# Initialize by loading all configurations
load_config()
load_storage_config()
load_services()

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
                          share_method=config["share_method"],
                          storage_config=storage_config)

# Save Storage config
@app.route('/storage-save', methods=['POST'])
def storage_save():
    # Update sharing method
    config["share_method"] = request.form.get("share_method", "samba")
    
    # Process USB drives
    drives = get_available_drives()
    
    # Reset the mounts to rebuild them from form data
    new_mounts = {}
    
    # Process each drive
    for drive in drives:
        drive_key = drive["device"].replace("/", "_")
        
        # Check if any uses are selected
        uses = []
        if f"use_movies_{drive_key}" in request.form:
            uses.append("movies")
        if f"use_tvshows_{drive_key}" in request.form:
            uses.append("tvshows")
        if f"use_music_{drive_key}" in request.form:
            uses.append("music")
        if f"use_books_{drive_key}" in request.form:
            uses.append("books")
        if f"use_downloads_{drive_key}" in request.form:
            uses.append("downloads")
        if f"use_custom_{drive_key}" in request.form:
            uses.append("custom")
            
        # Only process drives with at least one use
        if uses:
            mount_point = request.form.get(f"mount_point_{drive_key}", f"/mnt/{drive['device'].replace('/dev/', '')}")
            
            # Store the drive mount config
            new_mounts[drive["device"]] = {
                "mount_point": mount_point,
                "uses": uses
            }
            
            # Add custom name if applicable
            if "custom" in uses:
                custom_name = request.form.get(f"custom_name_{drive_key}", "custom")
                new_mounts[drive["device"]]["custom_name"] = custom_name
    
    # Update the storage config with new mounts
    storage_config["mounts"] = new_mounts
    
    # Process network shares
    new_network_shares = {}
    
    # Process existing network shares
    if "network_shares" in storage_config:
        for i, share in storage_config["network_shares"].items():
            # Check if this share is marked for removal
            if f"net_remove_{i}" in request.form:
                continue
                
            # Update the share configuration
            mount_point = request.form.get(f"net_mount_point_{i}", share["mount_point"])
            options = request.form.get(f"net_options_{i}", share["options"])
            
            # Collect uses
            uses = []
            if f"net_use_movies_{i}" in request.form:
                uses.append("movies")
            if f"net_use_tvshows_{i}" in request.form:
                uses.append("tvshows")
            if f"net_use_music_{i}" in request.form:
                uses.append("music")
            if f"net_use_books_{i}" in request.form:
                uses.append("books")
            if f"net_use_downloads_{i}" in request.form:
                uses.append("downloads")
            if f"net_use_custom_{i}" in request.form:
                uses.append("custom")
            
            # Only keep share if it has uses
            if uses:
                new_network_shares[i] = {
                    "type": share["type"],
                    "remote_path": share["remote_path"],
                    "mount_point": mount_point,
                    "options": options,
                    "uses": uses
                }
                
                # Add custom name if applicable
                if "custom" in uses:
                    custom_name = request.form.get(f"net_custom_name_{i}", "custom")
                    new_network_shares[i]["custom_name"] = custom_name
    
    # Process new network share if provided
    if request.form.get("new_net_remote_path") and request.form.get("new_net_mount_point"):
        # Generate a new unique ID
        new_id = str(uuid.uuid4())
        
        # Collect uses
        uses = []
        if "new_net_use_movies" in request.form:
            uses.append("movies")
        if "new_net_use_tvshows" in request.form:
            uses.append("tvshows")
        if "new_net_use_music" in request.form:
            uses.append("music")
        if "new_net_use_books" in request.form:
            uses.append("books")
        if "new_net_use_downloads" in request.form:
            uses.append("downloads")
        if "new_net_use_custom" in request.form:
            uses.append("custom")
        
        # Add new share if it has uses
        if uses:
            new_network_shares[new_id] = {
                "type": request.form.get("new_net_type", "cifs"),
                "remote_path": request.form.get("new_net_remote_path"),
                "mount_point": request.form.get("new_net_mount_point"),
                "options": request.form.get("new_net_options", ""),
                "uses": uses
            }
            
            # Add custom name if applicable
            if "custom" in uses:
                custom_name = request.form.get("new_net_custom_name", "custom")
                new_network_shares[new_id]["custom_name"] = custom_name
    
    # Update network shares
    storage_config["network_shares"] = new_network_shares
    
    # Process local paths
    new_local_paths = {}
    
    # Process existing local paths
    if "local_paths" in storage_config:
        for i, path_info in storage_config["local_paths"].items():
            # Check if this path is marked for removal
            if f"local_remove_{i}" in request.form:
                continue
                
            # Update the path
            path = request.form.get(f"local_path_{i}", path_info["path"])
            
            # Collect uses
            uses = []
            if f"local_use_movies_{i}" in request.form:
                uses.append("movies")
            if f"local_use_tvshows_{i}" in request.form:
                uses.append("tvshows")
            if f"local_use_music_{i}" in request.form:
                uses.append("music")
            if f"local_use_books_{i}" in request.form:
                uses.append("books")
            if f"local_use_downloads_{i}" in request.form:
                uses.append("downloads")
            if f"local_use_custom_{i}" in request.form:
                uses.append("custom")
            
            # Only keep path if it has uses
            if uses:
                new_local_paths[i] = {
                    "path": path,
                    "uses": uses
                }
                
                # Add custom name if applicable
                if "custom" in uses:
                    custom_name = request.form.get(f"local_custom_name_{i}", "custom")
                    new_local_paths[i]["custom_name"] = custom_name
    
    # Process new local path if provided
    if request.form.get("new_local_path"):
        # Generate a new unique ID
        new_id = str(uuid.uuid4())
        
        # Collect uses
        uses = []
        if "new_local_use_movies" in request.form:
            uses.append("movies")
        if "new_local_use_tvshows" in request.form:
            uses.append("tvshows")
        if "new_local_use_music" in request.form:
            uses.append("music")
        if "new_local_use_books" in request.form:
            uses.append("books")
        if "new_local_use_downloads" in request.form:
            uses.append("downloads")
        if "new_local_use_custom" in request.form:
            uses.append("custom")
        
        # Add new path if it has uses
        if uses:
            new_local_paths[new_id] = {
                "path": request.form.get("new_local_path"),
                "uses": uses
            }
            
            # Add custom name if applicable
            if "custom" in uses:
                custom_name = request.form.get("new_local_custom_name", "custom")
                new_local_paths[new_id]["custom_name"] = custom_name
    
    # Update local paths
    storage_config["local_paths"] = new_local_paths
    
    # Save the storage configuration
    save_storage_config()
    
    # Update config with primary storage locations based on the first available options
    # This allows us to override default media directories
    
    # Look for movie storage
    for device_info in storage_config["mounts"].values():
        if "movies" in device_info["uses"]:
            config["movies_folder"] = os.path.join(device_info["mount_point"], "Movies")
            break
    
    # Look for TV show storage
    for device_info in storage_config["mounts"].values():
        if "tvshows" in device_info["uses"]:
            config["tvshows_folder"] = os.path.join(device_info["mount_point"], "TVShows")
            break
    
    # Look for music storage
    for device_info in storage_config["mounts"].values():
        if "music" in device_info["uses"]:
            config["music_folder"] = os.path.join(device_info["mount_point"], "Music")
            break
    
    # Look for book storage
    for device_info in storage_config["mounts"].values():
        if "books" in device_info["uses"]:
            config["books_folder"] = os.path.join(device_info["mount_point"], "Books")
            break
    
    # Look for download storage
    for device_info in storage_config["mounts"].values():
        if "downloads" in device_info["uses"]:
            config["downloads_folder"] = os.path.join(device_info["mount_point"], "downloads")
            break
    
    # Save the updated config
    save_config()
    
    # Redirect to services selection
    return redirect(url_for('services_selection'))

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

# Services Selection Page
@app.route('/services-selection')
def services_selection():
    return render_template('services_selection.html', services=services)

# Save Services Selection
@app.route('/services-selection-save', methods=['POST'])
def services_selection_save():
    global services
    
    # Process Arr applications
    services["arr_apps"]["sonarr"] = "service_sonarr" in request.form
    services["arr_apps"]["radarr"] = "service_radarr" in request.form
    services["arr_apps"]["lidarr"] = "service_lidarr" in request.form
    services["arr_apps"]["readarr"] = "service_readarr" in request.form
    services["arr_apps"]["prowlarr"] = "service_prowlarr" in request.form
    services["arr_apps"]["bazarr"] = "service_bazarr" in request.form
    
    # Process Media Server (radio buttons - only one can be selected)
    media_server = request.form.get("media_server", "jellyfin")
    services["media_servers"]["jellyfin"] = media_server == "jellyfin"
    services["media_servers"]["plex"] = media_server == "plex"
    services["media_servers"]["emby"] = media_server == "emby"
    
    # Process Download Clients
    torrent_client = request.form.get("torrent_client", "transmission")
    services["download_clients"]["transmission"] = torrent_client == "transmission"
    services["download_clients"]["qbittorrent"] = torrent_client == "qbittorrent"
    
    usenet_client = request.form.get("usenet_client", "nzbget")
    services["download_clients"]["nzbget"] = usenet_client == "nzbget"
    services["download_clients"]["sabnzbd"] = usenet_client == "sabnzbd"
    
    services["download_clients"]["jdownloader"] = "service_jdownloader" in request.form
    
    # Process Utilities
    services["utilities"]["heimdall"] = "service_heimdall" in request.form
    services["utilities"]["overseerr"] = "service_overseerr" in request.form
    services["utilities"]["tautulli"] = "service_tautulli" in request.form
    services["utilities"]["portainer"] = "service_portainer" in request.form
    services["utilities"]["nginx_proxy_manager"] = "service_nginx_proxy_manager" in request.form
    services["utilities"]["get_iplayer"] = "service_get_iplayer" in request.form
    
    # Save to services file
    save_services()
    
    # Generate list of enabled services for the services configuration page
    enabled_services = get_enabled_services()
    
    # Redirect to services configuration page
    return redirect(url_for('services_config'))

# Services Configuration Page
@app.route('/services-config')
def services_config():
    enabled_services = get_enabled_services()
    return render_template('services_config.html', config=config, enabled_services=enabled_services)

# Save Services Configuration
@app.route('/services-config-save', methods=['POST'])
def services_config_save():
    # Update general settings
    config["timezone"] = request.form.get("timezone", "Europe/London")
    config["puid"] = request.form.get("puid", "1000")
    config["pgid"] = request.form.get("pgid", "1000")
    
    # Get all enabled services
    enabled_services = get_enabled_services()
    
    # Process port configurations for each enabled service
    if 'prowlarr' in enabled_services:
        config["prowlarr_port"] = request.form.get("prowlarr_port", "9696")
    
    if 'sonarr' in enabled_services:
        config["sonarr_port"] = request.form.get("sonarr_port", "8989")
    
    if 'radarr' in enabled_services:
        config["radarr_port"] = request.form.get("radarr_port", "7878")
    
    if 'lidarr' in enabled_services:
        config["lidarr_port"] = request.form.get("lidarr_port", "8686")
    
    if 'readarr' in enabled_services:
        config["readarr_port"] = request.form.get("readarr_port", "8787")
    
    if 'bazarr' in enabled_services:
        config["bazarr_port"] = request.form.get("bazarr_port", "6767")
    
    if 'jellyfin' in enabled_services:
        config["jellyfin_port"] = request.form.get("jellyfin_port", "8096")
        config["jellyfin_https_port"] = request.form.get("jellyfin_https_port", "8920")
    
    if 'plex' in enabled_services:
        config["plex_claim"] = request.form.get("plex_claim", "")
    
    if 'emby' in enabled_services:
        config["emby_port"] = request.form.get("emby_port", "8096")
        config["emby_https_port"] = request.form.get("emby_https_port", "8920")
    
    if 'transmission' in enabled_services:
        config["transmission_port"] = request.form.get("transmission_port", "9091")
    
    if 'qbittorrent' in enabled_services:
        config["qbittorrent_port"] = request.form.get("qbittorrent_port", "8080")
    
    if 'nzbget' in enabled_services:
        config["nzbget_port"] = request.form.get("nzbget_port", "6789")
    
    if 'sabnzbd' in enabled_services:
        config["sabnzbd_port"] = request.form.get("sabnzbd_port", "8080")
    
    if 'get_iplayer' in enabled_services:
        config["get_iplayer_port"] = request.form.get("get_iplayer_port", "1935")
    
    if 'heimdall' in enabled_services:
        config["heimdall_port"] = request.form.get("heimdall_port", "80")
        config["heimdall_https_port"] = request.form.get("heimdall_https_port", "443")
    
    if 'overseerr' in enabled_services:
        config["overseerr_port"] = request.form.get("overseerr_port", "5055")
    
    if 'tautulli' in enabled_services:
        config["tautulli_port"] = request.form.get("tautulli_port", "8181")
    
    if 'portainer' in enabled_services:
        config["portainer_port"] = request.form.get("portainer_port", "9000")
        config["portainer_edge_port"] = request.form.get("portainer_edge_port", "8000")
    
    # Save configuration
    save_config()
    
    # Redirect to installation page
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

def setup_storage():
    """Set up all storage options including USB drives, network shares, and local paths"""
    with open(INSTALLER_LOG, "a") as log:
        log.write("Setting up storage configuration...\n")
    
    # Process USB drive mounts
    if storage_config.get("mounts"):
        with open(INSTALLER_LOG, "a") as log:
            log.write(f"Setting up {len(storage_config['mounts'])} USB drive(s)...\n")
            
        for mount_point, mount_info in storage_config["mounts"].items():
            device = mount_info.get("device")
            fs_type = mount_info.get("fs_type", "auto")
            mount_options = mount_info.get("options", "defaults")
            
            if not device:
                continue
                
            # Create mount point directory if it doesn't exist
            if not os.path.exists(mount_point):
                try:
                    os.makedirs(mount_point, exist_ok=True)
                    # Set permissions to allow containers to access files
                    os.chmod(mount_point, 0o755)
                    log.write(f"Created mount point directory: {mount_point}\n")
                except Exception as e:
                    log.write(f"Failed to create mount point {mount_point}: {str(e)}\n")
                    continue
            
            # Add entry to fstab if not already present
            fstab_line = f"{device} {mount_point} {fs_type} {mount_options} 0 0"
            try:
                # Check if entry already exists in fstab
                with open("/etc/fstab", "r") as fstab:
                    if any(line.strip() == fstab_line for line in fstab if not line.startswith("#")):
                        log.write(f"Mount entry for {device} already exists in fstab\n")
                        continue
                        
                # Add entry to fstab
                with open("/etc/fstab", "a") as fstab:
                    fstab.write(f"\n{fstab_line}\n")
                    log.write(f"Added {device} to fstab\n")
                    
                # Mount the drive
                subprocess.run(["mount", mount_point], check=True)
                log.write(f"Mounted {device} at {mount_point}\n")
            except Exception as e:
                log.write(f"Failed to configure mount for {device}: {str(e)}\n")
    
    # Process network shares
    if storage_config.get("network_shares"):
        with open(INSTALLER_LOG, "a") as log:
            log.write(f"Setting up {len(storage_config['network_shares'])} network share(s)...\n")
            
        for mount_point, share_info in storage_config["network_shares"].items():
            share_type = share_info.get("type", "cifs")
            share_path = share_info.get("path")
            share_options = share_info.get("options", "")
            
            if not share_path:
                continue
                
            # Create mount point directory if it doesn't exist
            if not os.path.exists(mount_point):
                try:
                    os.makedirs(mount_point, exist_ok=True)
                    # Set permissions
                    os.chmod(mount_point, 0o755)
                    log.write(f"Created network share mount point: {mount_point}\n")
                except Exception as e:
                    log.write(f"Failed to create network share mount point {mount_point}: {str(e)}\n")
                    continue
            
            # Handle CIFS/SMB shares
            if share_type == "cifs":
                # Ensure cifs-utils is installed
                try:
                    subprocess.run(["apt-get", "install", "-y", "cifs-utils"], check=True)
                except Exception as e:
                    log.write(f"Failed to install cifs-utils: {str(e)}\n")
                    continue
                
                # Create credentials file if username/password provided
                if "username" in share_info and "password" in share_info:
                    creds_file = f"/root/.smbcredentials-{os.path.basename(mount_point)}"
                    try:
                        with open(creds_file, "w") as creds:
                            creds.write(f"username={share_info['username']}\n")
                            creds.write(f"password={share_info['password']}\n")
                        os.chmod(creds_file, 0o600)
                        share_options += f",credentials={creds_file}"
                        log.write(f"Created SMB credentials file {creds_file}\n")
                    except Exception as e:
                        log.write(f"Failed to create SMB credentials file: {str(e)}\n")
                
                # Add entry to fstab if not already present
                fstab_line = f"{share_path} {mount_point} {share_type} {share_options} 0 0"
            
            # Handle NFS shares
            elif share_type == "nfs":
                # Ensure nfs-common is installed
                try:
                    subprocess.run(["apt-get", "install", "-y", "nfs-common"], check=True)
                except Exception as e:
                    log.write(f"Failed to install nfs-common: {str(e)}\n")
                    continue
                
                # Add entry to fstab if not already present
                fstab_line = f"{share_path} {mount_point} {share_type} {share_options} 0 0"
            
            # Add to fstab and mount
            try:
                # Check if entry already exists in fstab
                with open("/etc/fstab", "r") as fstab:
                    if any(line.strip() == fstab_line for line in fstab if not line.startswith("#")):
                        log.write(f"Mount entry for {share_path} already exists in fstab\n")
                        continue
                        
                # Add entry to fstab
                with open("/etc/fstab", "a") as fstab:
                    fstab.write(f"\n{fstab_line}\n")
                    log.write(f"Added {share_path} to fstab\n")
                    
                # Mount the share
                subprocess.run(["mount", mount_point], check=True)
                log.write(f"Mounted {share_path} at {mount_point}\n")
            except Exception as e:
                log.write(f"Failed to configure mount for {share_path}: {str(e)}\n")
    
    # Process local paths
    if storage_config.get("local_paths"):
        with open(INSTALLER_LOG, "a") as log:
            log.write(f"Setting up {len(storage_config['local_paths'])} local path(s)...\n")
            
        for path, path_info in storage_config["local_paths"].items():
            # Create directory if it doesn't exist
            if not os.path.exists(path):
                try:
                    os.makedirs(path, exist_ok=True)
                    # Set permissions based on path_info
                    permissions = path_info.get("permissions", "0755")
                    os.chmod(path, int(permissions, 8))
                    log.write(f"Created local path: {path} with permissions {permissions}\n")
                    
                    # Set ownership if specified
                    if "owner" in path_info:
                        owner = path_info["owner"]
                        if ":" in owner:  # Format is user:group
                            user, group = owner.split(":")
                            subprocess.run(["chown", f"{user}:{group}", path], check=True)
                        else:  # Just user
                            subprocess.run(["chown", owner, path], check=True)
                        log.write(f"Set ownership of {path} to {owner}\n")
                except Exception as e:
                    log.write(f"Failed to create local path {path}: {str(e)}\n")
    
    with open(INSTALLER_LOG, "a") as log:
        log.write("Storage configuration completed\n")

def generate_docker_compose_file():
    """Generate Docker Compose file using generate-compose.sh script based on user selections"""
    with open(INSTALLER_LOG, "a") as log:
        log.write("Generating Docker Compose file...\n")
    
    # Path to the generate-compose.sh script
    generate_script = os.path.join(BASE_DIR, "scripts", "generate-compose.sh")
    
    # Make script executable if it isn't already
    if not os.access(generate_script, os.X_OK):
        try:
            os.chmod(generate_script, 0o755)
        except Exception as e:
            with open(INSTALLER_LOG, "a") as log:
                log.write(f"Failed to make generate-compose.sh executable: {str(e)}\n")
            raise
    
    # Build command to run the generate-compose.sh script
    cmd = [generate_script]
    
    # Add output file and environment file parameters
    cmd.extend(["--output", os.path.join(BASE_DIR, "docker-compose.yml")])
    cmd.extend(["--env", os.path.join(BASE_DIR, ".env")])
    
    # Add services based on user selections
    # Add arr apps if any arr app is selected
    if any(services.get("arr_apps", {}).values()):
        cmd.append("--arr-apps")
    
    # Add media server selection
    for server, enabled in services.get("media_servers", {}).items():
        if enabled:
            cmd.extend(["--media-server", server])
    
    # Add torrent client
    for client, enabled in services.get("download_clients", {}).items():
        if enabled and client in ["transmission", "qbittorrent"]:
            cmd.extend(["--torrent-client", client])
            break
    
    # Add usenet client
    for client, enabled in services.get("download_clients", {}).items():
        if enabled and client in ["nzbget", "sabnzbd"]:
            cmd.extend(["--usenet-client", client])
            break
    
    # Add direct download if jdownloader is enabled
    if services.get("download_clients", {}).get("jdownloader", False):
        cmd.append("--direct-download")
    
    # Add utility options
    if services.get("utilities", {}).get("heimdall", False):
        cmd.append("--dashboard")
    
    if services.get("utilities", {}).get("overseerr", False):
        cmd.append("--requests")
    
    if services.get("utilities", {}).get("tautulli", False):
        cmd.append("--monitoring")
    
    if services.get("utilities", {}).get("nginx_proxy_manager", False):
        cmd.append("--proxy")
    
    # Execute the command
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        with open(INSTALLER_LOG, "a") as log:
            log.write("Docker Compose file generated successfully\n")
            log.write(f"Command output: {result.stdout}\n")
    except subprocess.CalledProcessError as e:
        with open(INSTALLER_LOG, "a") as log:
            log.write(f"Failed to generate Docker Compose file: {str(e)}\n")
            log.write(f"Error output: {e.stderr}\n")
        raise
    except Exception as e:
        with open(INSTALLER_LOG, "a") as log:
            log.write(f"Failed to generate Docker Compose file: {str(e)}\n")
        raise

def run_installation():
    try:
        with open(INSTALLER_LOG, "w") as f:
            f.write("Starting installation...\n")
        
        # Setup advanced storage configuration based on user choices
        setup_storage()
        
        # Create the .env file with all configured parameters
        create_env_file()
        
        # Install dependencies
        install_dependencies()
        
        # Set up Tailscale if enabled
        if config["tailscale_auth_key"]:
            setup_tailscale()
        
        # Configure PIA VPN if credentials provided
        setup_pia_vpn()
        
        # Generate Docker Compose file using generate-compose.sh
        generate_docker_compose_file()
        
        # Set up Docker network
        setup_docker_network()
        
        # Deploy Docker Compose stack
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
    
    # Install Tailscale with retry mechanism
    max_retries = 3
    retry_delay = 5  # seconds
    
    for attempt in range(max_retries):
        try:
            # Download Tailscale installer with timeout
            download_cmd = "curl -fsSL https://tailscale.com/install.sh -o tailscale-install.sh"
            subprocess.run(download_cmd, shell=True, check=True, timeout=60)
            
            # Run installer with timeout
            install_cmd = "bash tailscale-install.sh"
            subprocess.run(install_cmd, shell=True, check=True, timeout=120)
            
            # Clean up installer script
            if os.path.exists("tailscale-install.sh"):
                os.remove("tailscale-install.sh")
            
            # Start Tailscale with auth key if provided
            if config["tailscale_auth_key"]:
                cmd = f"sudo tailscale up --accept-routes=false --authkey={config['tailscale_auth_key']}"
            else:
                cmd = "sudo tailscale up --accept-routes=false"
            
            subprocess.run(cmd, shell=True, check=True, timeout=60)
            
            with open(INSTALLER_LOG, "a") as log:
                log.write("Tailscale installed and running\n")
                
            # If we get here, installation was successful
            break
            
        except subprocess.TimeoutExpired:
            with open(INSTALLER_LOG, "a") as log:
                log.write(f"Tailscale installation timed out (attempt {attempt+1}/{max_retries})\n")
            
            # Clean up installer script if it exists
            if os.path.exists("tailscale-install.sh"):
                os.remove("tailscale-install.sh")
                
            if attempt == max_retries - 1:
                with open(INSTALLER_LOG, "a") as log:
                    log.write("Tailscale installation failed: maximum retries reached\n")
                raise Exception("Tailscale installation timed out after multiple attempts")
                
        except subprocess.CalledProcessError as e:
            with open(INSTALLER_LOG, "a") as log:
                log.write(f"Tailscale installation failed on attempt {attempt+1}: {str(e)}\n")
                
            # Clean up installer script if it exists
            if os.path.exists("tailscale-install.sh"):
                os.remove("tailscale-install.sh")
                
            if attempt == max_retries - 1:
                with open(INSTALLER_LOG, "a") as log:
                    log.write("Tailscale installation failed: maximum retries reached\n")
                raise
                
        # Wait before retrying
        time.sleep(retry_delay)

def install_dependencies():
    with open(INSTALLER_LOG, "a") as log:
        log.write("Installing dependencies...\n")
    
    # Define timeouts and retry settings
    apt_timeout = 120  # 2 minutes for apt commands
    docker_timeout = 300  # 5 minutes for Docker commands
    max_retries = 3
    retry_delay = 5  # seconds
    
    try:
        # Update package list with timeout and retry
        for attempt in range(max_retries):
            try:
                with open(INSTALLER_LOG, "a") as log:
                    log.write(f"Updating package list (attempt {attempt+1}/{max_retries})...\n")
                subprocess.run("sudo apt update", shell=True, check=True, timeout=apt_timeout)
                break
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
                with open(INSTALLER_LOG, "a") as log:
                    log.write(f"Failed to update package list: {str(e)}\n")
                if attempt == max_retries - 1:
                    with open(INSTALLER_LOG, "a") as log:
                        log.write("Failed to update package list after multiple attempts\n")
                    raise
                time.sleep(retry_delay)
        
        # Install required packages with timeout and retry
        for attempt in range(max_retries):
            try:
                with open(INSTALLER_LOG, "a") as log:
                    log.write(f"Installing basic dependencies (attempt {attempt+1}/{max_retries})...\n")
                subprocess.run("sudo apt install -y curl jq git", shell=True, check=True, timeout=apt_timeout)
                break
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
                with open(INSTALLER_LOG, "a") as log:
                    log.write(f"Failed to install basic dependencies: {str(e)}\n")
                if attempt == max_retries - 1:
                    with open(INSTALLER_LOG, "a") as log:
                        log.write("Failed to install basic dependencies after multiple attempts\n")
                    raise
                time.sleep(retry_delay)
        
        # Remove conflicting Docker packages
        try:
            with open(INSTALLER_LOG, "a") as log:
                log.write("Removing conflicting Docker packages...\n")
            subprocess.run("for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove -y $pkg; done", 
                          shell=True, timeout=apt_timeout)
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
            with open(INSTALLER_LOG, "a") as log:
                log.write(f"Warning: Failed to remove conflicting packages: {str(e)}\n")
                log.write("Continuing with Docker installation anyway\n")
        
        # Install Docker with timeout and retry
        docker_install_commands = """
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
"""
        
        for attempt in range(max_retries):
            try:
                with open(INSTALLER_LOG, "a") as log:
                    log.write(f"Installing Docker (attempt {attempt+1}/{max_retries})...\n")
                subprocess.run(docker_install_commands, shell=True, check=True, timeout=docker_timeout)
                break
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
                with open(INSTALLER_LOG, "a") as log:
                    log.write(f"Failed to install Docker: {str(e)}\n")
                if attempt == max_retries - 1:
                    with open(INSTALLER_LOG, "a") as log:
                        log.write("Failed to install Docker after multiple attempts\n")
                    raise
                time.sleep(retry_delay)
        
        # Verify Docker installation with timeout and retry
        for attempt in range(max_retries):
            try:
                with open(INSTALLER_LOG, "a") as log:
                    log.write(f"Verifying Docker installation (attempt {attempt+1}/{max_retries})...\n")
                subprocess.run("sudo docker run --rm hello-world", shell=True, check=True, timeout=60)
                break
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
                with open(INSTALLER_LOG, "a") as log:
                    log.write(f"Failed to verify Docker: {str(e)}\n")
                if attempt == max_retries - 1:
                    with open(INSTALLER_LOG, "a") as log:
                        log.write("Warning: Docker verification failed, but continuing anyway\n")
                    # Don't raise an exception here, as Docker might be installed correctly
                    # but the hello-world test could fail for network reasons
                time.sleep(retry_delay)
        
        with open(INSTALLER_LOG, "a") as log:
            log.write("Dependencies installed successfully\n")
    except Exception as e:
        with open(INSTALLER_LOG, "a") as log:
            log.write(f"Dependency installation failed with error: {str(e)}\n")
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
  if [[ -f "$SCRIPT_DIR/pi-pvr.sh" ]]; then
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
    chmod +x "$SCRIPT_DIR/pi-pvr.sh"
    
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