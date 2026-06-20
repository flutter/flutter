FROM ubuntu:24.04
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN touch /var/mail/ubuntu && chown ubuntu /var/mail/ubuntu && userdel -r ubuntu
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && getent group video >/dev/null || groupadd video \
    && getent group render >/dev/null || groupadd render \
    && usermod -aG video,render $USERNAME \
    && mkdir /etc/sudoers.d \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# install tzdata before the deuid deps script tries to as otherwise will prompt for tz
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Montreal
RUN apt update && apt-get -y install tzdata

# Prerequisites including most of ones from engine repo: src/build/install-build-deps.sh
# BUT src/build/install-build-deps.sh still needs to be run to pick some special case, symlinks, etc.
RUN apt update && apt install -y \
    curl git unzip xz-utils zip python3 build-essential lsb-release sudo \
    clang cmake ninja-build pkg-config \
    liblzma-dev libgl1-mesa-dev libegl1-mesa-dev libdrm-dev \
    libgbm-dev libgles2-mesa-dev libwayland-dev wayland-protocols \
    libxkbcommon-dev \
    bison cdbs dpkg-dev elfutils devscripts fakeroot \
    flex g++ gperf \
    libasound2-dev libbrlapi-dev \
    libbz2-dev libcairo2-dev libcap-dev libcups2-dev libcurl4-gnutls-dev \
    libelf-dev libexif-dev libglib2.0-dev \
    libglu1-mesa-dev libgtk-3-dev libkrb5-dev \
    libnspr4-dev libnss3-dev libpam0g-dev libpci-dev libpulse-dev \
    libsctp-dev libspeechd-dev libsqlite3-dev libssl-dev libudev-dev \
    libwww-perl libxslt1-dev libxss-dev libxt-dev libxtst-dev \
    patch perl python3-pip python3-setuptools \
    python3-dev python3-numpy python3-opencv python3-openssl python3-psutil \
    python3-yaml rpm ruby subversion wdiff \
    libatk1.0-0 libc6 libcap2 libexpat1 \
    libexif12 libfontconfig1 libfreetype6 \
    libpam0g libpcre3 libpixman-1-0 \
    libspeechd2 libstdc++6 libx11-6 libxau6 libxcb1 \
    libxcomposite1 libxcursor1 libxdamage1 libxdmcp6 libxext6 libxfixes3 \
    libxi6 libxinerama1 libxrandr2 libxrender1 zlib1g \
    libasound2t64 libpango-1.0-0 time libxxf86vm-dev
RUN apt update && apt install -y mesa-utils mesa-utils-extra \
    libwayland-client0 libwayland-egl1 libwayland-cursor0 wayland-utils

USER $USERNAME
WORKDIR /home/$USERNAME
