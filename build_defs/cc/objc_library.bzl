# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""flutter_objc_library: cc_library's Objective-C(++) counterpart, for the .m and .mm files of a GN target.

Bazel's `cc_library` refuses `.m` and `.mm` sources, and its `objc_library`
compiles them with flags of its own that GN's command lines do not have --
`-O0 -DDEBUG=1` in a debug build, `-Os -DNDEBUG=1 -Wno-extra` and the rest
in an optimized one, appended after a target's copts, so that `-Os` would
win over the toolchain's `-O2` -- and has no `local_defines`. This rule
compiles its sources through the same toolchain as `cc_library` (the
`objc-compile` and `objc++-compile` actions of the macOS toolchains,
cc_toolchain_config.bzl under os = "mac") with nothing added: the
toolchain's flags, then the target's `copts`, which carry the Objective-C
flags GN's `cflags_objc`/`cflags_objcc` hold (ARC among them:
copts.bzl's MACOS_CFLAGS_OBJC). Its archive links like a cc_library's, and
`alwayslink` makes it a GN source_set's objects (-force_load on a Mac).

The converter emits one beside a `cc_library` whose GN target has
Objective-C sources (`<name>_objc`, the same headers and deps, the target's
Objective-C flags), which the `cc_library` depends on under the Apple
platforms; `target_compatible_with` keeps it off the others, where the
toolchains have no Objective-C actions.

    flutter_objc_library(
        name = "fml_objc",
        srcs = ["platform/darwin/cf_utils.mm", ...],
        hdrs = [...],
        copts = FLUTTER_COPTS + MACOS_CFLAGS_OBJCC,
        local_defines = FLUTTER_LOCAL_DEFINES,
        deps = [...],
        alwayslink = True,
        target_compatible_with = select({apple: [], default: ["@platforms//:incompatible"]}),
    )
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

def _expand(ctx, attribute, flags):
    return [ctx.expand_make_variables(attribute, flag, {}) for flag in flags]

def _flutter_objc_library_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        language = "objc",
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    deps = [dep[CcInfo] for dep in ctx.attr.deps]

    # `includes` as cc_library takes them: package-relative, each naming the
    # source tree's directory and the generated files' beside it.
    includes = []
    for include in ctx.attr.includes:
        directory = paths.normalize(paths.join(ctx.label.workspace_root, ctx.label.package, include))
        includes.append(directory)
        includes.append(paths.join(ctx.bin_dir.path, directory))

    compilation_context, compilation_outputs = cc_common.compile(
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        name = ctx.label.name,
        srcs = ctx.files.srcs,
        public_hdrs = ctx.files.hdrs,
        textual_hdrs = ctx.files.textual_hdrs,
        includes = includes,
        defines = ctx.attr.defines,
        local_defines = _expand(ctx, "local_defines", ctx.attr.local_defines),
        user_compile_flags = _expand(ctx, "copts", ctx.attr.copts),
        compilation_contexts = [dep.compilation_context for dep in deps],
        additional_inputs = ctx.files.additional_compiler_inputs,
        language = "objc",
    )
    linking_context, _ = cc_common.create_linking_context_from_compilation_outputs(
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        compilation_outputs = compilation_outputs,
        name = ctx.label.name,
        linking_contexts = [dep.linking_context for dep in deps],
        user_link_flags = _expand(ctx, "linkopts", ctx.attr.linkopts),
        alwayslink = ctx.attr.alwayslink,
        disallow_dynamic_library = True,
    )
    return [
        DefaultInfo(files = depset(compilation_outputs.objects + compilation_outputs.pic_objects)),
        CcInfo(compilation_context = compilation_context, linking_context = linking_context),
    ]

flutter_objc_library = rule(
    implementation = _flutter_objc_library_impl,
    doc = "cc_library for Objective-C and Objective-C++ sources, compiled with the toolchain's flags and the " +
          "target's alone (see the file's docstring); CcInfo for a cc_library, cc_binary or cc_test to depend on.",
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".m", ".mm", ".h", ".hh", ".hpp", ".inc"],
            doc = "The Objective-C (.m) and Objective-C++ (.mm) sources, and private headers.",
        ),
        "hdrs": attr.label_list(allow_files = True, doc = "The headers dependents may include."),
        "textual_hdrs": attr.label_list(allow_files = True),
        "includes": attr.string_list(doc = "Include directories, package-relative, as cc_library's."),
        "defines": attr.string_list(doc = "Defines for this target and its dependents."),
        "local_defines": attr.string_list(doc = "Defines for this target's compiles alone."),
        "copts": attr.string_list(doc = "The target's compile flags, after the toolchain's: GN's cflags, cflags_cc and cflags_objc[c]."),
        "linkopts": attr.string_list(doc = "Link flags for whatever links this in (GN's frameworks, libs, ldflags)."),
        "additional_compiler_inputs": attr.label_list(allow_files = True),
        "deps": attr.label_list(providers = [CcInfo]),
        "alwayslink": attr.bool(default = False, doc = "Link every object, as a GN source_set's are (-force_load on a Mac)."),
    },
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(),
    provides = [CcInfo],
)
