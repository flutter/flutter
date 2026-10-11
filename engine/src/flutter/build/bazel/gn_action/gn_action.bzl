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
"""

load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

def _expand(ctx, arg, targets):
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

def _gn_action_impl(ctx):
    outputs = [ctx.actions.declare_file(path) for path in ctx.attr.outputs]
    dep_files = [f for dep in ctx.attr.deps for f in dep[DefaultInfo].files.to_list()]
    inputs = ctx.files.srcs + ctx.files.inputs + dep_files
    targets = ctx.attr.srcs + ctx.attr.inputs + ctx.attr.deps
    arguments = [_expand(ctx, arg, targets) for arg in ctx.attr.args]
    ctx.actions.run(
        executable = ctx.executable._python,
        # -B: no bytecode caches next to the script.
        arguments = ["-B", ctx.file.script.path] + arguments,
        inputs = depset([ctx.file.script] + inputs),
        tools = ctx.attr._python_runtime[DefaultInfo].files,
        outputs = outputs,
        mnemonic = "GnAction",
        progress_message = "GN action %{label}",
        env = {
            "PYTHONDONTWRITEBYTECODE": "1",
            "PYTHONHASHSEED": "0",
        },
    )
    return [DefaultInfo(files = depset(outputs))]

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
        "_python": attr.label(
            default = "@cpython3//:bin/python3",
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_python_runtime": attr.label(default = "@cpython3//:runtime"),
    },
)

def _gn_copy_impl(ctx):
    # The copy's content is its sources. GN's destination (`outputs`, under
    # the build directory) is the artifact layout, which packaging assembles;
    # here the files travel as they are. The empty CcInfo keeps the edges
    # that GN has from libraries and binaries to copies, which order them.
    return [
        DefaultInfo(files = depset(ctx.files.srcs)),
        CcInfo(),
    ]

gn_copy = rule(
    implementation = _gn_copy_impl,
    doc = "A GN copy(): its sources, as they are. See the implementation for why the destination is not reproduced.",
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
            doc = "GN's `sources`.",
        ),
        "outputs": attr.string_list(
            doc = "GN's `outputs`, for the record: where the build directory would hold the copies.",
        ),
    },
)
