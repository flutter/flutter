# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Bazel counterparts of the templates in testing.gni."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_library")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("//build_defs/cc:sanitizers.bzl", "SANITIZER_ATTRS", "sanitizer_launcher_lines")
load("//build_defs/dart:kernel.bzl", "SOURCE_URI_SCHEME", _dart_kernel = "dart_kernel")
load("//build_defs/dart:snapshot.bzl", "aot_snapshot")

# Where tests run from: the runfiles directory of the main repository. Paths
# below are relative to it, so nothing absolute is compiled into a test. The
# source directory has GN's trailing slash (rebase_path("//") ends in one).
_SOURCE_DIR = "engine/src/"
_TESTING_ASSETS_DIR = "engine/src/flutter/testing/assets"

# The URI the Dart compiler records for a source file of the tree: dart_kernel
# (build_defs/dart/kernel.bzl) compiles under a virtual root scheme over the
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

# run_tests.py's `'release' in build_dir`: the modes whose build directories
# carry the word (host_release, host_jit_release), in which it does not run
# the VM-service Dart tests.
_RELEASE_MODES = _PRODUCT_MODES

# The GPU test backends (build/bazel/gl_wrap): SwiftShader's Vulkan driver,
# its ICD manifest and the Vulkan loader, which a suite needs in the
# directory of its binary, and the Khronos validation layer with its
# manifest, for the Vulkan playground, which requires validation.
# Each as gl_wrap's product (by base name) and its path next to the binary:
# GN's layout, which the manifests' library_path entries are relative to
# (the layer's is ../libVkLayer_khronos_validation.<so|dylib> from
# vulkan-data/), by the OS whose names the libraries carry: Linux's
# (.so, the loader libvulkan.so.1) or macOS's (.dylib). The manifests are
# the same on both.
_GPU_TEST_BACKEND_MANIFESTS = {
    "vk_swiftshader_icd.json": "vk_swiftshader_icd.json",
    "VkLayer_khronos_validation.json": "vulkan-data/VkLayer_khronos_validation.json",
}

_GPU_TEST_BACKEND_FILES = {
    "@platforms//os:linux": {
        "libvk_swiftshader.so": "libvk_swiftshader.so",
        "libvulkan.so.1": "libvulkan.so.1",
        "libVkLayer_khronos_validation.so": "libVkLayer_khronos_validation.so",
    } | _GPU_TEST_BACKEND_MANIFESTS,
    "@platforms//os:macos": {
        "libvk_swiftshader.dylib": "libvk_swiftshader.dylib",
        "libvulkan.dylib": "libvulkan.dylib",
        "libVkLayer_khronos_validation.dylib": "libVkLayer_khronos_validation.dylib",
    } | _GPU_TEST_BACKEND_MANIFESTS,
}

