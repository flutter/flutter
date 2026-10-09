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
| `copts.bzl` | `FLUTTER_COPTS` / `FLUTTER_LOCAL_DEFINES`: what GN adds to first-party code only (`chromium_code`, `//flutter:config`), for `BUILD` files to spell out. |

## How dependencies reach Bazel during the transition

`gclient sync` stays the only fetcher. Every source dependency is exposed as a
`synced_repository` whose contents are symlinks into the checkout, so GN and
Bazel compile identical trees and nothing is stored twice. Upstream Bazel
files are used where they are maintained and flag-compatible (`googletest`,
`abseil-cpp`); everything else gets an overlay.

Prebuilt tools (clang, gn, ...) default to the synced copy as well. Set

```
FLUTTER_BAZEL_FETCH_TOOLCHAINS=1   # e.g. bazelisk build --repo_env=FLUTTER_BAZEL_FETCH_TOOLCHAINS=1 ...
```

to have Bazel download them from CIPD at the `DEPS` pins instead; the
repository layout is the same either way. This is the path a checkout without
`gclient` will use once the switch is complete. The download is the exact
package file `gclient` installs (verified byte-for-byte for clang and gn on
linux-x64), served as a zip by
`https://chrome-infra-packages.appspot.com/dl/<package>/+/<version>`.

A CIPD instance id is `base64url(sha256(zip) + 0x02)`, so the sha256 Bazel
needs to verify (and cache) a download can be read off the instance id that
`gclient sync` writes to `<path>/.versions/<name>.cipd_version`, without
downloading anything. Known hashes live in `_CIPD_SHA256` in `extensions.bzl`;
for an unknown pin Bazel still fetches and prints the hash to add.

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

```
bazelisk test //engine/src/flutter/build/bazel/toolchains/tests:cc_toolchain_smoke_test
```

checks the language mode, the libc++ in use, the sysroot, and that a C file
and a threaded C++ program build and run.

## Adding a dependency

1. Make sure `deps.lock.bzl` is current (`gen_deps.dart --check`).
2. Add an entry to `_SOURCE_REPOSITORIES` or `_TOOL_REPOSITORIES` in
   `extensions.bzl`, pointing at the `DEPS` path (sysroots go in
   `_SYSROOT_REPOSITORIES`, keyed by their `sysroots.json` entry).
3. If upstream has no usable Bazel files, add `third_party/<name>/BUILD.<name>.bazel`.
4. Add the repository name to `use_repo(synced_deps, ...)` in the root `MODULE.bazel`.
