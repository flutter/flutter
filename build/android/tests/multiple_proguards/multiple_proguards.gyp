# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
{
  'variables': {
    'chromium_code': 1,
  },
  'targets': [
    {
      'target_name': 'multiple_proguards_test_apk',
      'type': 'none',
      'variables': {
        'app_manifest_version_name%': '<(android_app_version_name)',
        'java_in_dir': '.',
        'proguard_enabled': 'true',
        'proguard_flags_paths': [
          # Both these proguard?.flags files need to be part of the build to
          # remove both warnings from the src/dummy/DummyActivity.java file, else the
          # build will fail.
          'proguard1.flags',
          'proguard2.flags',
        ],
        'R_package': 'dummy',
        'R_package_relpath': 'dummy',
        'apk_name': 'MultipleProguards',
        # This is a build-only test. There's nothing to install.
        'gyp_managed_install': 0,
        # The Java code produces warnings, so force the build to not show them.
        'chromium_code': 0,
      },
      'includes': [ '../../../../build/java_apk.gypi' ],
    },
  ],
}
