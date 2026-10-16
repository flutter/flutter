# build/bazel

Bazel-side support files for the GN → Bazel migration of the engine build.
Nothing in this directory is used by the GN build.

| File | Role |
| --- | --- |
| `deps.lock.bzl` | **Generated** from `DEPS` by `tools/bazel_tools/bin/gen_deps.dart`; never edit by hand. The pins (`VARS`, `GIT_DEPS`, `CIPD_DEPS`, `GCLIENT_GN_ARGS`) as Starlark data. |
| `repositories.bzl` | Repository rules: `synced_repository` (a directory populated by `gclient sync`, consumed in place), `cipd_package` (a CIPD instance downloaded over HTTPS, no `cipd` client needed) and `engine_version_repository` (the version strings `tools/gn` computes at gen time -- git HEAD, the content hash, Skia's and Dart's DEPS revisions -- as `@engine_version//:version.bzl`, for `shell/version`). |
| `extensions.bzl` | The `synced_deps` module extension: the table of repositories the root `MODULE.bazel` imports with `use_repo`, backed by the pins in `deps.lock.bzl` and `build/linux/sysroot_scripts/sysroots.json`; and `engine_version`, which declares `@engine_version`. |
| `third_party/<name>/BUILD.<name>.bazel` | Overlay root `BUILD` files for dependencies that ship no usable Bazel build files. Deliberately not named `BUILD.bazel`, so Bazel does not treat them as packages of this repository. |
| `toolchains/` | The hermetic C/C++ toolchains (`cc_toolchain_config.bzl` holds the flag tables, `BUILD.bazel` the `cc_toolchain`/`toolchain` targets per platform, `tests/` a smoke test). |
| `copts.bzl` | What GN adds per target rather than per toolchain, for `BUILD` files to spell out: `FLUTTER_COPTS` / `FLUTTER_LOCAL_DEFINES` for first-party code (`chromium_code`, `//flutter:config`) and `FLUTTER_THIRD_PARTY_COPTS` for overlays (`no_chromium_code`). |
| `gn_build/` | The `gn_build` rule (`gn_build.bzl`, action script `gn_build.py`): a GN build of part of the tree as one Bazel action, for the subtrees that keep their GN rules during the migration. |
| `gn_action/` | The `gn_action` rule: GN's `action()` -- one run of a Python script under the hermetic `@cpython3` -- as the generated `BUILD` files emit it, with the path tokens (`$(execpath ...)`, `$(src ...)`, `$(gen ...)`) the converter writes for `rebase_path()` results; `gn_copy` for `copy()`; `run_python` for other rules that run the engine's scripts. |
| `flatbuffers/` | The engine's `flatbuffers()` GN template as a macro: `flatc` per schema, the generated headers as a library. |
| `impeller/` | The engine's `impeller_shaders()` GN template as a macro over three rules (`impellerc_compile`, `shader_archive`, `embed_blob`), and `impellerc()` itself (the template the test fixtures invoke directly) over `impellerc_run`; see below. |
| `dart_wrap/` | The Dart SDK, built with `gn_build`: `BUILD.gn` lists the GN targets, `BUILD.bazel` the args, the inputs and the `cc_library` facades; `tests/` starts the VM from the archive. |
| `gl_wrap/` | The GPU test backends -- ANGLE, SwiftShader, the Vulkan loader -- built with `gn_build` the same way; `stubs/` holds the stand-in GN files for the engine directories ANGLE's GN reaches; `tests/` renders through both. See below. |
| `dart/` | The engine's own Dart pipeline on the wrapped SDK's tools and the prebuilt SDK: `snapshot.bzl` (`compile_platform`, `core_snapshot`, `aot_snapshot`, `bin_to_assembly` -- `lib/snapshot/BUILD.gn`'s steps) and `kernel.bzl` (`dart_kernel`, GN's `flutter_frontend_server`); see below. |

## How dependencies reach Bazel during the transition

`gclient sync` stays the only fetcher. Every source dependency is exposed as a
`synced_repository` whose contents are symlinks into the checkout, so GN and
Bazel compile identical trees and nothing is stored twice. Upstream Bazel
files are used where they are maintained and flag-compatible (`googletest`,
`abseil-cpp`); everything else gets an overlay. An overlay replaces the
upstream root `BUILD` file and hides upstream `BUILD` files in subdirectories
(ICU ships some for its data-generation tools), so the overlay's globs can
span the whole tree. Engine code includes such dependencies by their
canonical paths (`absl/...`, `unicode/...`), which both GN and the upstream
or overlay `BUILD` files resolve.

