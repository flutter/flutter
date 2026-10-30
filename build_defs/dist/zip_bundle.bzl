# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""GN's zip_bundle template: an archive under zip_archives/, made by build/zip.py.

//flutter/build/zip_bundle.gni packages the engine's artifacts: an action
running build/zip.py over a list of `{ source, destination }` scopes, writing
`$root_build_dir/zip_archives/<output>`, with a generated
`LICENSE.<target>.md` first in every archive that points at the engine's
license and the bundle's source directory at the engine's version.

zip_bundle does the same under Bazel: the same script, under the synced
Python (@cpython3; GN runs it under depot_tools' vpython3) through
zip_bundle.py, which hands it the files the sandbox's input symlinks name,
over the files of `files` (destination to the one file placed there -- or,
for a directory of the build directory that a target's closure fills, a
macOS framework bundle, the files placed under it at their paths below the
destination) and the trees of `trees` (zip_tree below: files at their paths
under a destination, GN's directory sources), the readme written by the
rule from the version @engine_version//:version.bzl carries, and the
archive at `zip_archives/<output>` under the package. The converter writes
the calls from GN's zip_bundle invocations (tools/gn_to_bazel:
templateMappings).

A zip_tree is a directory entry of a GN zip_bundle -- `source` a directory,
which zip.py walks -- or the GTK shell's idiom of one entry per output of a
target at its build-directory path: the files of `srcs`, each at
`<destination>/<its path relative to root>`, `root` being a directory of the
files' repository (`engine/src/flutter/impeller/compiler/shader_lib`; empty
for the repository itself, as for the prebuilt Dart SDK). zip.py walks a
directory in the filesystem's order; here the files come in Bazel's, sorted.
"""

load("@engine_version//:version.bzl", "ENGINE_VERSION")
load("//build_defs/gn:build_directory.bzl", "BuildDirectoryInfo", "build_directory_aspect", "collected_build_directory_entries", "path_under_root", "shipped_file")

ZipTreeInfo = provider(
    doc = "The entries a zip_tree contributes to an archive.",
    fields = {"entries": "A list of (file, path in the archive) pairs."},
)

ZipBundleInfo = provider(
    doc = "What a zip_bundle's archive holds, for a rule that lays the files out instead " +
          "(the tool's SDK cache unpacks the archives: local_engine.bzl's bundle_directory).",
    fields = {"entries": "A list of (file, path in the archive) pairs, the license readme first; a directory file is a directory entry."},
)

def _zip_tree_impl(ctx):
    entries = []
    for file in ctx.files.srcs:
        path = path_under_root(file, ctx.attr.root, ctx.label)
        entries.append((file, ctx.attr.destination + "/" + path if ctx.attr.destination else path))
    return [
        ZipTreeInfo(entries = entries),
        DefaultInfo(files = depset(ctx.files.srcs)),
    ]

zip_tree = rule(
    implementation = _zip_tree_impl,
    doc = "Files at their paths under a destination directory of an archive: a zip_bundle's `trees`.",
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
            doc = "The files (a filegroup over a directory, a copy's outputs).",
        ),
        "root": attr.string(
            doc = "The directory the paths are relative to, relative to the files' repository root; " +
                  "empty for the repository root itself.",
        ),
        "destination": attr.string(
            doc = "The directory in the archive the files go under; empty for the archive's root.",
        ),
    },
)

def zip_bundle_from_file(name, **kwargs):
    """zip_bundle.gni's zip_bundle_from_file: the same archive, without the license file.

    GN's template takes the entries as a list of scopes written to a file
    for zip.py and adds no LICENSE.<name>.md (zip_bundle does); the archive
    is otherwise the same.

    Args:
      name: the target's name.
      **kwargs: zip_bundle's attributes.
    """
    zip_bundle(
        name = name,
        license = False,
        **kwargs
    )

def _build_directory_tree_impl(ctx):
    # Every file the closure places under `under` in the build directory, at
    # its path below it.
    prefix = ctx.attr.under.strip("/") + "/"
    entries = []
    seen = {}
    for target in ctx.attr.srcs:
        for file, path in collected_build_directory_entries(target):
            if not path.startswith(prefix):
                continue
            if path in seen:
                if seen[path] != file:
                    fail("%s: %s is placed twice (%s, %s)" % (ctx.label, path, seen[path].short_path, file.short_path))
                continue
            seen[path] = file
            entries.append((file, ctx.attr.destination + "/" + path[len(prefix):] if ctx.attr.destination else path[len(prefix):]))
    return [
        ZipTreeInfo(entries = sorted(entries, key = lambda e: e[1])),
        DefaultInfo(files = depset([file for file, _ in entries])),
    ]

build_directory_tree = rule(
    implementation = _build_directory_tree_impl,
    doc = "A directory of GN's build directory as an archive's tree: what the srcs' dependency closure places " +
          "under it (BuildDirectoryInfo), each at its path below -- GN's " +
          "`foreach(f, filter_include(outputs, [\"$root_build_dir/<dir>/**\"])) { destination = rebase_path(f, \"$root_build_dir/<dir>\") }` " +
          "(the web SDK's archive over flutter_web_sdk).",
    attrs = {
        "srcs": attr.label_list(
            aspects = [build_directory_aspect],
            mandatory = True,
            doc = "The targets (GN's deps) whose closure places the files.",
        ),
        "under": attr.string(
            mandatory = True,
            doc = "The directory under the build directory (`flutter_web_sdk`).",
        ),
        "destination": attr.string(
            doc = "The directory in the archive the files go under; empty for the archive's root.",
        ),
    },
)

def _zip_bundle_impl(ctx):
    output = ctx.actions.declare_file("zip_archives/" + ctx.attr.output)

    # zip_bundle.gni's generated_file, byte for byte: the directory of the
    # bundle's BUILD file relative to //flutter, the license's path, both at
    # the engine's version on GitHub. The title is the generated_file's own
    # name -- the template reads `target_name` inside that block.
    package = ctx.label.package
    prefix = "engine/src/flutter/"
    if not package.startswith(prefix):
        fail("%s: a zip_bundle belongs under //engine/src/flutter" % ctx.label)
    source_path = package[len(prefix):]
    license_path = "sky/packages/sky_engine/LICENSE"
    git_url = "https://github.com/flutter/engine/tree/" + ENGINE_VERSION
    sky_engine_url = "https://storage.googleapis.com/flutter_infra_release/flutter/" + ENGINE_VERSION + "/sky_engine.zip"

    # zip.py stores a symlink as a symlink entry (a macOS framework's), and
    # every input of a sandboxed action is one; GN hands it the build
    # directory's real files. zip_bundle.py resolves each source to the file
    # it names before zip.py sees it -- except a symlink output
    # (framework.bzl's, with a relative target), which is the symlink GN's
    # archive stores.
    args = ctx.actions.args()
    args.add_all([ctx.file._wrapper, ctx.file._script])
    args.add("-o", output)
    inputs = []
    entries = []
    if ctx.attr.license:
        readme_name = "LICENSE.%s.md" % ctx.label.name
        readme = ctx.actions.declare_file(readme_name)
        ctx.actions.write(
            output = readme,
            content = "\n".join([
                "# _%s_license_md" % ctx.label.name,
                "",
                "This bundle is part of the the Flutter SDK.",
                "",
                "The source code is hosted at [flutter/engine/%s](%s/%s)." % (source_path, git_url, source_path),
                "The license for this bundle is hosted at [flutter/engine/%s](%s/%s) " % (license_path, git_url, license_path),
                "and [sky_engine.zip](%s)." % sky_engine_url,
                "",
            ]),
        )
        args.add_all(["-i", readme, readme_name])
        inputs.append(readme)
        entries.append((readme, readme_name))

    # The archive's own place, and its entries' places: ninja building GN's
    # archive target writes each input that is an output of the build into
    # the build directory on the way (`sources`: GN's `$root_out_dir/...`
    # source of an entry, as a path under the build directory), and an
    # install of the archive lays them there too.
    placed = [(output, "zip_archives/" + ctx.attr.output)]
    for destination, target in ctx.attr.files.items():
        files = target[DefaultInfo].files.to_list()
        if len(files) != 1:
            # A target of several files (an action with several build
            # outputs: the Android embedding's android_jar, flutter.jar and
            # the engine's jar): the one at the entry's GN source path
            # under the build directory (BuildDirectoryInfo).
            source = ctx.attr.sources.get(destination)
            at_source = [
                file
                for file, path in (target[BuildDirectoryInfo].entries.to_list() if BuildDirectoryInfo in target else [])
                if path == source
            ]
            if len(at_source) != 1:
                # Or a directory of the build directory that the target's
                # closure fills (a macOS framework bundle: the copies under
                # Versions/A and the symlinks beside them, framework.bzl),
                # which zip.py would walk: every file placed under it, at
                # its path below the destination.
                under = [
                    (file, path[len(source) + 1:])
                    for file, path in collected_build_directory_entries(target)
                    if source and path.startswith(source + "/")
                ] if not at_source else []
                if not under:
                    fail("%s: %s should be one file for %s, or place one at %s (or files under it); has %s" % (ctx.label, target.label, destination, source, files))
                for file, path in sorted(under, key = lambda e: e[1]):
                    args.add_all(["-i", file, destination + "/" + path], expand_directories = False)
                    inputs.append(file)
                    entries.append((file, destination + "/" + path))
                continue
            files = at_source

        # An executable or shared library goes in as GN's link tool leaves
        # it in the build root: stripped (build_directory.bzl).
        file = shipped_file(target, files[0])

        # A directory (the javadoc tree) goes to zip.py as itself, which
        # walks it, not as its files.
        args.add_all(["-i", file, destination], expand_directories = False)
        inputs.append(file)
        entries.append((file, destination))
        if destination in ctx.attr.sources:
            placed.append((file, ctx.attr.sources[destination]))
    for tree in ctx.attr.trees:
        for file, destination in tree[ZipTreeInfo].entries:
            # A directory among a tree's entries (a build_directory_tree
            # over an action's directory output: the sky_engine package
            # copied for release) goes to zip.py as itself, as above.
            args.add_all(["-i", file, destination], expand_directories = False)
            inputs.append(file)
            entries.append((file, destination))

    ctx.actions.run(
        executable = ctx.executable._python,
        arguments = [args],
        inputs = depset(
            inputs + [ctx.file._wrapper, ctx.file._script],
            transitive = [ctx.attr._python_runtime[DefaultInfo].files],
        ),
        outputs = [output],
        env = {"PYTHONDONTWRITEBYTECODE": "1"},
        mnemonic = "ZipBundle",
        progress_message = "Zipping %{output}",
    )
    return [
        DefaultInfo(files = depset([output])),
        BuildDirectoryInfo(entries = depset(placed)),
        ZipBundleInfo(entries = entries),
    ]

zip_bundle = rule(
    implementation = _zip_bundle_impl,
    doc = "GN's zip_bundle: `zip_archives/<output>` made by build/zip.py from `files`, LICENSE.<name>.md first.",
    attrs = {
        "output": attr.string(
            mandatory = True,
            doc = "The archive's path under zip_archives/ (`linux-x64/font-subset.zip`).",
        ),
        "files": attr.string_keyed_label_dict(
            allow_files = True,
            aspects = [build_directory_aspect],
            doc = "The archive's entries: each destination path mapped to the target of the one file placed there " +
                  "(or, for a directory of the build directory that the target's closure fills, of the files under it); " +
                  "an executable or shared library is placed stripped, as GN links it.",
        ),
        "sources": attr.string_dict(
            doc = "For the entries whose GN source is an output of the build (`$root_out_dir/flutter_tester`, " +
                  "`$root_gen_dir/...`): the destination mapped to the source's path under the build directory, " +
                  "where an install lays the file as ninja's build of the archive leaves it.",
        ),
        "license": attr.bool(
            default = True,
            doc = "Whether LICENSE.<name>.md leads the archive, as zip_bundle.gni's zip_bundle has it; " +
                  "its zip_bundle_from_file writes no such file.",
        ),
        "trees": attr.label_list(
            providers = [ZipTreeInfo],
            doc = "zip_tree targets: files at their paths under a destination (GN's directory sources).",
        ),
        "deps": attr.label_list(
            aspects = [build_directory_aspect],
            doc = "GN's deps: the targets whose outputs the entries are. An install of the archive lays what " +
                  "their closure places (BuildDirectoryInfo), as ninja's build of the archive leaves every " +
                  "output of those targets in the build directory, not only the ones the archive packs.",
        ),
        "_script": attr.label(
            default = "//engine/src/flutter/build:zip.py",
            allow_single_file = True,
        ),
        "_wrapper": attr.label(
            default = "//build_defs/dist:zip_bundle.py",
            allow_single_file = True,
        ),
        "_python": attr.label(
            default = "@cpython3//:bin/python3",
            executable = True,
            cfg = "exec",
            allow_single_file = True,
        ),
        "_python_runtime": attr.label(default = "@cpython3//:runtime"),
    },
)
