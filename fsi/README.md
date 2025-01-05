# FSI using openfoam and Calculix

This dockerfile installs openfoam and Calculix on ubuntu 22.04 alongside precice package. The combination of these three open source backages make the simulation of computational fluid dynamic (CFD), finite element analysis (FEA), and fluid structural interaction (FSI).

## Setup 
Navigate to the fsi folder and run the following command:
```bash
docker build -t fsi .
```
After building the image, now we create a container:
```bash
docker run -it -d --name fsi_container -v /home/amir/Projects/fsi_data:/fsi_data fsi
```
Now we can log in to the fsi_container using:
```bash
docker exec -it fsi_container /bin/bash
```
## How to run the simulation
TODO

## Convert Calculix files to vtk for paraview
```bash
ccx2paraview tube.frd vtk
```
