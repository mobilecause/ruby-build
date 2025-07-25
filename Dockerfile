FROM amazonlinux:latest

# Update system and install development tools
RUN dnf update -y && \
    dnf groupinstall -y "Development Tools" && \
    dnf install -y --allowerasing \
        rpm-build \
        rpm-devel \
        rpmdevtools \
        wget \
        perl \
        readline-devel \
        libffi-devel \
        libyaml-devel \
        zlib-devel \
        gdbm-devel \
        ncurses-devel \
        tk-devel \
        sqlite-devel \
        pcre-devel \
        libxml2-devel \
        libxslt-devel \
        expat-devel \
        libdb-devel \
        cmake \
        gmp-devel \
        hostname \
        procps-ng \
        'dnf-command(builddep)' \
        dnf-plugins-core

# Create build user and setup RPM build environment
RUN useradd -m builder && \
    su - builder -c "rpmdev-setuptree"

# Set environment variables for compat-openssl11
ENV PKG_CONFIG_PATH="/usr/lib64/openssl11/pkgconfig"
ENV CPPFLAGS="-I/usr/include/openssl11"

# Switch to builder user
USER builder
WORKDIR /home/builder

# Download and install Ruby source RPM
RUN wget https://dl.rockylinux.org/pub/rocky/9/devel/source/tree/Packages/r/ruby-3.0.7-165.el9_5.src.rpm && \
    rpm -ivh ruby-3.0.7-165.el9_5.src.rpm

# Download and install compat-openssl11 source RPM in builder's rpmbuild
RUN wget https://pkgs.sysadmins.ws/el9/extras/SRPMS/compat-openssl11-1.1.1k-5.el9.src.rpm && \
    rpm -ivh compat-openssl11-1.1.1k-5.el9.src.rpm

# Install compat-openssl11 build dependencies as root
USER root
RUN cd /home/builder && \
    dnf builddep -y rpmbuild/SPECS/compat-openssl11.spec

# Build compat-openssl11 packages as builder user
USER builder
RUN rpmbuild -bb --nocheck rpmbuild/SPECS/compat-openssl11.spec

