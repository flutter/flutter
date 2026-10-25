# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The web engine's unit tests (lib/web_ui/test) compiled as felt compiles them.

felt (lib/web_ui/dev) compiles every `*_test.dart` of a test set
(`lib/web_ui/test/<set>/`) for a bundle's compile configuration --
dart2js or dart2wasm, CanvasKit or skwasm (lib/web_ui/test/felt_config.yaml,
dev/steps/compile_bundle_step.dart) -- into
`out/web_tests/test_bundles/<bundle>/<rel>.browser_test.dart.{js,wasm}`, with
a `results.json` naming the files that compiled, and its run step serves the
bundle's directory to the browser. The tests import `package:ui` (the package
lib/web_ui is) and never `dart:ui`, so the compile is the stock Dart SDK's
over a pub package configuration: no platform dill, no engine build.

web_ui_test_bundle compiles one test file for one compile configuration, as
one action, into a directory shaped as the bundle's: the file's output
beside a results.json of that one file, which felt's run step reads as it
reads the whole bundle's. web_ui_test runs that file through felt's own run
step -- felt compiled for the VM and placed where felt.dart lives, so that
its path derivation holds: the bundle and the artifacts felt's copy step
would make (CanvasKit, skwasm and flutter.js from the web SDK's archive,
the fonts, Skia's test images, the host page) lie at engine/src/out/web_tests
in the runfiles, and Chrome is the pinned @chrome (browsers.bzl) --
`felt test --run --suite=<suite>` with the file as the bundle's one result.
No network: felt's Skia Gold client finds Gold unreachable and the goldens
compare nothing, as for a developer offline; CI's Gold runs stay felt's.
"""

load("//build_defs/dart:pub.bzl", "PubPackageConfigInfo")
load("//build_defs/dist:zip_bundle.bzl", "ZipBundleInfo")

# felt_config.yaml's compile-configs: the compiler and the renderer each
# names, as the -D defines the compile passes (FLUTTER_WEB_USE_SKIA,
# FLUTTER_WEB_USE_SKWASM: lib/src/engine/configuration.dart).
COMPILE_CONFIGS = {
    "dart2js-canvaskit": struct(compiler = "dart2js", renderer = "canvaskit"),
    "dart2wasm-canvaskit": struct(compiler = "dart2wasm", renderer = "canvaskit"),
    "dart2wasm-skwasm": struct(compiler = "dart2wasm", renderer = "skwasm"),
}

WebUiTestBundleInfo = provider(
    doc = "One test file compiled for one of felt's bundles.",
    fields = {
        "directory": "File: the bundle-shaped directory (a tree artifact) holding the compiled test and results.json.",
        "bundle": "string: felt's bundle name (felt_config.yaml's test-bundles).",
        "test_set": "string: the test set's directory under lib/web_ui/test.",
        "relative": "string: the test file's path within the test set.",
    },
)

def _resources(_os, _inputs):
    # dart2js and dart2wasm each hold the whole engine in memory.
    return {"cpu": 1, "memory": 2500}

def _compile_command(config, dart, sdk_root, package_config, test, out, relative):
    """felt's compile command for one configuration (compile_bundle_step.dart), and its output."""
    defines = [
        "-DFLUTTER_WEB_USE_SKIA=%s" % ("true" if config.renderer == "canvaskit" else "false"),
        "-DFLUTTER_WEB_USE_SKWASM=%s" % ("true" if config.renderer == "skwasm" else "false"),
    ]
    if config.compiler == "dart2js":
        target = "%s/%s.browser_test.dart.js" % (out.path, relative)
        return target, [
            dart.path,
            "compile",
            "js",
            "--packages=" + package_config.path,
            "--no-minify",
            "--disable-inlining",
            "--enable-asserts",
        ] + defines + ["-O2", "-o", target, test.path]
    target = "%s/%s.browser_test.dart.wasm" % (out.path, relative)
    return target, [
        sdk_root + "/bin/dartaotruntime",
        sdk_root + "/bin/snapshots/dart2wasm_product.snapshot",
        "--libraries-spec=" + sdk_root + "/lib/libraries.json",
        "--packages=" + package_config.path,
        "--enable-asserts",
        "--enable-experimental-ffi",
        "--enable-experimental-wasm-interop",
    ] + defines + ([
        "--import-shared-memory",
        "--shared-memory-max-pages=32768",
    ] if config.renderer == "skwasm" else []) + [test.path, target]

def _web_ui_test_bundle_impl(ctx):
    test = ctx.file.test
    configs = [COMPILE_CONFIGS[name] for name in ctx.attr.compile_configs]
    set_root = "%s/test/%s" % (ctx.label.package, ctx.attr.test_set)
    if not test.path.startswith(set_root + "/"):
        fail("%s: %s is not under %s" % (ctx.label, test.path, set_root))
    relative = test.path[len(set_root) + 1:]
    out = ctx.actions.declare_directory(ctx.label.name)
    sdk = ctx.attr._sdk[DefaultInfo].files
    dart = [f for f in sdk.to_list() if f.short_path.endswith("/bin/dart")][0]
    sdk_root = dart.path[:-len("/bin/dart")]
    package_config = ctx.file.package_config

    # One compile per configuration into the same directory (the fallbacks
    # bundle holds a file's dart2wasm and dart2js outputs side by side).
    script = ["set -e"]
    for config in configs:
        target, command = _compile_command(config, dart, sdk_root, package_config, test, out, relative)
        script.append("mkdir -p \"$(dirname '%s')\"" % target)
        script.append(" ".join(["'%s'" % part for part in command]))
    results = json.encode_indent({
        "name": ctx.attr.bundle,
        "directory": ctx.attr.test_set,
        "builds": [{"compiler": config.compiler, "renderer": config.renderer} for config in configs],
        "results": {relative: "success"},
    }, indent = "  ")
    script.append("cat > '%s/results.json' <<'EOF'\n%s\nEOF" % (out.path, results))
    ctx.actions.run_shell(
        command = "\n".join(script) + "\n",
        inputs = depset(
            [test, package_config] + ctx.files.srcs,
            transitive = [sdk, ctx.attr.package_config[PubPackageConfigInfo].sources],
        ),
        outputs = [out],
        mnemonic = "WebUiTestCompile",
        progress_message = "Compiling %s for %s" % (relative, ctx.attr.bundle),
        resource_set = _resources,
        # The compilers write their caches and temporary files under HOME.
        env = {"HOME": "/tmp"},
    )
    return [
        DefaultInfo(files = depset([out])),
        WebUiTestBundleInfo(
            directory = out,
            bundle = ctx.attr.bundle,
            test_set = ctx.attr.test_set,
            relative = relative,
        ),
    ]

web_ui_test_bundle = rule(
    implementation = _web_ui_test_bundle_impl,
    doc = "One of lib/web_ui's test files compiled for one of felt's bundles, into a directory shaped as the bundle's.",
    attrs = {
        "test": attr.label(
            allow_single_file = [".dart"],
            mandatory = True,
            doc = "The test file, under lib/web_ui/test/<test_set>/.",
        ),
        "srcs": attr.label_list(
            allow_files = True,
            doc = "The test set's other sources the file imports (test/common, the set's helpers, its fixtures).",
        ),
        "test_set": attr.string(mandatory = True, doc = "The test set's directory under lib/web_ui/test (felt_config.yaml's test-sets)."),
        "bundle": attr.string(mandatory = True, doc = "felt's bundle name, written into results.json."),
        "compile_configs": attr.string_list(
            mandatory = True,
            allow_empty = False,
            doc = "The bundle's compile configurations (COMPILE_CONFIGS' names): one, or the fallbacks bundle's two.",
        ),
        "package_config": attr.label(
            allow_single_file = [".json"],
            providers = [PubPackageConfigInfo],
            mandatory = True,
            doc = "The package configuration of the compile (pub_package_config over lib/web_ui's own lock).",
        ),
        "_sdk": attr.label(default = "@dart_sdk_linux_x64//:dart"),
    },
)

def web_ui_test_bundles(name, bundle, compile_configs, test_set, tests, srcs, package_config, **kwargs):
    """One web_ui_test_bundle per test file of a bundle, and a filegroup over them.

    Args:
      name: the filegroup's name (`<name>` lists every file's directory).
      bundle: felt's bundle name (felt_config.yaml's test-bundles).
      compile_configs: the bundle's compile configurations (COMPILE_CONFIGS' names).
      test_set: the test set's directory under lib/web_ui/test.
      tests: the test files (a glob over `test/<test_set>/**/*_test.dart`).
      srcs: the other sources the files import.
      package_config: the pub_package_config of the compile.
      **kwargs: the targets' other attributes (visibility, tags).

    Each file's target is `bundles/<bundle>/<its path in the test set, less .dart>`.
    """
    prefix = "test/%s/" % test_set
    directories = []
    for test in tests:
        if not test.startswith(prefix) or not test.endswith(".dart"):
            fail("%s: %s is not a Dart file under %s" % (name, test, prefix))
        target = "bundles/%s/%s" % (bundle, test[len(prefix):-len(".dart")])
        web_ui_test_bundle(
            name = target,
            test = test,
            srcs = srcs,
            test_set = test_set,
            bundle = bundle,
            compile_configs = compile_configs,
            package_config = package_config,
            **kwargs
        )
        directories.append(":" + target)
    native.filegroup(
        name = name,
        srcs = directories,
        **kwargs
    )

# ---------------------------------------------------------------------------
# The host page: web_engine_tester's host.dart, which loads each test's page
# in an iframe and relays package:test's channels to felt's server over a
# websocket, compiled by dart2js as felt's copy_artifacts_step compiles it.

def _web_ui_host_page_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + "/host.dart.js")
    sdk = ctx.attr._sdk[DefaultInfo].files
    dart = [f for f in sdk.to_list() if f.short_path.endswith("/bin/dart")][0]
    args = ctx.actions.args()
    args.add_all(["compile", "js", "--packages=" + ctx.file.package_config.path, ctx.file.main.path, "-o", out.path])
    ctx.actions.run(
        executable = dart,
        arguments = [args],
        inputs = depset(
            [ctx.file.main, ctx.file.package_config] + ctx.files.srcs,
            transitive = [sdk, ctx.attr.package_config[PubPackageConfigInfo].sources],
        ),
        outputs = [out],
        mnemonic = "WebUiHostPage",
        progress_message = "Compiling the web tests' host page",
        env = {"HOME": "/tmp"},
    )
    return [DefaultInfo(files = depset([out]))]