Prebuilt tools (clang, gn, ninja, ...) default to the synced copy as well. Set

```
FLUTTER_BAZEL_FETCH_TOOLCHAINS=1   # e.g. bazelisk build --repo_env=FLUTTER_BAZEL_FETCH_TOOLCHAINS=1 ...
```

to have Bazel download them from CIPD at the `DEPS` pins instead; the
repository layout is the same either way. This is the path a checkout without
`gclient` will use once the switch is complete. The download is the exact
package file `gclient` installs (verified byte-for-byte for clang, gn and
ninja on linux-x64), served as a zip by
`https://chrome-infra-packages.appspot.com/dl/<package>/+/<version>`.

A CIPD instance id is `base64url(sha256(zip) + 0x02)`, so the sha256 Bazel
needs to verify (and cache) a download can be read off the instance id that
`gclient sync` writes to `<path>/.versions/<name>.cipd_version` (or, for
packages without one, to `.cipd/pkgs/<n>/_current` next to `DEPS`), without
downloading anything. Known hashes live in `_CIPD_SHA256` in `extensions.bzl`;
for an unknown pin Bazel still fetches and prints the hash to add.

A few tools are not in `DEPS` at all and are therefore always downloaded
(`_DOWNLOADED_TOOL_REPOSITORIES` in `extensions.bzl`, pins included). The one
so far is `@cpython3`, the interpreter for the Python scripts that wrapped GN
builds run: `.gn` names depot_tools' `vpython3` for those, which a Bazel
action must not reach for. Its pin is the one Skia's Bazel build uses.

## C/C++ toolchains

Bazel never uses a compiler found on the host
(`BAZEL_DO_NOT_DETECT_CPP_TOOLCHAIN=1` in `.bazelrc`). Each registered
toolchain is assembled from the same pieces GN uses for that platform:

| Piece | linux-x64 |
| --- | --- |
| Compiler, linker, archiver | `@clang_linux_x64` (the `DEPS` clang package; `-fuse-ld=lld`, `llvm-ar`). |
| Sysroot | `@sysroot_linux_x64`, the Debian bullseye sysroot pinned in `sysroots.json` (symlinked from `build/linux/`, or downloaded from the same URL under `FLUTTER_BAZEL_FETCH_TOOLCHAINS`). |
| C++ standard library | The engine's own libc++ / libc++abi / llvm-libc from `DEPS`, built from source (`@libcxx`, `@libcxxabi`, `@llvm_libc`), with the engine's `__config_site` (ABI namespace `__fl`). Headers replace clang's (`-nostdinc++`), and the archive is linked into every binary through `--@bazel_tools//tools/cpp:link_extra_libs`. |

