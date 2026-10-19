# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""web_sdk.gni's sdk_rewriter template, as a rule.

`sdk_rewriter` runs web_sdk/sdk_rewriter.dart under the prebuilt Dart SDK
(GN's prebuilt_dart_action, with the Dart tree's package configuration for
its package:args and package:path) over a directory of the web engine's
sources, rewriting each into a part of a `dart:` library under an output
directory, with the library's API file beside them. The engine's one use
outside the web SDK itself is sky/packages/sky_engine's
`web_ui_ui_web_with_output`: dart:ui_web's sources into the sky_engine
package's lib/ui_web/, which `web_ui_ui_web_with_output` below spells out as
the GN template does. The outputs are declared one per source (the script's
layout: `<library>/<path under the input directory>` and the API file's
name), so that install can place them (BuildDirectoryInfo) and anything
can depend on them.
"""

load("//engine/src/flutter/build/bazel:build_directory.bzl", "BuildDirectoryInfo", "build_directory_path")

def _sdk_rewriter_impl(ctx):
    input_dir = ctx.attr.input_dir.strip("/")
    outputs = []
    for src in ctx.files.srcs:
        if not src.short_path.startswith(input_dir + "/"):
            fail("%s: %s is not under the input directory %s" % (ctx.label, src.short_path, input_dir))
        relative = src.short_path[len(input_dir) + 1:]

        # The script's own selection.
        if not relative.endswith(".dart") or relative.endswith("_test.dart"):
            continue
        outputs.append(ctx.actions.declare_file(ctx.label.name + "/" + ctx.attr.library_name + "/" + relative))
    api = ctx.actions.declare_file(ctx.label.name + "/" + ctx.file.api_file.basename)
    stamp = ctx.actions.declare_file(ctx.label.name + ".stamp")
    depfile = ctx.actions.declare_file(ctx.label.name + ".d")
    dart = [f for f in ctx.files._sdk if f.basename == "dart" and f.dirname.endswith("/bin")]
    if len(dart) != 1:
        fail("%s: the SDK filegroup must hold one bin/dart, holds %s" % (ctx.label, dart))
    args = ctx.actions.args()
    args.add("--packages=" + ctx.file.package_config.path)
    args.add(ctx.file._script)
    args.add("--build-dir=.")
    args.add("--output-dir=" + api.dirname)

    # With the trailing slash GN's rebase_path keeps: the script takes each
    # source's path under the directory by stripping its length.
    args.add("--input-dir=" + input_dir + "/")
    args.add("--depfile", depfile)
    args.add("--stamp", stamp)
    if ctx.attr.public:
        args.add("--public")
    args.add("--library-name=" + ctx.attr.library_name)
    args.add("--api-file=" + ctx.file.api_file.path)
    ctx.actions.run(
        executable = dart[0],
        arguments = [args],
        inputs = depset(
            ctx.files.srcs + [ctx.file.api_file, ctx.file._script, ctx.file.package_config],
            transitive = [depset(ctx.files._sdk), depset(ctx.files.packages)],
        ),
        outputs = outputs + [api, stamp, depfile],
        mnemonic = "SdkRewriter",
        progress_message = "Rewriting %{label} for the SDK",
    )
    entries = []
    under = build_directory_path(ctx.attr.output_dir.rstrip("/"))
    if under:
        for output in outputs + [api]:
            entries.append((output, under + "/" + output.path[len(api.dirname) + 1:]))
    return [
        DefaultInfo(files = depset(outputs + [api])),
        BuildDirectoryInfo(entries = depset(entries)),
    ]

sdk_rewriter = rule(
    implementation = _sdk_rewriter_impl,
    doc = "web_sdk.gni's sdk_rewriter: a directory of sources rewritten into parts of a dart: library.",
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
            doc = "The sources under input_dir (the script takes the .dart files, tests excluded).",
        ),
        "input_dir": attr.string(
            mandatory = True,
            doc = "The directory the sources are rewritten from, as a path of this repository.",
        ),
        "api_file": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The library's API file (GN's api_file).",
        ),
        "library_name": attr.string(
            mandatory = True,
            doc = "The dart: library's name (GN's library_name).",
        ),
        "public": attr.bool(
            doc = "GN's is_public.",
        ),
        "output_dir": attr.string(
            mandatory = True,
            doc = "GN's output_dir, as GN wrote it (`$root_gen_dir/...`): where the build directory holds the outputs.",
        ),
        "package_config": attr.label(
            default = "@dart//:.dart_tool/package_config.json",
            allow_single_file = True,
            doc = "The package configuration the script runs under (GN's dart_sdk_package_config).",
        ),
        "packages": attr.label_list(
            default = ["@dart//:script_packages"],
            allow_files = True,
            doc = "The packages the configuration resolves the script's imports to.",
        ),
        "_script": attr.label(
            default = "//engine/src/flutter/web_sdk:sdk_rewriter.dart",
            allow_single_file = True,
        ),
        "_sdk": attr.label_list(
            default = ["@dart_sdk_linux_x64//:dart"],
            allow_files = True,
            doc = "The prebuilt SDK: dart with its libraries and snapshots.",
        ),
    },
)

def web_ui_ui_web_with_output(name, output_dir, **kwargs):
    """web_sdk.gni's web_ui_ui_web_with_output: dart:ui_web's sources rewritten into `output_dir`.

    Args:
      name: the target's name.
      output_dir: GN's output_dir (`$root_gen_dir/dart-pkg/sky_engine/lib/ui_web/`).
      **kwargs: the rule's other arguments (visibility, tags).
    """
    sdk_rewriter(
        name = name,
        srcs = ["//engine/src/flutter:ui_web_sources"],
        input_dir = "engine/src/flutter/lib/web_ui/lib/ui_web/src/ui_web",
        api_file = "//engine/src/flutter:lib/web_ui/lib/ui_web/src/ui_web.dart",
        library_name = "ui_web",
        public = True,
        output_dir = output_dir,
        **kwargs
    )
