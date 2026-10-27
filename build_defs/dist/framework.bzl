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
"""

load("//build_defs/gn:build_directory.bzl", "BuildDirectoryInfo", "build_directory_aspect")
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
