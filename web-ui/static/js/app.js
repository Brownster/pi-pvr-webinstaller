// PI-PVR Ultimate Media Stack - Web UI JavaScript

// Global variables
let config = {};
let services = {};
let systemInfo = {};
let containerStatus = {};
let installationLog = '';
let installationInterval = null;

// DOM elements
const themeToggle = document.getElementById('theme-toggle');
const navTabs = document.querySelectorAll('nav a');
const tabContents = document.querySelectorAll('.main .tab-content');
const installTabs = document.querySelectorAll('[data-install-tab]');
const installTabContents = document.querySelectorAll('#install .tab-content');

// Initialize the application
document.addEventListener('DOMContentLoaded', () => {
  initTheme();
  initTabs();
  initInstallTabs();
  initFormHandlers();
  loadSystemInfo();
  loadConfig();
  loadServices();
  loadStatus();
  
  // Refresh data every 10 seconds
  setInterval(() => {
    loadSystemInfo();
    loadStatus();
  }, 10000);
});

// Initialize theme
function initTheme() {
  const currentTheme = localStorage.getItem('theme') || 'light';
  if (currentTheme === 'dark') {
    document.body.classList.add('dark-mode');
    themeToggle.innerHTML = '<i class="fas fa-sun"></i>';
  }
  
  themeToggle.addEventListener('click', () => {
    document.body.classList.toggle('dark-mode');
    const isDark = document.body.classList.contains('dark-mode');
    localStorage.setItem('theme', isDark ? 'dark' : 'light');
    themeToggle.innerHTML = isDark ? '<i class="fas fa-sun"></i>' : '<i class="fas fa-moon"></i>';
  });
}

// Initialize main tabs
function initTabs() {
  navTabs.forEach(tab => {
    tab.addEventListener('click', (e) => {
      e.preventDefault();
      
      // Remove active class from all tabs and contents
      navTabs.forEach(t => t.classList.remove('active'));
      tabContents.forEach(c => c.classList.remove('active'));
      
      // Add active class to clicked tab and corresponding content
      tab.classList.add('active');
      const tabId = tab.getAttribute('data-tab');
      document.getElementById(tabId).classList.add('active');
    });
  });
}

// Initialize installation tabs
function initInstallTabs() {
  // Next buttons
  document.getElementById('next-arr-apps').addEventListener('click', () => {
    activateInstallTab('arr-apps');
  });
  document.getElementById('next-download-clients').addEventListener('click', () => {
    activateInstallTab('download-clients');
  });
  document.getElementById('next-media-servers').addEventListener('click', () => {
    activateInstallTab('media-servers');
  });
  document.getElementById('next-utilities').addEventListener('click', () => {
    activateInstallTab('utilities');
  });
  document.getElementById('next-summary').addEventListener('click', () => {
    activateInstallTab('summary');
    updateSummary();
  });
  
  // Previous buttons
  document.getElementById('prev-system-config').addEventListener('click', () => {
    activateInstallTab('system-config');
  });
  document.getElementById('prev-arr-apps').addEventListener('click', () => {
    activateInstallTab('arr-apps');
  });
  document.getElementById('prev-download-clients').addEventListener('click', () => {
    activateInstallTab('download-clients');
  });
  document.getElementById('prev-media-servers').addEventListener('click', () => {
    activateInstallTab('media-servers');
  });
  document.getElementById('prev-utilities').addEventListener('click', () => {
    activateInstallTab('utilities');
  });
  
  // Start installation button
  document.getElementById('start-installation').addEventListener('click', () => {
    startInstallation();
  });
  
  // Tab buttons
  installTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      const tabId = tab.getAttribute('data-install-tab');
      activateInstallTab(tabId);
      
      if (tabId === 'summary') {
        updateSummary();
      }
    });
  });
}

