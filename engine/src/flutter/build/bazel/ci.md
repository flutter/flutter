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
- **Bazel's state** -- the output root, bazelisk's download -- lives, on a
  bot, in the task's temporary directory (`TMPDIR`, which the recipe engine
  sets for every step; swarming removes it with the task). Nothing under
  the checkout outlives a build: the recipe force-mounts the `builder`
  cache at the start of every build (`repo_util`: `mount_cache('builder',
  force=True)` clobbers it and downloads a fresh checkout from CAS), and
  an output root left under the checkout made the next build's clobber
  take an hour (the first presubmit runs). A developer's state goes under
  the checkout's `.bazel_ci/` (ignored by git), with a disk cache capped at
  40 GB, because a developer runs a builder file's builds one after another
  in one checkout and the flags that tell them apart (asan, unoptimized,
  dart_debug) reach the exec configuration, whose output directory does
  not spell them -- without the cache each switch rebuilds the host tools
  (10 minutes between `ci/host_debug` and a second `ci/host_debug_unopt`
  on 10-31). `BAZEL_CI_HOME` overrides the location. `--config=ci` (the
  root `.bazelrc`) keeps the output readable in a log. A bot's Bazel
  server exits five minutes after its last command (`--max_idle_secs`):
  the recipe's process cleanup does not know the detached JVM, which would
  otherwise idle for hours into the bot's next task. A bot's sandboxes go
  to `/dev/shm` when it has 16 GB or more there (`--sandbox_base`): a bot's
  disk is a network one with a low metadata rate, and the symlink forests
  the sandboxes lay -- and the stash Bazel keeps of them -- made removing
  an output root a matter of 20 minutes and more (the recipe's clobber of
  the checkout on the first presubmit runs, swarming's cleanup of the task
  directory since; the 85-minute `ci/wasm_release` build then overran its
  orchestrator, which cocoon gives master's 120-minute timeout, not the
  PR's 240).
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
  bucket the tool downloads from). `linux_unopt`'s first build also carries
  the step that keeps the generated files honest, "Check generated Bazel
  files" (`ci/check_generated_bazel_files.sh`: `gn_to_bazel --check` on the
  checkout's prebuilt Dart SDK, without buildifier, about a minute; a
  `BUILD.gn` or builder-file change that was not regenerated fails there).
