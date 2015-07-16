# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import io
import os.path
import unittest

from fakes import FakeMojomFile
from fetcher.mojom_directory import MojomDirectory
from fetcher.repository import Repository
from mojom_gn import BuildGNGenerator

class FakeRepository(Repository):
  def get_all_external_mojom_directories(self):
    mojom = FakeMojomFile(
        self, os.path.join(self.get_external_directory(),
                           "domokit.org/bar/baz/foo.mojom"))
    mojom.add_dependency("example.com/dir/example.mojom")
    mojom.add_dependency("example.com/dir/dir.mojom")
    mojom.add_dependency("buzz.mojom")
    mojom.add_dependency("foo/bar.mojom")
    mojom.add_dependency(
        "mojo/public/interfaces/application/shell.mojom")
    directory = MojomDirectory(
        os.path.join(self.get_external_directory(),
                     "domokit.org/bar/baz"))
    directory.add_mojom(mojom)
    return [directory]


class FakeBuildGNGenerator(BuildGNGenerator):
  def __init__(self, *args, **kwargs):
    self.opened_files = {}
    BuildGNGenerator.__init__(self, *args, **kwargs)

  def _open(self, filepath, mode):
    if mode != "w":
      raise Exception("Invalid mode " + str(mode))
    self.opened_files[filepath] = io.StringIO()
    return self.opened_files[filepath]


class TestBuildGNGenerator(unittest.TestCase):
  BAZ_BUILD_GN = u"""import("//build/module_args/mojo.gni")
import("$mojo_sdk_root/mojo/public/tools/bindings/mojom.gni")

mojom("baz") {
  deps = [
    ":foo",
  ]
}

mojom("foo") {
  sources = [
    "foo.mojom",
  ]
  import_dirs = [
    get_path_info("..", "abspath"),
  ]
  mojo_sdk_deps = [
    "mojo/public/interfaces/application",
  ]
  deps = [
    "//third_party/external/example.com/dir:example",
    "//third_party/external/example.com/dir:dir_mojom",
    ":buzz",
    "../foo:bar",
  ]
}"""
  def test_generate(self):
    self.maxDiff = None
    repository = FakeRepository("/base/repo", "third_party/external")
    gn_generator = FakeBuildGNGenerator(repository, os.path.abspath(
        os.path.join(os.path.dirname(__file__),
                     "../../../public/tools/mojom_fetcher")))
    gn_generator.generate()
    output_stream = gn_generator.opened_files[
        "/base/repo/third_party/external/domokit.org/bar/baz/BUILD.gn"]
    self.assertEquals(prepare_string(self.BAZ_BUILD_GN),
                      prepare_string(output_stream.getvalue()))

def prepare_string(value):
  lines = value.split("\n")
  lines = map(lambda l: l.strip().replace(" ", ""), lines)
  lines = filter(lambda l: not l.startswith("#"), lines)
  return ''.join(lines)

