#!/bin/bash
set -ex

# Create an src/ directory to work with.
# TODO(alhaad): This is a temporary hack. Find a better way to do this.
mkdir ../src
mv * ../src
mv .??* ../src
mv ../src .

# Get depot_tools.
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$(pwd)/depot_tools:${PATH}"

# Get dependencies.
sudo apt-get install libdbus-1-dev libgconf2-dev bison gperf wdiff python-openssl libxtst-dev
sudo easy_install pip
sudo pip install requests

# Get gsutil
rm -f gsutil.tar.gz
wget https://storage.googleapis.com/pub/gsutil.tar.gz
tar xzf gsutil.tar.gz

# Setup .gclient file.
cp src/travis/gclient .gclient

cd src
gclient sync