web_ui_host_page = rule(
    implementation = _web_ui_host_page_impl,
    doc = "web_engine_tester's host page script (lib/static/host.dart) compiled by dart2js, as felt compiles it.",
    attrs = {
        "main": attr.label(allow_single_file = [".dart"], mandatory = True, doc = "host.dart."),
        "srcs": attr.label_list(allow_files = True, doc = "What it imports besides the configuration's packages."),
        "package_config": attr.label(
            allow_single_file = [".json"],
            providers = [PubPackageConfigInfo],
            mandatory = True,
            doc = "The package configuration (execroot layout).",
        ),
        "_sdk": attr.label(default = "@dart_sdk_linux_x64//:dart"),
    },
)

# ---------------------------------------------------------------------------
# The test: felt's own run step on one compiled file, from the runfiles.

# Where felt looks for the compiled bundles and the artifacts: engine/src/out
# -- five directories above dev/felt.dart (dev/environment.dart), which is
# where the kernel lies in the runfiles, so the same path there.
_WEB_TESTS = "engine/src/out/web_tests"

# felt's test fonts (copy_artifacts_step.dart's copyTestFonts): family to
# file of txt/third_party/fonts, in the FontManifest.json's order.
_FONTS = [
    ("Ahem", "ahem.ttf"),
    ("Roboto", "Roboto-Regular.ttf"),
    ("RobotoVariable", "RobotoSlab-VariableFont_wght.ttf"),
    ("Noto Naskh Arabic UI", "NotoNaskhArabic-Regular.ttf"),
    ("Noto Color Emoji", "NotoColorEmoji.ttf"),
]

