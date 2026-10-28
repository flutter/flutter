# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A pure-Dart package's test, compiled by Bazel and run by the stock `dart test` (dart_test).

`dart test` compiles each test file at run time, in the VM. package:test's
runner has a mode that takes the compile as done -- `--precompiled=<dir>`:
for the test file `<dir>/<path>` it loads the kernel
`<dir>/<path>.vm_test.vm.app.dill`, compiled from a bootstrap that hands
the test's main to test_core's `internalBootstrapVmTest`, with the package
configuration `<dir>/.dart_tool/package_config.json` (test_core's
vm/platform.dart). dart_test writes that bootstrap, compiles it with the
frontend server against the Dart SDK's VM platform kernel (kernel.bzl's
compile_to_kernel, `--target=vm`) and a package configuration over the
package's dependency closure (pub.bzl), and runs the stock runner on it
-- its reporters, `--name`, `--plain-name`, tags, shards.

The runner is package:test's own `bin/test.dart`, compiled once to a
kernel by dart_test_runner (//build_defs/dart:test_runner)
and run as `dart --packages=<its configuration> <runner.dill>
--precompiled=<the runfiles tree> <path>`, not the `dart test` command:
that command is dartdev's, which wants a pubspec.yaml in the working
directory and resolves it with pub -- rewriting .dart_tool/package_config.json
-- before it runs the runner. So nothing is compiled at test time, the
runner included.

The test's package configuration (pub_package_config, runfiles layout)
sits at the runfiles tree's `.dart_tool/package_config.json`, where
precompiled mode reads it for the test's isolate. One dart_test per test
file (dart_tests() declares them over a glob); the test runs from the
runfiles tree's root, so a file the test reads is at its repository path.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@host_platform//:host.bzl", "HOST_DART_SDK")
load(
    "//build_defs/dart:kernel.bzl",
    "KERNEL_TOOL_ATTRS",
    "SOURCE_URI_SCHEME",
    "compile_to_kernel",
)
load("//build_defs/dart:pub.bzl", "PubCacheInfo", "PubPackageConfigInfo", "pub_package_config")

# Where test_core's precompiled mode looks for the package configuration.
_PACKAGE_CONFIG = ".dart_tool/package_config.json"

ToolEnvironmentInfo = provider(
    doc = "What a test exports for the programs it runs (dart_test's `tools`): variables naming directories of the runfiles, and others.",
    fields = {
        "directories": "Variable name to the Files (directories) it names, joined with ':' in order, each under the runfiles root " +
                       "(LD_LIBRARY_PATH at the runtime sysroot's libraries for a built app to load; Mesa's LIBGL_DRIVERS_PATH).",
        "values": "Variable name to its value, a string in which `$root` is the runfiles root and `$HOME` the test's own " +
                  "home directory (JAVA_HOME at a repository's root; a file: URL into the runfiles; GRADLE_USER_HOME under " +
                  "$HOME). Optional.",
        "setup": "Shell lines the launcher runs after exporting the variables, before the test (a Gradle home's " +
                 "properties file written under $HOME). Optional.",
    },
)

DartTestRunnerInfo = provider(
    doc = "package:test's runner, compiled to a kernel.",
    fields = {
        "kernel": "File: the runner's kernel.",
        "package_config": "File: the runner's package configuration, runfiles layout.",
    },
)

def _dart_test_runner_impl(ctx):
    mains = [f for f in ctx.files.srcs if f.short_path.endswith("/" + ctx.attr.main)]
    if len(mains) != 1:
        fail("%s: srcs should hold one %s, has %d" % (ctx.label, ctx.attr.main, len(mains)))
    kernel = ctx.actions.declare_file(ctx.label.name + ".dill")
    compile_to_kernel(
        ctx,
        main = mains[0],
        out = kernel,
        srcs = depset(ctx.files.srcs, transitive = [ctx.attr.package_config[PubPackageConfigInfo].sources]),
        package_config = ctx.file.package_config,
        platform = ctx.files._vm_platform,
        target = "vm",
    )
    return [
        DefaultInfo(files = depset([kernel])),
        DartTestRunnerInfo(kernel = kernel, package_config = ctx.file.runtime_package_config),
    ]

dart_test_runner = rule(
    implementation = _dart_test_runner_impl,
    doc = "package:test's runner (bin/test.dart) compiled to a kernel, for dart_test to run tests with.",
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
            doc = "package:test's files (@pub//test:sources).",
        ),
        "main": attr.string(
            default = "bin/test.dart",
            doc = "The runner's entry point among srcs, by its path under the package.",
        ),
        "package_config": attr.label(
            allow_single_file = True,
            mandatory = True,
            providers = [PubPackageConfigInfo],
            doc = "The package configuration for the compile (pub_package_config over `test`, execroot layout).",
        ),
        "runtime_package_config": attr.label(
            allow_single_file = True,
            mandatory = True,
            providers = [PubPackageConfigInfo],
            doc = "The same for the run (runfiles layout).",
        ),
        "_vm_platform": attr.label(
            default = HOST_DART_SDK + "//:vm_platform",
            allow_files = True,
        ),
    } | KERNEL_TOOL_ATTRS,
)

