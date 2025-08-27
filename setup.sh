#!/bin/bash

# Docker Container Manager
# Unified management tool for FSI, ParaView, and PyTorch containers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Container definitions - easily extensible
# Format: "image:tag|directory|description|size|container_patterns|start_command|port"
declare -A CONTAINERS=(
    ["fsi"]="fsi:latest|fsi|FSI Container (OpenFOAM + CalculiX + preCICE)|5.2GB|fsi-*|interactive|"
    ["paraview"]="paraview:latest|paraview|ParaView Visualization Server|2.6GB|paraview-server|daemon|11111"
    ["pytorch"]="pytorch_jupyter:latest|pytorch_jupyter|PyTorch Jupyter Environment|7.9GB|pytorch-jupyter|daemon|8989"
)

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}$1${NC}"
}

print_cmd() {
    echo -e "${CYAN}$1${NC}"
}

# Parse container info
get_container_info() {
    local container_key=$1
    local info_type=$2
    
    if [[ -z "${CONTAINERS[$container_key]}" ]]; then
        echo "Unknown container: $container_key"
        return 1
    fi
    
    local info="${CONTAINERS[$container_key]}"
    case $info_type in
        "image") echo "$(echo "$info" | cut -d'|' -f1)" ;;
        "dir") echo "$(echo "$info" | cut -d'|' -f2)" ;;
        "desc") echo "$(echo "$info" | cut -d'|' -f3)" ;;
        "size") echo "$(echo "$info" | cut -d'|' -f4)" ;;
        "patterns") echo "$(echo "$info" | cut -d'|' -f5)" ;;
        "type") echo "$(echo "$info" | cut -d'|' -f6)" ;;
        "port") echo "$(echo "$info" | cut -d'|' -f7)" ;;
        *) echo "$info" ;;
    esac
}

# Function to check if Docker is installed and running
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
}

# Check if container image exists
image_exists() {
    local image_name=$1
    docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image_name}$"
}

# Check if container is running
is_container_running() {
    local container_name=$1
    docker ps --format "{{.Names}}" | grep -q "^${container_name}$"
}

# Function to build a Docker image
build_container() {
    local container_key=$1
    local image_name=$(get_container_info "$container_key" "image")
    local dockerfile_dir=$(get_container_info "$container_key" "dir")
    local description=$(get_container_info "$container_key" "desc")
    
    print_status "Building $description..."
    
    if [ ! -d "$dockerfile_dir" ]; then
        print_error "Directory $dockerfile_dir does not exist"
        return 1
    fi
    
    cd "$dockerfile_dir"
    
    if docker build -t "$image_name" . 2>&1 | tee "/tmp/build_${container_key}.log"; then
        print_success "$description built successfully"
        return 0
    else
        print_error "Failed to build $description"
        print_error "Check log: /tmp/build_${container_key}.log"
        return 1
    fi
    
    cd - > /dev/null
}

# Test container functionality
test_container_functionality() {
    local container_key=$1
    local image_name=$(get_container_info "$container_key" "image")
    local description=$(get_container_info "$container_key" "desc")
    
    print_status "Testing $description..."
    
    case $container_key in
        "fsi")
            if docker run --rm "$image_name" bash -c "/root/calculix-adapter-master/bin/ccx_preCICE -v" 2>&1 | grep -q "Version"; then
                print_success "✓ CalculiX with preCICE"
            else
                print_warning "✗ CalculiX test failed"
                return 1
            fi
            if docker run --rm "$image_name" bash -c "source /usr/lib/openfoam/openfoam2406/etc/bashrc && which icoFoam" > /dev/null 2>&1; then
                print_success "✓ OpenFOAM environment"
            else
                print_warning "✗ OpenFOAM test failed"
                return 1
            fi
            ;;
        "paraview")
            if docker run --rm "$image_name" bash -c "pvserver --version" > /dev/null 2>&1; then
                print_success "✓ ParaView server"
            else
                print_warning "✗ ParaView test failed"
                return 1
            fi
            ;;
        "pytorch")
            if docker run --rm "$image_name" python -c "import torch; print(f'PyTorch {torch.__version__} OK')" > /dev/null 2>&1; then
                print_success "✓ PyTorch functionality"
            else
                print_warning "✗ PyTorch test failed"
                return 1
            fi
            ;;
    esac
    
    return 0
}