// Activate install tab
function activateInstallTab(tabId) {
  // Remove active class from all tabs and contents
  installTabs.forEach(t => t.classList.remove('active'));
  installTabContents.forEach(c => c.classList.remove('active'));
  
  // Add active class to clicked tab and corresponding content
  document.querySelector(`[data-install-tab="${tabId}"]`).classList.add('active');
  document.getElementById(tabId).classList.add('active');
}

// Initialize form handlers
function initFormHandlers() {
  // VPN toggle
  document.getElementById('vpn_enabled').addEventListener('change', (e) => {
    const vpnFields = document.getElementById('vpn-config-fields');
    vpnFields.style.display = e.target.checked ? 'block' : 'none';
  });
  
  // Tailscale toggle
  document.getElementById('tailscale_enabled').addEventListener('change', (e) => {
    const tailscaleFields = document.getElementById('tailscale-config-fields');
    tailscaleFields.style.display = e.target.checked ? 'block' : 'none';
  });
  
  // Service management buttons
  document.getElementById('restart-all').addEventListener('click', () => {
    restartAllServices();
  });
  
  document.getElementById('update-images').addEventListener('click', () => {
    updateImages();
  });
  
  document.getElementById('backup-config').addEventListener('click', () => {
    backupConfig();
  });
  
  // Settings buttons
  document.getElementById('save-settings').addEventListener('click', () => {
    saveSettings();
  });
  
  document.getElementById('reset-config').addEventListener('click', () => {
    if (confirm('Are you sure you want to reset your configuration? This cannot be undone.')) {
      resetConfig();
    }
  });
  
  document.getElementById('uninstall').addEventListener('click', () => {
    if (confirm('Are you sure you want to uninstall the stack? This will remove all containers and volumes.')) {
      uninstallStack();
    }
  });
}

// Load system information
function loadSystemInfo() {
  fetch('/api/system')
    .then(response => response.json())
    .then(data => {
      systemInfo = data;
      updateSystemInfo();
      updateResourceUsage();
    })
    .catch(error => {
      console.error('Error loading system information:', error);
    });
}

// Update system information display
function updateSystemInfo() {
  const systemInfoEl = document.getElementById('system-info');
  
  const formattedMemory = formatBytes(systemInfo.memory_total);
  const formattedDisk = formatBytes(systemInfo.disk_total);
  
  systemInfoEl.innerHTML = `
    <div class="grid">
      <div>
        <p><strong>Hostname:</strong> ${systemInfo.hostname}</p>
        <p><strong>Platform:</strong> ${systemInfo.platform} ${systemInfo.platform_version}</p>
        <p><strong>Architecture:</strong> ${systemInfo.architecture}</p>
      </div>
      <div>
        <p><strong>Memory:</strong> ${formattedMemory}</p>
        <p><strong>Disk:</strong> ${formattedDisk}</p>
        <p><strong>Docker:</strong> ${systemInfo.docker_installed ? 'Installed' : 'Not Installed'}</p>
        <p><strong>Tailscale:</strong> ${systemInfo.tailscale_installed ? 'Installed' : 'Not Installed'}</p>
      </div>
    </div>
  `;
}

// Update resource usage display
function updateResourceUsage() {
  const cpuUsageBar = document.getElementById('cpu-usage-bar');
  const memoryUsageBar = document.getElementById('memory-usage-bar');
  const diskUsageBar = document.getElementById('disk-usage-bar');
  
  // Calculate usage percentages
  const memoryUsage = systemInfo.memory_total > 0 
    ? ((systemInfo.memory_total - systemInfo.memory_available) / systemInfo.memory_total) * 100 
    : 0;
  
  const diskUsage = systemInfo.disk_total > 0 
    ? ((systemInfo.disk_total - systemInfo.disk_free) / systemInfo.disk_total) * 100 
    : 0;
  
  // Apply to progress bars
  cpuUsageBar.style.width = '0%'; // We don't have CPU usage data yet
  cpuUsageBar.innerHTML = '<span class="progress-text">N/A</span>';
  
  memoryUsageBar.style.width = `${memoryUsage}%`;
  memoryUsageBar.innerHTML = `<span class="progress-text">${memoryUsage.toFixed(1)}%</span>`;
  
  diskUsageBar.style.width = `${diskUsage}%`;
  diskUsageBar.innerHTML = `<span class="progress-text">${diskUsage.toFixed(1)}%</span>`;
}

