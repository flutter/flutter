#!/bin/sh
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

SCRIPT_DIR=$(dirname $0)

DISTRO=ubuntu
DIST=trusty

# This is where we get all the debian packages from.
APT_REPO=http://archive.ubuntu.com/ubuntu
APT_REPO_ARM=http://ports.ubuntu.com
REPO_BASEDIR="${APT_REPO}/dists/${DIST}"
KEYRING_FILE=/usr/share/keyrings/ubuntu-archive-keyring.gpg

# Sysroot packages: these are the packages needed to build chrome.
# NOTE: When DEBIAN_PACKAGES is modified, the packagelist files must be updated
# by running this script in GeneratePackageList mode.
DEBIAN_PACKAGES="\
  comerr-dev \
  gcc-4.8 \
  krb5-multidev \
  libasound2 \
  libasound2-dev \
  libatk1.0-0 \
  libatk1.0-dev \
  libavahi-client3 \
  libavahi-common3 \
  libc6 \
  libc6-dev \
  libcairo2 \
  libcairo2-dev \
  libcairo-gobject2 \
  libcairo-script-interpreter2 \
  libcap-dev \
  libcap2 \
  libcomerr2 \
  libcups2 \
  libcups2-dev \
  libdbus-1-3 \
  libdbus-1-dev \
  libdbus-glib-1-2 \
  libdrm2 \
  libelf1 \
  libelf-dev \
  libexif12 \
  libexif-dev \
  libexpat1 \
  libexpat1-dev \
  libffi6 \
  libfontconfig1 \
  libfontconfig1-dev \
  libfreetype6 \
  libfreetype6-dev \
  libgcc1 \
  libgconf-2-4 \
  libgconf2-4 \
  libgconf2-dev \
  libgcrypt11 \
  libgcrypt11-dev \
  libgdk-pixbuf2.0-0 \
  libgdk-pixbuf2.0-dev \
  libgl1-mesa-dev \
  libgl1-mesa-glx \
  libglapi-mesa \
  libglib2.0-0 \
  libglib2.0-dev \
  libgnome-keyring0 \
  libgnome-keyring-dev \
  libgnutls26 \
  libgnutls-dev \
  libgnutls-openssl27 \
  libgnutlsxx27 \
  libgomp1 \
  libgpg-error0 \
  libgpg-error-dev \
  libgssapi-krb5-2 \
  libgssrpc4 \
  libgtk2.0-0 \
  libgtk2.0-dev \
  libk5crypto3 \
  libkadm5clnt-mit9 \
  libkadm5srv-mit9 \
  libkdb5-7 \
  libkeyutils1 \
  libkrb5-3 \
  libkrb5-dev \
  libkrb5support0 \
  libnspr4 \
  libnspr4-dev \
  libnss3 \
  libnss3-dev \
  libnss-db \
  liborbit2 \
  libp11-2 \
  libp11-kit0 \
  libpam0g \
  libpam0g-dev \
  libpango-1.0-0 \
  libpango1.0-dev \
  libpangocairo-1.0-0 \
  libpangoft2-1.0-0 \
  libpangoxft-1.0-0 \
  libpci3 \
  libpci-dev \
  libpcre3 \
  libpcre3-dev \
  libpcrecpp0 \
  libpixman-1-0 \
  libpixman-1-dev \
  libpng12-0 \
  libpng12-dev \
  libpulse0 \
  libpulse-dev \
  libpulse-mainloop-glib0 \
  libselinux1 \
  libspeechd2 \
  libspeechd-dev \
  libssl1.0.0 \
  libssl-dev \
  libstdc++6 \
  libstdc++-4.8-dev \
  libtasn1-6 \
  libx11-6 \
  libx11-dev \
  libx11-xcb1 \
  libxau6 \
  libxau-dev \
  libxcb1 \
  libxcb1-dev \
  libxcb-glx0 \
  libxcb-render0 \
  libxcb-render0-dev \
  libxcb-shm0 \
  libxcb-shm0-dev \
  libxcomposite1 \
  libxcomposite-dev \
  libxcursor1 \
  libxcursor-dev \
  libxdamage1 \
  libxdamage-dev \
  libxdmcp6 \
  libxext6 \
  libxext-dev \
  libxfixes3 \
  libxfixes-dev \
  libxi6 \
  libxi-dev \
  libxinerama1 \
  libxinerama-dev \
  libxrandr2 \
  libxrandr-dev \
  libxrender1 \
  libxrender-dev \
  libxss1 \
  libxss-dev \
  libxt6 \
  libxt-dev \
  libxtst6 \
  libxtst-dev \
  libxxf86vm1 \
  linux-libc-dev \
  mesa-common-dev \
  speech-dispatcher \
  x11proto-composite-dev \
  x11proto-core-dev \
  x11proto-damage-dev \
  x11proto-fixes-dev \
  x11proto-input-dev \
  x11proto-kb-dev \
  x11proto-randr-dev \
  x11proto-record-dev \
  x11proto-render-dev \
  x11proto-scrnsaver-dev \
  x11proto-xext-dev \
  zlib1g \
  zlib1g-dev"

DEBIAN_PACKAGES_X86="libquadmath0"

. ${SCRIPT_DIR}/sysroot-creator.sh
