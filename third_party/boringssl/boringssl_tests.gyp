# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'includes': [
    'boringssl_tests.gypi',
  ],
  'targets': [
    {
      'target_name': 'boringssl_unittests',
      'type': 'executable',
      'sources': [
        'boringssl_unittest.cc',
       ],
      'dependencies': [
        '<@(boringssl_test_targets)',
        '../../base/base.gyp:base',
        '../../base/base.gyp:run_all_unittests',
        '../../base/base.gyp:test_support_base',
        '../../testing/gtest.gyp:gtest',
      ],
    },
  ],
}
