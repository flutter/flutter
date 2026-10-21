# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The LTO variants of emscripten's system libraries, built at fetch time.

GN's web build links with `-flto` (enable_lto, tools/gn's --lto default,
which the skwasm toolchains keep and the CanvasKit ones turn off), and emcc
then links the LTO variants of its system libraries
(`sysroot/lib/wasm32-emscripten/lto/libc-ww.a`, ...). The synced SDK ships
without them -- its prebuilt cache has the ww/mt/debug variants and no lto/
-- and GN's first link builds them into the prebuilt SDK's cache, whose
.emscripten leaves the cache writable. The Bazel toolchain freezes the cache
(hermetic; the synced tree read-only), so the variants are built here
instead, once per output base, by the SDK's own embuilder into a cache of
this repository's own; the emsdk repository's view links the directory into
place (synced_repository's `links`, extensions.bzl), where the frozen cache
finds it. The whole set takes under a minute (48 s for the twelve, 3.5 CPU
minutes).

The library list is what GN's links of the three skwasm modules built
(research note 12 §5): a module needing a variant not listed fails its link
with emcc's "FROZEN_CACHE is set, but cache file is missing", which names
the library to add.
"""

load("//engine/src/flutter/build/bazel:repositories.bzl", "checkout_root")

# The variants the skwasm modules' links need (wasm workers, no exceptions,
# WebGL 2 with getProcAddress), by their embuilder names.
LTO_LIBRARIES = [
    "crtbegin",
    "libbulkmemory",
    "libc-ww",
    "libc++-ww-noexcept",
    "libc++abi-ww-noexcept",
    "libc_optz-ww",
    "libcompiler_rt-ww",
    "libdlmalloc-ww",
    "libGL-ww-webgl2-getprocaddr",
    "libnoexit",
    "libsockets-ww",
    "libwasm_workers",
]

_CONFIG = """# emcc's configuration for the fetch-time build of the LTO system
# libraries: the SDK's own tools, a cache of this repository's own.
EMSCRIPTEN_ROOT = {emscripten}
LLVM_ROOT = {llvm}
BINARYEN_ROOT = {binaryen}
NODE_JS = {node}
CACHE = {cache}
FROZEN_CACHE = False
"""

_BUILD = """# The LTO variants of emscripten's system libraries (see lto_libraries.bzl).
package(default_visibility = ["//visibility:public"])

filegroup(
    name = "lto",
    srcs = glob(["lto/**"]),
)
"""

def _node(emsdk):
    # The Node.js the SDK ships (NODE_JS in its .emscripten); the version is
    # in the path.
    for child in emsdk.get_child("node").readdir():
        node = child.get_child("bin/node")
        if node.exists:
            return node
    fail("emsdk_lto_libraries: no node/*/bin/node under %s" % emsdk)

def _emsdk_lto_libraries_impl(rctx):
    emsdk = checkout_root(rctx).get_child(rctx.attr.emsdk_path)
    emscripten = emsdk.get_child("upstream/emscripten")
    if not emscripten.get_child("embuilder.py").exists:
        fail(
            "emsdk_lto_libraries: %s is not an activated Emscripten SDK. It is populated by " % emsdk +
            "`gclient sync`; run it from the repository root (see DEPS).",
        )

    # A roll of the SDK re-fetches; nothing else about the tree is watched
    # (the libraries depend on the SDK's version, not on this checkout).
    rctx.watch(emscripten.get_child("emscripten-version.txt"))

    cache = rctx.path("cache")
    rctx.file("em_config.py", _CONFIG.format(
        emscripten = repr(str(emscripten)),
        llvm = repr(str(emsdk.get_child("upstream/bin"))),
        binaryen = repr(str(emsdk.get_child("upstream"))),
        node = repr(str(_node(emsdk))),
        cache = repr(str(cache)),
    ))
    result = rctx.execute(
        [
            rctx.path(rctx.attr._python),
            "-B",
            emscripten.get_child("embuilder.py"),
            "build",
        ] + rctx.attr.libraries + ["--lto"],
        environment = {
            "EM_CONFIG": str(rctx.path("em_config.py")),
            "PYTHONDONTWRITEBYTECODE": "1",
        },
        timeout = 1800,
    )
    if result.return_code != 0:
        fail("emsdk_lto_libraries: embuilder failed (%d):\n%s\n%s" % (result.return_code, result.stdout, result.stderr))

    # The libraries are the repository; the rest of the cache (the installed
    # headers, the sanity file, the build directories) was embuilder's
    # scratch.
    lto = cache.get_child("sysroot/lib/wasm32-emscripten/lto")
    for library in rctx.attr.libraries:
        name = library + (".o" if library.startswith("crt") else ".a")
        if not lto.get_child(name).exists:
            fail("emsdk_lto_libraries: embuilder built no %s" % name)
    rctx.symlink(lto, "lto")
    rctx.file("BUILD.bazel", _BUILD)
    rctx.file("REPO.bazel", "")

emsdk_lto_libraries = repository_rule(
    implementation = _emsdk_lto_libraries_impl,
    doc = "The LTO variants of emscripten's system libraries, built by the synced SDK's embuilder.",
    attrs = {
        "emsdk_path": attr.string(
            mandatory = True,
            doc = "The activated SDK, relative to the repository root (engine/src/flutter/prebuilts/emsdk).",
        ),
        "libraries": attr.string_list(
            default = LTO_LIBRARIES,
            doc = "The variants to build, by embuilder's names.",
        ),
        "_python": attr.label(
            default = "@cpython3//:bin/python3",
            doc = "The checkout's Python, which runs embuilder.",
        ),
    },
)