_GPU_TEST_BACKENDS_PACKAGE = "//engine/src/flutter/build/bazel/gl_wrap"

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
    files = list(ctx.files.files) + _selected_files(ctx.attr.targets)
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
    doc = "Copies (as symlinks) into the fixtures directory the fixture files, the files of other " +
          "targets (GN's `fixtures = get_target_outputs(...)`, optionally through filter_include) and " +
          "the fixtures that test_fixtures() targets below `deps` declare for this package (GN's `dest`).",
    attrs = {
        "files": attr.label_list(
            allow_files = True,
            doc = "The fixture files (a select() among them: a file of the machine under the host's setting).",
        ),
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
    `use_target_as_artifact_prefix`), which DartFixture loads from there. In
    the AOT test modes (profile and release: testing.gni's is_aot_test) the
    kernel is compiled for AOT and gen_snapshot turns it into
    `app_elf_snapshot.so` beside it, which the fixtures load instead.
    The sources it imports are `dart_srcs`, by default the `.dart` files of
    its own directory (GN finds them through the compiler's depfile).

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

    # One rule copies them all (a select() among the fixtures -- a file of
    # the machine under the host's setting, a Mac's emoji font -- is a
    # rule's to resolve, and no test of a macro's), each at its basename
    # under assets/.
    copies = []
    if type(fixtures) != "list" or fixtures or fixtures_targets or deps:
        _fixture_copies(
            name = "_ft_%s" % name,
            files = fixtures,
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

        # GN's dart_snapshot: in the AOT test modes, the ELF snapshot too.
        elf = prefix + "app_elf_snapshot.so"
        flutter_dart_snapshot_aot(
            name = "_dsa_%s" % name,
            dart_kernel = kernel,
            dart_elf_filename = elf,
            visibility = ["//visibility:private"],
        )
        copies = copies + select({mode: [paths.join("assets", elf)] for mode in _AOT_MODES} | {"//conditions:default": []})

    # GN's fixtures_location template: the compiled-in default locations that
    # GetSourcePath, GetFixturesPath and GetTestingAssetsPath fall back to
    # when the FLUTTER_TEST_*_DIR environment variables are not set, and the
    # source URI prefix GetSourceUri joins, as a translation unit written per
    # fixtures target with the values baked in (write_file there too). GN's
    # are absolute paths of the build machine; these are relative to the
    # runfiles root, which is the working directory Bazel runs tests in, and
    # the URI prefix is the virtual root the Dart sources are compiled under
    # (build_defs/dart/kernel.bzl). Written rather than passed as quoted
    # -D values: tools/clang_tidy splits a compile command on spaces and a
    # quoted define does not survive it (shell/version/version.cc opts out
    # of the linter for that reason); a generated file is not linted at all,
    # as GN's is not.
    location_source = "_fl_%s.cc" % name
    write_file(
        name = "_fl_%s" % name,
        out = location_source,
        content = [
            "// Generated by flutter_test_fixtures (testing.bzl): the compiled-in",
            "// default locations of %s's fixtures." % name,
            "namespace flutter { namespace testing {",
            'const char* GetCompiledInSourcePath() {return "%s";}' % _SOURCE_DIR,
            'const char* GetCompiledInFixturesPath() {return "%s";}' % fixtures_dir,
            'const char* GetCompiledInTestingAssetsPath() {return "%s";}' % _TESTING_ASSETS_DIR,
            'const char* GetCompiledInSourceUriPrefix() {return "%s";}' % _SOURCE_URI_PREFIX,
            "}}",
        ],
        testonly = True,
        visibility = ["//visibility:private"],
    )

    cc_library(
        name = name,
        testonly = True,
        srcs = [location_source],
        data = copies + deps,
        # The functions are referenced from testing.cc, which sits in an
        # archive linked before this one; make sure the object is kept.
        alwayslink = True,
        visibility = visibility,
        deps = ["//engine/src/flutter/testing:testing_core"],
        **kwargs
    )

def flutter_gpu_test_backends(name, visibility = None, **kwargs):
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
      **kwargs: the filegroup's other attributes (target_compatible_with,
        for a target GN defines under a condition).
    """

    # The copies of each OS's files, compatible with that OS alone (a
    # wildcard build on the other skips them; the filegroup selects its
    # own), the manifests' copies shared by name.
    copies = {}
    made = {}
    for os, files in _GPU_TEST_BACKEND_FILES.items():
        copies[os] = []
        for product, file in files.items():
            copies[os].append(file)
            if file in made:
                continue
            made[file] = True
            copy_file(
                name = "_gb_%s_%s" % (name, product),
                src = "%s:%s" % (_GPU_TEST_BACKENDS_PACKAGE, product),
                out = file,
                allow_symlink = True,
                visibility = ["//visibility:private"],
                target_compatible_with = [] if product in _GPU_TEST_BACKEND_MANIFESTS else [os],
            )
    native.filegroup(
        name = name,
        srcs = select(copies | {"//conditions:default": []}),
        visibility = visibility,
        **kwargs
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
# Suites under gtest-parallel, as run_tests.py runs them
# ---------------------------------------------------------------------------

# testing/run_tests.py runs every suite of its run_cc_tests list through
# gtest-parallel (flutter/third_party/gtest-parallel, @gtest_parallel): the
# runner lists the suite's tests and runs each in a process of its own,
# every test twice (--repeat=2), on as many workers as the machine has
# cores. Here the same runner, under the synced Python, through
# testing/gtest_parallel_run.sh, which adds the repeat and translates
# Bazel's sharding and output conventions.
#
# run_tests.py runs the suites one after another, each with the whole
# machine; Bazel runs tests side by side, and twenty-seven suites each
# starting a worker per core thrash (a 50 ms test took 5 s, and the
# display-list suite ran past its timeout). Each suite therefore gets a
# budget Bazel schedules by -- the `cpu:N` tag reserves N of the local
# CPUs -- and the runner the same N workers: the same per-test processes and
# repeats as run_tests.py's, three suites at a time on a 24-core host rather
# than one.
_GTEST_PARALLEL_WORKERS = 8

_GTEST_PARALLEL_ATTRS = {
    "runner_args": attr.string_list(
        doc = "gtest-parallel's own options (run_tests.py's --timeout=90 for ui_unittests), ahead of the " +
              "binary; `args` are the binary's, after `--`.",
    ),
    "_gtest_parallel_wrapper": attr.label(
        default = "//engine/src/flutter/testing:gtest_parallel_run.sh",
        allow_single_file = True,
    ),
    "_gtest_parallel": attr.label(
        default = "@gtest_parallel//:gtest_parallel",
        allow_files = True,
    ),
    "_python": attr.label(
        default = "@cpython3//:bin/python3",
        allow_single_file = True,
        executable = True,
        cfg = "exec",
    ),
    "_python_runtime": attr.label(default = "@cpython3//:runtime"),
}

def _gtest_parallel_words(ctx):
    """The launcher's words ahead of the binary -- the wrapper, Python, the runner, its options -- and their runfiles."""
    runner = [f for f in ctx.files._gtest_parallel if f.basename == "gtest-parallel"]
    if len(runner) != 1:
        fail("%s: @gtest_parallel//:gtest_parallel should hold the gtest-parallel script" % ctx.label)
    words = [ctx.file._gtest_parallel_wrapper.short_path, ctx.file._python.short_path, runner[0].short_path] + ctx.attr.runner_args
    runfiles = ctx.runfiles(
        files = [ctx.file._gtest_parallel_wrapper, ctx.file._python] + ctx.files._gtest_parallel,
        transitive_files = ctx.attr._python_runtime[DefaultInfo].files,
    )
    return words, runfiles

def _launcher_line(words, prologue = []):
    # The prologue's lines (the sanitizer environment of a sanitized build,
    # build_defs/cc/sanitizers.bzl), then one `exec` line: the words quoted,
    # then the test's own arguments.
    return "#!/bin/bash\n" + "".join([line + "\n" for line in prologue]) + "exec " + " ".join(["'" + w.replace("'", "'\\''") + "'" for w in words]) + " \"$@\"\n"

def _gtest_parallel_test_impl(ctx):
    launcher = ctx.actions.declare_file(ctx.label.name + ".sh")
    words, runfiles = _gtest_parallel_words(ctx)
    prologue, sanitizer_runfiles = sanitizer_launcher_lines(ctx)
    ctx.actions.write(
        output = launcher,
        content = _launcher_line(words + [ctx.executable.binary.short_path, "--"], prologue),
        is_executable = True,
    )
    runfiles = runfiles.merge(sanitizer_runfiles)
    runfiles = runfiles.merge(ctx.runfiles(files = [ctx.executable.binary] + ctx.files.data))
    runfiles = runfiles.merge(ctx.attr.binary[DefaultInfo].default_runfiles)
    for target in ctx.attr.data:
        runfiles = runfiles.merge(target[DefaultInfo].default_runfiles)
    return [
        DefaultInfo(executable = launcher, runfiles = runfiles),
        RunEnvironmentInfo(environment = dict(ctx.attr.env)),
    ]

_gtest_parallel_test = rule(
    implementation = _gtest_parallel_test_impl,
    test = True,
    doc = "Runs a googletest binary through gtest-parallel as testing/run_tests.py does: a process per test, " +
          "every test twice.",
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
            doc = "Environment of the test (run_tests.py's extra_env).",
        ),
    } | _GTEST_PARALLEL_ATTRS | SANITIZER_ATTRS,
)

