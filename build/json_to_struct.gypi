# Copyright 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    # When including this gypi, the following variables must be set:
    #   schema_file: a json file that comprise the structure model.
    #   namespace: the C++ namespace that all generated files go under
    #   cc_dir: path to generated files
    # Functions and namespaces can be excluded by setting "nocompile" to true.
    'struct_gen_dir': '<(DEPTH)/tools/json_to_struct',
    'struct_gen%': '<(struct_gen_dir)/json_to_struct.py',
    'output_filename%': '<(RULE_INPUT_ROOT)',
  },
  'rules': [
    {
      # GN version: //tools/json_to_struct/json_to_struct.gni
      'rule_name': 'genstaticinit',
      'extension': 'json',
      'inputs': [
        '<(struct_gen)',
        '<(struct_gen_dir)/element_generator.py',
        '<(struct_gen_dir)/json_to_struct.py',
        '<(struct_gen_dir)/struct_generator.py',
        '<(schema_file)',
      ],
      'outputs': [
        '<(SHARED_INTERMEDIATE_DIR)/<(cc_dir)/<(output_filename).cc',
        '<(SHARED_INTERMEDIATE_DIR)/<(cc_dir)/<(output_filename).h',
      ],
      'action': [
        'python',
        '<(struct_gen)',
        '<(RULE_INPUT_PATH)',
        '--destbase=<(SHARED_INTERMEDIATE_DIR)',
        '--destdir=<(cc_dir)',
        '--namespace=<(namespace)',
        '--schema=<(schema_file)',
        '--output=<(output_filename)',
      ],
      'message': 'Generating C++ static initializers from <(RULE_INPUT_PATH)',
      'process_outputs_as_sources': 1,
    },
  ],
  'include_dirs': [
    '<(SHARED_INTERMEDIATE_DIR)',
    '<(DEPTH)',
  ],
  # This target exports a hard dependency because it generates header
  # files.
  'hard_dependency': 1,
}
