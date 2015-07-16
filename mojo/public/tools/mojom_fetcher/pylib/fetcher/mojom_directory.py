# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os

from fetcher.dependency import group_target_name

class MojomDirectory(object):
  """This class represents a directory that directly holds mojom files, in the
  external directory structure."""
  def __init__(self, path):
    self.path = path
    self.mojoms = []

  def add_mojom(self, mojom):
    self.mojoms.append(mojom)

  def get_jinja_parameters(self, include_dirs):
    """Get the Jinja parameters to construct the BUILD.gn file of this
    directory."""
    params = {}
    params["group_name"] = group_target_name(self.path)
    params["mojoms"] = []
    for mojom in self.mojoms:
      params["mojoms"].append(mojom.get_jinja_parameters(include_dirs))
    return params

  def get_build_gn_path(self):
    return os.path.join(self.path, "BUILD.gn")
