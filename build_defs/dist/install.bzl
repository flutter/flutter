# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""`bazel run` targets that lay a build's files into GN's build directory.

CI's recipes read a directory laid out as GN's `engine/src/out/<build>/`
is: the archives from its `zip_archives/`, a build's executables and
libraries from its root. Under Bazel each of those is an output under its
own package in bazel-bin; install copies a chosen set of them to where the
consumers look -- `engine/src/out/<variant>/<path>`, `<variant>` being GN's
name for the configuration's build directory (host_debug_unopt,
host_release, ...; checkout_view.bzl) -- or to a directory named on the
command line. The copies land in the checkout (BUILD_WORKSPACE_DIRECTORY),
outside Bazel's output tree, as GN's would; the rule's own output is the
script that copies. The installs are the builders' (ci/builders/BUILD.bazel,
one per CI build over its ninja targets); the flutter tool reads a
developer's build where Bazel built it instead, through the manifest
`local_engine` (local_engine.bzl) writes, which shares this rule's
attributes and aspect.

    bazel run --config=ci_host_release //engine/src/flutter/ci/builders:ci_host_release
    bazel run --config=ci_host_debug //engine/src/flutter/ci/builders:ci_host_debug -- engine/src/out/ci/host_debug_bazel

`contents` are targets whose dependency closure says where GN's build
directory holds its files (BuildDirectoryInfo, build_directory.bzl: copies,
actions, generated files, archives; a cc_binary's executable or shared
library at the build root, as GN puts them -- stripped, as GN's link tools
leave them, with the binary as linked under exe.unstripped/ or
lib.unstripped/); `files` maps a target to the directory
under the build directory that holds its files by base name (`` for the
build directory itself, `gen`, `flutter_patched_sdk`), for rules that do not
say; `trees` are zip_tree targets, whose files go at their paths under the
tree's destination (`dart-sdk/bin/dart`); `archives` are zip_bundle targets,
whose archives go under `zip_archives/` at the path the bundle names.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//build_defs/config:checkout_view.bzl", "ENGINE_SRC", "build_directory_attrs", "build_directory_variant")
load("//build_defs/gn:build_directory.bzl", "binary_entries", "build_directory_aspect", "collected_build_directory_entries")
load(":zip_bundle.bzl", "ZipTreeInfo")

def install_entries(ctx, contents, files, trees, archives):
    """The (file, path under the build directory) pairs an install's attributes name, each path once.

    Args:
      ctx: the rule context (for messages).
      contents: targets whose dependency closure places its files itself
        (BuildDirectoryInfo, collected by build_directory_aspect).
      files: targets mapped to the directory under the build directory that
        holds their files by base name.
      trees: zip_tree targets.
      archives: zip_bundle targets, under zip_archives/.

    Returns:
      A list of (File, path) pairs, in order, with no path twice; two files
      at one path fail.
    """
    entries = []
    for target in contents:
        entries.extend(collected_build_directory_entries(target))
    for target, directory in files.items():
        directory = directory.strip("/")

        # An executable or shared library lands as GN's link tool leaves it:
        # stripped, with the binary as linked under exe.unstripped/ or
        # lib.unstripped/ (build_directory.bzl).
        binary = binary_entries(target)
        if binary != None:
            for file, path in binary:
                entries.append((file, paths.join(directory, path) if directory else path))
            continue
        for file in target[DefaultInfo].files.to_list():
            entries.append((file, paths.join(directory, file.basename) if directory else file.basename))
    for target in trees:
        entries.extend(target[ZipTreeInfo].entries)
    for target in archives:
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
    return unique

