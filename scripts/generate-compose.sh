#!/bin/bash
# Script to generate a custom docker-compose.yml file based on user selections

set -euo pipefail

# Set default paths
COMPOSE_DIR="${COMPOSE_DIR:-$(dirname "$0")/../docker-compose}"
OUTPUT_FILE="${OUTPUT_FILE:-$(dirname "$0")/../docker-compose.yml}"
ENV_FILE="${ENV_FILE:-$(dirname "$0")/../.env}"

# Default services
SERVICES=(
  "base"
)

# Variables for service selections
MEDIA_SERVER=""
TORRENT_CLIENT="transmission"
USENET_CLIENT="nzbget"
USE_DIRECT_DOWNLOAD="false"
USE_DASHBOARD="false"
USE_REQUESTS="false"
USE_MONITORING="false"
USE_PROXY="false"

# Flag for full arr stack
FULL_ARR_STACK="false"

# Function to print help
print_help() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Generate a custom docker-compose.yml file based on service selections."
  echo ""
  echo "Options:"
  echo "  -h, --help                 Show this help message"
  echo "  -o, --output FILE          Output docker-compose file (default: ../docker-compose.yml)"
  echo "  -e, --env FILE             Environment file (default: ../.env)"
  echo "  -a, --arr-apps             Include all Arr applications (Sonarr, Radarr, Lidarr, Readarr, Prowlarr, Bazarr)"
  echo "  -m, --media-server NAME    Media server to use (jellyfin, plex, emby, all)"
  echo "  -t, --torrent-client NAME  Torrent client to use (transmission, qbittorrent)"
  echo "  -u, --usenet-client NAME   Usenet client to use (nzbget, sabnzbd)"
  echo "  -d, --direct-download      Include JDownloader for direct downloads"
  echo "  --dashboard                Include Heimdall dashboard"
  echo "  --requests                 Include Overseerr for media requests"
  echo "  --monitoring               Include Tautulli for Plex monitoring"
  echo "  --proxy                    Include Nginx Proxy Manager"
  echo "  --all                      Include all services"
  echo ""
  echo "Examples:"
  echo "  $0 -a -m jellyfin -t transmission -u nzbget"
  echo "  $0 --all"
  echo "  $0 -a -m plex --dashboard --requests --monitoring"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      print_help
      exit 0
      ;;
    -o|--output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    -e|--env)
      ENV_FILE="$2"
      shift 2
      ;;
    -a|--arr-apps)
      FULL_ARR_STACK="true"
      shift
      ;;
    -m|--media-server)
      MEDIA_SERVER="$2"
      shift 2
      ;;
    -t|--torrent-client)
      TORRENT_CLIENT="$2"
      shift 2
      ;;
    -u|--usenet-client)
      USENET_CLIENT="$2"
      shift 2
      ;;
    -d|--direct-download)
      USE_DIRECT_DOWNLOAD="true"
      shift
      ;;
    --dashboard)
      USE_DASHBOARD="true"
      shift
      ;;
    --requests)
      USE_REQUESTS="true"
      shift
      ;;
    --monitoring)
      USE_MONITORING="true"
      shift
      ;;
    --proxy)
      USE_PROXY="true"
      shift
      ;;
    --all)
      FULL_ARR_STACK="true"
      MEDIA_SERVER="all"
      TORRENT_CLIENT="transmission"
      USENET_CLIENT="nzbget"
      USE_DIRECT_DOWNLOAD="true"
      USE_DASHBOARD="true"
      USE_REQUESTS="true"
      USE_MONITORING="true"
      USE_PROXY="true"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      print_help
      exit 1
      ;;
  esac
done

# Add arr services if full arr stack selected
if [[ "$FULL_ARR_STACK" == "true" ]]; then
  SERVICES+=("arr")
fi

# Add download services based on selected clients
SERVICES+=("download")

# Add media server based on selection
if [[ "$MEDIA_SERVER" == "jellyfin" || "$MEDIA_SERVER" == "all" ]]; then
  PROFILES+=("--profile jellyfin")
fi
if [[ "$MEDIA_SERVER" == "plex" || "$MEDIA_SERVER" == "all" ]]; then
  PROFILES+=("--profile plex")
fi
if [[ "$MEDIA_SERVER" == "emby" || "$MEDIA_SERVER" == "all" ]]; then
  PROFILES+=("--profile emby")
fi

# Add alternate torrent client if selected
if [[ "$TORRENT_CLIENT" == "qbittorrent" ]]; then
  PROFILES+=("--profile alt_torrent")
fi

# Add alternate usenet client if selected
if [[ "$USENET_CLIENT" == "sabnzbd" ]]; then
  PROFILES+=("--profile alt_usenet")
fi

