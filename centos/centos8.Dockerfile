# Pull the Base Image
FROM centos:8.4.2105 as Base

ARG DNA_FOLDER="${DNA_FOLDER:-WebDNA-folder-8.6}"
ARG DNA_EXECUTABLE="${DNA_EXECUTABLE:-WebDNA-Linux-FastCGI-8.6.5}"
ARG APACHE_USER="${APACHE_USER:-apache}"
ARG APACHE_LOC="/etc/httpd"
ARG APACHE_CONFIG="$APACHE_LOC/conf/httpd.conf"
ARG WEBROOT="/var/www/html"
ARG WEBDNA_LOC="$WEBROOT/WebDNA"

# Set Working Directory
WORKDIR /tmp

# Copy over setup scripts
COPY ../webdna.sh ./

## Build The Container
# Perform Updates - Need to update Repo to vault first as CentOS8 is no longer supported
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* && \
    dnf --setopt=install_weak_deps=False -y install wget httpd mod_fcgid libnsl openssl unzip && \
    # Run WebDNA Setup Script
    DNA_FOLDER="$DNA_FOLDER" \
    DNA_EXECUTABLE="$DNA_EXECUTABLE" \
    WEBROOT="$WEBROOT" \
    WEBDNA_LOC="$WEBDNA_LOC" \
    APACHE_USER="$APACHE_USER" \
    APACHE_LOC="$APACHE_LOC" \
    APACHE_CONFIG="$APACHE_CONFIG" \
    ./webdna.sh && \
    rm -f ./webdna.sh && \
    # clean up after ourselves
    dnf remove -y wget unzip && \
    dnf clean all

# Fresh Image Layer
FROM scratch AS Final

# Copy Structure
COPY --from=Base / /

# Start Apache in the Foreground when the container starts
ENTRYPOINT [ "httpd", "-DFOREGROUND" ]

# Expose http and https
EXPOSE 80 443