def _repository_relative(file):
    """A file's path under its own repository (another repository's short_path begins with ../<repository>/)."""
    path = file.short_path
    if path.startswith("../"):
        return path.split("/", 2)[2]
    return path

def _web_ui_test_impl(ctx):
    bundle = ctx.attr.bundle[WebUiTestBundleInfo]
    package = ctx.label.package

    # The runfiles tree as felt expects the checkout: the bundle and the
    # artifacts under engine/src/out/web_tests, as its compile and copy steps
    # leave them.
    symlinks = {"%s/test_bundles/%s" % (_WEB_TESTS, bundle.bundle): bundle.directory}
    for file, path in ctx.attr.web_sdk[ZipBundleInfo].entries:
        # CanvasKit's variants and skwasm, flutter.js: the web SDK's own
        # layout is the artifacts' (canvaskit/{,chromium/,webparagraph/},
        # canvaskit/skwasm*, canvaskit/wimp*, flutter_js/).
        if path.startswith("canvaskit/") or path.startswith("flutter_js/"):
            symlinks["%s/artifacts/%s" % (_WEB_TESTS, path)] = file
    fonts = {f.basename: f for f in ctx.files.fonts}
    manifest = []
    for family, name in _FONTS:
        if name not in fonts:
            fail("%s: fonts lacks %s" % (ctx.label, name))
        symlinks["%s/artifacts/assets/fonts/%s" % (_WEB_TESTS, name)] = fonts[name]
        manifest.append({"family": family, "fonts": [{"asset": "fonts/" + name}]})
    manifest_file = ctx.actions.declare_file(ctx.label.name + ".FontManifest.json")
    ctx.actions.write(manifest_file, json.encode_indent(manifest, indent = "  "))
    symlinks[_WEB_TESTS + "/artifacts/assets/FontManifest.json"] = manifest_file
    for file in ctx.files.fallback_fonts:
        symlinks["%s/artifacts/assets/fallback_fonts/%s" % (_WEB_TESTS, _repository_relative(file))] = file
    images = "resources/images/"
    for file in ctx.files.test_images:
        path = _repository_relative(file)
        if not path.startswith(images):
            fail("%s: %s is not under Skia's %s" % (ctx.label, path, images))

        # Skia's inputs for its own tests of invalid files are left out, as
        # felt leaves them.
        if "invalid" in file.basename or "missing_eof" in file.basename:
            continue
        symlinks["%s/artifacts/test_images/%s" % (_WEB_TESTS, path[len(images):])] = file
    for file in ctx.files.host_files:
        symlinks["%s/artifacts/host/%s" % (_WEB_TESTS, file.basename)] = file

    # felt's package configuration at the package's .dart_tool, where its
    # server resolves /packages/ URLs from (the runfiles layout, written for
    # that location).
    config_path = package + "/.dart_tool/package_config.json"
    symlinks[config_path] = ctx.file.runtime_package_config

    launcher = ctx.actions.declare_file(ctx.label.name + ".launcher.sh")
    ctx.actions.write(launcher, """#!/bin/bash
# {label}: felt's run step on one compiled test, from the runfiles tree.
set -euo pipefail
root="$PWD"
export CHROME_EXECUTABLE="$root/{chrome}"
# Chrome's own sandbox does not start inside Bazel's.
export CHROME_NO_SANDBOX=true
export HOME="${{TEST_TMPDIR:-$(mktemp -d)}}/home"
mkdir -p "$HOME"
cd "$root/{package}"
exec "$root/{dart}" --packages="$root/{config}" "{felt}" test --run --suite="{suite}" "$@"
""".format(
        label = ctx.label,
        chrome = ctx.file.browser.short_path,
        package = package,
        dart = ctx.file._dart.short_path,
        config = config_path,
        felt = ctx.file.felt.short_path[len(package) + 1:],
        suite = ctx.attr.suite,
    ), is_executable = True)
    runfiles = ctx.runfiles(
        files = [ctx.file.felt, ctx.file.runtime_package_config, ctx.file.browser] + ctx.files.srcs + ctx.files.browser_files,
        symlinks = symlinks,
        transitive_files = depset(transitive = [
            ctx.attr._sdk[DefaultInfo].files,
            ctx.attr.runtime_package_config[PubPackageConfigInfo].sources,
        ]),
    )
    return [DefaultInfo(executable = launcher, runfiles = runfiles)]

