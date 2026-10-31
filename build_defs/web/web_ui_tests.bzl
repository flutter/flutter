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
in the runfiles, and the browser is the pinned @chrome or @firefox
(browsers.bzl) through a browser_launcher (browser_launcher.bzl: its system
libraries from the build's sysroot) --
`felt test --run --suite=<suite>` with the file as the bundle's one result.
No network: felt's Skia Gold client finds Gold unreachable and the goldens
compare nothing, as for a developer offline; CI's Gold runs stay felt's.
"""

load("@host_platform//:host.bzl", "HOST_DART_SDK")
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
        # The files read, for the unused-inputs list (dart2js writes its own
        # .deps beside the output).
        "--depfile=" + target + ".d",
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
    script = ["set -euo pipefail"]
    deps_files = []
    for config in configs:
        target, command = _compile_command(config, dart, sdk_root, package_config, test, out, relative)
        script.append("mkdir -p \"$(dirname '%s')\"" % target)
        script.append(" ".join(["'%s'" % part for part in command]))
        deps_files.append(target + (".deps" if config.compiler == "dart2js" else ".d"))
    results = json.encode_indent({
        "name": ctx.attr.bundle,
        "directory": ctx.attr.test_set,
        "builds": [{"compiler": config.compiler, "renderer": config.renderer} for config in configs],
        "results": {relative: "success"},
    }, indent = "  ")
    script.append("cat > '%s/results.json' <<'EOF'\n%s\nEOF" % (out.path, results))

    # Which of `srcs` the compile did not read -- test files import other
    # test files, so every file of test/ is an input, but a change to one
    # should recompile only what imports it. dart2js lists the files it read
    # in <out>.deps (file: URLs under the execroot), dart2wasm in its depfile
    # (make syntax); the inputs not among them go to Bazel's unused-inputs
    # list, and the lists themselves, which name the sandbox's directory,
    # do not stay in the output.
    candidates = ctx.actions.declare_file(ctx.label.name + ".candidates")
    ctx.actions.write(candidates, "\n".join([f.path for f in ctx.files.srcs]) + "\n")
    unused = ctx.actions.declare_file(ctx.label.name + ".unused")
    script.append(
        ("cat %s | tr ' ' '\\n' | sed -e 's#^file://##' -e 's#.*/execroot/_main/##' -e 's#:$##' " +
         "| grep -v -e '^\\\\\\\\$' -e '^$' -e '^/' | LC_ALL=C sort -u > '%s.used'") % (
            " ".join(["'%s'" % f for f in deps_files]),
            unused.path,
        ),
    )
    script.append("LC_ALL=C sort -u '%s' | LC_ALL=C comm -23 - '%s.used' > '%s'" % (candidates.path, unused.path, unused.path))
    script.append("rm -f '%s.used' %s" % (unused.path, " ".join(["'%s'" % f for f in deps_files])))

    # A script file rather than run_shell: only `run` takes an unused-inputs list.
    compile = ctx.actions.declare_file(ctx.label.name + ".compile.sh")
    ctx.actions.write(compile, "#!/bin/bash\n" + "\n".join(script) + "\n", is_executable = True)
    ctx.actions.run(
        executable = compile,
        inputs = depset(
            [test, package_config, candidates] + ctx.files.srcs,
            transitive = [sdk, ctx.attr.package_config[PubPackageConfigInfo].sources],
        ),
        outputs = [out, unused],
        unused_inputs_list = unused,
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
        "_sdk": attr.label(default = HOST_DART_SDK + "//:dart"),
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
        "_sdk": attr.label(default = HOST_DART_SDK + "//:dart"),
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

    # The programs felt starts by name (Xvfb for Firefox): their directories
    # first on PATH.
    tool_directories = []
    for tool in ctx.files.tools:
        directory = tool.short_path.rsplit("/", 1)[0]
        if directory not in tool_directories:
            tool_directories.append(directory)

    launcher = ctx.actions.declare_file(ctx.label.name + ".launcher.sh")
    ctx.actions.write(launcher, """#!/bin/bash
# {label}: felt's run step on one compiled test, from the runfiles tree.
set -euo pipefail
root="$PWD"
export {variable}="$root/{browser}"
{env}{path}export HOME="${{TEST_TMPDIR:-$(mktemp -d)}}/home"
mkdir -p "$HOME"
cd "$root/{package}"
exec "$root/{dart}" --packages="$root/{config}" "{felt}" test --run --suite="{suite}" "$@"
""".format(
        label = ctx.label,
        variable = ctx.attr.browser_variable,
        browser = ctx.file.browser.short_path,
        env = "".join(["export %s=\"%s\"\n" % (name, value) for name, value in ctx.attr.env.items()]),
        path = "".join(["export PATH=\"$root/%s:$PATH\"\n" % directory for directory in tool_directories]),
        package = package,
        dart = ctx.file._dart.short_path,
        config = config_path,
        felt = ctx.file.felt.short_path[len(package) + 1:],
        suite = ctx.attr.suite,
    ), is_executable = True)
    runfiles = ctx.runfiles(
        files = [ctx.file.felt, ctx.file.runtime_package_config, ctx.file.browser] + ctx.files.srcs + ctx.files.browser_files + ctx.files.tools,
        symlinks = symlinks,
        transitive_files = depset(transitive = [
            ctx.attr._sdk[DefaultInfo].files,
            ctx.attr.runtime_package_config[PubPackageConfigInfo].sources,
        ]),
    )

    # A browser_launcher's runfiles: the browser's directory and the
    # libraries its script puts on LD_LIBRARY_PATH; the tools' likewise.
    runfiles = runfiles.merge(ctx.attr.browser[DefaultInfo].default_runfiles)
    for tool in ctx.attr.tools:
        runfiles = runfiles.merge(tool[DefaultInfo].default_runfiles)
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
        "browser": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The browser's executable, exported as `browser_variable`: a browser_launcher (browser_launcher.bzl; " +
                  "the pinned browser with the build's libraries), or the executable itself with `browser_files`.",
        ),
        "browser_files": attr.label_list(allow_files = True, doc = "The browser's directory, whole, when `browser` is the executable itself."),
        "browser_variable": attr.string(
            default = "CHROME_EXECUTABLE",
            values = ["CHROME_EXECUTABLE", "FIREFOX_EXECUTABLE"],
            doc = "The variable felt finds the browser through.",
        ),
        "env": attr.string_dict(
            doc = "Other variables exported before felt runs (CHROME_NO_SANDBOX for Chrome: its own sandbox does not " +
                  "start inside Bazel's; Firefox's MOZ_DISABLE_*_SANDBOX likewise).",
        ),
        "tools": attr.label_list(
            allow_files = True,
            doc = "Programs felt starts by name, their directories put first on PATH: a display_launcher's Xvfb " +
                  "(browser_launcher.bzl) for Firefox, which felt gives a display of its own.",
        ),
        "_sdk": attr.label(default = HOST_DART_SDK + "//:dart"),
        "_dart": attr.label(default = HOST_DART_SDK + "//:bin/dart", allow_single_file = True),
    },
)

def web_ui_test_suite(name, suite, bundle, tests, test_set, size = "large", tags = [], network = [], exclude = [], **kwargs):
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
      exclude: the test files left out of this suite (a file that declares no test on the suite's
        browser: felt's one run over the whole suite does not notice, a run of the file alone
        reports that no test ran).
      **kwargs: web_ui_test's other attributes, the same for every file.
    """
    prefix = "test/%s/" % test_set
    names = []
    for test in tests:
        if test in exclude:
            continue
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

def web_ui_tests(
        name,
        config,
        browsers,
        srcs,
        package_config,
        felt,
        runtime_package_config,
        package_files,
        web_sdk,
        fonts,
        fallback_fonts = [],
        test_images = [],
        host_files = [],
        exclude = {},
        network = [],
        tags = ["cpu:2"],
        bundle_tags = ["manual"],
        browser_tags = {}):
    """The web engine's unit tests, whole, from felt's configuration.

    One call declares, for the suites of `config` whose run configuration
    names a browser in `browsers`: the compiled bundles they run
    (`bundles/<bundle>/<file>` per test file, web_ui_test_bundles), one
    web_ui_test per file and suite (`<suite>/<file>`, web_ui_test_suite), a
    test_suite per suite (`<suite>`), one per browser (`<browser>_tests`) and
    one over all of them (`name`). The test sets' files are globbed from
    their directories here, so a new test file is a new target and nothing
    else changes; a new suite, bundle or set is a change to felt_config.yaml
    and a run of tools/gn_to_bazel.

    Args:
      name: the test_suite over the suites a wildcard build runs on this host (every browser's but
        those `browser_tags` makes manual, which have their `<browser>_tests` alone).
      config: `FELT_CONFIG` from the generated felt_config.bzl (tools/gn_to_bazel's
        rendering of test/felt_config.yaml).
      browsers: the browsers this host runs, by felt's name (`chrome`, `firefox`), each a dict of
        `browser` (the executable), `files` (its directory), `variable` (the variable felt finds it
        through), `env` and `tools` (web_ui_test's attributes; `tools` may be left out); suites of
        other browsers (Safari's, Edge's) are left out.
      srcs: the sources the test files import (a glob over test/).
      package_config: the pub_package_config of the compiles.
      felt: felt compiled for the VM.
      runtime_package_config: felt's package configuration in the runfiles layout.
      package_files: the package's files felt and the runner read at run time.
      web_sdk: the web SDK's archive bundle.
      fonts: the test fonts.
      fallback_fonts: the fallback fonts.
      test_images: Skia's test images.
      host_files: the host page's files.
      exclude: suite name to the test files left out of it (web_ui_test_suite's `exclude`).
      network: the test files that reach the web (web_ui_test_suite's `network`).
      tags: each test's tags.
      bundle_tags: the bundle targets' tags (`manual`: built by the tests that run them).
      browser_tags: further tags for one browser's tests and suites, by felt's name of the
        browser (`manual` for a browser's suites a wildcard build leaves out on this host; the
        browser's suites then stay out of `name` too).
    """
    test_sets = {
        test_set: native.glob(["test/%s/**/*_test.dart" % directory])
        for test_set, directory in config["test_sets"].items()
    }
    suites_by_browser = {}
    bundles = {}
    for suite, spec in config["test_suites"].items():
        browser = config["run_configs"][spec["run_config"]]["browser"]
        if browser not in browsers:
            continue
        suites_by_browser.setdefault(browser, []).append(suite)
        bundles[spec["test_bundle"]] = None

    # A suite felt keeps off CI (`enable-ci: false` in the YAML; felt's
    # generate_builder_json.dart leaves it out of the builders, and it runs
    # by name alone: Firefox's wimp suite, whose animated-image cases fail
    # there) is `manual` here the same way: declared, out of the aggregates,
    # run as `bazel test //...:<suite>`.
    def _enabled(suite):
        return config["test_suites"][suite].get("enable_ci", True)

    for bundle in bundles:
        spec = config["test_bundles"][bundle]
        web_ui_test_bundles(
            name = "bundles/" + bundle,
            srcs = srcs,
            bundle = bundle,
            compile_configs = spec["compile_configs"],
            package_config = package_config,
            tags = bundle_tags,
            test_set = config["test_sets"][spec["test_set"]],
            tests = test_sets[spec["test_set"]],
        )
    for browser, suites in suites_by_browser.items():
        for suite in suites:
            spec = config["test_suites"][suite]
            test_set = config["test_bundles"][spec["test_bundle"]]["test_set"]
            web_ui_test_suite(
                name = suite,
                srcs = package_files,
                browser = browsers[browser]["browser"],
                browser_files = browsers[browser]["files"],
                browser_variable = browsers[browser]["variable"],
                bundle = spec["test_bundle"],
                env = browsers[browser]["env"],
                exclude = exclude.get(suite, []),
                fallback_fonts = fallback_fonts,
                felt = felt,
                fonts = fonts,
                host_files = host_files,
                network = network,
                runtime_package_config = runtime_package_config,
                suite = suite,
                tags = tags + browser_tags.get(browser, []) + ([] if _enabled(suite) else ["manual"]),
                test_images = test_images,
                test_set = config["test_sets"][test_set],
                tests = test_sets[test_set],
                tools = browsers[browser].get("tools", []),
                web_sdk = web_sdk,
            )
        native.test_suite(
            name = browser + "_tests",
            tags = browser_tags.get(browser, []),
            tests = [":" + suite for suite in suites if _enabled(suite)],
        )

    # The suites a wildcard build runs on this host. A test_suite runs what
    # it lists, `manual` or not, so a browser whose suites are manual here
    # (browser_tags: Firefox on a Mac) is left to its own `<browser>_tests`,
    # run by name; listed here, the wildcard would run them after all (the
    # Mac's T56: 377 Firefox suites run and killed at launch). The suites
    # felt keeps off CI are left out the same way.
    native.test_suite(
        name = name,
        tests = [
            ":" + suite
            for browser, suites in suites_by_browser.items()
            if "manual" not in browser_tags.get(browser, [])
            for suite in suites
            if _enabled(suite)
        ],
    )