def flutter_cc_test(name, size = None, timeout = None, shard_count = None, flaky = None, args = [], runner_args = [], data = [], env = {}, tags = [], visibility = None, **kwargs):
    """A googletest suite of the engine, run as testing/run_tests.py runs it: through gtest-parallel.

    The binary is a cc_binary (`<name>_binary`, in this package, so that the
    GPU test backends copied beside it are found) and the test target runs
    it through gtest-parallel: each test in a process of its own, every
    test twice (--repeat=2), a worker per core -- run_tests.py's
    run_cc_tests, where every engine suite passes through the runner with
    those flags. A test that leaks state into its process or fails the
    second time round fails here as it does there.

    Args:
      name: name of the test; the binary is `<name>_binary`.
      size: the test's size.
      timeout: the test's timeout.
      shard_count: the test's shards, which gtest-parallel splits
        (--shard_count/--shard_index from Bazel's variables).
      flaky: the test's flaky attribute.
      args: arguments of the binary (after gtest-parallel's `--`).
      runner_args: gtest-parallel's own options (`--timeout=90`).
      data: runfiles of the test.
      env: environment of the test.
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
    _gtest_parallel_test(
        name = name,
        binary = ":" + name + "_binary",
        size = size,
        timeout = timeout,
        shard_count = shard_count,
        flaky = flaky,
        args = args,
        runner_args = _gtest_parallel_runner_args(runner_args),
        data = data,
        env = env,
        tags = _gtest_parallel_tags(tags),
        visibility = visibility,
    )

def _gtest_parallel_runner_args(runner_args):
    return ["--workers=%d" % _GTEST_PARALLEL_WORKERS] + runner_args

def _gtest_parallel_tags(tags):
    return tags + ["cpu:%d" % _GTEST_PARALLEL_WORKERS]

# ---------------------------------------------------------------------------
# Suites that open a window
# ---------------------------------------------------------------------------

def _display_test_impl(ctx):
    # The test's working directory is the runfiles tree's main repository,
    # under `bazel test` and `bazel run` alike, so short paths resolve as
    # they are.
    launcher = ctx.actions.declare_file(ctx.label.name + ".sh")
    words = [ctx.file._wrapper.short_path]
    runfiles = ctx.runfiles(files = [ctx.file._wrapper, ctx.executable.binary] + ctx.files.data)
    if ctx.attr.gtest_parallel:
        # Under the display, gtest-parallel and its processes (run_tests.py
        # starts its Xvfb around the whole run).
        gtest_parallel_words, gtest_parallel_runfiles = _gtest_parallel_words(ctx)
        words += gtest_parallel_words + [ctx.executable.binary.short_path, "--"]
        runfiles = runfiles.merge(gtest_parallel_runfiles)
    else:
        words.append(ctx.executable.binary.short_path)
    prologue, sanitizer_runfiles = sanitizer_launcher_lines(ctx)
    ctx.actions.write(
        output = launcher,
        content = _launcher_line(words, prologue),
        is_executable = True,
    )
    runfiles = runfiles.merge(sanitizer_runfiles)
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
    if ctx.attr.session_bus:
        # The wrapper starts a D-Bus session bus for the binary unless the
        # environment has one (see xvfb_run.sh).
        env["FLUTTER_TEST_SESSION_BUS"] = "1"
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
        "session_bus": attr.bool(
            doc = "Run the binary under a D-Bus session bus of its own (dbus-run-session) unless the environment " +
                  "has one: what GTK's accessibility bridge needs, and what run_tests.py's run inherits from the " +
                  "session it runs in.",
        ),
        "gtest_parallel": attr.bool(
            doc = "Run the binary through gtest-parallel under the display, as run_tests.py runs the suites of its " +
                  "run_cc_tests list (the Linux shell's); the Impeller suites run whole.",
        ),
        "_wrapper": attr.label(
            default = "//engine/src/flutter/testing:xvfb_run.sh",
            allow_single_file = True,
        ),
    } | _GTEST_PARALLEL_ATTRS | SANITIZER_ATTRS,
)

def flutter_display_test(name, size = None, timeout = None, shard_count = None, flaky = None, args = [], runner_args = [], data = [], env = {}, vulkan_validation = True, session_bus = False, gtest_parallel = False, tags = [], visibility = None, **kwargs):
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
        runs its share of the suite's tests (with `gtest_parallel`, the
        runner splits the suite instead).
      flaky: the test's flaky attribute.
      args: arguments of the binary.
      runner_args: gtest-parallel's own options, with `gtest_parallel`.
      data: runfiles of the test.
      env: environment of the test.
      vulkan_validation: run_tests.py's vulkan_validation_env: SwiftShader as
        the ICD and the Khronos validation layer, from the GPU test backends
        copied into this package (the suite must list them as data).
      session_bus: a D-Bus session bus of the test's own unless the
        environment has one (GTK's accessibility bridge needs it; see
        xvfb_run.sh).
      gtest_parallel: run the binary through gtest-parallel under the
        display, as flutter_cc_test does without one: run_tests.py's
        run_cc_tests suites (the Linux shell's); the Impeller suites, which
        their builder runs whole, keep the default.
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
        runner_args = _gtest_parallel_runner_args(runner_args) if gtest_parallel else runner_args,
        data = data,
        env = env,
        vulkan_validation = vulkan_validation,
        session_bus = session_bus,
        gtest_parallel = gtest_parallel,
        tags = _gtest_parallel_tags(tags) if gtest_parallel else tags,
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
{sanitizers}build_dir="${{TEST_TMPDIR:-${{TMPDIR:-/tmp}}}}/flutter_build_directory"
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
command=("$runfiles/{tester}" "$@" "${{options[@]}}" \\
  --use-test-fonts \\
  "--icu-data-file-path=$runfiles/{icu_data}" \\
  "--flutter-assets-dir=$runfiles/{assets_dir}" \\
  --disable-asset-fonts \\
  "$runfiles/{kernel}")
# run_tests.py's forbidden_output: strings the run's output (stdout and
# stderr together) must not contain, checked once the run has passed.
forbidden=({forbidden})
if [[ "{must_fail}" != 1 && "${{#forbidden[@]}}" -eq 0 ]]; then
  exec "${{command[@]}}"
fi
log="$build_dir/{name}.log"
set +e
"${{command[@]}}" >"$log" 2>&1
status=$?
set -e
cat "$log"
if [[ "{must_fail}" != 1 ]]; then
  if [[ "$status" -ne 0 ]]; then
    exit "$status"
  fi
  for string in "${{forbidden[@]}}"; do
    if grep -qF -- "$string" "$log"; then
      echo "flutter_tester_test: the output of {kernel} contained the forbidden string \\"$string\\":" >&2
      grep -F -- "$string" "$log" >&2
      exit 1
    fi
  done
  exit 0
fi
# A test that must fail (run_tests.py's smoke test, fail_test.dart): the
# runner has to exit non-zero and report a failed test -- not fall over
# before running one.
if [[ "$status" -eq 0 ]]; then
  echo "flutter_tester_test: {kernel} was expected to fail and passed" >&2
  exit 1
fi
if ! grep -q "Some tests failed." "$log"; then
  echo "flutter_tester_test: {kernel} exited with status $status without the test runner reporting a failed test" >&2
  exit 1
fi
echo "flutter_tester_test: {kernel} failed as expected (status $status)" >&2
"""

