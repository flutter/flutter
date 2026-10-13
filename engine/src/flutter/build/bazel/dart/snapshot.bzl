# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The Dart snapshot pipeline of //flutter/lib/snapshot, as Bazel rules.

GN builds the engine's Dart platform in three steps (lib/snapshot/BUILD.gn,
with templates from the Dart tree's utils/compile_platform.gni,
//build/compiled_action.gni and //flutter/build/bin_to_obj.gni):

  1. compile_platform: the core libraries (the Dart SDK's sdk/lib plus
     dart:ui, joined by lib/snapshot/libraries.json) to kernel,
     `flutter_patched_sdk/platform_strong.dill`;
  2. gen_snapshot --snapshot_kind=core: that kernel to the VM's isolate
     snapshot (data and instructions);
  3. bin_to_assembly: each blob to an assembly file that defines a symbol
     over its bytes (`.incbin`), which source_set("snapshot") compiles.

The tools come from the wrapped Dart SDK build (../dart_wrap), in the
target configuration: GN builds gen_snapshot in the host toolchain, which
for a host build is the default toolchain, and the snapshot it writes must
match the VM it is linked with (debug or release, asserts or not), so the
tool and the library share a configuration here too. Cross builds, where
GN's gen_snapshot is a host binary targeting another architecture, are a
later phase.
"""

load("//engine/src/flutter/build/bazel/gn_action:gn_action.bzl", "PYTHON_ATTRS", "run_python")

# A tool of the wrapped Dart SDK build, see the module docstring.
def _dart_tool(name):
    return attr.label(
        default = "//engine/src/flutter/build/bazel/dart_wrap:" + name,
        allow_single_file = True,
        executable = True,
        cfg = "target",
    )

_GN_ROOT = "engine/src"

def _gn_path(ctx, file, tree):
    """Where [file] sits in the GN source tree, relative to the GN root.

    A file of this repository is under engine/src, the GN root. A file of
    another repository is at the GN path of that repository's root
    ([tree], the `tree` attribute) plus its path within the repository.
    """
    workspace_root = file.owner.workspace_root
    if not workspace_root:
        prefix = _GN_ROOT + "/"
        if not file.short_path.startswith(prefix):
            fail("%s: %s is not under %s" % (ctx.label, file.short_path, _GN_ROOT))
        return file.short_path[len(prefix):]
    for target, gn_dir in tree.items():
        if target.label.workspace_root == workspace_root:
            within = file.path[len(workspace_root) + 1:]
            return gn_dir.strip("/") + "/" + within
    fail("%s: %s is in a repository the tree attribute does not place" % (ctx.label, file.short_path))

def _compile_platform_impl(ctx):
    # GN: bootstrap_compile_platform.exe <args> --single-root-scheme=S
    # --single-root-base=<GN root> S:///flutter/lib/snapshot/libraries.json
    # unused-vm-platform.dill <platform> <outline>. The single root is the
    # directory the specification's relative paths resolve from: the GN
    # source root, in which the Dart tree is flutter/third_party/dart. In
    # the execution root that tree is another repository, so the root is
    # staged: a directory of symlinks, each input at its GN path.
    root = ctx.label.name + ".root"
    staged = []
    for file in ctx.files.srcs + ctx.files.tree + [ctx.file.libraries_json]:
        link = ctx.actions.declare_file(root + "/" + _gn_path(ctx, file, ctx.attr.tree))
        ctx.actions.symlink(output = link, target_file = file)
        staged.append(link)
    root_dir = ctx.bin_dir.path + "/" + ctx.label.package + "/" + root
    if ctx.label.workspace_root:
        root_dir = ctx.bin_dir.path + "/" + ctx.label.workspace_root + "/" + ctx.label.package + "/" + root
    args = ctx.actions.args()
    args.add_all(ctx.attr.args)
    args.add("-Ddart.vm.product=%s" % ("true" if ctx.attr.product else "false"))
    args.add("-Ddart.isVM=true")
    args.add("dart:core")
    args.add("--single-root-scheme=org-dartlang-sdk")
    args.add("--single-root-base=" + root_dir)
    args.add("org-dartlang-sdk:///" + _gn_path(ctx, ctx.file.libraries_json, ctx.attr.tree))
    args.add("unused-vm-platform.dill")
    args.add(ctx.outputs.platform)
    args.add(ctx.outputs.outline)
    ctx.actions.run(
        executable = ctx.executable._compiler,
        arguments = [args],
        inputs = staged,
        outputs = [ctx.outputs.platform, ctx.outputs.outline],
        mnemonic = "CompilePlatform",
        progress_message = "Compiling the Dart platform %{label}",
    )
    return [DefaultInfo(files = depset([ctx.outputs.platform, ctx.outputs.outline]))]

compile_platform = rule(
    implementation = _compile_platform_impl,
    doc = "GN's compile_platform(): the core libraries to kernel.",
    attrs = {
        "libraries_json": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The libraries specification (GN's libraries_specification_uri), a file of this repository under engine/src.",
        ),
        "srcs": attr.label_list(
            allow_files = True,
            doc = "Files of this repository the specification reaches (dart:ui's sources); GN tracks them through a depfile.",
        ),
        "tree": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "Files of other repositories the specification reaches (the SDK's sdk/lib tree), keyed to the GN path of their repository's root (`flutter/third_party/dart`).",
        ),
        "args": attr.string_list(
            doc = "The compiler's leading arguments (GN's args before the -D defines).",
        ),
        "product": attr.bool(
            doc = "-Ddart.vm.product: true in the release and jit_release runtime modes.",
        ),
        "platform": attr.output(
            mandatory = True,
            doc = "The platform kernel, GN's flutter_patched_sdk/platform_strong.dill.",
        ),
        "outline": attr.output(
            mandatory = True,
            doc = "The platform's outline, GN's flutter_patched_sdk/vm_outline_strong.dill.",
        ),
        "_compiler": _dart_tool("bootstrap_compile_platform.exe"),
    },
)

def _core_snapshot_impl(ctx):
    # GN: gen_snapshot --snapshot_kind=core --enable_mirrors=false
    # --snapshot_data=<data> --snapshot_text=<text> [--enable_asserts]
    # <platform>.
    args = ctx.actions.args()
    args.add("--snapshot_kind=core")
    args.add("--enable_mirrors=false")
    args.add(ctx.outputs.data, format = "--snapshot_data=%s")
    args.add(ctx.outputs.instructions, format = "--snapshot_text=%s")
    if ctx.attr.enable_asserts:
        args.add("--enable_asserts")
    args.add(ctx.file.platform)
    ctx.actions.run(
        executable = ctx.executable._gen_snapshot,
        arguments = [args],
        inputs = [ctx.file.platform],
        outputs = [ctx.outputs.data, ctx.outputs.instructions],
        mnemonic = "GenSnapshot",
        progress_message = "Generating the core snapshot %{label}",
    )
    return [DefaultInfo(files = depset([ctx.outputs.data, ctx.outputs.instructions]))]

core_snapshot = rule(
    implementation = _core_snapshot_impl,
    doc = "GN's generate_snapshot_bin: the platform kernel to the VM's core snapshot.",
    attrs = {
        "platform": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The platform kernel.",
        ),
        "enable_asserts": attr.bool(
            doc = "--enable_asserts: GN passes it in a debug build of the debug runtime mode.",
        ),
        "data": attr.output(
            mandatory = True,
            doc = "The isolate snapshot data (GN's isolate_snapshot.bin).",
        ),
        "instructions": attr.output(
            mandatory = True,
            doc = "The isolate snapshot instructions (GN's isolate_snapshot_instructions.bin).",
        ),
        "_gen_snapshot": _dart_tool("gen_snapshot"),
    },
)

def _bin_to_assembly_impl(ctx):
    # GN: bin_to_assembly.py --input <bin> --output <S> --symbol_name <sym>
    # [--size_symbol_name <sym> --target_arch <cpu>] --target_os <os>
    # [--executable] --incbin. With --incbin the assembly names the blob by
    # the path given here, which the assembler resolves from the execution
    # root like the script did; the blob is therefore an input of the
    # library that compiles the assembly (additional_compiler_inputs).
    output = ctx.actions.declare_file(ctx.file.src.basename + ".S")
    arguments = [
        "--input",
        ctx.file.src.path,
        "--output",
        output.path,
        "--symbol_name",
        ctx.attr.symbol,
        "--target_os",
        ctx.attr.target_os,
    ]
    if ctx.attr.size_symbol:
        arguments += ["--size_symbol_name", ctx.attr.size_symbol, "--target_arch", ctx.attr.target_cpu]
    if ctx.attr.executable:
        arguments.append("--executable")
    if ctx.attr.target_os != "win":
        arguments.append("--incbin")
    run_python(
        ctx,
        script = ctx.file._script,
        arguments = arguments,
        inputs = [ctx.file.src],
        outputs = [output],
        mnemonic = "BinToAssembly",
        progress_message = "Wrapping %s as %s" % (ctx.file.src.basename, ctx.attr.symbol),
    )
    return [DefaultInfo(files = depset([output]))]

bin_to_assembly = rule(
    implementation = _bin_to_assembly_impl,
    doc = "GN's bin_to_assembly(): a symbol over the bytes of a file, as assembly (`<file>.S`).",
    attrs = {
        "src": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The binary file.",
        ),
        "symbol": attr.string(
            mandatory = True,
            doc = "The symbol to define over the bytes.",
        ),
        "size_symbol": attr.string(
            doc = "A symbol to define as the size of the bytes, if any.",
        ),
        "executable": attr.bool(
            doc = "Place the bytes in a text section rather than read-only data.",
        ),
        "target_os": attr.string(
            default = "linux",
            doc = "GN's current_os.",
        ),
        "target_cpu": attr.string(
            default = "x64",
            doc = "GN's current_cpu (the size symbol's width).",
        ),
        "_script": attr.label(
            default = "@dart//:runtime/tools/bin_to_assembly.py",
            allow_single_file = True,
        ),
    } | PYTHON_ATTRS,
)
