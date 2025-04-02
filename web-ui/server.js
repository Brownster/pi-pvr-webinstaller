// PI-PVR Ultimate Media Stack - API Server
const express = require('express');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');
const { exec, spawn } = require('child_process');
const morgan = require('morgan');

// Create Express app
const app = express();
const port = process.env.PORT || 8080;

// Middleware
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(morgan('dev')); // Logging middleware

// Serve static files
app.use(express.static(path.join(__dirname, 'web-ui')));
app.use('/css', express.static(path.join(__dirname, 'web-ui/css')));
app.use('/js', express.static(path.join(__dirname, 'web-ui/js')));
app.use('/static', express.static(path.join(__dirname, 'web-ui/static')));

// Configuration paths
const CONFIG_DIR = path.join(process.env.HOME, '.pi-pvr-config');
const CONFIG_FILE = path.join(CONFIG_DIR, 'config.json');
const SERVICES_FILE = path.join(CONFIG_DIR, 'services.json');
const LOGS_DIR = path.join(CONFIG_DIR, 'logs');
const INSTALL_LOG = path.join(LOGS_DIR, 'install.log');

// Create necessary directories
if (!fs.existsSync(CONFIG_DIR)) {
  fs.mkdirSync(CONFIG_DIR, { recursive: true });
}

if (!fs.existsSync(LOGS_DIR)) {
  fs.mkdirSync(LOGS_DIR, { recursive: true });
}

// Load or create config
let config = {};
if (fs.existsSync(CONFIG_FILE)) {
  try {
    config = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
  } catch (error) {
    console.error('Error loading config:', error);
    // Create default config
    createDefaultConfig();
  }
} else {
  createDefaultConfig();
}

// Load or create services config
let services = {};
if (fs.existsSync(SERVICES_FILE)) {
  try {
    services = JSON.parse(fs.readFileSync(SERVICES_FILE, 'utf8'));
  } catch (error) {
    console.error('Error loading services config:', error);
    // Create default services config
    createDefaultServicesConfig();
  }
} else {
  createDefaultServicesConfig();
}

// Create default config
function createDefaultConfig() {
  config = {
    puid: 1000,
    pgid: 1000,
    timezone: 'Europe/London',
    media_dir: '/mnt/media',
    downloads_dir: '/mnt/downloads',
    docker_dir: path.join(process.env.HOME, 'docker'),
    vpn: {
      enabled: true,
      provider: 'private internet access',
      username: '',
      password: '',
      region: 'Netherlands'
    },
    tailscale: {
      enabled: false,
      auth_key: ''
    },
    installation_status: 'not_started'
  };
  saveConfig();
}

// Create default services config
function createDefaultServicesConfig() {
  services = {
    arr_apps: {
      sonarr: true,
      radarr: true,
      prowlarr: true,
      lidarr: false,
      readarr: false,
      bazarr: false
    },
    download_clients: {
      transmission: true,
      qbittorrent: false,
      nzbget: true,
      sabnzbd: false,
      jdownloader: false
    },
    media_servers: {
      jellyfin: true,
      plex: false,
      emby: false
    },
    utilities: {
      heimdall: false,
      overseerr: false,
      tautulli: false,
      portainer: true,
      nginx_proxy_manager: false,
      get_iplayer: true
    }
  };
  saveServicesConfig();
}

// Save config
function saveConfig() {
  fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));
}

// Save services config
function saveServicesConfig() {
  fs.writeFileSync(SERVICES_FILE, JSON.stringify(services, null, 2));
}

// API Routes

// Helper function to promisify exec
function execPromise(command) {
  return new Promise((resolve, reject) => {
    exec(command, (error, stdout, stderr) => {
      if (error) {
        reject(error);
        return;
      }
      resolve(stdout.trim());
    });
  });
}

/**
 * Get detailed platform information
 * @returns {Promise<Object>} Platform info including name, version, etc.
 */
