# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""`bazel run` targets that lay a build's files into GN's build directory.

What consumes an engine build reads a directory laid out as GN's
`engine/src/out/<build>/` is: the flutter tool's `--local-engine` reads
`flutter_tester`, `gen_snapshot`, `icudtl.dat`, `dart-sdk/`,
`flutter_patched_sdk/`, `gen/flutter/lib/snapshot/`, `flutter_linux/` and
the rest from there, and CI's uploader reads the archives from its
`zip_archives/`. Under Bazel each of those is an output under its own
package in bazel-bin; install copies a chosen set of them to where the
consumers look -- `engine/src/out/<variant>/<path>`, `<variant>` being GN's
name for the configuration's build directory (host_debug_unopt,
host_release, ...; checkout_view.bzl) -- or to a directory named on the
command line. The copies land in the checkout (BUILD_WORKSPACE_DIRECTORY),
outside Bazel's output tree, as GN's would; the rule's own output is the
script that copies.

    bazel run //engine/src/flutter:install
    bazel run //engine/src/flutter:install -- engine/src/out/host_debug_unopt_bazel
    bazel run -c opt --//engine/src/flutter/common:runtime_mode=release \\
        //engine/src/flutter:install_host_release_archives

`files` maps a target to the directory under the build directory that holds
its files by base name (`` for the build directory itself, `gen`,
`flutter_patched_sdk`); `trees` are zip_tree targets, whose files go at
their paths under the tree's destination (`dart-sdk/bin/dart`); `archives`
are zip_bundle targets, whose archives go under `zip_archives/` at the path
the bundle names.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load(":checkout_view.bzl", "ENGINE_SRC", "build_directory_attrs", "build_directory_variant")
load(":zip_bundle.bzl", "ZipTreeInfo")

def _install_impl(ctx):
    entries = []
    for target, directory in ctx.attr.files.items():
        directory = directory.strip("/")
        for file in target[DefaultInfo].files.to_list():
            entries.append((file, paths.join(directory, file.basename) if directory else file.basename))
    for target in ctx.attr.trees:
        entries.extend(target[ZipTreeInfo].entries)
    for target in ctx.attr.archives:
        for file in target[DefaultInfo].files.to_list():
            marker = "/zip_archives/"
            if marker not in file.short_path:
                fail("%s: %s is not an archive under zip_archives/" % (ctx.label, file.short_path))
            entries.append((file, "zip_archives/" + file.short_path.split(marker, 1)[1]))
    seen = {}
    for file, path in entries:
        if path in seen and seen[path] != file:
            fail("%s: %s and %s both install as %s" % (ctx.label, seen[path].short_path, file.short_path, path))
        seen[path] = file

    lines = [
        "#!/bin/sh",
        "set -e",
        'root="${BUILD_WORKSPACE_DIRECTORY:?%s runs under bazel run}"' % ctx.label.name,
        'dest="${1:-%s/out/%s}"' % (ENGINE_SRC, build_directory_variant(ctx)),
        'case "$dest" in /*) ;; *) dest="$root/$dest" ;; esac',
    ]
    directories = {paths.dirname(path): None for _, path in entries}
    for directory in sorted(directories.keys()):
        lines.append('mkdir -p "$dest/%s"' % directory if directory else 'mkdir -p "$dest"')
    for file, path in entries:
        # -f: a copy of a read-only output (Bazel's are) is read-only, and
        # the next install replaces it.
        lines.append('cp -f "%s" "$dest/%s"' % (file.short_path, path))
    lines.append('echo "%d files into $dest"' % len(entries))
    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(script, "\n".join(lines) + "\n", is_executable = True)
    return [DefaultInfo(
        executable = script,
        runfiles = ctx.runfiles(files = [file for file, _ in entries]),
    )]

_install = rule(
    implementation = _install_impl,
    executable = True,
    attrs = {
        "files": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "Targets mapped to the directory under the build directory that holds their " +
                  "files by base name (``, `gen`, `flutter_patched_sdk`).",
        ),
        "trees": attr.label_list(
            providers = [ZipTreeInfo],
            doc = "zip_tree targets whose files go at their paths under the tree's destination.",
        ),
        "archives": attr.label_list(
            allow_files = [".zip"],
            doc = "zip_bundle targets whose archives go under zip_archives/.",
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

def install(name, files = {}, trees = [], archives = [], **kwargs):
    """A `bazel run` target copying a build's files into engine/src/out/<variant>/ (or a named directory).

    Args:
      name: the target's name.
      files: targets mapped to the directory under the build directory that holds their files.
      trees: zip_tree targets.
      archives: zip_bundle targets.
      **kwargs: the rule's other arguments (visibility, tags).
    """
    _install(
        name = name,
        files = files,
        trees = trees,
        archives = archives,
        **(build_directory_attrs() | kwargs)
    )
