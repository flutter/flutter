# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The macOS SDK of the host's Xcode as a repository (`@macos_sdk`), for the macOS toolchains.

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
MACOS_PLATFORM_PATH, XCODE_DEVELOPER_DIR), for messages and for rules that
need the platform's own frameworks (XCTest, under the platform path).
"""

# Frameworks left out of the view, each for a reason.
_EXCLUDED_FRAMEWORKS = {
    # Holds the SDK's one symlink cycle (Headers/ruby/ruby -> .); nothing
    # in the engine includes it.
    "Ruby.framework": "symlink cycle",
}

# The entries of the view that are the toolchain's inputs: what the
# compiler and the linker read of an SDK.
_SDK_INPUTS = [
    "MacOSX.sdk/SDKSettings.json",
    "MacOSX.sdk/SDKSettings.plist",
    "MacOSX.sdk/usr/include",
    "MacOSX.sdk/usr/lib",
    "MacOSX.sdk/System/Library/Frameworks",
    "MacOSX.sdk/System/Library/SubFrameworks",
]

def _xcrun(rctx, environment, arguments):
    result = rctx.execute(["/usr/bin/xcrun", "--sdk", "macosx"] + arguments, environment = environment)
    if result.return_code != 0:
        fail("macos_sdk: `xcrun --sdk macosx %s` failed (is Xcode installed and selected?):\n%s" % (
            " ".join(arguments),
            result.stderr,
        ))
    return result.stdout.strip()

def _lay_view(rctx, sdk):
    """Lays MacOSX.sdk/: the SDK's entries symlinked, the frameworks one by one."""
    rctx.file("MacOSX.sdk/.view", "")
    for entry in sdk.readdir():
        if entry.basename != "System":
            rctx.symlink(entry, "MacOSX.sdk/" + entry.basename)
    library = sdk.get_child("System", "Library")
    for entry in library.readdir():
        if entry.basename != "Frameworks":
            rctx.symlink(entry, "MacOSX.sdk/System/Library/" + entry.basename)
    rctx.file("MacOSX.sdk/System/Library/Frameworks/.view", "")
    for framework in library.get_child("Frameworks").readdir():
        if framework.basename not in _EXCLUDED_FRAMEWORKS:
            rctx.symlink(framework, "MacOSX.sdk/System/Library/Frameworks/" + framework.basename)

def _macos_sdk_impl(rctx):
    developer_dir = rctx.getenv("DEVELOPER_DIR", "")
    found = {
        "MACOS_SDK_PATH": "",
        "MACOS_SDK_VERSION": "",
        "MACOS_PLATFORM_PATH": "",
        "XCODE_DEVELOPER_DIR": "",
    }
    inputs = []
    if rctx.os.name.lower().startswith("mac"):
        environment = {"DEVELOPER_DIR": developer_dir} if developer_dir else {}
        if not developer_dir:
            # xcode-select's choice: its link, and the chosen Xcode's version
            # file, so that switching or updating Xcode re-evaluates this.
            link = rctx.path("/var/db/xcode_select_link")
            if link.exists:
                rctx.watch(link)
        sdk_path = _xcrun(rctx, environment, ["--show-sdk-path"])
        sdk = rctx.path(sdk_path).realpath
        if not sdk.exists or not sdk.is_dir:
            fail("macos_sdk: %s (from xcrun) is not a directory" % sdk_path)
        found["MACOS_SDK_PATH"] = str(sdk)
        found["MACOS_SDK_VERSION"] = _xcrun(rctx, environment, ["--show-sdk-version"])
        found["MACOS_PLATFORM_PATH"] = _xcrun(rctx, environment, ["--show-sdk-platform-path"])
        found["XCODE_DEVELOPER_DIR"] = found["MACOS_PLATFORM_PATH"].split("/Platforms/")[0]
        version_plist = rctx.path(found["XCODE_DEVELOPER_DIR"]).get_child("..", "version.plist")
        if version_plist.exists:
            rctx.watch(version_plist)
        rctx.watch(sdk.get_child("SDKSettings.json"))
        _lay_view(rctx, sdk)
        inputs = [path for path in _SDK_INPUTS if rctx.path(path).exists]

    rctx.file("BUILD.bazel", """# The macOS SDK of the host's Xcode (build_defs/repositories/macos_sdk.bzl).
package(default_visibility = ["//visibility:public"])

# What a compile or link reads of the SDK, as directory inputs: the
# toolchain's -isysroot is their parent, MacOSX.sdk.
filegroup(
    name = "sdk",
    srcs = %s,
)

# A file at the view's root, whose directory the toolchain takes as the
# sysroot (cc_toolchain_config.bzl's sysroot_marker).
filegroup(
    name = "view",
    srcs = %s,
)
""" % (repr(inputs), repr(["MacOSX.sdk/.view"] if inputs else [])))
    rctx.file("sdk.bzl", "".join([
        "%s = %r\n" % (name, value)
        for name, value in found.items()
    ]))

macos_sdk = repository_rule(
    implementation = _macos_sdk_impl,
    doc = "A view of the macOS SDK of the host's Xcode, from `xcrun --sdk macosx` (empty off macOS); see the file's docstring.",
    local = True,
)
