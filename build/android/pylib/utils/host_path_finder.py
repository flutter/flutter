# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os

from pylib import constants


def GetMostRecentHostPath(file_name):
  """Returns the most recent existing full path for the given file name.

  Returns: An empty string if no path could be found.
  """
  out_dir = os.path.join(
      constants.DIR_SOURCE_ROOT, os.environ.get('CHROMIUM_OUT_DIR', 'out'))
  candidate_paths = [os.path.join(out_dir, build_type, file_name)
                     for build_type in ['Debug', 'Release']]
  candidate_paths = filter(os.path.exists, candidate_paths)
  candidate_paths = sorted(candidate_paths, key=os.path.getmtime, reverse=True)
  candidate_paths.append('')
  return candidate_paths[0]
