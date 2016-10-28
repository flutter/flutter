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
  | grep -v "\[error\] Native functions can only be declared in the SDK and code that is loaded through native extensions" \
  | grep -Ev "\[(hint|error)\] The function '.+' is not used"                  \
  | grep -Ev "\[(warning|error)\] Undefined name 'main'"                       \
  | grep -Ev "\[(warning|error)\] Undefined name 'VMLibraryHooks"              \
  | grep -v "\[error\] The library ''dart:_internal'' is internal"             \
  | grep -Ev "Unused import .+ui\.dart"                                        \
  | grep -v "\[info\] TODO"                                                    \
  | grep -Ev "[0-9]+ errors.*found."                                           \
  | grep -v "Analyzing \[out/host_debug_unopt/gen/sky/bindings/dart_ui/ui.dart\]\.\.\."`

echo "$RESULTS"
if [ -n "$RESULTS" ];
  then exit 1;
fi
