# Use the official Ubuntu 22.04 image as the base
FROM ubuntu:22.04

# Use bash as the default shell
SHELL ["/bin/bash", "-c"]

# Set the working directory inside the container
WORKDIR /root

# Update and install basic utilities
RUN apt update && apt upgrade -y && apt install -y \
    vim wget apt-transport-https flex make gcc g++ build-essential cmake openmpi-bin \
    python3-dev python3-pip libeigen3-dev libyaml-cpp-dev libboost-all-dev libxml2 \
    libxml2-dev libopenblas-dev liblapack-dev libarpack2-dev libspooles-dev git

# Install PETSc
RUN pip3 install numpy && \
    wget http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-3.16.0.tar.gz && \
    tar -xzf petsc-3.16.0.tar.gz && \
    cd petsc-3.16.0 && \
    ./configure --prefix=/usr/local --with-mpi=1 \
    --with-blas-lib=/usr/lib/x86_64-linux-gnu/libopenblas.so \
    --with-lapack-lib=/usr/lib/x86_64-linux-gnu/liblapack.so && \
    make && make install

# Set PETSc environment variables
ENV PETSC_DIR="/usr/local"
ENV PETSC_ARCH="arch-linux2-c-debug"

# Install preCICE
RUN git clone --branch v3.1.2 https://github.com/precice/precice.git && \
    cd precice && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DPETSC_DIR=/usr/local -DPETSC_ARCH=arch-linux2-c-debug .. && \
    make -j$(nproc) && make install

# Install OpenFOAM
RUN wget -q -O - https://dl.openfoam.com/add-debian-repo.sh | bash && \
    apt-get update && \
    apt-get install -y openfoam2406-dev

# Set up OpenFOAM environment
RUN mkdir -p /root/OpenFOAM/user-v2406 && \
    wget https://sourceforge.net/projects/openfoam/files/v2406/ThirdParty-v2406.tgz && \
    tar -xzf ThirdParty-v2406.tgz -C /usr/lib/openfoam/openfoam2406 && \
    rm ThirdParty-v2406.tgz && \
    echo "source /usr/lib/openfoam/openfoam2406/etc/bashrc" >> /root/.bashrc && \
    echo "export SHELL=/bin/bash" >> /usr/lib/openfoam/openfoam2406/etc/bashrc && \
    echo "export WM_SHELL=bash" >> /usr/lib/openfoam/openfoam2406/etc/bashrc

ENV LANG=C.UTF-8

# Build OpenFOAM adapter
RUN mkdir -p /usr/lib/openfoam/openfoam2406/OpenFOAM-adapter && \
    wget https://github.com/precice/openfoam-adapter/releases/download/v1.3.1/openfoam-adapter-v1.3.1-OpenFOAMv1812-v2406-newer.tar.gz -O /usr/lib/openfoam/openfoam2406/OpenFOAM-adapter/openfoam-adapter.tar.gz && \
    tar -xzf /usr/lib/openfoam/openfoam2406/OpenFOAM-adapter/openfoam-adapter.tar.gz -C /usr/lib/openfoam/openfoam2406/OpenFOAM-adapter && \
    rm /usr/lib/openfoam/openfoam2406/OpenFOAM-adapter/openfoam-adapter.tar.gz && \
    cd /usr/lib/openfoam/openfoam2406/OpenFOAM-adapter && \
    cd $(find . -mindepth 1 -maxdepth 1 -type d) && \
    bash -c "source /usr/lib/openfoam/openfoam2406/etc/bashrc && chmod +x Allwmake && ./Allwmake"

# Install and build CalculiX and its adapter
RUN wget http://www.dhondt.de/ccx_2.20.src.tar.bz2 && \
    tar xvjf ccx_2.20.src.tar.bz2 && \
    wget https://github.com/precice/calculix-adapter/archive/refs/heads/master.tar.gz && \
    tar -xzf master.tar.gz && \
    cd calculix-adapter-master && \
    sed -i 's|^FFLAGS = -Wall -O3 -fopenmp $(INCLUDES)|FFLAGS = -Wall -O3 -fopenmp -fallow-argument-mismatch $(INCLUDES)|' Makefile && \
    make

CMD ["/bin/bash", "-c", "source /usr/lib/openfoam/openfoam2406/etc/bashrc && /bin/bash"]
