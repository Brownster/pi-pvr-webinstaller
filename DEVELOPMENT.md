# PI-PVR Development Guide

This document provides information for developers working on the PI-PVR Ultimate Media Stack project, particularly focusing on the web UI components.

## Architecture Overview

PI-PVR consists of two main components:

1. **Docker-based Media Stack**: A collection of Docker containers running various media services.
2. **Web UI**: A Node.js/Express application with a browser-based interface for managing the stack.

### Web UI Architecture

The Web UI follows a client-server architecture:

#### Backend (Server-Side)

- **Technology**: Node.js with Express
- **Key Files**:
  - `web-ui/server.js`: Main server file containing API endpoints
  - `web-ui/package.json`: Node dependencies

#### Frontend (Client-Side)

- **Technology**: Vanilla JavaScript with modern ES6+ features
- **Key Files**:
  - `web-ui/js/api-client.js`: Centralized API client for all requests
  - `web-ui/js/notifications.js`: Notification system
  - `web-ui/js/main.js`: Main application logic
  - `web-ui/css/main.css`: Styling
  - `web-ui/index.html`: Main HTML structure

## API Documentation

The backend exposes a RESTful API for the frontend to consume:

### System Information

- `GET /api/system`: Get system information (hostname, OS, memory, disk, etc.)
  - Response: System information object

### Services Management

- `GET /api/services`: Get all running services with their status
  - Response: Array of service objects
- `POST /api/start/:container`: Start a container
  - Response: Status object
- `POST /api/stop/:container`: Stop a container
  - Response: Status object
- `POST /api/restart/:container`: Restart a container
  - Response: Status object
- `POST /api/restart`: Restart all containers
  - Response: Status object

### Storage Management

- `GET /api/drives`: Get available drives
  - Response: Array of drive objects

### Update Management

- `POST /api/update/images`: Start Docker image update process
  - Response: Status object
- `GET /api/update/status`: Get update status
  - Response: Status and logs

### Log Management

- `GET /api/logs`: Get installation logs
  - Response: Logs content
- `GET /api/logs/system`: Get system logs
  - Query params: `source`, `level`, `lines`
  - Response: Logs content
- `GET /api/logs/:service`: Get service logs
  - Query params: `lines`
  - Response: Logs content

## Frontend Components

### API Client

The API client (`api-client.js`) centralizes all API requests to maintain DRY principles. It provides a clean interface for the frontend to interact with the backend:

```javascript
// Example usage:
import { systemApi } from './api-client.js';

// Make API request
const systemInfo = await systemApi.getSystemInfo();
```

### Notification System

The notification system (`notifications.js`) provides a unified way to show notifications to users:

```javascript
// Example usage:
import { notify } from './notifications.js';

// Show notification
notify.success('Operation completed successfully');
notify.error('Failed to perform operation');
```

## Development Workflow

### Setting Up Development Environment

1. Clone the repository
2. Install Node.js dependencies:
   ```bash
   cd web-ui
   npm install
   ```
3. Start the development server:
   ```bash
   node server.js
   ```

### Making Changes

1. Backend changes:
   - Modify `server.js` to add/update API endpoints
   - Restart the server to see changes

2. Frontend changes:
   - Modify JavaScript files in `web-ui/js`
   - Update HTML and CSS as needed
   - Refresh the browser to see changes

### Testing

Currently, the project does not have automated tests. Manual testing should be performed for:

1. API endpoint functionality
2. UI responsiveness
3. Error handling
4. Cross-browser compatibility

### Submitting Changes

1. Create a new branch for your feature/fix
2. Make your changes
3. Test thoroughly
4. Create a Pull Request with a clear description of changes

## Design Principles

### DRY (Don't Repeat Yourself)

- Centralized API client prevents duplication of fetch logic
- Reusable UI components and functions
- Common error handling patterns

### Separation of Concerns

- Backend handles data and business logic
- Frontend handles UI and user interaction
- API provides a clean contract between them

### Progressive Enhancement

- Basic functionality works without advanced JavaScript
- Enhanced experience with JavaScript enabled
- Responsive design works on all device sizes

## Future Improvements

- Add TypeScript for better type safety
- Implement a component framework for more modular UI
- Add automated testing (Jest, Cypress)
- Implement state management for complex UI state
- Add authentication and user management
- Improve Docker composition management
- Add more detailed system monitoring