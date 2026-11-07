# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""GN's native_activity_apk (testing/android/native_activity/native_activity.gni): a gtest suite as an Android APK.

The engine's Android-only suites (impeller/toolkit/android's, the Vulkan
backend's) are built twice under GN: as an executable `run_tests.py --type
android` pushes with adb, and as an APK of android.app.NativeActivity around
the same library, which an emulator or device runs as an app. The template
is three targets: the manifest from a template (`templater`, which writes
`{{apk-library-name}}` as the library's name), the shared library of the
suite (`lib<apk_name>.so`, GN's `shared_library` over the invocation's deps)
and an action running native_activity_apk.py -- aapt2 links the manifest
against the platform's android.jar into a skeleton, the library is added
under lib/<abi>/, zipalign aligns and apksigner signs it with the checked-in
debug keystore -- into `$root_build_dir/<apk_name>.apk`; the invocation's
name is a group over the APK.

Here the same three, from the same inputs: `android_manifest_<name>`
(the substitution itself; the templater does nothing more for this
template), `shared_library_<name>` (flutter_shared_library, the converter's
shape for GN's shared_library) and `apk_<name>` (the script, with the SDK's
build tools from @android_tools and java for apksigner from @openjdk on its
PATH -- the script's own JDK path is relative to a layout this checkout
does not have), placed at the build root as GN places it. Running the APK
is the Android test phase's (an emulator); nothing here is a test.
"""

load("//build_defs/cc:shared_library.bzl", "flutter_shared_library")
load("//build_defs/gn:build_directory.bzl", "BuildDirectoryInfo", "build_directory_aspect", "shipped_file")
load("//build_defs/gn:gn_action.bzl", "PYTHON_ATTRS", "run_python")

_NATIVE_ACTIVITY = "//engine/src/flutter/testing/android/native_activity"

# The SDK's build tools the script runs (native_activity.gni's
# android_buildtools: the version the converter's mapping spells out,
# android_sdk_build_tools) and the platform jar (android_sdk_jar).
_BUILD_TOOLS = "@android_tools//:sdk/build-tools/37.0.0/"
_ANDROID_JAR = "@android_tools//:sdk/platforms/android-37.0/android.jar"

# GN's android_app_abi (build/config/android/config.gni) by the target CPU:
# the directory the library goes under in the APK.
_ANDROID_APP_ABI = select({
    "@platforms//cpu:aarch64": "arm64-v8a",
    "@platforms//cpu:armv7": "armeabi-v7a",
    "@platforms//cpu:riscv64": "riscv64",
    "@platforms//cpu:x86_32": "x86",
    "@platforms//cpu:x86_64": "x86_64",
})

def _android_manifest_impl(ctx):
    # tools/templater substitutes `{{key}}` for each `--key=value` given;
    # the manifest template names one key.
    ctx.actions.expand_template(
        template = ctx.file.template,
        output = ctx.outputs.out,
        substitutions = {"{{apk-library-name}}": ctx.attr.apk_name},
    )
    return [DefaultInfo(files = depset([ctx.outputs.out]))]

_android_manifest = rule(
    implementation = _android_manifest_impl,
    doc = "The APK's AndroidManifest.xml: the template with the library's name written in (GN's templater).",
    attrs = {
        "apk_name": attr.string(mandatory = True, doc = "The library's name, `android.app.lib_name`."),
        "template": attr.label(
            default = _NATIVE_ACTIVITY + ":AndroidManifest.xml.template",
            allow_single_file = True,
        ),
        "out": attr.output(mandatory = True, doc = "AndroidManifest.xml under the package."),
    },
)

def _native_activity_apk_impl(ctx):
    apk = ctx.actions.declare_file(ctx.attr.apk_name + ".apk")

    # The script's intermediate APKs (<name>.apk.unaligned, .unsigned) go
    # under GN's target_gen_dir; a directory of this target's here.
    gen_dir = ctx.actions.declare_directory(ctx.label.name + ".gen")

    # The library as GN's build root holds it: stripped under
    # stripped_symbols (the linked one is lib.unstripped/'s), else as linked
    # (build_directory.bzl's aspect strips it; the emulator builder's
    # configuration says --stripped=false).
    library = shipped_file(ctx.attr.library, ctx.file.library)
    args = ctx.actions.args()
    args.add("--aapt2-bin", ctx.executable.aapt2)
    args.add("--zipalign-bin", ctx.executable.zipalign)
    args.add("--apksigner-bin", ctx.executable.apksigner)
    args.add("--android-manifest", ctx.file.manifest)
    args.add("--android-jar", ctx.file.android_jar)
    args.add("--output-path", apk)
    args.add("--library", library)
    args.add("--keystore", ctx.file.keystore)
    args.add("--gen-dir", gen_dir.path)
    args.add("--android-abi", ctx.attr.android_abi)

    # apksigner is a shell script that runs `java` from PATH; the script
    # prepends a JDK path of its own that this checkout's layout does not
    # have, which leaves ours first among what exists.
    java_bin = ctx.executable.java.dirname
    run_python(
        ctx,
        script = ctx.file._script,
        arguments = [args],
        inputs = [library, ctx.file.manifest, ctx.file.android_jar, ctx.file.keystore],
        tools = [ctx.executable.aapt2, ctx.executable.zipalign, ctx.executable.apksigner, ctx.executable.java] +
                ctx.files.build_tools_libraries + ctx.files._jdk,
        outputs = [apk, gen_dir],
        mnemonic = "NativeActivityApk",
        progress_message = "Packaging %s" % apk.short_path,
        env = {"PATH": java_bin + ":/bin:/usr/bin"},
    )
    return [
        DefaultInfo(files = depset([apk])),
        # GN's apk_path: `$root_build_dir/<apk_name>.apk`.
        BuildDirectoryInfo(entries = depset([(apk, apk.basename)])),
    ]

_native_activity_apk = rule(
    implementation = _native_activity_apk_impl,
    doc = "native_activity_apk.py over the suite's library: the signed, aligned APK at the build root.",
    attrs = {
        "apk_name": attr.string(mandatory = True, doc = "GN's apk_name: the APK is <apk_name>.apk, the library lib<apk_name>.so."),
        "library": attr.label(
            mandatory = True,
            allow_single_file = True,
            aspects = [build_directory_aspect],
            doc = "The suite's shared library (shared_library_<name>).",
        ),
        "manifest": attr.label(mandatory = True, allow_single_file = True, doc = "The APK's AndroidManifest.xml."),
        "android_abi": attr.string(mandatory = True, doc = "GN's android_app_abi: the ABI directory of the library in the APK."),
        "android_jar": attr.label(default = _ANDROID_JAR, allow_single_file = True),
        "keystore": attr.label(default = _NATIVE_ACTIVITY + ":debug.keystore", allow_single_file = True),
        "aapt2": attr.label(default = _BUILD_TOOLS + "aapt2", executable = True, cfg = "exec", allow_single_file = True),
        "zipalign": attr.label(default = _BUILD_TOOLS + "zipalign", executable = True, cfg = "exec", allow_single_file = True),
        "apksigner": attr.label(default = _BUILD_TOOLS + "apksigner", executable = True, cfg = "exec", allow_single_file = True),
        # apksigner's jar beside it, and the libc++ zipalign loads from
        # lib64/ next to itself (a Linux package's; a Mac's links the system's).
        "build_tools_libraries": attr.label(default = "@android_tools//:build_tools_libraries", allow_files = True),
        "java": attr.label(default = "@openjdk//:bin/java", executable = True, cfg = "exec", allow_single_file = True),
        "_jdk": attr.label(default = "@openjdk//:runtime"),
        "_script": attr.label(default = _NATIVE_ACTIVITY + ":native_activity_apk.py", allow_single_file = True),
    } | PYTHON_ATTRS,
)

def native_activity_apk(name, apk_name, deps = [], testonly = None, visibility = None, target_compatible_with = None, **kwargs):
    """GN's native_activity_apk(): a gtest suite as an APK around android.app.NativeActivity.

    Args:
      name: GN's target name (the group over the APK; an alias here).
      apk_name: GN's apk_name: the APK is <apk_name>.apk at the build root,
        the library in it lib<apk_name>.so.
      deps: GN's deps, the shared library's (the suite's library and
        testing/android/native_activity's gtest_activity, which supplies
        ANativeActivity_onCreate).
      testonly: whether the targets are testonly (GN's).
      visibility: the targets' visibility.
      target_compatible_with: the targets' constraints (the converted
        file's: Android).
      **kwargs: the shared library's other attributes (GN forwards the
        invocation's variables to it).
    """
    compatibility = {}
    if target_compatible_with != None:
        compatibility["target_compatible_with"] = target_compatible_with
    _android_manifest(
        name = "android_manifest_" + name,
        apk_name = apk_name,
        out = name + "/AndroidManifest.xml",
        testonly = testonly,
        visibility = visibility,
        **compatibility
    )
    flutter_shared_library(
        name = "shared_library_" + name,
        output_name = apk_name,
        # BUILDCONFIG.gn's default deps link the engine's libc++ into every
        # shared library; the converter lists it in a shared_library's deps,
        # and the macro does the same for the one it declares.
        deps = deps + ["//engine/src/flutter/build/bazel/toolchains:cxx_runtime"],
        testonly = testonly,
        visibility = visibility,
        target_compatible_with = target_compatible_with or [],
        **kwargs
    )
    _native_activity_apk(
        name = "apk_" + name,
        apk_name = apk_name,
        android_abi = _ANDROID_APP_ABI,
        library = ":shared_library_" + name,
        manifest = ":android_manifest_" + name,
        testonly = testonly,
        visibility = visibility,
        **compatibility
    )
    native.alias(
        name = name,
        actual = ":apk_" + name,
        testonly = testonly,
        visibility = visibility,
        **compatibility
    )
