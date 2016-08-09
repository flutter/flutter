# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into an action to invoke grit repack in a
# consistent manner. To use this the following variables need to be
# defined:
#   pak_inputs: list: paths of pak files that need to be combined.
#   pak_output: string: the output pak file path.

{
  # GYP version: //tools/grit/repack.gni
  'variables': {
    'repack_path': '<(DEPTH)/tools/grit/grit/format/repack.py',
    'repack_options%': [],
  },
  'inputs': [
    '<(repack_path)',
    '<@(pak_inputs)',
  ],
  'outputs': [
    '<(pak_output)'
  ],
  'action': [
    'python',
    '<(repack_path)',
    '<@(repack_options)',
    '<(pak_output)',
    '<@(pak_inputs)',
  ],
}