DartTestPreludeInfo = provider(
    doc = "A kernel of the libraries a package's tests share, for their compiles to start from.",
    fields = {"kernel": "File: the prelude's kernel."},
)

def _dart_test_prelude_impl(ctx):
    main = ctx.actions.declare_file(ctx.label.name + ".prelude.dart")
    ctx.actions.write(main, "\n".join([
        "// Generated by dart_test_prelude (build_defs/dart/dart_test.bzl):",
        "// the libraries the tests share, compiled once.",
    ] + ["import '%s';" % uri for uri in ctx.attr.imports] + ["", "void main() {}", ""]))
    kernel = ctx.actions.declare_file(ctx.label.name + ".dill")
    compile_to_kernel(
        ctx,
        main = main,
        out = kernel,
        srcs = depset(
            ctx.files.srcs,
            transitive = [ctx.attr.package_config[PubPackageConfigInfo].sources] +
                         [dep[DefaultInfo].files for dep in ctx.attr.deps],
        ),
        package_config = ctx.file.package_config,
        platform = ctx.files._vm_platform,
        args = ctx.attr.compile_args,
        target = "vm",
    )
    return [
        DefaultInfo(files = depset([kernel])),
        DartTestPreludeInfo(kernel = kernel),
    ]

dart_test_prelude = rule(
    implementation = _dart_test_prelude_impl,
    doc = "The libraries a package's tests share, compiled once for the VM, for their compiles to start from " +
          "(the frontend server's --initialize-from-dill): a tool's whole library in 25 s once rather than per test.",
    attrs = {
        "imports": attr.string_list(
            mandatory = True,
            doc = "The libraries, as the tests import them (`package:flutter_tools/executable.dart`).",
        ),
        "srcs": attr.label_list(
            allow_files = True,
            doc = "Other files the imports reach.",
        ),
        "deps": attr.label_list(
            allow_files = True,
            doc = "Other files the compile may read besides the configuration's packages.",
        ),
        "compile_args": attr.string_list(
            doc = "Further frontend server arguments, the same as the tests'.",
        ),
        "package_config": attr.label(
            allow_single_file = True,
            mandatory = True,
            providers = [PubPackageConfigInfo],
            doc = "The package configuration for the compile (pub_package_config, execroot layout).",
        ),
        "_vm_platform": attr.label(
            default = HOST_DART_SDK + "//:vm_platform",
            allow_files = True,
        ),
    } | KERNEL_TOOL_ATTRS,
)

def _dart_vm_kernel_impl(ctx):
    kernel = ctx.actions.declare_file(ctx.attr.out or ctx.label.name + ".dill")
    compile_to_kernel(
        ctx,
        main = ctx.file.main,
        out = kernel,
        srcs = depset(
            ctx.files.srcs,
            transitive = [ctx.attr.package_config[PubPackageConfigInfo].sources] +
                         [dep[DefaultInfo].files for dep in ctx.attr.deps],
        ),
        package_config = ctx.file.package_config,
        platform = ctx.files._vm_platform,
        args = ctx.attr.compile_args,
        target = "vm",
    )
    return [DefaultInfo(files = depset([kernel]))]

