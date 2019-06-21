#!/bin/bash

pushd "$CIRRUS_WORKING_DIR/flutter/packages/flutter_tool"

pub run build_runner build_runner

popd
