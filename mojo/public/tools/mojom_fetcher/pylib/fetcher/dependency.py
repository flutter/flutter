# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os


class DuplicateDependencyFoundException(Exception):
  """Two potentially matching files have been found that could satisfy this
  dependency, so the right one cannot be selected automatically."""
  pass


class DependencyNotFoundException(Exception):
  """The dependency hasn't been found on the local filesystem."""
  pass


class Dependency(object):
  """Dependency represents an import request from one mojom file to another.
  """
  def __init__(self, repository, importer, imported):
    self._repository = repository
    self._importer_filename = os.path.normpath(importer)
    self._imported_filename = os.path.normpath(imported)

  def __str__(self):
    return str(self.__dict__)

  def __eq__(self, other):
    return self.__dict__ == other.__dict__

  def get_importer(self):
    """Returns the name and full path of the file doing the import."""
    return self._importer_filename

  def get_imported(self):
    """Returns the imported file (filename and path)."""
    return self._imported_filename

  def is_sdk_dep(self):
    """Returns whether this dependency is from the mojo SDK."""
    return (self._imported_filename.startswith("mojo/public/") or
            self._imported_filename.startswith("//mojo/public/"))

  def _is_in_external(self):
    """Returns whether this dependency is under the external directory."""
    common = os.path.commonprefix((self._repository.get_external_directory(),
                                   self._importer_filename))
    return common == self._repository.get_external_directory()

  def maybe_is_a_url(self):
    """Returns whether this dependency may be pointing to a downloadable
    ressource."""
    if self._is_in_external() and not self.is_sdk_dep():
      # External dependencies may refer to other dependencies by relative path,
      # so they can always be URLs.
      return True

    base, _ = self._imported_filename.split(os.path.sep, 1)
    if not '.' in base:
      # There is no dot separator in the first part of the path; it cannot be a
      # URL.
      return False
    return True

  def generate_candidate_urls(self):
    """Generates possible paths where to download this dependency. It is
    expected that at most one of them should work."""
    candidates = []

    base, _ = self._imported_filename.split(os.path.sep, 1)
    if '.' in base and not base.startswith('.'):
      # This import may be an absolute URL path (without scheme).
      candidates.append(self._imported_filename)

    # External dependencies may refer to other dependencies by relative path.
    if self._is_in_external():
      directory = os.path.relpath(os.path.dirname(self._importer_filename),
                                  self._repository.get_external_directory())

      # This is to handle the case where external dependencies use
      # imports relative to a directory upper in the directory structure. As we
      # don't know which directory, we need to go through all of them.
      while len(directory) > 0:
        candidates.append(os.path.join(directory, self._imported_filename))
        directory = os.path.dirname(directory)
    return candidates

  def get_search_path_for_dependency(self):
    """Return all possible search paths for this dependency."""

    # Root directory and external directory are always included.
    search_paths = set([self._repository.get_repo_root_directory(),
                        self._repository.get_external_directory()])
    # Local import paths
    search_paths.add(os.path.dirname(self._importer_filename))

    if self._is_in_external():
      directory = os.path.dirname(self._importer_filename)

      # This is to handle the case where external dependencies use
      # imports relative to a directory upper in the directory structure. As we
      # don't know which directory, we need to go through all of them.
      while self._repository.get_external_directory() in directory:
        search_paths.add(directory)
        directory = os.path.dirname(directory)
    return search_paths

  def is_sdk_dep(self):
    """Returns whether this dependency is from the mojo SDK."""
    return self._imported_filename.startswith("mojo/public/")

  def _os_path_exists(self, path):
    return os.path.exists(path)

  def get_target_and_import(self, extra_import_dirs):
    """Returns a tuple (target, import_directory) for this dependency.
    import_directory may be Null. extra_import_dirs lists directories that
    should be searched for this dependency in addition to the ones directly
    above the importing file.
    """
    directory = os.path.dirname(self.get_importer())
    if self.is_sdk_dep():
      return (os.path.dirname(self.get_imported()), None)

    # We need to determine if it is a relative path or not
    if self._os_path_exists(os.path.join(directory, self.get_imported())):
      # This is a relative import path
      dependency_path = os.path.normpath(os.path.join(directory,
                                                      self.get_imported()))
      return (target_from_path(os.path.relpath(dependency_path, directory)),
              None)

    if self._os_path_exists(
        os.path.join(self._repository.get_external_directory(),
                     self.get_imported())):
      # This is an "absolute" external dependency, specified by full path
      # relative to the external directory.
      return (target_from_path(
          "//" + os.path.join(self._repository.get_external_suffix(),
                              self.get_imported())), None)

    # We assume that the dependency is specified relative to a directory
    # above this one, so we search all of them for a correspondence. If we
    # find one, we return an import directory.
    result = None
    for import_dir_candidate in (list(self.get_search_path_for_dependency())
                                  + extra_import_dirs):
      dep_mojom_path = os.path.join(
          import_dir_candidate, self.get_imported())
      if self._os_path_exists(dep_mojom_path):
        if result != None:
          raise DuplicateDependencyFoundException(self.get_imported())
        import_dir = os.path.relpath(import_dir_candidate, directory)
        result = (target_from_path(os.path.relpath(
            dep_mojom_path, directory)), import_dir)
    if result == None:
      raise DependencyNotFoundException(self.get_imported())
    return result


def group_target_name(directory):
  """Returns the name of the group target for a given directory."""
  return os.path.basename(directory)

def _target_dir_from_path(path):
  directory, filename = os.path.split(path)
  target, _ = os.path.splitext(filename)
  if target == group_target_name(directory):
    target = target + "_mojom"
  return directory, target

def target_name_from_path(path):
  return _target_dir_from_path(path)[1]


def target_from_path(path):
  return ':'.join(_target_dir_from_path(path))

