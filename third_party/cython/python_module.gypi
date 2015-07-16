# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    'python_module_destination': '<(PRODUCT_DIR)/python/<(python_base_module)',
  },
  'rules': [
    {
      'rule_name': '<(_target_name)_cp_python',
      'extension': 'py',
      'inputs': [
        '<(DEPTH)/build/cp.py',
      ],
      'outputs': [
        '<(python_module_destination)/<(RULE_INPUT_NAME)',
      ],
      'action': [
        'python',
        '<@(_inputs)',
        '<(RULE_INPUT_PATH)',
        '<@(_outputs)',
      ],
      'message': 'Moving <(RULE_INPUT_PATH) to its destination',
    },
  ],
  'hard_dependency': 1,
}
