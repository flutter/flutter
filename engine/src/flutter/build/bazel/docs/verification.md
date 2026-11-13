# What to run before landing a change to the Bazel build

## What to run before landing: the suites no single wildcard covers

`bazel test //engine/src/flutter/...` is the engine's gate on either host
(1,427 tests on Linux x64 after the roll, 968 declared on a Mac), but
several suites are
outside it by design, and a change can break one of them without a wildcard
noticing -- as 418 did to the Android tool tests (the facsimile's engine
stamp changed under the Maven repository the Gradle plugin reads; found at
the first rerun, 440) and 436 to a Mac's wildcard (the aggregate `:tests`
listed suites tagged `manual`; a test_suite runs what it lists). The full
set, per host, with what each takes from a warm cache on a 24-core machine:

| Host | Command | What it covers | Time |
|---|---|---|---|
| Linux | `bazel test //engine/src/flutter/...` | the engine: C++ suites, Dart tests under flutter_tester, the web engine's Chrome and Firefox suites, the packages' tests | about 1 h 10 – 1 h 45 |
| Linux | `bazel test //:framework_tests //:tool_tests //:dart_tests` | the framework's 1,644 files, the tool's six shards (general, commands, integration, desktop, web, hermetic), the Dart packages' | about 75 min for the three |
| Linux | `bazel test //:android_tool_tests` | `flutter build apk\|appbundle\|aar` through the tool against the build's Android engine; Gradle from the network | about 50 min |
| Linux | `bazel test --config=android_debug_test //engine/src/flutter/ci/builders:android_debug_test_tests` | the embedding's 87 Robolectric classes, under an Android configuration | about 45 min |
| Mac | `bazel test //engine/src/flutter/...` | the engine on a Mac: the macOS shell and its suites, the Metal backends, the golden suite, Chrome's web suites | about 2 h 20 |
| Mac | `bazel test //:framework_tests //:tool_tests //:dart_tests` | as Linux's, on a Mac -- **one suite at a time on a 1 TB Mac**: the three in one invocation lay more than 500 runfiles trees at once (`--jobs=200`), 160 GB of APFS metadata and links, which emptied a 208 GB disk; `//:framework_tests` alone, then the others, or `--jobs=32` | about 67 min |
| Mac | `bazel test //:apple_tool_tests` | `flutter build macos\|ios`, SwiftPM and the Xcode migrations through the tool against the universal frameworks, and the two Android files' macOS/iOS cases (`apple_cases_shard`) | about 15 min once the frameworks are built |
| Mac | `for c in mac_android_profile mac_android_profile_arm64 mac_android_profile_x64 mac_android_release mac_android_release_arm64 mac_android_release_x64; do bazel run --config=$c //engine/src/flutter/ci/builders:$c -- /tmp/$c; done` | Android from a Mac host: the six Android AOT builders' installs -- the universal gen_snapshot in `darwin-x64.zip`, lib/snapshot's blobs | about 3 min each once the Dart wrap's halves are built |

A change to the tool tests' facsimile (`packages/flutter_tools/BUILD.bazel`'s
cache lists, `bin/internal`'s stamps, `build_defs/android/build_tools.bzl`,
`build_defs/dist/local_engine.bzl`) wants the second, third and seventh; a
change to a test macro (`build_defs/web/web_ui_tests.bzl`,
`build_defs/dart/dart_test.bzl`, `build_defs/java/robolectric.bzl`) the
suites it declares on both hosts; a change to the engine's rules the
wildcard on both; a change to the Android toolchains, the NDK overlay, the
Dart wrap or the Android shell's file the eighth besides the Linux Android
builds. `bazel query 'tests(<suite>)' | wc -l` says what a suite
holds on this host before a run. Disk: the framework tests' kernels and the
engine's extra configurations write on the order of a gigabyte a minute at
full load, and the home-directory disk cache (`--disk_cache` in the root
`.bazelrc`, collected to its cap by the idle server) grows with them -- the
cache can regrow far past its cap between two runs with no idle time
between them (56 GB was seen); a build
with `--experimental_disk_cache_gc_max_size=10G
--experimental_disk_cache_gc_idle_delay=10s` collects it on demand.

After a rebase or a roll, before any of them, the generated files: `DEPS`
feeds `deps.lock.bzl` (`gen_deps.dart --check` in `tools/bazel_tools`),
`pubspec.lock` and lib/web_ui's feed `pub.lock.bzl` (`gen_pub_lock.dart
--check` there too, after `dart pub get` at the root and in lib/web_ui so the
package configurations match the locks), the GN files feed the BUILD files
(`gn_to_bazel.dart --check` in `tools/gn_to_bazel`), and the recipe's CI
sequence runs by hand (`ci.md`). A stale `pub.lock.bzl` makes the tool's
tests run against pub packages the lock has moved past; the `bazel_tools`
tests catch it (`pub_lock_current_test.dart`).
