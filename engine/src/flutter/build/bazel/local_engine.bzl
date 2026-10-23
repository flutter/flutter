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
file, and a GN directory whose files all sit by the same names in one
directory of the build maps as that directory too (`flutter_patched_sdk`,
the frontend server's --sdk-root).
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//engine/src/flutter/build/bazel/gn_action:gn_action.bzl", "PYTHON_ATTRS", "run_python")
load(":checkout_view.bzl", "build_directory_attrs", "build_directory_variant")
load(":install.bzl", "INSTALL_CONTENT_ATTRS", "install_entries")
load(":zip_bundle.bzl", "ZipTreeInfo")

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

def _assemble(ctx, prefix, entries):
    """A directory artifact holding what `entries` place under the GN path `prefix`."""
    output = ctx.actions.declare_directory(paths.join(ctx.label.name, paths.basename(prefix)))
    args = ctx.actions.args()
    args.add("--output", output.path)
    inputs = []
    for file, path in entries:
        if path == prefix:
            if not file.is_directory:
                fail("%s: %s is a file, not a directory to assemble" % (ctx.label, prefix))
            args.add("--directory", "%s=." % file.path)
        elif path.startswith(prefix + "/"):
            args.add("--%s" % ("directory" if file.is_directory else "file"), "%s=%s" % (file.path, path[len(prefix) + 1:]))
        elif file.is_directory and prefix.startswith(path + "/"):
            # A directory artifact holding the prefix as a subdirectory
            # (dart_pkg's gen/dart-pkg holds sky_engine/).
            args.add("--directory", "%s=." % paths.join(file.path, prefix[len(path) + 1:]))
        else:
            continue
        inputs.append(file)
    if not inputs:
        fail("%s: nothing places files under %s" % (ctx.label, prefix))
    args.set_param_file_format("multiline")
    args.use_param_file("@%s", use_always = True)
    run_python(
        ctx,
        script = ctx.file._assemble,
        arguments = [args],
        inputs = inputs,
        outputs = [output],
        mnemonic = "AssembleDirectory",
        progress_message = "Assembling %s of %s" % (prefix, ctx.label),
    )
    return output

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
    folded = {}
    for file, path in entries:
        if _covered(path, ctx.attr.assemble):
            continue
        mapping[path] = _relative_path(file.path, directory)
        outputs.append(file)
        if not file.is_directory and "/" in path:
            folded.setdefault(paths.dirname(path), []).append((path, mapping[path]))

    # A GN directory whose files all sit, by the same names, in one directory
    # of the build maps as that directory too (flutter_patched_sdk, which the
    # tool hands the frontend server as --sdk-root).
    for gn_directory, children in folded.items():
        if gn_directory in mapping:
            continue
        real_directories = {paths.dirname(real): None for _, real in children}
        same_names = [paths.basename(path) == paths.basename(real) for path, real in children]
        if len(real_directories) == 1 and all(same_names):
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
            default = "//engine/src/flutter/build/bazel:assemble_directory.py",
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
            default = "//engine/src/flutter/build/bazel:assemble_directory.py",
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
