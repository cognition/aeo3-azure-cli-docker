FROM ubuntu:latest

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV AZURE_CLI_VERSION=latest

# Install prerequisites and tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    lsb-release \
    gnupg \
    git \
    vim \
    sudo \
    make \
    bash \
    bash-completion \
    ssh \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Azure DevOps extension
RUN az extension add --name azure-devops

# Create non-root user
RUN useradd -m -s /bin/bash ubuntu && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Clone and install cognitify using configure script with --docker flag
# Install components individually to skip post-install package installation
RUN git clone https://github.com/cognition/cognitify.git /tmp/cognitify && \
    cd /tmp/cognitify && \
    chmod +x configure && \
    ./configure --user=ubuntu --docker --skip-packages && \
    make && \
    make install-config install-completions install-home install-bin install-distro install-docs install-man install-profile-d install-skel && \
    rm -rf /tmp/cognitify

# Remove .orig backup files created by cognitify (not needed in fresh container)
RUN find /home/ubuntu -maxdepth 1 -name "*.orig" -type f -delete

# Add permission fix and organization env setup to bashrc (runs on shell startup)
RUN echo '' >> /home/ubuntu/.bashrc && \
    echo '# Fix permissions on mounted volumes' >> /home/ubuntu/.bashrc && \
    echo 'if [ -d /home/ubuntu/.azure ] && [ "$(stat -c %U /home/ubuntu/.azure 2>/dev/null)" != "ubuntu" ]; then' >> /home/ubuntu/.bashrc && \
    echo '    sudo chown -R ubuntu:ubuntu /home/ubuntu/.azure 2>/dev/null || true' >> /home/ubuntu/.bashrc && \
    echo '    sudo chmod -R 755 /home/ubuntu/.azure 2>/dev/null || true' >> /home/ubuntu/.bashrc && \
    echo 'fi' >> /home/ubuntu/.bashrc && \
    echo 'if [ -d /home/ubuntu/.ssh ] && [ "$(stat -c %U /home/ubuntu/.ssh 2>/dev/null)" != "ubuntu" ]; then' >> /home/ubuntu/.bashrc && \
    echo '    sudo chown -R ubuntu:ubuntu /home/ubuntu/.ssh 2>/dev/null || true' >> /home/ubuntu/.bashrc && \
    echo '    sudo chmod -R 700 /home/ubuntu/.ssh 2>/dev/null || true' >> /home/ubuntu/.bashrc && \
    echo 'fi' >> /home/ubuntu/.bashrc && \
    echo '' >> /home/ubuntu/.bashrc && \
    echo '# Set Azure DevOps organization from environment if provided' >> /home/ubuntu/.bashrc && \
    echo 'if [ -n "${AZURE_DEVOPS_ORG_URL:-}" ]; then' >> /home/ubuntu/.bashrc && \
    echo '    export AZURE_DEVOPS_ORG_URL' >> /home/ubuntu/.bashrc && \
    echo 'fi' >> /home/ubuntu/.bashrc && \
    chown ubuntu:ubuntu /home/ubuntu/.bashrc

# Switch to non-root user
USER ubuntu
WORKDIR /home/ubuntu

# Set up environment
ENV HOME=/home/ubuntu
ENV USER=ubuntu
# Disable Azure DevOps CLI keyring to avoid warnings in Docker containers
ENV AZURE_DEVOPS_CLI_KEYRING=false

# Default command
CMD ["/bin/bash"]
