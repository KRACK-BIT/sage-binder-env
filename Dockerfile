# Dockerfile for binder
# Reference: https://mybinder.readthedocs.io/en/latest/tutorials/dockerfile.html

FROM local-sage

ENV DATA_DIR=${NB_HOME}

###--MANIM--###

RUN yay -Sy --cleanafter && yay -S --noconfirm --needed --cleanafter  \
    manim \
    # && ~/.local/bin/update_all \
    && yay -Syu --noconfirm --cleanafter

###--Python_Profiling--###

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

### QOL tools
RUN sudo pacman -Sy && sudo pacman -S --noconfirm --needed  \
    bat \
    less \
    xxhash \
    && sudo pacman -Scc --noconfirm

RUN sudo mv \
    /usr/share/jupyter/kernels/sagemath/kernel.json \
    /usr/share/jupyter/kernels/sagemath/kernel.json.old

RUN jq -Mc '. + {"metadata": {"debugger": true}}' \
    /usr/share/jupyter/kernels/sagemath/kernel.json.old \
    | sudo /usr/share/jupyter/kernels/sagemath/kernel.json

# Create the jupyter_lab_config.py file with a custom logging filter to
# suppress the perpetual nodejs warning
RUN mkdir -p ${NB_HOME}/.jupyter
COPY config/jupyter_lab_config.py ${NB_HOME}/.jupyter/jupyter_lab_config.py

RUN uv run jupyter notebook --generate-config
RUN echo "c.JupyterNotebookApp.default_url = '/lab'" >> ${NB_HOME}/.jupyter/jupyter_notebook_config.py

RUN mkdir -p ${NB_HOME}/.jupyter/lab/user-settings
COPY config/user-settings/ ${NB_HOME}/.jupyter/lab/user-settings

#> Start in the home directory of the user
#> Make sure the contents of the notebooks directory are in ${HOME}
WORKDIR ${DATA_DIR}

# NOTE: Always do this last, so each notebook change doesn't invalidate any big steps
COPY notebooks/* ${DATA_DIR}/
RUN sudo chown -R ${NB_USER}:${NB_USER} ${DATA_DIR}

#> For debugging, set to `USER root` and run `docker run --rm -it $(docker build -q .)`
USER ${NB_USER}
# USER root
