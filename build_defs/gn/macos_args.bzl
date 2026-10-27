# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The GN arguments a wrapped GN build (gn_build) takes for a macOS target.

What tools/gn writes to args.gn on a Mac -- setup_apple_sdks: the deployment
target, no simulator -- and the SDK, platform and toolchain paths of the
host's Xcode from @macos_sdk, which build/config/darwin/darwin_sdk.gni would
otherwise ask xcrun for (build/mac/darwin_sdk.py): the same Xcode either way,
named here so that the action's key carries it. The Dart wrap
(engine/src/flutter/build/bazel/dart_wrap) and the GPU test backends' wrap
(build/bazel/gl_wrap) select these for the macOS platforms.
"""

load("@macos_sdk//:sdk.bzl", "MACOS_PLATFORM_PATH", "MACOS_SDK_PATH", "XCODE_DEVELOPER_DIR")

MACOS_TARGET_GN_ARGS = {
    "ios_use_simulator": "false",
    "mac_deployment_target": '"12.0.0"',
    "mac_host_toolchain_path": '"%s/Toolchains/XcodeDefault.xctoolchain"' % XCODE_DEVELOPER_DIR,
    "mac_platform_path": '"%s"' % MACOS_PLATFORM_PATH,
    "mac_sdk_path": '"%s"' % MACOS_SDK_PATH,
    "target_os": '"mac"',
    "use_ios_simulator": "false",
}
