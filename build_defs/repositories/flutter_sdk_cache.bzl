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
fetch until the pin follows. The Gradle wrapper and, for a Mac host, the
six iOS USB dependencies follow the same pattern.
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

# As the tool lays it: the archive's own gradle-wrapper.properties (a
# distribution of 2016) and NOTICE deleted after unpacking (flutter_cache.dart's
# GradleWrapper.updateInner), so that `flutter create` writes the properties
# for the Gradle its templates want rather than keeping these.
filegroup(
    name = "wrapper",
    srcs = glob(
        ["**"],
        exclude = [
            "BUILD.bazel",
            "REPO.bazel",
            "NOTICE",
            "gradle/wrapper/gradle-wrapper.properties",
        ],
    ),
)
""")

gradle_wrapper = repository_rule(
    implementation = _gradle_wrapper_impl,
    doc = "The Gradle wrapper archive the flutter tool caches as bin/cache/artifacts/gradle_wrapper.",
)

# The iOS USB dependencies (flutter_cache.dart's IosUsbArtifacts), universal
# artifacts the tool checks on every host and downloads on a Mac: each
# bin/cache/artifacts/<name> is the archive flutter_infra_release/
# ios-usb-dependencies/arm64_x86_64/<name>/<version>/<name>.zip, the version
# from bin/internal/<name>.version. The tests' SDK facsimile on a Mac host
# lays them (packages/flutter_tools/BUILD.bazel) so that the tool run from it
# downloads nothing -- its "[1/6] iOS USB Artifact" progress lines reach
# stdout ahead of a debug adapter's Content-Length headers. Pinned as the
# fonts are: the version each file named when this was written, and the
# archive's sha256; a roll changes the version file and fails the fetch until
# the pin follows.
_IOS_USB_ARTIFACTS = {
    "libimobiledevice": (
        "0bf0f9e941c85d06ce4b5909d7a61b3a4f2a6a05",
        "366410275af4d7f68defcb98a3997c83863f3e31c0345490ce62159f92260b47",
    ),
    "libusbmuxd": (
        "19d6bec393c9f9b31ccb090059f59268da32e281",
        "0a1d11f950f8b140cbbd365768039028648018dcbe095f4eb6ba0366f3f0d605",
    ),
    "libplist": (
        "cf5897a71ea412ea2aeb1e2f6b5ea74d4fabfd8c",
        "fd4909cfa7ea4367732fe745ff9c794ed42c9f1bd4042a1e6ec4c9bcf08e2861",
    ),
    "openssl": (
        "22dbb176deef7d9a80f5c94f57a4b518ea935f50",
        "f760b25a2c72b4244bd3c1ea90e866239fa3376eff3c23fe1e70504bd4615719",
    ),
    "libimobiledeviceglue": (
        "050ff3bf8fdab6ce53a2ddc6ae49b11b1c02a168",
        "04d4fdea8ca09135ab27cc638adff0ee2693e61d72901a92ef71023f2f55dba6",
    ),
    "ios-deploy": (
        "7a29ab0b6d611f2bf5de4b6f929a82a091866307",
        "bdf617ac854a8db4902ef44d780688e98ef18ffc4d06db41af02f085c328c089",
    ),
}

# The artifacts' names, in the tool's order (IosUsbArtifacts.artifactNames).
IOS_USB_ARTIFACTS = _IOS_USB_ARTIFACTS.keys()

def ios_usb_repository(artifact):
    """The repository this extension declares for an iOS USB artifact (ios-deploy's is @ios_usb_ios_deploy)."""
    return "ios_usb_" + artifact.replace("-", "_")

def _ios_usb_artifact_impl(rctx):
    artifact = rctx.attr.artifact
    version_file = rctx.path(Label("//bin/internal:" + artifact + ".version"))
    rctx.watch(version_file)
    named = rctx.read(version_file).strip()
    if named != rctx.attr.version:
        fail(("bin/internal/%s.version names %s, but %s pins %s: update _IOS_USB_ARTIFACTS " +
              "(sha256sum of %s%s).") % (
            artifact,
            named,
            "build_defs/repositories/flutter_sdk_cache.bzl",
            rctx.attr.version,
            _STORAGE,
            _ios_usb_archive(artifact, named),
        ))
    rctx.download_and_extract(
        url = _STORAGE + _ios_usb_archive(artifact, named),
        sha256 = rctx.attr.sha256,
        type = "zip",
    )
    rctx.file("BUILD.bazel", """# The iOS USB dependency %s of bin/internal/%s.version (flutter_sdk_cache.bzl).

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "files",
    srcs = glob(["**"], exclude = ["BUILD.bazel", "REPO.bazel"]),
)
""" % (artifact, artifact))

def _ios_usb_archive(artifact, version):
    return "flutter_infra_release/ios-usb-dependencies/arm64_x86_64/%s/%s/%s.zip" % (artifact, version, artifact)

ios_usb_artifact = repository_rule(
    implementation = _ios_usb_artifact_impl,
    attrs = {
        "artifact": attr.string(
            mandatory = True,
            doc = "The artifact's name (one of IosUsbArtifacts.artifactNames), which names its version file and its archive.",
        ),
        "version": attr.string(
            mandatory = True,
            doc = "The version bin/internal/<artifact>.version is expected to name.",
        ),
        "sha256": attr.string(
            mandatory = True,
            doc = "The archive's sha256.",
        ),
    },
    doc = "An iOS USB dependency the flutter tool caches as bin/cache/artifacts/<artifact> on a Mac.",
)

def _flutter_sdk_cache_impl(mctx):
    material_fonts(name = "material_fonts")
    gradle_wrapper(name = "gradle_wrapper")
    for artifact in IOS_USB_ARTIFACTS:
        version, sha256 = _IOS_USB_ARTIFACTS[artifact]
        ios_usb_artifact(
            name = ios_usb_repository(artifact),
            artifact = artifact,
            version = version,
            sha256 = sha256,
        )
    root = mctx.modules[0] if mctx.modules else None
    if root != None and root.is_root:
        return mctx.extension_metadata(
            root_module_direct_deps = [
                "gradle_wrapper",
                "material_fonts",
            ] + [ios_usb_repository(artifact) for artifact in IOS_USB_ARTIFACTS],
            root_module_direct_dev_deps = [],
            reproducible = True,
        )
    return mctx.extension_metadata(reproducible = True)

flutter_sdk_cache = module_extension(
    implementation = _flutter_sdk_cache_impl,
    doc = "The Flutter SDK's cache artifacts the framework's and the tool's tests read (@material_fonts, @gradle_wrapper, @ios_usb_<name>).",
)
