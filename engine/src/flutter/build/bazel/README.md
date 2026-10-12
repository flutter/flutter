# build/bazel

Bazel-side support files for the GN → Bazel migration of the engine build.
Nothing in this directory is used by the GN build.

| File | Role |
| --- | --- |
| `deps.lock.bzl` | **Generated** from `DEPS` by `tools/bazel_tools/bin/gen_deps.dart`; never edit by hand. The pins (`VARS`, `GIT_DEPS`, `CIPD_DEPS`, `GCLIENT_GN_ARGS`) as Starlark data. |
| `repositories.bzl` | Repository rules: `synced_repository` (a directory populated by `gclient sync`, consumed in place) and `cipd_package` (a CIPD instance downloaded over HTTPS, no `cipd` client needed). |
| `extensions.bzl` | The `synced_deps` module extension: the table of repositories the root `MODULE.bazel` imports with `use_repo`, backed by the pins in `deps.lock.bzl` and `build/linux/sysroot_scripts/sysroots.json`. |
| `third_party/<name>/BUILD.<name>.bazel` | Overlay root `BUILD` files for dependencies that ship no usable Bazel build files. Deliberately not named `BUILD.bazel`, so Bazel does not treat them as packages of this repository. |
| `toolchains/` | The hermetic C/C++ toolchains (`cc_toolchain_config.bzl` holds the flag tables, `BUILD.bazel` the `cc_toolchain`/`toolchain` targets per platform, `tests/` a smoke test). |
| `copts.bzl` | What GN adds per target rather than per toolchain, for `BUILD` files to spell out: `FLUTTER_COPTS` / `FLUTTER_LOCAL_DEFINES` for first-party code (`chromium_code`, `//flutter:config`) and `FLUTTER_THIRD_PARTY_COPTS` for overlays (`no_chromium_code`). |
| `gn_build/` | The `gn_build` rule (`gn_build.bzl`, action script `gn_build.py`): a GN build of part of the tree as one Bazel action, for the subtrees that keep their GN rules during the migration. |
| `gn_action/` | The `gn_action` rule: GN's `action()` -- one run of a Python script under the hermetic `@cpython3` -- as the generated `BUILD` files emit it, with the path tokens (`$(execpath ...)`, `$(src ...)`, `$(gen ...)`) the converter writes for `rebase_path()` results; `gn_copy` for `copy()`; `run_python` for other rules that run the engine's scripts. |
| `flatbuffers/` | The engine's `flatbuffers()` GN template as a macro: `flatc` per schema, the generated headers as a library. |
| `impeller/` | The engine's `impeller_shaders()` GN template as a macro over three rules (`impellerc_compile`, `shader_archive`, `embed_blob`); see below. |
| `dart_wrap/` | The Dart SDK, built with `gn_build`: `BUILD.gn` lists the GN targets, `BUILD.bazel` the args, the inputs and the `cc_library` facades; `tests/` starts the VM from the archive. |

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
-D_DEBUG`) and `-c opt` to optimized ones (`-O2 -DNDEBUG`, dead stripping).
There is no component build: `.bazelrc` sets `--force_pic` and
`--dynamic_mode=off`, as GN links everything statically with `-fPIC`.

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
sandboxed build with a missing file, and the fix is a glob. The tools come
from the same places as for the rest of the build: `@gn`, `@ninja`,
`@clang_linux_x64`, `@sysroot_linux_x64`, and `@cpython3` as the
`--script-executable` in place of depot_tools' `vpython3`.

```
bazelisk build //engine/src/flutter/build/bazel/dart_wrap:dart_sdk   # everything
bazelisk build //engine/src/flutter/build/bazel/dart_wrap:gen_snapshot
bazelisk test  //engine/src/flutter/build/bazel/dart_wrap/tests:dart_vm_smoke_test
```

Products are targets of the package (`:gen_snapshot`, `:libdart_jit.a`,
`:compile_commands.json`, ...), libraries are consumed through the facades
(`:libdart_jit`, `:common_embedder_dart_io`, `:elf_loader`, ...). A full
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
