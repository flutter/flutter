#!/bin/bash
set -ex

(cd packages/cassowary; pub get)
(cd packages/newton; pub get)
(cd packages/flutter_tools; pub get)

pub global activate tuneup
