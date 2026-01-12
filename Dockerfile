# Dockerfile for binder
# Reference: https://mybinder.readthedocs.io/en/latest/tutorials/dockerfile.html

FROM ghcr.io/sagemath/sage/sage-ubuntu-noble-standard-with-targets:10.8

USER root

###--JUPYTER_SETUP--###

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
    sudo \
    python3-pip \
    \
    # jupyter \
    # jupyterhub \
    # python3-ipywidgets \
    # python3-notebook \
    # python3-jupyterlab-server \
    # python3-jupyterlab-pygments \
    \
    black \
    isort \
    \
    && apt-get autoclean \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --no-warn-script-location --no-cache-dir --break-system-packages \
    ipywidgets \
    notebook \
    jupyterlab \
    \
    jupyter-server-proxy \
    jupyterlab-code-formatter
# dask-labextension

RUN jupyter labextension disable "@jupyterlab/apputils-extension:announcements"
# RUN jupyter labextension disable dask-labextension

###--MANIM_SETUP--###

# RUN apt-get update -qq \
#     && apt-get install -y \
#     # --no-install-recommends \
#     # --no-install-suggests \
#     \
#     # LaTex - OPTION 1: install texlive, but be warned, these are *big*
#     # texlive-science \
#     # LaTex - OPTION 1: install texlive-full, for full features, but *massive* size (~6 GB)
#     texlive-full \
#     \
#     && apt-get autoclean \
#     && apt-get clean \
#     && rm -rf /var/lib/apt/lists/*

RUN apt-get update -qq \
    && apt-get install -y \
    --no-install-recommends \
    --no-install-suggests \
    \
    dot2tex \
    \
    #> Manim: critical dependencies
    libcairo2-dev \
    libffi-dev \
    libpango1.0-dev \
    freeglut3-dev \
    ffmpeg \
    fonts-noto \
    \
    #> Manim: optional dependencies
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

###--QOL_TOOLS--###

# RUN apt-get update -qq \
#     && apt-get install -y \
#     --no-install-recommends \
#     --no-install-suggests \
#     \
#     # python3-dask \
#     # python3-distributed \
#     \
#     xxhash \
#     \
#     # <https://github.com/pythonprofilers/memory_profiler>
#     python3-memory-profiler \
#     google-perftools \
#     \
#     jq \
#     \
#     less \
#     bat \
#     \
#     && apt-get autoclean \
#     && apt-get clean \
#     && rm -rf /var/lib/apt/lists/*

# RUN mv \
#     /sage/venv/share/jupyter/kernels/sagemath/kernel.json \
#     /sage/venv/share/jupyter/kernels/sagemath/kernel.json.old

# RUN jq -Mc '. + {"metadata": {"debugger": true}}' \
#     /sage/venv/share/jupyter/kernels/sagemath/kernel.json.old \
#     > /sage/venv/share/jupyter/kernels/sagemath/kernel.json

ARG NB_USER=user
ARG NB_UID=1000
ENV NB_USER=user
ENV NB_UID=1000

ENV NB_HOME=/home/${NB_USER}
ENV DATA_DIR=${NB_HOME}

RUN deluser --remove-home ubuntu
RUN adduser \
    --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}

RUN usermod -aG sudo ${NB_USER}
RUN echo "${NB_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/admins
RUN chmod 0440 /etc/sudoers.d/admins

# Switch to the user
USER ${NB_USER}

# Make Sage accessible from anywhere
ENV PATH="/sage:$PATH"

# NOTE: should do this *before* notebooks are copied, so each notebook change doesn't invalidate the manim install stage
# <https://github.com/bloomberg/memray>
RUN sage -pip install -U \
    # manim \
    # dot2tex \
    # igraph \
    # \
    # memray \
    line-profiler

# Install Sage kernel to Jupyter
RUN mkdir -p $(jupyter --data-dir)/kernels
COPY --chown=${NB_USER}:${NB_USER} config/kernels/sagemath /tmp/sagemath
RUN mv /tmp/sagemath $(jupyter --data-dir)/kernels/
# RUN ln -s /sage/venv/share/jupyter/kernels/sagemath $(jupyter --data-dir)/kernels

# Create the jupyter_lab_config.py file with a custom logging filter to
# suppress the perpetual nodejs warning
RUN mkdir -p ${NB_HOME}/.jupyter
COPY config/jupyter_lab_config.py ${NB_HOME}/.jupyter/jupyter_lab_config.py

RUN jupyter notebook --generate-config
RUN echo "c.JupyterNotebookApp.default_url = '/lab'" >> ${NB_HOME}/.jupyter/jupyter_notebook_config.py

RUN mkdir -p ${NB_HOME}/.jupyter/lab/user-settings
COPY config/user-settings/ ${NB_HOME}/.jupyter/lab/user-settings

# Start in the home directory of the user
# Make sure the contents of the notebooks directory are in ${HOME}
WORKDIR ${DATA_DIR}
COPY notebooks/* ${DATA_DIR}/
RUN sudo chown -R ${NB_USER}:${NB_USER} ${DATA_DIR}

#> For debugging, set to `USER root` and run `docker run --rm -it $(docker build -q .)`
USER ${NB_USER}
# USER root
