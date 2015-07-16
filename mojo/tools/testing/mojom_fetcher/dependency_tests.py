# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import unittest

from fetcher.dependency import Dependency

class FakeRepository(object):
  def get_repo_root_directory(self):
    return "/base/repo"

  def get_external_directory(self):
    return "/base/repo/third_party/external"

class TestDependency(unittest.TestCase):
  def test_importer_imported(self):
    dep = Dependency(FakeRepository(),
                     "/base/repo/services/foo/../bar/bar.mojom",
                     "mojo/public/./../public/baz.mojom")

    self.assertEqual("/base/repo/services/bar/bar.mojom", dep.get_importer())
    self.assertEqual("mojo/public/baz.mojom", dep.get_imported())

  def test_is_sdk_dep(self):
    # Not in SDK
    dep = Dependency(FakeRepository(),
                     "/base/repo/services/bar/bar.mojom",
                     "mojo/public/../foo/baz.mojom")
    self.assertFalse(dep.is_sdk_dep())

    # In SDK
    dep = Dependency(FakeRepository(),
                     "/base/repo/services/bar/bar.mojom",
                     "mojo/public/baz.mojom")
    self.assertTrue(dep.is_sdk_dep())

  def test_maybe_is_a_url(self):
    # Not a URL
    dep = Dependency(FakeRepository(),
                     "/base/repo/services/bar/bar.mojom",
                     "mojo/foo/baz.mojom")
    self.assertFalse(dep.maybe_is_a_url())

    # URL import from non-external mojom
    dep = Dependency(FakeRepository(),
                     "/base/repo/services/bar/bar.mojom",
                     "foo.bar.com/foo/baz.mojom")
    self.assertTrue(dep.maybe_is_a_url())

    # URL import from an external mojom
    dep = Dependency(FakeRepository(),
                     "/base/repo/third_party/external/" +
                     "services.bar.com/bar/bar.mojom",
                     "foo.bar.com/foo/baz.mojom")
    self.assertTrue(dep.maybe_is_a_url())

    # relative import from an external mojom
    dep = Dependency(
        FakeRepository(),
        "/base/repo/third_party/external/services.bar.com/bar/bar.mojom",
        "foo/baz.mojom")
    self.assertTrue(dep.maybe_is_a_url())

    # external mojom importing SDK dep
    dep = Dependency(
        FakeRepository(),
        "/base/repo/third_party/external/services.bar.com/bar/bar.mojom",
        "mojo/public/foo/baz.mojom")
    self.assertFalse(dep.maybe_is_a_url())

  def test_generate_candidate_urls_relative(self):
    dep = Dependency(
        FakeRepository(),
        "/base/repo/third_party/external/" +
            "services.bar.com/bar/interfaces/bar.mojom",
        "foo/baz.mojom")
    self.assertTrue(dep.maybe_is_a_url())
    candidate_urls = dep.generate_candidate_urls()
    self.assertEqual(["services.bar.com/bar/interfaces/foo/baz.mojom",
                       "services.bar.com/bar/foo/baz.mojom",
                       "services.bar.com/foo/baz.mojom"], candidate_urls)

  def test_generate_candidate_urls_absolute(self):
    dep = Dependency(FakeRepository(),
                     "/base/repo/services/bar/interfaces/bar.mojom",
                     "services.foo.com/foo/baz.mojom")
    self.assertTrue(dep.maybe_is_a_url())
    candidate_urls = dep.generate_candidate_urls()
    self.assertEqual(["services.foo.com/foo/baz.mojom"], candidate_urls)

  def test_get_search_path_for_dependency(self):
    # Absolute
    dep = Dependency(FakeRepository(),
                     "/base/repo/services/bar/interfaces/bar.mojom",
                     "services.foo.com/foo/baz.mojom")
    self.assertEqual(set(["/base/repo/services/bar/interfaces",
                          "/base/repo", "/base/repo/third_party/external"]),
                     dep.get_search_path_for_dependency())

    # Relative
    dep = Dependency(
        FakeRepository(),
        "/base/repo/third_party/external/services.foo.com/bar/bar.mojom",
        "baz/baz.mojom")
    self.assertEqual(set([
        "/base/repo", "/base/repo/third_party/external",
        "/base/repo/third_party/external/services.foo.com/bar",
        "/base/repo/third_party/external/services.foo.com"]),
                     dep.get_search_path_for_dependency())