# Install built compat-openssl11 packages as root
USER root
RUN echo "=== Installing built compat-openssl11 packages ===" && \
    rpm -ivh /home/builder/rpmbuild/RPMS/*/compat-openssl11-*.rpm && \
    echo "=== Verifying compat-openssl11 installation ===" && \
    ls -la /usr/lib64/openssl11/ && \
    ls -la /usr/include/openssl11/

# Modify Ruby spec file to use compat-openssl11 and add FIPS patch
USER builder
RUN cd /home/builder && \
    cp rpmbuild/SPECS/ruby.spec rpmbuild/SPECS/ruby.spec.bak && \
    sed -i 's|%configure|%configure --with-openssl-dir=%{_includedir}/openssl11 --with-openssl-lib=%{_libdir}/openssl11 --with-openssl-include=%{_includedir}/openssl11|' rpmbuild/SPECS/ruby.spec && \
    sed -i '/BuildRequires:.*multilib-rpm-config/d' rpmbuild/SPECS/ruby.spec && \
    sed -i 's/BuildRequires:.*openssl-devel/BuildRequires: compat-openssl11-devel/' rpmbuild/SPECS/ruby.spec && \
    sed -i 's|%multilib_fix_c_header.*||g' rpmbuild/SPECS/ruby.spec && \
    sed -i '/^%build/a\\n# Fix OPENSSL_FIPS preprocessor syntax\nfind . -name "ossl.c" -exec sed -i "s/#elif OPENSSL_FIPS/#elif defined(OPENSSL_FIPS)/g" {} \\;' rpmbuild/SPECS/ruby.spec && \
    sed -i 's/%bcond_without rubypick/%bcond_with rubypick/' rpmbuild/SPECS/ruby.spec

# Create FIPS fix patch and add to Ruby spec
# RUN cd /home/builder && \
#     echo "=== Creating FIPS preprocessor fix patch ===" && \
#     echo "--- a/ext/openssl/ossl.c" > rpmbuild/SOURCES/ruby-openssl-fips-fix.patch && \
#     echo "+++ b/ext/openssl/ossl.c" >> rpmbuild/SOURCES/ruby-openssl-fips-fix.patch && \
#     echo "@@ -409,7 +409,7 @@" >> rpmbuild/SOURCES/ruby-openssl-fips-fix.patch && \
#     echo " #ifdef OPENSSL_FIPS" >> rpmbuild/SOURCES/ruby-openssl-fips-fix.patch && \
#     echo "     rb_define_const(mOSSL, \"OPENSSL_FIPS\", Qtrue);" >> rpmbuild/SOURCES/ruby-openssl-fips-fix.patch && \
#     echo "-#elif OPENSSL_FIPS" >> rpmbuild/SOURCES/ruby-openssl-fips-fix.patch && \
#     echo "+#elif defined(OPENSSL_FIPS)" >> rpmbuild/SOURCES/ruby-openssl-fips-fix.patch && \
#     echo "     rb_define_const(mOSSL, \"OPENSSL_FIPS\", Qfalse);" >> rpmbuild/SOURCES/ruby-openssl-fips-fix.patch && \
#     echo " #else" >> rpmbuild/SOURCES/ruby-openssl-fips-fix.patch && \
#     echo "     rb_define_const(mOSSL, \"OPENSSL_FIPS\", Qfalse);" >> rpmbuild/SOURCES/ruby-openssl-fips-fix.patch

# Add patch to spec file
# RUN cd /home/builder && \
#     echo "=== Adding FIPS patch to Ruby spec file ===" && \
#     sed -i '/^Source[0-9]*:/a Patch1000: ruby-openssl-fips-fix.patch' rpmbuild/SPECS/ruby.spec && \
#     sed -i '/^%prep/a %patch1000 -p1' rpmbuild/SPECS/ruby.spec

# Install additional build dependencies and create missing tools
USER root
RUN dnf install -y --allowerasing checksec || true
RUN if [ ! -f /usr/bin/multilib-rpm-config ]; then \
        echo '#!/bin/bash' > /usr/bin/multilib-rpm-config && \
        echo 'echo "multilib-rpm-config: skipped for container build"' >> /usr/bin/multilib-rpm-config && \
        chmod +x /usr/bin/multilib-rpm-config; \
    fi

# Install Ruby build dependencies
RUN cd /home/builder && \
    dnf builddep -y rpmbuild/SPECS/ruby.spec || \
    (grep "BuildRequires:" rpmbuild/SPECS/ruby.spec | sed 's/BuildRequires://g' | sed 's/,/ /g' | xargs dnf install -y --allowerasing || true)

# Build Ruby RPM with compat-openssl11
USER builder
RUN echo "=== Building Ruby with compat-openssl11 ===" && \
    PKG_CONFIG_PATH="/usr/lib64/openssl11/pkgconfig" \
    LDFLAGS="-L/usr/lib64/openssl11" \
    CPPFLAGS="-I/usr/include/openssl11" \
    CFLAGS="-I/usr/include/openssl11" \
    rpmbuild -bb --nocheck rpmbuild/SPECS/ruby.spec

# Create unified output directory with all RPMs
RUN echo "=== Creating unified output directory ===" && \
    mkdir -p /home/builder/output && \
    echo "=== Copying all built RPMs to output directory ===" && \
    find rpmbuild/RPMS -name "*.rpm" -exec cp {} /home/builder/output/ \; && \
    echo "=== Final RPM inventory ===" && \
    ls -la /home/builder/output/ && \
    echo "=== RPM details ===" && \
    for rpm in /home/builder/output/*.rpm; do \
        echo "=== $(basename $rpm) ==="; \
        rpm -qp --info "$rpm" 2>/dev/null || echo "Could not read RPM info"; \
        echo ""; \
    done

# Test RPM installation with compat-openssl11 packages
USER root
RUN echo "=== Testing RPM installation ===" && \
    dnf remove -y ruby* rubygems* --skip-broken || true && \
    dnf clean all && \
    echo "=== Installing compat-openssl11 and Ruby packages ===" && \
    rpm -ivh --force /home/builder/output/compat-openssl11-*.rpm && \
    echo "=== Testing compat-openssl11 installation ===" && \
    ls -la /usr/lib64/openssl11/ && \
    ls -la /usr/include/openssl11/ && \
    echo "=== Installing Ruby packages ===" && \
    rpm -ivh --force --nodeps /home/builder/output/ruby-libs-*.rpm && \
    rpm -ivh --force --nodeps /home/builder/output/ruby-3.0.7-*.rpm && \
    echo "=== Testing Ruby binary location ===" && \
    ls -la /usr/bin/ruby* && \
    echo "=== Testing Ruby functionality ===" && \
    ruby --version && \
    echo "=== All tests passed! ==="

# Create complete ruby3-0-7 repository structure
USER builder
RUN echo "=== Creating ruby3-0-7 repository structure ===" && \
    mkdir -p /home/builder/ruby3-0-7/rpm-repo/x86_64 && \
    mkdir -p /home/builder/ruby3-0-7/client-setup && \
    echo "=== Copying x86_64 and noarch RPM packages ===" && \
    find /home/builder/output -name '*x86_64.rpm' -exec cp {} /home/builder/ruby3-0-7/rpm-repo/x86_64/ \; 2>/dev/null || true && \
    find /home/builder/output -name '*noarch.rpm' -exec cp {} /home/builder/ruby3-0-7/rpm-repo/x86_64/ \; 2>/dev/null || true

# Switch to root to install createrepo_c
USER root
RUN echo "=== Installing createrepo_c ===" && \
    dnf install -y createrepo_c

# Switch back to builder and continue repository creation
USER builder
RUN echo "=== Generating repository metadata ===" && \
    createrepo_c /home/builder/ruby3-0-7/rpm-repo/x86_64/ && \
    echo "=== Creating client setup files ===" && \
    echo '[ruby-build-3-0-7]' > /home/builder/ruby3-0-7/client-setup/ruby-build.repo && \
    echo 'name=Ruby 3.0.7 Build Repository' >> /home/builder/ruby3-0-7/client-setup/ruby-build.repo && \
    echo 'baseurl=https://raw.githubusercontent.com/mobilecause/ruby-build/main/ruby3-0-7/rpm-repo/x86_64/' >> /home/builder/ruby3-0-7/client-setup/ruby-build.repo && \
    echo 'enabled=1' >> /home/builder/ruby3-0-7/client-setup/ruby-build.repo && \
    echo 'gpgcheck=0' >> /home/builder/ruby3-0-7/client-setup/ruby-build.repo && \
    echo 'metadata_expire=300' >> /home/builder/ruby3-0-7/client-setup/ruby-build.repo && \
    echo 'priority=9' >> /home/builder/ruby3-0-7/client-setup/ruby-build.repo && \
    echo "=== Creating installation script ===" && \
    echo '#!/bin/bash' > /home/builder/ruby3-0-7/client-setup/install.sh && \
    echo 'set -e' >> /home/builder/ruby3-0-7/client-setup/install.sh && \
    echo '' >> /home/builder/ruby3-0-7/client-setup/install.sh && \
    echo 'REPO_URL="https://raw.githubusercontent.com/USERNAME/REPOSITORY/main"' >> /home/builder/ruby3-0-7/client-setup/install.sh && \
    echo '' >> /home/builder/ruby3-0-7/client-setup/install.sh && \
    echo 'echo "Installing Ruby 3.0.7 repository..."' >> /home/builder/ruby3-0-7/client-setup/install.sh && \
    echo '' >> /home/builder/ruby3-0-7/client-setup/install.sh && \
    echo '# Download repo config with priority=9' >> /home/builder/ruby3-0-7/client-setup/install.sh && \
    echo 'curl -fsSL "$REPO_URL/ruby3-0-7/client-setup/ruby-build.repo" \\' >> /home/builder/ruby3-0-7/client-setup/install.sh && \
    echo '    -o "/etc/yum.repos.d/ruby-build-3-0-7.repo"' >> /home/builder/ruby3-0-7/client-setup/install.sh && \
    echo '' >> /home/builder/ruby3-0-7/client-setup/install.sh && \
    echo '# Refresh cache' >> /home/builder/ruby3-0-7/client-setup/install.sh && \
    echo 'dnf clean all' >> /home/builder/ruby3-0-7/client-setup/install.sh && \
    echo 'dnf makecache' >> /home/builder/ruby3-0-7/client-setup/install.sh && \
    echo '' >> /home/builder/ruby3-0-7/client-setup/install.sh && \
    echo 'echo "✅ Ruby 3.0.7 repository installed with priority 9!"' >> /home/builder/ruby3-0-7/client-setup/install.sh && \
    echo 'echo "📦 Install Ruby: dnf install ruby compat-openssl11"' >> /home/builder/ruby3-0-7/client-setup/install.sh && \
    echo 'echo "🔍 Verify source: dnf info ruby"' >> /home/builder/ruby3-0-7/client-setup/install.sh && \
    chmod +x /home/builder/ruby3-0-7/client-setup/install.sh && \
    echo "=== Complete ruby3-0-7 structure ===" && \
    find /home/builder/ruby3-0-7 -type f | sort && \
    echo "=== Repository metadata verification ===" && \
    ls -la /home/builder/ruby3-0-7/rpm-repo/x86_64/repodata/ && \
    echo "=== Client setup files ===" && \
    ls -la /home/builder/ruby3-0-7/client-setup/

CMD ["/bin/bash"]