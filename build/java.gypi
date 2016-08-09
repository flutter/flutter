# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into a target to provide a rule
# to build Java in a consistent manner.
#
# To use this, create a gyp target with the following form:
# {
#   'target_name': 'my-package_java',
#   'type': 'none',
#   'variables': {
#     'java_in_dir': 'path/to/package/root',
#   },
#   'includes': ['path/to/this/gypi/file'],
# }
#
# Required variables:
#  java_in_dir - The top-level java directory. The src should be in
#    <java_in_dir>/src.
# Optional/automatic variables:
#  add_to_dependents_classpaths - Set to 0 if the resulting jar file should not
#    be added to its dependents' classpaths.
#  additional_input_paths - These paths will be included in the 'inputs' list to
#    ensure that this target is rebuilt when one of these paths changes.
#  additional_src_dirs - Additional directories with .java files to be compiled
#    and included in the output of this target.
#  generated_src_dirs - Same as additional_src_dirs except used for .java files
#    that are generated at build time. This should be set automatically by a
#    target's dependencies. The .java files in these directories are not
#    included in the 'inputs' list (unlike additional_src_dirs).
#  input_jars_paths - The path to jars to be included in the classpath. This
#    should be filled automatically by depending on the appropriate targets.
#  javac_includes - A list of specific files to include. This is by default
#    empty, which leads to inclusion of all files specified. May include
#    wildcard, and supports '**/' for recursive path wildcards, ie.:
#    '**/MyFileRegardlessOfDirectory.java', '**/IncludedPrefix*.java'.
#  has_java_resources - Set to 1 if the java target contains an
#    Android-compatible resources folder named res.  If 1, R_package and
#    R_package_relpath must also be set.
#  R_package - The java package in which the R class (which maps resources to
#    integer IDs) should be generated, e.g. org.chromium.content.
#  R_package_relpath - Same as R_package, but replace each '.' with '/'.
#  res_extra_dirs - A list of extra directories containing Android resources.
#    These directories may be generated at build time.
#  res_extra_files - A list of the files in res_extra_dirs.
#  never_lint - Set to 1 to not run lint on this target.

