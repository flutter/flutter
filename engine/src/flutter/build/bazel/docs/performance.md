# Build speed: the cache and the sandbox

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
descriptors). Measured once on a 16-core Apple-silicon Mac: the
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

## Measurements (November 2026)

One 24-core Linux x64 workstation with 94 GB of RAM, `host_debug_unopt`, the
same commit and compiler for both systems, each sequence from a fresh output
location. "Full build" is GN's default target (7,523 ninja steps) and
`//engine/src/flutter:flutter` (6,961 executed processes). Small steps are
medians of three runs. A "code edit" appends a global variable, so the object
file changes and both systems relink.

Without remote execution:

| Step | GN + ninja | Bazel |
|---|---|---|
| Cold full build (two runs each) | 20 min 16 s, 21 min 10 s | 31 min 52 s, 35 min 49 s |
| Build with nothing changed | 0.9 s | 1.1 s |
| Code edit in `fml`, rebuild `fml_unittests` | 2.0 s | 4.0 s |
| Code edit of `shell/common/shell.cc`, rebuild `flutter_tester` | 12.9 s | 16.9 s |
| Comment added to `fml/logging.h`, rebuild `flutter_tester` | 2 min 58 s | 3 min 14 s |
| Clean rebuild from the local disk cache | not available | 1 min 56 s |
| Peak process memory, cold full build | 10.5 GB | 15.1 GB |
| Disk after a full build | 26.8 GB | 47.8 GB, plus a 19.5 GB disk cache |

With remote execution (`--config=rbe` and the wrapped builds through reclient;
GN through reclient as `et` runs it):

| Step | GN + reclient | Bazel |
|---|---|---|
| Cold full build | 5 min 13 s | 7 min 47 s, with 39% of its actions already in the remote cache |
| Rebuild from nothing, remote cache warm | 4 min 23 s | 4 min 25 s |
| Code edit in `fml`, rebuild `fml_unittests` | 8.8 s | 13.8 s |
| Code edit of `shell/common/shell.cc`, rebuild `flutter_tester` | 20.0 s | 82 to 95 s |
| Peak process memory, cold full build | 5.3 GB | 19.7 GB |

Bazel's cold local build spends its critical path, about 17 minutes, in the two
wrapped GN builds. An edit that leaves the object file unchanged (a comment)
does not relink under Bazel. With remote execution the link of `flutter_tester`
runs on a 2-vCPU worker and takes over a minute, where it takes about five
seconds locally.
