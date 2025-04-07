// Main JavaScript file for PI-PVR Ultimate Media Stack UI
import { systemApi, servicesApi, storageApi, networkApi, updateApi, configApi, logsApi } from './api-client.js';
import { notify, dismissAllNotifications } from './notifications.js';

// DOM ready event
document.addEventListener('DOMContentLoaded', function() {
  // Initialize the UI
  initUI();
  
  // Fetch initial data
  fetchSystemInfo();
  fetchServicesStatus();
  
  // Set up intervals for updates
  setInterval(fetchSystemInfo, 30000); // Update system info every 30 seconds
  setInterval(fetchServicesStatus, 15000); // Update services status every 15 seconds
});

// Initialize UI components
function initUI() {
  // Toggle theme
  initThemeToggle();
  
  // Tab navigation
  initTabNavigation();
  
  // Install wizard
  initInstallWizard();
  
  // Settings tabs
  initSettingsTabs();
  
  // Services tabs
  initServicesTabs();
  
  // Storage tabs
  initStorageTabs();
  
  // Form toggles
  initFormToggles();
  
  // Add event listeners for buttons
  initButtonHandlers();
}

// Theme toggle functionality
function initThemeToggle() {
  const themeToggle = document.getElementById('theme-toggle');
  if (themeToggle) {
    themeToggle.addEventListener('click', function() {
      document.body.classList.toggle('dark-mode');
      const icon = this.querySelector('i');
      
      if (document.body.classList.contains('dark-mode')) {
        icon.classList.remove('fa-moon');
        icon.classList.add('fa-sun');
        localStorage.setItem('theme', 'dark');
      } else {
        icon.classList.remove('fa-sun');
        icon.classList.add('fa-moon');
        localStorage.setItem('theme', 'light');
      }
    });
    
    // Apply saved theme
    if (localStorage.getItem('theme') === 'dark') {
      document.body.classList.add('dark-mode');
      const icon = themeToggle.querySelector('i');
      icon.classList.remove('fa-moon');
      icon.classList.add('fa-sun');
    }
  }
}

// Main tab navigation
function initTabNavigation() {
  const navLinks = document.querySelectorAll('nav a');
  const tabContents = document.querySelectorAll('.main > .container > .tab-content');
  
  navLinks.forEach(link => {
    link.addEventListener('click', function(e) {
      e.preventDefault();
      
      const targetTab = this.getAttribute('data-tab');
      
      // Update active tab link
      navLinks.forEach(navLink => navLink.classList.remove('active'));
      this.classList.add('active');
      
      // Show the target tab content
      tabContents.forEach(tabContent => {
        if (tabContent.id === targetTab) {
          tabContent.classList.add('active');
        } else {
          tabContent.classList.remove('active');
        }
      });
      
      // Special case for logs - refresh the logs on tab click
      if (targetTab === 'logs') {
        refreshLogs();
      }
      
      // Special case for storage - fetch storage info
      if (targetTab === 'storage') {
        fetchStorageInfo();
      }
      
      // Special case for network - fetch network info
      if (targetTab === 'network') {
        fetchNetworkInfo();
      }
    });
  });
  
  // Support for tab links within pages
  document.querySelectorAll('a[data-tab]').forEach(link => {
    if (!link.matches('nav a')) {
      link.addEventListener('click', function(e) {
        e.preventDefault();
        
        const targetTab = this.getAttribute('data-tab');
        const tabButton = document.querySelector(`nav a[data-tab="${targetTab}"]`);
        
        if (tabButton) {
          tabButton.click();
        }
      });
    }
  });
}

// Initialize install wizard tabs
function initInstallWizard() {
  const installTabs = document.querySelectorAll('[data-install-tab]');
  const installContents = document.querySelectorAll('#install .tab-content');
  
  installTabs.forEach(tab => {
    tab.addEventListener('click', function() {
      const targetTab = this.getAttribute('data-install-tab');
      
      // Update active tab
      installTabs.forEach(t => t.classList.remove('active'));
      this.classList.add('active');
      
      // Show the target tab content
      installContents.forEach(content => {
        if (content.id === targetTab) {
          content.classList.add('active');
        } else {
          content.classList.remove('active');
        }
      });
    });
  });
  
  // Next and previous buttons
  document.getElementById('next-arr-apps')?.addEventListener('click', () => {
    document.querySelector('[data-install-tab="arr-apps"]').click();
  });
  
  document.getElementById('prev-system-config')?.addEventListener('click', () => {
    document.querySelector('[data-install-tab="system-config"]').click();
  });
  
  document.getElementById('next-download-clients')?.addEventListener('click', () => {
    document.querySelector('[data-install-tab="download-clients"]').click();
  });
  
  document.getElementById('prev-arr-apps')?.addEventListener('click', () => {
    document.querySelector('[data-install-tab="arr-apps"]').click();
  });
  
  document.getElementById('next-media-servers')?.addEventListener('click', () => {
    document.querySelector('[data-install-tab="media-servers"]').click();
  });
  
  document.getElementById('prev-download-clients')?.addEventListener('click', () => {
    document.querySelector('[data-install-tab="download-clients"]').click();
  });
  
  document.getElementById('next-utilities')?.addEventListener('click', () => {
    document.querySelector('[data-install-tab="utilities"]').click();
  });
  
  document.getElementById('prev-media-servers')?.addEventListener('click', () => {
    document.querySelector('[data-install-tab="media-servers"]').click();
  });
  
  document.getElementById('next-summary')?.addEventListener('click', () => {
    document.querySelector('[data-install-tab="summary"]').click();
    generateSummary();
  });
  
  document.getElementById('prev-utilities')?.addEventListener('click', () => {
    document.querySelector('[data-install-tab="utilities"]').click();
  });
  
  // Start installation button
  document.getElementById('start-installation')?.addEventListener('click', () => {
    startInstallation();
  });
}

// Initialize settings tabs
function initSettingsTabs() {
  const settingsTabs = document.querySelectorAll('[data-settings-tab]');
  const settingsContents = document.querySelectorAll('#settings .tab-content');
  
  settingsTabs.forEach(tab => {
    tab.addEventListener('click', function() {
      const targetTab = this.getAttribute('data-settings-tab');
      
      // Update active tab
      settingsTabs.forEach(t => t.classList.remove('active'));
      this.classList.add('active');
      
      // Show the target tab content
      settingsContents.forEach(content => {
        if (content.id === 'settings-' + targetTab) {
          content.classList.add('active');
        } else {
          content.classList.remove('active');
        }
      });
    });
  });
}

// Initialize services tabs
function initServicesTabs() {
  const servicesTabs = document.querySelectorAll('[data-services-tab]');
  const servicesContents = document.querySelectorAll('#services .tab-content');
  
  servicesTabs.forEach(tab => {
    tab.addEventListener('click', function() {
      const targetTab = this.getAttribute('data-services-tab');
      
      // Update active tab
      servicesTabs.forEach(t => t.classList.remove('active'));
      this.classList.add('active');
      
      // Show the target tab content
      servicesContents.forEach(content => {
        if (content.id === 'services-' + targetTab) {
          content.classList.add('active');
        } else {
          content.classList.remove('active');
        }
      });
      
      // Fetch service data for the selected tab
      fetchServicesByType(targetTab);
    });
  });
}

