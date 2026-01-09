# Azure CLI Docker Container

An Ubuntu-based Docker container with Azure CLI, DevOps extension, Git, Vim, and cognitify bootstrap.

## Features

- **Azure CLI**: Latest version with DevOps extension
- **Development Tools**: Git and Vim installed
- **Non-root User**: Runs as `aeo3user` for security
- **Cognitify**: Linux shell customisations and dotfiles from [cognitify](https://github.com/cognition/cognitify)

## Building

```bash
docker build -t aeo3-azure-cli .
```

## Running

```bash
docker run -it aeo3-azure-cli
```

## Usage with Azure Login

To use Azure CLI with authentication, mount your Azure credentials:

```bash
docker run -it -v ~/.azure:/home/aeo3user/.azure aeo3-azure-cli
```

Or use environment variables for service principal authentication:

```bash
docker run -it \
  -e AZURE_CLIENT_ID=your-client-id \
  -e AZURE_CLIENT_SECRET=your-client-secret \
  -e AZURE_TENANT_ID=your-tenant-id \
  aeo3-azure-cli
```

## Advanced Usage with Volume Mounts

For a more persistent and integrated development environment, you can mount various directories:

### Using Named Volume for Azure Credentials

Create a named volume to persist Azure CLI credentials across container runs:

```bash
docker volume create azure-cli-volume
docker run -it \
  --name azure-cli \
  --mount source=azure-cli-volume,target=/home/aeo3user/.azure \
  aeo3-azure-cli
```

### Mounting SSH Keys

Mount your SSH directory for Git operations:

```bash
docker run -it \
  --name azure-cli \
  --mount type=bind,source="$HOME"/.ssh,target=/home/aeo3user/.ssh \
  aeo3-azure-cli
```

### Mounting Project Directories

Mount your project directories for development:

```bash
docker run -it \
  --name azure-cli \
  --mount type=bind,source=/path/to/your/project,target=/home/aeo3user/project \
  aeo3-azure-cli
```

### Complete Example with Multiple Mounts

Example with SSH keys, Azure credentials volume, and project directory:

```bash
docker run -it \
  --name azure-cli \
  --mount type=bind,source="$HOME"/.ssh,target=/home/aeo3user/.ssh \
  --mount type=bind,source=/path/to/your/project,target=/home/aeo3user/project \
  --mount source=azure-cli-volume,target=/home/aeo3user/.azure \
  aeo3-azure-cli
```

**Note**: The container runs as `aeo3user` (non-root), so mount paths should target `/home/aeo3user/` instead of `/root/`.

## Convenience Script

A shell script is provided to easily connect to a running container. Install it to your PATH:

```bash
# Copy to a directory in your PATH (e.g., ~/bin or /usr/local/bin)
cp azure-cli-docker.sh ~/bin/azure-cli-docker
chmod +x ~/bin/azure-cli-docker

# Or create a symlink
ln -s "$(pwd)/azure-cli-docker.sh" ~/bin/azure-cli-docker
```

Then simply run:

```bash
# Connect to container named 'azure-cli' (default)
azure-cli-docker

# Or specify a different container name/ID
azure-cli-docker my-container-name
```

The script will:

- Check if the container exists
- Start it if it's stopped
- Execute an interactive bash session

## Customization

The container uses cognitify for shell customisations. The cognitify installation runs during build with:

- User: `aeo3user`
- Packages: Skipped (to keep image size small)

To customize further, you can modify the Dockerfile or mount custom configurations at runtime.
