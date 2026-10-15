# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Module extension that exposes the engine's dependencies as repositories.

The pins come from `deps.lock.bzl` (generated from `DEPS`) and, for the Debian
sysroots, from `build/linux/sysroot_scripts/sysroots.json`. During the
GN/Bazel transition every dependency is consumed from the directory
`gclient sync` populated (`synced_repository`), so both build systems see
identical trees and nothing is fetched twice.

Toolchains (clang, sysroots, gn, ninja, ...) can instead be downloaded by
Bazel itself by setting `FLUTTER_BAZEL_FETCH_TOOLCHAINS=1` (for example
through `--repo_env`). The repositories have the same layout either way.
The few tools that are not in DEPS at all (`_DOWNLOADED_TOOL_REPOSITORIES`)
are always downloaded.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load(":deps.lock.bzl", "CIPD_DEPS", "GIT_DEPS")
load(":repositories.bzl", "cipd_package", "engine_version_repository", "synced_repository")

_OVERLAYS = "//engine/src/flutter/build/bazel/third_party"

# Source trees from DEPS, keyed by repository name.
#   path:           directory relative to the repository root, as listed in DEPS.
#   build_file:     overlay BUILD file, or None to use the upstream Bazel files.
#   gn_build_files: instead of an overlay, GN build files that tools/gn_to_bazel
#                   converts into the repository at fetch time (with
#                   gn_repository and gn_secondary_dir, see repositories.bzl).
#   synced:         the DEPS entry inside `path`, when `path` is an engine
#                   directory holding the GN file over a synced subdirectory.
_SOURCE_REPOSITORIES = {
    "abseil-cpp": struct(
        path = "engine/src/third_party/abseil-cpp",
        build_file = None,
    ),
    # The overlay mirrors the engine's //flutter/third_party/boringssl/BUILD.gn.
    "boringssl": struct(
        path = "engine/src/flutter/third_party/boringssl/src",
        build_file = _OVERLAYS + ":boringssl/BUILD.boringssl.bazel",
    ),
    # Embedding API headers and the inputs of the wrapped GN build (see the
    # overlay).
    "dart": struct(
        path = "engine/src/flutter/third_party/dart",
        build_file = _OVERLAYS + ":dart/BUILD.dart.bazel",
    ),
    # Skia's codec and font dependencies, each converted at fetch time from
    # its GN file: in the synced tree (libpng, freetype2), in the engine's
    # secondary source tree (expat, libwebp, wuffs; files beside the BUILD.gn
    # are mirrored in), or in the engine over a synced `src/` (libjpeg-turbo).
    "expat": struct(
        path = "engine/src/flutter/third_party/expat",
        build_file = None,
        gn_build_files = ["engine/src/flutter/build/secondary/flutter/third_party/expat/BUILD.gn"],
        gn_repository = "@expat=//flutter/third_party/expat",
        gn_secondary_dir = "engine/src/flutter/build/secondary/flutter/third_party/expat",
    ),
    "freetype2": struct(
        path = "engine/src/flutter/third_party/freetype2",
        build_file = None,
        gn_build_files = ["engine/src/flutter/third_party/freetype2/BUILD.gn"],
        gn_repository = "@freetype2=//flutter/third_party/freetype2",
    ),
    # glslang's and SPIRV-Tools' own GN (upstream files): their action()
    # targets become gn_action rules.
    "glslang": struct(
        path = "engine/src/flutter/third_party/vulkan-deps/glslang/src",
        build_file = None,
        gn_build_files = ["engine/src/flutter/third_party/vulkan-deps/glslang/src/BUILD.gn"],
        gn_repository = "@glslang=//flutter/third_party/vulkan-deps/glslang/src",
    ),
    # The shader compiler's dependencies (research/08): engine GN in the
    # secondary tree describing a synced tree by absolute path, converted at
    # fetch time like the codecs above.
    "flatbuffers": struct(
        path = "engine/src/flutter/third_party/flatbuffers",
        build_file = None,
        gn_build_files = ["engine/src/flutter/build/secondary/flutter/third_party/flatbuffers/BUILD.gn"],
        gn_repository = "@flatbuffers=//flutter/third_party/flatbuffers",
    ),
    "googletest": struct(
        path = "engine/src/flutter/third_party/googletest",
        build_file = None,
    ),
    "icu": struct(
        path = "engine/src/flutter/third_party/icu",
        build_file = _OVERLAYS + ":icu/BUILD.icu.bazel",
    ),
    "inja": struct(
        path = "engine/src/flutter/third_party/inja",
        build_file = None,
        gn_build_files = ["engine/src/flutter/build/secondary/third_party/inja/BUILD.gn"],
        gn_repository = "@inja=//flutter/third_party/inja",
    ),
    "json": struct(
        path = "engine/src/flutter/third_party/json",
        build_file = None,
        gn_build_files = ["engine/src/flutter/build/secondary/flutter/third_party/json/BUILD.gn"],
        gn_repository = "@json=//flutter/third_party/json",
    ),
    # The engine's own C++ runtime, built from source by the toolchain's
    # `cxx_runtime` library (see toolchains/BUILD.bazel).
    "libcxx": struct(
        path = "engine/src/flutter/third_party/libcxx",
        build_file = _OVERLAYS + ":libcxx/BUILD.libcxx.bazel",
    ),
    "libcxxabi": struct(
        path = "engine/src/flutter/third_party/libcxxabi",
        build_file = _OVERLAYS + ":libcxxabi/BUILD.libcxxabi.bazel",
    ),
    "libjpeg-turbo": struct(
        path = "engine/src/flutter/third_party/libjpeg-turbo",
        synced = "engine/src/flutter/third_party/libjpeg-turbo/src",
        build_file = None,
        gn_build_files = ["engine/src/flutter/third_party/libjpeg-turbo/BUILD.gn"],
        gn_repository = "@libjpeg-turbo=//flutter/third_party/libjpeg-turbo",
    ),
    "libpng": struct(
        path = "engine/src/flutter/third_party/libpng",
        build_file = None,
        gn_build_files = ["engine/src/flutter/third_party/libpng/BUILD.gn"],
        gn_repository = "@libpng=//flutter/third_party/libpng",
    ),
    "libwebp": struct(
        path = "engine/src/flutter/third_party/libwebp",
        build_file = None,
        gn_build_files = ["engine/src/flutter/build/secondary/flutter/third_party/libwebp/BUILD.gn"],
        gn_repository = "@libwebp=//flutter/third_party/libwebp",
        gn_secondary_dir = "engine/src/flutter/build/secondary/flutter/third_party/libwebp",
    ),
    # The desktop embeddings' JSON library (header-only). The mirror's own GN
    # lists two headers fewer than the tree has, so the overlay stands in
    # (see BUILD.rapidjson.bazel).
    "rapidjson": struct(
        path = "engine/src/flutter/third_party/rapidjson",
        build_file = _OVERLAYS + ":rapidjson/BUILD.rapidjson.bazel",
    ),
    "llvm_libc": struct(
        path = "engine/src/flutter/third_party/llvm_libc",
        build_file = _OVERLAYS + ":llvm_libc/BUILD.llvm_libc.bazel",
    ),
    # Text shaping for txt and Skia's skshaper (research/08, step 5): the
    # secondary tree's GN over the synced tree.
    "harfbuzz": struct(
        path = "engine/src/flutter/third_party/harfbuzz",
        build_file = None,
        gn_build_files = ["engine/src/flutter/build/secondary/flutter/third_party/harfbuzz/BUILD.gn"],
        gn_repository = "@harfbuzz=//flutter/third_party/harfbuzz",
    ),
    # Impeller's tessellator (research/08, step 4): the secondary tree's GN
    # over the synced tree.
    "libtess2": struct(
        path = "engine/src/flutter/third_party/libtess2",
        build_file = None,
        gn_build_files = ["engine/src/flutter/build/secondary/third_party/libtess2/BUILD.gn"],
        gn_repository = "@libtess2=//flutter/third_party/libtess2",
    ),
    "re2": struct(
        path = "engine/src/flutter/third_party/re2",
        build_file = None,
        gn_build_files = ["engine/src/flutter/build/secondary/flutter/third_party/re2/BUILD.gn"],
        gn_repository = "@re2=//flutter/third_party/re2",
    ),
    # The Impeller playground's window and UI libraries: the secondary
    # tree's GN over the synced trees (GLFW's imports glfw_args.gni beside
    # it, which the secondary directory mirrors in).
    "glfw": struct(
        path = "engine/src/flutter/third_party/glfw",
        build_file = None,
        gn_build_files = ["engine/src/flutter/build/secondary/flutter/third_party/glfw/BUILD.gn"],
        gn_repository = "@glfw=//flutter/third_party/glfw",
        gn_secondary_dir = "engine/src/flutter/build/secondary/flutter/third_party/glfw",
    ),
    "imgui": struct(
        path = "engine/src/flutter/third_party/imgui",
        build_file = None,
        gn_build_files = ["engine/src/flutter/build/secondary/flutter/third_party/imgui/BUILD.gn"],
        gn_repository = "@imgui=//flutter/third_party/imgui",
    ),
    # Skia as the engine builds it: //flutter/skia/BUILD.gn (the engine's
    # wrapper over Skia's gn/*.gni source lists), converted at fetch time so
    # that Skia rolls need no regeneration (research/07). Skia's own Bazel
    # files are not used: the engine builds Skia with its own flags.
    "skia": struct(
        path = "engine/src/flutter/third_party/skia",
        build_file = None,
        gn_build_files = [
            "engine/src/flutter/skia/BUILD.gn",
            "engine/src/flutter/skia/modules/skcms/BUILD.gn",
            "engine/src/flutter/skia/modules/skparagraph/BUILD.gn",
            "engine/src/flutter/skia/modules/skshaper/BUILD.gn",
            "engine/src/flutter/skia/modules/skunicode/BUILD.gn",
            "engine/src/flutter/third_party/skia/src/partition_alloc/BUILD.gn",
            "engine/src/flutter/third_party/skia/third_party/icu/config/BUILD.gn",
        ],
        gn_repository = "@skia=//flutter/third_party/skia",
    ),
    "spirv-cross": struct(
        path = "engine/src/flutter/third_party/vulkan-deps/spirv-cross/src",
        build_file = None,
        gn_build_files = ["engine/src/flutter/build/secondary/third_party/spirv_cross_flutter/BUILD.gn"],
        gn_repository = "@spirv-cross=//flutter/third_party/vulkan-deps/spirv-cross/src",
    ),
    # SPIRV-Headers' own GN, in the synced tree.
    "spirv-headers": struct(
        path = "engine/src/flutter/third_party/vulkan-deps/spirv-headers/src",
        build_file = None,
        gn_build_files = ["engine/src/flutter/third_party/vulkan-deps/spirv-headers/src/BUILD.gn"],
        gn_repository = "@spirv-headers=//flutter/third_party/vulkan-deps/spirv-headers/src",
    ),
    "spirv-tools": struct(
        path = "engine/src/flutter/third_party/vulkan-deps/spirv-tools/src",
        build_file = None,
        gn_build_files = ["engine/src/flutter/third_party/vulkan-deps/spirv-tools/src/BUILD.gn"],
        gn_repository = "@spirv-tools=//flutter/third_party/vulkan-deps/spirv-tools/src",
    ),
    # The Vulkan headers (//flutter/common/graphics and the Vulkan backends),
    # from the tree's own GN; the platform defines come out as the engine's
    # build_overrides/vulkan_headers.gni sets them.
    "vulkan-headers": struct(
        path = "engine/src/flutter/third_party/vulkan-deps/vulkan-headers/src",
        build_file = None,
        gn_build_files = ["engine/src/flutter/third_party/vulkan-deps/vulkan-headers/src/BUILD.gn"],
        gn_repository = "@vulkan-headers=//flutter/third_party/vulkan-deps/vulkan-headers/src",
    ),
    # VulkanMemoryAllocator (one header), from the secondary tree's GN: a
    # config of defines and warning flags over the Vulkan headers.
    "vulkan_memory_allocator": struct(
        path = "engine/src/flutter/third_party/vulkan_memory_allocator",
        build_file = None,
        gn_build_files = ["engine/src/flutter/build/secondary/flutter/third_party/vulkan_memory_allocator/BUILD.gn"],
        gn_repository = "@vulkan_memory_allocator=//flutter/third_party/vulkan_memory_allocator",
    ),
    # ANGLE's headers alone (GLES2/GLES3/EGL/KHR), which Impeller's GLES
    # backend includes on every platform; ANGLE as a GL implementation (the
    # test surfaces' libEGL/libGLESv2) is a later conversion of its 2,000-line
    # BUILD.gn, so the overlay stands in until then.
    "angle": struct(
        path = "engine/src/flutter/third_party/angle",
        build_file = _OVERLAYS + ":angle/BUILD.angle.bazel",
    ),
    # Trees for the wrapped GN build of the GPU test backends
    # (build/bazel/gl_wrap): SwiftShader, the vulkan-deps directory (over
    # whose subdirectories @vulkan-headers, @spirv-tools, ... are separate
    # repositories), abseil-cpp (whose Bazel rules are @abseil-cpp's) and the
    # allocator (whose library is @vulkan_memory_allocator). Each is the
    # synced directory as files, nothing more.
    "swiftshader": struct(
        path = "engine/src/flutter/third_party/swiftshader",
        build_file = _OVERLAYS + ":swiftshader/BUILD.swiftshader.bazel",
    ),
    "vulkan_deps_tree": struct(
        path = "engine/src/flutter/third_party/vulkan-deps",
        build_file = _OVERLAYS + ":vulkan_deps_tree/BUILD.vulkan_deps_tree.bazel",
    ),
    "abseil_cpp_tree": struct(
        path = "engine/src/third_party/abseil-cpp",
        build_file = _OVERLAYS + ":abseil_cpp_tree/BUILD.abseil_cpp_tree.bazel",
    ),
    "vulkan_memory_allocator_tree": struct(
        path = "engine/src/flutter/third_party/vulkan_memory_allocator",
        build_file = _OVERLAYS + ":vulkan_memory_allocator_tree/BUILD.vulkan_memory_allocator_tree.bazel",
    ),
    # package:vector_math, which lib/gpu's Dart library imports; the test
    # fixtures that compile that library to kernel need its sources.
    "vector_math": struct(
        path = "engine/src/flutter/third_party/pkg/vector_math",
        build_file = _OVERLAYS + ":vector_math/BUILD.vector_math.bazel",
    ),
    # package:process, which the engine's skia_gold_client imports, and
    # through it the Dart tests of //flutter/testing/dart.
    "process": struct(
        path = "engine/src/flutter/third_party/pkg/process",
        build_file = _OVERLAYS + ":process/BUILD.process.bazel",
    ),
    "shaderc": struct(
        path = "engine/src/flutter/third_party/shaderc",
        build_file = None,
        gn_build_files = ["engine/src/flutter/build/secondary/third_party/shaderc_flutter/BUILD.gn"],
        gn_repository = "@shaderc=//flutter/third_party/shaderc",
    ),
    "wuffs": struct(
        path = "engine/src/flutter/third_party/wuffs",
        build_file = None,
        gn_build_files = ["engine/src/flutter/build/secondary/flutter/third_party/wuffs/BUILD.gn"],
        gn_repository = "@wuffs=//flutter/third_party/wuffs",
        gn_secondary_dir = "engine/src/flutter/build/secondary/flutter/third_party/wuffs",
    ),
    "zlib": struct(
        path = "engine/src/flutter/third_party/zlib",
        build_file = _OVERLAYS + ":zlib/BUILD.zlib.bazel",
    ),
}