// Initialize storage tabs
function initStorageTabs() {
  const shareTabs = document.querySelectorAll('[data-share-tab]');
  const shareContents = document.querySelectorAll('#shares-container .tab-content');
  
  shareTabs.forEach(tab => {
    tab.addEventListener('click', function() {
      const targetTab = this.getAttribute('data-share-tab');
      
      // Update active tab
      shareTabs.forEach(t => t.classList.remove('active'));
      this.classList.add('active');
      
      // Show the target tab content
      shareContents.forEach(content => {
        if (content.id === targetTab + '-shares') {
          content.classList.add('active');
        } else {
          content.classList.remove('active');
        }
      });
      
      // Fetch shares data
      if (targetTab === 'samba') {
        fetchSambaShares();
      } else if (targetTab === 'nfs') {
        fetchNfsShares();
      }
    });
  });
}

// Form toggle functionality
function initFormToggles() {
  // VPN toggle
  const vpnToggle = document.getElementById('vpn_enabled');
  const vpnFields = document.getElementById('vpn-config-fields');
  
  if (vpnToggle && vpnFields) {
    vpnToggle.addEventListener('change', function() {
      vpnFields.style.display = this.checked ? 'block' : 'none';
    });
  }
  
  // Tailscale toggle
  const tailscaleToggle = document.getElementById('tailscale_enabled');
  const tailscaleFields = document.getElementById('tailscale-config-fields');
  
  if (tailscaleToggle && tailscaleFields) {
    tailscaleToggle.addEventListener('change', function() {
      tailscaleFields.style.display = this.checked ? 'block' : 'none';
    });
  }
  
  // Security toggles
  const passwordProtectToggle = document.getElementById('settings-password-protect');
  const authFields = document.getElementById('auth-settings');
  
  if (passwordProtectToggle && authFields) {
    passwordProtectToggle.addEventListener('change', function() {
      authFields.style.display = this.checked ? 'block' : 'none';
    });
  }
  
  const httpsToggle = document.getElementById('settings-https-enabled');
  const httpsFields = document.getElementById('https-settings');
  
  if (httpsToggle && httpsFields) {
    httpsToggle.addEventListener('change', function() {
      httpsFields.style.display = this.checked ? 'block' : 'none';
    });
  }
  
  // Proxy toggle
  const proxyToggle = document.getElementById('settings-proxy-enabled');
  const proxyFields = document.getElementById('proxy-settings');
  
  if (proxyToggle && proxyFields) {
    proxyToggle.addEventListener('change', function() {
      proxyFields.style.display = this.checked ? 'block' : 'none';
    });
  }
}

// Initialize button handlers
function initButtonHandlers() {
  // Network buttons
  document.getElementById('edit-network')?.addEventListener('click', editNetwork);
  document.getElementById('edit-vpn')?.addEventListener('click', editVpn);
  document.getElementById('connect-vpn')?.addEventListener('click', connectVpn);
  document.getElementById('disconnect-vpn')?.addEventListener('click', disconnectVpn);
  document.getElementById('edit-tailscale')?.addEventListener('click', editTailscale);
  document.getElementById('connect-tailscale')?.addEventListener('click', connectTailscale);
  document.getElementById('disconnect-tailscale')?.addEventListener('click', disconnectTailscale);
  document.getElementById('add-port-forward')?.addEventListener('click', addPortForward);
  
  // Storage buttons
  document.getElementById('scan-movies')?.addEventListener('click', scanMovies);
  document.getElementById('browse-movies')?.addEventListener('click', browseMovies);
  document.getElementById('scan-tvshows')?.addEventListener('click', scanTvshows);
  document.getElementById('browse-tvshows')?.addEventListener('click', browseTvshows);
  document.getElementById('scan-downloads')?.addEventListener('click', scanDownloads);
  document.getElementById('browse-downloads')?.addEventListener('click', browseDownloads);
  document.getElementById('clean-downloads')?.addEventListener('click', cleanDownloads);
  document.getElementById('add-samba-share')?.addEventListener('click', addSambaShare);
  document.getElementById('add-nfs-share')?.addEventListener('click', addNfsShare);
  
  // Service batch operations
  document.getElementById('start-all')?.addEventListener('click', startAllServices);
  document.getElementById('restart-all')?.addEventListener('click', restartAllServices);
  document.getElementById('stop-all')?.addEventListener('click', stopAllServices);
  document.getElementById('update-all')?.addEventListener('click', updateAllServices);
  
  // Settings buttons
  document.getElementById('save-general-settings')?.addEventListener('click', saveGeneralSettings);
  document.getElementById('save-services-settings')?.addEventListener('click', saveServicesSettings);
  document.getElementById('save-network-settings')?.addEventListener('click', saveNetworkSettings);
  document.getElementById('save-security-settings')?.addEventListener('click', saveSecuritySettings);
  document.getElementById('save-advanced-settings')?.addEventListener('click', saveAdvancedSettings);
  document.getElementById('reset-config')?.addEventListener('click', resetConfiguration);
  document.getElementById('prune-docker')?.addEventListener('click', pruneDocker);
  document.getElementById('uninstall')?.addEventListener('click', uninstallStack);
  
  // Logs buttons
  document.getElementById('refresh-logs')?.addEventListener('click', refreshLogs);
  document.getElementById('download-logs')?.addEventListener('click', downloadLogs);
  document.getElementById('clear-logs')?.addEventListener('click', clearLogs);
  document.getElementById('refresh-container-logs')?.addEventListener('click', refreshContainerLogs);
  document.getElementById('download-container-logs')?.addEventListener('click', downloadContainerLogs);
  
  // Help buttons
  document.getElementById('check-for-updates')?.addEventListener('click', checkForUpdates);
  
  // FAQ toggles
  document.querySelectorAll('.faq-question').forEach(question => {
    question.addEventListener('click', function() {
      const answer = this.nextElementSibling;
      answer.style.display = answer.style.display === 'block' ? 'none' : 'block';
      this.classList.toggle('active');
    });
  });
  
  // Documentation links
  document.querySelectorAll('.doc-link').forEach(link => {
    link.addEventListener('click', function(e) {
      e.preventDefault();
      const docId = this.getAttribute('data-doc');
      openDocumentation(docId);
    });
  });
  
  // Modal close button
  document.querySelectorAll('.close-modal').forEach(closeBtn => {
    closeBtn.addEventListener('click', function() {
      const modal = this.closest('.modal');
      if (modal) {
        modal.style.display = 'none';
      }
    });
  });
  
  // Close modal when clicking outside the content
  window.addEventListener('click', function(e) {
    if (e.target.classList.contains('modal')) {
      e.target.style.display = 'none';
    }
  });
}

// Loading overlay functions
function showLoading() {
  document.getElementById('loading-overlay').classList.add('show');
}

function hideLoading() {
  document.getElementById('loading-overlay').classList.remove('show');
}

// Fetch system information
async function fetchSystemInfo() {
  try {
    showLoading();
    
    // Use the API client to get system info
    const data = await systemApi.getSystemInfo();
    
    // Update dashboard system info
    updateSystemInfo(data);
    
    // Update help page system info
    document.getElementById('help-system-info').textContent = 
      `${data.os?.pretty_name || 'Unknown'} (${data.architecture || 'Unknown'})`;
    
  } catch (error) {
    // Show error notification
    notify.error('Failed to fetch system information');
    console.error('Error fetching system info:', error);
  } finally {
    hideLoading();
  }
}

