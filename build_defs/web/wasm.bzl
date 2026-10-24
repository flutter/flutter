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
outputs, with the unoptimized build's `.wasm.map` as a fourth. (The link
itself is the rule's own action over the toolchain's command line; see the
implementation.)

The module is the whole of the C++ it needs: `srcs` compiled here, `deps`
linked in (cc_library targets, themselves built under the transition).

Which wasm platform: GN builds a wasm_lib in the toolchain a dependent names
on the edge (`"//flutter/skwasm(:skwasm)"`, the web SDK's copies in
//flutter/third_party/canvaskit/BUILD.gn -- a child toolchain whose
extra_toolchain_args are the variant's configuration) and in no other. Here
the edge is a gn_copy with a `platform`: its transition
(module_platform_transition) sets the `module_platform` flag of
build/bazel/web and --platforms for the copy's sources, and the module's own
transition (module_transition) builds it for the platform the flag names,
spending the flag, so that nothing below the module is configured by it
(the flag is the edge, the platform is the configuration). The module is compatible with the
variant platforms alone (every wasm_platform carries the `variant`
constraint; the bare wasm platform does not), as GN has no module outside
those toolchains: `bazel build //engine/src/flutter/skwasm:skwasm` wants
`--//engine/src/flutter/build/bazel/web:module_platform=//engine/src/flutter/third_party/canvaskit:skwasm`
(or `--platforms` of the same), or the copy that names it, and a wildcard
build skips the bare module. wasm_objects, a compile alone, takes the bare
platform.
"""

load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

WASM_PLATFORM = Label("//engine/src/flutter/build/bazel/toolchains/emscripten:wasm32_emscripten")

# The platform wasm modules are built for (build/bazel/web): a wasm_platform's
# label, or empty.
MODULE_PLATFORM = "//engine/src/flutter/build/bazel/web:module_platform"

# The constraint every wasm_platform carries and the bare wasm platform does
# not: what a wasm module is compatible with (a Label: the macros are called
# from other repositories' files too, Skia's for CanvasKit).
VARIANT = Label("//engine/src/flutter/build/bazel/web:variant")

def _module_transition_impl(settings, _attr):
    platform = settings[MODULE_PLATFORM]
    return {
        # The module's platform: the one the module_platform flag names (a
        # variant of the web build, third_party/canvaskit), else the one the
        # build has -- compatible only when that is a variant, see
        # wasm_module. The flag is spent here: nothing below the module is
        # configured by it.
        "//command_line_option:platforms": [platform] if platform else settings["//command_line_option:platforms"],
        # Every object is position independent under the root .bazelrc; the
        # wasm toolchain has no PIC.
        "//command_line_option:force_pic": False,
        MODULE_PLATFORM: "",
    }

module_transition = transition(
    implementation = _module_transition_impl,
    inputs = [
        "//command_line_option:platforms",
        MODULE_PLATFORM,
    ],
    outputs = [
        "//command_line_option:platforms",
        "//command_line_option:force_pic",
        MODULE_PLATFORM,
    ],
)

def _wasm_transition_impl(_settings, _attr):
    return {
        # A compile alone (wasm_objects) takes the wasm platform itself.
        "//command_line_option:platforms": [str(WASM_PLATFORM)],
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

def _module_platform_transition_impl(settings, attr):
    if not attr.platform:
        return {
            "//command_line_option:platforms": settings["//command_line_option:platforms"],
            MODULE_PLATFORM: settings[MODULE_PLATFORM],
        }
    return {
        "//command_line_option:platforms": [str(attr.platform)],
        MODULE_PLATFORM: str(attr.platform),
    }

# GN's `label(:toolchain)` edge, for a rule with a `platform` attribute
# (gn_copy): what the rule names is built for that platform, and a wasm
# module among them reads it from the flag.
module_platform_transition = transition(
    implementation = _module_platform_transition_impl,
    inputs = [
        "//command_line_option:platforms",
        MODULE_PLATFORM,
    ],
    outputs = [
        "//command_line_option:platforms",
        MODULE_PLATFORM,
    ],
)

WasmModuleInfo = provider(
    doc = "A linked wasm module.",
    fields = {
        "js": "The JavaScript loader (<name>.js).",
        "wasm": "The module (<name>.wasm).",
        "symbols": "The symbol map (<name>.js.symbols).",
        "source_map": "The source map (<name>.wasm.map) of an unoptimized build; None otherwise.",
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
    name = ctx.attr.output_name or ctx.label.name
    wasm_lib = ctx.attr.wasm_lib
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
        # wasm_lib's cflags, then the target's.
        user_compile_flags = (["-s", "MAIN_MODULE=1"] if wasm_lib else []) + ctx.attr.copts,
        compilation_contexts = [dep[CcInfo].compilation_context for dep in ctx.attr.deps],
    )
    js = ctx.actions.declare_file(name + ".js")
    wasm = ctx.actions.declare_file(name + ".wasm")
    symbols = ctx.actions.declare_file(name + ".js.symbols")
    outputs = [js, wasm, symbols]

    # The unoptimized build's source map (the toolchain's `source_map`
    # feature: -gsource-map on the link), which emcc writes beside the
    # .wasm. GN's link rule does not declare it -- the web SDK's copies name
    # it under is_debug and ninja finds it on disk -- so here it is the
    # module's fourth output when the feature holds, and nothing otherwise.
    source_map = None
    if cc_common.is_enabled(feature_configuration = feature_configuration, feature_name = "source_map"):
        source_map = ctx.actions.declare_file(name + ".wasm.map")
        outputs.append(source_map)

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
        user_link_flags = (["-s", "EXPORT_NAME=" + (ctx.attr.export_name or name)] if wasm_lib else []) + [
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
        outputs = outputs,
    )
    return [
        DefaultInfo(files = depset(outputs)),
        WasmModuleInfo(js = js, wasm = wasm, symbols = symbols, source_map = source_map),
    ]

_wasm_module = rule(
    implementation = _wasm_module_impl,
    doc = "GN's wasm_lib: a wasm module (.js, .wasm, .js.symbols) linked by the Emscripten toolchain under the wasm platform the module_platform flag names.",
    attrs = _MODULE_ATTRS | {
        "linkopts": attr.string_list(
            doc = "The module's ldflags, after wasm_lib's -s EXPORT_NAME=<name>; $(execpath ...) over link_inputs is expanded.",
        ),
        "link_inputs": attr.label_list(
            allow_files = True,
            doc = "Files the link reads besides objects: the --js-library and --pre-js files linkopts name.",
        ),
        "export_name": attr.string(doc = "EXPORT_NAME; the target's name by default, as in wasm_lib."),
        "output_name": attr.string(doc = "GN's output_name: what the .js, .wasm and .js.symbols are called; the target's name by default."),
        "wasm_lib": attr.bool(
            default = True,
            doc = "Whether the target is a wasm_lib (-s MAIN_MODULE=1 on the compiles, -s EXPORT_NAME on the link) " +
                  "or a plain executable in the wasm toolchain (CanvasKit's, which passes its own flags).",
        ),
    },
    cfg = module_transition,
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(),
    provides = [WasmModuleInfo],
)

def wasm_module(name, **kwargs):
    """GN's wasm_lib: a wasm module, built for the platform a dependent names.

    See the module docstring: the module is compatible with the web build's
    variant platforms alone (a wildcard build skips it; the web SDK's copies
    name the platform, or the command line does).

    Args:
      name: the module's name (EXPORT_NAME, unless `export_name` says otherwise).
      **kwargs: the rule's attributes.
    """
    _wasm_module(
        name = name,
        target_compatible_with = [VARIANT],
        **kwargs
    )

def wasm_executable(name, **kwargs):
    """GN's executable() in a wasm toolchain with `output_extension = "js"`.

    The same link as a wasm_module's (the toolchain writes the .js, .wasm
    and .js.symbols), without wasm_lib's flags: the target passes its own
    (CanvasKit's -sEXPORT_NAME=CanvasKitInit among its ldflags), and names
    its outputs with `output_name` where GN does.

    Args:
      name: the target's name.
      **kwargs: the rule's attributes.
    """
    _wasm_module(
        name = name,
        target_compatible_with = [VARIANT],
        wasm_lib = False,
        **kwargs
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
    "skia_use_bidi",
    "skia_canvaskit_enable_bidi",
    "skia_enable_skparagraph",
    "skia_canvaskit_enable_paragraph",
    "skia_enable_skshaper",
    "skia_use_harfbuzz",
    "skia_use_freetype",
    "flutter_use_freetype_woff2",
    "skia_enable_fontmgr_custom_embedded",
    "skia_enable_fontmgr_custom_empty",
    "skia_canvaskit_enable_font",
    "skia_canvaskit_enable_alias_font",
]

# The toolchain arguments that are compiler flags in GN
# (//build/config/compiler), each a feature of the emscripten toolchain
# configuration.
_FEATURE_ARGS = {
    "wasm_use_workers": "wasm_use_workers",
    "wasm_prioritize_size": "wasm_prioritize_size",
    "enable_lto": "lto",
}

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

    enable_lto: GN's web build has it on (tools/gn's --lto default) where a
    toolchain does not say otherwise -- the wasm platform carries the `lto`
    feature (toolchains/emscripten/BUILD.bazel), a toolchain's
    `enable_lto = false` turns it off here -- and the LTO variants of
    emscripten's system libraries it links are built at fetch time
    (lto_libraries.bzl).

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
        elif argument not in _LABEL_ARGS:
            fail("wasm_platform(%s): %s is not an argument the web build's platforms carry" % (name, argument))
    native.platform(
        name = name,
        constraint_values = [VARIANT],
        flags = flags,
        parents = [str(WASM_PLATFORM)],
        **kwargs
    )
