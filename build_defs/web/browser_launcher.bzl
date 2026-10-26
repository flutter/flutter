# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A browser the tests drive, with its system libraries from the build rather than the host.

The pinned browsers (@chrome, @firefox: build_defs/repositories/browsers.bzl)
ship their own libraries but load the platform's from the system: GTK, NSS,
X11, ALSA, D-Bus, fontconfig and the rest (`objdump -p chrome | grep
NEEDED`), which a test took from whatever the host had. The engine's build
sysroot (@sysroot_linux_x64, Chromium's Debian bullseye tarball) names
every one of them but cannot supply them: its shared objects are stubs,
the code stripped out, for linking only. So the build fetches the same
Debian packages whole, at the build sysroot's versions, pinned by sha256
(@sysroot_linux_x64_runtime: build_defs/repositories/debian_runtime.bzl and
its lock file), and browser_launcher writes a script in the browser's name
that puts that tree's library directories first on `LD_LIBRARY_PATH` and
execs the browser, so that the libraries come from the build. The C
library itself stays the host's: libc6 is not among the packages, as the
host's dynamic loader must match its own libc, and a library built against
glibc 2.31 runs on any newer one; nor is the compiler runtime (libgcc-s1).
Which libraries, is the label flag `//build_defs/web:browser_libraries`, a
`browser_libraries` target: the runtime sysroot's by default -- its two
library directories, and the variables that point Mesa at its drivers
(`LIBGL_DRIVERS_PATH`: Firefox's WebGL is Mesa's llvmpipe on Xvfb, loaded
by absolute path otherwise) and GLVND at its EGL vendor
(`__EGL_VENDOR_LIBRARY_DIRS`) --
`--//build_defs/web:browser_libraries=//build_defs/web:host_libraries` for
the host's (the script then sets nothing).

The fonts come from the build too: the runtime sysroot carries Debian's
DejaVu and Liberation (`fonts-dejavu-core`, `fonts-liberation`: the
metric-compatible stand-ins for Arial, Times and Courier) and fontconfig's
own rules (`fontconfig-config`'s `conf.d`: the metric aliases that answer
a request for Arial with Liberation Sans, the generic families), and the
script writes a `fonts.conf` naming that font directory alone and
including those rules, with a cache directory of the test's own, as
`FONTCONFIG_FILE` -- so a rendering depends on no font of the host (the
web engine's WebParagraph tests measure Arial, and get the same metrics
everywhere), and the sysroot's fontconfig scans a dozen files rather than
the host's hundreds (it cannot read the host's caches, a newer format,
and rebuilt one per test). The tests' own fonts (the web engine's
FontManifest, its fallback fonts) are the engine's, loaded by the page,
and unaffected.

