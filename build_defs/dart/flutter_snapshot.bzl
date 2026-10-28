# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""GN's flutter_snapshot (build/dart/internal/flutter_snapshot.gni): a Flutter app's kernel and snapshot.

The template compiles an app's entry point to kernel with the frontend
server (flutter_frontend_server: `--no-link-platform` in the JIT modes,
`--aot --tfa` in profile and release; `-Ddart.vm.product=true` for a
product build, `-Ddart.vm.profile=true` in profile) and runs gen_snapshot
over the kernel: in the JIT modes an application snapshot
(`--snapshot_kind=app`, the isolate's data and instructions beside the
kernel, with `--enable_asserts` in an unoptimized debug build), in the AOT
modes an assembly snapshot for iOS (`--snapshot_kind=app-aot-assembly`,
`ios/snapshot_assembly.S`) or an ELF for Android. The iOS scenario app
(testing/ios_scenario_app) is its one user: the JIT files are copied into
App.framework/flutter_assets, the assembly compiled into App.framework's
dylib.

Here: `_<name>_kernel` is a dart_kernel (kernel.bzl) writing kernel_blob.bin;
`_<name>_jit_snapshot` the application snapshot, compatible in the JIT
modes; `_<name>_aot_snapshot` the iOS assembly, compatible in the AOT modes
on iOS -- GN's one `_<name>_snapshot` target with mode-dependent outputs is
two rules with fixed outputs, and `_<name>_snapshot` an alias of the mode's;
`<name>` the group over the kernel and the snapshot. GN writes the assembly
into the `ios/` subdirectory of the app's gen dir, which here is the ios
package's own directory: the assembly is `<name>.snapshot_assembly.S` of
this package instead, and the package that compiles it names it so. The
Android ELF (`android/libs/<abi>/libapp.so`) has no user among the
converted files and is not declared.

gen_snapshot is the wrapped Dart build's host tool for the target
(dart_wrap:gen_snapshot_host: GN's compiled_action runs the host
toolchain's gen_snapshot, built to emit the target's snapshots).
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//build_defs/dart:kernel.bzl", "dart_kernel")

_AOT_MODES = [
    "//engine/src/flutter/common:runtime_mode_profile",
    "//engine/src/flutter/common:runtime_mode_release",
]

_JIT_MODES = [
    "//engine/src/flutter/common:runtime_mode_debug",
    "//engine/src/flutter/common:runtime_mode_jit_release",
]

_PROFILE_MODE = "//engine/src/flutter/common:runtime_mode_profile"

def _gen_snapshot_attr():
    return attr.label(
        default = "//engine/src/flutter/build/bazel/dart_wrap:gen_snapshot_host",
        allow_single_file = True,
        executable = True,
        cfg = "target",
    )

def _app_jit_snapshot_impl(ctx):
    # GN: gen_snapshot [--enable_asserts] --snapshot_kind=app
    # --snapshot_data=<data> --snapshot_text=<instructions> <kernel>, with
    # the engine's VM and isolate snapshots among the inputs (an ordering
    # dependency on generate_snapshot_bin, kept as inputs here).
    args = ctx.actions.args()
    if ctx.attr.enable_asserts:
        args.add("--enable_asserts")
    args.add("--snapshot_kind=app")
    args.add(ctx.outputs.data, format = "--snapshot_data=%s")
    args.add(ctx.outputs.instructions, format = "--snapshot_text=%s")
    args.add(ctx.file.kernel)
    ctx.actions.run(
        executable = ctx.executable._gen_snapshot,
        arguments = [args],
        inputs = [ctx.file.kernel] + ctx.files.engine_snapshots,
        outputs = [ctx.outputs.data, ctx.outputs.instructions],
        mnemonic = "GenAppSnapshot",
        progress_message = "Generating the application snapshot %{label}",
    )
    return [DefaultInfo(files = depset([ctx.outputs.data, ctx.outputs.instructions]))]

app_jit_snapshot = rule(
    implementation = _app_jit_snapshot_impl,
    doc = "flutter_snapshot's JIT half: gen_snapshot --snapshot_kind=app over a kernel.",
    attrs = {
        "kernel": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The kernel file.",
        ),
        "data": attr.output(
            mandatory = True,
            doc = "The isolate snapshot's data (GN's isolate_snapshot_data).",
        ),
        "instructions": attr.output(
            mandatory = True,
            doc = "The isolate snapshot's instructions (GN's isolate_snapshot_instr).",
        ),
        "engine_snapshots": attr.label_list(
            allow_files = True,
            doc = "The engine's VM and isolate snapshots (GN's inputs: generate_snapshot_bin's " +
                  "vm_isolate_snapshot.bin and isolate_snapshot.bin).",
        ),
        "enable_asserts": attr.bool(
            doc = "--enable_asserts: GN passes it in an unoptimized (is_debug) build of the debug runtime mode.",
        ),
        "_gen_snapshot": _gen_snapshot_attr(),
    },
)

