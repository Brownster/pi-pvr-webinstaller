/**
 * PI-PVR API Client
 * Centralizes all API requests to maintain DRY principles
 */

// Base API configuration
const API_BASE_URL = '/api';
const DEFAULT_HEADERS = {
  'Content-Type': 'application/json'
};

// Error handling wrapper for fetch requests
async function apiRequest(endpoint, options = {}) {
  try {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      headers: DEFAULT_HEADERS,
      ...options
    });
    
    // Handle non-2xx responses
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.message || `Request failed with status ${response.status}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error(`API request failed: ${endpoint}`, error);
    throw error; // Re-throw for component-level handling
  }
}

// System information API
export const systemApi = {
  getSystemInfo: () => apiRequest('/system'),
  getStatus: () => apiRequest('/status')
};

// Services API
export const servicesApi = {
  getAllServices: () => apiRequest('/services'),
  startService: (serviceName) => apiRequest(`/services/${serviceName}/start`, { method: 'POST' }),
  stopService: (serviceName) => apiRequest(`/services/${serviceName}/stop`, { method: 'POST' }),
  restartService: (serviceName) => apiRequest(`/services/${serviceName}/restart`, { method: 'POST' }),
  restartAll: () => apiRequest('/services/restart-all', { method: 'POST' })
};

// Storage API
export const storageApi = {
  getDrives: () => apiRequest('/storage/drives'),
  unmountDrive: (device) => apiRequest(`/storage/unmount`, { 
    method: 'POST',
    body: JSON.stringify({ device })
  }),
  scanDirectory: (path) => apiRequest('/storage/scan-directory', {
    method: 'POST',
    body: JSON.stringify({ path })
  }),
  getSambaShares: () => apiRequest('/storage/shares/samba'),
  getNfsShares: () => apiRequest('/storage/shares/nfs'),
  addSambaShare: (shareData) => apiRequest('/storage/shares/samba', {
    method: 'POST',
    body: JSON.stringify(shareData)
  }),
  deleteSambaShare: (name) => apiRequest(`/storage/shares/samba/${name}`, {
    method: 'DELETE'
  })
};

// Configuration API
export const configApi = {
  getConfig: () => apiRequest('/config'),
  saveConfig: (config) => apiRequest('/config', {
    method: 'POST',
    body: JSON.stringify(config)
  }),
  // Settings categories
  saveGeneralSettings: (settings) => apiRequest('/settings/general', {
    method: 'POST',
    body: JSON.stringify(settings)
  }),
  saveNetworkSettings: (settings) => apiRequest('/settings/network', {
    method: 'POST',
    body: JSON.stringify(settings)
  }),
  resetConfig: () => apiRequest('/config/reset', { method: 'POST' }),
  backupConfig: () => apiRequest('/config/backup', { method: 'POST' })
};

// Installation API
export const installApi = {
  startInstallation: (config) => apiRequest('/install', {
    method: 'POST',
    body: JSON.stringify(config)
  }),
  getInstallationStatus: () => apiRequest('/install/status'),
  getLogs: () => apiRequest('/logs')
};

// Network API
export const networkApi = {
  getNetworkInfo: () => apiRequest('/network'),
  getVpnStatus: () => apiRequest('/vpn/status'),
  connectVpn: () => apiRequest('/vpn/connect', { method: 'POST' }),
  disconnectVpn: () => apiRequest('/vpn/disconnect', { method: 'POST' }),
  getTailscaleStatus: () => apiRequest('/tailscale/status'),
  enableTailscale: () => apiRequest('/tailscale/enable', { method: 'POST' }),
  disableTailscale: () => apiRequest('/tailscale/disable', { method: 'POST' })
};

// Update API
export const updateApi = {
  updateImages: () => apiRequest('/update/images', { method: 'POST' }),
  getUpdateStatus: () => apiRequest('/update/status')
};

// Logs API
export const logsApi = {
  getServiceLogs: (service, lines = 100) => apiRequest(`/logs/${service}?lines=${lines}`),
  getSystemLogs: (lines = 100) => apiRequest(`/logs/system?lines=${lines}`)
};