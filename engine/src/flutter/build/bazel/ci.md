# The engine's CI on Bazel

How a LUCI builder builds and tests the engine with Bazel through the
unchanged `engine_v2` recipe, what that costs, and what a recipe change would
buy. Everything here lives in this repository.

## What the recipe does, and where this repository gets a word in

The `engine_v2/builder` recipe (flutter/recipes, `recipes/engine_v2/builder.py`
and `recipe_modules/build_util`) builds one build of a builder file
(`ci/builders/<name>.json`) in a fixed sequence, every step of which runs a
file of this checkout:

1. `gclient sync` of the checkout with the build's `gclient_variables`, into
   the bot's persistent `builder` cache (bot_update cleans untracked files,
   not ignored ones; `clobber` wipes the cache).
2. `python3 flutter/tools/gn <the build's gn flags>` (plus `--no-goma --no-rbe`
   for an official build, `--no-lto` under the `no_lto` property,
   `--rbe-server-address=...` with `--rbe`, `--gn-args=engine_version=...` on
   the monorepo project).
3. `<checkout>/third_party/ninja/ninja -C out/<config> [-j N] <ninja targets>`.
4. The build's `tests`: `[language] <checkout>/<script> <parameters>`, from
   `engine/src/flutter`, with `FLUTTER_LOGS_DIR` and the step's `env`;
   `testing/run_tests.py --variant <dir> --type ...` among them.
5. The build's `generators` (scripts over `out/<dir>`), then its `archives`
   (files under `out/<dir>/zip_archives/...`, uploaded to a GCS prefix the
   `realm` picks), then a CAS archive of `out/<name>` for the global steps.

Steps 2 and 4 are scripts of this repository; step 3 runs whatever
`build.ninja` step 2 left in the directory. That is enough:

- **`tools/gn --bazel`** writes no GN build. It looks the flag list up in
  `build/bazel/builds.json` -- the converter's table of every build of the
  builder files, with the Bazel configuration (`ci/builders/configs.bazelrc`)
  and install target (`ci/builders/BUILD.bazel`) each amounts to -- and writes
  into the build directory a `build.ninja` with one edge, which runs
  `bazelisk run --config=<name> //engine/src/flutter/ci/builders:<name> --
  <dir>` (the build's install: what its ninja targets build, laid into the
  directory as GN lays it), and a phony edge per ninja target of the build, so
  that the recipe's `ninja -C out/<dir> <targets>` is satisfied by that one
  run. Beside it goes `bazel.json`: the configuration, the Bazel suites of the
  build's test types, the paths.
- **`testing/run_tests.py`** reads `bazel.json` when it is there and runs each
  `--type` as `bazelisk test --config=<name> <the type's suites>` -- the
  suites `ci/builders/BUILD.bazel` already declares per builder (the C++
  suites of the `engine` type, the Dart tests on flutter_tester, the packages'
  `dart test`s, the Java tests, ...). A test executable a step runs from the
  build directory is `run_tests.py --type binaries` in a Bazel build: the
  Bazel test of the same executable. A `--type` the build runs no Bazel test
  for is an error, not a silent pass.
- **The builder files** carry `--bazel` among each build's flags (and
  `--no-rbe` in place of `--rbe`, with `use_rbe: false` and
  `download_bazelisk: true` among the gclient variables: Bazel's actions run
  on the bot). The Linux engine builders build this way themselves, in
  place: cocoon admits a new `.ci.yaml` target only as `bringup: true`, which
  never runs in presubmit, so a build that is to be tested on a PR has to be
  an existing builder's. A `<file>_bazel.json` variant beside an original (a
  Mac's, when it comes) is still accepted and checked the same way. The
  converter refuses a build with `--bazel` that has no configuration or
  install, and a variant's build that is not, infrastructure flags apart, a
  build of the original -- which is what `tools/gn --bazel` would refuse on
  the bot.
- **bazelisk** comes from `DEPS` under the gclient variable
  `download_bazelisk` (off by default; the Bazel builds set it), as the
  CIPD package `infra/3pp/tools/bazelisk`; it fetches the Bazel release
  `.bazelversion` names. A developer's own bazelisk on `PATH` serves too.
