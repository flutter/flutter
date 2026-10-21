# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The web SDK's Dart side: web_sdk.gni's templates and web_sdk/BUILD.gn's, as rules.

GN assembles `$root_out_dir/flutter_web_sdk` in three steps (web_sdk/BUILD.gn):

  1. `sdk_rewriter` runs web_sdk/sdk_rewriter.dart under the prebuilt Dart
     SDK (GN's prebuilt_dart_action, with the Dart tree's package
     configuration for its package:args and package:path) over a directory
     of the web engine's sources, rewriting each into a part of a `dart:`
     library under an output directory (`lib/_engine/`, `lib/ui/`, ...),
     with the library's API file beside them; `copy("web_ui_library")`
     puts libraries.json at the root.
  2. `_compile_platform` compiles those libraries, with the Dart SDK's own,
     to a platform kernel for each of dart2js, dart2wasm and DDC
     (`kernel/*.dill`): the SDK's kernel_worker, reading the libraries
     through a multi-root file system whose roots are flutter_web_sdk and
     the directory holding the prebuilt `dart-sdk`
     (libraries.json includes `../dart-sdk/lib/libraries.json`).
  3. `_compile_ddc_sdk` compiles them to JavaScript for DDC's stable and
     canary module systems (`kernel/ddc/{stable,canary}/dart_sdk.js`).

