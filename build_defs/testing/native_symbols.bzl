# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""testing/symbols/check_forbidden_native_symbols.gni's template as a rule.

GN's `check_forbidden_native_symbols()` is a prebuilt_dart_action over one
shared library of the build directory -- the Android embedding's
libflutter.so, the embedder's libflutter_engine.so, the Linux shell's
libflutter_linux_gtk.so, the Apple frameworks' dylib as copied into the
framework -- that runs testing/symbols/check_forbidden_native_symbols.dart
with the host toolchain's llvm-nm and fails the build when the library
defines a std::format or Ryu symbol (the libc++ `<format>` ban). Its output
is a stamp, which the targets that ship the library depend on
(`:android_jar`, `:flutter_engine`, the frameworks' symlink step, ...).

The rule runs the same script on the same interpreter (the host's prebuilt
Dart SDK) with the same arguments. The library is named as the invoker
does: by its path under the build directory (`library`, GN's
`"$_out_dir/libflutter.so"`), found among the dependencies' placements
(build_directory_aspect: the stripped copy at the build root where GN's
link tool strips, the library itself where it does not), or as the first
output of a target (`library_target`, GN's `get_target_outputs(
":copy_dylib")[0]`).
"""

load("@host_platform//:host.bzl", "HOST_CLANG", "HOST_DART_SDK")
load(
    "//build_defs/gn:build_directory.bzl",
    "build_directory_aspect",
    "build_directory_path",
    "collected_build_directory_entries",
)

def _check_forbidden_native_symbols_impl(ctx):
    if (ctx.attr.library == "") == (ctx.attr.library_target == None):
        fail("%s: exactly one of library and library_target must be given" % ctx.label)
    if ctx.attr.library_target != None:
        files = ctx.files.library_target
        if not files:
            fail("%s: %s has no files" % (ctx.label, ctx.attr.library_target.label))
        library = files[0]
    else:
        path = build_directory_path(ctx.attr.library)
        if path == None:
            fail("%s: library %r is not a path under the build directory" % (ctx.label, ctx.attr.library))
        library = None
        for dep in ctx.attr.deps:
            for file, placed in collected_build_directory_entries(dep):
                if placed == path:
                    library = file
                    break
            if library != None:
                break
        if library == None:
            fail("%s: no dependency places a file at %s" % (ctx.label, path))

    nm = [f for f in ctx.files._nm if f.basename == "llvm-nm"]
    if len(nm) != 1:
        fail("%s: _nm should hold llvm-nm, holds %s" % (ctx.label, ctx.files._nm))
    dart = [f for f in ctx.files._sdk if f.basename == "dart" and f.dirname.endswith("/bin")]
    if len(dart) != 1:
        fail("%s: the SDK filegroup must hold one bin/dart, holds %s" % (ctx.label, dart))

    stamp = ctx.actions.declare_file(ctx.label.name + ".stamp")
    args = ctx.actions.args()
    args.add(ctx.file._script)
    args.add("--stamp", stamp)
    args.add("--nm", nm[0])
    args.add("--library", library)

    # GN's is_debug (`--unoptimized`: without dead-code stripping the Ryu
    # symbols are expected): Bazel's -c dbg or fastbuild, as
    # //engine/src/flutter/build/bazel:unoptimized reads them.
    if ctx.var["COMPILATION_MODE"] != "opt":
        args.add("--unoptimized")
    ctx.actions.run(
        executable = dart[0],
        arguments = [args],
        inputs = depset([ctx.file._script, library], transitive = [depset(ctx.files._sdk)]),
        tools = ctx.files._nm,
        outputs = [stamp],
        mnemonic = "CheckForbiddenNativeSymbols",
        progress_message = "Checking %{label} for forbidden native symbols",
    )
    return [DefaultInfo(files = depset([stamp]))]

check_forbidden_native_symbols = rule(
    implementation = _check_forbidden_native_symbols_impl,
    doc = "GN's check_forbidden_native_symbols(): the forbidden-symbol check of one shared library, a stamp.",
    attrs = {
        "deps": attr.label_list(
            mandatory = True,
            aspects = [build_directory_aspect],
            doc = "GN's deps: the targets that place the library in the build directory.",
        ),
        "library": attr.string(
            doc = "GN's library as a path under the build directory (`$root_out_dir/libflutter.so`).",
        ),
        "library_target": attr.label(
            allow_files = True,
            doc = "GN's library as the first output of a target (`get_target_outputs(\":copy_dylib\")[0]`).",
        ),
        "_script": attr.label(
            default = "//engine/src/flutter/testing:symbols/check_forbidden_native_symbols.dart",
            allow_single_file = True,
        ),
        "_sdk": attr.label_list(
            default = [HOST_DART_SDK + "//:dart"],
            allow_files = True,
            cfg = "exec",
            doc = "The prebuilt SDK: dart with its libraries and snapshots (GN's prebuilt_dart_action).",
        ),
        "_nm": attr.label(
            default = HOST_CLANG + "//:nm_files",
            allow_files = True,
            cfg = "exec",
            doc = "The host toolchain's llvm-nm (GN's $buildtools_path/<host>/clang/bin/llvm-nm).",
        ),
    },
)
