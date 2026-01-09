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
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Azure DevOps extension
RUN az extension add --name azure-devops

# Create non-root user
RUN useradd -m -s /bin/bash aeo3user && \
    echo "aeo3user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Clone and install cognitify using configure script with --docker flag
RUN git clone https://github.com/cognition/cognitify.git /tmp/cognitify && \
    cd /tmp/cognitify && \
    chmod +x configure && \
    ./configure --user=aeo3user --docker --skip-packages && \
    make && \
    make install && \
    rm -rf /tmp/cognitify

# Switch to non-root user
USER aeo3user
WORKDIR /home/aeo3user

# Set up environment
ENV HOME=/home/aeo3user
ENV USER=aeo3user

# Default command
CMD ["/bin/bash"]