// Load configuration
function loadConfig() {
  fetch('/api/config')
    .then(response => response.json())
    .then(data => {
      config = data;
      updateConfigForm();
    })
    .catch(error => {
      console.error('Error loading configuration:', error);
    });
}

// Update configuration form
function updateConfigForm() {
  // System config
  document.getElementById('puid').value = config.puid || 1000;
  document.getElementById('pgid').value = config.pgid || 1000;
  document.getElementById('timezone').value = config.timezone || 'Europe/London';
  document.getElementById('media_dir').value = config.media_dir || '/mnt/media';
  document.getElementById('downloads_dir').value = config.downloads_dir || '/mnt/downloads';
  document.getElementById('docker_dir').value = config.docker_dir || '/home/pi/docker';
  
  // VPN config
  document.getElementById('vpn_enabled').checked = config.vpn?.enabled !== false;
  document.getElementById('vpn-config-fields').style.display = config.vpn?.enabled !== false ? 'block' : 'none';
  
  if (config.vpn) {
    document.getElementById('vpn_provider').value = config.vpn.provider || 'private internet access';
    document.getElementById('vpn_username').value = config.vpn.username || '';
    document.getElementById('vpn_password').value = config.vpn.password || '';
    document.getElementById('vpn_region').value = config.vpn.region || 'Netherlands';
  }
  
  // Tailscale config
  document.getElementById('tailscale_enabled').checked = config.tailscale?.enabled === true;
  document.getElementById('tailscale-config-fields').style.display = config.tailscale?.enabled === true ? 'block' : 'none';
  
  if (config.tailscale) {
    document.getElementById('tailscale_auth_key').value = config.tailscale.auth_key || '';
  }
  
  // Settings
  document.getElementById('settings-puid').value = config.puid || 1000;
  document.getElementById('settings-pgid').value = config.pgid || 1000;
  document.getElementById('settings-timezone').value = config.timezone || 'Europe/London';
}

// Save configuration
function saveConfig() {
  // Gather config from form
  const newConfig = {
    puid: parseInt(document.getElementById('puid').value),
    pgid: parseInt(document.getElementById('pgid').value),
    timezone: document.getElementById('timezone').value,
    media_dir: document.getElementById('media_dir').value,
    downloads_dir: document.getElementById('downloads_dir').value,
    docker_dir: document.getElementById('docker_dir').value,
    vpn: {
      enabled: document.getElementById('vpn_enabled').checked,
      provider: document.getElementById('vpn_provider').value,
      username: document.getElementById('vpn_username').value,
      password: document.getElementById('vpn_password').value,
      region: document.getElementById('vpn_region').value
    },
    tailscale: {
      enabled: document.getElementById('tailscale_enabled').checked,
      auth_key: document.getElementById('tailscale_auth_key').value
    },
    installation_status: config.installation_status || 'not_started'
  };
  
  // Save config to API
  fetch('/api/config', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(newConfig)
  })
    .then(response => response.json())
    .then(data => {
      if (data.status === 'success') {
        config = newConfig;
      }
    })
    .catch(error => {
      console.error('Error saving configuration:', error);
    });
}

// Load services configuration
function loadServices() {
  fetch('/api/services')
    .then(response => response.json())
    .then(data => {
      services = data;
      updateServicesForm();
    })
    .catch(error => {
      console.error('Error loading services:', error);
    });
}

