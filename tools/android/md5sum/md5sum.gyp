# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      # GN: //tools/android/md5sum:md5sum
      'target_name': 'md5sum',
      'type': 'none',
      'dependencies': [
        'md5sum_stripped_device_bin',
        'md5sum_bin_host#host',
      ],
      # For the component build, ensure dependent shared libraries are stripped
      # and put alongside md5sum to simplify pushing to the device.
      'variables': {
         'output_dir': '<(PRODUCT_DIR)/md5sum_dist/',
         'native_binary': '<(PRODUCT_DIR)/md5sum_bin',
      },
      'includes': ['../../../build/android/native_app_dependencies.gypi'],
    },
    {
      # GN: //tools/android/md5sum:md5sum_bin($default_toolchain)
      'target_name': 'md5sum_device_bin',
      'type': 'executable',
      'dependencies': [
        '../../../base/base.gyp:base',
      ],
      'include_dirs': [
        '../../..',
      ],
      'sources': [
        'md5sum.cc',
      ],
      'conditions': [
        [ 'order_profiling!=0 and OS=="android"', {
            'dependencies': [ '../../../tools/cygprofile/cygprofile.gyp:cygprofile', ],
        }],
      ],
    },
    {
      # GN: //tools/android/md5sum:md5sum_prepare_dist
      'target_name': 'md5sum_stripped_device_bin',
      'type': 'none',
      'dependencies': [
        'md5sum_device_bin',
      ],
      'actions': [
        {
          'action_name': 'strip_md5sum_device_bin',
          'inputs': ['<(PRODUCT_DIR)/md5sum_device_bin'],
          'outputs': ['<(PRODUCT_DIR)/md5sum_bin'],
          'action': [
            '<(android_strip)',
            '--strip-unneeded',
            '<@(_inputs)',
            '-o',
            '<@(_outputs)',
          ],
        },
      ],
    },
    # Same binary but for the host rather than the device.
    {
      # GN: //tools/android/md5sum:md5sum_copy_host($default_toolchain)
      'target_name': 'md5sum_bin_host',
      'toolsets': ['host'],
      'type': 'executable',
      'dependencies': [
        '../../../base/base.gyp:base',
      ],
      'include_dirs': [
        '../../..',
      ],
      'sources': [
        'md5sum.cc',
      ],
    },
  ],
}
