# Dockerfile for binder
# Reference: https://mybinder.readthedocs.io/en/latest/tutorials/dockerfile.html

FROM ghcr.io/sagemath/sage-binder-env:10.7

USER root

###--CUSTOM-APT-DEPENDENCIES--##

RUN apt-get update -qq \
    && apt-get upgrade -y \
    && apt-get autoclean \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update -qq \
    && apt-get install -y \
    --no-install-recommends \
    --no-install-suggests \
    \
    #> Manim: critical dependencies
    libcairo2-dev \
    libffi-dev \
    libpango1.0-dev \
    freeglut3-dev \
    ffmpeg \
    fonts-noto \
    \
    # build-essential \
    # gcc \
    # cmake \
    \
    # pkg-config \
    # make \
    # wget \
    # ghostscript \
    \
    && apt-get autoclean \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update -qq \
    && apt-get install -y \
    # --no-install-recommends \
    # --no-install-suggests \
    \
    #> Manim: optional dependencies
    #
    # LaTex - OPTION 1: install texlive, but be warned, these are *big*
    # texlive-science \
    # LaTex - OPTION 1: install texlive-full, for full features, but *massive* size (~6 GB)
    texlive-full \
    \
    && apt-get autoclean \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update -qq \
    && apt-get install -y \
    \
    python3-dask \
    python3-distributed \
    \
    && apt-get autoclean \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# <https://github.com/pythonprofilers/memory_profiler>
# <https://github.com/bloomberg/memray>
RUN apt-get update -qq \
    && apt-get install -y \
    \
    dot2tex \
    xxhash \
    \
    python3-memory-profiler \
    google-perftools \
    \
    jq \
    \
    less \
    bat \
    \
    && apt-get autoclean \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update -qq \
    && apt-get install -y \
    \
    black \
    isort \
    \
    && apt-get autoclean \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


RUN python3 -m pip install --no-warn-script-location --no-cache-dir \
    jupyter-server-proxy \
    jupyterlab-code-formatter \
    memray

# dask-labextension
# RUN jupyter labextension disable dask-labextension

RUN mkdir /data

RUN mv /sage/venv/share/jupyter/kernels/sagemath/kernel.json /sage/venv/share/jupyter/kernels/sagemath/kernel.json.old
RUN jq -Mc '. + {"metadata": {"debugger": true}}' /sage/venv/share/jupyter/kernels/sagemath/kernel.json.old > /sage/venv/share/jupyter/kernels/sagemath/kernel.json

###--CUSTOM_END--###

# Create user with uid 1000
ARG NB_USER=user
ARG NB_UID=1000
ENV NB_USER=user
ENV NB_UID=1000
ENV HOME=/home/${NB_USER}
RUN adduser --disabled-password --gecos "Default user" --uid ${NB_UID} ${NB_USER}

# Switch to the user
USER ${NB_USER}

###--CUSTOM-PIP-DEPENDENCIES--##
# NOTE: should do this *before* notebooks are copied, so each notebook change doesn't invalidate the manim install stage

RUN /sage/sage -pip install --no-cache-dir \
    manim \
    dot2tex \
    igraph \
    \
    memray \
    line-profiler

###--CUSTOM_END--###

# Install Sage kernel to Jupyter
RUN mkdir -p $(jupyter --data-dir)/kernels
RUN ln -s /sage/venv/share/jupyter/kernels/sagemath $(jupyter --data-dir)/kernels

# Make Sage accessible from anywhere
ENV PATH="/sage:$PATH"

# Start in the home directory of the user
WORKDIR /home/${NB_USER}

# Create the jupyter_lab_config.py file with a custom logging filter to
# suppress the perpetual nodejs warning
RUN mkdir -p /home/${NB_USER}/.jupyter
COPY config/jupyter_lab_config.py  /home/${NB_USER}/.jupyter/jupyter_lab_config.py

RUN jupyter notebook --generate-config
RUN echo "c.JupyterNotebookApp.default_url = '/lab'" >> /home/${NB_USER}/.jupyter/jupyter_notebook_config.py

RUN mkdir -p  /home/${NB_USER}/.jupyter/lab/user-settings
COPY config/user-settings/ /home/${NB_USER}/.jupyter/lab/user-settings

###===END_OF_DOCKER_IMAGE===###

USER root

# Make sure the contents of the notebooks directory are in ${HOME}
COPY notebooks/* ${HOME}/
RUN chown -R ${NB_USER}:${NB_USER} ${HOME}

#> For debugging, set to `USER root` and run `docker run --rm -it $(docker build -q .)`
USER ${NB_USER}
# USER root

