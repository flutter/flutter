# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""`wasm_module`: GN's `wasm_lib` (build/toolchain/wasm.gni) as a Bazel rule.

GN's template is an executable in the wasm toolchain with
`output_extension = "js"`, `-s MAIN_MODULE=1` among its cflags and
`-s EXPORT_NAME=<name>` among its ldflags, and the toolchain declares what
one emcc link writes (`link_outputs`): the `.js` loader, the `.wasm` beside
it and the `.js.symbols` symbol map (`--emit-symbol-map`). Here the rule
compiles its sources and links them with the C++ toolchain's own actions
(cc_common.compile and cc_common.link, so the flags are the toolchain
configuration's) under the wasm platform -- a configuration transition, so
a module can be named from any build -- and declares the same three
outputs. (The link itself is the rule's own action over the toolchain's
command line; see the implementation.)

The module is the whole of the C++ it needs: `srcs` compiled here, `deps`
linked in (cc_library targets, themselves built under the transition).
"""

load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

WASM_PLATFORM = Label("//engine/src/flutter/build/bazel/toolchains/emscripten:wasm32_emscripten")

def _wasm_transition_impl(_settings, _attr):
    return {
        "//command_line_option:platforms": [str(WASM_PLATFORM)],
        # Every object is position independent under the root .bazelrc; the
        # wasm toolchain has no PIC.
        "//command_line_option:force_pic": False,
    }

wasm_transition = transition(
    implementation = _wasm_transition_impl,
    inputs = [],
    outputs = [
        "//command_line_option:platforms",
        "//command_line_option:force_pic",
    ],
)

WasmModuleInfo = provider(
    doc = "A linked wasm module.",
    fields = {
        "js": "The JavaScript loader (<name>.js).",
        "wasm": "The module (<name>.wasm).",
        "symbols": "The symbol map (<name>.js.symbols).",
    },
)

# What a compile under the wasm platform takes (wasm_module and
# wasm_objects alike).
_MODULE_ATTRS = {
    "srcs": attr.label_list(allow_files = [".cc", ".cpp", ".c"], doc = "The sources compiled here."),
    "hdrs": attr.label_list(allow_files = [".h"], doc = "Headers the sources include."),
    "deps": attr.label_list(providers = [CcInfo], doc = "cc_library targets, built under the wasm platform too."),
    "include_markers": attr.label_list(
        allow_files = True,
        doc = "Files whose directories are added as -I include directories (a repository's root, say).",
    ),
    "defines": attr.string_list(doc = "Defines of the compiles."),
    "copts": attr.string_list(doc = "The target's cflags (after wasm_lib's -s MAIN_MODULE=1 in a module)."),
    "_allowlist_function_transition": attr.label(
        default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
    ),
}

def _wasm_module_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    name = ctx.label.name
    _, compilation_outputs = cc_common.compile(
        name = name,
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        srcs = ctx.files.srcs,
        private_hdrs = ctx.files.hdrs,
        includes = [marker.dirname for marker in ctx.files.include_markers],
        defines = ctx.attr.defines,
        # wasm_lib's cflags, then the target's.
        user_compile_flags = ["-s", "MAIN_MODULE=1"] + ctx.attr.copts,
        compilation_contexts = [dep[CcInfo].compilation_context for dep in ctx.attr.deps],
    )
    js = ctx.actions.declare_file(name + ".js")
    wasm = ctx.actions.declare_file(name + ".wasm")
    symbols = ctx.actions.declare_file(name + ".js.symbols")

    # The link is an action of this rule's own rather than cc_common.link:
    # that API declares one output per link, and the three a module has
    # (`additional_outputs`, `main_output`) are Bazel's private API. The
    # command line is nevertheless the toolchain's -- its linker, the
    # flags its feature configuration composes for an executable link (the
    # output, the target's ldflags, then the configuration's), its
    # environment -- followed by the objects and the dependencies'
    # archives, where GN's link rule puts them.
    link_variables = cc_common.create_link_variables(
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
        output_file = js.path,
        is_using_linker = True,
        is_linking_dynamic_library = False,
        is_static_linking_mode = True,
        # wasm_lib's ldflags, then the target's.
        user_link_flags = ["-s", "EXPORT_NAME=" + (ctx.attr.export_name or name)] + ctx.attr.linkopts,
    )
    link_action = ACTION_NAMES.cpp_link_executable
    objects = compilation_outputs.objects
    archives = []
    for dep in ctx.attr.deps:
        for linker_input in dep[CcInfo].linking_context.linker_inputs.to_list():
            for library in linker_input.libraries:
                archive = library.static_library or library.pic_static_library
                if archive:
                    archives.append(archive)
    arguments = ctx.actions.args()
    arguments.add_all(cc_common.get_memory_inefficient_command_line(
        feature_configuration = feature_configuration,
        action_name = link_action,
        variables = link_variables,
    ))

    # GN's link rule groups the objects and archives (gcc_toolchain's
    # -Wl,--start-group @rsp -Wl,--end-group); the system libraries follow,
    # from the toolchain's link libs.
    arguments.add("-Wl,--start-group")
    arguments.add_all(objects)
    arguments.add_all(archives)
    arguments.add("-Wl,--end-group")
    ctx.actions.run(
        mnemonic = "WasmLink",
        progress_message = "Linking wasm module %{output}",
        executable = cc_common.get_tool_for_action(
            feature_configuration = feature_configuration,
            action_name = link_action,
        ),
        arguments = [arguments],
        env = cc_common.get_environment_variables(
            feature_configuration = feature_configuration,
            action_name = link_action,
            variables = link_variables,
        ),
        inputs = depset(
            objects + archives + ctx.files.link_inputs,
            transitive = [cc_toolchain.all_files],
        ),
        outputs = [js, wasm, symbols],
    )
    return [
        DefaultInfo(files = depset([js, wasm, symbols])),
        WasmModuleInfo(js = js, wasm = wasm, symbols = symbols),
    ]

wasm_module = rule(
    implementation = _wasm_module_impl,
    doc = "GN's wasm_lib: a wasm module (.js, .wasm, .js.symbols) linked by the Emscripten toolchain under the wasm platform.",
    attrs = _MODULE_ATTRS | {
        "linkopts": attr.string_list(doc = "The module's ldflags, after wasm_lib's -s EXPORT_NAME=<name>."),
        "link_inputs": attr.label_list(
            allow_files = True,
            doc = "Files the link reads besides objects: --js-library and --pre-js files named in linkopts.",
        ),
        "export_name": attr.string(doc = "EXPORT_NAME; the target's name by default, as in wasm_lib."),
    },
    cfg = wasm_transition,
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(),
    provides = [WasmModuleInfo],
)

def _wasm_objects_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    _, compilation_outputs = cc_common.compile(
        name = ctx.label.name,
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        srcs = ctx.files.srcs,
        private_hdrs = ctx.files.hdrs,
        includes = [marker.dirname for marker in ctx.files.include_markers],
        defines = ctx.attr.defines,
        user_compile_flags = ctx.attr.copts,
        compilation_contexts = [dep[CcInfo].compilation_context for dep in ctx.attr.deps],
    )
    return [DefaultInfo(files = depset(compilation_outputs.objects))]

wasm_objects = rule(
    implementation = _wasm_objects_impl,
    doc = "Sources compiled by the Emscripten toolchain under the wasm platform, to their objects: a compile with no link, for a translation unit of a library the web engine builds (the spike's Skia unit).",
    attrs = _MODULE_ATTRS,
    cfg = wasm_transition,
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(),
)
