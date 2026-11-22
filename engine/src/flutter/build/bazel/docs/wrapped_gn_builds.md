# The Dart SDK as a wrapped GN build; the GPU test backends, which were one

## Wrapped GN builds: the Dart SDK

The Dart SDK (VM, `gen_snapshot`, the frontend server, ...) is not converted
to Bazel rules; the engine's GN build of it runs as one Bazel action, the
`gn_build` rule (`build_defs/gn/gn_build.bzl`). The action builds a GN
source root out of
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

Known limits: `bootstrap_compile_platform.exe`, which the prebuilt SDK's
`dart compile exe`
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
a possible follow-up), and
the `dart_test`/`dart_vm_kernel` rules and the package tests, which run on the
prebuilt SDK (the builder runs no tests).

## The GPU test backends

The host suites render through ANGLE (OpenGL ES on Vulkan) and SwiftShader
(Vulkan on the CPU): `//flutter/testing:opengl` links ANGLE's
`libEGL_static` and `libGLESv2_static`, `:vulkan` opens SwiftShader's
`libvk_swiftshader.so`, and ANGLE itself opens the Khronos loader
(`libvulkan.so.1`) and, through it, SwiftShader. `gl_wrap/` provides the
three, and the Khronos validation layer (`libVkLayer_khronos_validation.so`
and its manifest: `impeller_unittests`' data under `--use-glfw-swiftshader`,
the configuration of CI's `host_debug_unopt_impeller_tests` and, since
flutter/flutter#196282, of `host_profile_test` and `host_release_test`,
whose `run_tests.py --type impeller` runs need it for Vulkan validation).

