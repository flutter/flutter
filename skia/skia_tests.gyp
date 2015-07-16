# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    'chromium_code': 1,
  },
  'targets': [
    {
      'target_name': 'skia_unittests',
      'type': '<(gtest_target_type)',
      'dependencies': [
        '../base/base.gyp:base',
        '../base/base.gyp:run_all_unittests',
        '../testing/gtest.gyp:gtest',
        '../skia/skia.gyp:skia',
        '../ui/gfx/gfx.gyp:gfx',
        '../ui/gfx/gfx.gyp:gfx_geometry',
      ],
      'sources': [
        'ext/analysis_canvas_unittest.cc',
        'ext/bitmap_platform_device_mac_unittest.cc',
        'ext/convolver_unittest.cc',
        'ext/image_operations_unittest.cc',
        'ext/pixel_ref_utils_unittest.cc',
        'ext/platform_canvas_unittest.cc',
        'ext/recursive_gaussian_convolution_unittest.cc',
        'ext/refptr_unittest.cc',
        'ext/skia_utils_ios_unittest.mm',
        'ext/skia_utils_mac_unittest.mm',
      ],
      'conditions': [
        ['OS != "win" and OS != "mac"', {
          'sources!': [
            'ext/platform_canvas_unittest.cc',
          ],
        }],
        ['OS == "android"', {
          'dependencies': [
            '../testing/android/native_test.gyp:native_test_native_code',
          ],
        }],
      ],
    },
  ],
  'conditions': [
    ['OS == "android"', {
      'targets': [
        {
          'target_name': 'skia_unittests_apk',
          'type': 'none',
          'dependencies': [
            'skia_unittests',
          ],
          'variables': {
            'test_suite_name': 'skia_unittests',
          },
          'includes': [ '../build/apk_test.gypi' ],
        },
      ],
    }],
  ],
}
