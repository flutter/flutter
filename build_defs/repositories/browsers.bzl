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
# pinned, and per host -- the Linux x64 and the Apple-silicon Mac builds
# of Chrome for Testing (chrome-for-testing-public lays them out as
# <version>/<platform>/chrome-<platform>.zip and chromedriver-<platform>.zip)
# -- the sha256s of the two archives at that version, the directory each
# unpacks to, and the browser's executable inside it (an app bundle on a
# Mac). A roll changes the lock; update the version and every sha256
# together (sha256sum of the archives). Another host fails the fetch with
# the URLs to pin.
_CHROME_VERSION = "145.0.7632.117"

_CHROME_URL = "https://storage.googleapis.com/chrome-for-testing-public/%s/%s/%s.zip"

_CHROME_BUILDS = {
    "linux_x64": struct(
        platform = "linux64",
        chrome_sha256 = "b373fbc7cc71922082febe41fe413e02bb6c4ae31b6b6626ddb2c764289ef15d",
        chromedriver_sha256 = "7f397fa71614b2d97dcb06a87f3297c91725042803654d6c7fedcd10387a5df8",
        executable = "chrome-linux64/chrome",
    ),
    "mac_arm64": struct(
        platform = "mac-arm64",
        chrome_sha256 = "cced377de50a37287f7f69337bbad5d9f12505bf6b03f7d40a627cc8061f7f59",
        chromedriver_sha256 = "25d09ebbca90628b480e95e0d1541818f8e7646d0b77fa81c6258fc13c0613d0",
        executable = "chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing",
    ),
}

def _host_key(rctx):
    """The host as _CHROME_BUILDS keys it (linux_x64, mac_arm64, ...)."""
    name = rctx.os.name.lower()
    if name.startswith("linux"):
        os = "linux"
    elif name.startswith("mac"):
        os = "mac"
    else:
        os = name
    arch = rctx.os.arch.lower()
    cpu = "x64" if arch in ("amd64", "x86_64", "x64") else ("arm64" if arch in ("aarch64", "arm64") else arch)
    return "%s_%s" % (os, cpu)

# The Firefox version the lock named when this was pinned, and the sha256 of
# linux-x86_64's firefox-<version>.tar.xz and of the Mac's disk image
# (`Firefox <version>.dmg`, one image for both CPUs), which felt downloads
# the same way (lib/web_ui/dev/firefox_installer.dart).
_FIREFOX_VERSION = "148.0"
_FIREFOX_SHA256 = "a3ea5907006baa19183d5f582f7781c1d0e22fd1605603c4a76fc14b7f55be23"
_FIREFOX_MAC_SHA256 = "ec50d7ed2337441d92272617f510cd4c11e44d68699349d466d62211b767e0a2"

_FIREFOX_URL = "https://ftp.mozilla.org/pub/firefox/releases/%s/linux-x86_64/en-US/firefox-%s.tar.xz"
_FIREFOX_MAC_URL = "https://ftp.mozilla.org/pub/firefox/releases/%s/mac/en-US/Firefox%%20%s.dmg"

# What felt writes beside the executable it resolves (dev/firefox.dart: no
# update checks); in the Linux repository already, so that it finds it
# written and writes nothing into the repository. Not in the Mac's app
# bundle: a file added to a sealed bundle breaks its signature, and macOS
# kills the browser at launch (the Mac's T54A); there felt resolves the
# launcher script, which has the file beside it (browser_launcher's
# `policies`), and the bundle stays as Mozilla signed it.
_FIREFOX_POLICIES = """{
  "policies": {
    "DisableAppUpdate": true
  }
}
"""

_FIREFOX_BUILD = """# Firefox {version} ({platform}), the browser lib/web_ui/dev/package_lock.yaml pins (browsers.bzl).

package(default_visibility = ["//visibility:public"])

# The browser's directory whole: the executable loads its libraries and
# resources from beside itself (an app bundle on a Mac).
filegroup(
    name = "firefox",
    srcs = glob(["{tree}/**"]),
)

exports_files(["{executable}"])

# The executable under one name per host (firefox/firefox on Linux, the
# Mac's inside its app bundle).
alias(
    name = "executable",
    actual = "{executable}",
)
"""