def _shell_quoted(strings):
    return " ".join(["'" + s.replace("'", "'\\''") + "'" for s in strings])

def _flutter_tester_test_impl(ctx):
    launcher = ctx.actions.declare_file(ctx.label.name + ".sh")
    assets_dir = paths.join(ctx.attr.assets.label.package, "assets")
    prologue, sanitizer_runfiles = sanitizer_launcher_lines(ctx)
    ctx.actions.write(
        output = launcher,
        content = _TESTER_LAUNCHER.format(
            name = ctx.label.name,
            kernel = ctx.file.kernel.short_path,
            tester = ctx.executable.tester.short_path,
            source = ctx.file.source.short_path,
            icu_data = ctx.file.icu_data.short_path,
            assets_dir = assets_dir,
            must_fail = "1" if ctx.attr.must_fail else "0",
            forbidden = _shell_quoted(ctx.attr.forbidden_output),
            sanitizers = "".join([line + "\n" for line in prologue]),
        ),
        is_executable = True,
    )
    runfiles = ctx.runfiles(
        files = [ctx.file.kernel, ctx.file.source, ctx.file.icu_data, ctx.executable.tester] + ctx.files.data,
    )
    runfiles = runfiles.merge(sanitizer_runfiles)
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
        "must_fail": attr.bool(
            doc = "The test passes when the runner exits non-zero reporting a failed test (run_tests.py's smoke test, " +
                  "whose expect_failure only tolerates the failure).",
        ),
        "forbidden_output": attr.string_list(
            doc = "Strings the run's output must not contain (run_tests.py's forbidden_output: `[ERROR` in an " +
                  "optimized build directory), checked once the run has passed.",
        ),
    } | SANITIZER_ATTRS,
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
        variants = None,
        must_fail = False,
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
        --profile-microtasks. run_tests.py skips these tests in a build
        directory with `release` in its name; here they are incompatible in
        the jit_release and release modes, which a wildcard or suite run
        skips.
      srcs: Dart sources of other packages of this repository the tests
        import (skia_gold_client's, lib/gpu's), besides this package's.
      package_roots: dart_package_root targets with the packages the tests
        import from other repositories (package:test and what it reaches).
      data: runfiles every test needs besides the runner's (the fonts of
        //flutter/txt's fixtures; spawn_helper's kernel at the root).
      tester: the runner.
      tester_opengles: the runner of the OpenGL ES variants.
      variants: the variants to run, by suffix (`skia`, `skia_mt`, `vulkan`,
        `vulkan_mt`, `opengles`); all of them by default. run_tests.py runs
        its smoke test in two alone.
      must_fail: the tests must fail (flutter_tester_test's must_fail):
        run_tests.py's smoke test, fail_test.dart. Such a run is also exempt
        from the forbidden-output rule below, as under run_tests.py.
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
        selected = [
            (suffix, backend, multithreaded, True)
            for suffix, backend, multithreaded in _TESTER_VARIANTS
            if variants == None or suffix in variants
        ]
        if test == "gpu_test.dart":
            # Once more with Impeller but without Flutter GPU, for the
            # "Flutter GPU must be enabled" error.
            selected += [("vulkan_no_flutter_gpu", "vulkan", False, False), ("opengles_no_flutter_gpu", "opengles", False, False)]
        for suffix, backend, multithreaded, flutter_gpu in selected:
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
                must_fail = must_fail,
                # run_tests.py: `[] if 'unopt' in build_dir or expect_failure
                # else ['[ERROR']` -- an optimized build's runs must not log
                # an error.
                forbidden_output = [] if must_fail else select({
                    "//engine/src/flutter/build/bazel:optimized": ["[ERROR"],
                    "//conditions:default": [],
                }),
                size = size,
                tags = tags,
                target_compatible_with = select({mode: ["@platforms//:incompatible"] for mode in _RELEASE_MODES} | {"//conditions:default": []}) if vm_service else [],
                visibility = ["//visibility:private"],
            )
            all_tests.append(":" + test_name)
    native.test_suite(
        name = name,
        tests = all_tests,
        visibility = visibility,
    )