function getPlatformInfo() {
  return new Promise((resolve, reject) => {
    // Try to read /etc/os-release first (most Linux distros)
    fs.readFile('/etc/os-release', 'utf8', (err, data) => {
      if (!err) {
        // Parse os-release file
        const osInfo = {};
        data.split('\n').forEach(line => {
          const parts = line.split('=');
          if (parts.length === 2) {
            const key = parts[0];
            // Remove quotes if present
            const value = parts[1].replace(/^"(.+)"$/, '$1');
            osInfo[key] = value;
          }
        });
        
        return resolve({
          name: osInfo.NAME || 'Linux',
          version: osInfo.VERSION_ID || 'unknown',
          pretty_name: osInfo.PRETTY_NAME || 'Linux',
          id: osInfo.ID || 'linux'
        });
      }
      
      // Fallback to uname
      exec('uname -a', (err, stdout) => {
        if (err) {
          return resolve({
            name: 'Unknown',
            version: 'Unknown',
            pretty_name: 'Unknown OS',
            id: 'unknown'
          });
        }
        
        const parts = stdout.split(' ');
        return resolve({
          name: parts[0] || 'Unknown',
          version: parts[2] || 'Unknown',
          pretty_name: `${parts[0]} ${parts[2]}` || 'Unknown OS',
          id: parts[0].toLowerCase() || 'unknown'
        });
      });
    });
  });
}

// Get memory info
function getMemoryInfo() {
  return new Promise((resolve, reject) => {
    exec('free -b', (error, stdout) => {
      if (error) {
        return resolve({ total: 0, available: 0 });
      }
      
      try {
        const lines = stdout.split('\n');
        const memLine = lines[1].split(/\s+/);
        resolve({
          total: parseInt(memLine[1], 10) || 0,
          available: parseInt(memLine[6], 10) || 0
        });
      } catch (err) {
        resolve({ total: 0, available: 0 });
      }
    });
  });
}

// Get disk info
function getDiskInfo() {
  return new Promise((resolve, reject) => {
    exec('df -B1 /', (error, stdout) => {
      if (error) {
        return resolve({ total: 0, free: 0 });
      }
      
      try {
        const lines = stdout.split('\n');
        const diskLine = lines[1].split(/\s+/);
        resolve({
          total: parseInt(diskLine[1], 10) || 0,
          free: parseInt(diskLine[3], 10) || 0
        });
      } catch (err) {
        resolve({ total: 0, free: 0 });
      }
    });
  });
}

// Check Docker 
function checkDocker() {
  return new Promise((resolve, reject) => {
    exec('which docker', (error) => {
      if (error) {
        return resolve({ installed: false, version: null });
      }
      
      exec('docker --version', (err, stdout) => {
        let version = null;
        if (!err) {
          const match = stdout.match(/Docker version ([0-9.]+)/);
          if (match) {
            version = match[1];
          }
        }
        
        resolve({ installed: true, version });
      });
    });
  });
}

// Check Tailscale
function checkTailscale() {
  return new Promise((resolve, reject) => {
    exec('which tailscale', (error) => {
      if (error) {
        return resolve({ installed: false, ip: null });
      }
      
      exec('tailscale ip', (err, stdout) => {
        resolve({
          installed: true,
          ip: err ? null : stdout.trim()
        });
      });
    });
  });
}

