# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The engine's `impeller_shaders()` GN template as a Bazel macro.

`impeller_shaders("entity_shaders") { name = "entity"  shaders = [...] }`
(impeller/tools/shaders.gni and the files it imports) compiles each shader
with `impellerc` once per backend, archives the compiled shaders of a
backend into a `.shar` blob with `shader_archiver`, embeds the blob into a
C++ source with tools/xxd.py, and wraps the reflection headers impellerc
writes (`solid_fill.vert.h`, the pipeline's vertex and fragment shader
structs) in a library. The converter (tools/gn_to_bazel) emits the
invocations; the template's body lives here, as rules.

The expansion is the one shaders.gni produces for the platform:
`impeller_enable_opengles` and `impeller_enable_vulkan` on everywhere, so
GLES 2 (`gles`), GLES 3 (`gles3`, language version 300) and Vulkan (`vk`),
and on the Apple platforms Metal besides (`mtl`: `impeller_enable_metal`,
research/20 M4). Where Metal is off, the Vulkan reflection library is the
one dependents see and its intermediates sit in the target's directory;
where it is on, Metal's reflection is the public one ("Metal reflectors
generate a superset of information", shaders_vk.gni) and Vulkan's moves
under `vk/` -- the same rule instance writes either layout, choosing by
platform at analysis time, which is why the outputs are declared rather
than predeclared. The GLES intermediates are under subdirectories either
way. The target names are GN's, so that `gn desc` and the generated tree
read alike:

  impellerc_<backend>_<name>       the per-shader impellerc runs
  genlib_<backend>_<name>          the .shar archive (Metal: the .metallib)
  gen_blob_embed_<backend>_<name>  xxd.py
  embed_<backend>_<name>           the embedded blob, a library
  reflect_<backend>_<name>         the reflection headers and sources
  <backend>_<name>                 the backend's group
  <name>                           the group over the backends

Generated headers are included by their path under GN's `gen/flutter`
(`impeller/entity/solid_fill.vert.h`, `impeller/entity/vk/entity_shaders_vk.h`,
`impeller/entity/mtl/entity_shaders.h`); //engine/src/flutter:config's
`includes` spans the output tree, which is where they land.

Metal's library is Xcode's `metal` compiler over impellerc's `.metal`
sources (impeller/tools/metal_library.py: `xcrun -sdk macosx metal`), the
one tool of the pipeline that is not the build's own -- the same Xcode
`@macos_sdk` is a view of; DEVELOPER_DIR reaches it through --action_env.

