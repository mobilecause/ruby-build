# Ruby 3.0.7 RPM Builder & Repository

A complete solution for building Ruby 3.0.7 RPM packages and hosting them as a YUM/DNF repository on GitHub. Perfect for Enterprise Linux environments (Amazon Linux, Rocky Linux, RHEL, CentOS, etc.).

## 🎯 What This Project Does

This project provides:
1. **Docker-based Ruby RPM Builder**: Builds Ruby 3.0.7 with compat-openssl11 support
2. **Automated RPM Repository**: Creates a complete YUM/DNF repository with metadata
3. **GitHub-hosted Package Distribution**: Serves RPM packages directly from GitHub
4. **Easy Server Installation**: One-line installation script for your servers

## 🏗️ Architecture Overview

```
📦 Ruby Build Process
├── 🐳 Docker Container
│   ├── Builds Ruby 3.0.7 + compat-openssl11 RPMs
│   ├── Creates repository metadata (repodata/)
│   └── Generates client setup files
├── 🎯 GitHub Actions
│   ├── Automates the build process
│   └── Uploads complete repository as artifact
└── 📁 Repository Structure
    └── ruby3-0-7/
        ├── rpm-repo/x86_64/          # RPM packages + metadata
        └── client-setup/             # Installation scripts
```

## 🚀 Quick Start Guide

### For Repository Maintainers

#### 1. Fork & Setup
```bash
# Fork this repository to your GitHub account
# Clone your fork
git clone https://github.com/YOUR-USERNAME/ruby-build.git
cd ruby-build
```

#### 2. Trigger Build
```bash
# Go to GitHub Actions tab in your repository
# Run "Build Ruby RPM (Simple)" workflow
# Click "Run workflow" button (x86_64 only)
```

#### 3. Download & Deploy
```bash
# After build completes:
# 1. Go to Actions → Latest Run → Artifacts
# 2. Download "ruby3-0-7-complete-x86_64"
# 3. Extract the zip file
# 4. You'll get a ruby3-0-7/ folder

# Update repository URLs in the files:
# Edit ruby3-0-7/client-setup/ruby-build.repo
# Edit ruby3-0-7/client-setup/install.sh
# Replace USERNAME/REPOSITORY with your GitHub details

# Upload to your repository
cp -r ruby3-0-7 /path/to/your/repo/
cd /path/to/your/repo/
git add ruby3-0-7/
git commit -m "🚀 Add Ruby 3.0.7 RPM repository"
git push
```

### For Server Administrators

#### 1. Install Repository (One Command)
```bash
# Replace YOUR-USERNAME/YOUR-REPO with actual repository details
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/YOUR-REPO/main/ruby3-0-7/client-setup/install.sh | sudo bash
```

#### 2. Install Ruby
```bash
# Install Ruby and dependencies
sudo dnf install ruby compat-openssl11

# Verify installation
ruby --version
dnf info ruby  # Should show ruby-build-3-0-7 as source
```

#### 3. Package Management
```bash
# Search for available Ruby packages
dnf search ruby --repo=ruby-build-3-0-7

# List all packages from ruby-build repository
dnf list available --repo=ruby-build-3-0-7

# Update Ruby packages
sudo dnf update --repo=ruby-build-3-0-7
```

## 📋 Detailed Instructions

### Building Ruby RPMs

#### Prerequisites
- GitHub account
- Basic familiarity with GitHub Actions
- Text editor for updating configuration files

#### Step-by-Step Build Process

1. **Access GitHub Actions**
   - Go to your forked repository on GitHub
   - Click "Actions" tab
   - Select "Build Ruby RPM (Simple)" workflow

2. **Configure Build**
   - Click "Run workflow"
   - Select branch: `main`
   - Click "Run workflow" button (builds x86_64 automatically)

3. **Monitor Build Progress**
   - Build takes approximately 15-20 minutes
   - Watch the progress in the Actions tab
   - Green checkmark = successful build
   - Red X = build failed (check logs)

