# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    'chromium_code': 1,
  },
  'includes': [
    '../build/win_precompile.gypi',
    'base.gypi',
  ],
  'targets': [
    {
      'target_name': 'base',
      'type': '<(component)',
      'toolsets': ['host', 'target'],
      'variables': {
        'base_target': 1,
        'enable_wexit_time_destructors': 1,
        'optimize': 'max',
      },
      'dependencies': [
        'base_static',
        'allocator/allocator.gyp:allocator_extension_thunks',
        '../testing/gtest.gyp:gtest_prod',
        '../third_party/modp_b64/modp_b64.gyp:modp_b64',
        'third_party/dynamic_annotations/dynamic_annotations.gyp:dynamic_annotations',
      ],
      # TODO(gregoryd): direct_dependent_settings should be shared with the
      #  64-bit target, but it doesn't work due to a bug in gyp
      'direct_dependent_settings': {
        'include_dirs': [
          '..',
        ],
      },
      'conditions': [
        ['desktop_linux == 1 or chromeos == 1', {
          'conditions': [
            ['chromeos==1', {
              'sources/': [ ['include', '_chromeos\\.cc$'] ]
            }],
          ],
          'dependencies': [
            'symbolize',
            'xdg_mime',
          ],
          'defines': [
            'USE_SYMBOLIZE',
          ],
        }, {  # desktop_linux == 0 and chromeos == 0
            'sources/': [
              ['exclude', '/xdg_user_dirs/'],
              ['exclude', '_nss\\.cc$'],
            ],
        }],
        ['use_glib==1', {
          'dependencies': [
            '../build/linux/system.gyp:glib',
          ],
          'export_dependent_settings': [
            '../build/linux/system.gyp:glib',
          ],
        }],
        ['OS == "android" and _toolset == "host"', {
          # Always build base as a static_library for host toolset, even if
          # we're doing a component build. Specifically, we only care about the
          # target toolset using components since that's what developers are
          # focusing on. In theory we should do this more generally for all
          # targets when building for host, but getting the gyp magic
          # per-toolset for the "component" variable is hard, and we really only
          # need base on host.
          'type': 'static_library',
          # Base for host support is the minimum required to run the
          # ssl false start blacklist tool. It requires further changes
          # to generically support host builds (and tests).
          # Note: when building for host, gyp has OS == "android",
          # hence the *_android.cc files are included but the actual code
          # doesn't have OS_ANDROID / ANDROID defined.
          'conditions': [
            ['host_os == "mac"', {
              'sources/': [
                ['exclude', '^native_library_linux\\.cc$'],
                ['exclude', '^process_util_linux\\.cc$'],
                ['exclude', '^sys_info_linux\\.cc$'],
                ['exclude', '^sys_string_conversions_linux\\.cc$'],
                ['exclude', '^worker_pool_linux\\.cc$'],
              ],
            }],
          ],
        }],
        ['OS == "android" and _toolset == "target"', {
          'conditions': [
            ['target_arch == "ia32" or target_arch == "x64"', {
              'sources/': [
                ['include', '^atomicops_internals_x86_gcc\\.cc$'],
              ],
            }],
            ['target_arch == "mipsel"', {
              'sources/': [
                ['include', '^atomicops_internals_mips_gcc\\.cc$'],
              ],
            }],
          ],
          'dependencies': [
            'base_java',
            'base_jni_headers',
            '../build/android/ndk.gyp:cpu_features',
            '../third_party/ashmem/ashmem.gyp:ashmem',
          ],
          'link_settings': {
            'libraries': [
              '-llog',
            ],
          },
          'sources!': [
            'debug/stack_trace_posix.cc',
          ],
        }],
        ['os_bsd==1', {
          'include_dirs': [
            '/usr/local/include',
          ],
          'link_settings': {
            'libraries': [
              '-L/usr/local/lib -lexecinfo',
            ],
          },
        }],
        ['OS == "linux"', {
          'link_settings': {
            'libraries': [
              # We need rt for clock_gettime().
              '-lrt',
              # For 'native_library_linux.cc'
              '-ldl',
            ],
          },
          'conditions': [
            ['use_allocator!="tcmalloc"', {
              'defines': [
                'NO_TCMALLOC',
              ],
              'direct_dependent_settings': {
                'defines': [
                  'NO_TCMALLOC',
                ],
              },
            }],
          ],
        }],
        ['OS == "win"', {
          # Specify delayload for base.dll.
          'msvs_settings': {
            'VCLinkerTool': {
              'DelayLoadDLLs': [
                'cfgmgr32.dll',
                'powrprof.dll',
                'setupapi.dll',
              ],
              'AdditionalDependencies': [
                'cfgmgr32.lib',
                'powrprof.lib',
                'setupapi.lib',
              ],
            },
          },
          # Specify delayload for components that link with base.lib.
          'all_dependent_settings': {
            'msvs_settings': {
              'VCLinkerTool': {
                'DelayLoadDLLs': [
                  'cfgmgr32.dll',
                  'powrprof.dll',
                  'setupapi.dll',
                ],
                'AdditionalDependencies': [
                  'cfgmgr32.lib',
                  'powrprof.lib',
                  'setupapi.lib',
                ],
              },
            },
          },
          'copies': [
            {
              'destination': '<(PRODUCT_DIR)/',
              'files': [
                '../build/win/dbghelp_xp/dbghelp.dll',
              ],
            },
          ],
          'dependencies': [
           'trace_event/etw_manifest/etw_manifest.gyp:etw_manifest',
          ],
        }],
        ['OS == "mac" or (OS == "ios" and _toolset == "host")', {
          'link_settings': {
            'libraries': [
              '$(SDKROOT)/System/Library/Frameworks/AppKit.framework',
              '$(SDKROOT)/System/Library/Frameworks/ApplicationServices.framework',
              '$(SDKROOT)/System/Library/Frameworks/Carbon.framework',
              '$(SDKROOT)/System/Library/Frameworks/CoreFoundation.framework',
              '$(SDKROOT)/System/Library/Frameworks/Foundation.framework',
              '$(SDKROOT)/System/Library/Frameworks/IOKit.framework',
              '$(SDKROOT)/System/Library/Frameworks/Security.framework',
            ],
          },
        }],
        ['OS == "ios" and _toolset != "host"', {
          'link_settings': {
            'libraries': [
              '$(SDKROOT)/System/Library/Frameworks/CoreFoundation.framework',
              '$(SDKROOT)/System/Library/Frameworks/CoreGraphics.framework',
              '$(SDKROOT)/System/Library/Frameworks/CoreText.framework',
              '$(SDKROOT)/System/Library/Frameworks/Foundation.framework',
              '$(SDKROOT)/System/Library/Frameworks/UIKit.framework',
            ],
          },
        }],
        ['OS != "win" and (OS != "ios" or _toolset == "host")', {
            'dependencies': ['../third_party/libevent/libevent.gyp:libevent'],
        },],
        ['component=="shared_library"', {
          'conditions': [
            ['OS=="win"', {
              'sources!': [
                'debug/debug_on_start_win.cc',
              ],
            }],
          ],
        }],
      ],
      'sources': [
        'async_socket_io_handler.h',
        'async_socket_io_handler_posix.cc',
        'async_socket_io_handler_win.cc',
        'auto_reset.h',
        'linux_util.cc',
        'linux_util.h',
        'message_loop/message_pump_android.cc',
        'message_loop/message_pump_android.h',
        'message_loop/message_pump_glib.cc',
        'message_loop/message_pump_glib.h',
        'message_loop/message_pump_io_ios.cc',
        'message_loop/message_pump_io_ios.h',
        'message_loop/message_pump_libevent.cc',
        'message_loop/message_pump_libevent.h',
        'message_loop/message_pump_mac.h',
        'message_loop/message_pump_mac.mm',
        'metrics/field_trial.cc',
        'metrics/field_trial.h',
        'posix/file_descriptor_shuffle.cc',
        'posix/file_descriptor_shuffle.h',
        'sync_socket.h',
        'sync_socket_posix.cc',
        'sync_socket_win.cc',
        'third_party/xdg_user_dirs/xdg_user_dir_lookup.cc',
        'third_party/xdg_user_dirs/xdg_user_dir_lookup.h',
      ],
      'includes': [
        '../build/android/increase_size_for_speed.gypi',
      ],
    },
    {
      'target_name': 'base_i18n',
      'type': '<(component)',
      'variables': {
        'enable_wexit_time_destructors': 1,
        'optimize': 'max',
        'base_i18n_target': 1,
      },
      'dependencies': [
        'base',
        'third_party/dynamic_annotations/dynamic_annotations.gyp:dynamic_annotations',
        '../third_party/icu/icu.gyp:icui18n',
        '../third_party/icu/icu.gyp:icuuc',
      ],
      'conditions': [
        ['OS == "win"', {
          # TODO(jschuh): crbug.com/167187 fix size_t to int truncations.
          'msvs_disabled_warnings': [
            4267,
          ],
        }],
        ['icu_use_data_file_flag==1', {
          'defines': ['ICU_UTIL_DATA_IMPL=ICU_UTIL_DATA_FILE'],
        }, { # else icu_use_data_file_flag !=1
          'conditions': [
            ['OS=="win"', {
              'defines': ['ICU_UTIL_DATA_IMPL=ICU_UTIL_DATA_SHARED'],
            }, {
              'defines': ['ICU_UTIL_DATA_IMPL=ICU_UTIL_DATA_STATIC'],
            }],
          ],
        }],
        ['OS == "ios"', {
          'toolsets': ['host', 'target'],
        }],
      ],
      'export_dependent_settings': [
        'base',
      ],
      'includes': [
        '../build/android/increase_size_for_speed.gypi',
      ],
    },
    {
      'target_name': 'base_message_loop_tests',
      'type': 'static_library',
      'dependencies': [
        'base',
        '../testing/gtest.gyp:gtest',
      ],
      'sources': [
        'message_loop/message_loop_test.cc',
        'message_loop/message_loop_test.h',
      ],
    },
    {
      'target_name': 'base_prefs',
      'type': '<(component)',
      'variables': {
        'enable_wexit_time_destructors': 1,
        'optimize': 'max',
      },
      'dependencies': [
        'base',
      ],
      'export_dependent_settings': [
        'base',
      ],
      'defines': [
        'BASE_PREFS_IMPLEMENTATION',
      ],
      'sources': [
        'prefs/base_prefs_export.h',
        'prefs/default_pref_store.cc',
        'prefs/default_pref_store.h',
        'prefs/json_pref_store.cc',
        'prefs/json_pref_store.h',
        'prefs/overlay_user_pref_store.cc',
        'prefs/overlay_user_pref_store.h',
        'prefs/persistent_pref_store.h',
        'prefs/pref_change_registrar.cc',
        'prefs/pref_change_registrar.h',
        'prefs/pref_filter.h',
        'prefs/pref_member.cc',
        'prefs/pref_member.h',
        'prefs/pref_notifier.h',
        'prefs/pref_notifier_impl.cc',
        'prefs/pref_notifier_impl.h',
        'prefs/pref_observer.h',
        'prefs/pref_registry.cc',
        'prefs/pref_registry.h',
        'prefs/pref_registry_simple.cc',
        'prefs/pref_registry_simple.h',
        'prefs/pref_service.cc',
        'prefs/pref_service.h',
        'prefs/pref_service_factory.cc',
        'prefs/pref_service_factory.h',
        'prefs/pref_store.cc',
        'prefs/pref_store.h',
        'prefs/pref_value_map.cc',
        'prefs/pref_value_map.h',
        'prefs/pref_value_store.cc',
        'prefs/pref_value_store.h',
        'prefs/scoped_user_pref_update.cc',
        'prefs/scoped_user_pref_update.h',
        'prefs/value_map_pref_store.cc',
        'prefs/value_map_pref_store.h',
        'prefs/writeable_pref_store.h',
      ],
      'includes': [
        '../build/android/increase_size_for_speed.gypi',
      ],
    },
    {
      'target_name': 'base_prefs_test_support',
      'type': 'static_library',
      'dependencies': [
        'base',
        'base_prefs',
        '../testing/gmock.gyp:gmock',
      ],
      'sources': [
        'prefs/mock_pref_change_callback.cc',
        'prefs/pref_store_observer_mock.cc',
        'prefs/pref_store_observer_mock.h',
        'prefs/testing_pref_service.cc',
        'prefs/testing_pref_service.h',
        'prefs/testing_pref_store.cc',
        'prefs/testing_pref_store.h',
      ],
    },
    {
      # This is the subset of files from base that should not be used with a
      # dynamic library. Note that this library cannot depend on base because
      # base depends on base_static.
      'target_name': 'base_static',
      'type': 'static_library',
      'variables': {
        'enable_wexit_time_destructors': 1,
        'optimize': 'max',
      },
      'toolsets': ['host', 'target'],
      'sources': [
        'base_switches.cc',
        'base_switches.h',
        'win/pe_image.cc',
        'win/pe_image.h',
      ],
      'include_dirs': [
        '..',
      ],
      'includes': [
        '../build/android/increase_size_for_speed.gypi',
      ],
    },
    # Include this target for a main() function that simply instantiates
    # and runs a base::TestSuite.
    {
      'target_name': 'run_all_unittests',
      'type': 'static_library',
      'dependencies': [
        'test_support_base',
      ],
      'sources': [
        'test/run_all_unittests.cc',
      ],
    },
    {
      'target_name': 'base_unittests',
      'type': '<(gtest_target_type)',
      'sources': [
        'android/application_status_listener_unittest.cc',
        'android/content_uri_utils_unittest.cc',
        'android/jni_android_unittest.cc',
        'android/jni_array_unittest.cc',
        'android/jni_string_unittest.cc',
        'android/library_loader/library_prefetcher_unittest.cc',
        'android/path_utils_unittest.cc',
        'android/scoped_java_ref_unittest.cc',
        'android/sys_utils_unittest.cc',
        'async_socket_io_handler_unittest.cc',
        'at_exit_unittest.cc',
        'atomicops_unittest.cc',
        'barrier_closure_unittest.cc',
        'base64_unittest.cc',
        'big_endian_unittest.cc',
        'bind_unittest.cc',
        'bind_unittest.nc',
        'bits_unittest.cc',
        'build_time_unittest.cc',
        'callback_helpers_unittest.cc',
        'callback_list_unittest.cc',
        'callback_list_unittest.nc',
        'callback_unittest.cc',
        'callback_unittest.nc',
        'cancelable_callback_unittest.cc',
        'command_line_unittest.cc',
        'containers/adapters_unittest.cc',
        'containers/hash_tables_unittest.cc',
        'containers/linked_list_unittest.cc',
        'containers/mru_cache_unittest.cc',
        'containers/scoped_ptr_hash_map_unittest.cc',
        'containers/small_map_unittest.cc',
        'containers/stack_container_unittest.cc',
        'cpu_unittest.cc',
        'debug/crash_logging_unittest.cc',
        'debug/debugger_unittest.cc',
        'debug/leak_tracker_unittest.cc',
        'debug/proc_maps_linux_unittest.cc',
        'debug/stack_trace_unittest.cc',
        'debug/task_annotator_unittest.cc',
        'deferred_sequenced_task_runner_unittest.cc',
        'environment_unittest.cc',
        'file_version_info_unittest.cc',
        'files/dir_reader_posix_unittest.cc',
        'files/file_path_unittest.cc',
        'files/file_path_watcher_unittest.cc',
        'files/file_proxy_unittest.cc',
        'files/file_unittest.cc',
        'files/file_util_proxy_unittest.cc',
        'files/file_util_unittest.cc',
        'files/important_file_writer_unittest.cc',
        'files/memory_mapped_file_unittest.cc',
        'files/scoped_temp_dir_unittest.cc',
        'gmock_unittest.cc',
        'guid_unittest.cc',
        'hash_unittest.cc',
        'i18n/break_iterator_unittest.cc',
        'i18n/case_conversion_unittest.cc',
        'i18n/char_iterator_unittest.cc',
        'i18n/file_util_icu_unittest.cc',
        'i18n/icu_string_conversions_unittest.cc',
        'i18n/number_formatting_unittest.cc',
        'i18n/rtl_unittest.cc',
        'i18n/streaming_utf8_validator_unittest.cc',
        'i18n/string_search_unittest.cc',
        'i18n/time_formatting_unittest.cc',
        'i18n/timezone_unittest.cc',
        'id_map_unittest.cc',
        'ios/crb_protocol_observers_unittest.mm',
        'ios/device_util_unittest.mm',
        'ios/weak_nsobject_unittest.mm',
        'json/json_parser_unittest.cc',
        'json/json_reader_unittest.cc',
        'json/json_value_converter_unittest.cc',
        'json/json_value_serializer_unittest.cc',
        'json/json_writer_unittest.cc',
        'json/string_escape_unittest.cc',
        'lazy_instance_unittest.cc',
        'logging_unittest.cc',
        'mac/bind_objc_block_unittest.mm',
        'mac/dispatch_source_mach_unittest.cc',
        'mac/foundation_util_unittest.mm',
        'mac/libdispatch_task_runner_unittest.cc',
        'mac/mac_util_unittest.mm',
        'mac/objc_property_releaser_unittest.mm',
        'mac/scoped_nsobject_unittest.mm',
        'mac/scoped_objc_class_swizzler_unittest.mm',
        'mac/scoped_sending_event_unittest.mm',
        'md5_unittest.cc',
        'memory/aligned_memory_unittest.cc',
        'memory/discardable_shared_memory_unittest.cc',
        'memory/linked_ptr_unittest.cc',
        'memory/memory_pressure_monitor_chromeos_unittest.cc',
        'memory/memory_pressure_monitor_mac_unittest.cc',
        'memory/memory_pressure_monitor_win_unittest.cc',
        'memory/ref_counted_memory_unittest.cc',
        'memory/ref_counted_unittest.cc',
        'memory/scoped_ptr_unittest.cc',
        'memory/scoped_ptr_unittest.nc',
        'memory/scoped_vector_unittest.cc',
        'memory/shared_memory_unittest.cc',
        'memory/singleton_unittest.cc',
        'memory/weak_ptr_unittest.cc',
        'memory/weak_ptr_unittest.nc',
        'message_loop/message_loop_proxy_impl_unittest.cc',
        'message_loop/message_loop_proxy_unittest.cc',
        'message_loop/message_loop_unittest.cc',
        'message_loop/message_pump_glib_unittest.cc',
        'message_loop/message_pump_io_ios_unittest.cc',
        'message_loop/message_pump_libevent_unittest.cc',
        'metrics/bucket_ranges_unittest.cc',
        'metrics/field_trial_unittest.cc',
        'metrics/histogram_base_unittest.cc',
        'metrics/histogram_delta_serialization_unittest.cc',
        'metrics/histogram_macros_unittest.cc',
        'metrics/histogram_snapshot_manager_unittest.cc',
        'metrics/histogram_unittest.cc',
        'metrics/sample_map_unittest.cc',
        'metrics/sample_vector_unittest.cc',
        'metrics/sparse_histogram_unittest.cc',
        'metrics/statistics_recorder_unittest.cc',
        'move_unittest.cc',
        'numerics/safe_numerics_unittest.cc',
        'observer_list_unittest.cc',
        'os_compat_android_unittest.cc',
        'path_service_unittest.cc',
        'pickle_unittest.cc',
        'posix/file_descriptor_shuffle_unittest.cc',
        'posix/unix_domain_socket_linux_unittest.cc',
        'power_monitor/power_monitor_unittest.cc',
        'prefs/default_pref_store_unittest.cc',
        'prefs/json_pref_store_unittest.cc',
        'prefs/mock_pref_change_callback.h',
        'prefs/overlay_user_pref_store_unittest.cc',
        'prefs/pref_change_registrar_unittest.cc',
        'prefs/pref_member_unittest.cc',
        'prefs/pref_notifier_impl_unittest.cc',
        'prefs/pref_service_unittest.cc',
        'prefs/pref_value_map_unittest.cc',
        'prefs/pref_value_store_unittest.cc',
        'prefs/scoped_user_pref_update_unittest.cc',
        'process/memory_unittest.cc',
        'process/memory_unittest_mac.h',
        'process/memory_unittest_mac.mm',
        'process/process_metrics_unittest.cc',
        'process/process_metrics_unittest_ios.cc',
        'process/process_unittest.cc',
        'process/process_util_unittest.cc',
        'profiler/stack_sampling_profiler_unittest.cc',
        'profiler/tracked_time_unittest.cc',
        'rand_util_unittest.cc',
        'scoped_clear_errno_unittest.cc',
        'scoped_generic_unittest.cc',
        'scoped_native_library_unittest.cc',
        'security_unittest.cc',
        'sequence_checker_unittest.cc',
        'sha1_unittest.cc',
        'stl_util_unittest.cc',
        'strings/nullable_string16_unittest.cc',
        'strings/safe_sprintf_unittest.cc',
        'strings/string16_unittest.cc',
        'strings/string_number_conversions_unittest.cc',
        'strings/string_piece_unittest.cc',
        'strings/string_split_unittest.cc',
        'strings/string_tokenizer_unittest.cc',
        'strings/string_util_unittest.cc',
        'strings/stringize_macros_unittest.cc',
        'strings/stringprintf_unittest.cc',
        'strings/sys_string_conversions_mac_unittest.mm',
        'strings/sys_string_conversions_unittest.cc',
        'strings/utf_offset_string_conversions_unittest.cc',
        'strings/utf_string_conversions_unittest.cc',
        'supports_user_data_unittest.cc',
        'sync_socket_unittest.cc',
        'synchronization/cancellation_flag_unittest.cc',
        'synchronization/condition_variable_unittest.cc',
        'synchronization/lock_unittest.cc',
        'synchronization/waitable_event_unittest.cc',
        'synchronization/waitable_event_watcher_unittest.cc',
        'sys_info_unittest.cc',
        'system_monitor/system_monitor_unittest.cc',
        'task/cancelable_task_tracker_unittest.cc',
        'task_runner_util_unittest.cc',
        'template_util_unittest.cc',
        'test/expectations/expectation_unittest.cc',
        'test/expectations/parser_unittest.cc',
        'test/histogram_tester_unittest.cc',
        'test/test_pending_task_unittest.cc',
        'test/test_reg_util_win_unittest.cc',
        'test/trace_event_analyzer_unittest.cc',
        'test/user_action_tester_unittest.cc',
        'threading/non_thread_safe_unittest.cc',
        'threading/platform_thread_unittest.cc',
        'threading/sequenced_worker_pool_unittest.cc',
        'threading/simple_thread_unittest.cc',
        'threading/thread_checker_unittest.cc',
        'threading/thread_collision_warner_unittest.cc',
        'threading/thread_id_name_manager_unittest.cc',
        'threading/thread_local_storage_unittest.cc',
        'threading/thread_local_unittest.cc',
        'threading/thread_unittest.cc',
        'threading/watchdog_unittest.cc',
        'threading/worker_pool_posix_unittest.cc',
        'threading/worker_pool_unittest.cc',
        'time/pr_time_unittest.cc',
        'time/time_unittest.cc',
        'time/time_win_unittest.cc',
        'timer/hi_res_timer_manager_unittest.cc',
        'timer/mock_timer_unittest.cc',
        'timer/timer_unittest.cc',
        'tools_sanity_unittest.cc',
        'tracked_objects_unittest.cc',
        'tuple_unittest.cc',
        'values_unittest.cc',
        'version_unittest.cc',
        'vlog_unittest.cc',
        'win/dllmain.cc',
        'win/enum_variant_unittest.cc',
        'win/event_trace_consumer_unittest.cc',
        'win/event_trace_controller_unittest.cc',
        'win/event_trace_provider_unittest.cc',
        'win/i18n_unittest.cc',
        'win/iunknown_impl_unittest.cc',
        'win/message_window_unittest.cc',
        'win/object_watcher_unittest.cc',
        'win/pe_image_unittest.cc',
        'win/registry_unittest.cc',
        'win/scoped_bstr_unittest.cc',
        'win/scoped_comptr_unittest.cc',
        'win/scoped_process_information_unittest.cc',
        'win/scoped_variant_unittest.cc',
        'win/shortcut_unittest.cc',
        'win/startup_information_unittest.cc',
        'win/win_util_unittest.cc',
        'win/wrapped_window_proc_unittest.cc',
        '<@(trace_event_test_sources)',
      ],
      'dependencies': [
        'base',
        'base_i18n',
        'base_message_loop_tests',
        'base_prefs',
        'base_prefs_test_support',
        'base_static',
        'run_all_unittests',
        'test_support_base',
        'third_party/dynamic_annotations/dynamic_annotations.gyp:dynamic_annotations',
        '../testing/gmock.gyp:gmock',
        '../testing/gtest.gyp:gtest',
        '../third_party/icu/icu.gyp:icui18n',
        '../third_party/icu/icu.gyp:icuuc',
      ],
      'includes': ['../build/nocompile.gypi'],
      'variables': {
         # TODO(ajwong): Is there a way to autodetect this?
        'module_dir': 'base'
      },
      'conditions': [
        ['OS == "android"', {
          'dependencies': [
            'android/jni_generator/jni_generator.gyp:jni_generator_tests',
            '../testing/android/native_test.gyp:native_test_native_code',
          ],
        }],
        ['OS == "ios" and _toolset != "host"', {
          'sources/': [
            # Only test the iOS-meaningful portion of process_utils.
            ['exclude', '^process/memory_unittest'],
            ['exclude', '^process/process_unittest\\.cc$'],
            ['exclude', '^process/process_util_unittest\\.cc$'],
            ['include', '^process/process_util_unittest_ios\\.cc$'],
            # iOS does not use message_pump_libevent.
            ['exclude', '^message_loop/message_pump_libevent_unittest\\.cc$'],
          ],
          'actions': [
            {
              'action_name': 'copy_test_data',
              'variables': {
                'test_data_files': [
                  'test/data',
                ],
                'test_data_prefix': 'base',
              },
              'includes': [ '../build/copy_test_data_ios.gypi' ],
            },
          ],
        }],
        ['desktop_linux == 1 or chromeos == 1', {
          'defines': [
            'USE_SYMBOLIZE',
          ],
          'sources!': [
            'file_version_info_unittest.cc',
          ],
          'conditions': [
            [ 'desktop_linux==1', {
              'sources': [
                'nix/xdg_util_unittest.cc',
              ],
            }],
          ],
        }],
        ['use_glib == 1', {
          'dependencies': [
            '../build/linux/system.gyp:glib',
          ],
        }, {  # use_glib == 0
          'sources!': [
            'message_loop/message_pump_glib_unittest.cc',
          ]
        }],
        ['use_ozone == 1', {
          'sources!': [
            'message_loop/message_pump_glib_unittest.cc',
          ]
        }],
        ['OS == "linux"', {
          'dependencies': [
            'malloc_wrapper',
          ],
          'conditions': [
            ['use_allocator!="none"', {
              'dependencies': [
                'allocator/allocator.gyp:allocator',
              ],
            }],
          ]},
        ],
        ['OS == "win"', {
          'sources!': [
            'file_descriptor_shuffle_unittest.cc',
            'files/dir_reader_posix_unittest.cc',
            'message_loop/message_pump_libevent_unittest.cc',
            'threading/worker_pool_posix_unittest.cc',
          ],
          # TODO(jschuh): crbug.com/167187 fix size_t to int truncations.
          'msvs_disabled_warnings': [
            4267,
          ],
          'conditions': [
            # This is needed so base_unittests uses the allocator shim, as
            # SecurityTest.MemoryAllocationRestriction* tests are dependent
            # on tcmalloc.
            # TODO(wfh): crbug.com/246278 Move tcmalloc specific tests into
            # their own test suite.
            ['win_use_allocator_shim==1', {
              'dependencies': [
                'allocator/allocator.gyp:allocator',
              ],
            }],
            ['icu_use_data_file_flag==0', {
              # This is needed to trigger the dll copy step on windows.
              # TODO(mark): This should not be necessary.
              'dependencies': [
                '../third_party/icu/icu.gyp:icudata',
              ],
            }],
          ],
        }, {  # OS != "win"
          'dependencies': [
            '../third_party/libevent/libevent.gyp:libevent'
          ],
        }],
      ],  # conditions
      'target_conditions': [
        ['OS == "ios" and _toolset != "host"', {
          'sources/': [
            # Pull in specific Mac files for iOS (which have been filtered out
            # by file name rules).
            ['include', '^mac/bind_objc_block_unittest\\.mm$'],
            ['include', '^mac/foundation_util_unittest\\.mm$',],
            ['include', '^mac/objc_property_releaser_unittest\\.mm$'],
            ['include', '^mac/scoped_nsobject_unittest\\.mm$'],
            ['include', '^sys_string_conversions_mac_unittest\\.mm$'],
          ],
        }],
        ['OS == "android"', {
          'sources/': [
            ['include', '^debug/proc_maps_linux_unittest\\.cc$'],
          ],
        }],
        # Enable more direct string conversions on platforms with native utf8
        # strings
        ['OS=="mac" or OS=="ios" or <(chromeos)==1 or <(chromecast)==1', {
          'defines': ['SYSTEM_NATIVE_UTF8'],
        }],
      ],  # target_conditions
    },
    {
      # GN: //base:base_perftests
      'target_name': 'base_perftests',
      'type': '<(gtest_target_type)',
      'dependencies': [
        'base',
        'test_support_base',
        '../testing/gtest.gyp:gtest',
      ],
      'sources': [
        'message_loop/message_pump_perftest.cc',
        'test/run_all_unittests.cc',
        'threading/thread_perftest.cc',
        '../testing/perf/perf_test.cc'
      ],
      'conditions': [
        ['OS == "android"', {
          'dependencies': [
            '../testing/android/native_test.gyp:native_test_native_code',
          ],
        }],
      ],
    },
    {
      # GN: //base:base_i18n_perftests
      'target_name': 'base_i18n_perftests',
      'type': '<(gtest_target_type)',
      'dependencies': [
        'test_support_base',
        'test_support_perf',
        '../testing/gtest.gyp:gtest',
        'base_i18n',
        'base',
      ],
      'sources': [
        'i18n/streaming_utf8_validator_perftest.cc',
      ],
    },
    {
      # GN: //base/test:test_support
      'target_name': 'test_support_base',
      'type': 'static_library',
      'dependencies': [
        'base',
        'base_static',
        'base_i18n',
        '../testing/gmock.gyp:gmock',
        '../testing/gtest.gyp:gtest',
        '../third_party/icu/icu.gyp:icuuc',
        '../third_party/libxml/libxml.gyp:libxml',
        'third_party/dynamic_annotations/dynamic_annotations.gyp:dynamic_annotations',
      ],
      'export_dependent_settings': [
        'base',
      ],
      'conditions': [
        ['os_posix==0', {
          'sources!': [
            'test/scoped_locale.cc',
            'test/scoped_locale.h',
          ],
        }],
        ['os_bsd==1', {
          'sources!': [
            'test/test_file_util_linux.cc',
          ],
        }],
        ['OS == "android"', {
          'dependencies': [
            'base_unittests_jni_headers',
            'base_java_unittest_support',
          ],
        }],
        ['OS == "ios"', {
          'toolsets': ['host', 'target'],
        }],
      ],
      'sources': [
        'test/expectations/expectation.cc',
        'test/expectations/expectation.h',
        'test/expectations/parser.cc',
        'test/expectations/parser.h',
        'test/gtest_util.cc',
        'test/gtest_util.h',
        'test/gtest_xml_unittest_result_printer.cc',
        'test/gtest_xml_unittest_result_printer.h',
        'test/gtest_xml_util.cc',
        'test/gtest_xml_util.h',
        'test/histogram_tester.cc',
        'test/histogram_tester.h',
        'test/ios/wait_util.h',
        'test/ios/wait_util.mm',
        'test/launcher/test_launcher.cc',
        'test/launcher/test_launcher.h',
        'test/launcher/test_result.cc',
        'test/launcher/test_result.h',
        'test/launcher/test_results_tracker.cc',
        'test/launcher/test_results_tracker.h',
        'test/launcher/unit_test_launcher.cc',
        'test/launcher/unit_test_launcher.h',
        'test/launcher/unit_test_launcher_ios.cc',
        'test/mock_chrome_application_mac.h',
        'test/mock_chrome_application_mac.mm',
        'test/mock_devices_changed_observer.cc',
        'test/mock_devices_changed_observer.h',
        'test/mock_entropy_provider.cc',
        'test/mock_entropy_provider.h',
        'test/mock_log.cc',
        'test/mock_log.h',
        'test/multiprocess_test.cc',
        'test/multiprocess_test.h',
        'test/multiprocess_test_android.cc',
        'test/null_task_runner.cc',
        'test/null_task_runner.h',
        'test/opaque_ref_counted.cc',
        'test/opaque_ref_counted.h',
        'test/perf_log.cc',
        'test/perf_log.h',
        'test/perf_test_suite.cc',
        'test/perf_test_suite.h',
        'test/perf_time_logger.cc',
        'test/perf_time_logger.h',
        'test/power_monitor_test_base.cc',
        'test/power_monitor_test_base.h',
        'test/scoped_locale.cc',
        'test/scoped_locale.h',
        'test/scoped_path_override.cc',
        'test/scoped_path_override.h',
        'test/sequenced_task_runner_test_template.cc',
        'test/sequenced_task_runner_test_template.h',
        'test/sequenced_worker_pool_owner.cc',
        'test/sequenced_worker_pool_owner.h',
        'test/simple_test_clock.cc',
        'test/simple_test_clock.h',
        'test/simple_test_tick_clock.cc',
        'test/simple_test_tick_clock.h',
        'test/task_runner_test_template.cc',
        'test/task_runner_test_template.h',
        'test/test_discardable_memory_allocator.cc',
        'test/test_discardable_memory_allocator.h',
        'test/test_file_util.cc',
        'test/test_file_util.h',
        'test/test_file_util_android.cc',
        'test/test_file_util_linux.cc',
        'test/test_file_util_mac.cc',
        'test/test_file_util_posix.cc',
        'test/test_file_util_win.cc',
        'test/test_io_thread.cc',
        'test/test_io_thread.h',
        'test/test_listener_ios.h',
        'test/test_listener_ios.mm',
        'test/test_mock_time_task_runner.cc',
        'test/test_mock_time_task_runner.h',
        'test/test_pending_task.cc',
        'test/test_pending_task.h',
        'test/test_reg_util_win.cc',
        'test/test_reg_util_win.h',
        'test/test_shortcut_win.cc',
        'test/test_shortcut_win.h',
        'test/test_simple_task_runner.cc',
        'test/test_simple_task_runner.h',
        'test/test_suite.cc',
        'test/test_suite.h',
        'test/test_support_android.cc',
        'test/test_support_android.h',
        'test/test_support_ios.h',
        'test/test_support_ios.mm',
        'test/test_switches.cc',
        'test/test_switches.h',
        'test/test_timeouts.cc',
        'test/test_timeouts.h',
        'test/test_ui_thread_android.cc',
        'test/test_ui_thread_android.h',
        'test/thread_test_helper.cc',
        'test/thread_test_helper.h',
        'test/trace_event_analyzer.cc',
        'test/trace_event_analyzer.h',
        'test/trace_to_file.cc',
        'test/trace_to_file.h',
        'test/user_action_tester.cc',
        'test/user_action_tester.h',
        'test/values_test_util.cc',
        'test/values_test_util.h',
      ],
      'target_conditions': [
        ['OS == "ios"', {
          'sources/': [
            # Pull in specific Mac files for iOS (which have been filtered out
            # by file name rules).
            ['include', '^test/test_file_util_mac\\.cc$'],
          ],
        }],
        ['OS == "ios" and _toolset == "target"', {
          'sources!': [
            # iOS uses its own unit test launcher.
            'test/launcher/unit_test_launcher.cc',
          ],
        }],
        ['OS == "ios" and _toolset == "host"', {
          'sources!': [
            'test/launcher/unit_test_launcher_ios.cc',
            'test/test_support_ios.h',
            'test/test_support_ios.mm',
          ],
        }],
      ],  # target_conditions
    },
    {
      'target_name': 'test_support_perf',
      'type': 'static_library',
      'dependencies': [
        'base',
        'test_support_base',
        '../testing/gtest.gyp:gtest',
      ],
      'sources': [
        'test/run_all_perftests.cc',
      ],
      'direct_dependent_settings': {
        'defines': [
          'PERF_TEST',
        ],
      },
    },
    {
      'target_name': 'test_launcher_nacl_nonsfi',
      'conditions': [
        ['disable_nacl==0 and disable_nacl_untrusted==0 and enable_nacl_nonsfi_test==1', {
          'type': 'static_library',
          'sources': [
            'test/launcher/test_launcher_nacl_nonsfi.cc',
          ],
          'dependencies': [
            'test_support_base',
          ],
        }, {
          'type': 'none',
        }],
      ],
    },
  ],
  'conditions': [
    ['OS=="ios" and "<(GENERATOR)"=="ninja"', {
      'targets': [
        {
          'target_name': 'test_launcher',
          'toolsets': ['host'],
          'type': 'executable',
          'dependencies': [
            'test_support_base',
          ],
          'sources': [
            'test/launcher/test_launcher_ios.cc',
          ],
        },
      ],
    }],
    ['OS!="ios"', {
      'targets': [
        {
          # GN: //base:check_example
          'target_name': 'check_example',
          'type': 'executable',
          'sources': [
            'check_example.cc',
          ],
          'dependencies': [
            'base',
          ],
        },
        {
          'target_name': 'build_utf8_validator_tables',
          'type': 'executable',
          'toolsets': ['host'],
          'dependencies': [
            'base',
            '../third_party/icu/icu.gyp:icuuc',
          ],
          'sources': [
            'i18n/build_utf8_validator_tables.cc'
          ],
        },
      ],
    }],
    ['OS == "win" and target_arch=="ia32"', {
      'targets': [
        # The base_win64 target here allows us to use base for Win64 targets
        # (the normal build is 32 bits).
        {
          'target_name': 'base_win64',
          'type': '<(component)',
          'variables': {
            'base_target': 1,
          },
          'dependencies': [
            'base_static_win64',
            'allocator/allocator.gyp:allocator_extension_thunks_win64',
            '../third_party/modp_b64/modp_b64.gyp:modp_b64_win64',
            'third_party/dynamic_annotations/dynamic_annotations.gyp:dynamic_annotations_win64',
            'trace_event/etw_manifest/etw_manifest.gyp:etw_manifest',
          ],
          # TODO(gregoryd): direct_dependent_settings should be shared with the
          # 32-bit target, but it doesn't work due to a bug in gyp
          'direct_dependent_settings': {
            'include_dirs': [
              '..',
            ],
          },
          'defines': [
            'BASE_WIN64',
            '<@(nacl_win64_defines)',
          ],
          'configurations': {
            'Common_Base': {
              'msvs_target_platform': 'x64',
            },
          },
          'conditions': [
            ['component == "shared_library"', {
              'sources!': [
                'debug/debug_on_start_win.cc',
              ],
            }],
          ],
          # Specify delayload for base_win64.dll.
          'msvs_settings': {
            'VCLinkerTool': {
              'DelayLoadDLLs': [
                'cfgmgr32.dll',
                'powrprof.dll',
                'setupapi.dll',
              ],
              'AdditionalDependencies': [
                'cfgmgr32.lib',
                'powrprof.lib',
                'setupapi.lib',
              ],
            },
          },
          # Specify delayload for components that link with base_win64.lib.
          'all_dependent_settings': {
            'msvs_settings': {
              'VCLinkerTool': {
                'DelayLoadDLLs': [
                  'cfgmgr32.dll',
                  'powrprof.dll',
                  'setupapi.dll',
                ],
                'AdditionalDependencies': [
                  'cfgmgr32.lib',
                  'powrprof.lib',
                  'setupapi.lib',
                ],
              },
            },
          },
          # TODO(rvargas): Bug 78117. Remove this.
          'msvs_disabled_warnings': [
            4244,
            4996,
            4267,
          ],
          'sources': [
            'async_socket_io_handler.h',
            'async_socket_io_handler_posix.cc',
            'async_socket_io_handler_win.cc',
            'auto_reset.h',
            'linux_util.cc',
            'linux_util.h',
            'md5.cc',
            'md5.h',
            'message_loop/message_pump_libevent.cc',
            'message_loop/message_pump_libevent.h',
            'metrics/field_trial.cc',
            'metrics/field_trial.h',
            'posix/file_descriptor_shuffle.cc',
            'posix/file_descriptor_shuffle.h',
            'sync_socket.h',
            'sync_socket_posix.cc',
            'sync_socket_win.cc',
            'third_party/xdg_user_dirs/xdg_user_dir_lookup.cc',
            'third_party/xdg_user_dirs/xdg_user_dir_lookup.h',
          ],
        },
        {
          'target_name': 'base_i18n_nacl_win64',
          'type': '<(component)',
          # TODO(gregoryd): direct_dependent_settings should be shared with the
          # 32-bit target, but it doesn't work due to a bug in gyp
          'direct_dependent_settings': {
            'include_dirs': [
              '..',
            ],
          },
          'defines': [
            '<@(nacl_win64_defines)',
            'BASE_I18N_IMPLEMENTATION',
          ],
          'include_dirs': [
            '..',
          ],
          'sources': [
            'i18n/icu_util_nacl_win64.cc',
          ],
          'configurations': {
            'Common_Base': {
              'msvs_target_platform': 'x64',
            },
          },
        },
        {
          # TODO(rvargas): Remove this when gyp finally supports a clean model.
          # See bug 36232.
          'target_name': 'base_static_win64',
          'type': 'static_library',
          'sources': [
            'base_switches.cc',
            'base_switches.h',
            'win/pe_image.cc',
            'win/pe_image.h',
          ],
          'sources!': [
            # base64.cc depends on modp_b64.
            'base64.cc',
          ],
          'include_dirs': [
            '..',
          ],
          'configurations': {
            'Common_Base': {
              'msvs_target_platform': 'x64',
            },
          },
          'defines': [
            '<@(nacl_win64_defines)',
          ],
          # TODO(rvargas): Bug 78117. Remove this.
          'msvs_disabled_warnings': [
            4244,
          ],
        },
      ],
    }],
    ['os_posix==1 and OS!="mac" and OS!="ios"', {
      'targets': [
        {
          'target_name': 'symbolize',
          'type': 'static_library',
          'toolsets': ['host', 'target'],
          'variables': {
            'chromium_code': 0,
          },
          'conditions': [
            ['OS == "solaris"', {
              'include_dirs': [
                '/usr/gnu/include',
                '/usr/gnu/include/libelf',
              ],
            },],
          ],
          'cflags': [
            '-Wno-sign-compare',
          ],
          'cflags!': [
            '-Wextra',
          ],
          'defines': [
            'GLOG_BUILD_CONFIG_INCLUDE="build/build_config.h"',
          ],
          'sources': [
            'third_party/symbolize/config.h',
            'third_party/symbolize/demangle.cc',
            'third_party/symbolize/demangle.h',
            'third_party/symbolize/glog/logging.h',
            'third_party/symbolize/glog/raw_logging.h',
            'third_party/symbolize/symbolize.cc',
            'third_party/symbolize/symbolize.h',
            'third_party/symbolize/utilities.h',
          ],
          'include_dirs': [
            '..',
          ],
          'includes': [
            '../build/android/increase_size_for_speed.gypi',
          ],
        },
        {
          'target_name': 'xdg_mime',
          'type': 'static_library',
          'toolsets': ['host', 'target'],
          'variables': {
            'chromium_code': 0,
          },
          'cflags!': [
            '-Wextra',
          ],
          'sources': [
            'third_party/xdg_mime/xdgmime.c',
            'third_party/xdg_mime/xdgmime.h',
            'third_party/xdg_mime/xdgmimealias.c',
            'third_party/xdg_mime/xdgmimealias.h',
            'third_party/xdg_mime/xdgmimecache.c',
            'third_party/xdg_mime/xdgmimecache.h',
            'third_party/xdg_mime/xdgmimeglob.c',
            'third_party/xdg_mime/xdgmimeglob.h',
            'third_party/xdg_mime/xdgmimeicon.c',
            'third_party/xdg_mime/xdgmimeicon.h',
            'third_party/xdg_mime/xdgmimeint.c',
            'third_party/xdg_mime/xdgmimeint.h',
            'third_party/xdg_mime/xdgmimemagic.c',
            'third_party/xdg_mime/xdgmimemagic.h',
            'third_party/xdg_mime/xdgmimeparent.c',
            'third_party/xdg_mime/xdgmimeparent.h',
          ],
          'includes': [
            '../build/android/increase_size_for_speed.gypi',
          ],
        },
      ],
    }],
    ['OS == "linux"', {
      'targets': [
        {
          'target_name': 'malloc_wrapper',
          'type': 'shared_library',
          'dependencies': [
            'base',
          ],
          'sources': [
            'test/malloc_wrapper.cc',
          ],
        }
      ],
    }],
    ['OS == "android"', {
      'targets': [
        {
          # GN: //base:base_jni_headers
          'target_name': 'base_jni_headers',
          'type': 'none',
          'sources': [
            'android/java/src/org/chromium/base/ApkAssets.java',
            'android/java/src/org/chromium/base/ApplicationStatus.java',
            'android/java/src/org/chromium/base/AnimationFrameTimeHistogram.java',
            'android/java/src/org/chromium/base/BuildInfo.java',
            'android/java/src/org/chromium/base/CommandLine.java',
            'android/java/src/org/chromium/base/ContentUriUtils.java',
            'android/java/src/org/chromium/base/CpuFeatures.java',
            'android/java/src/org/chromium/base/EventLog.java',
            'android/java/src/org/chromium/base/FieldTrialList.java',
            'android/java/src/org/chromium/base/ImportantFileWriterAndroid.java',
            'android/java/src/org/chromium/base/JNIUtils.java',
            'android/java/src/org/chromium/base/JavaHandlerThread.java',
            'android/java/src/org/chromium/base/LocaleUtils.java',
            'android/java/src/org/chromium/base/MemoryPressureListener.java',
            'android/java/src/org/chromium/base/PathService.java',
            'android/java/src/org/chromium/base/PathUtils.java',
            'android/java/src/org/chromium/base/PowerMonitor.java',
            'android/java/src/org/chromium/base/SysUtils.java',
            'android/java/src/org/chromium/base/SystemMessageHandler.java',
            'android/java/src/org/chromium/base/ThreadUtils.java',
            'android/java/src/org/chromium/base/TraceEvent.java',
            'android/java/src/org/chromium/base/library_loader/LibraryLoader.java',
            'android/java/src/org/chromium/base/metrics/RecordHistogram.java',
            'android/java/src/org/chromium/base/metrics/RecordUserAction.java',
          ],
          'variables': {
            'jni_gen_package': 'base',
          },
          'dependencies': [
            'android_runtime_jni_headers',
          ],
          'includes': [ '../build/jni_generator.gypi' ],
        },
        {
          # GN: //base:android_runtime_jni_headers
          'target_name': 'android_runtime_jni_headers',
          'type': 'none',
          'variables': {
            'jni_gen_package': 'base',
            'input_java_class': 'java/lang/Runtime.class',
          },
          'includes': [ '../build/jar_file_jni_generator.gypi' ],
        },
        {
          # TODO(GN)
          'target_name': 'base_unittests_jni_headers',
          'type': 'none',
          'sources': [
            'test/android/java/src/org/chromium/base/ContentUriTestUtils.java',
            'test/android/java/src/org/chromium/base/TestUiThread.java',
          ],
          'variables': {
            'jni_gen_package': 'base',
          },
          'includes': [ '../build/jni_generator.gypi' ],
        },
        {
          # GN: //base:base_native_libraries_gen
          'target_name': 'base_native_libraries_gen',
          'type': 'none',
          'sources': [
            'android/java/templates/NativeLibraries.template',
          ],
          'variables': {
            'package_name': 'org/chromium/base/library_loader',
            'template_deps': [],
          },
          'includes': [ '../build/android/java_cpp_template.gypi' ],
        },
        {
          # GN: //base:base_android_java_enums_srcjar
          'target_name': 'base_java_library_process_type',
          'type': 'none',
          'variables': {
            'source_file': 'android/library_loader/library_loader_hooks.h',
          },
          'includes': [ '../build/android/java_cpp_enum.gypi' ],
        },
        {
          # GN: //base:base_java
          'target_name': 'base_java',
          'type': 'none',
          'variables': {
            'java_in_dir': '../base/android/java',
            'jar_excluded_classes': [ '*/NativeLibraries.class' ],
          },
          'dependencies': [
            'base_java_application_state',
            'base_java_library_load_from_apk_status_codes',
            'base_java_library_process_type',
            'base_java_memory_pressure_level',
            'base_native_libraries_gen',
            '../third_party/jsr-305/jsr-305.gyp:jsr_305_javalib',
          ],
          'includes': [ '../build/java.gypi' ],
        },
        {
          # GN: //base:base_java_unittest_support
          'target_name': 'base_java_unittest_support',
          'type': 'none',
          'dependencies': [
            'base_java',
          ],
          'variables': {
            'java_in_dir': '../base/test/android/java',
          },
          'includes': [ '../build/java.gypi' ],
        },
        {
          # GN: //base:base_android_java_enums_srcjar
          'target_name': 'base_java_application_state',
          'type': 'none',
          'variables': {
            'source_file': 'android/application_status_listener.h',
          },
          'includes': [ '../build/android/java_cpp_enum.gypi' ],
        },
        {
          # GN: //base:base_android_java_enums_srcjar
          'target_name': 'base_java_library_load_from_apk_status_codes',
          'type': 'none',
          'variables': {
            'source_file': 'android/library_loader/library_load_from_apk_status_codes.h'
          },
          'includes': [ '../build/android/java_cpp_enum.gypi' ],
        },
        {
          # GN: //base:base_android_java_enums_srcjar
          'target_name': 'base_java_memory_pressure_level',
          'type': 'none',
          'variables': {
            'source_file': 'memory/memory_pressure_listener.h',
          },
          'includes': [ '../build/android/java_cpp_enum.gypi' ],
        },
        {
          # GN: //base:base_java_test_support
          'target_name': 'base_java_test_support',
          'type': 'none',
          'dependencies': [
            'base_java',
            '../testing/android/on_device_instrumentation.gyp:reporter_java',
          ],
          'variables': {
            'java_in_dir': '../base/test/android/javatests',
          },
          'includes': [ '../build/java.gypi' ],
        },
        {
          # GN: //base:base_junit_tests
          'target_name': 'base_junit_tests',
          'type': 'none',
          'dependencies': [
            'base_java',
            'base_java_test_support',
            '../testing/android/junit/junit_test.gyp:junit_test_support',
          ],
          'variables': {
             'main_class': 'org.chromium.testing.local.JunitTestMain',
             'src_paths': [
               '../base/android/junit/',
             ],
           },
          'includes': [ '../build/host_jar.gypi' ],
        },
        {
          # GN: //base:base_javatests
          'target_name': 'base_javatests',
          'type': 'none',
          'dependencies': [
            'base_java',
            'base_java_test_support',
          ],
          'variables': {
            'java_in_dir': '../base/android/javatests',
          },
          'includes': [ '../build/java.gypi' ],
        },
        {
          # GN: //base/android/linker:chromium_android_linker
          'target_name': 'chromium_android_linker',
          'type': 'shared_library',
          'sources': [
            'android/linker/linker_jni.cc',
          ],
          # The crazy linker is never instrumented.
          'cflags!': [
            '-finstrument-functions',
          ],
          'dependencies': [
            # The NDK contains the crazy_linker here:
            #   '<(android_ndk_root)/crazy_linker.gyp:crazy_linker'
            # However, we use our own fork.  See bug 384700.
            '../third_party/android_crazy_linker/crazy_linker.gyp:crazy_linker',
          ],
        },
        {
          # TODO(GN)
          'target_name': 'base_perftests_apk',
          'type': 'none',
          'dependencies': [
            'base_perftests',
          ],
          'variables': {
            'test_suite_name': 'base_perftests',
          },
          'includes': [ '../build/apk_test.gypi' ],
        },
        {
          # GN: //base:base_unittests_apk
          'target_name': 'base_unittests_apk',
          'type': 'none',
          'dependencies': [
            'base_java',
            'base_unittests',
          ],
          'variables': {
            'test_suite_name': 'base_unittests',
            'isolate_file': 'base_unittests.isolate',
          },
          'includes': [ '../build/apk_test.gypi' ],
        },
      ],
    }],
    ['OS == "win"', {
      'targets': [
        {
          'target_name': 'debug_message',
          'type': 'executable',
          'sources': [
            'debug_message.cc',
          ],
          'msvs_settings': {
            'VCLinkerTool': {
              'SubSystem': '2',         # Set /SUBSYSTEM:WINDOWS
            },
          },
        },
        {
          # Target to manually rebuild pe_image_test.dll which is checked into
          # base/test/data/pe_image.
          'target_name': 'pe_image_test',
          'type': 'shared_library',
          'sources': [
            'win/pe_image_test.cc',
          ],
          'msvs_settings': {
            'VCLinkerTool': {
              'SubSystem': '2',         # Set /SUBSYSTEM:WINDOWS
              'DelayLoadDLLs': [
                'cfgmgr32.dll',
                'shell32.dll',
              ],
              'AdditionalDependencies': [
                'cfgmgr32.lib',
                'shell32.lib',
              ],
            },
          },
        },
      ],
    }],
    ['test_isolation_mode != "noop"', {
      'targets': [
        {
          'target_name': 'base_unittests_run',
          'type': 'none',
          'dependencies': [
            'base_unittests',
          ],
          'includes': [
            '../build/isolate.gypi',
          ],
          'sources': [
            'base_unittests.isolate',
          ],
        },
      ],
    }],
  ],
}
