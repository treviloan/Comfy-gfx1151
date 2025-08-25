# Use the specific ROCm PyTorch image
FROM rocm/pytorch:rocm6.4.1_ubuntu24.04_py3.12_pytorch_release_2.6.0

# Install basic tools
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      git python3 python3-venv python3-dev python3-pip \
      build-essential wget ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Use conda environment directly (don't create venv)
ENV PATH=/opt/conda/envs/py_3.12/bin:$PATH

# Work under the app directory
WORKDIR /app

# Clone ComfyUI to a temporary location for installation
RUN git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git /tmp/ComfyUI

# Install ComfyUI requirements using conda environment
RUN python -m pip install -r /tmp/ComfyUI/requirements.txt

# Create startup script to copy ComfyUI if needed
RUN echo '#!/bin/bash\n\
# Copy ComfyUI to mounted directory if it does not exist\n\
if [ ! -d "/app/ComfyUI" ]; then\n\
    echo "Copying ComfyUI to mounted directory..."\n\
    cp -r /tmp/ComfyUI /app/\n\
    echo "ComfyUI copied successfully"\n\
fi\n\
# Start ComfyUI with additional arguments from environment\n\
cd /app/ComfyUI && python main.py --listen 0.0.0.0 --port 8188 --enable-cors-header ${COMFYUI_ARGS}\n\
' > /startup.sh && chmod +x /startup.sh

# Default command: run startup script
EXPOSE 8188
CMD ["/startup.sh"]