# Add direct download client if selected
if [[ "$USE_DIRECT_DOWNLOAD" == "true" ]]; then
  PROFILES+=("--profile direct_download")
fi

# Add utilities
SERVICES+=("utilities")

# Add utility profiles based on selections
if [[ "$USE_DASHBOARD" == "true" ]]; then
  PROFILES+=("--profile dashboard")
fi
if [[ "$USE_REQUESTS" == "true" ]]; then
  PROFILES+=("--profile requests")
fi
if [[ "$USE_MONITORING" == "true" ]]; then
  PROFILES+=("--profile monitoring")
fi
if [[ "$USE_PROXY" == "true" ]]; then
  PROFILES+=("--profile proxy")
fi

# Detect system and set hardware acceleration options
echo "Detecting system for hardware acceleration..."
if [[ -x "${SCRIPT_DIR}/detect-system.sh" ]]; then
  SYSTEM_INFO=$(bash "${SCRIPT_DIR}/detect-system.sh")
  
  # Extract transcoding info
  V4L2_AVAILABLE=$(echo "$SYSTEM_INFO" | grep -o '"v4l2_available": [^,]*' | cut -d' ' -f2)
  VAAPI_AVAILABLE=$(echo "$SYSTEM_INFO" | grep -o '"vaapi_available": [^,]*' | cut -d' ' -f2)
  NVDEC_AVAILABLE=$(echo "$SYSTEM_INFO" | grep -o '"nvdec_available": [^,]*' | cut -d' ' -f2)
  RECOMMENDED_TRANSCODING=$(echo "$SYSTEM_INFO" | grep -o '"recommended_method": "[^"]*"' | cut -d'"' -f4)
  
  # Set hardware acceleration devices based on detected capabilities
  if [[ "$V4L2_AVAILABLE" == "true" ]]; then
    echo "Raspberry Pi hardware acceleration detected, using V4L2"
    export HW_ACCEL_JELLYFIN="devices:
      - /dev/video10:/dev/video10
      - /dev/video11:/dev/video11
      - /dev/video12:/dev/video12
      - /dev/vchiq:/dev/vchiq"
    export HW_ACCEL_PLEX="$HW_ACCEL_JELLYFIN"
    export HW_ACCEL_EMBY="$HW_ACCEL_JELLYFIN"
  elif [[ "$VAAPI_AVAILABLE" == "true" ]]; then
    echo "Intel/AMD GPU hardware acceleration detected, using VAAPI"
    export HW_ACCEL_JELLYFIN="devices:
      - /dev/dri:/dev/dri"
    export HW_ACCEL_PLEX="$HW_ACCEL_JELLYFIN"
    export HW_ACCEL_EMBY="$HW_ACCEL_JELLYFIN"
  elif [[ "$NVDEC_AVAILABLE" == "true" ]]; then
    echo "NVIDIA GPU hardware acceleration detected, using NVDEC"
    export HW_ACCEL_JELLYFIN="runtime: nvidia
    devices:
      - /dev/nvidia0:/dev/nvidia0
      - /dev/nvidiactl:/dev/nvidiactl
      - /dev/nvidia-modeset:/dev/nvidia-modeset"
    export HW_ACCEL_PLEX="$HW_ACCEL_JELLYFIN"
    export HW_ACCEL_EMBY="$HW_ACCEL_JELLYFIN"
  else
    echo "No hardware acceleration detected, using software transcoding"
    export HW_ACCEL_JELLYFIN=""
    export HW_ACCEL_PLEX=""
    export HW_ACCEL_EMBY=""
  fi
else
  echo "System detection script not found, using software transcoding"
  export HW_ACCEL_JELLYFIN=""
  export HW_ACCEL_PLEX=""
  export HW_ACCEL_EMBY=""
fi

# Generate docker-compose file paths
COMPOSE_FILES=""
for SERVICE in "${SERVICES[@]}"; do
  COMPOSE_FILES+=" -f ${COMPOSE_DIR}/docker-compose.${SERVICE}.yml"
done

# Create the command
CMD="docker-compose ${COMPOSE_FILES} ${PROFILES[*]} config > ${OUTPUT_FILE}"

# Display the command
echo "Generating docker-compose.yml with the following services:"
for SERVICE in "${SERVICES[@]}"; do
  echo "  - ${SERVICE}"
done
echo ""
echo "Selected profiles:"
for PROFILE in "${PROFILES[@]}"; do
  echo "  - ${PROFILE}"
done
echo ""
echo "Running command: ${CMD}"

# Execute the command
eval "${CMD}"

echo "Docker Compose file generated at: ${OUTPUT_FILE}"
echo "You can now run 'docker-compose -f ${OUTPUT_FILE} up -d' to start your services."