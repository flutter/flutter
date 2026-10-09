# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Module extension that exposes the engine's dependencies as repositories.

The pins come from `deps.lock.bzl` (generated from `DEPS`) and, for the Debian
sysroots, from `build/linux/sysroot_scripts/sysroots.json`. During the
GN/Bazel transition every dependency is consumed from the directory
`gclient sync` populated (`synced_repository`), so both build systems see
identical trees and nothing is fetched twice.

Toolchains (clang, sysroots, gn, ...) can instead be downloaded by Bazel
itself by setting `FLUTTER_BAZEL_FETCH_TOOLCHAINS=1` (for example through
`--repo_env`). The repositories have the same layout either way.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load(":deps.lock.bzl", "CIPD_DEPS", "GIT_DEPS")
load(":repositories.bzl", "cipd_package", "synced_repository")

_OVERLAYS = "//engine/src/flutter/build/bazel/third_party"

# Source trees from DEPS, keyed by repository name.
#   path:       directory relative to the repository root, as listed in DEPS.
#   build_file: overlay BUILD file, or None to use the upstream Bazel files.
_SOURCE_REPOSITORIES = {
    "abseil-cpp": struct(
        path = "engine/src/third_party/abseil-cpp",
        build_file = None,
    ),
    # Embedding API headers only, for now (see the overlay).
    "dart": struct(
        path = "engine/src/flutter/third_party/dart",
        build_file = _OVERLAYS + ":dart/BUILD.dart.bazel",
    ),
    "googletest": struct(
        path = "engine/src/flutter/third_party/googletest",
        build_file = None,
    ),
    "icu": struct(
        path = "engine/src/flutter/third_party/icu",
        build_file = _OVERLAYS + ":icu/BUILD.icu.bazel",
    ),
    # The engine's own C++ runtime, built from source by the toolchain's
    # `cxx_runtime` library (see toolchains/BUILD.bazel).
    "libcxx": struct(
        path = "engine/src/flutter/third_party/libcxx",
        build_file = _OVERLAYS + ":libcxx/BUILD.libcxx.bazel",
    ),
    "libcxxabi": struct(
        path = "engine/src/flutter/third_party/libcxxabi",
        build_file = _OVERLAYS + ":libcxxabi/BUILD.libcxxabi.bazel",
    ),
    "llvm_libc": struct(
        path = "engine/src/flutter/third_party/llvm_libc",
        build_file = _OVERLAYS + ":llvm_libc/BUILD.llvm_libc.bazel",
    ),
}

# Prebuilt tools from DEPS (CIPD packages), keyed by repository name. These
# are symlinked from the checkout by default and downloaded from CIPD when
# FLUTTER_BAZEL_FETCH_TOOLCHAINS is set.
_TOOL_REPOSITORIES = {
    "clang_linux_x64": struct(
        path = "engine/src/flutter/buildtools/linux-x64/clang",
        build_file = _OVERLAYS + ":clang/BUILD.clang.bazel",
    ),
    "gn": struct(
        path = "engine/src/flutter/third_party/gn",
        build_file = _OVERLAYS + ":gn/BUILD.gn_tool.bazel",
    ),
}

# Debian sysroots, keyed by repository name. They are not DEPS entries: the
# linux_sysroot_* hooks unpack them with install-sysroot.py, whose pins live
# in sysroots.json (read below, so there is one source of truth). Like the
# tools, they are symlinked from the checkout by default and downloaded when
# FLUTTER_BAZEL_FETCH_TOOLCHAINS is set.
_SYSROOT_REPOSITORIES = {
    "sysroot_linux_x64": struct(
        key = "bullseye_amd64",
        build_file = _OVERLAYS + ":sysroot/BUILD.sysroot_linux.bazel",
    ),
}

_SYSROOTS_JSON = Label("//engine/src/build/linux/sysroot_scripts:sysroots.json")
_SYSROOTS_DIR = "engine/src/build/linux"

_FETCH_TOOLCHAINS_ENV = "FLUTTER_BAZEL_FETCH_TOOLCHAINS"