def _firefox_mac(rctx, named):
    """Mozilla's disk image, mounted with hdiutil and its app bundle copied in, as felt installs it on a Mac."""
    image = rctx.path("Firefox.dmg")
    rctx.download(
        url = _FIREFOX_MAC_URL % (named, named),
        output = image,
        sha256 = _FIREFOX_MAC_SHA256,
    )
    mount = rctx.path("mount")
    attached = rctx.execute(["hdiutil", "attach", "-nobrowse", "-readonly", "-noverify", "-mountpoint", str(mount), str(image)])
    if attached.return_code != 0:
        fail("browsers.bzl: hdiutil attach of %s failed: %s%s" % (image, attached.stdout, attached.stderr))
    copied = rctx.execute(["cp", "-R", str(mount.get_child("Firefox.app")), str(rctx.path("Firefox.app"))])
    detached = rctx.execute(["hdiutil", "detach", str(mount)])
    if copied.return_code != 0:
        fail("browsers.bzl: copying Firefox.app out of %s failed: %s%s" % (image, copied.stdout, copied.stderr))
    if detached.return_code != 0:
        fail("browsers.bzl: hdiutil detach of %s failed: %s%s" % (mount, detached.stdout, detached.stderr))
    rctx.delete(image)

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
    host = _host_key(rctx)
    build = _CHROME_BUILDS.get(host)
    if build == None:
        fail(("browsers.bzl pins Chrome for Testing for %s; this host is %s: add its build to _CHROME_BUILDS " +
              "(sha256sum of %s and %s).") % (
            ", ".join(sorted(_CHROME_BUILDS.keys())),
            host,
            _CHROME_URL % (named, "<platform>", "chrome-<platform>"),
            _CHROME_URL % (named, "<platform>", "chromedriver-<platform>"),
        ))
    chrome_url = _CHROME_URL % (named, build.platform, "chrome-" + build.platform)
    chromedriver_url = _CHROME_URL % (named, build.platform, "chromedriver-" + build.platform)
    if named != _CHROME_VERSION:
        fail(("lib/web_ui/dev/package_lock.yaml names Chrome %s, but %s pins %s: update _CHROME_VERSION and " +
              "every sha256 of _CHROME_BUILDS (sha256sum of %s and %s, and the other hosts' archives).") % (
            named,
            "build_defs/repositories/browsers.bzl",
            _CHROME_VERSION,
            chrome_url,
            chromedriver_url,
        ))
    rctx.download_and_extract(
        url = chrome_url,
        sha256 = build.chrome_sha256,
        type = "zip",
    )
    rctx.download_and_extract(
        url = chromedriver_url,
        sha256 = build.chromedriver_sha256,
        type = "zip",
    )
    rctx.file("BUILD.bazel", """# Chrome for Testing {version} ({platform}) and its chromedriver, the browser lib/web_ui/dev/package_lock.yaml pins (browsers.bzl).

package(default_visibility = ["//visibility:public"])

# The browser's directory whole: the executable loads its libraries,
# resources and locales from beside itself (an app bundle on a Mac).
filegroup(
    name = "chrome",
    srcs = glob(["chrome-{platform}/**"]),
)

exports_files([
    "{executable}",
    "chromedriver-{platform}/chromedriver",
])

# The executables under one name per host (the paths differ: chrome under
# chrome-linux64/, the Mac's inside its app bundle).
alias(
    name = "executable",
    actual = "{executable}",
)

alias(
    name = "chromedriver",
    actual = "chromedriver-{platform}/chromedriver",
)
""".format(
        version = named,
        platform = build.platform,
        executable = build.executable,
    ))

chrome = repository_rule(
    implementation = _chrome_impl,
    doc = "Chrome for Testing and its chromedriver at the version lib/web_ui/dev/package_lock.yaml pins, for the tool's web tests.",
)

def _firefox_impl(rctx):
    named = _locked_version(rctx, "firefox")
    if named != _FIREFOX_VERSION:
        fail(("lib/web_ui/dev/package_lock.yaml names Firefox %s, but %s pins %s: update _FIREFOX_VERSION, " +
              "_FIREFOX_SHA256 (sha256sum of %s) and _FIREFOX_MAC_SHA256 (of %s).") % (
            named,
            "build_defs/repositories/browsers.bzl",
            _FIREFOX_VERSION,
            _FIREFOX_URL % (named, named),
            _FIREFOX_MAC_URL % (named, named),
        ))
    host = _host_key(rctx)
    if host.startswith("mac_"):
        _firefox_mac(rctx, named)
        tree = "Firefox.app"
        executable = "Firefox.app/Contents/MacOS/firefox"
        platform = "mac"
    else:
        rctx.download_and_extract(
            url = _FIREFOX_URL % (named, named),
            sha256 = _FIREFOX_SHA256,
            type = "tar.xz",
        )
        tree = "firefox"
        executable = "firefox/firefox"
        platform = "linux-x86_64"
        rctx.file("firefox/distribution/policies.json", _FIREFOX_POLICIES)
    rctx.file("BUILD.bazel", _FIREFOX_BUILD.format(version = named, platform = platform, tree = tree, executable = executable))

firefox = repository_rule(
    implementation = _firefox_impl,
    doc = "Firefox at the version lib/web_ui/dev/package_lock.yaml pins, for the web engine's Firefox suites: " +
          "Mozilla's Linux tarball, or its Mac disk image mounted and copied as felt installs it.",
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
