# [Choice] Debian / Ubuntu version (use Debian 11/9, Ubuntu 18.04/21.04 on local arm64/Apple Silicon): debian-11, debian-10, debian-9, ubuntu-21.04, ubuntu-20.04, ubuntu-18.04
ARG VARIANT=debian-11
FROM mcr.microsoft.com/devcontainers/base:${VARIANT}
WORKDIR /src

# Install Prerrequisites
RUN apt-get update && \
    apt-get install build-essential procps curl file git --no-install-recommends -y && \
    rm -rf /var/lib/apt/lists/*
USER vscode
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)" && \
    sudo chown -R vscode /home/linuxbrew/.linuxbrew/Cellar

# USER vscode
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"

RUN brew install jq gum