# Docker Container Manager for FSI, ParaView, and PyTorch

This repository provides a unified Docker management system for computational fluid dynamics (CFD), fluid-structure interaction (FSI), visualization, and machine learning workflows. The `setup.sh` script acts as a comprehensive container manager with selective installation, monitoring, and lifecycle management.

## 🚀 Quick Start

### Container Manager Usage
```bash
# Show help and available commands
./setup.sh help

# Install specific containers
./setup.sh install fsi        # Install FSI container only
./setup.sh install pytorch    # Install PyTorch container only
./setup.sh install all        # Install all containers

# Check container status
./setup.sh status

# Start/stop services
./setup.sh start paraview     # Start ParaView server
./setup.sh stop paraview      # Stop ParaView server
```

### Available Commands
```bash
./setup.sh install <container|all>  # Install/build container(s)
./setup.sh status                   # Show status of all containers
./setup.sh test <container|all>     # Test container functionality
./setup.sh start <container>        # Start container service
./setup.sh stop <container>         # Stop container service
./setup.sh restart <container>      # Restart container service
./setup.sh update <container|all>   # Update/rebuild container(s)
./setup.sh remove <container|all>   # Remove container image(s)
./setup.sh logs <container>         # Show container logs
./setup.sh shell <container>        # Open interactive shell
./setup.sh info                     # Show system information
```

## 📦 Containers Overview

| Container | Size | Purpose | Key Software |
|-----------|------|---------|--------------|
| **FSI** | 5.2GB | Fluid-Structure Interaction | OpenFOAM v2406, CalculiX 2.20, preCICE 3.1.2 |
| **ParaView** | 2.6GB | Scientific Visualization | ParaView 5.13.1 Server |
| **PyTorch Jupyter** | 7.9GB | Machine Learning | PyTorch 2.2.1, JupyterLab |

## 🔧 Container Usage

### 1. FSI Container (`fsi`)

**Purpose**: Complete FSI simulation environment with OpenFOAM for CFD and CalculiX for structural analysis, coupled via preCICE.

#### Management Commands
```bash
# Install FSI container
./setup.sh install fsi

# Test FSI functionality
./setup.sh test fsi

# Start interactive session
./setup.sh start fsi

# Open shell (alternative)
./setup.sh shell fsi
```

#### Manual Docker Usage
```bash
# Mount your case directory and run OpenFOAM
docker run --rm -v $(pwd)/my_case:/workspace -w /workspace fsi:latest \
  bash -c "source /usr/lib/openfoam/openfoam2406/etc/bashrc && icoFoam"

# Run CalculiX with preCICE adapter
docker run --rm -v $(pwd)/my_case:/workspace -w /workspace fsi:latest \
  /root/calculix-adapter-master/bin/ccx_preCICE input.inp

# Convert CalculiX results to ParaView format
docker run --rm -v $(pwd)/my_case:/workspace -w /workspace fsi:latest \
  python3 -c "import ccx2paraview; ccx2paraview.converter('results.frd')"
```

#### Available Tools
- **OpenFOAM solvers**: `icoFoam`, `simpleFoam`, `pimpleFoam`, etc.
- **CalculiX with preCICE**: `/root/calculix-adapter-master/bin/ccx_preCICE`
- **preCICE tools**: `precice-tools`
- **ccx2paraview**: Convert CalculiX results to VTK format
- **Standard tools**: `vim`, `tmux`, `wget`, `git`

---

### 2. ParaView Container (`paraview`)

**Purpose**: Remote ParaView server for scientific visualization and post-processing.

#### Management Commands
```bash
# Install ParaView container
./setup.sh install paraview

# Test ParaView functionality
./setup.sh test paraview

# Start ParaView server (port 11111)
./setup.sh start paraview

# Stop ParaView server
./setup.sh stop paraview

# View server logs
./setup.sh logs paraview

# Restart server
./setup.sh restart paraview
```

#### Connect from ParaView Client
1. Install ParaView client on your local machine
2. Open ParaView client
3. Go to `File > Connect`
4. Add Server: `localhost`, Port: `11111`
5. Connect and start visualization

#### Manual Docker Usage
```bash
# Server with custom settings
docker run -d --name paraview-custom \
  -p 11111:11111 \
  -v $(pwd)/data:/data \
  paraview:latest pvserver --server-port=11111 --data=/data

# Multiple server instances
docker run -d --name paraview-1 -p 11111:11111 paraview:latest
docker run -d --name paraview-2 -p 11112:11111 paraview:latest
```

---

### 3. PyTorch Jupyter Container (`pytorch`)

**Purpose**: Machine learning environment with PyTorch and JupyterLab for data analysis and ML workflows.

