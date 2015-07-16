#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import subprocess
import utils

def patch_and_filter():
  """Applies the *.patch files in the current dir and some hardcoded filters."""
  os.chdir(utils.mojo_root_dir)

  utils.filter_file("build/landmines.py",
      lambda line: not "gyp_environment" in line)
  utils.commit("filter gyp_environment out of build/landmines.py")

  utils.filter_file("gpu/BUILD.gn", lambda line: not "//gpu/ipc" in line)
  utils.commit("filter //gpu/ipc out of gpu/BUILD.gn")

  utils.filter_file("cc/BUILD.gn", lambda line: not "//media" in line)
  utils.commit("filter //media out of cc/BUILD.gn")

  patch()


def patch(relative_patches_dir=os.curdir):
  """Applies the *.patch files in |relative_patches_dir|.

  Args:
    relative_patches_dir: A directory path relative to the current directory.
        Defaults to the directory of this file.

  Raises:
    subprocess.CalledProcessError if the patch couldn't be applied.
  """
  patches_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)),
                             relative_patches_dir)
  assert os.path.isdir(patches_dir)

  os.chdir(utils.mojo_root_dir)
  for p in utils.find(["*.patch"], patches_dir):
    print "applying patch %s" % os.path.basename(p)
    try:
      utils.system(["git", "apply", p])
      utils.commit("applied patch %s" % os.path.basename(p))
    except subprocess.CalledProcessError:
      print "ERROR: patch %s failed to apply" % os.path.basename(p)
      raise
