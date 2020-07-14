#!/bin/bash
set -e
set -x

# web_analysis: a command-line utility for running dart analyzer on Flutter Web
# Engine. Used/Called by LUCI recipes:
#
# See: https://flutter.googlesource.com/recipes/+/refs/heads/master/recipes/web_engine.py

echo "Engine path $ENGINE_PATH"

DART_SDK_DIR="${ENGINE_PATH}/src/out/host_debug_unopt/dart-sdk"
PUB_PATH="$DART_SDK_DIR/bin/pub"
DART_ANALYZER_PATH="$DART_SDK_DIR/bin/dartanalyzer"

echo "Running \`pub get\` in 'engine/src/flutter/lib/web_ui'"
(cd "$WEB_UI_DIR"; $PUB_PATH get)

echo "Running \`dartanalyzer\` in 'engine/src/flutter/lib/web_ui'"
(cd "$WEB_UI_DIR"; $DART_ANALYZER_PATH --enable-experiment=non-nullable --fatal-warnings --fatal-hints dev/ lib/ test/ tool/)
