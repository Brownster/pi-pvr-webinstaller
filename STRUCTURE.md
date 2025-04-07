# PI-PVR Ultimate Media Stack - Project Structure

This document provides a comprehensive overview of the project's directory structure, file organization, and component relationships.

## Top-Level Directories

- **docker-compose/** - Contains modular docker-compose configuration files for different service categories
- **scripts/** - Shell scripts and Python utilities for the project
- **web-ui/** - The web-based management interface and frontend components
- **config/** - Configuration files (created during setup)
- **logs/** - Log files for installation and operation
- **.github/** - GitHub-related files like workflows and templates

## Key Entry Point Files

- **pi-pvr.sh** - The main command-line installer script
- **web-install.sh** - Web-based installer launcher
- **web-installer.sh** - Web-based installer implementation with Flask
- **web-ui.sh** - Launcher for the management web UI
- **start.sh** - User-friendly menu-based launcher for all installation methods

## Documentation Files

- **README.md** - Main project documentation and features overview
- **DEVELOPMENT.md** - Comprehensive developer documentation
- **STRUCTURE.md** - This file, explaining project structure
- **ROADMAP.md** - Planned features and development roadmap
- **CONTRIBUTING.md** - Guidelines for contributors
- **API-DOCUMENTATION.md** - Detailed API documentation
- **WEB-UI-GUIDE.md** - Guide for using the web UI
- **CLAUDE.md** - Guidelines for AI assistants working on this project

## Docker Compose Files

The project uses a modular Docker Compose architecture, with each file serving a specific purpose:

- **docker-compose/docker-compose.base.yml** - Core infrastructure including:
  - Network definitions
  - Shared volumes
  - Common environment variables
  - Base containers like VPN and Tailscale

- **docker-compose/docker-compose.arr.yml** - Arr applications:
  - Sonarr (TV Shows)
  - Radarr (Movies)
  - Lidarr (Music)
  - Readarr (Books/Audiobooks)
  - Prowlarr (Indexers)
  - Bazarr (Subtitles)

- **docker-compose/docker-compose.download.yml** - Download clients:
  - Transmission (Torrent)
  - qBittorrent (Torrent)
  - NZBGet (Usenet)
  - SABnzbd (Usenet)
  - JDownloader (Direct Downloads)

- **docker-compose/docker-compose.media.yml** - Media servers:
  - Jellyfin
  - Plex
  - Emby

- **docker-compose/docker-compose.utilities.yml** - Utility services:
  - Heimdall (Dashboard)
  - Overseerr (Requests)
  - Tautulli (Plex Monitoring)
  - Portainer (Docker Management)
  - Nginx Proxy Manager
  - Get iPlayer

## Scripts Directory

The scripts directory contains utilities for system detection, installation, and API services:

- **scripts/generate-compose.sh** - Script to generate docker-compose.yml from modular files
  - Accepts command-line arguments for service selection
  - Supports profiles for different service configurations
  - Handles hardware detection for acceleration

- **scripts/detect-system.sh** - Detects system hardware and capabilities
  - Identifies Raspberry Pi models
  - Detects available hardware acceleration methods
  - Determines optimal configurations based on hardware

- **scripts/api.py** - RESTful API server for the web installer and management UI
  - System information endpoints
  - Container management endpoints
  - Storage management endpoints
  - Configuration endpoints

- **scripts/remote-installer.sh** - Script for remote installation on a separate device

- **scripts/test_api.py** - Test suite for the API

- **scripts/templates/** - Contains template files for various components

## Web UI Structure

The web UI is a modern, responsive interface built with vanilla JavaScript:

- **web-ui/index.html** - Main dashboard and management interface
- **web-ui/install.html** - Installation wizard interface
- **web-ui/css/main.css** - Main styling for the web UI
- **web-ui/js/** - JavaScript modules
  - **web-ui/js/api-client.js** - Centralized API client
  - **web-ui/js/main.js** - Main application logic
  - **web-ui/js/notifications.js** - UI notification system
- **web-ui/static/** - Static assets
  - **web-ui/static/css/style.css** - Additional styling
  - **web-ui/static/img/** - Images for the web interface
  - **web-ui/static/js/app.js** - Additional JavaScript

## Key Component Files

### Server and API

- **web-ui/server.js** - Express.js server for the web UI
- **scripts/api.py** - Flask API server with endpoints for:
  - System information and monitoring
  - Docker container management
  - Storage configuration
  - Service health monitoring
  - Configuration management
  - Installation process control

### Installation Components

- **web-installer.sh** - The web-based installer implementation
  - Contains embedded Flask application
  - Includes HTML templates
  - Manages the installation process

- **pi-pvr.sh** - The command-line installer
  - Interactive setup process
  - System detection
  - Docker and dependency installation
  - Configuration management

## Generated Files

During installation, the following files and directories are created:

- **docker-compose.yml** - The generated Docker Compose file
  - Combined from the modular files based on user selections
  - Configured for the specific hardware detected

- **.env** - Environment variables file
  - Contains user configuration settings
  - Defines paths for media and downloads
  - Stores VPN and service configuration

- **~/docker/** - Docker configuration directory
  - Contains service-specific configuration files
  - Stores Docker volumes for persistent data

## Configuration Files

- **config/config.json** - User configuration
  - System settings (PUID, PGID, timezone)
  - Directory paths for media and downloads
  - VPN configuration
  - Tailscale configuration
  - Installation status

- **config/services.json** - Services configuration
  - Selected Arr applications
  - Selected download clients
  - Selected media servers
  - Selected utility services

## Log Files

- **logs/installation.log** - Installation process log
  - Records all steps during installation
  - Captures errors and warnings
  - Useful for troubleshooting

## Installation Flow

The installation process follows this sequence:

1. **User Entry Point**
   - User starts with either `start.sh`, `pi-pvr.sh`, or `web-install.sh`

2. **Configuration**
   - User selects services and configures settings
   - System hardware is detected and analyzed

3. **Dependency Installation**
   - Docker and required dependencies are installed
   - VPN and Tailscale are configured if selected

4. **Docker Compose Generation**
   - `generate-compose.sh` creates the Docker Compose file
   - Configures services based on user selections

5. **Service Deployment**
   - Docker Compose stack is started
   - Containers are initialized and configured
   - Services become accessible via web UI

## Web UI Structure (Post-Installation)

After installation, the web UI provides these main functional areas:

1. **Dashboard**
   - System health metrics (CPU, Memory, Disk, Temperature)
   - Service status overview
   - Quick actions

2. **Services Management**
   - Start/stop/restart containers
   - View service status
   - Access service web UIs
   - Update Docker images

3. **Storage Management**
   - Monitor disk usage
   - Manage mount points
   - Configure network shares
   - Browse directories

4. **Network Configuration**
   - Manage VPN settings
   - Configure Tailscale
   - Set up port forwarding
   - Manage network interfaces

5. **Settings**
   - Update system configuration
   - Manage service settings
   - Configure security options
   - Perform system maintenance

6. **Logs**
   - View system logs
   - Monitor container logs
   - Download logs for troubleshooting

## File Relationships

```
                                   +----------------+
                                   |                |
                                   |    start.sh    |
                                   |                |
                                   +-------+--------+
                                           |
                                           v
                  +----------------+     +-------+--------+     +----------------+
                  |                |     |                |     |                |
                  | web-install.sh +---->+  pi-pvr.sh    +---->+web-installer.sh|
                  |                |     |                |     |                |
                  +-------+--------+     +-------+--------+     +-------+--------+
                          |                      |                      |
                          v                      v                      v
                  +----------------+     +-------+--------+     +-------+--------+
                  |                |     |                |     |                |
                  |   server.js    |     |generate-compose.sh  |    api.py      |
                  |                |     |                |     |                |
                  +-------+--------+     +----------------+     +----------------+
                          |                                              |
                          v                                              v
                  +----------------+                             +-------+--------+
                  |                |                             |                |
                  | web-ui assets  |                             |  Docker        |
                  |                |                             |  Containers    |
                  +----------------+                             +----------------+
```

This structure is designed to be modular, allowing for easy extension and customization of the system's components.