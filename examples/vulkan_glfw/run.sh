#!/bin/bash
set -xe

#################################################################
# Make the host C++ project.
#################################################################
cmake -Bdebug -DCMAKE_BUILD_TYPE=Debug
pushd debug > /dev/null
make

#################################################################
# Make the guest Flutter project.
#################################################################
if [ ! -d myapp ]; then
    flutter create myapp
fi
pushd myapp > /dev/null
#cp ../../main.dart lib/main.dart
flutter build bundle
popd > /dev/null

#################################################################
# Run the Flutter Engine Embedder
#################################################################
./embedder_example_vulkan ./myapp ../../../../third_party/icu/common/icudtl.dat

popd > /dev/null
