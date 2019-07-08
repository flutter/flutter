#!/bin/bash
echo "Analyzing dart:ui library..."

echo "Using analyzer from `which dartanalyzer`"

dartanalyzer --version

RESULTS=`dartanalyzer                                                          \
  --options flutter/analysis_options.yaml                                      \
  "$1out/host_debug_unopt/gen/sky/bindings/dart_ui/ui.dart"                    \
  2>&1                                                                         \
  | grep -Ev "No issues found!"                                                \
  | grep -Ev "Analyzing.+out/host_debug_unopt/gen/sky/bindings/dart_ui/ui\.dart"`

echo "$RESULTS"
if [ -n "$RESULTS" ]; then
  echo "Failed."
  exit 1;
fi

echo "Analyzing frontend_server..."
RESULTS=`dartanalyzer                                                          \
  --packages=flutter/frontend_server/.packages                                 \
  --options flutter/analysis_options.yaml                                      \
  flutter/frontend_server                                                      \
  2>&1                                                                         \
  | grep -Ev "No issues found!"                                                \
  | grep -Ev "Analyzing.+frontend_server"`
echo "$RESULTS"
if [ -n "$RESULTS" ]; then
  echo "Failed."
  exit 1;
fi

echo "Analyzing tools/licenses..."
(cd flutter/tools/licenses && pub get)
RESULTS=`dartanalyzer                                                          \
  --packages=flutter/tools/licenses/.packages                                  \
  --options flutter/tools/licenses/analysis_options.yaml                       \
  flutter/tools/licenses                                                       \
  2>&1                                                                         \
  | grep -Ev "No issues found!"                                                \
  | grep -Ev "Analyzing.+tools/licenses"`
echo "$RESULTS"
if [ -n "$RESULTS" ]; then
  echo "Failed."
  exit 1;
fi