4. **Download Artifacts**
   - After successful build, scroll to "Artifacts" section
   - Download `ruby3-0-7-complete-x86_64.zip`
   - Extract the zip file to get `ruby3-0-7/` folder

#### Artifact Contents Explained
```
ruby3-0-7/
├── rpm-repo/
│   └── x86_64/
│       ├── repodata/                    # Repository metadata
│       │   ├── repomd.xml              # Main metadata file
│       │   ├── primary.xml.gz          # Package information
│       │   ├── filelists.xml.gz        # File listings
│       │   └── other.xml.gz            # Additional metadata
│       ├── ruby-3.0.7-*.rpm           # Ruby interpreter
│       ├── ruby-libs-*.rpm             # Ruby libraries
│       ├── ruby-devel-*.rpm            # Development files
│       └── compat-openssl11-*.rpm      # OpenSSL 1.1 compatibility
└── client-setup/
    ├── ruby-build.repo                 # YUM/DNF repository config
    └── install.sh                      # Automated installation script
```

### Configuring Repository URLs

#### Edit Repository Configuration
```bash
# Open ruby3-0-7/client-setup/ruby-build.repo
# Update this line:
baseurl=https://raw.githubusercontent.com/USERNAME/REPOSITORY/main/ruby3-0-7/rpm-repo/x86_64/

# Replace USERNAME with your GitHub username
# Replace REPOSITORY with your repository name
# Example:
baseurl=https://raw.githubusercontent.com/johndoe/ruby-build/main/ruby3-0-7/rpm-repo/x86_64/
```

#### Edit Installation Script
```bash
# Open ruby3-0-7/client-setup/install.sh
# Update this line:
REPO_URL="https://raw.githubusercontent.com/USERNAME/REPOSITORY/main"

# Example:
REPO_URL="https://raw.githubusercontent.com/johndoe/ruby-build/main"
```

### Server-Side Installation

#### Manual Repository Setup
```bash
# Method 1: Using the install script (recommended)
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/YOUR-REPO/main/ruby3-0-7/client-setup/install.sh | sudo bash

# Method 2: Manual configuration
sudo curl -o /etc/yum.repos.d/ruby-build-3-0-7.repo \
  https://raw.githubusercontent.com/YOUR-USERNAME/YOUR-REPO/main/ruby3-0-7/client-setup/ruby-build.repo

sudo dnf clean all
sudo dnf makecache
```

#### Repository Priority Explanation
The repository is configured with `priority=9`, which means:
- **Lower number = Higher priority**
- Amazon Linux default repos typically have priority 10
- Your Ruby packages will be preferred over Amazon Linux Ruby packages
- System-critical repos (priority 1-50) still take precedence

#### Verifying Installation
```bash
# Check if repository is installed
dnf repolist | grep ruby-build

# Verify Ruby will come from your repository
dnf list ruby --showduplicates

# Check package information
dnf info ruby

# Test Ruby installation
ruby --version
which ruby
```

## 🔧 Technical Details

### What Gets Built
- **Ruby 3.0.7**: Main interpreter with compat-openssl11 support
- **Ruby Libraries**: Runtime libraries and standard library
- **Ruby Development**: Headers and development tools
- **compat-openssl11**: OpenSSL 1.1.1 compatibility layer
- **Repository Metadata**: Complete YUM/DNF repository structure

### Build Process Details
1. **Container Setup**: Amazon Linux base with development tools
2. **OpenSSL Build**: Builds compat-openssl11 packages from source
3. **Ruby Configuration**: Modifies Ruby spec to use compat-openssl11
4. **RPM Building**: Creates all Ruby-related packages
5. **Repository Creation**: Generates metadata with `createrepo_c`
6. **Testing**: Verifies package installation and Ruby functionality

### Security Considerations
- **No GPG Signing**: Packages are not GPG signed (gpgcheck=0)
- **Public Repository**: All packages are publicly accessible
- **Source Verification**: Built from official Rocky Linux SRPMs
- **Container Isolation**: Build process runs in isolated container

