# Ruby RPM Builder

A Docker-based build environment for creating Ruby RPM packages compatible with Amazon Linux and Rocky Linux distributions.

## Overview

This repository contains a Dockerfile that creates a containerized build environment for building Ruby 3.0.7 RPM packages from source. The build process is specifically designed to work with Rocky Linux source RPMs and includes compatibility fixes for Amazon Linux environments.

## Use Case

- **Enterprise Linux Deployments**: Build Ruby RPMs for RHEL-based distributions (Amazon Linux, Rocky Linux, CentOS, etc.)
- **Custom Ruby Builds**: Create Ruby packages with specific OpenSSL versions and configurations
- **CI/CD Pipelines**: Automate Ruby package building in containerized environments
- **Package Management**: Generate installable RPM packages for enterprise environments

## Key Features

- **OpenSSL 1.1.1 Compatibility**: Builds Ruby with OpenSSL 1.1.1w for security and compatibility
- **Rocky Linux Source Integration**: Uses official Rocky Linux 9 Ruby source RPM
- **Container-based Build**: Isolated build environment using Amazon Linux base image
- **Development Tools**: Includes complete RPM build toolchain and dependencies
- **Multi-architecture Support**: Supports linux/amd64 platform

## Functionality

### Build Process

1. **Base Environment Setup**: Sets up Amazon Linux with development tools and RPM build utilities
2. **OpenSSL Installation**: Compiles and installs OpenSSL 1.1.1w from source
3. **Ruby Source Preparation**: Downloads and extracts Ruby 3.0.7 source RPM from Rocky Linux
4. **Spec File Modification**: Adapts the Ruby spec file for OpenSSL 1.1 compatibility
5. **Dependency Resolution**: Installs all required build dependencies
6. **RPM Building**: Compiles Ruby and creates installable RPM packages
7. **Package Output**: Copies built RPMs to accessible output directory

### Built Packages

The build process generates several RPM packages:
- `ruby` - Main Ruby interpreter
- `ruby-devel` - Development headers and libraries
- `ruby-libs` - Ruby runtime libraries
- Additional Ruby-related packages as defined in the spec file

## Usage

### Building the Container

```bash
docker build -t ruby-rpm-builder .
```

### Running the Build

```bash
# Run the container to build RPMs
docker run --name ruby-build ruby-rpm-builder

# Copy built RPMs from container
docker cp ruby-build:/home/builder/output/ ./ruby-rpms/
```

### Installing Built Packages

```bash
# Install the built Ruby RPM
sudo rpm -ivh ruby-rpms/ruby-*.rpm
```

## Technical Details

- **Base Image**: Amazon Linux (latest)
- **Ruby Version**: 3.0.7
- **OpenSSL Version**: 1.1.1w
- **Build User**: Non-root `builder` user for security
- **Output Location**: `/home/builder/output/`

## Requirements

- Docker or compatible container runtime
- Sufficient disk space for build dependencies and source code
- Internet connection for downloading source packages

## License

This build configuration is provided as-is for creating Ruby RPM packages from official sources.