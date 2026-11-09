#!/bin/bash
os=$(uname -s | tr '[A-Z]' '[a-z'])
arch=$(uname -m | tr '[A-Z]' '[a-z]' | sed -E 's/^x86_64$/x64/')
rm -f "$1"
cp "../../../flutter/buildtools/$os-$arch/clang/bin/llvm" "$1"
chmod +x "$1"
INCLUDE=${INCLUDE//\\/\/}
"$@"