def _aot_assembly_snapshot_impl(ctx):
    # GN: gen_snapshot --deterministic --snapshot_kind=app-aot-assembly
    # --assembly=<assembly> <kernel>.
    args = ctx.actions.args()
    args.add("--deterministic")
    args.add("--snapshot_kind=app-aot-assembly")
    args.add(ctx.outputs.assembly, format = "--assembly=%s")
    args.add(ctx.file.kernel)
    ctx.actions.run(
        executable = ctx.executable._gen_snapshot,
        arguments = [args],
        inputs = [ctx.file.kernel],
        outputs = [ctx.outputs.assembly],
        mnemonic = "GenAotAssemblySnapshot",
        progress_message = "Generating the AOT assembly snapshot %{label}",
    )
    return [DefaultInfo(files = depset([ctx.outputs.assembly]))]

aot_assembly_snapshot = rule(
    implementation = _aot_assembly_snapshot_impl,
    doc = "flutter_snapshot's AOT half on iOS: gen_snapshot --snapshot_kind=app-aot-assembly over a kernel.",
    attrs = {
        "kernel": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The kernel file, compiled with --aot --tfa.",
        ),
        "assembly": attr.output(
            mandatory = True,
            doc = "The assembly file (GN's ios/snapshot_assembly.S).",
        ),
        "_gen_snapshot": _gen_snapshot_attr(),
    },
)

def flutter_snapshot(name, main_dart, dart_srcs = None, package_config = None, product = False, visibility = None, testonly = None, **kwargs):
    """GN's flutter_snapshot(): see the file's docstring.

    Args:
      name: GN's target name; the group over the kernel and the snapshot.
      main_dart: the entry point.
      dart_srcs: the Dart sources the entry point imports; by default every
        `.dart` file under the entry point's directory, when that is in this
        package.
      package_config: the package configuration (GN's package_config); the
        engine's by default.
      product: GN's `product`: -Ddart.vm.product=true whatever the mode
        (without it, profile gets -Ddart.vm.profile=true).
      visibility: visibility of the targets.
      testonly: whether the targets are testonly.
      **kwargs: the group's other arguments (tags).
    """
    if dart_srcs == None:
        dart_srcs = [] if main_dart.startswith("//") or main_dart.startswith("@") else native.glob([paths.join(paths.dirname(main_dart), "**/*.dart")])
    kernel = "_%s_kernel" % name
    kernel_args = {}
    if package_config != None:
        kernel_args["package_config"] = package_config
    dart_kernel(
        name = kernel,
        main = main_dart,
        srcs = dart_srcs,
        out = "kernel_blob.bin",
        product = product,
        args = select({mode: ["--aot", "--tfa"] for mode in _AOT_MODES} | {"//conditions:default": ["--no-link-platform"]}) +
               ([] if product else select({_PROFILE_MODE: ["-Ddart.vm.profile=true"], "//conditions:default": []})),
        visibility = visibility,
        testonly = testonly,
        **kernel_args
    )
    jit = "_%s_jit_snapshot" % name
    app_jit_snapshot(
        name = jit,
        kernel = ":" + kernel,
        data = "isolate_snapshot_data",
        instructions = "isolate_snapshot_instr",
        engine_snapshots = [
            "//engine/src/flutter/lib/snapshot:vm_isolate_snapshot.bin",
            "//engine/src/flutter/lib/snapshot:isolate_snapshot.bin",
        ],
        # GN's `is_debug && flutter_runtime_mode == "debug"` (the other JIT
        # mode, jit_release, is excluded by name).
        enable_asserts = select({
            "//engine/src/flutter/build/bazel:unoptimized_debug": True,
            "//conditions:default": False,
        }),
        target_compatible_with = select({mode: [] for mode in _JIT_MODES} | {"//conditions:default": ["@platforms//:incompatible"]}),
        visibility = visibility,
        testonly = testonly,
    )
    aot = "_%s_aot_snapshot" % name
    aot_assembly_snapshot(
        name = aot,
        kernel = ":" + kernel,
        assembly = name + ".snapshot_assembly.S",
        target_compatible_with = select({mode: [] for mode in _AOT_MODES} | {"//conditions:default": ["@platforms//:incompatible"]}) + select({
            "@platforms//os:ios": [],
            "//conditions:default": ["@platforms//:incompatible"],
        }),
        visibility = visibility,
        testonly = testonly,
    )
    native.alias(
        name = "_%s_snapshot" % name,
        actual = select({mode: ":" + aot for mode in _AOT_MODES} | {"//conditions:default": ":" + jit}),
        visibility = visibility,
        testonly = testonly,
    )
    native.filegroup(
        name = name,
        srcs = [
            ":" + kernel,
            ":_%s_snapshot" % name,
        ],
        visibility = visibility,
        testonly = testonly,
        **kwargs
    )
