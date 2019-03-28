#!/bin/bash

# Reference script for creating patched sdk locally.
# Copy normal dart sources into flutter_patched sdk
mkdir -p out/host_debug_unopt/flutter_patched_sdk/lib
cp -RL out/host_debug_unopt/dart-sdk/lib/ out/host_debug_unopt/flutter_patched_sdk/lib

# Copy stub ui dart sources into flutter_patched sdk
mkdir -p out/host_debug_unopt/flutter_patched_sdk/lib/ui
cp -RL flutter/lib/stub_ui/ out/host_debug_unopt/flutter_patched_sdk/lib/ui

# Copy libraries.json into flutter patched sdk.
cp -RL flutter/flutter_web/libraries.json out/host_debug_unopt/flutter_patched_sdk/lib/libraries.json

# Copy libraries.dart into flutter patched sdk
cp -RL flutter/flutter_web/libraries.dart out/host_debug_unopt/flutter_patched_sdk/lib/_internal/libraries.dart
