#!/usr/bin/env bash
# Azure CLI Docker Container Connection Script
# Usage: azure-cli-docker.sh [container-name-or-id]

set -euo pipefail

CONTAINER_NAME="${1:-azure-cli}"
IMAGE_NAME="aeo3-azure-cli"
AZURE_VOLUME_NAME="azure-cli-volume"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored messages
info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Check if container exists
container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

# Check if container is running
container_running() {
    docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

# Connect to existing container
connect_to_container() {
    if ! container_running; then
        info "Container '${CONTAINER_NAME}' is not running. Starting it..."
        docker start "${CONTAINER_NAME}" >/dev/null
        sleep 1
    fi
    success "Connecting to container '${CONTAINER_NAME}'..."
    exec docker exec -it "${CONTAINER_NAME}" /bin/bash
}

# Prompt for yes/no
prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    if [[ "$default" == "y" ]]; then
        read -p "${prompt} [Y/n]: " response
        response="${response:-y}"
    else
        read -p "${prompt} [y/N]: " response
        response="${response:-n}"
    fi
    
    [[ "$response" =~ ^[Yy]$ ]]
}

# Prompt for input with default
prompt_input() {
    local prompt="$1"
    local default="${2:-}"
    local response
    
    if [[ -n "$default" ]]; then
        read -p "${prompt} [${default}]: " response
        response="${response:-$default}"
    else
        read -p "${prompt}: " response
    fi
    
    echo "$response"
}

