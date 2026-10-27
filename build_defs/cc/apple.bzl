# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""What the engine's Apple builds agree on, for the rules and the toolchains.

The macOS deployment target is tools/gn's mac_deployment_target (12.0.0),
which GN hands the C/C++ compiles as -mmacosx-version-min, the Swift
compiles in the target triple (build/config/darwin's compiler config) and
the wrapped GN builds as an argument: the toolchains (cc_toolchain_config.bzl,
os = "mac"), flutter_swift_library and //build_defs/gn:macos_args.bzl take
it from here.
"""

MACOS_DEPLOYMENT_TARGET = "12.0.0"