// Update services form
function updateServicesForm() {
  // Arr applications
  if (services.arr_apps) {
    document.getElementById('sonarr_enabled').checked = services.arr_apps.sonarr !== false;
    document.getElementById('radarr_enabled').checked = services.arr_apps.radarr !== false;
    document.getElementById('prowlarr_enabled').checked = services.arr_apps.prowlarr !== false;
    document.getElementById('lidarr_enabled').checked = services.arr_apps.lidarr === true;
    document.getElementById('readarr_enabled').checked = services.arr_apps.readarr === true;
    document.getElementById('bazarr_enabled').checked = services.arr_apps.bazarr === true;
  }
  
  // Download clients
  if (services.download_clients) {
    document.getElementById('transmission_enabled').checked = services.download_clients.transmission !== false;
    document.getElementById('qbittorrent_enabled').checked = services.download_clients.qbittorrent === true;
    document.getElementById('nzbget_enabled').checked = services.download_clients.nzbget !== false;
    document.getElementById('sabnzbd_enabled').checked = services.download_clients.sabnzbd === true;
    document.getElementById('jdownloader_enabled').checked = services.download_clients.jdownloader === true;
  }
  
  // Media servers
  if (services.media_servers) {
    document.getElementById('jellyfin_enabled').checked = services.media_servers.jellyfin !== false;
    document.getElementById('plex_enabled').checked = services.media_servers.plex === true;
    document.getElementById('emby_enabled').checked = services.media_servers.emby === true;
  }
  
  // Utilities
  if (services.utilities) {
    document.getElementById('heimdall_enabled').checked = services.utilities.heimdall === true;
    document.getElementById('overseerr_enabled').checked = services.utilities.overseerr === true;
    document.getElementById('tautulli_enabled').checked = services.utilities.tautulli === true;
    document.getElementById('portainer_enabled').checked = services.utilities.portainer !== false;
    document.getElementById('nginx_proxy_manager_enabled').checked = services.utilities.nginx_proxy_manager === true;
    document.getElementById('get_iplayer_enabled').checked = services.utilities.get_iplayer !== false;
  }
}

// Save services configuration
function saveServices() {
  // Gather services config from form
  const newServices = {
    arr_apps: {
      sonarr: document.getElementById('sonarr_enabled').checked,
      radarr: document.getElementById('radarr_enabled').checked,
      prowlarr: document.getElementById('prowlarr_enabled').checked,
      lidarr: document.getElementById('lidarr_enabled').checked,
      readarr: document.getElementById('readarr_enabled').checked,
      bazarr: document.getElementById('bazarr_enabled').checked
    },
    download_clients: {
      transmission: document.getElementById('transmission_enabled').checked,
      qbittorrent: document.getElementById('qbittorrent_enabled').checked,
      nzbget: document.getElementById('nzbget_enabled').checked,
      sabnzbd: document.getElementById('sabnzbd_enabled').checked,
      jdownloader: document.getElementById('jdownloader_enabled').checked
    },
    media_servers: {
      jellyfin: document.getElementById('jellyfin_enabled').checked,
      plex: document.getElementById('plex_enabled').checked,
      emby: document.getElementById('emby_enabled').checked
    },
    utilities: {
      heimdall: document.getElementById('heimdall_enabled').checked,
      overseerr: document.getElementById('overseerr_enabled').checked,
      tautulli: document.getElementById('tautulli_enabled').checked,
      portainer: document.getElementById('portainer_enabled').checked,
      nginx_proxy_manager: document.getElementById('nginx_proxy_manager_enabled').checked,
      get_iplayer: document.getElementById('get_iplayer_enabled').checked
    }
  };
  
  // Save services to API
  fetch('/api/services', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(newServices)
  })
    .then(response => response.json())
    .then(data => {
      if (data.status === 'success') {
        services = newServices;
      }
    })
    .catch(error => {
      console.error('Error saving services:', error);
    });
}

// Load status information
function loadStatus() {
  fetch('/api/status')
    .then(response => response.json())
    .then(data => {
      containerStatus = data.containers || {};
      updateContainerStatus();
    })
    .catch(error => {
      console.error('Error loading status:', error);
    });
}