web_ui_test = rule(
    implementation = _web_ui_test_impl,
    test = True,
    doc = "One of lib/web_ui's test files run by felt's own run step (`felt test --run --suite=<suite>`) on the pinned Chrome, from the runfiles.",
    attrs = {
        "bundle": attr.label(providers = [WebUiTestBundleInfo], mandatory = True, doc = "The file compiled for the suite's bundle (web_ui_test_bundle)."),
        "suite": attr.string(mandatory = True, doc = "felt's suite name (felt_config.yaml's test-suites)."),
        "felt": attr.label(allow_single_file = [".dill"], mandatory = True, doc = "felt compiled for the VM, at dev/felt.dill of the package."),
        "srcs": attr.label_list(allow_files = True, doc = "The package's files felt and the runner read: the tests, dev/, the configuration files."),
        "runtime_package_config": attr.label(
            allow_single_file = [".json"],
            providers = [PubPackageConfigInfo],
            mandatory = True,
            doc = "felt's package configuration in the runfiles layout, written for <package>/.dart_tool/package_config.json.",
        ),
        "web_sdk": attr.label(providers = [ZipBundleInfo], mandatory = True, doc = "The web SDK's archive (flutter-web-sdk.zip's bundle): CanvasKit, skwasm and flutter.js come from it."),
        "fonts": attr.label_list(allow_files = True, mandatory = True, doc = "The test fonts of txt/third_party/fonts (_FONTS)."),
        "fallback_fonts": attr.label_list(allow_files = True, doc = "The fallback fonts (@google_fonts_for_unit_tests), laid as assets/fallback_fonts."),
        "test_images": attr.label_list(allow_files = True, doc = "Skia's resources/images, laid as test_images."),
        "host_files": attr.label_list(allow_files = True, doc = "The host page: index.html, host.css, favicon.ico and host.dart.js, laid as host/."),
        "browser": attr.label(allow_single_file = True, mandatory = True, doc = "Chrome's executable (@chrome), exported as CHROME_EXECUTABLE."),
        "browser_files": attr.label_list(allow_files = True, doc = "The browser's directory, whole."),
        "_sdk": attr.label(default = "@dart_sdk_linux_x64//:dart"),
        "_dart": attr.label(default = "@dart_sdk_linux_x64//:bin/dart", allow_single_file = True),
    },
)

