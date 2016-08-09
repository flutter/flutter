# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

from pylib import cmd_helper


def GetGitHeadSHA1(in_directory):
  """Returns the git hash tag for the given directory.

  Args:
    in_directory: The directory where git is to be run.
  """
  command_line = ['git', 'log', '-1', '--pretty=format:%H']
  output = cmd_helper.GetCmdOutput(command_line, cwd=in_directory)
  return output[0:40]