// Update container status display
function updateContainerStatus() {
  const servicesGrid = document.getElementById('services-grid');
  const manageServicesGrid = document.getElementById('manage-services-grid');
  
  // Clear grids
  servicesGrid.innerHTML = '';
  manageServicesGrid.innerHTML = '';
  
  // Generate cards for each container
  Object.entries(containerStatus).forEach(([name, status]) => {
    // Dashboard card
    const card = document.createElement('div');
    card.className = 'card service-card';
    card.innerHTML = `
      <div class="service-card-header">
        <h3>${formatContainerName(name)}</h3>
        <span class="status status-${status.status}">${status.status}</span>
      </div>
      <div class="service-card-body">
        ${status.ports.length > 0 ? 
          `<p><a href="http://${window.location.hostname}:${status.ports[0].host}" target="_blank" class="service-url">
            http://${window.location.hostname}:${status.ports[0].host}
          </a></p>` : 
          '<p>No web interface</p>'
        }
      </div>
    `;
    servicesGrid.appendChild(card);
    
    // Management card
    const manageCard = document.createElement('div');
    manageCard.className = 'card service-card';
    manageCard.innerHTML = `
      <div class="service-card-header">
        <h3>${formatContainerName(name)}</h3>
        <span class="status status-${status.status}">${status.status}</span>
      </div>
      <div class="service-card-body">
        ${status.ports.length > 0 ? 
          `<p><a href="http://${window.location.hostname}:${status.ports[0].host}" target="_blank" class="service-url">
            http://${window.location.hostname}:${status.ports[0].host}
          </a></p>` : 
          '<p>No web interface</p>'
        }
      </div>
      <div class="service-card-footer">
        ${status.status === 'running' ? 
          `<button class="btn btn-secondary btn-stop" data-container="${name}">Stop</button>
          <button class="btn btn-primary btn-restart" data-container="${name}">Restart</button>` :
          `<button class="btn btn-primary btn-start" data-container="${name}">Start</button>`
        }
      </div>
    `;
    manageServicesGrid.appendChild(manageCard);
  });
  
  // Add event listeners to buttons
  document.querySelectorAll('.btn-restart').forEach(btn => {
    btn.addEventListener('click', () => {
      restartContainer(btn.getAttribute('data-container'));
    });
  });
  
  document.querySelectorAll('.btn-stop').forEach(btn => {
    btn.addEventListener('click', () => {
      stopContainer(btn.getAttribute('data-container'));
    });
  });
  
  document.querySelectorAll('.btn-start').forEach(btn => {
    btn.addEventListener('click', () => {
      startContainer(btn.getAttribute('data-container'));
    });
  });
}

