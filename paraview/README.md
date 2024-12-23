# Paraview server 5.13.1

By following the bellow instructions you can run paraview server on localhost:11111 and be able to connect to this server using 
your local paraview (should have the same version).

## Build the image
In the paraview folder, run the follwing command:
```
bash

docker build -t paraview .
```

Then run the container:

docker run -it -d -p 11111:11111 --name paraview_container paraview

```
