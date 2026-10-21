# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Compiler options that GN attaches per target rather than per toolchain.

GN compiles first-party code with the `chromium_code` and `//flutter:config`
configs and third-party code with `no_chromium_code`. Both configs end with
`default_warning_flags`, the list of warnings every target is built with,
-Werror included. Order matters: `-Wall -Wextra` re-enable warnings that the
list turns off (`-Wno-unused-parameter`, for instance), so the list has to
follow them. Bazel puts toolchain flags before a target's `copts`, which is
why the lists below repeat DEFAULT_WARNING_FLAGS after their own flags.

The toolchain applies the same list, minus -Werror, to everything it
compiles. That copy matters for dependencies built from upstream BUILD files
(abseil, googletest), whose copts are not ours: they enable warnings GN never
does -- abseil's -Wundef, for one, fires inside libc++'s <chrono> -- so
making them fatal would break builds GN accepts. -Werror therefore comes
from the engine's own copts, i.e. it covers engine code and every overlay.

BUILD files for engine code use FLUTTER_COPTS / FLUTTER_LOCAL_DEFINES; overlay
BUILD files for third-party trees use FLUTTER_THIRD_PARTY_COPTS, plus whatever
-Wno-* flags their BUILD.gn adds after it.
"""

# `default_warning_flags` in //build/config/compiler/BUILD.gn (clang, Linux).
DEFAULT_WARNING_FLAGS = [
    # Enables.
    "-Wendif-labels",  # Weird old-style text after an #endif.
    # Disables.
    "-Wno-missing-field-initializers",  # "struct foo f = {0};"
    "-Wno-unused-parameter",  # Unused function parameters.
    "-Werror",  # Warnings as errors.
    "-Wno-unused-but-set-parameter",
    "-Wno-unused-but-set-variable",
    # Needed for compiling Skia with clang-12
    "-Wno-psabi",
    "-Wno-implicit-int-float-conversion",
    "-Wno-deprecated-copy",
    # Needed for nlohmann/json.
    "-Wno-deprecated-literal-operator",
    # Unqualified std::move is pretty common.
    "-Wno-unqualified-std-cast-call",
    # Needed by skia, imgui, swiftshader, and angle
    "-Wno-nontrivial-memcall",
    "-Wno-non-c-typedef-for-linkage",
    "-Wno-range-loop-construct",
]

# What the toolchain passes to every compile (see the module docstring).
TOOLCHAIN_WARNING_FLAGS = [flag for flag in DEFAULT_WARNING_FLAGS if flag != "-Werror"]

# `default_warning_flags` as the same file has it under `is_wasm`: the four
# the branch adds (zlib's, freetype2's, -Wno-sign-conversion) and without
# the two it adds for clang on the other platforms, which the Emscripten
# SDK's clang (20) does not know. The Emscripten toolchain passes this
# list, minus -Werror, to every compile (toolchains/emscripten).
WASM_DEFAULT_WARNING_FLAGS = [
    "-Wendif-labels",
    "-Wno-missing-field-initializers",
    "-Wno-unused-parameter",
    "-Werror",
    "-Wno-shift-negative-value",
    "-Wno-unused-function",
    "-Wno-unused-variable",
    "-Wno-sign-conversion",
    "-Wno-unused-but-set-parameter",
    "-Wno-unused-but-set-variable",
    "-Wno-psabi",
    "-Wno-implicit-int-float-conversion",
    "-Wno-deprecated-copy",
    "-Wno-deprecated-literal-operator",
    "-Wno-non-c-typedef-for-linkage",
    "-Wno-range-loop-construct",
]

# The per-target lists differ by platform where GN's configs test is_wasm:
# a select() over the converter's OS settings (build/bazel/BUILD.bazel),
# which a BUILD file's `copts = FLUTTER_COPTS + [...]` composes with. A
# Label, since the overlays of external repositories load this file too.
_NOT_WASM = Label("//engine/src/flutter/build/bazel:not_wasm")

def _by_platform(other, wasm):
    return select({
        _NOT_WASM: other,
        "//conditions:default": wasm,
    })

# //build/config/compiler:chromium_code (cflags): first-party code and the
# few third-party targets GN does not switch to no_chromium_code. Goes with
# FLUTTER_LOCAL_DEFINES. No -Wall -Wextra under is_wasm (as on Windows).
CHROMIUM_CODE_COPTS = _by_platform(
    [
        "-Wall",
        "-Wextra",
    ] + DEFAULT_WARNING_FLAGS,
    WASM_DEFAULT_WARNING_FLAGS,
)

# //build/config/compiler:chromium_code (cflags) + //flutter:config.
FLUTTER_COPTS = CHROMIUM_CODE_COPTS + [
    "-Wunreachable-code",
]

# //flutter/common/config.gni's flutter_cflags_objc and flutter_cflags_objcc:
# the Objective-C flags of the Apple embeddings and their tests (ARC, the
# selector and override checks as errors). Plain lists, since a file names
# them inside a select() branch (testing's suites under test_enable_metal),
# where a select() cannot nest: macOS's extra -fapplication-extension is
# the Apple phase's, on its platform. Nothing compiles Objective-C on the
# other platforms.
FLUTTER_CFLAGS_OBJC = [
    "-Werror=overriding-method-mismatch",
    "-Werror=undeclared-selector",
    "-fobjc-arc",
]

FLUTTER_CFLAGS_OBJCC = FLUTTER_CFLAGS_OBJC

# //build/config/compiler:chromium_code (defines).
FLUTTER_LOCAL_DEFINES = [
    "__STDC_CONSTANT_MACROS",
    "__STDC_FORMAT_MACROS",
]

# //build/config/compiler:no_chromium_code (clang): the two clang flags,
# -Wno-deprecated-non-prototype on every platform but wasm, then the
# platform's default_warning_flags.
FLUTTER_THIRD_PARTY_COPTS = _by_platform(
    [
        # TODO(zra): Remove when zlib no longer needs this.
        # https://github.com/flutter/flutter/issues/103568
        "-Wno-deprecated-non-prototype",
        "-Wno-newline-eof",
        "-Wno-typedef-redefinition",
    ] + DEFAULT_WARNING_FLAGS,
    [
        "-Wno-newline-eof",
        "-Wno-typedef-redefinition",
    ] + WASM_DEFAULT_WARNING_FLAGS,
)

# config.gni's `feature_defines_list`: the runtime mode and slimpeller as
# macros, which //flutter/common:flutter_config (converted from GN) carries to
# every engine library. GN's final `else` (FLUTTER_RUNTIME_MODE=0, an unknown
# mode) cannot happen here: the `runtime_mode` flag only takes the four.
FLUTTER_FEATURE_DEFINES = [
    "FLUTTER_RUNTIME_MODE_DEBUG=1",
    "FLUTTER_RUNTIME_MODE_PROFILE=2",
    "FLUTTER_RUNTIME_MODE_RELEASE=3",
    "FLUTTER_RUNTIME_MODE_JIT_RELEASE=4",
    "DART_LEGACY_API=[[deprecated]]",
] + select({
    "//engine/src/flutter/common:runtime_mode_debug": [
        "FLUTTER_RUNTIME_MODE=1",
        "FLUTTER_JIT_RUNTIME=1",
    ],
    "//engine/src/flutter/common:runtime_mode_profile": ["FLUTTER_RUNTIME_MODE=2"],
    "//engine/src/flutter/common:runtime_mode_release": [
        "FLUTTER_RUNTIME_MODE=3",
        "FLUTTER_RELEASE=1",
    ],
    "//engine/src/flutter/common:runtime_mode_jit_release": [
        "FLUTTER_RUNTIME_MODE=4",
        "FLUTTER_RELEASE=1",
        "FLUTTER_JIT_RUNTIME=1",
    ],
}) + select({
    "//engine/src/flutter/common:slimpeller_enabled": ["SLIMPELLER=1"],
    "//conditions:default": [],
})
