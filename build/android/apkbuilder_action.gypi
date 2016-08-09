# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is a helper to java_apk.gypi. It should be used to create an
# action that runs ApkBuilder via ANT.
#
# Required variables:
#  apk_name - File name (minus path & extension) of the output apk.
#  apk_path - Path to output apk.
#  package_input_paths - Late-evaluated list of resource zips.
#  native_libs_dir - Path to lib/ directory to use. Set to an empty directory
#    if no native libs are needed.
# Optional variables:
#  has_code - Whether to include classes.dex in the apk.
#  dex_path - Path to classes.dex. Used only when has_code=1.
#  extra_inputs - List of extra action inputs.
{
  'variables': {
    'variables': {
      'has_code%': 1,
    },
    'conditions': [
      ['has_code == 0', {
        'has_code_str': 'false',
      }, {
        'has_code_str': 'true',
      }],
    ],
    'has_code%': '<(has_code)',
    'extra_inputs%': [],
    # Write the inputs list to a file, so that its mtime is updated when
    # the list of inputs changes.
    'inputs_list_file': '>|(apk_package.<(_target_name).<(apk_name).gypcmd >@(package_input_paths))',
    'resource_packaged_apk_name': '<(apk_name)-resources.ap_',
    'resource_packaged_apk_path': '<(intermediate_dir)/<(resource_packaged_apk_name)',
  },
  'action_name': 'apkbuilder_<(apk_name)',
  'message': 'Packaging <(apk_name)',
  'inputs': [
    '<(DEPTH)/build/android/ant/apk-package.xml',
    '<(DEPTH)/build/android/gyp/util/build_utils.py',
    '<(DEPTH)/build/android/gyp/ant.py',
    '<(resource_packaged_apk_path)',
    '<@(extra_inputs)',
    '>@(package_input_paths)',
    '>(inputs_list_file)',
  ],
  'outputs': [
    '<(apk_path)',
  ],
  'conditions': [
    ['has_code == 1', {
      'inputs': ['<(dex_path)'],
      'action': [
        '-DDEX_FILE_PATH=<(dex_path)',
      ]
    }],
  ],
  'action': [
    'python', '<(DEPTH)/build/android/gyp/ant.py',
    '--',
    '-quiet',
    '-DHAS_CODE=<(has_code_str)',
    '-DANDROID_SDK_ROOT=<(android_sdk_root)',
    '-DANDROID_SDK_TOOLS=<(android_sdk_tools)',
    '-DRESOURCE_PACKAGED_APK_NAME=<(resource_packaged_apk_name)',
    '-DNATIVE_LIBS_DIR=<(native_libs_dir)',
    '-DAPK_NAME=<(apk_name)',
    '-DCONFIGURATION_NAME=<(CONFIGURATION_NAME)',
    '-DOUT_DIR=<(intermediate_dir)',
    '-DUNSIGNED_APK_PATH=<(apk_path)',
    '-DEMMA_INSTRUMENT=<(emma_instrument)',
    '-DEMMA_DEVICE_JAR=<(emma_device_jar)',
    '-Dbasedir=.',
    '-buildfile',
    '<(DEPTH)/build/android/ant/apk-package.xml',
  ]
}
