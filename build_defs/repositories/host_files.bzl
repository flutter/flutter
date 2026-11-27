# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Files of the machine that builds, which GN's build files name by absolute path, as a repository (`@host_files`).

GN's test_fixtures copy `/System/Library/Fonts/Apple Color Emoji.ttc` into
the text and Impeller test fixtures on a Mac (txt/BUILD.gn and
impeller/fixtures/BUILD.gn, under `host_os == "mac"`): a file of the
machine, not of the tree. Here each such path (HOST_FILE_PATHS, which the
converter knows too) that exists on this machine is a file of this
repository at the path less its leading slash --
`@host_files//:System/Library/Fonts/Apple Color Emoji.ttc` -- so that its
basename, which the fixtures' copy and the test's lookup go by, is the
file's own. A path that does not exist (every one of them off a Mac) is no
target; the generated files name it under the host's setting alone
(//engine/src/flutter/build/bazel:host_os_is_mac), which never holds there.
The symlink points at the machine's file, which Bazel reads as a source
file: its contents are part of every action key that depends on it.
"""

# The paths GN names, by the host OS that has them.
HOST_FILE_PATHS = {
    "mac": ["/System/Library/Fonts/Apple Color Emoji.ttc"],
}

def _host_files_impl(rctx):
    present = []
    for host_paths in HOST_FILE_PATHS.values():
        for path in host_paths:
            file = rctx.path(path)
            if not file.exists:
                continue
            rctx.symlink(file, path.lstrip("/"))
            present.append(path.lstrip("/"))
    rctx.file("BUILD.bazel", """# Files of this machine that GN's build files name by absolute path
# (build_defs/repositories/host_files.bzl): the ones that exist here.
package(default_visibility = ["//visibility:public"])

exports_files(%s)
""" % repr(present))

host_files = repository_rule(
    implementation = _host_files_impl,
    doc = "The files of this machine that GN names by absolute path, as targets (empty where none exists); see the file's docstring.",
    local = True,
)