dart_vm_kernel = rule(
    implementation = _dart_vm_kernel_impl,
    doc = "A Dart program compiled for the VM against a pub package configuration: a kernel `dart` runs " +
          "(flutter_tools' entry point as bin/cache/flutter_tools.snapshot in the tests' SDK facsimile; the " +
          "SDK's shell script compiles the same entry point with `dart --snapshot` on the first run).",
    attrs = {
        "main": attr.label(
            allow_single_file = [".dart"],
            mandatory = True,
            doc = "The entry point.",
        ),
        "out": attr.string(
            doc = "The kernel's file name; `<name>.dill` by default.",
        ),
        "srcs": attr.label_list(
            allow_files = True,
            doc = "Other files the entry point reaches.",
        ),
        "deps": attr.label_list(
            allow_files = True,
            doc = "Other files the compile may read besides the configuration's packages.",
        ),
        "compile_args": attr.string_list(
            doc = "Further frontend server arguments.",
        ),
        "package_config": attr.label(
            allow_single_file = True,
            mandatory = True,
            providers = [PubPackageConfigInfo],
            doc = "The package configuration for the compile (pub_package_config, execroot layout).",
        ),
        "_vm_platform": attr.label(
            default = HOST_DART_SDK + "//:vm_platform",
            allow_files = True,
        ),
    } | KERNEL_TOOL_ATTRS,
)

