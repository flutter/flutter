# build/bazel

Bazel-side support files for the GN → Bazel migration of the engine build.
Nothing in this directory is used by the GN build.

| File | Role |
| --- | --- |
| `deps.lock.bzl` | **Generated** from `DEPS` by `tools/bazel_tools/bin/gen_deps.dart`; never edit by hand. The pins (`VARS`, `GIT_DEPS`, `CIPD_DEPS`, `GCLIENT_GN_ARGS`) as Starlark data. |
| `repositories.bzl` | Repository rules: `synced_repository` (a directory populated by `gclient sync`, consumed in place) and `cipd_package` (a CIPD instance downloaded over HTTPS, no `cipd` client needed). |
| `extensions.bzl` | The `synced_deps` module extension: the table of repositories the root `MODULE.bazel` imports with `use_repo`, backed by the pins in `deps.lock.bzl`. |
| `third_party/<name>/BUILD.<name>.bazel` | Overlay root `BUILD` files for dependencies that ship no usable Bazel build files. Deliberately not named `BUILD.bazel`, so Bazel does not treat them as packages of this repository. |

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

## Adding a dependency

1. Make sure `deps.lock.bzl` is current (`gen_deps.dart --check`).
2. Add an entry to `_SOURCE_REPOSITORIES` or `_TOOL_REPOSITORIES` in
   `extensions.bzl`, pointing at the `DEPS` path.
3. If upstream has no usable Bazel files, add `third_party/<name>/BUILD.<name>.bazel`.
4. Add the repository name to `use_repo(synced_deps, ...)` in the root `MODULE.bazel`.
