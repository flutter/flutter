# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into an action to invoke grit in a
# consistent manner. To use this the following variables need to be
# defined:
#   grit_grd_file: string: grd file path
#   grit_out_dir: string: the output directory path

# It would be really nice to do this with a rule instead of actions, but it
# would need to determine inputs and outputs via grit_info on a per-file
# basis. GYP rules don't currently support that. They could be extended to
# do this, but then every generator would need to be updated to handle this.

{
  'variables': {
    'grit_cmd': ['python', '<(DEPTH)/tools/grit/grit.py'],
    'grit_resource_ids%': '<(DEPTH)/tools/gritsettings/resource_ids',
    # This makes it possible to add more defines in specific targets,
    # instead of build/common.gypi .
    'grit_additional_defines%': [],
    'grit_rc_header_format%': [],
    'grit_whitelist%': '',

    'conditions': [
      # These scripts can skip writing generated files if they are identical
      # to the already existing files, which avoids further build steps, like
      # recompilation. However, a dependency (earlier build step) having a
      # newer timestamp than an output (later build step) confuses some build
      # systems, so only use this on ninja, which explicitly supports this use
      # case (gyp turns all actions into ninja restat rules).
      ['"<(GENERATOR)"=="ninja"', {
        'write_only_new': '1',
      }, {
        'write_only_new': '0',
      }],
    ],
  },
  'conditions': [
    ['"<(grit_whitelist)"==""', {
      'variables': {
        'grit_whitelist_flag': [],
      }
    }, {
      'variables': {
        'grit_whitelist_flag': ['-w', '<(grit_whitelist)'],
      }
    }]
  ],
  'inputs': [
    '<!@pymod_do_main(grit_info <@(grit_defines) <@(grit_additional_defines) '
        '<@(grit_whitelist_flag) --inputs <(grit_grd_file) '
        '-f "<(grit_resource_ids)")',
  ],
  'outputs': [
    '<!@pymod_do_main(grit_info <@(grit_defines) <@(grit_additional_defines) '
        '<@(grit_whitelist_flag) --outputs \'<(grit_out_dir)\' '
        '<(grit_grd_file) -f "<(grit_resource_ids)")',
  ],
  'action': ['<@(grit_cmd)',
             '-i', '<(grit_grd_file)', 'build',
             '-f', '<(grit_resource_ids)',
             '-o', '<(grit_out_dir)',
             '--write-only-new=<(write_only_new)',
             '<@(grit_defines)',
             '<@(grit_whitelist_flag)',
             '<@(grit_additional_defines)',
             '<@(grit_rc_header_format)'],
  'message': 'Generating resources from <(grit_grd_file)',
}