All four are converted trees on Linux and on a Mac, their own GN files
turned into BUILD files at fetch time like Skia's: SwiftShader
(`@swiftshader`, eleven GN files: the driver, its pipeline and device, the
Reactor JIT on Subzero for x64 and on LLVM for arm64, marl, and
SwiftShader's own SPIRV-Tools and SPIRV-Headers), the loader
(`@vulkan-loader`), the layer (`@vulkan_validation_layers`, which the
Android embedding's debug jar packs for arm64 as well) and ANGLE (`@angle`,
eight GN files behind the templates and arguments of `gni/angle.gni`: the
two static libraries, the translator and the preprocessor, the Vulkan
backend, Linux's desktop GL backend, a Mac's Metal backend, and the shared
`libEGL` and `libGLESv2` that a Mac's Impeller golden suite opens by name).
They were one wrapped GN build first, which `gl_wrap` is named for and why
this section is in this file: about 1,100 compiles in a single action that
no cache could split (669 s of `ninja` on 24 cores with the layer). As
converted trees each compile is an action of its own, cached and
distributed, and a roll of one tree rebuilds that tree alone. No GN runs
for them now.

`gl_wrap`'s `:angle` is ANGLE's two static libraries; its targets of the
shared libraries' file names (a Mac's are `libvk_swiftshader.dylib`,
`libvulkan.dylib`, `libVkLayer_khronos_validation.dylib`, `libEGL.dylib` and
`libGLESv2.dylib`) are `build_root_binary` targets
(//build_defs/gn:build_directory.bzl) over the converted ones: the file as
GN's build root holds it, which is what a suite loads -- stripped under
`stripped_symbols` on Linux (the layer is 300 MB with its symbols), as
linked on a Mac, whose GN toolchain strips nothing.

One thing differs from GN on a Mac, on purpose: the loader's install name.
GN's mac toolchain names none, so a dylib's is the path its link wrote
(`./libvulkan.dylib`), which dyld resolves against the working directory:
GN's build directory, where `run_tests.py` starts the suites. A Mac's ANGLE
links the loader directly, and Bazel starts a test in its runfiles tree, so
the converted loader is linked with `-install_name @rpath/libvulkan.dylib`
(the converter's manifest, `installNames`; `flutter_shared_library`'s
`apple_install_name`), which the rpath of the binary's own directory finds
at the suite's copy. SwiftShader's driver sets its own in GN
(`@rpath/libvk_swiftshader.dylib`), the layer is opened by the path its
manifest names, and nothing links against ANGLE's two shared libraries:
`libEGL` opens `libGLESv2` from its own directory, and the golden suite
opens `libGLESv2.dylib` by name.

The converted trees are evaluated under `tools/gn`'s arguments for a host
build (the converter's assumptions), and one GN default among them matters
at run time: `is_minimal_linux` stays `false`.
`build_overrides/vulkan_headers.gni` derives `vulkan_use_x11` from it, and
a loader built without `VK_USE_PLATFORM_XCB_KHR` strips `VK_KHR_xcb_surface`
from the extensions SwiftShader reports, after which GLFW cannot create the
playground's Vulkan window surface.

ANGLE's files are evaluated for the two hosts that build it (the manifest's
`angleHosts`). Its targets are always the host's own, which settles two
things GN decides by the host: `tools/gn` turns ANGLE's GL backend off when
the host is a Mac (the converter's `angle_enable_gl` is `!is_mac`), and
ANGLE's own `target_os == host_os` holds. Only what the four libraries are
made of is converted: the GLES 1 library, frame capture, the second set of
libraries for ANGLE's own tests and its command-line tools are skipped in
the manifest, each with its reason. Four things in it are not plain
compiles:

- Two actions write the headers its version string is made of.
  `commit_id.py` asks git for the commit, which a sandboxed action has none
  of; it takes `ANGLE_UPSTREAM_HASH` instead, the `DEPS` pin's revision
  (`gl_wrap/angle_version.bzl`, through the converter's `scriptEnvironment`).
  `program_serialize_data_version.py` hashes the thousand sources that shape
  a program binary, named in a response file (`gn_action`'s
  `response_file_contents`); the hash covers the paths as written, so the
  version differs from a GN build's of the same sources, which only keys
  ANGLE's program cache.
- A Mac's Metal backend compiles its internal shaders at build time, as
  GN's build does where the target is the host's own OS: three actions of
  its package, `xcrun metal` to an `.air` file, `xcrun metallib` to a
  library, and a script that embeds the library in a header, which the
  program version above hashes too. GN writes all three under
  `$root_gen_dir/angle`; an action writes within its own package, so here
  that directory is `angle/` of the package's generated tree (the
  converter's `genDirHomes`), and the file a later action reads is the
  action that wrote it. The Metal toolchain is the host Xcode's -- since
  Xcode 26 a component installed separately (`xcodebuild -downloadComponent
  MetalToolchain`) -- and no file of the checkout. The two `xcrun` actions
  name the Xcode and its SDK's version in their environment (`@macos_sdk`,
  through `scriptEnvironment`), so their key changes with either; the
  toolchain component itself is in no key. They run on the Mac that builds
  (`rbe_mac` sends compiles alone to the workers).
- GN's dependency edges do not carry every header the sources include, so
  every ANGLE target takes the tree's headers from one library
  (`@angle//:all_headers`, the manifest's `implicitDeps`), as SwiftShader's
  packages do from theirs.
- Its dependencies outside the tree are the Bazel side's: abseil
  (`@abseil-cpp`, with the `ABSL_ALLOCATOR_NOTHROW` define of abseil's GN
  config), zlib and its gzip helpers (`@zlib`), SPIRV-Tools (`@spirv-tools`),
  the Vulkan headers and the engine's `flutter_vma`, which
  `build_overrides/angle.gni` names as ANGLE's VulkanMemoryAllocator.

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
bazelisk build //engine/src/flutter/build/bazel/gl_wrap:angle \
    //engine/src/flutter/build/bazel/gl_wrap:runtime_files
bazelisk test  //engine/src/flutter/build/bazel/gl_wrap/tests:gl_backends_smoke_test
```

The smoke test clears and reads back a pixel through EGL on ANGLE and
SwiftShader, and opens SwiftShader as a Vulkan driver.

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
`host_debug_unopt_impeller_tests` builder and, since flutter/flutter#196282,
`host_profile_test` and `host_release_test`: no arguments of its own). That
suite is 4,795 tests and ~35 minutes serial under Bazel; `run_tests.py`
runs it through gtest-parallel, and Bazel's form of that is `shard_count`
(`testShardCounts` in bazel_mapping.dart: sixteen shards), which works because
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

The GTK shell's suite (`shell/platform/linux:flutter_linux_unittests`, about 860
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