def web_ui_test_suite(name, suite, bundle, tests, test_set, size = "large", tags = [], network = [], **kwargs):
    """felt's test suite as Bazel tests: one web_ui_test per file, and a test_suite over them.

    The tests run with no network (`block-network`): felt's Skia Gold client
    finds Gold unreachable and the goldens compare nothing, as they do for a
    developer offline -- a verdict that depends neither on the host's fonts
    against CI's baselines nor on Gold. The few files that fetch from the
    web by design (`network`) keep it, as `requires-network`.

    Args:
      name: the test_suite's name (the suite's).
      suite: felt's suite name.
      bundle: the bundle's name, whose compiled files are `bundles/<bundle>/<rel>` (web_ui_test_bundles).
      tests: the test files (a glob over `test/<test_set>/**/*_test.dart`).
      test_set: the test set's directory under lib/web_ui/test.
      size: each test's size.
      tags: each test's tags, and the suite's.
      network: the test files that reach the web (font_fallback_service_test downloads a Noto font).
      **kwargs: web_ui_test's other attributes, the same for every file.
    """
    prefix = "test/%s/" % test_set
    names = []
    for test in tests:
        stem = test[len(prefix):-len(".dart")]
        target = "%s/%s" % (suite, stem)
        web_ui_test(
            name = target,
            bundle = ":bundles/%s/%s" % (bundle, stem),
            suite = suite,
            size = size,
            tags = tags + (["requires-network"] if test in network else ["block-network"]),
            **kwargs
        )
        names.append(":" + target)
    native.test_suite(
        name = name,
        tests = names,
        tags = tags,
    )