// Get system information
app.get('/api/system', async (req, res) => {
  try {
    // Run commands in parallel using Promise.all
    const [hostnameResult, platformInfo, memoryInfo, diskInfo, dockerInfo, tailscaleInfo] = 
      await Promise.all([
        execPromise('hostname'),
        getPlatformInfo(),
        getMemoryInfo(),
        getDiskInfo(),
        checkDocker(),
        checkTailscale()
      ]);
    
    // Get CPU usage - this is somewhat complex so we do it separately
    let cpu_usage = 0;
    try {
      const cpuInfo = await execPromise("top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'");
      cpu_usage = parseFloat(cpuInfo);
    } catch (error) {
      console.error('Error getting CPU usage:', error);
    }
    
    res.json({
      hostname: hostnameResult,
      os: {
        name: platformInfo.name,
        version: platformInfo.version,
        pretty_name: platformInfo.pretty_name,
        id: platformInfo.id
      },
      architecture: process.arch,
      memory_total: memoryInfo.total,
      memory_available: memoryInfo.available,
      disk_total: diskInfo.total,
      disk_free: diskInfo.free,
      cpu_usage: cpu_usage,
      docker_installed: dockerInfo.installed,
      docker_version: dockerInfo.version,
      tailscale_installed: tailscaleInfo.installed,
      tailscale_ip: tailscaleInfo.ip,
      ip_address: await getIpAddress(),
      installation_status: config.installation_status
    });
  } catch (error) {
    console.error('Error getting system info:', error);
    res.status(500).json({ 
      error: 'Failed to get system information',
      details: error.message
    });
  }
});

// Get IP address
async function getIpAddress() {
  try {
    const output = await execPromise("hostname -I | awk '{print $1}'");
    return output || '127.0.0.1';
  } catch (error) {
    console.error('Error getting IP address:', error);
    return '127.0.0.1';
  }
}

// Get configuration
app.get('/api/config', (req, res) => {
  res.json(config);
});

// Update configuration
app.post('/api/config', (req, res) => {
  config = { ...config, ...req.body };
  saveConfig();
  res.json({ status: 'success' });
});

// Get services
app.get('/api/services', (req, res) => {
  res.json(services);
});

// Update services
app.post('/api/services', (req, res) => {
  services = { ...services, ...req.body };
  saveServicesConfig();
  res.json({ status: 'success' });
});

// Get status of containers
app.get('/api/status', (req, res) => {
  exec('docker ps -a --format "{{.Names}}|{{.Status}}|{{.Ports}}"', (err, stdout) => {
    const containers = {};
    
    if (!err) {
      stdout.split('\n').filter(Boolean).forEach(line => {
        const [name, status, ports] = line.split('|');
        const isRunning = status.includes('Up');
        
        // Parse ports
        const portsList = [];
        if (ports) {
          const portRegex = /(\d+)->(\d+)/g;
          let match;
          while ((match = portRegex.exec(ports)) !== null) {
            portsList.push({
              host: match[1],
              container: match[2]
            });
          }
        }
        
        containers[name] = {
          status: isRunning ? 'running' : 'stopped',
          ports: portsList
        };
      });
    }
    
    res.json({
      containers,
      installation_status: config.installation_status
    });
  });
});

// Get all services with status
app.get('/api/services', (req, res) => {
  exec('docker ps -a --format "{{.Names}}|{{.Status}}|{{.Ports}}"', (err, stdout) => {
    if (err) {
      return res.status(500).json({ 
        error: 'Failed to get services status',
        details: err.message
      });
    }
    
    // Parse docker ps output
    const servicesList = [];
    
    stdout.split('\n').filter(Boolean).forEach(line => {
      const [name, status, ports] = line.split('|');
      const isRunning = status.includes('Up');
      
      // Skip system containers like watchtower
      if (name === 'watchtower') {
        return;
      }
      
      // Determine service type
      let type = 'utility';
      if (['sonarr', 'radarr', 'prowlarr', 'lidarr', 'readarr', 'bazarr', 'jellyfin', 'plex', 'emby'].includes(name)) {
        type = 'media';
      } else if (['transmission', 'qbittorrent', 'nzbget', 'sabnzbd', 'jdownloader', 'get_iplayer'].includes(name)) {
        type = 'download';
      }
      
      // Parse main port for URL
      let port = null;
      let url = null;
      
      if (ports) {
        const portMatch = ports.match(/(\d+)->(\d+)/);
        if (portMatch) {
          port = portMatch[1];
          
          // Construct URL
          const ipAddress = config.ip_address || 'localhost';
          url = `http://${ipAddress}:${port}`;
        }
      }
      
      // Add service to list
      servicesList.push({
        name,
        type,
        status: isRunning ? 'running' : 'stopped',
        port,
        url
      });
    });
    
    // Add a description for each service
    const descriptions = {
      sonarr: 'TV show management',
      radarr: 'Movie management',
      prowlarr: 'Indexer management',
      lidarr: 'Music management',
      readarr: 'Book management',
      bazarr: 'Subtitle management',
      jellyfin: 'Media server (open source)',
      plex: 'Media server',
      emby: 'Media server',
      transmission: 'Torrent client',
      qbittorrent: 'Torrent client',
      nzbget: 'Usenet client',
      sabnzbd: 'Usenet client',
      jdownloader: 'Direct download client',
      get_iplayer: 'BBC content downloader',
      portainer: 'Docker management',
      heimdall: 'Application dashboard',
      overseerr: 'Media requests',
      tautulli: 'Plex monitoring',
      vpn: 'VPN connection'
    };
    
    servicesList.forEach(service => {
      service.description = descriptions[service.name] || `${service.type} service`;
    });
    
    res.json({
      services: servicesList
    });
  });
});

