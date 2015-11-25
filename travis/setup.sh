#!/bin/bash
set -ex

(cd; git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git)

cd ..
mv engine src
mkdir engine
mv src engine
cd engine/src

mv travis/gclient ../.gclient
