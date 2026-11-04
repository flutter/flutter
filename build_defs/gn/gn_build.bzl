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

# The configurations of @reclient_cfgs a Linux host's wrapped build takes
# (tools/gn's rbe_cfg: rewrapper-<buildtools dir>.cfg; the recipe's bootstrap
# cfg): the proxy's, and the rewrapper's GN names.
_BOOTSTRAP_CFG = "reclient-linux.cfg"
_REWRAPPER_CFG = "rewrapper-linux-x64.cfg"

# Where the two trees sit under the GN root: buildtools' reclient (rbe.gni's
# default rbe_dir) and flutter/build/rbe (the toolchain's wrapper scripts).
RBE_TREE = {
    "@reclient//:all_files": "flutter/buildtools/linux-x64/reclient",
    "@reclient_cfgs//:all_files": "flutter/build/rbe",
}

def _tree_entries(tree):
    """The symlink tree spec: for each `tree` target, its files and where they go."""
    entries = []
    inputs = []
    for target, gn_path in tree.items():
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
    # The wrapped build parallelizes on its own (gn_build.py runs ninja with
    # a job per CPU). It is not declared as the whole machine: Bazel grants
    # a request larger than what is free only once nothing else runs
    # locally, and in a build with work to spare that moment never comes --
    # the engine's test gate had the Dart SDK's build waiting an hour behind
    # a dozen compiles, with every Dart test behind it (10-27). A wrapped
    # build is the long pole of whatever needs it, so it is declared the way
    # other wrapped builds are (rules_foreign_cc): one CPU, which is always
    # granted, and the machine is oversubscribed for the minutes it runs.
    # The memory keeps two wrapped builds from starting together on a small
    # machine (Bazel's local memory is two thirds of the host's by default).
    return {"cpu": 1, "memory": 8192}

def _gn_build_impl(ctx):
    name = ctx.label.name
    scratch = paths.join(ctx.bin_dir.path, ctx.label.package, name + _SCRATCH_SUFFIX)
    root_target_dir = ctx.attr.root_target_dir.strip("/")

    outputs = {}
    install_names = {}
    for product, gn_path in ctx.attr.outs.items():
        if not gn_path:
            # A product the GN build does not make in this configuration
            # (analyze_snapshot for a 32-bit target): no file, an empty
            # output group.
            continue
        f = ctx.actions.declare_file(paths.join(name, product))
        outputs[f] = gn_path
        if product in ctx.attr.install_names:
            install_names[f.path] = ctx.attr.install_names[product]
    if install_names and not ctx.file.install_name_tool:
        fail("%s: install_names needs install_name_tool" % ctx.label)
    archives = {}
    for file_name, label in ctx.attr.archives.items():
        archives[ctx.actions.declare_file(paths.join(name, file_name))] = label
    compile_commands = ctx.actions.declare_file(paths.join(name, "compile_commands.json"))

    entries, tree_inputs = _tree_entries(ctx.attr.tree)
    entries.append(struct(
        path = root_target_dir,
        base = paths.dirname(ctx.file.build_file.path),
        files = [ctx.file.build_file.path],
    ))

    # The compiles on the RBE workers through reclient (the wrap_rbe flag,
    # through the macro's rbe_tree): reclient and the engine's configurations
    # for it under the GN root where GN's rbe.gni and the Linux toolchain name
    # them, and for gn_build.py the proxy's binaries and configuration and
    # GN's arguments -- use_rbe, the rewrapper configuration of this host,
    # and the recipe's strategy on a bot, remote with a local fallback.
    rbe = None
    if ctx.attr.rbe_tree:
        rbe_entries, rbe_inputs = _tree_entries(ctx.attr.rbe_tree)
        entries.extend(rbe_entries)
        tree_inputs.extend(rbe_inputs)
        reclient_dir = None
        bootstrap_cfg = None
        rewrapper_cfg = None
        for entry in rbe_entries:
            for path in entry.files:
                name = paths.basename(path)
                if name == "bootstrap":
                    reclient_dir = paths.dirname(path)
                elif name == _BOOTSTRAP_CFG:
                    bootstrap_cfg = path
                elif name == _REWRAPPER_CFG:
                    rewrapper_cfg = "//" + entry.path + "/" + name
        if not reclient_dir or not bootstrap_cfg or not rewrapper_cfg:
            fail("%s: rbe_tree must hold reclient's bootstrap and the configurations %s and %s" % (
                ctx.label,
                _BOOTSTRAP_CFG,
                _REWRAPPER_CFG,
            ))
        rbe = struct(
            reclient_dir = reclient_dir,
            bootstrap_cfg = bootstrap_cfg,
            gn_args = {
                "rbe_cfg": "\"%s\"" % rewrapper_cfg,
                "rbe_exec_strategy": "\"remote_local_fallback\"",
                "use_rbe": "true",
            },
        )

    params = dict(
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
    if install_names:
        # Only where asked, so that a build without keeps its parameters
        # (and its cache entries) as they were.
        params["install_names"] = install_names
        params["install_name_tool"] = ctx.file.install_name_tool.path
    if rbe:
        params["rbe"] = rbe
    params_file = ctx.actions.declare_file(name + ".params.json")
    ctx.actions.write(params_file, json.encode_indent(struct(**params)))

    all_outputs = list(outputs.keys()) + list(archives.keys()) + [compile_commands]
    ctx.actions.run(
        executable = ctx.executable._python,
        # -B: no bytecode caches next to the script.
        arguments = ["-B", ctx.file._script.path, params_file.path],
        inputs = depset([ctx.file._script, params_file, ctx.file.build_file], transitive = tree_inputs),
        tools = depset(
            [ctx.file._gn, ctx.file._ninja, ctx.file.ar] + ctx.files.install_name_tool,
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
        "install_names": attr.string_dict(
            doc = "Products that are Mach-O dynamic libraries whose install name is rewritten on the " +
                  "copy (the product's name to the new install name): GN's mac toolchain gives a " +
                  "shared library `./lib<name>.dylib`, which dyld resolves against the working directory " +
                  "-- GN's build directory, where its tests run -- whereas Bazel runs tests from the " +
                  "runfiles root with the libraries beside the binary, which `@rpath/lib<name>.dylib` " +
                  "finds through the binary's @loader_path rpath (cc_toolchain_config.bzl's Mac link flags).",
        ),
        "install_name_tool": attr.label(
            allow_single_file = True,
            doc = "llvm-install-name-tool, from the same toolchain as the GN build; needed with install_names.",
        ),
        "env": attr.string_dict(
            doc = "Environment variables for the wrapped build, besides PATH and Python's: what " +
                  "its scripts read (ANGLE's commit id, for one).",
        ),
        "rbe_tree": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "reclient and its configurations, mapped like `tree`, when the compiles go to the " +
                  "RBE workers (RBE_TREE under the wrap_rbe flag; the gn_build macro sets it); empty otherwise.",
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
        `ninja_target`, `tree`, `gn_args`, `archive_boundaries`, `ar`, `env`,
        `install_names`, `install_name_tool`).
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
        rbe_tree = select({
            "//engine/src/flutter/build/bazel:wrap_rbe_enabled": RBE_TREE,
            "//conditions:default": {},
        }),
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
