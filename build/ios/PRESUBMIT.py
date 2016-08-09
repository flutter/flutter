# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os

"""Chromium presubmit script for src/tools/ios.

See http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts
for more details on the presubmit API built into depot_tools.
"""

WHITELIST_FILE = 'build/ios/grit_whitelist.txt'

def _CheckWhitelistSorted(input_api, output_api):
  for path in input_api.LocalPaths():
    if WHITELIST_FILE == path:
      lines = open(os.path.join('../..', WHITELIST_FILE)).readlines()
      i = 0
      while i < len(lines) - 1 and lines[i] <= lines[i + 1]:
        i += 1
      if i < len(lines) - 1:
        return [output_api.PresubmitError(
            'The file ' + WHITELIST_FILE + ' must be sorted.  ' +
            'First offending line: #' + str(i + 2))]
  return []

def _CommonChecks(input_api, output_api):
  """Checks common to both upload and commit."""
  results = []
  results.extend(_CheckWhitelistSorted(input_api, output_api))
  return results

def CheckChangeOnUpload(input_api, output_api):
  results = []
  results.extend(_CommonChecks(input_api, output_api))
  return results

def CheckChangeOnCommit(input_api, output_api):
  results = []
  results.extend(_CommonChecks(input_api, output_api))
  return results
