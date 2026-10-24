# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""GN's `action()` as a Bazel rule.

A GN action runs a Python script once, with arguments that name its inputs
and outputs as paths relative to the build directory (`rebase_path(x,
root_build_dir)`), and declares `sources`, `inputs` and `outputs`. The
converter (tools/gn_to_bazel) emits one `gn_action` per GN action and writes
the paths in the arguments as tokens this rule expands:

  $(execpath LABEL)   an input file, as Bazel's own expansion (the file must
                      be among `srcs`, `inputs`, `tools` or the outputs of
                      `deps`);
  $(src PATH)         a source directory (or file) of this repository, PATH
                      relative to the repository root -- or, as a label
                      (`@repo//:dir`), a directory of another repository;
  $(gen PATH)         a generated file or directory, PATH relative to the
                      repository root under the output directory -- where
                      GN's `$target_gen_dir` and `$root_gen_dir` land; when
                      the closure of `deps` places gen/PATH in the build
                      directory (BuildDirectoryInfo), that file -- or, for a
                      directory that several of them fill (gen/dart-pkg/
                      sky_engine: dart_pkg's package directory and the
                      libraries copied beside it), a directory assembled
                      from what they place there (stage_build_directory.py)
                      -- which the script then reads;
  $(built PATH)       the file at PATH under GN's build directory: one of the
                      action's own `build_outputs` (or `build_output_dirs`), or one that the closure
                      of its `deps` places there (BuildDirectoryInfo: another
                      action's build output, a linked shared library, its
                      lib.stripped/ copy), which the script then reads; or
                      a directory holding such a file (`.` for the build
                      directory itself), as the directory the action's own
                      build outputs are declared in.

The script runs with the checkout's hermetic Python (`@cpython3`), from the
execution root, in a sandbox that holds exactly the declared inputs: an
undeclared input GN would have tolerated is a failure here, by design.