Here the rewriters declare their outputs one per source (the script's
layout: `<library>/<path under the input directory>` and the API file's
name), so that install can place them (BuildDirectoryInfo) and anything can
depend on them; `web_sdk_root` stages the whole tree the compilers read --
the rewriters' outputs at their build-directory paths under
`flutter_web_sdk/`, libraries.json, and the prebuilt SDK's lib/ under
`dart-sdk/` -- as a directory of symlinks, which the two compile rules name
as their multi-roots (relative paths: the workers resolve them against the
working directory, as GN's absolute `file:///` URIs resolve). The engine's
one use of sdk_rewriter outside the web SDK is sky/packages/sky_engine's
`web_ui_ui_web_with_output`, which the macro of that name spells out as the
GN template does.
"""

load("//engine/src/flutter/build/bazel:build_directory.bzl", "BuildDirectoryInfo", "build_directory_path")

# BUILD.gn's web_engine_libraries: the targets whose outputs assemble
# flutter_web_sdk/lib, which every compilation step reads.
WEB_ENGINE_LIBRARIES = [
    "//engine/src/flutter/web_sdk:skwasm_impl_library",
    "//engine/src/flutter/web_sdk:skwasm_stub_library",
    "//engine/src/flutter/web_sdk:web_engine_library",
    "//engine/src/flutter/web_sdk:web_ui_library",
    "//engine/src/flutter/web_sdk:web_ui_ui_web",
    "//engine/src/flutter/web_sdk:web_ui_library_sources",
    "//engine/src/flutter/web_sdk:web_test_fonts_library",
    "//engine/src/flutter/web_sdk:web_locale_keymap_library",
]

_PREBUILT_SDK = "@dart_sdk_linux_x64"

def _sdk_rewriter_impl(ctx):
    input_dir = ctx.attr.input_dir.strip("/")
    ui = ctx.attr.ui
    if not ui and not ctx.attr.library_name:
        fail("%s: library_name must be given unless ui is" % ctx.label)
    outputs = []
    for src in ctx.files.srcs:
        if not src.short_path.startswith(input_dir + "/"):
            fail("%s: %s is not under the input directory %s" % (ctx.label, src.short_path, input_dir))
        relative = src.short_path[len(input_dir) + 1:]

        # The script's own selection.
        if not relative.endswith(".dart") or relative.endswith("_test.dart"):
            continue
        if ctx.attr.exclude and src.short_path.startswith(ctx.attr.exclude.strip("/") + "/"):
            continue
        within = relative if ui else ctx.attr.library_name + "/" + relative
        outputs.append(ctx.actions.declare_file(ctx.label.name + "/" + within))
    output_dir = ctx.bin_dir.path + "/" + ctx.label.package + "/" + ctx.label.name
    api = None
    if ctx.file.api_file:
        api = ctx.actions.declare_file(ctx.label.name + "/" + ctx.file.api_file.basename)
        outputs.append(api)
    stamp = ctx.actions.declare_file(ctx.label.name + ".stamp")
    depfile = ctx.actions.declare_file(ctx.label.name + ".d")
    dart = [f for f in ctx.files._sdk if f.basename == "dart" and f.dirname.endswith("/bin")]
    if len(dart) != 1:
        fail("%s: the SDK filegroup must hold one bin/dart, holds %s" % (ctx.label, dart))
    args = ctx.actions.args()
    args.add("--packages=" + ctx.file.package_config.path)
    args.add(ctx.file._script)
    args.add("--build-dir=.")
    args.add("--output-dir=" + output_dir)

    # With the trailing slash GN's rebase_path keeps: the script takes each
    # source's path under the directory by stripping its length.
    args.add("--input-dir=" + input_dir + "/")
    args.add("--depfile", depfile)
    args.add("--stamp", stamp)
    if ctx.attr.exclude:
        # The script skips what starts with the pattern; the sandbox holds
        # the declared sources alone, but the argument is GN's.
        args.add("--exclude-pattern=" + ctx.attr.exclude.strip("/"))
    if ctx.attr.public:
        args.add("--public")
    if ui:
        args.add("--ui")
    else:
        args.add("--library-name=" + ctx.attr.library_name)
    if api:
        args.add("--api-file=" + ctx.file.api_file.path)
    ctx.actions.run(
        executable = dart[0],
        arguments = [args],
        inputs = depset(
            ctx.files.srcs + ([ctx.file.api_file] if api else []) + [ctx.file._script, ctx.file.package_config],
            transitive = [depset(ctx.files._sdk), depset(ctx.files.packages)],
        ),
        outputs = outputs + [stamp, depfile],
        mnemonic = "SdkRewriter",
        progress_message = "Rewriting %{label} for the SDK",
    )
    entries = []
    under = build_directory_path(ctx.attr.output_dir.rstrip("/"))
    if under:
        for output in outputs:
            entries.append((output, under + "/" + output.path[len(output_dir) + 1:]))
    return [
        DefaultInfo(files = depset(outputs)),
        BuildDirectoryInfo(entries = depset(entries)),
    ]

sdk_rewriter = rule(
    implementation = _sdk_rewriter_impl,
    doc = "web_sdk.gni's sdk_rewriter: a directory of sources rewritten into parts of a dart: library " +
          "(or, with `ui`, into dart:ui itself).",
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
        "exclude": attr.string(
            doc = "A directory under input_dir whose files are left out (GN's exclude_pattern), as a path of this repository.",
        ),
        "api_file": attr.label(
            allow_single_file = True,
            doc = "The library's API file (GN's api_file).",
        ),
        "library_name": attr.string(
            doc = "The dart: library's name (GN's library_name); not with `ui`.",
        ),
        "ui": attr.bool(
            doc = "GN's ui: the sources are dart:ui's own, rewritten in place rather than into a library's directory.",
        ),
        "public": attr.bool(
            doc = "GN's is_public.",
        ),
        "output_dir": attr.string(
            mandatory = True,
            doc = "GN's output_dir, as GN wrote it (`$root_out_dir/...`): where the build directory holds the outputs.",
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
            default = [_PREBUILT_SDK + "//:dart"],
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

# ---------------------------------------------------------------------------
# The staged tree the compilers read
# ---------------------------------------------------------------------------

WebSdkRootInfo = provider(
    doc = "The staged flutter_web_sdk tree and the prebuilt SDK beside it.",
    fields = {
        "directory": "The directory holding flutter_web_sdk/ and dart-sdk/, relative to the execution root.",
        "files": "The staged files (symlinks), a depset.",
    },
)

_WEB_SDK = "flutter_web_sdk/"

def _repository_path(file):
    # A file of another repository, relative to that repository's root.
    root = file.owner.workspace_root
    if root and file.path.startswith(root + "/"):
        return file.path[len(root) + 1:]
    return file.short_path

def _web_sdk_root_impl(ctx):
    root = ctx.label.name
    staged = []
    seen = {}
    for library in ctx.attr.libraries:
        for file, path in library[BuildDirectoryInfo].entries.to_list():
            if not path.startswith(_WEB_SDK):
                fail("%s: %s puts %s outside flutter_web_sdk (%s)" % (ctx.label, library.label, file.short_path, path))
            if path in seen:
                fail("%s: %s is placed twice (%s, %s)" % (ctx.label, path, seen[path], library.label))
            seen[path] = library.label
            link = ctx.actions.declare_file(root + "/" + path)
            ctx.actions.symlink(output = link, target_file = file)
            staged.append(link)
    for file in ctx.files.sdk:
        link = ctx.actions.declare_file(root + "/dart-sdk/" + _repository_path(file))
        ctx.actions.symlink(output = link, target_file = file)
        staged.append(link)
    directory = ctx.bin_dir.path + "/" + ctx.label.package + "/" + root
    return [
        DefaultInfo(files = depset(staged)),
        WebSdkRootInfo(directory = directory, files = depset(staged)),
    ]

web_sdk_root = rule(
    implementation = _web_sdk_root_impl,
    doc = "The flutter_web_sdk tree GN assembles in the build directory, staged beside the prebuilt dart-sdk " +
          "for the compilers' multi-root file system.",
    attrs = {
        "libraries": attr.label_list(
            providers = [BuildDirectoryInfo],
            mandatory = True,
            doc = "The rewriters and copies whose outputs are the tree (BUILD.gn's web_engine_libraries).",
        ),
        "sdk": attr.label_list(
            default = [_PREBUILT_SDK + "//:lib"],
            allow_files = True,
            doc = "The prebuilt SDK's lib/ (its libraries.json and sources), staged as dart-sdk/lib.",
        ),
    },
)

# ---------------------------------------------------------------------------
# The compilers
# ---------------------------------------------------------------------------

def _kernel_output(ctx, path):
    # GN's output path under the build directory ($root_out_dir/flutter_web_sdk/kernel/...):
    # the file here under kernel/, placed there by install.
    under = build_directory_path(path)
    if not under or not under.startswith(_WEB_SDK + "kernel/"):
        fail("%s: %s is not under flutter_web_sdk/kernel" % (ctx.label, path))
    return ctx.actions.declare_file(under[len(_WEB_SDK):]), under

def _snapshot_args(ctx, snapshot):
    # GN's _dartdevc and _kernel_worker: gn_run_binary.py running the
    # prebuilt SDK's dartaotruntime on an AOT snapshot of the tool, whose
    # path leads the arguments.
    args = ctx.actions.args()
    args.add(ctx.file._kernel_worker if snapshot == "kernel_worker" else ctx.file._dartdevc)
    return args

def _run_snapshot(ctx, args, inputs, outputs, mnemonic, progress_message):
    ctx.actions.run(
        executable = ctx.executable._dartaotruntime,
        # The caller's Args object (_snapshot_args and what it added).
        # buildifier: disable=pass-args-to-actions
        arguments = [args],
        inputs = depset(
            inputs + [ctx.file._kernel_worker, ctx.file._dartdevc, ctx.file.package_config],
            transitive = [ctx.attr.root[WebSdkRootInfo].files],
        ),
        outputs = outputs,
        mnemonic = mnemonic,
        progress_message = progress_message,
    )

_COMPILER_ATTRS = {
    "root": attr.label(
        default = "//engine/src/flutter/web_sdk:flutter_web_sdk_root",
        providers = [WebSdkRootInfo],
        doc = "The staged tree (web_sdk_root).",
    ),
    "package_config": attr.label(
        default = "@dart//:.dart_tool/package_config.json",
        allow_single_file = True,
        doc = "GN's dart_sdk_package_config.",
    ),
    "_dartaotruntime": attr.label(
        default = _PREBUILT_SDK + "//:bin/dartaotruntime",
        allow_single_file = True,
        executable = True,
        cfg = "exec",
    ),
    "_kernel_worker": attr.label(
        default = _PREBUILT_SDK + "//:bin/snapshots/kernel_worker_aot.dart.snapshot",
        allow_single_file = True,
    ),
    "_dartdevc": attr.label(
        default = _PREBUILT_SDK + "//:bin/snapshots/dartdevc_aot.dart.snapshot",
        allow_single_file = True,
    ),
}

# The libraries every compilation names (BUILD.gn's --source list), and the
# skwasm one by target.
_SOURCES = ["dart:core", "dart:ui", "dart:ui_web", "dart:_engine"]
_LAST_SOURCE = "dart:_web_locale_keymap"

def _web_platform_dill_impl(ctx):
    root = ctx.attr.root[WebSdkRootInfo].directory
    output, under = _kernel_output(ctx, ctx.attr.output_dill)
    target = ctx.attr.kernel_target
    args = _snapshot_args(ctx, "kernel_worker")
    args.add("--summary-only" if ctx.attr.summary_only else "--no-summary-only")
    if ctx.attr.null_environment:
        args.add("--null-environment")
    skwasm = "dart:_skwasm_impl" if target == "dart2wasm" else "dart:_skwasm_stub"
    if target == "ddc":
        args.add("--include-unsupported-platform-library-stubs")
    args.add("--target", target)
    args.add("--packages-file", ctx.file.package_config)
    args.add("--multi-root-scheme", "org-dartlang-sdk")
    args.add("--multi-root", root + "/" + _WEB_SDK)
    args.add("--libraries-file", "org-dartlang-sdk:///libraries.json")
    args.add("--output", output)
    for source in _SOURCES + [skwasm, _LAST_SOURCE]:
        args.add("--source", source)
    args.add("--multi-root", root + "/")
    _run_snapshot(
        ctx,
        args,
        inputs = [],
        outputs = [output],
        mnemonic = "WebPlatformDill",
        progress_message = "Compiling the web platform %{label}",
    )
    return [
        DefaultInfo(files = depset([output])),
        BuildDirectoryInfo(entries = depset([(output, under)])),
    ]

web_platform_dill = rule(
    implementation = _web_platform_dill_impl,
    doc = "web_sdk/BUILD.gn's _compile_platform: the web libraries to a platform kernel for one compiler target.",
    attrs = {
        "kernel_target": attr.string(
            mandatory = True,
            values = ["ddc", "dart2js", "dart2wasm"],
            doc = "GN's kernel_target.",
        ),
        "summary_only": attr.bool(doc = "GN's summary_only: an outline rather than the full kernel."),
        "null_environment": attr.bool(doc = "GN's null_environment."),
        "output_dill": attr.string(
            mandatory = True,
            doc = "GN's output_dill, as GN wrote it (`$root_out_dir/flutter_web_sdk/kernel/...`).",
        ),
    } | _COMPILER_ATTRS,
)

def _ddc_sdk_impl(ctx):
    root = ctx.attr.root[WebSdkRootInfo].directory
    channel = "canary" if ctx.attr.canary else "stable"
    under = _WEB_SDK + "kernel/ddc/" + channel + "/dart_sdk.js"
    js = ctx.actions.declare_file("kernel/ddc/" + channel + "/dart_sdk.js")
    source_map = ctx.actions.declare_file("kernel/ddc/" + channel + "/dart_sdk.js.map")
    args = _snapshot_args(ctx, "dartdevc")
    args.add("--compile-sdk")
    args.add_all(_SOURCES + ["dart:_skwasm_stub", _LAST_SOURCE])
    args.add("--no-summarize")
    args.add("--packages", ctx.file.package_config)
    args.add("--multi-root-scheme", "org-dartlang-sdk")
    args.add("--multi-root", root + "/" + _WEB_SDK)

    # GN: the build directory, which the source map's paths are made
    # relative to -- flutter_web_sdk/kernel/ddc/<channel>/dart_sdk.js sits
    # four directories below it. Here the output sits as deep below this
    # package's parent (web_sdk/kernel/ddc/<channel>/), so that directory
    # stands in and the map's paths come out as GN's
    # (`../../../../dart-sdk/lib/...`).
    package_parent = ctx.label.package.rsplit("/", 1)[0] if "/" in ctx.label.package else ""
    args.add("--multi-root-output-path", ctx.bin_dir.path + "/" + package_parent + "/")
    args.add("--libraries-file", "org-dartlang-sdk:///libraries.json")
    args.add("--inline-source-map")
    args.add("-DFLUTTER_WEB_USE_SKIA=true")
    args.add("--modules", "ddc")
    args.add("-o", js)
    if ctx.attr.canary:
        args.add("--canary")
    args.add("--multi-root", root + "/")
    _run_snapshot(
        ctx,
        args,
        inputs = [],
        outputs = [js, source_map],
        mnemonic = "DdcSdk",
        progress_message = "Compiling the web SDK with DDC (%s) %%{label}" % channel,
    )
    return [
        DefaultInfo(files = depset([js, source_map])),
        BuildDirectoryInfo(entries = depset([(js, under), (source_map, under + ".map")])),
    ]

ddc_sdk = rule(
    implementation = _ddc_sdk_impl,
    doc = "web_sdk/BUILD.gn's _compile_ddc_sdk: the web libraries compiled to JavaScript by DDC, stable or canary.",
    attrs = {
        "canary": attr.bool(doc = "GN's canary: DDC's canary module system rather than the stable one."),
    } | _COMPILER_ATTRS,
)
