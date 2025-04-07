# PI-PVR Development Guide

This comprehensive guide provides detailed information for developers working on the PI-PVR Ultimate Media Stack project, covering both the core components and the web UI.

## System Architecture

PI-PVR follows a modular architecture with three main components:

1. **Core Installation Scripts**: Bash scripts for system setup and configuration
2. **Docker-based Media Stack**: Modular Docker Compose files for containerized services
3. **Web UI & API**: Python Flask API and JavaScript frontend for management

### Core Component Relationships

```
                  +-------------------+
                  |                   |
                  |  Web UI (JS/HTML) |
                  |                   |
                  +--------+----------+
                           |
                           | HTTP
                           v
                  +-------------------+
                  |                   |
                  |   Flask API (PY)  |
                  |                   |
                  +--------+----------+
                           |
                           | Shell Commands
                           v
                  +-------------------+
                  |                   |
                  |  Bash Scripts     |
                  |                   |
                  +--------+----------+
                           |
                           | Docker Commands
                           v
                  +-------------------+
                  |                   |
                  | Docker Containers |
                  |                   |
                  +-------------------+
```

## Installation Components

### Main Installer Scripts

- **pi-pvr.sh**: Command-line installer offering interactive setup
- **web-installer.sh**: Web-based installer with Flask backend
- **web-ui.sh**: Starts the management web UI after installation
- **scripts/generate-compose.sh**: Creates Docker Compose config based on selections

### Docker Compose Structure

The system uses a modular Docker Compose architecture with separate files:

- **docker-compose.base.yml**: Networks, volumes, shared configuration
- **docker-compose.arr.yml**: Arr applications (Sonarr, Radarr, Lidarr, etc.)
- **docker-compose.download.yml**: Download clients (Transmission, NZBGet, etc.)
- **docker-compose.media.yml**: Media servers (Jellyfin, Plex, Emby)
- **docker-compose.utilities.yml**: Supporting services (Heimdall, Portainer, etc.)

This architecture allows for mix-and-match service selection during installation.

## API Architecture

### API Backend (Python Flask)

The API server provides endpoints for both the installer and management UI:

- **scripts/api.py**: Main API server with the following components:
  - System information collection
  - Docker container management
  - Storage configuration
  - Service health monitoring
  - Configuration management
  - Installation process

### API Endpoints

#### System Information

- `GET /api/system`: Get system information (hostname, OS, memory, disk, temperature, etc.)
  - Response: Detailed system information object including CPU temperature and usage
  - Example: `{ "hostname": "raspberrypi", "os": { "name": "linux" }, "temperature_celsius": 45.2, ... }`

#### Container Management

- `GET /api/status`: Get status of Docker and containers
  - Response: Installation status and container information
  - Example: `{ "installation_status": "completed", "containers": { "sonarr": { "status": "running" } } }`

- `GET /api/services`: Get formatted service information for UI
  - Response: Array of service objects with name, status, type, URL, etc.
  - Example: `{ "services": [{ "name": "sonarr", "status": "running", "url": "http://localhost:8989" }] }`

- `POST /api/start/<container>`: Start a container
  - Response: Success or error status
  - Example: `{ "status": "success" }`

- `POST /api/stop/<container>`: Stop a container
  - Response: Success or error status

- `POST /api/restart/<container>`: Restart a container
  - Response: Success or error status
  
- `POST /api/restart`: Restart all containers
  - Response: Success or error status

#### Configuration

- `GET /api/config`: Get current configuration
  - Response: Configuration object
  - Example: `{ "puid": 1000, "pgid": 1000, "timezone": "Europe/London", ... }`

- `POST /api/config`: Save configuration
  - Body: Configuration object
  - Response: Success or error status

- `GET /api/services`: Get service selections
  - Response: Service selection object
  - Example: `{ "arr_apps": { "sonarr": true, ... }, "media_servers": { "jellyfin": true, ... } }`

- `POST /api/services`: Save service selections
  - Body: Service selection object
  - Response: Success or error status

#### Storage Management

- `GET /api/drives`: Get available drives and usage
  - Response: Array of drive objects
  - Example: `{ "drives": [{ "device": "/dev/sda1", "mountPoint": "/mnt/media", ... }] }`

