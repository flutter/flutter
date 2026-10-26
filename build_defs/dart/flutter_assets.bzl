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
test_assets.py's manifests (the asset map, no fonts, no native assets),
the package's own assets at their keys (`assets`, each file's path under
`assets_root` -- the package's directory -- as flutter_tools keys it, with
resolution variants beside their main asset in the map), and each shader
compiled by the Bazel-built impellerc as flutter_tools compiles it for
flutter_tester (`--sksl --runtime-stage-vulkan --iplr`, the shader_lib
include; shader_compiler.dart). Fonts (flutter_tester runs tests with
--disable-asset-fonts) and NOTICES.Z (the packages' licenses, which
LicenseRegistry reads) are not built; see research/15.
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
    outputs = [asset_manifest, font_manifest, native_assets_manifest]

    # The package's assets, each at its key: the path under the package's
    # directory, as flutter_tools keys an asset of the application.
    root = ctx.attr.assets_root
    keyed = []
    for file in ctx.files.assets:
        if root and not file.short_path.startswith(root + "/"):
            fail("%s: assets: %s is not under %s" % (ctx.label, file.short_path, root))
        keyed.append((file.short_path[len(root) + 1:] if root else file.short_path, file))

    # A dependency's assets, as flutter_tools keys them: `packages/<name>/`
    # and the file's path under the package's lib/ (an asset the pubspec
    # names as `packages/flutter_gallery_assets/people/ali_landscape.png`
    # is lib/people/ali_landscape.png of that package); and a dependency's
    # fonts, which its own pubspec declares relative to its root
    # (cupertino_icons' assets/CupertinoIcons.ttf), under `packages/<name>/`
    # at that path -- its assets/ and fonts/ directories. All of them rather
    # than the pubspecs' lists: the superset is harmless to a test.
    for target, name in ctx.attr.package_assets.items():
        for file in target[DefaultInfo].files.to_list():
            path = file.short_path
            if path.startswith("../"):
                path = path.split("/", 2)[2]
            elif target.label.package:
                path = path[len(target.label.package) + 1:]
            if path.startswith("lib/"):
                keyed.append(("packages/%s/%s" % (name, path[len("lib/"):]), file))
            elif path.startswith("assets/") or path.startswith("fonts/"):
                keyed.append(("packages/%s/%s" % (name, path), file))
    for key, file in keyed:
        placed = ctx.actions.declare_file(prefix + "/" + key)
        ctx.actions.symlink(output = placed, target_file = file)
        outputs.append(placed)
        args.add("--asset", key)
    ctx.actions.run(
        executable = ctx.executable._python,
        arguments = [args],
        inputs = depset([ctx.file._script], transitive = [ctx.attr._python_runtime[DefaultInfo].files]),
        outputs = [asset_manifest, font_manifest, native_assets_manifest],
        env = {"PYTHONDONTWRITEBYTECODE": "1"},
        mnemonic = "FlutterTestAssets",
        progress_message = "Writing the asset manifests of %s" % ctx.label,
    )

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
        "assets": attr.label_list(
            allow_files = True,
            doc = "The package's own asset files, as its pubspec declares them; each is placed at " +
                  "its path under `assets_root` and listed in the manifest.",
        ),
        "assets_root": attr.string(
            doc = "The package's directory, relative to the repository (`dev/integration_tests/ui`): " +
                  "the assets' keys are their paths under it.",
        ),
        "package_assets": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "Dependencies whose files the pubspec names as assets (`packages/<name>/...`: their lib/ files) " +
                  "or whose own pubspecs declare fonts (their assets/ and fonts/ files, at their root-relative " +
                  "paths): each one's files (a pub repository's `sources`) to the package's name.",
        ),
        "shaders": attr.label_keyed_string_dict(
            allow_files = [".frag"],
            doc = "Each shader source to its path in the directory (`shaders/ink_sparkle.frag`).",
        ),
        "_script": attr.label(
            default = "//build_defs/dart:test_assets.py",
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
