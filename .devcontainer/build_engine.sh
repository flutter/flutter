#!/usr/bin/bash
#Commands to build the engine inside the devcontainer

export PATH="$PATH:/builds/flutter/engine/src/flutter/third_party/depot_tools/"

cd /builds/flutter
gclient sync -D

cd /builds/flutter/engine/src

# Build RELEASE engine x86
./flutter/tools/gn --runtime-mode release --embedder-for-target --no-build-embedder-examples --enable-fontconfig
ninja -C out/host_release flutter_linux_gtk