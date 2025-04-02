# Contributing to PI-PVR Ultimate Media Stack

Thank you for considering contributing to PI-PVR Ultimate Media Stack! This document provides guidelines and instructions for contributing to the project.

## How to Contribute

There are many ways to contribute to the project:

1. **Bug reports**: If you find a bug, please create an issue with a detailed description.
2. **Feature requests**: Suggest new features or improvements through issues.
3. **Documentation**: Help improve documentation, tutorials, or examples.
4. **Code contributions**: Submit pull requests with bug fixes or new features.
5. **Testing**: Test the software on different hardware or configurations.

## Development Setup

1. Fork the repository on GitHub.
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/PI-PVR-0.1.git
   cd PI-PVR-0.1
   ```
3. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Project Structure

Please see [STRUCTURE.md](STRUCTURE.md) for a detailed explanation of the project's organization.

## Code Style Guidelines

- **Bash scripts**:
  - Use 2-space indentation
  - Add comments for complex operations
  - Use meaningful variable names
  - Add error handling for critical operations

- **Python code**:
  - Follow PEP 8 guidelines
  - Use clear and descriptive variable names
  - Add docstrings for functions and modules
  - Add appropriate error handling

- **JavaScript & HTML/CSS**:
  - Use 2-space indentation
  - Follow modern ES6+ syntax
  - Prefer semantic HTML elements
  - Maintain responsive design principles

## Pull Request Process

1. Ensure your code follows the style guidelines above.
2. Update documentation if you're changing functionality.
3. Make sure all existing tests pass, and add tests for new features.
4. Update the CHANGELOG.md file with details of your changes.
5. The PR should work on Raspberry Pi and other Linux environments.

## Development Workflow

1. Create a branch for your feature or bugfix:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

2. Make your changes and commit them:
   ```bash
   git add .
   git commit -m "Description of changes"
   ```

3. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

4. Submit a pull request to the main repository.

## Adding New Services

When adding a new service to the stack:

1. Add the service to the appropriate docker-compose file.
2. Update the web UI to include options for the service.
3. Test the service with and without VPN routing.
4. Document the service in the README.md.
5. Add any specific configuration instructions.

## Testing

Test your changes on as many platforms as possible, ideally including:
- Raspberry Pi 4
- Raspberry Pi 5
- Other ARM-based systems
- x86/x64 Linux systems

Verify that:
- Installation works correctly
- Services can be configured properly
- The web UI functions as expected

## License

By contributing to PI-PVR Ultimate Media Stack, you agree that your contributions will be licensed under the project's MIT License.

## Questions?

If you have any questions about contributing, please open an issue for discussion.