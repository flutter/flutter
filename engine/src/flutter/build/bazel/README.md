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
| `gn_action/` | The `gn_action` rule: GN's `action()` -- one run of a Python script under the hermetic `@cpython3` -- as the generated `BUILD` files emit it, with the path tokens (`$(execpath ...)`, `$(src ...)`, `$(gen ...)`, `$(built ...)`) the converter writes for `rebase_path()` results, and the build-directory outputs, tools and platform-transitioned dependencies the Android embedding's actions need, and a directory of the build directory assembled from the deps' placements for a script that reads one (`stage_build_directory.py`: sky/dist's copy of the sky_engine package); `gn_copy` for `copy()`; `run_python` for other rules that run the engine's scripts. |
| `flatbuffers/` | The engine's `flatbuffers()` GN template as a macro: `flatc` per schema, the generated headers as a library. |
| `impeller/` | The engine's `impeller_shaders()` GN template as a macro over three rules (`impellerc_compile`, `shader_archive`, `embed_blob`), and `impellerc()` itself (the template the test fixtures invoke directly) over `impellerc_run`; see below. |
| `dart_wrap/` | The Dart SDK, built with `gn_build`: `BUILD.gn` lists the GN targets, `BUILD.bazel` the args, the inputs and the `cc_library` facades; `tests/` starts the VM from the archive. |
| `gl_wrap/` | The GPU test backends -- ANGLE, SwiftShader, the Vulkan loader -- built with `gn_build` the same way; `stubs/` holds the stand-in GN files for the engine directories ANGLE's GN reaches; `tests/` renders through both. See below. |
| `dart/` | The engine's own Dart pipeline on the wrapped SDK's tools and the prebuilt SDK: `snapshot.bzl` (`compile_platform`, `core_snapshot`, `aot_snapshot`, `bin_to_assembly` -- `lib/snapshot/BUILD.gn`'s steps), `kernel.bzl` (`dart_kernel`, GN's `flutter_frontend_server`), `package_test.bzl` (`dart_package_test`, a Dart package's own `dart test` run) and `dart_pkg.bzl` (GN's `dart_pkg.py` action, which assembles the sky_engine package); see below. |
| `checkout_view.bzl`, `checkout_script_test.bzl` | The checkout-shaped runfiles tree the Dart tests and the checkout's scripts run in, and GN's name for the build directory of a configuration (`host_debug_unopt`), which the tests' launchers and `install` use; see below. |
| `zip_bundle.bzl` | GN's `zip_bundle` template (the archives CI uploads) as a rule running `build/zip.py`, with `zip_tree` for a directory's files; see below. |
| `build_directory.bzl` | `BuildDirectoryInfo`: where GN's build directory holds a rule's files, which `gn_copy`, `gn_action`, `gn_generated_file`, `zip_bundle`, `dart_pkg` and `sdk_rewriter` provide and `install` collects over a closure; see below. |
| `install.bzl` | `install`: a `bazel run` target laying a build's files into GN's build directory (`engine/src/out/<variant>/`, or a named directory) for the consumers that read it; the root package's `install` and the generated per-builder targets in `ci/builders`; see below. |

## How dependencies reach Bazel during the transition

`gclient sync` stays the only fetcher. Every source dependency is exposed as a
`synced_repository` whose contents are symlinks into the checkout, so GN and
Bazel compile identical trees and nothing is stored twice. Upstream Bazel
files are used where they are maintained and flag-compatible (`googletest`,
`abseil-cpp`); everything else gets an overlay. An overlay replaces the
upstream root `BUILD` file and hides upstream `BUILD` files in subdirectories
(ICU ships some for its data-generation tools), so the overlay's globs can
span the whole tree. Engine code includes such dependencies as it always
has, by either the canonical path (`absl/...`, `unicode/...`) or the
engine's root-relative one (`third_party/abseil-cpp/absl/...`,
`third_party/icu/source/common/unicode/...`, which GN's root include
directory resolves): a `root_includes` library in the abseil tree's and
ICU's overlays is a view of the same headers under that prefix
(`include_prefix`), carried by ICU's libraries and listed by the converter
beside every abseil dependency -- no engine include changes for Bazel.

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

| Piece | linux-x64 (the host; the default platform) | linux-arm64 (`--platforms=//engine/src/flutter/build/bazel/toolchains:linux_arm64`) |
| --- | --- | --- |
| Compiler, linker, archiver | `@clang_linux_x64` (the `DEPS` clang package; `-fuse-ld=lld`, `llvm-ar`). | The same `@clang_linux_x64`, driven with `--target=aarch64-linux-gnu` (and `-DBORINGSSL_CLANG_SUPPORTS_DOT_ARCH`) as GN's `clang_arm64` toolchain drives it. |
| Sysroot | `@sysroot_linux_x64`, the Debian bullseye sysroot pinned in `sysroots.json` (symlinked from `build/linux/`, or downloaded from the same URL under `FLUTTER_BAZEL_FETCH_TOOLCHAINS`). | `@sysroot_linux_arm64`, `sysroots.json`'s `bullseye_arm64`, which gclient's `linux_sysroot_arm64` hook unpacks beside the x64 one. |
| C++ standard library | The engine's own libc++ / libc++abi / llvm-libc from `DEPS`, built from source (`@libcxx`, `@libcxxabi`, `@llvm_libc`), with the engine's `__config_site` (ABI namespace `__fl`). Headers replace clang's (`-nostdinc++`), and the archive is linked into every binary through `--@bazel_tools//tools/cpp:link_extra_libs`. | The same sources, built for aarch64 by the arm64 toolchain like the rest of the target configuration. |

