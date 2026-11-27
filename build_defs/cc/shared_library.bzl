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
install name is the path the link names. That path is where dyld looks for
the library on behalf of whatever linked against it: GN's `./lib<name>.dylib`
is found by a test started in the build directory, as run_tests.py starts
them, and the path of a Bazel link (`bazel-out/<configuration>/bin/...`) by
nothing. A library that other targets of the build link against and run
with therefore names one (`apple_install_name`, from the converter's
manifest: the Khronos loader's `@rpath/libvulkan.dylib`, which a dependent's
rpaths resolve -- Bazel's to the library among its runfiles, and the one to
the binary's own directory); a GN target that sets an install name itself
(SwiftShader's driver) carries it in its link flags. ANGLE's libEGL and
libGLESv2 set none and need none: nothing links against them (libEGL opens
libGLESv2 from its own directory, a Mac's golden suite opens libGLESv2 by
name).

A library whose GN target sets `output_extension` for Linux (the Khronos
loader: `so.1`, for libvulkan.so.1, the name its clients open) has a third
file, `lib<output_name>.<extension>`, compatible with Linux alone
(`linux_output_extension`); `lib<output_name>.so` is then the other
non-Apple platforms'.

On Linux and on Android the link names the library in it, as GN's solink
tool does for every ELF library (build/toolchain/gcc_toolchain.gni:
`-Wl,-soname=` and the file's name, libflutter.so, libvulkan.so.1). A
client linked against the file by its path then records that name; without
a SONAME the linker records the path the client's link gave it, which is a
path of the build.

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

def flutter_shared_library(name, output_name, linux_output_extension = None, apple_install_name = None, target_compatible_with = [], visibility = None, testonly = None, interface_deps = [], **kwargs):
    """GN's shared_library(): see the file's docstring.

    Args:
      name: GN's target name; an alias of the platform's library.
      output_name: GN's output_name, or the target's name: the library is
        lib<output_name>.so or lib<output_name>.dylib.
      linux_output_extension: GN's output_extension where the target sets
        one for Linux: the library is lib<output_name>.<extension> there.
      apple_install_name: the dylib's install name (`@rpath/lib<name>.dylib`),
        for a library the build's own targets link against and run with;
        by default the link names none.
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
    dylib = "lib%s.dylib" % output_name
    files = {os: dylib for os in _APPLE}
    if linux_output_extension:
        files[_LINUX] = "lib%s.%s" % (output_name, linux_output_extension)
    files["//conditions:default"] = "lib%s.so" % output_name
    for file in {file: None for file in files.values()}:
        attributes = dict(kwargs)
        if apple_install_name and file == dylib:
            # The dylib's link alone: -install_name is ld64's word.
            attributes["linkopts"] = attributes.get("linkopts", []) + ["-Wl,-install_name," + apple_install_name]
        if file != dylib:
            # GN's solink tool for ELF: the library's own name as its SONAME.
            attributes["linkopts"] = attributes.get("linkopts", []) + select({
                "@platforms//os:android": ["-Wl,-soname=" + file],
                _LINUX: ["-Wl,-soname=" + file],
                "//conditions:default": [],
            })
        cc_binary(
            name = file,
            linkshared = True,
            target_compatible_with = select({
                key: [] if platform_file == file else ["@platforms//:incompatible"]
                for key, platform_file in files.items()
            }) + target_compatible_with,
            visibility = visibility,
            testonly = testonly,
            **attributes
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
