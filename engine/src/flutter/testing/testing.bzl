# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Bazel counterparts of the templates in testing.gni."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")
load("@rules_cc//cc:defs.bzl", "cc_library")
load("//engine/src/flutter/build/bazel/dart:kernel.bzl", "SOURCE_URI_SCHEME", _dart_kernel = "dart_kernel")
load("//engine/src/flutter/build/bazel/dart:snapshot.bzl", "aot_snapshot")

# Where tests run from: the runfiles directory of the main repository. Paths
# below are relative to it, so nothing absolute is compiled into a test. The
# source directory has GN's trailing slash (rebase_path("//") ends in one).
_SOURCE_DIR = "engine/src/"
_TESTING_ASSETS_DIR = "engine/src/flutter/testing/assets"

# The URI the Dart compiler records for a source file of the tree: dart_kernel
# (build/bazel/dart/kernel.bzl) compiles under a virtual root scheme over the
# execution root, so a source's URI is machine-independent and the same in
# every sandbox; a test looks a library up by the same URI (GetSourceUri).
_SOURCE_URI_PREFIX = SOURCE_URI_SCHEME + ":///" + _SOURCE_DIR

# testing.gni's is_aot_test: the profile and release runtime modes, in which
# the fixtures are compiled ahead of time.
_AOT_MODES = [
    "//engine/src/flutter/common:runtime_mode_profile",
    "//engine/src/flutter/common:runtime_mode_release",
]

# dart_snapshot_kernel's -Ddart.vm.product=true modes.
_PRODUCT_MODES = [
    "//engine/src/flutter/common:runtime_mode_jit_release",
    "//engine/src/flutter/common:runtime_mode_release",
]

def _quoted_define(name, value):
    return '%s=\\"%s\\"' % (name, value)

def flutter_dart_snapshot_kernel(name, dart_main, dart_kernel, dart_srcs = None, visibility = None, **kwargs):
    """GN's dart_snapshot_kernel (testing.gni): a Dart entry point to kernel.

    A flutter_frontend_server run with testing.gni's arguments: the product
    define in the release modes, --aot --tfa in the AOT test modes.

    Args:
      name: name of the target.
      dart_main: the entry point.
      dart_kernel: the kernel file to write, relative to this package (GN's
        `$target_gen_dir/assets/...`).
      dart_srcs: the Dart sources the entry point imports; by default the
        `.dart` files of its directory, when that is in this package.
      visibility: visibility of the target.
      **kwargs: forwarded to dart_kernel.
    """
    if dart_srcs == None:
        dart_srcs = [] if dart_main.startswith("//") or dart_main.startswith("@") else native.glob([paths.join(paths.dirname(dart_main), "*.dart")])
    _dart_kernel(
        name = name,
        main = dart_main,
        srcs = dart_srcs,
        out = dart_kernel,
        product = select({mode: True for mode in _PRODUCT_MODES} | {"//conditions:default": False}),
        args = select({mode: ["--aot", "--tfa"] for mode in _AOT_MODES} | {"//conditions:default": []}),
        testonly = True,
        visibility = visibility,
        **kwargs
    )

def flutter_dart_snapshot_aot(name, dart_kernel, dart_elf_filename, deps = [], visibility = None, **kwargs):
    """GN's dart_snapshot_aot (testing.gni): a kernel file to an AOT ELF snapshot in `assets/`.

    The snapshot exists in the AOT test modes alone (profile and release),
    where dart_snapshot_kernel compiles its kernel with --aot: gen_snapshot
    refuses a JIT kernel ("Missing table selector metadata"), and GN reaches
    the template only from targets under those modes. Elsewhere the target
    is incompatible, which a wildcard build skips.

    Args:
      name: name of the target.
      dart_kernel: the kernel file.
      dart_elf_filename: the ELF's file name.
      deps: GN's ordering dependencies (the kernel's target); the file
        dependency orders the actions here.
      visibility: visibility of the target.
      **kwargs: forwarded to aot_snapshot.
    """
    _ = deps  # @unused
    aot_snapshot(
        name = name,
        kernel = dart_kernel,
        elf = paths.join("assets", dart_elf_filename),
        target_compatible_with = select({mode: [] for mode in _AOT_MODES} | {"//conditions:default": ["@platforms//:incompatible"]}),
        testonly = True,
        visibility = visibility,
        **kwargs
    )

