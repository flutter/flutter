FROM ubuntu:bionic@sha256:512274f1739676880585e70eea6a883db7b6d92841b02647b6c92b478356572c

ENV DEPOT_TOOLS_PATH $HOME/depot_tools
ENV BUILDROOT_PATH $HOME/buildroot
ENV ENGINE_PATH $HOME/engine
ENV PATH $PATH:$DEPOT_TOOLS_PATH
ARG DEBIAN_FRONTEND=noninteractive

# Notes:
# - libx11-dev is used by Flutter for desktop linux (see also install-build-deps-linux-desktop.sh)
# - chrome is used by Flutter for web.

# Updates the distribution.
RUN apt-get update 

# Install generic tools.
RUN apt-get install -y ca-certificates gnupg wget curl lsb-release sudo apt-transport-https

# Add additional repos.
#   chrome stable
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | tee /etc/apt/sources.list.d/google-chrome.list
#   gcloud sdk
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
RUN apt-get update

# Install basic tools and libraries
RUN apt-get install -y \
    acpica-tools       \
    autoconf           \
    automake           \
    bison              \
    build-essential    \
    dejagnu            \
    dosfstools         \
    flex               \
    g++-multilib       \
    gettext            \
    git                \
    gperf              \
    groff              \
    ifupdown           \
    libblkid-dev       \
    libc6-dev-i386     \
    libedit-dev        \
    libfreetype6-dev   \
    libglib2.0-dev     \
    liblz4-tool        \
    libncurses5-dev    \
    libssl-dev         \
    libtool            \
    libxcursor-dev     \
    libxinerama-dev    \
    libxrandr-dev      \
    libxxf86vm-dev     \
    lsof               \
    mtools             \
    nasm               \
    net-tools          \
    pkg-config         \
    python             \
    python2.7-dev      \
    tcpdump            \
    texinfo            \
    unzip              \
    uuid-dev           \
    vim                \
    xz-utils           \
    zip                \
    zlib1g-dev

# Install x/gui deps
RUN apt-get install -y \
    libegl1-mesa       \
    libgles2-mesa-dev  \
    libglu1-mesa-dev   \
    libgtk-3-dev       \
    libx11-dev         \
    mesa-common-dev    \
    xvfb

# Install browsers
RUN apt-get install -y \
    google-chrome-stable

# Install and config gcloud
RUN apt-get update && apt-get install -y google-cloud-sdk && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true

# Clone depot_tools
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $DEPOT_TOOLS_PATH

# Clone buildroot
RUN git clone https://github.com/flutter/buildroot.git $BUILDROOT_PATH

# Make engine path and start change directory to buildroot.
RUN mkdir --parents $ENGINE_PATH && \
    cd $BUILDROOT_PATH