#### Management Commands
```bash
# Install PyTorch container
./setup.sh install pytorch

# Test PyTorch functionality
./setup.sh test pytorch

# Start Jupyter server (port 8989)
./setup.sh start pytorch

# Stop Jupyter server
./setup.sh stop pytorch

# View server logs
./setup.sh logs pytorch

# Open interactive shell
./setup.sh shell pytorch
```

#### Access JupyterLab
1. Start the server: `./setup.sh start pytorch`
2. Open browser and go to: `http://localhost:8989`
3. No password required (configured for development)
4. Create notebooks in `/workspace` directory

#### Manual Docker Usage
```bash
# Run a Python script
docker run --rm -v $(pwd):/workspace -w /workspace pytorch_jupyter:latest \
  python my_script.py

# Run with GPU support (if available)
docker run --rm --gpus all -v $(pwd):/workspace pytorch_jupyter:latest \
  python gpu_script.py

# Interactive Python/IPython session
docker run -it --rm pytorch_jupyter:latest python
docker run -it --rm pytorch_jupyter:latest ipython
```

## 🧪 Testing and Verification

### Test All Containers
```bash
# Test all installed containers
./setup.sh test all

# Test specific containers
./setup.sh test fsi
./setup.sh test paraview
./setup.sh test pytorch
```

### Manual Verification (Alternative)
You can still use the dedicated test script:
```bash
./test_containers.sh
```

## 📊 Container Monitoring

### Check Container Status
```bash
# Show comprehensive status of all containers
./setup.sh status

# Show system information and container status
./setup.sh info
```

The status command shows:
- Which containers are built (installed)
- Which containers are currently running
- Container descriptions and sizes

### Example Status Output
```
Container Status
Container    Built    Running  Description
----------   -----    -------  -----------
fsi          Yes      No       FSI Container (OpenFOAM + CalculiX + preCICE) (5.2GB)
paraview     Yes      Yes      ParaView Visualization Server (2.6GB)
pytorch      No       No       PyTorch Jupyter Environment (7.9GB)
```

## 📊 System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| **Disk Space** | 20GB | 50GB+ |
| **RAM** | 8GB | 16GB+ |
| **CPU** | 4 cores | 8+ cores |
| **Docker Version** | 20.x+ | Latest |

## 🔍 Troubleshooting

### Build Issues
```bash
# Check Docker daemon
docker info

# Clean up space
docker system prune -a

# Check build logs
docker build -t fsi:latest ./fsi 2>&1 | tee fsi_build.log
```

### Runtime Issues
```bash
# Check container status
docker ps -a

# View container logs
docker logs container_name

# Interactive debugging
docker run -it fsi:latest bash
```

### Port Conflicts
```bash
# Check what's using port 8989
lsof -i :8989

# Use different ports
docker run -p 8990:8989 pytorch_jupyter:latest
docker run -p 11112:11111 paraview:latest
```

## ➕ Adding New Containers

The container manager is **fully generalized** and extensible. Adding a new container requires **NO CODE CHANGES** - just configuration!

### Step 1: Add Container Definition
Edit `setup.sh` and add your container to the `CONTAINERS` associative array:

```bash
# In setup.sh, around line 19-23
declare -A CONTAINERS=(
    ["fsi"]="fsi:latest|fsi|FSI Container (OpenFOAM + CalculiX + preCICE)|5.2GB|fsi-*|interactive|"
    ["paraview"]="paraview:latest|paraview|ParaView Visualization Server|2.6GB|paraview-server|daemon|11111"
    ["pytorch"]="pytorch_jupyter:latest|pytorch_jupyter|PyTorch Jupyter Environment|7.9GB|pytorch-jupyter|daemon|8989"
    ["mynew"]="mynew:latest|mynew|My New Container Description|2.0GB|mynew-server|daemon|8080"  # Add this line
)
```

**Format**: `"key"="image:tag|directory|description|size|container_patterns|type|port"`

**Field Descriptions:**
- `key`: Container identifier used in commands
- `image:tag`: Docker image name and tag  
- `directory`: Directory containing Dockerfile
- `description`: Human-readable description
- `size`: Estimated size for display
- `container_patterns`: Container naming pattern (`*` for timestamp suffix)
- `type`: `daemon` (persistent service) or `interactive` (temporary session)
- `port`: Port for daemon containers (empty for interactive)

### Step 2: Create Container Directory
```bash
mkdir mynew
cd mynew
# Add your Dockerfile here
```

