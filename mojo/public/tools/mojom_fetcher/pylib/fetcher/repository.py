# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os

from fetcher.dependency import Dependency
from fetcher.mojom_directory import MojomDirectory
from fetcher.mojom_file import MojomFile
from mojom.parse.parser import Parse


class Repository(object):
  """Repository represents a code repository on the local disc."""
  def __init__(self, root_dir, external_dir):
    """root_dir represents the root of the repository;
    external_dir is the relative path of the external directory within the
    repository (so, relative to root_dir)
    """
    self._root_dir = os.path.normpath(root_dir)
    self._external_dir = external_dir

  def get_repo_root_directory(self):
    return self._root_dir

  def get_external_directory(self):
    return os.path.join(self._root_dir, self._external_dir)

  def get_external_suffix(self):
    return self._external_dir

  def _os_walk(self, root_directory):
    # This method is included for dependency injection
    return os.walk(root_directory)

  def _open(self, filename):
    # This method is included for dependency injection
    return open(filename)

  def _get_all_mojom_in_directory(self, root_directory):
    mojoms = []
    for dirname, _, files in self._os_walk(root_directory):
      for f in files:
        if f.endswith(".mojom"):
          mojoms.append(os.path.join(dirname,f))
    return mojoms

  def _resolve_dependencies(self, dependencies, mojoms):
    """Resolve dependencies between discovered mojoms, so we know which are the
    missing ones."""
    missing = []
    for dependency in dependencies:
      found = False
      for search_path in dependency.get_search_path_for_dependency():
        if os.path.normpath(
            os.path.join(search_path,
                         dependency.get_imported())) in mojoms:
          found = True
          break
      if not found:
        missing.append(dependency)
    return missing

  def get_missing_dependencies(self):
    """get_missing_dependencies returns a set of dependencies that are required
    by mojoms in this repository but not available.
    """
    # Update the list of available mojoms in this repository.
    mojoms = set(self._get_all_mojom_in_directory(self._root_dir))

    # Find all declared dependencies
    needed_deps = set([])
    for mojom in mojoms:
      with self._open(mojom) as f:
        source = f.read()
        tree = Parse(source, mojom)
        for dep in tree.import_list:
          needed_deps.add(Dependency(self, dep.filename, dep.import_filename))

    missing_deps = self._resolve_dependencies(needed_deps, mojoms)

    return missing_deps

  def get_external_urls(self):
    """Get all external mojom files in this repository, by urls (without
    scheme)."""
    mojoms = set(self._get_all_mojom_in_directory(
        self.get_external_directory()))
    urls = []
    for mojom in mojoms:
      urls.append(os.path.relpath(mojom, self.get_external_directory()))
    return urls

  def get_all_external_mojom_directories(self):
    """Get all external directories populated with their mojom files."""
    mojoms = self._get_all_mojom_in_directory(self.get_external_directory())
    directories = {}
    for mojom_path in mojoms:
      directory_path = os.path.dirname(mojom_path)
      directory = directories.setdefault(
          directory_path, MojomDirectory(directory_path))
      with self._open(mojom_path) as f:
        source = f.read()
        tree = Parse(source, mojom_path)
        mojom = MojomFile(self, mojom_path)
        directory.add_mojom(mojom)
        for dep in tree.import_list:
          mojom.add_dependency(dep.import_filename)
    return directories.values()






