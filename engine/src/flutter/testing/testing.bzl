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

# The GPU test backends (build/bazel/gl_wrap): SwiftShader's Vulkan driver,
# its ICD manifest and the Vulkan loader, which a suite needs in the
# directory of its binary.
_GPU_TEST_BACKEND_FILES = [
    "libvk_swiftshader.so",
    "libvulkan.so.1",
    "vk_swiftshader_icd.json",
]

_GPU_TEST_BACKENDS_PACKAGE = "//engine/src/flutter/build/bazel/gl_wrap"

def _quoted_define(name, value):
    return '%s=\\"%s\\"' % (name, value)

def flutter_dart_snapshot_kernel(name, dart_main, dart_kernel, dart_srcs = None, dart_packages = {}, visibility = None, **kwargs):
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
      dart_packages: packages it imports from synced trees, each mapped to
        its path under the source root (dart_kernel's package_trees).
      visibility: visibility of the target.
      **kwargs: forwarded to dart_kernel.
    """
    if dart_srcs == None:
        dart_srcs = [] if dart_main.startswith("//") or dart_main.startswith("@") else native.glob([paths.join(paths.dirname(dart_main), "*.dart")])
    _dart_kernel(
        name = name,
        main = dart_main,
        srcs = dart_srcs,
        package_trees = dart_packages,
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

def _matches(basename, pattern):
    # GN's file patterns as the fixtures use them: `*.ext`, or a plain name.
    if pattern.startswith("*") and "*" not in pattern[1:]:
        return basename.endswith(pattern[1:])
    if "*" in pattern:
        fail("fixture pattern %r: only `*.ext` and plain names are supported" % pattern)
    return basename == pattern

def _fixture_target_copies_impl(ctx):
    outputs = []
    for target, patterns in ctx.attr.targets.items():
        wanted = patterns.split(" ") if patterns else []
        for f in target[DefaultInfo].files.to_list():
            if wanted and not [p for p in wanted if _matches(f.basename, p)]:
                continue
            out = ctx.actions.declare_file(paths.join(ctx.attr.dir, f.basename))
            ctx.actions.symlink(output = out, target_file = f)
            outputs.append(out)
    return [DefaultInfo(files = depset(outputs))]

_fixture_target_copies = rule(
    implementation = _fixture_target_copies_impl,
    doc = "Copies (as symlinks) the files of other targets into the fixtures directory: GN's " +
          "`fixtures = get_target_outputs(...)`, optionally through filter_include.",
    attrs = {
        "targets": attr.label_keyed_string_dict(
            doc = "The targets, each with its patterns separated by spaces (none for every file).",
        ),
        "dir": attr.string(mandatory = True),
    },
)

def flutter_test_fixtures(
        name,
        fixtures = [],
        fixtures_targets = {},
        dart_main = None,
        dart_srcs = None,
        dart_packages = {},
        use_target_as_artifact_prefix = False,
        deps = [],
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
      fixtures_targets: targets whose files are copied there too (GN's
        `get_target_outputs()` among the fixtures), each with the
        `filter_include` patterns that select among them (`*.iplr`; none
        for every file).
      dart_main: the Dart entry point to compile to kernel, if any.
      dart_srcs: the Dart sources the entry point imports; see above.
      dart_packages: packages the entry point imports from synced trees
        (see flutter_dart_snapshot_kernel).
      use_target_as_artifact_prefix: prefix the kernel's name with `name`.
      deps: GN's `deps` of the template, the copy's ordering dependencies
        (the targets producing fixtures); runfiles of the library here, so
        that they are built with the test and present when it runs.
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

    if fixtures_targets:
        _fixture_target_copies(
            name = "_ft_%s" % name,
            targets = {target: " ".join(patterns) for target, patterns in fixtures_targets.items()},
            dir = "assets",
            testonly = True,
            visibility = ["//visibility:private"],
        )
        copies.append(":_ft_%s" % name)

    if dart_main:
        prefix = name + "_" if use_target_as_artifact_prefix else ""
        kernel = paths.join("assets", prefix + "kernel_blob.bin")
        flutter_dart_snapshot_kernel(
            name = "_ds_%s" % name,
            dart_main = dart_main,
            dart_kernel = kernel,
            dart_srcs = dart_srcs,
            dart_packages = dart_packages,
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
        data = copies + deps,
        # The functions are referenced from testing.cc, which sits in an
        # archive linked before this one; make sure the object is kept.
        alwayslink = True,
        visibility = visibility,
        deps = ["//engine/src/flutter/testing:testing_core"],
        **kwargs
    )

def flutter_gpu_test_backends(name, visibility = None):
    """The GPU test backends in this package, next to its test binaries.

    GN's //flutter/third_party/swiftshader group and ANGLE's own data_deps
    put SwiftShader's Vulkan driver, its ICD manifest and the Vulkan loader
    in the build directory, next to every executable; ANGLE opens the loader
    from, and points it at the manifest in, the directory of its own module
    (the test binary, which links ANGLE statically), and the engine's test
    utilities look next to the executable too. Here they are built once
    (build/bazel/gl_wrap) and each suite that renders through them lists
    this target as `data`: a copy of the three files in the suite's package,
    which is where the binary sits in the runfiles tree, in bazel-bin and
    for `bazel run`.

    Args:
      name: name of the target (a filegroup of the copies).
      visibility: visibility of the target.
    """
    copies = []
    for file in _GPU_TEST_BACKEND_FILES:
        copy_file(
            name = "_gb_%s_%s" % (name, file),
            src = "%s:%s" % (_GPU_TEST_BACKENDS_PACKAGE, file),
            out = file,
            allow_symlink = True,
            testonly = True,
            visibility = ["//visibility:private"],
        )
        copies.append(file)
    native.filegroup(
        name = name,
        srcs = copies,
        testonly = True,
        visibility = visibility,
    )