def flutter_test_fixtures(
        name,
        fixtures = [],
        dart_main = None,
        dart_srcs = None,
        use_target_as_artifact_prefix = False,
        visibility = None,
        **kwargs):
    """Declares the fixtures of a test binary, like GN's test_fixtures template.

    Creates a library named `name` that test binaries depend on. It defines
    the compiled-in default locations flutter::testing::GetSourcePath,
    GetFixturesPath and GetTestingAssetsPath fall back to, and carries the
    fixtures as runfiles. As in GN, the fixtures are copied into an `assets`
    directory next to the test (here `<package>/assets` under the runfiles
    root rather than under the GN target_gen_dir), so a test finds them at
    GetFixturesPath()/<basename>.

    A Dart entry point (GN's `dart_main`) is compiled to kernel in the same
    directory, as `kernel_blob.bin` (`<name>_kernel_blob.bin` with
    `use_target_as_artifact_prefix`), which DartFixture loads from there.
    The sources it imports are `dart_srcs`, by default the `.dart` files of
    its own directory (GN finds them through the compiler's depfile). The
    AOT snapshot GN adds in the profile and release runtime modes
    (`app_elf_snapshot.so`) is not produced yet: the host suites run in the
    debug mode.

    Args:
      name: name of the library.
      fixtures: files to copy into the fixtures directory.
      dart_main: the Dart entry point to compile to kernel, if any.
      dart_srcs: the Dart sources the entry point imports; see above.
      use_target_as_artifact_prefix: prefix the kernel's name with `name`.
      visibility: visibility of the library.
      **kwargs: forwarded to the library (`tags`, ...).
    """
    package = native.package_name()
    fixtures_dir = paths.join(package, "assets")

    copies = []
    for fixture in fixtures:
        basename = paths.basename(fixture)
        out = paths.join("assets", basename)
        copy_file(
            name = "_cf_%s_%s" % (name, basename),
            src = fixture,
            out = out,
            allow_symlink = True,
            testonly = True,
            visibility = ["//visibility:private"],
        )
        copies.append(out)

    if dart_main:
        prefix = name + "_" if use_target_as_artifact_prefix else ""
        kernel = paths.join("assets", prefix + "kernel_blob.bin")
        flutter_dart_snapshot_kernel(
            name = "_ds_%s" % name,
            dart_main = dart_main,
            dart_kernel = kernel,
            dart_srcs = dart_srcs,
            visibility = ["//visibility:private"],
        )
        copies.append(kernel)

    cc_library(
        name = name,
        testonly = True,
        srcs = ["//engine/src/flutter/testing:fixtures_location.cc"],
        local_defines = [
            _quoted_define("FLUTTER_TEST_SOURCE_DIR_DEFAULT", _SOURCE_DIR),
            _quoted_define("FLUTTER_TEST_FIXTURES_DIR_DEFAULT", fixtures_dir),
            _quoted_define("FLUTTER_TEST_TESTING_ASSETS_DIR_DEFAULT", _TESTING_ASSETS_DIR),
            _quoted_define("FLUTTER_TEST_SOURCE_URI_PREFIX_DEFAULT", _SOURCE_URI_PREFIX),
        ],
        data = copies,
        # The functions are referenced from testing.cc, which sits in an
        # archive linked before this one; make sure the object is kept.
        alwayslink = True,
        visibility = visibility,
        deps = ["//engine/src/flutter/testing:testing_core"],
        **kwargs
    )