# Prebuilt tools from DEPS (CIPD packages), keyed by repository name. These
# are symlinked from the checkout by default and downloaded from CIPD when
# FLUTTER_BAZEL_FETCH_TOOLCHAINS is set.
_TOOL_REPOSITORIES = {
    "clang_linux_x64": struct(
        path = "engine/src/flutter/buildtools/linux-x64/clang",
        build_file = _OVERLAYS + ":clang/BUILD.clang.bazel",
    ),
    # The prebuilt Dart SDK (GN's host_prebuilt_dart_sdk): the runtime and
    # snapshots of the Dart tools the engine runs but does not build, the
    # frontend server first (build/bazel/dart/kernel.bzl).
    "dart_sdk_linux_x64": struct(
        path = "engine/src/flutter/prebuilts/linux-x64/dart-sdk",
        build_file = _OVERLAYS + ":dart_sdk/BUILD.dart_sdk.bazel",
    ),
    "gn": struct(
        path = "engine/src/flutter/third_party/gn",
        build_file = _OVERLAYS + ":gn/BUILD.gn_tool.bazel",
    ),
    "ninja": struct(
        path = "third_party/ninja",
        build_file = _OVERLAYS + ":ninja/BUILD.ninja.bazel",
    ),
}

# Prebuilt tools that are not in DEPS, keyed by repository name. They are
# always downloaded from CIPD, whatever FLUTTER_BAZEL_FETCH_TOOLCHAINS says,
# so their pins live here rather than in deps.lock.bzl.
#
# cpython3: the interpreter for the Python scripts GN builds run (DEPS and GN
# rely on depot_tools' `vpython3` for that, which Bazel actions must not reach
# for). The pin is the one Skia's Bazel build uses
# (`third_party/skia/bazel/cipd_deps.bzl`); bump the two together.
_DOWNLOADED_TOOL_REPOSITORIES = {
    "cpython3": struct(
        package = "infra/3pp/tools/cpython3/${platform}",
        version = "version:3@3.11.9.chromium.36",
        build_file = _OVERLAYS + ":cpython3/BUILD.cpython3.bazel",
    ),
}

