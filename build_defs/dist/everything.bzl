# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""GN's default target -- everything -- as the contents of an install or a local engine.

What `ninja -C out/<dir>` with no target builds under GN is the root group
`flutter` (engine/src's //:default depends on //flutter alone), and what
that group lays out is what two Bazel consumers want in one place:
//engine/src/flutter:local_engine, the developer's build directory the
flutter tool reads through its manifest (local_engine.bzl), and the install
of a CI build whose builder file names no ninja target -- the Mac's test
builds and iOS simulator builds (mac_unopt.json, mac_ios_engine.json),
which GN builds whole and whose later steps read the directory (the iOS
xcframework generator takes Flutter.framework from each simulator
directory; the test steps run the suites). The three functions return the
`contents`, `files` and `trees` attributes both rules share
(INSTALL_CONTENT_ATTRS), by platform; `everything_assemble` is the local
engine's alone (the directories the tool reads as directories).

What a host build lays out, a Linux host's and a Mac's alike: the targets
that place their own files (BuildDirectoryInfo) -- the sky_engine package
(gen/dart-pkg/sky_engine: the targets of sky/packages/sky_engine) and
impellerc's GLSL library, which GN's shader_lib group copies beside the
compiler (shader_lib/flutter/runtime_effect.glsl, shader_lib/impeller/
*.glsl; the flutter tool hands the directory to impellerc as --include
when it compiles a package's shaders) -- and the files by the directory
that holds them under the build root (a shared library by its GN target,
lib<name>.so or .dylib by the platform). An Android or iOS build's
contents are the root group's: the Android shell with its jars and
archives, the host gen_snapshot, the snapshots, the Impeller SDK, the
embedder archive (the Maven tree and the dist archives are not in it; the
builders name them as targets); Flutter.framework and Flutter.xcframework,
the host's universal gen_snapshot halves and the snapshots
(generate_snapshot_bins), the scenario app in debug and profile -- what
the flutter tool reads of an iOS engine, with its host tools from the Mac's
host build (--local-engine-host). A Mac's host build lays
FlutterMacOS.framework and its xcframework at the build root besides
(shell/platform/darwin/macos's `macos` group, what the root reaches
through shell/platform:platform).
"""

_HOST_CONTENTS = [
    "//engine/src/flutter/impeller/compiler/shader_lib/flutter",
    "//engine/src/flutter/impeller/compiler/shader_lib/impeller",
    "//engine/src/flutter/sky/packages/sky_engine",
]

_HOST_FILES = {
    "//engine/src/flutter/build/bazel/dart_wrap:gen_snapshot": "",
    "//engine/src/flutter/flutter_frontend_server:frontend_server": "gen",
    "//engine/src/flutter/impeller/compiler:impellerc": "",
    "//engine/src/flutter/impeller/tessellator:tessellator_shared": "",
    "//engine/src/flutter/lib/snapshot:flutter_patched_sdk/platform_strong.dill": "flutter_patched_sdk",
    "//engine/src/flutter/lib/snapshot:flutter_patched_sdk/vm_outline_strong.dill": "flutter_patched_sdk",
    "//engine/src/flutter/lib/snapshot:isolate_snapshot.bin": "gen/flutter/lib/snapshot",
    "//engine/src/flutter/lib/snapshot:isolate_snapshot_instructions.bin": "gen/flutter/lib/snapshot",
    "//engine/src/flutter/lib/snapshot:vm_isolate_snapshot.bin": "gen/flutter/lib/snapshot",
    "//engine/src/flutter/lib/snapshot:vm_snapshot_instructions.bin": "gen/flutter/lib/snapshot",
    "//engine/src/flutter/shell/platform/embedder:copy_headers": "",
    "//engine/src/flutter/shell/platform/embedder:flutter_engine_library": "",
    "//engine/src/flutter/shell/testing:flutter_tester": "",
    "//engine/src/flutter/tools/font_subset:font-subset": "",
    "//engine/src/flutter/tools/path_ops:path_ops": "",
    # copy("copy_icudata"): the full data file, where artifacts.zip
    # carries the trimmed flutter/icudtl.dat.
    "@icu//:icudata": "",
}

# The Dart SDK's tree, at its paths.
_HOST_TREES = ["//engine/src/flutter/build/archives:dart_sdk_archive_dart-sdk"]

def everything_contents():
    """The targets that place their own files (BuildDirectoryInfo), by platform."""
    return select({
        "@platforms//os:android": ["//engine/src/flutter:flutter"],
        "@platforms//os:ios": ["//engine/src/flutter:flutter"],
        "@platforms//os:macos": _HOST_CONTENTS + [
            "//engine/src/flutter/shell/platform/darwin/macos:macos",
        ],
        "//conditions:default": _HOST_CONTENTS,
    })

def everything_files():
    """The files by the directory that holds them under the build root, by platform."""
    return select({
        # copy("copy_icudata"): ICU's data file for the target at the build
        # root (android/icudtl.dat; @icu's filegroup selects it), as GN's
        # icudata group lays it.
        "@platforms//os:android": {"@icu//:icudata": ""},
        # ICU's data is inside Flutter.framework on iOS.
        "@platforms//os:ios": {},
        "@platforms//os:macos": _HOST_FILES,
        # A Linux host's adds the GTK embedding's library (its headers are
        # a tree, everything_trees).
        "//conditions:default": _HOST_FILES | {
            "//engine/src/flutter/shell/platform/linux:flutter_linux_gtk": "",
        },
    })

def everything_trees():
    """The trees at their paths: the Dart SDK, and on Linux the GTK headers."""
    return select({
        "@platforms//os:android": [],
        "@platforms//os:ios": [],
        "@platforms//os:macos": _HOST_TREES,
        "//conditions:default": _HOST_TREES + [
            "//engine/src/flutter/shell/platform/linux:flutter_gtk_publish_headers_linux",
        ],
    })

def everything_assemble():
    """The host build's directories built as one directory artifact each, for the local engine's manifest."""
    return select({
        "@platforms//os:android": [],
        "@platforms//os:ios": [],
        "//conditions:default": [
            "gen/dart-pkg/sky_engine",
            "shader_lib",
        ],
    })
