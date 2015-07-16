# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
See http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts
for more details on the presubmit API built into depot_tools.
"""


def CheckChange(input_api, output_api):
  """Checks the DrMemory suppression files for bad suppressions."""

  # TODO(timurrrr): find out how to do relative imports
  # and remove this ugly hack. Also, the CheckChange function won't be needed.
  tools_vg_path = input_api.os_path.join(input_api.PresubmitLocalPath(), '..')
  import sys
  old_path = sys.path
  try:
    sys.path = sys.path + [tools_vg_path]
    import suppressions
    return suppressions.PresubmitCheck(input_api, output_api)
  finally:
    sys.path = old_path


def CheckChangeOnUpload(input_api, output_api):
  return CheckChange(input_api, output_api)


def CheckChangeOnCommit(input_api, output_api):
  return CheckChange(input_api, output_api)


def GetPreferredTryMasters(project, change):
  return {
    'tryserver.chromium.win': {
      'win_drmemory': set(['defaulttests']),
    }
  }
