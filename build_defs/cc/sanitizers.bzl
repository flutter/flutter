# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""CI's sanitizer environment around the tests of a sanitized build.

testing/run_tests.py --use-sanitizer-suppressions (the `Host_Tests` step of
the asan builder, linux_unopt.json's ci/host_debug_unopt) runs every test
with what testing/sanitizer_suppressions.sh exports: ASAN_OPTIONS with leak
detection on, LSAN/TSAN/UBSAN_OPTIONS naming the suppression lists beside the
script, and ASAN_SYMBOLIZER_PATH at the checkout's clang. Under the asan flag
(//engine/src/flutter/build/bazel:asan) the test launchers source the same
script from the runfiles, so that the options and the lists stay the
script's, and point the symbolizer at the toolchain's, which is where the
runfiles have it. Without the flag the launchers add nothing.
"""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@host_platform//:host.bzl", "HOST_CLANG")

SANITIZER_ATTRS = {
    "_asan": attr.label(
        default = "//engine/src/flutter/build/bazel:asan",
        doc = "The asan flag.",
    ),
    "_sanitizer_suppressions": attr.label(
        default = "//engine/src/flutter/testing:sanitizer_suppressions.sh",
        allow_single_file = True,
    ),
    "_sanitizer_suppression_lists": attr.label_list(
        default = [
            "//engine/src/flutter/testing:lsan_suppressions.txt",
            "//engine/src/flutter/testing:tsan_suppressions.txt",
            "//engine/src/flutter/testing:ubsan_suppressions.txt",
        ],
        allow_files = True,
    ),
    "_llvm_symbolizer": attr.label(
        # A symlink to the toolchain's multicall binary, which must come
        # along; the host's clang (@host_platform), whichever host runs the
        # tests.
        default = HOST_CLANG + "//:bin/llvm-symbolizer",
        allow_single_file = True,
    ),
    "_llvm_multicall": attr.label(
        default = HOST_CLANG + "//:bin/llvm",
        allow_single_file = True,
    ),
}

def sanitizer_launcher_lines(ctx, runfiles_root = "$PWD"):
    """The lines a test launcher runs before the test, and their runfiles.

    Args:
      ctx: the rule context, with SANITIZER_ATTRS among its attributes.
      runfiles_root: a shell expression for the runfiles directory of the
        main repository (`bazel test`'s working directory, so `$PWD` until
        the launcher changes directory).

    Returns:
      A pair: shell lines (empty unless the build is sanitized), and the
      runfiles they need.
    """
    if not ctx.attr._asan[BuildSettingInfo].value:
        return [], ctx.runfiles()
    lines = [
        "source \"%s/%s\" >/dev/null" % (runfiles_root, ctx.file._sanitizer_suppressions.short_path),
        "export ASAN_SYMBOLIZER_PATH=\"%s/%s\"" % (runfiles_root, ctx.file._llvm_symbolizer.short_path),
    ]
    runfiles = ctx.runfiles(
        files = [ctx.file._sanitizer_suppressions, ctx.file._llvm_symbolizer, ctx.file._llvm_multicall] +
                ctx.files._sanitizer_suppression_lists,
    )
    return lines, runfiles
