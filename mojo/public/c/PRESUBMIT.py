# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Presubmit script for mojo/public/c.

See http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts
for more details about the presubmit API built into depot_tools.
"""

def CheckChangeOnUpload(input_api, output_api):
  results = []
  results += input_api.canned_checks.CheckChangeHasOnlyOneEol(input_api,
                                                              output_api)
  results += input_api.canned_checks.CheckPatchFormatted(input_api, output_api)
  return results
