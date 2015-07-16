# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into a target to provide a rule
# to generate Java source files from templates that are processed
# through the host C pre-processor.
#
# NOTE: For generating Java conterparts to enums prefer using the java_cpp_enum
#       rule instead.
#
# To use this, create a gyp target with the following form:
#  {
#    'target_name': 'android_net_java_constants',
#    'type': 'none',
#    'sources': [
#      'net/android/NetError.template',
#    ],
#    'variables': {
#      'package_name': 'org/chromium/net',
#      'template_deps': ['base/net_error_list.h'],
#    },
#    'includes': [ '../build/android/java_cpp_template.gypi' ],
#  },
#
# The 'sources' entry should only list template file. The template file
# itself should use the 'ClassName.template' format, and will generate
# 'gen/templates/<target-name>/<package-name>/ClassName.java. The files which
# template dependents on and typically included by the template should be listed
# in template_deps variables. Any change to them will force a rebuild of
# the template, and hence of any source that depends on it.
#

{
  # Location where all generated Java sources will be placed.
  'variables': {
    'include_path%': '<(DEPTH)',
    'output_dir': '<(SHARED_INTERMEDIATE_DIR)/templates/<(_target_name)/<(package_name)',
  },
  'direct_dependent_settings': {
    'variables': {
      # Ensure that the output directory is used in the class path
      # when building targets that depend on this one.
      'generated_src_dirs': [
        '<(output_dir)/',
      ],
      # Ensure dependents are rebuilt when sources for this rule change.
      'additional_input_paths': [
        '<@(_sources)',
        '<@(template_deps)',
      ],
    },
  },
  # Define a single rule that will be apply to each .template file
  # listed in 'sources'.
  'rules': [
    {
      'rule_name': 'generate_java_constants',
      'extension': 'template',
      # Set template_deps as additional dependencies.
      'variables': {
        'output_path': '<(output_dir)/<(RULE_INPUT_ROOT).java',
      },
      'inputs': [
        '<(DEPTH)/build/android/gyp/util/build_utils.py',
        '<(DEPTH)/build/android/gyp/gcc_preprocess.py',
        '<@(template_deps)'
      ],
      'outputs': [
        '<(output_path)',
      ],
      'action': [
        'python', '<(DEPTH)/build/android/gyp/gcc_preprocess.py',
        '--include-path=<(include_path)',
        '--output=<(output_path)',
        '--template=<(RULE_INPUT_PATH)',
      ],
      'message': 'Generating Java from cpp template <(RULE_INPUT_PATH)',
    }
  ],
}
