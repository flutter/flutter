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
load("//build_defs/cc:apple.bzl", "IOS_DEPLOYMENT_TARGET")
load(
    ":cc_toolchain_config.bzl",
    "CXX_INCLUDE_MARKERS",
    "IOS_ARM64_COMPILE_FLAGS",
    "IOS_ARM64_LINK_FLAGS",
    "IOS_X64_COMPILE_FLAGS",
    "IOS_X64_LINK_FLAGS",
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

# iOS (build/toolchain/mac's ios_clang_arm, ios_clang_arm_sim and
# ios_clang_x64_sim): the darwin triple per CPU, and the environment --
# a device or the simulator, GN's use_ios_simulator -- which picks the SDK
# (@macos_sdk's iPhoneOS or iPhoneSimulator view), the deployment-target
# flag and the platforms' constraint (build/bazel:ios_environment).
_IOS_CPUS = {
    "arm64": struct(
        constraint = "@platforms//cpu:aarch64",
        copts = IOS_ARM64_COMPILE_FLAGS,
        linkopts = IOS_ARM64_LINK_FLAGS,
        triple = "arm64-apple-darwin",
        legacy_cpu = "ios_arm64",
    ),
    "x64": struct(
        constraint = "@platforms//cpu:x86_64",
        copts = IOS_X64_COMPILE_FLAGS,
        linkopts = IOS_X64_LINK_FLAGS,
        triple = "x86_64-apple-darwin",
        legacy_cpu = "ios_x86_64",
    ),
}

_IOS_ENVIRONMENTS = {
    "device": struct(
        constraint = "//engine/src/flutter/build/bazel:ios_device",
        sdk = "@macos_sdk//:ios_sdk",
        sdk_marker = "@macos_sdk//:ios_view",
        deployment_target_flag = "-miphoneos-version-min=",
    ),
    "simulator": struct(
        constraint = "//engine/src/flutter/build/bazel:ios_simulator",
        sdk = "@macos_sdk//:ios_simulator_sdk",
        sdk_marker = "@macos_sdk//:ios_simulator_view",
        deployment_target_flag = "-mios-simulator-version-min=",
    ),
}
_IOS = ["@platforms//os:ios"]

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
        cxx_include_markers = CXX_INCLUDE_MARKERS,
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

def ios_clang_toolchain(name, exec_cpu, target_cpu, environment, clang, cxx_headers = ":linux_cxx_headers"):
    """Declares an iOS cc_toolchain, `name`, its `<name>_toolchain` and the files and configuration behind it.

    GN's ios_clang_arm (a device, arm64), ios_clang_arm_sim and
    ios_clang_x64_sim (the simulator): the Mac's clang over the iPhoneOS or
    iPhoneSimulator SDK, with iOS's flags (cc_toolchain_config.bzl, os =
    "ios"). Every target of it is compatible with iOS alone (the target
    platform's OS, which the toolchain's own files are configured for --
    not the Mac's, which is the execution platform's: the Mac's T24), and
    the toolchain executes on a Mac alone.

    Args:
      name: the toolchain's name.
      exec_cpu: the CPU of the Mac that builds, arm64 or x64.
      target_cpu: the CPU built for, arm64 (a device or the simulator) or x64
        (the simulator).
      environment: `device` or `simulator`.
      clang: the clang repository for the Mac that builds (@clang_mac_arm64 or
        @clang_mac_x64).
      cxx_headers: the engine's C++ standard library headers.
    """
    exec = _CPUS[exec_cpu]
    target = _IOS_CPUS[target_cpu]
    env = _IOS_ENVIRONMENTS[environment]

    native.filegroup(
        name = name + "_compiler_files",
        srcs = [
            cxx_headers,
            clang + "//:compiler_files",
            env.sdk,
        ],
        target_compatible_with = _IOS,
    )
    native.filegroup(
        name = name + "_linker_files",
        srcs = [
            clang + "//:linker_files",
            env.sdk,
        ],
        target_compatible_with = _IOS,
    )
    native.filegroup(
        name = name + "_all_files",
        srcs = [
            ":" + name + "_compiler_files",
            ":" + name + "_linker_files",
            clang + "//:all_files",
        ],
        target_compatible_with = _IOS,
    )
    flutter_cc_toolchain_config(
        name = name + "_config",
        ar = clang + "//:bin/llvm-libtool-darwin",
        arch_copts = target.copts,
        arch_linkopts = target.linkopts,
        asan = select({
            "//engine/src/flutter/build/bazel:asan_enabled": True,
            "//conditions:default": False,
        }),
        clang = clang + "//:bin/clang",
        clangxx = clang + "//:bin/clang++",
        cxx_include_markers = CXX_INCLUDE_MARKERS,
        deployment_target = IOS_DEPLOYMENT_TARGET,
        deployment_target_flag = env.deployment_target_flag,
        lto = select({
            "//engine/src/flutter/build/bazel:lto_enabled": True,
            "//conditions:default": False,
        }),
        objcopy = clang + "//:bin/llvm-objcopy",
        os = "ios",
        resource_include_marker = clang + "//:resource_include_marker",
        strip = clang + "//:bin/llvm-strip",
        sysroot_marker = env.sdk_marker,
        target_compatible_with = _IOS,
        target_cpu = target.legacy_cpu,
        # The Mach-O link forms, as the macOS toolchains take them from
        # this name.
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
        target_compatible_with = _IOS,
        toolchain_config = ":" + name + "_config",
        toolchain_identifier = name,
    )
    native.toolchain(
        name = name + "_toolchain",
        exec_compatible_with = _MACOS + [exec.constraint],
        target_compatible_with = _IOS + [target.constraint, env.constraint],
        toolchain = ":" + name,
        toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    )