- **The edge runs the install through `bazel_ci.py install <dir>`**, which
  reads `bazel.json` and starts bazelisk with every inherited file
  descriptor above stderr closed. ninja learns that a console-pool command
  is done when every holder of a pipe it hands the child has closed it; the
  Bazel server the client starts inherits what the client has and lives on
  after the command (its idle timeout is hours), and ninja waited on it --
  the first end-to-end run hung after a finished install. A shell loop over
  `exec N>&-` did the same on a host whose `/bin/sh` is bash; the bots' is
  dash, which has no descriptors above 9 (`exec: 10: not found`, the first
  presubmit run), and Python's `close_fds` has no such limit.
- **The recipe's `--no-lto`.** cocoon sets the `no_lto` property on a
  release builder's presubmit builds and the recipe appends `--no-lto` to
  the flags; a build whose own flags lack it matches without it and runs
  with LTO off (`--//engine/src/flutter/build/bazel:lto=false` after its
  configuration, in the install and the tests alike: `bazel.json`'s
  `options`).
- **One output root for the install and the tests.** `run_tests.py` runs
  its Bazel commands from `bazel.json`'s recorded startup and build options
  rather than recomputing them: computed again from the checkout root they
  landed two directories above it (`repo_root` of a root), and the tests
  rebuilt the build in a second output root -- outside the bot's cache,
  25 GB under a developer's home.
- **Bazel's state** -- the output root, bazelisk's download, the disk cache --
  lives under the checkout's `.bazel_ci/` (ignored by git, in the bot's
  `builder` cache), not under `out/` (which the recipe clobbers) or the bot's
  home (which may not outlive the task): a bot's second build of a
  configuration is incremental. `--config=ci` (the root `.bazelrc`) keeps the
  output readable in a log; `bazel_ci.py` puts the disk cache under
  `.bazel_ci/disk_cache` (capped at 40 GB) because a builder file's builds
  run one after another in one checkout and the flags that tell them apart
  (asan, unoptimized, dart_debug) reach the exec configuration, whose output
  directory does not spell them -- without the cache each switch rebuilds the
  host tools (the first end-to-end run paid 10 minutes for it between
  `ci/host_debug` and a second `ci/host_debug_unopt`).
- **The install runs once per build.** The edge has no inputs ninja could
  compare, so `tools/gn --bazel` removes the previous run's
  `bazel_install.stamp` when it writes the directory; a second `ninja` in the
  same build is "no work to do", as under GN.
- **`icudtl.dat` is at the root of every install that links ICU**, as GN's
  `copy_icudata` lays it from `icuuc`'s dependency edge (the install's
  `flutter_tester` loads it from there without `--icu-data-file-path`).

The shared code is `build/bazel/bazel_ci.py` (`bazel_ci_test.py` tests it;
`tools/gn_test.py` covers the flag). The module runs under the recipe's
`python3` with the standard library alone.

### The sequence by hand

What a bot does, from `engine/src` of a synced checkout
(`download_bazelisk: true` in the `.gclient`'s custom vars, or bazelisk on
`PATH`):

```sh
python3 flutter/tools/gn --target-dir ci/host_debug_unopt --runtime-mode debug \
    --unoptimized --prebuilt-dart-sdk --asan --dart-debug --no-rbe --no-goma --bazel
../../third_party/ninja/ninja -C out/ci/host_debug_unopt flutter/tools/font_subset \
    flutter:unittests flutter/build/dart:dart_sdk flutter/shell/testing sky_engine
python3 flutter/testing/run_tests.py --variant ci/host_debug_unopt \
    --type dart,dart-host,engine,font-subset --engine-capture-core-dump
```