# Build docker run command with mounts
build_run_command() {
    local mounts=()
    local cmd="docker run -it --name ${CONTAINER_NAME}"
    
    # SSH keys mount
    if prompt_yes_no "Mount SSH keys from \$HOME/.ssh?" "y"; then
        if [[ -d "$HOME/.ssh" ]]; then
            mounts+=("--mount type=bind,source=$HOME/.ssh,target=/home/aeo3user/.ssh")
            info "Will mount SSH keys"
        else
            warning "SSH directory not found at $HOME/.ssh"
        fi
    fi
    
    # Azure credentials
    echo ""
    info "Azure credentials options:"
    echo "  1) Use named volume (persistent across containers)"
    echo "  2) Bind mount from \$HOME/.azure"
    echo "  3) Skip (no Azure credentials mounted)"
    local azure_choice=$(prompt_input "Choose option" "1")
    
    case "$azure_choice" in
        1)
            # Create volume if it doesn't exist
            if ! docker volume ls --format '{{.Name}}' | grep -q "^${AZURE_VOLUME_NAME}$"; then
                info "Creating Azure credentials volume '${AZURE_VOLUME_NAME}'..."
                docker volume create "${AZURE_VOLUME_NAME}" >/dev/null
            fi
            mounts+=("--mount source=${AZURE_VOLUME_NAME},target=/home/aeo3user/.azure")
            info "Will use Azure credentials volume"
            ;;
        2)
            if [[ -d "$HOME/.azure" ]]; then
                mounts+=("--mount type=bind,source=$HOME/.azure,target=/home/aeo3user/.azure")
                info "Will bind mount Azure credentials"
            else
                warning "Azure directory not found at $HOME/.azure"
            fi
            ;;
        3)
            info "Skipping Azure credentials mount"
            ;;
    esac
    
    # Project directories
    echo ""
    if prompt_yes_no "Mount a project directory?" "n"; then
        local project_path=""
        local project_valid=false
        
        while [[ "$project_valid" == false ]]; do
            project_path=$(prompt_input "Enter project directory path")
            
            if [[ -d "$project_path" ]]; then
                project_valid=true
            else
                warning "Directory not found: ${project_path}"
                if prompt_yes_no "Would you like to create this directory?" "y"; then
                    if mkdir -p "$project_path" 2>/dev/null; then
                        success "Created directory: ${project_path}"
                        project_valid=true
                    else
                        error "Failed to create directory: ${project_path}"
                        if ! prompt_yes_no "Try a different path?" "y"; then
                            info "Skipping project directory mount"
                            break
                        fi
                    fi
                else
                    if prompt_yes_no "Enter a different path?" "y"; then
                        continue
                    else
                        info "Skipping project directory mount"
                        break
                    fi
                fi
            fi
        done
        
        if [[ "$project_valid" == true ]] && [[ -n "$project_path" ]]; then
            local mount_name=$(prompt_input "Enter mount name in container (e.g., 'project', 'work')" "project")
            mounts+=("--mount type=bind,source=${project_path},target=/home/aeo3user/${mount_name}")
            info "Will mount ${project_path} to /home/aeo3user/${mount_name}"
        fi
    fi
    
    # Additional custom mounts
    echo ""
    if prompt_yes_no "Add additional custom mount?" "n"; then
        local custom_source=""
        local custom_valid=false
        
        while [[ "$custom_valid" == false ]]; do
            custom_source=$(prompt_input "Enter source path")
            
            if [[ -d "$custom_source" ]] || [[ -f "$custom_source" ]]; then
                custom_valid=true
            else
                warning "Path not found: ${custom_source}"
                # Only offer to create if it's a directory path (ends with / or no extension suggests directory)
                if [[ "$custom_source" =~ /$ ]] || [[ ! "$custom_source" =~ \.[^/]+$ ]]; then
                    if prompt_yes_no "Would you like to create this directory?" "y"; then
                        if mkdir -p "$custom_source" 2>/dev/null; then
                            success "Created directory: ${custom_source}"
                            custom_valid=true
                        else
                            error "Failed to create directory: ${custom_source}"
                            if ! prompt_yes_no "Try a different path?" "y"; then
                                info "Skipping custom mount"
                                break
                            fi
                        fi
                    else
                        if prompt_yes_no "Enter a different path?" "y"; then
                            continue
                        else
                            info "Skipping custom mount"
                            break
                        fi
                    fi
                else
                    # File path that doesn't exist
                    if prompt_yes_no "Enter a different path?" "y"; then
                        continue
                    else
                        info "Skipping custom mount"
                        break
                    fi
                fi
            fi
        done
        
        if [[ "$custom_valid" == true ]] && [[ -n "$custom_source" ]]; then
            local custom_target=$(prompt_input "Enter target path in container")
            mounts+=("--mount type=bind,source=${custom_source},target=${custom_target}")
            info "Will mount ${custom_source} to ${custom_target}"
        fi
    fi
    
    # Build final command
    for mount in "${mounts[@]}"; do
        cmd+=" ${mount}"
    done
    
    cmd+=" ${IMAGE_NAME}"
    
    echo ""
    info "Launch command:"
    echo "  ${cmd}"
    echo ""
    
    if prompt_yes_no "Launch container with these settings?" "y"; then
        eval "$cmd"
    else
        error "Launch cancelled"
        exit 1
    fi
}

# Main logic
main() {
    # Check if Docker is available
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Check if image exists
    if ! docker images --format '{{.Repository}}' | grep -q "^${IMAGE_NAME}$"; then
        error "Image '${IMAGE_NAME}' not found."
        echo ""
        info "Please build the image first:"
        echo "  docker build -t ${IMAGE_NAME} ."
        exit 1
    fi
    
    # If container exists, connect to it
    if container_exists; then
        connect_to_container
    else
        # Container doesn't exist, offer to create it
        warning "Container '${CONTAINER_NAME}' does not exist."
        echo ""
        info "Available options:"
        echo "  1) Launch new container with interactive setup"
        echo "  2) Launch new container with default settings (no mounts)"
        echo "  3) Exit"
        echo ""
        
        local choice=$(prompt_input "Choose option" "1")
        
        case "$choice" in
            1)
                build_run_command
                ;;
            2)
                info "Launching container with default settings..."
                docker run -it --name "${CONTAINER_NAME}" "${IMAGE_NAME}"
                ;;
            3)
                info "Exiting..."
                exit 0
                ;;
            *)
                error "Invalid choice"
                exit 1
                ;;
        esac
    fi
}

main "$@"
