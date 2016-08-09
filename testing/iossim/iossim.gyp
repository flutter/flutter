# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    'mac_deployment_target': '10.8'
  },
  'conditions': [
    ['OS!="ios" or "<(GENERATOR)"!="xcode" or "<(GENERATOR_FLAVOR)"=="ninja"', {
      'targets': [
        {
          'target_name': 'iossim',
          'toolsets': ['host'],
          'type': 'executable',
          'variables': {
            'developer_dir': '<!(xcode-select -print-path)',
            # TODO(lliabraa): Once all builders are on Xcode 6 this variable can
            # be removed and the actions gated by this variable can be run by
            # default (crbug.com/385030).
            'xcode_version': '<!(xcodebuild -version | grep Xcode | awk \'{print $2}\')',
          },
          'conditions': [
            ['xcode_version>="6.0"', {
              'variables': {
                'iphone_sim_path': '<(developer_dir)/../SharedFrameworks',
              },
              'defines': [
                'IOSSIM_USE_XCODE_6',
              ],
              'actions': [
                {
                  'action_name': 'generate_dvt_foundation_header',
                  'inputs': [
                    '<(iphone_sim_path)/DVTFoundation.framework/Versions/Current/DVTFoundation',
                    '<(PRODUCT_DIR)/class-dump',
                  ],
                  'outputs': [
                    '<(INTERMEDIATE_DIR)/iossim/DVTFoundation.h'
                  ],
                  'action': [
                    # Actions don't provide a way to redirect stdout, so a custom
                    # script is invoked that will execute the first argument and
                    # write the output to the file specified as the second argument.
                    # -I sorts classes, categories, and protocols by inheritance.
                    # -C <regex> only displays classes matching regular expression.
                    './redirect-stdout.sh',
                    '<(PRODUCT_DIR)/class-dump -CDVTStackBacktrace|DVTInvalidation|DVTMixIn <(iphone_sim_path)/DVTFoundation.framework',
                    '<(INTERMEDIATE_DIR)/iossim/DVTFoundation.h',
                  ],
                  'message': 'Generating DVTFoundation.h',
                },
                {
                  'action_name': 'generate_dvt_core_simulator',
                  'inputs': [
                    '<(developer_dir)/Library/PrivateFrameworks/CoreSimulator.framework/Versions/Current/CoreSimulator',
                    '<(PRODUCT_DIR)/class-dump',
                  ],
                  'outputs': [
                    '<(INTERMEDIATE_DIR)/iossim/CoreSimulator.h'
                  ],
                  'action': [
                    # Actions don't provide a way to redirect stdout, so a custom
                    # script is invoked that will execute the first argument and
                    # write the output to the file specified as the second argument.
                    # -I sorts classes, categories, and protocols by inheritance.
                    # -C <regex> only displays classes matching regular expression.
                    './redirect-stdout.sh',
                    '<(PRODUCT_DIR)/class-dump -CSim <(developer_dir)/Library/PrivateFrameworks/CoreSimulator.framework',
                    '<(INTERMEDIATE_DIR)/iossim/CoreSimulator.h',
                  ],
                  'message': 'Generating CoreSimulator.h',
                },
              ],  # actions
            }, {  # else: xcode_version<"6.0"
              'variables': {
                'iphone_sim_path': '<(developer_dir)/Platforms/iPhoneSimulator.platform/Developer/Library/PrivateFrameworks',
              },
            }],  # xcode_version
          ],  # conditions
          'dependencies': [
            '<(DEPTH)/third_party/class-dump/class-dump.gyp:class-dump#host',
          ],
          'include_dirs': [
            '<(INTERMEDIATE_DIR)/iossim',
          ],
          'sources': [
            'iossim.mm',
            '<(INTERMEDIATE_DIR)/iossim/iPhoneSimulatorRemoteClient.h',
          ],
          'libraries': [
            '$(SDKROOT)/System/Library/Frameworks/Foundation.framework',
          ],
          'actions': [
            {
              'action_name': 'generate_dvt_iphone_sim_header',
              'inputs': [
                '<(iphone_sim_path)/DVTiPhoneSimulatorRemoteClient.framework/Versions/Current/DVTiPhoneSimulatorRemoteClient',
                '<(PRODUCT_DIR)/class-dump',
              ],
              'outputs': [
                '<(INTERMEDIATE_DIR)/iossim/DVTiPhoneSimulatorRemoteClient.h'
              ],
              'action': [
                # Actions don't provide a way to redirect stdout, so a custom
                # script is invoked that will execute the first argument and
                # write the output to the file specified as the second argument.
                # -I sorts classes, categories, and protocols by inheritance.
                # -C <regex> only displays classes matching regular expression.
                './redirect-stdout.sh',
                '<(PRODUCT_DIR)/class-dump -I -CiPhoneSimulator <(iphone_sim_path)/DVTiPhoneSimulatorRemoteClient.framework',
                '<(INTERMEDIATE_DIR)/iossim/DVTiPhoneSimulatorRemoteClient.h',
              ],
              'message': 'Generating DVTiPhoneSimulatorRemoteClient.h',
            },
          ],  # actions
          'xcode_settings': {
            'ARCHS': ['x86_64'],
          },
        },
      ],
    }, {  # else, OS=="ios" and "<(GENERATOR)"=="xcode" and "<(GENERATOR_FLAVOR)"!="ninja"
      'variables': {
        'ninja_output_dir': 'ninja-iossim',
        'ninja_product_dir':
          '$(SYMROOT)/<(ninja_output_dir)/<(CONFIGURATION_NAME)',
      },
      'targets': [
        {
          'target_name': 'iossim',
          'type': 'none',
          'toolsets': ['host'],
          'variables': {
            # Gyp to rerun
            're_run_targets': [
               'testing/iossim/iossim.gyp',
            ],
          },
          'includes': ['../../build/ios/mac_build.gypi'],
          'actions': [
            {
              'action_name': 'compile iossim',
              'inputs': [],
              'outputs': [],
              'action': [
                '<@(ninja_cmd)',
                'iossim',
              ],
              'message': 'Generating the iossim executable',
            },
          ],
        },
      ],
    }],
  ],
}
