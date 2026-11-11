# Archives, the build directory and local engines

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
--name` (`cases`). The test's home is its own (`$TEST_TMPDIR/home`, for
the tool's settings), and on a Mac `security` reads the keychain search
list from the home's preferences: the launcher of an unsandboxed tool test
copies the developer's list into the test's home (`security list-keychains
-d user -s`; the keychains stay where they are), or the login keychain and
its code-signing identity are invisible -- `flutter create` then writes no
DEVELOPMENT_TEAM, a device build has nothing to sign with, and a failed
device build is explained by the missing team rather than by Xcode's output
(a "no valid code signing
certificates" failure has the same cause). Two of the android shard's files build for macOS and
iOS as well on a Mac (analyze_size_test's iOS and macOS cases on
hello_world, flutter_build_with_compilation_error_test's macos and ios
targets; `skip: !platform.isMacOS` elsewhere): the android shard runs their
other cases with `--name` on every host, and `apple_cases_shard`, of the
apple shard's shape and in `//:apple_tool_tests`, runs those (targets
`<file>_apple`; hello_world's Xcode projects copied writable like the
gallery's); they fail in the android shard,
whose facsimile has neither the iOS engine nor the writable scripts.
The host's TMPDIR reaches these tests as Bazel passes it
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
nothing; for Android the generated configurations set it off (the flag
itself defaults on), and the aspect adds GN's android
toolchain's `--strip-unneeded` copy as `lib.stripped/<name>` (see the
Android section); on the macOS platforms the aspect strips nothing and
writes no `exe.unstripped/`, as GN's mac toolchain links into the build
root as is (the frameworks' packaging strips and writes dSYMs:
`apple_universal`, above). The objcopy is the host's clang's
(`@host_platform`). The
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

Neither the manifest nor a host builder's install carries the web SDK (the
wasm builders' installs lay it),
or GN's own bookkeeping (`args.gn`,
depfiles). `compile_commands.json`, which `tools/clang_tidy` and clangd
read, comes from `tools/gn_to_bazel/tool/compile_commands.py` over
`bazel aquery` after a build (a tool, since no action can query the
graph); its entries run from the execution root, where Bazel's relative
include paths resolve, but name the source and the compiler as the
checkout spells them, so that `tools/clang_tidy`'s file selection and its
search for `clang-tidy` beside the compiler work on it as they do on GN's.
For a `tools/gn --bazel` build directory, `compile_commands.py
--build-directory=out/<name> --build` runs through the directory's own
Bazel commands (bazel.json's: the same server, output base and
configuration as the build), first a build of the query's universe that
fetches the generated sources and headers a remote build leaves on the
workers (`--remote_download_regex`, the manual tests included), then the
query; `ci/clang_tidy.sh --variant <name>` does that itself when it finds a
bazel.json, and the clang-tidy builders run the script as the build's own
test step (`ci.md`). Entries whose compiler is not clang -- Emscripten's
under the wasm transitions -- are left out, as the tool could not find a
clang-tidy for them; `tools/clang_tidy` reads an entry's `arguments` when
there is one, so Bazel's quoted defines reach clang-tidy whole, and
`.clang-tidy`'s header filter knows the execution root's spelling of the
engine's headers beside GN's. The builder-specific
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
    --local-engine=$PWD/../../engine/src/out/bazel-out/android_arm64_debug-opt/bin/engine/src/flutter \
    --local-engine-host=$PWD/../../engine/src/out/bazel-out/linux_x64_debug-opt/bin/engine/src/flutter
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
archives, ICU's data file for the target.
