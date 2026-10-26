# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The browsers the web tests drive, as Bazel repositories.

flutter_tools' web tests (test/web.shard, the widget previewer's integration
tests) run `flutter run -d chrome` and the previewer in a headless Chrome,
which the tool finds through CHROME_EXECUTABLE or, failing that, on the
host; the web-server device's tests drive that Chrome through a
`chromedriver` found on PATH. The web engine's own test runner
(lib/web_ui/dev/felt) pins the Chrome it tests with in
lib/web_ui/dev/package_lock.yaml -- a Chrome for Testing build, downloaded
from chrome-for-testing-public with its chromedriver -- and `chrome` fetches
that same build and driver (what CI's `chrome_and_driver` dependency holds),
verified against the sha256s pinned here, for dart_test's `browser` and
`browser_driver` attributes to export as CHROME_EXECUTABLE and put on PATH:
the tests drive the pinned browser wherever they run, not whatever the host
has. The lock file is watched: a browser roll that changes it fails the
fetch until the pins follow.

`firefox` is the same for Firefox (the version the lock names, from
Mozilla's release archive): felt's Firefox suites of the web engine's unit
tests drive it through FIREFOX_EXECUTABLE, on an X display felt starts
itself (Xvfb, by name) when none is set.

Chrome and Firefox load the platform's X11, NSS, GTK and audio libraries
at run time, and Xvfb is a program of the platform's: the tests get them
from the build too -- the runtime sysroot (debian_runtime.bzl) through the
launchers of //build_defs/web:browser_launcher.bzl -- or from the host,
under `--//build_defs/web:browser_libraries=//build_defs/web:host_libraries`.
"""

# The Chrome version lib/web_ui/dev/package_lock.yaml named when this was
# pinned, and the sha256s of linux64's chrome-linux64.zip and
# chromedriver-linux64.zip at that version. A roll changes the lock; update
# all three together.
_CHROME_VERSION = "145.0.7632.117"
_CHROME_SHA256 = "b373fbc7cc71922082febe41fe413e02bb6c4ae31b6b6626ddb2c764289ef15d"
_CHROMEDRIVER_SHA256 = "7f397fa71614b2d97dcb06a87f3297c91725042803654d6c7fedcd10387a5df8"

_CHROME_URL = "https://storage.googleapis.com/chrome-for-testing-public/%s/linux64/chrome-linux64.zip"
_CHROMEDRIVER_URL = "https://storage.googleapis.com/chrome-for-testing-public/%s/linux64/chromedriver-linux64.zip"

# The Firefox version the lock named when this was pinned, and the sha256 of
# linux-x86_64's firefox-<version>.tar.xz.
_FIREFOX_VERSION = "148.0"
_FIREFOX_SHA256 = "a3ea5907006baa19183d5f582f7781c1d0e22fd1605603c4a76fc14b7f55be23"

_FIREFOX_URL = "https://ftp.mozilla.org/pub/firefox/releases/%s/linux-x86_64/en-US/firefox-%s.tar.xz"

def _locked_version(rctx, browser):
    """The `<browser>: version:` of package_lock.yaml (a small, fixed shape; no YAML parser here)."""

    # Read from the tree, not by label: lib/web_ui/dev has no BUILD file.
    lock = rctx.path(Label("//:MODULE.bazel")).dirname.get_child("engine/src/flutter/lib/web_ui/dev/package_lock.yaml")
    rctx.watch(lock)
    section = None
    for line in rctx.read(lock).splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if not line.startswith(" "):
            section = stripped.rstrip(":")
        elif section == browser and stripped.startswith("version:"):
            return stripped[len("version:"):].strip().strip("'\"")
    fail("lib/web_ui/dev/package_lock.yaml names no %s version" % browser)

def _chrome_impl(rctx):
    named = _locked_version(rctx, "chrome")
    if named != _CHROME_VERSION:
        fail(("lib/web_ui/dev/package_lock.yaml names Chrome %s, but %s pins %s: update _CHROME_VERSION, " +
              "_CHROME_SHA256 and _CHROMEDRIVER_SHA256 (sha256sum of %s and %s).") % (
            named,
            "build_defs/repositories/browsers.bzl",
            _CHROME_VERSION,
            _CHROME_URL % named,
            _CHROMEDRIVER_URL % named,
        ))
    rctx.download_and_extract(
        url = _CHROME_URL % named,
        sha256 = _CHROME_SHA256,
        type = "zip",
    )
    rctx.download_and_extract(
        url = _CHROMEDRIVER_URL % named,
        sha256 = _CHROMEDRIVER_SHA256,
        type = "zip",
    )
    rctx.file("BUILD.bazel", """# Chrome for Testing %s and its chromedriver, the browser lib/web_ui/dev/package_lock.yaml pins (browsers.bzl).

package(default_visibility = ["//visibility:public"])

# The browser's directory whole: the executable loads its libraries,
# resources and locales from beside itself.
filegroup(
    name = "chrome",
    srcs = glob(["chrome-linux64/**"]),
)

exports_files([
    "chrome-linux64/chrome",
    "chromedriver-linux64/chromedriver",
])
""" % named)

chrome = repository_rule(
    implementation = _chrome_impl,
    doc = "Chrome for Testing and its chromedriver at the version lib/web_ui/dev/package_lock.yaml pins, for the tool's web tests.",
)

def _firefox_impl(rctx):
    named = _locked_version(rctx, "firefox")
    if named != _FIREFOX_VERSION:
        fail(("lib/web_ui/dev/package_lock.yaml names Firefox %s, but %s pins %s: update _FIREFOX_VERSION and " +
              "_FIREFOX_SHA256 (sha256sum of %s).") % (
            named,
            "build_defs/repositories/browsers.bzl",
            _FIREFOX_VERSION,
            _FIREFOX_URL % (named, named),
        ))
    rctx.download_and_extract(
        url = _FIREFOX_URL % (named, named),
        sha256 = _FIREFOX_SHA256,
        type = "tar.xz",
    )

    # The policy felt writes beside the executable before it launches Firefox
    # (no update checks); here already, so that felt finds it and writes
    # nothing into the repository.
    rctx.file("firefox/distribution/policies.json", """{
  "policies": {
    "DisableAppUpdate": true
  }
}
""")
    rctx.file("BUILD.bazel", """# Firefox %s, the browser lib/web_ui/dev/package_lock.yaml pins (browsers.bzl).

package(default_visibility = ["//visibility:public"])

# The browser's directory whole: the executable loads its libraries and
# resources from beside itself.
filegroup(
    name = "firefox",
    srcs = glob(["firefox/**"]),
)

exports_files(["firefox/firefox"])
""" % named)

firefox = repository_rule(
    implementation = _firefox_impl,
    doc = "Firefox at the version lib/web_ui/dev/package_lock.yaml pins, for the web engine's Firefox suites.",
)

def _browsers_impl(mctx):
    chrome(name = "chrome")
    firefox(name = "firefox")
    root = mctx.modules[0] if mctx.modules else None
    if root != None and root.is_root:
        return mctx.extension_metadata(
            root_module_direct_deps = ["chrome", "firefox"],
            root_module_direct_dev_deps = [],
            reproducible = True,
        )
    return mctx.extension_metadata(reproducible = True)

browsers = module_extension(
    implementation = _browsers_impl,
    doc = "The browsers the tests drive, at the web engine's pinned versions: @chrome (Chrome for Testing), @firefox.",
)
