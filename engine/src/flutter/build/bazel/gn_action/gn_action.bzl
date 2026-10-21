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
                      be among `srcs`, `inputs` or the outputs of `deps`);
  $(src PATH)         a source directory (or file) of this repository, PATH
                      relative to the repository root;
  $(gen PATH)         a generated file or directory, PATH relative to the
                      repository root under the output directory -- where
                      GN's `$target_gen_dir` and `$root_gen_dir` land.

The script runs with the checkout's hermetic Python (`@cpython3`), from the
execution root, in a sandbox that holds exactly the declared inputs: an
undeclared input GN would have tolerated is a failure here, by design.

Each rule here says where GN's build directory holds its files
(BuildDirectoryInfo, ../build_directory.bzl): an action's outputs under
gen/<package>/, a copy's at its `outputs`, a generated file's at its
output; `install` (../install.bzl) lays them out there.
"""

load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("//engine/src/flutter/build/bazel:build_directory.bzl", "BuildDirectoryInfo", "build_directory_path", "copy_entries")
load("//engine/src/flutter/build/bazel/toolchains/emscripten:wasm.bzl", "module_platform_transition")

def expand_gn_paths(ctx, arg, targets):
    """Expands the path tokens of one argument (see the module docstring).

    For rules besides gn_action whose arguments the converter writes with the
    same tokens (the impellerc rule's shader bundle).

    Args:
      ctx: the rule context.
      arg: the argument.
      targets: the targets `$(execpath ...)` may name.

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
            value = _gen_path(ctx, path)
        elif kind == "src":
            value = _src_path(ctx, path)
        else:
            # Bazel's own: $(execpath ...), $(rootpath ...), $(location ...).
            value = ctx.expand_location("$(" + token + ")", targets)
        out += rest[:start] + value
        rest = rest[end + 1:]
    return out + rest

def _src_path(ctx, path):
    root = ctx.label.workspace_root
    if root and path:
        return root + "/" + path
    return root + path or "."

def _gen_path(ctx, path):
    return ctx.bin_dir.path + "/" + _src_path(ctx, path)

def run_python(ctx, script, arguments, inputs, outputs, mnemonic, progress_message):
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
        tools = ctx.attr._python_runtime[DefaultInfo].files,
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

def _gn_action_impl(ctx):
    outputs = [ctx.actions.declare_file(path) for path in ctx.attr.outputs]
    dep_files = [f for dep in ctx.attr.deps for f in dep[DefaultInfo].files.to_list()]
    inputs = ctx.files.srcs + ctx.files.inputs + dep_files
    targets = ctx.attr.srcs + ctx.attr.inputs + ctx.attr.deps
    arguments = [expand_gn_paths(ctx, arg, targets) for arg in ctx.attr.args]
    run_python(
        ctx,
        script = ctx.file.script,
        arguments = arguments,
        inputs = inputs,
        outputs = outputs,
        mnemonic = "GnAction",
        progress_message = "GN action %{label}",
    )

    # The outputs are under GN's $target_gen_dir: gen/<GN package>/. An
    # action of another repository (a synced tree's overlay) has its GN
    # directory elsewhere, which install does not reconstruct.
    package = gn_package(ctx)
    return [
        DefaultInfo(files = depset(outputs)),
        BuildDirectoryInfo(entries = depset([
            (output, "gen/" + package + "/" + path)
            for output, path in zip(outputs, ctx.attr.outputs)
        ] if package != None else [])),
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
            doc = "GN's `deps`: their outputs are inputs of the script, as GN's ordering made them available.",
        ),
        "outputs": attr.string_list(
            mandatory = True,
            doc = "GN's `outputs`, as paths relative to this package (GN's `$target_gen_dir`).",
        ),
        "args": attr.string_list(
            doc = "GN's `args`, with paths as $(execpath LABEL), $(src PATH) and $(gen PATH) tokens.",
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
                  "and deps are built for (a wasm_platform of the web build; see toolchains/emscripten/wasm.bzl).",
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
