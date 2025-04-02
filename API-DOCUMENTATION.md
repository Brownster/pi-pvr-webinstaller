# PI-PVR API Documentation

This document provides reference information for the PI-PVR API endpoints.

## Base URL

All API endpoints are relative to the base URL of your PI-PVR installation:

```
http://<your-pi-ip>:8080/api
```

## Authentication

Currently, the API does not require authentication. This will be added in a future update.

## Error Handling

All API endpoints return standard HTTP status codes:

- `200 OK`: The request was successful
- `400 Bad Request`: The request was invalid
- `404 Not Found`: The requested resource was not found
- `500 Internal Server Error`: An error occurred on the server

Error responses include a JSON body with error details:

```json
{
  "error": "Error message",
  "details": "Detailed error information (if available)"
}
```

## API Endpoints

### System Information

#### Get System Information

```
GET /system
```

Returns detailed information about the system.

**Response Example:**

```json
{
  "hostname": "pi-pvr",
  "os": {
    "name": "Debian",
    "version": "12",
    "pretty_name": "Debian GNU/Linux 12 (bookworm)",
    "id": "debian"
  },
  "architecture": "aarch64",
  "memory_total": 4294967296,
  "memory_available": 2147483648,
  "disk_total": 107374182400,
  "disk_free": 53687091200,
  "cpu_usage": 15,
  "docker_installed": true,
  "docker_version": "24.0.5",
  "tailscale_installed": true,
  "tailscale_ip": "100.100.100.100",
  "ip_address": "192.168.1.100",
  "installation_status": "completed"
}
```

### Configuration

#### Get Configuration

```
GET /config
```

Returns the current system configuration.

**Response Example:**

```json
{
  "puid": 1000,
  "pgid": 1000,
  "timezone": "Europe/London",
  "media_dir": "/mnt/media",
  "downloads_dir": "/mnt/downloads",
  "docker_dir": "/home/pi/docker",
  "vpn": {
    "enabled": true,
    "provider": "private internet access",
    "region": "Netherlands"
  },
  "tailscale": {
    "enabled": false
  },
  "installation_status": "completed"
}
```

#### Update Configuration

```
POST /config
```

Updates the system configuration.

**Request Body Example:**

```json
{
  "puid": 1000,
  "pgid": 1000,
  "timezone": "Europe/Paris"
}
```

**Response Example:**

```json
{
  "status": "success"
}
```

### Services

#### Get All Services

```
GET /services
```

Returns information about all services.

**Response Example:**

```json
{
  "services": [
    {
      "name": "sonarr",
      "type": "media",
      "status": "running",
      "port": 8989,
      "url": "http://192.168.1.100:8989",
      "description": "TV show management"
    },
    {
      "name": "radarr",
      "type": "media",
      "status": "running",
      "port": 7878,
      "url": "http://192.168.1.100:7878",
      "description": "Movie management"
    },
    // Additional services...
  ]
}
```

#### Start Service

```
POST /start/:container
```

Starts a specific container.

**Path Parameters:**

- `container`: The name of the container to start

**Response Example:**

```json
{
  "status": "success"
}
```

#### Stop Service

```
POST /stop/:container
```

Stops a specific container.

**Path Parameters:**

- `container`: The name of the container to stop

**Response Example:**

```json
{
  "status": "success"
}
```

#### Restart Service

```
POST /restart/:container
```

Restarts a specific container.

**Path Parameters:**

- `container`: The name of the container to restart

**Response Example:**

```json
{
  "status": "success"
}
```

#### Restart All Services

```
POST /restart
```

Restarts all containers.

**Response Example:**

```json
{
  "status": "success"
}
```

### Storage

#### Get Drives

```
GET /drives
```

Returns information about connected drives.

**Response Example:**

```json
{
  "drives": [
    {
      "device": "/dev/sda1",
      "size": "500G",
      "type": "ext4"
    },
    {
      "device": "/dev/sdb1",
      "size": "1T",
      "type": "ext4"
    }
  ]
}
```

### Update Management

#### Start Image Update

```
POST /update/images
```

Starts the process of updating all Docker images.

**Response Example:**

```json
{
  "status": "success",
  "message": "Image update process started"
}
```

#### Get Update Status

```
GET /update/status
```

Returns the status of the image update process.

**Response Example:**

```json
{
  "status": "in_progress",
  "logs": "Starting Docker image updates...\nPulling image sonarr:latest...\nPulling image radarr:latest..."
}
```

### Logs

#### Get Installation Logs

```
GET /logs
```

Returns the installation logs.

**Response Example:**

```json
{
  "logs": "Installation started...\nInstalling Docker...\nDocker installed successfully...\n"
}
```

#### Get System Logs

```
GET /logs/system
```

Returns system logs.

**Query Parameters:**

- `source`: Log source (system, installer, vpn, docker)
- `level`: Log level (all, info, warning, error)
- `lines`: Number of lines to return (default: 100)

**Response Example:**

```json
{
  "content": "2025-04-02 10:00:05 [INFO] System startup\n2025-04-02 10:00:10 [INFO] Loading configuration\n...",
  "source": "system",
  "level": "all",
  "lines": 100
}
```

#### Get Service Logs

```
GET /logs/:service
```

Returns logs for a specific service.

**Path Parameters:**

- `service`: The name of the service to get logs for

**Query Parameters:**

- `lines`: Number of lines to return (default: 100)

**Response Example:**

```json
{
  "content": "Starting Sonarr...\nSonarr started successfully...\n",
  "service": "sonarr",
  "lines": 100
}
```

### Installation

#### Start Installation

```
POST /install
```

Starts the installation process.

**Response Example:**

```json
{
  "status": "started"
}
```

## JavaScript API Client

For frontend developers, PI-PVR provides a JavaScript API client that centralizes all API calls. This client is available in `web-ui/js/api-client.js` and can be imported in your JavaScript modules:

```javascript
import { systemApi, servicesApi, storageApi, networkApi, updateApi, configApi, logsApi } from './api-client.js';

// Example: Get system information
const systemInfo = await systemApi.getSystemInfo();

// Example: Start a service
await servicesApi.startService('sonarr');

// Example: Get logs
const logs = await logsApi.getSystemLogs('system', 'all', 100);
```

The API client handles error reporting and provides a consistent interface for all API endpoints.

## WebSocket API (Coming Soon)

A WebSocket API will be added in a future update to provide real-time updates without polling. This will enable:

- Real-time resource usage monitoring
- Instant service status updates
- Live log streaming
- Installation progress events

## API Versioning

The current API is v1 (implicit). Future versions will be explicitly versioned in the URL path (e.g., `/api/v2/system`).

## Rate Limiting

Currently, there are no rate limits on the API. However, excessive requests may impact system performance.

## Future Enhancements

Planned API enhancements include:

- Authentication and authorization
- Pagination for list endpoints
- Filtering and sorting options
- WebSocket support for real-time updates
- Comprehensive error codes
- API versioning
- Rate limiting