# Use the official PyTorch image
FROM pytorch/pytorch

# Install JupyterLab and other essential tools
RUN pip install --no-cache-dir --upgrade pip \
    && pip install jupyterlab numpy

# Install vim for convenience
RUN apt-get update && apt-get install -y vim

# Set up JupyterLab to allow access without authentication
RUN mkdir -p /root/.jupyter \
    && echo "c.ServerApp.ip = '0.0.0.0'" >> /root/.jupyter/jupyter_lab_config.py \
    && echo "c.ServerApp.port = 8989" >> /root/.jupyter/jupyter_lab_config.py \
    && echo "c.ServerApp.open_browser = False" >> /root/.jupyter/jupyter_lab_config.py \
    && echo "c.ServerApp.allow_root = True" >> /root/.jupyter/jupyter_lab_config.py \
    && echo "c.ServerApp.token = ''" >> /root/.jupyter/jupyter_lab_config.py \
    && echo "c.ServerApp.password = ''" >> /root/.jupyter/jupyter_lab_config.py \
    && echo "c.ServerApp.disable_check_xsrf = True" >> /root/.jupyter/jupyter_lab_config.py

# Set a default working directory
WORKDIR /workspace

# Expose the JupyterLab port
EXPOSE 8989

# Command to run JupyterLab on container start
CMD ["jupyter-lab", "--config=/root/.jupyter/jupyter_lab_config.py"]
