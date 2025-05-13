#syntax=docker/dockerfile:1.6
# Use the official PyTorch image as the base
FROM pytorch/pytorch:2.4.1-cuda12.1-cudnn9-devel

SHELL ["/bin/bash", "-c"]

# Set environment variables (optional, but good practice)
# ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
# ENV PYTHONUNBUFFERED=1 # Often set in Python images

# (IMPORTANT) Install essential system dependencies that Azure ML might need
# and your script might assume.
# The PyTorch image will have some, but maybe not all.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl \
    git \
    fuse \
    openssh-client \
    # Add any other system packages your script or ML libraries might need
    && rm -rf /var/lib/apt/lists/*

# Set a working directory
WORKDIR /app

# Copy your setup script and any other necessary files
COPY setup-docker.sh .

# Make your shell script executable
RUN chmod +x setup-docker.sh

RUN conda init bash
RUN source /root/.bashrc

# Run your setup script
# This script should leverage the existing Python/Conda environment in the image.
# For example, it might directly use 'pip install' or 'conda install'
# assuming they are on the PATH and configured for the correct environment.
RUN source ./setup-docker.sh --new-env --basic --xformers --flash-attn --diffoctreerast --spconv --mipgaussian --kaolin --nvdiffrast

# Example: Ensure your script installs Azure ML SDKs
# RUN pip install azure-ai-ml azureml-mlflow

COPY configs /app/configs
COPY extensions /app/extensions
COPY extern /app/extern
COPY gclib /app/gclib
COPY train.py .
COPY trellis /app/trellis

COPY gclib/requirements.txt gclib_requirements.txt

RUN . /opt/conda/etc/profile.d/conda.sh && conda activate trellis && pip install -r gclib_requirements.txt && pip install webdataset mosaicml-streaming fsspec s3fs tensorboard