def _dart_test_impl(ctx):
    test = ctx.file.test
    if test.dirname != ctx.label.package and not test.dirname.startswith(ctx.label.package + "/"):
        fail("%s: the test %s must be in this package: the kernel is written beside it" % (ctx.label, test.short_path))

    # test_core's names: `<test>.vm_test.dart` beside the test, its kernel
    # `<test>.vm_test.vm.app.dill` (the `.dart` of the test's name kept).
    relative = test.short_path[len(ctx.label.package) + 1:] if ctx.label.package else test.short_path
    bootstrap = ctx.actions.declare_file(relative + ".vm_test.dart")
    ctx.actions.write(bootstrap, "\n".join([
        "// Generated by dart_test (build_defs/dart/dart_test.bzl):",
        "// %s under `dart test --precompiled`." % test.short_path,
        "import 'dart:isolate';",
        "",
        "import 'package:test_core/src/bootstrap/vm.dart';",
        "",
        "import '%s:///%s' as test;" % (SOURCE_URI_SCHEME, test.path),
        "",
        "void main(List<String> _, SendPort sendPort) {",
        "  internalBootstrapVmTest(() => test.main, sendPort);",
        "}",
        "",
    ]))
    kernel = ctx.actions.declare_file(relative + ".vm_test.vm.app.dill")
    prelude = ctx.attr.prelude[DartTestPreludeInfo].kernel if ctx.attr.prelude else None
    compile_to_kernel(
        ctx,
        main = bootstrap,
        out = kernel,
        srcs = depset(
            [test] + ctx.files.srcs,
            transitive = [ctx.attr.package_config[PubPackageConfigInfo].sources] +
                         [dep[DefaultInfo].files for dep in ctx.attr.deps],
        ),
        package_config = ctx.file.package_config,
        platform = ctx.files._vm_platform,
        args = ctx.attr.compile_args + (
            # Start from the prelude's kernel: the frontend server's
            # incremental mode, initialized from it, reuses its libraries.
            ["--incremental", "--initialize-from-dill", prelude.path] if prelude else []
        ),
        extra_inputs = [prelude] if prelude else [],
        target = "vm",
    )

    dart = [f for f in ctx.files._sdk if f.short_path.endswith("/bin/dart")]
    if len(dart) != 1:
        fail("%s: the SDK should hold one bin/dart" % ctx.label)
    runner = ctx.attr._runner[DartTestRunnerInfo]

    # The working directory: the BUILD file's package, which is the pub
    # package's root when the file sits there (dev/snippets) -- `dart test`
    # runs from the package, and tests read `data/`, `test/fixtures/` relative
    # to it. The kernel sits beside the test, so --precompiled is the same
    # directory.
    # The programs the test runs by name (`tools`): their directories first
    # on PATH, and the variables they ask the test to export.
    tool_directories = []
    tool_variables = {}
    tool_values = {}
    tool_setup = []
    for tool in ctx.attr.tools:
        for file in tool[DefaultInfo].files.to_list():
            directory = paths.dirname(file.short_path)
            if directory not in tool_directories:
                tool_directories.append(directory)
        if ToolEnvironmentInfo in tool:
            for variable, files in tool[ToolEnvironmentInfo].directories.items():
                tool_variables.setdefault(variable, []).extend(files)
            if hasattr(tool[ToolEnvironmentInfo], "values") and tool[ToolEnvironmentInfo].values:
                tool_values |= tool[ToolEnvironmentInfo].values
            if hasattr(tool[ToolEnvironmentInfo], "setup") and tool[ToolEnvironmentInfo].setup:
                tool_setup.extend(tool[ToolEnvironmentInfo].setup)
    tools_env = "".join(["export PATH=\"$root/%s:$PATH\"\n" % directory for directory in tool_directories]) + "".join([
        "export %s=\"%s\"\n" % (variable, ":".join(["$root/" + f.short_path for f in files]))
        for variable, files in tool_variables.items()
    ]) + "".join([
        "export %s=\"%s\"\n" % (variable, value)
        for variable, value in tool_values.items()
    ]) + "".join([line + "\n" for line in tool_setup])

    # An X display of the test's own (`display`, an X server taking
    # -displayfd): started before the test, DISPLAY exported, stopped after
    # -- what xvfb-run does for the tests that run a desktop app.
    if ctx.file.display:
        display_env = """display_files="${{TEST_TMPDIR:-$(mktemp -d)}}/display"
mkdir -p "$display_files"
"$root/{display}" -displayfd 3 -screen 0 1280x800x24 -ac -nolisten tcp 3>"$display_files/number" 2>"$display_files/log" &
display_pid=$!
for _ in $(seq 1 200); do [ -s "$display_files/number" ] && break; sleep 0.1; done
[ -s "$display_files/number" ] || {{ echo "{display} reported no display:" >&2; cat "$display_files/log" >&2; exit 1; }}
export DISPLAY=":$(tr -d '\n' < "$display_files/number")"
trap 'kill "$display_pid" 2>/dev/null' EXIT
""".format(display = ctx.file.display.short_path)
        run = ""
    else:
        display_env = ""
        run = "exec "

    launcher = ctx.actions.declare_file(ctx.label.name + ".launcher.sh")
    ctx.actions.write(
        output = launcher,
        content = """#!/bin/bash
set -euo pipefail
root="$PWD"
# The repository's root, for tests that find it there (flutter_tools' read
# FLUTTER_ROOT before deriving it from the script's path): the runfiles
# tree, whose layout is the repository's.
export FLUTTER_ROOT="$root"
# The temporary directory with its symbolic links resolved, where the host
# names one (a Mac's Bazel passes TMPDIR through: /var/folders/..., and
# /var is /private/var there): the tool resolves the paths it watches
# (PreviewDetector) and a test compares them with the path it created.
# Linux's tests get no TMPDIR and use the sandbox's own /tmp.
if [ -n "${{TMPDIR:-}}" ] && [ -d "$TMPDIR" ]; then export TMPDIR="$(cd "$TMPDIR" && pwd -P)"; fi
# The SDK cache's directory, for a tool under test that writes there
# (Cache.lock opens bin/cache/lockfile); what tests read of it is laid
# in by `cache` and `cache_files`.
mkdir -p "$root/bin/cache"
{pub_cache_env}{tool_env}{browser_env}{tools_env}{display_env}{writable}cd "{package}"
{run}"$root/{dart}" --packages="$root/{runner_config}" "$root/{runner}" --precompiled="$PWD" {args} "{test}" "$@"
""".format(
            tools_env = tools_env,
            display_env = display_env,
            run = run,
            package = ctx.label.package or ".",
            # A pub cache of the rule's own for a test that runs pub (pub_cache),
            # in the runfiles tree; pub writes nothing to it that is already
            # there.
            pub_cache_env = "export PUB_CACHE=\"$root/.pub-cache\"\n" if ctx.attr.pub_cache else "",
            # When the facsimile holds the tool (sdk_files): the SDK's bin on
            # PATH, as a developer's shell has it (integration tests run
            # `flutter` by name), and a home of the test's own for the tool's
            # settings and analytics (`flutter config --enable-...` writes
            # them there; the developer's are not read).
            tool_env = ("export PATH=\"$root/bin:$PATH\"\n" +
                        "export HOME=\"${TEST_TMPDIR:-$(mktemp -d)}/home\"\n" +
                        "mkdir -p \"$HOME\"\n") if [p for p in ctx.attr.sdk_files.values() if p.startswith("bin/")] else "",
            # The browser the test drives, by the variable the tool and the web
            # engine's test runner both read, and its driver's directory on
            # PATH (the web-server device's tests spawn `chromedriver`). A
            # file of another repository lies under `../<repository>/`, which
            # short_path says.
            browser_env = ("export CHROME_EXECUTABLE=\"$root/%s\"\n" % ctx.file.browser.short_path if ctx.file.browser else "") +
                          ("export PATH=\"$root/%s:$PATH\"\n" % paths.dirname(ctx.file.browser_driver.short_path) if ctx.file.browser_driver else ""),
            # Files the tool rewrites in place (pub touches the workspace's
            # lock), copied over their symlinks into the writable runfiles
            # tree so that the source stays as it is -- or whole directories
            # of them (an Xcode project the tool migrates), their trees
            # copied with the links followed.
            writable = "".join([
                # A directory -- or a link to one, the facsimile's engine
                # directories -- is copied beside itself (cp -RL: the links
                # followed, as BSD and GNU cp both have it) and moved into
                # place; a file's real copy is made first, the link removed,
                # the copy made: BSD cp (a Mac's) has no --remove-destination.
                ("if [ -d \"$root/{f}\" ]; then cp -RL \"$root/{f}\" \"$root/{f}.writable\" && rm -rf \"$root/{f}\" && mv \"$root/{f}.writable\" \"$root/{f}\" && chmod -R u+w \"$root/{f}\"; " +
                 "elif [ -L \"$root/{f}\" ]; then real=\"$(readlink -f \"$root/{f}\")\" && rm -f \"$root/{f}\" && cp \"$real\" \"$root/{f}\" && chmod u+w \"$root/{f}\"; fi\n").format(f = f)
                for f in ctx.attr.writable
            ]),
            dart = dart[0].short_path,
            runner_config = runner.package_config.short_path,
            runner = runner.kernel.short_path,
            args = " ".join(ctx.attr.runner_args),
            test = relative,
        ),
        is_executable = True,
    )

    # The SDK cache's paths under FLUTTER_ROOT/bin/cache (as flutter_test lays
    # them): each tree's files at their paths within their repository -- or,
    # for this repository's, within their package -- under the directory
    # named; each file at the path named. sdk_trees the same under
    # FLUTTER_ROOT itself, where the runfiles tree's own files win (a
    # workspace member's pubspec among the data, and again in
    # @pub_workspace).
    runtime = ctx.attr.runtime_package_config
    regular = [kernel, test, runner.kernel, runner.package_config] + ctx.files.data + ctx.files._sdk
    present = {}
    if ctx.attr.sdk_trees:
        present = {file.short_path: True for file in regular + runtime[PubPackageConfigInfo].sources.to_list()}
        for dep in ctx.attr.data:
            for file in dep[DefaultInfo].default_runfiles.files.to_list():
                present[file.short_path] = True
    cache = {}

    def lay(target, directory, unless_present = False):
        for file in target[DefaultInfo].files.to_list():
            path = file.short_path
            if path.startswith("../"):
                path = path.split("/", 2)[2]
            elif target.label.package:
                path = paths.relativize(path, target.label.package)
            path = paths.join(directory, path) if directory else path
            if unless_present and path in present:
                continue
            cache[path] = file

    for target, directory in ctx.attr.cache.items():
        lay(target, paths.join("bin/cache", directory))
    for target, directory in ctx.attr.sdk_trees.items():
        lay(target, directory, unless_present = True)
    for target, path in ctx.attr.cache_files.items():
        files = target[DefaultInfo].files.to_list()
        if len(files) != 1:
            fail("%s: cache_files: %s should be one file" % (ctx.label, target.label))
        cache[paths.join("bin/cache", path)] = files[0]
    for target, path in ctx.attr.sdk_files.items():
        files = target[DefaultInfo].files.to_list()
        if len(files) != 1:
            fail("%s: sdk_files: %s should be one file" % (ctx.label, target.label))
        cache[path] = files[0]
    if ctx.attr.pub_cache:
        for path, file in ctx.attr.pub_cache[PubCacheInfo].entries.items():
            cache[paths.join(".pub-cache", path)] = file
    runfiles = ctx.runfiles(
        files = regular + ctx.files.browser + ctx.files.browser_files + ctx.files.browser_driver + ctx.files.tools + ctx.files.display,
        # The runtime configuration at the package's .dart_tool/, where `dart
        # test --precompiled` reads it from the working directory and a tool
        # under test looks for its own (flutter_tools' template images);
        # pub_package_config writes its root URIs for that location.
        symlinks = {paths.join(ctx.label.package, _PACKAGE_CONFIG): ctx.file.runtime_package_config} | cache,
        # The test's packages, for what it reads of them at run time.
        transitive_files = runtime[PubPackageConfigInfo].sources,
    )
    for dep in ctx.attr.data:
        runfiles = runfiles.merge(dep[DefaultInfo].default_runfiles)

    # A browser_launcher's runfiles: the browser's (or the driver's)
    # directory and the libraries its script puts on LD_LIBRARY_PATH; the
    # tools' and the display's likewise.
    for target in [ctx.attr.browser, ctx.attr.browser_driver, ctx.attr.display] + ctx.attr.tools:
        if target:
            runfiles = runfiles.merge(target[DefaultInfo].default_runfiles)
    return [DefaultInfo(executable = launcher, runfiles = runfiles)]

