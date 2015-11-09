#!/bin/bash
set -ex

(cd packages/cassowary; pub global run tuneup check; pub run test -j1)
(cd packages/flutter_tools; pub global run tuneup check; pub run test -j1)
(cd packages/flx; pub global run tuneup check; pub run test -j1)
(cd packages/newton; pub global run tuneup check; pub run test -j1)

./bin/flutter test --engine-src-path bin/cache/travis
