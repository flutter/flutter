FROM ubuntu:14.04

ENV DEPOT_TOOLS_PATH $HOME/depot_tools
ENV ENGINE_PATH $HOME/engine

RUN apt-get update
RUN apt-get install -y git wget curl unzip python lsb-release sudo

RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $DEPOT_TOOLS_PATH
ENV PATH $PATH:$DEPOT_TOOLS_PATH

RUN mkdir --parents $ENGINE_PATH
WORKDIR $ENGINE_PATH
ADD engine_gclient .gclient
RUN gclient sync

WORKDIR $ENGINE_PATH/src
RUN ./build/install-build-deps.sh --no-prompt
RUN ./build/install-build-deps-android.sh --no-prompt

WORKDIR $HOME/dart
RUN wget https://storage.googleapis.com/dart-archive/channels/dev/release/2.1.0-dev.7.1/sdk/dartsdk-linux-x64-release.zip
RUN unzip dartsdk-linux-x64-release.zip
ENV PATH $PATH:$HOME/dart/dart-sdk/bin

