# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into a target to provide an action
# to generate Java source files from a C++ header file containing annotated
# enum definitions using a Python script.
#
# To use this, create a gyp target with the following form:
#  {
#    'target_name': 'bitmap_format_java',
#    'type': 'none',
#    'variables': {
#      'source_file': 'ui/android/bitmap_format.h',
#    },
#    'includes': [ '../build/android/java_cpp_enum.gypi' ],
#  },
#
# Then have the gyp target which compiles the java code depend on the newly
# created target.

{
  'variables': {
    # Location where all generated Java sources will be placed.
    'output_dir': '<(SHARED_INTERMEDIATE_DIR)/enums/<(_target_name)',
    'generator_path': '<(DEPTH)/build/android/gyp/java_cpp_enum.py',
    'generator_args': '<(output_dir) <(source_file)',
  },
  'direct_dependent_settings': {
    'variables': {
      # Ensure that the output directory is used in the class path
      # when building targets that depend on this one.
      'generated_src_dirs': [
        '<(output_dir)/',
      ],
      # Ensure that the targets depending on this one are rebuilt if the sources
      # of this one are modified.
      'additional_input_paths': [
        '<(source_file)',
      ],
    },
  },
  'actions': [
    {
      'action_name': 'generate_java_constants',
      'inputs': [
        '<(DEPTH)/build/android/gyp/util/build_utils.py',
        '<(generator_path)',
        '<(source_file)',
      ],
      'outputs': [
        # This is the main reason this is an action and not a rule. Gyp doesn't
        # properly expand RULE_INPUT_PATH here and so it's impossible to
        # calculate the list of outputs.
        '<!@pymod_do_main(java_cpp_enum --print_output_only '
            '<@(generator_args))',
      ],
      'action': [
        'python', '<(generator_path)', '<@(generator_args)'
      ],
      'message': 'Generating Java from cpp header <(source_file)',
    },
  ],
}
