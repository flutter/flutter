FROM ubuntu:16.04

ENV DEPOT_TOOLS_PATH $HOME/depot_tools
ENV BUILDROOT_PATH $HOME/buildroot
ENV ENGINE_PATH $HOME/engine
ENV PATH $PATH:$DEPOT_TOOLS_PATH

# Notes:
# - libx11-dev is used by Flutter for desktop linux (see also install-build-deps-linux-desktop.sh)
# - chrome is used by Flutter for web.
RUN apt-get update && \
    apt-get install -y git wget curl unzip python lsb-release sudo apt-transport-https && \
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $DEPOT_TOOLS_PATH && \
    mkdir --parents $ENGINE_PATH && \
    git clone https://github.com/flutter/buildroot.git $BUILDROOT_PATH && \
    cd $BUILDROOT_PATH && \
    ./build/install-build-deps.sh --no-prompt && \
    ./build/install-build-deps-android.sh --no-prompt && \
    (echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list) && \
    (curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -) && \
    (wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -) && \
    echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | tee /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get install -y google-cloud-sdk google-chrome-stable libx11-dev && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    apt-get clean
