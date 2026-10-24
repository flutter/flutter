# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""gn_build: a GN build of part of the engine tree, as one Bazel action.

During the migration some subtrees keep being built by their GN rules, the
Dart SDK first of all: the engine's GN build of it is wrapped as a single
Bazel action whose products (executables, snapshots, archives of the
libraries) other Bazel targets consume like any other file.

The action (gn_build.py) assembles a GN source root in a scratch directory
from symlinks to its declared inputs -- so the GN build reads nothing else,
sandboxed or not -- then runs `gn gen` with `--root-target` pointing at a
BUILD.gn that lists what to build, and `ninja`. The inputs are the real
trees GN reads (`@dart//:build_tree`, `//engine/src/build:gn_files`, ...),
the hermetic toolchain and the `gn`, `ninja` and Python packages from DEPS
and CIPD; nothing comes from the host.

Libraries are exported as archives: for each one the action collects the
object files of the GN target's dependency closure, stopping at the other
exported targets and at `archive_boundaries` (dependencies the Bazel side
provides itself, such as ICU), and fails if two archives would contain the
same object. The `cc_library` facades that wrap the archives must therefore
mirror the GN dependencies between the exported targets.

The scratch directory is not an output. Under the default sandboxed
execution it is discarded, and every run is a full GN build; with
`--strategy=GnBuild=local` it persists in bazel-out and ninja rebuilds
incrementally, which is the mode for iterating on the wrapped sources.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//build_defs/gn:build_directory.bzl", "GnBuildInfo")

_SCRATCH_SUFFIX = ".gn"

def _tree_entries(ctx):
    """The symlink tree spec: for each `tree` target, its files and where they go."""
    entries = []
    inputs = []
    for target, gn_path in ctx.attr.tree.items():
        files = target[DefaultInfo].files.to_list()
        if not files:
            fail("gn_build: %s provides no files" % target.label)
        roots = {f.root.path: None for f in files}
        if len(roots) != 1:
            fail("gn_build: %s mixes source and generated files" % target.label)

        # Not paths.join: an empty package (repository root) must not leave a
        # trailing separator.
        base = "/".join([c for c in [files[0].root.path, target.label.workspace_root, target.label.package] if c])
        entries.append(struct(
            path = gn_path.strip("/"),
            base = base,
            files = [f.path for f in files],
        ))
        inputs.append(target[DefaultInfo].files)
    return entries, inputs

def _resources(_os_name, _inputs_size):
    # The wrapped build parallelizes on its own and should have the machine
    # to itself: Bazel runs an action that asks for more than is available
    # alone, once everything else has finished.
    return {"cpu": 256, "memory": 32768}

def _gn_build_impl(ctx):
    name = ctx.label.name
    scratch = paths.join(ctx.bin_dir.path, ctx.label.package, name + _SCRATCH_SUFFIX)
    root_target_dir = ctx.attr.root_target_dir.strip("/")

    outputs = {}
    for product, gn_path in ctx.attr.outs.items():
        if not gn_path:
            # A product the GN build does not make in this configuration
            # (analyze_snapshot for a 32-bit target): no file, an empty
            # output group.
            continue
        f = ctx.actions.declare_file(paths.join(name, product))
        outputs[f] = gn_path
    archives = {}
    for file_name, label in ctx.attr.archives.items():
        archives[ctx.actions.declare_file(paths.join(name, file_name))] = label
    compile_commands = ctx.actions.declare_file(paths.join(name, "compile_commands.json"))

    entries, tree_inputs = _tree_entries(ctx)
    entries.append(struct(
        path = root_target_dir,
        base = paths.dirname(ctx.file.build_file.path),
        files = [ctx.file.build_file.path],
    ))

    params = struct(
        scratch = scratch,
        gn = ctx.file._gn.path,
        ninja = ctx.file._ninja.path,
        python = ctx.executable._python.path,
        ar = ctx.file.ar.path,
        root_target = "//" + root_target_dir,
        ninja_target = root_target_dir + ":" + ctx.attr.ninja_target,
        gn_args = ctx.attr.gn_args,
        tree = entries,
        outputs = {f.path: gn_path for f, gn_path in outputs.items()},
        archives = {f.path: struct(label = label) for f, label in archives.items()},
        archive_boundaries = ctx.attr.archive_boundaries,
        compile_commands = compile_commands.path,
    )
    params_file = ctx.actions.declare_file(name + ".params.json")
    ctx.actions.write(params_file, json.encode_indent(params))

    all_outputs = list(outputs.keys()) + list(archives.keys()) + [compile_commands]
    ctx.actions.run(
        executable = ctx.executable._python,
        # -B: no bytecode caches next to the script.
        arguments = ["-B", ctx.file._script.path, params_file.path],
        inputs = depset([ctx.file._script, params_file, ctx.file.build_file], transitive = tree_inputs),
        tools = depset(
            [ctx.file._gn, ctx.file._ninja, ctx.file.ar],
            transitive = [ctx.attr._python_runtime[DefaultInfo].files],
        ),
        outputs = all_outputs,
        mnemonic = "GnBuild",
        progress_message = "GN build of %s" % ctx.label,
        # PATH as the strict action environment defines it (the Dart build's
        # version script looks for git, and copes without it). The variables
        # keep Python from writing bytecode next to the sources and make its
        # hashing deterministic for scripts that iterate over sets; `env`
        # adds what the wrapped build's own scripts read.
        use_default_shell_env = True,
        env = {
            "PYTHONDONTWRITEBYTECODE": "1",
            "PYTHONHASHSEED": "0",
        } | ctx.attr.env,
        # The inputs are symlinks into the checkout (synced_repository), which
        # only resolve on this machine. Results can still be cached.
        execution_requirements = {"no-remote-exec": "1"},
        resource_set = _resources,
    )

    groups = {paths.basename(f.path): depset([f]) for f in all_outputs}
    for product, gn_path in ctx.attr.outs.items():
        if not gn_path:
            groups[product] = depset()

    # Where each product sits in GN's build directory: an `outs` entry at
    # its path (out_paths), an archive where GN writes a static library
    # (obj/<its directory>/<file>). A product that is another name for a
    # file a product of that name exports (the host's gen_snapshot_host,
    # which in the host's own build is gen_snapshot) places nothing: the
    # file is placed once, under its own name.
    product_paths = {}
    for f, gn_path in outputs.items():
        product = paths.basename(f.path)
        aliased = [p for p, path in ctx.attr.outs.items() if path == gn_path and p != product]
        if aliased and product != paths.basename(gn_path):
            continue
        product_paths[product] = gn_path
    for f, label in archives.items():
        product_paths[paths.basename(f.path)] = paths.join("obj", label.split(":")[0].lstrip("/"), f.basename)
    return [
        DefaultInfo(files = depset(all_outputs)),
        OutputGroupInfo(**groups),
        # For build_directory_aspect: a product's filegroup (below) places
        # its file where GN's build directory has it.
        GnBuildInfo(paths = product_paths),
    ]

