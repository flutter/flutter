# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into a target to provide a rule
# to build Java in a consistent manner.

{
  'all_dependent_settings': {
    'variables': {
      'input_jars_paths': ['>(apk_output_jar_path)'],
      'library_dexed_jars_paths': ['>(apk_output_jar_path)'],
    },
  },
}
