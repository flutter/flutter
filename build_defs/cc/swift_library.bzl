# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""flutter_swift_library: a GN source_set of Swift sources, compiled as GN's `tool("swift")` compiles it.

GN's mac toolchain (build/toolchain/mac/BUILD.gn) runs Chromium's
build/toolchain/darwin/swiftc.py over a target's Swift sources: one module
(`-module-name`, the target's name), a bridging header for the Objective-C
the Swift imports (`-import-objc-header`), the module's generated
Objective-C header for the Objective-C that imports the Swift
(`-emit-objc-header`; `--fix-generated-header` rewrites its imports for a
build without -fmodules), one object file per source, the swiftmodule and
its companions, and a depfile. This rule runs the same script with the same
arguments -- build/config/darwin's compiler config's `-sdk`, `-target
<arch>-apple-macos<deployment target>` and `-swift-version 5`; the compiler
config's `-Onone` in an unoptimized build and `-O` in an optimized one,
`-g` (GN's symbols config on Apple); `--whole-module-optimization`
(swift_whole_module_optimization is is_official_build, true in every
engine build); `--mac-host-toolchain-path` for the Testing plugin --
and gives the result the shape of a cc_library: its CcInfo has the
generated header (at `<package>/<name>/<name>.h`, GN's
`$target_gen_dir/<name>/<name>.h`, which an include of
`flutter/.../<name>/<name>.h` reaches through include_root's bin twin) and
the objects archived, `alwayslink` as a source_set's objects are
(-force_load on a Mac), with `-L` for the SDK's and the toolchain's Swift
libraries (GN's `lib_dirs = mac_swift_lib_paths`, darwin_sdk.gni) so that
the objects' autolink entries (swiftCore and the rest) resolve in whatever
links them.

The bridging header's imports are the deps' headers: their include
directories go to swiftc.py as `-I` (which it hands to both Swift and its
clang importer) and their defines as `-D`. The Swift compiler is Xcode's,
through /usr/bin/swiftc and xcode-select or DEVELOPER_DIR (--action_env),
as `metal` is for the shaders; the SDK is named by its path (@macos_sdk's,
the same Xcode the toolchain's sysroot comes from), so the action's key
carries it and an Xcode change recompiles. Off macOS the toolchains have
no Swift and the converter marks the target incompatible.

The converter emits one for a GN source_set whose sources are `.swift`
(`bridge_header`, `swiftflags` and `public` as attributes):

    flutter_swift_library(
        name = "InternalFlutterSwiftCommon",
        srcs = ["framework/Source/Logger.swift", ...],
        bridge_header = "InternalFlutterSwiftCommon-Bridging-Header.h",
        hdrs = [...],
        swiftflags = select({unittests: ["-enable-testing"], default: []}),
        deps = [":flutter_engine_bindings"],
        target_compatible_with = select({macos: [], default: ["@platforms//:incompatible"]}),
    )
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@macos_sdk//:sdk.bzl", "MACOS_SDK_PATH", "XCODE_DEVELOPER_DIR")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load(":apple.bzl", "MACOS_DEPLOYMENT_TARGET")

# The toolchain of the host's Xcode (darwin_sdk.gni's mac_host_toolchain_path:
# the Swift libraries' second directory, and swiftc.py's Testing plugin).
_XCODE_TOOLCHAIN = XCODE_DEVELOPER_DIR + "/Toolchains/XcodeDefault.xctoolchain"

# darwin_sdk.gni's mac_swift_lib_paths: where the Swift runtime's libraries
# are for the link (`lib_dirs` of darwin/common's config).
MACOS_SWIFT_LIBRARY_DIRS = [
    MACOS_SDK_PATH + "/usr/lib/swift",
    _XCODE_TOOLCHAIN + "/usr/lib/swift/macosx",
]

# GN's source root (`//` in its labels), under the repository's root: the
# directory swiftc.py makes the generated header's imports relative to
# (GN's `--src-dir`), as the engine's includes are spelled (`flutter/...`,
# found through include_root); its twin under the bin directory is GN's
# root_gen_dir (`--gen-dir`).
_GN_SOURCE_ROOT = "engine/src"

# What swiftc.py writes beside the objects for a module (GN's tool("swift")
# outputs with whole-module optimization), by suffix of the module's name.
_MODULE_OUTPUT_SUFFIXES = [
    "-OutputFileMap.json",
    ".SwiftFileList",
    ".abi.json",
    ".d",
    ".dia",
    ".swiftconstvalues",
    ".swiftdoc",
    ".swiftmodule",
    ".swiftsourceinfo",
]

SwiftModuleInfo = provider(
    doc = "The Swift modules a target brings to a Swift compile that depends on it: GN's {{module_dirs}} " +
          "(`-I<dir>` per module directory, computed over the dependencies) and the module files themselves.",
    fields = {
        "directories": "depset of strings: the directories holding a <module>.swiftmodule, as -I takes them.",
        "files": "depset of Files: the modules' files (the compile's inputs).",
    },
)

def _swift_modules_aspect_impl(target, ctx):
    # A module's own directory and files, and those of its dependencies --
    # through a C++ library in between (darwin/common's framework_common
    # carries InternalFlutterSwiftCommon as a public dependency, and
    # test_utils_swift imports the module through it), as GN computes a
    # Swift compile's module search path over the whole dependency graph.
    transitive = [
        dep[SwiftModuleInfo]
        for attribute in ["deps", "implementation_deps"]
        for dep in getattr(ctx.rule.attr, attribute, [])
        if SwiftModuleInfo in dep
    ]
    if _OwnSwiftModuleInfo in target:
        own = target[_OwnSwiftModuleInfo]
        return [SwiftModuleInfo(
            directories = depset([own.directory], transitive = [m.directories for m in transitive]),
            files = depset(own.files, transitive = [m.files for m in transitive]),
        )]
    return [SwiftModuleInfo(
        directories = depset(transitive = [m.directories for m in transitive]),
        files = depset(transitive = [m.files for m in transitive]),
    )]

# What a flutter_swift_library says of its own module; the aspect gathers
# these over the dependencies into SwiftModuleInfo.
_OwnSwiftModuleInfo = provider(
    doc = "A flutter_swift_library's module: its directory and files.",
    fields = {"directory": "string", "files": "list of Files"},
)

_swift_modules_aspect = aspect(
    implementation = _swift_modules_aspect_impl,
    attr_aspects = ["deps", "implementation_deps"],
    doc = "Gathers the Swift modules among a target's dependencies (SwiftModuleInfo).",
)

def _expand(ctx, attribute, flags):
    """The strings of `swiftflags` and `linkopts` as cc_library reads its flags.

    cc_library's `copts` and `linkopts` get Make-variable substitution, then
    Bourne shell tokenization; the converter escapes GN's flags for that
    reading, whatever rule takes them (objc_library.bzl's `_expand` is the
    same).
    """
    result = []
    for flag in flags:
        result.extend(ctx.tokenize(ctx.expand_make_variables(attribute, flag, {})))
    return result

def _flutter_swift_library_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    deps = [dep[CcInfo] for dep in ctx.attr.deps]
    module = ctx.attr.module_name or ctx.label.name

    # The outputs, as GN's tool("swift") lays them: the header under the
    # package's generated directory (GN's target_gen_dir:
    # <module>/<module>.h, the path the Objective-C imports spell), the
    # rest under a directory of the target's (GN's $target_out_dir/
    # $label_name). Bazel's gen and out trees are one, so a module named
    # for another target of the package -- an executable's companion
    # (the converter's <name>_swift), whose module is the executable's
    # name -- would put its header's directory where that target's output
    # goes; such a header, which nothing imports, sits with the module's
    # other files instead (the Mac's T19).
    out_dir = "_swift/" + ctx.label.name
    header = ctx.actions.declare_file(
        paths.join(module, module + ".h") if module == ctx.label.name else paths.join(out_dir, module + ".h"),
    )
    objects = [
        ctx.actions.declare_file(paths.join(out_dir, paths.replace_extension(src.basename, ".o")))
        for src in ctx.files.srcs
    ]
    module_files = [
        ctx.actions.declare_file(paths.join(out_dir, module + suffix))
        for suffix in _MODULE_OUTPUT_SUFFIXES
    ]
    depfile = ctx.actions.declare_file(paths.join("_swift", ctx.label.name + ".d"))
    target_out_dir = paths.join(ctx.bin_dir.path, ctx.label.package, out_dir)

    # The deps' compilation context: the bridging header's imports, as -I
    # (swiftc.py hands it to Swift and to its clang importer) and -D; the
    # target's own `includes` as cc_library takes them (GN's include_dirs:
    # the package's generated directory), each the source directory and
    # its twin under the bin directory.
    compilation = cc_common.merge_compilation_contexts(
        compilation_contexts = [dep.compilation_context for dep in deps],
    )
    includes = []
    for include in ctx.attr.includes:
        directory = paths.normalize(paths.join(ctx.label.workspace_root, ctx.label.package, include))
        includes.append(directory)
        includes.append(paths.join(ctx.bin_dir.path, directory))
    args = ctx.actions.args()
    args.add("-B")
    args.add(ctx.file._script)
    args.add("-module-name", module)
    args.add("--header-path", header)
    args.add("--target-out-dir", target_out_dir)
    args.add("--const-gather-protocols-file", ctx.file._const_gather_protocols)
    args.add("--depfile-path", depfile)
    args.add("--src-dir", _GN_SOURCE_ROOT)
    args.add("--gen-dir", paths.join(ctx.bin_dir.path, _GN_SOURCE_ROOT))

    # swiftc.py requires the option (GN's tool passes {{bridge_header}},
    # empty for a module without one, and the script skips an empty value).
    args.add("-import-objc-header", ctx.file.bridge_header or "")
    args.add_all(includes, before_each = "-I")
    args.add_all(
        depset(transitive = [compilation.quote_includes, compilation.includes, compilation.system_includes]),
        before_each = "-I",
    )

    # GN's {{module_dirs}}: the directories of the Swift modules among the
    # dependencies (the aspect's SwiftModuleInfo), where `import <Module>`
    # finds <Module>.swiftmodule.
    modules = [dep[SwiftModuleInfo] for dep in ctx.attr.deps if SwiftModuleInfo in dep]
    module_directories = depset(transitive = [m.directories for m in modules])
    module_inputs = depset(transitive = [m.files for m in modules])
    args.add_all(module_directories, before_each = "-I")
    args.add_all(compilation.framework_includes, before_each = "-F")
    args.add_all(compilation.defines, before_each = "-D")
    args.add_all(compilation.local_defines, before_each = "-D")
    args.add("-sdk", MACOS_SDK_PATH)
    args.add("-target", cc_toolchain.target_gnu_system_name + MACOS_DEPLOYMENT_TARGET)
    args.add("-swift-version", "5")
    args.add_all(_expand(ctx, "swiftflags", ctx.attr.swiftflags))
    args.add_all(ctx.files.srcs)
    args.add("--fix-generated-header")
    args.add("--whole-module-optimization")
    args.add("--mac-host-toolchain-path", _XCODE_TOOLCHAIN)

    # build/config/compiler's optimize and symbols configs on Apple: -Onone
    # (no_optimize, an unoptimized build), -O (optimize), -g (symbols).
    mode = ctx.var["COMPILATION_MODE"]
    args.add("-O" if mode == "opt" else "-Onone")
    args.add("-g")

    ctx.actions.run(
        executable = ctx.executable._python,
        arguments = [args],
        inputs = depset(
            [ctx.file._script, ctx.file._const_gather_protocols] + ctx.files.srcs + ctx.files.bridge_header + ctx.files.hdrs,
            transitive = [compilation.headers, module_inputs],
        ),
        tools = ctx.attr._python_runtime[DefaultInfo].files,
        outputs = [header, depfile] + objects + module_files,
        mnemonic = "SwiftCompile",
        progress_message = "swiftc %{label}",
        # The script runs Xcode's swiftc: the shell's PATH, and DEVELOPER_DIR
        # when --action_env passes it, as for the SDK and metal.
        use_default_shell_env = True,
        env = {
            "PYTHONDONTWRITEBYTECODE": "1",
            "PYTHONHASHSEED": "0",
        },
    )

    # The library: the generated header and `hdrs` (GN's `public`) for the
    # dependents' compiles -- and the bridging header, which the generated
    # header imports (swiftc.py rewrites the import relative to the source
    # root) --, the objects for their links, with the Swift libraries'
    # directories.
    compilation_context, _ = cc_common.compile(
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        name = ctx.label.name,
        public_hdrs = [header] + ctx.files.hdrs + ctx.files.bridge_header,
        compilation_contexts = [dep.compilation_context for dep in deps],
    )
    linking_context, _ = cc_common.create_linking_context_from_compilation_outputs(
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        compilation_outputs = cc_common.create_compilation_outputs(
            objects = depset(objects),
            pic_objects = depset(objects),
        ),
        name = ctx.label.name,
        linking_contexts = [dep.linking_context for dep in deps],
        user_link_flags = ["-L" + directory for directory in MACOS_SWIFT_LIBRARY_DIRS] + _expand(ctx, "linkopts", ctx.attr.linkopts),
        alwayslink = ctx.attr.alwayslink,
        disallow_dynamic_library = True,
    )
    return [
        DefaultInfo(files = depset([header] + objects)),
        CcInfo(compilation_context = compilation_context, linking_context = linking_context),
        OutputGroupInfo(swiftmodule = depset(module_files)),
        _OwnSwiftModuleInfo(directory = target_out_dir, files = module_files),
    ]

flutter_swift_library = rule(
    implementation = _flutter_swift_library_impl,
    doc = "A GN source_set of Swift sources, compiled through build/toolchain/darwin/swiftc.py as GN's mac " +
          "toolchain compiles it (see the file's docstring); CcInfo for the Objective-C that imports the " +
          "module's generated header and for whatever links the objects.",
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".swift"],
            mandatory = True,
            doc = "The Swift sources of the module.",
        ),
        "module_name": attr.string(doc = "The module's name (GN's module_name); the target's name by default."),
        "bridge_header": attr.label(
            allow_single_file = [".h"],
            doc = "GN's bridge_header: the Objective-C header the Swift sources import.",
        ),
        "hdrs": attr.label_list(
            allow_files = True,
            doc = "GN's `public`: the headers dependents may include, beside the generated one.",
        ),
        "swiftflags": attr.string_list(doc = "GN's swiftflags of the target and its configs, after the toolchain's."),
        "includes": attr.string_list(doc = "Include directories, package-relative, as cc_library's (GN's include_dirs)."),
        "linkopts": attr.string_list(doc = "Link flags for whatever links the module in (GN's frameworks, libs, ldflags)."),
        "deps": attr.label_list(
            providers = [CcInfo],
            aspects = [_swift_modules_aspect],
            doc = "What the bridging header imports (their headers, include directories and defines reach the " +
                  "compile) and the Swift modules the sources import, directly or through a C++ library " +
                  "(the aspect gathers them: GN's {{module_dirs}}).",
        ),
        "alwayslink": attr.bool(
            default = True,
            doc = "Link every object, as a GN source_set's are (-force_load on a Mac).",
        ),
        "_script": attr.label(
            default = "//engine/src/build:toolchain/darwin/swiftc.py",
            allow_single_file = True,
        ),
        "_const_gather_protocols": attr.label(
            default = "//engine/src/build:toolchain/darwin/swift_const_gather_protocols.json",
            allow_single_file = True,
        ),
        "_python": attr.label(
            default = "@cpython3//:bin/python3",
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_python_runtime": attr.label(default = "@cpython3//:runtime"),
    },
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(),
    provides = [CcInfo],
)
