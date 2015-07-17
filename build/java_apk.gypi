# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is meant to be included into a target to provide a rule
# to build Android APKs in a consistent manner.
#
# To use this, create a gyp target with the following form:
# {
#   'target_name': 'my_package_apk',
#   'type': 'none',
#   'variables': {
#     'apk_name': 'MyPackage',
#     'java_in_dir': 'path/to/package/root',
#     'resource_dir': 'path/to/package/root/res',
#   },
#   'includes': ['path/to/this/gypi/file'],
# }
#
# Required variables:
#  apk_name - The final apk will be named <apk_name>.apk
#  java_in_dir - The top-level java directory. The src should be in
#    <(java_in_dir)/src.
# Optional/automatic variables:
#  additional_input_paths - These paths will be included in the 'inputs' list to
#    ensure that this target is rebuilt when one of these paths changes.
#  additional_res_packages - Package names of R.java files generated in addition
#    to the default package name defined in AndroidManifest.xml.
#  additional_src_dirs - Additional directories with .java files to be compiled
#    and included in the output of this target.
#  additional_bundled_libs - Additional libraries what will be stripped and
#    bundled in the apk.
#  asset_location - The directory where assets are located.
#  create_abi_split - Whether to create abi-based spilts. Splits
#    are supported only for minSdkVersion >= 21.
#  create_density_splits - Whether to create density-based apk splits.
#  language_splits - List of languages to create apk splits for.
#  generated_src_dirs - Same as additional_src_dirs except used for .java files
#    that are generated at build time. This should be set automatically by a
#    target's dependencies. The .java files in these directories are not
#    included in the 'inputs' list (unlike additional_src_dirs).
#  input_jars_paths - The path to jars to be included in the classpath. This
#    should be filled automatically by depending on the appropriate targets.
#  is_test_apk - Set to 1 if building a test apk.  This prevents resources from
#    dependencies from being re-included.
#  native_lib_target - The target_name of the target which generates the final
#    shared library to be included in this apk. A stripped copy of the
#    library will be included in the apk.
#  resource_dir - The directory for resources.
#  shared_resources - Make a resource package that can be loaded by a different
#    application at runtime to access the package's resources.
#  R_package - A custom Java package to generate the resource file R.java in.
#    By default, the package given in AndroidManifest.xml will be used.
#  include_all_resources - Set to 1 to include all resource IDs in all generated
#    R.java files.
#  use_chromium_linker - Enable the content dynamic linker that allows sharing the
#    RELRO section of the native libraries between the different processes.
#  load_library_from_zip - When using the dynamic linker, load the library
#    directly out of the zip file.
#  use_relocation_packer - Enable relocation packing. Relies on the chromium
#    linker, so use_chromium_linker must also be enabled.
#  enable_chromium_linker_tests - Enable the content dynamic linker test support
#    code. This allows a test APK to inject a Linker.TestRunner instance at
#    runtime. Should only be used by the chromium_linker_test_apk target!!
#  never_lint - Set to 1 to not run lint on this target.
#  java_in_dir_suffix - To override the /src suffix on java_in_dir.
#  app_manifest_version_name - set the apps 'human readable' version number.
#  app_manifest_version_code - set the apps version number.
{
  'variables': {
    'tested_apk_obfuscated_jar_path%': '/',
    'tested_apk_dex_path%': '/',
    'additional_input_paths': [],
    'create_density_splits%': 0,
    'language_splits': [],
    'input_jars_paths': [],
    'library_dexed_jars_paths': [],
    'additional_src_dirs': [],
    'generated_src_dirs': [],
    'app_manifest_version_name%': '<(android_app_version_name)',
    'app_manifest_version_code%': '<(android_app_version_code)',
    # aapt generates this proguard.txt.
    'generated_proguard_file': '<(intermediate_dir)/proguard.txt',
    'proguard_enabled%': 'false',
    'proguard_flags_paths': ['<(generated_proguard_file)'],
    'jar_name': 'chromium_apk_<(_target_name).jar',
    'resource_dir%':'<(DEPTH)/build/android/ant/empty/res',
    'R_package%':'',
    'include_all_resources%': 0,
    'additional_R_text_files': [],
    'dependencies_res_zip_paths': [],
    'additional_res_packages': [],
    'additional_bundled_libs%': [],
    'is_test_apk%': 0,
    # Allow icu data, v8 snapshots, and pak files to be loaded directly from the .apk.
    # Note: These are actually suffix matches, not necessarily extensions.
    'extensions_to_not_compress%': '.dat,.bin,.pak',
    'resource_input_paths': [],
    'intermediate_dir': '<(PRODUCT_DIR)/<(_target_name)',
    'asset_location%': '<(intermediate_dir)/assets',
    'codegen_stamp': '<(intermediate_dir)/codegen.stamp',
    'package_input_paths': [],
    'ordered_libraries_file': '<(intermediate_dir)/native_libraries.json',
    'additional_ordered_libraries_file': '<(intermediate_dir)/additional_native_libraries.json',
    'native_libraries_template': '<(DEPTH)/base/android/java/templates/NativeLibraries.template',
    'native_libraries_java_dir': '<(intermediate_dir)/native_libraries_java/',
    'native_libraries_java_file': '<(native_libraries_java_dir)/NativeLibraries.java',
    'native_libraries_java_stamp': '<(intermediate_dir)/native_libraries_java.stamp',
    'native_libraries_template_data_dir': '<(intermediate_dir)/native_libraries/',
    'native_libraries_template_data_file': '<(native_libraries_template_data_dir)/native_libraries_array.h',
    'native_libraries_template_version_file': '<(native_libraries_template_data_dir)/native_libraries_version.h',
    'compile_stamp': '<(intermediate_dir)/compile.stamp',
    'lint_stamp': '<(intermediate_dir)/lint.stamp',
    'lint_result': '<(intermediate_dir)/lint_result.xml',
    'lint_config': '<(intermediate_dir)/lint_config.xml',
    'never_lint%': 0,
    'findbugs_stamp': '<(intermediate_dir)/findbugs.stamp',
    'run_findbugs%': 0,
    'java_in_dir_suffix%': '/src',
    'instr_stamp': '<(intermediate_dir)/instr.stamp',
    'jar_stamp': '<(intermediate_dir)/jar.stamp',
    'obfuscate_stamp': '<(intermediate_dir)/obfuscate.stamp',
    'pack_relocations_stamp': '<(intermediate_dir)/pack_relocations.stamp',
    'strip_stamp': '<(intermediate_dir)/strip.stamp',
    'stripped_libraries_dir': '<(intermediate_dir)/stripped_libraries',
    'strip_additional_stamp': '<(intermediate_dir)/strip_additional.stamp',
    'version_stamp': '<(intermediate_dir)/version.stamp',
    'javac_includes': [],
    'jar_excluded_classes': [],
    'javac_jar_path': '<(intermediate_dir)/<(_target_name).javac.jar',
    'jar_path': '<(PRODUCT_DIR)/lib.java/<(jar_name)',
    'obfuscated_jar_path': '<(intermediate_dir)/obfuscated.jar',
    'test_jar_path': '<(PRODUCT_DIR)/test.lib.java/<(apk_name).jar',
    'dex_path': '<(intermediate_dir)/classes.dex',
    'emma_device_jar': '<(android_sdk_root)/tools/lib/emma_device.jar',
    'android_manifest_path%': '<(java_in_dir)/AndroidManifest.xml',
    'split_android_manifest_path': '<(intermediate_dir)/split-manifests/<(android_app_abi)/AndroidManifest.xml',
    'push_stamp': '<(intermediate_dir)/push.stamp',
    'link_stamp': '<(intermediate_dir)/link.stamp',
    'resource_zip_path': '<(intermediate_dir)/<(_target_name).resources.zip',
    'shared_resources%': 0,
    'final_apk_path%': '<(PRODUCT_DIR)/apks/<(apk_name).apk',
    'final_apk_path_no_extension%': '<(PRODUCT_DIR)/apks/<(apk_name)',
    'final_abi_split_apk_path%': '<(PRODUCT_DIR)/apks/<(apk_name)-abi-<(android_app_abi).apk',
    'incomplete_apk_path': '<(intermediate_dir)/<(apk_name)-incomplete.apk',
    'apk_install_record': '<(intermediate_dir)/apk_install.record.stamp',
    'device_intermediate_dir': '/data/data/org.chromium.gyp_managed_install/<(_target_name)/<(CONFIGURATION_NAME)',
    'symlink_script_host_path': '<(intermediate_dir)/create_symlinks.sh',
    'symlink_script_device_path': '<(device_intermediate_dir)/create_symlinks.sh',
    'create_standalone_apk%': 1,
    'res_v14_skip%': 0,
    'variables': {
      'variables': {
        'native_lib_target%': '',
        'native_lib_version_name%': '',
        'use_chromium_linker%' : 0,
        'use_relocation_packer%' : 0,
        'enable_chromium_linker_tests%': 0,
        'is_test_apk%': 0,
        'unsigned_apk_path': '<(intermediate_dir)/<(apk_name)-unsigned.apk',
        'unsigned_abi_split_apk_path': '<(intermediate_dir)/<(apk_name)-abi-<(android_app_abi)-unsigned.apk',
        'create_abi_split%': 0,
      },
      'unsigned_apk_path': '<(unsigned_apk_path)',
      'unsigned_abi_split_apk_path': '<(unsigned_abi_split_apk_path)',
      'create_abi_split%': '<(create_abi_split)',
      'conditions': [
        ['gyp_managed_install == 1 and native_lib_target != ""', {
          'conditions': [
            ['create_abi_split == 0', {
              'unsigned_standalone_apk_path': '<(intermediate_dir)/<(apk_name)-standalone-unsigned.apk',
            }, {
              'unsigned_standalone_apk_path': '<(intermediate_dir)/<(apk_name)-abi-<(android_app_abi)-standalone-unsigned.apk',
            }],
          ],
        }, {
          'unsigned_standalone_apk_path': '<(unsigned_apk_path)',
        }],
        ['gyp_managed_install == 1', {
          'apk_package_native_libs_dir': '<(intermediate_dir)/libs.managed',
        }, {
          'apk_package_native_libs_dir': '<(intermediate_dir)/libs',
        }],
        ['is_test_apk == 0 and emma_coverage != 0', {
          'emma_instrument%': 1,
        },{
          'emma_instrument%': 0,
        }],
        # When using abi splits, the abi split is modified by
        # gyp_managed_install rather than the main .apk
        ['create_abi_split == 1', {
          'managed_input_apk_path': '<(unsigned_abi_split_apk_path)',
        }, {
          'managed_input_apk_path': '<(unsigned_apk_path)',
        }],
      ],
    },
    'native_lib_target%': '',
    'native_lib_version_name%': '',
    'use_chromium_linker%' : 0,
    'load_library_from_zip%' : 0,
    'use_relocation_packer%' : 0,
    'enable_chromium_linker_tests%': 0,
    'emma_instrument%': '<(emma_instrument)',
    'apk_package_native_libs_dir': '<(apk_package_native_libs_dir)',
    'unsigned_standalone_apk_path': '<(unsigned_standalone_apk_path)',
    'unsigned_apk_path': '<(unsigned_apk_path)',
    'unsigned_abi_split_apk_path': '<(unsigned_abi_split_apk_path)',
    'create_abi_split%': '<(create_abi_split)',
    'managed_input_apk_path': '<(managed_input_apk_path)',
    'libchromium_android_linker': 'libchromium_android_linker.>(android_product_extension)',
    'extra_native_libs': [],
    'native_lib_placeholder_stamp': '<(apk_package_native_libs_dir)/<(android_app_abi)/native_lib_placeholder.stamp',
    'native_lib_placeholders': [],
    'main_apk_name': '<(apk_name)',
    'enable_errorprone%': '0',
    'errorprone_exe_path': '<(PRODUCT_DIR)/bin.java/chromium_errorprone',
  },
  # Pass the jar path to the apk's "fake" jar target.  This would be better as
  # direct_dependent_settings, but a variable set by a direct_dependent_settings
  # cannot be lifted in a dependent to all_dependent_settings.
  'all_dependent_settings': {
    'conditions': [
      ['proguard_enabled == "true"', {
        'variables': {
          'proguard_enabled': 'true',
        }
      }],
    ],
    'variables': {
      'apk_output_jar_path': '<(jar_path)',
      'tested_apk_obfuscated_jar_path': '<(obfuscated_jar_path)',
      'tested_apk_dex_path': '<(dex_path)',
    },
  },
  'conditions': [
    ['resource_dir!=""', {
      'variables': {
        'resource_input_paths': [ '<!@(find <(resource_dir) -name "*")' ]
      },
    }],
    ['R_package != ""', {
      'variables': {
        # We generate R.java in package R_package (in addition to the package
        # listed in the AndroidManifest.xml, which is unavoidable).
        'additional_res_packages': ['<(R_package)'],
        'additional_R_text_files': ['<(intermediate_dir)/R.txt'],
      },
    }],
    ['native_lib_target != "" and component == "shared_library"', {
      'dependencies': [
        '<(DEPTH)/build/android/setup.gyp:copy_system_libraries',
      ],
    }],
    ['use_chromium_linker == 1', {
      'dependencies': [
        '<(DEPTH)/base/base.gyp:chromium_android_linker',
      ],
    }],
    ['enable_errorprone == 1', {
      'dependencies': [
        '<(DEPTH)/third_party/errorprone/errorprone.gyp:chromium_errorprone',
      ],
    }],
    ['native_lib_target != ""', {
      'variables': {
        'conditions': [
          ['use_chromium_linker == 1', {
            'variables': {
              'chromium_linker_path': [
                '<(SHARED_LIB_DIR)/<(libchromium_android_linker)',
              ],
            }
          }, {
            'variables': {
              'chromium_linker_path': [],
            },
          }],
        ],
        'generated_src_dirs': [ '<(native_libraries_java_dir)' ],
        'native_libs_paths': [
          '<(SHARED_LIB_DIR)/<(native_lib_target).>(android_product_extension)',
          '<@(chromium_linker_path)'
        ],
        'package_input_paths': [
          '<(apk_package_native_libs_dir)/<(android_app_abi)/gdbserver',
        ],
      },
      'copies': [
        {
          # gdbserver is always copied into the APK's native libs dir. The ant
          # build scripts (apkbuilder task) will only include it in a debug
          # build.
          'destination': '<(apk_package_native_libs_dir)/<(android_app_abi)',
          'files': [
            '<(android_gdbserver)',
          ],
        },
      ],
      'actions': [
        {
          'variables': {
            'input_libraries': [
              '<@(native_libs_paths)',
              '<@(extra_native_libs)',
            ],
          },
          'includes': ['../build/android/write_ordered_libraries.gypi'],
        },
        {
          'action_name': 'native_libraries_<(_target_name)',
          'variables': {
            'conditions': [
              ['use_chromium_linker == 1', {
                'variables': {
                  'linker_gcc_preprocess_defines': [
                    '--defines', 'ENABLE_CHROMIUM_LINKER',
                  ],
                }
              }, {
                'variables': {
                  'linker_gcc_preprocess_defines': [],
                },
              }],
              ['load_library_from_zip == 1', {
                'variables': {
                  'linker_load_from_zip_file_preprocess_defines': [
                    '--defines', 'ENABLE_CHROMIUM_LINKER_LIBRARY_IN_ZIP_FILE',
                  ],
                }
              }, {
                'variables': {
                  'linker_load_from_zip_file_preprocess_defines': [],
                },
              }],
              ['enable_chromium_linker_tests == 1', {
                'variables': {
                  'linker_tests_gcc_preprocess_defines': [
                    '--defines', 'ENABLE_CHROMIUM_LINKER_TESTS',
                  ],
                }
              }, {
                'variables': {
                  'linker_tests_gcc_preprocess_defines': [],
                },
              }],
            ],
            'gcc_preprocess_defines': [
              '<@(linker_load_from_zip_file_preprocess_defines)',
              '<@(linker_gcc_preprocess_defines)',
              '<@(linker_tests_gcc_preprocess_defines)',
            ],
          },
          'message': 'Creating NativeLibraries.java for <(_target_name)',
          'inputs': [
            '<(DEPTH)/build/android/gyp/util/build_utils.py',
            '<(DEPTH)/build/android/gyp/gcc_preprocess.py',
            '<(ordered_libraries_file)',
            '<(native_libraries_template)',
          ],
          'outputs': [
            '<(native_libraries_java_stamp)',
          ],
          'action': [
            'python', '<(DEPTH)/build/android/gyp/gcc_preprocess.py',
            '--include-path=',
            '--output=<(native_libraries_java_file)',
            '--template=<(native_libraries_template)',
            '--stamp=<(native_libraries_java_stamp)',
            '--defines', 'NATIVE_LIBRARIES_LIST=@FileArg(<(ordered_libraries_file):java_libraries_list)',
            '--defines', 'NATIVE_LIBRARIES_VERSION_NUMBER="<(native_lib_version_name)"',
            '<@(gcc_preprocess_defines)',
          ],
        },
        {
          'action_name': 'strip_native_libraries',
          'variables': {
            'ordered_libraries_file%': '<(ordered_libraries_file)',
            'stripped_libraries_dir%': '<(stripped_libraries_dir)',
            'input_paths': [
              '<@(native_libs_paths)',
              '<@(extra_native_libs)',
            ],
            'stamp': '<(strip_stamp)'
          },
          'includes': ['../build/android/strip_native_libraries.gypi'],
        },
        {
          'action_name': 'insert_chromium_version',
          'variables': {
            'ordered_libraries_file%': '<(ordered_libraries_file)',
            'stripped_libraries_dir%': '<(stripped_libraries_dir)',
            'version_string': '<(native_lib_version_name)',
            'input_paths': [
              '<(strip_stamp)',
            ],
            'stamp': '<(version_stamp)'
          },
          'includes': ['../build/android/insert_chromium_version.gypi'],
        },
        {
          'action_name': 'pack_relocations',
          'variables': {
            'conditions': [
              ['use_chromium_linker == 1 and use_relocation_packer == 1 and profiling != 1', {
                'enable_packing': 1,
              }, {
                'enable_packing': 0,
              }],
            ],
            'exclude_packing_list': [
              '<(libchromium_android_linker)',
            ],
            'ordered_libraries_file%': '<(ordered_libraries_file)',
            'stripped_libraries_dir%': '<(stripped_libraries_dir)',
            'packed_libraries_dir': '<(libraries_source_dir)',
            'input_paths': [
              '<(version_stamp)'
            ],
            'stamp': '<(pack_relocations_stamp)',
          },
          'includes': ['../build/android/pack_relocations.gypi'],
        },
        {
          'variables': {
            'input_libraries': [
              '<@(additional_bundled_libs)',
            ],
            'ordered_libraries_file': '<(additional_ordered_libraries_file)',
            'subtarget': '_additional_libraries',
          },
          'includes': ['../build/android/write_ordered_libraries.gypi'],
        },
        {
          'action_name': 'strip_additional_libraries',
          'variables': {
            'ordered_libraries_file': '<(additional_ordered_libraries_file)',
            'stripped_libraries_dir': '<(libraries_source_dir)',
            'input_paths': [
              '<@(additional_bundled_libs)',
              '<(strip_stamp)',
            ],
            'stamp': '<(strip_additional_stamp)'
          },
          'includes': ['../build/android/strip_native_libraries.gypi'],
        },
        {
          'action_name': 'Create native lib placeholder files for previous releases',
          'variables': {
            'placeholders': ['<@(native_lib_placeholders)'],
            'conditions': [
              ['gyp_managed_install == 1', {
                # This "library" just needs to be put in the .apk. It is not loaded
                # at runtime.
                'placeholders': ['libfix.crbug.384638.so'],
              }]
            ],
          },
          'inputs': [
            '<(DEPTH)/build/android/gyp/create_placeholder_files.py',
          ],
          'outputs': [
            '<(native_lib_placeholder_stamp)',
          ],
          'action': [
            'python', '<(DEPTH)/build/android/gyp/create_placeholder_files.py',
            '--dest-lib-dir=<(apk_package_native_libs_dir)/<(android_app_abi)/',
            '--stamp=<(native_lib_placeholder_stamp)',
            '<@(placeholders)',
          ],
        },
      ],
      'conditions': [
        ['gyp_managed_install == 1', {
          'variables': {
            'libraries_top_dir': '<(intermediate_dir)/lib.stripped',
            'libraries_source_dir': '<(libraries_top_dir)/lib/<(android_app_abi)',
            'device_library_dir': '<(device_intermediate_dir)/lib.stripped',
            'configuration_name': '<(CONFIGURATION_NAME)',
          },
          'dependencies': [
            '<(DEPTH)/build/android/setup.gyp:get_build_device_configurations',
            '<(DEPTH)/build/android/pylib/device/commands/commands.gyp:chromium_commands',
          ],
          'actions': [
            {
              'includes': ['../build/android/push_libraries.gypi'],
            },
            {
              'action_name': 'create device library symlinks',
              'message': 'Creating links on device for <(_target_name)',
              'inputs': [
                '<(DEPTH)/build/android/gyp/util/build_utils.py',
                '<(DEPTH)/build/android/gyp/create_device_library_links.py',
                '<(apk_install_record)',
                '<(build_device_config_path)',
                '<(ordered_libraries_file)',
              ],
              'outputs': [
                '<(link_stamp)'
              ],
              'action': [
                'python', '<(DEPTH)/build/android/gyp/create_device_library_links.py',
                '--build-device-configuration=<(build_device_config_path)',
                '--libraries=@FileArg(<(ordered_libraries_file):libraries)',
                '--script-host-path=<(symlink_script_host_path)',
                '--script-device-path=<(symlink_script_device_path)',
                '--target-dir=<(device_library_dir)',
                '--apk=<(incomplete_apk_path)',
                '--stamp=<(link_stamp)',
                '--configuration-name=<(CONFIGURATION_NAME)',
              ],
            },
          ],
          'conditions': [
            ['create_standalone_apk == 1', {
              'actions': [
                {
                  'action_name': 'create standalone APK',
                  'variables': {
                    'inputs': [
                      '<(ordered_libraries_file)',
                      '<(strip_additional_stamp)',
                      '<(pack_relocations_stamp)',
                    ],
                    'output_apk_path': '<(unsigned_standalone_apk_path)',
                    'libraries_top_dir%': '<(libraries_top_dir)',
                    'input_apk_path': '<(managed_input_apk_path)',
                  },
                  'includes': [ 'android/create_standalone_apk_action.gypi' ],
                },
              ],
            }],
          ],
        }, {
          # gyp_managed_install != 1
          'variables': {
            'libraries_source_dir': '<(apk_package_native_libs_dir)/<(android_app_abi)',
            'package_input_paths': [
              '<(strip_additional_stamp)',
              '<(pack_relocations_stamp)',
            ],
          },
        }],
      ],
    }], # native_lib_target != ''
    ['gyp_managed_install == 0 or create_standalone_apk == 1 or create_abi_split == 1', {
      'dependencies': [
        '<(DEPTH)/build/android/rezip.gyp:rezip_apk_jar',
      ],
    }],
    ['create_abi_split == 1 or gyp_managed_install == 0 or create_standalone_apk == 1', {
      'actions': [
        {
          'action_name': 'finalize_base',
          'variables': {
            'output_apk_path': '<(final_apk_path)',
            'conditions': [
              ['create_abi_split == 0', {
                'input_apk_path': '<(unsigned_standalone_apk_path)',
              }, {
                'input_apk_path': '<(unsigned_apk_path)',
                'load_library_from_zip': 0,
              }]
            ],
          },
          'includes': [ 'android/finalize_apk_action.gypi']
        },
      ],
    }],
    ['create_abi_split == 1', {
      'actions': [
        {
          'action_name': 'generate_split_manifest_<(_target_name)',
          'inputs': [
            '<(DEPTH)/build/android/gyp/util/build_utils.py',
            '<(DEPTH)/build/android/gyp/generate_split_manifest.py',
            '<(android_manifest_path)',
          ],
          'outputs': [
            '<(split_android_manifest_path)',
          ],
          'action': [
            'python', '<(DEPTH)/build/android/gyp/generate_split_manifest.py',
            '--main-manifest', '<(android_manifest_path)',
            '--out-manifest', '<(split_android_manifest_path)',
            '--split', 'abi_<(android_app_abi)',
          ],
        },
        {
          'variables': {
            'apk_name': '<(main_apk_name)-abi-<(android_app_abi)',
            'asset_location': '',
            'android_manifest_path': '<(split_android_manifest_path)',
            'create_density_splits': 0,
            'language_splits=': [],
          },
          'includes': [ 'android/package_resources_action.gypi' ],
        },
        {
          'variables': {
            'apk_name': '<(main_apk_name)-abi-<(android_app_abi)',
            'apk_path': '<(unsigned_abi_split_apk_path)',
            'has_code': 0,
            'native_libs_dir': '<(apk_package_native_libs_dir)',
            'extra_inputs': ['<(native_lib_placeholder_stamp)'],
          },
          'includes': ['android/apkbuilder_action.gypi'],
        },
      ],
    }],
    ['create_abi_split == 1 and (gyp_managed_install == 0 or create_standalone_apk == 1)', {
      'actions': [
        {
          'action_name': 'finalize_split',
          'variables': {
            'output_apk_path': '<(final_abi_split_apk_path)',
            'conditions': [
              ['gyp_managed_install == 1', {
                'input_apk_path': '<(unsigned_standalone_apk_path)',
              }, {
                'input_apk_path': '<(unsigned_abi_split_apk_path)',
              }],
            ],
          },
          'includes': [ 'android/finalize_apk_action.gypi']
        },
      ],
    }],
    ['gyp_managed_install == 1', {
      'actions': [
        {
          'action_name': 'finalize incomplete apk',
          'variables': {
            'load_library_from_zip': 0,
            'input_apk_path': '<(managed_input_apk_path)',
            'output_apk_path': '<(incomplete_apk_path)',
          },
          'includes': [ 'android/finalize_apk_action.gypi']
        },
        {
          'action_name': 'apk_install_<(_target_name)',
          'message': 'Installing <(apk_name).apk',
          'inputs': [
            '<(DEPTH)/build/android/gyp/util/build_utils.py',
            '<(DEPTH)/build/android/gyp/apk_install.py',
            '<(build_device_config_path)',
            '<(incomplete_apk_path)',
          ],
          'outputs': [
            '<(apk_install_record)',
          ],
          'action': [
            'python', '<(DEPTH)/build/android/gyp/apk_install.py',
            '--build-device-configuration=<(build_device_config_path)',
            '--install-record=<(apk_install_record)',
            '--configuration-name=<(CONFIGURATION_NAME)',
            '--android-sdk-tools', '<(android_sdk_tools)',
          ],
          'conditions': [
            ['create_abi_split == 1', {
              'inputs': [
                '<(final_apk_path)',
              ],
              'action': [
                '--apk-path=<(final_apk_path)',
                '--split-apk-path=<(incomplete_apk_path)',
              ],
            }, {
              'action': [
                '--apk-path=<(incomplete_apk_path)',
              ],
            }],
            ['create_density_splits == 1', {
              'inputs': [
                '<(final_apk_path_no_extension)-density-hdpi.apk',
                '<(final_apk_path_no_extension)-density-xhdpi.apk',
                '<(final_apk_path_no_extension)-density-xxhdpi.apk',
                '<(final_apk_path_no_extension)-density-xxxhdpi.apk',
                '<(final_apk_path_no_extension)-density-tvdpi.apk',
              ],
              'action': [
                '--split-apk-path=<(final_apk_path_no_extension)-density-hdpi.apk',
                '--split-apk-path=<(final_apk_path_no_extension)-density-xhdpi.apk',
                '--split-apk-path=<(final_apk_path_no_extension)-density-xxhdpi.apk',
                '--split-apk-path=<(final_apk_path_no_extension)-density-xxxhdpi.apk',
                '--split-apk-path=<(final_apk_path_no_extension)-density-tvdpi.apk',
              ],
            }],
            ['language_splits != []', {
              'inputs': [
                "<!@(python <(DEPTH)/build/apply_locales.py '<(final_apk_path_no_extension)-lang-ZZLOCALE.apk' <(language_splits))",
              ],
              'action': [
                "<!@(python <(DEPTH)/build/apply_locales.py -- '--split-apk-path=<(final_apk_path_no_extension)-lang-ZZLOCALE.apk' <(language_splits))",
              ],
            }],
          ],
        },
      ],
    }],
    ['create_density_splits == 1', {
      'actions': [
        {
          'action_name': 'finalize_density_splits',
          'variables': {
            'density_splits': 1,
          },
          'includes': [ 'android/finalize_splits_action.gypi']
        },
      ],
    }],
    ['is_test_apk == 1', {
      'dependencies': [
        '<(DEPTH)/build/android/pylib/device/commands/commands.gyp:chromium_commands',
        '<(DEPTH)/tools/android/android_tools.gyp:android_tools',
      ]
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
            '<(jar_path)',
            '<(compile_stamp)',
          ],
          'outputs': [
            '<(findbugs_stamp)',
          ],
          'action': [
            'python', '<(DEPTH)/build/android/findbugs_diff.py',
            '--auxclasspath-gyp', '>(input_jars_paths)',
            '--stamp', '<(findbugs_stamp)',
            '<(jar_path)',
          ],
        },
      ],
    },
    ]
  ],
  'dependencies': [
    '<(DEPTH)/tools/android/md5sum/md5sum.gyp:md5sum',
  ],
  'actions': [
    {
      'action_name': 'process_resources',
      'message': 'processing resources for <(_target_name)',
      'variables': {
        # Write the inputs list to a file, so that its mtime is updated when
        # the list of inputs changes.
        'inputs_list_file': '>|(apk_codegen.<(_target_name).gypcmd >@(additional_input_paths) >@(resource_input_paths))',
        'process_resources_options': [],
        'conditions': [
          ['is_test_apk == 1', {
            'dependencies_res_zip_paths=': [],
            'additional_res_packages=': [],
          }],
          ['res_v14_skip == 1', {
            'process_resources_options+': ['--v14-skip']
          }],
          ['shared_resources == 1', {
            'process_resources_options+': ['--shared-resources']
          }],
          ['R_package != ""', {
            'process_resources_options+': ['--custom-package', '<(R_package)']
          }],
          ['include_all_resources == 1', {
            'process_resources_options+': ['--include-all-resources']
          }]
        ],
      },
      'inputs': [
        '<(DEPTH)/build/android/gyp/util/build_utils.py',
        '<(DEPTH)/build/android/gyp/process_resources.py',
        '<(android_manifest_path)',
        '>@(additional_input_paths)',
        '>@(resource_input_paths)',
        '>@(dependencies_res_zip_paths)',
        '>(inputs_list_file)',
      ],
      'outputs': [
        '<(resource_zip_path)',
        '<(generated_proguard_file)',
        '<(codegen_stamp)',
      ],
      'action': [
        'python', '<(DEPTH)/build/android/gyp/process_resources.py',
        '--android-sdk', '<(android_sdk)',
        '--aapt-path', '<(android_aapt_path)',

        '--android-manifest', '<(android_manifest_path)',
        '--dependencies-res-zips', '>(dependencies_res_zip_paths)',

        '--extra-res-packages', '>(additional_res_packages)',
        '--extra-r-text-files', '>(additional_R_text_files)',

        '--proguard-file', '<(generated_proguard_file)',

        '--resource-dirs', '<(resource_dir)',
        '--resource-zip-out', '<(resource_zip_path)',

        '--R-dir', '<(intermediate_dir)/gen',

        '--stamp', '<(codegen_stamp)',

        '<@(process_resources_options)',
      ],
    },
    {
      'action_name': 'javac_<(_target_name)',
      'message': 'Compiling java for <(_target_name)',
      'variables': {
        'extra_args': [],
        'extra_inputs': [],
        'gen_src_dirs': [
          '<(intermediate_dir)/gen',
          '>@(generated_src_dirs)',
        ],
        # If there is a separate find for additional_src_dirs, it will find the
        # wrong .java files when additional_src_dirs is empty.
        # TODO(thakis): Gyp caches >! evaluation by command. Both java.gypi and
        # java_apk.gypi evaluate the same command, and at the moment two targets
        # set java_in_dir to "java". Add a dummy comment here to make sure
        # that the two targets (one uses java.gypi, the other java_apk.gypi)
        # get distinct source lists. Medium-term, make targets list all their
        # Java files instead of using find. (As is, this will be broken if two
        # targets use the same java_in_dir and both use java_apk.gypi or
        # both use java.gypi.)
        'java_sources': ['>!@(find >(java_in_dir)>(java_in_dir_suffix) >(additional_src_dirs) -name "*.java"  # apk)'],
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
        '<(codegen_stamp)',
        '<@(extra_inputs)',
      ],
      'conditions': [
        ['native_lib_target != ""', {
          'inputs': [ '<(native_libraries_java_stamp)' ],
        }],
      ],
      'outputs': [
        '<(compile_stamp)',
        '<(javac_jar_path)',
      ],
      'action': [
        'python', '<(DEPTH)/build/android/gyp/javac.py',
        '--bootclasspath=<(android_sdk_jar)',
        '--classpath=>(input_jars_paths) <(android_sdk_jar)',
        '--src-gendirs=>(gen_src_dirs)',
        '--javac-includes=<(javac_includes)',
        '--chromium-code=<(chromium_code)',
        '--jar-path=<(javac_jar_path)',
        '--jar-excluded-classes=<(jar_excluded_classes)',
        '--stamp=<(compile_stamp)',
        '<@(extra_args)',
        '>@(java_sources)',
      ],
    },
    {
      'action_name': 'instr_jar_<(_target_name)',
      'message': 'Instrumenting <(_target_name) jar',
      'variables': {
        'input_path': '<(javac_jar_path)',
        'output_path': '<(jar_path)',
        'stamp_path': '<(instr_stamp)',
        'instr_type': 'jar',
      },
      'outputs': [
        '<(instr_stamp)',
        '<(jar_path)',
      ],
      'inputs': [
        '<(javac_jar_path)',
      ],
      'includes': [ 'android/instr_action.gypi' ],
    },
    {
      'variables': {
        'src_dirs': [
          '<(java_in_dir)<(java_in_dir_suffix)',
          '>@(additional_src_dirs)',
        ],
        'lint_jar_path': '<(jar_path)',
        'stamp_path': '<(lint_stamp)',
        'result_path': '<(lint_result)',
        'config_path': '<(lint_config)',
      },
      'outputs': [
        '<(lint_stamp)',
      ],
      'includes': [ 'android/lint_action.gypi' ],
    },
    {
      'action_name': 'obfuscate_<(_target_name)',
      'message': 'Obfuscating <(_target_name)',
      'variables': {
        'additional_obfuscate_options': [],
        'additional_obfuscate_input_paths': [],
        'proguard_out_dir': '<(intermediate_dir)/proguard',
        'proguard_input_jar_paths': [
          '>@(input_jars_paths)',
          '<(jar_path)',
        ],
        'target_conditions': [
          ['is_test_apk == 1', {
            'additional_obfuscate_options': [
              '--testapp',
            ],
          }],
          ['is_test_apk == 1 and tested_apk_obfuscated_jar_path != "/"', {
            'additional_obfuscate_options': [
              '--tested-apk-obfuscated-jar-path', '>(tested_apk_obfuscated_jar_path)',
            ],
            'additional_obfuscate_input_paths': [
              '>(tested_apk_obfuscated_jar_path).info',
            ],
          }],
          ['proguard_enabled == "true"', {
            'additional_obfuscate_options': [
              '--proguard-enabled',
            ],
          }],
        ],
        'obfuscate_input_jars_paths': [
          '>@(input_jars_paths)',
          '<(jar_path)',
        ],
      },
      'conditions': [
        ['is_test_apk == 1', {
          'outputs': [
            '<(test_jar_path)',
          ],
        }],
      ],
      'inputs': [
        '<(DEPTH)/build/android/gyp/apk_obfuscate.py',
        '<(DEPTH)/build/android/gyp/util/build_utils.py',
        '>@(proguard_flags_paths)',
        '>@(obfuscate_input_jars_paths)',
        '>@(additional_obfuscate_input_paths)',
        '<(instr_stamp)',
      ],
      'outputs': [
        '<(obfuscate_stamp)',

        # In non-Release builds, these paths will all be empty files.
        '<(obfuscated_jar_path)',
        '<(obfuscated_jar_path).info',
        '<(obfuscated_jar_path).dump',
        '<(obfuscated_jar_path).seeds',
        '<(obfuscated_jar_path).mapping',
        '<(obfuscated_jar_path).usage',
      ],
      'action': [
        'python', '<(DEPTH)/build/android/gyp/apk_obfuscate.py',

        '--configuration-name', '<(CONFIGURATION_NAME)',

        '--android-sdk', '<(android_sdk)',
        '--android-sdk-tools', '<(android_sdk_tools)',
        '--android-sdk-jar', '<(android_sdk_jar)',

        '--input-jars-paths=>(proguard_input_jar_paths)',
        '--proguard-configs=>(proguard_flags_paths)',

        '--test-jar-path', '<(test_jar_path)',
        '--obfuscated-jar-path', '<(obfuscated_jar_path)',

        '--proguard-jar-path', '<(android_sdk_root)/tools/proguard/lib/proguard.jar',

        '--stamp', '<(obfuscate_stamp)',

        '>@(additional_obfuscate_options)',
      ],
    },
    {
      'action_name': 'dex_<(_target_name)',
      'variables': {
        'dex_input_paths': [
          '>@(library_dexed_jars_paths)',
          '<(jar_path)',
        ],
        'output_path': '<(dex_path)',
        'proguard_enabled_input_path': '<(obfuscated_jar_path)',
      },
      'target_conditions': [
        ['emma_instrument != 0', {
          'variables': {
            'dex_no_locals': 1,
            'dex_input_paths': [
              '<(emma_device_jar)'
            ],
          },
        }],
        ['is_test_apk == 1 and tested_apk_dex_path != "/"', {
          'variables': {
            'dex_additional_options': [
              '--excluded-paths', '@FileArg(>(tested_apk_dex_path).inputs)'
            ],
          },
          'inputs': [
            '>(tested_apk_dex_path).inputs',
          ],
        }],
        ['proguard_enabled == "true"', {
          'inputs': [ '<(obfuscate_stamp)' ]
        }, {
          'inputs': [ '<(instr_stamp)' ]
        }],
      ],
      'includes': [ 'android/dex_action.gypi' ],
    },
    {
      'variables': {
        'extra_inputs': ['<(codegen_stamp)'],
        'resource_zips': [
          '<(resource_zip_path)',
        ],
        'conditions': [
          ['is_test_apk == 0', {
            'resource_zips': [
              '>@(dependencies_res_zip_paths)',
            ],
          }],
        ],
      },
      'includes': [ 'android/package_resources_action.gypi' ],
    },
    {
      'variables': {
        'apk_path': '<(unsigned_apk_path)',
        'conditions': [
          ['native_lib_target != ""', {
            'extra_inputs': ['<(native_lib_placeholder_stamp)'],
          }],
          ['create_abi_split == 0', {
            'native_libs_dir': '<(apk_package_native_libs_dir)',
          }, {
            'native_libs_dir': '<(DEPTH)/build/android/ant/empty/res',
          }],
        ],
      },
      'includes': ['android/apkbuilder_action.gypi'],
    },
  ],
}