{
  'dependencies': [
    '<(DEPTH)/build/android/setup.gyp:build_output_dirs'
  ],
  'variables': {
    'add_to_dependents_classpaths%': 1,
    'android_jar': '<(android_sdk)/android.jar',
    'input_jars_paths': [ '<(android_jar)' ],
    'additional_src_dirs': [],
    'javac_includes': [],
    'jar_name': '<(_target_name).jar',
    'jar_dir': '<(PRODUCT_DIR)/lib.java',
    'jar_path': '<(intermediate_dir)/<(jar_name)',
    'jar_final_path': '<(jar_dir)/<(jar_name)',
    'jar_excluded_classes': [ '*/R.class', '*/R##*.class' ],
    'instr_stamp': '<(intermediate_dir)/instr.stamp',
    'additional_input_paths': [],
    'dex_path': '<(PRODUCT_DIR)/lib.java/<(_target_name).dex.jar',
    'generated_src_dirs': ['>@(generated_R_dirs)'],
    'generated_R_dirs': [],
    'has_java_resources%': 0,
    'res_extra_dirs': [],
    'res_extra_files': [],
    'res_v14_skip%': 0,
    'resource_input_paths': ['>@(res_extra_files)'],
    'intermediate_dir': '<(SHARED_INTERMEDIATE_DIR)/<(_target_name)',
    'compile_stamp': '<(intermediate_dir)/compile.stamp',
    'lint_stamp': '<(intermediate_dir)/lint.stamp',
    'lint_result': '<(intermediate_dir)/lint_result.xml',
    'lint_config': '<(intermediate_dir)/lint_config.xml',
    'never_lint%': 0,
    'findbugs_stamp': '<(intermediate_dir)/findbugs.stamp',
    'run_findbugs%': 0,
    'java_in_dir_suffix%': '/src',
    'proguard_config%': '',
    'proguard_preprocess%': '0',
    'enable_errorprone%': '0',
    'errorprone_exe_path': '<(PRODUCT_DIR)/bin.java/chromium_errorprone',
    'variables': {
      'variables': {
        'proguard_preprocess%': 0,
        'emma_never_instrument%': 0,
      },
      'conditions': [
        ['proguard_preprocess == 1', {
          'javac_jar_path': '<(intermediate_dir)/<(_target_name).pre.jar'
        }, {
          'javac_jar_path': '<(jar_path)'
        }],
        ['chromium_code != 0 and emma_coverage != 0 and emma_never_instrument == 0', {
          'emma_instrument': 1,
        }, {
          'emma_instrument': 0,
        }],
      ],
    },
    'emma_instrument': '<(emma_instrument)',
    'javac_jar_path': '<(javac_jar_path)',
  },
  'conditions': [
    ['add_to_dependents_classpaths == 1', {
      # This all_dependent_settings is used for java targets only. This will add the
      # jar path to the classpath of dependent java targets.
      'all_dependent_settings': {
        'variables': {
          'input_jars_paths': ['<(jar_final_path)'],
          'library_dexed_jars_paths': ['<(dex_path)'],
        },
      },
    }],
    ['has_java_resources == 1', {
      'variables': {
        'resource_dir': '<(java_in_dir)/res',
        'res_input_dirs': ['<(resource_dir)', '<@(res_extra_dirs)'],
        'resource_input_paths': ['<!@(find <(resource_dir) -type f)'],

        'R_dir': '<(intermediate_dir)/java_R',
        'R_text_file': '<(R_dir)/R.txt',

        'generated_src_dirs': ['<(R_dir)'],
        'additional_input_paths': ['<(resource_zip_path)', ],

        'dependencies_res_zip_paths': [],
        'resource_zip_path': '<(PRODUCT_DIR)/res.java/<(_target_name).zip',
      },
      'all_dependent_settings': {
        'variables': {
          # Dependent libraries include this target's R.java file via
          # generated_R_dirs.
          'generated_R_dirs': ['<(R_dir)'],

          # Dependent libraries and apks include this target's resources via
          # dependencies_res_zip_paths.
          'additional_input_paths': ['<(resource_zip_path)'],
          'dependencies_res_zip_paths': ['<(resource_zip_path)'],

          # additional_res_packages and additional_R_text_files are used to
          # create this packages R.java files when building the APK.
          'additional_res_packages': ['<(R_package)'],
          'additional_R_text_files': ['<(R_text_file)'],
        },
      },
      'actions': [
        # Generate R.java and crunch image resources.
        {
          'action_name': 'process_resources',
          'message': 'processing resources for <(_target_name)',
          'variables': {
            'android_manifest': '<(DEPTH)/build/android/AndroidManifest.xml',
            # Write the inputs list to a file, so that its mtime is updated when
            # the list of inputs changes.
            'inputs_list_file': '>|(java_resources.<(_target_name).gypcmd >@(resource_input_paths))',
            'process_resources_options': [],
            'conditions': [
              ['res_v14_skip == 1', {
                'process_resources_options': ['--v14-skip']
              }],
            ],
          },
          'inputs': [
            '<(DEPTH)/build/android/gyp/util/build_utils.py',
            '<(DEPTH)/build/android/gyp/process_resources.py',
            '<(DEPTH)/build/android/gyp/generate_v14_compatible_resources.py',
            '>@(resource_input_paths)',
            '>@(dependencies_res_zip_paths)',
            '>(inputs_list_file)',
          ],
          'outputs': [
            '<(resource_zip_path)',
          ],
          'action': [
            'python', '<(DEPTH)/build/android/gyp/process_resources.py',
            '--android-sdk', '<(android_sdk)',
            '--aapt-path', '<(android_aapt_path)',
            '--non-constant-id',

            '--android-manifest', '<(android_manifest)',
            '--custom-package', '<(R_package)',

            '--dependencies-res-zips', '>(dependencies_res_zip_paths)',
            '--resource-dirs', '<(res_input_dirs)',

            '--R-dir', '<(R_dir)',
            '--resource-zip-out', '<(resource_zip_path)',

            '<@(process_resources_options)',
          ],
        },
      ],
    }],
    ['proguard_preprocess == 1', {
      'actions': [
        {
          'action_name': 'proguard_<(_target_name)',
          'message': 'Proguard preprocessing <(_target_name) jar',
          'inputs': [
            '<(android_sdk_root)/tools/proguard/lib/proguard.jar',
            '<(DEPTH)/build/android/gyp/util/build_utils.py',
            '<(DEPTH)/build/android/gyp/proguard.py',
            '<(javac_jar_path)',
            '<(proguard_config)',
          ],
          'outputs': [
            '<(jar_path)',
          ],
          'action': [
            'python', '<(DEPTH)/build/android/gyp/proguard.py',
            '--proguard-path=<(android_sdk_root)/tools/proguard/lib/proguard.jar',
            '--input-path=<(javac_jar_path)',
            '--output-path=<(jar_path)',
            '--proguard-config=<(proguard_config)',
            '--classpath=<(android_sdk_jar) >(input_jars_paths)',
          ]
        },
      ],
    }],
    ['run_findbugs == 1', {
      'actions': [
        {
          'action_name': 'findbugs_<(_target_name)',
          'message': 'Running findbugs on <(_target_name)',
          'inputs': [
            '<(DEPTH)/build/android/findbugs_diff.py',
            '<(DEPTH)/build/android/findbugs_filter/findbugs_exclude.xml',
            '<(DEPTH)/build/android/pylib/utils/findbugs.py',
            '>@(input_jars_paths)',
            '<(jar_final_path)',
            '<(compile_stamp)',
          ],
          'outputs': [
            '<(findbugs_stamp)',
          ],
          'action': [
            'python', '<(DEPTH)/build/android/findbugs_diff.py',
            '--auxclasspath-gyp', '>(input_jars_paths)',
            '--stamp', '<(findbugs_stamp)',
            '<(jar_final_path)',
          ],
        },
      ],
    }],
    ['enable_errorprone == 1', {
      'dependencies': [
        '<(DEPTH)/third_party/errorprone/errorprone.gyp:chromium_errorprone',
      ],
    }],
  ],
  'actions': [
    {
      'action_name': 'javac_<(_target_name)',
      'message': 'Compiling <(_target_name) java sources',
      'variables': {
        'extra_args': [],
        'extra_inputs': [],
        'java_sources': ['>!@(find >(java_in_dir)>(java_in_dir_suffix) >(additional_src_dirs) -name "*.java")'],
        'conditions': [
          ['enable_errorprone == 1', {
            'extra_inputs': [
              '<(errorprone_exe_path)',
            ],
            'extra_args': [ '--use-errorprone-path=<(errorprone_exe_path)' ],
          }],
        ],
      },
      'inputs': [
        '<(DEPTH)/build/android/gyp/util/build_utils.py',
        '<(DEPTH)/build/android/gyp/javac.py',
        '>@(java_sources)',
        '>@(input_jars_paths)',
        '>@(additional_input_paths)',
        '<@(extra_inputs)',
      ],
      'outputs': [
        '<(compile_stamp)',
        '<(javac_jar_path)',
      ],
      'action': [
        'python', '<(DEPTH)/build/android/gyp/javac.py',
        '--bootclasspath=<(android_sdk_jar)',
        '--classpath=>(input_jars_paths)',
        '--src-gendirs=>(generated_src_dirs)',
        '--javac-includes=<(javac_includes)',
        '--chromium-code=<(chromium_code)',
        '--jar-path=<(javac_jar_path)',
        '--jar-excluded-classes=<(jar_excluded_classes)',
        '--stamp=<(compile_stamp)',
        '>@(java_sources)',
        '<@(extra_args)',
      ]
    },
    {
      'action_name': 'instr_jar_<(_target_name)',
      'message': 'Instrumenting <(_target_name) jar',
      'variables': {
        'input_path': '<(jar_path)',
        'output_path': '<(jar_final_path)',
        'stamp_path': '<(instr_stamp)',
        'instr_type': 'jar',
      },
      'outputs': [
        '<(jar_final_path)',
      ],
      'inputs': [
        '<(jar_path)',
      ],
      'includes': [ 'android/instr_action.gypi' ],
    },
    {
      'variables': {
        'src_dirs': [
          '<(java_in_dir)<(java_in_dir_suffix)',
          '>@(additional_src_dirs)',
        ],
        'stamp_path': '<(lint_stamp)',
        'result_path': '<(lint_result)',
        'config_path': '<(lint_config)',
        'lint_jar_path': '<(jar_final_path)',
      },
      'inputs': [
        '<(jar_final_path)',
        '<(compile_stamp)',
      ],
      'outputs': [
        '<(lint_stamp)',
      ],
      'includes': [ 'android/lint_action.gypi' ],
    },
    {
      'action_name': 'jar_toc_<(_target_name)',
      'message': 'Creating <(_target_name) jar.TOC',
      'inputs': [
        '<(DEPTH)/build/android/gyp/util/build_utils.py',
        '<(DEPTH)/build/android/gyp/util/md5_check.py',
        '<(DEPTH)/build/android/gyp/jar_toc.py',
        '<(jar_final_path)',
      ],
      'outputs': [
        '<(jar_final_path).TOC',
      ],
      'action': [
        'python', '<(DEPTH)/build/android/gyp/jar_toc.py',
        '--jar-path=<(jar_final_path)',
        '--toc-path=<(jar_final_path).TOC',
      ]
    },
    {
      'action_name': 'dex_<(_target_name)',
      'variables': {
        'conditions': [
          ['emma_instrument != 0', {
            'dex_no_locals': 1,
          }],
        ],
        'dex_input_paths': [ '<(jar_final_path)' ],
        'output_path': '<(dex_path)',
      },
      'includes': [ 'android/dex_action.gypi' ],
    },
  ],
}