### Supported Platforms
- **Architecture**: x86_64 only (Intel/AMD 64-bit)
- **OS Compatibility**: Enterprise Linux 9 (Amazon Linux 2023, Rocky Linux 9, RHEL 9, CentOS 9, AlmaLinux 9)
- **Ruby Version**: 3.0.7 (with potential for version updates)
- **Note**: aarch64 (ARM64) support removed for simplicity

## 🛠️ Troubleshooting

### Common Build Issues

#### Build Fails During Docker Build
```bash
# Check Docker logs
docker logs ruby-builder

# Common issues:
# - Network connectivity problems
# - Insufficient disk space
# - Missing dependencies
```

#### Artifact Download Problems
```bash
# Artifacts are only available for:
# - 30 days after build
# - Successful builds only
# - Repository collaborators

# Re-run the workflow if artifact expired
```

### Common Installation Issues

#### Repository Not Found
```bash
# Verify repository URL is accessible
curl -I https://raw.githubusercontent.com/YOUR-USERNAME/YOUR-REPO/main/ruby3-0-7/client-setup/ruby-build.repo

# Should return "200 OK"
```

#### Package Conflicts
```bash
# Remove existing Ruby packages
sudo dnf remove ruby* rubygems* --skip-broken

# Clean DNF cache
sudo dnf clean all

# Reinstall from ruby-build repository
sudo dnf install ruby --repo=ruby-build-3-0-7
```

#### Permission Denied
```bash
# Ensure you have sudo privileges
sudo -v

# Check repository file permissions
ls -la /etc/yum.repos.d/ruby-build-3-0-7.repo
```

### Getting Help

#### Build Logs
- Check GitHub Actions logs for detailed build information
- Look for error messages in Docker build steps
- Verify all dependencies are correctly installed

#### Repository Issues
- Verify file permissions and accessibility
- Check network connectivity from server
- Ensure repository URLs are correctly configured

#### Ruby Issues
- Test with `ruby --version` and `ruby -e "puts 'Hello'"`
- Check library loading with `ruby -e "require 'openssl'; puts OpenSSL::VERSION"`
- Verify gem installation with `gem --version`

## 📝 Advanced Configuration

### Adding Multiple Ruby Versions
```bash
# Create additional version directories
ruby3-1-0/
ruby3-2-0/
# Each with their own rpm-repo and client-setup
```

### Custom Build Modifications
```bash
# Modify Dockerfile to:
# - Change Ruby version
# - Add additional packages
# - Modify build flags
# - Include custom patches
```

### Repository Maintenance
```bash
# Periodic tasks:
# - Update Ruby versions
# - Clean old packages
# - Monitor repository size
# - Update security patches
```

## 📖 Additional Resources

### Documentation Links
- [RPM Packaging Guide](https://rpm-packaging-guide.github.io/)
- [DNF Repository Management](https://dnf.readthedocs.io/en/latest/)
- [Ruby Build Configuration](https://www.ruby-lang.org/en/documentation/installation/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

### Community Support
- **Issues**: Report problems in the GitHub Issues section
- **Discussions**: Use GitHub Discussions for questions
- **Contributions**: Pull requests welcome for improvements

## 📄 License & Legal

This project is provided as-is for building Ruby RPM packages from official sources. All built packages maintain their original licensing terms:
- Ruby: Licensed under Ruby License / BSD 2-Clause License
- OpenSSL: Licensed under Apache License 2.0
- Rocky Linux packages: Follow respective upstream licenses

## 🔄 Version History

- **v1.0**: Initial Ruby 3.0.7 build with compat-openssl11
- **v1.1**: Added automated repository generation
- **v1.2**: GitHub-hosted repository with client setup
- **Current**: Complete automated workflow with manual deployment

---

**Need Help?** Open an issue in this repository or check the troubleshooting section above.