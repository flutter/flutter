# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The macOS C/C++ toolchains: GN's //build/toolchain/mac:clang_arm64 and clang_x64.

One toolchain per (Mac that builds, CPU built for): the checkout's clang
for the Mac (@clang_mac_arm64 or @clang_mac_x64, buildtools/mac-<cpu>/clang,
synced on a Mac of that CPU), the macOS SDK of its Xcode (@macos_sdk, as
-isysroot), the engine's own libc++, `--target=<cpu>-apple-macos -arch
<cpu>` and -mmacosx-version-min=12.0.0 (cc_toolchain_config.bzl, os =
"mac"). A Mac of either CPU builds for either CPU, as GN's does.

Every target of a macOS toolchain is incompatible off macOS
(target_compatible_with): a wildcard build on Linux skips them without
fetching the Mac's clang, which the checkout there has not.
"""

load("@rules_cc//cc:defs.bzl", "cc_toolchain")
load(
    ":cc_toolchain_config.bzl",
    "MACOS_ARM64_COMPILE_FLAGS",
    "MACOS_ARM64_LINK_FLAGS",
    "MACOS_X64_COMPILE_FLAGS",
    "MACOS_X64_LINK_FLAGS",
    "flutter_cc_toolchain_config",
)

_CPUS = {
    "arm64": struct(
        constraint = "@platforms//cpu:aarch64",
        copts = MACOS_ARM64_COMPILE_FLAGS,
        linkopts = MACOS_ARM64_LINK_FLAGS,
        triple = "arm64-apple-macos",
        legacy_cpu = "darwin_arm64",
    ),
    "x64": struct(
        constraint = "@platforms//cpu:x86_64",
        copts = MACOS_X64_COMPILE_FLAGS,
        linkopts = MACOS_X64_LINK_FLAGS,
        triple = "x86_64-apple-macos",
        legacy_cpu = "darwin_x86_64",
    ),
}

_MACOS = ["@platforms//os:macos"]

def macos_clang_toolchain(name, exec_cpu, target_cpu, clang, sdk = "@macos_sdk//:sdk", sdk_marker = "@macos_sdk//:view", cxx_headers = ":linux_cxx_headers"):
    """Declares a macOS cc_toolchain, `name`, its `<name>_toolchain` and the files and configuration behind it.

    Args:
      name: the cc_toolchain's name (macos_arm64_clang, macos_x64_on_arm64_clang, ...).
      exec_cpu: the CPU of the Mac that runs the toolchain, "arm64" or "x64".
      target_cpu: the CPU built for, "arm64" or "x64".
      clang: the clang repository of the Mac that runs it (@clang_mac_<exec_cpu>).
      sdk: the SDK's files (directory inputs; @macos_sdk's view).
      sdk_marker: a file at the view's root, whose directory is -isysroot.
      cxx_headers: the engine's libc++ headers, which every C++ compile needs
        (-nostdinc++); the same filegroup as the Linux toolchains'.
    """
    exec = _CPUS[exec_cpu]
    target = _CPUS[target_cpu]

    native.filegroup(
        name = name + "_compiler_files",
        srcs = [
            cxx_headers,
            clang + "//:compiler_files",
            sdk,
        ],
        target_compatible_with = _MACOS,
    )
    native.filegroup(
        name = name + "_linker_files",
        srcs = [
            clang + "//:linker_files",
            sdk,
        ],
        target_compatible_with = _MACOS,
    )
    native.filegroup(
        name = name + "_all_files",
        srcs = [
            ":" + name + "_compiler_files",
            ":" + name + "_linker_files",
            clang + "//:all_files",
        ],
        target_compatible_with = _MACOS,
    )
    flutter_cc_toolchain_config(
        name = name + "_config",
        # Bazel's archive action speaks libtool on a Mac (target_libc
        # "macosx": `-static -o`), so the package's llvm-libtool-darwin
        # stands where GN runs `llvm-ar rcs`; the archives are the same
        # BSD ar with a symbol table.
        ar = clang + "//:bin/llvm-libtool-darwin",
        arch_copts = target.copts,
        arch_linkopts = target.linkopts,
        asan = select({
            "//engine/src/flutter/build/bazel:asan_enabled": True,
            "//conditions:default": False,
        }),
        clang = clang + "//:bin/clang",
        clangxx = clang + "//:bin/clang++",
        cxx_include_markers = [
            "@libcxx//:include/__config",
            "@libcxxabi//:include/cxxabi.h",
            "//engine/src/flutter/build/secondary/flutter/third_party/libcxx:config/__config_site",
        ],
        lto = select({
            "//engine/src/flutter/build/bazel:lto_enabled": True,
            "//conditions:default": False,
        }),
        objcopy = clang + "//:bin/llvm-objcopy",
        os = "mac",
        resource_include_marker = clang + "//:resource_include_marker",
        strip = clang + "//:bin/llvm-strip",
        sysroot_marker = sdk_marker,
        target_compatible_with = _MACOS,
        target_cpu = target.legacy_cpu,
        # Bazel's own link features take their Mach-O forms from this name
        # (-force_load for an alwayslink library, @loader_path rpaths).
        target_libc = "macosx",
        target_system_name = target.triple,
        toolchain_identifier = name,
    )
    cc_toolchain(
        name = name,
        all_files = ":" + name + "_all_files",
        ar_files = clang + "//:ar_files",
        compiler_files = ":" + name + "_compiler_files",
        dwp_files = ":empty",
        linker_files = ":" + name + "_linker_files",
        objcopy_files = clang + "//:objcopy_files",
        strip_files = clang + "//:strip_files",
        supports_param_files = True,
        target_compatible_with = _MACOS,
        toolchain_config = ":" + name + "_config",
        toolchain_identifier = name,
    )
    native.toolchain(
        name = name + "_toolchain",
        exec_compatible_with = _MACOS + [exec.constraint],
        target_compatible_with = _MACOS + [target.constraint],
        toolchain = ":" + name,
        toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    )
