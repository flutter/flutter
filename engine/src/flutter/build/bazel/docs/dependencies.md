# Dependencies: how they reach Bazel, and how to add one

## How dependencies reach Bazel during the transition

In a checkout that `gclient sync` populated, gclient is the only fetcher.
Every source dependency is exposed as a `synced_repository` whose contents
are symlinks into the checkout, so GN and Bazel compile identical trees and
nothing is stored twice. (A checkout that was never synced is the next
section's.) Upstream Bazel
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
repository layout is the same either way. A checkout without the synced
copy downloads them without being asked. The download is the exact
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

## A checkout without `gclient sync`

A plain `git clone` builds the engine too: where the checkout lacks a
directory `DEPS` names, Bazel fetches it. Nothing is asked for and nothing
is written into the checkout; a checkout that has the directory keeps
reading its own, as above.

**What is fetched, and from where.** `deps.lock.bzl`, generated from `DEPS`,
has every git dependency's URL and revision beside the CIPD pins, so `DEPS`
stays the one place a pin is written. For each git dependency the
`synced_deps` extension defines a `fetched_tree` (`git_deps.bzl`), which
nothing fetches until a repository needs it:

- the dependency's revision, by `git fetch --depth=1 <url> <revision>`: one
  commit, checked out with its `.git`, as `gclient sync --no-history` leaves
  it;
- the dependencies `DEPS` nests inside it: linked in from their own fetched
  trees (vulkan-deps' ten members, so that neither is fetched twice), or,
  where the tree runs hooks, fetched in place -- the Dart tree's 21 git
  dependencies (`third_party/pkg/*`, perfetto, binaryen) and two CIPD
  packages (its bootstrap SDK and devtools), since its hooks resolve their
  own path;
- what gclient and its hooks write into the tree: for the Dart tree, the
  `gclient_args.gni` of `DEPS`' `gclient_gn_args`, and the two hooks that
  are scripts of the tree (`generate_package_config.py`,
  `generate_sdk_version_file.py`), run with `DEPS`' Python.

The result is a directory a synced checkout could have had. A
`synced_repository` reads it as it reads the checkout's (`fetched`): the same
overlay, the same fetch-time GN conversion, the same globs. Compared file by
file with a synced checkout at the same `DEPS`, the fetched trees are
identical but for one field of the Dart tree's package configuration, the
pub cache's location, which gclient's hook takes from the user's home
directory and a fetched tree fixes at a path that is the same everywhere.

The tools and the sysroots come the same way (the previous section's
packages and the sysroot hooks' tarballs): a `fetched_archive`
(`fetched_archive.bzl`) per tool, downloaded where the checkout has no such
directory and read by the tool's `synced_repository`. Both kinds of fetch
are repositories of their own because a `synced_repository` is a local
rule, run again at every server start: a download made there would be made
again each time. `third_party/ninja` holds a checked-in README beside where
`DEPS` puts the package, so the directory exists in every checkout and only
the binary says whether ninja is there (`marker`).

**The fetch-time GN conversion.** The converter reads GN files by their path
from the GN root, across trees (FreeType's file imports zlib's and
libpng's). Where the checkout lacks a tree a conversion reads, the converter
runs on a view of the checkout that has the fetched trees at their paths
(`checkout_view`), with `DEPS`' prebuilt Dart SDK and `gn` from the tool
repositories. `_GN_TREES` in `extensions.bzl` lists, per conversion, the
other trees it reads. The list is an optimization and cannot go stale
silently: the converter is told which trees the checkout lacks
(`--absent-tree`), stops at the first path inside one that it does not find,
and the conversion fetches that tree, says so, and runs again.

**The engine's package configuration.** `gclient sync` ends with `dart pub
get --offline` in `engine/src/flutter` (the `pub_get_offline` hook), which
writes `.dart_tool/package_config.json` for the engine's Dart compiles, its
Dart packages' tests and the converter itself. Without it,
`@engine_package_config` (`engine_packages.bzl`) is the same command run by
the same SDK in a view of the checkout that has the fetched packages; pub
writes into the view, never into the checkout. `@host_platform`'s
`ENGINE_PACKAGE_CONFIG` names whichever of the two the checkout has, and
`//engine/src/flutter:package_config` is that file. It names every package
by a path relative to itself, so the rules that read it (the kernel
compiles, the Dart packages' tests) lay the fetched one where the checkout's
would be, `engine/src/flutter/.dart_tool/`, in the tree they build: every
package then has the URI it has in a synced checkout.

**What it needs.** `git` on `PATH`, and the network: `*.googlesource.com` for
the trees, `chrome-infra-packages.appspot.com` for the packages. The fetches
are anonymous. They are Bazel's: the trees live in the output base, are
fetched once per output base, and again after `bazel clean --expunge` or a
roll of their pin (a tree at a time; the Dart tree with everything nested in
it). `--repository_cache` does not hold them, since git is not Bazel's
downloader.

**A roll.** A tree whose pin changed is fetched again, into the same
directory, by the next build that reads it. What was made from the old tree
is made again with it: every fetch writes a `fetched.stamp` beside the tree,
and a repository that reads a fetched tree -- its `synced_repository`, a GN
conversion that imports from it, `@engine_package_config` -- watches that
file (`fetched_tree_directory`). Bazel brings a watched repository up to
date before it decides about the watcher, so the reader waits for the new
tree and is then evaluated again. (Before the stamp, the package
configuration resolved over the old Dart tree stayed as it was after a Dart
roll, and a conversion that ran while the tree was being fetched found half
of it.)

**`et`.** The engine tool checks for gclient only when it builds with GN.
Where `gclient sync` has run, `bin/et` starts as it always did, on the
checkout's prebuilt Dart SDK and package resolution. Where it has not, the
backend decides. With GN (the default) it asks for `gclient sync`, as
before. With Bazel (`--backend bazel`, or `ET_BACKEND=bazel`) it asks Bazel
where the host's prebuilt Dart SDK and the engine's package configuration
are -- one `bazel query --output=location` over
`//engine/src/flutter:package_config` and `@dart_sdk_<host>//:bin/dart`,
which fetches them the first time (and the Dart tree, which holds the
packages) -- and runs the checkout's `tools/engine_tool/bin/et.dart` on
those. A query and not a build: a build with other options than the
developer's last one would discard that build's analysis. `et fetch` with
the Bazel backend looks for neither gclient nor `.gclient` and fetches
nothing: Bazel does that when a build first reads a dependency. `et.bat` is
unchanged; there is no Bazel build on a Windows host.

**What it does not do.**

- The web engine: the Emscripten SDK is installed by a hook of `DEPS`
  (`download_emsdk`), which no fetched tree runs; `@emsdk` says so when a
  build asks for it.
- macOS and Windows hosts: the rules are host-independent, but only Linux
  x64 has been run.
- A synced checkout that lacks one nested dependency (a roll added it and
  `gclient sync` has not run since) is not repaired: a tree comes from the
  checkout or from a fetch, whole.

`FLUTTER_BAZEL_FETCH_SOURCES=1` (`--repo_env`) takes every source tree from
its fetch in a synced checkout too: what a plain clone builds, without
making one.

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
