# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""`bazel run` targets that lay the archives into GN's build directory.

The archives CI uploads are read from `engine/src/out/<build>/zip_archives/`
(the `archives` entries of ci/builders/*.json name paths there). Under Bazel
each converted zip_bundle writes its archive under its own package in
bazel-bin; install_archives copies a set of them to where the uploader
looks: `engine/src/out/<variant>/zip_archives/<path>`, `<variant>` being
GN's name for the configuration's build directory (host_debug_unopt,
host_release, ...; checkout_view.bzl) and `<path>` the archive's path under
its package's zip_archives/ (`linux-x64/artifacts.zip`). The copies land in
the checkout (BUILD_WORKSPACE_DIRECTORY), outside Bazel's output tree, as
GN's would; the rule's own output is the script that copies.

    bazel run //engine/src/flutter:install_host_debug_archives
    bazel run -c opt --//engine/src/flutter/common:runtime_mode=release \\
        //engine/src/flutter:install_host_release_archives
"""

load(":checkout_view.bzl", "ENGINE_SRC", "build_directory_attrs", "build_directory_variant")

def _install_archives_impl(ctx):
    variant = build_directory_variant(ctx)
    lines = [
        "#!/bin/sh",
        "set -e",
        'root="${BUILD_WORKSPACE_DIRECTORY:?install_archives runs under bazel run}"',
        'dest="$root/%s/out/%s/zip_archives"' % (ENGINE_SRC, variant),
    ]
    files = []
    for target in ctx.attr.archives:
        for file in target[DefaultInfo].files.to_list():
            marker = "/zip_archives/"
            if marker not in file.short_path:
                fail("%s: %s is not an archive under zip_archives/" % (ctx.label, file.short_path))
            path = file.short_path.split(marker, 1)[1]
            directory = path.rsplit("/", 1)[0] if "/" in path else ""
            lines.append('mkdir -p "$dest/%s"' % directory)
            lines.append('cp -f "%s" "$dest/%s"' % (file.short_path, path))
            lines.append('echo "$dest/%s"' % path)
            files.append(file)
    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(script, "\n".join(lines) + "\n", is_executable = True)
    return [DefaultInfo(executable = script, runfiles = ctx.runfiles(files = files))]

_install_archives = rule(
    implementation = _install_archives_impl,
    executable = True,
    attrs = {
        "archives": attr.label_list(
            allow_files = [".zip"],
            mandatory = True,
            doc = "zip_bundle targets whose archives to install.",
        ),
        "build_directory_name": attr.string(
            mandatory = True,
            doc = "GN's name for the build directory in this mode (host_debug, host_release, ...).",
        ),
        "optimized": attr.bool(
            doc = "Whether this is an optimized build; GN's name carries _unopt otherwise.",
        ),
    },
)

def install_archives(name, archives, **kwargs):
    """A `bazel run` target copying `archives` into engine/src/out/<variant>/zip_archives/.

    Args:
      name: the target's name.
      archives: zip_bundle targets.
      **kwargs: the rule's other arguments (visibility, tags).
    """
    _install_archives(
        name = name,
        archives = archives,
        **(build_directory_attrs() | kwargs)
    )