# Display system information
show_system_info() {
    echo
    print_header "System Information"
    echo "  Docker: $(docker --version 2>/dev/null || echo 'Not installed')"
    echo "  Disk Space: $(df -h . | awk 'NR==2{print $4}') available"
    echo "  Memory: $(free -h | awk 'NR==2{print $7}') available"
    echo "  CPU Cores: $(nproc)"
    echo
}

# Show container status
show_status() {
    echo
    print_header "Container Status"
    printf "%-12s %-8s %-8s %-50s\n" "Container" "Built" "Running" "Description"
    printf "%-12s %-8s %-8s %-50s\n" "----------" "-----" "-------" "-----------"
    
    for container_key in "${!CONTAINERS[@]}"; do
        local image_name=$(get_container_info "$container_key" "image")
        local description=$(get_container_info "$container_key" "desc")
        local size=$(get_container_info "$container_key" "size")
        
        local built="No"
        local running="No"
        
        if image_exists "$image_name"; then
            built="Yes"
        fi
        
        # Check if container is running using patterns
        local container_patterns=$(get_container_info "$container_key" "patterns")
        local container_type=$(get_container_info "$container_key" "type")
        
        if [[ "$container_type" == "daemon" ]]; then
            # For daemon containers, check the specific named container
            if is_container_running "$container_patterns"; then
                running="Yes"
            fi
        else
            # For interactive containers, check for any matching pattern
            if docker ps --format "{{.Names}}" | grep -q "^${container_key}-[0-9]*$"; then
                running="Yes"
            fi
        fi
        
        printf "%-12s %-8s %-8s %-50s\n" "$container_key" "$built" "$running" "$description ($size)"
    done
    echo
}

# Show usage information
show_usage() {
    echo
    print_header "Docker Container Manager"
    echo "Usage: $0 <command> [container]"
    echo
    echo "Commands:"
    echo "  install <container|all>  - Install/build container(s)"
    echo "  status                   - Show status of all containers"
    echo "  test <container|all>     - Test container functionality"
    echo "  start <container>        - Start container service"
    echo "  stop <container>         - Stop container service"
    echo "  restart <container>      - Restart container service"
    echo "  update <container|all>   - Update/rebuild container(s)"
    echo "  repair <container|all>   - Repair/rebuild container(s)"
    echo "  remove <container|all>   - Remove only container and its image"
    echo "  logs <container>         - Show container logs"
    echo "  shell <container>        - Open interactive shell"
    echo "  info                     - Show system information"
    echo "  help                     - Show this help message"
    echo
    echo "Available containers: $(echo "${!CONTAINERS[@]}" | tr ' ' ', ')"
    echo
    echo "Examples:"
    print_cmd "  $0 install fsi          # Install FSI container only"
    print_cmd "  $0 install all          # Install all containers"
    print_cmd "  $0 status               # Show container status"
    print_cmd "  $0 test pytorch         # Test PyTorch container"
    print_cmd "  $0 start paraview       # Start ParaView server"
    echo
}

