# Dart Runner Tests

Contains tests for the Dart Runner and their corresponding utility code

### Running the Tests
<!-- TODO(erkln): Replace steps once test runner script is updated to run Dart runner tests -->
- The tests can be run using the Fuchsia emulator
```
fx set workstation_eng.qemu-x64
ffx emu start --headless
```
- Start up the package server
```
fx serve
```
- Prepare the BUILD files
```
$ENGINE_DIR/flutter/tools/gn --fuchsia --no-lto
```
- Build the Fuchsia binary with the test directory as the target (ie. `flutter/shell/platform/fuchsia/dart_runner/tests/startup_integration_test`)
```
ninja -C $ENGINE_DIR/out/fuchsia_debug_x64 flutter/shell/platform/fuchsia/dart_runner/tests/startup_integration_test
```
- Deploy/publish test FAR files to Fuchsia
```
$FUCHSIA_DIR/.jiri_root/bin/fx pm publish -a -repo $FUCHSIA_DIR/$(cat $FUCHSIA_DIR/.fx-build-dir)/amber-files -f $ENGINE_DIR/out/fuchsia_debug_x64/dart-jit-runner-integration-test-0.far
```

Note that some tests may have components that also need to be deployed/published (ie. `dart_jit_echo_server` also needs to be published for the Dart JIT integration test to run successfully)

```
$FUCHSIA_DIR/.jiri_root/bin/fx pm publish -a -repo $FUCHSIA_DIR/$(cat $FUCHSIA_DIR/.fx-build-dir)/amber-files -f $ENGINE_DIR/out/fuchsia_debug_x64/gen/flutter/shell/platform/fuchsia/dart_runner/tests/startup_integration_test/dart_jit_runner/dart_jit_echo_server/dart_jit_echo_server/dart_jit_echo_server.far
```
- Run the test
```
ffx test run "fuchsia-pkg://fuchsia.com/dart-jit-runner-integration-test#meta/dart-jit-runner-integration-test.cm"
```

Notes:
- To find the FAR files, `ls` into the output directory provided to the `ninja` command
