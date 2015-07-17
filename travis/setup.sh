#!/bin/bash
set -ex

# Get depot_tools.
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$(pwd)/depot_tools:${PATH}"

# Get gsutil
rm -f gsutil.tar.gz
wget https://storage.googleapis.com/pub/gsutil.tar.gz
tar xzf gsutil.tar.gz

# Get dependencies.
sudo apt-get install libdbus-1-dev
sudo apt-get install libgconf2-dev
sudo apt-get install python-openssl
sudo easy_install pip
sudo pip install requests

gclient sync --gclientfile=travis/gclient
