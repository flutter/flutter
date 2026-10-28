# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A macOS framework bundle's symlinks: GN's action over package_framework.py.

A versioned framework bundle (FlutterEmbedder.framework, FlutterMacOS.framework)
keeps its files under `Versions/A/` and reaches them through symlinks:
`Versions/Current -> A`, and at the top `FlutterEmbedder ->
Versions/Current/FlutterEmbedder`, `Resources -> Versions/Current/Resources`,
and so on. GN's embedder and macOS shell files copy the files into place
(copy(), copy_info_plist.py) and run build/config/mac/package_framework.py
once over the bundle to make the symlinks and write a stamp:

    action("generate_symlinks") {
      script = "//build/config/mac/package_framework.py"
      outputs = [ "$root_build_dir/FlutterEmbedder.stamp", "$root_out_dir/FlutterEmbedder.framework", ... ]
      args = [ "--framework", "FlutterEmbedder.framework", "--version", "A",
               "--contents", "FlutterEmbedder", "Resources", "Headers", "Modules",
               "--stamp", "FlutterEmbedder.stamp" ]
      deps = [ ":copy_dylib", ":copy_framework_headers", ... ]
    }

framework_symlinks runs the same script with the same arguments, the bundle
and the stamp at their places under this package's output directory, and
declares each symlink the script makes as a symlink output
(ctx.actions.declare_symlink: Bazel keeps it as the symlink it is, with its
relative target, in sandboxes and archives alike -- zip.py stores it as a
symlink entry, as GN's archive has it). The converter (tools/gn_to_bazel)
writes the call from GN's action, which it knows by its script
(scriptMappings); the copies that fill the bundle are the `deps`, whose
places in the build directory (BuildDirectoryInfo) an archive's directory
entry over the bundle gathers (zip_bundle.bzl) and an install lays out.

xcframework is GN's other framework action, sky/tools/create_xcframework.py
(`xcrun xcodebuild -create-xcframework -framework <bundle> -output
<location>/<name>.xcframework`), mapped the same way: xcodebuild wants the
bundle as a directory, and in a sandbox the bundle's files are links into
the execution root, so xcframework.py assembles each bundle in a scratch
directory from what the deps place under it (files copied by content, the
symlink outputs made again as links) before the script runs; the
xcframework is a directory output, its relative links inside it.

framework_module_check is GN's umbrella-import check of a framework (the
macOS shell's `_generate_symlinks_and_verify_framework_module`, the iOS
shell's `copy_and_verify_framework_module`): a shared_library of one
Objective-C file that imports the framework's umbrella header
(`#import <FlutterMacOS/FlutterMacOS.h>`) with `-F$root_out_dir`, linked
with `-Xlinker -fatal_warnings` -- against the framework where GN's
`frameworks` names it (macOS), against nothing where the check compiles
alone (iOS) -- a build that fails when the module map, the headers or the
links of the assembled bundle are wrong; nothing ships from it. The rule
assembles the bundle the deps place into a directory output
(assemble_bundle.py), compiles the sources through the C++ toolchain's
Objective-C action with `-F` naming that directory's parent, and links the
dynamic library the same way; the converter writes the call from GN's
shared_library when its flags name the build directory as a framework
search path (tools/gn_to_bazel).
"""

load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("//build_defs/gn:build_directory.bzl", "BuildDirectoryInfo", "build_directory_aspect", "collected_build_directory_entries")
load("//build_defs/gn:gn_action.bzl", "PYTHON_ATTRS", "run_python")

def _parsed_arguments(ctx):
    """package_framework.py's arguments: (framework, version, contents, stamp)."""
    framework = None
    version = None
    contents = []
    stamp = None
    option = None
    for arg in ctx.attr.args:
        if arg.startswith("--"):
            option = arg
            continue
        if option == "--framework":
            framework = arg
        elif option == "--version":
            version = arg
        elif option == "--contents":
            contents.append(arg)
        elif option == "--stamp":
            stamp = arg
        else:
            fail("%s: package_framework.py takes --framework, --version, --contents and --stamp; got %r in %s" % (ctx.label, arg, ctx.attr.args))
    if not framework or not stamp:
        fail("%s: --framework and --stamp are required; got %s" % (ctx.label, ctx.attr.args))
    return framework, version, contents, stamp

def _framework_symlinks_impl(ctx):
    framework, version, contents, stamp = _parsed_arguments(ctx)

    # The symlinks the script makes, by their path under the build directory
    # (the bundle sits at the build root, as GN's `$root_out_dir/<bundle>`):
    # Versions/Current to the version, and each content at the top to its
    # file under Versions/Current.
    targets = {}
    if version:
        targets[framework + "/Versions/Current"] = version
    for item in contents:
        targets[framework + "/" + item] = "Versions/Current/" + item
    links = {path: ctx.actions.declare_symlink(path) for path in targets}
    stamp_file = ctx.actions.declare_file(stamp)

    # The script's paths are relative to GN's build directory; here the
    # bundle and the stamp are under this package's output directory, and
    # the script runs from the execution root (run_python).
    root = ctx.bin_dir.path + "/" + ctx.label.package
    arguments = ["--framework", root + "/" + framework]
    if version:
        arguments += ["--version", version]
    if contents:
        arguments += ["--contents"] + contents
    arguments += ["--stamp", stamp_file.path]
    run_python(
        ctx,
        script = ctx.file.script,
        arguments = arguments,
        inputs = [],
        outputs = links.values() + [stamp_file],
        mnemonic = "FrameworkSymlinks",
        progress_message = "Linking %s for %%{label}" % framework,
    )
    outputs = links.values() + [stamp_file]
    return [
        DefaultInfo(files = depset(outputs)),
        BuildDirectoryInfo(entries = depset(
            [(link, path) for path, link in links.items()] + [(stamp_file, stamp)],
        )),
    ]

framework_symlinks = rule(
    implementation = _framework_symlinks_impl,
    doc = "A macOS framework bundle's symlinks and stamp, by build/config/mac/package_framework.py with GN's arguments.",
    attrs = {
        "args": attr.string_list(
            mandatory = True,
            doc = "The script's arguments as GN's action has them: --framework <bundle>, --version <version>, " +
                  "--contents <item>..., --stamp <stamp>; the bundle and the stamp are paths under the build directory.",
        ),
        "deps": attr.label_list(
            aspects = [build_directory_aspect],
            doc = "GN's deps: the copies and actions that put the bundle's files under Versions/<version>/, " +
                  "whose places in the build directory travel with this target's.",
        ),
        "script": attr.label(
            default = "//engine/src/build:config/mac/package_framework.py",
            allow_single_file = True,
            doc = "GN's script.",
        ),
    } | PYTHON_ATTRS,
)

def _built_path(token):
    """The build-directory path a `$(built PATH)` token names, or None for any other argument."""
    if token.startswith("$(built ") and token.endswith(")"):
        path = token[len("$(built "):-1]
        return "" if path == "." else path
    return None

def _xcframework_impl(ctx):
    # GN's `args`: --frameworks <bundle>... --name <name> --location <dir>,
    # the bundles and the directory as path tokens (the converter's
    # actionArgs).
    frameworks = []
    name = None
    location = None
    option = None
    for arg in ctx.attr.args:
        if arg.startswith("--"):
            option = arg
            continue
        if option == "--frameworks":
            path = _built_path(arg)
            if path == None:
                fail("%s: --frameworks takes bundles of the build directory; got %r" % (ctx.label, arg))
            frameworks.append(path)
        elif option == "--name":
            name = arg
        elif option == "--location":
            location = _built_path(arg)
            if location == None:
                fail("%s: --location takes a directory of the build directory; got %r" % (ctx.label, arg))
        else:
            fail("%s: create_xcframework.py takes --frameworks, --name and --location; got %r in %s" % (ctx.label, arg, ctx.attr.args))
    if not frameworks or not name or location == None:
        fail("%s: --frameworks, --name and --location are required; got %s" % (ctx.label, ctx.attr.args))

    # The xcframework: a directory at <location>/<name>.xcframework of the
    # build directory, declared under the package at the same path.
    bundle_path = (location + "/" if location else "") + name + ".xcframework"
    output = ctx.actions.declare_directory(bundle_path)

    # Each framework bundle's files: what the deps' closures place under
    # it in the build directory, by their paths below it.
    placed = {}
    for dep in ctx.attr.deps:
        for file, path in collected_build_directory_entries(dep):
            placed[path] = file
    args = ctx.actions.args()
    args.use_param_file("@%s", use_always = True)
    args.set_param_file_format("multiline")
    args.add("--script", ctx.file.script)
    args.add("--name", name)
    args.add("--location", output.dirname)
    inputs = [ctx.file.script]
    for framework in frameworks:
        entries = sorted([
            (path[len(framework) + 1:], file)
            for path, file in placed.items()
            if path.startswith(framework + "/")
        ])
        if not entries:
            fail("%s: nothing among the deps places files under %s in the build directory" % (ctx.label, framework))
        args.add("--framework", framework.split("/")[-1])
        for path, file in entries:
            args.add("--entry", "%s=%s" % (file.path, path))
            inputs.append(file)
    run_python(
        ctx,
        script = ctx.file._wrapper,
        arguments = [args],
        inputs = inputs,
        outputs = [output],
        mnemonic = "XCFramework",
        progress_message = "Creating %s.xcframework for %%{label}" % name,
    )
    return [
        DefaultInfo(files = depset([output])),
        BuildDirectoryInfo(entries = depset([(output, bundle_path)])),
    ]

xcframework = rule(
    implementation = _xcframework_impl,
    doc = "An xcframework over framework bundles of the build directory, by sky/tools/create_xcframework.py " +
          "(xcrun xcodebuild -create-xcframework) with GN's arguments; the bundles are assembled for it from " +
          "what the deps place (xcframework.py).",
    attrs = {
        "args": attr.string_list(
            mandatory = True,
            doc = "The script's arguments as GN's action has them, the paths as gn_action's tokens: " +
                  "--frameworks $(built <bundle>)..., --name <name>, --location $(built <dir>).",
        ),
        "deps": attr.label_list(
            aspects = [build_directory_aspect],
            doc = "GN's deps: the groups over the bundles' copies and links, whose closures place the bundles' " +
                  "files in the build directory.",
        ),
        "script": attr.label(
            default = "//engine/src/flutter/sky:tools/create_xcframework.py",
            allow_single_file = True,
            doc = "GN's script.",
        ),
        "_wrapper": attr.label(
            default = "//build_defs/dist:xcframework.py",
            allow_single_file = True,
        ),
    } | PYTHON_ATTRS,
)

def _framework_module_check_impl(ctx):
    placed = {}
    for dep in ctx.attr.deps:
        for file, path in collected_build_directory_entries(dep):
            placed[path] = file

    # The bundle: GN's `frameworks` where the check links it (the macOS
    # shell's), else the one bundle the deps place (the iOS shell's check
    # compiles against the bundle and links nothing of it).
    framework = ctx.attr.framework
    if not framework:
        bundles = {path.split("/")[0]: None for path in placed if path.split("/")[0].endswith(".framework")}
        if len(bundles) != 1:
            fail("%s: the deps place %s in the build directory; one <name>.framework is needed (or `framework`)" % (
                ctx.label,
                sorted(bundles.keys()) or "no bundle",
            ))
        framework = bundles.keys()[0]
    if not framework.endswith(".framework"):
        fail("%s: framework names a bundle, <name>.framework; got %r" % (ctx.label, framework))
    bundle_name = framework[:-len(".framework")]

    # The bundle, assembled from what the deps place under it in the build
    # directory, as a directory output named as the bundle is, so that -F
    # on its parent finds <name>.framework.
    assembled = ctx.actions.declare_directory("_framework_check/%s/%s" % (ctx.label.name, framework))
    entries = sorted([
        (path[len(framework) + 1:], file)
        for path, file in placed.items()
        if path.startswith(framework + "/")
    ])
    if not entries:
        fail("%s: nothing among the deps places files under %s in the build directory" % (ctx.label, framework))
    args = ctx.actions.args()
    args.use_param_file("@%s", use_always = True)
    args.set_param_file_format("multiline")
    args.add("--out", assembled.path)
    for path, file in entries:
        args.add("--entry", "%s=%s" % (file.path, path))
    run_python(
        ctx,
        script = ctx.file._assembler,
        arguments = [args],
        inputs = [file for _, file in entries],
        outputs = [assembled],
        mnemonic = "AssembleFramework",
        progress_message = "Assembling %s for %%{label}" % framework,
    )

    # The compile and the link, through the toolchain as a cc rule's: GN's
    # cflags_objc and ldflags with the search path, the framework among
    # the link's frameworks.
    cc_toolchain = find_cc_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        language = "objc",
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    search_path = "-F" + assembled.dirname
    _, compilation_outputs = cc_common.compile(
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        name = ctx.label.name,
        srcs = ctx.files.srcs,
        user_compile_flags = [search_path] + [ctx.expand_make_variables("copts", flag, {}) for flag in ctx.attr.copts],
        local_defines = ctx.attr.local_defines,
        compilation_contexts = [dep[CcInfo].compilation_context for dep in ctx.attr.deps if CcInfo in dep],
        additional_inputs = [assembled],
        language = "objc",
    )
    linking_outputs = cc_common.link(
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        name = ctx.label.name,
        compilation_outputs = compilation_outputs,
        output_type = "dynamic_library",
        user_link_flags = [search_path] + (["-framework", bundle_name] if ctx.attr.framework else []) +
                          [ctx.expand_make_variables("linkopts", flag, {}) for flag in ctx.attr.linkopts],
        additional_inputs = [assembled],
    )
    library = linking_outputs.library_to_link.dynamic_library
    return [DefaultInfo(files = depset([library]))]

framework_module_check = rule(
    implementation = _framework_module_check_impl,
    doc = "GN's umbrella-import check of a framework: the bundle the deps place, assembled, and a dynamic library " +
          "of the sources compiled and linked against it with -F (see the file's docstring). Nothing ships from it.",
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".m", ".mm"],
            mandatory = True,
            doc = "The Objective-C sources that import the framework's umbrella header.",
        ),
        "framework": attr.string(
            doc = "The bundle, <name>.framework, as GN's `frameworks` names it where the check links the framework " +
                  "(the macOS shell's); empty where it does not (the iOS shell's), and the one bundle the deps place " +
                  "in the build directory is the one compiled against.",
        ),
        "deps": attr.label_list(
            aspects = [build_directory_aspect],
            doc = "GN's deps: the copies and links whose closures place the bundle's files in the build directory.",
        ),
        "copts": attr.string_list(doc = "GN's cflags_objc, less the search path the rule sets."),
        "local_defines": attr.string_list(doc = "Defines of the compile."),
        "linkopts": attr.string_list(doc = "GN's ldflags, less the search path and the framework the rule sets."),
        "_assembler": attr.label(
            default = "//build_defs/dist:assemble_bundle.py",
            allow_single_file = True,
        ),
    } | PYTHON_ATTRS,
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(),
)
