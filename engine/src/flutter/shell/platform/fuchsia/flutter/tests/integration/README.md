# `flutter integration tests`

## Configure and build fuchsia

```shell
$ cd "$FUCHSIA_DIR"
$ fx set terminal.x64
$ fx build
```

## Build the test

You can specify the test's package target to build only the test package, with
its dependencies. This will also build the required runner.

```shell
$ cd "$ENGINE_DIR/src"
$ ./flutter/tools/gn --fuchsia <flags> \
      # for example: --goma --fuchsia-cpu=x64 --runtime-mode=debug
$ ninja -C out/fuchsia_debug_x64 \
    flutter/shell/platform/fuchsia/flutter/tests/integration
```


## Start an emulator

```shell
ffx emu start --net tap
```

NOTE: Do _not_ run the default package server. The instructions below describe
how to launch a flutter-specific package server.

## Publish the test packages to the Fuchsia package server

The tests currently specify the Fuchsia package server's standard domain,
`fuchsia.com`, as the server to use to resolve (locate and load) the test
packages. So, before running the test, the most recently built `.far` files
need to be published to the Fuchsia package repo:

```shell
$ fx pm publish -a -repo "$(cat $FUCHSIA_DIR/.fx-build-dir)/amber-files/" \
  -f "$FLUTTER_ENGINE_DIR"/src/out/fuchsia_*64/oot_flutter_jit_runner-0.far
$ fx pm publish -a -repo "$(cat $FUCHSIA_DIR/.fx-build-dir)/amber-files/" \
  -f "$FLUTTER_ENGINE_DIR"/src/out/fuchsia_*64/flutter-embedder-test-0.far
$ fx pm publish -a -repo "$(cat $FUCHSIA_DIR/.fx-build-dir)/amber-files/" \
  -f $(find "$FLUTTER_ENGINE_DIR"/src/out/fuchsia_*64 -name parent-view.far)
$ fx pm publish -a -repo "$(cat $FUCHSIA_DIR/.fx-build-dir)/amber-files/" \
  -f $(find "$FLUTTER_ENGINE_DIR"/src/out/fuchsia_*64 -name child-view.far)
```

## Run the test

```shell
$ ffx test run fuchsia-pkg:://fuchsia.com/flutter-embedder-test#meta/flutter-embedder-test.cm
```

If, for example, you only make a change to the Dart code in `parent-view`, you
can rebuild only the parent-view package target, and republish it.

```shell
$ ninja -C out/fuchsia_debug_x64 \
    flutter/shell/platform/fuchsia/flutter/tests/integration/embedder/parent-view:package
$ fx pm publish -a -repo "$(cat $FUCHSIA_DIR/.fx-build-dir)/amber-files/" \
  -f $(find "$FLUTTER_ENGINE_DIR"/src/out/fuchsia_*64 -name parent-view.far)
```

Then re-run the test as above.

The tests use a flutter runner with "oot_" prefixed to its package name, to
avoid conflicting with any flutter_runner package in the base fuchsia image.
After making a change to the flutter_runner you can re-deploy it with:

```shell
$ ninja -C out/fuchsia_debug_x64 \
    flutter/shell/platform/fuchsia/flutter:oot_flutter_jit_runner
$ fx pm publish -a -repo "$(cat $FUCHSIA_DIR/.fx-build-dir)/amber-files/" \
  -f $(find "$FLUTTER_ENGINE_DIR"/src/out/fuchsia_*64 -name oot_flutter_jit_runner.far)
```

Then re-run the test as above.

From here, you can modify the Flutter test, rebuild flutter, and usually rerun
the test without rebooting, by repeating the commands above.
