# Dockerfile for binder
# Reference: https://mybinder.readthedocs.io/en/latest/tutorials/dockerfile.html

FROM ghcr.io/sagemath/sage-binder-env:10.7

USER root

###--CUSTOM-APT-DEPENDENCIES--##

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
    --no-install-recommends \
    --no-install-suggests \
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

###--CUSTOM_END--###

# Create user with uid 1000
ARG NB_USER=user
ARG NB_UID=1000
ENV NB_USER=user
ENV NB_UID=1000
ENV HOME=/home/${NB_USER}
RUN adduser --disabled-password --gecos "Default user" --uid ${NB_UID} ${NB_USER}

###--CUSTOM-PIP-DEPENDENCIES--##
# NOTE: should do this *before* notebooks are copied, so each notebook change doesn't invalidate the manim install stage

USER ${NB_USER}

RUN /sage/sage -pip install --no-cache-dir \
    manim

USER root

###--CUSTOM_END--###

# Make sure the contents of the notebooks directory are in ${HOME}
COPY notebooks/* ${HOME}/
RUN chown -R ${NB_USER}:${NB_USER} ${HOME}

# Switch to the user
USER ${NB_USER}

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
RUN echo "\
    import logging\n\
    \n\
    class NoNodeJSWarningFilter(logging.Filter):\n\
    def filter(self, record):\n\
    return 'Could not determine jupyterlab build status without nodejs' not in record.getMessage()\n\
    \n\
    logging.getLogger('LabApp').addFilter(NoNodeJSWarningFilter())\n\
    " > /home/${NB_USER}/.jupyter/jupyter_lab_config.py

#> For debugging, uncomment and run `docker run --rm -it $(docker build -q .)`
# USER root
