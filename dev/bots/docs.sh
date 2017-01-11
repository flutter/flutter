#!/bin/bash
set -e

# Install dartdoc.
pub global activate dartdoc 0.9.9

# This script generates a unified doc set, and creates
# a custom index.html, placing everything into dev/docs/doc
(cd dev/tools; pub get)
FLUTTER_ROOT=$PWD dart dev/tools/dartdoc.dart

# Smoke test the docs to make sure we have all the major kinds of things.

if [[ ! -f dev/docs/doc/flutter/widgets/Widget/Widget.html ]]; then
  echo 'Failed to find documentation for Widget class. Are the docs complete?'
  exit 1
fi

if [[ ! -f dev/docs/doc/flutter/dart-io/File/File.html ]]; then
  echo 'Failed to find documentation for File class. Are the docs complete?'
  exit 1
fi

if [[ ! -f dev/docs/doc/flutter/dart-ui/Canvas/drawRect.html ]]; then
  echo 'Failed to find documentation for Canvas.drawRect. Are the docs complete?'
  exit 1
fi

if [[ ! -f dev/docs/doc/flutter/flutter_test/WidgetTester/pumpWidget.html ]]; then
  echo 'Failed to find documentation for WidgetTester.pumpWidget. Are the docs complete?'
  exit 1
fi

# Ensure google webmaster tools can verify our site.
cp dev/docs/google2ed1af765c529f57.html dev/docs/doc

# Upload new API docs when on Travis and branch is master

if [ "$TRAVIS_PULL_REQUEST" = "false" ]; then
  if [ "$TRAVIS_BRANCH" = "master" ]; then
    cd dev/docs
    firebase deploy --project docs-flutter-io
  fi
fi