# Debian sysroots, keyed by repository name. They are not DEPS entries: the
# linux_sysroot_* hooks unpack them with install-sysroot.py, whose pins live
# in sysroots.json (read below, so there is one source of truth). Like the
# tools, they are symlinked from the checkout by default and downloaded when
# FLUTTER_BAZEL_FETCH_TOOLCHAINS is set.
_SYSROOT_REPOSITORIES = {
    "sysroot_linux_x64": struct(
        key = "bullseye_amd64",
        build_file = _OVERLAYS + ":sysroot/BUILD.sysroot_linux.bazel",
    ),
}

_SYSROOTS_JSON = Label("//engine/src/build/linux/sysroot_scripts:sysroots.json")
_SYSROOTS_DIR = "engine/src/build/linux"

_FETCH_TOOLCHAINS_ENV = "FLUTTER_BAZEL_FETCH_TOOLCHAINS"

# sha256 of the zip CIPD serves for a (package, version) pair.
#
# A CIPD instance id is base64url(sha256(zip) + 0x02), so the hash can be read
# off the instance id `gclient sync` records in `<path>/.versions/*.cipd_version`
# without downloading anything; Bazel also prints it after an unpinned fetch.
# A missing entry is not an error -- the download is merely unverified and not
# shared through the repository cache. These should eventually be produced by
# gen_deps.dart rather than maintained by hand.
_CIPD_SHA256 = {
    ("fuchsia/third_party/clang/linux-amd64", "git_revision:07d67299a15ce03b053736e2d31a668ee0576987"): "6b657ccd9ca05c6b9e4458181ec71f1dbaf7122a5e6df7aaaec381a31ab34bd3",
    ("gn/gn/linux-amd64", "git_revision:81b24e01531ecf0eff12ec9359a555ec3944ec4e"): "cd330cb4f4e0d8e5c82ca3a583798ea5337fd01308952dbe227c9dd8bc51d854",
    ("infra/3pp/tools/ninja/linux-amd64", "version:2@1.11.1.chromium.4"): "55833d93abb510f908b2347235116717b10ba6eca19e426a01e6a66b8c3cfd86",
    # cpython3 hashes as recorded by Skia (same zip, same URL).
    ("infra/3pp/tools/cpython3/linux-amd64", "version:3@3.11.9.chromium.36"): "a06bad297267859aad818d2d6c9cc2865f4b0087c71dbf020f6b8e0cb92746c2",
    ("infra/3pp/tools/cpython3/mac-amd64", "version:3@3.11.9.chromium.36"): "787e1e98b6220b4bf887ae04a8a80fb4939ad3c24ca6e2e7753541048c97224a",
    ("infra/3pp/tools/cpython3/mac-arm64", "version:3@3.11.9.chromium.36"): "6c7fb45e6ac6363c00b9820b259132554190a197d65437a0912025fa9c27e161",
    ("infra/3pp/tools/cpython3/windows-amd64", "version:3@3.11.9.chromium.36"): "cdc51dd7d25bc6a249b076e117cdfe29456a93cddd48d4193ca3742a20ea7699",
}

