# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Xcode throws an error if an iOS target depends on a Mac OS X target. So
# any place a utility program needs to be build and run, an action is
# used to run ninja as script to work around this.
# Example:
# {
#   'target_name': 'foo',
#   'type': 'none',
#   'variables': {
#     # The name of a directory used for ninja. This cannot be shared with
#     # another mac build.
#     'ninja_output_dir': 'ninja-foo',
#     # The full path to the location in which the ninja executable should be
#     # placed. This cannot be shared with another mac build.
#    'ninja_product_dir':
#      '<(DEPTH)/xcodebuild/<(ninja_output_dir)/<(CONFIGURATION_NAME)',
#     # The list of all the gyp files that contain the targets to run.
#     're_run_targets': [
#       'foo.gyp',
#     ],
#   },
#   'includes': ['path_to/mac_build.gypi'],
#   'actions': [
#     {
#       'action_name': 'compile foo',
#       'inputs': [],
#       'outputs': [],
#       'action': [
#         '<@(ninja_cmd)',
#         # All the targets to build.
#         'foo1',
#         'foo2',
#       ],
#     },
#   ],
# }
{
  'variables': {
    'variables': {
     'parent_generator%': '<(GENERATOR)',
    },
    'parent_generator%': '<(parent_generator)',
    # Common ninja command line flags.
    'ninja_cmd': [
      # Bounce through clean_env to clean up the environment so things
      # set by the iOS build don't pollute the Mac build.
      '<(DEPTH)/build/ios/clean_env.py',
      # ninja must be found in the PATH.
      'ADD_TO_PATH=<!(echo $PATH)',
      'ninja',
      '-C',
      '<(ninja_product_dir)',
    ],

    # Common syntax to rerun gyp to generate the Mac projects.
    're_run_gyp': [
      'build/gyp_chromium',
      '--depth=.',
      # Don't use anything set for the iOS side of things.
      '--ignore-environment',
      # Generate for ninja
      '--format=ninja',
      # Generate files into xcodebuild/ninja
      '-Goutput_dir=xcodebuild/<(ninja_output_dir)',
      # nacl isn't in the iOS checkout, make sure it's turned off
      '-Ddisable_nacl=1',
      # Pass through the Mac SDK version.
      '-Dmac_sdk=<(mac_sdk)',
      '-Dparent_generator=<(parent_generator)'
    ],

    # Rerun gyp for each of the projects needed. This is what actually
    # generates the projects on disk.
    're_run_gyp_execution':
      '<!(cd <(DEPTH) && <@(re_run_gyp) <@(re_run_targets))',
  },
  # Since these are used to generate things needed by other targets, make
  # them hard dependencies so they are always built first.
  'hard_dependency': 1,
}
