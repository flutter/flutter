# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
{
  'conditions': [
    ['component == "shared_library"', {
      'targets': [
        {
          # These libraries from the Android ndk are required to be packaged with
          # any APK that is built with them. build/java_apk.gypi expects any
          # libraries that should be packaged with the apk to be in
          # <(SHARED_LIB_DIR)
          'target_name': 'copy_system_libraries',
          'type': 'none',
          'copies': [
            {
              'destination': '<(SHARED_LIB_DIR)/',
              'files': [
                '<(android_libcpp_libs_dir)/libc++_shared.so',
              ],
            },
          ],
        },
      ],
    }],
  ],
  'targets': [
    {
      'target_name': 'get_build_device_configurations',
      'type': 'none',
      'actions': [
        {
          'action_name': 'get configurations',
          'inputs': [
            'gyp/util/build_device.py',
            'gyp/get_device_configuration.py',
          ],
          'outputs': [
            '<(build_device_config_path)',
            '<(build_device_config_path).fake',
          ],
          'action': [
            'python', 'gyp/get_device_configuration.py',
            '--output=<(build_device_config_path)',
          ],
        }
      ],
    },
    {
      # Target for creating common output build directories. Creating output
      # dirs beforehand ensures that build scripts can assume these folders to
      # exist and there are no race conditions resulting from build scripts
      # trying to create these directories.
      # The build/java.gypi target depends on this target.
      'target_name': 'build_output_dirs',
      'type': 'none',
      'actions': [
        {
          'action_name': 'create_java_output_dirs',
          'variables' : {
            'output_dirs' : [
              '<(PRODUCT_DIR)/apks',
              '<(PRODUCT_DIR)/lib.java',
              '<(PRODUCT_DIR)/test.lib.java',
            ]
          },
          'inputs' : [],
          # By not specifying any outputs, we ensure that this command isn't
          # re-run when the output directories are touched (i.e. apks are
          # written to them).
          'outputs': [''],
          'action': [
            'mkdir',
            '-p',
            '<@(output_dirs)',
          ],
        },
      ],
    }, # build_output_dirs
    {
      'target_name': 'sun_tools_java',
      'type': 'none',
      'variables': {
        'found_jar_path': '<(PRODUCT_DIR)/sun_tools_java/tools.jar',
        'jar_path': '<(found_jar_path)',
      },
      'includes': [
        '../../build/host_prebuilt_jar.gypi',
      ],
      'actions': [
        {
          'action_name': 'find_sun_tools_jar',
          'variables' : {
          },
          'inputs' : [
            'gyp/find_sun_tools_jar.py',
            'gyp/util/build_utils.py',
          ],
          'outputs': [
            '<(found_jar_path)',
          ],
          'action': [
            'python', 'gyp/find_sun_tools_jar.py',
            '--output', '<(found_jar_path)',
          ],
        },
      ],
    }, # sun_tools_java
  ]
}

