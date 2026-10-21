# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""build/esbuild/esbuild.gni's `esbuild` template, as a rule.

GN runs the prebuilt esbuild (`$host_prebuilts_path/esbuild/bin/esbuild`)
over an entry point under the build directory -- flutter.js's, which a copy
put there with the sources it imports -- with `--bundle`, `--minify` and
`--sourcemap` as asked, writing `<output_bundle>/<entry point's name>` and
its `.map`. Here the entry point is a file among `srcs` (the copy's files,
which travel as they are: esbuild resolves the imports beside the entry
point), and the bundle is written under the target's directory, placed in
the build directory by install (BuildDirectoryInfo).
"""

load("//engine/src/flutter/build/bazel:build_directory.bzl", "BuildDirectoryInfo", "build_directory_path")

def _esbuild_impl(ctx):
    entry = build_directory_path(ctx.attr.entry_point)
    bundle = build_directory_path(ctx.attr.output_bundle.rstrip("/"))
    if not entry or not bundle:
        fail("%s: entry_point and output_bundle must be paths under the build directory" % ctx.label)

    # The entry point among the sources: the copy's file whose destination
    # is GN's entry point (the copy's BuildDirectoryInfo places it).
    entry_file = None
    for src in ctx.attr.srcs:
        if BuildDirectoryInfo in src:
            for file, path in src[BuildDirectoryInfo].entries.to_list():
                if path == entry:
                    entry_file = file
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
    args.add("--outdir=" + js.dirname)
    args.add(entry_file)
    ctx.actions.run(
        executable = ctx.executable._esbuild,
        arguments = [args],
        inputs = ctx.files.srcs,
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
