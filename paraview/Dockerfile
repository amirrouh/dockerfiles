# Use Ubuntu 22.04 as base image
FROM ubuntu:22.04

# Use bash as the default shell
SHELL ["/bin/bash", "-c"]

# Install necessary dependencies, including wget
RUN apt update && apt install -y \
    wget libgomp1 libcurl4 libx11-6 libgl1-mesa-glx libxt6 libxrender1 \
    libxcomposite1 libxcursor1 libxi6 libxrandr2 libfontconfig1 \
    libfreetype6 libglvnd0 libegl1-mesa libsm6 libice6

# Download and install ParaView 5.13.1
RUN wget -q "https://www.paraview.org/files/v5.13/ParaView-5.13.1-MPI-Linux-Python3.10-x86_64.tar.gz" -O ParaView-5.13.1-MPI-Linux-Python3.10-x86_64.tar.gz && \
    tar -xzf ParaView-5.13.1-MPI-Linux-Python3.10-x86_64.tar.gz && \
    mv ParaView-5.13.1-MPI-Linux-Python3.10-x86_64 /opt/paraview && \
    rm -f ParaView-5.13.1-MPI-Linux-Python3.10-x86_64.tar.gz
ENV PATH="/opt/paraview/bin:$PATH"

# Expose the port for ParaView server
EXPOSE 11111

# Start ParaView server as a service
CMD ["pvserver", "--server-port=11111"]
