# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The programs `flutter build linux` runs, from the build: a bin/ directory for a test's PATH.

flutter_tools builds a Linux desktop app by running `cmake -G Ninja` and
`ninja install` over the project's CMake files (lib/src/linux/build_linux.dart),
with CC=clang and CXX=clang++ and `pkg-config` for GTK, and native assets
(package:native_toolchain_c) compile with the `clang`, `ar` and `ld` they
find on PATH. The tool's integration tests of that path want all of those
wherever they run; `linux_build_tools` writes one directory of scripts in
their names that run the build's own:

- `cmake`: Kitware's binary release, @cmake_linux_x64 (build_defs/repositories/cmake.bzl).
- `ninja`, `pkg-config`: Debian's, from the runtime sysroot (@sysroot_linux_x64_runtime),
  on the sysroot's libraries; `pkg-config` answers for the build sysroot's
  packages (PKG_CONFIG_LIBDIR under it, PKG_CONFIG_SYSROOT_DIR), so that
  `gtk+-3.0`'s flags name the build sysroot's headers and libraries.
- `clang`, `clang++`: the engine's own (@clang_linux_x64), with `--sysroot`
  at the engine's build sysroot (@sysroot_linux_x64: bullseye's headers and
  link-time libraries, the ones the GTK embedder itself is built against).
- `ld`, `ar`, `ranlib`, `strip`, `objcopy`, `nm`, `objdump`, `readelf`: lld
  and the llvm tools of that clang (clang finds `ld` on PATH when its own
  directory has none).

The built app loads GTK and the rest at run time, so the target also
carries the test's environment for running it (ToolEnvironmentInfo:
LD_LIBRARY_PATH at the runtime sysroot's libraries, Mesa's and GLVND's
variables, GIO_MODULE_DIR at the sysroot's modules rather than the host's),
and a display comes from dart_test's `display` (a display_launcher's Xvfb,
build_defs/web/browser_launcher.bzl). Under
`--//build_defs/web:browser_libraries=//build_defs/web:host_libraries` the
scripts run the same programs on the host's libraries and the environment
is empty.

    linux_build_tools(name = "linux_build_tools")
    dart_package_tests(..., tools = [":linux_build_tools"], display = ":Xvfb")

The target's files are the scripts, at `<name>/bin/<program>`; its runfiles
carry what they run.
"""

load("//build_defs/dart:dart_test.bzl", "ToolEnvironmentInfo")
load("//build_defs/web:browser_launcher.bzl", "BrowserLibrariesInfo")

# The llvm tools the scripts stand for, by the name a build expects.
_LLVM_TOOLS = {
    "ar": "llvm-ar",
    "nm": "llvm-nm",
    "objcopy": "llvm-objcopy",
    "objdump": "llvm-objdump",
    "ranlib": "llvm-ranlib",
    "readelf": "llvm-readelf",
    "strip": "llvm-strip",
}

def _repository_root(file):
    """The runfiles path of the repository a file of another repository lies in (../<repository>)."""
    path = file.short_path
    if not path.startswith("../"):
        fail("%s is this repository's; a repository root was wanted" % path)
    return "/".join(path.split("/", 2)[:2])

def _linux_build_tools_impl(ctx):
    libraries = ctx.attr.libraries[BrowserLibrariesInfo]
    package_path = "%s/%s/bin" % (ctx.label.package, ctx.label.name) if ctx.label.package else ctx.label.name + "/bin"
    sysroot = _repository_root(ctx.files.sysroot[0])
    clang = _repository_root(ctx.files.clang[0])
    library_exports = ""
    if libraries.directories:
        library_exports = "export LD_LIBRARY_PATH=\"%s${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}\"\n" % ":".join([
            "$root/" + f.short_path
            for f in libraries.directories
        ])

    def script(name, body, what):
        file = ctx.actions.declare_file("%s/bin/%s" % (ctx.label.name, name))

        # The runfiles root, from this directory's entry on PATH (dart_test
        # puts it there), else from the script's own place: a hook of
        # package:hooks_runner runs with an environment of PATH, HOME and
        # little else, and package:native_toolchain_c runs a compiler by its
        # resolved path, which for a runfiles symlink is the output tree's,
        # where nothing else of the tree lies.
        ctx.actions.write(file, """#!/bin/bash
