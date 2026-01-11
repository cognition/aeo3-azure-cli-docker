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
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Azure DevOps extension
RUN az extension add --name azure-devops

# Create non-root user
RUN useradd -m -s /bin/bash aeo3user && \
    echo "aeo3user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Clone and install cognitify using configure script with --docker flag
# Install components individually to skip post-install package installation
RUN git clone https://github.com/cognition/cognitify.git /tmp/cognitify && \
    cd /tmp/cognitify && \
    chmod +x configure && \
    ./configure --user=aeo3user --docker --skip-packages && \
    make && \
    make install-config install-completions install-home install-bin install-distro install-docs install-man install-profile-d install-skel && \
    rm -rf /tmp/cognitify

# Remove .orig backup files created by cognitify (not needed in fresh container)
RUN find /home/aeo3user -maxdepth 1 -name "*.orig" -type f -delete

# Add permission fix to bashrc (runs on shell startup)
RUN echo '' >> /home/aeo3user/.bashrc && \
    echo '# Fix permissions on mounted volumes' >> /home/aeo3user/.bashrc && \
    echo 'if [ -d /home/aeo3user/.azure ] && [ "$(stat -c %U /home/aeo3user/.azure 2>/dev/null)" != "aeo3user" ]; then' >> /home/aeo3user/.bashrc && \
    echo '    sudo chown -R aeo3user:aeo3user /home/aeo3user/.azure 2>/dev/null || true' >> /home/aeo3user/.bashrc && \
    echo '    sudo chmod -R 755 /home/aeo3user/.azure 2>/dev/null || true' >> /home/aeo3user/.bashrc && \
    echo 'fi' >> /home/aeo3user/.bashrc && \
    echo 'if [ -d /home/aeo3user/.ssh ] && [ "$(stat -c %U /home/aeo3user/.ssh 2>/dev/null)" != "aeo3user" ]; then' >> /home/aeo3user/.bashrc && \
    echo '    sudo chown -R aeo3user:aeo3user /home/aeo3user/.ssh 2>/dev/null || true' >> /home/aeo3user/.bashrc && \
    echo '    sudo chmod -R 700 /home/aeo3user/.ssh 2>/dev/null || true' >> /home/aeo3user/.bashrc && \
    echo 'fi' >> /home/aeo3user/.bashrc && \
    chown aeo3user:aeo3user /home/aeo3user/.bashrc

# Switch to non-root user
USER aeo3user
WORKDIR /home/aeo3user

# Set up environment
ENV HOME=/home/aeo3user
ENV USER=aeo3user
# Disable Azure DevOps CLI keyring to avoid warnings in Docker containers
ENV AZURE_DEVOPS_CLI_KEYRING=false

# Default command
CMD ["/bin/bash"]
