# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Bazel counterparts of the templates in testing.gni."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")
load("@rules_cc//cc:defs.bzl", "cc_library")

# Where tests run from: the runfiles directory of the main repository. Paths
# below are relative to it, so nothing absolute is compiled into a test. The
# source directory has GN's trailing slash (rebase_path("//") ends in one).
_SOURCE_DIR = "engine/src/"
_TESTING_ASSETS_DIR = "engine/src/flutter/testing/assets"

# The URI the Dart compiler records for a source file of the tree, which a
# test looks a library up by (GetSourceUri): Dart sources are compiled under
# a virtual root scheme over the execution root, so the URI is
# machine-independent and the same in every sandbox.
_SOURCE_URI_PREFIX = "org-dartlang-root:///" + _SOURCE_DIR

def _quoted_define(name, value):
    return '%s=\\"%s\\"' % (name, value)

def flutter_test_fixtures(name, fixtures = [], visibility = None, **kwargs):
    """Declares the fixtures of a test binary, like GN's test_fixtures template.

    Creates a library named `name` that test binaries depend on. It defines
    the compiled-in default locations flutter::testing::GetSourcePath,
    GetFixturesPath and GetTestingAssetsPath fall back to, and carries the
    fixtures as runfiles. As in GN, the fixtures are copied into an `assets`
    directory next to the test (here `<package>/assets` under the runfiles
    root rather than under the GN target_gen_dir), so a test finds them at
    GetFixturesPath()/<basename>.

    Dart fixtures (GN's `dart_main`) are not supported yet; they need the
    Dart toolchain rules.

    Args:
      name: name of the library.
      fixtures: files to copy into the fixtures directory.
      visibility: visibility of the library.
      **kwargs: forwarded to the library (`tags`, ...).
    """
    package = native.package_name()
    fixtures_dir = paths.join(package, "assets")

    copies = []
    for fixture in fixtures:
        basename = paths.basename(fixture)
        out = paths.join("assets", basename)
        copy_file(
            name = "_cf_%s_%s" % (name, basename),
            src = fixture,
            out = out,
            allow_symlink = True,
            testonly = True,
            visibility = ["//visibility:private"],
        )
        copies.append(out)

    cc_library(
        name = name,
        testonly = True,
        srcs = ["//engine/src/flutter/testing:fixtures_location.cc"],
        local_defines = [
            _quoted_define("FLUTTER_TEST_SOURCE_DIR_DEFAULT", _SOURCE_DIR),
            _quoted_define("FLUTTER_TEST_FIXTURES_DIR_DEFAULT", fixtures_dir),
            _quoted_define("FLUTTER_TEST_TESTING_ASSETS_DIR_DEFAULT", _TESTING_ASSETS_DIR),
            _quoted_define("FLUTTER_TEST_SOURCE_URI_PREFIX_DEFAULT", _SOURCE_URI_PREFIX),
        ],
        data = copies,
        # The functions are referenced from testing.cc, which sits in an
        # archive linked before this one; make sure the object is kept.
        alwayslink = True,
        visibility = visibility,
        deps = ["//engine/src/flutter/testing:testing_core"],
        **kwargs
    )
