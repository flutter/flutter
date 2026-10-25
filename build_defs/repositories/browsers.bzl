# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""The browser the tool's web tests drive, as a Bazel repository.

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

Chrome needs the host's X11, NSS, GTK and audio libraries at run time
(the workstation's and the web CI images' package sets); the sandbox
leaves /usr/lib readable.
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

def _locked_chrome_version(rctx):
    """The `chrome: version:` of package_lock.yaml (a small, fixed shape; no YAML parser here)."""

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
        elif section == "chrome" and stripped.startswith("version:"):
            return stripped[len("version:"):].strip().strip("'\"")
    fail("lib/web_ui/dev/package_lock.yaml names no chrome version")

def _chrome_impl(rctx):
    named = _locked_chrome_version(rctx)
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

def _browsers_impl(mctx):
    chrome(name = "chrome")
    root = mctx.modules[0] if mctx.modules else None
    if root != None and root.is_root:
        return mctx.extension_metadata(
            root_module_direct_deps = ["chrome"],
            root_module_direct_dev_deps = [],
            reproducible = True,
        )
    return mctx.extension_metadata(reproducible = True)

browsers = module_extension(
    implementation = _browsers_impl,
    doc = "The browsers the tests drive (@chrome: Chrome for Testing at the web engine's pinned version).",
)