Each rule here says where GN's build directory holds its files
(BuildDirectoryInfo, ../build_directory.bzl): an action's outputs under
gen/<package>/ (or, its `build_outputs`, at their paths under the build
directory itself), a copy's at its `outputs`, a generated file's at its
output; `install` (../install.bzl) lays them out there.
"""

load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load(
    "//build_defs/gn:build_directory.bzl",
    "BuildDirectoryInfo",
    "build_directory_aspect",
    "build_directory_path",
    "collected_build_directory_entries",
    "copy_entries",
)
load("//build_defs/web:wasm.bzl", "module_platform_transition")

def expand_gn_paths(ctx, arg, targets, placed = {}, used = None, staged = None, own = {}):
    """Expands the path tokens of one argument (see the module docstring).

    For rules besides gn_action whose arguments the converter writes with the
    same tokens (the impellerc rule's shader bundle).

    Args:
      ctx: the rule context.
      arg: the argument.
      targets: the targets `$(execpath ...)` may name.
      placed: the files of the build directory `$(built ...)` may name, by
        their path under it.
      used: a list the files `$(built ...)` named are appended to, if given.
      staged: a dict, build-directory path -> directory artifact, of the
        directories assembled for the tokens so far, if the rule can assemble
        one (it has PYTHON_ATTRS); None otherwise.
      own: the rule's own build outputs among `placed` (a dict of files),
        which a token names as outputs, not as something to read.

    Returns:
      The argument with every token replaced.
    """
    out = ""
    rest = arg
    for _ in range(len(arg)):
        start = rest.find("$(")
        if start < 0:
            break
        end = rest.find(")", start)
        if end < 0:
            fail("%s: unterminated $( in argument %r" % (ctx.label, arg))
        token = rest[start + 2:end]
        kind, _, path = token.partition(" ")
        if kind == "gen":
            # What a dep places at gen/PATH, or a placed directory holding
            # it (a package directory under gen/dart-pkg/), before the
            # output directory's own path for it. PATH is relative to the
            # repository root; GN's build directory is rooted at engine/src.
            gn_root = "engine/src/"
            placed_path = _placed_input(
                ctx,
                "gen/" + (path[len(gn_root):] if path.startswith(gn_root) else path),
                placed,
                used,
                staged,
                own,
            )
            value = placed_path if placed_path != None else _gen_path(ctx, path)
        elif kind == "src":
            value = _src_path(ctx, path)
        elif kind == "built":
            placed_path = _placed_input(ctx, path, placed, used, staged, own) if path not in (".", "") else None
            if placed_path != None:
                value = placed_path
            elif path in (".", "") or [p for p in placed if p.startswith(path + "/")]:
                # The build directory itself, or a directory under it that
                # holds a placed file: where this rule's own build outputs
                # are declared (GN's `rebase_path(root_build_dir,
                # root_build_dir)`, a script's output directory).
                value = _built_root(ctx) + ("/" + path if path not in (".", "") else "")
            else:
                fail("%s: nothing among the deps places %s in the build directory (argument %r)" % (ctx.label, path, arg))
        else:
            # Bazel's own: $(execpath ...), $(rootpath ...), $(location ...).
            value = ctx.expand_location("$(" + token + ")", targets)
        out += rest[:start] + value
        rest = rest[end + 1:]
    return out + rest

def _placed_input(ctx, path, placed, used, staged, own):
    """Where a script finds `path` of the build directory among what the deps place.

    The file placed at `path`; a path inside a placed directory; or, when
    several placements fall under `path` (a directory of the build directory
    that more than one target fills), a directory assembled from them
    (stage_build_directory.py), one per path, which the action reads
    instead. None when nothing is placed there.

    Args:
      ctx: the rule context.
      path: a path under the build directory.
      placed: build-directory path -> file, what the deps' closures place
        (and the rule's own build outputs).
      used: a list the files the script reads are appended to, if given.
      staged: the directories assembled so far, by path, or None when the
        rule cannot assemble one.
      own: the rule's own build outputs (a dict of files): a directory
        holding only those is where the script writes, not reads (None).

    Returns:
      The path in the execution root, or None.
    """
    under = [(p, file) for p, file in placed.items() if p.startswith(path + "/") and file not in own]
    above = [
        (p, file)
        for p, file in placed.items()
        if file.is_directory and path.startswith(p + "/")
    ]
    if path in placed and not under:
        if used != None:
            used.append(placed[path])
        return placed[path].path
    if above and not under and path not in placed:
        p, file = above[0]
        if used != None:
            used.append(file)
        return file.path + path[len(p):]
    if not under and not above and path not in placed:
        return None
    if staged == None:
        fail("%s: %s is a directory of the build directory that several targets fill; this rule cannot assemble it" % (ctx.label, path))
    if path not in staged:
        directory = ctx.actions.declare_directory(ctx.label.name + ".staged/" + path)
        args = ctx.actions.args()
        args.add(directory.path)
        inputs = []
        if path in placed:
            args.add_all([placed[path], "."], expand_directories = False)
            inputs.append(placed[path])
        for p, file in above:
            args.add_all([file.path + path[len(p):], "."], expand_directories = False)
            inputs.append(file)
        for p, file in under:
            args.add_all([file, p[len(path) + 1:]], expand_directories = False)
            inputs.append(file)
        run_python(
            ctx,
            script = ctx.file._stage_script,
            arguments = [args],
            inputs = inputs,
            outputs = [directory],
            mnemonic = "StageBuildDirectory",
            progress_message = "Assembling %s of the build directory for %%{label}" % path,
        )
        staged[path] = directory
    if used != None:
        used.append(staged[path])
    return staged[path].path

def _built_root(ctx):
    """Where a rule's build outputs are declared: its package's output directory."""
    return ctx.bin_dir.path + "/" + _src_path(ctx, ctx.label.package)

def _src_path(ctx, path):
    if path.startswith("@") or path.startswith("//"):
        # A directory of another repository, as a label (the embedding's
        # dependency jars in @android_embedding_dependencies): where the
        # repository sits in the execution root. The files the script reads
        # there are among the inputs on their own.
        label = Label(path)
        parts = [part for part in [label.workspace_root, label.package, label.name] if part]
        return "/".join(parts)
    root = ctx.label.workspace_root
    if root and path:
        return root + "/" + path
    return root + path or "."

def _gen_path(ctx, path):
    return ctx.bin_dir.path + "/" + _src_path(ctx, path)

def run_python(ctx, script, arguments, inputs, outputs, mnemonic, progress_message, tools = []):
    """Runs a Python script with the checkout's hermetic interpreter.

    For rules whose attrs include PYTHON_ATTRS. The script runs from the
    execution root, without bytecode caches, with a fixed hash seed.

    Args:
      ctx: the rule context.
      script: the script, a File.
      arguments: the script's arguments.
      inputs: the files the script reads (the script itself is added).
      outputs: the files it writes.
      mnemonic: the action's mnemonic.
      progress_message: the action's progress message.
      tools: the programs the script runs, with the files they load (the
        interpreter is added).
    """
    args = ctx.actions.args()

    # -B: no bytecode caches next to the script.
    args.add("-B")
    args.add(script)
    ctx.actions.run(
        executable = ctx.executable._python,
        # The caller's arguments follow: strings, or Args objects of its own
        # (dart_pkg, the snapshots), which is what the list holds.
        # buildifier: disable=pass-args-to-actions
        arguments = [args] + arguments,
        inputs = depset([script] + inputs),
        tools = depset(tools, transitive = [ctx.attr._python_runtime[DefaultInfo].files]),
        outputs = outputs,
        mnemonic = mnemonic,
        progress_message = progress_message,
        env = {
            "PYTHONDONTWRITEBYTECODE": "1",
            "PYTHONHASHSEED": "0",
        },
    )

# The attributes run_python needs: the interpreter and its runtime files.
PYTHON_ATTRS = {
    "_python": attr.label(
        default = "@cpython3//:bin/python3",
        allow_single_file = True,
        executable = True,
        cfg = "exec",
    ),
    "_python_runtime": attr.label(default = "@cpython3//:runtime"),
}

def _platform_transition_impl(settings, attr):
    if not attr.platform:
        return {"//command_line_option:platforms": settings["//command_line_option:platforms"]}
    return {"//command_line_option:platforms": [str(attr.platform)]}

# GN's `label(:toolchain)` on an action's dependency edge (the Android
# embedding's jar packing the Vulkan validation layer built by
# clang_arm64_apilevel26): the dependency is built for the `platform`.
_platform_transition = transition(
    implementation = _platform_transition_impl,
    inputs = ["//command_line_option:platforms"],
    outputs = ["//command_line_option:platforms"],
)

def _platform_dep_entries(ctx, dep):
    """A platform_dep's build-directory entries, under GN's directory for its toolchain.

    GN writes a non-default toolchain's outputs under a directory named for
    it (clang_arm64_apilevel26/libVkLayer_khronos_validation.so) -- except
    what its link tools write relative to the build directory itself: the
    Android toolchain's lib.stripped/ copies.
    """
    entries = []
    for file, path in collected_build_directory_entries(dep):
        if ctx.attr.platform_build_dir and not path.startswith("lib.stripped/"):
            path = ctx.attr.platform_build_dir + "/" + path
        entries.append((file, path))
    return entries

def _gn_action_impl(ctx):
    outputs = [ctx.actions.declare_file(path) for path in ctx.attr.outputs] + [
        ctx.actions.declare_directory(path)
        for path in ctx.attr.output_dirs
    ]

    # The files of the build directory the script may name ($(built PATH)):
    # what the deps' closures place there (a platform_dep's under its
    # toolchain's directory), and the action's own build outputs, declared
    # under this package at the same paths.
    placed = {}
    for dep in ctx.attr.deps:
        for file, path in collected_build_directory_entries(dep):
            placed[path] = file
    for dep in ctx.attr.platform_deps:
        for file, path in _platform_dep_entries(ctx, dep):
            placed[path] = file
    built_paths = ctx.attr.build_outputs + ctx.attr.build_output_dirs
    built = [ctx.actions.declare_file(path) for path in ctx.attr.build_outputs] + [
        ctx.actions.declare_directory(path)
        for path in ctx.attr.build_output_dirs
    ]
    for file, path in zip(built, built_paths):
        placed[path] = file
    read = []
    for path in ctx.attr.build_inputs:
        if path not in placed:
            fail("%s: nothing among the deps places %s (of build_inputs) in the build directory" % (ctx.label, path))
        read.append(placed[path])
    dep_files = [f for dep in ctx.attr.deps + ctx.attr.platform_deps for f in dep[DefaultInfo].files.to_list()]

    # A target among both srcs and deps (GN's `sources +=
    # get_target_outputs(":gen")` beside the dep on it) is one target for
    # the lookup.
    targets = {}
    for target in ctx.attr.srcs + ctx.attr.inputs + ctx.attr.deps + ctx.attr.platform_deps + ctx.attr.tools:
        if str(target.label) not in targets:
            targets[str(target.label)] = target
    own = {file: None for file in built}
    staged = {}
    arguments = [
        expand_gn_paths(ctx, arg, targets.values(), placed, read, staged, own)
        for arg in ctx.attr.args
    ]
    inputs = ctx.files.srcs + ctx.files.inputs + dep_files + [file for file in read if file not in own]
    run_python(
        ctx,
        script = ctx.file.script,
        arguments = arguments,
        inputs = inputs,
        outputs = outputs + built,
        mnemonic = "GnAction",
        progress_message = "GN action %{label}",
        tools = ctx.files.tools,
    )

    # The outputs are under GN's $target_gen_dir: gen/<GN package>/. An
    # action of another repository (a synced tree's overlay) has its GN
    # directory elsewhere, which install does not reconstruct. The build
    # outputs are at their paths under the build directory wherever the
    # action is.
    package = gn_package(ctx)
    return [
        DefaultInfo(files = depset(outputs + built)),
        # The platform_deps' placements travel with the action's own: the
        # aspect that collects them for an install follows deps, not
        # platform_deps (GN lays the toolchain's directory out the same way).
        BuildDirectoryInfo(entries = depset(
            ([
                (output, "gen/" + package + "/" + path)
                for output, path in zip(outputs, ctx.attr.outputs + ctx.attr.output_dirs)
            ] if package != None else []) + list(zip(built, built_paths)) +
            [entry for dep in ctx.attr.platform_deps for entry in _platform_dep_entries(ctx, dep)],
        )),
    ]

def gn_package(ctx):
    """The GN directory of the rule's package, for build directory paths.

    Args:
      ctx: the rule context.

    Returns:
      The package's path under engine/src (`flutter/fml` for
      //engine/src/flutter/fml), or None for a package of another repository
      or outside engine/src.
    """
    prefix = "engine/src/"
    if ctx.label.workspace_root or not ctx.label.package.startswith(prefix):
        return None
    return ctx.label.package[len(prefix):]

gn_action = rule(
    implementation = _gn_action_impl,
    doc = "A GN action(): one run of a Python script. See the module docstring for the argument tokens.",
    attrs = {
        "script": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The Python script (GN's `script`).",
        ),
        "srcs": attr.label_list(
            allow_files = True,
            doc = "GN's `sources`.",
        ),
        "inputs": attr.label_list(
            allow_files = True,
            doc = "GN's `inputs`.",
        ),
        "deps": attr.label_list(
            aspects = [build_directory_aspect],
            doc = "GN's `deps`: their outputs are inputs of the script, as GN's ordering made them available; " +
                  "what their closures place in the build directory, `$(built PATH)` and `build_inputs` may name.",
        ),
        "platform_deps": attr.label_list(
            cfg = _platform_transition,
            aspects = [build_directory_aspect],
            doc = "GN's `deps` with a toolchain (`label($apilevel26_toolchain)`): built for `platform`; what their " +
                  "closures place in the build directory sits under `platform_build_dir`, as GN's toolchain directory.",
        ),
        "platform": attr.label(
            doc = "The platform the platform_deps are built for (the GN toolchain's; see toolchainPlatforms in the converter).",
        ),
        "platform_build_dir": attr.string(
            doc = "GN's directory under the build directory for the platform's toolchain (`clang_arm64_apilevel26`).",
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
        "tools": attr.label_list(
            allow_files = True,
            cfg = "exec",
            doc = "Programs the script runs, named in `args` as $(execpath LABEL) like inputs, with the files they " +
                  "load (a JDK's bin/javac with its lib/): built or taken for the execution platform.",
        ),
        "outputs": attr.string_list(
            doc = "GN's `outputs` under `$target_gen_dir`, as paths relative to this package.",
        ),
        "output_dirs": attr.string_list(
            doc = "GN's `outputs` under `$target_gen_dir` that are directories (the javadoc tree), as paths " +
                  "relative to this package: declared as directories.",
        ),
        "_stage_script": attr.label(
            default = "//build_defs/gn:stage_build_directory.py",
            allow_single_file = True,
        ),
        "build_output_dirs": attr.string_list(
            doc = "GN's `outputs` under the build directory itself that are directories " +
                  "(`$root_build_dir/dist/packages/sky_engine`, a package copied for release), as paths under it.",
        ),
        "build_outputs": attr.string_list(
            doc = "GN's `outputs` under the build directory itself (`$root_out_dir/flutter.jar`, " +
                  "`$root_out_dir/obj/...`), as paths under it: declared under this package at the same paths, " +
                  "placed there by install.",
        ),
        "build_inputs": attr.string_list(
            doc = "GN's `inputs` under the build directory (`$root_build_dir/libflutter.so`), as paths under it: " +
                  "files the deps' closures place there, which the script reads.",
        ),
        "args": attr.string_list(
            doc = "GN's `args`, with paths as $(execpath LABEL), $(src PATH), $(gen PATH) and $(built PATH) tokens.",
        ),
    } | PYTHON_ATTRS,
)

def _gn_copy_impl(ctx):
    # The copy's content is its sources. GN's destination (`outputs`, under
    # the build directory) is the artifact layout, which install assembles
    # (BuildDirectoryInfo, from `outputs`); here the files travel as they
    # are -- unless the copy renames (`outs`: a literal output name, which
    # is the point of such a copy), when each source is linked under its new
    # name. The empty CcInfo keeps the edges that GN has from libraries and
    # binaries to copies, which order them.
    files = ctx.files.srcs
    if ctx.attr.files:
        # The copy names some of a target's files (a wasm module's .js,
        # .wasm and .js.symbols, and its .wasm.map in the unoptimized build
        # where GN's copy lists it): those, in the order named.
        by_name = {file.basename: file for file in files}
        missing = [name for name in ctx.attr.files if name not in by_name]
        if missing:
            fail("%s: %s not among the sources' files (%s)" % (ctx.label, ", ".join(missing), ", ".join(by_name.keys())))
        files = [by_name[name] for name in ctx.attr.files]
    if ctx.outputs.outs:
        if len(ctx.outputs.outs) != len(files):
            fail("%s: %d outs for %d sources" % (ctx.label, len(ctx.outputs.outs), len(files)))
        for i, out in enumerate(ctx.outputs.outs):
            ctx.actions.symlink(output = out, target_file = files[i])
        files = ctx.outputs.outs
    return [
        DefaultInfo(files = depset(files)),
        CcInfo(),
        BuildDirectoryInfo(entries = depset(copy_entries(ctx.attr.outputs, files, ctx.label.package))),
    ]

gn_copy = rule(
    implementation = _gn_copy_impl,
    doc = "A GN copy(): its sources, as they are, or under their new names when the copy renames them. " +
          "See the implementation for why the destination is not otherwise reproduced.",
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
            cfg = module_platform_transition,
            doc = "GN's `sources`; a target among them stands for its files (a wasm module's, built for `platform`).",
        ),
        "files": attr.string_list(
            doc = "The sources' files the copy takes, by base name, when GN names some of a target's " +
                  "files rather than the target (a wasm module's outputs; the unoptimized build's " +
                  ".wasm.map where GN's copy lists it under is_debug). Every file otherwise.",
        ),
        "outs": attr.output_list(
            doc = "The copies, one per source in order, when GN's `outputs` name the files literally " +
                  "(no `{{source...}}` expansion): a renaming copy. Relative to the package, as GN's are " +
                  "to its target_gen_dir.",
        ),
        "outputs": attr.string_list(
            doc = "GN's `outputs`, for the record: where the build directory would hold the copies.",
        ),
        "deps": attr.label_list(
            cfg = module_platform_transition,
            doc = "GN's `deps`: ordering only (the sources carry the file dependencies).",
        ),
        "platform": attr.label(
            doc = "GN's `label(:toolchain)` on the copy's dependency edges: the wasm platform the sources " +
                  "and deps are built for (a wasm_platform of the web build; see build_defs/web/wasm.bzl).",
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)

def _gn_generated_file_impl(ctx):
    # GN's generated_file with `contents` and no output_conversion: a list
    # is written one element per line, each line ended.
    ctx.actions.write(ctx.outputs.out, "".join([line + "\n" for line in ctx.attr.content]))
    entries = []
    for output in ctx.attr.outputs:
        path = build_directory_path(output)
        if path:
            entries.append((ctx.outputs.out, path))
    return [
        DefaultInfo(files = depset([ctx.outputs.out])),
        BuildDirectoryInfo(entries = depset(entries)),
    ]

gn_generated_file = rule(
    implementation = _gn_generated_file_impl,
    doc = "A GN generated_file() with `contents`: the lines, written at build time.",
    attrs = {
        "out": attr.output(
            mandatory = True,
            doc = "The file, relative to the package: GN's output's path under the build directory.",
        ),
        "content": attr.string_list(
            doc = "GN's `contents`: one element per line.",
        ),
        "outputs": attr.string_list(
            doc = "GN's `outputs`, for the record: where the build directory holds the file.",
        ),
    },
)
