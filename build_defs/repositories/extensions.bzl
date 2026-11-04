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
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//engine/src/flutter/build/bazel/toolchains/emscripten:lto_libraries.bzl", "emsdk_lto_libraries")
load(":deps.lock.bzl", "CIPD_DEPS", "GIT_DEPS")
load(":flutter_bin_cache.bzl", "PREBUILT_ENGINE_ENV")
load(":host_files.bzl", "host_files")
load(":host_platform.bzl", "BIN_CACHE_DART_SDK", "host_platform", "host_platform_values")
load(":macos_sdk.bzl", "macos_sdk")
load(":repositories.bzl", "cipd_download_url", "cipd_package", "engine_version_repository", "synced_repository")

_OVERLAYS = "//engine/src/flutter/build/bazel/third_party"

# Source trees from DEPS, keyed by repository name.
#   path:           directory relative to the repository root, as listed in DEPS.
#   build_file:     overlay BUILD file, or None to use the upstream Bazel files.
#   gn_build_files: instead of an overlay, GN build files that tools/gn_to_bazel
#                   converts into the repository at fetch time (with
#                   gn_repository and gn_secondary_dir, see repositories.bzl).
#   synced:         the DEPS entry inside `path`, when `path` is an engine
#                   directory holding the GN file over a synced subdirectory.
#   exclude:        entries of the tree left out of the repository (paths
#                   relative to `path`): what another build writes into it.
#   links:          directories of other repositories put at paths of the
#                   tree (the emsdk's LTO system libraries).
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
    # google/benchmark, for //flutter/benchmarking and the benchmark
    # executables (testing/run_tests.py --type benchmarks): the secondary
    # tree's GN over the synced tree, converted at fetch time; the tree's own
    # Bazel files are not used, as Skia's are not.
    "benchmark": struct(
        path = "engine/src/flutter/third_party/benchmark",
        build_file = None,
        gn_build_files = ["engine/src/flutter/build/secondary/flutter/third_party/benchmark/BUILD.gn"],
        gn_repository = "@benchmark=//flutter/third_party/benchmark",
    ),
    # Brotli's decoder, which FreeType's WOFF2 support links (the web build's
    # flutter_use_freetype_woff2): the engine's GN for the tree, in the
    # secondary source tree, converted at fetch time.
    "brotli": struct(
        path = "engine/src/flutter/third_party/brotli",
        build_file = None,
        gn_build_files = ["engine/src/flutter/build/secondary/third_party/brotli/BUILD.gn"],
        gn_repository = "@brotli=//flutter/third_party/brotli",
    ),
    # Embedding API headers and the inputs of the wrapped GN build (see the
    # overlay).
    "dart": struct(
        path = "engine/src/flutter/third_party/dart",
        build_file = _OVERLAYS + ":dart/BUILD.dart.bazel",
    ),
    # The Emscripten SDK (GN's wasm toolchain, build/toolchain/wasm.gni),
    # a git dependency whose compiler and Node.js tools/activate_emsdk.py
    # installs into it under `download_emsdk`; consumed in place by
    # build/bazel/toolchains/emscripten (see the overlay). The repository is
    # the SDK as synced: the Bazel toolchain runs emcc with the SDK's cache
    # frozen and its Python without bytecode files, while GN's toolchain
    # leaves the cache writable, so a GN build on the same checkout adds
    # emcc's working files to the tree -- left out of the view, so that they
    # neither change every wasm action's inputs (nor differ between
    # machines) nor vanish while Bazel fingerprints the SDK.
    "emsdk": struct(
        path = "engine/src/flutter/prebuilts/emsdk",
        build_file = _OVERLAYS + ":emsdk/BUILD.emsdk.bazel",
        exclude = [
            "upstream/emscripten/cache/build",  # system libraries being built
            "upstream/emscripten/cache/cache.lock",
            "upstream/emscripten/cache/sanity.txt",  # names this machine's paths
            "upstream/emscripten/cache/symbol_lists",  # JS symbol lists of past links
            "upstream/emscripten/cache/symbol_lists.lock",
            # Python's bytecode caches of emcc's modules (stamped with this
            # checkout's source mtimes).
            "upstream/emscripten/__pycache__",
            "upstream/emscripten/third_party/leb128/__pycache__",
            "upstream/emscripten/tools/__pycache__",
            "upstream/emscripten/tools/ports/__pycache__",
            "upstream/emscripten/tools/ports/contrib/__pycache__",
        ],
        # The LTO variants of the system libraries, which GN's -flto links
        # build into the prebuilt's cache on first use: the Bazel build's own
        # copies (@emsdk_lto, built at fetch time by the SDK's embuilder --
        # toolchains/emscripten/lto_libraries.bzl), where the frozen cache
        # looks for them.
        links = {
            "upstream/emscripten/cache/sysroot/lib/wasm32-emscripten/lto": "@emsdk_lto//:lto",
        },
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
    # Google's cpu_features (DEPS: the src/ subtree) under the engine's GN
    # file: the NDK-compatible cpu-features.c libwebp reads on Android
    # (//third_party/cpu_features:ndk_compat, build/secondary's forwarder).
    "cpu_features": struct(
        path = "engine/src/flutter/third_party/cpu_features",
        synced = "engine/src/flutter/third_party/cpu_features/src",
        build_file = None,
        gn_build_files = ["engine/src/flutter/third_party/cpu_features/BUILD.gn"],
        gn_repository = "@cpu_features=//flutter/third_party/cpu_features",
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
            "engine/src/flutter/skia/modules/canvaskit/BUILD.gn",
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
    # The Vulkan validation layer (VkLayer_khronos_validation), which the
    # Android embedding's debug jar packs for arm64
    # (impeller_enable_vulkan_validation_layers; GN builds it at API level 26
    # in a toolchain of its own): the engine's GN in the secondary tree over
    # the synced tree, and the layer-settings library of
    # vulkan-utility-libraries it links, from that tree's own GN.
    "vulkan_validation_layers": struct(
        path = "engine/src/flutter/third_party/vulkan-deps/vulkan-validation-layers/src",
        build_file = None,
        gn_build_files = ["engine/src/flutter/build/secondary/third_party/vulkan_validation_layers/BUILD.gn"],
        gn_repository = "@vulkan_validation_layers=//third_party/vulkan_validation_layers",
        gn_secondary_dir = "engine/src/flutter/build/secondary/third_party/vulkan_validation_layers",
    ),
    "vulkan-utility-libraries": struct(
        path = "engine/src/flutter/third_party/vulkan-deps/vulkan-utility-libraries/src",
        build_file = None,
        gn_build_files = ["engine/src/flutter/third_party/vulkan-deps/vulkan-utility-libraries/src/BUILD.gn"],
        gn_repository = "@vulkan-utility-libraries=//flutter/third_party/vulkan-deps/vulkan-utility-libraries/src",
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
    # googletest's headers under the engine's root-relative spellings
    # (third_party/googletest/googletest/include/gtest/...); @googletest
    # itself keeps upstream's build files.
    "googletest_tree": struct(
        path = "engine/src/flutter/third_party/googletest",
        build_file = _OVERLAYS + ":googletest_tree/BUILD.googletest_tree.bazel",
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
    # package:io, package:node_preamble and package:process_runner: the other
    # packages of the engine's pub workspace under third_party/pkg that its
    # Dart tools and their tests reach (testing/run_tests.py --type dart-host,
    # build_defs/dart/package_test.bzl).
    "io": struct(
        path = "engine/src/flutter/third_party/pkg/io",
        build_file = _OVERLAYS + ":io/BUILD.io.bazel",
    ),
    "node_preamble": struct(
        path = "engine/src/flutter/third_party/pkg/node_preamble",
        build_file = _OVERLAYS + ":node_preamble/BUILD.node_preamble.bazel",
    ),
    "process_runner": struct(
        path = "engine/src/flutter/third_party/pkg/process_runner",
        build_file = _OVERLAYS + ":process_runner/BUILD.process_runner.bazel",
    ),
    # google/gtest-parallel: the runner testing/run_tests.py puts every
    # engine suite through (a process per test, --repeat=2), which
    # flutter_cc_test reproduces (testing.bzl).
    "gtest_parallel": struct(
        path = "engine/src/flutter/third_party/gtest-parallel",
        build_file = _OVERLAYS + ":gtest_parallel/BUILD.gtest_parallel.bazel",
    ),
    "shaderc": struct(
        path = "engine/src/flutter/third_party/shaderc",
        build_file = None,
        gn_build_files = ["engine/src/flutter/build/secondary/third_party/shaderc_flutter/BUILD.gn"],
        gn_repository = "@shaderc=//flutter/third_party/shaderc",
    ),
    # OCMock, which the Objective-C suites link on a Mac; the engine's GN
    # file for it sits in the secondary tree.
    "ocmock": struct(
        path = "engine/src/flutter/third_party/ocmock",
        build_file = None,
        gn_build_files = ["engine/src/flutter/build/secondary/flutter/third_party/ocmock/BUILD.gn"],
        gn_repository = "@ocmock=//flutter/third_party/ocmock",
        gn_secondary_dir = "engine/src/flutter/build/secondary/flutter/third_party/ocmock",
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
    # The Mac's clang (DEPS: buildtools/mac-${arch}/clang, synced on a macOS
    # host of that CPU), for the macOS toolchains
    # (build/bazel/toolchains:macos_*). Defined on every host, fetched only
    # where a macOS toolchain is selected: elsewhere those toolchains'
    # targets are incompatible, and a checkout has no mac-*/ directory.
    "clang_mac_arm64": struct(
        path = "engine/src/flutter/buildtools/mac-arm64/clang",
        build_file = _OVERLAYS + ":clang/BUILD.clang.bazel",
    ),
    "clang_mac_x64": struct(
        path = "engine/src/flutter/buildtools/mac-x64/clang",
        build_file = _OVERLAYS + ":clang/BUILD.clang.bazel",
    ),
    # The Android SDK and NDK (DEPS: download_android_deps, on for a Linux
    # x64 or macOS host), for the Android toolchains: the NDK's sysroot,
    # libraries and compiler runtime (the overlay says which). A checkout
    # synced without it has no Android build, as GN has none.
    "android_tools": struct(
        path = "engine/src/flutter/third_party/android_tools",
        build_file = _OVERLAYS + ":android_tools/BUILD.android_tools.bazel",
    ),
    # The JDK (DEPS: flutter/java/openjdk/${platform}), whose javac and jar
    # the Android embedding's build runs (shell/platform/android/BUILD.gn,
    # through build/android/gyp/javac.py). The Mac's package is a bundle
    # with the JDK under Contents/Home/ (GN's BUILD file spells the paths
    # out per host): there the repository is that directory, so that the
    # overlay's paths hold on every host.
    "openjdk": struct(
        path = "engine/src/flutter/third_party/java/openjdk",
        build_file = _OVERLAYS + ":openjdk/BUILD.openjdk.bazel",
        mac_subdir = "Contents/Home",
    ),
    # The Android embedding's compile-time dependencies (DEPS:
    # flutter/android/embedding_bundle, under download_android_deps): the
    # AndroidX jars its javac runs against.
    "android_embedding_dependencies": struct(
        path = "engine/src/flutter/third_party/android_embedding_dependencies",
        build_file = _OVERLAYS + ":android_embedding_dependencies/BUILD.android_embedding_dependencies.bazel",
    ),
    # The prebuilt Dart SDK (GN's host_prebuilt_dart_sdk): the runtime and
    # snapshots of the Dart tools the engine runs but does not build, the
    # frontend server first (build_defs/dart/kernel.bzl).
    "dart_sdk_linux_x64": struct(
        path = "engine/src/flutter/prebuilts/linux-x64/dart-sdk",
        build_file = _OVERLAYS + ":dart_sdk/BUILD.dart_sdk.bazel",
    ),
    # The Linux arm64 cross build's target SDK (GN's target_prebuilt_dart_sdk,
    # the one its dart-sdk/ and dart-sdk-linux-arm64.zip ship; the tools that
    # run at build time stay the host's, above).
    "dart_sdk_linux_arm64": struct(
        path = "engine/src/flutter/prebuilts/linux-arm64/dart-sdk",
        build_file = _OVERLAYS + ":dart_sdk/BUILD.dart_sdk.bazel",
    ),
    # The Mac's (DEPS: prebuilts/macos-<cpu>/dart-sdk, synced on a Mac of
    # that CPU): the host's, through @host_platform's HOST_DART_SDK, is
    # what the Dart rules and the tests' BUILD files name.
    "dart_sdk_macos_arm64": struct(
        path = "engine/src/flutter/prebuilts/macos-arm64/dart-sdk",
        build_file = _OVERLAYS + ":dart_sdk/BUILD.dart_sdk.bazel",
    ),
    "dart_sdk_macos_x64": struct(
        path = "engine/src/flutter/prebuilts/macos-x64/dart-sdk",
        build_file = _OVERLAYS + ":dart_sdk/BUILD.dart_sdk.bazel",
    ),
    # esbuild, which bundles the web SDK's flutter.js (build/esbuild): the
    # host's (DEPS has one per host under prebuilts/<host>/; {host_prebuilts}
    # is filled in from the machine, host_platform.bzl's HOST_PREBUILTS).
    "esbuild": struct(
        path = "engine/src/flutter/prebuilts/{host_prebuilts}/esbuild",
        build_file = _OVERLAYS + ":esbuild/BUILD.esbuild.bazel",
    ),
    # The Noto fonts the web engine's unit tests fall back to (DEPS:
    # flutter/flutter_font_fallbacks; felt lays them as assets/fallback_fonts).
    # Data, not a tool, but a CIPD package of DEPS all the same.
    "google_fonts_for_unit_tests": struct(
        path = "engine/src/flutter/third_party/google_fonts_for_unit_tests",
        build_file = _OVERLAYS + ":google_fonts_for_unit_tests/BUILD.google_fonts_for_unit_tests.bazel",
    ),
    # The hermetic Python of DEPS (engine/src/.gn's script_executable): the
    # interpreter for the Python scripts GN builds and the converted actions
    # run, so that no Bazel action reaches for depot_tools' vpython3 or the
    # machine's python3.
    "cpython3": struct(
        path = "engine/src/flutter/third_party/cpython3",
        build_file = _OVERLAYS + ":cpython3/BUILD.cpython3.bazel",
    ),
    "gn": struct(
        path = "engine/src/flutter/third_party/gn",
        build_file = _OVERLAYS + ":gn/BUILD.gn_tool.bazel",
    ),
    "ninja": struct(
        path = "third_party/ninja",
        build_file = _OVERLAYS + ":ninja/BUILD.ninja.bazel",
    ),
    # reclient (DEPS: use_rbe; the Linux x64 host's) and the engine's
    # configurations for it (flutter/build/rbe, a flutter_internal CIPD
    # package: Googlers and the bots), for a wrapped GN build whose compiles
    # go to the RBE workers (gn_build.bzl's rbe; --//engine/src/flutter/
    # build/bazel:wrap_rbe). Fetched only when that flag names them: a
    # checkout synced without use_rbe falls back to the packages, the first
    # public, the second not.
    "reclient": struct(
        path = "engine/src/flutter/buildtools/linux-x64/reclient",
        build_file = _OVERLAYS + ":reclient/BUILD.reclient.bazel",
    ),
    "reclient_cfgs": struct(
        path = "engine/src/flutter/build/rbe",
        build_file = _OVERLAYS + ":reclient/BUILD.reclient_cfgs.bazel",
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
    # The arm64 cross build's (tools/gn --target-os=linux --linux-cpu=arm64;
    # gclient's linux_sysroot_arm64 hook unpacks it).
    "sysroot_linux_arm64": struct(
        key = "bullseye_arm64",
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
    ("infra/rbe/client/linux-amd64", "re_client_version:0.185.0.db415f21-gomaip"): "003bf3eac433bd071450e97a2e6633f7f93046828c8be428a5c3938c63dd1764",
    ("flutter_internal/rbe/reclient_cfgs", "Vk7WiSKwQdBHbCrZ9PtRl3po2WpRFQZSag9M6-sxF_0C"): "564ed68922b041d0476c2ad9f4fb51977a68d96a511506526a0f4cebeb3117fd",
    # cpython3: decoded from the instance ids `cipd describe` reports for
    # DEPS' version (the rule above).
    ("infra/3pp/tools/cpython3/linux-amd64", "version:3@3.11.9.chromium.38"): "b7b8a0a6d171b8918fda51aee1d6ffeb0c8a14c791fb1d0bc5d7454c8c9d949b",
    ("infra/3pp/tools/cpython3/linux-arm64", "version:3@3.11.9.chromium.38"): "0d223051e9fd26a92010266e8508677ea832986d2a0a28015b2b809feecba17b",
    ("infra/3pp/tools/cpython3/mac-amd64", "version:3@3.11.9.chromium.38"): "4117f3d5f00e323469c420036f4a39e3fd6413959a59da26c62d7acbe25acbdd",
    ("infra/3pp/tools/cpython3/mac-arm64", "version:3@3.11.9.chromium.38"): "cfa6cee19e64c2d934ba1f68c465ce7793bb2f26430279a53be7bcea764b4621",
    ("infra/3pp/tools/cpython3/windows-amd64", "version:3@3.11.9.chromium.38"): "8c83d1aa0e044fe2023bf5e43aec12696f266f07d88962790836fc42eeeadb89",
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

def _prebuilt_engine(mctx):
    """Whether the build takes the engine from bin/cache (--config=prebuilt_engine).

    Set through --repo_env by the configuration that points the test rules
    at the prebuilt engine (flutter_bin_cache.bzl): HOST_DART_SDK, the name
    every Dart rule uses, is then the flutter tool's Dart SDK repository
    (bin/cache/dart-sdk, below) rather than the gclient-synced prebuilt's,
    so that a checkout without the engine's dependencies has one.
    """
    return mctx.getenv(PREBUILT_ENGINE_ENV, "") not in ("", "0", "false", "no")

def _cipd_pin(path):
    entry = CIPD_DEPS.get(path)
    if entry == None:
        fail("synced_deps: %s is not a CIPD dependency in DEPS (deps.lock.bzl is stale?)" % path)
    packages = entry["packages"]
    if len(packages) != 1:
        fail("synced_deps: %s installs %d CIPD packages; exactly one is supported" % (path, len(packages)))
    return packages[0]

def _download_cipd_package(name, package_template, version, platform, build_file, strip_prefix = ""):
    package = package_template.replace("${platform}", platform)
    cipd_package(
        name = name,
        package = package,
        version = version,
        sha256 = _CIPD_SHA256.get((package, version), ""),
        build_file = build_file,
        strip_prefix = strip_prefix,
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
            # The checkout's, and the same tarball when the checkout has none
            # (synced_repository's fallback: a bare checkout on the prebuilt
            # engine).
            synced_repository(
                name = name,
                path = _SYSROOTS_DIR + "/" + entry["SysrootDir"],
                build_file = spec.build_file,
                fallback_url = entry["URL"] + "/" + entry["Sha256Sum"],
                fallback_sha256 = entry["Sha256Sum"],
                fallback_type = "tar.xz",
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
            exclude = getattr(spec, "exclude", []),
            links = getattr(spec, "links", {}),
        )

    # The LTO variants of emscripten's system libraries, which the emsdk
    # repository's view links into the SDK's cache.
    emsdk_lto_libraries(
        name = "emsdk_lto",
        emsdk_path = _SOURCE_REPOSITORIES["emsdk"].path,
    )

    fetch = _fetch_toolchains(mctx)
    platform = _cipd_platform(mctx)
    host = host_platform_values(mctx.os.name, mctx.os.arch)
    for name, spec in _TOOL_REPOSITORIES.items():
        path = spec.path.format(host_prebuilts = host["HOST_PREBUILTS"])
        pin = _cipd_pin(path)

        # A package whose root is a directory inside it on a Mac (the JDK
        # bundle's Contents/Home/): the repository is that directory.
        subdir = getattr(spec, "mac_subdir", "") if host["HOST_OS"] == "mac" else ""
        if fetch:
            _download_cipd_package(name, pin["package"], pin["version"], platform, spec.build_file, strip_prefix = subdir)
        else:
            # The checkout's copy, and the CIPD package when the checkout has
            # none (synced_repository's fallback): a checkout without
            # `gclient sync` running the tests on the prebuilt engine
            # (--config=prebuilt_engine) still wants cpython3 for the pub
            # repositories and the package configurations, and the desktop
            # shard clang and the sysroots.
            package = pin["package"].replace("${platform}", platform)
            synced_repository(
                name = name,
                path = path + ("/" + subdir if subdir else ""),
                build_file = spec.build_file,
                fallback_url = cipd_download_url(package, pin["version"]),
                fallback_sha256 = _CIPD_SHA256.get((package, pin["version"]), ""),
                fallback_strip_prefix = subdir,
            )

    _sysroot_repositories(mctx, fetch)

    # The macOS SDK of the host's Xcode (macos_sdk.bzl), the macOS
    # toolchains' sysroot; an empty repository off macOS.
    macos_sdk(name = "macos_sdk")

    # The files of the machine GN names by absolute path (host_files.bzl):
    # a Mac's emoji font, for the text tests' fixtures; empty elsewhere.
    host_files(name = "host_files")

    # The flutter tool's Dart SDK, HOST_DART_SDK under --config=prebuilt_engine
    # (host_platform.bzl's BIN_CACHE_DART_SDK; fetched only when named).
    synced_repository(
        name = BIN_CACHE_DART_SDK.lstrip("@"),
        path = "bin/cache/dart-sdk",
        build_file = _TOOL_REPOSITORIES[host["HOST_DART_SDK"].lstrip("@")].build_file,
        missing_hint = "`bin/flutter precache` (the flutter tool's Dart SDK, for --config=prebuilt_engine)",
    )

    # The host itself, as constants (host_platform.bzl).
    host_platform(name = "host_platform", prebuilt_engine = _prebuilt_engine(mctx))
    return _metadata(mctx)

def _metadata(mctx):
    """The extension's metadata.

    Everything the extensions define is derived from checked-in files and
    the host platform, so nothing needs recording in MODULE.bazel.lock
    (`reproducible`). Every repository is a direct dependency of the
    engine's module, whose use_repo() lists them all (`bazel mod tidy`
    keeps the list complete); another root module that depends on the
    engine (the Fuchsia spike's, engine/src/flutter/build/bazel/toolchains/
    fuchsia) imports the few it uses, and is not held to the full list.
    """
    root = mctx.modules[0] if mctx.modules else None
    if root != None and root.is_root and root.name == "flutter":
        return mctx.extension_metadata(
            root_module_direct_deps = "all",
            root_module_direct_dev_deps = [],
            reproducible = True,
        )
    return mctx.extension_metadata(reproducible = True)

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
    return _metadata(mctx)

engine_version = module_extension(
    implementation = _engine_version_impl,
    doc = "Exposes the version strings of shell/version/version.gni as @engine_version//:version.bzl.",
)
