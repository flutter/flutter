# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The SDKs of the host's Xcode as a repository (`@macos_sdk`): macOS, and iOS's device and simulator ones.

GN finds the SDK through `xcrun` (build/config/darwin/darwin_sdk.gni) and,
under tools/gn's --xcode-symlinks, reaches it through a symlink in
engine/src/flutter/prebuilts/SDKs/ so that its command lines do not name
the Xcode installation. This repository is Bazel's counterpart: it lays a
view of the SDK `xcrun --sdk macosx --show-sdk-path` names, `MacOSX.sdk/`,
whose entries are symlinks to the SDK's. The toolchain passes it as
-isysroot, and its headers, libraries and frameworks reach every compile
and link as directory inputs (`:sdk`), tracked by content like the Linux
sysroot's (the root .bazelrc's BAZEL_TRACK_SOURCE_DIRECTORIES) -- an Xcode
update changes the actions' keys, and a remote cache would see the SDK as
an input rather than as an assumption about the executor.

A view rather than one symlink to the SDK's root, because Bazel walks a
directory input and the SDK holds a symlink cycle
(Ruby.framework/.../Headers/ruby/ruby -> .): System/Library/Frameworks is
a directory of the frameworks' symlinks without Ruby's. Everything else is
symlinked whole. `:sdk` is the inputs; `:view` is a marker file at the
view's root, whose directory is the toolchain's sysroot.

The Xcode is `xcrun`'s: DEVELOPER_DIR when set (the repository re-evaluates
when it changes), else `xcode-select`'s, whose link and version file the
repository watches. On a host that is not a Mac the repository is empty
(an `:sdk` of no files): the macOS toolchains are incompatible there, and
nothing else reads it.