- Still GN, and why: `linux_unopt`'s `ci/host_debug_no_prebuilt_dart_sdk`
  (the Dart SDK from source; `--config=host_debug_no_prebuilt_dart_sdk`
  exists for a developer, a cold bot has no time for it); `linux_clang_tidy`
  (clang-tidy over GN's compile database); `linux_android_emulator_tests`
  (`run_tests.py --type android` runs the C++ suites on the emulator: no
  Bazel counterpart yet); `local_engine_builds` (local_engine.json's builds
  are `bazel build` targets without installs); the Fuchsia builders; the
  standalone files `linux_benchmarks` and `linux_clangd` (`linux_license`
  builds with Bazel since 536: its `--enable-minimal-linux`, which only
  spares GN's pkg-config on a bot without the desktop's packages, asks for
  what the sysroot-based build has already, and its test runner runs as
  `run_tests.py --type binaries` as the Mac licenses builder's does);
  Windows. The Mac engine builders build this way since 509
  (`mac_host_engine`, `mac_android_aot_engine`, `mac_ios_engine` and
  `_ddm`), and so do the eight standalone Mac test builders that replaced
  `mac_unopt.json` (#195868, #196027: `ci/builders/standalone/mac_*.json`,
  one build a file, which the converter reads as builder files of one
  build -- `withStandaloneBuilds` -- since 524; `mac_clangd` stays GN).
  `tools/gn --bazel` knows the host: a Mac builder
  switches as the Linux ones did, or as a `mac_*_bazel.json` variant first.
- Steps left out of a Bazel build: the malioc diff (GN's Mali offline
  compiler analysis), and `linux_host_engine_test`'s benchmark-metrics dry
  runs (`generate_metrics.sh` and `upload_metrics.sh --no-upload` run
  benchmark executables from the directory, which the install does not lay:
  the `benchmarks` type runs them as Bazel tests; the real upload is
  `linux_benchmarks`, GN). The licenses test runner, an executable the
  original ran from the directory, runs as `run_tests.py --type binaries`
  (the Linux and the Mac licenses builds alike: the recipe runs a step's
  path as it is, and the install lays no test, so the converter refuses a
  `--bazel` build with such a step).
- Global tests (`tests` at the top of a builder file, run on tester drones
  against the CAS archive of `out/<name>`) stay what they are: a tester
  drone has the installed directory, laid out as GN lays it, and not the
  Bazel outputs, so the Bazel builds keep their tests local to the
  builder's drone.
- Remote execution on a Linux bot, and no state between builds on the bot
  itself (the recipe clobbers the checkout; a named cache for Bazel's
  output root is an infra change, below). A Linux bot's builds run their
  actions on Flutter's RBE instance -- the one the GN builds' reclient
  uses, named in the builders' `$flutter/rbe` property -- as the root
  `.bazelrc`'s `build:rbe`
  (`--remote_executor=grpcs://remotebuildexecution.googleapis.com`,
  `--remote_instance_name=projects/flutter-rbe-prod/instances/default`,
  the builders' debian11 `container-image` as the default execution
  properties, their `rbe_jobs` as `--jobs=200`,
  `--google_default_credentials`: the emulated GCE metadata server every
  LUCI bot has, which is how reclient authenticates there too), which
  bazel_ci.py adds to every build on a Linux bot (a Mac sends its compiles
  alone, below: the workers are Linux x64). Three ways to turn it off, so that the two
  can be compared on the bots: `--no-bazel-rbe` among a build's `gn` flags
  in its builder file (an infrastructure flag like `--bazel`, matched away;
  `--bazel-rbe` asks for RBE anywhere, a developer's Linux checkout
  included, given `gcloud auth application-default login`),
  `FLUTTER_BAZEL_RBE=0` in the environment of a run, and `RBE_ON_BOTS` in
  bazel_ci.py, the default a Linux bot gets without either; test.dart's
  shards have the same three (`--bazel-rbe` / `--no-bazel-rbe`, the
  variable, `kBazelRbeOnBots` in dev/bots/bazel.dart). The compiles,
  links, kernel compiles and snapshots run on the
  workers, 200 at a time where a try bot has 8 cores, and their results
  stay in the instance's cache for every later build, so a bot's build
  repeats nothing another bot has done since the inputs last changed. What
  stays on the bot: the wrapped GN builds (the Dart runtime, the GL stack:
  `gn_build.bzl`'s `no-remote-exec`, their inputs being a synced tree --
  `ninja -j8` 442 s for the Dart runtime on an 8-core bot, 84–155 s on 32
  cores, unless the bot's own disk cache has them, below) and the engine's
  tests (a display, a GPU, a device: run_tests.py's `TEST_OPTIONS`,
  `--strategy=TestRunner=sandboxed,local`). The wrapped builds run on the
  bot, but their compiles do not, since 510: the action runs reclient's
  proxy around ninja as the recipe ran it around a GN build (`gn_build.py`'s
  Reproxy: `bootstrap --re_proxy=reproxy --cfg=reclient-linux.cfg`, a socket
  of its own under the sandbox's /tmp, logs and the dependency cache under
  the action's scratch, and `bootstrap --shutdown`), GN's `use_rbe` with the
  engine's `rewrapper-linux-x64.cfg` and `remote_local_fallback`, 80 ninja
  jobs a core; @reclient and @reclient_cfgs (the two DEPS packages
  gclient's `use_rbe` syncs, back on in the Linux Bazel builders' files for
  that) are laid under the GN root where rbe.gni and the Linux toolchain's
  wrapper scripts expect them. The flag is
  `--//engine/src/flutter/build/bazel:wrap_rbe`, which bazel_ci.py adds
  with `--config=rbe`. The proxy's credentials: a Bazel action sees none
  of the task's environment, so bazel_ci.py writes the task's emulated
  metadata server (`GCE_METADATA_HOST=127.0.0.1:<port>` and its two
  aliases, `RBE_use_gce_credentials=true`) to
  `~/.cache/flutter_engine_bazel/wrap_rbe_env.json` before every Bazel
  command on a bot, and gn_build.py gives it to the proxy, read at run
  time rather than as an input (the port would otherwise re-key the wrap
  every task) -- the first presubmit with 510 had every wrap fail with
  "insufficient authentication scopes": reclient's Application Default
  Credentials had found the VM's own metadata server. A developer's
  sandbox has `--action_env=GOOGLE_APPLICATION_CREDENTIALS=<the gcloud ADC
  file>` instead (not `--action_env=HOME`, which makes the Dart SDK's own
  `dart compile` write telemetry into a read-only home). Without the file
  or the variable, or when the proxy cannot start, the wrap compiles
  locally and says so in its log (a proxy without credentials fails every
  compile outright; `remote_local_fallback` does not cover
  Unauthenticated). Measured from a workstation in the
  sandbox: the Dart runtime's 2,252 compiles all through the proxy, 77 s of
  ninja when they are reclient cache hits (about 2.5 minutes when they
  execute), the action 2:20 with its tree, digests and the local Dart
  snapshot steps. The framework shards' tests are
  another matter: the headless ones -- the framework's under
  `flutter_tester`, the pure-Dart packages' -- run on the workers too
  (505), and the bot downloads their logs and results rather than their
  kernels (50 MB each, 40 GB a shard); what stays on the bot there is
  tagged `no-remote-exec` by `dart_test.bzl` and `flutter_test.bzl` (a
  test that may reach the network, drives a browser or a display, runs a
  tool of the host -- every shard of the tool's -- or is named in a suite's
  `host` list: dev/tools' engine-version tests run `git`, devicelab's
  runner_test starts thirty VMs). Execution
  rather than a cache alone because of the instance's IAM: a client -- the
  bots' service account included -- reads the action cache but only a
  worker writes it (`remotebuildexecution.actions.update`), so a build with
  `--remote_cache` and local execution finds nothing of its own, ever.
  Measured from a workstation before the bots (11-03): `fml_unittests`'
  676 actions in 93 s on the workers (critical path 60 s), then 38 s from
  a fresh output base, every action a hit. The first runs on the bots (PR
  #195825 at 495 and 497): `ci/host_debug` 4:11–4:42 for its build step,
  `ci/host_release` 1:38–2:05, the Android builds 4:16–8:08,
  `ci/linux_debug_arm64` 6:33–7:12, `ci/wasm_release` 9:16 -- with the
  caveat that the try pool mixes 8-core and 32-core bots and every RBE run
  landed on a 32-core one. Against the same 32-core bots building locally
  (492: 4:23–8:07, wasm 12:02 at 480) RBE is roughly a wash for these
  builds: with the compiles hits or remote, the critical path is the two
  wrapped GN builds (the Dart runtime and the GL stack, `ninja -j32` for
  84–155 s each, local) and the install. On the 8-core bots the gain is
  about half (500: `ci/android_release` 22:38 → 10:12, of which the Dart
  runtime's wrap is 442 s); the shards, all on
  8-core bots, are the like-for-like measurement (README: 23–35% off the
  kernel-compile-heavy ones). The workers are 2-vCPU Debian 11 machines,
  clock in UTC. Three findings, all the worker's environment: the desktop
  builds' impellerc linked the sysroot's libfontconfig (the fontconfig
  flag reaching the exec configuration; 496 builds the tool without it),
  emcc's Closure compiler was npm's `.bin` symlink, which a worker gets as
  a copy (497 names the script's own path), and an archive zipped on a
  worker carries UTC in its zone-less DOS timestamps, seven hours ahead of
  the Pacific bots that unzip it -- pub took sky_engine's pubspec for newer
  than every lockfile (500 zips on the bot). A bot's home directory, it
  turned out,
  survives its tasks, so the root `.bazelrc`'s disk cache under `~/.cache`
  had already been warming repeat builds on the same bot (492's
  `host_debug_unopt_impeller_tests` found 6,113 of its actions there, 3
  minutes) -- an accident of the pool, not something to rely on; the
  remote cache is shared by every bot and every build. The wrapped GN
  builds, which only that disk cache can serve, never were hits in it
  until 503: zlib's input tree carried the checkout's `.git`, which every
  sync rewrites, so their action keys changed from task to task
  (gn_build.py printed its input trees' digests with its timing line, 501,
  which is how three drones of one presubmit showed the one directory
  that differed; 511 took the diagnostic out again, its cause found and its
  cost 38 s a wrap). Sent to a worker as they are
  (`--modify_execution_info=GnBuild=-no-remote-exec --remote_timeout=3600`
  on a `--config=rbe` build, plus a `git` stub on the action's PATH, the
  image having none and Dart's `tools/make_version.py` running git whatever
  its arguments say -- a dozen lines in gn_build.py, kept out of the tree
  since every change to that file costs the pool its cached wraps), the
  Dart runtime's wrap took 51 minutes on a 2-vCPU worker (11-04, from a
  workstation) against 442 s on an 8-core bot:
  not a route. What would take the wraps off a cold bot: reclient inside
  the wrap (the GN build's compiles on the workers, as the recipe ran them
  before), prebuilts of the engine's Dart runtime per roll, or the Dart
  runtime and the GL stack built by Bazel. No reclient: the
  Bazel builds carry `--no-rbe` and `use_rbe: false`, so the recipe starts
  no reproxy; Bazel speaks to RBE itself. Two timeouts apply: the target's in
  `.ci.yaml` (the orchestrator's; 240 for the switched targets) and each
  build's own `timeout` key in the builder file, which the recipe gives the
  drone (`shard_util`; 60 minutes when the key is absent) -- the Bazel
  builds say 240. The first presubmit run (PR #195825, 8-core try bots,
  cold): `ci/host_release` 5 minutes, the desktop and Android builds 24–27,
  `ci/host_debug` 40, `ci/wasm_release` past 60 (36,000 of 39,000 actions
  on a 32-core bot when the default timeout cut it). Disk: an output root
  of a test build is tens of gigabytes.
- A Mac bot's compiles on the same workers (519, 520; Q40 option B). The
  Mac engine builders on Bazel compiled on the bots themselves
  (mac_host_engine 44–67 minutes against GN+reclient's 34; mac_ios_engine
  31–36 against 23), where GN's reclient build had long sent a Mac's
  compiles to the Linux workers with the Linux clang of the same revision
  (`build/rbe/remote_wrapper.sh` rewrites the compiler's path,
  `rewrapper-mac-*.cfg` lists the Linux clang as inputs, `--xcode-symlinks`
  puts the SDK under the checkout). The Bazel build does the same two ways.
  Bazel's own compiles: `--//engine/src/flutter/build/bazel:apple_remote_compiles`
  (`build:rbe_mac` in the root `.bazelrc`) turns the macOS and iOS
  toolchains' compiler into `toolchains/apple_clang_wrapper.sh`, which
  execs the clang the action's environment names for the machine it runs
  on -- the Mac's under Darwin, `buildtools/linux-x64/clang` (which a Mac
  checkout syncs) under Linux -- adds the Linux clang's files to the
  compiler's inputs, and marks the toolchain's links, archives, strip and
  objcopy `no-remote-exec`; the Xcode SDK view (@macos_sdk) was an input
  already, a tracked directory of symlinks that Bazel resolves into the
  worker's input tree (35,270 files / 484 MB for MacOSX.sdk, 9,000 / 80 MB
  per iOS SDK, uploaded once per bot). The config's strategies send the
  two compile mnemonics (CppCompile, ObjcCompile) to the workers first,
  with the local fallback, and keep every other action on the Mac (the
  links, lipo, dsymutil, codesign, Swift, Dart, impellerc, python: Mac
  binaries), upload no local result, and keep the SDK's Merkle tree across
  actions (`--experimental_remote_merkle_tree_cache`). The wrapped GN
  builds: `wrap_rbe` on a Mac runs the Mac's reclient (`@reclient` is the
  host's `buildtools/<host>/reclient`) with `reclient-mac.cfg` and
  `rewrapper-mac-<cpu>.cfg`, and lays under the GN root what that
  configuration needs -- the Linux clang under
  `flutter/buildtools/linux-x64/clang` and the SDK views under
  `flutter/prebuilts/SDKs/`, where GN's own symlinks go, named to GN as
  `mac_sdk_path` and the iOS SDK paths so that `-isysroot` is a path under
  the exec root. bazel_ci.py adds `--config=rbe_mac` and the wrap flag on
  a Mac bot as it adds `--config=rbe` on a Linux one (the same three
  switches), and the Mac Bazel builders' files say `use_rbe: true` again
  for the sync (reclient, the cfgs, the Linux clang; `--no-rbe` stays, the
  recipe starts no proxy). The bot's emulated metadata server is the same
  on a Mac ("in all environments for uniformity", the rbe recipe module).
  Measured on a 16-core Apple-silicon Mac before the pool (11-05): the
  `ci_mac_host_debug` install 7:38 with 5,540 compiles on the workers and
  673 actions local, against ~16 minutes for the same install locally;
  `ci_ios_debug` 8:25 against 14:52 (5,122 remote); the Dart runtime's
  wrap 423 s of ninja with every compile executed remotely (333 local on
  16 cores), 91 s once reclient's cache has them; the GL backends' 196 s
  against 283. `ninja -j1280` under reclient died on the Mac with "pipe:
  Too many open files": the soft descriptor limit is 256 there and ninja's
  Darwin build waits on its pipes with pselect(2), bounded by 1024, so
  gn_build.py caps a Mac at 800 jobs as the recipe does (crbug.com/936864)
  and raises the limit. On the pool (presubmits at 524–531, 11-05/06, warm,
  against master's GN+reclient postsubmits of the same day):
  mac_host_engine 13–15 minutes (GN 30–48; 44 with local compiles),
  mac_ios_engine 12–17 (GN 31–74), mac_android_aot_engine 13–14 (GN
  22–31); the standalone Mac test builders, on Bazel since 524:
  mac_host_debug_arm64_tests 15–16 (GN 20–35), host_debug_unopt_arm64 24–25
  (GN 38–40), the iOS simulator unopt builders 18–22, the licenses builder
  7–8. The test targets whose copts name the Xcode's platform directories
  (XCTest, Testing: 15 rules) compile on the Mac (`no-remote-exec`, from
  the converter): a worker has no Xcode.
- The Linux test drones (`linux_unopt`, eight builds, each with its tests
  on the bot): 25:54 at 531 against GN's 16–17, the difference the Android
  embedding's Robolectric suite -- 87 JVMs, one per class, on an 8-core bot:
  one at a time at first (each declared 12 GB to the scheduler against the
  bot's 20 GB budget; 23 minutes for a suite Gradle's eight forks finish in
  four), six abreast since 530 (3 GB declared, measured 3.0 GB peak;
  11–13.5 minutes), and with the C1 compiler alone and the serial
  collector since 533 (a class-loading-bound JVM that lives seconds; 2.5×
  faster at six abreast on eight cores in a measurement here, and on the
  bots the step went from 1,398 s to 342–454 s: `linux_unopt` 17:31–17:58
  at 534 and 536, GN's 16–17). The other drones are at GN's times:
  `ci/host_debug_unopt` builds in 3:15 (GN 2:20) and runs its host tests
  in 4:43 (GN 5:30); the standalone `linux_license` builder's Bazel steps
  take 84 s (a build of remote cache hits, the runner's tests, the license
  run) under a twelve-minute checkout.
- Presubmit: the switched builders run on every PR as they did under GN,
  which is the point. A new `.ci.yaml` target cannot do that: cocoon admits
  it only as `bringup: true`, which runs in postsubmit on the staging pool
  until the usual promotion. **The presubmits at 531 (`2f1e2923442`,
  11-05) and 536 (`c070fe38b22`, 11-06) were 338/338 green: the Linux and
  Mac engine builders, the standalone Mac test builders and the Linux
  licenses builder, the Linux test drones and every framework and tool
  shard on Bazel through the unchanged recipes.**

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
3. **bazelisk and Bazel from the recipe's dependencies, and a named cache
   for the output root.** `flutter_deps` provides tools by CIPD package
   (`open_jdk`, `goldctl`, ...); `bazelisk` joins them, and Bazel's own
   release is fetched once into a named cache rather than per task, with
   `BAZELISK_HOME` and `--output_user_root` set by the recipe to named
   caches the infra sizes and evicts -- the one place on a bot that
   outlives a build, which the recipe's clobber of the `builder` cache
   today denies to anything under the checkout. With it a bot's second
   build of a configuration is incremental; today every build is cold.
   The repository cache (`--repository_cache`, the downloaded external
   repositories) belongs in the same named cache: today every run of a
   linux_unopt Java drone downloads the Android embedding's test
   dependencies again -- 99 Maven files, 2.2 GB, the Robolectric
   android-all jars most of it -- about 40 s of the step on a bot (and the
   reason 531 fetches Maven Central through Google's mirror: repo1.maven.org
   rate-limits the bots' shared addresses).
4. **The rest of remote execution.** The execution itself is in, above: the
   RBE instance needed nothing outside this repository, since every bot
   already holds the credentials for reclient. What a recipe change adds:
   `--bes_backend` for invocation pages beside the step log; the wrapped GN
   builds taken out of the bot's critical path (a named cache for the
   output root, or the Dart runtime as a prebuilt the recipe fetches); and
   the Mac builders' remaining local actions (links, lipo, dsymutil,
   codesign, the test targets that read the Xcode by absolute path) on a
   Mac pool of the instance -- their compiles already run on the Linux
   workers (519). The Robolectric tests stay on the bot by measurement: the
   instance's 2-vCPU workers run a class 7–10× slower than a bot's eight
   cores and each would materialize the 2.3 GB of android-all jars and
   JDK; six abreast on the bot with C1 and the serial collector (533) is
   the better shape.
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
