# PI-PVR Ultimate Media Stack - Project Structure

This document provides an overview of the project's directory structure and key files.

## Top-Level Directories

- **docker-compose/** - Contains modular docker-compose configuration files
- **scripts/** - Shell scripts and utilities for the project
- **web-ui/** - The web-based installer interface
- **config/** - Configuration files (created during setup)
- **logs/** - Log files (created during setup)

## Key Files

- **pi-pvr.sh** - The main command-line installer
- **web-install.sh** - Entry point for the web-based installer
- **README.md** - Project documentation
- **ROADMAP.md** - Planned features and development roadmap
- **CLAUDE.md** - Guidelines for AI assistants working on this project
- **requirements.txt** - Python dependencies

## Docker Compose Files

- **docker-compose/docker-compose.base.yml** - Core infrastructure (networks, shared volumes)
- **docker-compose/docker-compose.arr.yml** - Arr applications (Sonarr, Radarr, etc.)
- **docker-compose/docker-compose.download.yml** - Download clients (Transmission, NZBGet, etc.)
- **docker-compose/docker-compose.media.yml** - Media servers (Jellyfin, Plex, Emby)
- **docker-compose/docker-compose.utilities.yml** - Utility services (Heimdall, etc.)
- **docker-compose/.env.example** - Example environment variables

## Scripts

- **scripts/generate-compose.sh** - Script to generate docker-compose.yml from modular files
- **scripts/api.py** - API server for the web installer

## Web UI Structure

- **web-ui/index.html** - Main web interface
- **web-ui/static/css/style.css** - Web UI styling
- **web-ui/static/js/app.js** - Web UI JavaScript
- **web-ui/static/img/** - Images for the web interface

## Generated Files

During installation, the following files and directories are created:

- **docker-compose.yml** - The generated docker-compose file
- **.env** - Environment variables for the installation
- **~/docker/** - Docker configuration files and volumes
- **~/services_urls.txt** - List of service URLs

## Created During Operation

- **config/config.json** - User configuration
- **config/services.json** - Services configuration
- **logs/installation.log** - Installation log