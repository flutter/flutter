#!/bin/bash
set -ex

# Install dartdoc.
pub global activate dartdoc

# Generate flutter docs into dev/docs/doc/api/.
(cd dev/tools; pub get)

# This script generates a unified doc set, and creates
# a custom index.html, placing everything into dev/docs/doc
dart dev/tools/dartdoc.dart

# Ensure google webmaster tools can verify our site.
cp dev/docs/google2ed1af765c529f57.html dev/docs/doc

# Upload the docs.
if [ "$1" = "--upload" ]; then
  gsutil -m cp -z "js,json,html,css" dev/docs/doc/ gs://docs.flutter.io/
fi
