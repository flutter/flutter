# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import subprocess

import mopy.paths

class Version(object):
  """Computes the version (git committish) of the mojo repo"""

  def __init__(self):
    self.version = subprocess.check_output(["git", "rev-parse", "HEAD"],
        cwd=mopy.paths.Paths().src_root).strip()