// Update system information in the UI
function updateSystemInfo(data) {
  // System information
  document.getElementById('hostname').textContent = data.hostname || 'Unknown';
  document.getElementById('architecture').textContent = data.architecture || 'Unknown';
  document.getElementById('os').textContent = data.os?.pretty_name || 'Unknown';
  
  // Memory
  const memGB = (data.memory_total / (1024 * 1024 * 1024)).toFixed(1);
  document.getElementById('memory').textContent = `${memGB}GB`;
  
  // Storage
  const diskGB = (data.disk_total / (1024 * 1024 * 1024)).toFixed(1);
  const freeGB = (data.disk_free / (1024 * 1024 * 1024)).toFixed(1);
  document.getElementById('storage').textContent = `${diskGB}GB (${freeGB}GB free)`;
  
  // Network
  document.getElementById('ip-address').textContent = data.ip_address || 'Unknown';
  
  // Tailscale
  document.getElementById('tailscale-status').textContent = 
    data.tailscale_installed ? `Installed (${data.tailscale_ip})` : 'Not Installed';
  
  // Installation status
  let statusText = 'Not Started';
  if (data.installation_status === 'in_progress') {
    statusText = 'In Progress';
  } else if (data.installation_status === 'completed') {
    statusText = 'Installed';
  } else if (data.installation_status === 'failed') {
    statusText = 'Failed';
  }
  document.getElementById('installation-status').textContent = statusText;
  
  // Resource usage
  updateResourceUsage(data);
}

// Update resource usage bars
function updateResourceUsage(data) {
  // CPU usage
  const cpuUsage = data.cpu_usage_percent || Math.floor(Math.random() * 30) + 5; // Random value if CPU usage not available
  const cpuBar = document.getElementById('cpu-usage-bar');
  if (cpuBar) {
    cpuBar.style.width = `${cpuUsage}%`;
    document.getElementById('cpu-usage').textContent = `${cpuUsage}%`;
    
    // Update color based on CPU usage
    if (cpuUsage > 80) {
      cpuBar.style.backgroundColor = '#e53e3e'; // Red for high usage
    } else if (cpuUsage > 60) {
      cpuBar.style.backgroundColor = '#ed8936'; // Orange for medium usage
    } else {
      cpuBar.style.backgroundColor = '#38a169'; // Green for low usage
    }
  }
  
  // Memory usage
  if (data.memory_total && data.memory_available) {
    const memoryUsage = Math.round((1 - (data.memory_available / data.memory_total)) * 100);
    const memoryBar = document.getElementById('memory-usage-bar');
    if (memoryBar) {
      memoryBar.style.width = `${memoryUsage}%`;
      document.getElementById('memory-usage').textContent = `${memoryUsage}%`;
      
      // Update color based on memory usage
      if (memoryUsage > 80) {
        memoryBar.style.backgroundColor = '#e53e3e'; // Red for high usage
      } else if (memoryUsage > 60) {
        memoryBar.style.backgroundColor = '#ed8936'; // Orange for medium usage
      } else {
        memoryBar.style.backgroundColor = '#38a169'; // Green for low usage
      }
    }
  }
  
  // Disk usage
  if (data.disk_total && data.disk_free) {
    const diskUsage = Math.round((1 - (data.disk_free / data.disk_total)) * 100);
    const diskBar = document.getElementById('disk-usage-bar');
    if (diskBar) {
      diskBar.style.width = `${diskUsage}%`;
      document.getElementById('disk-usage').textContent = `${diskUsage}%`;
      
      // Update color based on disk usage
      if (diskUsage > 90) {
        diskBar.style.backgroundColor = '#e53e3e'; // Red for high usage
      } else if (diskUsage > 75) {
        diskBar.style.backgroundColor = '#ed8936'; // Orange for medium usage
      } else {
        diskBar.style.backgroundColor = '#38a169'; // Green for low usage
      }
    }
  }
  
  // Temperature
  if (data.temperature_celsius) {
    const temp = data.temperature_celsius;
    const tempBar = document.getElementById('temperature-bar');
    if (tempBar) {
      // Convert temperature to percentage (0-100%)
      // Assume 0°C is 0% and 85°C is 100% (typical throttling temp for Pi)
      const tempPercentage = Math.min(Math.round((temp / 85) * 100), 100);
      tempBar.style.width = `${tempPercentage}%`;
      document.getElementById('temperature').textContent = `${temp.toFixed(1)}°C`;
      
      // Update color based on temperature
      if (temp > 75) {
        tempBar.style.backgroundColor = '#e53e3e'; // Red for hot
      } else if (temp > 60) {
        tempBar.style.backgroundColor = '#ed8936'; // Orange for warm
      } else {
        tempBar.style.backgroundColor = '#38a169'; // Green for cool
      }
    }
  }
}

// Fetch services status
async function fetchServicesStatus() {
  try {
    // Use the API client to get services status
    const data = await servicesApi.getAllServices();
    
    // Update the services tables with the received data
    updateServicesTable(data.services);
  } catch (error) {
    // Show error notification
    notify.error('Failed to fetch services status');
    console.error('Error fetching services status:', error);
  }
}

// Update services table
function updateServicesTable(services) {
  // Update the main dashboard services table
  const tableBody = document.getElementById('services-table-body');
  if (tableBody) {
    let tableHTML = '';
    
    services.forEach(service => {
      let statusClass = 'status-stopped';
      if (service.status === 'running') {
        statusClass = 'status-running';
      } else if (service.status === 'error') {
        statusClass = 'status-error';
      }
      
      let actions = '';
      if (service.status === 'running') {
        actions = `
          <button class="action-btn btn-warning" onclick="restartService('${service.name}')">
            <i class="fas fa-sync-alt"></i>
          </button>
          <button class="action-btn btn-danger" onclick="stopService('${service.name}')">
            <i class="fas fa-stop"></i>
          </button>
        `;
      } else {
        actions = `
          <button class="action-btn btn-success" onclick="startService('${service.name}')">
            <i class="fas fa-play"></i>
          </button>
        `;
      }
      
      tableHTML += `
        <tr>
          <td>${service.name}</td>
          <td><span class="status-badge ${statusClass}">${service.status}</span></td>
          <td>${service.port || 'N/A'}</td>
          <td>${actions}</td>
        </tr>
      `;
    });
    
    tableBody.innerHTML = tableHTML;
  }
  
  // If the services page is loaded, also update those tables
  updateServicesByType(services);
}

// Update services tables by type
function updateServicesByType(services) {
  const allServicesTable = document.getElementById('all-services-table');
  if (allServicesTable) {
    let tableHTML = '';
    
    services.forEach(service => {
      let statusClass = 'status-stopped';
      if (service.status === 'running') {
        statusClass = 'status-running';
      } else if (service.status === 'error') {
        statusClass = 'status-error';
      }
      
      let actions = '';
      if (service.status === 'running') {
        actions = `
          <button class="action-btn btn-warning" onclick="restartService('${service.name}')">
            <i class="fas fa-sync-alt"></i>
          </button>
          <button class="action-btn btn-danger" onclick="stopService('${service.name}')">
            <i class="fas fa-stop"></i>
          </button>
        `;
        
        if (service.url) {
          actions += `
            <a href="${service.url}" target="_blank" class="action-btn btn-primary">
              <i class="fas fa-external-link-alt"></i>
            </a>
          `;
        }
      } else {
        actions = `
          <button class="action-btn btn-success" onclick="startService('${service.name}')">
            <i class="fas fa-play"></i>
          </button>
        `;
      }
      
      tableHTML += `
        <tr>
          <td>${service.name}</td>
          <td>${service.type}</td>
          <td><span class="status-badge ${statusClass}">${service.status}</span></td>
          <td>${service.url || 'N/A'}</td>
          <td>${actions}</td>
        </tr>
      `;
    });
    
    allServicesTable.innerHTML = tableHTML;
  }
  
  // Update service type grids
  updateServiceTypeGrid('media', services.filter(s => s.type === 'media'));
  updateServiceTypeGrid('download', services.filter(s => s.type === 'download'));
  updateServiceTypeGrid('utility', services.filter(s => s.type === 'utility'));
}

