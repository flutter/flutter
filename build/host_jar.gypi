# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into a target to provide a rule to build
# a JAR file for use on a host in a consistent manner. If a main class is
# specified, this file will also generate an executable to run the jar in the
# output folder's /bin/ directory.
#
# To use this, create a gyp target with the following form:
# {
#   'target_name': 'my_jar',
#   'type': 'none',
#   'variables': {
#     'src_paths': [
#       'path/to/directory',
#       'path/to/other/directory',
#       'path/to/individual_file.java',
#       ...
#     ],
#   },
#   'includes': [ 'path/to/this/gypi/file' ],
# }
#
# Required variables:
#   src_paths - A list of all paths containing java files that should be
#     included in the jar. Paths can be either directories or files.
# Optional/automatic variables:
#   excluded_src_paths - A list of all paths that should be excluded from
#     the jar.
#   generated_src_dirs - Directories containing additional .java files
#     generated at build time.
#   input_jars_paths - A list of paths to the jars that should be included
#     in the classpath.
#   main_class - The class containing the main() function that should be called
#     when running the jar file.
#   jar_excluded_classes - A list of .class files that should be excluded
#     from the jar.

{
  'dependencies': [
    '<(DEPTH)/build/android/setup.gyp:build_output_dirs',
  ],
  'variables': {
    'classes_dir': '<(intermediate_dir)/classes',
    'excluded_src_paths': [],
    'generated_src_dirs': [],
    'input_jars_paths': [],
    'intermediate_dir': '<(SHARED_INTERMEDIATE_DIR)/<(_target_name)',
    'jar_dir': '<(PRODUCT_DIR)/lib.java',
    'jar_excluded_classes': [],
    'jar_name': '<(_target_name).jar',
    'jar_path': '<(jar_dir)/<(jar_name)',
    'main_class%': '',
    'stamp': '<(intermediate_dir)/jar.stamp',
  },
  'all_dependent_settings': {
    'variables': {
      'input_jars_paths': ['<(jar_path)']
    },
  },
  'actions': [
    {
      'action_name': 'javac_<(_target_name)',
      'message': 'Compiling <(_target_name) java sources',
      'variables': {
        'extra_options': [],
        'java_sources': [ '<!@(find <@(src_paths) -name "*.java")' ],
        'conditions': [
          ['"<(excluded_src_paths)" != ""', {
            'java_sources!': ['<!@(find <@(excluded_src_paths) -name "*.java")']
          }],
          ['"<(jar_excluded_classes)" != ""', {
            'extra_options': ['--jar-excluded-classes=<(jar_excluded_classes)']
          }],
          ['main_class != ""', {
            'extra_options': ['--main-class=>(main_class)']
          }]
        ],
      },
      'inputs': [
        '<(DEPTH)/build/android/gyp/util/build_utils.py',
        '<(DEPTH)/build/android/gyp/javac.py',
        '^@(java_sources)',
        '>@(input_jars_paths)',
      ],
      'outputs': [
        '<(jar_path)',
        '<(stamp)',
      ],
      'action': [
        'python', '<(DEPTH)/build/android/gyp/javac.py',
        '--classpath=>(input_jars_paths)',
        '--src-gendirs=>(generated_src_dirs)',
        '--chromium-code=<(chromium_code)',
        '--stamp=<(stamp)',
        '--jar-path=<(jar_path)',
        '<@(extra_options)',
        '^@(java_sources)',
      ],
    },
  ],
  'conditions': [
    ['main_class != ""', {
      'actions': [
        {
          'action_name': 'create_java_binary_script_<(_target_name)',
          'message': 'Creating java binary script <(_target_name)',
          'variables': {
            'output': '<(PRODUCT_DIR)/bin/<(_target_name)',
          },
          'inputs': [
            '<(DEPTH)/build/android/gyp/create_java_binary_script.py',
            '<(jar_path)',
          ],
          'outputs': [
            '<(output)',
          ],
          'action': [
            'python', '<(DEPTH)/build/android/gyp/create_java_binary_script.py',
            '--classpath=>(input_jars_paths)',
            '--jar-path=<(jar_path)',
            '--output=<(output)',
            '--main-class=>(main_class)',
          ]
        }
      ]
    }]
  ]
}

