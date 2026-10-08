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
  ship no Bazel build files or whose upstream ones should not be used.

* `cipd_package`: a repository populated by downloading a CIPD package over
  HTTPS (the same mechanism Skia uses). It needs no `cipd` client and no
  `gclient sync`; the pins come from `deps.lock.bzl`.

Both produce the same layout, so a dependency can move from one to the other
without touching the targets that use it.
"""

_BUILD_FILE_NAMES = ("BUILD", "BUILD.bazel")
_BOUNDARY_FILE_NAMES = ("MODULE.bazel", "REPO.bazel", "WORKSPACE", "WORKSPACE.bazel")

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

# ---------------------------------------------------------------------------
# synced_repository
# ---------------------------------------------------------------------------

def _synced_repository_impl(rctx):
    if rctx.attr.build_file != None and rctx.attr.build_file_content:
        fail("synced_repository(%s): specify at most one of build_file and build_file_content" % rctx.name)

    source = rctx.workspace_root.get_child(rctx.attr.path)
    if not source.exists or not source.is_dir:
        fail(
            "synced_repository(%s): %s does not exist. It is populated by " % (rctx.name, source) +
            "`gclient sync`; run it from the repository root (see DEPS).",
        )

    overlaying = rctx.attr.build_file != None or bool(rctx.attr.build_file_content)

    # readdir() also registers a watch on the directory's entries, so adding or
    # removing a top-level entry (for example after a roll) refreshes the
    # repository. Changes inside the entries are tracked like any source file.
    for child in source.readdir():
        name = child.basename
        if name in _BOUNDARY_FILE_NAMES:
            continue
        if overlaying and name in _BUILD_FILE_NAMES:
            # The upstream root BUILD file is replaced by the overlay. Upstream
            # BUILD files in subdirectories remain visible as packages.
            continue
        rctx.symlink(child, name)

    _write_build_file(rctx, rctx.attr.build_file, rctx.attr.build_file_content)
    _mark_repository_boundary(rctx)

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
            doc = "Overlay BUILD file for the repository root. Replaces any upstream root BUILD file.",
        ),
        "build_file_content": attr.string(
            doc = "Inline overlay BUILD file content; mutually exclusive with `build_file`.",
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