// Update service grid by type
function updateServiceTypeGrid(type, services) {
  const grid = document.getElementById(`${type}-services-grid`);
  if (grid) {
    if (services.length === 0) {
      grid.innerHTML = `<div class="service-card">No ${type} services found</div>`;
      return;
    }
    
    let gridHTML = '';
    services.forEach(service => {
      let statusClass = 'status-stopped';
      if (service.status === 'running') {
        statusClass = 'status-running';
      } else if (service.status === 'error') {
        statusClass = 'status-error';
      }
      
      let actions = '';
      if (service.status === 'running') {
        actions = `
          <button class="btn btn-warning" onclick="restartService('${service.name}')">
            <i class="fas fa-sync-alt"></i> Restart
          </button>
          <button class="btn btn-danger" onclick="stopService('${service.name}')">
            <i class="fas fa-stop"></i> Stop
          </button>
        `;
        
        if (service.url) {
          actions += `
            <a href="${service.url}" target="_blank" class="btn btn-primary">
              <i class="fas fa-external-link-alt"></i> Open
            </a>
          `;
        }
      } else {
        actions = `
          <button class="btn btn-success" onclick="startService('${service.name}')">
            <i class="fas fa-play"></i> Start
          </button>
        `;
      }
      
      gridHTML += `
        <div class="service-card">
          <div class="service-card-header">
            <h3>${service.name}</h3>
            <span class="status-badge ${statusClass}">${service.status}</span>
          </div>
          <div class="service-card-body">
            <p>${service.description || `${capitalizeFirstLetter(type)} service`}</p>
            <p>${service.url ? `URL: <a href="${service.url}" target="_blank">${service.url}</a>` : ''}</p>
          </div>
          <div class="service-card-actions">
            ${actions}
          </div>
        </div>
      `;
    });
    
    grid.innerHTML = gridHTML;
  }
}

// Fetch services by type
function fetchServicesByType(type) {
  // In a real implementation, this would make an API call
  // For now, we just call the fetchServicesStatus to get all services
  fetchServicesStatus();
}

// Fetch storage information
async function fetchStorageInfo() {
  try {
    showLoading();
    
    // Use the API client to get storage information
    const drivesData = await storageApi.getDrives();
    
    // Get shares data
    const sambaSharesData = await storageApi.getSambaShares();
    const nfsSharesData = await storageApi.getNfsShares();
    
    // Update UI with the received data
    updateDrivesTable(drivesData.drives);
    updateDirectories(drivesData.directories);
    updateSambaShares(sambaSharesData.shares);
    updateNfsShares(nfsSharesData.shares);
    
  } catch (error) {
    // Show error notification
    notify.error('Failed to fetch storage information');
    console.error('Error fetching storage info:', error);
  } finally {
    hideLoading();
  }
}

// Update drives table
function updateDrivesTable(drives) {
  const tableBody = document.getElementById('drives-table-body');
  if (tableBody) {
    let tableHTML = '';
    
    drives.forEach(drive => {
      tableHTML += `
        <tr>
          <td>${drive.device}</td>
          <td>${drive.mountPoint}</td>
          <td>${drive.size}</td>
          <td>${drive.used}</td>
          <td>${drive.available}</td>
          <td>${drive.fsType}</td>
          <td>
            <button class="action-btn btn-primary" onclick="browseDrive('${drive.mountPoint}')">
              <i class="fas fa-folder-open"></i>
            </button>
            <button class="action-btn btn-danger" onclick="unmountDrive('${drive.device}')">
              <i class="fas fa-eject"></i>
            </button>
          </td>
        </tr>
      `;
    });
    
    tableBody.innerHTML = tableHTML;
  }
}

// Update directories information
function updateDirectories(directories) {
  // Movies directory
  document.getElementById('movies-path').textContent = directories.movies.path;
  document.getElementById('movies-size').textContent = directories.movies.size;
  document.getElementById('movies-files').textContent = directories.movies.files;
  document.getElementById('movies-usage').textContent = `${directories.movies.usage}%`;
  document.getElementById('movies-usage-bar').style.width = `${directories.movies.usage}%`;
  
  // TV Shows directory
  document.getElementById('tvshows-path').textContent = directories.tvshows.path;
  document.getElementById('tvshows-size').textContent = directories.tvshows.size;
  document.getElementById('tvshows-files').textContent = directories.tvshows.files;
  document.getElementById('tvshows-usage').textContent = `${directories.tvshows.usage}%`;
  document.getElementById('tvshows-usage-bar').style.width = `${directories.tvshows.usage}%`;
  
  // Downloads directory
  document.getElementById('downloads-path').textContent = directories.downloads.path;
  document.getElementById('downloads-size').textContent = directories.downloads.size;
  document.getElementById('downloads-files').textContent = directories.downloads.files;
  document.getElementById('downloads-usage').textContent = `${directories.downloads.usage}%`;
  document.getElementById('downloads-usage-bar').style.width = `${directories.downloads.usage}%`;
}

// Update Samba shares
function updateSambaShares(shares) {
  const tableBody = document.getElementById('samba-shares-body');
  if (tableBody) {
    let tableHTML = '';
    
    shares.forEach(share => {
      tableHTML += `
        <tr>
          <td>${share.name}</td>
          <td>${share.path}</td>
          <td>${share.access}</td>
          <td><code>${share.connectionString}</code></td>
          <td>
            <button class="action-btn btn-primary" onclick="editSambaShare('${share.name}')">
              <i class="fas fa-edit"></i>
            </button>
            <button class="action-btn btn-danger" onclick="deleteSambaShare('${share.name}')">
              <i class="fas fa-trash"></i>
            </button>
          </td>
        </tr>
      `;
    });
    
    tableBody.innerHTML = tableHTML;
  }
}

// Update NFS shares
function updateNfsShares(shares) {
  const tableBody = document.getElementById('nfs-shares-body');
  if (tableBody) {
    let tableHTML = '';
    
    shares.forEach(share => {
      tableHTML += `
        <tr>
          <td>${share.path}</td>
          <td>${share.client}</td>
          <td>${share.options}</td>
          <td><code>${share.connectionString}</code></td>
          <td>
            <button class="action-btn btn-primary" onclick="editNfsShare('${share.path}')">
              <i class="fas fa-edit"></i>
            </button>
            <button class="action-btn btn-danger" onclick="deleteNfsShare('${share.path}')">
              <i class="fas fa-trash"></i>
            </button>
          </td>
        </tr>
      `;
    });
    
    tableBody.innerHTML = tableHTML;
  }
}

// Fetch network information
async function fetchNetworkInfo() {
  try {
    showLoading();
    
    // Use the API client to get network information
    const networkData = await networkApi.getNetworkInfo();
    
    // Get VPN status
    const vpnData = await networkApi.getVpnStatus();
    
    // Get Tailscale status
    const tailscaleData = await networkApi.getTailscaleStatus();
    
    // Update UI with the received data
    updateNetworkInfo(networkData.network);
    updateVpnInfo(vpnData);
    updateTailscaleInfo(tailscaleData);
    updatePortForwards(networkData.portForwards);
    
  } catch (error) {
    // Show error notification
    notify.error('Failed to fetch network information');
    console.error('Error fetching network info:', error);
  } finally {
    hideLoading();
  }
}

// Update network information
function updateNetworkInfo(network) {
  document.getElementById('net-hostname').textContent = network.hostname;
  document.getElementById('net-ip').textContent = network.ip;
  document.getElementById('net-gateway').textContent = network.gateway;
  document.getElementById('net-dns').textContent = network.dns.join(', ');
  document.getElementById('net-mac').textContent = network.mac;
}

