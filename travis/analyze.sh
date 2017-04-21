echo "Analyzing dart:ui library..."
RESULTS=`dartanalyzer                                                          \
  --ignore-unrecognized-flags                                                  \
  --supermixin                                                                 \
  --enable-strict-call-checks                                                  \
  --enable_type_checks                                                         \
  --strong                                                                     \
  --package-warnings                                                           \
  --fatal-warnings                                                             \
  --strong-hints                                                               \
  --fatal-hints                                                                \
  --lints                                                                      \
  out/host_debug_unopt/gen/sky/bindings/dart_ui/ui.dart                        \
  2>&1                                                                         \
  | grep -v "Native functions can only be declared in the SDK and code that is loaded through native extensions" \
  | grep -Ev "The function '.+' (is not|isn't) used"                           \
  | grep -Ev "Undefined name 'main'"                                           \
  | grep -Ev "Undefined name 'VMLibraryHooks"                                  \
  | grep -v "The library ''dart:_internal'' is internal"                       \
  | grep -Ev "Unused import .+ui\.dart"                                        \
  | grep -v "TODO"                                                             \
  | grep -Ev "[0-9]+ errors.*found\."                                          \
  | grep -v "Analyzing out/host_debug_unopt/gen/sky/bindings/dart_ui/ui.dart\.\.\."`

echo "$RESULTS"
if [ -n "$RESULTS" ]; then
  echo "Failed."
  exit 1;
fi
