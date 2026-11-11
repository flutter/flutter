# C/C++ toolchains

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
`ci/builders` but linux_benchmarks' `ci/host_release_benchmarks` and `et`'s
`local_engine.json` pass; the wrapped GN builds
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
have none), and the Android configurations set `stripped` off
(`stripped=false`; the flag's own default is on, so a bare
`--platforms=...:android_*` build strips), as `tools/gn`'s
`stripped_symbols = target_os != "android"` has it: the build root holds the
unstripped library and the install's aspect writes GN's android toolchain's
strip step beside it as `lib.stripped/<name>` (and `shipped/<name>` where
`--stripped` holds). The Dart
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
the emulator builder's install lays it). The three device suites the
emulator builder's `run_tests.py --type android` pushes are
`flutter_android_device_test` (`build_defs/testing/android_device_test.bzl`;
`androidDeviceTests` in bazel_mapping.dart names them, run_tests.py's
`run_android_tests` list): a `cc_binary` of the Android configuration
(`<name>_binary`) and a host launcher that `adb push`es it to
`/data/local/tmp/<name>` and runs it there whole, with no arguments and no
environment, adb's exit status the verdict and `adb logcat -d` into the
test's undeclared outputs on a failure -- `run_android_unittest`, step for
step. The launcher takes `adb` from `PATH` and starts neither emulator nor
adb server: on the bot the recipe's `android_virtual_device` context has
booted the device before the step (the suite is
`//engine/src/flutter/ci/builders:android_emulator_debug_x64_tests` under
`--config=android_emulator_debug_x64`); on a workstation, an emulator or
device connected to the host's adb server. The tests are `local`, `exclusive`
(one device, fixed paths) and `external`, and compatible with Android target
configurations only, so a host configuration's wildcard run skips them. The
APKs are built and installed, as under GN, and run by nothing (run_tests.py
never launched them). Not here: x86, which no builder builds.

**Android from a Mac host**: the Android
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
cache **frozen** -- the LTO variants GN's links build on the spot come
from `@emsdk_lto` (`lto_libraries.bzl`: built at fetch time by the SDK's
own embuilder into a cache of this repository's own, linked into the
view), and a system library variant neither holds (one outside
`LTO_LIBRARIES`, say `lto/libembind.a`) is an error, where GN's emcc would
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
lines: `-fstack-protector-all` where Linux has
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
inside an Objective-C object). On a Mac, its first run: 16.8 s
wall -- the SDK view fetched (`xcrun`, ~300 symlinks), 4,772 targets
analyzed, libc++, libc++abi, googletest and the test compiled, 84 actions
in the darwin sandbox -- 7/7; a no-op rerun 0.3 s; `-c opt` 17.6 s, the
`.mm` compiled with `-O2 -g2` and nothing of Bazel's. The command lines
are GN's flags in GN's order but for a target's own, which Bazel puts
after the toolchain's.

The converter speaks macOS: `is_mac` (and `is_apple`,
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
gets neither, as GN applies them to no compile. And the host itself is a
repository,
`@host_platform//:host.bzl` (`HOST_OS`, `HOST_CPU`, their constraints,
`HOST_PREBUILTS`, `HOST_DART_SDK`, `HOST_CLANG`), from which
`build/bazel`'s `host_toolchain` group takes the host's CPU -- an
Apple-silicon Mac is its own host, where x86_64 was assumed.