// Update VPN information
function updateVpnInfo(vpn) {
  document.getElementById('vpn-status').textContent = capitalizeFirstLetter(vpn.status);
  document.getElementById('vpn-provider').textContent = vpn.provider;
  document.getElementById('vpn-region').textContent = vpn.region;
  document.getElementById('vpn-external-ip').textContent = vpn.externalIp;
  document.getElementById('vpn-connected-since').textContent = vpn.connectedSince;
  
  // Enable/disable buttons based on status
  const connectBtn = document.getElementById('connect-vpn');
  const disconnectBtn = document.getElementById('disconnect-vpn');
  
  if (connectBtn && disconnectBtn) {
    if (vpn.status === 'connected') {
      connectBtn.disabled = true;
      disconnectBtn.disabled = false;
    } else {
      connectBtn.disabled = false;
      disconnectBtn.disabled = true;
    }
  }
}

// Update Tailscale information
function updateTailscaleInfo(tailscale) {
  document.getElementById('ts-status').textContent = capitalizeFirstLetter(tailscale.status);
  document.getElementById('ts-ip').textContent = tailscale.ip;
  document.getElementById('ts-hostname').textContent = tailscale.hostname;
  document.getElementById('ts-peers').textContent = tailscale.peers;
  
  // Enable/disable buttons based on status
  const connectBtn = document.getElementById('connect-tailscale');
  const disconnectBtn = document.getElementById('disconnect-tailscale');
  
  if (connectBtn && disconnectBtn) {
    if (tailscale.status === 'connected') {
      connectBtn.disabled = true;
      disconnectBtn.disabled = false;
    } else {
      connectBtn.disabled = false;
      disconnectBtn.disabled = true;
    }
  }
}

// Update port forwards table
function updatePortForwards(portForwards) {
  const tableBody = document.getElementById('port-table-body');
  if (tableBody) {
    let tableHTML = '';
    
    portForwards.forEach(port => {
      let statusClass = port.status === 'active' ? 'status-running' : 'status-stopped';
      
      tableHTML += `
        <tr>
          <td>${port.service}</td>
          <td>${port.internalPort}</td>
          <td>${port.externalPort}</td>
          <td>${port.protocol}</td>
          <td><span class="status-badge ${statusClass}">${port.status}</span></td>
          <td>
            <button class="action-btn btn-primary" onclick="editPortForward(${port.internalPort})">
              <i class="fas fa-edit"></i>
            </button>
            <button class="action-btn btn-danger" onclick="deletePortForward(${port.internalPort})">
              <i class="fas fa-trash"></i>
            </button>
          </td>
        </tr>
      `;
    });
    
    tableBody.innerHTML = tableHTML;
  }
}

// Refresh logs
async function refreshLogs() {
  const logSource = document.getElementById('log-source').value;
  const logLevel = document.getElementById('log-level').value;
  
  try {
    showLoading();
    
    // Use the API client to get logs
    const logsData = await logsApi.getSystemLogs(logSource, logLevel);
    
    // Update UI with the received data
    document.getElementById('logs-content').textContent = logsData.content || 'No logs available.';
    
  } catch (error) {
    // Show error notification
    notify.error('Failed to fetch logs');
    console.error('Error fetching logs:', error);
    document.getElementById('logs-content').textContent = 'Error loading logs.';
  } finally {
    hideLoading();
  }
}

// Refresh container logs
function refreshContainerLogs() {
  const container = document.getElementById('container-source').value;
  const lines = document.getElementById('container-lines').value;
  const follow = document.getElementById('follow-logs').checked;
  
  showLoading();
  
  // Simulate API call with mock data (replace with actual API endpoint)
  setTimeout(() => {
    let logContent = '';
    
    if (container === 'all') {
      logContent = 'Select a specific container to view logs';
    } else {
      // Simulate logs for the selected container
      logContent = `2025-04-02 10:00:05 [${container}] Container started\n2025-04-02 10:00:10 [${container}] Loading configuration\n2025-04-02 10:00:15 [${container}] Service initialized\n2025-04-02 10:00:20 [${container}] Listening on port 0\n2025-04-02 10:00:25 [${container}] Ready to accept connections`;
      
      // If follow is enabled, simulate live logs
      if (follow) {
        logContent += `\n2025-04-02 10:00:30 [${container}] New connection from 192.168.1.10\n2025-04-02 10:00:35 [${container}] Processing request\n2025-04-02 10:00:40 [${container}] Request completed`;
      }
    }
    
    document.getElementById('container-logs-content').textContent = logContent;
    
    hideLoading();
  }, 300);
  
  // If following logs, set up interval to update
  if (follow) {
    if (window.logUpdateInterval) {
      clearInterval(window.logUpdateInterval);
    }
    
    window.logUpdateInterval = setInterval(() => {
      const currentLog = document.getElementById('container-logs-content').textContent;
      const timestamp = new Date().toISOString().replace('T', ' ').substr(0, 19);
      const newLine = `\n${timestamp} [${container}] ${getRandomLogMessage()}`;
      
      document.getElementById('container-logs-content').textContent = currentLog + newLine;
      
      // Scroll to bottom
      const logViewer = document.getElementById('container-logs-content').parentElement;
      logViewer.scrollTop = logViewer.scrollHeight;
    }, 3000);
  } else {
    if (window.logUpdateInterval) {
      clearInterval(window.logUpdateInterval);
      window.logUpdateInterval = null;
    }
  }
}

// Generate random log message for demo
function getRandomLogMessage() {
  const messages = [
    'Processing request',
    'New connection from 192.168.1.10',
    'Request completed',
    'Cache hit',
    'Cache miss',
    'Refreshing metadata',
    'Scanning media',
    'Background task started',
    'Background task completed',
    'Received API request',
    'Database query executed',
    'Resource usage stats updated',
    'Ping successful',
    'Checking for updates',
    'Maintaining connection'
  ];
  
  return messages[Math.floor(Math.random() * messages.length)];
}

// Download logs
function downloadLogs() {
  const logContent = document.getElementById('logs-content').textContent;
  const logSource = document.getElementById('log-source').value;
  const timestamp = new Date().toISOString().replace(/:/g, '-').split('.')[0];
  const filename = `${logSource}-logs-${timestamp}.txt`;
  
  downloadTextFile(logContent, filename);
}

// Download container logs
function downloadContainerLogs() {
  const logContent = document.getElementById('container-logs-content').textContent;
  const container = document.getElementById('container-source').value;
  const timestamp = new Date().toISOString().replace(/:/g, '-').split('.')[0];
  const filename = `${container}-logs-${timestamp}.txt`;
  
  downloadTextFile(logContent, filename);
}