`sdk.bzl` records what was found (MACOS_SDK_PATH, MACOS_SDK_VERSION,
MACOS_PLATFORM_PATH, XCODE_DEVELOPER_DIR), for messages and for the link
flags of the rules that need the platform's own frameworks (XCTest, under
the platform path). Their compiles get those through `:macos_developer`
(`:ios_developer`, `:ios_simulator_developer`): a `platform_developer`
rule over views of the platform's `Developer/Library/Frameworks` and
`Developer/usr/lib` -- `<view>.platform/Developer/...`, the frameworks
symlinked one by one, usr/lib whole -- whose CcInfo gives a dependent's
compiles `-F` and `-I` on them as exec-root paths and the directories as
inputs, so that the compile can run on a remote worker (the Apple
toolchains' remote-compile mode); the converter turns darwin/common's
test_config's `-F$platform/Developer/Library/Frameworks` and
`-I$platform/Developer/usr/lib` compile flags into that dependency
(starlark_emitter.dart). Links keep the absolute paths: they run on the Mac.

The iOS toolchains read the same Xcode's iPhoneOS and iPhoneSimulator SDKs
(GN: darwin_sdk.gni's ios_device_sdk_path and ios_simulator_sdk_path, from
build/mac/darwin_sdk.py): laid as views the same way, `iPhoneOS.sdk/` and
`iPhoneSimulator.sdk/`, as `:ios_sdk`/`:ios_view` and
`:ios_simulator_sdk`/`:ios_simulator_view`, with IPHONEOS_SDK_PATH,
IPHONEOS_PLATFORM_PATH, IPHONESIMULATOR_SDK_PATH,
IPHONESIMULATOR_PLATFORM_PATH and IOS_SDK_VERSION in sdk.bzl. A Mac whose
Xcode has no iOS platform (the command-line tools alone) gets empty ones:
the iOS toolchains fail to find their sysroot there, nothing else reads
them. The repository keeps its name from the first SDK it held.
"""

# Frameworks left out of the view, each for a reason.
_EXCLUDED_FRAMEWORKS = {
    # Holds the SDK's one symlink cycle (Headers/ruby/ruby -> .); nothing
    # in the engine includes it.
    "Ruby.framework": "symlink cycle",
}

# The entries of a view that are the toolchain's inputs: what the
# compiler and the linker read of an SDK (under the view's name).
_SDK_INPUTS = [
    "SDKSettings.json",
    "SDKSettings.plist",
    "usr/include",
    "usr/lib",
    "System/Library/Frameworks",
    "System/Library/SubFrameworks",
]

# The SDKs: xcrun's name, the view's directory, the names of the
# filegroups and of the constants.
_SDKS = [
    struct(xcrun = "macosx", view = "MacOSX.sdk", group = "", constant = "MACOS", required = True),
    struct(xcrun = "iphoneos", view = "iPhoneOS.sdk", group = "ios_", constant = "IPHONEOS", required = False),
    struct(xcrun = "iphonesimulator", view = "iPhoneSimulator.sdk", group = "ios_simulator_", constant = "IPHONESIMULATOR", required = False),
]

def _xcrun(rctx, environment, sdk, arguments, required = True):
    result = rctx.execute(["/usr/bin/xcrun", "--sdk", sdk] + arguments, environment = environment)
    if result.return_code != 0:
        if not required:
            return None
        fail("macos_sdk: `xcrun --sdk %s %s` failed (is Xcode installed and selected?):\n%s" % (
            sdk,
            " ".join(arguments),
            result.stderr,
        ))
    return result.stdout.strip()

def _lay_view(rctx, sdk, view):
    """Lays <view>/: the SDK's entries symlinked, the frameworks one by one."""
    rctx.file(view + "/.view", "")
    for entry in sdk.readdir():
        if entry.basename != "System":
            rctx.symlink(entry, view + "/" + entry.basename)
    library = sdk.get_child("System", "Library")
    for entry in library.readdir():
        if entry.basename != "Frameworks":
            rctx.symlink(entry, view + "/System/Library/" + entry.basename)
    rctx.file(view + "/System/Library/Frameworks/.view", "")
    for framework in library.get_child("Frameworks").readdir():
        if framework.basename not in _EXCLUDED_FRAMEWORKS:
            rctx.symlink(framework, view + "/System/Library/Frameworks/" + framework.basename)

# The platform's Developer entries a test compile reads: the frameworks
# directory (XCTest.framework, Testing.framework, ...) and usr/lib (the
# Swift support library and modules), under <view>.platform/Developer/.
_DEVELOPER_FRAMEWORKS = "Developer/Library/Frameworks"
_DEVELOPER_LIB = "Developer/usr/lib"

def _lay_developer(rctx, platform, view):
    """Lays <view>.platform/Developer/{Library/Frameworks,usr/lib}: the frameworks symlinked one by one, usr/lib whole.

    Returns the two directories' paths under the repository, or None where the
    platform has no frameworks directory (an Xcode without the platform's
    test support).
    """
    frameworks = platform.get_child(*_DEVELOPER_FRAMEWORKS.split("/"))
    lib = platform.get_child(*_DEVELOPER_LIB.split("/"))
    if not frameworks.exists or not frameworks.is_dir:
        return None
    frameworks_view = view + ".platform/" + _DEVELOPER_FRAMEWORKS
    rctx.file(frameworks_view + "/.view", "")
    for framework in frameworks.readdir():
        if framework.basename not in _EXCLUDED_FRAMEWORKS:
            rctx.symlink(framework, frameworks_view + "/" + framework.basename)
    lib_view = view + ".platform/" + _DEVELOPER_LIB
    if lib.exists and lib.is_dir:
        rctx.symlink(lib, lib_view)
    else:
        rctx.file(lib_view + "/.view", "")
    return struct(frameworks = frameworks_view, lib = lib_view)

_PLATFORM_DEVELOPER_BZL = '''# Generated by macos_sdk (build_defs/repositories/macos_sdk.bzl); do not edit.

"""A platform's Developer directories as what a test compile reads of them."""

def _platform_developer_impl(ctx):
    frameworks = ctx.file.frameworks
    lib = ctx.file.lib

    # The directories are source directories (tracked: the root .bazelrc's
    # BAZEL_TRACK_SOURCE_DIRECTORIES), inputs whole as the SDK view is.
    compilation_context = cc_common.create_compilation_context(
        headers = depset([frameworks, lib]),
        framework_includes = depset([frameworks.path]),
        includes = depset([lib.path]),
    )
    return [CcInfo(compilation_context = compilation_context)]

platform_developer = rule(
    implementation = _platform_developer_impl,
    doc = "The platform's Developer/Library/Frameworks and Developer/usr/lib for a dependent's compiles: " +
          "`-F` and `-I` on the views (exec-root paths), the directories as inputs.",
    attrs = {
        "frameworks": attr.label(allow_single_file = True, mandatory = True, doc = "The frameworks view directory."),
        "lib": attr.label(allow_single_file = True, mandatory = True, doc = "The usr/lib view directory."),
    },
    provides = [CcInfo],
)
'''

def _macos_sdk_impl(rctx):
    developer_dir = rctx.getenv("DEVELOPER_DIR", "")
    found = {
        "MACOS_SDK_PATH": "",
        "MACOS_SDK_VERSION": "",
        "MACOS_PLATFORM_PATH": "",
        "XCODE_DEVELOPER_DIR": "",
        "IPHONEOS_SDK_PATH": "",
        "IPHONEOS_PLATFORM_PATH": "",
        "IPHONESIMULATOR_SDK_PATH": "",
        "IPHONESIMULATOR_PLATFORM_PATH": "",
        "IOS_SDK_VERSION": "",
    }
    inputs = {sdk.group: [] for sdk in _SDKS}
    developer = {sdk.group: None for sdk in _SDKS}
    if rctx.os.name.lower().startswith("mac"):
        environment = {"DEVELOPER_DIR": developer_dir} if developer_dir else {}
        if not developer_dir:
            # xcode-select's choice: its link, and the chosen Xcode's version
            # file, so that switching or updating Xcode re-evaluates this.
            link = rctx.path("/var/db/xcode_select_link")
            if link.exists:
                rctx.watch(link)
        for spec in _SDKS:
            sdk_path = _xcrun(rctx, environment, spec.xcrun, ["--show-sdk-path"], required = spec.required)
            if sdk_path == None:
                continue
            sdk = rctx.path(sdk_path).realpath
            if not sdk.exists or not sdk.is_dir:
                fail("macos_sdk: %s (from xcrun --sdk %s) is not a directory" % (sdk_path, spec.xcrun))
            found[spec.constant + "_SDK_PATH"] = str(sdk)
            found[spec.constant + "_PLATFORM_PATH"] = _xcrun(rctx, environment, spec.xcrun, ["--show-sdk-platform-path"])
            version = _xcrun(rctx, environment, spec.xcrun, ["--show-sdk-version"])
            if spec.xcrun == "macosx":
                found["MACOS_SDK_VERSION"] = version
                found["XCODE_DEVELOPER_DIR"] = found["MACOS_PLATFORM_PATH"].split("/Platforms/")[0]
                version_plist = rctx.path(found["XCODE_DEVELOPER_DIR"]).get_child("..", "version.plist")
                if version_plist.exists:
                    rctx.watch(version_plist)
            else:
                found["IOS_SDK_VERSION"] = version
            rctx.watch(sdk.get_child("SDKSettings.json"))
            _lay_view(rctx, sdk, spec.view)
            inputs[spec.group] = [spec.view + "/" + path for path in _SDK_INPUTS if rctx.path(spec.view + "/" + path).exists]
            developer[spec.group] = _lay_developer(rctx, rctx.path(found[spec.constant + "_PLATFORM_PATH"]), spec.view)

    groups = []
    for spec in _SDKS:
        groups.append("""
# What a compile or link reads of the %s SDK, as directory inputs: the
# toolchain's -isysroot is their parent, %s.
filegroup(
    name = "%ssdk",
    srcs = %s,
)

# A file at the view's root, whose directory the toolchain takes as the
# sysroot (cc_toolchain_config.bzl's sysroot_marker).
filegroup(
    name = "%sview",
    srcs = %s,
)
""" % (
            spec.xcrun,
            spec.view,
            spec.group,
            repr(inputs[spec.group]),
            spec.group,
            repr([spec.view + "/.view"] if inputs[spec.group] else []),
        ))
        name = (spec.group if spec.group else "macos_") + "developer"
        dev = developer[spec.group]
        if dev != None:
            groups.append("""
# The %s platform's Developer directories for the test targets' compiles
# (platform_developer.bzl; the file's docstring).
platform_developer(
    name = "%s",
    frameworks = %r,
    lib = %r,
)
""" % (spec.xcrun, name, dev.frameworks, dev.lib))
        else:
            # Off a Mac, or an Xcode without the platform: a dependency that
            # compiles nothing in, so that the generated files load the same.
            groups.append("""
cc_library(
    name = "%s",
)
""" % name)
    rctx.file("platform_developer.bzl", _PLATFORM_DEVELOPER_BZL)
    rctx.file("BUILD.bazel", """# The SDKs of the host's Xcode (build_defs/repositories/macos_sdk.bzl).
load("@rules_cc//cc:defs.bzl", "cc_library")
load(":platform_developer.bzl", "platform_developer")

package(default_visibility = ["//visibility:public"])
""" + "".join(groups))
    rctx.file("sdk.bzl", "".join([
        "%s = %r\n" % (name, value)
        for name, value in found.items()
    ]))

macos_sdk = repository_rule(
    implementation = _macos_sdk_impl,
    doc = "Views of the host's Xcode's SDKs -- macOS, and iOS's device and simulator ones when the Xcode has them " +
          "-- from `xcrun --sdk <name>` (empty off macOS); see the file's docstring.",
    local = True,
)
