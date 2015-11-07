#!/bin/bash
set -ex

pub global activate tuneup

(cd packages/cassowary; pub get)
(cd packages/newton; pub get)
(cd packages/flutter_tools; pub get)
(cd packages/unit; pub get)

./travis/download_tester.py packages/unit/packages/sky_engine/REVISION bin/cache/travis/out/Debug