Shaders `#include` the shader library (`<impeller/types.glsl>`, the files
GN copies in //flutter/impeller/compiler/shader_lib) and files beside them
(`"sdf_utils.glsl"`); impellerc's depfile names them after the fact, so the
rules declare the library and the package's `.glsl` files as inputs
instead. Malioc analysis (`analyze`) has no counterpart: GN's is a no-op
unless `impeller_malioc_path` is set.
"""

load("@rules_cc//cc:defs.bzl", "cc_library")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("//build_defs/cc:copts.bzl", "CHROMIUM_CODE_COPTS", "FLUTTER_COPTS", "FLUTTER_LOCAL_DEFINES")
load("//build_defs/gn:gn_action.bzl", "PYTHON_ATTRS", "expand_gn_paths", "run_python")

# The shader library impellerc resolves `<impeller/...>` and `<flutter/...>`
# includes against: GN's copy() targets, whose files are the directory's.
_SHADER_LIB = [
    "//engine/src/flutter/impeller/compiler/shader_lib/flutter",
    "//engine/src/flutter/impeller/compiler/shader_lib/impeller",
]

# The Apple platforms, where shaders.gni's impeller_enable_metal holds.
_APPLE = "@platforms//os:macos"

# One entry per backend shaders.gni enables.
#   tag:        GN's target-name prefix and the group's name.
#   subdir:     impellerc's intermediates_subdir ("" for Vulkan without
#               Metal: shaders_vk.gni keeps them in the target's directory;
#               `vk` with it; "" for Metal).
#   extension:  sl_file_extension.
#   flags:      shader_target_flags.
#   defines:    the --define= macros.
#   version:    a fixed --gles-language-version (GLES 3), or None for the
#               invoker's.
#   symbol:     the embedded blob's symbol, over the library name.
#   embed:      the embedded blob's header and source, without extension.
#   opengles:   whether enable_opengles, gles_exclusions,
#               gles_language_version and require_framebuffer_fetch apply.
#   reflect:    whether the group exposes the reflection library: a bool, or
#               a select over the platform (Vulkan's only where Metal is off).
#   metal:      the Metal backend: Apple platforms only, the library by
#               Xcode's metal compiler, no .shar.
_BACKENDS = [
    struct(
        tag = "gles",
        subdir = "gles",
        extension = "gles",
        flags = ["--opengl-es"],
        defines = ["IMPELLER_TARGET_OPENGLES"],
        version = None,
        symbol = "%s_shaders_gles",
        embed = "gles/%s_shaders_gles",
        opengles = True,
        reflect = False,
        mnemonic = "ImpellercGles2",
    ),
    struct(
        tag = "gles3",
        subdir = "gles3",
        extension = "gles",
        flags = ["--opengl-es"],
        defines = ["IMPELLER_TARGET_OPENGLES", "IMPELLER_TARGET_OPENGLES3"],
        version = 300,
        symbol = "%s_shaders_gles3",
        embed = "gles3/%s_shaders_gles",
        opengles = True,
        reflect = False,
        mnemonic = "ImpellercGles3",
    ),
    struct(
        tag = "vk",
        subdir = select({
            _APPLE: "vk",
            "//conditions:default": "",
        }),
        extension = "vkspv",
        flags = ["--vulkan"],
        defines = ["IMPELLER_TARGET_VULKAN"],
        version = None,
        symbol = "%s_shaders_vk",
        embed = "vk/%s_shaders_vk",
        opengles = False,
        reflect = select({
            _APPLE: False,
            "//conditions:default": True,
        }),
        mnemonic = "ImpellercVulkan",
    ),
    struct(
        tag = "mtl",
        subdir = "",
        extension = "metal",
        flags = ["--metal-desktop"],
        defines = ["IMPELLER_TARGET_METAL", "IMPELLER_TARGET_METAL_DESKTOP"],
        version = None,
        symbol = "%s_shaders",
        embed = "mtl/%s_shaders",
        opengles = False,
        reflect = True,
        mnemonic = "ImpellercMetal",
    ),
]

# The backends by tag, and the ones a target is on the Apple platforms alone.
_METAL_TAGS = ["mtl"]

def _impellerc_compile_impl(ctx):
    shader_lib = ctx.files._shader_lib
    if not shader_lib:
        fail("%s: the shader library has no files" % ctx.label)

    # .../compiler/shader_lib, the parent of the copies' directories.
    shader_lib_dir = shader_lib[0].dirname.rsplit("/", 1)[0]
    shaders = ctx.files.srcs
    prefix = ctx.attr.subdir + "/" if ctx.attr.subdir else ""
    sls = []
    headers = []
    sources = []
    for shader in shaders:
        # GN's {{source_file_part}} under the intermediates subdirectory,
        # which the platform chooses (Vulkan's `vk/` where Metal is on).
        stem = prefix + shader.basename
        sl = ctx.actions.declare_file(stem + "." + ctx.attr.extension)
        header = ctx.actions.declare_file(stem + ".h")
        source = ctx.actions.declare_file(stem + ".cc")

        # impellerc writes these beside the declared outputs; GN leaves them
        # undeclared, a sandbox wants to know.
        spirv = ctx.actions.declare_file(shader.basename + ".spirv", sibling = sl)
        json = ctx.actions.declare_file(shader.basename + ".json", sibling = sl)
        depfile = ctx.actions.declare_file(shader.basename + ".d", sibling = sl)

        # The arguments as impeller/tools/compiler.gni orders them.
        arguments = ["--include=" + shader_lib_dir] + ctx.attr.flags + [
            "--input=" + shader.path,
            "--include=" + shader.dirname,
            "--depfile=" + depfile.path,
        ]
        if ctx.attr.gles_language_version:
            arguments.append("--gles-language-version=%d" % ctx.attr.gles_language_version)
        if ctx.attr.metal:
            # shaders_mtl.gni: the invoker's metal_version, "1.2" otherwise.
            arguments.append("--metal-version=" + (ctx.attr.metal_version or "1.2"))
        if ctx.attr.use_half_textures:
            arguments.append("--use-half-textures")
        if ctx.attr.require_framebuffer_fetch:
            arguments.append("--require-framebuffer-fetch")
        arguments += [
            "--entry-point-prefix=" + ctx.attr.entry_point_prefix,
            "--sl=" + sl.path,
            "--spirv=" + spirv.path,
            "--reflection-json=" + json.path,
            "--reflection-header=" + header.path,
            "--reflection-cc=" + source.path,
        ]
        arguments += ["--define=" + define for define in ctx.attr.defines]
        ctx.actions.run(
            executable = ctx.executable._impellerc,
            arguments = arguments,
            inputs = [shader] + ctx.files.includes + shader_lib,
            outputs = [sl, header, source, spirv, json, depfile],
            mnemonic = ctx.attr.mnemonic,
            progress_message = "impellerc %{input}",
        )
        sls.append(sl)
        headers.append(header)
        sources.append(source)
    return [
        DefaultInfo(files = depset(sls)),
        OutputGroupInfo(
            sl = depset(sls),
            reflection_headers = depset(headers),
            reflection_sources = depset(sources),
        ),
    ]

impellerc_compile = rule(
    implementation = _impellerc_compile_impl,
    doc = "GN's impellerc() template for one backend: one impellerc run per shader. The target's files are the compiled shaders " +
          "(`<subdir>/<file>.<extension>`); the output groups `reflection_headers` and `reflection_sources` are the reflection state.",
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
            doc = "The shaders (GN's `shaders`).",
        ),
        "includes": attr.label_list(
            allow_files = True,
            doc = "Files the shaders may `#include` beside themselves.",
        ),
        "subdir": attr.string(
            doc = "GN's intermediates_subdir: where the outputs go under the package, if anywhere. Selectable by platform.",
        ),
        "extension": attr.string(
            mandatory = True,
            doc = "GN's sl_file_extension (`vkspv`, `gles`, `metal`).",
        ),
        "flags": attr.string_list(
            mandatory = True,
            doc = "GN's `shader_target_flags` (`--vulkan`, `--opengl-es`, `--metal-desktop`).",
        ),
        "defines": attr.string_list(
            doc = "GN's `defines`: impellerc's --define= macros.",
        ),
        "gles_language_version": attr.int(
            doc = "--gles-language-version, 0 for none.",
        ),
        "metal": attr.bool(
            doc = "The Metal backend (shaders_mtl.gni): --metal-version is passed, the invoker's or 1.2.",
        ),
        "metal_version": attr.string(
            doc = "GN's metal_version, when the invoker sets it (a select() over the platform in the generated files, None off Apple).",
        ),
        "use_half_textures": attr.bool(),
        "require_framebuffer_fetch": attr.bool(),
        "entry_point_prefix": attr.string(
            mandatory = True,
            doc = "--entry-point-prefix.",
        ),
        "mnemonic": attr.string(
            default = "Impellerc",
        ),
        "_impellerc": attr.label(
            default = "//engine/src/flutter/impeller/compiler:impellerc",
            executable = True,
            cfg = "exec",
        ),
        "_shader_lib": attr.label_list(
            default = _SHADER_LIB,
            allow_files = True,
        ),
    },
)

def _shader_archive_impl(ctx):
    out = ctx.outputs.out
    arguments = [
        "--output=" + out.path,
        "--entry-point-prefix=" + ctx.attr.entry_point_prefix,
    ] + ["--input=" + shader.path for shader in ctx.files.srcs]
    ctx.actions.run(
        executable = ctx.executable._shader_archiver,
        arguments = arguments,
        inputs = ctx.files.srcs,
        outputs = [out],
        mnemonic = "ShaderArchive",
        progress_message = "shader_archiver %{output}",
    )
    return [DefaultInfo(files = depset([out]))]

shader_archive = rule(
    implementation = _shader_archive_impl,
    doc = "GN's shader_archive() template: the compiled shaders of a backend as one .shar blob.",
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
            doc = "The compiled shaders.",
        ),
        "out": attr.output(
            mandatory = True,
            doc = "The archive (GN's `$target_gen_dir/$target_name.shar`).",
        ),
        "entry_point_prefix": attr.string(mandatory = True),
        "_shader_archiver": attr.label(
            default = "//engine/src/flutter/impeller/shader_archive:shader_archiver",
            executable = True,
            cfg = "exec",
        ),
    },
)

def _metal_library_impl(ctx):
    out = ctx.actions.declare_file("shaders/" + ctx.attr.library_name + ".metallib")
    depfile = ctx.actions.declare_file("mtl/" + ctx.attr.library_name + ".depfile")
    outputs = [out, depfile]

    # metal_library.py's arguments as metal_library.gni orders them.
    arguments = [
        "--output=" + out.path,
        "--depfile=" + depfile.path,
        "--metal-version=" + (ctx.attr.metal_version or "1.2"),
    ]
    if ctx.attr.debug:
        arguments.append("--debug")
    else:
        # `metal` writes the symbols beside the library (-frecord-sources
        # in debug keeps them inside).
        outputs.append(ctx.actions.declare_file("shaders/" + ctx.attr.library_name + ".metallibsym"))
    arguments.append("--platform=" + ctx.attr.platform)
    for source in ctx.files.srcs:
        arguments += ["--source", source.path]
    args = ctx.actions.args()
    args.add("-B")
    args.add(ctx.file._script)
    args.add_all(arguments)
    ctx.actions.run(
        executable = ctx.executable._python,
        arguments = [args],
        inputs = depset([ctx.file._script] + ctx.files.srcs),
        tools = ctx.attr._python_runtime[DefaultInfo].files,
        outputs = outputs,
        mnemonic = "MetalLibrary",
        progress_message = "metal %{output}",
        # The script runs Xcode's `xcrun metal`: the shell's PATH, and
        # DEVELOPER_DIR when --action_env passes it, as for the SDK.
        use_default_shell_env = True,
        env = {
            "PYTHONDONTWRITEBYTECODE": "1",
            "PYTHONHASHSEED": "0",
        },
    )
    return [DefaultInfo(files = depset([out]))]

metal_library = rule(
    implementation = _metal_library_impl,
    doc = "GN's metal_library() template (impeller/tools/metal_library.gni): impellerc's .metal sources compiled into one " +
          ".metallib by Xcode's metal compiler (metal_library.py: `xcrun -sdk macosx metal`), under shaders/ as GN's root_out_dir has it. " +
          "The target's file is the library.",
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".metal"],
            mandatory = True,
            doc = "The Metal sources (the Metal impellerc target's files).",
        ),
        "library_name": attr.string(
            mandatory = True,
            doc = "GN's `name`: the library is shaders/<name>.metallib.",
        ),
        "metal_version": attr.string(
            doc = "GN's `metal_version` (-std=macos-metal<version>), 1.2 when unset.",
        ),
        "platform": attr.string(
            default = "mac",
            values = ["mac", "ios", "ios-simulator"],
            doc = "metal_library.py's --platform: the SDK.",
        ),
        "debug": attr.bool(
            doc = "GN's impeller_debug: -g and -frecord-sources; otherwise the symbols go to a .metallibsym beside the library.",
        ),
        "_script": attr.label(
            default = "//engine/src/flutter/impeller/tools:metal_library.py",
            allow_single_file = True,
        ),
    } | PYTHON_ATTRS,
)

def _embed_blob_impl(ctx):
    run_python(
        ctx,
        script = ctx.file._xxd,
        arguments = [
            "--symbol-name",
            ctx.attr.symbol_name,
            "--output-header",
            ctx.outputs.header.path,
            "--output-source",
            ctx.outputs.source.path,
            "--source",
            ctx.file.blob.path,
        ],
        inputs = [ctx.file.blob],
        outputs = [ctx.outputs.header, ctx.outputs.source],
        mnemonic = "Xxd",
        progress_message = "xxd.py %{output}",
    )
    return [DefaultInfo(files = depset([ctx.outputs.header, ctx.outputs.source]))]

embed_blob = rule(
    implementation = _embed_blob_impl,
    doc = "GN's embed_blob() action: a file's bytes as a C++ array (impeller/tools/xxd.py).",
    attrs = {
        "blob": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The file to embed.",
        ),
        "symbol_name": attr.string(
            mandatory = True,
            doc = "The array is impeller_<symbol_name>_data, its size impeller_<symbol_name>_length.",
        ),
        "header": attr.output(mandatory = True),
        "source": attr.output(mandatory = True),
        "_xxd": attr.label(
            default = "//engine/src/flutter/impeller/tools:xxd.py",
            allow_single_file = True,
        ),
    } | PYTHON_ATTRS,
)

def impeller_shaders(
        name,
        library_name,
        shaders,
        analyze = True,
        enable_opengles = True,
        gles_language_version = None,
        vulkan_language_version = None,
        metal_version = None,
        use_half_textures = False,
        require_framebuffer_fetch = False,
        gles_exclusions = [],
        vulkan_exclusions = [],
        entry_point_prefix = "imp_",
        target_compatible_with = None,
        **kwargs):
    """Precompiled shaders and their reflection library (GN's impeller_shaders).

    Args:
      name: the target name; the backends' targets are prefixed with it.
      library_name: GN's `name`, the base name of the embedded libraries
        (`<name>_shaders_vk`) and their symbols.
      shaders: the GLSL shaders.
      analyze: GN's `analyze` (malioc): accepted, nothing to do here.
      enable_opengles: whether to compile for GLES (GN's default is
        `impeller_enable_opengles`, on for the host).
      gles_language_version: --gles-language-version for GLES 2 (GLES 3
        is always 300).
      vulkan_language_version: GN's `vulkan_language_version`, which only
        malioc reads; accepted.
      metal_version: the Metal language version for the Metal backend's
        impellerc and the metal compiler (GN's default "1.2"); the
        generated files pass a select() over the platform, None elsewhere.
      use_half_textures: --use-half-textures for the Metal backend.
      require_framebuffer_fetch: --require-framebuffer-fetch for GLES.
      gles_exclusions: shaders not compiled for GLES.
      vulkan_exclusions: shaders not compiled for Vulkan.
      entry_point_prefix: --entry-point-prefix.
      target_compatible_with: applied to every target created, since GN
        defines the whole set under one condition (or not at all).
      **kwargs: `testonly`, `visibility` for the group.
    """
    _unused = (analyze, vulkan_language_version)  # buildifier: disable=unused-variable
    testonly = kwargs.get("testonly")

    # The Apple platforms alone: the Metal backend's targets.
    apple_only = select({
        _APPLE: [],
        "//conditions:default": ["@platforms//:incompatible"],
    })

    # impeller_debug (impeller/tools/args.gni): the debug and profile
    # runtime modes.
    impeller_debug = select({
        "//engine/src/flutter/common:runtime_mode_release": False,
        "//engine/src/flutter/common:runtime_mode_jit_release": False,
        "//conditions:default": True,
    })

    # What a shader may #include beside itself.
    includes = native.glob(["**/*.glsl"], allow_empty = True)

    # shaders.gni: "wasm builds only use GLES3, no need to build GLES2
    # shaders" -- the GLES 2 backend's targets are incompatible with the web
    # platform and the group lists them everywhere else.
    not_web = select({
        "@platforms//os:emscripten": ["@platforms//:incompatible"],
        "//conditions:default": [],
    })

    backends = []
    gles2_backends = []
    metal_backends = []
    for backend in _BACKENDS:
        if backend.opengles and not enable_opengles:
            continue
        metal = backend.tag in _METAL_TAGS
        exclusions = gles_exclusions if backend.opengles else vulkan_exclusions
        backend_shaders = [shader for shader in shaders if shader not in exclusions]
        tag = backend.tag + "_" + name
        compatible_with = target_compatible_with
        if backend.tag == "gles":
            compatible_with = (target_compatible_with or []) + not_web
        if metal:
            compatible_with = (target_compatible_with or []) + apple_only
        version = backend.version
        if version == None and backend.opengles and gles_language_version != None:
            version = gles_language_version
        impellerc_compile(
            name = "impellerc_" + tag,
            srcs = backend_shaders,
            includes = includes,
            subdir = backend.subdir,
            extension = backend.extension,
            flags = backend.flags,
            defines = backend.defines,
            gles_language_version = version or 0,
            # shaders_mtl.gni alone passes metal_version on (the invoker's,
            # or 1.2, which the rule supplies): a select() over the
            # platform in the generated files, with None off Apple, which
            # Bazel reads as the attribute's default.
            metal = metal,
            metal_version = metal_version if metal else None,
            use_half_textures = use_half_textures and metal,
            require_framebuffer_fetch = require_framebuffer_fetch and backend.opengles,
            entry_point_prefix = entry_point_prefix,
            mnemonic = backend.mnemonic,
            testonly = testonly,
            target_compatible_with = compatible_with,
            visibility = ["//visibility:private"],
        )
        for group in ["reflection_headers", "reflection_sources"]:
            native.filegroup(
                name = "impellerc_" + tag + "_" + group,
                srcs = [":impellerc_" + tag],
                output_group = group,
                testonly = testonly,
                target_compatible_with = compatible_with,
                visibility = ["//visibility:private"],
            )
        if metal:
            metal_library(
                name = "genlib_" + tag,
                srcs = [":impellerc_" + tag],
                library_name = library_name,
                metal_version = metal_version,
                debug = impeller_debug,
                # metal_library.gni's --platform: the simulator's or a
                # device's SDK under is_ios (use_ios_simulator), the Mac's
                # otherwise.
                platform = select({
                    "//engine/src/flutter/build/bazel:ios_simulator_enabled": "ios-simulator",
                    "@platforms//os:ios": "ios",
                    "//conditions:default": "mac",
                }),
                testonly = testonly,
                target_compatible_with = compatible_with,
                visibility = ["//visibility:private"],
            )
        else:
            shader_archive(
                name = "genlib_" + tag,
                srcs = [":impellerc_" + tag],
                out = "genlib_" + tag + ".shar",
                entry_point_prefix = entry_point_prefix,
                testonly = testonly,
                target_compatible_with = compatible_with,
                visibility = ["//visibility:private"],
            )
        embed = backend.embed % library_name
        embed_blob(
            name = "gen_blob_embed_" + tag,
            blob = ":genlib_" + tag,
            symbol_name = backend.symbol % library_name,
            header = embed + ".h",
            source = embed + ".cc",
            testonly = testonly,
            target_compatible_with = compatible_with,
            visibility = ["//visibility:private"],
        )

        # GN's source_set over the embedded blob: not engine code by the
        # converter's rule (it lists no //flutter:config and depends on
        # none), hence CHROMIUM_CODE_COPTS.
        cc_library(
            name = "embed_" + tag,
            srcs = [embed + ".cc"],
            hdrs = [embed + ".h"],
            copts = CHROMIUM_CODE_COPTS,
            local_defines = FLUTTER_LOCAL_DEFINES,
            deps = ["//engine/src/flutter:config"],
            testonly = testonly,
            target_compatible_with = compatible_with,
            alwayslink = True,
        )

        # GN's impellerc_reflect: engine code (it depends on impeller/core).
        cc_library(
            name = "reflect_" + tag,
            srcs = [":impellerc_" + tag + "_reflection_sources"],
            hdrs = [":impellerc_" + tag + "_reflection_headers"],
            copts = FLUTTER_COPTS,
            local_defines = FLUTTER_LOCAL_DEFINES,
            deps = [
                "//engine/src:include_root",
                "//engine/src/flutter:config",
                "//engine/src/flutter/impeller/core",
            ],
            testonly = testonly,
            target_compatible_with = compatible_with,
            alwayslink = True,
        )

        # The reflection library in the group where the backend's is the
        # public one: never (GLES), always (Metal), or off Apple (Vulkan's,
        # a select).
        reflect = backend.reflect
        if type(reflect) == type(True):
            reflect = [":reflect_" + tag] if reflect else []
        else:
            reflect = select({
                _APPLE: [],
                "//conditions:default": [":reflect_" + tag],
            })
        cc_library(
            name = tag,
            deps = [":embed_" + tag] + reflect,
            testonly = testonly,
            target_compatible_with = compatible_with,
        )
        if backend.tag == "gles":
            gles2_backends.append(":" + tag)
        elif metal:
            metal_backends.append(":" + tag)
        else:
            backends.append(":" + tag)

    cc_library(
        name = name,
        deps = backends + select({
            "@platforms//os:emscripten": [],
            "//conditions:default": gles2_backends,
        }) + select({
            _APPLE: metal_backends,
            "//conditions:default": [],
        }),
        target_compatible_with = target_compatible_with,
        **kwargs
    )

# ---------------------------------------------------------------------------
# impellerc(): the template invoked directly
# ---------------------------------------------------------------------------

# The target flags for which GN's template generates reflection state.
_REFLECTING_FLAGS = [
    "--metal-ios",
    "--metal-desktop",
    "--opengl-es",
    "--opengl-desktop",
    "--vulkan",
]

def _impellerc_run_impl(ctx):
    shader_lib = ctx.files._shader_lib
    if not shader_lib:
        fail("%s: the shader library has no files" % ctx.label)
    shader_lib_dir = shader_lib[0].dirname.rsplit("/", 1)[0]
    shaders = ctx.files.srcs

    # The arguments as impeller/tools/compiler.gni orders them, up to the
    # per-run ones.
    common = ["--include=" + shader_lib_dir] + ctx.attr.flags
    if ctx.attr.gles_language_version:
        common.append("--gles-language-version=%d" % ctx.attr.gles_language_version)
    if ctx.attr.metal_version:
        common.append("--metal-version=" + ctx.attr.metal_version)
    if ctx.attr.use_half_textures:
        common.append("--use-half-textures")
    if ctx.attr.require_framebuffer_fetch:
        common.append("--require-framebuffer-fetch")
    if ctx.attr.entry_point_prefix != None and ctx.attr.has_entry_point_prefix:
        common.append("--entry-point-prefix=" + ctx.attr.entry_point_prefix)
    if ctx.attr.json:
        common.append("--json")
    if ctx.attr.iplr:
        common.append("--iplr")
    defines = ["--define=" + define for define in ctx.attr.defines]
    inputs = shaders + ctx.files.includes + shader_lib

    if ctx.attr.shader_bundle:
        # One invocation; the bundle names the shaders by path (the
        # converter's $(src ...) tokens, which expand to execution-root
        # relative paths, as GN's rebase_path gave absolute ones).
        if len(ctx.outputs.outs) != 1:
            fail("%s: a shader bundle is one output" % ctx.label)
        out = ctx.outputs.outs[0]
        bundle = expand_gn_paths(ctx, ctx.attr.shader_bundle, ctx.attr.srcs)
        ctx.actions.run(
            executable = ctx.executable._impellerc,
            arguments = common + ["--sl=" + out.path, "--shader-bundle=" + bundle] + defines,
            inputs = inputs,
            outputs = [out],
            mnemonic = ctx.attr.mnemonic,
            progress_message = "impellerc %{output}",
        )

        # The empty CcInfo keeps the edges GN has from libraries to the
        # template's target (ordering), which the converter maps to deps.
        return [DefaultInfo(files = depset([out])), CcInfo()]

    if len(ctx.outputs.outs) != len(shaders):
        fail("%s: one output per shader" % ctx.label)
    reflecting = [flag for flag in ctx.attr.flags if flag in _REFLECTING_FLAGS]
    products = []
    for i, shader in enumerate(shaders):
        sl = ctx.outputs.outs[i]
        spirv = ctx.actions.declare_file(shader.basename + ".spirv", sibling = sl)
        depfile = ctx.actions.declare_file(shader.basename + ".d", sibling = sl)
        arguments = common + [
            "--input=" + shader.path,
            "--include=" + shader.dirname,
            "--depfile=" + depfile.path,
            "--sl=" + sl.path,
            "--spirv=" + spirv.path,
        ]
        outputs = [sl, spirv, depfile]
        products.append(sl)
        if reflecting:
            json = ctx.actions.declare_file(shader.basename + ".json", sibling = sl)
            header = ctx.actions.declare_file(shader.basename + ".h", sibling = sl)
            source = ctx.actions.declare_file(shader.basename + ".cc", sibling = sl)
            arguments += [
                "--reflection-json=" + json.path,
                "--reflection-header=" + header.path,
                "--reflection-cc=" + source.path,
            ]
            outputs += [json, header, source]

            # GN's outputs: the compiled shader, the header and the source.
            products += [header, source]
        ctx.actions.run(
            executable = ctx.executable._impellerc,
            arguments = arguments + defines,
            inputs = inputs,
            outputs = outputs,
            mnemonic = ctx.attr.mnemonic,
            progress_message = "impellerc %{input}",
        )
    return [DefaultInfo(files = depset(products)), CcInfo()]

impellerc_run = rule(
    implementation = _impellerc_run_impl,
    doc = "GN's impellerc() template as invoked directly: one impellerc run per shader, or one run for a shader bundle. " +
          "The target's files are GN's outputs (the compiled shaders, plus the reflection header and source when a reflecting target flag is given).",
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
            doc = "The shaders (GN's `shaders`).",
        ),
        "includes": attr.label_list(
            allow_files = True,
            doc = "Files the shaders may `#include` beside themselves.",
        ),
        "outs": attr.output_list(
            mandatory = True,
            doc = "The compiled shader of each source, in order (`<subdir>/<file>.<extension>`), or the one bundle.",
        ),
        "flags": attr.string_list(
            doc = "GN's `shader_target_flags`.",
        ),
        "defines": attr.string_list(
            doc = "GN's `defines`: impellerc's --define= macros.",
        ),
        "gles_language_version": attr.int(
            doc = "--gles-language-version, 0 for none.",
        ),
        "metal_version": attr.string(
            doc = "--metal-version, empty for none.",
        ),
        "use_half_textures": attr.bool(),
        "require_framebuffer_fetch": attr.bool(),
        "has_entry_point_prefix": attr.bool(
            doc = "Whether --entry-point-prefix is passed at all (GN passes it only when the invoker sets it).",
        ),
        "entry_point_prefix": attr.string(),
        "json": attr.bool(doc = "GN's `json`: --json."),
        "iplr": attr.bool(doc = "GN's `iplr`: --iplr."),
        "shader_bundle": attr.string(
            doc = "GN's `shader_bundle`: the bundle's JSON, with the shaders' paths as $(src ...) tokens; one invocation.",
        ),
        "mnemonic": attr.string(
            default = "Impellerc",
        ),
        "_impellerc": attr.label(
            default = "//engine/src/flutter/impeller/compiler:impellerc",
            executable = True,
            cfg = "exec",
        ),
        "_shader_lib": attr.label_list(
            default = _SHADER_LIB,
            allow_files = True,
        ),
    },
)

def impellerc(
        name,
        shaders,
        shader_target_flags = [],
        sl_file_extension = None,
        intermediates_subdir = None,
        iplr = False,
        json = False,
        shader_bundle = None,
        shader_bundle_output = None,
        gles_language_version = None,
        metal_version = None,
        use_half_textures = False,
        require_framebuffer_fetch = False,
        entry_point_prefix = None,
        defines = [],
        mnemonic = None,
        **kwargs):
    """GN's impellerc() template (impeller/tools/compiler.gni), invoked directly.

    The runtime stages and shader bundles of the test fixtures: one
    impellerc run per shader writing `<intermediates_subdir>/<shader>.<sl_file_extension>`,
    or, with `shader_bundle`, one run writing `<intermediates_subdir>/<shader_bundle_output>`.
    The target's files are what GN's get_target_outputs() lists.

    Args:
      name: the target name.
      shaders: the GLSL shaders.
      shader_target_flags: impellerc's target flags (`--sksl`,
        `--runtime-stage-vulkan`, `--vulkan`, ...).
      sl_file_extension: the compiled shader's extension (`iplr`, `vkspv`).
      intermediates_subdir: the subdirectory of the outputs, if any.
      iplr: --iplr.
      json: --json.
      shader_bundle: the bundle's JSON (one invocation), paths as the
        converter's $(src ...) tokens.
      shader_bundle_output: the bundle's file name.
      gles_language_version: --gles-language-version.
      metal_version: --metal-version (compiler.gni passes it wherever the
        invoker sets it; GN asserts an Apple platform).
      use_half_textures: --use-half-textures.
      require_framebuffer_fetch: --require-framebuffer-fetch.
      entry_point_prefix: --entry-point-prefix, when set.
      defines: --define= macros.
      mnemonic: GN's `mnemonic`, the action's.
      **kwargs: `testonly`, `visibility`, `target_compatible_with`.
    """
    prefix = intermediates_subdir + "/" if intermediates_subdir else ""
    if shader_bundle != None:
        if not shader_bundle_output:
            fail("impellerc(%s): shader_bundle needs shader_bundle_output" % name)
        outs = [prefix + shader_bundle_output]
    else:
        if not sl_file_extension:
            fail("impellerc(%s): sl_file_extension is required without shader_bundle" % name)

        # GN's {{source_file_part}}: the file name, whether the shader is a
        # path in this package or a label of another's.
        outs = [prefix + shader.rsplit(":", 1)[-1].rsplit("/", 1)[-1] + "." + sl_file_extension for shader in shaders]
    impellerc_run(
        name = name,
        srcs = shaders,
        includes = native.glob(["**/*.glsl"], allow_empty = True),
        outs = outs,
        flags = shader_target_flags,
        defines = defines,
        gles_language_version = gles_language_version or 0,
        metal_version = metal_version,
        use_half_textures = use_half_textures,
        require_framebuffer_fetch = require_framebuffer_fetch,
        has_entry_point_prefix = entry_point_prefix != None,
        entry_point_prefix = entry_point_prefix or "",
        json = json,
        iplr = iplr,
        shader_bundle = shader_bundle or "",
        # Bazel's mnemonics are letters and digits (GN's IMPELLERC_IPLR).
        mnemonic = "".join([c for c in (mnemonic or "Impellerc").elems() if c.isalnum()]),
        **kwargs
    )

# ---------------------------------------------------------------------------
# embed_blob(): the template invoked directly
# ---------------------------------------------------------------------------

def embed_blob_library(name, symbol_name, blob, hdr, cc, deps = [], **kwargs):
    """GN's embed_blob() template (impeller/tools/embed_blob.gni), invoked directly.

    A file's bytes as a C++ array (impeller/tools/xxd.py) behind a library
    whose header is included by its path under //flutter
    (`impeller/toolkit/interop/embedded_icu_data.h`): the template's
    `embed_<name>` config puts the generated tree's `flutter/` on the include
    path, which `//engine/src/flutter:config` is here.

    Args:
      name: the target name; the action is `gen_blob_<name>`, as in GN.
      symbol_name: the array's name (`impeller_<symbol_name>_data`).
      blob: the file to embed.
      hdr: the header to write, relative to this package.
      cc: the source to write, relative to this package.
      deps: GN's `deps`: ordering only (the blob carries the file dependency).
      **kwargs: `testonly`, `visibility`, `target_compatible_with`.
    """
    _unused = deps  # buildifier: disable=unused-variable
    embed_blob(
        name = "gen_blob_" + name,
        blob = blob,
        symbol_name = symbol_name,
        header = hdr,
        source = cc,
        visibility = ["//visibility:private"],
        testonly = kwargs.get("testonly", False),
        target_compatible_with = kwargs.get("target_compatible_with", []),
    )
    cc_library(
        name = name,
        srcs = [cc],
        hdrs = [hdr],
        copts = CHROMIUM_CODE_COPTS,
        local_defines = FLUTTER_LOCAL_DEFINES,
        deps = ["//engine/src/flutter:config"],
        alwayslink = True,
        **kwargs
    )
