#!/usr/bin/env python
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import subprocess
import utils

def patch_and_filter(dest_dir, relative_patches_dir):
  os.chdir(dest_dir)

  utils.filter_file("build/landmines.py",
      lambda line: not "gyp_environment" in line)
  utils.commit("filter gyp_environment out of build/landmines.py")

  patch(dest_dir, relative_patches_dir)


def patch(dest_dir, relative_patches_dir=os.curdir):
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

  os.chdir(dest_dir)
  for p in utils.find(["*.patch"], patches_dir):
    print "applying patch %s" % os.path.basename(p)
    try:
      utils.system(["git", "apply", p])
      utils.commit("applied patch %s" % os.path.basename(p))
    except subprocess.CalledProcessError:
      print "ERROR: patch %s failed to apply" % os.path.basename(p)
      raise
