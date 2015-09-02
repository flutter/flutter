#!/bin/bash
set -ex

./tools/dart/update.py

pushd sky/unit
../../third_party/dart-sdk/dart-sdk/bin/pub get
popd

pushd sky/packages/sky
../../../third_party/dart-sdk/dart-sdk/bin/pub get
popd

./sky/tools/download_sky_shell.py sky/unit/packages/sky_engine/REVISION out
