# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""An Xcode project's XCTest run on an iOS simulator against GN's build directory: run_tests.py --type objc.

run_tests.py's --type objc runs the iOS embedding's Objective-C unit tests.
flutter/testing/ios/IosUnitTests is an Xcode project: an app and its test
bundle, whose one source of the tree
(shell/platform/darwin/common/framework/Source/FlutterChannelsTest.m) links
the engine build's XCTest library -- libios_test_flutter.dylib, which holds
the suites of shell/platform/darwin/ios -- OCMock's dylib and
Flutter.framework, and embeds the three; the project reads them out of
`engine/src/out/$FLUTTER_ENGINE`, and its headers out of the checkout
(`../../../..` is engine/src, OCMock's `Source` directory a system header
path). The script creates a simulator (`xcrun simctl create
IosUnitTestsSimulator com.apple.CoreSimulator.SimDeviceType.iPhone-11`),
runs `xcodebuild -sdk iphonesimulator -scheme IosUnitTests
-resultBundlePath <tmp>/ios_embedding -destination id=<simulator> test
FLUTTER_ENGINE=<variant>` in the project's directory, zips the xcresult
bundle into FLUTTER_TEST_OUTPUTS_DIR when the tests fail, and deletes the
simulator.

ios_xctest runs a project the same way, in a writable view of a runfiles
tree shaped like the checkout (checkout_view.bzl): the project's directory a
copy, the tree's files it compiles and includes (`data`) at their paths
beside it, GN's build directory for the mode holding the `engine` targets'
products where GN's build writes them (build_directory.bzl: the dylibs at
the root, Flutter.framework's files under the bundle), and an external
repository's files where a GN checkout has them (`tree`: OCMock's headers
under flutter/third_party/ocmock). The build directory is copied into the
view rather than reached through the runfiles' symlinks: Xcode embeds the
framework and the dylibs into the app by copying them, and code-signs the
copies, which wants the bundle's files to be files, as GN's are. xcodebuild
builds under TEST_TMPDIR (-derivedDataPath; the script leaves Xcode's
default, ~/Library/Developer/Xcode/DerivedData), and the xcresult bundle of
a failed run goes to the test's undeclared outputs, zipped as the script
zips it.

The run is as hermetic as the script's, which is to say not: xcodebuild
and simctl are the machine's Xcode, and the simulator is a device of the
user's CoreSimulator, kept under ~/Library/Developer/CoreSimulator -- the
launcher restores the real home for them (the view's HOME under TEST_TMPDIR
is for the tests that write caches). The macro tags the test local (no
sandbox, no remote execution) and exclusive: the script names its simulator
fixedly and deletes a leaked one of the name before creating its own, and
so does this; two runs at once would take each other's device.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load(
    "//build_defs/config:checkout_view.bzl",
    "ENGINE_SRC",
    "build_directory_attrs",
    "build_directory_variant",
    "checkout_view_prologue",
)
load("//build_defs/gn:build_directory.bzl", "build_directory_aspect", "collected_build_directory_entries")

# run_tests.py's simulator: its name and device type (run_objc_tests).
SIMULATOR_NAME = "IosUnitTestsSimulator"
SIMULATOR_DEVICE_TYPE = "com.apple.CoreSimulator.SimDeviceType.iPhone-11"

def _path_in_repository(file):
    """A file's path within its repository: its short path less the `../<repository>/` of an external one."""
    short_path = file.short_path
    if short_path.startswith("../"):
        return short_path.split("/", 2)[2]
    return short_path

def _shell_quote(word):
    return "'" + word.replace("'", "'\\''") + "'"

