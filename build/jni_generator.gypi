# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into a target to provide a rule
# to generate jni bindings for Java-files in a consistent manner.
#
# To use this, create a gyp target with the following form:
#  {
#    'target_name': 'base_jni_headers',
#    'type': 'none',
#    'sources': [
#      'android/java/src/org/chromium/base/BuildInfo.java',
#      ...
#      ...
#      'android/java/src/org/chromium/base/SystemMessageHandler.java',
#    ],
#    'variables': {
#      'jni_gen_package': 'base',
#    },
#    'includes': [ '../build/jni_generator.gypi' ],
#  },
#
# The generated file name pattern can be seen on the "outputs" section below.
# (note that RULE_INPUT_ROOT is the basename for the java file).
#
# See base/android/jni_generator/jni_generator.py for more info about the
# format of generating JNI bindings.

{
  'variables': {
    'jni_generator': '<(DEPTH)/base/android/jni_generator/jni_generator.py',
    'jni_generator_jarjar_file%': '',
    'jni_generator_ptr_type%': 'long',
    # A comma separated string of include files.
    'jni_generator_includes%': (
        'base/android/jni_generator/jni_generator_helper.h'
    ),
    'native_exports%': '--native_exports_optional',
  },
  'rules': [
    {
      'rule_name': 'generate_jni_headers',
      'extension': 'java',
      'inputs': [
        '<(jni_generator)',
      ],
      'outputs': [
        '<(SHARED_INTERMEDIATE_DIR)/<(jni_gen_package)/jni/<(RULE_INPUT_ROOT)_jni.h',
      ],
      'action': [
        '<(jni_generator)',
        '--input_file',
        '<(RULE_INPUT_PATH)',
        '--output_dir',
        '<(SHARED_INTERMEDIATE_DIR)/<(jni_gen_package)/jni',
        '--includes',
        '<(jni_generator_includes)',
        '--optimize_generation',
        '<(optimize_jni_generation)',
        '--jarjar',
        '<(jni_generator_jarjar_file)',
        '--ptr_type',
        '<(jni_generator_ptr_type)',
        '<(native_exports)',
      ],
      'message': 'Generating JNI bindings from <(RULE_INPUT_PATH)',
      'process_outputs_as_sources': 1,
      'conditions': [
        ['jni_generator_jarjar_file != ""', {
          'inputs': [
            '<(jni_generator_jarjar_file)',
          ],
        }]
      ],
    },
  ],
  'direct_dependent_settings': {
    'include_dirs': [
      '<(SHARED_INTERMEDIATE_DIR)/<(jni_gen_package)',
    ],
  },
  # This target exports a hard dependency because it generates header
  # files.
  'hard_dependency': 1,
}

