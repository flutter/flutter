#!/bin/bash

pushd "$CIRRUS_WORKING_DIR/packages/flutter_tool"

pub run build_runner build_runner

popd