# Install containers
install_containers() {
    local containers_to_install=()
    
    if [[ "$1" == "all" ]]; then
        containers_to_install=("${!CONTAINERS[@]}")
    else
        if [[ -z "${CONTAINERS[$1]}" ]]; then
            print_error "Unknown container: $1"
            print_status "Available containers: ${!CONTAINERS[@]}"
            exit 1
        fi
        containers_to_install=("$1")
    fi
    
    check_docker
    
    # Calculate total size
    local total_size=0
    for container_key in "${containers_to_install[@]}"; do
        local size=$(get_container_info "$container_key" "size" | grep -o '[0-9.]*')
        total_size=$(echo "$total_size + $size" | bc 2>/dev/null || echo "?")
    done
    
    echo
    print_header "Installing Containers"
    for container_key in "${containers_to_install[@]}"; do
        local desc=$(get_container_info "$container_key" "desc")
        local size=$(get_container_info "$container_key" "size")
        echo "  - $desc ($size)"
    done
    echo "  Total estimated size: ~${total_size}GB"
    echo
    
    read -p "Continue with installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled"
        exit 0
    fi
    
    # Get script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cd "$SCRIPT_DIR"
    
    # Build containers
    local success_count=0
    for container_key in "${containers_to_install[@]}"; do
        echo
        if build_container "$container_key"; then
            if test_container_functionality "$container_key"; then
                ((success_count++))
            fi
        fi
    done
    
    echo
    print_header "Installation Summary"
    if [[ $success_count -eq ${#containers_to_install[@]} ]]; then
        print_success "All containers installed successfully!"
    else
        print_warning "$success_count/${#containers_to_install[@]} containers installed successfully"
    fi
}

# Start container service - generalized
start_container() {
    local container_key=$1
    local image_name=$(get_container_info "$container_key" "image")
    local container_patterns=$(get_container_info "$container_key" "patterns")
    local container_type=$(get_container_info "$container_key" "type")
    local port=$(get_container_info "$container_key" "port")
    
    if ! image_exists "$image_name"; then
        print_error "Container $container_key not installed. Run: $0 install $container_key"
        exit 1
    fi
    
    if [[ "$container_type" == "daemon" ]]; then
        # For daemon containers, use the pattern as the container name
        local container_name="$container_patterns"
        if is_container_running "$container_name"; then
            print_warning "$container_key server is already running"
        else
            if [[ -n "$port" ]]; then
                docker run -d --name "$container_name" -p "$port:$port" "$image_name"
                print_success "$container_key server started on port $port"
                if [[ "$container_key" == "pytorch" ]]; then
                    print_status "Access at: http://localhost:$port"
                fi
            else
                docker run -d --name "$container_name" "$image_name"
                print_success "$container_key server started"
            fi
        fi
    else
        # For interactive containers, create with timestamp
        print_status "Starting interactive $container_key session..."
        local container_name="${container_key}-$(date +%s)"
        docker run -it --name "$container_name" "$image_name"
    fi
}

# Stop container service - generalized
stop_container() {
    local container_key=$1
    local container_patterns=$(get_container_info "$container_key" "patterns")
    local container_type=$(get_container_info "$container_key" "type")
    
    if [[ "$container_type" == "daemon" ]]; then
        # For daemon containers, stop the named container
        local container_name="$container_patterns"
        if is_container_running "$container_name"; then
            docker stop "$container_name" && docker rm "$container_name"
            print_success "$container_key server stopped"
        else
            print_warning "$container_key server is not running"
        fi
    else
        print_error "Cannot stop $container_key (interactive container type)"
        print_status "Interactive containers exit automatically when the session ends"
    fi
}

# Remove only the specific containers and image created by this script - generalized
remove_containers() {
    local containers_to_remove=()
    
    if [[ "$1" == "all" ]]; then
        containers_to_remove=("${!CONTAINERS[@]}")
    else
        if [[ -z "${CONTAINERS[$1]}" ]]; then
            print_error "Unknown container: $1"
            exit 1
        fi
        containers_to_remove=("$1")
    fi
    
    echo
    print_warning "This will remove ONLY the specific containers and images created by this script:"
    echo
    
    # Show exactly what will be removed
    for container_key in "${containers_to_remove[@]}"; do
        local image_name=$(get_container_info "$container_key" "image")
        local description=$(get_container_info "$container_key" "desc")
        local container_patterns=$(get_container_info "$container_key" "patterns")
        local container_type=$(get_container_info "$container_key" "type")
        
        echo "  - $container_key: $description"
        
        # Show specific containers that will be removed based on patterns
        if [[ "$container_type" == "daemon" ]]; then
            # For daemon containers, check the specific named container
            if docker ps -a --format "{{.Names}}" | grep -q "^${container_patterns}$"; then
                echo "    Container: $container_patterns"
            fi
        else
            # For interactive containers, find all matching pattern containers
            local matching_containers=$(docker ps -a --format "{{.Names}}" | grep "^${container_key}-[0-9]*$" || true)
            if [[ -n "$matching_containers" ]]; then
                echo "    Containers: $matching_containers"
            fi
        fi
        
        if image_exists "$image_name"; then
            echo "    Image: $image_name"
        fi
    done
    
    echo
    print_status "Note: Only containers created by this script will be removed."
    print_status "NO volumes, networks, or other Docker resources will be touched."
    echo
    
    read -p "Continue with targeted removal? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Removal cancelled"
        exit 0
    fi
    
    local total_removed=0
    
    for container_key in "${containers_to_remove[@]}"; do
        local image_name=$(get_container_info "$container_key" "image")
        local container_patterns=$(get_container_info "$container_key" "patterns")
        local container_type=$(get_container_info "$container_key" "type")
        
        print_status "Removing resources for $container_key..."
        
        # Remove containers based on type and patterns
        if [[ "$container_type" == "daemon" ]]; then
            # For daemon containers, remove the specific named container
            if docker ps -a --format "{{.Names}}" | grep -q "^${container_patterns}$"; then
                print_status "  Removing container: $container_patterns"
                docker stop "$container_patterns" 2>/dev/null || true
                docker rm "$container_patterns" 2>/dev/null || true
                ((total_removed++))
            fi
        else
            # For interactive containers, remove all matching pattern containers
            local matching_containers=$(docker ps -a --format "{{.Names}}" | grep "^${container_key}-[0-9]*$" || true)
            if [[ -n "$matching_containers" ]]; then
                echo "$matching_containers" | while read -r container_name; do
                    if [[ -n "$container_name" ]]; then
                        print_status "  Removing container: $container_name"
                        docker stop "$container_name" 2>/dev/null || true
                        docker rm "$container_name" 2>/dev/null || true
                    fi
                done
                total_removed=$((total_removed + $(echo "$matching_containers" | wc -l)))
            fi
        fi
        
        # Remove only the specific image we built
        if image_exists "$image_name"; then
            print_status "  Removing image: $image_name"
            if docker rmi "$image_name" 2>/dev/null; then
                print_success "  ✓ Image removed: $image_name"
                ((total_removed++))
            else
                print_error "  ✗ Could not remove image: $image_name (may be in use)"
            fi
        else
            print_warning "  Image $image_name not found"
        fi
        
        echo
    done
    
    echo
    print_header "Removal Summary"
    if [[ $total_removed -gt 0 ]]; then
        print_success "Successfully removed $total_removed resource(s) for ${#containers_to_remove[@]} container(s)"
        print_status "Only targeted container resources were removed - no system cleanup performed"
    else
        print_warning "No resources found to remove"
    fi
}

# Main execution
main() {
    local command=${1:-help}
    local container=${2:-}
    
    # Get script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cd "$SCRIPT_DIR"
    
    case $command in
        "install")
            if [[ -z "$container" ]]; then
                print_error "Please specify container or 'all'"
                print_status "Usage: $0 install <container|all>"
                exit 1
            fi
            install_containers "$container"
            ;;
        "status")
            show_status
            ;;
        "test")
            if [[ -z "$container" ]]; then
                print_error "Please specify container or 'all'"
                exit 1
            fi
            if [[ "$container" == "all" ]]; then
                for container_key in "${!CONTAINERS[@]}"; do
                    test_container_functionality "$container_key"
                done
            else
                test_container_functionality "$container"
            fi
            ;;
        "start")
            if [[ -z "$container" ]]; then
                print_error "Please specify container"
                exit 1
            fi
            start_container "$container"
            ;;
        "stop")
            if [[ -z "$container" ]]; then
                print_error "Please specify container"
                exit 1
            fi
            stop_container "$container"
            ;;
        "restart")
            if [[ -z "$container" ]]; then
                print_error "Please specify container"
                exit 1
            fi
            stop_container "$container"
            sleep 2
            start_container "$container"
            ;;
        "update"|"repair")
            if [[ -z "$container" ]]; then
                print_error "Please specify container or 'all'"
                exit 1
            fi
            print_status "Rebuilding container(s)..."
            install_containers "$container"
            ;;
        "remove"|"uninstall"|"delete")
            if [[ -z "$container" ]]; then
                print_error "Please specify container or 'all'"
                exit 1
            fi
            remove_containers "$container"
            ;;
        "logs")
            if [[ -z "$container" ]]; then
                print_error "Please specify container"
                exit 1
            fi
            local container_patterns=$(get_container_info "$container" "patterns")
            local container_type=$(get_container_info "$container" "type")
            
            if [[ "$container_type" == "daemon" ]]; then
                docker logs "$container_patterns" 2>/dev/null || print_error "$container server not running"
            else
                print_error "No persistent logs for $container (interactive container type)"
                print_status "Interactive containers don't maintain persistent logs"
            fi
            ;;
        "shell")
            if [[ -z "$container" ]]; then
                print_error "Please specify container"
                exit 1
            fi
            local image_name=$(get_container_info "$container" "image")
            if ! image_exists "$image_name"; then
                print_error "Container $container not installed"
                exit 1
            fi
            docker run -it --rm "$image_name" bash
            ;;
        "info")
            show_system_info
            show_status
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"