// Update installation summary
function updateSummary() {
  // Save config and services
  saveConfig();
  saveServices();
  
  const summaryContent = document.getElementById('summary-content');
  
  // Create summary content
  let summary = `
    <h3>System Configuration</h3>
    <p><strong>User ID (PUID):</strong> ${config.puid}</p>
    <p><strong>Group ID (PGID):</strong> ${config.pgid}</p>
    <p><strong>Timezone:</strong> ${config.timezone}</p>
    <p><strong>Media Directory:</strong> ${config.media_dir}</p>
    <p><strong>Downloads Directory:</strong> ${config.downloads_dir}</p>
    
    <h3>VPN Configuration</h3>
    <p><strong>Enabled:</strong> ${config.vpn?.enabled ? 'Yes' : 'No'}</p>
    ${config.vpn?.enabled ? `
      <p><strong>Provider:</strong> ${config.vpn.provider}</p>
      <p><strong>Username:</strong> ${config.vpn.username ? '********' : 'Not set'}</p>
      <p><strong>Region:</strong> ${config.vpn.region}</p>
    ` : ''}
    
    <h3>Tailscale Configuration</h3>
    <p><strong>Enabled:</strong> ${config.tailscale?.enabled ? 'Yes' : 'No'}</p>
    ${config.tailscale?.enabled ? `
      <p><strong>Auth Key:</strong> ${config.tailscale.auth_key ? '********' : 'Not set'}</p>
    ` : ''}
    
    <h3>Selected Services</h3>
    <h4>Arr Applications</h4>
    <ul>
      ${services.arr_apps.sonarr ? '<li>Sonarr (TV Shows)</li>' : ''}
      ${services.arr_apps.radarr ? '<li>Radarr (Movies)</li>' : ''}
      ${services.arr_apps.prowlarr ? '<li>Prowlarr (Indexer Management)</li>' : ''}
      ${services.arr_apps.lidarr ? '<li>Lidarr (Music)</li>' : ''}
      ${services.arr_apps.readarr ? '<li>Readarr (Books)</li>' : ''}
      ${services.arr_apps.bazarr ? '<li>Bazarr (Subtitles)</li>' : ''}
    </ul>
    
    <h4>Download Clients</h4>
    <ul>
      ${services.download_clients.transmission ? '<li>Transmission</li>' : ''}
      ${services.download_clients.qbittorrent ? '<li>qBittorrent</li>' : ''}
      ${services.download_clients.nzbget ? '<li>NZBGet</li>' : ''}
      ${services.download_clients.sabnzbd ? '<li>SABnzbd</li>' : ''}
      ${services.download_clients.jdownloader ? '<li>JDownloader</li>' : ''}
    </ul>
    
    <h4>Media Servers</h4>
    <ul>
      ${services.media_servers.jellyfin ? '<li>Jellyfin</li>' : ''}
      ${services.media_servers.plex ? '<li>Plex Media Server</li>' : ''}
      ${services.media_servers.emby ? '<li>Emby</li>' : ''}
    </ul>
    
    <h4>Utilities</h4>
    <ul>
      ${services.utilities.heimdall ? '<li>Heimdall (Dashboard)</li>' : ''}
      ${services.utilities.overseerr ? '<li>Overseerr (Media Requests)</li>' : ''}
      ${services.utilities.tautulli ? '<li>Tautulli (Plex Monitoring)</li>' : ''}
      ${services.utilities.portainer ? '<li>Portainer (Docker Management)</li>' : ''}
      ${services.utilities.nginx_proxy_manager ? '<li>Nginx Proxy Manager</li>' : ''}
      ${services.utilities.get_iplayer ? '<li>Get iPlayer</li>' : ''}
    </ul>
  `;
  
  summaryContent.innerHTML = summary;
}

// Start installation process
function startInstallation() {
  // Show installation progress
  document.getElementById('installation-progress').style.display = 'block';
  document.getElementById('start-installation').disabled = true;
  
  // Start the installation
  fetch('/api/install', {
    method: 'POST'
  })
    .then(response => response.json())
    .then(data => {
      if (data.status === 'started') {
        // Start polling for installation progress
        pollInstallation();
      }
    })
    .catch(error => {
      console.error('Error starting installation:', error);
    });
}

// Poll installation progress
function pollInstallation() {
  if (installationInterval) {
    clearInterval(installationInterval);
  }
  
  installationInterval = setInterval(() => {
    // Check installation status
    fetch('/api/status')
      .then(response => response.json())
      .then(data => {
        const status = data.installation_status;
        
        // Get installation logs
        fetch('/api/logs')
          .then(response => response.json())
          .then(logData => {
            installationLog = logData.logs;
            updateInstallationProgress(status);
          });
        
        // If installation is complete, stop polling
        if (status === 'completed' || status === 'failed') {
          clearInterval(installationInterval);
          installationInterval = null;
          
          // Update UI
          if (status === 'completed') {
            alert('Installation completed successfully!');
            // Switch to dashboard tab
            document.querySelector('nav a[data-tab="dashboard"]').click();
            // Reload status
            loadStatus();
          } else {
            alert('Installation failed. Please check the logs.');
          }
          
          // Re-enable button
          document.getElementById('start-installation').disabled = false;
        }
      })
      .catch(error => {
        console.error('Error polling installation status:', error);
      });
  }, 5000);
}