dart_test = rule(
    implementation = _dart_test_impl,
    test = True,
    doc = "A test file of a pure-Dart package, compiled by the frontend server and run by `dart test --precompiled`.",
    attrs = {
        "test": attr.label(
            allow_single_file = [".dart"],
            mandatory = True,
            doc = "The test file, in this package.",
        ),
        "srcs": attr.label_list(
            allow_files = True,
            doc = "Other files of the test directory it imports (helpers beside it).",
        ),
        "deps": attr.label_list(
            allow_files = True,
            doc = "Other files the compile may read besides the configuration's packages.",
        ),
        "data": attr.label_list(
            allow_files = True,
            doc = "What the test reads at run time, at its repository path under the runfiles root.",
        ),
        "prelude": attr.label(
            providers = [DartTestPreludeInfo],
            doc = "The kernel the compile starts from (dart_test_prelude), compiled with the same " +
                  "configuration and arguments; none compiles the test from scratch.",
        ),
        "cache": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "What the test reads of the Flutter SDK's cache (FLUTTER_ROOT/bin/cache): each " +
                  "target's files, at their paths within their repository (this repository's: within " +
                  "their package), under the directory named (`dart-sdk`); flutter_sdk_cache.bzl.",
        ),
        "pub_cache": attr.label(
            providers = [PubCacheInfo],
            doc = "A pub cache (pub_cache) laid in the runfiles tree as .pub-cache, PUB_CACHE for the " +
                  "test: for a test that resolves a project of its own with the real pub.",
        ),
        "cache_files": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "Single files (or directory artifacts) of the SDK's cache, each at the path named under " +
                  "bin/cache (`engine.stamp`, which the tool's bootstrap writes; `artifacts/engine/linux-x64`, " +
                  "a bundle_directory).",
        ),
        "sdk_files": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "Single files of the SDK laid at the path named under FLUTTER_ROOT in place of the " +
                  "repository's own (`bin/flutter`: a launcher of the tool Bazel compiled, where the " +
                  "repository's script would bootstrap from the network).",
        ),
        "sdk_trees": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "Trees of the SDK laid under the directory named of FLUTTER_ROOT, each target's files " +
                  "at their paths within their repository, as `cache` lays them under bin/cache " +
                  "(`@pub_workspace//:pubspecs` at the root: every workspace member's pubspec, for a " +
                  "test that runs pub in a member).",
        ),
        "browser": attr.label(
            allow_single_file = True,
            doc = "A browser's executable, exported as CHROME_EXECUTABLE: a browser_launcher " +
                  "(//build_defs/web:browser_launcher.bzl; Chrome for Testing at the web engine's pinned version with " +
                  "the build's libraries), or the executable itself with `browser_files` carrying its directory.",
        ),
        "browser_files": attr.label_list(
            allow_files = True,
            doc = "The browser's directory, whole (`@chrome//:chrome`): the executable loads its libraries and " +
                  "resources from beside itself.",
        ),
        "browser_driver": attr.label(
            allow_single_file = True,
            doc = "The browser's WebDriver executable (a browser_launcher of `@chrome//:chromedriver`, " +
                  "or the executable); its directory goes first on PATH, where the web-server device's tests spawn `chromedriver`.",
        ),
        "tools": attr.label_list(
            allow_files = True,
            doc = "Programs the test (or the tool under test) runs by name: each target's files' directories go first " +
                  "on PATH, and a target's ToolEnvironmentInfo is exported (//build_defs/desktop:build_tools.bzl's " +
                  "linux_build_tools: cmake, ninja, pkg-config and the compilers `flutter build linux` runs).",
        ),
        "display": attr.label(
            allow_single_file = True,
            doc = "An X server taking -displayfd (a display_launcher's Xvfb, //build_defs/web:browser_launcher.bzl): " +
                  "started before the test with a screen of its own, DISPLAY exported, stopped after -- for a test " +
                  "that runs a desktop app, as xvfb-run would.",
        ),
        "writable": attr.string_list(
            doc = "Paths under FLUTTER_ROOT the tool under test rewrites in place (`pubspec.lock`: pub " +
                  "touches the workspace's lock when it resolves a member), copied over their runfiles " +
                  "symlinks when the test starts so that the sources stay as they are -- a file, or a whole " +
                  "directory (an Xcode project the tool migrates), its links followed -- which also " +
                  "serves a script that resolves its own symlink to find FLUTTER_ROOT (xcode_backend.sh).",
        ),
        "compile_args": attr.string_list(
            doc = "Further frontend server arguments for the compile.",
        ),
        "runner_args": attr.string_list(
            doc = "Further runner arguments (`--reporter=expanded`), before the test's path; " +
                  "the test's own `args` follow it.",
        ),
        "package_config": attr.label(
            allow_single_file = True,
            mandatory = True,
            providers = [PubPackageConfigInfo],
            doc = "The package configuration for the compile (pub_package_config, execroot layout).",
        ),
        "runtime_package_config": attr.label(
            allow_single_file = True,
            mandatory = True,
            providers = [PubPackageConfigInfo],
            doc = "The package configuration for the run (pub_package_config, runfiles layout, " +
                  "written for `<this package>/.dart_tool/package_config.json`, where the run " +
                  "places it): the test's packages and package:test's.",
        ),
        "_vm_platform": attr.label(
            default = HOST_DART_SDK + "//:vm_platform",
            allow_files = True,
        ),
        # The command-line SDK: `dart` with the snapshots and libraries it loads.
        "_sdk": attr.label(
            default = HOST_DART_SDK + "//:dart",
            allow_files = True,
        ),
        "_runner": attr.label(
            default = "//build_defs/dart:test_runner",
            providers = [DartTestRunnerInfo],
        ),
    } | KERNEL_TOOL_ATTRS,
)

