# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The recipe's universal Apple artifacts as one target each: a split transition over the builds they join.

CI's Mac builders build each platform and mode in a directory of its own,
and a generator step outside GN joins them (ci/builders/mac_host_engine.json,
mac_ios_engine.json: the `generators` tasks): sky/tools/
create_macos_framework.py lipos the arm64 and the x64 build's
FlutterMacOS.framework into one and makes FlutterMacOS.xcframework of it;
create_macos_gen_snapshots.py gathers the two builds' universal
gen_snapshot_arm64 and gen_snapshot_x64; create_ios_framework.py lipos the
two simulator builds' Flutter.framework, makes Flutter.xcframework of the
device's and the simulator's (and the extension-safe pair's), and takes the
device build's gen_snapshot_arm64. Their outputs are what the flutter tool's
cache unpacks as darwin-x64*/FlutterMacOS.xcframework, gen_snapshot_<cpu>
and ios*/Flutter.xcframework.

apple_universal is the generator step as a Bazel target: a split transition
builds `deps` once per platform of `builds` -- the mode stays the current
one, so a release build's framework joins release builds (in_configuration
chooses the mode) -- and the recipe's own script runs over them, each laid
out in a scratch directory as the part of its build directory the script
reads (the framework bundle's files and links, universal/gen_snapshot_<cpu>;
BuildDirectoryInfo says where each file sits). The script's `--dst` is a
scratch directory too, and the declared outputs are copied out of it
(universal.py). Nothing here reads GN; the targets live in the archives
appendix (tools/gn_to_bazel's manifest) beside the archives the recipe
uploads them in.
"""

load("//build_defs/config:platforms.bzl", "RUNTIME_MODE_FLAG", "runtime_mode_platform_base", "runtime_mode_platform_name")
load("//build_defs/gn:build_directory.bzl", "BuildDirectoryInfo", "build_directory_aspect", "collected_build_directory_entries")
load("//build_defs/gn:gn_action.bzl", "PYTHON_ATTRS", "run_python")

# The engine's platforms, whose runtime-mode children the split names
# (platforms.bzl's runtime_mode_platforms).
_TOOLCHAINS = "//engine/src/flutter/build/bazel/toolchains"

def _builds_transition_impl(settings, attr):
    # One configuration per build: the platform's child for the current
    # runtime mode -- or for the mode the platform's name carries
    # (`ios_sim_x64_debug`: the iOS recipe joins a profile or release
    # device build with the debug simulator builds) -- the mode's flag set
    # alongside, as in_configuration does, for the execution configuration
    # the build's tools come from. A build of the current mode keeps the
    # current compilation mode; one of a carried mode is built optimized,
    # as the builders build it (ci/builders: every mode but an --unoptimized
    # debug is -c opt), and so once, whichever mode's artifact wants it.
    mode = settings[RUNTIME_MODE_FLAG]
    compilation_mode = settings["//command_line_option:compilation_mode"]
    configurations = {}
    for key, platform in attr.builds.items():
        base = runtime_mode_platform_base(platform)
        carried = base != platform
        build_mode = platform[len(base) + 1:] if carried else mode
        configurations[key] = {
            "//command_line_option:compilation_mode": "opt" if carried else compilation_mode,
            "//command_line_option:platforms": ["%s:%s" % (_TOOLCHAINS, runtime_mode_platform_name(base, build_mode))],
            RUNTIME_MODE_FLAG: build_mode,
        }
    return configurations

_builds_transition = transition(
    implementation = _builds_transition_impl,
    inputs = [
        "//command_line_option:compilation_mode",
        RUNTIME_MODE_FLAG,
    ],
    outputs = [
        "//command_line_option:compilation_mode",
        "//command_line_option:platforms",
        RUNTIME_MODE_FLAG,
    ],
)

def _apple_universal_impl(ctx):
    if not ctx.attr.directories and not ctx.attr.files:
        fail("%s: name the script's outputs to keep (directories and/or files)" % ctx.label)

    args = ctx.actions.args()
    args.use_param_file("@%s", use_always = True)
    args.set_param_file_format("multiline")
    args.add("--script", ctx.file.script)
    inputs = [ctx.file.script] + ctx.files.script_deps

    # Each build's part of its build directory: the entries of its deps'
    # closures under the paths the script reads, by their build-directory
    # paths (a framework bundle's links among them, made again as links).
    for key in ctx.attr.builds:
        args.add("--build", key)
        staged = {}
        for dep in ctx.split_attr.deps[key]:
            for file, path in collected_build_directory_entries(dep):
                if [prefix for prefix in ctx.attr.stage if path == prefix or path.startswith(prefix + "/")]:
                    staged[path] = file
        if not staged:
            fail("%s: the %s build's deps place nothing under %s in the build directory" % (ctx.label, key, ctx.attr.stage))
        for path, file in sorted(staged.items()):
            args.add("--entry", "%s=%s" % (file.path, path))
            inputs.append(file)
    for alias, key in ctx.attr.aliases.items():
        if key not in ctx.attr.builds:
            fail("%s: alias %s names no build (%s)" % (ctx.label, alias, key))
        args.add("--alias", "%s=%s" % (alias, key))

    # The script's arguments, `{build:<key>}` and `{dst}` expanded by the
    # wrapper to the scratch directories.
    for arg in ctx.attr.args:
        args.add("--arg", arg)

    # The outputs, under the target's own directory so that two targets'
    # FlutterMacOS.xcframework do not meet.
    outputs = []
    entries = []
    for path in ctx.attr.directories:
        output = ctx.actions.declare_directory(ctx.label.name + "/" + path)
        args.add("--output", "%s=%s" % (path, output.path))
        outputs.append(output)
        entries.append((output, ctx.label.name + "/" + path))
    for path in ctx.attr.files:
        output = ctx.actions.declare_file(ctx.label.name + "/" + path)
        args.add("--output", "%s=%s" % (path, output.path))
        outputs.append(output)
        entries.append((output, ctx.label.name + "/" + path))

    run_python(
        ctx,
        script = ctx.file._wrapper,
        arguments = [args],
        inputs = inputs,
        outputs = outputs,
        mnemonic = "AppleUniversal",
        progress_message = "Joining the %s builds for %%{label}" % ", ".join(ctx.attr.builds.keys()),
    )
    return [
        DefaultInfo(files = depset(outputs)),
        BuildDirectoryInfo(entries = depset(entries)),
        OutputGroupInfo(**{path.replace("/", "_").replace(".", "_"): depset([output]) for output, path in zip(outputs, ctx.attr.directories + ctx.attr.files)}),
    ]

apple_universal = rule(
    implementation = _apple_universal_impl,
    doc = "The recipe's generator step over several platforms' builds (create_macos_framework.py, " +
          "create_macos_gen_snapshots.py, create_ios_framework.py) as one target: `deps` built once per " +
          "platform of `builds` in the current runtime mode (a split transition), laid out as their build " +
          "directories under `stage`, the script run over them, its named outputs kept.",
    attrs = {
        "script": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "The recipe's script (sky/tools/create_macos_framework.py, ...).",
        ),
        "script_deps": attr.label_list(
            allow_files = True,
            doc = "The modules the script imports from its directory (sky_utils.py, create_xcframework.py).",
        ),
        "builds": attr.string_dict(
            mandatory = True,
            doc = "The builds the script joins: a key the script's arguments name (`{build:arm64}`) mapped to " +
                  "a platform's base name in //engine/src/flutter/build/bazel/toolchains (`macos_arm64`, " +
                  "`ios_sim_x64`), whose child for the current runtime mode is built in the current compilation " +
                  "mode -- or to a mode's own (`ios_sim_x64_debug`), built as named and optimized (-c opt, the " +
                  "builders' way) whatever the current mode, so once for every mode's artifact.",
        ),
        "deps": attr.label_list(
            mandatory = True,
            cfg = _builds_transition,
            aspects = [build_directory_aspect],
            doc = "The targets whose build-directory entries each build lays out: the framework's group " +
                  "(shell/platform/darwin/macos:universal_flutter_framework), lib/snapshot's universal gen_snapshot.",
        ),
        "stage": attr.string_list(
            mandatory = True,
            doc = "The build-directory paths the script reads, which are laid out (`FlutterMacOS.framework`, " +
                  "`universal`): a directory's entries, or one file.",
        ),
        "aliases": attr.string_dict(
            doc = "Further names for a build's directory (`arm64_extension_safe` for `arm64`: " +
                  "create_ios_framework.py reads the extension-safe frameworks from `<out dir>_extension_safe`, " +
                  "which under Bazel is the same build; build/bazel/README.md).",
        ),
        "args": attr.string_list(
            mandatory = True,
            doc = "The script's arguments; `{build:<key>}` is a build's directory, `{dst}` the script's output " +
                  "directory (`--dst {dst} --arm64-out-dir {build:arm64} --x64-out-dir {build:x64}`), " +
                  "`--dsym --strip` as the recipe gives them per mode.",
        ),
        "directories": attr.string_list(
            doc = "The directories under the script's --dst to keep, as directory outputs (`FlutterMacOS.xcframework`).",
        ),
        "files": attr.string_list(
            doc = "The files under the script's --dst to keep (`gen_snapshot_arm64`).",
        ),
        "_wrapper": attr.label(
            default = "//build_defs/dist:universal.py",
            allow_single_file = True,
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    } | PYTHON_ATTRS,
)
