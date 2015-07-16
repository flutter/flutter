# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import io
import os.path
import unittest

from fetcher.dependency import Dependency

# Fake repository for testing
from fakes import FakeRepository


class TestRepository(unittest.TestCase):
  def test_init(self):
    repository = FakeRepository("/path/to/repo", "third_party/external")
    self.assertEqual("/path/to/repo", repository.get_repo_root_directory())
    self.assertEqual("/path/to/repo/third_party/external",
                     repository.get_external_directory())

  def test_get_missing_dependencies(self):
    repository = FakeRepository("/path/to/repo", "third_party/external")
    missing_deps = repository.get_missing_dependencies()
    self.assertEquals(["/path/to/repo"], repository.directories_walked)
    # Order is not important
    self.assertIn("/path/to/repo/foo/foo.mojom", repository.files_opened)
    self.assertIn("/path/to/repo/foo/bar/baz.mojom", repository.files_opened)
    self.assertIn(
        "/path/to/repo/third_party/external/services.domokit.org/foo/fiz.mojom",
        repository.files_opened)
    self.assertEquals(3, len(repository.files_opened))

    self.assertEquals([Dependency(repository,
        "/path/to/repo/third_party/external/services.domokit.org/foo/fiz.mojom",
        "services.fiz.org/foo/bar.mojom")], missing_deps)

  def test_get_external_urls(self):
    repository = FakeRepository("/path/to/repo", "third_party/external")
    urls = repository.get_external_urls()
    self.assertEquals(["/path/to/repo/third_party/external"],
                      repository.directories_walked)
    self.assertEquals(["services.domokit.org/foo/fiz.mojom"], urls)
