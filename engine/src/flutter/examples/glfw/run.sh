#!/bin/bash
set -e # Exit if any program returns an error.

#################################################################
# Make the host C++ project.
#################################################################
if [ ! -d debug ]; then
    mkdir debug
fi
cd debug
cmake -DCMAKE_BUILD_TYPE=Debug ..
make

#################################################################
# Make the guest Flutter project.
#################################################################
if [ ! -d myapp ]; then
    flutter create myapp
fi
cd myapp
cp ../../main.dart lib/main.dart
flutter build bundle
cd -

#################################################################
# Run the Flutter Engine Embedder
#################################################################
./flutter_glfw ./myapp ../../../../third_party/icu/common/icudtl.dat