def _cipd_platform(mctx):
    """Returns the value CIPD substitutes for `${platform}` on this host."""
    os_name = mctx.os.name.lower()
    if os_name.startswith("linux"):
        os_part = "linux"
    elif os_name.startswith("mac"):
        os_part = "mac"
    elif os_name.startswith("windows"):
        os_part = "windows"
    else:
        fail("synced_deps: unsupported host OS %r" % mctx.os.name)

    arch = mctx.os.arch.lower()
    if arch in ("amd64", "x86_64", "x64"):
        arch_part = "amd64"
    elif arch in ("aarch64", "arm64"):
        arch_part = "arm64"
    else:
        fail("synced_deps: unsupported host architecture %r" % mctx.os.arch)

    return os_part + "-" + arch_part

def _fetch_toolchains(mctx):
    return mctx.getenv(_FETCH_TOOLCHAINS_ENV, "") not in ("", "0", "false", "no")

def _cipd_pin(path):
    entry = CIPD_DEPS.get(path)
    if entry == None:
        fail("synced_deps: %s is not a CIPD dependency in DEPS (deps.lock.bzl is stale?)" % path)
    packages = entry["packages"]
    if len(packages) != 1:
        fail("synced_deps: %s installs %d CIPD packages; exactly one is supported" % (path, len(packages)))
    return packages[0]