#### Installation

- `POST /api/install`: Start installation process
  - Response: Status object
  - Example: `{ "status": "started", "message": "Installation started" }`

- `GET /api/logs`: Get installation logs
  - Response: Logs content
  - Example: `{ "logs": "2023-04-01 12:00:00 Started installation\n..." }`

#### Docker Compose Generation

- `POST /api/generate-compose`: Generate Docker Compose configuration
  - Response: Success or error status and output
  - Example: `{ "success": true, "output": "Generated docker-compose.yml with 5 services" }`

## Web UI Architecture

### Web UI Structure

The web UI uses a modern, responsive design with modular JavaScript components:

- **Frontend**: Vanilla JavaScript with ES6+ features, without external frameworks
- **CSS**: Custom CSS with a responsive design
- **HTML**: Modular HTML structure with component-based organization

### Key Frontend Files

- **web-ui/index.html**: Main UI page with dashboard, services, and management tabs
- **web-ui/js/api-client.js**: Centralized API client for all backend requests
- **web-ui/js/notifications.js**: Toast notification system
- **web-ui/js/main.js**: Main application logic
- **web-ui/css/main.css**: CSS styling

### Frontend Components

The UI consists of these main functional components:

1. **System Dashboard**: Shows system metrics (CPU, memory, disk, temperature)
2. **Services Panel**: Displays and manages all Docker containers
3. **Storage Management**: Configures and monitors storage devices and mounts
4. **Network Configuration**: Manages network settings, VPN, and port forwards
5. **Installation Wizard**: Step-by-step setup for new installations
6. **Settings Interface**: System configuration management
7. **Logs Viewer**: Displays and filters system and container logs

### API Client Module

The API client (`api-client.js`) provides a clean interface for backend communication:

```javascript
// Example of the API client organization
export const systemApi = {
  getSystemInfo: () => apiRequest('/system'),
  getStatus: () => apiRequest('/status')
};

export const servicesApi = {
  getAllServices: () => apiRequest('/services'),
  startService: (serviceName) => apiRequest(`/services/${serviceName}/start`, { method: 'POST' }),
  stopService: (serviceName) => apiRequest(`/services/${serviceName}/stop`, { method: 'POST' }),
  restartService: (serviceName) => apiRequest(`/services/${serviceName}/restart`, { method: 'POST' }),
  restartAll: () => apiRequest('/services/restart-all', { method: 'POST' })
};
```

## Development Workflows

### Setting Up Development Environment

1. Clone the repository:
   ```bash
   git clone https://github.com/Brownster/PI-PVR-0.1.git
   cd PI-PVR-0.1
   ```

2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Install Node.js dependencies for the web UI:
   ```bash
   cd web-ui
   npm install
   ```

4. Start the API server for development:
   ```bash
   cd scripts
   python api.py
   ```

5. In a separate terminal, start the web UI:
   ```bash
   cd web-ui
   node server.js
   ```

6. Access the development UI at http://localhost:8080

### API Development

To add or modify API endpoints:

1. Edit `scripts/api.py` to add new routes or modify existing ones
2. Add any necessary support functions for the endpoint
3. Test the endpoint with `curl` or through the UI
4. Document the new endpoint in this development guide

Example of adding a new API endpoint:

```python
@app.route('/api/custom-endpoint', methods=['GET'])
def api_custom_endpoint():
    # Your custom endpoint logic here
    return jsonify({
        "status": "success",
        "data": custom_data
    })
```

### Frontend Development

To modify the frontend:

1. Edit the appropriate files in `web-ui/js/` for JavaScript changes
2. Update `web-ui/css/main.css` for styling changes
3. Modify HTML templates in `web-ui/` for structural changes
4. Add new API client methods to `web-ui/js/api-client.js` if needed
5. Refresh the browser to see changes

Example of adding a new API client method:

```javascript
export const customApi = {
  getCustomData: () => apiRequest('/custom-endpoint')
};
```

### Docker Services Management

To add or modify Docker services:

1. Update the appropriate docker-compose file in `docker-compose/`
2. Modify `scripts/generate-compose.sh` to include the new service options
3. Update the service type mappings in `scripts/api.py` (`get_container_status()` function)
4. Test the service integration with the UI

