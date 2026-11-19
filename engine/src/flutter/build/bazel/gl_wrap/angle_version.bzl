# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""ANGLE's revision, for its version string.

ANGLE's commit_id.py writes the commit into a header its version string is
made of. In a GN build it asks git; the trees Bazel builds from hold no git
state, so it takes the ANGLE_UPSTREAM_HASH variable instead, which is the
DEPS pin's revision: for the converted ANGLE's action (@angle, the
converter's scriptEnvironment) and for the wrapped GN build of a Mac's
(BUILD.bazel).
"""

load("//build_defs/repositories:deps.lock.bzl", "GIT_DEPS")

# The first twelve digits, as commit_id.py abbreviates the hash git gives it.
ANGLE_UPSTREAM_HASH = GIT_DEPS["engine/src/flutter/third_party/angle"]["revision"][:12]
