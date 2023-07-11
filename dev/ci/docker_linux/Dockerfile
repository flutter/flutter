# Flutter (https://flutter.dev) Development Environment for Linux
# ===============================================================
#
# This environment passes all Linux Flutter Doctor checks and is sufficient
# for building Android applications and running Flutter tests.
#
# To build iOS applications, a Mac development environment is necessary.
#
# This includes applications and sdks that are needed only by the CI system
# for performing pushes to production, and so this image is quite a bit larger
# than strictly needed for just building Flutter apps.

# Last manual update 2021-09-24 (changing this comment will re-build image)

FROM ubuntu:bionic@sha256:eb1392bbdde63147bc2b4ff1a4053dcfe6d15e4dfd3cce29e9b9f52a4f88bc74
MAINTAINER Flutter Developers <flutter-dev@googlegroups.com>

RUN apt-get update -y && \
  apt-get upgrade -y

# Install basics
RUN apt-get install -y --no-install-recommends \
  git \
  wget \
  curl \
  zip \
  unzip \
  apt-transport-https \
  ca-certificates \
  gnupg

# Add repo for chrome stable
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | \
    tee /etc/apt/sources.list.d/google-chrome.list

# Add repo for gcloud sdk and install it
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

RUN apt-get update && apt-get install -y google-cloud-sdk && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true

# Add repo for OpenJDK from JFrog.io
RUN wget -q -O - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add -
RUN echo 'deb [arch=amd64] https://adoptopenjdk.jfrog.io/adoptopenjdk/deb bullseye main' | \
    tee /etc/apt/sources.list.d/adoptopenjdk.list

# Install the dependencies needed for the rest of the build.
RUN apt-get update && apt-get install -y --no-install-recommends \
  adoptopenjdk-11-hotspot \
  build-essential \
  default-jdk-headless \
  gcc \
  google-chrome-stable \
  lib32stdc++6 \
  libglu1-mesa \
  libstdc++6 \
  locales \
  nodejs \
  npm \
  ruby \
  ruby-dev && \
  apt-get clean

ENV JAVA_HOME="/usr/lib/jvm/adoptopenjdk-11-hotspot-amd64"

# Install the Android SDK Dependency.
# In the event of an update you can visit this page: https://developer.android.com/studio and scroll to the bottom to find
# the latest version to update. Be wary of any changes to the name of the package as you will need to adjust the paths below.
ENV ANDROID_SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip"
ENV ANDROID_TOOLS_ROOT="/opt/android_sdk"
RUN mkdir -p "${ANDROID_TOOLS_ROOT}"
RUN mkdir -p ~/.android
# Silence warning.
RUN touch ~/.android/repositories.cfg
ENV ANDROID_SDK_ARCHIVE="${ANDROID_TOOLS_ROOT}/archive"
RUN wget --progress=dot:giga "${ANDROID_SDK_URL}" -O "${ANDROID_SDK_ARCHIVE}"
RUN unzip -q -d "${ANDROID_TOOLS_ROOT}" "${ANDROID_SDK_ARCHIVE}"

RUN mkdir "${ANDROID_TOOLS_ROOT}/cmdline-tools/tools"

RUN mv "${ANDROID_TOOLS_ROOT}/cmdline-tools/NOTICE.txt" "${ANDROID_TOOLS_ROOT}/cmdline-tools/tools"
RUN mv "${ANDROID_TOOLS_ROOT}/cmdline-tools/bin" "${ANDROID_TOOLS_ROOT}/cmdline-tools/tools"
RUN mv "${ANDROID_TOOLS_ROOT}/cmdline-tools/lib" "${ANDROID_TOOLS_ROOT}/cmdline-tools/tools"
RUN mv "${ANDROID_TOOLS_ROOT}/cmdline-tools/source.properties" "${ANDROID_TOOLS_ROOT}/cmdline-tools/tools"

# Suppressing output of sdkmanager to keep log size down
# (it prints install progress WAY too often).
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/cmdline-tools/tools/bin/sdkmanager" "tools" > /dev/null
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/cmdline-tools/tools/bin/sdkmanager" "build-tools;28.0.3" > /dev/null
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/cmdline-tools/tools/bin/sdkmanager" "platforms;android-30" > /dev/null
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/cmdline-tools/tools/bin/sdkmanager" "platform-tools" > /dev/null
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/cmdline-tools/tools/bin/sdkmanager" "cmdline-tools;latest" > /dev/null
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/cmdline-tools/tools/bin/sdkmanager" "extras;android;m2repository" > /dev/null
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/cmdline-tools/tools/bin/sdkmanager" "extras;google;m2repository" > /dev/null
RUN yes "y" | "${ANDROID_TOOLS_ROOT}/cmdline-tools/tools/bin/sdkmanager" "patcher;v4" > /dev/null
RUN rm "${ANDROID_SDK_ARCHIVE}"
ENV PATH="${ANDROID_TOOLS_ROOT}/cmdline-tools/tools:${PATH}"
ENV PATH="${ANDROID_TOOLS_ROOT}/cmdline-tools/tools/bin:${PATH}"
# Silence warnings when accepting android licenses.
RUN mkdir -p ~/.android
RUN touch ~/.android/repositories.cfg

# Add npm to path.
ENV PATH="/usr/bin:${PATH}"

# Set locale to en_US
RUN locale-gen en_US "en_US.UTF-8" && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales
ENV LANG en_US.UTF-8

# Install dependencies for desktop flutter run
RUN apt-get install -y --no-install-recommends \
  clang \
  cmake \
  libgtk-3-dev \
  ninja-build \
	pkg-config \
	x11-xserver-utils \
	xauth \
	xvfb && \
  apt-get upgrade -y --no-install-recommends && \
  apt-get clean
