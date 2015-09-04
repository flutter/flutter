#!/bin/bash
set -ex

./tools/dart/update.py

(cd sky/unit; ../../third_party/dart-sdk/dart-sdk/bin/pub get)
(cd sky/packages/sky; ../../../third_party/dart-sdk/dart-sdk/bin/pub get)

./sky/tools/download_sky_shell.py sky/unit/packages/sky_engine/REVISION out
