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

## Customization

The container uses cognitify for shell customisations. The cognitify installation runs during build with:
- User: `aeo3user`
- Packages: Skipped (to keep image size small)

To customize further, you can modify the Dockerfile or mount custom configurations at runtime.
