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
script's own directory, under the synced Python (@cpython3) or bash, with
GN's build directory for the mode holding `build_directory`'s files.
`{variant}` in `script_args` is the build directory's name
(`host_debug_unopt`), what run_tests.py passes as `--variant`;
`{build_directory}` its path and `{engine_src}` the view's engine/src.

A step that reads the checkout as a whole -- tools/gn's unit tests, which
ask git for the engine's, Skia's and Dart's revisions and run the
content-aware hash; ci/ban_generated_plugin_registrant_java.sh, which walks
the tree -- runs `in_checkout`: no view, the script's directory in the
source tree itself is the working directory, and the test is local,
unsandboxed and external (not cached: its inputs are not declared), as the
plan's wrappers over whole-checkout checks are.
"""

load(
    "//engine/src/flutter/build/bazel:checkout_view.bzl",
    "BUILD_DIRECTORY_ATTRS",
    "build_directory_attrs",
    "build_directory_symlinks",
    "build_directory_variant",
    "checkout_view_prologue",
)
load("//engine/src/flutter/build/bazel:sanitizers.bzl", "SANITIZER_ATTRS", "sanitizer_launcher_lines")

def script_argument(argument, variant):
    """A script argument as a word of the launcher: quoted, with the placeholders expanded at run time.

    `{variant}` is the build directory's name (host_debug_unopt, what
    run_tests.py passes as --variant), `{build_directory}` its path in the
    view (FLUTTER_BUILD_DIRECTORY, as the prologue sets it) and `{engine_src}`
    the view's engine/src -- the last two bash variables of the launcher, so
    that they expand to the test's own TEST_TMPDIR.

    Args:
      argument: the argument as written in script_args.
      variant: the build directory's name.

    Returns:
      the word, single-quoted with the variables spliced in double quotes.
    """
    quoted = "'" + argument.replace("{variant}", variant).replace("'", "'\\''") + "'"
    return quoted.replace("{build_directory}", "'\"$FLUTTER_BUILD_DIRECTORY\"'").replace("{engine_src}", "'\"$tree/engine/src\"'")

def _checkout_script_test_impl(ctx):
    script = ctx.file.script
    package = ctx.label.package
    if not script.short_path.startswith(package + "/"):
        fail("%s: the script %s should be a file of this package" % (ctx.label, script.short_path))

    # The script's own directory (a subdirectory of the package for a
    # package that has none of its own: tools/gn_test.py is the root
    # package's) is the working directory and the view's writable copy.
    directory = script.short_path[:-len(script.basename) - 1]

    symlinks = {}
    build_directory = build_directory_symlinks(ctx, symlinks)
    variant = build_directory_variant(ctx)
    words = [script.basename] + [script_argument(arg, variant) for arg in ctx.attr.script_args]

    # Not `<name>.sh`: a bash script's test is named after the script, and
    # the launcher must not take the script's place in the runfiles.
    launcher = ctx.actions.declare_file(ctx.label.name + ".launcher.sh")

    # The sanitizer environment of a sanitized build (the script runs the
    # instrumented font-subset), after the prologue's cd: by $root.
    sanitizers, sanitizer_runfiles = sanitizer_launcher_lines(ctx, runfiles_root = "$root")
    if ctx.attr.in_checkout:
        if ctx.attr.build_directory:
            fail("%s: a test in the checkout has no build directory of the view" % ctx.label)

        # No view: the script's directory in the checkout itself, reached
        # through the runfiles symlink to the source file, is the working
        # directory. The test is tagged to run unsandboxed, where that
        # symlink leads to the source tree.
        prologue = """#!/bin/bash
set -euo pipefail
root="$PWD"
script="$(readlink -f "$root/{script}")"
cd "$(dirname "$script")"
export HOME="$TEST_TMPDIR/home"
mkdir -p "$HOME"
""".format(script = script.short_path)
    else:
        prologue = checkout_view_prologue(directory, build_directory)
    interpreter = {
        ".py": '"$root/%s"' % ctx.file._python.short_path,
        ".sh": "/bin/bash",
    }["." + script.extension]
    ctx.actions.write(
        output = launcher,
        content = prologue + "".join([line + "\n" for line in sanitizers]) + """
export PYTHONDONTWRITEBYTECODE=1
exec {interpreter} {words} "$@"
""".format(
            interpreter = interpreter,
            words = " ".join(words),
        ),
        is_executable = True,
    )

    runfiles = ctx.runfiles(
        files = [script] + ctx.files.srcs + ctx.files.data + [ctx.file._python],
        transitive_files = ctx.attr._python_runtime[DefaultInfo].files,
        symlinks = symlinks,
    )
    runfiles = runfiles.merge(sanitizer_runfiles)
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
            allow_single_file = [".py", ".sh"],
            mandatory = True,
            doc = "The script -- Python, run on the synced interpreter, or a bash script -- a file of this " +
                  "package (of a subdirectory of it, for a directory with no package of its own); its directory " +
                  "is the working directory.",
        ),
        "in_checkout": attr.bool(
            doc = "Run the script where it is in the checkout rather than in a view of the runfiles: for a " +
                  "step that reads the checkout as a whole (tools/gn's tests ask git for the revisions; " +
                  "ci/ban_generated_plugin_registrant_java.sh walks the tree). Such a test runs unsandboxed " +
                  "and uncached: the macro tags it local, no-sandbox and external.",
        ),
        "script_args": attr.string_list(
            doc = "The script's arguments; `{variant}` stands for the build directory's name (host_debug_unopt), " +
                  "`{build_directory}` for its path in the view, `{engine_src}` for the view's engine/src.",
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
    } | BUILD_DIRECTORY_ATTRS | SANITIZER_ATTRS,
)

def checkout_script_test(name, script, srcs = None, size = "small", in_checkout = False, tags = [], **kwargs):
    """A test script of the tree, as a CI step runs it from the script's directory.

    Declare it in the directory's own BUILD file (or the nearest package's,
    naming the script by its path there).

    Args:
      name: the target's name.
      script: the script (.py or .sh), a file of this package.
      srcs: the directory's files; every file by default.
      size: small by default.
      in_checkout: run in the checkout itself, unsandboxed and uncached
        (a step that reads the whole tree or asks git), not in a view.
      tags: the test's tags; in_checkout adds local, no-sandbox and external.
      **kwargs: script_args, data, build_directory, env, args and the test
        attributes.
    """
    if srcs == None:
        srcs = native.glob(["**"])
    if in_checkout:
        tags = tags + [t for t in ["local", "no-sandbox", "external"] if t not in tags]
    _checkout_script_test(
        name = name,
        script = script,
        srcs = srcs,
        size = size,
        in_checkout = in_checkout,
        tags = tags,
        **(build_directory_attrs() | kwargs)
    )
