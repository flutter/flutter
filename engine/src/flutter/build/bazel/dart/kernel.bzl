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
is the one the engine's VM reads.

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

def _dart_kernel_impl(ctx):
    platform = [f for f in ctx.files.platform if f.basename == "platform_strong.dill"]
    if len(platform) != 1:
        fail("%s: platform must provide platform_strong.dill" % ctx.label)

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

    args = ctx.actions.args()
    args.add(ctx.file._frontend_server)
    if ctx.attr.product:
        args.add("-Ddart.vm.product=true")
    args.add_all(ctx.attr.args)

    # The package configuration under the virtual scheme, so that the
    # packages' roots resolve against every filesystem root.
    args.add(ctx.file.package_config, format = "--packages=" + SOURCE_URI_SCHEME + ":///%s")
    args.add("--sdk-root", platform[0].dirname)
    args.add("--target=flutter")
    for root in roots:
        args.add("--filesystem-root", root)
    args.add("--filesystem-scheme", SOURCE_URI_SCHEME)
    args.add("--output-dill", ctx.outputs.out)
    args.add(ctx.file.main, format = SOURCE_URI_SCHEME + ":///%s")
    ctx.actions.run(
        executable = ctx.executable._dartaotruntime,
        arguments = [args],
        inputs = depset(
            [ctx.file.main, ctx.file.package_config, ctx.file._frontend_server] + ctx.files.platform + staged,
            transitive = [depset(ctx.files.srcs)] + [info.files for info in shared],
        ),
        outputs = [ctx.outputs.out],
        mnemonic = "DartKernel",
        progress_message = "Compiling %{input} to kernel",
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
        "_dartaotruntime": attr.label(
            default = "@dart_sdk_linux_x64//:dartaotruntime",
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_frontend_server": attr.label(
            default = "@dart_sdk_linux_x64//:frontend_server",
            allow_single_file = True,
        ),
    },
)