def _ios_xctest_impl(ctx):
    project = ctx.file.project
    package = ctx.label.package
    xcodeproj = paths.dirname(project.short_path)
    directory = paths.dirname(xcodeproj)
    if project.basename != "project.pbxproj" or not xcodeproj.endswith(".xcodeproj"):
        fail("%s: the project %s should be an .xcodeproj's project.pbxproj" % (ctx.label, project.short_path))
    if directory != package and not directory.startswith(package + "/"):
        fail("%s: the project %s should be a file of this package" % (ctx.label, project.short_path))

    # GN's build directory of the view: the engine targets' products at
    # their paths under it, each path once.
    variant = build_directory_variant(ctx)
    build_directory = paths.join(ENGINE_SRC, "out", variant)
    symlinks = {}
    placed = {}
    for target in ctx.attr.engine:
        for file, path in collected_build_directory_entries(target):
            if path in placed:
                if placed[path] != file:
                    fail("%s: %s and %s both land as %s of the build directory" % (ctx.label, placed[path].short_path, file.short_path, path))
                continue
            placed[path] = file
            symlinks[paths.join(build_directory, path)] = file
    for target, under in ctx.attr.tree.items():
        for file in target[DefaultInfo].files.to_list():
            symlinks[paths.join(ENGINE_SRC, under.strip("/"), _path_in_repository(file))] = file

    words = [
        "xcodebuild",
        "-sdk",
        "iphonesimulator",
        "-scheme",
        _shell_quote(ctx.attr.scheme),
        "-derivedDataPath",
        '"$TEST_TMPDIR/derived"',
        "-resultBundlePath",
        '"$result/ios_embedding"',
        "-destination",
        '"id=$simulator"',
    ] + [_shell_quote(arg) for arg in ctx.attr.xcodebuild_args] + [
        "test",
        "FLUTTER_ENGINE=" + _shell_quote(variant),
    ]
    create = ["xcrun", "simctl", "create", _shell_quote(ctx.attr.simulator_name), _shell_quote(ctx.attr.device_type)]
    if ctx.attr.runtime:
        create.append(_shell_quote(ctx.attr.runtime))

    launcher = ctx.actions.declare_file(ctx.label.name + ".launcher.sh")
    ctx.actions.write(
        output = launcher,
        content = checkout_view_prologue(directory, build_directory) + """
# The build directory as files, not the runfiles' symlinks to them: Xcode
# copies the framework and the dylibs into the app and signs the copies.
rm -f "$tree/{engine_src}/out"
mkdir -p "$tree/{engine_src}/out"
cp -RL "$root/{build_directory}" "$FLUTTER_BUILD_DIRECTORY"
chmod -R u+w "$FLUTTER_BUILD_DIRECTORY"
# simctl's devices and xcodebuild's caches are the user's, under the real
# home (the prologue's is under TEST_TMPDIR).
export HOME="$(eval echo "~$(id -un)")"
# A simulator left by a run that was killed, then this run's; deleted at
# exit, as run_tests.py deletes its own.
xcrun simctl delete {simulator_name} >/dev/null 2>&1 || true
simulator="$({create})"
trap 'xcrun simctl delete "$simulator" >/dev/null 2>&1 || true' EXIT
result="$TEST_TMPDIR/result"
mkdir -p "$result"
status=0
{xcodebuild} "$@" || status=$?
if [ "$status" != 0 ] && [ -d "$result/ios_embedding.xcresult" ] && [ -n "${{TEST_UNDECLARED_OUTPUTS_DIR:-}}" ]; then
  (cd "$result/ios_embedding.xcresult" && zip -qr "$TEST_UNDECLARED_OUTPUTS_DIR/ios_embedding.xcresult.zip" .)
fi
exit "$status"
""".format(
            engine_src = ENGINE_SRC,
            build_directory = build_directory,
            simulator_name = _shell_quote(ctx.attr.simulator_name),
            create = " ".join(create),
            xcodebuild = " ".join(words),
        ),
        is_executable = True,
    )

    runfiles = ctx.runfiles(
        files = [project] + ctx.files.srcs + ctx.files.data,
        symlinks = symlinks,
    )
    for target in ctx.attr.data + ctx.attr.engine:
        runfiles = runfiles.merge(target[DefaultInfo].default_runfiles)
    return [
        DefaultInfo(executable = launcher, runfiles = runfiles),
        RunEnvironmentInfo(environment = dict(ctx.attr.env)),
    ]

_ios_xctest_test = rule(
    implementation = _ios_xctest_impl,
    test = True,
    doc = "An Xcode project's XCTest run on an iOS simulator, in a writable view of a checkout-shaped runfiles " +
          "tree, against GN's build directory for the mode.",
    attrs = {
        "project": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The project's project.pbxproj, a file of this package; the .xcodeproj's directory is " +
                  "xcodebuild's working directory and the view's writable copy.",
        ),
        "scheme": attr.string(
            mandatory = True,
            doc = "The scheme xcodebuild tests.",
        ),
        "srcs": attr.label_list(
            allow_files = True,
            doc = "The project directory's files: every file by default.",
        ),
        "data": attr.label_list(
            allow_files = True,
            doc = "What the project compiles and includes out of the tree.",
        ),
        "engine": attr.label_list(
            aspects = [build_directory_aspect],
            doc = "The engine targets whose products the project reads out of the build directory, each where " +
                  "GN's build writes it (BuildDirectoryInfo over the target's closure; a shared library at the root).",
        ),
        "tree": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "An external repository's files the project reads, mapped to the directory under engine/src " +
                  "where a GN checkout has the repository (`@ocmock//:headers` to flutter/third_party/ocmock); " +
                  "each file goes at its path within the repository under it.",
        ),
        "xcodebuild_args": attr.string_list(
            doc = "Further xcodebuild options, before the `test` action.",
        ),
        "simulator_name": attr.string(
            default = SIMULATOR_NAME,
            doc = "The simulator's name: run_tests.py's. A leaked one of the name is deleted first.",
        ),
        "device_type": attr.string(
            default = SIMULATOR_DEVICE_TYPE,
            doc = "The simulator's device type: run_tests.py's iPhone 11.",
        ),
        "runtime": attr.string(
            doc = "The simulator's runtime (run_tests.py's --ios-runtime); Xcode's default when empty.",
        ),
        "env": attr.string_dict(
            doc = "Further environment variables for the run.",
        ),
        "build_directory_name": attr.string(
            mandatory = True,
            doc = "GN's name for the build directory of this configuration, up to the mode and the simulator " +
                  "(ios_debug, ios_debug_sim): build_directory_attrs().",
        ),
        "build_directory_cpu": attr.string(
            doc = "The CPU suffix of GN's name for the build directory, after _unopt (`_arm64`, or nothing): " +
                  "build_directory_attrs().",
        ),
        "optimized": attr.bool(
            doc = "Whether this is an optimized build; GN's name carries _unopt otherwise: build_directory_attrs().",
        ),
    },
)

def ios_xctest(name, project, scheme, srcs = None, size = "large", tags = [], **kwargs):
    """An Xcode project's XCTest run on an iOS simulator, as run_tests.py --type objc runs it.

    Args:
      name: the target's name.
      project: the project's project.pbxproj, a file of this package.
      scheme: the scheme xcodebuild tests.
      srcs: the project directory's files; every file of the package by default.
      size: large by default: xcodebuild builds the app and boots a simulator.
      tags: the test's tags; local and exclusive are added (see the file's docstring).
      **kwargs: data, engine, tree, xcodebuild_args, simulator_name, device_type,
        runtime, env, args and the test attributes.
    """
    if srcs == None:
        srcs = native.glob(["**"])
    _ios_xctest_test(
        name = name,
        project = project,
        scheme = scheme,
        srcs = srcs,
        size = size,
        tags = tags + [t for t in ["local", "exclusive"] if t not in tags],
        **(build_directory_attrs() | kwargs)
    )