The arm64 platform is GN's `--target-os=linux --linux-cpu=arm64` cross
build (CI's `linux_debug_arm64` and the three `linux_*_arm64_desktop`
builds). `--platforms` picks the `linux_arm64_clang` toolchain for the
target configuration only: the exec configuration keeps the host's, so the
tools a build runs (`gen_snapshot_host`, `impellerc`, the shader compilers,
the Dart SDK's `dart`) are x64 binaries built once, as GN builds them in its
`host_toolchain`, and what the build ships is aarch64 -- `flutter_tester`
included, which links SwiftShader's LLVM Reactor there (the GPU backends'
wrap carries LLVM's sources in its tree under arm64, as GN's
`swiftshader_static` picks Reactor over x64's Subzero). The generated files
needed nothing: the converter already rendered `current_cpu`/`target_cpu`
conditions as `select()`s over `@platforms//cpu:*`; the hand-written
overlays that lacked an aarch64 branch (zlib's) got one. `host_toolchain`,
the setting the generated `unittests_enabled` and the hand-written rules
read as "this is the host's build", is the host's OS *and* CPU, so the cross
build has no tests, as GN's has none (`enable_unittests` is false outside
`host_toolchain`); `build_directory_attrs` names its directory
`linux_<mode>_arm64`. The Dart wrap builds its tools for the host and its
`gen_snapshot` for arm64, and the prebuilt SDK a build ships is the target's
(`@dart_sdk_linux_arm64`, `prebuilts/linux-arm64/dart-sdk`, GN's
`target_prebuilt_dart_sdk`; `dart_wrap:prebuilt_dart_sdk` selects by CPU).
Against GN's `out/linux_debug_arm64`, `install_diff.py` finds the archives'
entry lists identical (`dart-sdk`'s 1,057 files among them), and
`flutter_embedder.h` and the frontend snapshot byte-identical; the binaries
differ as the host's do, by compile flags (and by GN's `--strip-all`, which
the install reproduces: see the install section). One cost to know about:
`--platforms` on the command line does not enter the output directory's
name, so the host's and the arm64 build's files of one compilation mode
share `bazel-out/k8-opt` (and `k8-fastbuild`), and switching between the
two rebuilds the tree -- from the disk cache when it holds the other
build's actions (2 to 6 minutes for an arm64 install after a host build),
from the compilers otherwise (20 minutes for the host's archives after an
arm64 build). Bazel's `--experimental_platform_in_output_dir` would give
each platform its own directory at the price of a one-time rebuild of
everything; not turned on.

`cc_toolchain_config.bzl` reproduces GN's toolchain-wide flags (warnings,
visibility, `-std=c++20`, `-fno-exceptions -fno-rtti`, the linker hardening
flags, defines). `-c dbg` corresponds to GN's unoptimized builds (`-O0 -g2
-D_DEBUG`) and `-c opt` to optimized ones (`-O2 -DNDEBUG`, dead stripping,
and `-g0`: BUILDCONFIG.gn's `symbol_level` for an optimized Linux build is
0, so GN's `host_debug`, `host_profile` and `host_release` carry no debug
info; `--copt=-g2` puts it back for a profile)
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

### The Android toolchains, and the Java half

The Android builds (`tools/gn --android --android-cpu=<cpu>`) are four
more platforms over the same clang:
`//engine/src/flutter/build/bazel/toolchains:android_arm64` (API 24,
`--target=aarch64-linux-android24`), `android_x64`
(`x86_64-linux-androideabi24`, the triple as GN spells it), `android_arm`
(armv7, API 21, GN's default CPU) and `android_riscv64` (API 35), plus
`android_arm64_api26`, GN's `clang_arm64_apilevel26` toolchain, which exists
for one target (below). Each toolchain is `flutter_cc_toolchain_config(os =
"android")` over `@android_tools` -- the synced SDK/NDK package
(`third_party/android_tools`) -- for the NDK sysroot's headers, the per-ABI
API-level libraries and crt objects, and the NDK clang's
`libclang_rt.builtins-<arch>-android.a`; the compiler is the engine's own
`@clang_linux_x64`, as under GN. The link line is GN's
(`build/toolchain/android/BUILD.gn`, `//build/config/android`): `-nostdlib
-nostdlib++` with the crt objects around the inputs and `-lc -ldl -lm` and
the builtins late, `--exclude-libs,ALL --icf=all -z max-page-size=65536`,
`-z defs` on complete links; the optimized modes compile `-Oz
-fomit-frame-pointer -g2`. Two things were needed to make `libflutter.so`
export what GN's does: `@libcxxabi` builds without exception support on
Android (`cxa_noexception.cpp`, as GN), since a `-nostdlib` link with no
libunwind cannot provide `_Unwind_*`; and the toolchains enable
`supports_start_end_lib`, so a link names object files (`--start-lib ...
--end-lib`) rather than archives -- with archives, lld's `--exclude-libs,ALL`
made every archive-defined symbol local regardless of the version script, and
the library exported neither `JNI_OnLoad` nor the ICU data. LTO is a
setting for the Android toolchains (`--//engine/src/flutter/build/bazel:lto`,
which CI's AOT builds set: `ci_android_profile_arm64`,
`ci_android_release_arm64`; the developer's configurations of the same names
have none), and `--stripped` defaults off for them, as `tools/gn`'s
`stripped_symbols = target_os != "android"` has it: the build root holds the
unstripped library and the install's aspect writes GN's android toolchain's
strip step beside it as `lib.stripped/<name>` (and `shipped/<name>` where
`--stripped` holds, which the size-experiment builders' jars pack). The Dart
wrap reads the platform: `target_os = "android"` and
`dart_use_compressed_pointers` from the CPU, `gen_snapshot` built for the
host targeting Android (`clang_x64/gen_snapshot`, the host toolchain's
directory, as GN's build directory names it) and the VM for the target; one
wrap build per Android CPU, 8 to 10 minutes each.

The Java half -- `flutter.jar`, the embedding jar, `artifacts.zip`, the
Maven tree under `zip_archives/download.flutter.io/` (`embedding_jars`,
`abi_jars`, their poms and `maven-metadata.xml`), `android-javadoc.zip`, the
profile jar's `libvmservice_snapshot.so` -- is built the way GN builds it:
with `build/android/gyp/*.py` (javac, jar, zip) over the SDK's `android.jar`
and `core-lambda-stubs.jar` (`@android_tools`), the `DEPS` JDK (`@openjdk`,
`third_party/java/openjdk`) and the embedding's 43 dependency jars
(`@android_embedding_dependencies`), each GN action a `gn_action` the
converter emits -- no Gradle, no `rules_android`. The rule grew what those
actions need and host actions never did: `build_outputs` and `build_inputs`
(files at their paths under the build directory itself, `flutter.jar`,
`libflutter.so`, placed and found through `BuildDirectoryInfo`), the
`$(built PATH)` token for them, `tools` (programs in the exec configuration:
`@openjdk//:runtime`'s `javac`, `jar`, `javadoc`), `output_dirs` (the javadoc
tree, a directory output), and `platform_deps` with `platform` and
`platform_build_dir`: GN's `label($apilevel26_toolchain)` on one dependency,
a transition to `android_arm64_api26` for the Vulkan validation layer
(`@vulkan_validation_layers`, converted from the secondary tree's GN, with
`@vulkan-utility-libraries`), which GN's debug arm64 jar carries by default
(`impeller_enable_vulkan_validation_layers`) under
`clang_arm64_apilevel26/`. `shell/vmservice/BUILD.bazel` is hand-written
(the VM-service kernel and its AOT snapshot per ABI). Against CI's artifacts
of the base commit: the embedding jar byte-identical (456 classes), the
arm64 debug and profile `flutter.jar` the same classes and libraries,
`artifacts.zip`, the poms and javadoc the same modulo dates and hashes, every
`libflutter.so` CI's exports and `NEEDED` entries. `et build --backend bazel
-c ci/android_debug_x64 //flutter/shell/platform/android:flutter_jar_zip`
builds `artifacts.zip` through it.

The configurations (`configs.bazelrc`) cover every Android build of the
Linux builder files: `android_{debug,profile,release}` (arm) and their
`_arm64`, `_x64`, `_riscv64` twins, `_ddm`, the `_unopt` ones,
`_size_exp` (`--no-dart-secure-socket`, a flag on the Dart wrap),
`android_debug_arm64_validation_layers`
(`--enable-vulkan-validation-layers`), `_clang_tidy`, `android_debug_test`,
the emulator's `android_emulator_debug_x64` and
`android_embedder_debug_unopt` (`--embedder-for-target`: the embedder
API's `libflutter_engine.so` and `flutter_embedder.h` for Android arm,
unoptimized; its install lays them with the stripped copy and the Dart
wrap's archives, 10 files). `bazel run
--config=android_debug_arm64 //engine/src/flutter/ci/builders:android_debug_arm64
-- <directory>` lays what the builder builds: `flutter.jar` and the jars,
poms and stamps at the root, `lib.stripped/`, `clang_arm64_apilevel26/`,
the Maven tree, `zip_archives/android-arm64/{artifacts,symbols,embedder,impeller_sdk,linux-x64}.zip`
and `android-javadoc.zip` (337 files); the arm builder's (`android_debug`,
343 files) adds `sky_engine.zip` and `flutter_gpu.zip` at the root of
`zip_archives/`, the two packages the flutter tool downloads from it
(`sky/dist`, `lib/gpu/dist`; `dist/packages/sky_engine` is the copy the
first is made from), file for file CI's. With them, every archive the
Android builders upload has its counterpart. What is not here: *running* the
three device suites the emulator builder's `run_tests.py --type android`
pushes (they build for `android_x64`; an emulator is the next phase), the
APK variants of two of them (GN's `native_activity_apk`), and x86, which no
builder builds.

### The Emscripten toolchain (the spike)

`toolchains/emscripten/` is GN's `build/toolchain/wasm:wasm` -- the
toolchain that builds the web engine's modules (skwasm, CanvasKit) -- over
the synced SDK, `@emsdk` (`engine/src/flutter/prebuilts/emsdk`, which
`gclient sync` populates under `download_emsdk`). Its tools are three
wrapper scripts (`emcc.sh`, `em++.sh`, `emar.sh`) that run the SDK's
Python drivers under the engine's `@cpython3` with the SDK's paths taken
from the action's environment (`EM_BIN_PATH`, `EM_CONFIG_PATH`, ...,
which the toolchain configuration sets), so that nothing in the toolchain
names a repository or a machine; `emscripten_config` is the Python
configuration emcc reads in place of the SDK's `.emscripten`, with the
same roles resolved against the execution root and the SDK's prebuilt
cache **frozen** -- a system library variant the cache lacks (LTO
variants, say: `lto/libembind.a`) is an error, where GN's emcc would
build it into the shared tree on the spot. The SDK reaches every action
as directory inputs. `emscripten_cc_toolchain_config.bzl` holds the
flags of `out/wasm_release`'s and `out/wasm_debug_unopt`'s compile and
link lines, in their order, minus what GN attaches per target (`-c opt` is
GN's optimized web build, `-O3 -g0`; `-c dbg` and `-c fastbuild` are both
its one unoptimized build, `-O1 -gsource-map` -- GN keeps `-O1` because a
fully deoptimized module has functions with too many locals for Chrome --
and the link carries `-Wl,-O2`, or `-Oz` under `wasm_prioritize_size`, and
`-Wl,--gc-sections` in every mode, as GN's `no_optimize` does for wasm);
the one thing GN's lines do not have
is the explicit, relative `--sysroot` and `-resource-dir`, because emcc
resolves them to absolute paths (through the repository's symlink, into
the checkout) that Bazel's header check would reject.

`wasm.bzl`'s `wasm_module` is GN's `wasm_lib`: a configuration transition
to the `wasm32_emscripten` platform (so a module can be named from any
build; `--force_pic` is turned off there), a compile through
`cc_common.compile`, and a link that is the rule's own action over the
toolchain's command line -- `cc_common.link` declares one output per
link and the three a module has (`.js`, `.wasm`, `.js.symbols`: GN's
`link_outputs`) are Bazel's private API -- with GN's `-Wl,--start-group
@objects -Wl,--end-group` around the objects. In the unoptimized modes the
module has a fourth output, `<name>.wasm.map`, which emcc writes beside the
`.wasm` under the toolchain's `source_map` feature (`-gsource-map`) and
GN's web SDK copies under `is_debug` without declaring (ninja finds it on
disk). `wasm_objects` is the
compile alone.

`toolchains/emscripten/spike/` is Phase 0's metric 0.6: an embind module
(`spike_module`) and one Skia translation unit (`skia_unit`,
`src/core/SkPath.cpp` with the wasm_release's defines), both `manual`
since the SDK is optional in the checkout, and `spike_test`, which
serves the module over a local HTTP server (an ES-module loader fetches
its `.wasm`) and reads its exports' results from headless Chrome's DOM
dump -- the host's Chrome, or `--test_env=CHROME=`; a hermetic browser
is the web phase's.

```
bazelisk build -c opt //engine/src/flutter/build/bazel/toolchains/emscripten/spike:all
bazelisk test -c opt //engine/src/flutter/build/bazel/toolchains/emscripten/spike:spike_test
```

Against `out/wasm_release`: the Skia unit's compile line carries every
flag and define GN's does, in GN's order but for the per-target `-Werror`
(copts.bzl's class) and the include directories' spelling; the module's
link line is GN's skwasm link in GN's order (the module's flags, the
compiler config's, the optimized build's, the libs), plus the relative
sysroot and Bazel's `-o` first. The module loads and runs in Chrome,
5 of 5.

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

### font-subset (`--type font-subset`)

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

## The archives CI uploads: `zip_bundle`

Every artifact a Linux host builder uploads is a `zip_bundle`
(`build/zip_bundle.gni`): `build/zip.py` over `{ source, destination }`
scopes, a generated `LICENSE.<target>.md` first in every archive, the result
at `$root_build_dir/zip_archives/<output>`. `ci/host_debug` uploads
`dart-sdk-linux-x64.zip`, `flutter_patched_sdk.zip`, `linux-x64/artifacts.zip`,
`linux-x64/font-subset.zip`, `linux-x64/impeller_sdk.zip` and
`linux-x64/linux-x64-embedder.zip`; `ci/host_release`,
`flutter_patched_sdk_product.zip`.

`zip_bundle.bzl` is the template's Bazel side: the same script under the
synced Python (`@cpython3`, through `zip_bundle.py`, which resolves the
sandbox's input symlinks to the files they name -- `zip.py` keeps a symlink
as a symlink entry), the readme written from `@engine_version`'s version
byte for byte (its title is the nested `generated_file`'s name,
`_<bundle>_license_md`, as GN evaluates `target_name` there), the archive at
`zip_archives/<output>` under the package. The converter maps the template
(`templateMappings['zip_bundle']`): `files` becomes a dictionary of
destination to the label of the file placed there, each entry under its
condition (`{...} | select({...})`, which Bazel merges); `output` is the
string GN computes, with `full_target_platform_name` and its kin assumed as
the Linux x64 host's (`linux-x64`), like every other platform variable in
the generated files. A source that is a file of the tree is its label; one
under the build directory (`$root_build_dir/impellerc`,
`$root_out_dir/flutter_embedder.h`) is resolved to the target that produces
it -- an executable by its `output_name` or name, a shared library by
`lib<name>.so`, a complete static library by `lib<name>.a`, a `copy()` by its
`outputs` (the copy itself when it is the one file: `copy_headers`, a copy of
`embedder.h` into the build root, converts as a `gn_copy` whose file travels
as it is) -- among the targets of the same file first, then of the files
the bundle's `deps` name (evaluated on demand, `dependency_resolver.dart`),
then `buildOutputLabels` for what the wrapped trees produce. The bundle's
helpers (`exe`, `prefix`, `zip_out_dir`) are told from its arguments by
being read in their own block (`GnTarget.readVariables`). GN's
`complete_static_lib` -- the Impeller SDK's `libimpeller.a`, every object of
the closure in one archive -- is `cc_static_library` (behind
`--experimental_cc_static_library` in Bazel 8; `.bazelrc`), named after the
`output_name` with an alias under the GN name.

A directory source (`artifacts.zip`'s `shader_lib`, the prebuilt Dart SDK
that `dart-sdk-linux-x64.zip` is) is a `zip_tree`: the files of a filegroup
over the directory (`directorySources` in the converter names it and the
directory's path), each at its path under the destination, in Bazel's
sorted order where `zip.py` walks the filesystem's. A destination or a name
that varies with the runtime mode (`flutter_patched_sdk_product/` and
`flutter_patched_sdk_product.zip` in release builds; the artifacts'
`linux-x64-<mode>/` prefix) is a `select()` over the mode's settings: the
converter gives a string with a conditional variable one value per case and
spells out `$flutter_runtime_mode` as the mode's values. A source produced
by a target of a wrapped or hand-written tree (`gen_snapshot`, the core
snapshot, the platform kernels) is named in `buildOutputLabels`; one behind
a group (`//flutter/shell/testing` over `flutter_tester`) is found through
the group.

All seven archives of the Linux host builders convert
(`font-subset.zip`, `linux-x64-embedder.zip`, `impeller_sdk.zip`,
`artifacts.zip`, `flutter_patched_sdk.zip`, `flutter_patched_sdk_product.zip`,
`dart-sdk-linux-x64.zip`), and the Linux desktop builders' one
(`linux-x64-<mode>/linux-x64-flutter-gtk.zip`): each with GN's set of
entries, the readme identical modulo the version hash, the data files,
kernels, headers and sources byte-identical, the binaries the files the
build makes. Entry order follows GN's list where GN's does (a directory's
files come sorted, after the list's files).
`tools/gn_to_bazel/tool/artifact_diff.py` compares the two builds' archives
entry by entry.

The GTK bundle places every header the copy `publish_headers_linux` lays
into `flutter_linux/` at its build-directory path -- GN's `foreach` over
`get_target_outputs(":publish_headers_linux")` with `destination =
rebase_path(source, root_build_dir)`. The converter runs the `foreach` (the
body once per element, in the enclosing scope as GN does it; a list it
cannot enumerate, a target's outputs, is one symbolic element) and reads the
resulting entry as a `zip_tree` of the copy's files, rooted where the copy's
output pattern says: outputs of `$root_out_dir/<dir>/{{source_file_part}}`
over sources that all lie under a `<dir>` directory put the tree's root
above it (`shell/platform/linux/public`), so each header lands at
`flutter_linux/<name>` as in GN. A copy of another shape is an error, to be
read when one appears.

## The build directory: `install`

What consumes an engine build reads a directory laid out as GN's
`engine/src/out/<build>/` is. The flutter tool's `--local-engine` reads
`flutter_tester`, `gen_snapshot`, `icudtl.dat`, `impellerc` and
`libtessellator.so`, `font-subset`, `libflutter_linux_gtk.so` with the
`flutter_linux/` headers, `dart-sdk/` (with `bin/dartaotruntime` and the
frontend server's snapshot under `bin/snapshots/`), `flutter_patched_sdk/`,
`gen/flutter/lib/snapshot/` (the core snapshot's four files) and
`gen/frontend_server_aot.dart.snapshot` from there (`artifacts.dart`); the
embedder's consumers `libflutter_engine.so` and `flutter_embedder.h`; CI's
uploader the archives under `zip_archives/`; the analyzer, and the tool as
a build input, the sky_engine package under `gen/dart-pkg/`. Under Bazel
each of these is an output under its own package in `bazel-bin`. `install`
(`install.bzl`) is the `bazel run` target that copies a chosen set of them
to where the consumers look. A rule that knows where GN's build directory
holds its files says so with `BuildDirectoryInfo` (`build_directory.bzl`):
`gn_copy` from its `outputs` (`$root_gen_dir/dart-pkg/sky_engine/lib/async/
{{source_file_part}}` places each source by name there; a literal output
places the one file), `gn_action` under `gen/<package>/`,
`gn_generated_file` at its output, `zip_bundle` under `zip_archives/`,
`dart_pkg` and `sdk_rewriter` where their GN outputs go; `install`'s
`contents` collects these over a target's dependency closure (an aspect
over `deps`, `srcs` and `data`, and over an archive's `files` and `trees`,
since ninja building GN's archive target writes its inputs' closure into
the build directory too: the web builder's install lays the
`flutter_web_sdk/` tree beside `flutter-web-sdk.zip`, a host builder's the
`flutter_tester` and libraries its archives pack -- and, as an aspect does
not reach a rule through its output files, a `zip_bundle` places the
entries whose GN source is an output of the build itself, at the source's
build-directory path the converter hands it as `sources`: the patched
SDK's dills, the snapshots under `gen/`; and it carries GN's `deps`, the
targets whose outputs the entries are, so that what their closure places
is laid too, as ninja's build of the archive leaves every output of those
targets in the build directory and not only the ones the archive packs:
the core snapshot's `isolate_snapshot_instructions.bin` and
`vm_snapshot_instructions.bin` beside the two `artifacts.zip` takes), so that one target --
the sky_engine package's -- brings its thirty copies, its generated file
and its assembled directory along. The script copies from the runfiles
tree, where each file is symlinked by its index in the install's list
rather than at its short path: one target built under several
configurations (CanvasKit's module under its three platforms) has one
short path for its several files, and a short-path runfiles tree would
hold one of them. For rules that do not say, `files` maps a target to the
directory under the build directory that holds its files by base name,
`trees` are `zip_tree` targets whose files go at their paths under the
tree's destination (the Dart SDK, the GTK headers), and `archives` are
`zip_bundle` targets whose archives go under `zip_archives/`. The
destination is `engine/src/out/<variant>/` -- `<variant>` GN's name for the
configuration's build directory (`host_debug_unopt`, `host_debug`,
`host_release`, `wasm_release`; `checkout_view.bzl`) -- or a directory named after `--`,
relative to the checkout; the copies land in the checkout
(`BUILD_WORKSPACE_DIRECTORY`), outside Bazel's output tree, as GN's would,
and writable, as GN's are (Bazel's outputs are not; a second install
replaces the first's).

An executable or shared library lands as GN's link tools leave it. GN's
Linux toolchains (`build/toolchain/gcc_toolchain.gni`) link every
executable to `exe.unstripped/<name>` and `llvm-objcopy --strip-all` it
into the build root, always; a shared library goes through
`lib.unstripped/` the same way under `stripped_symbols` -- `tools/gn`'s
default, which only the developer's `--no-stripped` configurations turn
off. So GN's `flutter_tester` in `out/linux_debug_arm64` is 57 MB over a
131 MB `exe.unstripped/flutter_tester`, and its archives pack the stripped
binaries. Bazel's binary in `bazel-bin` stays as linked -- the tests run it,
as GN's unstripped copy is there to be run under a debugger -- and the
aspect that places a `cc_binary` strips what is shipped
(`build_directory.bzl`): the same tool with the same flag writes the copy
under `shipped/` beside the binary, with the binary's own name, since the
scripts that pack it name entries after their inputs (`<name>.stripped` is
`cc_binary`'s own, the toolchain's strip with `-S`, debug sections only), which an `install`
lays at the build root and a `zip_bundle` packs, with the binary as linked
under `exe.unstripped/` or `lib.unstripped/`; a shared library under
`--//engine/src/flutter/build/bazel:stripped` (the default), as linked
otherwise. `--no-stripped` in a builder configuration is that flag off
(the developer's `host_debug`, `host_debug_unopt`, `host_profile`,
`host_release`); for the web it is nothing, as GN's wasm toolchain strips
nothing; for Android it is the default, and the aspect adds GN's android
toolchain's `--strip-unneeded` copy as `lib.stripped/<name>` (see the
Android section). The Dart wrap's `gen_snapshot` is already GN's stripped file.

The root package has `//engine/src/flutter:install`, the Linux host's build
directory as above with all seven archives of the Linux host configurations
-- and, under an Android platform, the Android developer's: the developer's
`android_*` configurations have no ninja targets of their own (GN builds
its default target, which is the root group `flutter`: `engine/src`'s
`//:default` depends on `//flutter` alone), so the install's attributes
select on the OS, and on Android lay that group -- libflutter.so with
`lib.stripped/`, the jars and poms, `clang_x64/gen_snapshot`, the
snapshots, the Impeller SDK, the embedder archive, the javadoc, ICU's data
file for the target (334 files for `android_debug_arm64`). Against GN's own
`out/android_debug_arm64`, `install_diff.py` finds nothing missing on
either side over 19 paths: 305 files identical, the binaries expected
different, and the poms, Maven metadata and javadoc pages differing by the
version hash and the date alone. The Maven tree and the `dist` archives are
not the default's under GN either; the builders name them as targets.

```sh
bazel run //engine/src/flutter:install
bazel run //engine/src/flutter:install -- engine/src/out/host_debug_unopt_bazel
bazel run --config=android_debug_unopt_x64 //engine/src/flutter:install   # out/android_debug_unopt_x64
```

installs 1,390 files; `tools/gn_to_bazel/tool/install_diff.py` compares such
a directory with GN's path by path (the consumer-visible paths above by
default; a directory is every file under it, an archive is compared entry
by entry as `artifact_diff.py` does): against `host_debug_unopt`, 17 of 17
paths agree -- 1,387 files identical, the eight binaries differing as builds
under different flags do, nothing missing on either side. Two things the
comparison turned up. GN's build root holds the *full* ICU data file
(`copy("copy_icudata")`, `common/icudtl.dat`, 10.8 MB), where `artifacts.zip`
ships the trimmed `flutter/icudtl.dat` (865 KB): a `--local-engine` run
loads different ICU data than a release does; `install` follows the build
directory. And the converter gives a copy elsewhere in the build directory
that renames its file (`copy_headers`: `embedder.h` to `flutter_embedder.h`)
an `outs` with GN's path for it, so that the Bazel file bears the layout's
name (`gn_copy` already renamed for literal outputs under the gen dir).

The sky_engine package (`sky/packages/sky_engine`, GN's
`gen/dart-pkg/sky_engine/`: the core libraries' sources copied out of the
Dart tree, `dart:ui`'s, `dart:ui_web`'s rewritten by `web_sdk/
sdk_rewriter.dart`, the embedder specification, and the package's own files
laid in by `build/dart/tools/dart_pkg.py`) converts as any other file: the
copies read the Dart SDK's `<library>_sources.gni` lists through
three-argument `rebase_path()` and name files of the Dart tree
(`@dart//:sdk/lib/async/async.dart`, which the overlay exports) and of other
packages; `generated_file` with `contents` is `gn_generated_file`; the
`dart_pkg.py` action is converted by its script (the converter's
`scriptMappings`) into `dart_pkg` (`build/bazel/dart/dart_pkg.bzl`), which
runs the script into a directory artifact; `web_ui_ui_web_with_output` is
`web_sdk/web_sdk.bzl`'s `sdk_rewriter` rule, which runs the script under
the prebuilt Dart SDK with the Dart tree's package configuration and
declares an output per source. The script's directory walk did not follow
symbolic links, which a sandbox's inputs are; it does now (a one-line
change, harmless to GN). Its 289 files come out byte-identical to GN's.

To use such a tree as a local engine with the flutter tool:

```sh
bazel run --config=host_debug_unopt //engine/src/flutter:install -- engine/src/out/host_debug_unopt_bazel
cd packages/flutter
../../bin/flutter test test/widgets/text_test.dart \
    --local-engine=host_debug_unopt_bazel --local-engine-host=host_debug_unopt_bazel
```

(any name under `engine/src/out/` will do; `host_debug_unopt`, the
default, is where GN's own build of that configuration lands, which
`install` overwrites -- each installed path is removed first and copied
afresh, since GN's copies are hard links of their sources and a copy
onto a hard link of its own source is refused as "the same file". GN's
files come back by deleting the installed paths -- the install script in
bazel-bin lists them -- and running `ninja` there; ninja takes the newer
Bazel copies for up to date otherwise). The tool reads `flutter_tester`, the patched SDK,
`dart-sdk/bin/dartaotruntime` and the frontend server from the tree, as the
verbose log shows. One thing to know on a fresh checkout: under a local
engine the tool downloads no engine artifacts, and pub resolves
`sky_engine` from `bin/cache/pkg/`, which only a run *without*
`--local-engine` populates -- run one plain `flutter test` first, or the
first local-engine run fails in pub with "could not find package
sky_engine". `packages/flutter/test/widgets` passes on the Bazel tree with
GN's exact numbers (7,349 tests, 128 skipped).

Not installed yet: the web SDK, and GN's own bookkeeping (`args.gn`,
depfiles). `compile_commands.json`, which `tools/clang_tidy` and clangd
read, comes from `tools/gn_to_bazel/tool/compile_commands.py` over
`bazel aquery` after a build (a tool, since no action can query the
graph); its entries run from the execution root, where Bazel's relative
include paths resolve, but name the source and the compiler as the
checkout spells them, so that `tools/clang_tidy`'s file selection and its
search for `clang-tidy` beside the compiler work on it as they do on GN's
(`ci/clang_tidy.sh --variant <build directory>`). The builder-specific
targets below install the archives alone.

## The builders: `--config=<build>` and their install targets

CI's builds are `ci/builders/*.json`: for each, the `tools/gn` flags of its
GN configuration, the ninja targets it builds, the archives it uploads from
`engine/src/out/<target dir>/zip_archives/`, the tests it runs. The
converter reads the Linux builder files (`tools/gn_to_bazel`'s
`builders.dart`, run with the rest) and generates two files beside them.
`ci/builders/configs.bazelrc`, which the root `.bazelrc` imports, has a
`build:<name>` configuration per Linux build -- the x64 host's own, the
web's, the arm64 cross builds' and Android's -- whose flags the Bazel build can all express -- `--runtime-mode` is the runtime mode setting,
`--unoptimized` the compilation mode (its absence `-c opt`), `--target-dir`
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
of the clang toolchains, Linux and Android; on in an optimized build
without `--no-lto`, as `tools/gn` has it, which is CI's Android AOT builds),
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
`--rbe`/`--no-goma` where the build runs and `--build-embedder-examples` a
target list, neither a flag -- and, for a build with a flag the Bazel build
has no setting for yet, the reason and no configuration:
`--no-prebuilt-dart-sdk`. The developer's own configurations,
`local_engine.json`'s `linux/` builds (what `et build --config <name>` runs:
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
Of the fifty-five Linux builds, fifty-four have a configuration, fifty-one
distinct: the host's `host_debug`, `ci_host_debug`,
`host_debug_unopt`, `host_profile`, `host_release`, `ci_host_release`,
`host_debug_desktop`,
`host_profile_desktop`, `host_release_desktop`, `host_debug_test`,
`host_profile_test`, `host_release_test`, `ci_host_debug_unopt`,
`host_debug_unopt_impeller_tests`, `host_debug_ddm`,
`host_release_licenses`, `host_debug_clang_tidy`; the web's `wasm_release`,
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
`android_embedder_debug_unopt`. The one without is
`ci/host_debug_no_prebuilt_dart_sdk`. The file ends by naming the builds of
those files that are not configurations at all, each with its reason --
the twelve Fuchsia builds (a platform the Bazel build has none for yet)
and the eight web test bundles (no `tools/gn` step) -- so that every build
of the Linux builder files is in one place or the other, and one filed
under the wrong reason shows.
`ci/builders/BUILD.bazel` has an `install` per
build over the Bazel counterparts of its ninja targets (a label, a
directory for its target of the same name, a bare unique name, as GN's
ninja files spell them), installing into GN's `--target-dir` -- or, for a
build without one, the directory `tools/gn` names for its flags, which the
install rule reads off its configuration (`checkout_view.bzl`'s
`build_directory_attrs`: `host`, `wasm` or `linux`, the runtime mode,
`_unopt`, `_arm64`) --
with the
targets nothing converted answers to listed (`flutter:unittests`,
`flutter/build/dart:dart_sdk`, the licenses tool):

```sh
bazel run --config=ci_host_release //engine/src/flutter/ci/builders:ci_host_release
bazel run --config=ci_host_debug //engine/src/flutter/ci/builders:ci_host_debug
bazel run --config=host_profile //engine/src/flutter:install   # the developer's: everything
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
`engine` the 27 executables `run_cc_tests` runs on Linux, each the
converted test of that name -- `runTestsTypeSuites` and
`runTestsEngineSuites` in `builders.dart`), with the build's other steps
(the formatter, the linters, `generate_metrics.sh`) listed as what they
are, scripts of the checkout:
`bazel test --config=host_debug_test //engine/src/flutter/ci/builders:host_debug_test_tests`
runs what `Linux linux_host_engine_test`'s `host_debug_test` runs.
`generated_file` over `metadata` (the macOS entitlements lists) is the
Apple phase's.

## `et` with `--backend bazel`

`et build`, `et test`, `et run`, `et query targets` and `et lint` take
`--backend bazel` (or `ET_BACKEND=bazel` in the environment; `gn` otherwise, and
nothing changes for anyone who does not ask), which drives the Bazel build
of the same configuration instead of GN and ninja. `et` asks the converter's code (`tools/gn_to_bazel`'s
`builders.dart`, the same that generates `configs.bazelrc`) which
`--config=<name>` the build has -- `host_debug_unopt` for the developer's
`host_debug_unopt`, `ci_host_debug_unopt` for `ci/host_debug_unopt` -- and
refuses, naming the flag, a build the Bazel build cannot express
(`ci/host_debug_no_prebuilt_dart_sdk`). GN labels and patterns are spelled
the Bazel way through the converter's table: `//flutter/fml:fml_unittests`
is `//engine/src/flutter/fml:fml_unittests`, `//flutter/shell/...` is
`//engine/src/flutter/shell/...`, `//flutter/fml:all` is
`//engine/src/flutter/fml:all`; a directory the converter has not converted
is left to Bazel to report.

```sh
et build --backend bazel --config host_debug_unopt //flutter/fml:fml_unittests //flutter/txt/...
et build --backend bazel --config host_debug_unopt        # everything: install into out/host_debug_unopt
et test --backend bazel --config host_debug_unopt //flutter/fml:fml_unittests
et test --backend bazel --config ci/host_debug_test       # the builder's own suite (its run_tests.py steps)
et query targets --backend bazel //flutter/fml/...        # the rules under fml, as GN labels
et query targets --backend bazel --testonly //flutter/... # the tests
et lint --backend bazel --config host_debug_unopt         # clang-tidy over the build's compile_commands.json
et run --backend bazel --config host_debug_unopt -- -d linux  # install, then flutter run --local-engine
et build --backend bazel --config ci/android_debug_x64 //flutter/shell/platform/android:flutter_jar_zip
et build --backend bazel --config android_debug_unopt_arm64  # the developer's linux/android_debug_unopt_arm64, installed into out/android_debug_unopt_arm64
```

Android builds are named as `et` names them under GN: `ci/android_debug_x64`
for CI's, `android_debug_unopt_arm64` for `local_engine.json`'s
`linux/android_debug_unopt_arm64` (there is no developer `android_debug_x64`
on Linux; `et build --help --verbose` lists what there is). `ci/` builds
are accepted without `--verbose`; `--help` merely hides them.

`et build` with no targets is GN's default target, everything, which under
Bazel is the build's install target run into its build directory
(`//engine/src/flutter:install` for a developer's build;
`//engine/src/flutter/ci/builders:<name>` for a CI build, over its ninja
targets) -- GN's layout from Bazel's outputs, in the directory GN would have
used. `et test` with no patterns runs the build's `<name>_tests` suite, and
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
read no build and run as before. `et run` installs the host build (and
the target build, when it is another one the Bazel build has a
configuration for) into its build directory and hands over to `flutter
run --local-engine` exactly as the GN path does. `--gn-args`
has no Bazel counterpart (the configuration is the whole of it) and is
refused; `--rbe`, `--lto` and `--build-strategy` are GN's concerns and are
ignored. `et stamp` and the rest stay on GN for now. bazelisk must
be on PATH (`.bazelversion` pins the version); `bazel` is accepted when it
is not.

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