def _download_cipd_package(name, package_template, version, platform, build_file):
    package = package_template.replace("${platform}", platform)
    cipd_package(
        name = name,
        package = package,
        version = version,
        sha256 = _CIPD_SHA256.get((package, version), ""),
        build_file = build_file,
    )

def _sysroot_repositories(mctx, fetch):
    sysroots = json.decode(mctx.read(_SYSROOTS_JSON))
    for name, spec in _SYSROOT_REPOSITORIES.items():
        entry = sysroots.get(spec.key)
        if entry == None:
            fail("synced_deps: %s has no %r entry" % (_SYSROOTS_JSON, spec.key))
        if fetch:
            # install-sysroot.py downloads `<URL>/<sha256>` (a .tar.xz).
            http_archive(
                name = name,
                url = entry["URL"] + "/" + entry["Sha256Sum"],
                sha256 = entry["Sha256Sum"],
                type = "tar.xz",
                build_file = spec.build_file,
            )
        else:
            synced_repository(
                name = name,
                path = _SYSROOTS_DIR + "/" + entry["SysrootDir"],
                build_file = spec.build_file,
            )

def _synced_deps_impl(mctx):
    for name, spec in _SOURCE_REPOSITORIES.items():
        synced = getattr(spec, "synced", spec.path)
        if synced not in GIT_DEPS:
            fail("synced_deps: %s is not a git dependency in DEPS (deps.lock.bzl is stale?)" % synced)
        synced_repository(
            name = name,
            path = spec.path,
            build_file = spec.build_file,
            gn_build_files = getattr(spec, "gn_build_files", []),
            gn_repository = getattr(spec, "gn_repository", ""),
            gn_secondary_dir = getattr(spec, "gn_secondary_dir", ""),
        )

    fetch = _fetch_toolchains(mctx)
    platform = _cipd_platform(mctx)
    for name, spec in _TOOL_REPOSITORIES.items():
        pin = _cipd_pin(spec.path)
        if fetch:
            _download_cipd_package(name, pin["package"], pin["version"], platform, spec.build_file)
        else:
            synced_repository(name = name, path = spec.path, build_file = spec.build_file)

    for name, spec in _DOWNLOADED_TOOL_REPOSITORIES.items():
        _download_cipd_package(name, spec.package, spec.version, platform, spec.build_file)

    _sysroot_repositories(mctx, fetch)

    return mctx.extension_metadata(
        root_module_direct_deps = "all",
        root_module_direct_dev_deps = [],
        # Everything here is derived from checked-in files and the host
        # platform; nothing needs to be recorded in MODULE.bazel.lock.
        reproducible = True,
    )

synced_deps = module_extension(
    implementation = _synced_deps_impl,
    doc = "Exposes DEPS dependencies (synced trees, or downloads for toolchains) as repositories.",
)

# The trees whose HEAD tools/gn reports as skia_version and dart_version.
_SKIA_PATH = "engine/src/flutter/third_party/skia"
_DART_PATH = "engine/src/flutter/third_party/dart"

def _engine_version_impl(mctx):
    for path in (_SKIA_PATH, _DART_PATH):
        if path not in GIT_DEPS:
            fail("engine_version: %s is not a git dependency in DEPS (deps.lock.bzl is stale?)" % path)
    engine_version_repository(
        name = "engine_version",
        skia_version = GIT_DEPS[_SKIA_PATH]["revision"],
        dart_version = GIT_DEPS[_DART_PATH]["revision"],
    )
    return mctx.extension_metadata(
        root_module_direct_deps = "all",
        root_module_direct_dev_deps = [],
        reproducible = True,
    )

engine_version = module_extension(
    implementation = _engine_version_impl,
    doc = "Exposes the version strings of shell/version/version.gni as @engine_version//:version.bzl.",
)
