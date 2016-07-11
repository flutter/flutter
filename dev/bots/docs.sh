#!/bin/bash
set -e

# Install dartdoc.
pub global activate dartdoc

# Generate flutter docs into dev/docs/doc/api/.
(cd dev/tools; pub get)

# This script generates a unified doc set, and creates
# a custom index.html, placing everything into dev/docs/doc
dart dev/tools/dartdoc.dart

# Ensure google webmaster tools can verify our site.
cp dev/docs/google2ed1af765c529f57.html dev/docs/doc

# Upload the docs to cloud storage.
# TODO: remove this when we're comfortable with Firebase hosting.

if [ "$1" = "--upload" ]; then
  # This isn't great, because we're uploading our files twice. But,
  # we're ensuring we're not leaving any deleted files on the server.
  # And we're ensuring we're compressing text files.
  # Unfortunately, rsync can't set Content-Encoding for a subset of files,
  # and rsync can't run in a "only delete files on server that are no
  # longer in the local source dir".

  # Ensure files on server are deleted when no longer in local generated source.
  gsutil -m rsync -d -r dev/docs/doc/ gs://docs.flutter.io/

  # Ensure compressable files are gzipped and then stored.
  gsutil -m cp -r -z "js,json,html,css" dev/docs/doc/* gs://docs.flutter.io/
fi

# Upload new API docs when on Travis and branch is master

if [ "$TRAVIS_PULL_REQUEST" = "false" ]; then
  if [ "$TRAVIS_BRANCH" = "master" ]; then
    cd dev/docs
    firebase deploy --project docs-flutter-io
  fi
fi