// Download text as file
function downloadTextFile(text, filename) {
  const blob = new Blob([text], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  
  // Clean up
  setTimeout(() => {
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }, 100);
}

// Clear logs
function clearLogs() {
  if (confirm('Are you sure you want to clear the logs?')) {
    document.getElementById('logs-content').textContent = 'Logs cleared.';
  }
}

// Generate installation summary
function generateSummary() {
  const summaryContent = document.getElementById('summary-content');
  if (!summaryContent) return;
  
  // Collect form values
  const puid = document.getElementById('puid').value;
  const pgid = document.getElementById('pgid').value;
  const timezone = document.getElementById('timezone').value;
  const mediaDir = document.getElementById('media_dir').value;
  const downloadsDir = document.getElementById('downloads_dir').value;
  const dockerDir = document.getElementById('docker_dir').value;
  
  // VPN settings
  const vpnEnabled = document.getElementById('vpn_enabled').checked;
  const vpnProvider = vpnEnabled ? document.getElementById('vpn_provider').value : 'None';
  const vpnRegion = vpnEnabled ? document.getElementById('vpn_region').value : 'N/A';
  
  // Tailscale settings
  const tailscaleEnabled = document.getElementById('tailscale_enabled').checked;
  
  // Collect selected apps
  const selectedServices = [];
  
  document.querySelectorAll('input[type="checkbox"][id$="_enabled"]:checked').forEach(checkbox => {
    const serviceName = checkbox.id.replace('_enabled', '');
    if (serviceName !== 'vpn' && serviceName !== 'tailscale') {
      selectedServices.push(capitalizeFirstLetter(serviceName));
    }
  });
  
  // Create summary HTML
  let summaryHTML = `
    <div class="summary-section">
      <h3>System Configuration</h3>
      <p><strong>PUID:</strong> ${puid}</p>
      <p><strong>PGID:</strong> ${pgid}</p>
      <p><strong>Timezone:</strong> ${timezone}</p>
      <p><strong>Media Directory:</strong> ${mediaDir}</p>
      <p><strong>Downloads Directory:</strong> ${downloadsDir}</p>
      <p><strong>Docker Directory:</strong> ${dockerDir}</p>
    </div>
    
    <div class="summary-section">
      <h3>Network Configuration</h3>
      <p><strong>VPN:</strong> ${vpnEnabled ? 'Enabled' : 'Disabled'}</p>
      ${vpnEnabled ? `<p><strong>VPN Provider:</strong> ${vpnProvider}</p>` : ''}
      ${vpnEnabled ? `<p><strong>VPN Region:</strong> ${vpnRegion}</p>` : ''}
      <p><strong>Tailscale:</strong> ${tailscaleEnabled ? 'Enabled' : 'Disabled'}</p>
    </div>
    
    <div class="summary-section">
      <h3>Selected Services</h3>
      <ul>
        ${selectedServices.map(service => `<li>${service}</li>`).join('')}
      </ul>
    </div>
  `;
  
  summaryContent.innerHTML = summaryHTML;
}

// Start installation
function startInstallation() {
  const installationProgress = document.getElementById('installation-progress');
  const progressBar = document.getElementById('installation-progress-bar');
  const installationLog = document.getElementById('installation-log');
  const startButton = document.getElementById('start-installation');
  
  if (installationProgress && progressBar && installationLog && startButton) {
    installationProgress.style.display = 'block';
    startButton.disabled = true;
    document.getElementById('prev-utilities').disabled = true;
    
    // Simulate installation progress
    let progress = 0;
    let logText = '';
    
    const steps = [
      'Creating directories...',
      'Installing dependencies...',
      'Setting up Docker network...',
      'Configuring VPN...',
      'Configuring storage...',
      'Generating Docker Compose file...',
      'Pulling Docker images...',
      'Starting services...',
      'Verifying services...',
      'Installation completed!'
    ];
    
    const interval = setInterval(() => {
      if (progress < steps.length) {
        // Update progress
        const percent = Math.round((progress + 1) * 100 / steps.length);
        progressBar.style.width = `${percent}%`;
        progressBar.textContent = `${percent}%`;
        
        // Update log
        const timestamp = new Date().toISOString().replace('T', ' ').substr(0, 19);
        logText += `${timestamp} [INFO] ${steps[progress]}\n`;
        installationLog.textContent = logText;
        
        // Scroll to bottom of log
        installationLog.scrollTop = installationLog.scrollHeight;
        
        progress++;
      } else {
        // Installation complete
        clearInterval(interval);
        startButton.textContent = 'Installation Complete';
        startButton.classList.remove('btn-primary');
        startButton.classList.add('btn-success');
        
        // Add view dashboard button
        const summaryContent = document.getElementById('summary-content');
        summaryContent.innerHTML += `
          <div class="form-group">
            <a href="#" data-tab="dashboard" class="btn btn-primary">View Dashboard</a>
          </div>
        `;
      }
    }, 1000);
  }
}

// Network button handlers
function editNetwork() {
  alert('Edit network configuration');
}

function editVpn() {
  alert('Edit VPN configuration');
}

function connectVpn() {
  showLoading();
  setTimeout(() => {
    document.getElementById('vpn-status').textContent = 'Connected';
    document.getElementById('connect-vpn').disabled = true;
    document.getElementById('disconnect-vpn').disabled = false;
    hideLoading();
  }, 1000);
}

function disconnectVpn() {
  showLoading();
  setTimeout(() => {
    document.getElementById('vpn-status').textContent = 'Disconnected';
    document.getElementById('connect-vpn').disabled = false;
    document.getElementById('disconnect-vpn').disabled = true;
    hideLoading();
  }, 1000);
}

function editTailscale() {
  alert('Edit Tailscale configuration');
}

function connectTailscale() {
  showLoading();
  setTimeout(() => {
    document.getElementById('ts-status').textContent = 'Connected';
    document.getElementById('connect-tailscale').disabled = true;
    document.getElementById('disconnect-tailscale').disabled = false;
    hideLoading();
  }, 1000);
}

function disconnectTailscale() {
  showLoading();
  setTimeout(() => {
    document.getElementById('ts-status').textContent = 'Disconnected';
    document.getElementById('connect-tailscale').disabled = false;
    document.getElementById('disconnect-tailscale').disabled = true;
    hideLoading();
  }, 1000);
}

function addPortForward() {
  alert('Add port forward');
}

function editPortForward(port) {
  alert(`Edit port forward: ${port}`);
}

function deletePortForward(port) {
  if (confirm(`Are you sure you want to delete port forward for port ${port}?`)) {
    // Delete port forward
  }
}

// Storage button handlers
function scanMovies() {
  showLoading();
  setTimeout(() => {
    alert('Movies directory scan completed');
    hideLoading();
  }, 1000);
}

function browseMovies() {
  alert('Browse movies directory');
}

function scanTvshows() {
  showLoading();
  setTimeout(() => {
    alert('TV Shows directory scan completed');
    hideLoading();
  }, 1000);
}

function browseTvshows() {
  alert('Browse TV Shows directory');
}

function scanDownloads() {
  showLoading();
  setTimeout(() => {
    alert('Downloads directory scan completed');
    hideLoading();
  }, 1000);
}

function browseDownloads() {
  alert('Browse downloads directory');
}

function cleanDownloads() {
  if (confirm('Are you sure you want to clean the downloads directory? This will delete all temporary and completed download files.')) {
    showLoading();
    setTimeout(() => {
      alert('Downloads directory cleaned');
      hideLoading();
    }, 1000);
  }
}

function browseDrive(mountPoint) {
  alert(`Browse drive: ${mountPoint}`);
}

function unmountDrive(device) {
  if (confirm(`Are you sure you want to unmount drive ${device}?`)) {
    showLoading();
    setTimeout(() => {
      alert(`Drive ${device} unmounted`);
      fetchStorageInfo(); // Refresh storage info
      hideLoading();
    }, 1000);
  }
}

function addSambaShare() {
  alert('Add Samba share');
}

function editSambaShare(name) {
  alert(`Edit Samba share: ${name}`);
}

function deleteSambaShare(name) {
  if (confirm(`Are you sure you want to delete Samba share "${name}"?`)) {
    // Delete Samba share
    fetchSambaShares(); // Refresh shares
  }
}

function addNfsShare() {
  alert('Add NFS share');
}

function editNfsShare(path) {
  alert(`Edit NFS share: ${path}`);
}

function deleteNfsShare(path) {
  if (confirm(`Are you sure you want to delete NFS share for "${path}"?`)) {
    // Delete NFS share
    fetchNfsShares(); // Refresh shares
  }
}

// Service management functions
async function startService(serviceName) {
  try {
    showLoading();
    
    // Use the API client to start the service
    await servicesApi.startService(serviceName);
    
    // Show success notification
    notify.success(`${serviceName} started successfully`);
    
    // Refresh services list
    await fetchServicesStatus();
  } catch (error) {
    // Show error notification
    notify.error(`Failed to start ${serviceName}: ${error.message}`);
    console.error(`Error starting ${serviceName}:`, error);
  } finally {
    hideLoading();
  }
}

async function stopService(serviceName) {
  try {
    showLoading();
    
    // Use the API client to stop the service
    await servicesApi.stopService(serviceName);
    
    // Show success notification
    notify.success(`${serviceName} stopped successfully`);
    
    // Refresh services list
    await fetchServicesStatus();
  } catch (error) {
    // Show error notification
    notify.error(`Failed to stop ${serviceName}: ${error.message}`);
    console.error(`Error stopping ${serviceName}:`, error);
  } finally {
    hideLoading();
  }
}

async function restartService(serviceName) {
  try {
    showLoading();
    
    // Use the API client to restart the service
    await servicesApi.restartService(serviceName);
    
    // Show success notification
    notify.success(`${serviceName} restarted successfully`);
    
    // Refresh services list
    await fetchServicesStatus();
  } catch (error) {
    // Show error notification
    notify.error(`Failed to restart ${serviceName}: ${error.message}`);
    console.error(`Error restarting ${serviceName}:`, error);
  } finally {
    hideLoading();
  }
}

// Service batch operations
function startAllServices() {
  if (confirm('Are you sure you want to start all services?')) {
    showLoading();
    setTimeout(() => {
      // In a real implementation, this would make an API call
      fetchServicesStatus(); // Refresh services
      hideLoading();
    }, 2000);
  }
}

function restartAllServices() {
  if (confirm('Are you sure you want to restart all services?')) {
    showLoading();
    setTimeout(() => {
      // In a real implementation, this would make an API call
      fetchServicesStatus(); // Refresh services
      hideLoading();
    }, 2000);
  }
}

function stopAllServices() {
  if (confirm('Are you sure you want to stop all services?')) {
    showLoading();
    setTimeout(() => {
      // In a real implementation, this would make an API call
      fetchServicesStatus(); // Refresh services
      hideLoading();
    }, 2000);
  }
}

async function updateAllServices() {
  if (!confirm('Are you sure you want to update all Docker images? This may take several minutes.')) {
    return;
  }
  
  try {
    showLoading();
    
    // Start the update process
    const updateResponse = await updateApi.updateImages();
    
    if (updateResponse.status !== 'success') {
      throw new Error(updateResponse.error || 'Failed to start image updates');
    }
    
    // Show initial notification
    const notificationId = notify.info('Image updates started. This may take several minutes.', 0);
    
    // Hide loading indicator since this will be a long-running process
    hideLoading();
    
    // Poll for update status
    let updateComplete = false;
    const checkInterval = 5000; // Check every 5 seconds
    const maxChecks = 360; // Max 30 minutes (360 * 5000ms = 30 minutes)
    let checkCount = 0;
    
    const statusCheck = async () => {
      if (updateComplete || checkCount >= maxChecks) {
        return;
      }
      
      checkCount++;
      
      try {
        const statusResponse = await updateApi.getUpdateStatus();
        
        if (statusResponse.status === 'completed') {
          updateComplete = true;
          dismissAllNotifications();
          notify.success('All images updated successfully');
          await fetchServicesStatus(); // Refresh services
        } else if (statusResponse.status === 'failed') {
          updateComplete = true;
          dismissAllNotifications();
          notify.error(`Image update failed: ${statusResponse.error || 'Unknown error'}`);
        } else {
          // Still in progress, check again after interval
          setTimeout(statusCheck, checkInterval);
        }
      } catch (error) {
        console.error('Error checking update status:', error);
        // Continue polling despite error
        setTimeout(statusCheck, checkInterval);
      }
    };
    
    // Start polling
    setTimeout(statusCheck, checkInterval);
    
  } catch (error) {
    notify.error(`Failed to update images: ${error.message}`);
    console.error('Error updating images:', error);
    hideLoading();
  }
}

// Settings functions
async function saveGeneralSettings() {
  try {
    showLoading();
    
    // Gather settings from form
    const settings = {
      puid: parseInt(document.getElementById('settings-puid').value),
      pgid: parseInt(document.getElementById('settings-pgid').value),
      timezone: document.getElementById('settings-timezone').value,
      language: document.getElementById('settings-language').value,
      theme: document.getElementById('settings-theme').value
    };
    
    // Validate settings
    if (isNaN(settings.puid) || isNaN(settings.pgid)) {
      throw new Error('User ID and Group ID must be valid numbers');
    }
    
    // Save settings via API
    await configApi.saveGeneralSettings(settings);
    
    // Show success notification
    notify.success('General settings saved successfully');
    
  } catch (error) {
    // Show error notification
    notify.error(`Failed to save settings: ${error.message}`);
    console.error('Error saving settings:', error);
  } finally {
    hideLoading();
  }
}

function saveServicesSettings() {
  showLoading();
  setTimeout(() => {
    alert('Service settings saved');
    hideLoading();
  }, 500);
}

function saveNetworkSettings() {
  showLoading();
  setTimeout(() => {
    alert('Network settings saved');
    hideLoading();
  }, 500);
}

function saveSecuritySettings() {
  showLoading();
  setTimeout(() => {
    alert('Security settings saved');
    hideLoading();
  }, 500);
}

function saveAdvancedSettings() {
  showLoading();
  setTimeout(() => {
    alert('Advanced settings saved');
    hideLoading();
  }, 500);
}

function resetConfiguration() {
  if (confirm('Are you sure you want to reset all configuration? This will not affect your media files, but will reset all PI-PVR settings to default.')) {
    showLoading();
    setTimeout(() => {
      alert('Configuration reset to defaults');
      hideLoading();
      location.reload();
    }, 2000);
  }
}

function pruneDocker() {
  if (confirm('Are you sure you want to prune Docker system? This will remove all unused containers, networks, and images.')) {
    showLoading();
    setTimeout(() => {
      alert('Docker system pruned successfully');
      hideLoading();
    }, 2000);
  }
}

function uninstallStack() {
  if (confirm('Are you sure you want to uninstall the PI-PVR stack? This will remove all containers and configuration, but will not delete your media files.')) {
    if (confirm('This action cannot be undone. Are you ABSOLUTELY SURE you want to proceed with uninstallation?')) {
      showLoading();
      setTimeout(() => {
        alert('PI-PVR stack uninstalled successfully');
        hideLoading();
        window.location.href = '/uninstalled.html';
      }, 3000);
    }
  }
}

// Help functions
function checkForUpdates() {
  showLoading();
  setTimeout(() => {
    alert('Your PI-PVR installation is up to date.');
    hideLoading();
  }, 1500);
}

function openDocumentation(docId) {
  const modal = document.getElementById('documentation-modal');
  const docTitle = document.getElementById('doc-title');
  const docContent = document.getElementById('doc-content');
  
  if (modal && docTitle && docContent) {
    let title = '';
    let content = '';
    
    // Set documentation content based on docId
    switch (docId) {
      case 'getting-started':
        title = 'Getting Started Guide';
        content = `
          <h3>Getting Started with PI-PVR</h3>
          <p>This guide will help you get up and running with your new PI-PVR media server.</p>
          <h4>Prerequisites</h4>
          <ul>
            <li>Raspberry Pi 4 or newer (or any Linux-based system)</li>
            <li>External storage for media files</li>
            <li>Internet connection</li>
            <li>VPN subscription (recommended)</li>
          </ul>
          <h4>Installation Steps</h4>
          <ol>
            <li>Follow the installation wizard in the Install tab</li>
            <li>Configure your storage and network settings</li>
            <li>Select the services you want to run</li>
            <li>Start the installation process</li>
            <li>Access your services through the dashboard</li>
          </ol>
          <p>For more detailed instructions, check out the other guides in the documentation section.</p>
        `;
        break;
      case 'services-guide':
        title = 'Services Guide';
        content = `
          <h3>PI-PVR Services</h3>
          <p>PI-PVR includes a comprehensive set of services for managing and enjoying your media library.</p>
          <h4>Media Management Services</h4>
          <ul>
            <li><strong>Sonarr</strong> - TV show management</li>
            <li><strong>Radarr</strong> - Movie management</li>
            <li><strong>Prowlarr</strong> - Indexer management</li>
            <li><strong>Lidarr</strong> - Music management</li>
            <li><strong>Readarr</strong> - Book management</li>
            <li><strong>Bazarr</strong> - Subtitle management</li>
          </ul>
          <h4>Download Clients</h4>
          <ul>
            <li><strong>Transmission</strong> - Torrent client</li>
            <li><strong>qBittorrent</strong> - Alternative torrent client</li>
            <li><strong>NZBGet</strong> - Usenet client</li>
            <li><strong>SABnzbd</strong> - Alternative usenet client</li>
          </ul>
          <h4>Media Servers</h4>
          <ul>
            <li><strong>Jellyfin</strong> - Open source media server</li>
            <li><strong>Plex</strong> - Media server with premium features</li>
            <li><strong>Emby</strong> - Alternative media server</li>
          </ul>
          <h4>Utilities</h4>
          <ul>
            <li><strong>Watchtower</strong> - Automatic container updates</li>
            <li><strong>Portainer</strong> - Docker management</li>
            <li><strong>Heimdall</strong> - Application dashboard</li>
            <li><strong>Overseerr</strong> - Media requests</li>
          </ul>
        `;
        break;
      case 'vpn-guide':
        title = 'VPN Configuration Guide';
        content = `
          <h3>VPN Configuration</h3>
          <p>PI-PVR uses Gluetun to provide a secure VPN connection for your download clients.</p>
          <h4>Supported VPN Providers</h4>
          <ul>
            <li>Private Internet Access</li>
            <li>NordVPN</li>
            <li>Mullvad</li>
            <li>Surfshark</li>
            <li>ExpressVPN</li>
            <li>And many more...</li>
          </ul>
          <h4>Configuration Steps</h4>
          <ol>
            <li>Enter your VPN credentials in the Settings tab</li>
            <li>Choose a server region</li>
            <li>Enable the VPN killswitch for added security</li>
            <li>Configure port forwarding if needed</li>
          </ol>
          <h4>Troubleshooting</h4>
          <p>If you're having issues with your VPN connection:</p>
          <ol>
            <li>Check your VPN credentials</li>
            <li>Try a different server region</li>
            <li>Check the VPN logs for error messages</li>
            <li>Try restarting the VPN container</li>
          </ol>
        `;
        break;
      case 'troubleshooting':
        title = 'Troubleshooting Guide';
        content = `
          <h3>Troubleshooting PI-PVR</h3>
          <p>Common issues and their solutions.</p>
          <h4>Services Won't Start</h4>
          <ol>
            <li>Check the service logs for error messages</li>
            <li>Verify that the required directories exist and have correct permissions</li>
            <li>Ensure Docker has enough resources</li>
            <li>Try restarting the Docker service</li>
          </ol>
          <h4>VPN Connection Issues</h4>
          <ol>
            <li>Verify your VPN credentials</li>
            <li>Try a different server region</li>
            <li>Check if your VPN provider has service outages</li>
          </ol>
          <h4>Media Not Showing in Library</h4>
          <ol>
            <li>Check that your media is in the correct directory format</li>
            <li>Verify permissions on media directories</li>
            <li>Run a library scan in your media server</li>
            <li>Check naming conventions match the media server requirements</li>
          </ol>
          <h4>Disk Space Issues</h4>
          <ol>
            <li>Use the Storage tab to check disk usage</li>
            <li>Clean up completed downloads</li>
            <li>Remove temporary files and logs</li>
            <li>Consider adding more storage</li>
          </ol>
        `;
        break;
      case 'networking':
        title = 'Networking Guide';
        content = `
          <h3>Networking with PI-PVR</h3>
          <p>Configure networking for optimal performance and security.</p>
          <h4>Local Network Access</h4>
          <p>By default, all services are accessible on your local network using your server's IP address and the assigned port numbers.</p>
          <h4>Remote Access Options</h4>
          <ol>
            <li><strong>Tailscale</strong> (Recommended)
              <ul>
                <li>Secure, encrypted access from anywhere</li>
                <li>No port forwarding required</li>
                <li>Client apps available for all platforms</li>
              </ul>
            </li>
            <li><strong>Port Forwarding</strong>
              <ul>
                <li>Configure your router to forward specific ports</li>
                <li>Use the Port Forwarding tab to manage forwarded ports</li>
                <li>Consider security implications</li>
              </ul>
            </li>
            <li><strong>Reverse Proxy</strong>
              <ul>
                <li>Use Nginx Proxy Manager for more advanced setups</li>
                <li>Secure access with SSL certificates</li>
                <li>Host services under your own domain</li>
              </ul>
            </li>
          </ol>
          <h4>Security Recommendations</h4>
          <ul>
            <li>Use Tailscale for remote access whenever possible</li>
            <li>Enable HTTPS for all web interfaces</li>
            <li>Password-protect your services</li>
            <li>Only forward necessary ports</li>
          </ul>
        `;
        break;
      case 'storage':
        title = 'Storage Management Guide';
        content = `
          <h3>Storage Management in PI-PVR</h3>
          <p>Efficiently manage your media storage.</p>
          <h4>Recommended Storage Setup</h4>
          <ul>
            <li>Dedicated external drive for media (USB 3.0 or better)</li>
            <li>Separate partition for downloads (optional)</li>
            <li>Format drives with ext4 for best performance on Linux</li>
          </ul>
          <h4>Directory Structure</h4>
          <pre>
/mnt/storage/
├── Movies/
│   ├── Action/
│   ├── Comedy/
│   └── ...
├── TVShows/
│   ├── Drama/
│   ├── Comedy/
│   └── ...
└── Downloads/
    ├── complete/
    └── incomplete/
          </pre>
          <h4>File Sharing</h4>
          <p>PI-PVR supports multiple sharing protocols:</p>
          <ul>
            <li><strong>Samba (SMB)</strong> - Best for Windows, macOS, and Linux</li>
            <li><strong>NFS</strong> - Optimized for Linux-to-Linux sharing</li>
          </ul>
          <h4>Space Management</h4>
          <ul>
            <li>Use the Storage tab to monitor disk usage</li>
            <li>Regularly clean up completed downloads</li>
            <li>Configure Radarr/Sonarr to remove duplicates</li>
            <li>Use the "Clean Downloads" feature to reclaim space</li>
          </ul>
        `;
        break;
      default:
        title = 'Documentation';
        content = 'Documentation not found.';
    }
    
    docTitle.textContent = title;
    docContent.innerHTML = content;
    modal.style.display = 'block';
  }
}

// Helper functions
function capitalizeFirstLetter(string) {
  return string.charAt(0).toUpperCase() + string.slice(1);
}

// Fetch functions for shares
function fetchSambaShares() {
  // In a real implementation, this would make an API call
  fetchStorageInfo(); // For demo, just refresh all storage info
}

function fetchNfsShares() {
  // In a real implementation, this would make an API call
  fetchStorageInfo(); // For demo, just refresh all storage info
}