## Testing

### Manual Testing Procedures

1. **API Testing**:
   - Test each endpoint individually with `curl` or Postman
   - Verify proper response formats and error handling
   - Test with invalid inputs to ensure proper validation

2. **Web UI Testing**:
   - Test across multiple browsers (Chrome, Firefox, Safari)
   - Test responsive design on different screen sizes
   - Verify all buttons and interactive elements work correctly
   - Test form validation and error handling

3. **Installation Testing**:
   - Test the complete installation process with various configurations
   - Verify all selected services are properly installed
   - Check that port mappings are correct
   - Verify storage mounts are properly configured

4. **Integration Testing**:
   - Test interaction between UI, API, and Docker containers
   - Verify container management works correctly
   - Test system resource monitoring accuracy

### Future Test Automation

Plans for automated testing include:

1. **Python Tests**: Using pytest for API endpoint testing
2. **JavaScript Tests**: Using Jest for UI component testing
3. **End-to-End Tests**: Using Cypress for complete workflow testing
4. **Docker Compose Validation**: Automated validation of Docker Compose configurations

## Design Principles

### Modularity

- Each component is designed to be independent and replaceable
- Docker services are modular and can be individually enabled/disabled
- UI components are logically separated by function

### Configurability

- All aspects of the system are configurable through the UI
- Service selection is flexible during installation
- Storage configuration supports multiple options (USB, network, local)

### Error Handling

- Comprehensive error handling at all levels
- User-friendly error messages in the UI
- Detailed logging for debugging
- Graceful degradation when components fail

### Security

- VPN integration for download clients
- Proper permission handling for media files
- No external API dependencies for core functionality
- Option for HTTPS and password protection

## Advanced Topics

### Custom Service Integration

To add custom services to PI-PVR:

1. Create a Docker Compose service definition in the appropriate file
2. Update the service mappings in `get_container_status()` in `api.py`
3. Add the service to the UI service selection options
4. Test the integration

Example of adding a custom service:

```yaml
# In docker-compose.utilities.yml
my-custom-service:
  image: username/custom-service
  container_name: my-custom-service
  ports:
    - "8123:8123"
  volumes:
    - ${MEDIA_DIR}:/media
  restart: unless-stopped
```

### Hardware Acceleration

PI-PVR automatically detects and configures hardware acceleration:

- **Raspberry Pi**: V4L2 (VideoCore) acceleration
- **Intel/AMD**: VAAPI acceleration
- **NVIDIA**: NVENC/NVDEC acceleration

The detection is handled in `scripts/detect-system.sh` and applied in `scripts/generate-compose.sh`.

### Network Configuration

Advanced network options include:

- **VPN Integration**: Route specific services through VPN
- **Tailscale**: Secure remote access without port forwarding
- **Port Forwarding**: Expose services to the internet
- **Reverse Proxy**: Nginx Proxy Manager for domain-based access

## Common Development Tasks

### Adding a New Service

1. Add the service to the appropriate Docker Compose file
2. Update `DEFAULT_SERVICES` in `api.py` to include the new service
3. Add the service to `service_types`, `default_ports`, and `service_descriptions` in `get_container_status()`
4. Add UI elements for configuring the service in the installation wizard
5. Test that the service is correctly installed and manageable

### Implementing a New Feature

1. Plan the feature and determine which components need to be modified
2. Update the API if new endpoints are needed
3. Update the UI to include controls for the new feature
4. Test the feature thoroughly
5. Update documentation to reflect the new feature

### Debugging Tips

1. Check the logs in `logs/installation.log` for installation issues
2. Use the browser developer console for UI debugging
3. Check Docker logs with `docker logs <container_name>` for service issues
4. Enable debug mode in the API with `app.run(debug=True)`
5. Add temporary logging statements with `print()` or `console.log()`

## Future Roadmap

See [ROADMAP.md](ROADMAP.md) for planned features. Key technical improvements include:

- TypeScript integration for better type safety
- Component framework for more modular UI
- Automated testing infrastructure
- User authentication system
- Enhanced monitoring and alerting
- Mobile app integration