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

The expansion is the one shaders.gni produces on a Linux host:
`impeller_enable_opengles` and `impeller_enable_vulkan` on, Metal off, so
three backends -- GLES 2 (`gles`), GLES 3 (`gles3`, language version 300)
and Vulkan (`vk`) -- with the Vulkan reflection library the one dependents
see (`!impeller_enable_metal`), and the GLES intermediates under
subdirectories (`impeller_enable_vulkan`). The target names are GN's, so
that `gn desc` and the generated tree read alike:

  impellerc_<backend>_<name>       the per-shader impellerc runs
  genlib_<backend>_<name>          the .shar archive
  gen_blob_embed_<backend>_<name>  xxd.py
  embed_<backend>_<name>           the embedded blob, a library
  reflect_<backend>_<name>         the reflection headers and sources
  <backend>_<name>                 the backend's group
  <name>                           the group over the backends

Generated headers are included by their path under GN's `gen/flutter`
(`impeller/entity/solid_fill.vert.h`, `impeller/entity/vk/entity_shaders_vk.h`);
//engine/src/flutter:config's `includes` spans the output tree, which is
where they land.

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

# One entry per backend shaders.gni enables on a Linux host.
#   tag:        GN's target-name prefix and the group's name.
#   subdir:     impellerc's intermediates_subdir ("" for Vulkan: without
#               Metal, shaders_vk.gni keeps them in the target's directory).
#   extension:  sl_file_extension.
#   flags:      shader_target_flags.
#   defines:    the --define= macros.
#   version:    a fixed --gles-language-version (GLES 3), or None for the
#               invoker's.
#   symbol:     the embedded blob's symbol, over the library name.
#   embed:      the embedded blob's header and source, without extension.
#   opengles:   whether enable_opengles, gles_exclusions,
#               gles_language_version and require_framebuffer_fetch apply.
#   reflect:    whether the group exposes the reflection library.
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
        subdir = "",
        extension = "vkspv",
        flags = ["--vulkan"],
        defines = ["IMPELLER_TARGET_VULKAN"],
        version = None,
        symbol = "%s_shaders_vk",
        embed = "vk/%s_shaders_vk",
        opengles = False,
        reflect = True,
        mnemonic = "ImpellercVulkan",
    ),
]

def _impellerc_compile_impl(ctx):
    shader_lib = ctx.files._shader_lib
    if not shader_lib:
        fail("%s: the shader library has no files" % ctx.label)

    # .../compiler/shader_lib, the parent of the copies' directories.
    shader_lib_dir = shader_lib[0].dirname.rsplit("/", 1)[0]
    shaders = ctx.files.srcs
    counts = [len(ctx.outputs.sl), len(ctx.outputs.reflection_headers), len(ctx.outputs.reflection_sources)]
    if counts != [len(shaders)] * 3:
        fail("%s: one sl, header and source output per shader" % ctx.label)
    for i, shader in enumerate(shaders):
        sl = ctx.outputs.sl[i]
        header = ctx.outputs.reflection_headers[i]
        source = ctx.outputs.reflection_sources[i]

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
    return [DefaultInfo(files = depset(ctx.outputs.sl))]

impellerc_compile = rule(
    implementation = _impellerc_compile_impl,
    doc = "GN's impellerc() template for one backend: one impellerc run per shader. The target's files are the compiled shaders.",
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
        "sl": attr.output_list(
            mandatory = True,
            doc = "The compiled shader of each source, in order (`<subdir>/<file>.<extension>`).",
        ),
        "reflection_headers": attr.output_list(
            mandatory = True,
            doc = "The reflection header of each source, in order.",
        ),
        "reflection_sources": attr.output_list(
            mandatory = True,
            doc = "The reflection source of each source, in order.",
        ),
        "flags": attr.string_list(
            mandatory = True,
            doc = "GN's `shader_target_flags` (`--vulkan`, `--opengl-es`).",
        ),
        "defines": attr.string_list(
            doc = "GN's `defines`: impellerc's --define= macros.",
        ),
        "gles_language_version": attr.int(
            doc = "--gles-language-version, 0 for none.",
        ),
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
      metal_version: Metal's; accepted (no Metal backend here).
      use_half_textures: Metal's; accepted.
      require_framebuffer_fetch: --require-framebuffer-fetch for GLES.
      gles_exclusions: shaders not compiled for GLES.
      vulkan_exclusions: shaders not compiled for Vulkan.
      entry_point_prefix: --entry-point-prefix.
      target_compatible_with: applied to every target created, since GN
        defines the whole set under one condition (or not at all).
      **kwargs: `testonly`, `visibility` for the group.
    """
    _unused = (analyze, vulkan_language_version, metal_version, use_half_textures)  # buildifier: disable=unused-variable
    testonly = kwargs.get("testonly")

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
    for backend in _BACKENDS:
        if backend.opengles and not enable_opengles:
            continue
        exclusions = gles_exclusions if backend.opengles else vulkan_exclusions
        backend_shaders = [shader for shader in shaders if shader not in exclusions]
        tag = backend.tag + "_" + name
        prefix = backend.subdir + "/" if backend.subdir else ""
        compatible_with = target_compatible_with
        if backend.tag == "gles":
            compatible_with = (target_compatible_with or []) + not_web

        # GN's {{source_file_part}}.
        stems = [prefix + shader.rsplit("/", 1)[-1] for shader in backend_shaders]
        reflection_headers = [stem + ".h" for stem in stems]
        reflection_sources = [stem + ".cc" for stem in stems]
        version = backend.version
        if version == None and backend.opengles and gles_language_version != None:
            version = gles_language_version
        impellerc_compile(
            name = "impellerc_" + tag,
            srcs = backend_shaders,
            includes = includes,
            sl = [stem + "." + backend.extension for stem in stems],
            reflection_headers = reflection_headers,
            reflection_sources = reflection_sources,
            flags = backend.flags,
            defines = backend.defines,
            gles_language_version = version or 0,
            require_framebuffer_fetch = require_framebuffer_fetch and backend.opengles,
            entry_point_prefix = entry_point_prefix,
            mnemonic = backend.mnemonic,
            testonly = testonly,
            target_compatible_with = compatible_with,
            visibility = ["//visibility:private"],
        )
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
            srcs = reflection_sources,
            hdrs = reflection_headers,
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
        cc_library(
            name = tag,
            deps = [":embed_" + tag] + ([":reflect_" + tag] if backend.reflect else []),
            testonly = testonly,
            target_compatible_with = compatible_with,
        )
        if backend.tag == "gles":
            gles2_backends.append(":" + tag)
        else:
            backends.append(":" + tag)

    cc_library(
        name = name,
        deps = backends + select({
            "@platforms//os:emscripten": [],
            "//conditions:default": gles2_backends,
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
      metal_version: Metal's; accepted (no Metal here).
      use_half_textures: --use-half-textures.
      require_framebuffer_fetch: --require-framebuffer-fetch.
      entry_point_prefix: --entry-point-prefix, when set.
      defines: --define= macros.
      mnemonic: GN's `mnemonic`, the action's.
      **kwargs: `testonly`, `visibility`, `target_compatible_with`.
    """
    _unused = metal_version  # buildifier: disable=unused-variable
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
