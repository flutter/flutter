# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into an action to copy test data files into
# an iOS app bundle. To use this the following variables need to be defined:
#   test_data_files: list: paths to test data files or directories
#   test_data_prefix: string: a directory prefix that will be prepended to each
#                             output path.  Generally, this should be the base
#                             directory of the gypi file containing the unittest
#                             target (e.g. "base" or "chrome").
#
# To use this, create a gyp target with the following form:
# {
#   'target_name': 'my_unittests',
#   'conditions': [
#     ['OS == "ios"', {
#       'actions': [
#         {
#           'action_name': 'copy_test_data',
#           'variables': {
#             'test_data_files': [
#               'path/to/datafile.txt',
#               'path/to/data/directory/',
#             ]
#             'test_data_prefix' : 'prefix',
#           },
#           'includes': ['path/to/this/gypi/file'],
#         },
#       ],
#     }],
# }
#

{
  'inputs': [
    # The |-o <(test_data_prefix)| is ignored; it is there to work around a
    # caching bug in gyp (https://code.google.com/p/gyp/issues/detail?id=112).
    # It caches command output when the string is the same, so if two copy
    # steps have the same relative paths, there can be bogus cache hits that
    # cause compile failures unless something varies.
    '<!@pymod_do_main(copy_test_data_ios -o <(test_data_prefix) --inputs <(test_data_files))',
  ],
  'outputs': [
    '<!@pymod_do_main(copy_test_data_ios -o <(PRODUCT_DIR)/<(_target_name).app/<(test_data_prefix) --outputs <(test_data_files))',
  ],
  'action': [
    'python',
    '<(DEPTH)/build/copy_test_data_ios.py',
    '-o', '<(PRODUCT_DIR)/<(_target_name).app/<(test_data_prefix)',
    '<@(_inputs)',
  ],
}