// Get available drives
app.get('/api/drives', (req, res) => {
  exec('lsblk -o NAME,SIZE,TYPE,FSTYPE -J', (err, stdout) => {
    if (err) {
      return res.status(500).json({ error: 'Failed to get drives' });
    }
    
    try {
      const data = JSON.parse(stdout);
      const drives = [];
      
      data.blockdevices.forEach(device => {
        if (device.type === 'disk' && device.children) {
          device.children.forEach(partition => {
            if (partition.type === 'part' && partition.fstype) {
              drives.push({
                device: `/dev/${partition.name}`,
                size: partition.size,
                type: partition.fstype
              });
            }
          });
        }
      });
      
      res.json({ drives });
    } catch (error) {
      console.error('Error parsing drives data:', error);
      res.status(500).json({ error: 'Failed to parse drives data' });
    }
  });
});

// Start installation
app.post('/api/install', (req, res) => {
  // Update installation status
  config.installation_status = 'in_progress';
  saveConfig();
  
  // Clear previous installation log
  fs.writeFileSync(INSTALL_LOG, '', { flag: 'w' });
  
  // Start installation process in background
  const installProcess = spawn('./pi-pvr.sh', [], {
    detached: true,
    stdio: ['ignore', fs.openSync(INSTALL_LOG, 'a'), fs.openSync(INSTALL_LOG, 'a')]
  });
  
  // Don't wait for the process to complete
  installProcess.unref();
  
  res.json({ status: 'started' });
});

// Start image update process
app.post('/api/update/images', (req, res) => {
  // Set update status
  config.update_status = 'in_progress';
  saveConfig();
  
  // Create update log file
  const updateLogFile = path.join(LOGS_DIR, 'update.log');
  fs.writeFileSync(updateLogFile, 'Starting Docker image updates...\n', { flag: 'w' });
  
  // Start the update process in the background
  const updateProcess = spawn('docker-compose', ['-f', path.join(config.docker_dir, 'docker-compose.yml'), 'pull'], {
    detached: true,
    stdio: ['ignore', fs.openSync(updateLogFile, 'a'), fs.openSync(updateLogFile, 'a')]
  });
  
  // Handle process completion
  updateProcess.on('exit', (code) => {
    if (code === 0) {
      // Success
      config.update_status = 'completed';
      fs.appendFileSync(updateLogFile, '\nImage updates completed successfully.\n');
    } else {
      // Failure
      config.update_status = 'failed';
      fs.appendFileSync(updateLogFile, `\nImage updates failed with code ${code}.\n`);
    }
    saveConfig();
  });
  
  // Don't wait for process to complete
  updateProcess.unref();
  
  res.json({ status: 'success', message: 'Image update process started' });
});

// Get update status
app.get('/api/update/status', (req, res) => {
  const updateLogFile = path.join(LOGS_DIR, 'update.log');
  let logs = '';
  
  if (fs.existsSync(updateLogFile)) {
    logs = fs.readFileSync(updateLogFile, 'utf8');
  }
  
  res.json({
    status: config.update_status || 'not_started',
    logs
  });
});

