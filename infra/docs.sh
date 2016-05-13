#!/bin/bash
set -ex

# Install dartdoc.
pub global activate dartdoc

# Generate flutter docs into dev/docs/doc/api/.
(cd dev/tools; pub get)
dart dev/tools/dartdoc.dart

cp dev/docs/google2ed1af765c529f57.html dev/docs/doc/api

# Upload the docs.
if [ "$1" = "--upload" ]; then
  gsutil cp dev/docs/google2ed1af765c529f57.html gs://docs.flutter.io
  gsutil -m rsync -d -r dev/docs/doc/api gs://docs.flutter.io/flutter
fi
