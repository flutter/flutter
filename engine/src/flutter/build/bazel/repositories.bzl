# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Repository rules that give Bazel access to the engine's dependencies.

Two kinds of repositories are needed while the engine build migrates from GN
to Bazel:

* `synced_repository`: a repository backed by a directory that `gclient sync`
  populated inside this checkout (a git dependency or a CIPD package from
  `DEPS`). The directory is consumed in place -- it is symlinked, never
  copied -- so GN and Bazel always build the exact same sources, and nothing
  is downloaded twice. An overlay `BUILD` file can be supplied for trees that
  ship no Bazel build files or whose upstream ones should not be used; or
  the engine's GN build files for the tree can be converted into `BUILD`
  files at fetch time (`gn_build_files`), so that a dependency roll that
  changes the GN side (Skia's source lists, say) needs no regeneration.

* `cipd_package`: a repository populated by downloading a CIPD package over
  HTTPS (the same mechanism Skia uses). It needs no `cipd` client and no
  `gclient sync`; the pins come from `deps.lock.bzl`.

Both produce the same layout, so a dependency can move from one to the other
without touching the targets that use it.

A third, `engine_version_repository`, holds no sources: it writes the version
strings `tools/gn` would compute at gen time (shell/version) as a `.bzl` of
constants, read from git and DEPS at fetch time.
"""

_BUILD_FILE_NAMES = ("BUILD", "BUILD.bazel")
_BOUNDARY_FILE_NAMES = ("MODULE.bazel", "REPO.bazel", "WORKSPACE", "WORKSPACE.bazel")
_BAZEL_FILE_NAMES = _BUILD_FILE_NAMES + _BOUNDARY_FILE_NAMES

# The engine module's MODULE.bazel, whichever repository the module is in.
_MODULE_FILE = Label("//:MODULE.bazel")

def checkout_root(rctx):
    """The checkout's root directory: the engine module's own.

    Not `rctx.workspace_root`, which is the main module's: the engine is a
    dependency of the Fuchsia spike's module
    (engine/src/flutter/build/bazel/toolchains/fuchsia), and the synced
    trees, the prebuilt Dart SDK and the converter are where the engine is.
    """
    return rctx.path(_MODULE_FILE).dirname

# Upper bound on the directories a synced tree may contain. Starlark has no
# unbounded loops; this is only reached when a symlink cycle makes the tree
# infinite (the largest tree today, the Dart SDK, has about 12,000).
_MAX_DIRECTORIES = 100000

def _write_build_file(rctx, build_file, build_file_content):
    if build_file != None:
        rctx.file("BUILD.bazel", rctx.read(build_file))
    elif build_file_content:
        rctx.file("BUILD.bazel", build_file_content)

def _mark_repository_boundary(rctx):
    # A boundary file keeps Bazel from treating any upstream WORKSPACE or
    # MODULE.bazel file as meaningful and makes the repository root explicit.
    if not rctx.path("REPO.bazel").exists:
        rctx.file("REPO.bazel", "")

def _join(directory, name):
    return directory + "/" + name if directory else name

def _directories_with_bazel_files(source):
    """Finds the directories of `source` that contain an upstream Bazel file.

    Returns them together with all of their ancestors, as a set of paths
    relative to `source` ("" for the root).

    The listings are read without registering watches: the rule is `local`,
    so it is re-run at every server start anyway, and watching every
    directory of a large tree is not free (on the Dart SDK's 12,000
    directories it doubled the fetch time and produced a 2 MB marker file).
    The price is that a dependency roll which adds a Bazel file deep inside
    an overlaid tree is only picked up at the next server start.
    """
    found = {}
    pending = [(source, "")]
    for _ in range(_MAX_DIRECTORIES):
        if not pending:
            return found
        directory, relative = pending.pop()
        for child in directory.readdir(watch = "no"):
            if child.is_dir:
                pending.append((child, _join(relative, child.basename)))
            elif child.basename in _BAZEL_FILE_NAMES:
                parts = relative.split("/") if relative else []
                for depth in range(len(parts) + 1):
                    found["/".join(parts[:depth])] = True
    fail("synced_repository: %s has more than %d directories; is there a symlink cycle?" % (source, _MAX_DIRECTORIES))

def _link_tree(rctx, source, overlaying):
    """Populates the repository with symlinks to the contents of `source`.

    Entries are symlinked whole, with two exceptions, both re-created as real
    directories whose entries are symlinked one by one:

    * the root of the tree, so that the overlay BUILD file and the repository
      boundary marker can be written next to the upstream files;
    * when an overlay replaces the upstream Bazel build, every directory that
      contains an upstream BUILD, WORKSPACE or MODULE file (and its
      ancestors), with those files left out. Otherwise such a directory would
      be a package (or repository) of its own, and the overlay's globs could
      not see the files in it -- ICU, for example, ships
      `source/common/BUILD.bazel` for its own data-generation build.
    """
    expanded = _directories_with_bazel_files(source) if overlaying else {}
    expanded[""] = True

    pending = [""]
    for _ in range(_MAX_DIRECTORIES):
        if not pending:
            return
        relative = pending.pop()
        directory = source.get_child(relative) if relative else source

        # readdir() also registers a watch on the directory's entries, so adding
        # or removing one (for example after a roll) refreshes the repository.
        # Changes inside the entries are tracked like any source file.
        for child in directory.readdir():
            name = child.basename
            if name in _BOUNDARY_FILE_NAMES:
                continue
            if overlaying and name in _BUILD_FILE_NAMES:
                # The overlay replaces the upstream build files. Without an
                # overlay, upstream BUILD files remain visible as packages.
                continue
            child_relative = _join(relative, name)
            if child_relative in expanded:
                pending.append(child_relative)
            else:
                rctx.symlink(child, child_relative)

# ---------------------------------------------------------------------------
# synced_repository
# ---------------------------------------------------------------------------

_CONVERTER = "engine/src/flutter/tools/gn_to_bazel"
_GN_ROOT = "engine/src"

def _host_dart(rctx):
    """The checkout's prebuilt Dart SDK for this host (a DEPS CIPD package)."""
    os_name = rctx.os.name.lower()
    if os_name.startswith("linux"):
        os_part, exe = "linux", "dart"
    elif os_name.startswith("mac"):
        os_part, exe = "macos", "dart"
    elif os_name.startswith("windows"):
        os_part, exe = "windows", "dart.exe"
    else:
        fail("synced_repository: unsupported host OS %r" % rctx.os.name)
    arch = rctx.os.arch.lower()
    if arch in ("amd64", "x86_64", "x64"):
        arch_part = "x64"
    elif arch in ("aarch64", "arm64"):
        arch_part = "arm64"
    else:
        fail("synced_repository: unsupported host architecture %r" % rctx.os.arch)
    dart = checkout_root(rctx).get_child("engine/src/flutter/prebuilts/%s-%s/dart-sdk/bin/%s" % (os_part, arch_part, exe))
    if not dart.exists:
        fail("synced_repository: %s does not exist; it is populated by `gclient sync`" % dart)
    return dart

def _convert_gn(rctx):
    """Runs tools/gn_to_bazel over `gn_build_files`, writing into the repository.

    The converter is the checkout's own: the prebuilt Dart SDK and `gn` from
    DEPS. Every GN file it read (the depfile) and the converter's sources are
    watched, so a roll that changes a `.gni` or an edit to the converter
    re-runs the conversion on the next build.
    """
    root = checkout_root(rctx).get_child(_GN_ROOT)
    converter = checkout_root(rctx).get_child(_CONVERTER)
    depfile = rctx.path("gn_to_bazel.d")
    arguments = [
        _host_dart(rctx),
        converter.get_child("bin/gn_to_bazel.dart"),
        "--root",
        root,
        "--gn",
        root.get_child("flutter/third_party/gn/gn"),
        "--out-dir",
        rctx.path(""),
        "--repository",
        rctx.attr.gn_repository,
        "--depfile",
        depfile,
        "--buildifier",
        "none",
    ] + [
        checkout_root(rctx).get_child(file)
        for file in rctx.attr.gn_build_files
    ]
    result = rctx.execute(arguments, timeout = 600)
    if result.return_code != 0:
        fail("synced_repository(%s): gn_to_bazel failed:\n%s%s" % (rctx.name, result.stdout, result.stderr))
    for line in rctx.read(depfile).splitlines():
        if line:
            rctx.watch(line)
    rctx.delete(depfile)
    rctx.watch_tree(converter.get_child("lib"))
    rctx.watch_tree(converter.get_child("bin"))

def _synced_repository_impl(rctx):
    if rctx.attr.build_file != None and rctx.attr.build_file_content:
        fail("synced_repository(%s): specify at most one of build_file and build_file_content" % rctx.name)
    converting = bool(rctx.attr.gn_build_files)
    if converting and (rctx.attr.build_file != None or rctx.attr.build_file_content):
        fail("synced_repository(%s): gn_build_files and an overlay BUILD file are mutually exclusive" % rctx.name)
    if converting != bool(rctx.attr.gn_repository):
        fail("synced_repository(%s): gn_build_files and gn_repository go together" % rctx.name)
    overlaying = converting or rctx.attr.build_file != None or bool(rctx.attr.build_file_content)

    source = checkout_root(rctx).get_child(rctx.attr.path)
    if not source.exists or not source.is_dir:
        fail(
            "synced_repository(%s): %s does not exist. It is populated by " % (rctx.name, source) +
            "`gclient sync`; run it from the repository root (see DEPS).",
        )

    _link_tree(rctx, source, overlaying)
    if converting:
        _link_secondary(rctx)
        _convert_gn(rctx)
    else:
        _write_build_file(rctx, rctx.attr.build_file, rctx.attr.build_file_content)
    _mark_repository_boundary(rctx)

def _link_secondary(rctx):
    """Mirrors what sits beside a secondary-tree BUILD.gn into the repository.

    GN's secondary source tree (`//flutter/build/secondary/`) holds build
    files for directories that cannot carry their own; files beside such a
    BUILD.gn (expat's `expat_config/`) belong to the directory it stands in
    for, which is this repository. The converter maps their GN paths the
    same way.
    """
    if not rctx.attr.gn_secondary_dir:
        return
    secondary = checkout_root(rctx).get_child(rctx.attr.gn_secondary_dir)
    for child in secondary.readdir():
        name = child.basename
        if name in _BUILD_FILE_NAMES or name == "BUILD.gn" or name.endswith(".gni"):
            continue
        if rctx.path(name).exists:
            fail("synced_repository(%s): %s exists both in the synced tree and beside its secondary BUILD.gn" % (rctx.name, name))
        rctx.symlink(child, name)

synced_repository = repository_rule(
    implementation = _synced_repository_impl,
    doc = "A repository whose contents are a directory populated by `gclient sync`, consumed in place.",
    attrs = {
        "path": attr.string(
            mandatory = True,
            doc = "Directory relative to the repository root, as listed in DEPS (for example `engine/src/flutter/third_party/icu`).",
        ),
        "build_file": attr.label(
            allow_single_file = True,
            doc = "Overlay BUILD file for the repository root. Replaces the upstream root BUILD file, if " +
                  "any, and hides upstream BUILD files in subdirectories.",
        ),
        "build_file_content": attr.string(
            doc = "Inline overlay BUILD file content; mutually exclusive with `build_file`.",
        ),
        "gn_build_files": attr.string_list(
            doc = "GN build files (relative to the repository root) that tools/gn_to_bazel converts into " +
                  "this repository's BUILD files at fetch time; hides upstream BUILD files like an overlay.",
        ),
        "gn_repository": attr.string(
            doc = "With gn_build_files: `@name=//gn/dir` naming this repository and the GN directory " +
                  "that is its root (the converter's --repository). The converted files become the " +
                  "repository's packages.",
        ),
        "gn_secondary_dir": attr.string(
            doc = "With gn_build_files: the directory of GN's secondary source tree that stands in for " +
                  "the repository's root, whose files other than build files are mirrored into the " +
                  "repository.",
        ),
    },
    # The repository only symlinks into the checkout, so it must be re-created
    # when the checkout layout changes rather than restored from a cache.
    local = True,
)

# ---------------------------------------------------------------------------
# cipd_package
# ---------------------------------------------------------------------------

_CIPD_DOWNLOAD_URL = "https://chrome-infra-packages.appspot.com/dl/{package}/+/{version}"

def cipd_download_url(package, version):
    """Returns the HTTPS URL that serves `version` of the CIPD `package` as a zip archive.

    Args:
      package: fully resolved CIPD package name (no `${platform}` template).
      version: an instance id, a ref, or a `key:value` tag.
    """
    if "${" in package:
        fail("cipd_download_url: unresolved template in package name %r" % package)

    # Colons would end up in Bazel's download cache file name, which breaks on
    # Windows; CIPD accepts the encoded form.
    return _CIPD_DOWNLOAD_URL.format(package = package, version = version.replace(":", "%3A"))

def _cipd_package_impl(rctx):
    if rctx.attr.build_file != None and rctx.attr.build_file_content:
        fail("cipd_package(%s): specify at most one of build_file and build_file_content" % rctx.name)

    url = cipd_download_url(rctx.attr.package, rctx.attr.version)
    download = rctx.download_and_extract(
        url = url,
        type = "zip",
        sha256 = rctx.attr.sha256,
        canonical_id = url,
    )

    _write_build_file(rctx, rctx.attr.build_file, rctx.attr.build_file_content)
    _mark_repository_boundary(rctx)

    if rctx.attr.sha256:
        return None

    # Tell Bazel how to make this fetch reproducible (printed with --verbose).
    attrs = {name: getattr(rctx.attr, name) for name in _CIPD_PACKAGE_ATTRS if getattr(rctx.attr, name)}
    attrs["name"] = rctx.name
    attrs["sha256"] = download.sha256
    return attrs

_CIPD_PACKAGE_ATTRS = {
    "package": attr.string(
        mandatory = True,
        doc = "Fully resolved CIPD package name, for example `fuchsia/third_party/clang/linux-amd64`.",
    ),
    "version": attr.string(
        mandatory = True,
        doc = "CIPD instance id, ref, or `key:value` tag, exactly as written in DEPS.",
    ),
    "sha256": attr.string(
        doc = "sha256 of the zip archive CIPD serves for this instance. Optional, but " +
              "without it the download is not shared through the repository cache.",
    ),
    "build_file": attr.label(
        allow_single_file = True,
        doc = "BUILD file for the repository root.",
    ),
    "build_file_content": attr.string(
        doc = "Inline BUILD file content; mutually exclusive with `build_file`.",
    ),
}

cipd_package = repository_rule(
    implementation = _cipd_package_impl,
    doc = "A repository populated by downloading one CIPD package instance over HTTPS.",
    attrs = _CIPD_PACKAGE_ATTRS,
)

# ---------------------------------------------------------------------------
# engine_version_repository
# ---------------------------------------------------------------------------

_VERSION_BZL = """\
# Generated by engine_version_repository (build/bazel/repositories.bzl); do not edit.

\"\"\"The engine's version strings: shell/version/version.gni's arguments.\"\"\"

ENGINE_VERSION = {engine_version}
CONTENT_HASH = {content_hash}
SKIA_VERSION = {skia_version}
DART_VERSION = {dart_version}
"""

_VERSION_BUILD = """\
# Generated by engine_version_repository (build/bazel/repositories.bzl); do not edit.

package(default_visibility = ["//visibility:public"])

exports_files(["version.bzl"])
"""

# Override the values read from the checkout (a build without git, or one
# that must reproduce another's version strings).
_ENGINE_VERSION_ENV = "FLUTTER_BAZEL_ENGINE_VERSION"
_CONTENT_HASH_ENV = "FLUTTER_BAZEL_CONTENT_HASH"

def _git(rctx, root, args):
    result = rctx.execute(["git", "-C", str(root)] + args)
    if result.return_code != 0:
        fail("engine_version: git %s failed in %s: %s" % (" ".join(args), root, result.stderr))
    return result.stdout.strip()

def _watch_head(rctx, root):
    """Re-runs the rule when HEAD moves: .git/HEAD, the ref it names, packed-refs."""
    git_dir = rctx.path(_git(rctx, root, ["rev-parse", "--absolute-git-dir"]))
    common_dir = rctx.path(_git(rctx, root, ["rev-parse", "--path-format=absolute", "--git-common-dir"]))
    head = git_dir.get_child("HEAD")
    rctx.watch(head)
    content = rctx.read(head).strip()
    if content.startswith("ref: "):
        rctx.watch(rctx.path(str(common_dir) + "/" + content[len("ref: "):]))
    rctx.watch(common_dir.get_child("packed-refs"))

def _content_hash(rctx, root):
    script = root.get_child("bin", "internal", "content_aware_hash")
    if rctx.os.name.lower().startswith("windows"):
        command = ["powershell.exe", "-ExecutionPolicy", "Bypass", str(script) + ".ps1"]
    else:
        command = [str(script) + ".sh"]
    result = rctx.execute(command, working_directory = str(root))
    if result.return_code != 0:
        fail("engine_version: %s failed: %s" % (command[-1], result.stderr))
    return result.stdout.strip()

def _engine_version_repository_impl(rctx):
    root = checkout_root(rctx)
    engine_version = rctx.getenv(_ENGINE_VERSION_ENV)
    content_hash = rctx.getenv(_CONTENT_HASH_ENV)
    if engine_version == None or content_hash == None:
        _watch_head(rctx, root)
        if engine_version == None:
            engine_version = _git(rctx, root, ["rev-parse", "HEAD"])
        if content_hash == None:
            content_hash = _content_hash(rctx, root)
    rctx.file("BUILD.bazel", _VERSION_BUILD)
    rctx.file("version.bzl", _VERSION_BZL.format(
        engine_version = repr(engine_version),
        content_hash = repr(content_hash),
        skia_version = repr(rctx.attr.skia_version),
        dart_version = repr(rctx.attr.dart_version),
    ))
    rctx.file("REPO.bazel", "")

engine_version_repository = repository_rule(
    implementation = _engine_version_repository_impl,
    doc = """The engine's version strings as a `version.bzl` of four constants.

`tools/gn` sets shell/version/version.gni's arguments when it generates a GN
build: `engine_version` is the checkout's `git rev-parse HEAD`,
`content_hash` the output of bin/internal/content_aware_hash, and
`skia_version` and `dart_version` the HEADs of the synced Skia and Dart
trees, which are their DEPS pins. This rule does the same at fetch time:
the first two from git (re-read when HEAD moves; `FLUTTER_BAZEL_ENGINE_VERSION`
and `FLUTTER_BAZEL_CONTENT_HASH` in the environment override them), the
last two from deps.lock.bzl through the attributes.""",
    attrs = {
        "skia_version": attr.string(mandatory = True, doc = "Skia's DEPS revision."),
        "dart_version": attr.string(mandatory = True, doc = "The Dart SDK's DEPS revision."),
    },
    # Read from the checkout; re-created at every server start rather than
    # restored from a cache.
    local = True,
)
