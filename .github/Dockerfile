# Multi-stage Dockerfile for slim Sage
# https://docs.docker.com/build/building/multi-stage

FROM docker.io/library/archlinux:latest

## Update the pacman package database
RUN pacman -Syu --noconfirm && pacman -S --noconfirm --needed \
    aria2 \
    \
    sudo \
    zsh \
    \
    python-pip \
    && pacman -Scc --noconfirm

### <https://wiki.archlinux.org/title/Pacman#Configuration>
RUN mkdir -p /root/.config/aria2/
COPY docker/aria2.conf /root/.config/aria2/pacman-aria2.conf
COPY docker/pacman-docker-extra.conf /etc/pacman.d/pacman-docker-extra.conf
### Could use multiple -e, since `;` is specified in POSIX; <https://stackoverflow.com/questions/6280599/how-portable-is-it-to-use-semi-colons-as-command-separators-in-sed/20769695#20769695>
RUN sed -i -e 's/^NoProgressBar$/#NoProgressBar/' /etc/pacman.conf \
    # && sed -i -e '/usr\/share\/man/d' /etc/pacman.conf \
    && printf "\n\n## Include \`Dockerfile\` customizations\n[options]\nInclude = /etc/pacman.d/pacman-docker-extra.conf" >> /etc/pacman.conf

## Sagemath

### Sagemath-generic Optional Dependencies
RUN sudo pacman -Sy && sudo pacman -S --noconfirm --needed  \
    cryptominisat \
    python-pyscipopt \
    shared_meataxe \
    msolve \
    rubiks \
    \
    pari-seadata \
    \
    dot2tex \
    cython \
    && pacman -Scc --noconfirm

### SageMath Base Dependencies
RUN sudo pacman -Sy && sudo pacman -S --noconfirm --needed  \
    sagemath \
    ### Sagemath-specific Optional Dependencies
    sage-data-elliptic_curves \
    sagemath-giac \
    sage-data-cunningham_tables \
    && pacman -Scc --noconfirm

## Jupyter

### Jupyter base dependencies
# RUN sudo pacman -Sy && sudo pacman -S --noconfirm --needed  \
#     jupyter-notebook \
#     jupyterlab \
#     \
#     python-ipywidgets \
#     jupyterlab-widgets \
#     \
#     python-jupyter-server-terminals \
#     \
#     && pacman -Scc --noconfirm

### Jupyter Extra Dependencies
RUN sudo pacman -Sy && sudo pacman -S --noconfirm --needed  \
    python-ruff \
    python-isort \
    python-black \
    \
    uv \
    \
    # python-phitigra \
    && pacman -Scc --noconfirm

# RUN python3 -m pip install --no-warn-script-location --no-cache-dir --break-system-packages \
#     # dask-labextension \
#     jupyter-server-proxy \
#     jupyterlab-code-formatter

# Disable annoying popup for Jupyter news
RUN jupyter labextension disable "@jupyterlab/apputils-extension:announcements"
