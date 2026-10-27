# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""flutter_shared_library: GN's shared_library(), named as the platform names its shared libraries.

GN's `shared_library("path_ops")` is libpath_ops.so on Linux and Android
and libpath_ops.dylib on macOS and iOS: one target, a file named by the
toolchain. Bazel's `cc_binary(linkshared = True)` is named by its file, so
one target cannot be both. This macro declares the two -- `lib<output_name>.so`,
compatible off the Apple platforms, and `lib<output_name>.dylib`, compatible
on them -- with the same sources, flags and dependencies, and `name` (GN's
name) as an alias of whichever the platform builds, so dependents, the
archives' entries (`$root_out_dir/libpath_ops.dylib` on a Mac) and the
build directory see GN's file under GN's name on every platform.

The converter emits it for every shared_library():

    flutter_shared_library(
        name = "path_ops",
        srcs = [...],
        output_name = "path_ops",
        deps = [...],
    )

As GN's mac toolchain names no install name (its solink tool links with
`-o ./lib<name>.dylib` and nothing else), neither does this: a dylib's
install name is the path the link names.
"""

load("@rules_cc//cc:defs.bzl", "cc_binary")

_APPLE = [
    "@platforms//os:ios",
    "@platforms//os:macos",
]

def flutter_shared_library(name, output_name, target_compatible_with = [], visibility = None, testonly = None, **kwargs):
    """GN's shared_library(): see the file's docstring.

    Args:
      name: GN's target name; an alias of the platform's library.
      output_name: GN's output_name, or the target's name: the library is
        lib<output_name>.so or lib<output_name>.dylib.
      target_compatible_with: the target's own constraints, on top of the
        platform family each library is for.
      visibility: visibility of the alias and the libraries.
      testonly: whether the libraries are testonly.
      **kwargs: cc_binary's attributes (srcs, deps, copts, linkopts, ...).
    """
    files = {
        "lib%s.so" % output_name: False,
        "lib%s.dylib" % output_name: True,
    }
    for file, apple in files.items():
        cc_binary(
            name = file,
            linkshared = True,
            target_compatible_with = select({
                os: [] if apple else ["@platforms//:incompatible"]
                for os in _APPLE
            } | {
                "//conditions:default": ["@platforms//:incompatible"] if apple else [],
            }) + target_compatible_with,
            visibility = visibility,
            testonly = testonly,
            **kwargs
        )
    native.alias(
        name = name,
        actual = select({
            os: ":lib%s.dylib" % output_name
            for os in _APPLE
        } | {
            "//conditions:default": ":lib%s.so" % output_name,
        }),
        visibility = visibility,
        testonly = testonly,
    )
