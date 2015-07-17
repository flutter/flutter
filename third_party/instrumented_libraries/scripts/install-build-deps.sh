#!/bin/bash -e

# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Script to install build dependencies of packages which we instrument.

# Enable source repositories in Goobuntu.
if hash goobuntu-config 2> /dev/null
then
  sudo goobuntu-config set include_deb_src true
fi

# TODO(earthdok): find a way to pull the list from the build config.
common_packages="\
atk1.0 \
dee \
freetype \
libappindicator1 \
libasound2 \
libcairo2 \
libcap2 \
libcups2 \
libdbus-1-3 \
libdbus-glib-1-2 \
libdbusmenu \
libdbusmenu-glib4 \
libexpat1 \
libffi6 \
libfontconfig1 \
libgconf-2-4 \
libgcrypt11 \
libgdk-pixbuf2.0-0 \
libglib2.0-0 \
libgnome-keyring0 \
libgpg-error0 \
libgtk2.0-0 \
libnspr4 \
libp11-kit0 \
libpci3 \
libpcre3 \
libpixman-1-0 \
libpng12-0 \
libunity9 \
libx11-6 \
libxau6 \
libxcb1 \
libxcomposite1 \
libxcursor1 \
libxdamage1 \
libxdmcp6 \
libxext6 \
libxfixes3 \
libxi6 \
libxinerama1 \
libxrandr2 \
libxrender1 \
libxss1 \
libxtst6 \
nss \
pango1.0 \
pulseaudio \
udev \
zlib1g \
brltty"

precise_specific_packages="libtasn1-3"
trusty_specific_packages="\
libtasn1-6 \
harfbuzz
libsecret"

ubuntu_release=$(lsb_release -cs)

if test "$ubuntu_release" = "precise" ; then
  packages="$common_packages $precise_specific_packages"
else
  packages="$common_packages $trusty_specific_packages"
fi

# Extra build deps for pulseaudio, which apt-get build-dep may fail to install
# for reasons which are not entirely clear. 
sudo apt-get install libltdl3-dev libjson0-dev \
         libsndfile1-dev libspeexdsp-dev libjack0 \
         chrpath -y  # Chrpath is required by fix_rpaths.sh.

sudo apt-get build-dep -y $packages

if test "$ubuntu_release" = "trusty" ; then
  # On Trusty, build deps for some of the instrumented packages above conflict
  # with Chromium's build deps. In particular:
  # zlib1g and libffi remove gcc-4.8 in favor of gcc-multilib,
  # libglib2.0-0 removes libelf in favor of libelfg0.
  # We let Chromium's build deps take priority. So, run Chromium's
  # install-build-deps.sh to reinstall those that have been removed.
  $(dirname ${BASH_SOURCE[0]})/../../../build/install-build-deps.sh --no-prompt
fi
