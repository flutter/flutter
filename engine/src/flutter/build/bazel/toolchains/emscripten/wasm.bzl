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

def _wasm_transition_impl(_settings, attr):
    return {
        # The module's platform: one of the web build's variants (a child of
        # the wasm platform carrying a GN wasm toolchain's arguments as
        # flags, third_party/canvaskit), or the wasm platform itself.
        "//command_line_option:platforms": [str(attr.platform)],
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
    "srcs": attr.label_list(
        allow_files = [".cc", ".cpp", ".c", ".h"],
        doc = "The sources compiled here, and headers among them (GN's `sources` lists both).",
    ),
    "hdrs": attr.label_list(allow_files = [".h"], doc = "Headers the sources include."),
    "deps": attr.label_list(providers = [CcInfo], doc = "cc_library targets, built under the wasm platform too."),
    "include_markers": attr.label_list(
        allow_files = True,
        doc = "Files whose directories are added as -I include directories (a repository's root, say).",
    ),
    "defines": attr.string_list(doc = "Defines of the compiles."),
    "copts": attr.string_list(doc = "The target's cflags (after wasm_lib's -s MAIN_MODULE=1 in a module)."),
    "platform": attr.label(
        default = WASM_PLATFORM,
        doc = "The platform to build for: the wasm platform, or a variant of the web build (a platform with the GN toolchain's arguments as flags).",
    ),
    "_allowlist_function_transition": attr.label(
        default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
    ),
}

def _split_sources(files):
    """GN's `sources`: the files to compile and the headers among them."""
    sources = [f for f in files if f.extension != "h"]
    headers = [f for f in files if f.extension == "h"]
    return sources, headers

def _wasm_module_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )
    name = ctx.label.name
    sources, headers = _split_sources(ctx.files.srcs)
    _, compilation_outputs = cc_common.compile(
        name = name,
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        srcs = sources,
        private_hdrs = ctx.files.hdrs + headers,
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
        # wasm_lib's ldflags, then the target's, a file among them named
        # by its $(execpath) over link_inputs (--js-library, --pre-js).
        user_link_flags = ["-s", "EXPORT_NAME=" + (ctx.attr.export_name or name)] + [
            ctx.expand_location(flag, targets = ctx.attr.link_inputs)
            for flag in ctx.attr.linkopts
        ],
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
        "linkopts": attr.string_list(
            doc = "The module's ldflags, after wasm_lib's -s EXPORT_NAME=<name>; $(execpath ...) over link_inputs is expanded.",
        ),
        "link_inputs": attr.label_list(
            allow_files = True,
            doc = "Files the link reads besides objects: the --js-library and --pre-js files linkopts name.",
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
    sources, headers = _split_sources(ctx.files.srcs)
    _, compilation_outputs = cc_common.compile(
        name = ctx.label.name,
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        srcs = sources,
        private_hdrs = ctx.files.hdrs + headers,
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

# ---------------------------------------------------------------------------
# wasm_platform: GN's wasm_toolchain
# ---------------------------------------------------------------------------

_WEB_SETTINGS = "//engine/src/flutter/build/bazel/web"

# The toolchain arguments that are build settings (build/bazel/web).
_SETTING_ARGS = [
    "skia_use_icu",
    "skia_use_client_icu",
    "skia_use_libjpeg_turbo_decode",
    "skia_use_libpng_decode",
    "skia_use_libwebp_decode",
    "skia_use_no_png_encode",
    "skia_use_libpng_encode",
    "skia_enable_threadlocal_strikecache",
]

# The toolchain arguments that are compiler flags in GN
# (//build/config/compiler), each a feature of the emscripten toolchain
# configuration.
_FEATURE_ARGS = {
    "wasm_use_workers": "wasm_use_workers",
    "wasm_prioritize_size": "wasm_prioritize_size",
}

# enable_lto: see wasm_platform; accepted, not applied.
_DEFERRED_ARGS = ["enable_lto"]

# skia_icu_bidi_third_party_dir names the directory of the client ICU's bidi
# library (//flutter/third_party/canvaskit/icu_bidi, the one value it ever
# has), which the skunicode conversion lists as a dependency under
# skia_use_client_icu: a label there, nothing here.
_LABEL_ARGS = ["skia_icu_bidi_third_party_dir"]

def wasm_platform(name, extra_toolchain_args = {}, **kwargs):
    """GN's wasm_toolchain: a platform for one variant of the web build.

    A child of the wasm platform whose flags are the toolchain's
    `extra_toolchain_args` -- the arguments GN re-evaluates Skia and the
    engine's libraries under in that toolchain -- as build-setting flags
    and toolchain features (Bazel's platform-based flags apply them to
    everything built for the platform).

    enable_lto: GN's web build has it on (is_official_build) where a
    toolchain does not say otherwise, and its first link builds the LTO
    variants of emscripten's system libraries into the prebuilt SDK's
    cache. The synced SDK ships without them (no lto/ beside the ww/ and mt/
    variants) and the Bazel toolchain freezes the cache, so the platforms
    do not turn the `lto` feature on until the variants are built at fetch
    time (research/12); the skwasm modules link without -flto meanwhile.

    Args:
      name: the toolchain's name (the platform's).
      extra_toolchain_args: GN's block, argument name to value.
      **kwargs: `visibility`.
    """
    flags = []
    for argument, value in extra_toolchain_args.items():
        if argument in _SETTING_ARGS:
            flags.append("--%s:%s=%s" % (_WEB_SETTINGS, argument, "true" if value else "false"))
        elif argument in _FEATURE_ARGS:
            flags.append("--features=%s%s" % ("" if value else "-", _FEATURE_ARGS[argument]))
        elif argument not in _LABEL_ARGS and argument not in _DEFERRED_ARGS:
            fail("wasm_platform(%s): %s is not an argument the web build's platforms carry" % (name, argument))
    native.platform(
        name = name,
        flags = flags,
        parents = [str(WASM_PLATFORM)],
        **kwargs
    )
