# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Container Management Commands

All container operations are handled through the unified `./setup.sh` script:

```bash
./setup.sh install <container|all>    # Build container(s) from Dockerfiles
./setup.sh status                     # Show build/runtime status of all containers
./setup.sh start <container>          # Start container service or interactive session
./setup.sh stop <container>           # Stop daemon containers
./setup.sh test <container|all>       # Test container functionality
./setup.sh logs <container>           # View logs for daemon containers
./setup.sh shell <container>          # Open interactive bash shell
./setup.sh remove <container|all>     # Remove containers and images
```

Available containers: `fsi`, `paraview`, `pytorch`

## Container Architecture

The repository implements a generalized container management system using associative arrays in bash. Container definitions are stored in the `CONTAINERS` array in `setup.sh:19-23` with the format:

```
"key"="image:tag|directory|description|size|container_patterns|type|port"
```

### Container Types

**Daemon containers** (`paraview`, `pytorch`):
- Run as persistent background services
- Have fixed container names (e.g., `paraview-server`, `pytorch-jupyter`)
- Support start/stop/restart operations
- Maintain persistent logs
- Expose specific ports

**Interactive containers** (`fsi`):
- Run temporarily for interactive sessions
- Use timestamped container names (e.g., `fsi-1234567890`)
- Exit automatically when session ends
- No persistent logs or start/stop operations

## Build Process

Each container has its own directory with a Dockerfile:

- **FSI** (`fsi/`): Complex multi-stage build installing OpenFOAM v2406, CalculiX 2.20, preCICE 3.1.2, and custom adapters. Build time ~45 minutes, final size ~5.2GB.
- **ParaView** (`paraview/`): Simple download and install of ParaView 5.13.1. Build time ~5 minutes, final size ~2.6GB.
- **PyTorch** (`pytorch_jupyter/`): Based on official PyTorch image with JupyterLab. Build time ~3 minutes, final size ~7.9GB.

## Development Workflow

1. Check container status: `./setup.sh status`
2. Install needed containers: `./setup.sh install <container>`
3. Test functionality: `./setup.sh test <container>`
4. Start services as needed:
   - ParaView server: `./setup.sh start paraview` (port 11111)
   - Jupyter server: `./setup.sh start pytorch` (port 8989)
   - FSI interactive: `./setup.sh start fsi`

## Adding New Containers

The system is fully extensible without code changes:

1. Add container definition to `CONTAINERS` array in `setup.sh:19-23`
2. Create directory with Dockerfile
3. Optionally add test case in `test_container_functionality()` function

The management script automatically handles installation, testing, lifecycle management, and cleanup for any properly configured container.

## Testing

Container functionality is tested during installation and can be run separately:
- FSI: Tests CalculiX with preCICE adapter and OpenFOAM environment
- ParaView: Tests `pvserver --version` 
- PyTorch: Tests PyTorch import and version

## File Structure

```
dockerfiles/
├── setup.sh              # Unified container management script
├── fsi/Dockerfile         # FSI simulation environment
├── paraview/Dockerfile    # ParaView visualization server  
├── pytorch_jupyter/Dockerfile # PyTorch ML environment
└── examples/              # Example usage files
```