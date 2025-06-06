# 🐳 PI-PVR Ultimate Media Stack Installer

**PI-PVR Ultimate Media Stack** is a comprehensive Docker-based media server solution with an intuitive web-based installer, designed for both Raspberry Pi and x86/x64 Linux systems. It intelligently detects your hardware and configures services optimally for your system. With support for VPN connectivity, secure remote access via Tailscale, and an extensive array of media management tools, it works on everything from a Raspberry Pi to a powerful desktop.

> **Recent Enhancements**: The latest version now includes a complete system health dashboard with temperature monitoring, enhanced container management with proper URL linking for all services, comprehensive storage configuration with support for multiple USB drives, network shares (SMB/CIFS, NFS), and local paths. The modular architecture allows for custom service combinations including full audiobook support via Readarr.

## Features

![image](https://github.com/user-attachments/assets/60ce9daf-3f7a-4a59-8ab1-5eb4be74a7a7)

- **🔒 VPN Integration**: Routes external traffic through a secure VPN container (Gluetun), supporting multiple providers.
- **🔗 Tailscale**: Enables secure remote access to your server and Docker containers via Tailscale IP.
- **📺 Complete Media Management**:
  - **Full "Arr" Suite**: Sonarr, Radarr, Lidarr, Readarr, Prowlarr, Bazarr
  - **Flexible Download Clients**: Transmission, qBittorrent, NZBGet, SABnzbd, JDownloader
  - **Multiple Media Servers**: Jellyfin, Plex, Emby
  - **Specialized Tools**: Get IPlayer, Overseerr, Tautulli
- **🧠 Smart System Detection**:
  - **Hardware Acceleration**: Automatically detects and configures GPU/CPU transcoding (VAAPI, NVDEC, V4L2)
  - **Cross-Platform**: Works on Raspberry Pi, Desktop Linux, and Servers
  - **Adaptive Configuration**: Optimizes settings for your specific hardware
- **🌐 Remote Installation**: Install directly from your laptop to your Raspberry Pi or server
- **🔄 Modular Architecture**: Mix and match components to build your perfect setup.
- **🖥️ Modern Web UI**: Easy-to-use interface for installation and management with an intuitive dashboard.
- **📱 Mobile-Friendly**: Responsive design that works on all devices with real-time notifications.
- **🔍 Intelligent Monitoring**: Automated health checks, resource monitoring, and container status tracking.
- **🛡️ Security-Focused**: Built with best practices for keeping your media server secure.
- **🔄 Real-time Updates**: Live updates of service status, resource usage, and system information.
- **📊 Comprehensive Dashboard**: Monitor and manage all aspects of your media server from one interface.

## Requirements

- Raspberry Pi 4/5 or any Linux-based system (4GB+ RAM recommended)
- Docker and Docker Compose (handled by the installer)
- External storage for media files
- Internet connection
- VPN subscription for providers like PIA, NordVPN, etc. (optional but recommended)
- Tailscale account for secure remote access (optional)

## Installation

### Option 1: Using the Start Script (Recommended)

This is the easiest way to start, as it provides a menu of installation options:

```bash
git clone https://github.com/Brownster/PI-PVR-0.1.git
cd PI-PVR-0.1
chmod +x start.sh
./start.sh
```

From the menu, select one of the installation options:
1. Command Line Installation
2. Web-Based Installation
3. Remote Installation (coming soon)
4. Update Existing Installation

### Option 2: Command Line Installation

```bash
git clone https://github.com/Brownster/PI-PVR-0.1.git
cd PI-PVR-0.1
chmod +x pi-pvr.sh
./pi-pvr.sh
```

Follow the on-screen prompts to configure the environment, VPN, and file sharing.

### Option 3: Web-Based Installation

For a more user-friendly installation experience with a modern web interface:

```bash
chmod +x web-ui.sh
./web-ui.sh
```

This will start the web UI server accessible at `http://<your-pi-ip>:8080` where you can:
- Configure all settings through an intuitive, mobile-friendly interface
- Select specific Docker containers including support for audiobooks (Readarr)
- Add multiple USB mounts with flexible configuration options
- Set up network shares (both SMB/CIFS and NFS) as mount points
- Configure local folder paths with custom permissions and ownership
- Manage media services with the comprehensive dashboard
- Monitor system resource usage with real-time graphs and statistics
- Monitor installation progress in real-time with detailed status updates
- View system and container logs with filtering and search capabilities
- Receive real-time notifications for important events and status changes
- Update Docker images and containers with a single click
- Restart, stop, or start services individually or in batch operations
- Access detailed documentation and help directly from the interface

## Usage

### Modular Service Selection

Create a custom stack with exactly the services you need using the generate-compose.sh script:

```bash
# Example: Full Arr suite with Jellyfin and Transmission
./scripts/generate-compose.sh --arr-apps --media-server jellyfin --torrent-client transmission

# Example: Complete media center with all components
./scripts/generate-compose.sh --all
```

Available options for the generate-compose.sh script:
- `--arr-apps`: Include all Arr applications (Sonarr, Radarr, Lidarr, Readarr, Prowlarr, Bazarr)
- `--media-server NAME`: Media server to use (jellyfin, plex, emby, all)
- `--torrent-client NAME`: Torrent client to use (transmission, qbittorrent)
- `--usenet-client NAME`: Usenet client to use (nzbget, sabnzbd)
- `--direct-download`: Include JDownloader for direct downloads
- `--dashboard`: Include Heimdall dashboard
- `--requests`: Include Overseerr for media requests
- `--monitoring`: Include Tautulli for Plex monitoring
- `--proxy`: Include Nginx Proxy Manager
- `--all`: Include all services

### Service Management

Access your services via the web interface or directly from your browser:

| Service | Default URL | Description |
|---------|-------------|-------------|
| Dashboard | http://\<IP\>:80 | Heimdall application dashboard |
| Prowlarr | http://\<IP\>:9696 | Indexer management |
| Sonarr | http://\<IP\>:8989 | TV show management |
| Radarr | http://\<IP\>:7878 | Movie management |
| Lidarr | http://\<IP\>:8686 | Music management |
| Readarr | http://\<IP\>:8787 | Book management |
| Bazarr | http://\<IP\>:6767 | Subtitle management |
| Transmission | http://\<IP\>:9091 | Torrent client |
| NZBGet | http://\<IP\>:6789 | Usenet client |
| Jellyfin | http://\<IP\>:8096 | Open source media server |
| Get iPlayer | http://\<IP\>:1935 | BBC iPlayer downloader |

### Remote Access

Access your media server from anywhere using Tailscale:
- Replace `<IP>` with your Tailscale IP in service URLs
- Enjoy secure, encrypted connections without port forwarding

## Advanced Configuration

### Custom Docker Compose

Create and modify the environment variables in the `.env` file to customize your setup:

```bash
# The .env file is automatically created during installation, 
# but you can modify it manually:
nano ./.env
```

### Hardware Acceleration

The installer automatically detects your hardware and configures the appropriate transcoding method:

- **Raspberry Pi**: Uses V4L2 hardware acceleration (VideoCore)
- **Intel/AMD**: Uses VAAPI hardware acceleration
- **NVIDIA**: Uses NVDEC hardware acceleration
- **Other Systems**: Falls back to software transcoding

After installation, hardware acceleration should be ready to use. You only need to:
1. Enable hardware acceleration in your media server settings
2. Choose the correct acceleration method (detected automatically)

## Testing

This project includes unit tests to ensure the stability and reliability of the codebase. The tests cover the following areas:

- **Python API Tests**: Located in the `scripts/test_api.py` file. These tests use the `pytest` framework to verify the functionality of the API endpoints defined in `scripts/api.py`. They cover aspects such as loading and saving configuration, managing services, and retrieving system information. To run these tests, use the command `pytest`.
- **JavaScript Web UI Tests**: Located in the `web-ui/test.js` file. These tests use the `Jest` framework to verify the functionality of the web UI components. They cover aspects such as making API requests and rendering UI elements. To run these tests, use the command `npm test`.

## Contributing

Contributions are welcome! Please check out our [ROADMAP.md](ROADMAP.md) for planned features and our [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License.

## Acknowledgements

- [LinuxServer.io](https://linuxserver.io/) for their excellent Docker containers
- [Servarr](https://wiki.servarr.com/) team for the "Arr" applications
- [Jellyfin](https://jellyfin.org/), [Plex](https://www.plex.tv/), and [Emby](https://emby.media/) teams
- [Gluetun](https://github.com/qdm12/gluetun) for the VPN container
- [Tailscale](https://tailscale.com/) for secure networking
- All open-source contributors that make this ecosystem possible