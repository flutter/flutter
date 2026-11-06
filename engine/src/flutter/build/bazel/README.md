# build/bazel

Bazel-side support files for the GN → Bazel migration of the engine build:
the build's settings, toolchains, wrapped GN builds and third-party overlays
here, and the rules in `//build_defs/` (this file documents both). Nothing
in this directory is used by the GN build.

| File | Role |
| --- | --- |
| `BUILD.bazel` | The engine build's settings and configuration targets: the build-wide `config_setting`s the generated `BUILD` files `select()` on (`optimized`, `not_<os>`, `host_toolchain`, `flutter_cxx`...) and the flags the builders set (`stripped`, `asan`, `lto`, `embedder_for_target`; `.bazelrc`, `ci/builders/configs.bazelrc`). |
| `third_party/<name>/BUILD.<name>.bazel` | Overlay root `BUILD` files for dependencies that ship no usable Bazel build files. Deliberately not named `BUILD.bazel`, so Bazel does not treat them as packages of this repository. |
| `toolchains/` | The hermetic C/C++ toolchains (`cc_toolchain_config.bzl` holds the flag tables, `BUILD.bazel` the `cc_toolchain`/`toolchain` targets per platform, `tests/` a smoke test). |
| `dart_wrap/` | The Dart SDK, built with `gn_build`: `BUILD.gn` lists the GN targets, `BUILD.bazel` the args, the inputs and the `cc_library` facades; `tests/` starts the VM from the archive. |
| `gl_wrap/` | The GPU test backends -- ANGLE, SwiftShader, the Vulkan loader -- built with `gn_build` the same way; `stubs/` holds the stand-in GN files for the engine directories ANGLE's GN reaches; `tests/` renders through both. See below. |
| `web/` | The web build's configuration targets (the module variants' settings). |
| `README.md` | This file: the design of the whole, rules included. |
| **`//build_defs/`** (the repository root) | **The rules** (`.bzl`) the `BUILD` files load, by subject -- `cc/`, `config/`, `gn/`, `dart/`, `dist/`, `testing/`, `web/`, `flatbuffers/`, `impeller/`, `repositories/` -- with their scripts and helper targets; `build_defs/README.md` is the index, the sections below the design. Rules relevant to one directory stay with it: the toolchain configurations (`toolchains/`), `packages/flutter/test/framework_tests.bzl`. |

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

