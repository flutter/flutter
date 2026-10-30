# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""What `flutter build apk` needs of the build and the machine, for the tests that run it.

flutter_tools' Android integration tests (test/integration.shard's
android_*, gradle_*, flutter_build_apk_* and deferred_components_* files)
run `flutter create` and `flutter build apk|appbundle|aar` through the tool
from the tests' SDK facsimile. The tool then wants:

- The Android SDK (`ANDROID_HOME`): the checkout's own,
  third_party/android_tools/sdk (@android_tools), with the platforms,
  build-tools and NDK the templates name -- as a writable view under the
  test's home (the SDK's entries symlinked; build-tools, cmake, ndk and
  platforms as directories of their versions' symlinks), since a build
  installs into the SDK what a project asks for and it lacks: the Flutter
  Gradle plugin runs sdkmanager for a project's NDK version
  (FlutterPluginUtils.kt's tool NDK provisioning), the Android Gradle
  plugin downloads a missing platform (android_plugin_*_mismatch_test ask
  for NDK 21 and platform 30). The runfiles' SDK is read-only in the
  sandbox; each test's installs land in its own view, from the network.
- A JDK (`JAVA_HOME`): the engine's own, @openjdk, which Gradle 9 runs on.
- The engine's Android artifacts in the facsimile's cache: gen_snapshot for
  each target CPU and AOT mode (`bin/cache/artifacts/engine/android-<cpu>-<mode>/linux-x64`,
  what `flutter precache --android` downloads) and the embedding as the
  Maven artifacts the Gradle plugin resolves --
  `io.flutter:flutter_embedding_<mode>` and `io.flutter:<abi>_<mode>` at
  version `1.0.0-<engine.stamp>`, from `$FLUTTER_STORAGE_BASE_URL/download.flutter.io`.
  The facsimile's engine.stamp is the engine's revision (bin/internal's
  versioned set, @engine_version: the facsimile that carries the engine's
  directories), which is what the build names its jars and poms by, so
  `engine_maven_repository` lays them under `1.0.0-<revision>` (or under
  another version a facsimile with another stamp asks for: `version`), and
  `android_build_tools` exports `FLUTTER_STORAGE_BASE_URL` as a `file:` URL
  to that directory: Gradle reads Maven repositories from `file:` URLs as
  from https ones.
  `android_engine_artifacts` declares the builds of all of it -- the
  engine for three CPUs in three modes, through in_configuration -- the
  first time, hours; cached afterwards.
- The network. The Android Gradle plugin, Kotlin and the libraries an app
  depends on come from Google's and Maven Central's repositories at build
  time, and the Gradle wrapper fetches its distribution; nothing of that is
  in the checkout, and a pinned mirror of it would be a gigabyte the Java
  tests' Maven lock (build_defs/java) is not. So these tests keep network
  access (`network = True`, no `block-network`), by decision (10-26): they
  are the one part of the test suite that reaches the network for its
  build inputs, and their timing and reliability depend on it.

    android_engine_artifacts(name = "android_engine")   # in //engine/src/flutter/build/archives
    android_build_tools(name = "android_build_tools", maven = "//engine/src/flutter/build/archives:android_engine_maven")
    dart_package_tests(..., tools = [":android_build_tools"], network = True)
"""

load("@engine_version//:version.bzl", "ENGINE_VERSION")
load("//build_defs/config:configuration.bzl", "in_configuration")
load("//build_defs/dart:dart_test.bzl", "ToolEnvironmentInfo")
load("//build_defs/dist:local_engine.bzl", "bundle_directory")

_ANDROID = "//engine/src/flutter/shell/platform/android"
_PLATFORMS = "//engine/src/flutter/build/bazel/toolchains"

# The target CPUs `flutter build apk` builds for by default (android-arm,
# android-arm64, android-x64), their platforms and their ABIs' Maven names.
CPUS = {
    "arm": struct(platform = _PLATFORMS + ":android_arm", abi = "armeabi_v7a"),
    "arm64": struct(platform = _PLATFORMS + ":android_arm64", abi = "arm64_v8a"),
    "x64": struct(platform = _PLATFORMS + ":android_x64", abi = "x86_64"),
}

MODES = ["debug", "profile", "release"]

def _repository_root(file):
    """The runfiles path of the repository a file of another repository lies in (../<repository>)."""
    path = file.short_path
    if not path.startswith("../"):
        fail("%s is this repository's; a repository root was wanted" % path)
    return "/".join(path.split("/", 2)[:2])

def _engine_maven_repository_impl(ctx):
    out = ctx.actions.declare_directory(ctx.label.name)
    args = ctx.actions.args()
    args.add(ctx.file._script)
    args.add("--output", out.path)
    args.add("--engine-version", ENGINE_VERSION)
    args.add("--version", ctx.attr.version)
    args.add_all(ctx.files.srcs)
    ctx.actions.run(
        executable = ctx.executable._python,
        arguments = [args],
        inputs = depset([ctx.file._script] + ctx.files.srcs, transitive = [ctx.attr._python_runtime[DefaultInfo].files]),
        outputs = [out],
        env = {"PYTHONDONTWRITEBYTECODE": "1"},
        mnemonic = "EngineMavenRepository",
        progress_message = "Laying the engine's Maven repository %s" % ctx.label,
    )
    return [DefaultInfo(files = depset([out]))]

engine_maven_repository = rule(
    implementation = _engine_maven_repository_impl,
    doc = "The Android embedding's Maven artifacts (jars and poms of the build) as a Maven repository under " +
          "download.flutter.io/, at the version the facsimile's engine.stamp asks for: the engine's revision, " +
          "which the build names them by, unless `version` says otherwise.",
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".jar", ".pom"],
            doc = "The build's embedding and ABI jars (shell/platform/android's embedding_jars, abi_jars) and " +
                  "poms (pom_embedding, pom_libflutter), each mode's and CPU's through in_configuration.",
        ),
        "version": attr.string(
            default = ENGINE_VERSION,
            doc = "What follows `1.0.0-` in the artifacts' version: the facsimile's engine.stamp -- the engine's " +
                  "revision (bin/internal's versioned stamps, the default) or a facsimile's fixed word.",
        ),
        "_script": attr.label(default = "//build_defs/android:engine_maven.py", allow_single_file = True),
        "_python": attr.label(
            default = "@cpython3//:bin/python3",
            executable = True,
            cfg = "exec",
            allow_single_file = True,
        ),
        "_python_runtime": attr.label(default = "@cpython3//:runtime"),
    },
)

def android_engine_artifacts(name, cpus = CPUS, modes = MODES, target_compatible_with = None):
    """The engine's Android artifacts for the tests' SDK facsimile: gen_snapshot per CPU and AOT mode, the embedding as a Maven repository.

    Declares, for each CPU and mode, the embedding's and the ABI's jars and
    poms built under that configuration (in_configuration with the CPU's
    platform, the mode, `-c opt`, LTO in profile and release, and
    --no-stripped: the Android builders' configurations,
    android_<mode>_<cpu>), gathered as `<name>_maven`; and for each CPU and
    AOT mode (profile, release) gen_snapshot's archive laid as a directory,
    `<name>_<cpu>_<mode>_gen_snapshot`, for the cache's
    `artifacts/engine/android-<cpu>-<mode>/linux-x64`.

    Args:
      name: the prefix of every target.
      cpus: the CPUs (CPUS).
      modes: the runtime modes (MODES).
      target_compatible_with: the constraints every target is compatible with,
        if any (the Linux host's: the JDK overlay knows no macOS bundle layout yet).
    """
    maven = []
    compatibility = {"target_compatible_with": target_compatible_with} if target_compatible_with else {}
    for cpu, spec in cpus.items():
        for mode in modes:
            prefix = "%s_%s_%s" % (name, cpu, mode)
            targets = {"abi_jars": "abi_jars", "pom_libflutter": "pom_libflutter"}
            if cpu == "arm64":
                # The embedding (one jar and pom per mode, the same for every
                # CPU) from one CPU's build.
                targets |= {"embedding_jars": "embedding_jars", "pom_embedding": "pom_embedding"}

            # The Android builders' configuration of the mode
            # (ci/builders/configs.bazelrc's android_<mode>_<cpu>): -c opt
            # in debug too, LTO in profile and release, and --no-stripped
            # throughout -- the jar carries the unstripped libflutter.so,
            # whose symbols an app's build extracts into its bundle and
            # strips itself (the tool checks a release bundle for them).
            configuration = dict(
                compilation_mode = "opt",
                lto = "false" if mode == "debug" else "true",
                platform = spec.platform,
                runtime_mode = mode,
                stripped = "false",
                **compatibility
            )
            for suffix, target in targets.items():
                in_configuration(
                    name = prefix + "_" + suffix,
                    target = _ANDROID + ":" + target,
                    **configuration
                )
                maven.append(":%s_%s" % (prefix, suffix))
            if mode != "debug":
                in_configuration(
                    name = prefix + "_gen_snapshot_zip",
                    target = _ANDROID + ":gen_snapshot",
                    **configuration
                )
                bundle_directory(
                    name = prefix + "_gen_snapshot",
                    bundles = [":" + prefix + "_gen_snapshot_zip"],
                    **compatibility
                )
    engine_maven_repository(
        name = name + "_maven",
        srcs = maven,
        **compatibility
    )

def _android_build_tools_impl(ctx):
    java_home = _repository_root(ctx.files.java_home[0])
    maven = ctx.file.maven
    return [
        DefaultInfo(
            runfiles = ctx.runfiles(files = [ctx.file.sdk, maven] + ctx.files.java_home),
        ),
        ToolEnvironmentInfo(
            directories = {},
            values = {
                "JAVA_HOME": "$root/" + java_home,
                # The SDK's writable view, laid by the setup lines below.
                "ANDROID_HOME": "$HOME/android-sdk",
                # The Gradle plugin's Maven repository for the embedding:
                # `$FLUTTER_STORAGE_BASE_URL/download.flutter.io` (FlutterPlugin.kt),
                # the directory engine_maven_repository lays.
                "FLUTTER_STORAGE_BASE_URL": "file://$root/" + maven.short_path,
                # A JVM takes `user.home` from the password database, not
                # from $HOME, and the Gradle wrapper (its distributions, the
                # dependency cache, the daemon) and the Android tools (the
                # debug keystore, analytics settings) default to directories
                # under it: the invoking user's real home, read-only in the
                # sandbox -- the wrapper dies at once on its lock file --
                # and shared between tests outside it. Both read these
                # variables first; under the test's own home, as the rest.
                "GRADLE_USER_HOME": "$HOME/.gradle",
                "ANDROID_USER_HOME": "$HOME/.android",
            },
            setup = [
                # ... and what reads `user.home` itself inside the Gradle
                # daemon -- the Kotlin daemon's run files
                # (~/.local/share/kotlin/daemon), the Android tools' analytics
                # on some paths -- gets the test's home too, through a
                # property of the Gradle home that every build of the test
                # applies to the daemon's JVM (gradle.properties'
                # `systemProp.` entries).
                "mkdir -p \"$GRADLE_USER_HOME\" && printf 'systemProp.user.home=%s\\n' \"$HOME\" > \"$GRADLE_USER_HOME/gradle.properties\"",
                # The SDK's writable view (see the file's docstring): what a
                # build installs lands beside the symlinks.
                "android_sdk_source=\"$root/" + ctx.file.sdk.short_path + "\"",
                "mkdir -p \"$ANDROID_HOME\"",
                "for android_sdk_entry in \"$android_sdk_source\"/*; do",
                "  android_sdk_name=\"$(basename \"$android_sdk_entry\")\"",
                "  case \"$android_sdk_name\" in",
                "    build-tools|cmake|ndk|platforms)",
                "      mkdir -p \"$ANDROID_HOME/$android_sdk_name\"",
                "      for android_sdk_version in \"$android_sdk_entry\"/*; do ln -s \"$android_sdk_version\" \"$ANDROID_HOME/$android_sdk_name/$(basename \"$android_sdk_version\")\"; done;;",
                "    *) ln -s \"$android_sdk_entry\" \"$ANDROID_HOME/$android_sdk_name\";;",
                "  esac",
                "done",
            ],
        ),
    ]

android_build_tools = rule(
    implementation = _android_build_tools_impl,
    doc = "The environment of a test that runs `flutter build apk`: ANDROID_HOME at a writable view of the checkout's " +
          "SDK, JAVA_HOME at the engine's JDK, FLUTTER_STORAGE_BASE_URL at the build's embedding (a file: URL), " +
          "GRADLE_USER_HOME and ANDROID_USER_HOME under the test's home; for dart_test's `tools`.",
    attrs = {
        "sdk": attr.label(
            default = "@android_tools//:android_sdk",
            allow_single_file = True,
            doc = "The Android SDK, one directory.",
        ),
        "java_home": attr.label_list(
            default = ["@openjdk//:home"],
            allow_files = True,
            doc = "The JDK's files; JAVA_HOME is their repository's root.",
        ),
        "maven": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The engine's Maven repository (engine_maven_repository), one directory holding download.flutter.io/.",
        ),
    },
)