def dart_tests(name, tests, size = "medium", tags = [], network = False, large = [], sizes = {}, flaky = [], cases = {}, unsandboxed = [], runner_args = [], **kwargs):
    """One dart_test per test file, and a test_suite of them.

    Args:
      name: the suite's name.
      tests: the test files (a glob of `*_test.dart`).
      size: each test's size.
      tags: each test's tags.
      network: whether the tests may reach the network; `block-network` otherwise.
      large: test files given the large size (a 15-minute timeout rather
        than medium's 5) whatever `size` says: the few that run the real
        pub or the analyzer over whole projects.
      sizes: test files given a size of their own (`enormous`, an hour:
        create_test, which creates, analyzes and tests some hundred
        projects through the tool).
      flaky: test files Bazel retries (a test with a timeout of its own
        inside, which a loaded machine overruns).
      cases: test files to a regular expression of the cases to run of them
        (`dart test --name`), for a file whose other cases want what the
        host cannot give (the apk cases of two native-asset files: Android's
        artifacts, SDK and Gradle); the rest run whole.
      unsandboxed: test files run outside Bazel's sandbox (`no-sandbox`): the
        tool's Apple builds run xcodebuild, which runs sandbox-exec itself,
        and a sandbox inside the sandbox is refused.
      runner_args: further runner arguments for every file.
      **kwargs: dart_test's attributes, the same for every file.
    """
    test_tags = list(tags) + ([] if network else ["block-network"])
    targets = []
    for test in tests:
        test_name = test.removesuffix(".dart").replace("/", "_")
        dart_test(
            name = test_name,
            test = test,
            size = sizes.get(test, "large" if test in large else size),
            tags = test_tags + (["no-sandbox"] if test in unsandboxed else []),
            flaky = test in flaky,
            runner_args = runner_args + (["--name=" + cases[test]] if test in cases else []),
            **kwargs
        )
        targets.append(":" + test_name)
    native.test_suite(name = name, tests = targets, tags = tags)

