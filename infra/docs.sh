#!/bin/bash
set -ex

# Install dartdoc.
pub global activate dartdoc

# Generate flutter docs into dev/docs/doc/api/.
(cd dev/tools; pub get)
dart dev/tools/dartdoc.dart

# Upload the docs.
if [ "$1" = "--upload" ]; then
  gsutil -m rsync -d -r dev/docs/doc/api gs://docs.flutter.io/flutter
fi
