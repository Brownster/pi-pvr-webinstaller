# 🐳 PI-PVR Ultimate Media Stack Installer

**PI-PVR Ultimate Media Stack** is a comprehensive Docker-based media server solution with an intuitive web-based installer, designed specifically for Raspberry Pi and other Linux systems. It integrates VPN connectivity, secure remote access via Tailscale, and an extensive array of media management tools.

## Features

- **🔒 VPN Integration**: Routes external traffic through a secure VPN container (Gluetun), supporting multiple providers.
- **🔗 Tailscale**: Enables secure remote access to your server and Docker containers via Tailscale IP.
- **📺 Complete Media Management**:
  - **Full "Arr" Suite**: Sonarr, Radarr, Lidarr, Readarr, Prowlarr, Bazarr
  - **Flexible Download Clients**: Transmission, qBittorrent, NZBGet, SABnzbd, JDownloader
  - **Multiple Media Servers**: Jellyfin, Plex, Emby
  - **Specialized Tools**: Get IPlayer, Overseerr, Tautulli
- **🔄 Modular Architecture**: Mix and match components to build your perfect setup.
- **🖥️ Modern Web UI**: Easy-to-use interface for installation and management.
- **📱 Mobile-Friendly**: Responsive design that works on all devices.
- **🔍 Intelligent Monitoring**: Automated health checks and updates.
- **🛡️ Security-Focused**: Built with best practices for keeping your media server secure.

## Requirements

- Raspberry Pi 4/5 or any Linux-based system (4GB+ RAM recommended)
- Docker and Docker Compose (handled by the installer)
- External storage for media files
- Internet connection
- VPN subscription for providers like PIA, NordVPN, etc. (optional but recommended)
- Tailscale account for secure remote access (optional)

## Installation

### Option 1: Command Line Installation

```bash
git clone https://github.com/Brownster/PI-PVR-0.1.git
cd PI-PVR-0.1
chmod +x pi-pvr.sh
./pi-pvr.sh
```

Follow the on-screen prompts to configure the environment, VPN, and file sharing.

### Option 2: Web-Based Installation (Recommended)

For a more user-friendly installation experience with a web interface:

```bash
chmod +x web-install.sh
./web-install.sh
```

This will start a web-based installer accessible at `http://<your-pi-ip>:8080` where you can:
- Configure all settings through an intuitive interface
- Monitor installation progress in real-time
- Easily reconfigure components after installation
- Access a dashboard for managing your media server

Alternatively, you can run:

```bash
chmod +x pi-pvr.sh
./pi-pvr.sh --web-installer
```

## Usage

### Modular Service Selection

Create a custom stack with exactly the services you need:

```bash
# Example: Full Arr suite with Jellyfin and Transmission
./scripts/generate-compose.sh --arr-apps --media-server jellyfin --torrent-client transmission

# Example: Complete media center with all components
./scripts/generate-compose.sh --all
```

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

Modify the environment variables in the `.env` file to customize your setup:

```bash
cp ./docker-compose/.env.example ./.env
nano ./.env
```

### Hardware Acceleration

For improved transcoding performance on Raspberry Pi:
- Uncomment the device mappings in the media server configuration
- Enable hardware acceleration in your media server settings

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