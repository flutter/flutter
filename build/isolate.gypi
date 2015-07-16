# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into a target to provide a rule
# to "build" .isolate files into a .isolated file.
#
# To use this, create a gyp target with the following form:
# 'conditions': [
#   ['test_isolation_mode != "noop"', {
#     'targets': [
#       {
#         'target_name': 'foo_test_run',
#         'type': 'none',
#         'dependencies': [
#           'foo_test',
#         ],
#         'includes': [
#           '../build/isolate.gypi',
#         ],
#         'sources': [
#           'foo_test.isolate',
#         ],
#       },
#     ],
#   }],
# ],
#
# Note: foo_test.isolate is included and a source file. It is an inherent
# property of the .isolate format. This permits to define GYP variables but is
# a stricter format than GYP so isolate.py can read it.
#
# The generated .isolated file will be:
#   <(PRODUCT_DIR)/foo_test.isolated
#
# See http://dev.chromium.org/developers/testing/isolated-testing/for-swes
# for more information.

{
  'includes': [
    '../build/util/version.gypi',
  ],
  'rules': [
    {
      'rule_name': 'isolate',
      'extension': 'isolate',
      'inputs': [
        # Files that are known to be involved in this step.
        '<(DEPTH)/tools/isolate_driver.py',
        '<(DEPTH)/tools/swarming_client/isolate.py',
        '<(DEPTH)/tools/swarming_client/run_isolated.py',
      ],
      'outputs': [],
      'action': [
        'python',
        '<(DEPTH)/tools/isolate_driver.py',
        '<(test_isolation_mode)',
        '--isolated', '<(PRODUCT_DIR)/<(RULE_INPUT_ROOT).isolated',
        '--isolate', '<(RULE_INPUT_PATH)',

        # Variables should use the -V FOO=<(FOO) form so frequent values,
        # like '0' or '1', aren't stripped out by GYP. Run 'isolate.py help' for
        # more details.

        # Path variables are used to replace file paths when loading a .isolate
        # file
        '--path-variable', 'DEPTH', '<(DEPTH)',
        '--path-variable', 'PRODUCT_DIR', '<(PRODUCT_DIR) ',

        # Extra variables are replaced on the 'command' entry and on paths in
        # the .isolate file but are not considered relative paths.
        '--extra-variable', 'version_full=<(version_full)',

        # Note: This list must match DefaultConfigVariables()
        # in build/android/pylib/utils/isolator.py
        '--config-variable', 'CONFIGURATION_NAME=<(CONFIGURATION_NAME)',
        '--config-variable', 'OS=<(OS)',
        '--config-variable', 'asan=<(asan)',
        '--config-variable', 'branding=<(branding)',
        '--config-variable', 'chromeos=<(chromeos)',
        '--config-variable', 'component=<(component)',
        '--config-variable', 'disable_nacl=<(disable_nacl)',
        '--config-variable', 'enable_pepper_cdms=<(enable_pepper_cdms)',
        '--config-variable', 'enable_plugins=<(enable_plugins)',
        '--config-variable', 'fastbuild=<(fastbuild)',
        '--config-variable', 'icu_use_data_file_flag=<(icu_use_data_file_flag)',
        # TODO(kbr): move this to chrome_tests.gypi:gles2_conform_tests_run
        # once support for user-defined config variables is added.
        '--config-variable',
          'internal_gles2_conform_tests=<(internal_gles2_conform_tests)',
        '--config-variable', 'kasko=<(kasko)',
        '--config-variable', 'libpeer_target_type=<(libpeer_target_type)',
        '--config-variable', 'lsan=<(lsan)',
        '--config-variable', 'msan=<(msan)',
        '--config-variable', 'target_arch=<(target_arch)',
        '--config-variable', 'tsan=<(tsan)',
        '--config-variable', 'use_custom_libcxx=<(use_custom_libcxx)',
        '--config-variable', 'use_instrumented_libraries=<(use_instrumented_libraries)',
        '--config-variable',
        'use_prebuilt_instrumented_libraries=<(use_prebuilt_instrumented_libraries)',
        '--config-variable', 'use_openssl=<(use_openssl)',
        '--config-variable', 'use_ozone=<(use_ozone)',
        '--config-variable', 'use_x11=<(use_x11)',
        '--config-variable', 'v8_use_external_startup_data=<(v8_use_external_startup_data)',
      ],
      'conditions': [
        # Note: When gyp merges lists, it appends them to the old value.
        ['OS=="mac"', {
          'action': [
            '--extra-variable', 'mac_product_name=<(mac_product_name)',
          ],
        }],
        ["test_isolation_mode == 'prepare'", {
          'outputs': [
            '<(PRODUCT_DIR)/<(RULE_INPUT_ROOT).isolated.gen.json',
          ],
        }, {
          'outputs': [
            '<(PRODUCT_DIR)/<(RULE_INPUT_ROOT).isolated',
          ],
        }],
      ],
    },
  ],
}
