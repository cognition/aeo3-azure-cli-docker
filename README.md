# Azure CLI Docker Container

An Ubuntu-based Docker container with Azure CLI, DevOps extension, Git, Vim, and cognitify bootstrap.

## Features

- **Azure CLI**: Latest version with DevOps extension
- **Development Tools**: Git and Vim installed
- **Non-root User**: Runs as `ubuntu` for security
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
docker run -it -v ~/.azure:/home/ubuntu/.azure aeo3-azure-cli
```

Or use environment variables for service principal authentication:

```bash
docker run -it \
  -e AZURE_CLIENT_ID=your-client-id \
  -e AZURE_CLIENT_SECRET=your-client-secret \
  -e AZURE_TENANT_ID=your-tenant-id \
  aeo3-azure-cli
```

### Setting Azure DevOps Organization

You can set the Azure DevOps organization URL as an environment variable:

```bash
docker run -it \
  -e AZURE_DEVOPS_ORG_URL=https://dev.azure.com/your-org \
  aeo3-azure-cli
```

Or just provide the organization name (the script will automatically format it):

```bash
docker run -it \
  -e AZURE_DEVOPS_ORG_URL=your-org \
  aeo3-azure-cli
```

**Note:** When using the interactive launch script (`azure-cli-docker.sh`), you'll be prompted to set the organization URL during container setup.

## Advanced Usage with Volume Mounts

For a more persistent and integrated development environment, you can mount various directories:

### Using Named Volume for Azure Credentials

Create a named volume to persist Azure CLI credentials across container runs:

```bash
docker volume create azure-cli-volume
docker run -it \
  --name azure-cli \
  --mount source=azure-cli-volume,target=/home/ubuntu/.azure \
  aeo3-azure-cli
```

### Mounting SSH Keys

Mount your SSH directory for Git operations:

```bash
docker run -it \
  --name azure-cli \
  --mount type=bind,source="$HOME"/.ssh,target=/home/ubuntu/.ssh \
  aeo3-azure-cli
```

### Mounting Project Directories

Mount your project directories for development:

```bash
docker run -it \
  --name azure-cli \
  --mount type=bind,source=/path/to/your/project,target=/home/ubuntu/project \
  aeo3-azure-cli
```

### Complete Example with Multiple Mounts

Example with SSH keys, Azure credentials volume, and project directory:

```bash
docker run -it \
  --name azure-cli \
  --mount type=bind,source="$HOME"/.ssh,target=/home/ubuntu/.ssh \
  --mount type=bind,source=/path/to/your/project,target=/home/ubuntu/project \
  --mount source=azure-cli-volume,target=/home/ubuntu/.azure \
  aeo3-azure-cli
```

**Note**: The container runs as `ubuntu` (non-root), so mount paths should target `/home/ubuntu/` instead of `/root/`.

## Convenience Script

An interactive shell script is provided to easily connect to or launch containers. **Install it to your PATH for easy access:**

### Installation

**Option 1: Copy to ~/bin (recommended for user-specific installation)**

```bash
# Create ~/bin directory if it doesn't exist
mkdir -p ~/bin

# Copy the script
cp azure-cli-docker.sh ~/bin/azure-cli-docker
chmod +x ~/bin/azure-cli-docker

# Ensure ~/bin is in your PATH (add to ~/.bashrc or ~/.profile if needed)
export PATH="$HOME/bin:$PATH"
```

**Option 2: Create a symlink**

```bash
# Create ~/bin directory if it doesn't exist
mkdir -p ~/bin

# Create symlink
ln -s "$(pwd)/azure-cli-docker.sh" ~/bin/azure-cli-docker

# Ensure ~/bin is in your PATH
export PATH="$HOME/bin:$PATH"
```

**Option 3: System-wide installation (requires sudo)**

```bash
# Copy to /usr/local/bin for system-wide access
sudo cp azure-cli-docker.sh /usr/local/bin/azure-cli-docker
sudo chmod +x /usr/local/bin/azure-cli-docker
```

**Note:** After installation, you may need to restart your terminal or run `source ~/.bashrc` for the PATH changes to take effect.

### Usage

**If container exists:**

```bash
# Connect to container named 'azure-cli' (default)
azure-cli-docker

# Or specify a different container name/ID
azure-cli-docker my-container-name
```

The script will automatically start the container if it's stopped and connect you to an interactive bash session.

**If container doesn't exist:**
The script will offer interactive options to launch a new container:

1. **Interactive setup** - Prompts for:
   - SSH keys mount (from `$HOME/.ssh`)
   - Azure credentials (named volume, bind mount, or skip)
   - Project directory mounts
   - Custom additional mounts

2. **Default launch** - Launches container with no mounts

3. **Exit** - Cancel the operation

### Interactive Setup Example

When launching a new container, you'll be prompted:

```text
[WARNING] Container 'azure-cli' does not exist.

[INFO] Available options:
  1) Launch new container with interactive setup
  2) Launch new container with default settings (no mounts)
  3) Exit

Choose option [1]: 1

Mount SSH keys from $HOME/.ssh? [Y/n]: y
[INFO] Will mount SSH keys

[INFO] Azure credentials options:
  1) Use named volume (persistent across containers)
  2) Bind mount from $HOME/.azure
  3) Skip (no Azure credentials mounted)
Choose option [1]: 1
[INFO] Will use Azure credentials volume

Mount a project directory? [y/N]: y
Enter project directory path: /home/user/myproject
Enter mount name in container (e.g., 'project', 'work') [project]: work
[INFO] Will mount /home/user/myproject to /home/ubuntu/work

[INFO] Launch command:
  docker run -it --name azure-cli --mount type=bind,source=/home/user/.ssh,target=/home/ubuntu/.ssh --mount source=azure-cli-volume,target=/home/ubuntu/.azure --mount type=bind,source=/home/user/myproject,target=/home/ubuntu/work aeo3-azure-cli

Launch container with these settings? [Y/n]: y
```

### Script Features

The script provides:

- **Automatic container detection** - Checks if container exists
- **Auto-start** - Starts stopped containers automatically
- **Interactive setup** - Guided prompts for mount configuration
- **Flexible mounts** - SSH keys, Azure credentials (volume or bind), project directories, custom mounts
- **Colored output** - Easy-to-read status messages
- **Error handling** - Validates paths and Docker availability

## Customization

The container uses cognitify for shell customisations. The cognitify installation runs during build with:

- User: `ubuntu`
- Packages: Skipped (to keep image size small)

To customize further, you can modify the Dockerfile or mount custom configurations at runtime.