// Get installation logs
app.get('/api/logs', (req, res) => {
  try {
    let logs = '';
    if (fs.existsSync(INSTALL_LOG)) {
      logs = fs.readFileSync(INSTALL_LOG, 'utf8');
    }
    res.json({ logs });
  } catch (error) {
    console.error('Error reading logs:', error);
    res.status(500).json({ error: 'Failed to read logs' });
  }
});

// Get system logs
app.get('/api/logs/system', (req, res) => {
  const lines = req.query.lines || 100;
  const source = req.query.source || 'system';
  const level = req.query.level || 'all';
  
  let command = '';
  
  switch (source) {
    case 'system':
      command = `journalctl -n ${lines}`;
      break;
    case 'installer':
      command = `cat ${INSTALL_LOG} | tail -n ${lines}`;
      break;
    case 'vpn':
      command = `docker logs --tail ${lines} vpn 2>&1`;
      break;
    case 'docker':
      command = `docker logs --tail ${lines} 2>&1`;
      break;
    default:
      command = `journalctl -n ${lines}`;
  }
  
  // Add filtering by log level if needed
  if (level !== 'all') {
    if (source === 'system' || source === 'installer') {
      switch (level) {
        case 'error':
          command += ' | grep -i "\\(error\\|critical\\|emergency\\|alert\\)"';
          break;
        case 'warning':
          command += ' | grep -i "\\(warning\\|error\\|critical\\|emergency\\|alert\\)"';
          break;
        case 'info':
          command += ' | grep -i "\\(info\\|notice\\|warning\\|error\\|critical\\|emergency\\|alert\\)"';
          break;
      }
    }
  }
  
  exec(command, (err, stdout) => {
    if (err) {
      return res.status(500).json({ 
        error: 'Failed to get logs',
        details: err.message
      });
    }
    
    res.json({ 
      content: stdout,
      source,
      level,
      lines
    });
  });
});

// Get service logs
app.get('/api/logs/:service', (req, res) => {
  const service = req.params.service;
  const lines = req.query.lines || 100;
  
  exec(`docker logs --tail ${lines} ${service} 2>&1`, (err, stdout) => {
    if (err) {
      return res.status(500).json({ 
        error: 'Failed to get service logs',
        details: err.message
      });
    }
    
    res.json({ 
      content: stdout,
      service,
      lines
    });
  });
});

// Restart container
app.post('/api/restart/:container', (req, res) => {
  const container = req.params.container;
  exec(`docker restart ${container}`, (err) => {
    if (err) {
      return res.status(500).json({ error: 'Failed to restart container' });
    }
    res.json({ status: 'success' });
  });
});

// Stop container
app.post('/api/stop/:container', (req, res) => {
  const container = req.params.container;
  exec(`docker stop ${container}`, (err) => {
    if (err) {
      return res.status(500).json({ error: 'Failed to stop container' });
    }
    res.json({ status: 'success' });
  });
});

// Start container
app.post('/api/start/:container', (req, res) => {
  const container = req.params.container;
  exec(`docker start ${container}`, (err) => {
    if (err) {
      return res.status(500).json({ error: 'Failed to start container' });
    }
    res.json({ status: 'success' });
  });
});

// Restart all containers
app.post('/api/restart', (req, res) => {
  exec('docker-compose -f ~/docker/docker-compose.yml restart', (err) => {
    if (err) {
      return res.status(500).json({ error: 'Failed to restart all containers' });
    }
    res.json({ status: 'success' });
  });
});

// Serve main page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'web-ui/index.html'));
});

// Serve install page
app.get('/install', (req, res) => {
  res.sendFile(path.join(__dirname, 'web-ui/install.html'));
});

// Start the server
app.listen(port, () => {
  console.log(`PI-PVR Web UI running on http://localhost:${port}`);
});