_gn_build = rule(
    implementation = _gn_build_impl,
    doc = "Runs a GN build of one root target and exports some of its products. Use the gn_build macro.",
    attrs = {
        "build_file": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The BUILD.gn of the root target; placed at `root_target_dir` in the GN source root.",
        ),
        "root_target_dir": attr.string(
            mandatory = True,
            doc = "Where `build_file` sits in the GN source root, for example `flutter/build/bazel/dart_wrap`.",
        ),
        "ninja_target": attr.string(
            mandatory = True,
            doc = "Name of the target in `build_file` to build.",
        ),
        "tree": attr.label_keyed_string_dict(
            allow_files = True,
            mandatory = True,
            doc = "The GN source root: targets providing files, mapped to the path under the root " +
                  "where the target's package directory appears (`\"\"` for the root itself).",
        ),
        "gn_args": attr.string_dict(
            doc = "Contents of args.gn; values are GN literals (`true`, `\"linux\"`, `3`).",
        ),
        "outs": attr.string_dict(
            doc = "Build products to export: the product's name (a file name under the target's " +
                  "directory, and its output group) to its path relative to the GN build directory. " +
                  "Two products may name one path (the host's gen_snapshot is the tool and the " +
                  "shipped binary in the host's own build, two files in a cross build); an empty " +
                  "path is a product the build does not make in this configuration (analyze_snapshot " +
                  "for a 32-bit target), whose output group is empty.",
        ),
        "archives": attr.string_dict(
            doc = "Archives to produce: file name to the GN label of the library target whose " +
                  "object closure it contains.",
        ),
        "archive_boundaries": attr.string_list(
            doc = "GN label prefixes whose targets are never archived (a Bazel dependency " +
                  "provides them).",
        ),
        "ar": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The archiver, from the same toolchain as the GN build.",
        ),
        "env": attr.string_dict(
            doc = "Environment variables for the wrapped build, besides PATH and Python's: what " +
                  "its scripts read (ANGLE's commit id, for one).",
        ),
        "_script": attr.label(
            default = ":gn_build.py",
            allow_single_file = True,
        ),
        "_python": attr.label(
            default = "@cpython3//:bin/python3",
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_python_runtime": attr.label(default = "@cpython3//:runtime"),
        "_gn": attr.label(default = "@gn//:gn", allow_single_file = True),
        "_ninja": attr.label(default = "@ninja//:ninja", allow_single_file = True),
    },
)

def gn_build(name, outs = [], out_paths = None, archives = {}, visibility = None, **kwargs):
    """A GN build of one root target, with its products as targets of this package.

    Besides the `name` target (all products), each product is available as
    `:<name>`: `:gen_snapshot` for an `outs` entry `gen_snapshot`,
    `:libdart_jit.a` for an `archives` key, plus `:compile_commands.json`.

    Args:
      name: name of the build target.
      outs: the products to export, by name -- a base name, the file's under
        the target's directory and its target in this package -- each a file
        of that name under the GN build directory unless `out_paths` says
        where it is.
      out_paths: the products' paths under the GN build directory when they
        differ from their names or depend on the configuration (a dict of
        name to path, or a select() over the platforms of such dicts: a
        cross build's host tools under clang_x64/, a manifest GN writes under
        vulkan-data/). A product `out_paths` does not name is at its own
        name; one it maps to the empty path is not made in that
        configuration (its target is empty).
      archives: archive file name -> GN library label (see the module docstring).
      visibility: visibility of the build target and the product targets.
      **kwargs: the attributes of the underlying rule (`build_file`, `root_target_dir`,
        `ninja_target`, `tree`, `gn_args`, `archive_boundaries`, `ar`, `env`).
    """
    for out in outs:
        if "/" in out:
            fail(("gn_build(%s): a product is named by its base name and reached as :%s; " +
                  "a product at another path under the GN build directory is named in outs " +
                  "and placed in out_paths: %s") % (name, paths.basename(out), out))
    paths_by_name = {out: out for out in outs}
    if out_paths != None:
        paths_by_name = paths_by_name | out_paths
    _gn_build(
        name = name,
        outs = paths_by_name,
        archives = archives,
        visibility = visibility,
        **kwargs
    )
    products = list(outs) + list(archives.keys()) + ["compile_commands.json"]
    if len(products) != len({p: None for p in products}):
        fail("gn_build(%s): product base names must be unique: %s" % (name, products))
    for product in products:
        native.filegroup(
            name = product,
            srcs = [":" + name],
            output_group = product,
            visibility = visibility,
        )