# sha256 of the zip CIPD serves for a (package, version) pair.
#
# A CIPD instance id is base64url(sha256(zip) + 0x02), so the hash can be read
# off the instance id `gclient sync` records in `<path>/.versions/*.cipd_version`
# without downloading anything; Bazel also prints it after an unpinned fetch.
# A missing entry is not an error -- the download is merely unverified and not
# shared through the repository cache. These should eventually be produced by
# gen_deps.dart rather than maintained by hand.
_CIPD_SHA256 = {
    ("fuchsia/third_party/clang/linux-amd64", "git_revision:07d67299a15ce03b053736e2d31a668ee0576987"): "6b657ccd9ca05c6b9e4458181ec71f1dbaf7122a5e6df7aaaec381a31ab34bd3",
    ("gn/gn/linux-amd64", "git_revision:81b24e01531ecf0eff12ec9359a555ec3944ec4e"): "cd330cb4f4e0d8e5c82ca3a583798ea5337fd01308952dbe227c9dd8bc51d854",
}

def _cipd_platform(mctx):
    """Returns the value CIPD substitutes for `${platform}` on this host."""
    os_name = mctx.os.name.lower()
    if os_name.startswith("linux"):
        os_part = "linux"
    elif os_name.startswith("mac"):
        os_part = "mac"
    elif os_name.startswith("windows"):
        os_part = "windows"
    else:
        fail("synced_deps: unsupported host OS %r" % mctx.os.name)

    arch = mctx.os.arch.lower()
    if arch in ("amd64", "x86_64", "x64"):
        arch_part = "amd64"
    elif arch in ("aarch64", "arm64"):
        arch_part = "arm64"
    else:
        fail("synced_deps: unsupported host architecture %r" % mctx.os.arch)

    return os_part + "-" + arch_part

def _fetch_toolchains(mctx):
    return mctx.getenv(_FETCH_TOOLCHAINS_ENV, "") not in ("", "0", "false", "no")

def _cipd_pin(path):
    entry = CIPD_DEPS.get(path)
    if entry == None:
        fail("synced_deps: %s is not a CIPD dependency in DEPS (deps.lock.bzl is stale?)" % path)
    packages = entry["packages"]
    if len(packages) != 1:
        fail("synced_deps: %s installs %d CIPD packages; exactly one is supported" % (path, len(packages)))
    return packages[0]

def _sysroot_repositories(mctx, fetch):
    sysroots = json.decode(mctx.read(_SYSROOTS_JSON))
    for name, spec in _SYSROOT_REPOSITORIES.items():
        entry = sysroots.get(spec.key)
        if entry == None:
            fail("synced_deps: %s has no %r entry" % (_SYSROOTS_JSON, spec.key))
        if fetch:
            # install-sysroot.py downloads `<URL>/<sha256>` (a .tar.xz).
            http_archive(
                name = name,
                url = entry["URL"] + "/" + entry["Sha256Sum"],
                sha256 = entry["Sha256Sum"],
                type = "tar.xz",
                build_file = spec.build_file,
            )
        else:
            synced_repository(
                name = name,
                path = _SYSROOTS_DIR + "/" + entry["SysrootDir"],
                build_file = spec.build_file,
            )

def _synced_deps_impl(mctx):
    for name, spec in _SOURCE_REPOSITORIES.items():
        if spec.path not in GIT_DEPS:
            fail("synced_deps: %s is not a git dependency in DEPS (deps.lock.bzl is stale?)" % spec.path)
        synced_repository(name = name, path = spec.path, build_file = spec.build_file)

    fetch = _fetch_toolchains(mctx)
    platform = _cipd_platform(mctx)
    for name, spec in _TOOL_REPOSITORIES.items():
        pin = _cipd_pin(spec.path)
        if fetch:
            package = pin["package"].replace("${platform}", platform)
            cipd_package(
                name = name,
                package = package,
                version = pin["version"],
                sha256 = _CIPD_SHA256.get((package, pin["version"]), ""),
                build_file = spec.build_file,
            )
        else:
            synced_repository(name = name, path = spec.path, build_file = spec.build_file)

    _sysroot_repositories(mctx, fetch)

    return mctx.extension_metadata(
        root_module_direct_deps = "all",
        root_module_direct_dev_deps = [],
        # Everything here is derived from checked-in files and the host
        # platform; nothing needs to be recorded in MODULE.bazel.lock.
        reproducible = True,
    )

synced_deps = module_extension(
    implementation = _synced_deps_impl,
    doc = "Exposes DEPS dependencies (synced trees, or downloads for toolchains) as repositories.",
)
