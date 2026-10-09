# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Compiler options for the engine's own code.

The toolchain (toolchains/cc_toolchain_config.bzl) carries the flags GN gives
to every target. GN additionally compiles first-party code with the
`chromium_code` and `//flutter:config` configs; third-party code instead gets
`no_chromium_code`. These lists are the Bazel counterparts: BUILD files for
engine code use FLUTTER_COPTS / FLUTTER_LOCAL_DEFINES, BUILD files for
third-party trees do not. Warnings are only errors in engine code.
"""

# //build/config/compiler:chromium_code (cflags) + //flutter:config +
# `-Werror` from `default_warning_flags`.
FLUTTER_COPTS = [
    "-Wall",
    "-Wextra",
    "-Werror",
    "-Wunreachable-code",
]

# //build/config/compiler:chromium_code (defines).
FLUTTER_LOCAL_DEFINES = [
    "__STDC_CONSTANT_MACROS",
    "__STDC_FORMAT_MACROS",
]
