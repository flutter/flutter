# `flutter scenic embedder tests`

## Configure and build fuchsia

For tests that require scenic, for example, run `fx set` with the required
targets; for example:

```shell
$ cd "$FUCHSIA_DIR"
$ fx set core.x64 \
    --with //src/ui/scenic \
    --with //src/ui/bin/root_presenter \
    --with //src/ui/bin/hardware_display_controller_provider
$ fx build
```

Note 1: You could use `--with-base` here, instead of `--with`, but if so, you
would also need to add `--with-base //garnet/bin/run_test_component`. More on
this below, under [Start the package servers](#start-the-package-servers).

Note 2: The `fx set` flags, above, offer a minimized fuchsia platform
configuration to successfully execute the test, but some optional services may
be missing. Be aware that the Fuchsia system logs may include multiple
occurrences `WARNING: error resolving ...` messages, such as the following,
which can be ignored:

```
[pkg-resolver] WARNING: error resolving fuchsia-pkg://fuchsia.com/fonts/0 ...
[pkg-resolver] WARNING: error resolving fuchsia-pkg://fuchsia.com/ime_service/0 ...
[pkg-resolver] WARNING: error resolving fuchsia-pkg://fuchsia.com/intl_property_manager/0 ...
```

## Restart and reboot your device

_(Optional)_ If developing with the emulator, launch (or shutdown and relaunch)
the emulator.

```shell
fx vdl start -N
```

NOTE: Do _not_ run the default package server. The instructions below describe
how to launch a flutter-specific package server.

Or if you've rebuilt fuchsia for a device that is already running a version of
fuchsia, you may be able to reboot without restarting the device:

```shell
$ fx reboot -r
```

If you are building a device that launches the UI at startup, you will likely
need to kill Scenic before running the test.

```shell
$ fx shell killall scenic.cmx
```

## Build the test

You can specify the test's package target to build only the test package, with
its dependencies. This will also build the required runner.

```shell
$ cd "$FLUTTER_ENGINE_DIR/src"
$ ./flutter/tools/gn --fuchsia <flags> \
      # for example: --goma --fuchsia-cpu=x64 --runtime-mode=debug
$ ninja -C out/fuchsia_debug_x64 \
    flutter/shell/platform/fuchsia/flutter/integration_flutter_tests
```

## Publish the test packages to the Fuchsia package server

The tests currently specify the Fuchsia package server's standard domain,
`fuchsia.com`, as the server to use to resolve (locate and load) the test
packages. So, before running the test, the most recently built `.far` files
need to be published to the Fuchsia package repo:

```shell
$ fx pm publish -a -repo "$(cat $FUCHSIA_DIR/.fx-build-dir)/amber-files/" \
  -f "$FLUTTER_ENGINE_DIR"/src/out/fuchsia_*64/flutter-embedder-test2-0.far
$ fx pm publish -a -repo "$(cat $FUCHSIA_DIR/.fx-build-dir)/amber-files/" \
  -f $(find "$FLUTTER_ENGINE_DIR"/src/out/fuchsia_*64 -name parent-view2.far)
$ fx pm publish -a -repo "$(cat $FUCHSIA_DIR/.fx-build-dir)/amber-files/" \
  -f $(find "$FLUTTER_ENGINE_DIR"/src/out/fuchsia_*64 -name child-view2.far)
```

## Run the test (using the package server at `fuchsia.com`)

```shell
$ fx test flutter-embedder-test2
```

## Make a change and re-run the test

If, for example, you only make a change to the Dart code in `parent-view2`, you
can rebuild only the parent-view2 package target, republish it, and then re-run
the test, with:

```shell
$ ninja -C out/fuchsia_debug_x64 \
    flutter/shell/platform/fuchsia/flutter/integration_flutter_tests/embedder/parent-view2:package
$ fx pm publish -a -repo "$(cat $FUCHSIA_DIR/.fx-build-dir)/amber-files/" \
  -f $(find "$FLUTTER_ENGINE_DIR"/src/out/fuchsia_*64 -name parent-view2.far)
$ fx test flutter-embedder-test2
```

From here, you can modify the Flutter test, rebuild flutter, and usually rerun
the test without rebooting, by repeating the commands above.

The embedder tests must be run on a product without a graphical base shell,
such as `core` because it starts and stops Scenic.

## (Alternative) Serving flutter packages from a custom package server

If you want to use a custom package server, you will need to edit these sources:

    * `//flutter/shell/platform/fuchsia/flutter/integration_flutter_tests/embedder/flutter-embedder-test2.cc`
    * `//flutter/shell/platform/fuchsia/flutter/integration_flutter_tests/embedder/parent-view2/parent_view2.dart`

Search for the component URLs with `fuchsia.com`, and change it to `engine`,
which is the domain currently registered with the custom package server in
`//tools/fuchsia/devshell/serve.sh`.

WARNING: Be careful not to check in that change because CI requires using the
`fuchsia.com` domain/package server.

The default fuchsia package server (launched via `fx serve`) is normally
required, unless all of your test's package dependencies are included in the
fuchsia system image. You can force additional packages into the system image
with `fx set ... --with-base <package>` (instead of using `--with`). For
example, in the `fx set` command above, using, `--with-base scenic`, and so on.
Note, however, that the default `core.x64` configuration bundles the test
runner as if it was included via
`--with //garnet/bin/run_test_component`, so to include the test runner in the
system image requires adding that package as well, via `--with-base`, instead.

In order to serve fuchsia package dependencies (like `scenic`, `root_presenter`,
and `hardware-display-controller-provider`), without forcing them into the
system image, you will need to run the fuchsia default package server, via `fx
serve`.

The `flutter/engine` packages (tests and flutter runners, for dart-based tests)
are served from a separate package server. The `flutter/engine` repo's
`serve.sh` script launches this secondary package server, and configures
package URL rewrite rules to redirect fuchsia's requests for flutter- and
dart-runner packages from `fuchsia.com` to flutter's package server instead.

**IMPORTANT:** _The flutter package server must be launched **after** the
default package server, because both `fx serve` and flutter's `serve.sh` set
package URL rewrite rules, and only the last one wins._

Launch each package server in a separate window or shell:

```shell
$ cd "${FUCHSIA_DIR}"
$ fx serve
```

From the flutter engine `src` directory, run the following script to launch the
`engine` package server, to serve the flutter runner and test components.

```shell
$ flutter/tools/fuchsia/devshell/serve.sh --out out/fuchsia_debug_x64 --only-serve-runners
```

## Run the test, using `engine` as the package server domain

```shell
$ fx test flutter-embedder-test2
```

You can recompile and run the test without needing to re-publish the `.far`.
