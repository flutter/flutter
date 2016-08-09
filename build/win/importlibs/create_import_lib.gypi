# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into a target to provide a rule
# to create import libraries from an import description file in a consistent
# manner.
#
# To use this, create a gyp target with the following form:
# {
#   'target_name': 'my_proto_lib',
#   'type': 'none',
#   'sources': [
#     'foo.imports',
#     'bar.imports',
#   ],
#   'variables': {
#     # Optional, see below: 'proto_in_dir': '.'
#     'create_importlib': 'path-to-script',
#     'lib_dir': 'path-to-output-directory',
#   },
#   'includes': ['path/to/this/gypi/file'],
# }
#
# This will generate import libraries named 'foo.lib' and 'bar.lib' in the
# specified lib directory.

{
  'variables': {
    'create_importlib': '<(DEPTH)/build/win/importlibs/create_importlib_win.py',
    'lib_dir': '<(PRODUCT_DIR)/lib',
  },
  'rules': [
    {
      'rule_name': 'create_import_lib',
      'extension': 'imports',
      'inputs': [
        '<(create_importlib)',
      ],
      'outputs': [
        '<(lib_dir)/<(RULE_INPUT_ROOT).lib',
      ],
      'action': [
        'python',
        '<(create_importlib)',
        '--output-file', '<@(_outputs)',
        '<(RULE_INPUT_PATH)',
      ],
      'message': 'Generating import library from <(RULE_INPUT_PATH)',
      'process_outputs_as_sources': 0,
    },
  ],
}
