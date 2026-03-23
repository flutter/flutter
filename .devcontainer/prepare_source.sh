#!/usr/bin/bash
set -e
set -x

sudo chown -R dev:dev /builds
cd /builds

git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$PATH:/builds/depot_tools"

