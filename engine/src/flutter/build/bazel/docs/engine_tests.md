# The engine's tests

## The Dart platform, the core snapshot and the test fixtures

What GN does in `lib/snapshot/BUILD.gn` and `testing/testing.gni`, on the
rules in `dart/`:

1. `compile_platform` runs the wrapped build's `bootstrap_compile_platform.exe`
   over `lib/snapshot/libraries.json`, which joins the Dart SDK's `sdk/lib`
   tree (`@dart//:sdk_lib`) and `dart:ui` (`//engine/src/flutter/lib/ui:dart_ui`)
   into `flutter_patched_sdk/platform_strong.dill`. The specification's
   relative paths cross from the engine into the Dart tree, which the
   execution root holds as another repository, so the rule stages a GN source
   root of symlinks (each input at its GN path; `tree` places `@dart` at
   `flutter/third_party/dart`) and compiles from it, as `gn_build` does.
2. `core_snapshot` runs the wrapped build's `gen_snapshot --snapshot_kind=core`
   over the platform; `bin_to_assembly` wraps each blob in an assembly file
   with the Dart tree's script (`--incbin`, the blob an
   `additional_compiler_inputs` of the library); `//engine/src/flutter/lib/snapshot:snapshot`
   is the `cc_library` the VM links. The two blobs are byte-identical to the
   GN build's.
