# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os

from fetcher.dependency import Dependency, target_name_from_path


class MojomFile(object):
  """Mojom represents an interface file at a given location in the
  repository."""
  def __init__(self, repository, name):
    self.name = name
    self._repository = repository
    self.deps = []

  def add_dependency(self, dependency):
    """Declare a new dependency of this mojom."""
    self.deps.append(Dependency(self._repository, self.name, dependency))

  def get_jinja_parameters(self, include_dirs):
    """Get the Jinja parameters to construct the BUILD.gn target of this
    mojom."""
    params = {}
    params["filename"] = os.path.basename(self.name)
    params["target_name"] = target_name_from_path(self.name)
    params["deps"] = []
    params["mojo_sdk_deps"] = []
    params["import_dirs"] = set()

    for dep in self.deps:
      # Mojo SDK dependencies have special treatment.
      if dep.is_sdk_dep():
        target, _ = dep.get_target_and_import(include_dirs)
        params["mojo_sdk_deps"].append(target)
      else:
        target, import_dir = dep.get_target_and_import(include_dirs)
        if import_dir != None:
            params["import_dirs"].add(import_dir)
        params["deps"].append(target)

    if len(params["import_dirs"]) != 0:
      params["import_dirs"] = list(params["import_dirs"])
    else:
      del params["import_dirs"]
    return params

  def _os_path_exists(self, path):
    return os.path.exists(path)

