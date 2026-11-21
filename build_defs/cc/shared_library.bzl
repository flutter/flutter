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

A library whose GN target sets `output_extension` for Linux (the Khronos
loader: `so.1`, for libvulkan.so.1, the name its clients open) has a third
file, `lib<output_name>.<extension>`, compatible with Linux alone
(`linux_output_extension`); `lib<output_name>.so` is then the other
non-Apple platforms'.

A GN target that lists a shared_library in its deps links against the
library (the iOS shell's test library, ios_test_flutter, against OCMock's
dylib). Bazel's C++ rules take no cc_binary in deps, so the macro also
declares `<name>_import`, which the converter names for such a dependency:
a cc_library over a cc_import of the platform's library (the link takes the
dylib, and it is among the dependent's runfiles) and over `interface_deps`
-- what GN hands a dependent of the shared library: its public_deps, its
public_configs and the all-dependent configs that reach it (OCMock's
`Source` include directory, ocmock_src's all_dependent_config, through
ocmock_shared), which the converter lists; a cc_import carries no headers
or include directories of its own.
"""

load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_import", "cc_library")

_APPLE = [
    "@platforms//os:ios",
    "@platforms//os:macos",
]

_LINUX = "@platforms//os:linux"

def flutter_shared_library(name, output_name, linux_output_extension = None, target_compatible_with = [], visibility = None, testonly = None, interface_deps = [], **kwargs):
    """GN's shared_library(): see the file's docstring.

    Args:
      name: GN's target name; an alias of the platform's library.
      output_name: GN's output_name, or the target's name: the library is
        lib<output_name>.so or lib<output_name>.dylib.
      linux_output_extension: GN's output_extension where the target sets
        one for Linux: the library is lib<output_name>.<extension> there.
      target_compatible_with: the target's own constraints, on top of the
        platform family each library is for.
      visibility: visibility of the alias and the libraries.
      testonly: whether the libraries are testonly.
      interface_deps: what a dependent of the library gets from it besides
        the dylib (GN's public_deps, public_configs and the all-dependent
        configs reaching it): dependencies of `<name>_import`.
      **kwargs: cc_binary's attributes (srcs, deps, copts, linkopts, ...).
    """

    # The platform's file, by the select() key it is built under.
    files = {os: "lib%s.dylib" % output_name for os in _APPLE}
    if linux_output_extension:
        files[_LINUX] = "lib%s.%s" % (output_name, linux_output_extension)
    files["//conditions:default"] = "lib%s.so" % output_name
    for file in {file: None for file in files.values()}:
        cc_binary(
            name = file,
            linkshared = True,
            target_compatible_with = select({
                key: [] if platform_file == file else ["@platforms//:incompatible"]
                for key, platform_file in files.items()
            }) + target_compatible_with,
            visibility = visibility,
            testonly = testonly,
            **kwargs
        )
    native.alias(
        name = name,
        actual = select({key: ":" + file for key, file in files.items()}),
        visibility = visibility,
        testonly = testonly,
    )
    cc_import(
        name = name + "_import_library",
        shared_library = ":" + name,
        target_compatible_with = target_compatible_with,
        visibility = ["//visibility:private"],
        testonly = testonly,
    )
    cc_library(
        name = name + "_import",
        deps = [":" + name + "_import_library"] + interface_deps,
        target_compatible_with = target_compatible_with,
        visibility = visibility,
        testonly = testonly,
    )
