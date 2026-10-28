# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Dart programs to kernel with the frontend server: GN's flutter_frontend_server.

build/dart/internal/flutter_frontend_server.gni compiles a Dart entry point
to a kernel file (`kernel_blob.bin`) for the engine's test fixtures and
tools. On a host with the prebuilt Dart SDK from DEPS (flutter_prebuilt_dart_sdk,
which is every desktop host) it runs that SDK's dartaotruntime on its
frontend_server_aot.dart.snapshot, against the engine's platform
(flutter_patched_sdk, //flutter/lib/snapshot:strong_platform) and the
engine's package configuration; the Dart sources the entry point imports it
tracks through a depfile. Here they are declared: `srcs`.

The runtime and the snapshot are the prebuilt SDK's rather than the wrapped
Dart build's: an AOT snapshot runs only on the runtime it was built for,
and the wrapped build (an unoptimized VM in a fastbuild) would make the
compiler several times slower than GN's for the same output. The prebuilt
SDK is pinned to the same Dart revision as the tree, so the kernel it emits
is the one the engine's VM reads. The one build without the prebuilt SDK
(tools/gn --no-prebuilt-dart-sdk; the dart_wrap package's flutter_prebuilt_dart_sdk
setting off, in the host's own build) runs the wrapped build's: both tools
come through that package's engine_dartaotruntime and engine_frontend_server,
which choose.

The compiler records each source's URI in the kernel, and a source given by
path gets `file://` plus its absolute path -- GN's checkout path, or here
the sandbox's, which changes with every run and would make the output
non-deterministic. The frontend server's virtual root makes the URI a
property of the tree instead: sources are compiled as
`org-dartlang-root:///<path from the execution root>` (`--filesystem-root .`
`--filesystem-scheme org-dartlang-root`), so a fixture's library is
`org-dartlang-root:///engine/src/flutter/...` on every machine, and tests
look it up by that URI through flutter::testing::GetSourceUri.
"""

SOURCE_URI_SCHEME = "org-dartlang-root"

DartPackageRootInfo = provider(
    doc = "A filesystem root of staged package sources (dart_package_root).",
    fields = {
        "root": "The root directory's path, for --filesystem-root.",
        "files": "depset of the staged files.",
    },
)

def _stage_trees(ctx, trees, root_name, sibling):
    """Symlinks the files of `trees` (target -> path under the source root) under `root_name`."""
    staged = []
    for target, virtual_path in trees.items():
        for f in target[DefaultInfo].files.to_list():
            if not f.short_path.startswith("../"):
                fail("%s: %s is in this repository; list it in srcs" % (ctx.label, f.short_path))
            relative = f.short_path.split("/", 2)[2]
            link = ctx.actions.declare_file(
                "/".join([root_name, virtual_path.strip("/"), relative]),
                sibling = sibling,
            )
            ctx.actions.symlink(output = link, target_file = f)
            staged.append(link)
    return staged

def _dart_package_root_impl(ctx):
    # A marker in the package directory, which the root's name is relative to.
    marker = ctx.actions.declare_file(ctx.label.name + ".staged")
    ctx.actions.write(marker, "")
    root_name = ctx.label.name + ".root"
    staged = _stage_trees(ctx, ctx.attr.trees, root_name, marker)
    return [
        DefaultInfo(files = depset(staged)),
        DartPackageRootInfo(root = marker.dirname + "/" + root_name, files = depset(staged)),
    ]

dart_package_root = rule(
    implementation = _dart_package_root_impl,
    doc = "Package sources from other repositories, staged once under a filesystem root at the paths " +
          "the package configuration names them by; kernel compiles that reach many packages (the " +
          "engine's Dart tests, on package:test) share it through dart_kernel's package_roots.",
    attrs = {
        "trees": attr.label_keyed_string_dict(
            allow_files = True,
            mandatory = True,
            doc = "Sources of packages in other repositories, each mapped to the path under the source " +
                  "root where the package configuration names the package (dart_kernel's package_trees).",
        ),
    },
)

# The frontend server's targets and the platform kernel each reads from
# --sdk-root: Flutter's (the engine's flutter_patched_sdk) and the VM's (the
# Dart SDK's lib/_internal).
PLATFORM_DILLS = {
    "flutter": "platform_strong.dill",
    "vm": "vm_platform_strong.dill",
}

def compile_to_kernel(ctx, main, out, srcs, package_config, platform, args = [], product = False, roots = ["."], extra_inputs = [], target = "flutter"):
    """The frontend server's compile of `main` to the kernel `out`, as dart_kernel runs it.

    For rules with dart_kernel's tool attributes (KERNEL_TOOL_ATTRS): the
    engine's own Dart tests, flutter_test's bootstrap of a framework test,
    dart_test's of a VM test.

    Args:
      ctx: the rule context.
      main: the entry point File.
      out: the kernel File to write.
      srcs: a depset of the files the entry point reaches (sources and the
        package files beside them).
      package_config: the package configuration File (--packages), read
        under the virtual scheme.
      platform: the files of the platform kernel's directory, the target's
        dill (PLATFORM_DILLS) among them.
      args: further frontend server arguments.
      product: -Ddart.vm.product=true.
      roots: the filesystem roots (--filesystem-root), the execution root by default.
      extra_inputs: further input Files.
      target: the frontend server's --target: `flutter` or `vm`.
    """
    if target not in PLATFORM_DILLS:
        fail("%s: target must be one of %s, not %s" % (ctx.label, PLATFORM_DILLS.keys(), target))
    dill = [f for f in platform if f.basename == PLATFORM_DILLS[target]]
    if len(dill) != 1:
        fail("%s: platform must provide %s" % (ctx.label, PLATFORM_DILLS[target]))
    arguments = ctx.actions.args()
    arguments.add(ctx.file._frontend_server)
    if product:
        arguments.add("-Ddart.vm.product=true")
    arguments.add_all(args)

    # The package configuration under the virtual scheme, so that the
    # packages' roots resolve against every filesystem root.
    arguments.add(package_config, format = "--packages=" + SOURCE_URI_SCHEME + ":///%s")
    arguments.add("--sdk-root", dill[0].dirname)
    arguments.add("--target=" + target)
    if PLATFORM_DILLS[target] != "platform_strong.dill":
        # The frontend server reads <sdk-root>/platform_strong.dill unless
        # told the platform kernel's name (resolved under --sdk-root).
        arguments.add("--platform", PLATFORM_DILLS[target])
    for root in roots:
        arguments.add("--filesystem-root", root)
    arguments.add("--filesystem-scheme", SOURCE_URI_SCHEME)
    arguments.add("--output-dill", out)
    arguments.add(main, format = SOURCE_URI_SCHEME + ":///%s")
    ctx.actions.run(
        executable = ctx.executable._dartaotruntime,
        arguments = [arguments],
        inputs = depset(
            [main, package_config, ctx.file._frontend_server] + platform + extra_inputs,
            transitive = [srcs],
        ),
        outputs = [out],
        mnemonic = "DartKernel",
        # %{input} would be the first input in depset order, not the entry point.
        progress_message = "Compiling %s to kernel" % main.short_path,
    )

# The frontend server and its runtime, for a rule that calls compile_to_kernel.
KERNEL_TOOL_ATTRS = {
    # In the target configuration, where the wrapped Dart build is: the
    # build without the prebuilt SDK takes both from it, and an exec
    # configuration dependency would build the SDK a second time.
    "_dartaotruntime": attr.label(
        default = "//engine/src/flutter/build/bazel/dart_wrap:engine_dartaotruntime",
        allow_single_file = True,
        executable = True,
        cfg = "target",
    ),
    "_frontend_server": attr.label(
        default = "//engine/src/flutter/build/bazel/dart_wrap:engine_frontend_server",
        allow_single_file = True,
    ),
}

def _dart_kernel_impl(ctx):
    # Packages from other repositories (the trees gclient syncs, which the
    # package configuration names by their paths under the source root):
    # a second virtual root of symlinks, each file at that path -- staged
    # here for this target, or shared (package_roots).
    staged = []
    roots = ["."]
    if ctx.attr.package_trees:
        root_name = ctx.label.name + ".root"
        staged = _stage_trees(ctx, ctx.attr.package_trees, root_name, ctx.outputs.out)
        roots.append(ctx.outputs.out.dirname + "/" + root_name)
    shared = [root[DartPackageRootInfo] for root in ctx.attr.package_roots]
    for info in shared:
        roots.append(info.root)
    compile_to_kernel(
        ctx,
        main = ctx.file.main,
        out = ctx.outputs.out,
        srcs = depset(ctx.files.srcs + staged, transitive = [info.files for info in shared]),
        package_config = ctx.file.package_config,
        platform = ctx.files.platform,
        args = ctx.attr.args,
        product = ctx.attr.product,
        roots = roots,
    )
    return [DefaultInfo(files = depset([ctx.outputs.out]))]

dart_kernel = rule(
    implementation = _dart_kernel_impl,
    doc = "GN's flutter_frontend_server(): a Dart entry point to kernel.",
    attrs = {
        "main": attr.label(
            allow_single_file = [".dart"],
            mandatory = True,
            doc = "The entry point (GN's main_dart).",
        ),
        "srcs": attr.label_list(
            allow_files = [".dart"],
            doc = "The other Dart sources the entry point reaches (GN's depfile).",
        ),
        "package_trees": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "Sources of packages in other repositories (the trees gclient syncs), each mapped to " +
                  "the path under the source root where the package configuration names the package " +
                  "(`engine/src/flutter/third_party/pkg/vector_math`); staged under a second virtual root.",
        ),
        "package_roots": attr.label_list(
            providers = [DartPackageRootInfo],
            doc = "Such packages staged once for many compiles (dart_package_root).",
        ),
        "out": attr.output(
            mandatory = True,
            doc = "The kernel file (GN's kernel_output).",
        ),
        "platform": attr.label(
            default = "//engine/src/flutter/lib/snapshot:strong_platform",
            allow_files = True,
            doc = "The platform kernel's directory contents (GN's --sdk-root, flutter_patched_sdk).",
        ),
        "package_config": attr.label(
            default = "//engine/src/flutter:package_config",
            allow_single_file = True,
            doc = "The package configuration (GN's --packages).",
        ),
        "product": attr.bool(
            doc = "-Ddart.vm.product=true: GN passes it in the release and jit_release runtime modes.",
        ),
        "args": attr.string_list(
            doc = "Further frontend server arguments (GN's extra_args: --aot --tfa for an AOT test).",
        ),
    } | KERNEL_TOOL_ATTRS,
)
