FROM nvcr.io/nvidia/pytorch:24.11-py3 AS base
# ========================================================================================================================
# Install system dependencies
# ========================================================================================================================
RUN apt-get update && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false
# ========================================================================================================================
# Install poetry
# ========================================================================================================================
# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE=1
# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1
# Adds poetry configurations
ENV \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/venv 
ENV \
    POETRY_VIRTUALENVS_CREATE=false \
    POETRY_VIRTUALENVS_IN_PROJECT=false \
    POETRY_NO_INTERACTION=1 \
    POETRY_VERSION=1.8.4
# add venv to path 
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# install poetry 
RUN pip install "poetry==$POETRY_VERSION"
# ========================================================================================================================
# Set up the environment and local directories
# ========================================================================================================================
# Creates a non-root user with an explicit UID and adds permission to access the /app folder
# For more info, please refer to https://aka.ms/vscode-docker-python-configure-containers
RUN mkdir /venv
RUN mkdir /app
RUN mkdir /app/.ruff_cache/
RUN touch /app/.coverage
RUN cat /etc/os-release
RUN chown ubuntu:ubuntu -R \
    /app \
    /app/.coverage \
    /app/.ruff_cache \
    /venv
WORKDIR /app

COPY --chown=ubuntu:ubuntu ./pyproject.toml ./poetry.lock ./

# ========================================================================================================================
# Install python packages
# ========================================================================================================================
USER ubuntu

# # Install python packages
RUN python -m venv $VIRTUAL_ENV
RUN . $VIRTUAL_ENV/bin/activate
RUN poetry config virtualenvs.create false
RUN poetry lock
RUN poetry install --no-root -n
WORKDIR /app/MONAI/
RUN python -m pip install -U pip
COPY --chown=ubuntu:ubuntu \
    ./MONAI/requirements.txt \
    ./MONAI/requirements-min.txt \
    ./MONAI/requirements-dev.txt \
    /app/MONAI/
RUN python -m pip install -U -r /app/MONAI/requirements.txt
RUN python -m pip install -U -r /app/MONAI/requirements-min.txt
RUN python -m pip install -U -r /app/MONAI/requirements-dev.txt

# ========================================================================================================================
# Wait
# ========================================================================================================================
FROM base AS wait
CMD [ "sleep", "infinity" ]
