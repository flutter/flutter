FROM ubuntu:16.04

ENV DEPOT_TOOLS_PATH $HOME/depot_tools
ENV ENGINE_PATH $HOME/engine

RUN apt-get update
RUN apt-get install -y git wget curl unzip python lsb-release sudo apt-transport-https

RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $DEPOT_TOOLS_PATH
ENV PATH $PATH:$DEPOT_TOOLS_PATH

RUN mkdir --parents $ENGINE_PATH
WORKDIR $ENGINE_PATH
ADD engine_gclient .gclient
RUN gclient sync

WORKDIR $ENGINE_PATH/src
RUN ./build/install-build-deps.sh --no-prompt
RUN ./build/install-build-deps-android.sh --no-prompt
RUN ./flutter/build/install-build-deps-linux-desktop.sh

 # Add repo for gcloud sdk and install it
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

 RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

 RUN apt-get update && apt-get install -y google-cloud-sdk && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true
