# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""`fetched_archive`: a tool of DEPS downloaded by Bazel, for a checkout without it.

The tools `gclient sync` installs -- the CIPD packages of DEPS (clang, the
prebuilt Dart SDK, gn, ninja, the hermetic Python, ...) and the sysroots its
hooks unpack -- are archives at fixed URLs. Where the checkout lacks a
tool's directory, its `synced_repository` (repositories.bzl) reads the
archive's contents from one of these instead, laid under the same `tree/`
as a fetched source tree (git_deps.bzl).

A repository of its own, like a fetched tree and for the same reason:
`synced_repository` is a local rule, run again at every server start, and a
download made there would be made again each time (the Android SDK is
3.9 GB). This one is fetched only when its pin changes. With its sha256
known (the lock has one for every CIPD package that exists) the download
comes from Bazel's repository cache, and the unpacked directory is kept
once, for every output base, in the repo contents cache (`reproducible`;
git_deps.bzl says the same of a fetched tree).
"""

load(":git_deps.bzl", "FETCHED_STAMP", "FETCHED_TREE_DIRECTORY", "fetch_stamp")

def _fetched_archive_impl(rctx):
    # Noted, since it is the build that downloads here and not gclient.
    print("fetched_archive(%s): downloading %s (%s), which is not in the checkout." % (
        rctx.name,
        rctx.attr.path,
        rctx.attr.url,
    ))  # buildifier: disable=print
    download = rctx.download_and_extract(
        url = rctx.attr.url,
        output = FETCHED_TREE_DIRECTORY,
        type = rctx.attr.type,
        sha256 = rctx.attr.sha256,
        canonical_id = rctx.attr.url,
        stripPrefix = rctx.attr.strip_prefix,
    )

    # A CIPD archive's own manifest, which `cipd ensure` does not install.
    rctx.delete(FETCHED_TREE_DIRECTORY + "/.cipdpkg")
    rctx.file("BUILD.bazel", "# A tool of DEPS downloaded by Bazel (build_defs/repositories/fetched_archive.bzl): %s/.\n" % FETCHED_TREE_DIRECTORY)
    rctx.file("REPO.bazel", "")

    # For what reads the tool, as a fetched tree's (git_deps.bzl).
    rctx.file(FETCHED_STAMP, fetch_stamp(rctx, rctx.attr.url))
    if rctx.attr.sha256:
        # Checked against its hash, the archive is the same wherever it is
        # fetched: another output base may take the unpacked directory as
        # it stands (Bazel's repo contents cache, the root .bazelrc).
        return rctx.repo_metadata(reproducible = True)

    # Tell Bazel how to make this fetch reproducible (printed with --verbose).
    attrs = {name: getattr(rctx.attr, name) for name in _ATTRS if getattr(rctx.attr, name)}
    attrs["name"] = rctx.name
    attrs["sha256"] = download.sha256
    return attrs

_ATTRS = {
    "path": attr.string(
        mandatory = True,
        doc = "The tool's directory as DEPS (or the sysroot hooks) name it, for messages.",
    ),
    "url": attr.string(
        mandatory = True,
        doc = "The archive: a CIPD package's download URL (repositories.bzl's cipd_download_url), a sysroot's tarball.",
    ),
    "type": attr.string(
        default = "zip",
        doc = "The archive's type, as download_and_extract takes it (`zip`, `tar.xz`).",
    ),
    "sha256": attr.string(
        doc = "The archive's sha256; without it the download is unverified and not shared through the repository cache.",
    ),
    "strip_prefix": attr.string(
        doc = "A directory of the archive that becomes the tree (the Mac's JDK bundle: `Contents/Home`).",
    ),
}

fetched_archive = repository_rule(
    implementation = _fetched_archive_impl,
    doc = "A tool of DEPS (a CIPD package, a sysroot tarball) downloaded and unpacked: for a checkout " +
          "that has no such directory.",
    attrs = _ATTRS,
)
