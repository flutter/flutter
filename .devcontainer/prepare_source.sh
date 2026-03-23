#!/usr/bin/bash
set -e
set -x

sudo chown -R dev:dev /builds
cd /builds

git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
echo 'export PATH="$PATH:/builds/depot_tools"' >> /home/dev/.bashrc
export PATH="$PATH:/builds/depot_tools"

cd flutter
cp engine/scripts/standard.gclient .gclient
gclient sync -D
./engine/src/flutter/build/install-build-deps-linux-desktop.sh