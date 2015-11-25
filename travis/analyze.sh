echo "Analyzing dart:ui library..."
RESULTS=`dartanalyzer --ignore-unrecognized-flags --supermixin --enable-strict-call-checks --enable_type_checks --strong --package-warnings --fatal-warnings --strong-hints --fatal-hints --lints out/Debug/gen/sky/bindings/dart_ui.dart 2>&1 | grep -v "\[error\] Native functions can only be declared in the SDK and code that is loaded through native extensions" | grep -Ev "\[hint\] The function '.+' is not used" | grep -v "\[warning\] Undefined name 'main'" | grep -Ev "[0-9]+ errors found." | grep -v "Analyzing \[out/Debug/gen/sky/bindings/dart_ui.dart\]\.\.\."`
echo "$RESULTS"
if [ -n "$RESULTS" ]; then exit 1; fi
