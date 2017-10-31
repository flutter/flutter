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

echo "Analyzing dart:ui library..."
RESULTS=`dartanalyzer                                                          \
  --supermixin                                                                 \
  --enable-assert-initializers                                                 \
  --initializing-formal-access                                                 \
  --enable-strict-call-checks                                                  \
  --enable_type_checks                                                         \
  --strong                                                                     \
  --no-implicit-dynamic                                                        \
  --package-warnings                                                           \
  --fatal-warnings                                                             \
  --fatal-hints                                                                \
  --lints                                                                      \
  --fatal-lints                                                                \
  out/host_debug_unopt/gen/sky/bindings/dart_ui/ui.dart                        \
  2>&1                                                                         \
  | grep -v "Native functions can only be declared in the SDK and code that is loaded through native extensions" \
  | grep -Ev "The function '.+' (is not|isn't) used"                           \
  | grep -Ev "Undefined name 'main'"                                           \
  | grep -Ev "Undefined name 'VMLibraryHooks"                                  \
  | grep -v "The library ''dart:_internal'' is internal"                       \
  | grep -Ev "Unused import.+ui\.dart"                                         \
  | grep -v "TODO"                                                             \
  | grep -Ev "[0-9]+ errors.*found\."                                          \
  | grep -Ev "Analyzing.+out/host_debug_unopt/gen/sky/bindings/dart_ui/ui\.dart"`

echo "$RESULTS"
if [ -n "$RESULTS" ]; then
  echo "Failed."
  exit 1;
fi
