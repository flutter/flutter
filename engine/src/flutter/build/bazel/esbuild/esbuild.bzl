# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""build/esbuild/esbuild.gni's `esbuild` template, as a rule.

GN runs the prebuilt esbuild (`$host_prebuilts_path/esbuild/bin/esbuild`)
over an entry point under the build directory -- flutter.js's, which a copy
put there with the sources it imports -- with `--bundle`, `--minify` and
`--sourcemap` as asked, writing `<output_bundle>/<entry point's name>` and
its `.map`. Here the entry point is a file among `srcs` (the copy's files,
which travel as they are), and the bundle is written under the target's
directory, placed in the build directory by install (BuildDirectoryInfo).

The copy's files are staged under the target's directory at their paths
below the bundle's directory first -- flutter_js/src/flutter.js beside the
flutter_js/flutter.js esbuild writes, as GN's build directory has them --
and esbuild runs on the staged entry point with --preserve-symlinks: the
source map's `sources` are paths relative to the bundle's directory, and so
come out as GN's (`src/flutter.js`) rather than as the sandbox's real paths
to the checkout.
"""

load("//engine/src/flutter/build/bazel:build_directory.bzl", "BuildDirectoryInfo", "build_directory_path")

def _esbuild_impl(ctx):
    entry = build_directory_path(ctx.attr.entry_point)
    bundle = build_directory_path(ctx.attr.output_bundle.rstrip("/"))
    if not entry or not bundle:
        fail("%s: entry_point and output_bundle must be paths under the build directory" % ctx.label)

    # The copy's files at their paths under the bundle's directory (where the
    # copy's BuildDirectoryInfo places them), symlinked under the target's
    # directory; the entry point is the one GN names.
    prefix = bundle + "/"
    staged = {}
    for src in ctx.attr.srcs:
        if BuildDirectoryInfo in src:
            for file, path in src[BuildDirectoryInfo].entries.to_list():
                if path.startswith(prefix):
                    link = ctx.actions.declare_file(ctx.label.name + "/" + path[len(prefix):])
                    ctx.actions.symlink(output = link, target_file = file)
                    staged[path] = link
    entry_file = staged.get(entry)
    if entry_file == None:
        fail("%s: no source is placed at %s" % (ctx.label, entry))
    name = entry_file.basename
    js = ctx.actions.declare_file(ctx.label.name + "/" + name)
    outputs = [js]
    entries = [(js, bundle + "/" + name)]
    args = ctx.actions.args()
    if ctx.attr.bundle:
        args.add("--bundle")
    if ctx.attr.minify:
        args.add("--minify")
    if ctx.attr.sourcemap:
        args.add("--sourcemap")
        source_map = ctx.actions.declare_file(ctx.label.name + "/" + name + ".map")
        outputs.append(source_map)
        entries.append((source_map, bundle + "/" + name + ".map"))
    args.add("--preserve-symlinks")
    args.add("--outdir=" + js.dirname)
    args.add(entry_file)
    ctx.actions.run(
        executable = ctx.executable._esbuild,
        arguments = [args],
        inputs = depset(staged.values(), transitive = [depset(ctx.files.srcs)]),
        outputs = outputs,
        mnemonic = "Esbuild",
        progress_message = "Bundling %{label} with esbuild",
    )
    return [
        DefaultInfo(files = depset(outputs)),
        BuildDirectoryInfo(entries = depset(entries)),
    ]

esbuild = rule(
    implementation = _esbuild_impl,
    doc = "build/esbuild/esbuild.gni's esbuild: an entry point and what it imports, bundled.",
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
            doc = "The copy of the sources (GN's public_deps), among which the entry point.",
        ),
        "entry_point": attr.string(
            mandatory = True,
            doc = "GN's entry_point, a path under the build directory the copy places a source at.",
        ),
        "output_bundle": attr.string(
            mandatory = True,
            doc = "GN's output_bundle: the directory under the build directory the bundle goes to.",
        ),
        "bundle": attr.bool(doc = "GN's bundle: --bundle."),
        "minify": attr.bool(doc = "GN's minify: --minify."),
        "sourcemap": attr.bool(doc = "GN's sourcemap: --sourcemap, and the .map beside the bundle."),
        "_esbuild": attr.label(
            default = "@esbuild//:bin/esbuild",
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
)
