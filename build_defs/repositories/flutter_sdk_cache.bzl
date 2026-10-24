# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The Flutter SDK's cache artifacts a framework test reads, as Bazel repositories.

The flutter tool downloads what the SDK needs beyond the repository into
`bin/cache/` (flutter_tools' Cache): the Dart SDK, the engine's artifacts,
the Material fonts. Two of the framework's tests read that cache through
FLUTTER_ROOT -- foundation/isolates_test runs `bin/cache/dart-sdk/bin/
dartvm`, material/icons_test loads `bin/cache/artifacts/material_fonts/
MaterialIcons-Regular.otf` -- and a flutter_test's runfiles tree is
FLUTTER_ROOT, so the rule lays the same paths there (its `cache`
attribute): the prebuilt Dart SDK the engine builds with for `dart-sdk`,
and the fonts from this file's repository.

`material_fonts` fetches the archive bin/internal/material_fonts.version
names, as the tool does (flutter_cache.dart's MaterialFonts: the file is a
path under storage.googleapis.com), verified against the sha256 pinned
here. The version file is watched: a font roll that changes it fails the
fetch until the pin follows.
"""

# The archive bin/internal/material_fonts.version named when this was
# pinned, and its sha256 (`sha256sum` of the download). A roll changes the
# version file; update both together.
_MATERIAL_FONTS_PATH = "flutter_infra_release/flutter/fonts/3012db47f3130e62f7cc0beabff968a33cbec8d8/fonts.zip"
_MATERIAL_FONTS_SHA256 = "e56fa8e9bb4589fde964be3de451f3e5b251e4a1eafb1dc98d94add034dd5a86"

_STORAGE = "https://storage.googleapis.com/"

def _material_fonts_impl(rctx):
    version_file = rctx.path(Label("//bin/internal:material_fonts.version"))
    rctx.watch(version_file)
    named = rctx.read(version_file).strip()
    if named != _MATERIAL_FONTS_PATH:
        fail(("bin/internal/material_fonts.version names %s, but %s pins %s: update _MATERIAL_FONTS_PATH " +
              "and _MATERIAL_FONTS_SHA256 (sha256sum of %s%s).") % (
            named,
            "build_defs/repositories/flutter_sdk_cache.bzl",
            _MATERIAL_FONTS_PATH,
            _STORAGE,
            named,
        ))
    rctx.download_and_extract(
        url = _STORAGE + named,
        sha256 = _MATERIAL_FONTS_SHA256,
        type = "zip",
    )
    rctx.file("BUILD.bazel", """# The Material fonts of bin/internal/material_fonts.version (flutter_sdk_cache.bzl).

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "fonts",
    srcs = glob(["**"], exclude = ["BUILD.bazel", "REPO.bazel"]),
)
""")

material_fonts = repository_rule(
    implementation = _material_fonts_impl,
    doc = "The Material fonts archive the flutter tool caches as bin/cache/artifacts/material_fonts.",
)

# The Gradle wrapper archive bin/internal/gradle_wrapper.version names
# (flutter_cache.dart's GradleWrapper; the tool lays it as
# bin/cache/artifacts/gradle_wrapper and `flutter create` copies it into an
# Android project), and its sha256, pinned the same way.
_GRADLE_WRAPPER_PATH = "flutter_infra_release/gradle-wrapper/fd5c1f2c013565a3bea56ada6df9d2b8e96d56aa/gradle-wrapper.tgz"
_GRADLE_WRAPPER_SHA256 = "31e9428baf1a2b2f485f1110c5899f852649b33d46a2e9b07f9d17752d50190a"

def _gradle_wrapper_impl(rctx):
    version_file = rctx.path(Label("//bin/internal:gradle_wrapper.version"))
    rctx.watch(version_file)
    named = rctx.read(version_file).strip()
    if named != _GRADLE_WRAPPER_PATH:
        fail(("bin/internal/gradle_wrapper.version names %s, but %s pins %s: update _GRADLE_WRAPPER_PATH " +
              "and _GRADLE_WRAPPER_SHA256 (sha256sum of %s%s).") % (
            named,
            "build_defs/repositories/flutter_sdk_cache.bzl",
            _GRADLE_WRAPPER_PATH,
            _STORAGE,
            named,
        ))
    rctx.download_and_extract(
        url = _STORAGE + named,
        sha256 = _GRADLE_WRAPPER_SHA256,
        type = "tgz",
    )
    rctx.file("BUILD.bazel", """# The Gradle wrapper of bin/internal/gradle_wrapper.version (flutter_sdk_cache.bzl).
package(default_visibility = ["//visibility:public"])
filegroup(
    name = "wrapper",
    srcs = glob(["**"], exclude = ["BUILD.bazel", "REPO.bazel"]),
)
""")

gradle_wrapper = repository_rule(
    implementation = _gradle_wrapper_impl,
    doc = "The Gradle wrapper archive the flutter tool caches as bin/cache/artifacts/gradle_wrapper.",
)

def _flutter_sdk_cache_impl(mctx):
    material_fonts(name = "material_fonts")
    gradle_wrapper(name = "gradle_wrapper")
    root = mctx.modules[0] if mctx.modules else None
    if root != None and root.is_root:
        return mctx.extension_metadata(
            root_module_direct_deps = [
                "gradle_wrapper",
                "material_fonts",
            ],
            root_module_direct_dev_deps = [],
            reproducible = True,
        )
    return mctx.extension_metadata(reproducible = True)

flutter_sdk_cache = module_extension(
    implementation = _flutter_sdk_cache_impl,
    doc = "The Flutter SDK's cache artifacts the framework's and the tool's tests read (@material_fonts, @gradle_wrapper).",
)
