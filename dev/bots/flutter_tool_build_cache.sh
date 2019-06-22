#!/bin/bash

pushd "$CIRRUS_WORKING_DIR/packages/flutter_tools"

"$CIRRUS_WORKING_DIR/bin/cache/dart-sdk/bin/pub" run build_runner build

popd