3. `flutter_test_fixtures(dart_main = ...)` (testing/testing.bzl) compiles a
   test's Dart entry point to `assets/kernel_blob.bin` with `dart_kernel`: the
   prebuilt SDK's `dartaotruntime` running its `frontend_server_aot.dart.snapshot`
   (`@dart_sdk_linux_x64`, GN's `host_prebuilt_dart_sdk`; the built SDK's
   own pair without the prebuilt, through `dart_wrap:engine_dartaotruntime`
   and `:engine_frontend_server`) against the
   platform and the engine's package configuration. `dart_snapshot_kernel`
   and `dart_snapshot_aot` have macros of their own. In the profile and
   release modes (testing.gni's `is_aot_test`) the kernel is compiled with
   `--aot --tfa` and the wrapped build's `gen_snapshot` turns it into
   `assets/app_elf_snapshot.so` beside it
   (`--//engine/src/flutter/common:runtime_mode=profile`): the fixtures load
   the ELF instead of the kernel, the embedder tests of the AOT data API run
   and the JIT snapshot ones skip, as under GN; the `dart_snapshot_aot`
   target is incompatible in the other modes, so a wildcard build skips it.
   `flutter_tester` keeps the JIT VM in every mode (`shell/testing/BUILD.gn`
   names `libdart_jit` directly), so the Dart tests run their kernels
   unchanged there. Fixtures that are other targets' outputs (GN's
   `fixtures = get_target_outputs(":runtime_stages")`, through
   `filter_include`) are `fixtures_targets`, a dictionary of target to
   patterns, copied into `assets/` with the files; GN's `deps` of the
   template are the library's runfiles, so that the targets producing
   fixtures build with the test.
   An entry point that imports a package from a synced tree
   (`lib/gpu`'s library imports `package:vector_math`) names it in
   `dart_packages`, each mapped to its path under the source root as the
   package configuration knows it: `dart_kernel` stages the package's files
   under a second `--filesystem-root` of symlinks at that path and passes
   the package configuration under the virtual scheme, so that its relative
   package roots resolve the same way on every machine.
   GN's `dest` (`lib/ui/fixtures/shaders/**`: five `test_fixtures` whose
   compiled shaders land in `lib/ui`'s own assets directory, where
   `run_tests.py` points `flutter_tester` for the Dart tests) names the
   package: such a target copies nothing and declares its files
   (`FixturesDestinationInfo`, with an empty `CcInfo` so that GN's groups,
   `cc_library` targets here, can depend on it), and the destination's
   `flutter_test_fixtures` pulls them into its `assets/` from below its
   `deps` through an aspect -- Bazel cannot write into another package's
   directory, and GN itself never links those targets' location libraries
   (they hang off the copy's `deps`). `lib/ui/assets` ends up file for file
   what GN's `gen/flutter/lib/ui/assets` holds. A `copy()` that renames its
   one source (`no_uniforms_alt`, a literal output name) is a `gn_copy` with
   `outs`, which produces the renamed file; other copies pass their sources
   through as before.

Two configuration choices are deliberate. The wrapped build's tools run from
the *target* configuration (`cfg = "target"`), because GN builds `gen_snapshot`
in the host toolchain, which for a host build is the default toolchain, and
the core snapshot must match the VM it is linked with; in a cross build the
tool is the wrap's `gen_snapshot_host`, the host's `gen_snapshot` targeting
the build's CPU, which the wrap places under `clang_<host cpu>/` as GN's
build directory does. And kernels are compiled under a virtual root
(`--filesystem-root .`
`--filesystem-scheme org-dartlang-root`), so that a source's URI in the
kernel is `org-dartlang-root:///engine/src/flutter/...` on every machine
rather than the sandbox's path; a test that needs a library's URI asks
`flutter::testing::GetSourceUri` for it, which the fixtures library compiles
in for each build (GN's is `file://` plus the absolute source root).

## The Dart tests under flutter_tester

`testing/run_tests.py --type dart` runs every `testing/dart/*_test.dart` (and
`vm_service/*_test.dart` with the VM service on) under `flutter_tester` --
GN's `//flutter/shell/testing`, generated like any other package -- in five
variants each: Skia's software renderer, Impeller on Vulkan (SwiftShader,
linked statically) and Impeller on OpenGL ES (`flutter_tester_opengles`,
ANGLE over SwiftShader, which carries the GPU test backends as its
runfiles), the first two also with `--force-multithreading`; `gpu_test` once
more per Impeller backend without Flutter GPU. `testing/testing.bzl`
reproduces this:

1. `flutter_dart_tests` compiles each test to kernel with `dart_kernel`
   (GN's `flutter_frontend_server`) and declares a `flutter_tester_test`
   per variant, `<test>_<variant>`, under a `test_suite`. The test's
   packages -- `package:test` and the thirty packages below it, `vm_service`,
   `ffi`, `vector_math`, `process` -- come from synced trees (`@dart`,
   `@vector_math`, `@process`), staged once by `dart_package_root` at the
   paths the engine's package configuration names them by and shared by
   every compile (`package_roots`); the in-tree ones (`skia_gold_client`,
   `engine_repo_tools`, `lib/gpu`) are `srcs`.
2. `flutter_tester_test` runs the kernel as `run_tests.py` does: from the
   source root (`engine/src` under the runfiles root, where the tests'
   relative paths -- `flutter/lib/ui/fixtures/...`,
   `flutter/testing/resources/...`, `flutter/third_party/skia/resources/...`
   -- resolve), with `--use-test-fonts`, ICU's data file, lib/ui's `assets`
   directory and `--disable-asset-fonts`, the variant's options first and the
   file's own `// FlutterTesterOptions=` line read at run time, and
   `FLUTTER_BUILD_DIRECTORY` (GN's build directory, which
   `shader_test_file_utils.dart` reads) pointing at a scratch directory
   whose `gen/` is the runfiles' `engine/src`: generated files sit at their
   source paths there, which is what GN's `gen/` holds. What the tests read
   rides as `data`: lib/ui's fixture images and compiled shaders at their
   build paths, `testing/resources`, Skia's `resources/images` placed at
   their GN path by `source_tree_files` (a synced tree is an external
   repository, whose runfiles lie elsewhere), the fonts of `txt`'s fixtures,
   and `spawn_helper`'s kernel copied to the root package (GN writes the
   test kernels at the gen root, and `spawn_test` loads that one by path).
3. The compiler's defines are GN's three in the terms of that working
   directory rather than absolute paths: `kFlutterSrcDirectory=flutter`,
   `kFlutterBuildDirectory=.`, `kSkiaGoldWorkDirectory=skia_gold_<test>`;
   plus `kFlutterSrcDirectoryUri=org-dartlang-root:///engine/src/flutter`,
   the source root as the compiler recorded it, which `spawn_test` uses for
   its library lookup where GN's build lets it compose `file://` and the
   absolute path (the same reason as `GetSourceUri` above).

`testing/dart/BUILD.bazel` and `vm_service/BUILD.bazel` are hand-written: the
GN files are a `foreach` over the test list with those absolute defines, and
the run matrix is `run_tests.py`'s, which GN does not have. The outcome is
GN's, run for run: 267 runs, the same `+N` passed count in each as
`run_tests.py --type dart` reports against `host_debug_unopt` (242 of them
print one; 2,334 test cases), and again against `host_profile_unopt` with
`--//engine/src/flutter/common:runtime_mode=profile`. `run_tests.py` leaves
the VM-service tests out of a build directory with `release` in its name;
`flutter_dart_tests(vm_service = True)` makes them incompatible in the
`jit_release` and `release` modes, which a wildcard or suite run skips.

`run_tests.py`'s two remaining runs are its smoke test: `fail_test.dart`
(`testing/smoke_test_failure`, hand-written the same way), a test that fails
on purpose, single- and multithreaded on Skia, run with `expect_failure` --
which in `run_tests.py` only *tolerates* a failure. Under Bazel a test that
cannot fail would say nothing, so `flutter_dart_tests(must_fail = True)`
(`flutter_tester_test`'s `must_fail`, with `variants = ["skia_mt", "skia"]`
for the two runs) requires it: the launcher runs the tester, and passes only
when it exits non-zero *and* the test runner reported a failed test
(`Some tests failed.`) -- a crash before any test ran would not do -- which
is the smoke test's stated point and what a check of the harness's failure
path can assert.

One more of `run_tests.py`'s rules rides on the compilation mode: in a build
directory without `unopt` in its name a Dart test run must not print
`[ERROR` anywhere (`forbidden_output`), the smoke test excepted. Under
`-c opt` -- `tools/gn` without `--unoptimized`, as the wrapped builds take
it -- `flutter_dart_tests` gives every run `forbidden_output = ["[ERROR"]`,
and the launcher, once the run has passed, fails it with the offending
lines if its merged output contains the string; in `fastbuild` and `dbg` the
list is empty and the launcher `exec`s the tester as before.

## The Dart packages' own tests (`--type dart-host`)

`testing/run_tests.py --type dart-host` runs `dart test --reporter=expanded`
in thirteen Dart packages of the tree (`build_dart_host_test_list`: `ci`,
`flutter_frontend_server`, `testing/skia_gold_client`, `tools/api_check`,
`tools/bazel_tools`, `tools/build_bucket_golden_scraper`, `tools/clang_tidy`,
`tools/engine_tool`, `tools/githooks`, `tools/header_guard_check`,
`tools/pkg/engine_build_configs`, `tools/pkg/engine_repo_tools`,
`tools/pkg/git_repo_tools`), each from its own directory in the checkout,
with the build directory's copy of the prebuilt Dart SDK and
`FLUTTER_BUILD_DIRECTORY` set. They are pure Dart -- the engine's tools and
their libraries -- and most of what they test is in the package; a few read
the tree (the builder configurations, `.ci.yaml`, dart:ui's API, `DEPS`) and
`flutter_frontend_server`'s compiles its fixture with the frontend server
and the engine's platform kernel out of the build directory.

`dart_package_test` (`build_defs/dart/package_test.bzl`) runs the same
suite from a runfiles tree shaped like the checkout. Declared in the
package's own BUILD file, it stages the package's files at their paths under
`engine/src/flutter` (`srcs`, every file of the directory but the
`.dart_tool` caches), the engine's package configuration (the one `gclient
sync` wrote, which names every package by a path relative to itself), the
packages of the pub workspace that live in synced trees at the paths the
configuration names them by (`package_trees`: `@dart//:host_package_sources`
-- package:test and everything below it, the analyzer included -- and
`@io`, `@node_preamble`, `@process`, `@process_runner`; the same staging as
`dart_package_root`'s, through runfiles symlinks), the in-tree packages the
tests import (`deps`: each package's `dart_sources` filegroup, which nests
the `dart_sources` of the in-tree packages it imports, so a dependency's
dependencies come along) and what the tests read (`data`). The working
directory is the package's, so `Engine.findWithin()` -- the tools' way to
the checkout, a walk up to a `src` directory holding `flutter` -- finds the
runfiles' `engine/src` as it finds the checkout's.

The launcher runs package:test's own entry point on the VM --
`dart --packages=<the configuration> .../pkgs/test/bin/test.dart
--reporter=expanded` -- which is what `dart test` delegates to once pub has
checked the workspace's resolution. That check wants every `pubspec.yaml`
of the workspace's hundred packages, the lock file, the members'
`workspace_ref.json` files and the pub cache the configuration recorded, and
re-resolves (rewriting `package_config.json`) when any of it disagrees; the
runner reads only the configuration, so the tree stays what was declared
and the run does not depend on pub's freshness heuristics. The outcome is
the same runner over the same files: each package's `+N` count is
`run_tests.py`'s (`engine_tool` 236, `engine_build_configs` 84,
`bazel_tools` 36, `skia_gold_client` 33, `header_guard_check` 23, ...).

`FLUTTER_BUILD_DIRECTORY` is a directory of the runfiles tree named as GN
names a build directory for the mode (`host_debug_unopt` in `fastbuild`,
`host_release` under `-c opt --runtime_mode=release`, ...), holding
`build_directory`'s files -- for `flutter_frontend_server`,
`gen/frontend_server_aot.dart.snapshot` from the prebuilt SDK and
`flutter_patched_sdk/` from `lib/snapshot`, whose platform is a product
build in the release modes, which the test's expected output follows by
reading the directory's name -- and empty for every other package, since
`run_tests.py` sets the variable for every run.

What each package's tests read is declared beside it: `ci/builders/**/*.json`
(`//engine/src/flutter/ci:builder_configs`) and `.ci.yaml` for
`engine_build_configs` and `engine_tool`; `bin/et` and the checkout's
`.gclient` for `engine_tool` (whose `et fetch` runs gclient from its
directory); `DEPS`, `.bazelignore` and `deps.lock.bzl` for `bazel_tools`,
which regenerates them and compares; dart:ui's sources, the web engine's,
`embedder.h`, the headers behind dart:ui and the Java and Swift files that
mirror its enums for `api_check`. The repository root has a `BUILD.bazel`
for the three checkout-level files. One read escapes the tree: `bin/et`
resolves its own location with `realpath`, which follows the runfiles
symlink to the checkout, so `engine_tool`'s entry-point test runs the
checkout's copy of the package on the checkout's prebuilt SDK.

Eleven of the thirteen packages are here, under
`//engine/src/flutter:dart_host_tests`. The two that are not run with
`dart test` in the checkout, as before: `ci`, whose `format_test.dart`
writes files into the checkout, adds them to the git index and runs
`ci/format.sh` over the working tree (a test of the checkout and its git
repository, which no runfiles tree holds and a sandboxed test must not
touch), and `clang_tidy`, whose tests read a GN build directory's
`compile_commands.json` and expect more than a thousand entries in it (a
test of the tool against GN's compilation database, which a Bazel build
does not write). Their BUILD files say so.

## The harness: gtest-parallel

`run_tests.py --type engine` does not run a suite's binary once. Every suite
of its `run_cc_tests` list goes through gtest-parallel
(`flutter/third_party/gtest-parallel`, a DEPS tree; `@gtest_parallel` here)
with `--repeat=2`: the runner lists the suite's tests and runs each in a
process of its own, every test twice, on as many workers as the machine has
cores -- a test that leaks state into its process, or fails the second time
round, fails there, and a single-process run would not see it. The
twenty-seven suites of that list on a Linux host (`gtestParallelSuites` in
bazel_mapping.dart; every suite `bazel test //engine/src/flutter/...` has
except the two Impeller ones, whose builders run the binaries whole, and the
smoke tests of the Bazel setup itself) are therefore `flutter_cc_test`
(testing.bzl) -- a `cc_binary` and a test target that runs it through
`testing/gtest_parallel_run.sh` under the synced Python -- or, for the GTK
shell's, `flutter_display_test(gtest_parallel = True)`, the runner under the
display. The wrapper adds `--repeat=2`, hands Bazel's shards to the runner
(`--shard_count`/`--shard_index`; the `GTEST_*` names an outer wrapper set
are dropped, or each test's process would shard again), keeps the per-test
logs under the test's undeclared outputs (`gtest-parallel-logs/`) and the
runner's timing cache under `TEST_TMPDIR`. The runner's own options come from
`testRuns` (`runnerArgs`: `ui_unittests`' `--timeout=90`, `run_tests.py`'s
"the image release unit test can take a while"); a suite's arguments
(`flow_unittests`' golden directory and font, after `run_tests.py`'s `--`)
follow the binary. A suite's log is then gtest-parallel's: a line per run
(`[N/M] Suite.Test (ms)`, `M` twice the suite's tests) and the failed runs'
output in full. One scheduling difference: `run_tests.py` runs the suites
one after another, each with a worker per core, while Bazel runs tests side
by side -- twenty-seven suites each starting twenty-four workers thrashed
the machine (a 50 ms test took 5 s; the display-list suite ran past its
timeout) -- so each suite reserves eight CPUs from Bazel (`tags = ["cpu:8"]`)
and gives the runner the same eight workers: the same processes and
repeats, three suites at a time on a 24-core host.

## The benchmarks (`--type benchmarks`)

`run_tests.py --type benchmarks` (`run_engine_benchmarks`; of the CI
builders only `host_release_test` asks for it) runs six benchmark
executables -- `shell_benchmarks`, `fml_benchmarks`, `ui_benchmarks`,
`display_list_builder_benchmarks`, `geometry_benchmarks`, `txt_benchmarks`
-- each with `--icu-data-file-path`, and requires exit code 0; google
benchmark itself decides how long each case runs. They are testonly
executables GN does not name `*tests`, so the converter would make them
binaries; the ones in its `benchmarkRuns` table become `cc_test`s instead,
with the ICU argument and `@icu//:icudata`, tagged `benchmark` and `manual`.
`manual` keeps them out of `bazel test //engine/src/flutter/...` as the
other builders' runs leave them out; `//engine/src/flutter:benchmarks` (a
`test_suite`, itself manual) runs the six, and
`//engine/src/flutter:benchmark_binaries` (a filegroup over the six and the
four benchmark binaries nobody runs, `host_release_test`'s build list) keeps
them all compiling in a wildcard build. `//flutter/benchmarking` converts
like any other package over `@benchmark` (google/benchmark, the secondary
tree's GN converted at fetch time; `//flutter/benchmarking`'s GN lost a
config whose include directory was a target label, which contributed
nothing). The sizes follow GN's unoptimized binaries on the host: 10–34 s
for five of them (`medium`), 1,087 s for `ui_benchmarks`, whose one case
completes a 3 MB platform message in a Dart isolate per iteration outside
the timed region (`enormous`); CI runs them optimized. The type's other
half, `run_benchmark_tests` -- `dart test/parse_and_send_test.dart` in
`testing/benchmark` -- reads the checkout's git log (`getGitLog`, `git log`
two directories up), so like `ci`'s tests it stays with `dart` in the
checkout.

## font-subset (`--type font-subset`)

`run_tests.py --type font-subset` is `python3 test.py --variant <build
directory>` in `tools/font_subset`: the script subsets the fixture fonts with
`out/<variant>/font-subset` (16 invocations compared with goldens), runs 17
invocations that must fail, writes the subset fonts to `gen/` beside its
fixtures, and checks that the build packaged the binary in
`out/<variant>/zip_archives/linux-x64/font-subset.zip`. Under Bazel the
package's generated file holds three things. The binary, `cc_binary("font-subset")`
with `alias("_font-subset")`: GN's target `_font-subset` produces
`font-subset` through `output_name`, and a `cc_binary`'s file is its name, so
the converter names the rule after the file and aliases the GN name, as it
does for shared libraries. The archive, `zip_bundle("font_subset")`, GN's
`zip_bundle` converted (below). The test,
`checkout_script_test("font_subset_test")` (`checkout_script_test.bzl`):
`test.py` run under `@cpython3` from its own directory in a writable view of
the checkout-shaped runfiles tree (`checkout_view.bzl`, shared with
`dart_package_test`, which it was lifted from), with the binary and the
archive at their places under `engine/src/out/<variant>` and the variant's
name -- GN's build directory name for the mode -- substituted for
`{variant}` in the script's arguments. 33 invocations, as in the checkout.

## The Android embedding's Java tests (`--type java`)

`run_tests.py --type java` runs Gradle in `shell/platform/android/test_runner`
(the checkout's `third_party/gradle`, JDK 25 as `JAVA_HOME`, the SDK as
`ANDROID_HOME`) over the build directory's `flutter.jar`: an
`com.android.library` module whose only sources are the tests
(`shell/platform/android/test/`, 96 files, 87 test classes), with AGP 9.3.1
and the test dependencies -- Robolectric 4.17, JUnit 4, androidx.test,
Mockito 5.20 as a `-javaagent`, Play Core, ICU4J -- resolved from Maven at
run time, and `robolectric.properties` naming SDK 37 and a shadow. On the
Bazel-built `flutter.jar` that flow passes all 1,565 tests (87 classes, 3
skipped; one Gradle executor died of SIGABRT between classes at four forks
of `-Xmx8g`, and the 20 classes it had not reached passed on a rerun).

Under Bazel (`build_defs/java`; the targets in the android package's
generated file) the same tests are the build's, without
rules_java or rules_jvm_external -- neither is a direct dependency of the
root module -- and the JDK is the engine's `@openjdk` 25, the one
CI's Gradle runs with. `android_tests.artifacts` is the closure Gradle
resolves for the test runtime (`gradle dependencies --configuration
debugUnitTestRuntimeClasspath`, 88 coordinates at the versions its
conflict resolution chose) plus Robolectric's fourteen
`android-all-instrumented` jars for SDK 24 through 37 -- a
`@Config(minSdk, maxSdk)` test runs once per SDK in its range, as Gradle's
`[34]`, `[35]` suffixes show, and Robolectric would otherwise download
each at first use; `maven_lock.py` pins each file (the `.aar` or the
`.jar`, maven.google.com first, Maven Central second) by sha256 into
`maven.lock.bzl` (99 files; the three BOMs have none), and `maven.bzl`'s
`maven_artifacts` repository rule fetches them into
`@maven_android_tests` (2.2 GB, the android-all jars most of it; AARs
unpacked, `classes.jar` and `res/` apart; the android-all jars in one
directory of their own, never on a class path) -- Maven Central's files
from Google's copy of it on Cloud Storage first
(`maven-central.storage-download.googleapis.com`), since repo1.maven.org
limits requests by address and the bots, each fetching the set afresh,
share theirs (429s on a linux_unopt drone). `robolectric.bzl` then:
`java_classes` compiles the 96 files with `@openjdk`'s javac into one jar
(`--release 17`; `android.jar` first on the class path rather than the
boot class path, which javac refuses past release 8 -- what AGP does for
a Java 17 module); `android_test_apk` gives Robolectric what AGP's unit
tests give it, the manifest merged (the module's namespace as its
`package`, `<uses-sdk>` 24/37) and linked by the SDK's aapt2 into a
resource APK; `robolectric_test` runs one class with `@openjdk`'s java --
JUnit's console runner, the `--add-opens` set and `-Xmx8g` from
`build.gradle`, Mockito's agent, `robolectric.offline` over the
android-all directory, and a class-path directory holding
`robolectric.properties` and AGP's `com/android/tools/test_config.properties`
(the manifest, the APK, `android_custom_package`); `robolectric_tests`
declares one per `*Test.java`. A class is found in the jar by its simple
name at run time, since a file's package need not match its directory
(`KeyboardChannelTest.java` under `engine/systemchannels/` declares
`io.flutter.embedding.android`; Gradle too finds classes, not files). The
tests run under an Android configuration, as `flutter.jar` is built under
one (`--config=android_debug_unopt` or any Android build's), on the host's
JVM; `ci/builders`' Android suites carry them for the `java` run_tests
type. Three things the first runs taught: the android-all jars on the
class path break Robolectric's sandbox (`RobolectricInternals.classHandler`
null); `android.jar` must be on the runtime class path, as AGP's mockable
android jar is, since the runner names framework types before the sandbox
exists; and without the resource APK the SDK 34-36 sandboxes resolved the
declared activities against the package `org.robolectric.default` while
SDK 37's did not.

```sh
bazel test --config=android_debug_unopt //engine/src/flutter/shell/platform/android:java_tests
bazel test --config=android_debug_unopt //engine/src/flutter/shell/platform/android:java_tests/io.flutter.embedding.android.FlutterActivityTest
```

Each test tells Bazel's scheduler `resources:memory:3072`: a Robolectric
JVM over the embedding's classes peaks at 2.3 GB resident (the activity
and text-input classes; 0.9 GB on average; sampled every 2 s over the
suite) under the 8 GB heap cap Gradle's forks have too, so an 8-core,
30 GB bot runs six at once, as Gradle ran eight (the 12 GB first
declared here ran them one at a time there: 23 minutes for a suite
Gradle finishes in four). The JVM runs with the C1 compiler alone and the
serial collector (`robolectric.bzl`'s JVM_FLAGS): a JVM that lives
seconds and loads tens of thousands of classes never amortizes C2, and
six G1 collectors' parallel threads on eight cores contend more than they
collect -- measured at six at once on 8 CPUs, the suite's summed time
went 6,605 s → 3,305 (C1 alone) → 2,430 (both), the longest class
418 s → 133, the wall 1,150 s → 467; Gradle's forks have neither flag but
run many classes each. On this host (24 cores, 94 GB) before those flags:
**87 of 87 classes pass** -- 1,567 test cases by JUnit's count (Gradle's
1,565 passed and 3 skipped) -- in 1,119 s at twenty-one at once (the
cores are the limit: 1,509 s at two, about the same at five). The compile
of the 96 files takes 11 s, the resource APK and R classes 4 s.