The first command writes `out/ci/host_debug_unopt/build.ninja` and
`bazel.json`; the second runs the Bazel build and install (the ninja targets
named are the builder file's, any of them: the one edge satisfies them all);
the third runs the four types' suites with `--config=ci_host_debug_unopt`.
`ninja -n` shows the command without running it.

The whole of both sequences (then the `linux_unopt_bazel.json` and
`linux_host_engine_bazel.json` variants, since folded into the originals), run
this way on a 24-core
workstation from a warm output root (10-31, before the GitHub run): every
`tools/gn --bazel`, ninja and archive step passed -- `ci/host_debug_unopt`'s
install 1,367 files, its `run_tests.py` 307 of 308 in 68 minutes (the one
failure is this workstation's GDK leaking under LSAN, a host finding from
before, not CI's image), `check_build_configs.sh`, the licenses build and
its test runner, `ci/host_debug`'s 67 files and six archives (36 minutes,
the GL wrap rerunning), `ci/host_release`'s archive, `verify_exported.dart`
(0 failing checks, with the recipe's `ENGINE_CHECKOUT_PATH`), `et stamp`.
Two steps of the originals are worth knowing when reading a run: `tools/
gn_test.py` wants `prebuilts/SDKs` for its `--ios` case unless
`LUCI_CONTEXT` is set (as it is on a bot; 6 of 6 with it), and the "test:
service protocol" step runs from `engine/src/flutter` with a path relative
to `engine/src`, where `test.dart` prints "Error launching shell" and exits
0 -- a silent no-op under GN too; the Bazel suite's
`//engine/src/flutter/shell/testing/vm_service:service_protocol_test` runs
the test for real, and so does the command from `engine/src`.

### Which builders build with Bazel, and where that stops

- With Bazel, in place: `linux_host_engine` (`ci/host_debug` and
  `ci/host_release`, their archives, and the global generators -- the
  symbol-export check, the API docs, the engine stamp), `linux_host_engine_ddm`,
  `linux_host_engine_test` (the three test builds, their `run_tests.py` types
  as Bazel suites), `linux_host_desktop_engine`, `linux_arm_host_engine`,
  `linux_arm_host_desktop_engine`, `linux_android_aot_engine` (and `_ddm`,
  `_size_exp`), `linux_android_debug_engine` (and `_ddm`), `linux_web_engine`
  (`ci/wasm_release`), and `linux_unopt`'s builds but one. A try build's
  archives go where they always went for a try build (the recipe's archives
  module routes the try bucket to `flutter_archives_v2`, never to the release
  bucket the tool downloads from).
- Still GN, and why: `linux_unopt`'s `ci/host_debug_no_prebuilt_dart_sdk`
  (the Dart SDK from source; `--config=host_debug_no_prebuilt_dart_sdk`
  exists for a developer, a cold bot has no time for it); `linux_clang_tidy`
  (clang-tidy over GN's compile database); `linux_android_emulator_tests`
  (`run_tests.py --type android` runs the C++ suites on the emulator: no
  Bazel counterpart yet); `local_engine_builds` (local_engine.json's builds
  are `bazel build` targets without installs); the Fuchsia builders; the
  standalone files (`linux_license`, `linux_benchmarks`, `linux_clangd`);
  Mac and Windows. A Mac's builds have their configurations and installs
  (`mac_*.json`), and `tools/gn --bazel` knows the host: a Mac builder
  switches as the Linux ones did, or as a `mac_*_bazel.json` variant first.
- Steps left out of a Bazel build: the malioc diff (GN's Mali offline
  compiler analysis), and `linux_host_engine_test`'s benchmark-metrics dry
  runs (`generate_metrics.sh` and `upload_metrics.sh --no-upload` run
  benchmark executables from the directory, which the install does not lay:
  the `benchmarks` type runs them as Bazel tests; the real upload is
  `linux_benchmarks`, GN). The licenses test runner, an executable the
  original ran from the directory, runs as `run_tests.py --type binaries`.
- Global tests (`tests` at the top of a builder file, run on tester drones
  against the CAS archive of `out/<name>`) stay what they are: a tester
  drone has the installed directory, laid out as GN lays it, and not the
  Bazel outputs, so the Bazel builds keep their tests local to the
  builder's drone.
- No remote cache and no remote execution. The bot builds from its `.bazel_ci`
  output root: incremental when the bot has built the configuration before,
  from scratch otherwise (the first `ci/host_debug_unopt` on a fresh 32-core
  bot: the wrapped Dart SDK build alone is 15–25 minutes; the whole build and
  its tests on the order of two hours, which is why the switched targets'
  timeouts are 240 minutes). Disk: an output root of a test build is tens
  of gigabytes.
- Presubmit: the switched builders run on every PR as they did under GN,
  which is the point. A new `.ci.yaml` target cannot do that: cocoon admits
  it only as `bringup: true`, which runs in postsubmit on the staging pool
  until the usual promotion.

## What a recipe change would do differently

Everything above works around one fact: the recipe only knows `tools/gn`,
`ninja` and a list of script steps. With a change to flutter/recipes
(`engine_v2/builder.py`, `build_util`, `shard_util`) the same build would be
simpler, faster and better reported:

1. **A `bazel` tool beside `ninja`.** A build's `ninja` block gains a
   `"tool": "bazel"` (the recipe already dispatches on `ninja.tool`), and the
   recipe runs `bazelisk run --config=<name> <install> -- out/<dir>` itself:
   no `tools/gn --bazel`, no synthetic `build.ninja`, no table of flags to
   match -- the builder file names the configuration directly
   (`"bazel": {"config": "ci_host_debug_unopt", "install": "..."}`). The
   flags-to-configuration mapping stays in the converter for `et`.
2. **`bazel test` as the test step, with its results.** `run_tests.py` is
   bypassed: the recipe runs `bazelisk test --config=<name> <suite>` and
   uploads the Build Event Protocol (`--build_event_binary_file`) or the
   test.xml files to ResultDB (`rdb stream` around the step, or the BEP
   uploader), so that every test case is a result in LUCI rather than a line
   in a step log, with history, flake detection and the tree-closing rules
   that come with it. Failed tests' logs stop being copied by hand.
3. **bazelisk and Bazel from the recipe's dependencies.** `flutter_deps`
   provides tools by CIPD package (`open_jdk`, `goldctl`, ...); `bazelisk`
   joins them, and Bazel's own release is fetched once into a named cache
   rather than per checkout, with `BAZELISK_HOME` and `--output_user_root` set
   by the recipe to named caches the infra sizes and evicts (today they are
   directories of the checkout cache the scripts chose).
4. **A remote cache, and later remote execution.** `--remote_cache` against a
   GCS bucket or a RBE CAS, with `--google_default_credentials` under the
   bot's service account, makes a fresh bot's build mostly a download and
   lets try builds share the postsubmit's artifacts; `--bes_backend` gives
   invocation pages. RBE execution (`--remote_executor`) replaces reclient
   for the C++ actions. Both need infra outside this repository (buckets,
   credentials, a pool), which is why v1 has neither.
5. **Archives from `bazel-bin`, no install.** The install exists to lay out
   GN's directory for the recipe's `archives` paths and generators. A recipe
   that asks Bazel for the artifacts (`bazel build //engine/src/flutter/
   build/archives:artifacts` and `bazel cquery --output=files` for the paths,
   or an install into a directory named by the recipe) drops the GN layout
   from the build and the `--target-dir` from the configuration. The global
   generators (`verify_exported.dart`, the frameworks' packaging) would take
   their inputs as files rather than as `out/ci/*`.
6. **Sharding by Bazel rather than by drone.** Today a builder file splits
   work into builds that each get a drone and a checkout. With the recipe
   driving Bazel, one drone can run `bazel test` over several
   configurations, or the tests of a build can be split with
   `--test_sharding_strategy` and Bazel's own `shard_count`, and the
   tester-drone shape (CAS of `out/<name>`, `tester_engine.py`) is not needed:
   the test runs where the build ran, from the cache.
7. **One configuration per builder, not per build directory.** Several
   builds of today's files differ only in `--target-dir` (CI's and the
   developer's `host_debug`): under a recipe that names configurations, the
   directory name stops mattering and `configs.bazelrc` shrinks to the
   configurations proper.
8. **The Mac and Windows hosts.** A Mac bot runs the same sequence once its
   builder file carries `--bazel`; with the recipe driving Bazel, the Xcode
   selection (`osx_sdk`) and the code-signing step work on files Bazel
   names. Windows has no Bazel build yet; the recipe change is not the gate
   there.

In short: v1 proves the Bazel build on the bots with the recipe as it is, by
teaching three scripts of this repository to speak for it; the recipe change
makes Bazel a first-class tool of the builder, with its results, its cache
and its artifacts in LUCI's terms, and retires `tools/gn --bazel`, the
synthetic `build.ninja` and the `run_tests.py` dispatch.
