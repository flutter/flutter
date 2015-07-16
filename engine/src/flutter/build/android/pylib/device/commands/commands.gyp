# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      # GN version: //build/android/pylib/devices/commands:chromium_commands
      'target_name': 'chromium_commands',
      'type': 'none',
      'variables': {
        'add_to_dependents_classpaths': 0,
        'java_in_dir': ['java'],
      },
      'includes': [
        '../../../../../build/java.gypi',
      ],
    }
  ],
}