def _install_impl(ctx):
    unique = install_entries(ctx, ctx.attr.contents, ctx.attr.files, ctx.attr.trees, ctx.attr.archives)

    lines = [
        "#!/bin/sh",
        "set -e",
        'root="${BUILD_WORKSPACE_DIRECTORY:?%s runs under bazel run}"' % ctx.label.name,
        'dest="${1:-%s/out/%s}"' % (ENGINE_SRC, ctx.attr.directory or build_directory_variant(ctx)),
        'case "$dest" in /*) ;; *) dest="$root/$dest" ;; esac',
    ]

    # What was there goes first, before any directory is made: an earlier
    # install's files, or GN's -- GN's copies are hard links of their
    # sources, and a copy onto a hard link of its own source is refused as
    # "the same file". A directory artifact replaces its whole destination
    # directory, which may also hold other entries' files (sky_engine's
    # `gen/dart-pkg`), so the removals precede every mkdir and copy.
    for file, path in unique:
        if file.is_directory or file.is_symlink:
            lines.append('rm -rf "$dest/%s"' % path)
        else:
            lines.append('rm -f "$dest/%s"' % path)
    directories = {paths.dirname(path) if not file.is_directory else path: None for file, path in unique}
    for directory in sorted(directories.keys()):
        lines.append('mkdir -p "$dest/%s"' % directory if directory else 'mkdir -p "$dest"')

    # The script copies each file from the runfiles tree, where it is
    # symlinked under a staging directory by its index in the list rather
    # than at its own short path: files of one short path from several
    # configurations -- CanvasKit's canvaskit.wasm under its three
    # platforms -- would collide at the one short path (the runfiles tree
    # has no configuration in its paths), and the install would copy the
    # last of them to all three destinations. An index rather than the
    # destination path, because a directory artifact's destination may
    # hold other entries' files (sky_engine's gen/dart-pkg), and runfiles
    # entries under a symlinked directory are dropped as obscured.
    staging = ctx.label.name + ".files"
    for index, (file, path) in enumerate(unique):
        source = "%s/%d" % (staging, index)
        if file.is_directory:
            # A directory artifact: its contents under the path. Bazel's
            # output directories are read-only, and a copy keeps the mode;
            # the next install must be able to replace what is inside, as
            # it can in GN's build directory.
            lines.append('cp -r "%s/." "$dest/%s"' % (source, path))
            lines.append('chmod -R u+w "$dest/%s"' % path)
        elif file.is_symlink:
            # A symlink output (a framework bundle's `Versions/Current ->
            # A`, framework.bzl): the link itself, with its relative target,
            # as GN's build directory has it. The runfiles entry is a link
            # to the output (absolute) -- -RP copies a link rather than what
            # it names -- or, should the runfiles tree carry the output's
            # own target instead, that target, which the install links to.
            lines.append(
                'link="$(readlink "%s")"; case "$link" in /*) cp -RP "$link" "$dest/%s" ;; *) ln -s "$link" "$dest/%s" ;; esac' %
                (source, path, path),
            )
        else:
            # -f besides the removal above, for a destination the shell
            # cannot remove but can replace.
            lines.append('cp -f "%s" "$dest/%s"' % (source, path))
    lines.append('echo "%d files into $dest"' % len(unique))
    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(script, "\n".join(lines) + "\n", is_executable = True)
    return [DefaultInfo(
        executable = script,
        runfiles = ctx.runfiles(symlinks = {"%s/%d" % (staging, index): file for index, (file, _) in enumerate(unique)}),
    )]

# The attributes naming an install's files, shared with local_engine.bzl.
INSTALL_CONTENT_ATTRS = {
    "contents": attr.label_list(
        aspects = [build_directory_aspect],
        doc = "Targets whose dependency closure places its files itself (BuildDirectoryInfo).",
    ),
    "files": attr.label_keyed_string_dict(
        allow_files = True,
        aspects = [build_directory_aspect],
        doc = "Targets mapped to the directory under the build directory that holds their " +
              "files by base name (``, `gen`, `flutter_patched_sdk`); an executable or shared library " +
              "stripped, with the binary as linked under exe.unstripped/ or lib.unstripped/ there.",
    ),
    "trees": attr.label_list(
        providers = [ZipTreeInfo],
        doc = "zip_tree targets whose files go at their paths under the tree's destination.",
    ),
    "archives": attr.label_list(
        allow_files = [".zip"],
        doc = "zip_bundle targets whose archives go under zip_archives/.",
    ),
}

_install = rule(
    implementation = _install_impl,
    executable = True,
    attrs = INSTALL_CONTENT_ATTRS | {
        "directory": attr.string(
            doc = "The build directory under engine/src/out to install into (GN's --target-dir, " +
                  "`ci/host_debug`), instead of the configuration's variant name.",
        ),
        "build_directory_name": attr.string(
            mandatory = True,
            doc = "GN's name for the build directory of this configuration, up to the mode (host_debug, host_release, wasm_release, ...).",
        ),
        "build_directory_cpu": attr.string(
            doc = "The CPU suffix of GN's name for the build directory, after _unopt (`_arm64`, or nothing).",
        ),
        "optimized": attr.bool(
            doc = "Whether this is an optimized build; GN's name carries _unopt otherwise.",
        ),
    },
)

def install(name, contents = [], files = {}, trees = [], archives = [], directory = None, **kwargs):
    """A `bazel run` target copying a build's files into engine/src/out/<variant>/ (or a named directory).

    Args:
      name: the target's name.
      contents: targets whose dependency closure places its files itself.
      files: targets mapped to the directory under the build directory that holds their files.
      trees: zip_tree targets.
      archives: zip_bundle targets.
      directory: the build directory under engine/src/out (GN's --target-dir), when not the
        configuration's variant name.
      **kwargs: the rule's other arguments (visibility, tags).
    """
    _install(
        name = name,
        contents = contents,
        files = files,
        trees = trees,
        archives = archives,
        directory = directory,
        **(build_directory_attrs() | kwargs)
    )
