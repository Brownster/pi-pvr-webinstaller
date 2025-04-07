const apiClient = require('./js/api-client');
const main = require('./js/main');

describe('Web UI Tests', () => {
  it('should import api-client.js', () => {
    expect(apiClient).toBeDefined();
  });

  it('should import main.js', () => {
    expect(main).toBeDefined();
  });

  describe('systemApi', () => {
    it('should get system info', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({
            hostname: 'test',
            platform: 'test',
            version: 'test'
          })
        });
      });

      const systemInfo = await apiClient.systemApi.getSystemInfo();
      expect(systemInfo).toEqual({
        hostname: 'test',
        platform: 'test',
        version: 'test'
      });
    });

    it('should get status', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({
            installation_status: 'completed',
            containers: {}
          })
        });
      });

      const status = await apiClient.systemApi.getStatus();
      expect(status).toEqual({
        installation_status: 'completed',
        containers: {}
      });
    });
  });

  describe('servicesApi', () => {
    it('should get all services', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({
            "service1": { "status": "running" },
            "service2": { "status": "stopped" }
          })
        });
      });

      const services = await apiClient.servicesApi.getAllServices();
      expect(services).toEqual({
        "service1": { "status": "running" },
        "service2": { "status": "stopped" }
      });
    });

    it('should start a service', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "success" })
        });
      });

      const status = await apiClient.servicesApi.startService('test');
      expect(status).toEqual({ "status": "success" });
    });

    it('should stop a service', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "success" })
        });
      });

      const status = await apiClient.servicesApi.stopService('test');
      expect(status).toEqual({ "status": "success" });
    });

    it('should restart a service', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "success" })
        });
      });

      const status = await apiClient.servicesApi.restartService('test');
      expect(status).toEqual({ "status": "success" });
    });

    it('should restart all services', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "success" })
        });
      });

      const status = await apiClient.servicesApi.restartAll();
      expect(status).toEqual({ "status": "success" });
    });
  });

  describe('storageApi', () => {
    it('should get drives', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({
            "drives": [
              { "device": "/dev/sda1", "size": "1TB", "type": "ext4" },
              { "device": "/dev/sdb1", "size": "2TB", "type": "ntfs" }
            ]
          })
        });
      });

      const drives = await apiClient.storageApi.getDrives();
      expect(drives).toEqual({
        "drives": [
          { "device": "/dev/sda1", "size": "1TB", "type": "ext4" },
          { "device": "/dev/sdb1", "size": "2TB", "type": "ntfs" }
        ]
      });
    });

    it('should unmount a drive', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "success" })
        });
      });

      const status = await apiClient.storageApi.unmountDrive('test');
      expect(status).toEqual({ "status": "success" });
    });

    it('should scan a directory', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "success" })
        });
      });

      const status = await apiClient.storageApi.scanDirectory('test');
      expect(status).toEqual({ "status": "success" });
    });

    it('should get samba shares', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({
            "shares": [
              { "name": "share1", "path": "/mnt/share1" },
              { "name": "share2", "path": "/mnt/share2" }
            ]
          })
        });
      });

      const shares = await apiClient.storageApi.getSambaShares();
      expect(shares).toEqual({
        "shares": [
          { "name": "share1", "path": "/mnt/share1" },
          { "name": "share2", "path": "/mnt/share2" }
        ]
      });
    });

    it('should get nfs shares', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({
            "shares": [
              { "name": "share1", "path": "/mnt/share1" },
              { "name": "share2", "path": "/mnt/share2" }
            ]
          })
        });
      });

      const shares = await apiClient.storageApi.getNfsShares();
      expect(shares).toEqual({
        "shares": [
          { "name": "share1", "path": "/mnt/share1" },
          { "name": "share2", "path": "/mnt/share2" }
        ]
      });
    });

    it('should add a samba share', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "success" })
        });
      });

      const status = await apiClient.storageApi.addSambaShare({});
      expect(status).toEqual({ "status": "success" });
    });

    it('should delete a samba share', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "success" })
        });
      });

      const status = await apiClient.storageApi.deleteSambaShare('test');
      expect(status).toEqual({ "status": "success" });
    });
  });

  describe('configApi', () => {
    it('should get config', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "test": "value" })
        });
      });

      const config = await apiClient.configApi.getConfig();
      expect(config).toEqual({ "test": "value" });
    });

    it('should save config', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "success" })
        });
      });

      const status = await apiClient.configApi.saveConfig({});
      expect(status).toEqual({ "status": "success" });
    });

    it('should save general settings', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "success" })
        });
      });

      const status = await apiClient.configApi.saveGeneralSettings({});
      expect(status).toEqual({ "status": "success" });
    });

    it('should save network settings', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "success" })
        });
      });

      const status = await apiClient.configApi.saveNetworkSettings({});
      expect(status).toEqual({ "status": "success" });
    });

    it('should reset config', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "success" })
        });
      });

      const status = await apiClient.configApi.resetConfig();
      expect(status).toEqual({ "status": "success" });
    });

    it('should backup config', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "success" })
        });
      });

      const status = await apiClient.configApi.backupConfig();
      expect(status).toEqual({ "status": "success" });
    });
  });

  describe('installApi', () => {
    it('should start installation', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "started" })
        });
      });

      const status = await apiClient.installApi.startInstallation({});
      expect(status).toEqual({ "status": "started" });
    });

    it('should get installation status', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "completed" })
        });
      });

      const status = await apiClient.installApi.getInstallationStatus();
      expect(status).toEqual({ "status": "completed" });
    });

    it('should get logs', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "logs": "test logs" })
        });
      });

      const logs = await apiClient.installApi.getLogs();
      expect(logs).toEqual({ "logs": "test logs" });
    });
  });

  describe('networkApi', () => {
    it('should get network info', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "test": "value" })
        });
      });

      const networkInfo = await apiClient.networkApi.getNetworkInfo();
      expect(networkInfo).toEqual({ "test": "value" });
    });

    it('should get vpn status', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "connected" })
        });
      });

      const status = await apiClient.networkApi.getVpnStatus();
      expect(status).toEqual({ "status": "connected" });
    });

    it('should connect vpn', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "success" })
        });
      });

      const status = await apiClient.networkApi.connectVpn();
      expect(status).toEqual({ "status": "success" });
    });

    it('should disconnect vpn', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "success" })
        });
      });

      const status = await apiClient.networkApi.disconnectVpn();
      expect(status).toEqual({ "status": "success" });
    });

    it('should get tailscale status', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "enabled" })
        });
      });

      const status = await apiClient.networkApi.getTailscaleStatus();
      expect(status).toEqual({ "status": "enabled" });
    });

    it('should enable tailscale', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "success" })
        });
      });

      const status = await apiClient.networkApi.enableTailscale();
      expect(status).toEqual({ "status": "success" });
    });

    it('should disable tailscale', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "success" })
        });
      });

      const status = await apiClient.networkApi.disableTailscale();
      expect(status).toEqual({ "status": "success" });
    });
  });

  describe('updateApi', () => {
    it('should update images', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "success" })
        });
      });

      const status = await apiClient.updateApi.updateImages();
      expect(status).toEqual({ "status": "success" });
    });

    it('should get update status', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "status": "idle" })
        });
      });

      const status = await apiClient.updateApi.getUpdateStatus();
      expect(status).toEqual({ "status": "idle" });
    });
  });

  describe('logsApi', () => {
    it('should get service logs', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "logs": "test logs" })
        });
      });

      const logs = await apiClient.logsApi.getServiceLogs('test');
      expect(logs).toEqual({ "logs": "test logs" });
    });

    it('should get system logs', async () => {
      global.fetch = jest.fn().mockImplementation(() => {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ "logs": "test logs" })
        });
      });

      const logs = await apiClient.logsApi.getSystemLogs();
      expect(logs).toEqual({ "logs": "test logs" });
    });
  });
});
