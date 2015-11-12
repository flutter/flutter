#!/bin/bash
set -ex

dart dev/update_packages.dart

./travis/download_tester.py packages/unit/packages/sky_engine/REVISION bin/cache/travis/out/Debug
