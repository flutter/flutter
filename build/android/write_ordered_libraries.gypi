# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into an action to provide a rule that
# generates a json file with the list of dependent libraries needed for a given
# shared library or executable.
#
# To use this, create a gyp target with the following form:
#  {
#    'actions': [
#      'variables': {
#        'input_libraries': 'shared library or executable to process',
#        'ordered_libraries_file': 'file to generate'
#      },
#      'includes': [ '../../build/android/write_ordered_libraries.gypi' ],
#    ],
#  },
#

{
  'action_name': 'ordered_libraries_<(_target_name)<(subtarget)',
  'message': 'Writing dependency ordered libraries for <(_target_name)',
  'variables': {
    'input_libraries%': [],
    'subtarget%': '',
  },
  'inputs': [
    '<(DEPTH)/build/android/gyp/util/build_utils.py',
    '<(DEPTH)/build/android/gyp/write_ordered_libraries.py',
    '<@(input_libraries)',
  ],
  'outputs': [
    '<(ordered_libraries_file)',
  ],
  'action': [
    'python', '<(DEPTH)/build/android/gyp/write_ordered_libraries.py',
    '--input-libraries=<(input_libraries)',
    '--libraries-dir=<(SHARED_LIB_DIR),<(PRODUCT_DIR)',
    '--readelf=<(android_readelf)',
    '--output=<(ordered_libraries_file)',
  ],
}
