# Multi-stage Dockerfile for slim Sage
# https://docs.docker.com/build/building/multi-stage

FROM docker.io/library/archlinux:latest

ARG NB_USER=user
ARG NB_UID=1000
ENV NB_USER=user
ENV NB_UID=1000
ENV NB_HOME=/home/${NB_USER}

## Update the pacman package database
RUN pacman -Syu --noconfirm && pacman -S --noconfirm --needed \
    aria2 \
    && pacman -Scc --noconfirm

### <https://wiki.archlinux.org/title/Pacman#Configuration>
RUN mkdir -p /root/.config/aria2/
COPY docker/aria2.conf /root/.config/aria2/pacman-aria2.conf
COPY docker/pacman-docker-extra.conf /etc/pacman.d/pacman-docker-extra.conf
### Could use multiple -e, since `;` is specified in POSIX; <https://stackoverflow.com/questions/6280599/how-portable-is-it-to-use-semi-colons-as-command-separators-in-sed/20769695#20769695>
RUN sed -i -e 's/^NoProgressBar$/#NoProgressBar/' /etc/pacman.conf \
    # && sed -i -e '/usr\/share\/man/d' /etc/pacman.conf \
    && printf "\n\n## Include \`Dockerfile\` customizations\n[options]\nInclude = /etc/pacman.d/pacman-docker-extra.conf" >> /etc/pacman.conf

## Update the pacman package database
RUN pacman -Sy --noconfirm && pacman -S --noconfirm --needed \
    sudo \
    && pacman -Scc --noconfirm

RUN useradd \
    -ms /bin/bash \
    --uid ${NB_UID} \
    ${NB_USER}
RUN printf "Defaults:${NB_USER}      !authenticate\n${NB_USER} ALL=(ALL:ALL) ALL\nDefaults          insults" >> /etc/sudoers

# Switch to the user
USER ${NB_USER}

RUN sudo pacman -Sy && sudo pacman -S --noconfirm --needed  \
    git \
    base-devel \
    # gcc \
    # && sudo pacman -Syu \
    && sudo pacman -Scc --noconfirm

RUN pushd $(mktemp -d) \
    # && git archive --format=tar --remote="https://aur.archlinux.org/yay.git" HEAD | tar xf - \
    && git clone --depth=1 --single-branch --branch=master https://aur.archlinux.org/yay.git \
    \
    && pushd yay \
    && makepkg -sci --noconfirm \
    && yay -Y --gendb \
    && yay -Syu --devel --noconfirm \
    && yay -Y --devel --save \
    && popd \
    \
    # TODO: remove `sudo` step when `yay` repo fixes its current problems
    && rm -rf yay \
    && popd \
    \
    && go clean -modcache \
    && go clean -cache \
    && yay -Syu --noconfirm --cleanafter \
    && yay -Scc --noconfirm

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
    && sudo pacman -Scc --noconfirm

### SageMath + Base Dependencies
RUN sudo pacman -Sy && sudo pacman -S --noconfirm --needed  \
    sagemath \
    sagemath-giac \
    && sudo pacman -Scc --noconfirm

### Sagemath Optional Data Dependencies
RUN sudo pacman -Sy && sudo pacman -S --noconfirm --needed  \
    sage-data-elliptic_curves \
    sage-data-cunningham_tables \
    && sudo pacman -Scc --noconfirm

###--MANIM_dependencies--###

RUN sudo pacman -Sy && sudo pacman -S --noconfirm --needed  \
    # texlive \
    \
    texlive-latex \
    texlive-latexextra \
    texlive-latexrecommended \
    \
    texlive-xetex \
    texlive-fontsrecommended \
    \
    texlive-langgreek \
    texlive-mathscience \
    \
    # dvisvgm  \
    texlive-binextra \
    \
    # texlive-pictures \
    # texlive-langenglish \
    && sudo pacman -Scc --noconfirm

RUN sudo pacman -Sy && sudo pacman -S --noconfirm --needed  \
    base-devel \
    cairo \
    pango \
    ffmpeg \
    && sudo pacman -Scc --noconfirm

###--JUPYTER--###

### Jupyter base dependencies
# RUN sudo pacman -Sy && sudo pacman -S --noconfirm --needed  \
#     jupyter-notebook \
#     python-ipywidgets \
#     python-jupyter-server-terminals \
#     \
#     && sudo pacman -Scc --noconfirm

### Local Jupyter Installation Local setup
WORKDIR ${NB_HOME}

RUN sudo pacman -Sy && sudo pacman -S --noconfirm --needed  \
    uv \
    && sudo pacman -Scc --noconfirm

RUN uv venv --system-site-packages
RUN uv pip install --no-cache-dir \
    notebook \
    ipywidgets \
    jupyterlab \
    jupyter_server_terminals \
    && uv cache clean && uv cache prune
RUN uv run jupyter labextension disable "@jupyterlab/apputils-extension:announcements"

RUN uv pip install --no-cache-dir \
    notebook \
    ipywidgets \
    jupyterlab \
    jupyter_server_terminals

###--MANIM_install--###

# RUN yay -Sy --cleanafter && yay -S --noconfirm --needed --cleanafter  \
#     manim \
#     # && ~/.local/bin/update_all \
#     && yay -Syu --noconfirm --cleanafter

# TODO: currently broken, wait until PyPI is fixed
# RUN uv pip install --no-cache-dir \
#     manim[jupyterlab]
#     manim
# RUN uv run manim checkhealth

ENTRYPOINT [ "uv", "run" ]
