# Dockerfile for binder
# Reference: https://mybinder.readthedocs.io/en/latest/tutorials/dockerfile.html

FROM ghcr.io/krack-bit/sage-binder-env:10.8

ENV DATA_DIR=${NB_HOME}

###===QOL===###

RUN sudo pacman -Sy && sudo pacman -S --noconfirm --needed  \
    gcc \
    # sagetex \
    # python-phitigra \
    && sudo pacman -Scc --noconfirm

RUN uv pip install --no-cache-dir \
    # manim \
    dot2tex \
    igraph \
    \
    #> <https://github.com/pythonprofilers/memory_profiler>
    # python3-memory-profiler \
    # google-perftools \
    \
    #> <https://github.com/bloomberg/memray>
    memray \
    \
    line-profiler

### Jupyterlab Extensions
RUN uv pip install --no-cache-dir \
    # dask-labextension \
    jupyter-server-proxy \
    jupyterlab-code-formatter \
    jupyter-resource-usage

### Language Tools
RUN sudo pacman -Sy && sudo pacman -S --noconfirm --needed  \
    python-ruff \
    # python-isort \
    # python-black \
    && sudo pacman -Scc --noconfirm

### QOL tools
RUN sudo pacman -Sy && sudo pacman -S --noconfirm --needed  \
    jq \
    bat \
    less \
    \
    tree \
    \
    xxhash \
    && sudo pacman -Scc --noconfirm

###===Config===###

RUN sudo mv \
    /usr/share/jupyter/kernels/sagemath/kernel.json \
    /usr/share/jupyter/kernels/sagemath/kernel.json.old

RUN jq -Mc '. + {"metadata": {"debugger": true}}' \
    /usr/share/jupyter/kernels/sagemath/kernel.json.old \
    | sudo tee /usr/share/jupyter/kernels/sagemath/kernel.json

#> Create the jupyter_lab_config.py file with a custom logging filter to
#> suppress the perpetual nodejs warning
RUN mkdir -p ${NB_HOME}/.jupyter
COPY --chown=${NB_USER}:${NB_USER} \
    config/jupyter_lab_config.py \
    ${NB_HOME}/.jupyter/jupyter_lab_config.py

RUN uv run jupyter notebook --generate-config
RUN echo "c.JupyterNotebookApp.default_url = '/lab'" >> ${NB_HOME}/.jupyter/jupyter_notebook_config.py

RUN mkdir -p ${NB_HOME}/.jupyter/lab/user-settings
COPY --chown=${NB_USER}:${NB_USER} \
    config/user-settings/ \
    ${NB_HOME}/.jupyter/lab/user-settings

#> Start in the home directory of the user
#> Make sure the contents of the notebooks directory are in ${HOME}
WORKDIR ${DATA_DIR}
#> NOTE: Always do this last, so each notebook change doesn't invalidate any big steps
COPY --chown=${NB_USER}:${NB_USER} notebooks/* ${DATA_DIR}/

#> For debugging, set to `USER root` and run `docker run --rm -it $(docker build -q .)`
USER ${NB_USER}
# USER root

ENTRYPOINT [ "uv", "run" ]
