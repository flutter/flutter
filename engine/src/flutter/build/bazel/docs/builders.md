# Builder configurations and `et`

## The builders: `--config=<build>` and their install targets

CI's builds are `ci/builders/*.json`: for each, the `tools/gn` flags of its
GN configuration, the ninja targets it builds, the archives it uploads from
`engine/src/out/<target dir>/zip_archives/`, the tests it runs. The
converter reads the Linux and the Mac builder files (`tools/gn_to_bazel`'s
`builders.dart`, run with the rest) and generates two files beside them.
`ci/builders/configs.bazelrc`, which the root `.bazelrc` imports, has a
`build:<name>` configuration per Linux-hosted and Mac-hosted build -- the hosts' own, the
web's, the arm64 cross builds', Android's and iOS's -- whose flags the Bazel build can all express -- `--runtime-mode` is the runtime mode setting,
`--unoptimized` `-c dbg`, GN's `-O0 -g2` (its absence `-c opt`; fastbuild, Bazel's default mode with line tables only, is no GN build and no configuration names it), `--target-dir`
the build directory, `--web` the wasm platform
(`--platforms=//engine/src/flutter/build/bazel/toolchains/emscripten:wasm32_emscripten`,
whose flags carry what `tools/gn`'s `to_gn_wasm_args` sets, LTO on the
optimized build among them -- so for the web `--no-lto` is the flag the
Bazel build cannot express), `--target-os=linux --linux-cpu=arm64` the arm64 platform
(`--platforms=//engine/src/flutter/build/bazel/toolchains:linux_arm64`; the
two flags are read as one, since `--linux-cpu` means nothing without
`--target-os=linux`), `--android --android-cpu=<cpu>` the Android platform
for the CPU (`toolchains:android_arm64`, `android_x64`, `android_arm` --
`tools/gn`'s default when `--android-cpu` is absent -- and
`android_riscv64`; x86 has none, and a build asking for it is listed with
the reason), `--lto`/`--no-lto` the `lto` setting
(`//engine/src/flutter/build/bazel:lto`: `-flto` on the compiles and links
of the clang toolchains; on in an optimized build
without `--no-lto`, as `tools/gn` has it, which is CI's Android AOT and iOS
device builds and linux_benchmarks' `ci/host_release_benchmarks`),
`--thin-lto` the `thin_lto` setting beside it
(`//engine/src/flutter/build/bazel:thin_lto`: `-flto=thin` in place of
`-flto`, in a build with LTO alone, as `tools/gn` passes `use_thin_lto`;
CI's Linux profile and release builds),
`--no-dart-secure-socket` the Dart wrap's `dart_disable_secure_socket` flag
(the size-experiment builds; the archives take their `-size-exp` names from
it), `--enable-vulkan-validation-layers` nothing where GN's default formula
packs the layer already (the debug runtime mode on Android arm64) and a
flag the build cannot express elsewhere, `--embedder-for-target` the
`embedder_for_target` flag (`//engine/src/flutter/build/bazel:embedder_for_target`:
the embedder API's library and header built for the target too, which
`ci/android_embedder_debug_unopt` builds for Android arm), `--enable-fontconfig` the fontconfig flag
(`//engine/src/flutter/txt:use_fontconfig`, which the three `*_desktop`
builds set: txt links the sysroot's libfontconfig and Skia's fontconfig font
manager is built and chosen, as in CI's Linux desktop artifact),
`--no-stripped` the `stripped` flag off (`//engine/src/flutter/build/bazel:stripped`:
whether the shared libraries an install or archive ships are stripped, as
GN's `stripped_symbols`; executables always are; for the web, whose
toolchain strips nothing, the flag is nothing),
`--asan` the asan flag (`//engine/src/flutter/build/bazel:asan`: the
toolchain's `asan` feature on every compile and link, `is_asan` in the
wrapped GN builds, and CI's sanitizer environment --
`testing/sanitizer_suppressions.sh`, leak detection on with its suppression
lists, the toolchain's `llvm-symbolizer` -- exported by every test launcher,
as `run_tests.py --use-sanitizer-suppressions` exports it; and, since an
instrumented build on a Debug VM runs its tests several times slower than
their sizes allow for and `run_tests.py` has no per-test timeout, four times
Bazel's default timeouts), `--dart-debug`
the Dart wrap's `dart_debug` flag (a Debug VM), `--gn-args=dart_dynamic_modules=true`
the wrap's `dart_dynamic_modules` flag (a VM with dynamic modules; the
archives take their `-ddm` names from it), `--prebuilt-dart-sdk` and
`--use-glfw-swiftshader` what the generated files assume,
`--no-prebuilt-dart-sdk` the Dart wrap's `flutter_prebuilt_dart_sdk`
setting off (the Dart SDK from source, above),
`--rbe`/`--no-goma` where the build runs and `--build-embedder-examples` a
target list, neither a flag -- and, for a build with a flag the Bazel build
has no setting for yet, the reason and no configuration (no Linux or Mac
build is in that case today). The developer's own configurations,
`local_engine.json`'s and `local_engine_common.json`'s `linux/` builds
(what `et build --config <name>` runs:
`host_debug`, `host_debug_unopt`, `host_profile`, `host_release`,
`wasm_release`, `wasm_debug_unopt`, `android_debug_arm64`,
`android_debug_riscv64`, `android_debug_unopt_arm64`,
`android_debug_unopt_x64`, `android_profile_arm64`, `android_release_arm64`;
the host ones with `--no-stripped`,
the `stripped` flag off -- shared libraries as linked, where CI's are
stripped), are read with the rest, and a name two builds share with the same
flags -- CI's `ci/wasm_release` and the developer's `linux/wasm_release`,
CI's `ci/android_debug_arm64` and the developer's `linux/android_debug_arm64`
-- is one configuration; where CI's flags differ from the developer's under
one bare name, the developer keeps the name `et` knows and CI's keeps its
prefix as its build directory does: `ci_host_debug` and `ci_host_release`
(`out/ci/host_debug`, `out/ci/host_release`: stripped libraries) beside
`host_debug` and `host_release`, `ci_host_debug_unopt`
(`out/ci/host_debug_unopt`, asan and a Debug VM) beside `host_debug_unopt`,
`ci_android_profile_arm64` and `ci_android_release_arm64` (LTO) beside
`android_profile_arm64` and `android_release_arm64`.
Of the fifty-eight Linux builds, every one has a configuration, fifty-five
distinct: the host's `host_debug`, `ci_host_debug`,
`host_debug_unopt`, `host_profile`, `host_release`, `ci_host_release`,
`host_debug_desktop`,
`host_profile_desktop`, `host_release_desktop`, `host_debug_test`,
`host_profile_test`, `host_release_test`, `ci_host_debug_unopt`,
`host_debug_unopt_impeller_tests`, `host_debug_ddm`,
`host_release_licenses`, `licenses` (the standalone `linux_license.json`'s),
`host_debug_no_prebuilt_dart_sdk`, `host_release_benchmarks`,
`linux_unopt_debug_no_rbe`, `host_debug_clang_tidy`; the web's `wasm_release`,
`wasm_debug_unopt`; the arm64 cross builds' `linux_debug_arm64`, `linux_debug_arm64_desktop`,
`linux_profile_arm64_desktop`, `linux_release_arm64_desktop`; and
Android's `android_debug`, `android_profile`, `android_release` (arm),
`android_debug_arm64`, `android_profile_arm64`, `android_release_arm64`,
`ci_android_profile_arm64`, `ci_android_release_arm64`,
`android_debug_x64`, `android_profile_x64`, `android_release_x64`,
`android_debug_riscv64`, `android_profile_riscv64`,
`android_release_riscv64`, `android_debug_unopt`,
`android_debug_unopt_arm64`, `android_debug_unopt_x64`,
`android_debug_arm64_ddm`, `android_debug_x64_ddm`,
`android_release_arm64_ddm`, `android_release_x64_ddm`,
`android_debug_arm64_size_exp`, `android_release_arm64_size_exp`,
`android_debug_arm64_validation_layers`, `android_debug_arm64_clang_tidy`,
`android_debug_test`, `android_emulator_debug_x64`,
`android_embedder_debug_unopt`. The file ends by naming the builds of
those files that are not configurations at all, each with its reason --
the twelve Fuchsia builds and the three riscv64 Linux builds
(`--linux-cpu=riscv64`), platforms the Bazel build has none for yet, and
the eight web test bundles (no `tools/gn` step) -- so that every build
of the Linux builder files is in one place or the other, and one filed
under the wrong reason shows.

The Mac's builder files (`mac_*.json`, `standalone/mac_*.json`, and
`local_engine.json`'s and `local_engine_common.json`'s `macos/` builds)
are read the same way, after
the Linux ones: sixty-eight builds, sixty configurations distinct (the
eight others are builds that share one, below: the developer's Android and
web builds with the Linux builds of the same names,
`macos/host_debug_unopt_arm64` with `ci/host_debug_unopt_arm64`). A
Mac's build is always a platform of the Bazel build, since `tools/gn`'s
target CPU on a Mac is `--mac-cpu` -- x64 unless given -- and not the Mac's
own: `--mac --mac-cpu arm64` and a host build with `--mac-cpu arm64` are
`--platforms=//engine/src/flutter/build/bazel/toolchains:macos_arm64`, a
host build without the flag (`ci/host_debug` from `mac_host_engine.json`,
an x64 build on CI's arm64 Macs) `:macos_x64`; a plain `bazel build` on a
Mac, with no `--config`, is the host's own as on Linux. A Mac build with a
Linux build's bare name is the same configuration when it is the same build
-- the same flags, ninja targets and tests, as the web's `wasm_release` and
`wasm_debug_unopt` from either host, or a developer's build of everything
with no tests on its flags alone, as `macos/android_debug_arm64` -- and
keeps its OS otherwise, the configuration, the install and the suite alike:
`mac_host_debug`, `mac_host_profile`, `mac_host_release` (the developer's,
`--no-stripped`) with CI's `ci_mac_host_debug`, `ci_mac_host_profile`,
`ci_mac_host_release` beside them (the `ci_` rule applies after the OS's),
`mac_host_debug_clang_tidy`, and `mac_android_profile`, `mac_android_release`
and their `_arm64` and `_x64` forms -- CI's Android AOT builds from a Mac,
whose flags are Linux's but whose targets are the Mac's own `gen_snapshot`.
The Mac-only names stay bare: `host_debug_unopt_arm64` (what a developer
on an Apple-silicon Mac builds; `ci/host_debug_unopt_arm64` and
`macos/host_debug_unopt_arm64` set the same flags), `host_profile_arm64`,
`host_release_arm64`, `host_debug_arm64_tests`, `host_profile_arm64_tests`,
`host_release_arm64_tests`, `host_release_arm64_licenses`,
`mac_debug_arm64`, `mac_profile_arm64`, `mac_release_arm64`,
`mac_release_arm64_tests`, and the `_framework` and `_gen_snapshot` builds
of each mode for either CPU (`host_debug_framework`,
`mac_debug_gen_snapshot_arm64`, ...). The iOS builds have configurations
too: `--ios` is the device platform (`ios_arm64`), `--simulator` the
simulator's of `--simulator-cpu` (`ios_sim_x64` unless given,
`ios_sim_arm64`), each with its mode (`ci_ios_debug`, `ios_debug_sim_arm64`,
`ios_release`, ...); `--darwin-extension-safe` is taken as given -- no GN
file reads it, the framework is app-extension-safe in every build -- so the
`_extension_safe` builds are their counterparts under another name. Their
installs lay `generate_snapshot_bins` and the framework, as their ninja
targets say; the xcframework over the device and simulator builds together,
the recipe's `create_ios_framework.py` step, is a target of its own under
Bazel (`//engine/src/flutter/build/archives:universal_ios_framework`, a
split transition over the three builds), as the Mac's universal framework is
(`:universal_macos_framework`; "The recipe's universal Apple archives"
above).
A Mac build's install and suite are compatible with macOS alone, as their
contents are, so a wildcard build on Linux skips them; its `engine` tests
are the Mac's list in `run_tests.py` (`runTestsEngineSuitesMac`: the common
and non-Windows suites, the Objective-C ones -- `accessibility_unittests`,
`framework_common_unittests`, ... -- `flow_unittests` without the golden
test, the Darwin desktop suites and the Impeller suites), each listed until
its package converts.
`ci/builders/BUILD.bazel` has an `install` per
build over the Bazel counterparts of its ninja targets (a label, a
directory for its target of the same name, a bare unique name, as GN's
ninja files spell them), installing into GN's `--target-dir` -- or, for a
build without one, the directory `tools/gn` names for its flags, which the
install rule reads off its configuration (`checkout_view.bzl`'s
`build_directory_attrs`: `host`, `wasm`, `linux`, `android` or `ios`, the
runtime mode, `_sim`, `_unopt`, and the CPU where it is not the target's
default -- `_arm64`, `_x64`, `_x86`, `_riscv64`) --
(a ninja
target nothing converted answers to would be listed in a comment;
every builder's every target has its counterpart); the host test
builders' `flutter/build/dart:dart_sdk`, GN's `copy_tree` of the prebuilt
SDK into `dart-sdk/`, is `//engine/src/flutter/build/dart:dart_sdk`
(`gn_copy_tree` over the Dart wrap's `prebuilt_dart_sdk`, the files placed
at their paths under `dart-sdk/`; the one `copy_tree` of a directory
outside its package, which the converter's `directorySources` names):

```sh
bazel run --config=ci_host_release //engine/src/flutter/ci/builders:ci_host_release
bazel run --config=ci_host_debug //engine/src/flutter/ci/builders:ci_host_debug
bazel build --config=host_profile //engine/src/flutter:local_engine   # the developer's: everything, read in place (above)
bazel run --config=wasm_release //engine/src/flutter/ci/builders:wasm_release
bazel run --config=linux_debug_arm64 //engine/src/flutter/ci/builders:linux_debug_arm64
```

lay `out/ci/host_release/zip_archives/flutter_patched_sdk_product.zip`,
`out/ci/host_debug/zip_archives/`'s six archives,
`out/wasm_release/zip_archives/flutter-web-sdk.zip` and
`out/ci/linux_debug_arm64/zip_archives/`'s five (`dart-sdk-linux-arm64.zip`
and `linux-arm64/`'s `artifacts.zip`, `linux-arm64-embedder.zip`,
`font-subset.zip` and `impeller_sdk.zip`, every binary in them aarch64)
where the builders' recipes read them. The executables and shared libraries a build's targets
produce (`flutter_tester`, `libpath_ops.so`) land in the build root, as GN
puts them: stripped, with the binaries as linked under `exe.unstripped/`
and `lib.unstripped/` (see the install section). A build with tests also gets a `<name>_tests` suite over the
Bazel suites that stand for its `run_tests.py` types (`dart` is the Dart
tests under flutter_tester with the VM service's and the smoke test,
`dart-host` the Dart packages' own, `benchmarks`, `font-subset`, and
`engine` the 27 executables `run_cc_tests` runs on Linux, or the 33 on a
Mac, each the converted test of that name -- `runTestsTypeSuites`,
`runTestsEngineSuites` and `runTestsEngineSuitesMac` in `builders.dart`),
with the build's other steps
(the formatter, the linters, "Check generated Bazel files") listed as what
they are, scripts of the checkout:
`bazel test --config=host_debug_test //engine/src/flutter/ci/builders:host_debug_test_tests`
runs what `Linux linux_host_engine_test`'s `host_debug_test` runs.

The whole engine tree is a wildcard on either host, each skipping the other
platforms' targets as incompatible rather than failing on them (the
toolchains' and system libraries' OS compatibility above; the files GN
reaches under `is_android` or `build_glfw_shell` carry the same condition):
`bazel test //engine/src/flutter/...` runs 1,427 targets on a Linux x64
host after the roll (1,345 before it: 1,243 pass, 102 skipped -- Android's,
Apple's) and 968 on an
Apple-silicon Mac (873 pass, 95 skipped -- Android's, iOS's, Linux's; the
377 Firefox web suites are `manual` there until a Mac's run of them is on
record), in an hour or two from a warm
cache; `//:framework_tests //:tool_tests //:dart_tests` adds the framework's,
the tool's and the repository's Dart tests on both (on a Mac `//:tool_tests`
skips the desktop shard, compatible with Linux alone; the apple shard is
`//:apple_tool_tests`).

### CI on these configurations without a recipe change

A LUCI builder runs the same install and suites through the unchanged
`engine_v2` recipe: `tools/gn --bazel` writes a `build.ninja` that runs the
build's install target (the recipe's `ninja -C out/<dir> <targets>` runs the
Bazel build), `testing/run_tests.py` runs each `--type` as the build's Bazel
suites, and the Linux and Mac builder files carry `--bazel` among their
builds' flags, in place (the `*_bazel.json` variants they started as were
folded into the originals). The converter
writes the table the scripts read (`build/bazel/builds.json`) with the two
files above. [ci.md](ci.md) has the
design, the limits of the first version and what a recipe change would do
differently.

## `et` with `--backend bazel`

`et build`, `et test`, `et run`, `et query targets` and `et lint` take
`--backend bazel` (or `ET_BACKEND=bazel` in the environment; `gn` otherwise, and
nothing changes for anyone who does not ask), which drives the Bazel build
of the same configuration instead of GN and ninja. `et` asks the converter's code (`tools/gn_to_bazel`'s
`builders.dart`, the same that generates `configs.bazelrc`) which
`--config=<name>` the build has -- `host_debug_unopt` for the developer's
`host_debug_unopt`, `ci_host_debug_unopt` for `ci/host_debug_unopt` -- and
refuses a build the Bazel build cannot express (the
riscv64 Linux builds' `--linux-cpu=riscv64`, the Fuchsia builds'
`--fuchsia`; every other Linux and Mac
build has a configuration). GN labels and patterns are spelled
the Bazel way through the converter's table: `//flutter/fml:fml_unittests`
is `//engine/src/flutter/fml:fml_unittests`, `//flutter/shell/...` is
`//engine/src/flutter/shell/...`, `//flutter/fml:all` is
`//engine/src/flutter/fml:all`; a directory the converter has not converted
is left to Bazel to report.

```sh
et build --backend bazel --config host_debug_unopt //flutter/fml:fml_unittests //flutter/txt/...
et build --backend bazel --config host_debug_unopt        # everything: the local engine, its directory printed
et test --backend bazel --config host_debug_unopt //flutter/fml:fml_unittests
et test --backend bazel --config ci/host_debug_test       # the builder's own suite (its run_tests.py steps)
et query targets --backend bazel //flutter/fml/...        # the rules under fml, as GN labels
et query targets --backend bazel --testonly //flutter/... # the tests
et lint --backend bazel --config host_debug_unopt         # clang-tidy over the build's compile_commands.json
et run --backend bazel --config host_debug_unopt -- -d linux  # the local engine, then flutter run --local-engine
et build --backend bazel --config ci/android_debug_x64 //flutter/shell/platform/android:flutter_jar_zip
et build --backend bazel --config android_debug_unopt_arm64  # the developer's linux/android_debug_unopt_arm64: its local engine, for the Gradle plugin
```

Android builds are named as `et` names them under GN: `ci/android_debug_x64`
for CI's, `android_debug_unopt_arm64` for `local_engine.json`'s
`linux/android_debug_unopt_arm64` (there is no developer `android_debug_x64`
on Linux; `et build --help --verbose` lists what there is). `ci/` builds
are accepted without `--verbose`; `--help` merely hides them.

`et build` with no targets is GN's default target, everything: for a
developer's configuration, the host's or Android's, the `local_engine`
manifest, built in place and its directory printed (`Local engine:
<bazel-out/<cfg>/bin/engine/src/flutter>`, the flags to pass with it; an
Android build's names the host build to pair it with); for a CI build the
install target run into its build directory
(`//engine/src/flutter/ci/builders:<name>` over the build's ninja targets) --
GN's layout from Bazel's outputs, in the directory GN would have used, which
the recipes read. `et run` builds the host's engine and, for another
platform, the target's -- a developer's build through its `local_engine`
manifest, a CI build through its install into its build directory -- and
hands both directories to `flutter run --local-engine[-host]`. `et test` with no patterns runs the build's `<name>_tests` suite, and
errors when the build has no `run_tests.py` step. `et query targets` is
`bazel query 'kind(rule, <patterns>)'` (`tests(<patterns>)` with
`--testonly`), printed as GN labels; it needs no build directory and no
configuration, since the targets are the same under every one, and leaves
out targets of other repositories, which have no GN spelling. It lists
every rule, the converter's own included (a test's `_binary`, a config's
library), where the GN path lists the kinds its parser knows (executables,
libraries, actions, groups). `et lint` under the Bazel backend first
writes the `--config` build's `compile_commands.json` into its build
directory through `compile_commands.py` (the build must have been built:
clang-tidy reads the generated headers) and runs `ci/clang_tidy.sh
--variant <build directory>` against it; the Dart, Java and Python linters
read no build and run as before. `--gn-args`
has no Bazel counterpart (the configuration is the whole of it) and is
refused; `--rbe`, `--lto` and `--build-strategy` are GN's concerns and are
ignored. `et stamp` and the rest stay on GN for now. bazelisk must
be on PATH (`.bazelversion` pins the version); `bazel` is accepted when it
is not.
