# PI-PVR Web UI Guide

This guide provides detailed information on using the PI-PVR Web UI, a comprehensive management interface for your media server.

## Dashboard

The dashboard is your central command center, displaying:

- **System Information**: Hostname, operating system, architecture, IP address
- **Resource Usage**: Real-time monitoring of CPU, memory, and disk usage
- **Service Status**: Quick overview of all running services with status indicators
- **Installation Status**: Current state of the installation process

### Key Features:

- **Real-time Updates**: Dashboard refreshes automatically every 30 seconds
- **Resource Monitoring**: Visual indicators show resource utilization
- **Service Quick Access**: Control services directly from the dashboard

## Services

The Services tab provides detailed management of all your media services:

- **All Services**: Complete list of all services with status and controls
- **Media Management**: Sonarr, Radarr, Prowlarr, etc.
- **Download Clients**: Transmission, NZBGet, etc.
- **Utilities**: Support services and tools

### Key Features:

- **Service Cards**: Visual representation of each service with description and status
- **Service Controls**: Start, stop, restart services with a single click
- **Batch Operations**: Perform actions on multiple services at once
- **Update Management**: Update Docker images with real-time progress tracking
- **Direct Links**: Quick access to service web interfaces

## Storage

The Storage tab helps you manage your media storage:

- **Connected Drives**: List of all storage devices with usage statistics
- **Media Directories**: Manage directories for Movies, TV Shows, and Downloads
- **Network Shares**: Configure Samba (SMB) and NFS shares

### Key Features:

- **Drive Management**: Mount, unmount, and monitor drives
- **Directory Scanning**: Analyze media directories for size and file count
- **Share Management**: Create and configure network shares for local network access

## Network

The Network tab provides network configuration and monitoring:

- **Network Configuration**: IP address, gateway, DNS settings
- **VPN Management**: Control and monitor VPN connection
- **Tailscale Integration**: Secure remote access setup
- **Port Forwarding**: Manage port forwarding for external access

### Key Features:

- **VPN Controls**: Connect, disconnect, and configure VPN settings
- **Tailscale Controls**: Enable/disable Tailscale for secure remote access
- **Port Management**: Configure and monitor port forwarding

## Settings

The Settings tab allows you to configure various aspects of your media server:

- **General Settings**: User ID, Group ID, timezone, language
- **Services Settings**: Container restart policy, update channel
- **Network Settings**: Port range, VPN kill switch, proxy settings
- **Security Settings**: Password protection, HTTPS configuration
- **Advanced Settings**: Resource limits, hardware acceleration, Docker flags

### Key Features:

- **User-friendly Forms**: Intuitive interface for configuration
- **Real-time Validation**: Immediate feedback on configuration changes
- **Configuration Backup**: Backup and restore system configuration
- **Reset Options**: Reset configuration to defaults if needed

## Logs

The Logs tab provides access to system and service logs:

- **System Logs**: View system-wide logs with filtering options
- **Container Logs**: View logs for specific containers
- **Log Controls**: Filter, search, and download logs

### Key Features:

- **Log Filtering**: Filter logs by source, level, and lines
- **Real-time Updates**: Follow logs in real-time
- **Download Option**: Save logs for offline analysis
- **Clear Option**: Clear logs to start fresh

## Help & Documentation

The Help tab provides access to documentation and support resources:

- **About PI-PVR**: Version information and system details
- **Documentation**: Comprehensive guides for various aspects of the system
- **FAQ**: Common questions and answers
- **Support Resources**: Links to GitHub, Discord, and other support channels

### Key Features:

- **Interactive Guides**: Step-by-step instructions for common tasks
- **Searchable FAQ**: Quick answers to common questions
- **System Information**: Detailed system information for troubleshooting
- **Update Checker**: Check for updates to PI-PVR

## Notifications

The notification system provides real-time feedback on actions and events:

- **Success Notifications**: Confirmation of successful operations
- **Error Notifications**: Information about failed operations
- **Info Notifications**: General information and updates
- **Warning Notifications**: Important warnings that require attention

### Key Features:

- **Visual Feedback**: Color-coded notifications for different types
- **Auto-dismiss**: Notifications automatically disappear after a set time
- **Manual Dismiss**: Click to dismiss notifications early
- **Non-intrusive**: Notifications appear in the corner without disrupting workflow

## Installation Wizard

The Installation Wizard guides you through setting up your media server:

1. **System Configuration**: Basic system settings
2. **Arr Applications**: Selection of media management applications
3. **Download Clients**: Selection of download clients
4. **Media Servers**: Selection of media server software
5. **Utilities**: Selection of supporting utilities
6. **Summary**: Overview of your selections before installation

### Key Features:

- **Step-by-step Process**: Clear guidance through installation
- **Real-time Validation**: Immediate feedback on configuration
- **Progress Tracking**: Visual indication of installation progress
- **Detailed Logs**: Access to installation logs in real-time

## Mobile Support

The Web UI is fully responsive and works on all devices:

- **Responsive Design**: Adapts to any screen size
- **Touch-friendly Controls**: Easy to use on touchscreens
- **Mobile-optimized Views**: Reorganized layouts for smaller screens

## Keyboard Shortcuts

For power users, keyboard shortcuts are available:

- **D**: Go to Dashboard
- **S**: Go to Services
- **T**: Go to Storage
- **N**: Go to Network
- **C**: Go to Settings
- **L**: Go to Logs
- **H**: Go to Help
- **R**: Refresh current page
- **Esc**: Close modals and dialogs

## Theme Support

The Web UI supports both light and dark themes:

- **Dark Mode**: Easier on the eyes in low-light environments
- **Light Mode**: Better visibility in bright environments
- **System Detection**: Automatically matches your system preference
- **Manual Toggle**: Switch between themes with a single click

## Getting Help

If you encounter issues or have questions:

1. Check the documentation in the Help tab
2. Look through the FAQ for common issues
3. Check GitHub issues for known problems
4. Join the Discord community for real-time support
5. Submit a GitHub issue for new problems