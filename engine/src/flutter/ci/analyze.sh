#!/bin/bash
echo "Analyzing dart:ui library..."

echo "Using analyzer from `which dartanalyzer`"

dartanalyzer --version

RESULTS=`dartanalyzer                                                          \
  --options flutter/analysis_options.yaml                                      \
  --enable-experiment=non-nullable                                             \
  "$1out/host_debug_unopt/gen/sky/bindings/dart_ui/ui.dart"                    \
  2>&1                                                                         \
  | grep -Ev "No issues found!"                                                \
  | grep -Ev "Analyzing.+out/host_debug_unopt/gen/sky/bindings/dart_ui/ui\.dart"`

echo "$RESULTS"
if [ -n "$RESULTS" ]; then
  echo "Failed."
  exit 1;
fi

echo "Analyzing flutter_frontend_server..."
RESULTS=`dartanalyzer                                                          \
  --packages=flutter/flutter_frontend_server/.dart_tool/package_config.json    \
  --options flutter/analysis_options.yaml                                      \
  flutter/flutter_frontend_server                                              \
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
  --packages=flutter/tools/licenses/.dart_tool/package_config.json             \
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

echo "Analyzing testing/dart..."
flutter/tools/gn --unoptimized
ninja -C out/host_debug_unopt sky_engine sky_services
(cd flutter/testing/dart && pub get)
RESULTS=`dartanalyzer                                                          \
  --packages=flutter/testing/dart/.dart_tool/package_config.json               \
  --options flutter/analysis_options.yaml                                      \
  flutter/testing/dart                                                         \
  2>&1                                                                         \
  | grep -Ev "No issues found!"                                                \
  | grep -Ev "Analyzing.+testing/dart"`
echo "$RESULTS"
if [ -n "$RESULTS" ]; then
  echo "Failed."
  exit 1;
fi

echo "Analyzing testing/scenario_app..."
(cd flutter/testing/scenario_app && pub get)
RESULTS=`dartanalyzer                                                          \
  --packages=flutter/testing/scenario_app/.dart_tool/package_config.json       \
  --options flutter/analysis_options.yaml                                      \
  flutter/testing/scenario_app                                                 \
  2>&1                                                                         \
  | grep -Ev "No issues found!"                                                \
  | grep -Ev "Analyzing.+testing/scenario_app"`
echo "$RESULTS"
if [ -n "$RESULTS" ]; then
  echo "Failed."
  exit 1;
fi