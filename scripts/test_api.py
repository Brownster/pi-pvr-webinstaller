import scripts.api
import os
import json
import subprocess
from unittest.mock import patch, MagicMock

def test_import_api():
    assert True

def test_load_config():
    # Create a temporary config file
    test_config = {"test": "value"}
    with open("test_config.json", "w") as f:
        json.dump(test_config, f)

    # Patch the CONFIG_FILE variable to point to the temporary file
    with patch("scripts.api.CONFIG_FILE", "test_config.json"):
        # Load the config
        config = scripts.api.load_config()

        # Assert that the config is loaded correctly
        assert config == test_config

    # Clean up the temporary file
    os.remove("test_config.json")

def test_save_config():
    # Create a temporary config file
    test_config = {"test": "value"}

    # Patch the CONFIG_FILE variable to point to the temporary file
    with patch("scripts.api.CONFIG_FILE", "test_config.json"):
        # Save the config
        scripts.api.save_config(test_config)

        # Load the config from the file
        with open("test_config.json", "r") as f:
            loaded_config = json.load(f)

        # Assert that the config is saved correctly
        assert loaded_config == test_config

    # Clean up the temporary file
    os.remove("test_config.json")

def test_load_services():
    # Create a temporary services file
    test_services = {"test": "value"}
    with open("test_services.json", "w") as f:
        json.dump(test_services, f)

    # Patch the SERVICES_FILE variable to point to the temporary file
    with patch("scripts.api.SERVICES_FILE", "test_services.json"):
        # Load the services
        services = scripts.api.load_services()

        # Assert that the services are loaded correctly
        assert services == test_services

    # Clean up the temporary file
    os.remove("test_services.json")

def test_save_services():
    # Create a temporary services file
    test_services = {"test": "value"}

    # Patch the SERVICES_FILE variable to point to the temporary file
    with patch("scripts.api.SERVICES_FILE", "test_services.json"):
        # Save the services
        scripts.api.save_services(test_services)

        # Load the services from the file
        with open("test_services.json", "r") as f:
            loaded_services = json.load(f)

        # Assert that the services are saved correctly
        assert loaded_services == test_services

    # Clean up the temporary file
    os.remove("test_services.json")

def test_is_docker_installed():
    # Mock subprocess.run to simulate Docker being installed
    with patch("subprocess.run") as mock_run:
        mock_run.return_value.returncode = 0
        assert scripts.api.is_docker_installed() == True

    # Mock subprocess.run to simulate Docker not being installed
    with patch("subprocess.run") as mock_run:
        mock_run.return_value.returncode = 1
        assert scripts.api.is_docker_installed() == False

def test_get_system_info():
    # Mock platform.system, platform.version, platform.machine, platform.processor, platform.python_version
    with patch("platform.system") as mock_system, \
         patch("platform.version") as mock_version, \
         patch("platform.machine") as mock_machine, \
         patch("platform.processor") as mock_processor, \
         patch("platform.python_version") as mock_python_version, \
         patch("psutil.virtual_memory") as mock_virtual_memory, \
         patch("psutil.disk_usage") as mock_disk_usage, \
         patch("scripts.api.is_docker_installed") as mock_is_docker_installed, \
         patch("os.path.exists") as mock_os_path_exists, \
         patch("builtins.open", create=True) as mock_open:

        mock_system.return_value = "Linux"
        mock_version.return_value = "5.4.0-58-generic"
        mock_machine.return_value = "x86_64"
        mock_processor.return_value = "Intel(R) Core(TM) i7-8700K CPU @ 3.70GHz"
        mock_python_version.return_value = "3.9.7"
        mock_virtual_memory.return_value.total = 16 * 1024 * 1024 * 1024
        mock_virtual_memory.return_value.available = 8 * 1024 * 1024 * 1024
        mock_disk_usage.return_value.total = 500 * 1024 * 1024 * 1024
        mock_disk_usage.return_value.free = 250 * 1024 * 1024 * 1024
        mock_is_docker_installed.return_value = True
        mock_os_path_exists.return_value = False
        mock_open.return_value.read.return_value = ""

        system_info = scripts.api.get_system_info()

        assert system_info["hostname"] is not None
        assert system_info["platform"] == "Linux"
        assert system_info["platform_version"] == "5.4.0-58-generic"
        assert system_info["architecture"] == "x86_64"
        assert system_info["processor"] == "Intel(R) Core(TM) i7-8700K CPU @ 3.70GHz"
        assert system_info["python_version"] == "3.9.7"
        assert system_info["memory_total"] == 16 * 1024 * 1024 * 1024
        assert system_info["memory_available"] == 8 * 1024 * 1024 * 1024
        assert system_info["disk_total"] == 500 * 1024 * 1024 * 1024
        assert system_info["disk_free"] == 250 * 1024 * 1024 * 1024
        assert system_info["docker_installed"] == True
        assert system_info["tailscale_installed"] == False
        assert system_info["os"]["name"] == "linux"
        assert system_info["os"]["version"] == "5.4.0-58-generic"
        assert system_info["os"]["pretty_name"] == "Linux 5.4.0-58-generic"
        assert system_info["raspberry_pi"]["is_raspberry_pi"] == False
        assert system_info["raspberry_pi"]["model"] == "Not a Raspberry Pi"
        assert system_info["hardware"]["cpu"]["model"] == "Intel(R) Core(TM) i7-8700K CPU @ 3.70GHz"
        assert system_info["hardware"]["cpu"]["cores"] == os.cpu_count()
        assert system_info["hardware"]["memory"]["total_gb"] == 16.0
        assert system_info["hardware"]["disk"]["root_size_gb"] == 500.0
        assert system_info["hardware"]["disk"]["root_available_gb"] == 250.0
        assert system_info["transcoding"]["vaapi_available"] == False
        assert system_info["transcoding"]["nvdec_available"] == False
        assert system_info["transcoding"]["v4l2_available"] == False
        assert system_info["transcoding"]["recommended_method"] == "software"

def test_get_container_status():
    # Mock subprocess.run to simulate Docker containers running
    with patch("subprocess.run") as mock_run:
        mock_run.return_value.returncode = 0
        mock_run.return_value.stdout = "container1|Up 2 hours|8080:8080\ncontainer2|Up 1 hour|443:443"
        container_status = scripts.api.get_container_status()
        assert container_status == {
            "container1": {"status": "running", "ports": [{"host": "8080", "container": "8080"}]},
            "container2": {"status": "running", "ports": [{"host": "443", "container": "443"}]}
        }

    # Mock subprocess.run to simulate no Docker containers running
    with patch("subprocess.run") as mock_run:
        mock_run.return_value.returncode = 0
        mock_run.return_value.stdout = ""
        container_status = scripts.api.get_container_status()
        assert container_status == {}

    # Mock subprocess.run to simulate Docker command failing
    with patch("subprocess.run") as mock_run:
        mock_run.side_effect = subprocess.CalledProcessError(1, "docker ps")
        container_status = scripts.api.get_container_status()
        assert container_status == {"error": {"status": "error", "message": "Command 'docker ps' returned non-zero exit status 1."}}