Two things stay the host's regardless: the dynamic loader and libc, as
said, and the X display -- felt starts Xvfb, the host's, when there is no
DISPLAY. The sysroot's other libraries read the host's configuration
where they look for it by absolute path (GTK's settings), as the host's
own would.

    browser_launcher(
        name = "chrome",
        browser = "@chrome//:chrome-linux64/chrome",
        browser_files = ["@chrome"],
    )
    web_ui_test(..., browser = ":chrome")

The target's one file is the script, at `<name>/<browser's basename>`; its
runfiles carry the browser's directory and the libraries. Firefox reads an
enterprise policies file beside its executable (felt writes one, disabling
updates, after resolving the executable's symbolic links -- which the
script's resolve to the script's own directory), so `policies` writes that
file beside the script.
"""

BrowserLibrariesInfo = provider(
    doc = "Where a browser's system libraries and fonts come from: the directories for LD_LIBRARY_PATH, the variables that point its loaders at the rest, the font directories.",
    fields = {
        "directories": "The library directories (Files), in LD_LIBRARY_PATH order; empty for the host's.",
        "environment": "Variable name to the File (a directory) it names: Mesa's LIBGL_DRIVERS_PATH, GLVND's __EGL_VENDOR_LIBRARY_DIRS.",
        "fonts": "The font directories (Files) fontconfig is confined to; empty for the host's fonts.",
        "font_configuration": "fontconfig's conf.d (a File, a directory) the launcher's fonts.conf includes, or None.",
    },
)

def _browser_libraries_impl(ctx):
    environment = {}
    for target, variable in ctx.attr.environment.items():
        files = target[DefaultInfo].files.to_list()
        if len(files) != 1:
            fail("%s: environment: %s should be one directory" % (ctx.label, target.label))
        environment[variable] = files[0]
    font_configuration = None
    if ctx.attr.font_configuration:
        files = ctx.attr.font_configuration[DefaultInfo].files.to_list()
        if len(files) != 1:
            fail("%s: font_configuration: %s should be one directory" % (ctx.label, ctx.attr.font_configuration.label))
        font_configuration = files[0]
    return [
        BrowserLibrariesInfo(
            directories = ctx.files.directories,
            environment = environment,
            fonts = ctx.files.fonts,
            font_configuration = font_configuration,
        ),
        DefaultInfo(files = depset(
            ctx.files.directories + environment.values() + ctx.files.fonts +
            ([font_configuration] if font_configuration else []),
        )),
    ]

browser_libraries = rule(
    implementation = _browser_libraries_impl,
    doc = "A browser's system libraries and fonts: the runtime sysroot's directories, or nothing for the host's.",
    attrs = {
        "directories": attr.label_list(allow_files = True, doc = "The directories for LD_LIBRARY_PATH, in order."),
        "environment": attr.label_keyed_string_dict(
            allow_files = True,
            doc = "A directory to the variable that names it to a loader (Mesa's drivers: LIBGL_DRIVERS_PATH; GLVND's EGL vendors: __EGL_VENDOR_LIBRARY_DIRS).",
        ),
        "fonts": attr.label_list(
            allow_files = True,
            doc = "The font directories: the launcher writes a fonts.conf confining fontconfig to them, with a cache " +
                  "directory of the test's own (FONTCONFIG_FILE); nothing leaves the host's fonts and configuration.",
        ),
        "font_configuration": attr.label(
            allow_files = True,
            doc = "fontconfig's conf.d to include in that fonts.conf (the metric aliases that answer Arial with " +
                  "Liberation Sans, the generic families, ...): the sysroot's fontconfig-config.",
        ),
    },
)

def _browser_launcher_impl(ctx):
    browser = ctx.file.browser
    libraries = ctx.attr.libraries[BrowserLibrariesInfo]
    script = ctx.actions.declare_file("%s/%s" % (ctx.label.name, browser.basename))
    outputs = [script]
    runfiles_files = [browser] + ctx.files.browser_files + libraries.directories + libraries.environment.values() + libraries.fonts + \
                     ([libraries.font_configuration] if libraries.font_configuration else [])
    if ctx.attr.policies:
        policies = ctx.actions.declare_file("%s/distribution/policies.json" % ctx.label.name)
        ctx.actions.write(policies, ctx.attr.policies)
        runfiles_files.append(policies)

    # The script finds the runfiles root from its own place in it: felt and
    # the tool run it by the path the test exports, <root>/<package>/<name>/<basename>.
    package_path = "%s/%s" % (ctx.label.package, ctx.label.name) if ctx.label.package else ctx.label.name
    exports = []
    if libraries.directories:
        exports.append("export LD_LIBRARY_PATH=\"%s${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}\"" % ":".join([
            "$root/" + f.short_path
            for f in libraries.directories
        ]))
    for variable in sorted(libraries.environment.keys()):
        exports.append("export %s=\"$root/%s\"" % (variable, libraries.environment[variable].short_path))
    if libraries.fonts:
        # fontconfig confined to the sysroot's fonts: a fonts.conf written where
        # the test may write (fontconfig wants absolute paths), with its cache
        # beside it -- a small cache over a few fonts rather than the host's
        # font set re-scanned by every test (the sysroot's fontconfig cannot
        # read the host's caches, a newer format).
        exports.append("\n".join([
            "fontconfig=\"${TEST_TMPDIR:-$(mktemp -d)}/fontconfig\"",
            "mkdir -p \"$fontconfig/cache\"",
            "cat > \"$fontconfig/fonts.conf\" <<FONTS_CONF",
            "<?xml version=\"1.0\"?>",
            "<!DOCTYPE fontconfig SYSTEM \"fonts.dtd\">",
            "<fontconfig>",
        ] + [
            "  <dir>$root/%s</dir>" % f.short_path
            for f in libraries.fonts
        ] + ([
            "  <include ignore_missing=\"yes\">$root/%s</include>" % libraries.font_configuration.short_path,
        ] if libraries.font_configuration else []) + [
            "  <cachedir>$fontconfig/cache</cachedir>",
            "</fontconfig>",
            "FONTS_CONF",
            "export FONTCONFIG_FILE=\"$fontconfig/fonts.conf\"",
        ]))
    ctx.actions.write(script, """#!/bin/bash
# {label}: {browser}, its system libraries from {libraries}.
here="$(cd "$(dirname "$0")" && pwd)"
root="${{here%/{package_path}}}"
{exports}exec "$root/{browser}" "$@"
""".format(
        label = ctx.label,
        browser = browser.short_path,
        libraries = "the host" if not libraries.directories else ", ".join([f.short_path for f in libraries.directories]),
        package_path = package_path,
        exports = "".join([line + "\n" for line in exports]),
    ), is_executable = True)
    return [DefaultInfo(
        files = depset(outputs),
        executable = script,
        runfiles = ctx.runfiles(files = runfiles_files),
    )]

browser_launcher = rule(
    implementation = _browser_launcher_impl,
    doc = "A script in a browser's name that execs it with the build's libraries on LD_LIBRARY_PATH.",
    attrs = {
        "browser": attr.label(allow_single_file = True, mandatory = True, doc = "The browser's executable."),
        "browser_files": attr.label_list(allow_files = True, doc = "The browser's directory, whole."),
        "libraries": attr.label(
            default = "//build_defs/web:browser_libraries",
            providers = [BrowserLibrariesInfo],
            doc = "The libraries (a browser_libraries, through the label flag: the runtime sysroot's by default, or the host's, nothing).",
        ),
        "policies": attr.string(
            doc = "Firefox's enterprise policies (distribution/policies.json beside the script), as felt writes them.",
        ),
    },
    executable = True,
)
