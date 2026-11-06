# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A local engine for the flutter tool without an install: a manifest over Bazel's outputs.

`flutter --local-engine <dir>` reads an engine build at the paths GN's build
directory gives its files: `flutter_tester`, `gen_snapshot`, `icudtl.dat`,
`flutter_patched_sdk/platform_strong.dill`, `gen/flutter/lib/snapshot/
isolate_snapshot.bin`, `gen/dart-pkg/sky_engine/`, `dart-sdk/`,
`libflutter_linux_gtk.so` and `flutter_linux/`, ... (its
CachedLocalEngineArtifacts). `install` (install.bzl) copies Bazel's outputs
into such a directory; local_engine writes instead, beside the outputs, a
manifest of where each of those paths' files is -- `local_engine.json`:

    {"name": "host_debug_unopt",
     "entries": {"flutter_tester": "shell/testing/flutter_tester",
                 "gen/dart-pkg/sky_engine": "local_engine/sky_engine",
                 "dart-sdk": "../../../../../../external/+synced_deps+dart_sdk_linux_x64",
                 ...}}

-- paths relative to the manifest's own directory (through `..` for another
repository's files; a consumer resolves the directory's symbolic links
first, since bazel-bin is one) -- and the tool, finding the manifest in the
directory it was given, resolves each GN path through it, by the longest
entry that is a prefix of the path. `bazel build //engine/src/flutter:local_engine`
builds every artifact and the manifest; nothing is copied out of the output
tree, and `--local-engine bazel-bin/engine/src/flutter` (or the
configuration's bazel-out/<cfg>/bin/engine/src/flutter) is the directory to
name (NEED_DECISION D15, research/16).

The entries come from the same attributes as install's (`contents`,
`files`, `trees`; install_entries). Three cases keep a GN path one
filesystem path: a zip_tree whose files all sit under one directory maps as
that directory (`dart-sdk`, the prebuilt SDK's repository); a path named in
`assemble` is built as a directory artifact from the entries under it
(`gen/dart-pkg/sky_engine`: dart_pkg's directory and the copied libraries,
one tree for package:sky_engine's root); every other entry maps to its
file, and a GN directory whose every entry sits at its relative path under
one directory of the build maps as that directory too (`flutter_patched_sdk`,
the frontend server's --sdk-root).
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//build_defs/config:checkout_view.bzl", "build_directory_attrs", "build_directory_variant")
load("//build_defs/gn:gn_action.bzl", "PYTHON_ATTRS", "run_python")
load(":install.bzl", "INSTALL_CONTENT_ATTRS", "install_entries")
load(":zip_bundle.bzl", "ZipBundleInfo", "ZipTreeInfo")

MANIFEST = "local_engine.json"

def _relative_path(target, directory):
    """`target` relative to `directory`, both relative to the execution root."""
    target_parts = [p for p in target.split("/") if p and p != "."]
    directory_parts = [p for p in directory.split("/") if p and p != "."]
    common = 0
    for i in range(min(len(target_parts), len(directory_parts))):
        if target_parts[i] != directory_parts[i]:
            break
        common += 1
    return "/".join([".."] * (len(directory_parts) - common) + target_parts[common:]) or "."

def _tree_directory(entries):
    """The one source directory a zip_tree's entries all sit under at their paths, or None.

    Entries are (file, `<destination>/<path under the tree>`); when every
    file's path ends with its path under the tree and the remainders agree,
    that remainder is the directory.
    """
    if not entries:
        return None
    destination = entries[0][1].split("/", 1)[0]
    directory = None
    for file, path in entries:
        if file.is_directory:
            return None
        parts = path.split("/", 1)
        if parts[0] != destination or len(parts) != 2:
            return None
        suffix = "/" + parts[1]
        if not file.path.endswith(suffix):
            return None
        root = file.path[:-len(suffix)]
        if directory == None:
            directory = root
        elif directory != root:
            return None
    return destination, directory

def _assemble_directory(ctx, name, placements):
    """A directory artifact `name` from `placements`: (file, source path, path under the directory) triples.

    A directory file's contents go under its path (`.` for the directory
    itself); assemble_directory.py copies.
    """
    output = ctx.actions.declare_directory(name)
    args = ctx.actions.args()
    args.add("--output", output.path)
    inputs = []
    for file, source, path in placements:
        args.add("--%s" % ("directory" if file.is_directory else "file"), "%s=%s" % (source, path))
        inputs.append(file)
    if not inputs:
        fail("%s: nothing to assemble into %s" % (ctx.label, name))
    args.set_param_file_format("multiline")
    args.use_param_file("@%s", use_always = True)
    run_python(
        ctx,
        script = ctx.file._assemble,
        arguments = [args],
        inputs = inputs,
        outputs = [output],
        mnemonic = "AssembleDirectory",
        progress_message = "Assembling %s of %s" % (name, ctx.label),
    )
    return output

def _assemble(ctx, prefix, entries):
    """A directory artifact holding what `entries` place under the GN path `prefix`."""
    placements = []
    for file, path in entries:
        if path == prefix:
            if not file.is_directory:
                fail("%s: %s is a file, not a directory to assemble" % (ctx.label, prefix))
            placements.append((file, file.path, "."))
        elif path.startswith(prefix + "/"):
            placements.append((file, file.path, path[len(prefix) + 1:]))
        elif file.is_directory and prefix.startswith(path + "/"):
            # A directory artifact holding the prefix as a subdirectory
            # (dart_pkg's gen/dart-pkg holds sky_engine/).
            placements.append((file, paths.join(file.path, prefix[len(path) + 1:]), "."))
    if not placements:
        fail("%s: nothing places files under %s" % (ctx.label, prefix))
    return _assemble_directory(ctx, paths.join(ctx.label.name, paths.basename(prefix)), placements)

def _covered(path, prefixes):
    """Whether a GN path is one of `prefixes`, under one, or (a directory artifact's) above one."""
    for prefix in prefixes:
        if path == prefix or path.startswith(prefix + "/") or prefix.startswith(path + "/"):
            return True
    return False

def _local_engine_impl(ctx):
    manifest = ctx.actions.declare_file(MANIFEST)
    directory = manifest.dirname
    mapping = {}
    outputs = [manifest]

    # The trees: one directory when the files allow, else file by file.
    trees = []
    for target in ctx.attr.trees:
        tree = _tree_directory(target[ZipTreeInfo].entries)
        if tree != None:
            destination, source = tree
            mapping[destination] = _relative_path(source, directory)
            outputs.extend([file for file, _ in target[ZipTreeInfo].entries])
        else:
            trees.append(target)

    entries = install_entries(ctx, ctx.attr.contents, ctx.attr.files, trees, [])
    for prefix in ctx.attr.assemble:
        assembled = _assemble(ctx, prefix, entries)
        mapping[prefix] = _relative_path(assembled.path, directory)
        outputs.append(assembled)
    subtrees = {}
    for file, path in entries:
        if _covered(path, ctx.attr.assemble):
            continue
        mapping[path] = _relative_path(file.path, directory)
        outputs.append(file)
        parts = path.split("/")
        for depth in range(1, len(parts)):
            subtrees.setdefault("/".join(parts[:depth]), []).append((path, mapping[path]))

    # A GN directory whose every entry under it, at any depth, sits at its
    # relative path under one directory of the build maps as that directory
    # too (flutter_patched_sdk, which the tool hands the frontend server as
    # --sdk-root). One agreeing child is not enough: gen/dart-pkg/sky_engine
    # has AUTHORS copied from the source root beside lib/ from the Dart tree,
    # and an entry for it would shadow dart_pkg's directory at gen/dart-pkg.
    for gn_directory, descendants in subtrees.items():
        if gn_directory in mapping:
            continue
        real_directories = {}
        for path, real in descendants:
            relative = path[len(gn_directory) + 1:]
            if real.endswith("/" + relative):
                real_directories[real[:-len(relative) - 1]] = None
            else:
                real_directories[None] = None
        if len(real_directories) == 1 and None not in real_directories:
            mapping[gn_directory] = real_directories.keys()[0]

    ctx.actions.write(manifest, json.encode_indent({
        "name": build_directory_variant(ctx),
        "entries": {path: mapping[path] for path in sorted(mapping.keys())},
    }, indent = "  ") + "\n")
    return [DefaultInfo(files = depset(outputs))]

_local_engine = rule(
    implementation = _local_engine_impl,
    attrs = INSTALL_CONTENT_ATTRS | PYTHON_ATTRS | {
        "assemble": attr.string_list(
            doc = "GN paths built as one directory artifact each from the entries under them " +
                  "(`gen/dart-pkg/sky_engine`), for a consumer that reads the directory.",
        ),
        "_assemble": attr.label(
            default = "//build_defs/dist:assemble_directory.py",
            allow_single_file = True,
        ),
        "build_directory_name": attr.string(mandatory = True),
        "build_directory_cpu": attr.string(),
        "optimized": attr.bool(),
    },
)

def _assembled_directory_impl(ctx):
    entries = install_entries(ctx, ctx.attr.contents, ctx.attr.files, ctx.attr.trees, ctx.attr.archives)
    return [DefaultInfo(files = depset([_assemble(ctx, ctx.attr.prefix, entries)]))]

assembled_directory = rule(
    implementation = _assembled_directory_impl,
    doc = "One directory of GN's build directory as a directory artifact, assembled from what some " +
          "targets place under it (install's content attributes): the sky_engine package for a test " +
          "that lays it under bin/cache/pkg, as local_engine assembles it for the manifest.",
    attrs = INSTALL_CONTENT_ATTRS | PYTHON_ATTRS | {
        "prefix": attr.string(
            mandatory = True,
            doc = "The GN path assembled (`gen/dart-pkg/sky_engine`).",
        ),
        "_assemble": attr.label(
            default = "//build_defs/dist:assemble_directory.py",
            allow_single_file = True,
        ),
    },
)

# What the flutter tool's cache deletes after unpacking an archive
# (Cache._denylistedBasenames): the code-signing lists a Mac's archives
# carry for the recipe (entitlements.txt, without_entitlements.txt,
# unsigned_binaries.txt), which every archive has at its root -- artifacts.zip's
# and font-subset's would otherwise collide there (the Mac's T44).
_CACHE_DENYLISTED_BASENAMES = ["entitlements.txt", "without_entitlements.txt", "unsigned_binaries.txt"]

def _bundle_directory_impl(ctx):
    placed = {}
    for bundle in ctx.attr.bundles:
        for file, path in bundle[ZipBundleInfo].entries:
            if path.rsplit("/", 1)[-1] in _CACHE_DENYLISTED_BASENAMES:
                continue

            # The same file in two archives (gen_snapshot is in a mode's
            # artifacts.zip and its desktop embedding's) lands once, as does
            # a bundle's license readme from two of its configurations (the
            # patched SDK's debug and product archives: the same text).
            if path in placed and placed[path] != file:
                if not (path.startswith("LICENSE.") and path.endswith(".md")):
                    fail("%s: %s places %s at %s, where %s already is" % (ctx.label, bundle.label, file.path, path, placed[path].path))
                continue
            placed[path] = file
    for target, path in ctx.attr.files.items():
        files = target[DefaultInfo].files.to_list()
        if len(files) != 1:
            fail("%s: files: %s should be one file" % (ctx.label, target.label))
        if path in placed:
            fail("%s: files places %s at %s, where %s already is" % (ctx.label, files[0].path, path, placed[path].path))
        placed[path] = files[0]
    placements = [(file, file.path, path) for path, file in placed.items()]
    return [DefaultInfo(files = depset([_assemble_directory(ctx, ctx.label.name, placements)]))]

bundle_directory = rule(
    implementation = _bundle_directory_impl,
    doc = "The files of some zip_bundles laid as one directory, each at its path in its archive, as " +
          "the flutter tool's cache unpacks the archives it downloads (`bin/cache/artifacts/engine/linux-x64` " +
          "is linux-x64/artifacts.zip and font-subset.zip unpacked together, less the code-signing lists " +
          "the cache deletes), and the files the cache writes beside them: the SDK cache the tests' " +
          "facsimile lays from the build instead of a download (dart_test's `cache_files`).",
    attrs = PYTHON_ATTRS | {
        "bundles": attr.label_list(
            mandatory = True,
            providers = [ZipBundleInfo],
            doc = "The zip_bundles; an entry path two of them place different files at is an error.",
        ),
        "files": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "Files the cache writes into the directory besides the archives' contents, each to its " +
                  "path there: the repository's LICENSE the tool copies into the iOS engine directories " +
                  "after unpacking (EngineCachedArtifact.updateInner, getLicenseDirs).",
        ),
        "_assemble": attr.label(
            default = "//build_defs/dist:assemble_directory.py",
            allow_single_file = True,
        ),
    },
)

def _files_directory_impl(ctx):
    prefix = ctx.attr.strip_prefix
    placements = []
    for file in ctx.files.srcs:
        path = file.short_path
        if path.startswith("../"):
            path = path.split("/", 2)[2]
        if prefix:
            if not path.startswith(prefix + "/"):
                fail("%s: %s is not under %s" % (ctx.label, path, prefix))
            path = path[len(prefix) + 1:]
        placements.append((file, file.path, path))
    if not placements:
        # An artifact set bin/cache does not hold (a profile or release
        # engine `flutter precache` was not asked for): an empty directory,
        # as the cache's would be absent.
        output = ctx.actions.declare_directory(ctx.label.name)
        args = ctx.actions.args()
        args.add(output.path)
        ctx.actions.run_shell(
            outputs = [output],
            command = "mkdir -p \"$1\"",
            arguments = [args],
            mnemonic = "AssembleDirectory",
            progress_message = "Assembling %s of %s (empty)" % (ctx.label.name, ctx.label),
        )
        return [DefaultInfo(files = depset([output]))]
    return [DefaultInfo(files = depset([_assemble_directory(ctx, ctx.label.name, placements)]))]

files_directory = rule(
    implementation = _files_directory_impl,
    doc = "Some files laid as one directory artifact, each at its path less `strip_prefix` (and less its " +
          "repository): bin/cache's engine directories under --config=prebuilt_engine on a Mac, whose " +
          "FlutterMacOS.xcframework a glob through its directory links lays flat -- assemble_directory.py " +
          "makes the bundle's links again, as it does for the tree's frameworks (bundle_directory).",
    attrs = PYTHON_ATTRS | {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
            doc = "The files; none is an empty directory.",
        ),
        "strip_prefix": attr.string(
            doc = "The directory within the files' repository the paths are taken relative to.",
        ),
        "_assemble": attr.label(
            default = "//build_defs/dist:assemble_directory.py",
            allow_single_file = True,
        ),
    },
)

def local_engine(name, contents = [], files = {}, trees = [], assemble = [], **kwargs):
    """The manifest `local_engine.json` over a build's files, for `flutter --local-engine`.

    Args:
      name: the target's name; the assembled directories go under it.
      contents: targets whose dependency closure places its files itself.
      files: targets mapped to the directory under the build directory that holds their files.
      trees: zip_tree targets.
      assemble: GN paths built as one directory each from the entries under them.
      **kwargs: the rule's other arguments (visibility, tags).
    """
    _local_engine(
        name = name,
        contents = contents,
        files = files,
        trees = trees,
        assemble = assemble,
        **(build_directory_attrs() | kwargs)
    )
