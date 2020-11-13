#!/bin/bash
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

# Needed because if it is set, cd may print the path it changed to.
unset CDPATH

# On Mac OS, readlink -f doesn't work, so follow_links traverses the path one
# link at a time, and then cds into the link destination and find out where it
# ends up.
#
# The function is enclosed in a subshell to avoid changing the working directory
# of the caller.
function follow_links() (
  cd -P "$(dirname -- "$1")"
  file="$PWD/$(basename -- "$1")"
  while [[ -L "$file" ]]; do
    cd -P "$(dirname -- "$file")"
    file="$(readlink -- "$file")"
    cd -P "$(dirname -- "$file")"
    file="$PWD/$(basename -- "$file")"
  done
  echo "$file"
)

SCRIPT_DIR=$(follow_links "$(dirname -- "${BASH_SOURCE[0]}")")
SRC_DIR="$(cd "$SCRIPT_DIR/../.."; pwd -P)"
FLUTTER_DIR="$SRC_DIR/flutter"
DART_BIN="$SRC_DIR/third_party/dart/tools/sdks/dart-sdk/bin"
PUB="$DART_BIN/pub"
DART_ANALYZER="$DART_BIN/dartanalyzer"

echo "Using analyzer from $DART_ANALYZER"

"$DART_ANALYZER" --version

function analyze() (
  local last_arg="${!#}"
  local results
  # Grep sets its return status to non-zero if it doesn't find what it's
  # looking for.
  set +e
  results="$("$DART_ANALYZER" "$@" 2>&1 |
    grep -Ev "No issues found!" |
    grep -Ev "Analyzing.+$last_arg")"
  set -e
  echo "$results"
  if [ -n "$results" ]; then
    echo "Failed analysis of $last_arg"
    return 1
  else
    echo "Success: no issues found in $last_arg"
  fi
  return 0
)

echo "Analyzing dart:ui library..."
autoninja -C "$SRC_DIR/out/host_debug_unopt" generate_dart_ui
analyze \
  --options "$FLUTTER_DIR/analysis_options.yaml" \
  --enable-experiment=non-nullable \
  "$SRC_DIR/out/host_debug_unopt/gen/sky/bindings/dart_ui/ui.dart"

echo "Analyzing flutter_frontend_server..."
analyze \
  --packages="$FLUTTER_DIR/flutter_frontend_server/.dart_tool/package_config.json" \
  --options "$FLUTTER_DIR/analysis_options.yaml" \
  "$FLUTTER_DIR/flutter_frontend_server"

echo "Analyzing tools/licenses..."
(cd "$FLUTTER_DIR/tools/licenses" && "$PUB" get)
analyze \
  --packages="$FLUTTER_DIR/tools/licenses/.dart_tool/package_config.json" \
  --options "$FLUTTER_DIR/tools/licenses/analysis_options.yaml" \
  "$FLUTTER_DIR/tools/licenses"

echo "Analyzing testing/dart..."
"$FLUTTER_DIR/tools/gn" --unoptimized
autoninja -C "$SRC_DIR/out/host_debug_unopt" sky_engine sky_services
(cd "$FLUTTER_DIR/testing/dart" && "$PUB" get)
analyze \
  --packages="$FLUTTER_DIR/testing/dart/.dart_tool/package_config.json" \
  --options "$FLUTTER_DIR/analysis_options.yaml" \
  "$FLUTTER_DIR/testing/dart"

echo "Analyzing testing/scenario_app..."
(cd "$FLUTTER_DIR/testing/scenario_app" && "$PUB" get)
analyze \
  --packages="$FLUTTER_DIR/testing/scenario_app/.dart_tool/package_config.json" \
  --options "$FLUTTER_DIR/analysis_options.yaml" \
  "$FLUTTER_DIR/testing/scenario_app"

# Check that dart libraries conform.
echo "Checking web_ui api conformance..."
(cd "$FLUTTER_DIR/web_sdk"; pub get)
(cd "$FLUTTER_DIR"; dart "web_sdk/test/api_conform_test.dart")
