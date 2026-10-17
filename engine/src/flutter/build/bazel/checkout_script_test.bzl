# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A Python test script of the tree, run from its directory against GN's build directory.

run_tests.py's --type font-subset is `python3 test.py --variant <build
directory>` in flutter/tools/font_subset: the script subsets the fixture
fonts with `engine/src/out/<variant>/font-subset`, compares the results with
its goldens, runs the invocations that must fail, and checks the
`zip_archives/linux-x64/font-subset.zip` the build packaged. It finds the
checkout from its own location and writes the subset fonts beside its
fixtures (gen/, ignored by git).

checkout_script_test runs such a script the same way: in a writable view of
a runfiles tree shaped like the checkout (checkout_view.bzl), from the
script's own directory, under the synced Python (@cpython3), with GN's build
directory for the mode holding `build_directory`'s files. `{variant}` in
`script_args` is the build directory's name (`host_debug_unopt`), what
run_tests.py passes as `--variant`.
"""

load(
    "//engine/src/flutter/build/bazel:checkout_view.bzl",
    "BUILD_DIRECTORY_ATTRS",
    "build_directory_attrs",
    "build_directory_symlinks",
    "build_directory_variant",
    "checkout_view_prologue",
)

def _checkout_script_test_impl(ctx):
    script = ctx.file.script
    package = ctx.label.package
    if script.short_path != package + "/" + script.basename:
        fail("%s: the script %s should be a file of this package" % (ctx.label, script.short_path))

    symlinks = {}
    build_directory = build_directory_symlinks(ctx, symlinks)
    variant = build_directory_variant(ctx)
    words = [script.basename] + [arg.replace("{variant}", variant) for arg in ctx.attr.script_args]

    launcher = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        output = launcher,
        content = checkout_view_prologue(package, build_directory) + """
export PYTHONDONTWRITEBYTECODE=1
exec "$root/{python}" {words} "$@"
""".format(
            python = ctx.file._python.short_path,
            words = " ".join(["'%s'" % word.replace("'", "'\\''") for word in words]),
        ),
        is_executable = True,
    )

    runfiles = ctx.runfiles(
        files = [script] + ctx.files.srcs + ctx.files.data + [ctx.file._python],
        transitive_files = ctx.attr._python_runtime[DefaultInfo].files,
        symlinks = symlinks,
    )
    for target in ctx.attr.data + ctx.attr.build_directory.keys():
        runfiles = runfiles.merge(target[DefaultInfo].default_runfiles)
    return [
        DefaultInfo(executable = launcher, runfiles = runfiles),
        RunEnvironmentInfo(environment = dict(ctx.attr.env)),
    ]

_checkout_script_test = rule(
    implementation = _checkout_script_test_impl,
    test = True,
    doc = "A Python test script of the tree run from its own directory, in a writable view of a checkout-shaped " +
          "runfiles tree, against GN's build directory for the mode.",
    attrs = {
        "script": attr.label(
            allow_single_file = [".py"],
            mandatory = True,
            doc = "The script, a file of this package; its directory is the working directory.",
        ),
        "script_args": attr.string_list(
            doc = "The script's arguments; `{variant}` stands for the build directory's name (host_debug_unopt).",
        ),
        "srcs": attr.label_list(
            allow_files = True,
            doc = "The files of the script's directory (its fixtures and goldens): every file by default.",
        ),
        "data": attr.label_list(
            allow_files = True,
            doc = "What else the script reads from the tree.",
        ),
        "env": attr.string_dict(
            doc = "Further environment variables for the run.",
        ),
        "_python": attr.label(
            default = "@cpython3//:bin/python3",
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_python_runtime": attr.label(default = "@cpython3//:runtime"),
    } | BUILD_DIRECTORY_ATTRS,
)

def checkout_script_test(name, script, srcs = None, size = "small", **kwargs):
    """A Python test script of the tree, as run_tests.py runs it from the script's directory.

    Declare it in the directory's own BUILD file.

    Args:
      name: the target's name.
      script: the script, a file of this package.
      srcs: the directory's files; every file by default.
      size: small by default.
      **kwargs: script_args, data, build_directory, env, args and the test
        attributes.
    """
    if srcs == None:
        srcs = native.glob(["**"])
    _checkout_script_test(
        name = name,
        script = script,
        srcs = srcs,
        size = size,
        **(build_directory_attrs() | kwargs)
    )
