# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The asset directory `flutter test` gives a package's tests (flutter_test_assets).

`flutter test` builds the package's asset bundle into build/unit_test_assets
and starts flutter_tester with `--flutter-assets-dir` on it
(packages/flutter_tools/lib/src/commands/test.dart; asset.dart builds the
bundle). Tests reach it through the engine's asset manager: `Image.asset`
and `rootBundle` for the package's assets, `FragmentProgram.fromAsset` for
the shaders -- the framework's own `shaders/ink_sparkle.frag` and
`shaders/stretch_effect.frag`, which flutter_tools compiles into every
bundle (asset.dart's _getFrameworkShaders) and the Material and the
stretch overscroll widgets load; a test that pumps a MaterialApp reaches
them.

flutter_test_assets lays the directory out under the target's name:
test_assets.py's manifests (an empty asset map, no fonts, no native
assets -- what packages/flutter's bundle holds), and each shader compiled
by the Bazel-built impellerc as flutter_tools compiles it for
flutter_tester (`--sksl --runtime-stage-vulkan --iplr`, the shader_lib
include; shader_compiler.dart). A package's own assets and fonts, and
NOTICES.Z (the packages' licenses, which LicenseRegistry reads) are not
built yet; see research/15.
"""

FlutterTestAssetsInfo = provider(
    doc = "A test's asset directory.",
    fields = {
        "asset_manifest": "File: the directory's AssetManifest.bin; the directory is its parent.",
    },
)

def _flutter_test_assets_impl(ctx):
    prefix = ctx.label.name
    asset_manifest = ctx.actions.declare_file(prefix + "/AssetManifest.bin")
    font_manifest = ctx.actions.declare_file(prefix + "/FontManifest.json")
    native_assets_manifest = ctx.actions.declare_file(prefix + "/NativeAssetsManifest.json")
    args = ctx.actions.args()
    args.add(ctx.file._script)
    args.add("--asset-manifest", asset_manifest)
    args.add("--font-manifest", font_manifest)
    args.add("--native-assets-manifest", native_assets_manifest)
    ctx.actions.run(
        executable = ctx.executable._python,
        arguments = [args],
        inputs = depset([ctx.file._script], transitive = [ctx.attr._python_runtime[DefaultInfo].files]),
        outputs = [asset_manifest, font_manifest, native_assets_manifest],
        env = {"PYTHONDONTWRITEBYTECODE": "1"},
        mnemonic = "FlutterTestAssets",
        progress_message = "Writing the asset manifests of %s" % ctx.label,
    )
    outputs = [asset_manifest, font_manifest, native_assets_manifest]

    # The shader_lib include directory: the package's source directory.
    shader_lib = ctx.attr._shader_lib.label.package
    for target, entry in ctx.attr.shaders.items():
        sources = target[DefaultInfo].files.to_list()
        if len(sources) != 1:
            fail("%s: shaders: %s should be one file" % (ctx.label, target.label))
        source = sources[0]
        compiled = ctx.actions.declare_file(prefix + "/" + entry)

        # impellerc writes the SPIR-V beside its output too; kept out of the
        # directory, as flutter_tools' bundle has no such file.
        spirv = ctx.actions.declare_file(prefix + ".spirv/" + entry + ".spirv")
        args = ctx.actions.args()
        args.add("--sksl")
        args.add("--runtime-stage-vulkan")
        args.add("--iplr")
        args.add(compiled, format = "--sl=%s")
        args.add(spirv, format = "--spirv=%s")
        args.add(source, format = "--input=%s")
        args.add("--input-type=frag")
        args.add(source.dirname, format = "--include=%s")
        args.add(shader_lib, format = "--include=%s")
        ctx.actions.run(
            executable = ctx.executable._impellerc,
            arguments = [args],
            inputs = depset([source], transitive = [ctx.attr._shader_lib[DefaultInfo].files]),
            outputs = [compiled, spirv],
            mnemonic = "ImpellerCompile",
            progress_message = "Compiling %s for the tests' assets" % source.short_path,
        )
        outputs.append(compiled)
    return [
        DefaultInfo(files = depset(outputs)),
        FlutterTestAssetsInfo(asset_manifest = asset_manifest),
    ]

flutter_test_assets = rule(
    implementation = _flutter_test_assets_impl,
    doc = "The asset directory of a package's tests, as `flutter test` builds it: the manifests and the compiled shaders.",
    attrs = {
        "shaders": attr.label_keyed_string_dict(
            allow_files = [".frag"],
            doc = "Each shader source to its path in the directory (`shaders/ink_sparkle.frag`).",
        ),
        "_script": attr.label(
            default = "//engine/src/flutter/build/bazel/dart:test_assets.py",
            allow_single_file = True,
        ),
        "_python": attr.label(
            default = "@cpython3//:bin/python3",
            executable = True,
            cfg = "exec",
            allow_single_file = True,
        ),
        "_python_runtime": attr.label(default = "@cpython3//:runtime"),
        "_impellerc": attr.label(
            default = "//engine/src/flutter/impeller/compiler:impellerc",
            executable = True,
            cfg = "exec",
        ),
        "_shader_lib": attr.label(
            default = "//engine/src/flutter/impeller/compiler/shader_lib:all_files",
            allow_files = True,
        ),
    },
)
