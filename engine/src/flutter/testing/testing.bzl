# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Bazel counterparts of the templates in testing.gni."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")
load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_library")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
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
# Each as gl_wrap's product (by base name) and its path next to the binary:
# GN's layout, which the manifests' library_path entries are relative to
# (the layer's is ../libVkLayer_khronos_validation.so from vulkan-data/).
_GPU_TEST_BACKEND_FILES = {
    "libvk_swiftshader.so": "libvk_swiftshader.so",
    "libvulkan.so.1": "libvulkan.so.1",
    "vk_swiftshader_icd.json": "vk_swiftshader_icd.json",
    # The Khronos validation layer and its manifest, for the Vulkan
    # playground, which requires validation.
    "libVkLayer_khronos_validation.so": "libVkLayer_khronos_validation.so",
    "VkLayer_khronos_validation.json": "vulkan-data/VkLayer_khronos_validation.json",
}

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

def _selected_files(targets):
    # The files of `targets` (a label_keyed_string_dict of target to patterns
    # separated by spaces, none for every file) that the patterns keep.
    files = []
    for target, patterns in targets.items():
        wanted = patterns.split(" ") if patterns else []
        for f in target[DefaultInfo].files.to_list():
            if wanted and not [p for p in wanted if _matches(f.basename, p)]:
                continue
            files.append(f)
    return files

FixturesDestinationInfo = provider(
    doc = "Fixtures that a test_fixtures() of one package places in the fixtures directory of " +
          "another (GN's `dest`): the destination package's own test_fixtures copies them.",
    fields = {
        "package": "The destination package (`engine/src/flutter/lib/ui`).",
        "files": "depset of the files.",
    },
)

_CollectedFixturesInfo = provider(
    doc = "What _collect_fixtures gathered below a target.",
    fields = {
        "by_package": "dict of destination package to list of depsets of files.",
    },
)

def _collect_fixtures_impl(target, ctx):
    by_package = {}
    if FixturesDestinationInfo in target:
        info = target[FixturesDestinationInfo]
        by_package[info.package] = [info.files]
    for dep in getattr(ctx.rule.attr, "deps", []):
        if _CollectedFixturesInfo in dep:
            for package, files in dep[_CollectedFixturesInfo].by_package.items():
                by_package[package] = by_package.get(package, []) + files
    return [_CollectedFixturesInfo(by_package = by_package)]

# GN reaches a `dest` test_fixtures through groups (`deps = ["fixtures/shaders"]`,
# a group of groups); here groups are cc_library targets, which forward no
# provider of their own, so an aspect walks the `deps` chain instead.
_collect_fixtures = aspect(
    implementation = _collect_fixtures_impl,
    attr_aspects = ["deps"],
    doc = "Collects the FixturesDestinationInfo of a target and of everything below its `deps`.",
)

def _destined_fixtures_impl(ctx):
    files = depset(ctx.files.fixtures + _selected_files(ctx.attr.fixtures_targets))
    return [
        DefaultInfo(files = files),
        FixturesDestinationInfo(package = ctx.attr.package, files = files),
        # Groups (cc_library targets) depend on it, as GN's do.
        CcInfo(),
    ]

_destined_fixtures = rule(
    implementation = _destined_fixtures_impl,
    doc = "GN's test_fixtures() with a `dest` in another package: declares the fixtures for that " +
          "package's test_fixtures to copy (nothing is copied here, and no location library is made, " +
          "which matches GN: the one it writes is never linked, the copy's deps carrying no objects).",
    attrs = {
        "package": attr.string(mandatory = True, doc = "The destination package."),
        "fixtures": attr.label_list(allow_files = True, doc = "The files."),
        "fixtures_targets": attr.label_keyed_string_dict(
            doc = "The targets whose files are fixtures, each with its patterns separated by spaces (none for every file).",
        ),
        "deps": attr.label_list(doc = "GN's deps: ordering only."),
    },
)

def _fixture_copies_impl(ctx):
    files = _selected_files(ctx.attr.targets)
    for dep in ctx.attr.deps:
        if _CollectedFixturesInfo in dep:
            for destined in dep[_CollectedFixturesInfo].by_package.get(ctx.label.package, []):
                files += destined.to_list()
    outputs = []
    for f in files:
        out = ctx.actions.declare_file(paths.join(ctx.attr.dir, f.basename))
        ctx.actions.symlink(output = out, target_file = f)
        outputs.append(out)
    return [DefaultInfo(files = depset(outputs))]

