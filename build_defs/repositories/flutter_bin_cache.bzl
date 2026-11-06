# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The engine artifacts the flutter tool downloaded into bin/cache, as a repository.

`flutter precache` (and every `flutter` command's first run) lays the
prebuilt engine of the version bin/cache/engine.stamp names -- what
bin/internal/update_engine_version.sh resolves from
FLUTTER_PREBUILT_ENGINE_VERSION, a tracked bin/internal/engine.version or
the checkout's content hash -- under bin/cache: artifacts/engine/<host>/
(flutter_tester, impellerc and its shader_lib, icudtl.dat, font-subset,
gen_snapshot, the frontend server snapshot), artifacts/engine/common/
(flutter_patched_sdk, the platform kernels), pkg/sky_engine and
pkg/flutter_gpu, dart-sdk/, and with `--linux` and `--web` the profile and
release host engines and flutter_web_sdk/.

With `--config=prebuilt_engine` (the root .bazelrc:
`--//build_defs/engine:source=prebuilt`), the framework's and the tool's
tests take those files in place of the engine targets the tree builds
(//build_defs/engine, the aliases every test rule names), so that a
checkout without the engine's dependencies -- a framework developer's, a
flutter_drone bot's -- runs them, and a checkout with them skips the
engine build. This repository is bin/cache's files, symlinked in place (as
the gclient-synced trees are, build_defs/repositories/repositories.bzl),
behind a check that what is there is the version the tool wants: the
stamps the tool writes beside each artifact set (flutter_sdk.stamp for the
engine and the packages, engine-dart-sdk.stamp for the Dart SDK,
font-subset.stamp, linux-sdk.stamp, flutter_web_sdk.stamp) must each
equal engine.stamp, or the fetch fails and says to run `flutter precache`
-- a stale cache is not an engine of another version by mistake.

The Dart SDK itself is not here: the host's Dart SDK repository
(HOST_DART_SDK, @dart_sdk_<host>) is bin/cache/dart-sdk under the same
configuration (the synced_deps extension reads FLUTTER_BAZEL_PREBUILT_ENGINE,
which the config sets through --repo_env), the one name every Dart rule
uses either way.
"""

load("//build_defs/repositories:host_platform.bzl", "host_platform_values")
load("//build_defs/repositories:repositories.bzl", "checkout_root", "link_tree")

# The environment variable --config=prebuilt_engine sets (--repo_env), read
# by the synced_deps extension to point the host's Dart SDK repository at
# bin/cache/dart-sdk.
PREBUILT_ENGINE_ENV = "FLUTTER_BAZEL_PREBUILT_ENGINE"

# What the tool wants, and the artifact sets this repository serves with
# their stamps (flutter_tools' flutter_cache.dart: the artifact's name is
# its stamp's): the set, whether a build with the prebuilt engine can do
# without it, and the `flutter precache` flag that fetches it.
_ENGINE_STAMP = "engine.stamp"
_ARTIFACT_SETS = [
    struct(stamp = "flutter_sdk", required = True, precache = ""),
    struct(stamp = "engine-dart-sdk", required = True, precache = ""),
    struct(stamp = "font-subset", required = True, precache = ""),
    struct(stamp = "linux-sdk", required = False, precache = "--linux"),
    struct(stamp = "macos-sdk", required = False, precache = "--macos"),
    struct(stamp = "flutter_web_sdk", required = False, precache = "--web"),
]

# The Dart packages the flutter_sdk artifact set lays under bin/cache/pkg
# (flutter_cache.dart's getPackageDirs), each a package of this repository.
_PACKAGES = ["sky_engine", "flutter_gpu"]

# The engine artifacts directory of a host, as the tool names it (a Mac's
# is darwin-x64 for both CPUs: universal binaries).
def host_engine_directory(os_name, arch):
    host = host_platform_values(os_name, arch)
    if host["HOST_OS"] == "mac":
        return "darwin-x64"
    return "linux-" + host["HOST_CPU"]

def _read_stamp(rctx, cache, name):
    stamp = cache.get_child(name)
    rctx.watch(stamp)
    if not stamp.exists:
        return None
    return rctx.read(stamp).strip()

def _flutter_bin_cache_impl(rctx):
    root = checkout_root(rctx)
    cache = root.get_child("bin/cache")
    hint = "run `bin/flutter precache` from the repository root (the prebuilt engine of bin/cache/engine.stamp)"
    wanted = _read_stamp(rctx, cache, _ENGINE_STAMP)
    if not wanted:
        fail("flutter_bin_cache: bin/cache/engine.stamp is missing: " + hint + ".")
    present = []
    for artifact_set in _ARTIFACT_SETS:
        version = _read_stamp(rctx, cache, artifact_set.stamp + ".stamp")
        if version == None:
            if artifact_set.required:
                fail("flutter_bin_cache: bin/cache has no %s (no %s.stamp): %s." % (
                    artifact_set.stamp,
                    artifact_set.stamp,
                    hint,
                ))
            continue
        if version != wanted:
            fail(("flutter_bin_cache: bin/cache's %s is engine %s, but engine.stamp wants %s: " +
                  "%s%s.") % (
                artifact_set.stamp,
                version,
                wanted,
                hint,
                " " + artifact_set.precache if artifact_set.precache else "",
            ))
        present.append(artifact_set.stamp)

    # The cache's files, symlinked as a synced tree is (repositories.bzl's
    # link_tree, overlaying): entries whole, but a directory that holds a
    # BUILD file is re-created with its entries linked one by one and the
    # BUILD file left out. The engine's artifacts.zip carries the build files
    # beside the shader library's sources (shader_lib/BUILD.gn as GN ships
    # them, shader_lib/BUILD.bazel since the tree has those too), and a
    # BUILD file inside the cache would make its directory a package of its
    # own, which the globs below could not see into (the first presubmit
    # runs of the shards under Bazel, 11-03: "glob pattern
    # 'artifacts/engine/linux-x64/shader_lib/**' didn't match anything").
    # pkg/'s two packages get a BUILD file each (a package's files are laid
    # relative to it, as the tree's sky_engine:package is): naming those
    # paths as excluded makes pkg/ and the package directories real
    # directories the files can be written into, rather than links into the
    # cache.
    link_tree(rctx, cache, True, ["pkg/%s/BUILD.bazel" % name for name in _PACKAGES], {})
    for name in _PACKAGES:
        if not rctx.path("pkg/" + name).exists:
            fail("flutter_bin_cache: bin/cache/pkg/%s is missing: %s." % (name, hint))
        rctx.file("pkg/%s/BUILD.bazel" % name, _PACKAGE_BUILD_FILE.format(name = name))

    host = host_engine_directory(rctx.os.name, rctx.os.arch)
    rctx.file("BUILD.bazel", _BUILD_FILE.format(
        host = host,
        wanted = wanted,
        present = ", ".join(present),
    ))
    rctx.file("version.bzl", 'ENGINE_VERSION = "%s"\nARTIFACT_SETS = %r\n' % (wanted, present))

flutter_bin_cache = repository_rule(
    implementation = _flutter_bin_cache_impl,
    doc = "bin/cache's prebuilt engine artifacts, checked against engine.stamp.",
    # Symlinks into the checkout, and the stamps are watched: not cached.
    local = True,
)

def _flutter_bin_cache_extension_impl(mctx):
    flutter_bin_cache(name = "flutter_bin_cache")
    return mctx.extension_metadata(
        root_module_direct_deps = "all",
        root_module_direct_dev_deps = [],
        reproducible = True,
    )

flutter_bin_cache_extension = module_extension(
    implementation = _flutter_bin_cache_extension_impl,
    doc = "The @flutter_bin_cache repository (above).",
)

_BUILD_FILE = '''# Generated by flutter_bin_cache (build_defs/repositories/flutter_bin_cache.bzl):
# bin/cache as the flutter tool laid it, engine {wanted}
# (artifact sets present: {present}). Do not edit.

package(default_visibility = ["//visibility:public"])

# The host's engine artifacts (artifacts.zip and font-subset.zip as the
# tool unpacks them), at their paths under bin/cache: a test's facsimile of
# the cache lays them there (`cache` with an empty directory).
filegroup(
    name = "host_engine",
    srcs = glob(["artifacts/engine/{host}/**"]),
)

filegroup(
    name = "host_engine_profile",
    srcs = glob(["artifacts/engine/{host}-profile/**"], allow_empty = True),
)

filegroup(
    name = "host_engine_release",
    srcs = glob(["artifacts/engine/{host}-release/**"], allow_empty = True),
)

filegroup(
    name = "common_engine",
    srcs = glob(["artifacts/engine/common/**"]),
)

# The platform kernels the frontend server compiles against (--sdk-root is
# their directory; build_defs/dart/kernel.bzl).
filegroup(
    name = "flutter_patched_sdk",
    srcs = glob(["artifacts/engine/common/flutter_patched_sdk/*"]),
)

filegroup(
    name = "flutter_patched_sdk_product",
    srcs = glob(["artifacts/engine/common/flutter_patched_sdk_product/*"]),
)

exports_files([
    "artifacts/engine/{host}/flutter_tester",
    "artifacts/engine/{host}/icudtl.dat",
    "artifacts/engine/{host}/impellerc",
    "artifacts/engine/{host}/font-subset",
    "artifacts/engine/{host}/gen_snapshot",
])

alias(
    name = "flutter_tester",
    actual = "artifacts/engine/{host}/flutter_tester",
)

alias(
    name = "icudtl",
    actual = "artifacts/engine/{host}/icudtl.dat",
)

alias(
    name = "impellerc",
    actual = "artifacts/engine/{host}/impellerc",
)

alias(
    name = "font_subset",
    actual = "artifacts/engine/{host}/font-subset",
)

filegroup(
    name = "shader_lib",
    srcs = glob(["artifacts/engine/{host}/shader_lib/**"]),
)

filegroup(
    name = "web_sdk",
    srcs = glob(["flutter_web_sdk/**"], allow_empty = True),
)

# The iOS engine directories (`flutter precache --ios`: artifacts/engine/
# ios{{,-profile,-release}}, each with Flutter.xcframework, the
# extension-safe one, gen_snapshot_arm64 and the LICENSE the cache copies
# in), for a Mac's apple shard under the prebuilt engine; empty where the
# tool has not fetched them (a Linux host, or a Mac without --ios).
filegroup(
    name = "ios_engine",
    srcs = glob(["artifacts/engine/ios/**"], allow_empty = True),
)

filegroup(
    name = "ios_engine_profile",
    srcs = glob(["artifacts/engine/ios-profile/**"], allow_empty = True),
)

filegroup(
    name = "ios_engine_release",
    srcs = glob(["artifacts/engine/ios-release/**"], allow_empty = True),
)

# The engine's bookkeeping as the tool left it: the engine's stamp and its
# JSON, the version file, the storage realm, and the stamps of the engine
# artifact sets a facsimile takes from here (the host engine and the
# desktop's, the Dart SDK, font-subset, the web SDK, the iOS engines). A
# facsimile under the prebuilt engine lays these as they are (`cache` with
# an empty directory), so that its stamps say what its artifacts are -- the
# engine the tool downloaded, which on a developer's machine is the content
# hash's build and not the checkout's HEAD -- and the tool neither
# re-downloads a set nor finds a framework stamped with another revision
# than the cache's. Not the other stamps: the tool rewrites the iOS USB
# artifacts' on Linux (it lays no artifacts there) and would find a
# read-only file; the fonts', the Gradle wrapper's and the Android
# gen_snapshots' the facsimile writes itself.
filegroup(
    name = "stamps",
    srcs = glob(
        [
            "engine.stamp",
            "engine_stamp.json",
            "engine_stamp.stamp",
            "flutter.version.json",
            "engine.realm",
            "flutter_sdk.stamp",
            "engine-dart-sdk.stamp",
            "font-subset.stamp",
            "linux-sdk.stamp",
            "macos-sdk.stamp",
            "ios-sdk.stamp",
            "flutter_web_sdk.stamp",
        ],
        allow_empty = True,
    ),
)
'''

_PACKAGE_BUILD_FILE = '''# Generated by flutter_bin_cache: bin/cache/pkg/{name}. Do not edit.

package(default_visibility = ["//visibility:public"])

# The package's files, laid relative to this package (pkg/{name}) by a
# test's cache facsimile, as the tree's are.
filegroup(
    name = "package",
    srcs = glob(["**"]),
)
'''