def dart_package_tests(
        name,
        package,
        tests,
        srcs = [],
        data = [],
        packages = {},
        roots = [],
        dev_roots = None,
        without = [],
        imports = [],
        compile_args = [],
        **kwargs):
    """A pure-Dart package's tests, from the BUILD file of the package itself: the configurations and one dart_test per file.

    Args:
      name: the suite's name.
      package: the package's name (its pubspec's); its files are this
        package's `sources` filegroup.
      tests: the test files (a glob of `test/**/*_test.dart`).
      srcs: the test tree's other Dart files, which tests import.
      data: what the tests read at run time.
      packages: workspace packages the tests reach besides the package
        itself: each one's files to its name, as pub_package_config takes
        them.
      roots: packages whose dependencies the configurations cover besides
        the package and `test` (whose runner runs the tests).
      dev_roots: packages whose dev dependencies they cover; the package
        itself by default.
      without: packages of the closure left out.
      imports: libraries the tests share, compiled once into a prelude the
        tests' compiles start from (`package:<package>/<package>.dart`);
        none compiles each test from scratch.
      compile_args: further frontend server arguments, for the prelude and
        the tests alike.
      **kwargs: dart_tests' other arguments (size, large, sizes, flaky, cases, unsandboxed, tags,
        network, runner_args, deps, cache, cache_files, sdk_files, sdk_trees, writable, pub_cache,
        browser, browser_files, browser_driver, tools, display).
    """
    workspace_packages = {":sources": package} | packages
    config_roots = [package, "test"] + roots
    config_dev_roots = [package] if dev_roots == None else dev_roots
    pub_package_config(
        name = name + "_package_config",
        out = name + "_package_config.json",
        dev_roots = config_dev_roots,
        packages = workspace_packages,
        roots = config_roots,
        without = without,
    )
    pub_package_config(
        name = name + "_runtime_package_config",
        out = name + "_runtime_package_config.json",
        dev_roots = config_dev_roots,
        layout = "runfiles",
        location = paths.join(native.package_name(), ".dart_tool/package_config.json"),
        packages = workspace_packages,
        roots = config_roots,
        without = without,
    )
    prelude = None
    if imports:
        dart_test_prelude(
            name = name + "_prelude",
            imports = imports,
            compile_args = compile_args,
            package_config = ":" + name + "_package_config",
        )
        prelude = ":" + name + "_prelude"
    dart_tests(
        name = name,
        tests = tests,
        srcs = srcs,
        data = data,
        compile_args = compile_args,
        prelude = prelude,
        package_config = ":" + name + "_package_config",
        runtime_package_config = ":" + name + "_runtime_package_config",
        **kwargs
    )
