# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os.path
import unittest

from fakes import FakeMojomFile
from fetcher.dependency import Dependency
from fetcher.mojom_directory import MojomDirectory
from fetcher.mojom_file import MojomFile
from fetcher.repository import Repository


class TestMojomDirectory(unittest.TestCase):
  def test_build_gn_path(self):
    directory = MojomDirectory(
        "/base/repo/third_party/external/domokit.org/bar/baz")
    self.assertEquals(
        "/base/repo/third_party/external/domokit.org/bar/baz/BUILD.gn",
        directory.get_build_gn_path())

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
    directory = MojomDirectory(
        "/base/repo/third_party/external/domokit.org/bar/baz")
    directory.add_mojom(mojom)
    params = directory.get_jinja_parameters([])
    self.assertEquals(
        {"group_name": "baz",
         "mojoms": [{
             "target_name": "foo",
             "filename": "foo.mojom",
             "import_dirs": [".."],
             "mojo_sdk_deps": ["mojo/public/interfaces/application"],
             "deps": [
                 '//third_party/external/example.com/dir:example',
                 '//third_party/external/example.com/dir:dir_mojom',
                 ':buzz',
                 '../foo:bar']
             }]}, params)