`cc_toolchain_config.bzl` reproduces GN's toolchain-wide flags (warnings,
visibility, `-std=c++20`, `-fno-exceptions -fno-rtti`, the linker hardening
flags, defines). `-c dbg` corresponds to GN's unoptimized builds (`-O0 -g2
-D_DEBUG`) and `-c opt` to optimized ones (`-O2 -DNDEBUG`, dead stripping)
without LTO -- `tools/gn --no-lto`, which every host builder in
`ci/builders` and `et`'s `local_engine.json` pass; the wrapped GN builds
set `enable_lto = false` in both modes for the same reason, so an optimized
build is one build without LTO rather than an engine without and a VM with.
There is no component build: `.bazelrc` sets `--force_pic` and
`--dynamic_mode=off`, as GN links everything statically with `-fPIC`.

One ordering detail is load-bearing. GN puts a target's own `cflags`
*before* the configs', so a target's `-march` loses to the compiler config's
`-march=x86-64`: Skia's `ml3` opts ask for `-march=haswell` and are built
for x86-64, and the engine's test goldens are renders of that raster
pipeline (a build in which haswell wins differs from
`verifyb143464703_soft_noxform.png` by three pixels). Bazel puts a
toolchain's flags before `copts`, so the architecture flags alone are
emitted after them (the `flutter_arch_flags` feature, behind an explicit
`user_compile_flags`); `-m<feature>` flags are indifferent to the order.

Two details keep warnings equivalent to GN's. GN's `default_warning_flags`
(`-Werror` included) apply to every target, third-party code included, which
is kept building with `-Wno-*` flags. The list lives in `copts.bzl`:
`FLUTTER_COPTS` and `FLUTTER_THIRD_PARTY_COPTS` carry it after their own
`-Wall -Wextra` / `-Wno-*` flags, as GN orders them, and the toolchain
applies it without `-Werror` to everything else -- dependencies built from
upstream BUILD files enable warnings GN never does, so they cannot be made
fatal. And the toolchain passes the `includes` of `cc_library` rules with
`-I` instead of Bazel's default `-isystem`, since clang does not report
warnings in headers found through `-isystem`: with the default, `-Werror`
would silently stop covering the engine's own headers.

The toolchain's header trees -- the sysroot's `usr/include`, libc++'s
`include`, clang's builtin headers under `lib/clang/<version>/include` --
are declared as *directory* inputs rather than file by file. Every compile
action lists the toolchain's files, and the default `linux-sandbox` stages
each input as a symlink per action: as ~11,000 files they were 70 % of a
compile's inputs and most of the sandbox's cost (a cold build of the Phase 0
exit test took 943 s sandboxed against 551 s unsandboxed); as three
directories they are three symlinks. Two things make this sound: the root
`.bazelrc` starts the server with `-DBAZEL_TRACK_SOURCE_DIRECTORIES=1`, so
Bazel tracks the directories' contents (without it, every action warns and
a change inside a directory may go unnoticed), and
`cxx_builtin_include_directories` names the same directories (exec-root
relative, through `%workspace%`), since Bazel's undeclared-inclusion check
can no longer match their headers file by file. The trees change only with
a `DEPS`/`sysroots.json` roll, which re-fetches the repository.

```
bazelisk test //engine/src/flutter/build/bazel/toolchains/tests:cc_toolchain_smoke_test
```

checks the language mode, the libc++ in use, the sysroot, and that a C file
and a threaded C++ program build and run. And

```
dart engine/src/flutter/tools/bazel_tools/bin/check_hermeticity.dart [-- <bazel options>]
```

scans the action graph of `deps(//...)` and fails if any command line,
parameter file or environment variable mentions a path outside the execution
root, or if a C/C++ action runs anything but a `clang_<platform>` binary (see
`tools/bazel_tools/README.md`).

## Wrapped GN builds: the Dart SDK

The Dart SDK (VM, `gen_snapshot`, the frontend server, ...) is not converted
to Bazel rules; the engine's GN build of it runs as one Bazel action, the
`gn_build` rule in `gn_build/`. The action builds a GN source root out of
symlinks to its declared inputs -- one link per file, so the GN build sees
nothing else whether or not it is sandboxed -- runs `gn gen` with
`--root-target` on `dart_wrap/BUILD.gn` (which loads only the Dart targets
and their dependencies: 129 GN files instead of the engine's thousands) and
`ninja`, then copies out the executables and snapshots and archives the
libraries. For each exported library the archive holds the object files of
the GN target's dependency closure, stopping at the other exported targets
and at `archive_boundaries` (ICU, which `@icu` provides); the `cc_library`
facades in `dart_wrap/BUILD.bazel` mirror those dependencies, and the action
fails if two archives would contain the same object.

The inputs are the trees GN reads, declared as filegroups: `build_tree` in
the overlays (`@dart`, `@icu`, `@zlib`, `@boringssl`, libc++ and the sysroot)
and `gn_files` in the main repository (`//engine/src/build`,
`//engine/src/flutter/build`, ...). They were measured on the build graph
(GN's inputs, clang's `-MMD` output, the Dart compilers' depfiles, `ninja -t
inputs`) and written with some slack -- except for the secondary source
tree, of which only the directories the wrapped build loads are inputs
(`gn gen --root-target` reads ten files under `flutter/build`; the rest of
`flutter/build/secondary` is BUILD.gn files for the engine's own
dependencies, and listing them made every edit to one of them rebuild the
Dart SDK from scratch). A Dart roll that reads from a new area fails the
sandboxed build with a missing file, and the fix is a glob. The whole-tree
globs exclude `__pycache__`: a GN build in the same checkout writes bytecode
caches beside the Python scripts it runs (SPIRV-Tools' table generators, for
one), and each new cache file would otherwise rebuild the wrap that reads the
tree -- thirteen minutes for the GPU backends. The tools come
from the same places as for the rest of the build: `@gn`, `@ninja`,
`@clang_linux_x64`, `@sysroot_linux_x64`, and `@cpython3` as the
`--script-executable` in place of depot_tools' `vpython3`.

```
bazelisk build //engine/src/flutter/build/bazel/dart_wrap:dart_sdk   # everything
bazelisk build //engine/src/flutter/build/bazel/dart_wrap:gen_snapshot
bazelisk test  //engine/src/flutter/build/bazel/dart_wrap/tests:dart_vm_smoke_test
```

Products are targets of the package (`:gen_snapshot`, `:libdart_jit.a`,
`:libdart_aotruntime.a`, `:compile_commands.json`, ...), libraries are
consumed through the facades (`:libdart_jit`, `:libdart_aotruntime` -- the
VM for AOT snapshots, which `//engine/src/flutter/runtime:libdart` picks in
the profile and release runtime modes --, `:common_embedder_dart_io`,
`:elf_loader`, ...). A full
build takes as long as the GN build of the same targets (5-6 minutes of
ninja on 24 cores, plus a few seconds for the symlink tree, `gn gen` and the
archives); the action reserves the machine, so Bazel runs nothing else
meanwhile. Under the default sandboxed execution every run is a full build
and the result is cached by Bazel; to iterate on the Dart sources with
incremental ninja builds, run with `--strategy=GnBuild=local`, which keeps
the GN root and build directory in
`bazel-bin/engine/src/flutter/build/bazel/dart_wrap/dart_sdk.gn/root/out/bazel`
(a regular GN build directory: `gn args`, `ninja -t ...` and
`compile_commands.json` all work there).

Known limits of the first version: host linux-x64 only; zlib and BoringSSL
have no Bazel targets yet and stay inside `libcommon_embedder_dart_io.a`;
`bootstrap_compile_platform.exe`, which the prebuilt SDK's `dart compile exe`
produces, embeds the absolute path of the build directory (as the GN build's
does), so it differs between sandboxed runs; and the Dart version script
looks for `git` on `PATH` at `gn gen` time (and copes without it).

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
   (`@dart_sdk_linux_x64`, GN's `host_prebuilt_dart_sdk`) against the
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
the core snapshot must match the VM it is linked with; cross builds, where
`gen_snapshot` is a host binary targeting another architecture, are a later
phase. And kernels are compiled under a virtual root (`--filesystem-root .`
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

`dart_package_test` (`build/bazel/dart/package_test.bzl`) runs the same
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

## Wrapped GN builds: the GPU test backends

The host suites render through ANGLE (OpenGL ES on Vulkan) and SwiftShader
(Vulkan on the CPU): `//flutter/testing:opengl` links ANGLE's
`libEGL_static` and `libGLESv2_static`, `:vulkan` opens SwiftShader's
`libvk_swiftshader.so`, and ANGLE itself opens the Khronos loader
(`libvulkan.so.1`) and, through it, SwiftShader. `gl_wrap/` builds the three,
and the Khronos validation layer (`libVkLayer_khronos_validation.so` and its
manifest: `impeller_unittests`' data under `--use-glfw-swiftshader`, the
configuration of CI's `host_debug_unopt_impeller_tests`, whose
`run_tests.py --type impeller` run needs it for `--enable_vulkan_validation`),
with their own GN rules in one `gn_build` action, as `dart_wrap/` builds the
Dart SDK:
ANGLE's `BUILD.gn` is 2,000 lines over a dozen trees and SwiftShader's build
is a JIT compiler's, and the suites are what matters now. The pruned graph
is about 1,100 compiles without the layer (ANGLE, SwiftShader with its
Subzero backend and its own SPIRV-Tools, the loader, abseil, zlib, libc++),
four minutes on 24 cores; the layer's generated validation code triples
that (669 s against 224 s of `ninja`).

The wrapped build takes `tools/gn`'s arguments for a host build, and one GN
default among them matters at run time: `is_minimal_linux` stays `false`.
`build_overrides/vulkan_headers.gni` derives `vulkan_use_x11` from it, and
a loader built without `VK_USE_PLATFORM_XCB_KHR` strips `VK_KHR_xcb_surface`
from the extensions SwiftShader reports, after which GLFW cannot create the
playground's Vulkan window surface. The price is `//build/config/linux`
probing the sysroot's pkg-config metadata (part of the sysroot repository's
`build_tree`) with the host's `pkg-config` at `gn gen` time, as GN's own
host build does.

`libangle.a` holds the object closure of the two static libraries up to the
`archive_boundaries` the Bazel side provides -- abseil (`@abseil-cpp`), zlib
(`@zlib`, with `google:compression_utils_portable` added to the overlay for
ANGLE's shader cache), SPIRV-Tools (`@spirv-tools`, which Impeller links as
well: a second copy of its objects would collide) and the C++ runtime; the
`:angle` facade lists them. One engine target is in the picture too: the
engine's `build_overrides/angle.gni` names `//flutter/flutter_vma` as ANGLE's
VulkanMemoryAllocator, so ANGLE's allocator wrapper compiles against the
allocator's header through it and its implementation comes from
`//engine/src/flutter/flutter_vma` (a dependency of the facade). Inside the
wrapped build that directory is a stand-in GN file (`gl_wrap/stubs/`): a
group with the real target's `public_deps` on the Vulkan headers and the
allocator, and no sources. The trees are the overlays' `build_tree`
filegroups (`@angle`, `@swiftshader`, `@vulkan_deps_tree` -- the
`vulkan-deps` directory as files, distinct from the repositories Bazel builds
from its subdirectories --, `@abseil_cpp_tree`, `@vulkan_memory_allocator_tree`),
measured on the build as the Dart SDK's were, and without any `.git`: ANGLE's
commit id comes from the `DEPS` pin through `ANGLE_UPSTREAM_HASH` (the rule's
`env`), not from the checkout's git state.

At run time the files must sit **next to the test binary**. ANGLE opens
the loader from, and points it (`VK_ICD_FILENAMES`) at the ICD manifest in,
the directory of its own module -- the executable, with ANGLE linked
statically -- and the manifest names `./libvk_swiftshader.so`; the engine's
test utilities look next to the executable too, and `//flutter/vulkan/procs`
opens the driver by bare name, which GN's `-rpath=$ORIGIN` resolves (the
toolchain gives every executable the same rpath). In GN the files land in
the build directory through `data_deps`. Here a suite lists
`flutter_gpu_test_backends` (testing/testing.bzl) as `data`: a copy of the
files in the suite's own package, in GN's layout (the layer's manifest under
`vulkan-data/`, which its `library_path` is relative to), which is where the
binary is in the runfiles tree (`bazel test`), in `bazel-bin` and for
`bazel run`. The converter declares the target in every package with a
suite of `gpuBackendTests` (bazel_mapping.dart) -- the suites whose GN
`runtime_deps` name `libvk_swiftshader.so`, kept as a list because the
converter sees one file at a time.

```
bazelisk build //engine/src/flutter/build/bazel/gl_wrap:gl_backends
bazelisk test  //engine/src/flutter/build/bazel/gl_wrap/tests:gl_backends_smoke_test
```

The smoke test clears and reads back a pixel through EGL on ANGLE and
SwiftShader, and opens SwiftShader as a Vulkan driver. As with the Dart SDK,
host linux-x64 only for now, and `--strategy=GnBuild=local` keeps a regular
GN build directory under `bazel-bin/.../gl_wrap/gl_backends.gn/root/out/bazel`
for iterating.

The Impeller playground (`impeller/playground`, on `@glfw` and `@imgui` --
the secondary tree's GN over the synced trees, converted at fetch time like
re2's) opens a GLFW window on X11 even when a suite only skips, so the
suites that link it (`impeller_dart_unittests`, `impeller_unittests`;
`displayTests` in bazel_mapping.dart) are `flutter_display_test`
(testing/testing.bzl): a `cc_binary` of the suite in its package, beside
the GPU backends, run through `testing/xvfb_run.sh`, which uses the
environment's `DISPLAY` or starts an Xvfb of its own inside the sandbox --
what `run_tests.py` does once for the whole Linux batch. The wrapper
starts `Xvfb -displayfd` directly rather than `xvfb-run -a`: that option
picks a display number by scanning `/tmp` for lock files, and sandboxes
each have a `/tmp` of their own while sharing the machine's abstract
socket namespace, so concurrent tests (the shards below) picked the same
number and failed to open their display; `-displayfd` binds the first free
number and reports it. The server's other arguments are `testing/xvfb.py`'s
(`run_tests.py`'s server), MIT-SHM disabled among them: with the extension
on, Mesa's unchecked shared-memory attach races a loaded server and killed
six of sixteen shards. Xvfb is a host
prerequisite for these suites, as it is for `run_tests.py`; the arguments
are `run_tests.py`'s (`testRuns`), which on Linux keep
`impeller_dart_unittests` to its Metal variants, all skipped, and run
`impeller_unittests` whole (`run_tests.py --type impeller`, the
`host_debug_unopt_impeller_tests` builder: no arguments of its own). That
suite is 4,795 tests and ~35 minutes serial under Bazel; `run_tests.py`
runs it through gtest-parallel, and Bazel's form of that is `shard_count`
(`testShardCounts` in bazel_mapping.dart: ten shards), which works because
`xvfb_run.sh` hands Bazel's `TEST_TOTAL_SHARDS`/`TEST_SHARD_INDEX`/
`TEST_SHARD_STATUS_FILE` to googletest under the `GTEST_*` names the
in-tree copy reads (a suite under gtest-parallel, below, is split by the
runner instead; a plain `cc_test` has no wrapper, and the converter
refuses to shard one). The test's environment is `run_tests.py`'s
`vulkan_validation_env` as well (`vulkan_validation = True`): the loader is
pointed at the copied SwiftShader manifest (`VK_ICD_FILENAMES`) and layer
directory (`VK_LAYER_PATH`), with the Khronos layer enabled
(`VK_INSTANCE_LAYERS`), by paths relative to the runfiles tree the test runs
from -- for the suites that carry the backends (`gpuBackendTests`); a display
test without them gets `vulkan_validation = False`.

The GTK shell's suite (`shell/platform/linux:flutter_linux_unittests`, 855
tests) is a display test too -- GTK opens the display at initialization --
and needs more of a desktop session than a display: GTK's accessibility
bridge asks the D-Bus *session bus* for the accessibility bus, and without
one a view's `AtkPlug` has no id, an Atk assertion that the suite's
environment (`G_DEBUG=fatal-criticals`, `run_tests.py`'s `extra_env`, the
test's `env`) turns into an abort in the first test. `run_tests.py`'s run
inherits the bot's session bus; a sandboxed test inherits nothing, so with
`session_bus = True` (`sessionBusTests` in bazel_mapping.dart) `xvfb_run.sh`
re-executes itself under `dbus-run-session`, which activates
`at-spi-bus-launcher` on demand (`dbus` and `at-spi2-core` are host
prerequisites, as GTK's own packages bring them), with a home directory of
the session's own under `TEST_TMPDIR`: the sandbox mounts the real one
read-only, and dconf -- GSettings' backend, which the launcher and the
shell's GNOME settings read through -- aborts under that `G_DEBUG` when it
cannot create its cache there. The empty home also makes the settings the
schemas' defaults, which is what the suite's expectations are (under
`run_tests.py` they are whatever the bot user has set). The daemon and the
services it activates run without the suite's `G_DEBUG`; the binary gets it
back. The compiled GSettings schemas the suite reads (`testing/gschemas`,
GN's `copy()` to `assets/<name>/gschemas.compiled`) are a `gn_copy` with
`outs` and the test's `data`: a `copy()` of the same file among a binary's
deps is run-time data, which GN's dependency only ordered.

### The harness: gtest-parallel

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

### The benchmarks (`--type benchmarks`)

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

## Impeller's shader pipeline

Every Impeller library with shaders invokes `impeller_shaders()`
(impeller/tools/shaders.gni); the converter emits the invocation as a call
of the macro in `impeller/shaders.bzl`, whose body is the template's,
rewritten once: for each backend of a Linux host (GLES 2, GLES 3, Vulkan)
`impellerc_compile` runs `//engine/src/flutter/impeller/compiler:impellerc`
once per shader, `shader_archive` packs the compiled shaders with
`shader_archiver`, `embed_blob` turns the archive into a C++ array with
`impeller/tools/xxd.py`, and `cc_library` wraps the blob and the reflection
headers. The targets keep GN's names (`impellerc_vk_entity_shaders`,
`embed_gles3_entity_shaders`, ...) so the two trees read alike; the oracle
knows them as the template's inner targets.

The tools run in Bazel's exec configuration -- GN's `host_toolchain` for
`compiled_action` -- which on a host build means `impellerc`'s closure
(Skia, SPIRV-Tools, glslang, shaderc) is compiled a second time, in
`bazel-out/*-exec-*`, where GN compiles it once because its default
toolchain is the host's. That is the cost of a build that can also cross
compile; a remote or disk cache absorbs it.

The test fixtures invoke the inner template, `impellerc()`
(impeller/tools/compiler.gni), directly: runtime stages (`--iplr`, one
run per shader) and Flutter GPU shader bundles (`--shader-bundle`, one run
over a JSON that names the shaders by path). The macro of the same name
in `impeller/shaders.bzl` declares GN's outputs
(`<intermediates_subdir>/<shader>.<sl_file_extension>`, or the bundle) and
runs `impellerc_run`, which builds the command line as the template does;
the bundle's paths, which GN wrote with `rebase_path`, are the converter's
`$(src ...)` tokens (`gn_action.bzl`'s `expand_gn_paths`), so the JSON is
the same text on every machine. GN's `mnemonic` becomes the action's,
reduced to letters and digits (`IMPELLERC_IPLR` is not a Bazel mnemonic).

`embed_blob()` (impeller/tools/embed_blob.gni) is invoked directly too, by
`impeller/toolkit/interop` for the ICU data of the standalone library; the
converter emits it as `embed_blob_library`, the `embed_blob` rule plus the
`cc_library` the template declares around the generated pair. The blob is
`@icu//:flutter/icudtl.dat`, the trimmed data file GN names, which the ICU
overlay exports beside `common/icudtl.dat`.

## Build speed: the cache and the sandbox

The root `.bazelrc` turns on a per-user disk cache (`~/.cache/
flutter_engine_bazel`, garbage-collected to 20 GB). It is content-addressed
and shared by every checkout and output base, so the second cold build of
the same inputs -- after `bazel clean`, in a second checkout, after a branch
switch and back -- is a cache hit for every action: measured at 78 s against
772 s for `display_list_unittests` from a clean output base, the exec
configuration included. It also covers a case the local action cache does
not: setting a Starlark flag (`--//engine/src/flutter/impeller/tools:
enable_vulkan=false`) and setting it back re-runs the affected actions
(`fml`'s 674 compiles) without the disk cache, and takes 7 s with it. CI
will use `--remote_cache` instead; the local cache is the same mechanism
without the network.

The sandbox is the other measured cost. With the toolchain's header trees as
directory inputs (see the toolchain section) a compile has ~4,200 inputs,
each a symlink per action; `--spawn_strategy=local` skips the sandbox and the
cold build drops from ~770 s to ~550 s on this machine, at the price of not
catching undeclared inputs -- fine for a developer, not for CI.
`--sandbox_base=/dev/shm` keeps the sandbox and puts its trees on tmpfs
(~620 s), but Bazel deletes sandbox directories asynchronously and a large
build can exhaust the tmpfs's inodes (the exit test alone used 7 M of 12 M
and left its tree behind after `bazel shutdown`); use it knowingly, with
`--experimental_sandbox_async_tree_delete_idle_threads=0` or a sweep of
`/dev/shm/bazel-sandbox.*`. Both belong in `user.bazelrc`, not here.

## Adding a dependency

1. Make sure `deps.lock.bzl` is current (`gen_deps.dart --check`).
2. Add an entry to `_SOURCE_REPOSITORIES` or `_TOOL_REPOSITORIES` in
   `extensions.bzl`, pointing at the `DEPS` path (sysroots go in
   `_SYSROOT_REPOSITORIES`, keyed by their `sysroots.json` entry; tools that
   `DEPS` does not provide go in `_DOWNLOADED_TOOL_REPOSITORIES` with an
   explicit CIPD pin and a hash in `_CIPD_SHA256`).
3. If upstream has no usable Bazel files, add `third_party/<name>/BUILD.<name>.bazel`,
   starting its `copts` from `FLUTTER_THIRD_PARTY_COPTS` and adding the `-Wno-*`
   flags its `BUILD.gn` uses.
4. Add the repository name to `use_repo(synced_deps, ...)` in the root `MODULE.bazel`.
