#!/bin/bash
# System detection script for PI-PVR Ultimate Media Stack
# Detects architecture, OS, and hardware details

set -e

# Get script directory (with support for symlinks)
SCRIPT_DIR="$( cd -- "$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")")" &> /dev/null && pwd )"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Function to detect architecture
detect_architecture() {
  # Get machine architecture
  local ARCH=$(uname -m)
  
  # Map architectures to common names
  case "$ARCH" in
    x86_64)
      echo "x86_64"
      ;;
    amd64)
      echo "x86_64"
      ;;
    i386|i686)
      echo "x86"
      ;;
    armv7l|armv7)
      echo "armv7"
      ;;
    armv6l|armv6)
      echo "armv6"
      ;;
    aarch64|arm64)
      echo "arm64"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

# Function to detect OS and distribution
detect_os() {
  # Check for /etc/os-release file first
  if [ -f /etc/os-release ]; then
    source /etc/os-release
    OS_NAME=$ID
    OS_VERSION=$VERSION_ID
    OS_PRETTY_NAME=$PRETTY_NAME
  # Check for older Debian/Ubuntu systems
  elif [ -f /etc/debian_version ]; then
    OS_NAME="debian"
    OS_VERSION=$(cat /etc/debian_version)
    OS_PRETTY_NAME="Debian/Ubuntu $OS_VERSION"
  # Check for older RHEL/CentOS systems
  elif [ -f /etc/redhat-release ]; then
    OS_NAME="redhat"
    OS_VERSION=$(cat /etc/redhat-release | sed 's/[^0-9.]//g')
    OS_PRETTY_NAME=$(cat /etc/redhat-release)
  # Fall back to basic OS detection
  else
    OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
    OS_VERSION=$(uname -r)
    OS_PRETTY_NAME="${OS_NAME} ${OS_VERSION}"
  fi
  
  # Check for specific Raspberry Pi details
  if [ -f /proc/device-tree/model ] && grep -q "Raspberry Pi" /proc/device-tree/model; then
    IS_RASPBERRY_PI=true
    PI_MODEL=$(tr -d '\0' < /proc/device-tree/model)
  else
    IS_RASPBERRY_PI=false
    PI_MODEL="Not a Raspberry Pi"
  fi
}

# Function to detect hardware details
detect_hardware() {
  # Get CPU info
  if [ -f /proc/cpuinfo ]; then
    CPU_CORES=$(grep -c "^processor" /proc/cpuinfo)
    CPU_MODEL=$(grep "^model name" /proc/cpuinfo | head -n1 | cut -d':' -f2 | sed 's/^[ \t]*//')
    
    # If no model name is found (common on ARM), try another field
    if [ -z "$CPU_MODEL" ]; then
      CPU_MODEL=$(grep "^Hardware" /proc/cpuinfo | head -n1 | cut -d':' -f2 | sed 's/^[ \t]*//')
    fi
  else
    CPU_CORES="Unknown"
    CPU_MODEL="Unknown"
  fi
  
  # Get memory info
  if [ -f /proc/meminfo ]; then
    MEM_TOTAL_KB=$(grep "^MemTotal:" /proc/meminfo | awk '{print $2}')
    MEM_TOTAL_MB=$((MEM_TOTAL_KB / 1024))
    MEM_TOTAL_GB=$(bc <<< "scale=1; $MEM_TOTAL_MB / 1024")
  else
    MEM_TOTAL_GB="Unknown"
  fi
  
  # Get disk info
  ROOT_DISK_SIZE_GB=$(df -h / | awk 'NR==2 {print $2}' | sed 's/G//')
  ROOT_DISK_AVAIL_GB=$(df -h / | awk 'NR==2 {print $4}' | sed 's/G//')
}

# Function to detect Docker
detect_docker() {
  if command -v docker &> /dev/null; then
    DOCKER_INSTALLED=true
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
  else
    DOCKER_INSTALLED=false
    DOCKER_VERSION="Not installed"
  fi
  
  if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_INSTALLED=true
    DOCKER_COMPOSE_VERSION=$(docker-compose --version | awk '{print $3}' | sed 's/,//')
  elif command -v docker && docker compose version &> /dev/null; then
    DOCKER_COMPOSE_INSTALLED=true
    DOCKER_COMPOSE_VERSION="Plugin version"
  else
    DOCKER_COMPOSE_INSTALLED=false
    DOCKER_COMPOSE_VERSION="Not installed"
  fi
}

# Function to check hardware transcoding capabilities
check_transcoding() {
  # Initialize variables
  VAAPI_AVAILABLE=false
  NVDEC_AVAILABLE=false
  V4L2_AVAILABLE=false
  
  # Check for VAAPI (Intel and some AMD GPUs)
  if [ -d /dev/dri ]; then
    VAAPI_AVAILABLE=true
  fi
  
  # Check for NVIDIA
  if [ -c /dev/nvidia0 ]; then
    NVDEC_AVAILABLE=true
  fi
  
  # Check for Raspberry Pi video acceleration
  if [ "$IS_RASPBERRY_PI" = true ] && [ -e /dev/video10 ]; then
    V4L2_AVAILABLE=true
  fi
  
  # Determine best transcoding method
  if [ "$V4L2_AVAILABLE" = true ]; then
    RECOMMENDED_TRANSCODING="v4l2"
  elif [ "$NVDEC_AVAILABLE" = true ]; then
    RECOMMENDED_TRANSCODING="nvdec"
  elif [ "$VAAPI_AVAILABLE" = true ]; then
    RECOMMENDED_TRANSCODING="vaapi"
  else
    RECOMMENDED_TRANSCODING="software"
  fi
}

# Run all detection functions
detect_architecture
detect_os
detect_hardware
detect_docker
check_transcoding

# Output results in JSON format
cat << EOF
{
  "architecture": "$(detect_architecture)",
  "os": {
    "name": "$OS_NAME",
    "version": "$OS_VERSION",
    "pretty_name": "$OS_PRETTY_NAME"
  },
  "raspberry_pi": {
    "is_raspberry_pi": $IS_RASPBERRY_PI,
    "model": "$PI_MODEL"
  },
  "hardware": {
    "cpu": {
      "model": "$CPU_MODEL",
      "cores": $CPU_CORES
    },
    "memory": {
      "total_gb": $MEM_TOTAL_GB
    },
    "disk": {
      "root_size_gb": $ROOT_DISK_SIZE_GB,
      "root_available_gb": $ROOT_DISK_AVAIL_GB
    }
  },
  "docker": {
    "installed": $DOCKER_INSTALLED,
    "version": "$DOCKER_VERSION",
    "compose_installed": $DOCKER_COMPOSE_INSTALLED,
    "compose_version": "$DOCKER_COMPOSE_VERSION"
  },
  "transcoding": {
    "vaapi_available": $VAAPI_AVAILABLE,
    "nvdec_available": $NVDEC_AVAILABLE,
    "v4l2_available": $V4L2_AVAILABLE,
    "recommended_method": "$RECOMMENDED_TRANSCODING"
  }
}
EOF