// Update installation progress display
function updateInstallationProgress(status) {
  const progressBar = document.getElementById('installation-progress-bar');
  const logElement = document.getElementById('installation-log');
  
  // Update progress bar
  let progressPercent = 0;
  if (status === 'in_progress') {
    // Calculate progress based on log content
    const logLines = installationLog.split('\n').length;
    progressPercent = Math.min(Math.max(logLines * 5, 10), 90); // Between 10% and 90%
  } else if (status === 'completed') {
    progressPercent = 100;
  } else if (status === 'failed') {
    progressPercent = 100;
    progressBar.style.backgroundColor = 'var(--danger)';
  }
  
  progressBar.style.width = `${progressPercent}%`;
  progressBar.innerHTML = `<span class="progress-text">${progressPercent}%</span>`;
  
  // Update log
  logElement.textContent = installationLog;
  logElement.scrollTop = logElement.scrollHeight; // Auto-scroll to bottom
}

// Restart a container
function restartContainer(container) {
  fetch(`/api/restart/${container}`, {
    method: 'POST'
  })
    .then(response => response.json())
    .then(data => {
      if (data.status === 'success') {
        // Wait a bit and then reload status
        setTimeout(() => {
          loadStatus();
        }, 2000);
      }
    })
    .catch(error => {
      console.error('Error restarting container:', error);
    });
}

// Stop a container
function stopContainer(container) {
  fetch(`/api/stop/${container}`, {
    method: 'POST'
  })
    .then(response => response.json())
    .then(data => {
      if (data.status === 'success') {
        // Wait a bit and then reload status
        setTimeout(() => {
          loadStatus();
        }, 2000);
      }
    })
    .catch(error => {
      console.error('Error stopping container:', error);
    });
}

// Start a container
function startContainer(container) {
  fetch(`/api/start/${container}`, {
    method: 'POST'
  })
    .then(response => response.json())
    .then(data => {
      if (data.status === 'success') {
        // Wait a bit and then reload status
        setTimeout(() => {
          loadStatus();
        }, 2000);
      }
    })
    .catch(error => {
      console.error('Error starting container:', error);
    });
}

// Restart all services
function restartAllServices() {
  fetch('/api/restart', {
    method: 'POST'
  })
    .then(response => response.json())
    .then(data => {
      if (data.status === 'success') {
        // Wait a bit and then reload status
        setTimeout(() => {
          loadStatus();
        }, 5000);
      }
    })
    .catch(error => {
      console.error('Error restarting services:', error);
    });
}

// Update Docker images
function updateImages() {
  // TODO: Implement this
  alert('This feature is not yet implemented.');
}

// Backup configuration
function backupConfig() {
  // TODO: Implement this
  alert('This feature is not yet implemented.');
}

// Save settings
function saveSettings() {
  // Update config
  config.puid = parseInt(document.getElementById('settings-puid').value);
  config.pgid = parseInt(document.getElementById('settings-pgid').value);
  config.timezone = document.getElementById('settings-timezone').value;
  
  // Save config
  fetch('/api/config', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(config)
  })
    .then(response => response.json())
    .then(data => {
      if (data.status === 'success') {
        alert('Settings saved successfully.');
        // Update config form
        updateConfigForm();
      }
    })
    .catch(error => {
      console.error('Error saving settings:', error);
    });
}

// Reset configuration
function resetConfig() {
  // TODO: Implement this
  alert('This feature is not yet implemented.');
}

// Uninstall stack
function uninstallStack() {
  // TODO: Implement this
  alert('This feature is not yet implemented.');
}

// Format bytes to human-readable string
function formatBytes(bytes, decimals = 2) {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
  
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

// Format container name
function formatContainerName(name) {
  return name
    .replace(/-/g, ' ')
    .replace(/_/g, ' ')
    .split(' ')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}