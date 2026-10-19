# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""`bazel run` targets that lay a build's files into GN's build directory.

What consumes an engine build reads a directory laid out as GN's
`engine/src/out/<build>/` is: the flutter tool's `--local-engine` reads
`flutter_tester`, `gen_snapshot`, `icudtl.dat`, `dart-sdk/`,
`flutter_patched_sdk/`, `gen/flutter/lib/snapshot/`, `flutter_linux/`,
`gen/dart-pkg/sky_engine/` and the rest from there, and CI's uploader reads
the archives from its `zip_archives/`. Under Bazel each of those is an
output under its own package in bazel-bin; install copies a chosen set of
them to where the consumers look -- `engine/src/out/<variant>/<path>`,
`<variant>` being GN's name for the configuration's build directory
(host_debug_unopt, host_release, ...; checkout_view.bzl) -- or to a
directory named on the command line. The copies land in the checkout
(BUILD_WORKSPACE_DIRECTORY), outside Bazel's output tree, as GN's would;
the rule's own output is the script that copies.

    bazel run //engine/src/flutter:install
    bazel run //engine/src/flutter:install -- engine/src/out/host_debug_unopt_bazel
    bazel run -c opt --//engine/src/flutter/common:runtime_mode=release \\
        //engine/src/flutter:install_host_release_archives

`contents` are targets whose dependency closure says where GN's build
directory holds its files (BuildDirectoryInfo, build_directory.bzl: copies,
actions, generated files, archives); `files` maps a target to the directory
under the build directory that holds its files by base name (`` for the
build directory itself, `gen`, `flutter_patched_sdk`), for rules that do not
say; `trees` are zip_tree targets, whose files go at their paths under the
tree's destination (`dart-sdk/bin/dart`); `archives` are zip_bundle targets,
whose archives go under `zip_archives/` at the path the bundle names.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load(":build_directory.bzl", "build_directory_aspect", "collected_build_directory_entries")
load(":checkout_view.bzl", "ENGINE_SRC", "build_directory_attrs", "build_directory_variant")
load(":zip_bundle.bzl", "ZipTreeInfo")

def _install_impl(ctx):
    entries = []
    for target in ctx.attr.contents:
        entries.extend(collected_build_directory_entries(target))
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
    unique = []
    for file, path in entries:
        if path in seen:
            if seen[path] != file:
                fail("%s: %s and %s both install as %s" % (ctx.label, seen[path].short_path, file.short_path, path))
            continue
        seen[path] = file
        unique.append((file, path))

    lines = [
        "#!/bin/sh",
        "set -e",
        'root="${BUILD_WORKSPACE_DIRECTORY:?%s runs under bazel run}"' % ctx.label.name,
        'dest="${1:-%s/out/%s}"' % (ENGINE_SRC, build_directory_variant(ctx)),
        'case "$dest" in /*) ;; *) dest="$root/$dest" ;; esac',
    ]
    directories = {paths.dirname(path) if not file.is_directory else path: None for file, path in unique}
    for directory in sorted(directories.keys()):
        lines.append('mkdir -p "$dest/%s"' % directory if directory else 'mkdir -p "$dest"')
    for file, path in unique:
        if file.is_directory:
            # A directory artifact: its contents under the path. Bazel's
            # output directories are read-only, and a copy keeps the mode;
            # the next install must be able to replace what is inside, as
            # it can in GN's build directory.
            lines.append('chmod -R u+w "$dest/%s"' % path)
            lines.append('cp -rf "%s/." "$dest/%s"' % (file.short_path, path))
            lines.append('chmod -R u+w "$dest/%s"' % path)
        else:
            # -f: a copy of a read-only output (Bazel's are) is read-only, and
            # the next install replaces it.
            lines.append('cp -f "%s" "$dest/%s"' % (file.short_path, path))
    lines.append('echo "%d files into $dest"' % len(unique))
    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(script, "\n".join(lines) + "\n", is_executable = True)
    return [DefaultInfo(
        executable = script,
        runfiles = ctx.runfiles(files = [file for file, _ in unique]),
    )]

_install = rule(
    implementation = _install_impl,
    executable = True,
    attrs = {
        "contents": attr.label_list(
            aspects = [build_directory_aspect],
            doc = "Targets whose dependency closure places its files itself (BuildDirectoryInfo).",
        ),
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

def install(name, contents = [], files = {}, trees = [], archives = [], **kwargs):
    """A `bazel run` target copying a build's files into engine/src/out/<variant>/ (or a named directory).

    Args:
      name: the target's name.
      contents: targets whose dependency closure places its files itself.
      files: targets mapped to the directory under the build directory that holds their files.
      trees: zip_tree targets.
      archives: zip_bundle targets.
      **kwargs: the rule's other arguments (visibility, tags).
    """
    _install(
        name = name,
        contents = contents,
        files = files,
        trees = trees,
        archives = archives,
        **(build_directory_attrs() | kwargs)
    )
