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

Every CIPD download is checked against a sha256, and the lock holds them:
`deps.lock.bzl`'s `CIPD_SHA256` has the hash of the archive for every CIPD
package of `DEPS` at its pinned version, a `${platform}` package once for
each platform `gclient` syncs on. `gen_deps.dart` writes it. A CIPD instance
id is `base64url(sha256(zip) + 0x02)`, so a pin by instance id names its own
hash; for a pin by tag the tool asks CIPD what the tag stands for (one
anonymous HTTPS request per package and platform, only for a pin the lock
does not have yet) and records the answer. From then on the lock is what a
download is checked against, so a tag that is moved upstream fails the fetch
instead of changing the build, and Bazel's repository cache
(`--repository_cache`) serves the archive to every checkout and output base
after the first download. An entry is empty where CIPD has no such package
for a platform or does not show it to an anonymous caller; a pin by tag of
such a package would be fetched unverified. `gen_deps.dart --check`, which
CI runs, asks no server: a `DEPS` whose CIPD pin changed without the lock
fails it.

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
are anonymous. They are Bazel's: made when a build first reads a dependency,
and again when its pin rolls (a tree at a time; the Dart tree with
everything nested in it).

**Fetched once, for every output base.** Bazel keeps a fetched repository in
its repo contents cache when the repository's rule says the fetch is
reproducible, and every output base that needs a repository of the same
definition gets a link to that one directory: a second checkout or
worktree, a new output base, the build after `bazel clean --expunge` fetch
nothing again. The root `.bazelrc` names the cache (`--repo_contents_cache`,
beside the repository cache under `~/.cache/flutter_engine_bazel`; this
Bazel leaves it off unless it is named, and `--repo_contents_cache=` on a
command line turns it off for that command). Bazel's idle server drops an
entry that no output base has used for two weeks. A `fetched_archive` is
reproducible when the lock has its sha256, which it has for every package
CIPD serves; a `fetched_tree` when it is a commit with nothing inside it
but pinned commits and checked packages, whether or not it runs hooks: the
Dart tree fetched twice, a day apart, is the same file for file, what its
hooks write included (83,475 files; `.git` and Python's bytecode aside), and
the Emscripten SDK's installation is a synced checkout's file for file. One
tree is not, and is fetched for each output base as before: vulkan-deps,
whose ten members, which are in the cache, are links into other
repositories of its output base. A bot runs
without this cache (`--repo_contents_cache=` on its command lines, from
`bazel_ci.py` and `dev/bots/bazel.dart`): nothing there would collect it --
Bazel's collector runs in a server that has been idle for five minutes, and
a bot's server exits after five idle minutes or with its task -- and a Mac
bot's home directory is years old. A bot's repositories are laid in its
task's output base, the downloaded ones from the repository cache. Before
bots fetch source trees in place of `gclient sync`, which roll daily, a
cache that the infrastructure sizes and evicts has to hold them: a named
cache, which takes a recipe change ([ci.md](../ci.md)).

Measured on Linux x64. In a checkout that never ran `gclient sync`, a C++
library (`@abseil-cpp//absl/strings`) built in a new output base in 22 s
with nothing fetched; the output base before it had fetched clang, the
sysroot and three trees, 2.3 GB in the cache. In a synced checkout with
`FLUTTER_BAZEL_FETCH_SOURCES=1` (below), `@zlib//:zlib`, whose BUILD file is
converted from GN over the tree in the cache, built in a second output base
in 7 s with nothing fetched; vulkan-deps was fetched there again, its ten
members were not. The two largest trees, in the checkout without `gclient
sync` again: the first output base fetched the Dart tree (with eleven
package trees, for the engine's package configuration) and the Emscripten
SDK; a second resolved the packages, ran a GN conversion and built zlib
over the Dart tree in 12 s, and built the LTO libraries and a wasm module
with the SDK in under a minute, each a link to the first one's directory,
with nothing fetched.

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

**The Emscripten SDK.** The web engine's toolchain is a git dependency of
`DEPS` under `download_emsdk`, the SDK's installer, and a hook,
`tools/activate_emsdk.py`, which runs it for the version it names
(`emsdk.py install`, then `activate`: the compiler and Node.js, downloaded
into the tree). Where the checkout has no SDK, its fetched tree runs the
same two commands, with the version read from that script, which stays the
one place it is written (`_emsdk_hooks` in `extensions.bzl`). `@emsdk_lto`,
the LTO system libraries built at fetch time, reads whichever SDK `@emsdk`
does. Neither is fetched until a build selects the wasm toolchain: the
toolchain is registered for every build, but registering it reads only its
own BUILD file, where the SDK is a label. So a host, Android or iOS build
downloads none of it, and a web build downloads it once per output base.
Measured on Linux x64 in a checkout that never ran `gclient sync`: an
analysis of the host engine leaves both unfetched; the analysis of
`ci/wasm_release`'s install fetches the installer, installs the SDK (1.4 GB)
and builds the twelve LTO libraries, 83 s in all; and the SDK it installs is
the synced checkout's file for file, bytecode caches and the working files
of earlier builds aside.

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

- Windows hosts. On macOS (arm64) the host build
  (`//engine/src/flutter:flutter`), nineteen of the host's test targets and
  `et` have been built and run this way, and a wasm analysis fetches and
  installs the Emscripten SDK there, with which a first module links; an
  Android or iOS build from a Mac has not been made this way, nor a whole
  web build (`ci/builders:wasm_release`, the web build's install, is marked
  for a Linux host).
- A synced checkout that lacks one nested dependency (a roll added it and
  `gclient sync` has not run since) is not repaired: a tree comes from the
  checkout or from a fetch, whole.

`FLUTTER_BAZEL_FETCH_SOURCES=1` (`--repo_env`) takes every source tree from
its fetch in a synced checkout too: what a plain clone builds, without
making one.

## Adding a dependency

1. Make sure `deps.lock.bzl` is current (`gen_deps.dart --check`). After a
   change to `DEPS`, `gen_deps.dart` rewrites it; for a new or changed CIPD
   pin that takes access to the network, once (the sha256, above).
2. Add an entry to `_SOURCE_REPOSITORIES` or `_TOOL_REPOSITORIES` in
   `extensions.bzl`, pointing at the `DEPS` path (sysroots go in
   `_SYSROOT_REPOSITORIES`, keyed by their `sysroots.json` entry).
3. If upstream has no usable Bazel files, add `third_party/<name>/BUILD.<name>.bazel`,
   starting its `copts` from `FLUTTER_THIRD_PARTY_COPTS` and adding the `-Wno-*`
   flags its `BUILD.gn` uses.
4. Add the repository name to `use_repo(synced_deps, ...)` in the root `MODULE.bazel`.