Every tool is a `DEPS` entry, `@cpython3` included: the hermetic Python
`engine/src/.gn` names as GN's `script_executable` (DEPS'
`engine/src/flutter/third_party/cpython3`) is the interpreter for the
Python scripts that wrapped GN builds and the converted actions run, so no
Bazel action reaches for depot_tools' `vpython3` or the machine's `python3`.
(Until 10-30 `.gn` named `vpython3` and `@cpython3` was pinned by hand to
Skia's Bazel build's version; the pin now comes from `DEPS` like the rest.)

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
the install reproduces: see the install section). Its outputs live in
`bazel-out/linux_arm64_<mode>-opt/`, apart from the host's
`linux_x64_<mode>-opt/` (the root `.bazelrc`'s
`--experimental_platform_in_output_dir` over the per-mode platforms of
`build_defs/config/platforms.bzl`; see the local engine section below), so
switching between the two rebuilds nothing.

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
`third_party/java/openjdk`; on a Mac the bundle's `Contents/Home`, so that
the overlay's paths hold on every host) and the embedding's 43 dependency jars
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
`clang_arm64_apilevel26/`; and `env`, which carries into the action's key
what a script reads outside its inputs (`copy_info_plist.py` runs `git
rev-parse HEAD` for the Apple frameworks' Info.plist: the converter sets
`FLUTTER_ENGINE_VERSION` from `@engine_version` on that script's actions,
so they rerun when HEAD moves instead of serving a cached revision).
`shell/vmservice/BUILD.bazel` is hand-written
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
Android builders upload has its counterpart. The APK variants of two of the
device suites (GN's `native_activity_apk`: the Vulkan backend's and the
Android toolkit's, android.app.NativeActivity around the suite's library)
build too -- `build_defs/android/native_activity_apk.bzl` is the template's
three targets: the manifest from its template, the library as a
`flutter_shared_library`, and the packaging script over the SDK's aapt2,
zipalign and apksigner with `@openjdk`'s java, the APK at the build root
(`impeller_vulkan_android_unittests.apk`, 144 MB unstripped under the
emulator builder's configuration, signed by the checked-in debug keystore;
the emulator builder's install lays it). What is not here: *running* the
three device suites the emulator builder's `run_tests.py --type android`
pushes and the APKs it installs (they build for `android_x64`; an emulator
is the next phase), and x86, which no builder builds.

**Android from a Mac host** (450–452, NEED_DECISION Q32): the Android
toolchains take the host's clang and constraints (`HOST_CLANG`,
`HOST_OS_CONSTRAINT`, `HOST_CPU_CONSTRAINT`) and the NDK's directory of host
tools (`HOST_NDK_PREBUILT`: `linux-x86_64` or `darwin-x86_64` -- GN's
`android_host_os`/`android_host_arch`; only the sysroot and the compiler
runtime archives under it are read), the Dart wrap passes a Mac host's
Xcode arguments for every target (`MAC_HOST_GN_ARGS`: tools/gn's
`setup_apple_sdks` runs on the host's OS, and the host toolchain compiles
the Android target's gen_snapshot), and the Android shell's generated file
is evaluated with `host_os` as cases (the gen_snapshot archive is
`darwin-x64.zip` from a Mac, holding the universal gen_snapshot
`lib/snapshot:create_macos_gen_snapshots` joins and the entitlements file;
`analyze_snapshot`'s archive is a Linux host's). The six
`mac_android_aot_engine.json` builds have their installs
(`--config=mac_android_profile[_arm64|_x64]`, `mac_android_release[...]`);
on an Apple-silicon Mac `libflutter.so` for arm64 builds in 12 minutes and
`ci/android_profile_arm64`'s install matches GN's build of the same two
targets file for file (GN's tree has besides the two thin host slices lipo
joins, which the recipe does not publish).

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
compile alone. The converter gives these rules the compiler options a
cc rule gets besides the invocation's `cflags`: the copts constant
(`FLUTTER_COPTS` for skwasm, which lists `//flutter:config`;
`CHROMIUM_CODE_COPTS` for CanvasKit's executable) and the flags their
dependencies' public configs hand them, so a module's own sources
compile with `-Werror` and `-Wunreachable-code` as GN's do. The
optimization level is the toolchain's `wasm_optimize` feature: `-O3`
under `opt`, `-Oz` where a variant's platform turns on
`wasm_prioritize_size` (GN passes one or the other).

`toolchains/emscripten/spike/` is Phase 0's metric 0.6: an embind module
(`spike_module`) and one Skia translation unit (`skia_unit`,
`src/core/SkPath.cpp` with the wasm_release's defines), both `manual`
since the SDK is optional in the checkout, and `spike_test`, which
serves the module over a local HTTP server (an ES-module loader fetches
its `.wasm`) and reads its exports' results from headless Chrome's DOM
dump -- the host's Chrome, or `--test_env=CHROME=` (the pinned Chrome for
Testing, `@chrome`, never returns from `--dump-dom` on this host; the tool's
tests drive it over DevTools instead).

```
# A wasm module builds for a variant of the web build (wasm.bzl: the
# module_platform flag names the wasm_platform; CanvasKit's here, an embind
# module without LTO like this one).
bazelisk build -c opt --//engine/src/flutter/build/bazel/web:module_platform=//engine/src/flutter/third_party/canvaskit:canvaskit //engine/src/flutter/build/bazel/toolchains/emscripten/spike:all
bazelisk test -c opt --//engine/src/flutter/build/bazel/web:module_platform=//engine/src/flutter/third_party/canvaskit:canvaskit //engine/src/flutter/build/bazel/toolchains/emscripten/spike:spike_test
```

Against `out/wasm_release`: the Skia unit's compile line carries every
flag and define GN's does, in GN's order but for the per-target `-Werror`
(copts.bzl's class) and the include directories' spelling; the module's
link line is GN's skwasm link in GN's order (the module's flags, the
compiler config's, the optimized build's, the libs), plus the relative
sysroot and Bazel's `-o` first. The module loads and runs in Chrome,
5 of 5.

### The macOS toolchains

GN's `//build/toolchain/mac:clang_arm64` and `clang_x64` (a Mac host,
`tools/gn --mac --mac-cpu <cpu>`), assembled from the same pieces
(`toolchains/macos_toolchain.bzl`; `cc_toolchain_config.bzl` under `os =
"mac"`): the checkout's clang for the Mac (`@clang_mac_arm64`,
`@clang_mac_x64`: `buildtools/mac-<cpu>/clang`, the Linux package's version,
whose driver links with its own `ld64.lld` by default, as GN's does), the
macOS SDK of the host's Xcode as sysroot (`@macos_sdk`), the engine's
libc++ as everywhere, and `--target=<cpu>-apple-macos -arch <cpu>
-mmacosx-version-min=12.0.0`. Four toolchains, since a Mac of either CPU
builds for either (`macos_arm64_clang`, `macos_x64_clang`, and the two
cross ones); the platforms `toolchains:macos_arm64` and `:macos_x64` name
the CPU built for, and a Mac's own build needs no `--platforms`. Every
target of theirs is `target_compatible_with` macOS, so a wildcard build on
Linux skips them without fetching a clang the checkout there has not -- and
the Linux and Android toolchains' targets are compatible with Linux and
Android alone for the same reason the other way round: a Mac's checkout has
neither the Linux clang nor the Debian sysroots (DEPS syncs them under
`download_linux_deps`), and its wildcard build skips them. The rule is
general: a toolchain's files are configured for its target platform when
it is used, so each toolchain's targets name that platform's OS.

The iOS toolchains are GN's `ios_clang_arm` (a device), `ios_clang_arm_sim`
and `ios_clang_x64_sim` (the simulator; `tools/gn --ios [--simulator
[--simulator-cpu <cpu>]]`) the same way (`toolchains/macos_toolchain.bzl`'s
`ios_clang_toolchain`; `cc_toolchain_config.bzl` under `os = "ios"`: the
Mac's flags less the desktop's stack protector, search paths, rpaths and
`-pie`, `-Os` when optimized): the same clang over the iPhoneOS or
iPhoneSimulator SDK of the host's Xcode, `--target=<cpu>-apple-darwin -arch
<cpu>` and `-miphoneos-version-min=15.0` or `-mios-simulator-version-min=15.0`
(`build_defs/cc/apple.bzl`'s `IOS_DEPLOYMENT_TARGET`). The platforms
`toolchains:ios_arm64` (a device), `:ios_sim_arm64` and `:ios_sim_x64` carry
the environment as a constraint of their own (`build/bazel:ios_environment`,
`ios_device` or `ios_simulator`: GN's `use_ios_simulator`, which the
toolchains resolve by and the generated files select on through
`ios_simulator_enabled`), each with its runtime modes; six toolchains, from
either Mac; their files are compatible with iOS, and a Mac runs a
simulator build's binary under `xcrun simctl spawn`
(`toolchains/tests:ios_cc_toolchain_smoke`). The Swift rule picks the SDK,
the triple (`<arch>-apple-ios15.0[-simulator]`) and the Swift libraries'
directories from the same constraints.

`@macos_sdk` (`build_defs/repositories/macos_sdk.bzl`) runs `xcrun --sdk
macosx` and lays a *view* of the SDK it names -- `MacOSX.sdk/` with the
SDK's entries symlinked, `System/Library/Frameworks` as a directory of the
frameworks' symlinks without `Ruby.framework`, which holds the SDK's one
symlink cycle -- and the same for the iPhoneOS and iPhoneSimulator SDKs
(`iPhoneOS.sdk/`, `iPhoneSimulator.sdk/`; `:ios_sdk`, `:ios_simulator_sdk`
and their `_view` markers; `IPHONEOS_*`, `IPHONESIMULATOR_*` and
`IOS_SDK_VERSION` in `sdk.bzl`), optional on a Mac without them. The toolchain passes the view as `-isysroot` (GN's and
Apple's spelling; a `sysroot` feature of the toolchain's own replaces
Bazel's `--sysroot=`), and its `usr/include`, `usr/lib`, `Frameworks`,
`SubFrameworks` and `SDKSettings.*` are directory inputs of every compile
and link, tracked by content like the Linux sysroot's: an Xcode update
changes the actions' keys, and a remote cache would see the SDK as an
input rather than as an assumption about the executor. `DEVELOPER_DIR`
selects the Xcode as it does for `xcrun`; without it the repository
watches `xcode-select`'s link and the chosen Xcode's `version.plist`.
`@macos_sdk//:sdk.bzl` records the paths and versions found. Off macOS the
repository is empty.

The flags are those of a `tools/gn --mac --unoptimized` build's command
lines (taken on a Mac, 10-26): `-fstack-protector-all` where Linux has
`-fstack-protector --param=ssp-buffer-size=8 -pipe -pthread`;
`-Wunguarded-availability` and -- `tools/gn` sets
`allow_deprecated_api_calls` on a Mac -- `-Wno-deprecated-declarations`
among the warnings (`copts.bzl`'s macOS lists); `-stdlib=libc++` after the
C++ flags; `-fobjc-call-cxx-cdtors` for Objective-C++, the one
toolchain-wide Objective-C flag (ARC and the selector checks are a
target's, `MACOS_CFLAGS_OBJC`); `_DEBUG` without `_GLIBCXX_DEBUG`; `-g2` in
every mode and `-Wl,-dead_strip` in opt (symbol_level is 2 on a Mac);
links with `-nostdlib++ -Wl,-search_paths_first` and the three rpaths of
`mac_dynamic_flags`, executables with `-Wl,-pie` and the
`@executable_path/Frameworks` rpath of GN's `link` tool. Left out: GN's
`-fdebug-prefix-map=<checkout>/engine/src/=` (Bazel's paths are
execution-root relative already, as on Linux) and `-L.`, the GN output
directory. Three things differ in kind from the Linux toolchains: Bazel's
own link features take their Mach-O forms (`target_libc = "macosx"`: an
alwayslink library is `-force_load`ed, rpaths say `@loader_path`, and the
archive action speaks libtool -- `-static -o` -- so the package's
`llvm-libtool-darwin` stands where GN runs `llvm-ar rcs`, writing the same
BSD archives with a symbol table); there is no `--start-lib` -- ld64 has
none -- so a library is its archive and an alwayslink one (a GN
source_set) is linked whole, which is GN's list of its objects again; and
Objective-C sources go through `flutter_objc_library`
(`build_defs/cc/objc_library.bzl`: `cc_library` takes none, and Bazel's
`objc_library` adds mode flags of its own, `-Os` in opt among them), for
which the toolchain has the `objc-compile`/`objc++-compile` actions on a
Mac alone. libc++abi leaves out `cxa_thread_atexit.cpp` on Apple
platforms as GN does.

```sh
bazelisk test //engine/src/flutter/build/bazel/toolchains/tests:macos_cc_toolchain_smoke_test   # on a Mac
```

The smoke test checks C++20, the engine's libc++ (`__fl`), the SDK with
GN's deployment target (`__MAC_OS_X_VERSION_MIN_REQUIRED == 120000`), no
exceptions or RTTI, C, and Objective-C++ through `flutter_objc_library`
with ARC against Foundation (a C++ member's constructor and destructor run
inside an Objective-C object). On the Mac (10-26): its first run 16.8 s
wall -- the SDK view fetched (`xcrun`, ~300 symlinks), 4,772 targets
analyzed, libc++, libc++abi, googletest and the test compiled, 84 actions
in the darwin sandbox -- 7/7; a no-op rerun 0.3 s; `-c opt` 17.6 s, the
`.mm` compiled with `-O2 -g2` and nothing of Bazel's. The command lines
are GN's flags in GN's order but for a target's own, which Bazel puts
after the toolchain's (research/20 has both).

The converter speaks macOS as of the same day: `is_mac` (and `is_apple`,
which derives from it) is a platform condition, rendered as `select()`s on
`@platforms//os:macos` as `is_android`'s and `is_wasm`'s are, so the
darwin branches of every converted file are in the generated BUILD files
(fml's `platform/darwin/`, the shell's `//flutter/shell/platform/darwin`
dependency, Skia's Metal backend when its repository converts on a Mac);
`is_ios` the same since the iOS port (`@platforms//os:ios`; `is_apple` is
`is_ios || is_mac`), with what the iOS branches read given a Bazel-side
meaning: `use_ios_simulator` is the platforms' environment setting,
`ios_platform_path` and `ios_sdk_path` a `@macos_sdk` constant per
environment (a reference per case of the predicate, `GnPredicateCases`),
`darwin_target_arch` and `darwin_target_sim` the Swift triple's parts (a
string that expands several conditional variables is a value per
combination), the deployment targets `15.0`. The arguments tools/gn passes
for a Mac or for iOS alone (`allow_deprecated_api_calls`, `skia_use_metal`;
iOS's `skia_use_gl` off, no Vulkan) are formulas over the OS beside the
web's (`perTargetOsArguments`). The files both Apple shells reach
(darwin/common, darwin/graphics, the darwin group) are converted under
`is_ios || is_mac` (a manifest condition may be a disjunction), the Metal
backends under `impeller_enable_metal`, and the iOS shell itself
(`shell/platform/darwin/ios`: Flutter.framework for a device or the
simulator, its xcframework) under `is_ios`; Impeller's shaders macro builds
each backend under its setting (iOS has Metal alone, with `--metal-ios`). A GN target's `.m` and `.mm`
sources go to a `flutter_objc_library` beside its `cc_library` or test,
`<name>_objc` -- the same headers, flags, defines and dependencies, the
target's `cflags_objc`/`cflags_objcc` (one list, `MACOS_CFLAGS_OBJC`
under `is_mac`) besides, alwayslink as the target is, compatible where the
sources are listed -- which the target depends on under the same
conditions; a target with Objective-C flags and no Objective-C sources
gets neither, as GN applies them to no compile. Three files keep `is_mac`
false for now (the manifest's `assume`, `macosDeferred`): the archives'
and font-subset's entitlements lists and the Impeller SDK's dylib are the
Apple products' phase's. And the host itself is a repository,
`@host_platform//:host.bzl` (`HOST_OS`, `HOST_CPU`, their constraints,
`HOST_PREBUILTS`, `HOST_DART_SDK`, `HOST_CLANG`), from which
`build/bazel`'s `host_toolchain` group takes the host's CPU -- an
Apple-silicon Mac is its own host, where x86_64 was assumed.

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
from the same places as for the rest of the build: `@gn`, `@ninja`, the
host's clang (`@host_platform`'s `HOST_CLANG`: `@clang_linux_x64`,
`@clang_mac_arm64`, ...), the Linux sysroots for the Linux and Android
targets, and `@cpython3` as the `--script-executable` (what `.gn` names
too). GN's `host_os` and `host_cpu` are the host's
(`HOST_OS`, `HOST_CPU`), and the host's tools land under
`clang_<host cpu>/` in a build for anything but the host's own OS and CPU
(`:host_own`); for the macOS platforms the GN args are what `tools/gn`
sets on a Mac (`target_os = "mac"`, the 12.0.0 deployment target, no
simulator) with the SDK, platform and toolchain paths of the host's Xcode
from `@macos_sdk` -- the same Xcode the Bazel toolchain's sysroot is a
view of, named in the args so that the action's key carries it, where
`darwin_sdk.gni` would otherwise ask `xcrun` -- and the prebuilt SDK is
the Mac's for the CPU (`@dart_sdk_macos_arm64`, `@dart_sdk_macos_x64`).

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

Known limits: zlib and BoringSSL
have no Bazel targets yet and stay inside `libcommon_embedder_dart_io.a`;
`bootstrap_compile_platform.exe`, which the prebuilt SDK's `dart compile exe`
produces, embeds the absolute path of the build directory (as the GN build's
does), so it differs between sandboxed runs; and the Dart version script
looks for `git` on `PATH` at `gn gen` time (and copes without it).

### The Dart SDK from source: `--no-prebuilt-dart-sdk`

Every builder but one runs on the prebuilt Dart SDK of DEPS
(`flutter/prebuilts/<host>/dart-sdk`, GN's `flutter_prebuilt_dart_sdk`). The
one -- linux_unopt.json's `ci/host_debug_no_prebuilt_dart_sdk`, the Dart
roll's check that the engine builds against the Dart tree it syncs --
passes `tools/gn --no-prebuilt-dart-sdk`; under Bazel that is the wrap's
setting:

```sh
bazelisk build --config=host_debug_no_prebuilt_dart_sdk //engine/src/flutter:flutter
# or, on any host build:
bazelisk build --//engine/src/flutter/build/bazel/dart_wrap:flutter_prebuilt_dart_sdk=false ...
```

With the setting off, in the host's own build (`dart_sdk_from_source`), the
wrap's GN root adds `create_sdk` and kernel-service's `frontend_server_aot`
(`dart_wrap/BUILD.gn`'s `flutter_build_dart_sdk`, with tools/gn's
`dart_include_wasm_opt = false`), its tree gains what the SDK's build reads
beyond the engine's Dart targets (`@dart//:sdk_build_tree`: binaryen, the
prebuilt DevTools app, devtools_shared, dev_compiler's web entry point, the
root's LICENSE and README, DEPS), and three more products come out:
`dartaotruntime` (the SDK's `bin/`), `frontend_server_aot_product.dart.snapshot`
(the SDK's own, from `bin/snapshots/`) and `frontend_server_aot.dart.snapshot`
(the release-mode one GN's `flutter_frontend_server` copies into the build
directory, which `flutter_frontend_server:frontend_server` exports). The
kernel compiles run the first two through `dart_wrap:engine_dartaotruntime`
and `:engine_frontend_server` (an AOT runtime loads only a snapshot of its
own build: the release snapshot on the product runtime fails with "the
snapshot requires 'release ...' but the VM has 'product ...'"). GN runs the
frontend server from source on the Dart tree's own prebuilt VM instead
(`flutter_frontend_server.gni`'s `prebuilt_dart_action`); the built pair is
the same check of the roll with the compiler compiled once. A cross build
keeps the prebuilt SDK whatever the setting says (the built SDK would be
the target's, which no build-time tool could run).

Cost: the SDK alone is a 19-minute GN build on 24 cores (5,256 steps, 685
MB); the root group under the configuration takes about 35 minutes with
the wrap on the critical path. Left as they are: the archives' dart-sdk zip
and the web SDK's compilers (no builder builds them without the prebuilt;
the generated files keep `flutter_prebuilt_dart_sdk` assumed on), the
`dart-sdk/` tree of `local_engine.json`'s facsimile and of the root group's
install (`build/dart:dart_sdk` lays the prebuilt's there, where GN's is
`create_sdk`'s; the built tree as a directory product of `gn_build` is
research/22's N2), and
the `dart_test`/`dart_binary` rules and the package tests, which run on the
prebuilt SDK (the builder runs no tests).

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

## The framework's and the repository's tests: `flutter_test` and `dart_test`

`flutter test` compiles a test file with the frontend server behind a
generated bootstrap and runs it on flutter_tester; `dart test` compiles and
runs it on the VM. Under Bazel both happen without the tools
(`build_defs/dart/flutter_test.bzl`, `dart_test.bzl`; the design is in the
migration notes, research/15): the pub packages a test reaches are lazily
fetched repositories (`pub.bzl`, a module extension over `pubspec.lock`;
`pub.lock.bzl` holds the lock's packages, checksums and dependency graph,
regenerated by `tools/bazel_tools`' `gen_pub_lock`), `pub_package_config`
writes a `package_config.json` over the closure of some roots' dependencies
in the execroot's or the runfiles' layout, and the compile is a Bazel
action against the engine's platform kernel.

A framework test is two targets: `flutter_test_kernel` compiles the
bootstrap (which imports the test and its directory's
`flutter_test_config.dart`, sets the golden comparator to the test's
directory and runs the test's main through package:test's engine with stack
traces chained, as `flutter test` does) from a `flutter_test_prelude` -- the
libraries a tree's tests share compiled once, each test's compile starting
from that kernel (`--incremental --initialize-from-dill`: 3 s a file instead
of 13) -- and `flutter_test` runs the kernel on the Bazel-built
flutter_tester with `flutter test`'s flags and environment: from the
package's directory, `FLUTTER_ROOT` the runfiles root, the asset directory
(`flutter_test_assets`: the manifests as flutter_tools writes them, the
package's own assets at their keys, its dependencies' as `packages/<name>/...`
-- their lib/ files, and the fonts their own pubspecs declare at their
root-relative paths (`package_assets`: the gallery's flutter_gallery_assets,
shrine_images and cupertino_icons' font) -- the framework's two shaders
compiled by the Bazel impellerc), the SDK cache's paths tests read (`cache`: the Dart
SDK, the Material fonts from a pinned repository), `--vm-service-port=0`
when a tree asks (`vm_service`), Impeller rendering when a tree asks
(`impeller`), `block-network` by default (Skia Gold comparisons are skipped
offline, as flutter_goldens does wherever Gold is unreachable). Three macros
give a tree in one call: `flutter_tests` (one kernel and one run per file,
`<test>_impeller` runs too when asked, the nearest `flutter_test_config.dart`
per file as flutter_tools' `findTestConfigFile` picks it, `flaky` and `large`
files, `shards` -- a file's tests in Bazel shards, contiguous slices as
test_core's `--total-shards` cuts them, for the gallery's smoke test whose
two tests take minutes each; the bootstrap also honours `bazel test
--test_filter=<regex>` over the tests' names), `framework_tests` (`packages/flutter/test/framework_tests.bzl`: the
directories of packages/flutter/test over the tree's shared configurations,
prelude, assets and helpers) and `flutter_package_tests`
(`build_defs/dart/flutter_package_tests.bzl`: any other package, from its
dependencies' closure to its own assets; `directory` for a package outside
`packages/`, `compile_args` for a `--dart-define` tree). `dart_test` and
`dart_package_tests` are the pure-Dart counterparts: test_core's own
`.vm_test.dart` bootstrap compiled for the VM (from a `dart_test_prelude`
of the package's libraries when the package gives `imports`), run by
package:test's runner precompiled to a kernel (`dart test` is dartdev's and
runs pub first) in `--precompiled` mode from the package's directory, with
`FLUTTER_ROOT` the runfiles root, the runtime package configuration at the
package's `.dart_tool/`, and what a tool under test reads of the SDK's
cache laid under `bin/cache` (`cache`, `cache_files`: the Dart SDK, the
engine stamps as fixed words). A test that runs the real pub on a project
of its own (flutter_tools' widget_preview tests, `flutter create`'s) gets
the rest of pub's view of the SDK -- `bin/cache/flutter.version.json`
with a version every `flutter:` constraint allows, the SDK packages under
`packages/`, the engine's `sky_engine` under `bin/cache/pkg/` (an
`assembled_directory`), the Gradle wrapper `flutter create` copies -- and
a `pub_cache` of the hosted packages the project reaches, laid in the
runfiles tree as `.pub-cache` with `PUB_CACHE` pointing at it; pub still
asks pub.dev which versions exist, so such a test has the network (`network`),
and downloads nothing it finds there. `large` names the files that run the
real pub or the analyzer over whole projects (a 15-minute timeout); `sizes`
gives a file a size of its own. A test that runs *the tool itself*
(create_test spawns `bin/flutter` and `dart bin/cache/flutter_tools.snapshot
analyze|test` on the projects it creates) gets the tool from the build too:
`dart_vm_kernel` compiles `bin/flutter_tools.dart` for the VM and the
kernel sits at `bin/cache/flutter_tools.snapshot`, `sdk_files` puts a
launcher at `bin/flutter` (the repository's script would bootstrap from
git and the network), and the engine artifacts lie in the cache's own
layout -- `bin/cache/artifacts/engine/linux-x64` is `linux-x64/artifacts.zip`
and `font-subset.zip` unpacked, `common/` the patched SDK's archive -- as
`bundle_directory` lays a zip_bundle's entries (`ZipBundleInfo`), with the
stamps the tool's `Cache.updateAll` checks before it would download
(`bin/internal`: the engine revision's fixed word, the fonts' and the Gradle
wrapper's pins). The other runtime modes' artifacts -- `linux-x64-profile`
and `linux-x64-release`: gen_snapshot and the desktop embedding, the
product platform kernel under `common/` -- come from the same bundles
built under those modes' configurations through `in_configuration`
(`configuration.bzl`: a transition to `-c opt` and the engine's
`runtime_mode` flag, what `--config=host_release` sets; a platform too,
for the web SDK), so a test that
builds a release app (icon_tree_shaker_test's tree-shaken bundle, the
integration shard's) has them; the first build of a mode is a build of the
engine, cached afterwards. The web SDK comes the same way
(`//engine/src/flutter/web_sdk:web_sdk_directory`: `flutter-web-sdk.zip`
built under the release mode and the Emscripten platform, unpacked as
`bin/cache/flutter_web_sdk`), so `flutter build web` and the widget
previewer run from the facsimile too; its first build is the web engine's.
The integration shard runs the tool as a
process on projects of its own -- hot reload on flutter_tester, the
daemon, the debug adapter, `flutter test` -- and some of its tests run pub
*in a workspace member* (hello_world, dev/automated_tests), which pub
resolves against the whole workspace: `@pub_workspace` (a repository the
pub extension makes: every member's pubspec at its path) is laid at the
root (`sdk_trees`) with a workspace-wide `pub_cache`, the lock is copied
over its symlink first (`writable`: pub touches it), the SDK's bin is on
PATH and the tool gets a HOME of the test's own for its settings. The
projects those tests copy or run in (hello_world, the gallery,
dev/integration_tests/*) are filegroups of globs over the source tree,
which exclude what the tool itself writes into a project
(`FLUTTER_PROJECT_GENERATED`, `build_defs/dart/flutter_project.bzl`:
`.dart_tool/`, `build/`, `android/local.properties`, the generated plugin
registrants, the `ephemeral/` directories), so that a developer's `flutter
test` in one of them does not reach the runfiles -- where those files would
be read-only symlinks the tool under test fails to rewrite. The web
shard (`flutter run -d chrome` and `-d web-server`, hot reload and restart
on the web, the web driver service) and the previewer's tests drive a
browser: `browser` exports Chrome for Testing -- at the version the web
engine's `lib/web_ui/dev/package_lock.yaml` pins, fetched as `@chrome` by
`build_defs/repositories/browsers.bzl` together with its chromedriver, what
CI's `chrome_and_driver` dependency holds -- as `CHROME_EXECUTABLE`, and
`browser_driver` puts the driver's directory on PATH, so the tests drive the
pinned browser wherever they run and not the host's; Chrome's system
libraries (X11, NSS, GTK, ...) come from the runtime sysroot through the
same launcher the web engine's tests use (the next section).
The desktop shard (`//packages/flutter_tools:desktop_shard`, 13 files)
builds and runs Linux desktop apps through the tool: `flutter build linux`
(`--config-only` and whole), the native-asset and data-asset tests,
`flutter run -d linux`, and overall_experience_test, which runs the tool
under `/usr/bin/xvfb-run` when it sees no DISPLAY (two of the native-asset
files build for Android too: `cases` runs their linux cases alone, the apk
ones wanting Android's artifacts, SDK and Gradle). `flutter build linux`
runs `cmake -G Ninja` with `CC=clang CXX=clang++`, `ninja install` and
`pkg-config` for GTK, and package:native_toolchain_c compiles with the
`clang`, `ar` and `ld` it finds on PATH; `linux_build_tools`
(`build_defs/desktop/build_tools.bzl`) writes one `bin/` directory of
scripts in those names that run the build's own -- Kitware's CMake
(`@cmake_linux_x64`, `build_defs/repositories/cmake.bzl`: one static
executable with its modules, pinned by sha256), Debian's ninja and
pkg-config from the runtime sysroot on its libraries, the engine's clang
with `--sysroot` at the engine's build sysroot (bullseye's headers, the
GTK the embedder itself is built against, the link-time stubs; pkg-config
answers for that sysroot's `.pc` files, `PKG_CONFIG_SYSROOT_DIR`), lld as
`ld` and the llvm tools as `ar`, `ranlib`, `strip`, `objcopy`, `nm`,
`objdump`, `readelf` -- and `dart_test`'s `tools` puts it first on PATH
(the scripts find the runfiles root from that PATH entry: a hook of
package:hooks_runner runs with an environment of PATH, HOME and little
else, and native_toolchain_c runs the compiler by its resolved path, the
output tree's, where nothing else of the tree lies).
The built app loads GTK at run time, so the target also carries the test's
environment for it (`ToolEnvironmentInfo`: `LD_LIBRARY_PATH` at the
runtime sysroot's libraries, Mesa's and GLVND's variables, `GIO_MODULE_DIR`
at the sysroot's modules rather than the host's, which GLib would load into
the sysroot's GLib from the path built into it), and `display` (the same
`display_launcher` Xvfb) gives each test an X display of its own: the
runner starts the server with `-displayfd`, exports `DISPLAY` and stops it
after, as xvfb-run would. Measured: the 13 files pass in 719 s of wall
time at `--local_test_jobs=3` (per-test sum 1,986 s; record_use_caching_test
the longest at 336 s), on a host with no cmake, clang or GTK of its own.

The Android shard (`//packages/flutter_tools:android_shard`, 25 files; the
root's `//:android_tool_tests`) builds apps, plugins and modules for
Android through the tool -- `flutter create`, `flutter build
apk|appbundle|aar` in every mode, the Gradle plugin's own tests. What
`flutter build apk` needs, and where it comes from
(`build_defs/android/build_tools.bzl`): the Android SDK, the checkout's
own (`@android_tools`, `ANDROID_HOME`); a JDK, the engine's (`@openjdk`,
`JAVA_HOME`); the engine's Android artifacts in the facsimile's cache --
gen_snapshot for each CPU `flutter build apk` builds for by default (arm,
arm64, x64) in each AOT mode (`artifacts/engine/android-<cpu>-<mode>/linux-x64`,
what `flutter precache --android` downloads), and the embedding as the
Maven artifacts the Gradle plugin resolves, `io.flutter:flutter_embedding_<mode>`
and `io.flutter:<abi>_<mode>` at `1.0.0-<engine.stamp>`. The facsimile's
stamp is the engine's revision (bin/internal's versioned stamps, since 418;
the word `bazel` before), which is what the build names its jars and poms
by, so `engine_maven_repository` lays them under `1.0.0-<revision>` (under
another version, the poms' text rewritten, for a facsimile whose stamp is
another word) as a Maven repository, and `FLUTTER_STORAGE_BASE_URL`
is a `file:` URL to it: the plugin reads `$FLUTTER_STORAGE_BASE_URL/download.flutter.io`,
and Gradle reads Maven repositories from `file:` URLs as from https ones.
`android_engine_artifacts` (in `build/archives`) declares all of it: the
engine for three CPUs in three modes through `in_configuration` -- the
Android builders' configurations, `-c opt` in debug too (`compilation_mode`),
so that a debug build shares `bazel-out/android_<cpu>-opt/` with
`--config=android_debug_<cpu>` -- hours the first time, cached afterwards.
**These tests reach the network, by decision (10-26):** Gradle fetches its
distribution, the Android Gradle plugin, Kotlin and the libraries an app
depends on from Google's and Maven Central's repositories at build time;
nothing of that is in the checkout, and a pinned mirror of it would be a
gigabyte, an order of magnitude beyond the Java tests' Maven lock. The
engine itself does not come from the network. Each test downloads into a
Gradle home of its own under `TEST_TMPDIR` (the tool's HOME is the
test's), so the first minutes of each are Gradle's. Two things of the
sandbox: a JVM takes `user.home` from the password database, not from
`$HOME`, and the Gradle wrapper and the Android tools default to
directories under it -- the invoking user's real home, read-only in the
sandbox, where the wrapper died at once on its lock file -- so
`android_build_tools` points `GRADLE_USER_HOME` and `ANDROID_USER_HOME`
under the test's home; and the Flutter Gradle plugin
(packages/flutter_tools/gradle) is an included build of every app's,
compiled in its own directory (build/, .gradle/, .kotlin/) -- in the
test's runfiles, which the sandbox lets it write, so long as the tool's
`sources` leaves out what a build in the checkout left there (those would
come in as read-only symlinks and break the locks). Measured (10-27):
**25 of 25 files pass**, 46 min of wall time at `--local_test_jobs=3` with
the artifacts built (per-test sum 8,613 s; `gradle_jni_packaging_test` the
longest at 862 s, `flutter_build_config_only_test` 13 s; the shard as one
`bazel test` 81 min, the host configurations' engines rebuilt on the way);
the engine's six Android configurations take 4 h 30 min from nothing on 24
cores (91,281 actions), hours again when the toolchain's files change, and
nothing when cached.

```sh
bazel test //:framework_tests //:tool_tests //:dart_tests   # everything below, the root's suites
bazel test //packages/flutter/test:all              # 919 files, 20,163 cases: flutter test's
bazel test //packages/flutter/test:all_impeller     # the same under --enable-impeller (//:framework_tests_impeller)
bazel test //packages/flutter/test/widgets:text_test
bazel build //packages/flutter/test/widgets:text_test_kernel   # compile only
bazel test //packages/flutter/examples/api/test:tests //packages/flutter_test/test:tests
bazel test //packages/flutter/test_release:tests    # -Ddart.vm.product=true
bazel test //packages/flutter_tools:general_shard   # dart_test: the tool's unit tests
bazel test //packages/flutter_tools:commands_shard_hermetic //packages/flutter_tools:commands_shard_permeable
bazel test //packages/flutter_tools:integration_shard //packages/flutter_tools:web_shard   # the tool as a process
bazel test //packages/flutter_tools:desktop_shard   # flutter build linux, flutter run -d linux: CMake, GTK and an X display from the build
bazel test //:android_tool_tests                    # flutter build apk: the engine's Android artifacts, the SDK and the JDK from the build; Gradle from the network
bazel test //:apple_tool_tests                      # a Mac host: flutter build macos|ios through Xcode, CocoaPods and Swift Package Manager against the facsimile's universal frameworks -- the cases that sign nothing
bazel test //:apple_signed_tool_tests               # the files that sign for an iOS device, on a Mac with a development certificate (manual)
bazel test //dev/bots:tests //dev/tools/gen_keycodes:tests
```

Every tree counts what `flutter test` or `dart test` counts on the same
engine (the migration notes record each): packages/flutter's 919 files, the
API samples' 580, flutter_test's, flutter_localizations', flutter_goldens',
flutter_driver's, integration_test's, the example apps', manual_tests',
tracing_tests', stocks', vitool's, integration_ui's, the gallery's (16 files,
153 + 2 skipped, its smoke test over every demo among them) and
multiple_windows' (a package outside the pub workspace: its dependencies
named as `roots`, since the lock's tables do not know them) -- 1,644 files
and 22,676 cases, every `flutter test` tree of the framework_tests shard a
Linux host runs -- plus the Impeller, no-tracking and release/profile runs,
flutter_tools' general shard (277 files) and commands shard (the hermetic
half, 68; the permeable half, 11) and its integration shard where a Linux host
can run it (73 of 117 files), its desktop shard (13 more) and its Android
shard (25, with the network; one file is macOS's), its web shard
(18 files, on the pinned Chrome) and, on a Mac host, its apple shard (the
13 files that build for macOS or iOS through Xcode: 6 whole and 2 in part
without a signing identity, 7 whole with one -- "The recipe's universal
Apple archives"),
and the pure-Dart trees (dev/bots, devicelab, packages_autoroller,
flutter_analyzer_plugin, snippets, gen_defaults, gen_keycodes,
fuchsia_remote_debug_protocol). Left out by name: web-only files and, on a
Linux host, the one macOS-only file (`@TestOn`, which a BUILD file cannot
read; dev/bots' codesign_test runs on a Mac host), tests of the repository
itself (git on the checkout), and what needs the engine in its other
runtime modes or a device. The compile's defines for
the SDK version are fixed words (`-DFLUTTER_VERSION=bazel`...), so a kernel
is the same on every commit and the cache holds across them.

### The same tests on the prebuilt engine: `--config=prebuilt_engine`

Everything above runs the tests on the engine the tree builds -- an engine
checkout (gclient), its toolchains, and the first build of flutter_tester,
impellerc and the platform kernels. A framework developer's checkout and a
flutter_drone bot (the framework's and the tool's CI shards, which the
flutter/flutter_drone recipe runs from a bare checkout with
`FLUTTER_PREBUILT_ENGINE_VERSION` naming the engine) have neither; what
they have is the prebuilt engine the flutter tool downloads into
`bin/cache` -- the same flutter_tester, Dart SDK, impellerc and platform
kernels `flutter test` runs them with. `--config=prebuilt_engine` (the root
`.bazelrc`) points the rules there:

```sh
bin/flutter precache                       # the default artifact sets: the framework's tests
bin/flutter precache --linux --web         # and the host desktop's profile/release engines and the web SDK: the tool's shards
bazelisk test --config=prebuilt_engine //packages/flutter/test/widgets:widgets //dev/bots:tests
bazelisk test --config=prebuilt_engine //packages/flutter_tools:general_shard
```

The config is two flags. `--//build_defs/engine:source=prebuilt` switches
the alias package `//build_defs/engine` -- `flutter_tester`, `icudtl`,
`strong_platform`, `impellerc`, `shader_lib`, `flutter_gpu`: the one set of
labels every test rule's defaults name (`flutter_test.bzl`, `kernel.bzl`,
`flutter_assets.bzl`) -- from the tree's targets to `@flutter_bin_cache`'s
files, and the tool's test facsimile from the tree's engine directories and
sky_engine to the cache's `artifacts/engine/<host>{,-profile,-release}`,
`artifacts/engine/common`, `flutter_web_sdk` and `pkg/sky_engine`
(`packages/flutter_tools/BUILD.bazel`: `select()` over
`//build_defs/engine:prebuilt` for `cache`, `cache_files` and the Apple and
Android shards' cache). `--repo_env=FLUTTER_BAZEL_PREBUILT_ENGINE=1` makes
the host's Dart SDK repository (`HOST_DART_SDK`, the name every Dart rule
uses) `@dart_sdk_bin_cache`, `bin/cache/dart-sdk` under the prebuilt SDK's
overlay BUILD file, instead of the engine checkout's `prebuilts/<host>/dart-sdk`
(`host_platform.bzl`, `extensions.bzl`: a repository of its own rather than
the one name re-pointed, so that a tree build in the same output base keeps
its actions). `@flutter_bin_cache`
(`build_defs/repositories/flutter_bin_cache.bzl`, a local repository rule
like the gclient-synced trees' `synced_repository`) symlinks `bin/cache`'s
entries in place -- `pkg/sky_engine` and `pkg/flutter_gpu` one level down,
with a `package` filegroup each, since a package's files are laid relative
to it -- behind a check of the stamps the tool writes beside each artifact
set: `flutter_sdk.stamp`, `engine-dart-sdk.stamp` and `font-subset.stamp`
must be there and equal `engine.stamp`, `linux-sdk.stamp`, `macos-sdk.stamp`
and `flutter_web_sdk.stamp` must equal it when there (their filegroups are
empty otherwise), or the fetch fails and says which `flutter precache` flag
to run -- a stale cache is never an engine of another version by mistake.
The rules take the prebuilt plain files where the tree gives built targets
(`allow_single_file` on the executable attributes, the source-file
executables added to runfiles by hand, cache paths relativized by package
for an external repository), and the shader include root is found from
`flutter/runtime_effect.glsl` wherever shader_lib lives.

Limits. The tool's iOS and Android engine directories (`_APPLE_CACHE_FILES`,
the android shard's `cache_files`) still come from the tree under either
configuration: the apple and android shards want an engine checkout
(`flutter precache --ios --android` would serve them the same way; not done).
Measured (11-02, Linux,
engine `c5ec59d0…` from `flutter precache --linux --web`): the three root
suites analyze under the config (2,557 targets; the tree's 2,799);
`//packages/flutter/test/animation:animation //dev/bots:tests` 24 of 24
pass; the tool's general and commands shards and the widgets tree:
**745 of 745 pass** (277 general, 68 hermetic, 10 permeable, 390 widgets;
37 min at `--local_test_jobs=4`, create_test's 18 min the critical path);
the tool's integration and desktop shards (11-03): **74 of 74 pass** in
36 min. On a Mac
(Apple Silicon, 11-03, after `flutter precache --macos --web`: the
`darwin-x64` universal engine directory, the arm64 Dart SDK): animation,
dev/bots and the general shard **303 of 303** in 5 min 51, the widgets tree
**390 of 390** in 3 min 05, and `test.dart --bazel` of the general shard
end to end -- the repository rules fetched without a complaint.

### `dev/bots/test.dart`: the shards under Bazel

`dart dev/bots/test.dart` is what the framework's and the tool's CI shards
run (the flutter_drone recipe sets `SHARD` and `SUBSHARD` and runs it, and
sets nothing else). On a Linux or macOS host the framework_tests shard
(widgets, libraries, impeller, slow, misc), the tool_tests shard's general
subshard, tool_tests_commands, web_tool_tests and tool_integration_tests
run their tests under Bazel on the prebuilt engine (`dev/bots/bazel.dart`;
`useBazel` in `utils.dart`) -- by default, which is how PR #195825's
presubmit runs the existing shards under Bazel with no `.ci.yaml` change
(the user's call, 11-03). `--no-bazel` runs a shard through `flutter test`
and `dart test` as before; Windows does so always (no bazelisk release is
pinned for it), and so does a shard run with `REDUCED_TEST_SET` (the
recipe's tag filter, which Bazel's targets cannot honor). `--bazel`, or a
`SHARD` or `SUBSHARD` value ending in `_bazel` (`SUBSHARD=widgets_bazel`;
`shardNameFromEnvironment` strips the suffix), asks for Bazel whatever the
default:

```sh
SHARD=framework_tests SUBSHARD=widgets bin/cache/dart-sdk/bin/dart dev/bots/test.dart             # under Bazel on Linux and macOS
SHARD=framework_tests SUBSHARD=widgets bin/cache/dart-sdk/bin/dart dev/bots/test.dart --no-bazel  # flutter test, as before
SHARD=tool_tests_commands SUBSHARD=1_3 bin/cache/dart-sdk/bin/dart dev/bots/test.dart             # the slice's files, as targets
bin/cache/dart-sdk/bin/dart dev/bots/test.dart --dry-run                                           # every shard: the targets each would run
```

One `bazelisk test --config=prebuilt_engine --keep_going --test_output=errors
--skip_incompatible_explicit_targets` runs a shard's targets from the
repository root (`--config=ci` too on a bot; the other shards -- web,
analyze, docs, Android, customer testing -- have no Bazel path and run as
they always did). A shard's
steps map to the suites the root `BUILD.bazel` gathers: the `flutter test`
or `dart test` of a package to its `tests` suite, each packages/flutter test
directory to its own, the tool's shards to theirs. Because a BUILD file
leaves some files out by name, test.dart does not assume a suite is a
directory: `BazelShard.cover` lists the step's test files as the step would
(the same directory walks, the same numbered-subshard slices), computes
each file's target name from its path (`bazelTestTarget`: `//<package>:` and
the path relative to the package, `.dart` dropped, slashes to underscores,
as `dart_tests` and `flutter_tests` name them), asks one `bazelisk query
tests(set(<suites>))` which exist, runs those under Bazel and the rest
through `flutter test`/`dart test` as without `--bazel`, saying which (a
remainder of nothing but files the host skips whole -- test/widgets' two
browser tests -- is no failure: package:test's exit 79, no tests ran, is
accepted for a remainder) --
so a shard covers the same files either way, and a new test directory
without a BUILD file is loud, not lost. The steps that are not a package's
tests run as they are: the test harness checks (test.dart testing itself),
`flutter config` and examples_smoke_test, the `dart fix` goldens, the
private tests, integration_test's Gradle unit test and the tracing app
builds (the slow subshard is mostly these), android_semantics_testing and
examples/image_list (no BUILD file), packages/flutter/test/dart (a
browser's test), the bindings_test_failure check, the tool's native-asset
example apps, and the integration shard's Android and Apple files (their
Bazel shards want the engine's Android artifacts or a Mac). What differs
from `flutter test` by design: the gallery and the libraries run once, with
creation locations (the Bazel tree builds the no-tracking variant for
test/widgets only); `REDUCED_TEST_SET` is ignored
(Bazel runs every test of a target; a note says so); `--local-engine` is
refused (the config is the prebuilt engine). The per-case results reach
LUCI's ResultDB as `flutter test`'s and `dart test`'s do: every `dart_test`
and `flutter_test` target writes package:test's JSON reporter -- the
`--file-reporter=json:` stream -- to its undeclared outputs
(`bazel-testlogs/<package>/<name>/test.outputs/test_results.json`; the
dart_test launcher passes the flag, the flutter_test bootstrap adds a
`JsonReporter` beside the direct one and names the suite by the test's
repository path), and after the run test.dart reads the files of the
targets it ran -- cached or not, passed or not -- and posts them through
the same `ResultDbRecorder` (`BazelShard`'s `_reportToResultDb`;
`bazelTestResults`), a no-op off LUCI.
Before the tool's commands, integration and web shards, test.dart runs
`flutter precache --<host desktop> --web` (the sets the facsimile lays and
the sandboxed tool cannot fetch).

Bazel's state goes where `bazel_ci.py` keeps it for this checkout, so that
the two share a server and its caches: `.bazel_ci/` in the checkout for a
developer (git ignores it), the task's temporary directory on a bot
(`--max_idle_secs=300` there, and `--sandbox_base=/dev/shm` when the bot has
16 GB of it, as bazel_ci does), `BAZEL_CI_HOME` overriding both; the root
`.bazelrc`'s disk cache under `~/.cache` applies as for any build. bazelisk
is what `BAZELISK` names, else the one on `PATH`, else the engine checkout's
`third_party/bazelisk` (DEPS' `download_bazelisk`), else a download of the
release DEPS pins (1.30.0, the asset for the host's ABI, checked against its
SHA-256) into that directory -- a flutter_drone bot has none of the first
three. `dev/bots/test/bazel_test.dart` tests the name and path functions,
`test_test.dart` the `_bazel` names and `--bazel` through `--dry-run`.

With the default on, the existing `.ci.yaml` targets are the CI targets
(a separate target per shard would have had to start as `bringup: true`,
which cocoon runs in postsubmit only). A flutter_drone bot is a bare
checkout -- git, no `gclient sync` -- so the tools of DEPS the test rules
still need there come down as the packages DEPS names: `synced_repository`
downloads its CIPD package or tarball when the checkout has not got the
directory (`fallback_url`; cpython3 for the pub repositories and the
package configurations, clang and the sysroots for the desktop shard),
which a bare worktree of this checkout verified end to end, and which the
first presubmit runs confirmed, after three findings of theirs (489: the
engine's artifacts.zip carries shader_lib's BUILD files, which must not
make packages inside the cache repository; 491: the tool shards see
JAVA_HOME and ANDROID_HOME, the desktop shard gets the pinned Chrome). On
the bots (PR #195825, 11-03), start to finish of the whole build: Linux
framework_tests_widgets 15 min (802 tests; about 11 under `flutter test`),
libraries 12, misc 18, slow 8, tool_tests_general 6, tool_tests_commands
13, web_tool_tests 14, the integration slices 14-18; Mac widgets 13,
impeller 17, misc 19, tool_tests_general 12 -- with every case in
ResultDB ("Reported 12,764 test result(s) of 532 test target(s)" for
libraries). A stand-in on a workstation (a fresh output root, 8 CPUs, no
disk cache) had given 16 min 15 for widgets, the Mac tester's Apple
Silicon 9 min 46. Those times are the 8-core bot compiling every kernel
itself; on a Linux bot the shard now builds with `--config=rbe`
(`bazelRbeOptions`, the config bazel_ci.py gives the engine builders: the
kernel compiles on Flutter's RBE workers, 200 at a time, cached there for
the next build of the same inputs; a Mac builds locally, the workers being
Linux x64). On the
same 8-core bots (PR #195825 at 497, 11-03), the `run test.dart` step:
libraries 8:44 → 5:39, misc 16:41 → 10:25, widgets 11:34 → 8:33,
tool_tests_general 5:25 → 3:34, tool_tests_commands 12:20 → 9:57,
web_tool_tests 9:59 → 9:21; the tool_integration slices (12–16 min) and
slow unchanged, their time being the tests themselves. Those runs still
ran every test on the bot, each one's kernel downloaded first (50 MB,
40 GB a shard). Since 505 the headless tests run on the workers as well --
the framework's under `flutter_tester` and the pure-Dart packages' -- and
the bot downloads their logs and results alone (`--remote_download_toplevel`,
the default, leaves a test's runfiles where they are); `build:rbe` also
lays no runfiles symlink forest for them (`--nobuild_runfile_links`; one
is laid when a local test needs it). A test stays on the bot by tag:
`flutter_tests`' `network = True` suites, and `dart_tests`' `network`,
`browser`, `browser_driver`, `browser_files`, `display`, `tools`,
`unsandboxed` and `host` (a per-file list: dev/tools' engine-version tests
run `git`, which a worker's image lacks; devicelab's runner_test starts
thirty VMs against a minute), which is every shard of the tool's and four
pure-Dart files. Measured from a workstation (fresh output base,
`//:framework_tests //:dart_tests`, 2,111 tests): 774 s elapsed, of which
the gallery smoke test's 484 s on a worker is the critical path and every
other test was done by +6:35; per test a median of 4 s on the workers; no
`.dill` in the output base afterwards. Again without the smoke test, the
forests off and the four `host` files local: 2,110 tests in 479 s
(critical path 215 s), 15,469 processes against 17,581, every test
passing. On the 8-core bots (505's presubmit), the step once more:
libraries 5:39 → 2:22, misc 10:25 → 7:24, widgets 8:33 → 8:15 (its floor
is the gallery smoke test, eight minutes on a worker or a bot alike),
slow 4:40; the tool shards as before, their tests on the bot by design.
The workers are
2-vCPU Debian 11 machines whose clock is UTC, which is why archives are
zipped on the bot (build_defs/dist/zip_bundle.bzl). `test.dart --no-bazel-rbe` keeps a shard's
build on the machine and `--bazel-rbe` asks for RBE off a bot (a Linux
host with `gcloud` credentials for the instance), `FLUTTER_BAZEL_RBE=0`
in the environment is the former for a run, and `kBazelRbeOnBots`
(bazel.dart) is the default -- the engine builds' bazel_ci.py has the same
three (ci.md), so that the two can be compared on the bots.

## The web engine's unit tests: felt's suites

`lib/web_ui/test` -- 189 files in six test sets (`engine`, `ui`, `canvaskit`,
`webparagraph`, `skwasm`, `fallbacks`) -- is run by felt
(`lib/web_ui/dev`): a compile step (dart2js or dart2wasm per bundle, one
compile per file, into `out/web_tests/test_bundles/<bundle>/` with a
`results.json`), a copy step that lays the artifacts the tests load
(`out/web_tests/artifacts/`: CanvasKit's variants and skwasm from the web
build, flutter.js, test fonts, Skia's test images, the harness's host page)
and a run step: package:test's runner in process, its browser platform
replaced by felt's own (a shelf server serving the bundle, the artifacts and
a generated page per test; Chrome driven over the DevTools protocol for
uncaught exceptions and screenshots), one suite at a time,
`--concurrency=1`. `lib/web_ui/test/felt_config.yaml` names the sets, the
bundles (set × compiler × renderer), the run configurations (browser,
CanvasKit variant, cross-origin isolation, flags) and the suites; CI's web
test builders compile the bundles from the prebuilt SDK and run the Chrome,
Firefox and Safari suites.

Under Bazel (`build_defs/web/web_ui_tests.bzl`; `lib/web_ui/BUILD.bazel`),
the same three steps are the build's. The tests import `package:ui`, never
`dart:ui`, so the compile needs no engine build: `web_ui_test_bundle` runs
felt's exact command from `@dart_sdk_linux_x64` over a package
configuration of package:ui, its path packages and the hosted packages of
**lib/web_ui's own `pubspec.lock`** (its versions differ from the
workspace's; `pub.lock.bzl`'s `PUB_LOCKS`, `pub_package_config(lock =
...)`), one action per file into a directory shaped as the bundle with a
one-file `results.json` -- `bundles/<bundle>/<file>`. Every file of
`test/` is an input of every compile (test files import other test files),
but the compilers say what they read (dart2js's `.deps`, dart2wasm's
`--depfile`) and the action hands Bazel the rest as its unused-inputs
list, so a test edit recompiles what imports it and no more. The run is
felt itself: `dart_vm_kernel` compiles `dev/felt.dart` and puts the kernel at
`dev/felt.dill`, where felt's path derivation (engine/src is five
directories above its script) makes the runfiles' `engine/src/out/web_tests`
its build directory; `web_ui_test` lays the bundle and the artifacts there
(CanvasKit, skwasm and flutter.js straight from
`flutter_web_sdk_archive_release`'s entries -- the web SDK's layout is
felt's -- the five fonts with a `FontManifest.json`, `@google_fonts_for_unit_tests`
as the fallback fonts, `@skia//:resources_images_tree` less the invalid
files, the host page with `web_ui_host_page`'s dart2js of `host.dart`), puts
felt's package configuration at the package's `.dart_tool` for its server,
and runs `felt test --run --suite=<suite>` on the pinned `@chrome`
(`CHROME_NO_SANDBOX=true` inside Bazel's sandbox) with cwd `lib/web_ui`.
One test target per file and suite, `<suite>/<file>`, a `test_suite` per
felt suite, `:chrome_tests` over the sixteen Chrome suites -- the CanvasKit
`chromium` and `full` variants, skwasm's cross-origin-isolated and
single-threaded runs, wimp, WebParagraph, dart2wasm's engine suite, the
three fallbacks suites (whose bundle compiles a file twice, dart2wasm-skwasm
and dart2js-canvaskit side by side) -- `:firefox_tests` over the eight
Firefox suites (`@firefox`, the release the lock pins, through
`FIREFOX_EXECUTABLE`; felt starts an X display itself, the host's Xvfb,
inside the sandbox) and `:tests` over both; the files run in parallel
(felt's browsers take a free debugger port now, not a constant). The tests
run with no network (`block-network`): felt's Skia Gold client finds Gold
unreachable and the goldens compare nothing, as for a developer offline --
with the network the verdict depended on the host's fonts against CI's
baselines (`web_paragraph.locales.png` is 10 px wider here, under felt on
the checkout just the same) and on Gold; CI's Gold comparison and upload
stay felt's job. A file that declares no test on a suite's browser is left
out of that suite (`exclude`: semantics_test on Firefox), since a run of
the file alone would report that no test ran.

The BUILD file does not repeat felt's configuration. `tools/gn_to_bazel`
reads `test/felt_config.yaml` -- the web team's source of truth, as felt's
own `dev/felt_config.dart` reads it -- and writes `lib/web_ui/felt_config.bzl`
beside the BUILD file: `FELT_CONFIG`, one dict of the five tables (compile
configurations, test sets with their directories, bundles with their set
and compile configurations, run configurations with their browser, suites
with their bundle, run configuration and artifact dependencies), the names
and the references among them; a run configuration's flags and variant
stay felt's, read from the YAML by suite name at run time. `--check`
compares the two files as it compares the generated BUILD files. One macro
call, `web_ui_tests(name = "tests", config = FELT_CONFIG, browsers =
{...})`, declares everything above: the suites whose run configuration
names one of the browsers given (Chrome's and Firefox's: Chrome for
Testing's build for the host, Mozilla's Linux tarball or, on a Mac, its disk
image mounted with hdiutil as felt installs it -- CI runs the Firefox suites
on Linux, and on a Mac they are `manual`, run by name, until a Mac's run of
them is on record: a corporate Mac whose endpoint policy admits no browser
but Chrome cannot run them, and the build does not re-sign the bundle to get
around that; Safari's and Edge's need other hosts), the bundles those
suites run, one test per file
and suite -- the test sets' files are globbed from their directories, so a
new test file is a new target with no edit -- and the suites per browser
and whole. What the BUILD file still says is this host's: the browsers
(`@chrome`, `@firefox`, their variables and sandbox environment), the
files a suite leaves out, the files that need the network. A new suite,
bundle or set is an edit to felt_config.yaml and a run of the converter.

The browsers' system libraries come from the build, not the host. Chrome
and Firefox ship their own libraries but load the platform's from the
system -- GTK, NSS, X11, ALSA, D-Bus, fontconfig, some eighty shared
objects (`LD_DEBUG=libs`) -- and a test took them from whatever the host
had. The build sysroot the engine compiles against (`@sysroot_linux_x64`,
Chromium's Debian bullseye tarball) names every one of them but cannot
supply them: Chromium strips its sysroot's shared objects to stubs for
linking (`libgtk-3.so.0` is 403 KB there, 8 MB whole), and a loader given
one asserts or faults. So the build fetches the same packages whole: the
build sysroot carries dpkg's metadata for its 640 packages
(`debian/<package>/DEBIAN/{control,md5sums}`), from which
`build_defs/repositories/debian_runtime_lock.py` maps the browsers' `NEEDED`
sonames to packages, adds Mesa (Firefox's WebGL on Xvfb is Mesa's
llvmpipe, which Firefox loads by `dlopen` rather than `NEEDED`; Chrome
brings its own ANGLE and SwiftShader) and Debian's fonts (DejaVu, and
Liberation, the metric-compatible stand-ins for Arial, Times and Courier,
with fontconfig's own rules, `fontconfig-config`), closes
over `Depends` (140 packages at the build sysroot's versions -- Mesa's
LLVM 11 the largest; architecture-independent data packages other than
those three, and the C library and compiler runtime, left out), finds each
file in snapshot.debian.org's immutable archive and pins its sha256 into
`debian_runtime.lock.bzl`; the `debian_runtime` extension
(`debian_runtime.bzl`) downloads them and unpacks each `data.tar` with
the engine's own llvm-ar into `@sysroot_linux_x64_runtime` (253 MB
unpacked; about a minute to fetch), then makes the two `conf.d` links
fontconfig-config's postinst would have made for the debconf defaults
(`10-hinting-slight.conf`, `70-no-bitmaps.conf`: unpacking runs no
postinst). `browser_launcher`
(`build_defs/web/browser_launcher.bzl`) writes a script in the browser's
name that puts that tree's `lib/x86_64-linux-gnu` and
`usr/lib/x86_64-linux-gnu` first on `LD_LIBRARY_PATH`, points Mesa at its
drivers (`LIBGL_DRIVERS_PATH`), GLVND at its EGL vendor
(`__EGL_VENDOR_LIBRARY_DIRS`) and GLib at its GIO modules
(`GIO_MODULE_DIR`) -- all found by absolute path otherwise, the host's
modules into the sysroot's GLib -- writes a `fonts.conf` confining
fontconfig to the sysroot's
`usr/share/fonts`, including its `etc/fonts/conf.d`, with a cache
directory of the test's own
(`FONTCONFIG_FILE`: a rendering depends on no font of the host, and
fontconfig scans twenty files rather than the host's hundreds), and execs the
browser: the browser process alone, so that felt's Dart VM and the Xvfb
it starts keep the host's libraries. `web_ui_test` and
`dart_test` take the launcher as their `browser` (flutter_tools' web shard
also wraps chromedriver). Under it Chrome loads 80 libraries from the
sysroot and 8 from the host: `ld-linux`, `libc`, `libm`, `libdl`,
`libpthread`, `librt`, `libresolv` and `libgcc_s`, by design -- the host's
dynamic loader must match its own libc, and a library built against glibc
2.31 runs on any newer one. What stays the host's: those eight, xkbcomp
(below), and the configuration the sysroot's other libraries read
by absolute path (GTK's settings). Firefox's
policies file, which felt writes beside the executable it resolves, is
written beside the launcher's script by the rule. The label flag
`--//build_defs/web:browser_libraries` names a `browser_libraries` target:
`//build_defs/web:sysroot_libraries` by default,
`//build_defs/web:host_libraries` for the host's (the script then sets
nothing). Without Mesa, Firefox's WebGL suites fail as "Skwasm requires
WebGL support": the host's Mesa cannot load beside the sysroot's older
`libdrm` and `libexpat`, which is the general hazard of mixing the two --
the closure must be complete. Measured on this host, the 923 tests with
`--local_test_jobs=6`: with the sysroot's libraries but the host's fonts
(the first form of this), 923 pass in 2,071 s of wall time, the per-test
sums Chrome 4,028 s (545 tests, median 5.7 s) and Firefox 4,764 s (375,
median 12.0 s); with the host's libraries (the flag) 923 pass in 2,295 s
(a few minutes of it re-checking the action cache under the changed
flag), Chrome 3,955 s (median 5.8 s), Firefox 3,560 s (median 8.0 s) --
Firefox paid about 4 s per test under the sysroot, the sysroot's
fontconfig 2.13 rebuilding a cache over the host's hundreds of fonts in
every test's HOME (it cannot read the host's caches, a newer format),
which is why the fonts joined the sysroot. Which fonts matters: the
WebParagraph suite measures `Arial` (this host has it, Microsoft's core
fonts). With DejaVu alone, four of its files fail, a line of Arial at
20 px measuring 24 rather than 22 (DejaVu Sans is taller); with
Liberation Sans answering for Arial but no hinting style set, three
cases of `paragraph_get_position_test` are a pixel off (fontconfig's
default is hintfull, under which the TrueType hints of Liberation Sans
1.07 move its advances); with the postinst's `hintslight`, 923 pass in
1,989 s of wall time, the fastest of the three forms: Chrome 3,802 s (546
tests, median 5.1 s), Firefox 3,994 s (377, median 9.3 s -- the cache it
rebuilds per test now covers 22 files; 1.3 s above the host's libraries
and caches).

The X display comes from the build as well. felt starts `Xvfb` by name
for Firefox when there is no `DISPLAY` (headless Firefox initializes
WebGL only on a display), and took the host's. Xvfb is a program the
build sysroot has no trace of, so `debian_runtime_lock.py` reads, for
what the sysroot lacks, bullseye's own `Packages` index as
snapshot.debian.org had it at `--index`'s timestamp (`20240901T000000Z`,
the month of the sysroot's newest package): a package's version,
dependencies, file and sha256 come from the index, and a package the
sysroot has keeps the sysroot's version. `--package xvfb` closes to eight
more packages (xvfb, libxfont2, libfontenc1, libunwind8, libaudit1,
libcap-ng0, libbz2-1.0 and, as data, xkb-data: 148 in all, 262 MB
unpacked). `display_launcher` writes a script named `Xvfb` that runs the
sysroot's on the sysroot's libraries with the server's built-in fonts and
the sysroot's keyboard data (`-fp built-ins -xkbdir`), and `web_ui_test`
puts it first on the test's PATH (`tools`; the `_BROWSERS` entry for
Firefox names it). One thing of X stays the host's: `xkbcomp`, the keymap
compiler Xvfb runs at the path built into it, `/usr/bin/xkbcomp`
(x11-xkb-utils; without it the server falls back to its pre-XKB keymap,
with a warning). Under `--//build_defs/web:browser_libraries=//build_defs/web:host_libraries`
the script hands over to the host's Xvfb, the next on PATH. Measured: the
923 tests pass in 1,488 s of wall time, Firefox's 377 at a median of 7.9 s
(9.3 s on the host's Xvfb, which scans the host's font directories at
start; the host-libraries form's 8.0), Chrome's 546 at 5.0 s (unchanged
path; 5.1 before). The sysroot's Xvfb loads 29 libraries from the sysroot
and glibc's 6 from the host.

```sh
bazel test //engine/src/flutter/lib/web_ui:tests                              # Chrome's sixteen suites and Firefox's eight: 923 tests
bazel test --//build_defs/web:browser_libraries=//build_defs/web:host_libraries //engine/src/flutter/lib/web_ui:tests   # the host's libraries
bazel test //engine/src/flutter/lib/web_ui:chrome_tests                       # 546 tests
bazel test //engine/src/flutter/lib/web_ui:chrome-dart2js-canvaskit-engine   # 86 files; felt's suite of that name
bazel test //engine/src/flutter/lib/web_ui:chrome-dart2js-canvaskit-engine/alarm_clock_test
bazel build //engine/src/flutter/lib/web_ui:bundles/dart2js-canvaskit-engine   # the compiles alone
```

`chrome-dart2js-canvaskit-engine`: 86 of 86 files, 1,274 cases and 13
skipped, in 4m18s from cold (the compiles included) -- what `felt test
--suite=chrome-dart2js-canvaskit-engine` counts. Chrome's sixteen: 546
files, 10,448 cases and 121 skipped, 19 minutes from cold with the 336
compiles; Firefox's eight: 377 files, 6,504 cases and 247 skipped, 19
minutes of runs. Safari and Edge (other hosts) stay felt's.

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

### The Android embedding's Java tests (`--type java`)

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
generated file; D12, option b) the same tests are the build's, without
rules_java or rules_jvm_external -- the root module's graph stays as the
10-20 decision left it, and the JDK is the engine's `@openjdk` 25, the one
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
`@maven_android_tests` (1.9 GB, the android-all jars most of it; AARs
unpacked, `classes.jar` and `res/` apart; the android-all jars in one
directory of their own, never on a class path). `robolectric.bzl` then:
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
JVM over the embedding's classes peaks at 3.0 GB resident (the activity
and text-input classes; 0.9 GB on average; sampled every 2 s over the
suite) under the 8 GB heap cap Gradle's forks have too, so an 8-core,
30 GB bot runs six at once, as Gradle ran eight (the 12 GB first
declared here ran them one at a time there: 23 minutes for a suite
Gradle finishes in four). On this host (24 cores, 94 GB): **87 of 87
classes pass** -- 1,567 test cases by JUnit's count (Gradle's 1,565
passed and 3 skipped) -- in 1,119 s at twenty-one at once (the cores are
the limit: 1,509 s at two, about the same at five); the longest classes
alone are TextInputPluginTest (65 s on a bot, 124 tests over four SDKs),
FlutterViewTest (68 s) and FlutterActivityAndFragmentDelegateTest (66 s).
The compile of the 96 files takes 11 s, the resource APK and R classes 4 s.

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

### The recipe's universal Apple archives: `apple_universal`

CI's Mac builders build each CPU, platform and mode in a directory of its
own and join them outside GN (the `generators` tasks of
`ci/builders/mac_host_engine.json` and `mac_ios_engine.json`):
`sky/tools/create_macos_framework.py` lipos the arm64 and the x64 build's
`FlutterMacOS.framework` into one and makes `FlutterMacOS.xcframework` of it
(its dSYM alongside, stripped, in release); `create_macos_gen_snapshots.py`
gathers the two builds' universal `gen_snapshot_arm64` and
`gen_snapshot_x64`; `create_ios_framework.py` lipos the two simulator
builds' `Flutter.framework` -- the debug ones whatever the mode -- and makes
`Flutter.xcframework` of the device's and the simulator's, the
extension-safe pair the same, with the device build's `gen_snapshot_arm64`.
The recipe uploads them as `darwin-x64[-<mode>]/framework.zip` and
`gen_snapshot.zip` and `ios[-<mode>]/artifacts.zip`, which `flutter precache
--macos|--ios` unpacks.

Under Bazel each is one target (`build_defs/dist/universal.bzl`'s
`apple_universal`, declared in `//engine/src/flutter/build/archives`): a
split transition builds `deps` once per platform of `builds` -- the
platform's child for the current runtime mode (`macos_arm64` under
`--config=host_release` is `macos_arm64_release`), or the mode a name carries
(`ios_sim_x64_debug`) -- each build is laid out in a scratch directory as the
part of its build directory the script reads (`FlutterMacOS.framework/` with
the bundle's links, `universal/gen_snapshot_<cpu>`), the recipe's own script
runs over them with `{build:<key>}` and `{dst}` expanded, and the outputs
named are kept:

    bazel build --config=mac_release_arm64 //engine/src/flutter/build/archives:universal_macos_framework
    bazel build --config=mac_release_arm64 //engine/src/flutter/build/archives:universal_macos_gen_snapshots
    bazel build --config=mac_release_arm64 //engine/src/flutter/build/archives:universal_ios_framework

(a Mac host's configuration of the mode wanted: the targets live in the
host's configuration and the split sends their builds to the Mac's two CPUs
or to the device and simulators; under an iOS `--config` they are
incompatible). `:macos_framework`, `:macos_gen_snapshot` and `:ios_artifacts` are the
recipe's archives over them (`zip_archives/darwin-x64-release/framework.zip`,
...: the recipe's names, whatever the Mac), and the tests' SDK facsimile on a
Mac host lays their contents as the tool's cache does
(`host_engine_*_directory`, `ios_engine_*_directory`). A Mac of either CPU
builds both slices (the macOS toolchains cross-build); `lipo`, `strip` and
`xcrun xcodebuild -create-xcframework` are Xcode's, `dsymutil` the checkout's
(`flutter/buildtools/mac-<cpu>/clang`). Linux skips the targets as
incompatible.

The tool's tests over these directories are the apple shard
(`//:apple_tool_tests`; `packages/flutter_tools/BUILD.bazel`): the 13 files
of the integration shard that build for macOS or iOS through the tool
(`flutter build macos|ios`, Xcode, CocoaPods, Swift Package Manager), on a
Mac host alone. They run unsandboxed (xcodebuild runs `sandbox-exec` itself,
which the sandbox refuses), with the Xcode projects the tool migrates and
the engine directories copied writable first (`writable`: APFS clones), and
the host's Xcode, CocoaPods, simulators and network. Seven of the files
build for an iOS *device* in some or all of their cases (`flutter build
ios` without `--simulator`/`--no-codesign`, `flutter ipa`, an add-to-app
project signed automatically), which wants an Apple development certificate
and a provisioning profile in the keychain: those files are
`//:apple_signed_tool_tests` (manual; targets `<file>_signed`), and the apple
shard keeps the two files whose other cases sign nothing with `dart test
--name` (`cases`). The host's TMPDIR reaches these tests as Bazel passes it
(`/var/folders/...`, which the tool's tests expect); only the widget_preview
watchers of the hermetic shard get it resolved (`resolved_tmpdir`).

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
Android section); on the macOS platforms the aspect strips nothing and
writes no `exe.unstripped/`, as GN's mac toolchain links into the build
root as is (the frameworks' packaging strips and writes dSYMs: the Apple
products' phase). The objcopy is the host's clang's (`@host_platform`). The
Dart wrap's `gen_snapshot` is already GN's stripped file.

The root package had `//engine/src/flutter:install` for the developer's
builds, GN's default target: the Linux host's build directory as above with
all seven archives of the Linux host configurations -- and, under an
Android platform, what the root group `flutter` lays (the developer's
`android_*` configurations have no ninja targets of their own; `engine/src`'s
`//:default` depends on `//flutter` alone): libflutter.so with
`lib.stripped/`, the jars and poms, `clang_x64/gen_snapshot`, the
snapshots, the Impeller SDK, the embedder archive, the javadoc, ICU's data
file for the target (334 files for `android_debug_arm64`). It is gone: the
flutter tool reads a developer's build, Android's included, where Bazel
builds it, through `local_engine.json` (next section), and `local_engine`
took over its content tables, so what was measured against the install
stands for the manifest's contents. Against GN's own
`out/android_debug_arm64`, `install_diff.py` found nothing missing on
either side over 19 paths: 305 files identical, the binaries expected
different, and the poms, Maven metadata and javadoc pages differing by the
version hash and the date alone; against `host_debug_unopt`, 1,390 files
installed and 17 of 17 paths agreeing -- 1,387 files identical, the eight
binaries differing as builds under different flags do, nothing missing on
either side. The Maven tree and the `dist` archives are not the default's
under GN either; the builders name them as targets.

`tools/gn_to_bazel/tool/install_diff.py` compares an installed directory
(a builder's, below) or a `local_engine.json` directory with GN's path by
path (the consumer-visible paths above by default, a manifest directory's
resolved through its entries; a directory is every file under it, an
archive is compared entry by entry as `artifact_diff.py` does):

```sh
bazel build //engine/src/flutter:local_engine
python3 engine/src/flutter/tools/gn_to_bazel/tool/install_diff.py \
    --gn=engine/src/out/host_debug_unopt --bazel=engine/src/out/bazel-bin/engine/src/flutter \
    --expect-different=flutter_tester --expect-different='*.so' ...
```

Against `host_debug_unopt`, the manifest's 16 paths (the archives aside)
all agree: 1,380 files identical, the eight binaries expected different,
nothing missing. Two of its entries map directories where Bazel keeps other
outputs beside the files (`dart-sdk` the prebuilt SDK's repository with its
`BUILD.bazel`, `gen/flutter/lib/snapshot` the snapshot package's output
directory with its 564 intermediates), which the tool counts as "beside
them" and does not compare, since the consumer reads GN's paths. Two things the
comparison turned up. GN's build root holds the *full* ICU data file
(`copy("copy_icudata")`, `common/icudtl.dat`, 10.8 MB), where `artifacts.zip`
ships the trimmed `flutter/icudtl.dat` (865 KB): a `--local-engine` run
loads different ICU data than a release does; the manifest follows the build
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
`scriptMappings`) into `dart_pkg` (`build_defs/dart/dart_pkg.bzl`), which
runs the script into a directory artifact; `web_ui_ui_web_with_output` is
`build_defs/web/web_sdk.bzl`'s `sdk_rewriter` rule, which runs the script under
the prebuilt Dart SDK with the Dart tree's package configuration and
declares an output per source. The script's directory walk did not follow
symbolic links, which a sandbox's inputs are; it does now (a one-line
change, harmless to GN). Its 289 files come out byte-identical to GN's.

A build used as a local engine with the flutter tool is the next section's
manifest; the installed tree was what first ran there
(`--local-engine=host_debug_unopt_bazel` under `engine/src/out/`:
`packages/flutter/test/widgets` passed on it with GN's exact numbers, 7,349
tests, 128 skipped), and two things learned with it hold. An install into
a directory GN also builds (`out/ci/host_debug` for a builder's)
overwrites -- each installed path is removed first and copied afresh, since
GN's copies are hard links of their sources and a copy onto a hard link of
its own source is refused as "the same file"; GN's files come back by
deleting the installed paths -- the install script in bazel-bin lists them
-- and running `ninja` there (ninja takes the newer Bazel copies for up to
date otherwise). And on a fresh checkout: under a local engine the tool
downloads no engine artifacts, and pub resolves `sky_engine` from
`bin/cache/pkg/`, which only a run *without* `--local-engine` populates --
run one plain `flutter test` first, or the first local-engine run fails in
pub with "could not find package sky_engine".

Neither an install nor the manifest carries the web SDK (the wasm builds'),
or GN's own bookkeeping (`args.gn`,
depfiles). `compile_commands.json`, which `tools/clang_tidy` and clangd
read, comes from `tools/gn_to_bazel/tool/compile_commands.py` over
`bazel aquery` after a build (a tool, since no action can query the
graph); its entries run from the execution root, where Bazel's relative
include paths resolve, but name the source and the compiler as the
checkout spells them, so that `tools/clang_tidy`'s file selection and its
search for `clang-tidy` beside the compiler work on it as they do on GN's
(`ci/clang_tidy.sh --variant <build directory>`). The builder-specific
targets below install the archives alone.

## A local engine without the copy: `local_engine.json`

The builders' installs lay GN's layout because the recipes read fixed paths
of a build directory; the flutter tool no longer needs one.
`//engine/src/flutter:local_engine` (`local_engine.bzl`)
builds what the flutter tool reads from a build directory -- the content
tables in the root BUILD file: for the host's own build the files above,
for an Android build the root group `flutter` and ICU's data file for the
target -- and, instead of copying them, writes `local_engine.json` beside
them in `bazel-bin`: the build's name (`host_debug_unopt` for `-c dbg`,
`android_debug_arm64` under that configuration, as GN names the directory) and a map from each GN path the tool reads to where Bazel built
the file, relative to the manifest's directory -- `flutter_tester` to
`shell/testing/shipped/flutter_tester`, `icudtl.dat` through `../` into the
ICU repository, `dart-sdk` to the prebuilt SDK's repository (a `zip_tree`
whose files all sit under one directory maps as that directory), and a GN
directory whose every entry, at any depth, sits at its relative path under
one directory of the build maps as that directory too
(`flutter_patched_sdk`, which the tool hands the frontend server as
`--sdk-root`; one agreeing child is not enough -- an Android build's
`gen/dart-pkg/sky_engine` has `AUTHORS` from the source root beside `lib/`
from the Dart tree, and an entry for it would shadow dart_pkg's directory
at `gen/dart-pkg`). Two things the tool reads as
directories are assembled as one under `local_engine/`: the sky_engine
package (`gen/dart-pkg/sky_engine`, dart_pkg's directory and the copied
libraries) and impellerc's `shader_lib` (GN copies the GLSL files beside
the compiler; the tool passes the directory as `--include`). The same
assembly is a rule of its own, `assembled_directory(contents, prefix)`,
for a GN directory something else reads whole:
`//engine/src/flutter/sky/packages/sky_engine:package` is the sky_engine
package as pub finds it under the SDK cache's `pkg/` (the tests' SDK
facsimile, above).

flutter_tools reads the manifest (`LocalEngineLayout` in
`packages/flutter_tools/lib/src/artifacts.dart`): `--local-engine` and
`--local-engine-host` take the directory holding it -- the layout is GN's
when there is none, so nothing changes for a GN build directory -- and
resolve each artifact by the longest manifest entry that prefixes its GN
path; a directory's symbolic links are resolved first, so the `bazel-bin`
convenience link works. flutter_tester is told `--icu-data-file-path`
explicitly (GN's layout had hidden that it looks beside its binary) and the
shader library is a host artifact of its own (`HostArtifact.shaderLib`)
rather than a path derived from impellerc's.

```sh
bazel build //engine/src/flutter:local_engine
cd packages/flutter
../../bin/flutter test test/widgets \
    --local-engine=$PWD/../../engine/src/out/bazel-bin/engine/src/flutter \
    --local-engine-host=$PWD/../../engine/src/out/bazel-bin/engine/src/flutter
```

gives GN's exact result for the directory (7,349 tests, 128 skipped) with
nothing copied, and `flutter assemble ... release_bundle_linux-x64_assets`
builds an AOT snapshot with the Bazel `gen_snapshot` the same way. `et build
--backend bazel` with no targets, for a developer's configuration, builds
this target and prints the directory to pass.

The directory can also go by its name: `--local-engine=host_debug_unopt`
(or `--local-engine-host=...`) looks under `engine/src/out/<name>` first,
as always, and then among the Bazel configurations' directories under
`engine/src/out/bazel-out/*/bin/engine/src/flutter` for the one whose
`local_engine.json` carries that name -- GN's name for the configuration's
build directory, which `local_engine` writes -- so after `bazel build
--config=android_debug_arm64 //engine/src/flutter:local_engine` and the host
build's, `flutter build apk --local-engine=android_debug_arm64
--local-engine-host=host_debug_unopt` needs no paths. Two Bazel
configurations carrying one name (a stale directory left by another
`.bazelrc`) are reported as such, with both paths. On a Mac the same holds
for `host_debug_unopt_arm64` and the iOS builds (`ios_debug_sim_unopt_arm64`:
`flutter build ios --simulator --local-engine=ios_debug_sim_unopt_arm64
--local-engine-host=host_debug_unopt_arm64`), whose `Flutter.xcframework`
and `FlutterMacOS.xcframework` the tool finds through the manifest too.

Two paths of the tool read GN's layout by name until commit 320, and read a
manifest directory now. The Gradle plugin took `-Plocal-engine-out` as
`<engine>/src/out/<name>`, deriving the ABI and the mode from the name and
the Maven files (`flutter_embedding_<mode>.{pom,jar,maven-metadata.xml}`,
`<abi>_<mode>.{...}`, from which `gradle.dart` builds the local Maven
repository Gradle resolves the embedding from) from fixed paths, and
handed `flutter assemble` the name with `--local-engine-src-path`; now the
Maven files resolve through `LocalEngineLayout`, the ABI and mode come from
the manifest's name, and `FlutterPlugin.kt` passes a directory holding
`local_engine.json` as `--local-engine=<path>` with no source path (the
tool finds `engine/src` from `FLUTTER_ROOT`). The desktop CMake re-entry
(`tool_backend.dart`, run by the generated CMake and Visual Studio
projects) got `LOCAL_ENGINE` as a name under `FLUTTER_ENGINE/out`; a
manifest directory is passed as its absolute path with no `FLUTTER_ENGINE`
(`LocalEngineInfo.toReentrantBuildEnvironment`), and the mode check reads
the manifest's name. One Bazel setting goes with this: a cross build's
output directory was named for the host CPU, the same as the host's own
(`bazel-out/k8-opt/` for `android_debug_arm64` and `host_debug` both), so
building one overwrote the other's manifest and the outputs whose paths
they share -- an Android engine and the host engine it pairs with could
not both be on disk. The root `.bazelrc` sets
`--experimental_platform_in_output_dir`, which names the directory after
the target platform; and since Bazel names a top-level configuration's
directory from the platform and the compilation mode alone -- the engine's
runtime mode, a Starlark flag, enters the name only through a transition's
hash -- the platforms are per runtime mode (`build_defs/config/platforms.bzl`:
`runtime_mode_platforms` declares `android_arm64` and `android_arm64_debug`,
`_profile`, `_release`, `_jit_release`, each child carrying
`--//engine/src/flutter/common:runtime_mode=<mode>` as a platform flag, as
Bazel 8.8 allows; the host has `linux_x64` and its modes the same way). The
builders' configurations name the mode's platform, so every build has a
directory of its own, as GN has a build directory per mode:
`bazel-out/android_arm64_profile-opt/` beside `android_arm64_release-opt/`,
`linux_x64_debug-opt/` beside `linux_x64_release-opt/`,
`wasm32_emscripten_release-opt/`. A build that names no platform
(`bazel test //...`) keeps Bazel's host platform and `k8-fastbuild`; the
exec configurations keep `k8-opt-exec`. The configurations also set the
mode flag on the command line: a platform's flags apply where the platform
is the target's, and the tools a build runs (gen_snapshot in the Dart wrap,
impellerc) are built in the execution configuration, on the host's modeless
platform, so the mode reaches them from the command line, as GN builds its
host tools in the build's mode. `in_configuration` (configuration.bzl)
moves between the modes of one platform by name, and from Bazel's host
platform to the host's mode platform (`@host_platform`'s `HOST_PLATFORM`).

```sh
bazel build --config=android_debug_arm64 //engine/src/flutter:local_engine
bazel build --config=host_debug //engine/src/flutter:local_engine
cd examples/hello_world
../../bin/flutter build apk --debug --target-platform android-arm64 \
    --local-engine=$PWD/../../engine/src/out/bazel-out/android_arm64-opt/bin/engine/src/flutter \
    --local-engine-host=$PWD/../../engine/src/out/bazel-out/k8-opt/bin/engine/src/flutter
```

builds hello_world's `app-debug.apk` (69.9 MB, 191 s with pub and the
tool's own rebuild) whose `lib/arm64-v8a/libflutter.so` is byte-identical
to the Bazel build's `lib.stripped/libflutter.so`; Gradle's log shows
`-Plocal-engine-out=<the Bazel directory>`, the Maven repository built from
the manifest's entries
(`io/flutter/flutter_embedding_debug/1.0.0-<hash>/`, `arm64_v8a_debug/`),
and the re-entry `flutter --local-engine <path> --local-engine-host <path>
assemble debug_android_application`. `tool_backend.dart linux-x64 debug`
with `LOCAL_ENGINE=LOCAL_ENGINE_HOST=<the host directory>` compiles the
kernel with the Bazel Dart SDK's `dartaotruntime` and frontend server in
19 s (`flutter build linux` itself needs cmake, clang and the GTK headers,
which this host lacks). The Android manifest names 380 entries: the root
group's files -- the embedding's jars and poms, `libflutter.so` with its
`lib.stripped/` copy, `clang_x64/gen_snapshot`, the snapshots, the
archives, ICU's data file for the target. The Xcode side (macOS, iOS) is
the Apple phase's.

## The builders: `--config=<build>` and their install targets

CI's builds are `ci/builders/*.json`: for each, the `tools/gn` flags of its
GN configuration, the ninja targets it builds, the archives it uploads from
`engine/src/out/<target dir>/zip_archives/`, the tests it runs. The
converter reads the Linux and the Mac builder files (`tools/gn_to_bazel`'s
`builders.dart`, run with the rest) and generates two files beside them.
`ci/builders/configs.bazelrc`, which the root `.bazelrc` imports, has a
`build:<name>` configuration per Linux build -- the x64 host's own, the
web's, the arm64 cross builds' and Android's -- whose flags the Bazel build can all express -- `--runtime-mode` is the runtime mode setting,
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

The Mac's builder files (`mac_*.json`, and `local_engine.json`'s `macos/`
builds) are read the same way since the macOS port (research/20, M3), after
the Linux ones: forty-four builds, thirty-six configurations distinct. A
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
`build_directory_attrs`: `host`, `wasm` or `linux`, the runtime mode,
`_unopt`, `_arm64`) --
(a ninja
target nothing converted answers to would be listed in a comment; since 448
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
(the formatter, the linters, `generate_metrics.sh`) listed as what they
are, scripts of the checkout:
`bazel test --config=host_debug_test //engine/src/flutter/ci/builders:host_debug_test_tests`
runs what `Linux linux_host_engine_test`'s `host_debug_test` runs.
`generated_file` over `metadata` (the macOS entitlements lists) is the
Apple phase's.

The whole engine tree is a wildcard on either host, each skipping the other
platforms' targets as incompatible rather than failing on them (the
toolchains' and system libraries' OS compatibility above; the files GN
reaches under `is_android` or `build_glfw_shell` carry the same condition):
`bazel test //engine/src/flutter/...` runs 1,345 targets on a Linux x64
host (1,243 pass, 102 skipped -- Android's, Apple's) and 968 on an
Apple-silicon Mac (873 pass, 95 skipped -- Android's, iOS's, Linux's; the
377 Firefox web suites are `manual` there until a Mac's run of them is on
record), in an hour or two from a warm
cache; `//:framework_tests //:tool_tests //:dart_tests` adds the framework's,
the tool's and the repository's Dart tests on both (a Mac's `//:tool_tests`
includes the apple shard and leaves out the Linux desktop shard).

### CI on these configurations without a recipe change

A LUCI builder runs the same install and suites through the unchanged
`engine_v2` recipe: `tools/gn --bazel` writes a `build.ninja` that runs the
build's install target (the recipe's `ninja -C out/<dir> <targets>` runs the
Bazel build), `testing/run_tests.py` runs each `--type` as the build's Bazel
suites, and Bazel variants of the builder files (`linux_unopt_bazel.json`,
`linux_host_engine_bazel.json`; `.ci.yaml`'s `Linux linux_unopt_bazel` and
`Linux linux_host_engine_bazel`, bringup) name the builds. The converter
writes the table the scripts read (`build/bazel/builds.json`) with the two
files above and checks the variants against it. [ci.md](ci.md) has the
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
refuses, naming the flag, a build the Bazel build cannot express
(`ci/host_debug_no_prebuilt_dart_sdk`). GN labels and patterns are spelled
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
the recipes read. `et run` builds the host's local engine and, for another
platform, the target's, and hands both directories to `flutter run`. `et test` with no patterns runs the build's `<name>_tests` suite, and
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
of the macro in `build_defs/impeller/shaders.bzl`, whose body is the template's,
rewritten once: for each backend (GLES 2, GLES 3, Vulkan; Metal on the
Apple platforms) `impellerc_compile` runs
`//engine/src/flutter/impeller/compiler:impellerc`
once per shader, `shader_archive` packs the compiled shaders with
`shader_archiver`, `embed_blob` turns the archive into a C++ array with
`impeller/tools/xxd.py`, and `cc_library` wraps the blob and the reflection
headers. The targets keep GN's names (`impellerc_vk_entity_shaders`,
`embed_gles3_entity_shaders`, ...) so the two trees read alike; the oracle
knows them as the template's inner targets.

Which backends a build has is args.gni's `impeller_enable_metal`,
`impeller_enable_opengles` and `impeller_enable_vulkan`, each a tri-state
flag in `impeller/tools` (`--//engine/src/flutter/impeller/tools:enable_metal=auto|true|false`):
`auto`, the default, is GN's formula over the target platform -- Metal on
macOS and iOS, Vulkan on the desktops and Android, OpenGL ES on those and the
web -- and `true`/`false` a build's override, as GN's args allow; the wasm
platform's own flags spell the web's out. The generated files `select()` on
`:metal`, `:opengles` and `:vulkan`, which hold for `true` and for `auto`
where the formula does, so a plain `bazel build` on a Mac has Metal as GN's
does without any `--config`.

The Metal backend (`mtl_<name>`; research/20 M4) is shaders_mtl.gni's:
impellerc with `--metal-desktop`, `--metal-version` (1.2 unless the
invocation says) and `IMPELLER_TARGET_METAL(_DESKTOP)` writes the `.metal`
sources and the reflection; `metal_library` compiles them into one
`shaders/<name>.metallib` through `impeller/tools/metal_library.py`, which
runs Xcode's `xcrun -sdk macosx metal` (with `-g -frecord-sources` in the
debug and profile runtime modes, impeller_debug; a `.metallibsym` beside the
library otherwise) -- the one tool of the pipeline that is not the build's
own, the same Xcode `@macos_sdk` is a view of (DEVELOPER_DIR reaches it
through `--action_env`); `embed_blob` embeds the library as
`impeller_<name>_shaders_data` (`mtl/<name>_shaders.h`). Where Metal is on,
Metal's reflection headers are the public ones (shaders_vk.gni: "Metal
reflectors generate a superset of information") and Vulkan's move under
`vk/`, which is why `impellerc_compile` declares its outputs at analysis
time from a platform-selected `subdir` rather than predeclaring them: one
rule instance, either layout, no two rules claiming
`impeller/entity/solid_fill.vert.h`. Off the Apple platforms the Metal
targets are incompatible and a wildcard build skips them.

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
(`fml`'s 674 compiles) without the disk cache, and takes 7 s with it. On
CI a Linux bot does not cache but executes remotely, on Flutter's RBE
instance (`build:rbe` in the root `.bazelrc`: the reclient instance of the
GN builds, the builders' debian11 image, 200 jobs, Application Default
Credentials -- a bot's emulated GCE metadata server, a developer's `gcloud
auth application-default login`; bazel_ci.py adds the config to a Linux
bot's engine builds, ci.md says how and what stays on the bot). Execution
rather than a shared cache because of the instance's IAM: only a worker
writes the action cache, so a locally run action is never a hit for
anyone. Measured from a workstation: `fml_unittests`' 676 actions in 93 s
on the workers, then 38 s from a fresh output base with every action a
hit. The local disk cache is the same mechanism without the network. A Mac
sends its C/C++/Objective-C compiles to the same Linux workers under
`--config=rbe_mac` (`build/bazel:apple_remote_compiles`: the Apple
toolchains' compiler becomes `toolchains/apple_clang_wrapper.sh`, which
runs the Mac's clang on a Mac and `buildtools/linux-x64/clang` of the same
revision on a worker, over the Xcode SDK view and the engine's libc++
headers that every compile has as inputs; the links, archives, lipo,
dsymutil, codesign, Swift and the Dart tools stay on the Mac, as the
config's strategies and the toolchain's `no-remote-exec` say), and the
wrapped GN builds' compiles go through the Mac's reclient with
`--//engine/src/flutter/build/bazel:wrap_rbe` (the SDK views and the Linux
clang laid under the GN root for `rewrapper-mac-<cpu>.cfg`; ninja at most
800 jobs there, the recipe's own cap: ninja's Darwin build selects on 1024
descriptors). Measured on a 16-core Apple-silicon Mac (11-05): the
`ci_mac_host_debug` install 7:38 with 5,540 compiles on the workers
against ~16 minutes local; `ci_ios_debug` 8:25 against 14:52; the Dart
runtime's wrap 91 s of ninja with reclient's cache warm against 333 s
local. bazel_ci.py adds both flags on a Mac bot, as it adds `--config=rbe`
on a Linux one; ci.md has the details.

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

Compilation modes are output directories. The unoptimized configurations
are `-c dbg` (GN's `-O0 -g2`); a bare `bazel test //engine/src/flutter/...`
runs in Bazel's default fastbuild (`-O0 -g1`, no GN build). The two share
nothing: the engine compiles once per mode, and so do the wrapped GN builds
-- their GN arguments are the same for both, but an action's outputs live
under the mode's directory, so the Dart SDK (~10 minutes) and the GPU
backends (~40 minutes) build again the first time a tree built in one mode
is built in the other (the first `--config=host_debug_unopt` run of a tree
that had only seen the wildcard took 89 minutes). Pick one mode for a
checkout; the disk cache holds both once built.

## What to run before landing: the suites no single wildcard covers

`bazel test //engine/src/flutter/...` is the engine's gate on either host
(1,345 tests on Linux x64, 968 declared on a Mac), but several suites are
outside it by design, and a change can break one of them without a wildcard
noticing -- as 418 did to the Android tool tests (the facsimile's engine
stamp changed under the Maven repository the Gradle plugin reads; found at
the first rerun, 440) and 436 to a Mac's wildcard (the aggregate `:tests`
listed suites tagged `manual`; a test_suite runs what it lists). The full
set, per host, with what each takes from a warm cache on a 24-core machine:

| Host | Command | What it covers | Time |
|---|---|---|---|
| Linux | `bazel test //engine/src/flutter/...` | the engine: C++ suites, Dart tests under flutter_tester, the web engine's Chrome and Firefox suites, the packages' tests | 1 h 10 – 1 h 45 (2 h 15 when a wrapped GN build reruns; 7 h 50 at 462 with every C++ object recompiled and both wrapped builds rerun per configuration, 1,427 tests after the roll) |
| Linux | `bazel test //:framework_tests //:tool_tests //:dart_tests` | the framework's 1,644 files, the tool's six shards (general, commands, integration, desktop, web, hermetic), the Dart packages' | 75 min for the three (2,550 tests, 10-27; 3 h 14 at 463 with the engine's profile and release builds for the facsimile); 78 min for the tool's and the Dart packages' alone when the framework's are cached (509 tests at 464) |
| Linux | `bazel test //:android_tool_tests` | `flutter build apk\|appbundle\|aar` through the tool against the build's Android engine; Gradle from the network | 50 min (the first run builds the Android engine for three CPUs in three modes); 72 min at 464 |
| Linux | `bazel test --config=android_debug_test //engine/src/flutter/ci/builders:android_debug_test_tests` | the embedding's 87 Robolectric classes, under an Android configuration | 45 min (the Android debug engine's build included); 36 min at 464 |
| Mac | `bazel test //engine/src/flutter/...` | the engine on a Mac: the macOS shell and its suites, the Metal backends, the golden suite, Chrome's web suites | 2 h 20 |
| Mac | `bazel test //:framework_tests //:tool_tests //:dart_tests` | as Linux's, on a Mac | 67 min |
| Mac | `bazel test //:apple_tool_tests` | `flutter build macos\|ios`, SwiftPM and the Xcode migrations through the tool against the universal frameworks | 15 min once the frameworks are built |
| Mac | `for c in mac_android_profile mac_android_profile_arm64 mac_android_profile_x64 mac_android_release mac_android_release_arm64 mac_android_release_x64; do bazel run --config=$c //engine/src/flutter/ci/builders:$c -- /tmp/$c; done` | Android from a Mac host (Q32): the six Android AOT builders' installs -- the universal gen_snapshot in `darwin-x64.zip`, lib/snapshot's blobs | 3 min each once the Dart wrap's halves are built (12 min the first) |

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
round of 10-31 ran the root suites with `--disk_cache=` after the cache had
regrown to 56 GB between two runs with no idle time between them; a build
with `--experimental_disk_cache_gc_max_size=10G
--experimental_disk_cache_gc_idle_delay=10s` collects it on demand.

After a rebase or a roll, before any of them, the generated files: `DEPS`
feeds `deps.lock.bzl` (`gen_deps.dart --check` in `tools/bazel_tools`),
`pubspec.lock` and lib/web_ui's feed `pub.lock.bzl` (`gen_pub_lock.dart
--check` there too, after `dart pub get` at the root and in lib/web_ui so the
package configurations match the locks), the GN files feed the BUILD files
(`gn_to_bazel.dart --check` in `tools/gn_to_bazel`), and the recipe's CI
sequence runs by hand (`ci.md`). The rebase of 10-30 regenerated the first
and third and not the second: the tool's tests then ran against pub
packages the lock had moved past (`dap_adapters` 1.0.1 for 1.1.0), which
the `bazel_tools` tests now catch (`pub_lock_current_test.dart`, data on
both locks and the generated file) and the root suites found.

## Adding a dependency

1. Make sure `deps.lock.bzl` is current (`gen_deps.dart --check`).
2. Add an entry to `_SOURCE_REPOSITORIES` or `_TOOL_REPOSITORIES` in
   `extensions.bzl`, pointing at the `DEPS` path (sysroots go in
   `_SYSROOT_REPOSITORIES`, keyed by their `sysroots.json` entry), and the
   sha256 of its CIPD zip to `_CIPD_SHA256` so a download is verified.
3. If upstream has no usable Bazel files, add `third_party/<name>/BUILD.<name>.bazel`,
   starting its `copts` from `FLUTTER_THIRD_PARTY_COPTS` and adding the `-Wno-*`
   flags its `BUILD.gn` uses.
4. Add the repository name to `use_repo(synced_deps, ...)` in the root `MODULE.bazel`.
