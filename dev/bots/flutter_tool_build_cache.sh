#!/bin/bash

pushd "$CIRRUS_WORKING_DIR/packages/flutter_tools"

pub run build_runner build

popd