### Step 3: Test Your Addition (Automatic)
```bash
./setup.sh install mynew    # Builds and tests automatically
./setup.sh start mynew      # Starts based on type (daemon/interactive)
./setup.sh stop mynew       # Stops daemon containers
./setup.sh remove mynew     # Removes containers and image
./setup.sh status           # Shows all containers including new one
```

### Container Type Examples

**Daemon Container** (persistent service):
```bash
["nginx"]="nginx:latest|nginx|Web Server|200MB|nginx-server|daemon|8080"
```
- Creates container named `nginx-server`
- Runs as background service on port 8080
- Can be started/stopped/restarted
- Has persistent logs

**Interactive Container** (temporary session):
```bash
["shell"]="ubuntu:latest|shell|Ubuntu Shell|100MB|shell-*|interactive|"
```  
- Creates containers named `shell-1234567890` (with timestamp)
- Runs interactively then exits
- Cannot be stopped (exits when session ends)
- No persistent logs

### Step 4: Optional - Custom Testing
If you need special test logic, add a case to `test_container_functionality()`:

```bash
        "mynew")
            if docker run --rm "$image_name" your-test-command; then
                print_success "✓ MyNew functionality"
            else
                print_warning "✗ MyNew test failed"
                return 1
            fi
            ;;
```

**That's it!** The system automatically handles:
- ✅ Installation and building
- ✅ Starting/stopping based on type
- ✅ Status monitoring 
- ✅ Container removal with patterns
- ✅ Logs viewing (for daemon types)
- ✅ Help and command listings

## 📁 Directory Structure

```
dockerfiles/
├── setup.sh              # Container management script
├── test_containers.sh     # Legacy testing script
├── README.md             # This file
├── fsi/
│   ├── Dockerfile        # FSI container definition
│   ├── README.md         # FSI-specific instructions
│   ├── frdToVTKConverter.exe
│   └── unical3
├── paraview/
│   ├── Dockerfile        # ParaView container definition
│   └── README.md         # ParaView-specific instructions
└── pytorch_jupyter/
    ├── Dockerfile        # PyTorch container definition
    └── README.md         # PyTorch-specific instructions
```

## 🛠️ Container Lifecycle Management

### Update/Repair Containers
```bash
# Rebuild specific container (useful after Dockerfile changes)
./setup.sh update fsi
./setup.sh repair paraview    # Same as update

# Rebuild all containers
./setup.sh update all
```

### Remove Containers
```bash
# Remove specific container image
./setup.sh remove fsi

# Remove all container images (with confirmation)
./setup.sh remove all
```

### Container Logs and Debugging
```bash
# View logs for running services
./setup.sh logs paraview
./setup.sh logs pytorch

# Open interactive shell for debugging
./setup.sh shell fsi
./setup.sh shell pytorch
```

## 🚨 Security Notes

- **PyTorch Jupyter**: Configured without authentication for development
- **ParaView**: Server accepts connections from any IP
- **FSI Container**: Contains development tools and compilers

**For production use**: Implement proper authentication and network security.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `./setup.sh`
5. Submit a pull request

## 📄 License

This project contains configurations for open-source software:
- OpenFOAM: GPL v3
- CalculiX: GPL v2
- preCICE: LGPL v3
- ParaView: BSD License
- PyTorch: Modified BSD License

## 🔧 Advanced Usage Examples

### Development Workflow
```bash
# 1. Check what's installed
./setup.sh status

# 2. Install only what you need
./setup.sh install fsi
./setup.sh install paraview

# 3. Start services
./setup.sh start paraview

# 4. Work with containers
./setup.sh shell fsi

# 5. Test everything works
./setup.sh test all

# 6. Clean up when done
./setup.sh stop paraview
./setup.sh remove fsi
```

### Parallel Development
```bash
# Terminal 1: Work with FSI
./setup.sh start fsi

# Terminal 2: ParaView server for visualization
./setup.sh start paraview

# Terminal 3: ML analysis
./setup.sh start pytorch
# Then visit http://localhost:8989
```

## 🆘 Support

For issues and questions:
1. Check container status: `./setup.sh status`
2. View system info: `./setup.sh info`
3. Test containers: `./setup.sh test all`
4. Check logs: `./setup.sh logs <container>`
5. Review the troubleshooting section below

---

## 📋 Quick Reference

```bash
# Essential Commands
./setup.sh help                    # Show all commands
./setup.sh status                  # Check container status
./setup.sh install <container>     # Install specific container
./setup.sh start <container>       # Start container service
./setup.sh stop <container>        # Stop container service
./setup.sh test <container>        # Test container functionality
./setup.sh remove <container>      # Remove container image
```

**Available Containers**: `fsi`, `paraview`, `pytorch`, `all`

**Happy Computing!** 🚀