_fixture_copies = rule(
    implementation = _fixture_copies_impl,
    doc = "Copies (as symlinks) into the fixtures directory the files of other targets (GN's " +
          "`fixtures = get_target_outputs(...)`, optionally through filter_include) and the fixtures " +
          "that test_fixtures() targets below `deps` declare for this package (GN's `dest`).",
    attrs = {
        "targets": attr.label_keyed_string_dict(
            doc = "The targets, each with its patterns separated by spaces (none for every file).",
        ),
        "deps": attr.label_list(
            aspects = [_collect_fixtures],
            doc = "GN's deps of the template, searched for fixtures destined here.",
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
        dest = None,
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

    With `dest` naming another package (GN's `dest = "$root_gen_dir/<path>"`,
    the shader fixtures of lib/ui), the fixtures belong to that package's
    directory: the target declares them (FixturesDestinationInfo), and the
    test_fixtures of that package copies them into its `assets` when this
    target is below its `deps`.

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
        that they are built with the test and present when it runs, and
        where fixtures destined for this package are looked for.
      dest: the package whose fixtures directory receives the files
        (`//engine/src/flutter/lib/ui`), when not this one; see above.
      visibility: visibility of the library.
      **kwargs: forwarded to the library (`tags`, ...).
    """
    package = native.package_name()
    fixtures_dir = paths.join(package, "assets")
    targets = {target: " ".join(patterns) for target, patterns in fixtures_targets.items()}

    if dest != None and dest.lstrip("/") != package:
        if dart_main:
            fail("flutter_test_fixtures(%s): dart_main with a dest in another package is not supported" % name)
        _destined_fixtures(
            name = name,
            package = dest.lstrip("/"),
            fixtures = fixtures,
            fixtures_targets = targets,
            deps = deps,
            testonly = True,
            visibility = visibility,
            **kwargs
        )
        return

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

    if fixtures_targets or deps:
        _fixture_copies(
            name = "_ft_%s" % name,
            targets = targets,
            deps = deps,
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
    for product, file in _GPU_TEST_BACKEND_FILES.items():
        copy_file(
            name = "_gb_%s_%s" % (name, product),
            src = "%s:%s" % (_GPU_TEST_BACKENDS_PACKAGE, product),
            out = file,
            allow_symlink = True,
            visibility = ["//visibility:private"],
        )
        copies.append(file)
    native.filegroup(
        name = name,
        srcs = copies,
        visibility = visibility,
    )

def _source_tree_files_impl(ctx):
    # Each file of a tree at `<path>/<its path in the repository>` in this
    # package: with the package at the tree's place under the source root,
    # the file's runfiles path is its GN path.
    links = []
    for target, path in ctx.attr.trees.items():
        for f in target[DefaultInfo].files.to_list():
            if not f.short_path.startswith("../"):
                fail("%s: %s is in this repository; a filegroup serves it" % (ctx.label, f.short_path))
            relative = f.short_path.split("/", 2)[2]
            link = ctx.actions.declare_file(paths.join(path, relative))
            ctx.actions.symlink(output = link, target_file = f)
            links.append(link)
    return [DefaultInfo(files = depset(links), runfiles = ctx.runfiles(files = links))]

source_tree_files = rule(
    implementation = _source_tree_files_impl,
    doc = "Files of trees gclient syncs (external repositories here) at their paths under the engine's " +
          "source root, for tests that read them by those paths from the source root as run_tests.py " +
          "runs them (Skia's resources/images for the Dart tests).",
    attrs = {
        "trees": attr.label_keyed_string_dict(
            allow_files = True,
            mandatory = True,
            doc = "Files of a repository, mapped to the tree's directory below this package (`skia`).",
        ),
    },
)

# ---------------------------------------------------------------------------
# Suites that open a window
# ---------------------------------------------------------------------------

def _display_test_impl(ctx):
    # The test's working directory is the runfiles tree's main repository,
    # under `bazel test` and `bazel run` alike, so short paths resolve as
    # they are.
    launcher = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        output = launcher,
        content = "#!/bin/bash\nexec \"%s\" \"%s\" \"$@\"\n" % (ctx.file._wrapper.short_path, ctx.executable.binary.short_path),
        is_executable = True,
    )
    runfiles = ctx.runfiles(files = [ctx.file._wrapper, ctx.executable.binary] + ctx.files.data)
    runfiles = runfiles.merge(ctx.attr.binary[DefaultInfo].default_runfiles)
    for target in ctx.attr.data:
        runfiles = runfiles.merge(target[DefaultInfo].default_runfiles)
    env = dict(ctx.attr.env)
    if ctx.attr.vulkan_validation:
        # testing/run_tests.py's vulkan_validation_env: the loader finds
        # SwiftShader's ICD manifest and the validation layer next to the
        # binary (flutter_gpu_test_backends), by paths relative to the
        # runfiles tree the test runs from.
        package = ctx.label.package
        env["VK_ICD_FILENAMES"] = package + "/vk_swiftshader_icd.json"
        env["VK_LAYER_PATH"] = package + "/vulkan-data"
        env["VK_INSTANCE_LAYERS"] = "VK_LAYER_KHRONOS_validation"
    return [
        DefaultInfo(executable = launcher, runfiles = runfiles),
        RunEnvironmentInfo(environment = env),
    ]

_display_test = rule(
    implementation = _display_test_impl,
    test = True,
    doc = "Runs a test binary under a display (testing/xvfb_run.sh): the suite's own Xvfb unless DISPLAY is set.",
    attrs = {
        "binary": attr.label(
            mandatory = True,
            executable = True,
            cfg = "target",
            doc = "The test binary.",
        ),
        "data": attr.label_list(
            allow_files = True,
            doc = "Runfiles of the test, besides the binary's.",
        ),
        "env": attr.string_dict(
            doc = "Environment of the test.",
        ),
        "vulkan_validation": attr.bool(
            doc = "Point the Vulkan loader at the GPU test backends copied into this package (SwiftShader's ICD " +
                  "manifest, the Khronos validation layer), as testing/run_tests.py does for the Impeller suites.",
        ),
        "_wrapper": attr.label(
            default = "//engine/src/flutter/testing:xvfb_run.sh",
            allow_single_file = True,
        ),
    },
)

def flutter_display_test(name, size = None, timeout = None, shard_count = None, flaky = None, args = [], data = [], env = {}, vulkan_validation = True, tags = [], visibility = None, **kwargs):
    """A test suite that opens a window: the Impeller playground's (GLFW on X11).

    testing/run_tests.py starts an Xvfb for the Linux suites; here the binary
    is a cc_binary (`<name>_binary`, in this package, so that the GPU test
    backends copied beside it are found) and the test target runs it
    through testing/xvfb_run.sh, which uses the environment's DISPLAY or
    starts an Xvfb of its own.

    Args:
      name: name of the test; the binary is `<name>_binary`.
      size: the test's size.
      timeout: the test's timeout.
      shard_count: the test's shards; xvfb_run.sh hands Bazel's shard
        variables to googletest under the GTEST_* names it reads, so a shard
        runs its share of the suite's tests (run_tests.py's gtest-parallel,
        in Bazel's form).
      flaky: the test's flaky attribute.
      args: arguments of the binary.
      data: runfiles of the test.
      env: environment of the test.
      vulkan_validation: run_tests.py's vulkan_validation_env: SwiftShader as
        the ICD and the Khronos validation layer, from the GPU test backends
        copied into this package (the suite must list them as data).
      tags: tags of the test.
      visibility: visibility of the test.
      **kwargs: the binary's attributes (cc_test's: srcs, deps, copts, ...).
    """
    cc_binary(
        name = name + "_binary",
        testonly = True,
        visibility = ["//visibility:private"],
        **kwargs
    )
    _display_test(
        name = name,
        binary = ":" + name + "_binary",
        size = size,
        timeout = timeout,
        shard_count = shard_count,
        flaky = flaky,
        args = args,
        data = data,
        env = env,
        vulkan_validation = vulkan_validation,
        tags = tags,
        visibility = visibility,
    )

# ---------------------------------------------------------------------------
# The Dart tests: testing/dart under flutter_tester
# ---------------------------------------------------------------------------

# What testing/run_tests.py passes flutter_tester for every Dart test, after
# the variant's own options: the test fonts, ICU's data file (GN's
# `<build dir>/icudtl.dat`), lib/ui's fixture assets (GN's
# `<build dir>/gen/flutter/lib/ui/assets`; the same files under the runfiles
# root here), no asset fonts, then the kernel. The test runs from the source
# root, as under run_tests.py (BUILDROOT_DIR: engine/src, where the tests'
# relative paths -- flutter/lib/ui/fixtures/..., flutter/testing/resources/...
# -- resolve), with FLUTTER_BUILD_DIRECTORY (run_tests.py: the GN build
# directory) a scratch directory whose gen/ is that root: under the runfiles
# root, generated files sit at their source paths, which is what GN's gen/
# holds.
_TESTER_LAUNCHER = """#!/bin/bash
# Generated by flutter_tester_test (testing.bzl); runs {kernel} under
# {tester} as testing/run_tests.py does.
set -eu
runfiles="$PWD"
build_dir="${{TEST_TMPDIR:-${{TMPDIR:-/tmp}}}}/flutter_build_directory"
mkdir -p "$build_dir"
ln -sfn "$runfiles/engine/src" "$build_dir/gen"
export FLUTTER_BUILD_DIRECTORY="$build_dir"
options=()
# The test's own options, from its `// FlutterTesterOptions=` line, as
# run_tests.py reads them.
while IFS= read -r line; do
  options+=("$line")
done < <(sed -n 's|^// FlutterTesterOptions=||p' "$runfiles/{source}")
cd "$runfiles/engine/src"
exec "$runfiles/{tester}" "$@" "${{options[@]}}" \\
  --use-test-fonts \\
  "--icu-data-file-path=$runfiles/{icu_data}" \\
  "--flutter-assets-dir=$runfiles/{assets_dir}" \\
  --disable-asset-fonts \\
  "$runfiles/{kernel}"
"""

def _flutter_tester_test_impl(ctx):
    launcher = ctx.actions.declare_file(ctx.label.name + ".sh")
    assets_dir = paths.join(ctx.attr.assets.label.package, "assets")
    ctx.actions.write(
        output = launcher,
        content = _TESTER_LAUNCHER.format(
            kernel = ctx.file.kernel.short_path,
            tester = ctx.executable.tester.short_path,
            source = ctx.file.source.short_path,
            icu_data = ctx.file.icu_data.short_path,
            assets_dir = assets_dir,
        ),
        is_executable = True,
    )
    runfiles = ctx.runfiles(
        files = [ctx.file.kernel, ctx.file.source, ctx.file.icu_data, ctx.executable.tester] + ctx.files.data,
    )
    runfiles = runfiles.merge(ctx.attr.tester[DefaultInfo].default_runfiles)
    runfiles = runfiles.merge(ctx.attr.assets[DefaultInfo].default_runfiles)
    for target in ctx.attr.data:
        runfiles = runfiles.merge(target[DefaultInfo].default_runfiles)
    return [
        DefaultInfo(executable = launcher, runfiles = runfiles),
        RunEnvironmentInfo(environment = dict(ctx.attr.env)),
    ]

flutter_tester_test = rule(
    implementation = _flutter_tester_test_impl,
    test = True,
    doc = "One Dart test of the engine (a kernel file) under flutter_tester, as testing/run_tests.py runs it.",
    attrs = {
        "kernel": attr.label(
            allow_single_file = [".dill"],
            mandatory = True,
            doc = "The test compiled to kernel (flutter_frontend_server's output).",
        ),
        "source": attr.label(
            allow_single_file = [".dart"],
            mandatory = True,
            doc = "The test's source, for its `// FlutterTesterOptions=` line.",
        ),
        "tester": attr.label(
            default = "//engine/src/flutter/shell/testing:flutter_tester",
            executable = True,
            cfg = "target",
            doc = "The runner: flutter_tester, or flutter_tester_opengles for the OpenGL ES variants.",
        ),
        "assets": attr.label(
            default = "//engine/src/flutter/lib/ui:ui_unittests_fixtures",
            doc = "The fixtures whose `assets` directory is --flutter-assets-dir (lib/ui's).",
        ),
        "icu_data": attr.label(
            default = "@icu//:icudata",
            allow_single_file = True,
            doc = "ICU's data file (--icu-data-file-path).",
        ),
        "data": attr.label_list(
            allow_files = True,
            doc = "Runfiles of the test besides the runner's and the assets'.",
        ),
        "env": attr.string_dict(
            doc = "Environment of the test.",
        ),
    },
)

# run_tests.py's variants of every Dart test (gather_dart_tests): the
# renderer (Skia's software backend, Impeller on Vulkan, Impeller on OpenGL
# ES through flutter_tester_opengles; Metal on a Mac) by itself and
# multithreaded (--force-multithreading), except that OpenGL ES over swangle
# cannot share a context between the raster and IO threads. Each as a
# suffix of the test's name and the options in run_tests.py's order.
_TESTER_VARIANTS = [
    ("skia", "", False),
    ("skia_mt", "", True),
    ("vulkan", "vulkan", False),
    ("vulkan_mt", "vulkan", True),
    ("opengles", "opengles", False),
]

def _tester_options(backend, multithreaded, vm_service, microtask_profiling, flutter_gpu = True):
    options = []
    if multithreaded:
        options.append("--force-multithreading")
    if not vm_service:
        options.append("--disable-vm-service")
    if backend:
        options += ["--enable-impeller", "--impeller-backend=" + backend]
        if flutter_gpu:
            options.append("--enable-flutter-gpu")
    else:
        options.append("--no-enable-impeller")
    if microtask_profiling:
        options.append("--profile-microtasks")
    return options

def flutter_dart_tests(
        name,
        tests,
        vm_service = False,
        srcs = [],
        package_roots = [],
        data = [],
        tester = "//engine/src/flutter/shell/testing:flutter_tester",
        tester_opengles = "//engine/src/flutter/shell/testing:flutter_tester_opengles",
        size = "medium",
        tags = [],
        visibility = None):
    """The engine's Dart tests of this package: GN's flutter_frontend_server per test, run as run_tests.py runs them.

    Each `<test>.dart` is compiled to `<test>.dart.dill` with the three
    defines GN's //flutter/testing/dart gives the compiler, in the terms of
    the directory the tests run from (engine/src under the runfiles root,
    run_tests.py's working directory; GN's values are absolute paths):
    kFlutterSrcDirectory is `flutter`, kFlutterBuildDirectory is `.` (GN's
    root_gen_dir: under the runfiles root, generated files sit at their
    source paths -- the fonts of //flutter/txt's fixtures at
    flutter/txt/assets, spawn_helper's kernel at the root) and
    kSkiaGoldWorkDirectory is `skia_gold_<test>` (a directory the test
    creates). A fourth, kFlutterSrcDirectoryUri, names the source root as
    the compiler recorded it (`org-dartlang-root:///engine/src/flutter`, see
    dart_kernel), for spawn_test's library lookup, which GN composes from
    `file://` and the absolute path. Then a test target per variant
    (_TESTER_VARIANTS) named `<test>_<variant>`, and `name` as the suite of
    them all.

    Args:
      name: name of the test suite.
      tests: GN's list: the test files (`*_test.dart`), each an entry point,
        and spawn_helper.dart, which spawn_test loads as a kernel from
        kFlutterBuildDirectory (compiled, not run). The kernels' sources are
        the package's Dart files (GN finds them through the depfile).
      vm_service: run the tests with the VM service (testing/dart/vm_service;
        run_tests.py's enable_vm_service), and microtask_profiling_test with
        --profile-microtasks.
      srcs: Dart sources of other packages of this repository the tests
        import (skia_gold_client's, lib/gpu's), besides this package's.
      package_roots: dart_package_root targets with the packages the tests
        import from other repositories (package:test and what it reaches).
      data: runfiles every test needs besides the runner's (the fonts of
        //flutter/txt's fixtures; spawn_helper's kernel at the root).
      tester: the runner.
      tester_opengles: the runner of the OpenGL ES variants.
      size: the tests' size.
      tags: tags of the tests.
      visibility: visibility of the suite.
    """
    defines = [
        "-DkFlutterSrcDirectory=flutter",
        "-DkFlutterSrcDirectoryUri=" + _SOURCE_URI_PREFIX + "flutter",
        "-DkFlutterBuildDirectory=.",
    ]
    all_tests = []
    srcs = native.glob(["*.dart"]) + srcs
    for test in tests:
        _dart_kernel(
            name = "compile_" + test,
            main = test,
            srcs = srcs,
            out = test + ".dill",
            package_roots = package_roots,
            args = defines + ["-DkSkiaGoldWorkDirectory=skia_gold_" + test],
            testonly = True,
            visibility = ["//visibility:public"],
        )
    for test in tests:
        if not test.endswith("_test.dart"):
            # spawn_helper.dart: compiled for spawn_test, not run
            # (run_tests.py globs *_test.dart).
            continue
        base = test[:-len(".dart")]
        variants = [
            (suffix, backend, multithreaded, True)
            for suffix, backend, multithreaded in _TESTER_VARIANTS
        ]
        if test == "gpu_test.dart":
            # Once more with Impeller but without Flutter GPU, for the
            # "Flutter GPU must be enabled" error.
            variants += [("vulkan_no_flutter_gpu", "vulkan", False, False), ("opengles_no_flutter_gpu", "opengles", False, False)]
        for suffix, backend, multithreaded, flutter_gpu in variants:
            test_name = base + "_" + suffix
            flutter_tester_test(
                name = test_name,
                kernel = ":" + test + ".dill",
                source = test,
                tester = tester_opengles if backend == "opengles" else tester,
                args = _tester_options(
                    backend,
                    multithreaded,
                    vm_service,
                    microtask_profiling = vm_service and test == "microtask_profiling_test.dart",
                    flutter_gpu = flutter_gpu,
                ),
                data = data,
                size = size,
                tags = tags,
                visibility = ["//visibility:private"],
            )
            all_tests.append(":" + test_name)
    native.test_suite(
        name = name,
        tests = all_tests,
        visibility = visibility,
    )
