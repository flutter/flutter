# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The GN arguments a wrapped GN build (gn_build) takes for a macOS or an iOS target.

What tools/gn writes to args.gn on a Mac -- setup_apple_sdks: the deployment
target, no simulator -- and the SDK, platform and toolchain paths of the
host's Xcode from @macos_sdk, which build/config/darwin/darwin_sdk.gni would
otherwise ask xcrun for (build/mac/darwin_sdk.py): the same Xcode either way,
named here so that the action's key carries it. The Dart wrap
(engine/src/flutter/build/bazel/dart_wrap) and the GPU test backends' wrap
(build/bazel/gl_wrap) select these for the macOS platforms.

For an iOS target (tools/gn --ios [--simulator]) the same Xcode's iPhoneOS
and iPhoneSimulator SDKs and platforms besides (setup_apple_sdks names all
four; darwin_sdk.gni picks the environment's by use_ios_simulator), and the
Mac's SDK and toolchain still, for the host's own tools; the environment's
two flags come from the platform's constraint (IOS_SIMULATOR_GN_ARGS,
IOS_DEVICE_GN_ARGS).
"""

load(
    "@macos_sdk//:sdk.bzl",
    "IPHONEOS_PLATFORM_PATH",
    "IPHONEOS_SDK_PATH",
    "IPHONESIMULATOR_PLATFORM_PATH",
    "IPHONESIMULATOR_SDK_PATH",
    "MACOS_PLATFORM_PATH",
    "MACOS_SDK_PATH",
    "XCODE_DEVELOPER_DIR",
)
load("//build_defs/cc:apple.bzl", "MACOS_DEPLOYMENT_TARGET")

_XCODE_ARGS = {
    "mac_deployment_target": '"%s"' % MACOS_DEPLOYMENT_TARGET,
    "mac_host_toolchain_path": '"%s/Toolchains/XcodeDefault.xctoolchain"' % XCODE_DEVELOPER_DIR,
    "mac_platform_path": '"%s"' % MACOS_PLATFORM_PATH,
    "mac_sdk_path": '"%s"' % MACOS_SDK_PATH,
}

MACOS_TARGET_GN_ARGS = _XCODE_ARGS | {
    "ios_use_simulator": "false",
    "target_os": '"mac"',
    "use_ios_simulator": "false",
}

IOS_TARGET_GN_ARGS = _XCODE_ARGS | {
    "ios_device_platform_path": '"%s"' % IPHONEOS_PLATFORM_PATH,
    "ios_device_sdk_path": '"%s"' % IPHONEOS_SDK_PATH,
    "ios_simulator_platform_path": '"%s"' % IPHONESIMULATOR_PLATFORM_PATH,
    "ios_simulator_sdk_path": '"%s"' % IPHONESIMULATOR_SDK_PATH,
    "target_os": '"ios"',
}

# tools/gn's use_ios_simulator (--simulator) and Skia's alias of it, per
# environment (build/bazel:ios_environment).
IOS_SIMULATOR_GN_ARGS = {
    "ios_use_simulator": "true",
    "use_ios_simulator": "true",
}

IOS_DEVICE_GN_ARGS = {
    "ios_use_simulator": "false",
    "use_ios_simulator": "false",
}
