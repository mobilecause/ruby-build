#!/bin/bash
set -e

REPO_URL="https://raw.githubusercontent.com/USERNAME/REPOSITORY/main"

echo "Installing Ruby 3.0.7 repository..."

# Download repo config with priority=70
curl -fsSL "$REPO_URL/ruby3-0-7/client-setup/ruby-build.repo" \\
    -o "/etc/yum.repos.d/ruby-build-3-0-7.repo"

# Refresh cache
dnf clean all
dnf makecache

echo "✅ Ruby 3.0.7 repository installed with priority 70!"
echo "📦 Install Ruby: dnf install ruby compat-openssl11"
echo "🔍 Verify source: dnf info ruby"
