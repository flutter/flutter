# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import io
import os.path

from fetcher.dependency import Dependency
from fetcher.mojom_file import MojomFile
from fetcher.repository import Repository

class FakeRepository(Repository):
  data1 = """module test;
import "bar/baz.mojom";
interface Foo {};"""
  data2 = """module test;
import "services.domokit.org/foo/fiz.mojom";
interface Baz {};"""
  data3 = """module test;
import "services.fiz.org/foo/bar.mojom";
interface Fiz {};"""
  data4 = """module test;
interface SomeInterface {};"""

  def __init__(self, *args, **kwargs):
    self.files_opened = []
    self.directories_walked = []
    self.all_files_available = False

    Repository.__init__(self, *args, **kwargs)

  def get_walk_base(self, directory):
    data_base = [
        (directory, ["foo", "third_party"], []),
        (os.path.join(directory, "foo"), ["bar"], ["foo.mojom"]),
        (os.path.join(directory, "foo/bar"), [], ["baz.mojom"]),
        (os.path.join(directory, "third_party"), ["external"], []),
        (os.path.join(directory, "third_party/external"),
         ["services.domokit.org"], []),
        (os.path.join(directory,
                      "third_party/external/services.domokit.org"),
         ["foo"], []),
        (os.path.join(directory,
                      "third_party/external/services.domokit.org/foo"),
         [], ["fiz.mojom"])]
    if self.all_files_available:
      data_base.extend([
          (os.path.join(directory,
                      "third_party/external/services.fiz.org"),
           ["foo"], []),
          (os.path.join(directory,
                        "third_party/external/services.fiz.org/foo"),
           [], ["bar.mojom"])])
    return data_base

  def get_walk_external(self, directory):
    data_external = [
        (directory, ["services.domokit.org"], []),
        (os.path.join(directory, "services.domokit.org"),
         ["foo"], []),
        (os.path.join(directory, "services.domokit.org/foo"),
         [], ["fiz.mojom"])]
    if self.all_files_available:
      data_external.extend([
          (os.path.join(directory, "services.fiz.org"),
           ["foo"], []),
          (os.path.join(directory, "services.fiz.org/foo"),
           [], ["bar.mojom"])])
    return data_external


  def _open(self, f):
    self.files_opened.append(f)

    if "foo.mojom" in f:
      val = io.BytesIO(self.data1)
    elif "baz.mojom" in f:
      val = io.BytesIO(self.data2)
    elif "fiz.mojom" in f:
      val = io.BytesIO(self.data3)
    else:
      val = io.BytesIO(self.data4)
    return val

  def _os_walk(self, directory):
    self.directories_walked.append(directory)
    if directory == self._root_dir:
      return iter(self.get_walk_base(directory))
    else:
      return iter(self.get_walk_external(directory))


class FakeDependency(Dependency):
  IN_FILESYSTEM = [
      "/base/repo/third_party/external/example.com/dir/example.mojom",
      "/base/repo/third_party/external/example.com/dir/dir.mojom",
      "/base/repo/third_party/external/domokit.org/bar/baz/buzz.mojom",
      "/base/repo/third_party/external/domokit.org/bar/foo/bar.mojom",
      ]

  def _os_path_exists(self, path):
    if path in self.IN_FILESYSTEM:
      return True
    elif os.path.join("/base/repo", path) in self.IN_FILESYSTEM:
      return True
    else:
      return False


class FakeMojomFile(MojomFile):
  def add_dependency(self, dependency):
    """Declare a new dependency of this mojom."""
    self.deps.append(FakeDependency(self._repository, self.name, dependency))