# {label}: {what}.
root=""
IFS=: read -ra directories <<< "${{PATH:-}}"
for directory in "${{directories[@]}}"; do
  case "$directory" in */{package_path}) root="${{directory%/{package_path}}}"; break;; esac
done
if [ -z "$root" ]; then
  here="$(cd "$(dirname "$0")" && pwd)"
  root="${{here%/{package_path}}}"
fi
{body}""".format(label = ctx.label, what = what, package_path = package_path, body = body), is_executable = True)
        return file

    scripts = [
        script("cmake", "exec \"$root/%s\" \"$@\"\n" % ctx.file.cmake.short_path, "CMake, Kitware's release"),
        script(
            "ninja",
            library_exports + "exec \"$root/%s\" \"$@\"\n" % ctx.file.ninja.short_path,
            "ninja, Debian's from the runtime sysroot",
        ),
        script(
            "pkg-config",
            library_exports +
            "export PKG_CONFIG_LIBDIR=\"$root/{s}/usr/lib/pkgconfig:$root/{s}/usr/lib/x86_64-linux-gnu/pkgconfig:$root/{s}/usr/share/pkgconfig\"\n".format(s = sysroot) +
            "export PKG_CONFIG_SYSROOT_DIR=\"$root/%s\"\n" % sysroot +
            "exec \"$root/%s\" \"$@\"\n" % ctx.file.pkg_config.short_path,
            "pkg-config, Debian's, answering for the build sysroot's packages",
        ),
        script("ld", "exec \"$root/%s/bin/ld.lld\" \"$@\"\n" % clang, "lld, the engine's clang's"),
    ]
    for compiler in ["clang", "clang++"]:
        scripts.append(script(
            compiler,
            "exec \"$root/{c}/bin/{compiler}\" --sysroot=\"$root/{s}\" \"$@\"\n".format(c = clang, compiler = compiler, s = sysroot),
            "%s, the engine's, over its build sysroot" % compiler,
        ))
    for name, llvm_tool in _LLVM_TOOLS.items():
        scripts.append(script(name, "exec \"$root/%s/bin/%s\" \"$@\"\n" % (clang, llvm_tool), "%s, the engine's clang's" % llvm_tool))

    directories = {}
    if libraries.directories:
        directories["LD_LIBRARY_PATH"] = libraries.directories
        for variable in sorted(libraries.environment.keys()):
            directories[variable] = [libraries.environment[variable]]
    return [
        DefaultInfo(
            files = depset(scripts),
            runfiles = ctx.runfiles(
                files = scripts + [ctx.file.cmake, ctx.file.ninja, ctx.file.pkg_config] + ctx.files.cmake_files +
                        ctx.files.clang + ctx.files.sysroot + libraries.directories + libraries.environment.values(),
            ),
        ),
        ToolEnvironmentInfo(directories = directories),
    ]

linux_build_tools = rule(
    implementation = _linux_build_tools_impl,
    doc = "A bin/ directory of cmake, ninja, pkg-config, clang, clang++, ld and the binutils names, each running the build's own, for a test's PATH.",
    attrs = {
        "cmake": attr.label(default = "@cmake_linux_x64//:bin/cmake", allow_single_file = True, doc = "The CMake executable."),
        "cmake_files": attr.label_list(default = ["@cmake_linux_x64//:all_files"], allow_files = True, doc = "CMake's executable and modules."),
        "ninja": attr.label(default = "@sysroot_linux_x64_runtime//:ninja", allow_single_file = True, doc = "The ninja executable."),
        "pkg_config": attr.label(default = "@sysroot_linux_x64_runtime//:pkg_config", allow_single_file = True, doc = "The pkg-config executable."),
        "clang": attr.label_list(default = ["@clang_linux_x64//:all_files"], allow_files = True, doc = "The engine's clang: its executables, resource directory and runtime libraries."),
        "sysroot": attr.label_list(default = ["@sysroot_linux_x64//:build_tree"], allow_files = True, doc = "The build sysroot: headers, link-time libraries, pkg-config files."),
        "libraries": attr.label(
            default = "//build_defs/web:browser_libraries",
            providers = [BrowserLibrariesInfo],
            doc = "The runtime libraries ninja, pkg-config and the built app load (a browser_libraries, through the label flag: " +
                  "the runtime sysroot's by default, or the host's, nothing).",
        ),
    },
)
