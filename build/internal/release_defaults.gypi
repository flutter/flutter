# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
{
  'msvs_settings': {
    'VCCLCompilerTool': {
      'StringPooling': 'true',
    },
    'VCLinkerTool': {
      # No incremental linking.
      'LinkIncremental': '1',
      # Eliminate Unreferenced Data (/OPT:REF).
      'OptimizeReferences': '2',
      # Folding on (/OPT:ICF).
      'EnableCOMDATFolding': '2',
    },
  },
}
