# PI-PVR Development Guidelines

## Commands
- **Run script**: `./pi-pvr.sh`
- **Debug mode**: `./pi-pvr.sh --debug`
- **Update Docker Compose**: `./pi-pvr.sh --update`
- **No lint/test commands**: This project is a bash script without formal testing framework

## Code Style Guidelines

### Bash Scripting
- Use `set -euo pipefail` for error handling
- Functions should be snake_case
- Variables should be UPPER_CASE
- Use `[[ ]]` for conditionals (not `[ ]`)
- Document functions with comments
- Use heredocs (<<EOF) for multi-line text generation

### Error Handling
- Exit on error with descriptive messages
- Check return codes after critical operations
- Provide user-friendly error messages

### File Structure
- Scripts in root directory
- Configuration in user's home directory
- Docker setup in ~/docker
- Use environment variables for configuration

### Docker Integration
- Container names defined as environment variables
- Service containers use VPN container network
- Properly handle environment variables and volume mounts
- Include container health checks

### Feature Additions
- Add new features to both the script and the README
- Document any new environment variables
- Follow existing patterns for network/storage setup
- For new containers, follow existing naming and network patterns