# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
{
  'targets': [
    {
      # GN version: //base/trace_event/etw_manifest/BUILD.gn
      'target_name': 'etw_manifest',
      'type': 'none',
      'toolsets': ['host', 'target'],
      'hard_dependency': 1,
      'conditions': [
        ['OS=="win"', {
          'sources': [
            'chrome_events_win.man',
          ],
          'variables': {
            'man_output_dir': '<(SHARED_INTERMEDIATE_DIR)/base/trace_event/etw_manifest',
          },
          'rules': [{
            # Rule to run the message compiler.
            'rule_name': 'message_compiler',
            'extension': 'man',
            'outputs': [
              '<(man_output_dir)/chrome_events_win.h',
              '<(man_output_dir)/chrome_events_win.rc',
            ],
            'action': [
              'mc.exe',
              '-h', '<(man_output_dir)',
              '-r', '<(man_output_dir)/.',
              '-um',
              '<(RULE_INPUT_PATH)',
            ],
            'message': 'Running message compiler on <(RULE_INPUT_PATH)',
          }],
        }],
      ],
    }
  ]
}
