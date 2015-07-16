# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os.path
import unittest

from fetcher.mojom_file import MojomFile
from fetcher.dependency import Dependency
from fetcher.repository import Repository
from fakes import FakeDependency, FakeMojomFile


class TestMojomFile(unittest.TestCase):
  def test_add_dependency(self):
    mojom = MojomFile(Repository("/base/repo", "third_party/external"),
                      "mojom_name")
    mojom.add_dependency("dependency_name")
    self.assertEqual(1, len(mojom.deps))
    self.assertEqual("mojom_name", mojom.deps[0].get_importer())
    self.assertEqual("dependency_name", mojom.deps[0].get_imported())

  def test_jinja_parameters(self):
    mojom = FakeMojomFile(
        Repository("/base/repo", "third_party/external"),
        "/base/repo/third_party/external/domokit.org/bar/baz/foo.mojom")
    mojom.add_dependency("example.com/dir/example.mojom")
    mojom.add_dependency("example.com/dir/dir.mojom")
    mojom.add_dependency("buzz.mojom")
    mojom.add_dependency("foo/bar.mojom")
    mojom.add_dependency(
        "mojo/public/interfaces/application/shell.mojom")
    params = mojom.get_jinja_parameters([])
    self.assertEquals({
        "target_name": "foo",
        "filename": "foo.mojom",
        "import_dirs": [".."],
        "mojo_sdk_deps": ["mojo/public/interfaces/application"],
        "deps": [
            '//third_party/external/example.com/dir:example',
            '//third_party/external/example.com/dir:dir_mojom',
            ':buzz',
            '../foo:bar']
        }, params)
