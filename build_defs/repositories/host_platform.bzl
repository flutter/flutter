# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The host that runs the build, as constants (`@host_platform//:host.bzl`).

GN knows its host (`host_os`, `host_cpu`) and spells the host's prebuilts
by it: buildtools/<host>/clang, prebuilts/<host>/dart-sdk. Bazel's BUILD
files are read on every host alike, so what depends on the host -- the
repository of the Dart SDK the build's tools run on, the constraint that
says "the host's own CPU" (build/bazel's host_toolchain group, GN's
`current_toolchain == host_toolchain`) -- comes from this repository, which
the synced_deps extension lays from what it sees of the machine:

    load("@host_platform//:host.bzl", "HOST_CPU_CONSTRAINT", "HOST_DART_SDK", "HOST_PLATFORM")

Linux x64 and arm64, macOS x64 and arm64, Windows x64, as DEPS packages
them.
"""

_OSES = {
    "linux": struct(gn = "linux", prebuilts = "linux", buildtools = "linux", platform = "linux", constraint = "@platforms//os:linux"),
    "mac": struct(gn = "mac", prebuilts = "macos", buildtools = "mac", platform = "macos", constraint = "@platforms//os:macos"),
    "windows": struct(gn = "win", prebuilts = "windows", buildtools = "windows", platform = "windows", constraint = "@platforms//os:windows"),
}

_CPUS = {
    "x64": struct(constraint = "@platforms//cpu:x86_64"),
    "arm64": struct(constraint = "@platforms//cpu:aarch64"),
}

def host_platform_values(os_name, arch):
    """The constants for a host.

    Args:
      os_name: the host's OS as repository_ctx.os.name spells it (linux, mac os x, windows ...).
      arch: the host's CPU as repository_ctx.os.arch spells it (amd64, aarch64, ...).

    Returns:
      The constants of host.bzl, by name.
    """
    name = os_name.lower()
    if name.startswith("linux"):
        os = "linux"
    elif name.startswith("mac"):
        os = "mac"
    elif name.startswith("windows"):
        os = "windows"
    else:
        fail("host_platform: unsupported host OS %r" % os_name)
    arch = arch.lower()
    if arch in ("amd64", "x86_64", "x64"):
        cpu = "x64"
    elif arch in ("aarch64", "arm64"):
        cpu = "arm64"
    else:
        fail("host_platform: unsupported host architecture %r" % arch)
    spec = _OSES[os]
    prebuilts = "%s-%s" % (spec.prebuilts, cpu)
    return {
        # GN's host_os and host_cpu.
        "HOST_OS": spec.gn,
        "HOST_CPU": cpu,
        # The platform constraints of the host.
        "HOST_OS_CONSTRAINT": spec.constraint,
        "HOST_CPU_CONSTRAINT": _CPUS[cpu].constraint,
        # The host's directory under prebuilts/ (linux-x64, macos-arm64, ...)
        # and under buildtools/ (linux-x64, mac-arm64, ...: DEPS spells the
        # two differently).
        "HOST_PREBUILTS": prebuilts,
        "HOST_BUILDTOOLS": "%s-%s" % (spec.buildtools, cpu),
        # The repositories of the host's prebuilt Dart SDK and clang
        # (synced_deps' names).
        "HOST_DART_SDK": "@dart_sdk_" + prebuilts.replace("-", "_"),
        "HOST_CLANG": "@clang_%s_%s" % (os, cpu),
        # The host's platform among the engine's (build/bazel/toolchains:
        # linux_x64, macos_arm64, ...), the base of its runtime modes'
        # (build_defs/config/platforms.bzl).
        "HOST_PLATFORM": "%s_%s" % (spec.platform, cpu),
    }

def _host_platform_impl(rctx):
    values = host_platform_values(rctx.os.name, rctx.os.arch)
    rctx.file("BUILD.bazel", "# The host that runs the build (build_defs/repositories/host_platform.bzl).\n")
    rctx.file("host.bzl", "".join([
        "%s = %r\n" % (name, value)
        for name, value in values.items()
    ]))

host_platform = repository_rule(
    implementation = _host_platform_impl,
    doc = "The host's OS, CPU, constraints and prebuilt repositories as constants, host.bzl.",
    local = True,
)
