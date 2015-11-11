#!/bin/bash
set -ex

(cd packages/cassowary; pub global run tuneup check; pub run test -j1)
(cd packages/flutter_sprites; pub global run tuneup check) # No tests to run.
(cd packages/flutter_tools; pub global run tuneup check; pub run test -j1)
(cd packages/flx; pub global run tuneup check; pub run test -j1)
(cd packages/newton; pub global run tuneup check; pub run test -j1)
(cd packages/playfair; pub global run tuneup check) # No tests to run.
(cd packages/updater; pub global run tuneup check) # No tests to run.

./bin/flutter test --engine-src-path bin/cache/travis
