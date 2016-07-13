# Copyright (c) 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file defines five targets that we are using to track the progress of the
# GYP->GN migration:
#
# 'both_gn_and_gyp' lists what GN is currently capable of building and should
# match the 'both_gn_and_gyp' target in //BUILD.gn.
#
# 'gyp_all' Should include everything built when building "all"; i.e., if you
# type 'ninja gyp_all' and then 'ninja all', the second build should do
# nothing. 'gyp_all' should just depend on the other four targets.
#
# 'gyp_only' lists any targets that are not meant to be ported over to the GN
# build.
#
# 'gyp_remaining' lists all of the targets that still need to be converted,
# i.e., all of the other (non-empty) targets that a GYP build will build.
#
# TODO(GYP): crbug.com/481694. Add a build step to the bot that enforces the
# above contracts.

{
  'targets': [
    {
      'target_name': 'gyp_all',
      'type': 'none',
      'dependencies': [
        'both_gn_and_gyp',
        'gyp_only',
        'gyp_remaining',
      ]
    },
    {
      # This target should mirror the structure of //:both_gn_and_gyp
      # in src/BUILD.gn as closely as possible, for ease of comparison.
      'target_name': 'both_gn_and_gyp',
      'type': 'none',
      'dependencies': [
        '../base/base.gyp:base_i18n_perftests',
        '../base/base.gyp:base_perftests',
        '../base/base.gyp:base_unittests',
        '../base/base.gyp:build_utf8_validator_tables#host',
        '../base/base.gyp:check_example',
        '../cc/cc_tests.gyp:cc_perftests',
        '../cc/cc_tests.gyp:cc_unittests',
        '../cc/blink/cc_blink_tests.gyp:cc_blink_unittests',
        '../chrome/chrome.gyp:chrome',
        '../chrome/chrome.gyp:browser_tests',
        '../chrome/chrome.gyp:chrome_app_unittests',
        '../chrome/chrome.gyp:chromedriver',
        '../chrome/chrome.gyp:chromedriver_tests',
        '../chrome/chrome.gyp:chromedriver_unittests',
        '../chrome/chrome.gyp:interactive_ui_tests',
        '../chrome/chrome.gyp:load_library_perf_tests',
        '../chrome/chrome.gyp:performance_browser_tests',
        '../chrome/chrome.gyp:sync_integration_tests',
        '../chrome/chrome.gyp:sync_performance_tests',
        '../chrome/chrome.gyp:unit_tests',
        '../chrome/tools/profile_reset/jtl_compiler.gyp:jtl_compiler',
        '../cloud_print/cloud_print.gyp:cloud_print_unittests',
        '../components/components.gyp:network_hints_browser',
        '../components/components.gyp:policy_templates',
        '../components/components_tests.gyp:components_browsertests',
        '../components/components_tests.gyp:components_perftests',
        '../components/components_tests.gyp:components_unittests',
        '../content/content.gyp:content_app_browser',
        '../content/content.gyp:content_app_child',
        '../content/content_shell_and_tests.gyp:content_browsertests',
        '../content/content_shell_and_tests.gyp:content_gl_benchmark',
        '../content/content_shell_and_tests.gyp:content_gl_tests',
        '../content/content_shell_and_tests.gyp:content_perftests',
        '../content/content_shell_and_tests.gyp:content_shell',
        '../content/content_shell_and_tests.gyp:content_unittests',
        '../courgette/courgette.gyp:courgette',
        '../courgette/courgette.gyp:courgette_fuzz',
        '../courgette/courgette.gyp:courgette_minimal_tool',
        '../courgette/courgette.gyp:courgette_unittests',
        '../crypto/crypto.gyp:crypto_unittests',
        '../extensions/extensions_tests.gyp:extensions_browsertests',
        '../extensions/extensions_tests.gyp:extensions_unittests',
        '../device/device_tests.gyp:device_unittests',
        '../gin/gin.gyp:gin_v8_snapshot_fingerprint',
        '../gin/gin.gyp:gin_shell',
        '../gin/gin.gyp:gin_unittests',
        '../google_apis/gcm/gcm.gyp:gcm_unit_tests',
        '../google_apis/gcm/gcm.gyp:mcs_probe',
        '../google_apis/google_apis.gyp:google_apis_unittests',
        '../gpu/gpu.gyp:angle_unittests',
        '../gpu/gpu.gyp:gl_tests',
        '../gpu/gpu.gyp:gpu_perftests',
        '../gpu/gpu.gyp:gpu_unittests',
        '../gpu/gles2_conform_support/gles2_conform_support.gyp:gles2_conform_support',  # TODO(GYP) crbug.com/471920
        '../gpu/gles2_conform_support/gles2_conform_test.gyp:gles2_conform_test',  # TODO(GYP) crbug.com/471920
        '../gpu/khronos_glcts_support/khronos_glcts_test.gyp:khronos_glcts_test',  # TODO(GYP) crbug.com/471903 to make this complete.
        '../ipc/ipc.gyp:ipc_perftests',
        '../ipc/ipc.gyp:ipc_tests',
        '../ipc/mojo/ipc_mojo.gyp:ipc_mojo_unittests',
        '../jingle/jingle.gyp:jingle_unittests',
        '../media/media.gyp:ffmpeg_regression_tests',  # TODO(GYP) this should be conditional on media_use_ffmpeg
        '../media/media.gyp:media_perftests',
        '../media/media.gyp:media_unittests',
        '../media/midi/midi.gyp:midi_unittests',
        '../media/cast/cast.gyp:cast_benchmarks',
        '../media/cast/cast.gyp:cast_unittests',
        '../media/cast/cast.gyp:generate_barcode_video',
        '../media/cast/cast.gyp:generate_timecode_audio',
        '../mojo/mojo.gyp:mojo',
        '../mojo/mojo_base.gyp:mojo_application_base',
        '../mojo/mojo_base.gyp:mojo_common_unittests',
        '../net/net.gyp:crash_cache',
        '../net/net.gyp:crl_set_dump',
        '../net/net.gyp:dns_fuzz_stub',
        '../net/net.gyp:dump_cache',
        '../net/net.gyp:gdig',
        '../net/net.gyp:get_server_time',
        '../net/net.gyp:hpack_example_generator',
        '../net/net.gyp:hpack_fuzz_mutator',
        '../net/net.gyp:hpack_fuzz_wrapper',
        '../net/net.gyp:net_perftests',
        '../net/net.gyp:net_unittests',
        '../net/net.gyp:net_watcher',  # TODO(GYP): This should be conditional on use_v8_in_net
        '../net/net.gyp:run_testserver',
        '../net/net.gyp:stress_cache',
        '../net/net.gyp:tld_cleanup',
        '../ppapi/ppapi_internal.gyp:ppapi_example_audio',
        '../ppapi/ppapi_internal.gyp:ppapi_example_audio_input',
        '../ppapi/ppapi_internal.gyp:ppapi_example_c_stub',
        '../ppapi/ppapi_internal.gyp:ppapi_example_cc_stub',
        '../ppapi/ppapi_internal.gyp:ppapi_example_compositor',
        '../ppapi/ppapi_internal.gyp:ppapi_example_crxfs',
        '../ppapi/ppapi_internal.gyp:ppapi_example_enumerate_devices',
        '../ppapi/ppapi_internal.gyp:ppapi_example_file_chooser',
        '../ppapi/ppapi_internal.gyp:ppapi_example_flash_topmost',
        '../ppapi/ppapi_internal.gyp:ppapi_example_gamepad',
        '../ppapi/ppapi_internal.gyp:ppapi_example_gles2',
        '../ppapi/ppapi_internal.gyp:ppapi_example_gles2_spinning_cube',
        '../ppapi/ppapi_internal.gyp:ppapi_example_graphics_2d',
        '../ppapi/ppapi_internal.gyp:ppapi_example_ime',
        '../ppapi/ppapi_internal.gyp:ppapi_example_input',
        '../ppapi/ppapi_internal.gyp:ppapi_example_media_stream_audio',
        '../ppapi/ppapi_internal.gyp:ppapi_example_media_stream_video',
        '../ppapi/ppapi_internal.gyp:ppapi_example_mouse_cursor',
        '../ppapi/ppapi_internal.gyp:ppapi_example_mouse_lock',
        '../ppapi/ppapi_internal.gyp:ppapi_example_paint_manager',
        '../ppapi/ppapi_internal.gyp:ppapi_example_post_message',
        '../ppapi/ppapi_internal.gyp:ppapi_example_printing',
        '../ppapi/ppapi_internal.gyp:ppapi_example_scaling',
        '../ppapi/ppapi_internal.gyp:ppapi_example_scroll',
        '../ppapi/ppapi_internal.gyp:ppapi_example_simple_font',
        '../ppapi/ppapi_internal.gyp:ppapi_example_threading',
        '../ppapi/ppapi_internal.gyp:ppapi_example_url_loader',
        '../ppapi/ppapi_internal.gyp:ppapi_example_url_loader_file',
        '../ppapi/ppapi_internal.gyp:ppapi_example_vc',
        '../ppapi/ppapi_internal.gyp:ppapi_example_video_decode',
        '../ppapi/ppapi_internal.gyp:ppapi_example_video_decode_dev',
        '../ppapi/ppapi_internal.gyp:ppapi_example_video_effects',
        '../ppapi/ppapi_internal.gyp:ppapi_example_video_encode',
        '../ppapi/ppapi_internal.gyp:ppapi_tests',
        '../ppapi/ppapi_internal.gyp:ppapi_perftests',
        '../ppapi/ppapi_internal.gyp:ppapi_unittests',
        '../ppapi/tools/ppapi_tools.gyp:pepper_hash_for_uma',
        '../printing/printing.gyp:printing_unittests',
        '../skia/skia_tests.gyp:skia_unittests',
        '../skia/skia.gyp:filter_fuzz_stub',
        '../skia/skia.gyp:image_operations_bench',
        '../sql/sql.gyp:sql_unittests',
        '../sync/sync.gyp:run_sync_testserver',
        '../sync/sync.gyp:sync_unit_tests',
        '../sync/tools/sync_tools.gyp:sync_client',
        '../sync/tools/sync_tools.gyp:sync_listen_notifications',
        '../testing/gmock.gyp:gmock_main',
        '../third_party/WebKit/Source/platform/blink_platform_tests.gyp:blink_heap_unittests',
        '../third_party/WebKit/Source/platform/blink_platform_tests.gyp:blink_platform_unittests',
        '../third_party/WebKit/Source/web/web_tests.gyp:webkit_unit_tests',
        '../third_party/WebKit/Source/wtf/wtf_tests.gyp:wtf_unittests',
        '../third_party/cacheinvalidation/cacheinvalidation.gyp:cacheinvalidation_unittests',
        '../third_party/codesighs/codesighs.gyp:codesighs',
        '../third_party/codesighs/codesighs.gyp:maptsvdifftool',
        '../third_party/leveldatabase/leveldatabase.gyp:env_chromium_unittests',
        '../third_party/libphonenumber/libphonenumber.gyp:libphonenumber_unittests',
        '../third_party/libaddressinput/libaddressinput.gyp:libaddressinput_unittests',
        '../third_party/mojo/mojo_edk_tests.gyp:mojo_system_unittests',
        '../third_party/mojo/mojo_edk_tests.gyp:mojo_public_bindings_unittests',
        '../third_party/mojo/mojo_edk_tests.gyp:mojo_public_environment_unittests',
        '../third_party/mojo/mojo_edk_tests.gyp:mojo_public_system_perftests',
        '../third_party/mojo/mojo_edk_tests.gyp:mojo_public_system_unittests',
        '../third_party/mojo/mojo_edk_tests.gyp:mojo_public_utility_unittests',
        '../third_party/pdfium/samples/samples.gyp:pdfium_diff',
        '../third_party/pdfium/samples/samples.gyp:pdfium_test',
        '../tools/gn/gn.gyp:gn',
        '../tools/gn/gn.gyp:generate_test_gn_data',
        '../tools/gn/gn.gyp:gn_unittests',
        '../tools/imagediff/image_diff.gyp:image_diff',
        '../tools/perf/clear_system_cache/clear_system_cache.gyp:clear_system_cache',
        '../tools/telemetry/telemetry.gyp:bitmaptools#host',
        '../ui/accessibility/accessibility.gyp:accessibility_unittests',
        '../ui/app_list/app_list.gyp:app_list_unittests',
        '../ui/base/ui_base_tests.gyp:ui_base_unittests',
        '../ui/compositor/compositor.gyp:compositor_unittests',
        '../ui/display/display.gyp:display_unittests',
        '../ui/events/events.gyp:events_unittests',
        '../ui/gfx/gfx_tests.gyp:gfx_unittests',
        '../ui/gl/gl_tests.gyp:gl_unittests',
        '../ui/message_center/message_center.gyp:message_center_unittests',
        '../ui/snapshot/snapshot.gyp:snapshot_unittests',
        '../ui/touch_selection/ui_touch_selection.gyp:ui_touch_selection_unittests',
        '../ui/views/examples/examples.gyp:views_examples_with_content_exe',
        '../url/url.gyp:url_unittests',
        '../v8/tools/gyp/v8.gyp:v8_snapshot',
        '../v8/tools/gyp/v8.gyp:postmortem-metadata',
      ],
      'conditions': [
        ['clang==1', {
          'dependencies': [
            '../build/sanitizers/sanitizers.gyp:llvm-symbolizer',
          ],
        }],
        ['disable_nacl==0 and disable_nacl_untrusted==0', {
          'dependencies': [
            '../components/nacl.gyp:nacl_loader_unittests',
          ]
        }],
        ['enable_extensions==1 and OS!="mac"', {
          'dependencies': [
            '../extensions/shell/app_shell.gyp:app_shell',
            '../extensions/shell/app_shell.gyp:app_shell_unittests',
          ],
        }],
        ['enable_mdns==1', {
          'dependencies': [
            '../chrome/chrome.gyp:service_discovery_sniffer',
          ]
        }],
        ['remoting==1', {
          'dependencies': [
            '../remoting/remoting_all.gyp:remoting_all',
          ],
        }],
        ['remoting==1 and chromeos==0 and use_x11==1', {
          'dependencies': [
            '../remoting/remoting.gyp:remoting_me2me_host',
            '../remoting/remoting.gyp:remoting_me2me_native_messaging_host',
          ],
        }],
        ['toolkit_views==1', {
          'dependencies': [
            '../ui/app_list/app_list.gyp:app_list_demo',
            '../ui/views/views.gyp:views_unittests',
          ],
        }],
        ['use_ash==1', {
          'dependencies': [
            '../ash/ash.gyp:ash_shell',
            '../ash/ash.gyp:ash_shell_unittests',
            '../ash/ash.gyp:ash_unittests',
          ],
        }],
        ['use_ash==1 or chromeos== 1', {
          'dependencies': [
            '../components/components.gyp:session_manager_component',
          ]
        }],
        ['use_aura==1', {
          'dependencies': [
            '../ui/aura/aura.gyp:aura_bench',
            '../ui/aura/aura.gyp:aura_demo',
            '../ui/aura/aura.gyp:aura_unittests',
            '../ui/keyboard/keyboard.gyp:keyboard_unittests',
            '../ui/wm/wm.gyp:wm_unittests',
          ],
        }],
        ['use_ozone==1', {
          'dependencies': [
            '../ui/ozone/ozone.gyp:ozone',
          ],
        }],
        ['use_x11==1', {
          'dependencies': [
            '../tools/xdisplaycheck/xdisplaycheck.gyp:xdisplaycheck',
          ],
          'conditions': [
            ['target_arch!="arm"', {
              'dependencies': [
                '../gpu/tools/tools.gyp:compositor_model_bench',
              ],
            }],
          ],
        }],
        ['OS=="android"', {
          'dependencies': [
            '../base/base.gyp:chromium_android_linker',
            '../breakpad/breakpad.gyp:dump_syms',
            '../build/android/rezip.gyp:rezip_apk_jar',
            '../chrome/chrome.gyp:chrome_public_apk',
            '../chrome/chrome.gyp:chrome_public_test_apk',
            '../chrome/chrome.gyp:chrome_shell_apk',
            '../chrome/chrome.gyp:chromedriver_webview_shell_apk',
            #"//clank" TODO(GYP) - conditional somehow?
            '../tools/imagediff/image_diff.gyp:image_diff#host',
            '../tools/telemetry/telemetry.gyp:bitmaptools#host',

            # TODO(GYP): Remove these when the components_unittests work.
            #"//components/history/core/test:test",
            #"//components/policy:policy_component_test_support",
            #"//components/policy:test_support",
            #"//components/rappor:test_support",
            #"//components/signin/core/browser:test_support",
            #"//components/sync_driver:test_support",
            #"//components/user_manager",
            #"//components/wallpaper",

            '../content/content_shell_and_tests.gyp:content_shell_apk',

            '../third_party/WebKit/Source/platform/blink_platform_tests.gyp:blink_heap_unittests_apk',
            '../third_party/WebKit/Source/platform/blink_platform_tests.gyp:blink_platform_unittests_apk',
            '../third_party/WebKit/Source/web/web_tests.gyp:webkit_unit_tests_apk',
            '../third_party/WebKit/Source/wtf/wtf_tests.gyp:wtf_unittests_apk',
            # TODO(GYP): Are these needed, or will they be pulled in automatically?
            #"//third_party/android_tools:android_gcm_java",
            #"//third_party/android_tools:uiautomator_java",
            #"//third_party/android_tools:android_support_v13_java",
            #"//third_party/android_tools:android_support_v7_appcompat_java",
            #"//third_party/android_tools:android_support_v7_mediarouter_java",
            #"//third_party/mesa",
            #"//third_party/mockito:mockito_java",
            #"//third_party/openmax_dl/dl",
            #"//third_party/speex",
            #"//ui/android:ui_java",

            # TODO(GYP): Are these needed?
            #"//chrome/test:test_support_unit",
            #"//ui/message_center:test_support",
          ],
          'dependencies!': [
            '../breakpad/breakpad.gyp:symupload',
            '../chrome/chrome.gyp:browser_tests',
            '../chrome/chrome.gyp:chromedriver',
            '../chrome/chrome.gyp:chromedriver_unitests',
            '../chrome/chrome.gyp:interactive_ui_tests',
            '../chrome/chrome.gyp:performance_browser_tests',
            '../chrome/chrome.gyp:sync_integration_tests',
            '../chrome/chrome.gyp:unit_tests',
            '../extensions/extensions_tests.gyp:extensions_browsertests',
            '../extensions/extensions_tests.gyp:extensions_unittests',
            '../google_apis/gcm/gcm.gyp:gcm_unit_tests',
            '../ipc/ipc.gyp:ipc_tests',
            '../jingle/jingle.gyp:jingle_unittests',
            '../net/net.gyp:net_unittests',
            #"//ppapi/examples",
            '../third_party/pdfium/samples/samples.gyp:pdfium_test',
            '../tools/gn/gn.gyp:gn',
            '../tools/gn/gn.gyp:gn_unittests',
            '../tools/imagediff/image_diff.gyp:image_diff',
            '../tools/gn/gn.gyp:gn',
            '../tools/gn/gn.gyp:gn_unittests',
            '../ui/app_list/app_list.gyp:app_list_unittests',
            '../url/url.gyp:url_unittests',
          ],
        }],
        ['OS=="android" or OS=="linux"', {
          'dependencies': [
            '../net/net.gyp:disk_cache_memory_test',
          ],
        }],
        ['chromeos==1', {
          'dependencies': [
            '../chromeos/chromeos.gyp:chromeos_unittests',
            '../ui/chromeos/ui_chromeos.gyp:ui_chromeos_unittests',
          ]
        }],
        ['chromeos==1 or OS=="win" or OS=="mac"', {
          'dependencies': [
            '../rlz/rlz.gyp:rlz_id',
            '../rlz/rlz.gyp:rlz_lib',
            '../rlz/rlz.gyp:rlz_unittests',
          ],
        }],
        ['OS=="android" or OS=="linux" or os_bsd==1', {
          'dependencies': [
            '../breakpad/breakpad.gyp:core-2-minidump',
            '../breakpad/breakpad.gyp:microdump_stackwalk',
            '../breakpad/breakpad.gyp:minidump_dump',
            '../breakpad/breakpad.gyp:minidump_stackwalk',
            '../breakpad/breakpad.gyp:symupload',
            '../third_party/codesighs/codesighs.gyp:nm2tsv',
          ],
        }],
        ['OS=="linux"', {
          'dependencies': [
            '../breakpad/breakpad.gyp:breakpad_unittests',
            '../breakpad/breakpad.gyp:dump_syms#host',
            '../breakpad/breakpad.gyp:generate_test_dump',
            '../breakpad/breakpad.gyp:minidump-2-core',
            '../dbus/dbus.gyp:dbus_test_server',
            '../dbus/dbus.gyp:dbus_unittests',
            '../media/cast/cast.gyp:tap_proxy',
            '../net/net.gyp:disk_cache_memory_test',
            '../net/net.gyp:flip_in_mem_edsm_server',
            '../net/net.gyp:flip_in_mem_edsm_server_unittests',
            '../net/net.gyp:epoll_quic_client',
            '../net/net.gyp:epoll_quic_server',
            '../net/net.gyp:hpack_example_generator',
            '../net/net.gyp:hpack_fuzz_mutator',
            '../net/net.gyp:hpack_fuzz_wrapper',
            '../net/net.gyp:net_perftests',
            '../net/net.gyp:quic_client',
            '../net/net.gyp:quic_server',
            '../sandbox/sandbox.gyp:chrome_sandbox',
            '../sandbox/sandbox.gyp:sandbox_linux_unittests',
            '../sandbox/sandbox.gyp:sandbox_linux_jni_unittests',
            '../third_party/sqlite/sqlite.gyp:sqlite_shell',
         ],
        }],
        ['OS=="mac"', {
          'dependencies': [
            '../breakpad/breakpad.gyp:crash_inspector',
            '../breakpad/breakpad.gyp:dump_syms',
            '../breakpad/breakpad.gyp:symupload',
            '../third_party/apple_sample_code/apple_sample_code.gyp:apple_sample_code',
            '../third_party/molokocacao/molokocacao.gyp:molokocacao',

            # TODO(GYP): remove these when the corresponding root targets work.
            #"//cc/blink",
            #"//components/ui/zoom:ui_zoom",
            #"//content",
            #"//content/test:test_support",
            #"//device/battery",
            #"//device/bluetooth",
            #"//device/nfc",
            #"//device/usb",
            #"//device/vibration",
            #"//media/blink",
            #"//pdf",
            #"//storage/browser",
            #"//third_party/brotli",
            #"//third_party/flac",
            #"//third_party/hunspell",
            #//third_party/iccjpeg",
            #"//third_party/libphonenumber",
            #"//third_party/ots",
            #"//third_party/qcms",
            #"//third_party/speex",
            #"//third_party/webrtc/system_wrappers",
            #"//ui/native_theme",
            #"//ui/snapshot",
            #"//ui/surface",
          ],
          'dependencies!': [
            #"//chrome",  # TODO(GYP)
            #"//chrome/test:browser_tests",  # TODO(GYP)
            #"//chrome/test:interactive_ui_tests",  # TODO(GYP)
            #"//chrome/test:sync_integration_tests",  # TODO(GYP)
            #"//chrome/test:unit_tests",  # TODO(GYP)
            #"//components:components_unittests",  # TODO(GYP)
            #"//content/test:content_browsertests",  # TODO(GYP)
            #"//content/test:content_perftests",  # TODO(GYP)
            #"//content/test:content_unittests",  # TODO(GYP)
            #"//extensions:extensions_browsertests",  # TODO(GYP)
            #"//extensions:extensions_unittests",  # TODO(GYP)
            #"//net:net_unittests",  # TODO(GYP)
            #"//third_party/usrsctp",  # TODO(GYP)
            #"//ui/app_list:app_list_unittests",  # TODO(GYP)
            #"//ui/gfx:gfx_unittests",  # TODO(GYP)
          ],
        }],
        ['OS=="win"', {
          'dependencies': [
            '../base/base.gyp:pe_image_test',
            '../chrome/chrome.gyp:crash_service',
            '../chrome/chrome.gyp:setup_unittests',
            '../chrome_elf/chrome_elf.gyp:chrome_elf_unittests',
            '../chrome_elf/chrome_elf.gyp:dll_hash_main',
            '../components/components.gyp:wifi_test',
            '../net/net.gyp:quic_client',
            '../net/net.gyp:quic_server',
            '../sandbox/sandbox.gyp:pocdll',
            '../sandbox/sandbox.gyp:sandbox_poc',
            '../sandbox/sandbox.gyp:sbox_integration_tests',
            '../sandbox/sandbox.gyp:sbox_unittests',
            '../sandbox/sandbox.gyp:sbox_validation_tests',
            '../testing/gtest.gyp:gtest_main',
            '../third_party/codesighs/codesighs.gyp:msdump2symdb',
            '../third_party/codesighs/codesighs.gyp:msmap2tsv',
            '../third_party/pdfium/samples/samples.gyp:pdfium_diff',
            '../win8/win8.gyp:metro_viewer',
          ],
        }],
      ],
    },
    {
      'target_name': 'gyp_only',
      'type': 'none',
      'conditions': [
        ['OS=="linux" or OS=="win"', {
          'conditions': [
            ['disable_nacl==0 and disable_nacl_untrusted==0', {
              'dependencies': [
                '../mojo/mojo_nacl.gyp:monacl_shell',  # This should not be built in chromium.
              ]
            }],
          ]
        }],
      ],
    },
    {
      'target_name': 'gyp_remaining',
      'type': 'none',
      'conditions': [
        ['remoting==1', {
          'dependencies': [
            '../remoting/app_remoting_webapp.gyp:ar_sample_app',  # crbug.com/471916
          ],
        }],
        ['test_isolation_mode!="noop"', {
          'dependencies': [
            '../base/base.gyp:base_unittests_run',
            '../cc/cc_tests.gyp:cc_unittests_run',
            '../chrome/chrome.gyp:browser_tests_run',
            '../chrome/chrome.gyp:chrome_run',
            '../chrome/chrome.gyp:interactive_ui_tests_run',
            '../chrome/chrome.gyp:sync_integration_tests_run',
            '../chrome/chrome.gyp:unit_tests_run',
            '../components/components_tests.gyp:components_browsertests_run',
            '../components/components_tests.gyp:components_unittests_run',
            '../content/content_shell_and_tests.gyp:content_browsertests_run',
            '../content/content_shell_and_tests.gyp:content_unittests_run',
            '../courgette/courgette.gyp:courgette_unittests_run',
            '../crypto/crypto.gyp:crypto_unittests_run',
            '../google_apis/gcm/gcm.gyp:gcm_unit_tests_run',
            '../gpu/gpu.gyp:gpu_unittests_run',
            '../ipc/ipc.gyp:ipc_tests_run',
            '../media/cast/cast.gyp:cast_unittests_run',
            '../media/media.gyp:media_unittests_run',
            '../media/midi/midi.gyp:midi_unittests_run',
            '../net/net.gyp:net_unittests_run',
            '../printing/printing.gyp:printing_unittests_run',
            '../remoting/remoting.gyp:remoting_unittests_run',
            '../skia/skia_tests.gyp:skia_unittests_run',
            '../sql/sql.gyp:sql_unittests_run',
            '../sync/sync.gyp:sync_unit_tests_run',
            '../third_party/cacheinvalidation/cacheinvalidation.gyp:cacheinvalidation_unittests_run',
            '../third_party/mojo/mojo_edk_tests.gyp:mojo_public_bindings_unittests_run',
            '../tools/gn/gn.gyp:gn_unittests_run',
            '../ui/accessibility/accessibility.gyp:accessibility_unittests_run',
            '../ui/app_list/app_list.gyp:app_list_unittests_run',
            '../ui/compositor/compositor.gyp:compositor_unittests_run',
            '../ui/events/events.gyp:events_unittests_run',
            '../ui/gl/gl_tests.gyp:gl_unittests_run',
            '../ui/message_center/message_center.gyp:message_center_unittests_run',
            '../ui/touch_selection/ui_touch_selection.gyp:ui_touch_selection_unittests_run',
            '../url/url.gyp:url_unittests_run',
          ],
          'conditions': [
            ['OS=="linux"', {
              'dependencies': [
                '../sandbox/sandbox.gyp:sandbox_linux_unittests_run',
                '../ui/display/display.gyp:display_unittests_run',
              ],
            }],
            ['OS=="mac"', {
              'dependencies': [
                '../sandbox/sandbox.gyp:sandbox_mac_unittests_run',
              ],
            }],
            ['OS=="win"', {
              'dependencies': [
                '../chrome/chrome.gyp:installer_util_unittests_run',
                '../chrome/chrome.gyp:setup_unittests_run',
                '../sandbox/sandbox.gyp:sbox_integration_tests',
                '../sandbox/sandbox.gyp:sbox_unittests',
                '../sandbox/sandbox.gyp:sbox_validation_tests',
              ],
            }],
            ['use_ash==1', {
              'dependencies': [
                '../ash/ash.gyp:ash_unittests_run',
              ],
            }],
            ['use_aura==1', {
              'dependencies': [
                '../ui/aura/aura.gyp:aura_unittests_run',
                '../ui/wm/wm.gyp:wm_unittests_run',
              ],
            }],
            ['enable_webrtc==1 or OS!="android"', {
              'dependencies': [
                '../jingle/jingle.gyp:jingle_unittests_run',
              ],
            }],
            ['disable_nacl==0 and disable_nacl_untrusted==0', {
              'dependencies': [
                '../components/nacl.gyp:nacl_loader_unittests_run',
              ]
            }],
          ],
        }],
        ['use_openssl==1', {
          'dependencies': [
            # TODO(GYP): All of these targets still need to be converted.
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_ecdsa_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_bn_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_pqueue_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_digest_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_cipher_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_hkdf_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_constant_time_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_thread_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_base64_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_gcm_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_bytestring_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_evp_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_dsa_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_rsa_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_hmac_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_aead_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_ssl_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_err_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_lhash_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_pbkdf_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_dh_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_pkcs12_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_example_mul',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_ec_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_bio_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_pkcs7_test',
            '../third_party/boringssl/boringssl_tests.gyp:boringssl_unittests',
          ],
        }],
        ['chromeos==1', {
          'dependencies': [
            '../content/content_shell_and_tests.gyp:jpeg_decode_accelerator_unittest',
            '../content/content_shell_and_tests.gyp:video_encode_accelerator_unittest',
          ],
        }],
        ['chromeos==1 and target_arch != "arm"', {
          'dependencies': [
            '../content/content_shell_and_tests.gyp:vaapi_jpeg_decoder_unittest',
          ],
        }],
        ['chromeos==1 or OS=="win" or OS=="android"', {
          'dependencies': [
            '../content/content_shell_and_tests.gyp:video_decode_accelerator_unittest',
          ],
        }],
        ['OS=="linux" or OS=="win"', {
          'dependencies': [
            # TODO(GYP): Figure out which of these run on android/mac/win/ios/etc.
            '../net/net.gyp:net_docs',
            '../remoting/remoting.gyp:ar_sample_test_driver',

            # TODO(GYP): in progress - see tfarina.
            '../third_party/webrtc/tools/tools.gyp:frame_analyzer',
            '../third_party/webrtc/tools/tools.gyp:rgba_to_i420_converter',
          ],
        }],
        ['OS=="win"', {
          'dependencies': [
            # TODO(GYP): All of these targets still need to be converted.
            '../base/base.gyp:debug_message',
            '../chrome/chrome.gyp:app_shim',
            '../chrome/chrome.gyp:gcapi_dll',
            '../chrome/chrome.gyp:gcapi_test',
            '../chrome/chrome.gyp:installer_util_unittests',
            '../chrome/chrome.gyp:pack_policy_templates',
            '../chrome/chrome.gyp:sb_sigutil',
            '../chrome/chrome.gyp:setup',
            '../chrome/installer/mini_installer.gyp:mini_installer',
            '../chrome/tools/crash_service/caps/caps.gyp:caps',
            '../cloud_print/gcp20/prototype/gcp20_device.gyp:gcp20_device',
            '../cloud_print/gcp20/prototype/gcp20_device.gyp:gcp20_device_unittests',
            '../cloud_print/service/win/service.gyp:cloud_print_service',
            '../cloud_print/service/win/service.gyp:cloud_print_service_config',
            '../cloud_print/service/win/service.gyp:cloud_print_service_setup',
            '../cloud_print/virtual_driver/win/install/virtual_driver_install.gyp:virtual_driver_setup',
            '../cloud_print/virtual_driver/win/virtual_driver.gyp:gcp_portmon',
            '../components/test_runner/test_runner.gyp:layout_test_helper',
            '../content/content_shell_and_tests.gyp:content_shell_crash_service',
            '../gpu/gpu.gyp:angle_end2end_tests',
            '../gpu/gpu.gyp:angle_perftests',
            '../net/net.gyp:net_docs',
            '../ppapi/ppapi_internal.gyp:ppapi_perftests',
            '../remoting/remoting.gyp:ar_sample_test_driver',
            '../remoting/remoting.gyp:remoting_breakpad_tester',
            '../remoting/remoting.gyp:remoting_console',
            '../remoting/remoting.gyp:remoting_desktop',
            '../rlz/rlz.gyp:rlz',
            '../tools/win/static_initializers/static_initializers.gyp:static_initializers',
          ],
        }],
        ['OS=="win" and win_use_allocator_shim==1', {
          'dependencies': [
            '../base/allocator/allocator.gyp:allocator_unittests',
          ]
        }],
        ['OS=="win" and target_arch=="ia32"', {
          'dependencies': [
            # TODO(GYP): All of these targets need to be ported over.
            '../base/base.gyp:base_win64',
            '../base/base.gyp:base_i18n_nacl_win64',
            '../chrome/chrome.gyp:crash_service_win64',
            '../chrome/chrome.gyp:launcher_support64',
            '../components/components.gyp:breakpad_win64',
            '../courgette/courgette.gyp:courgette64',
            '../crypto/crypto.gyp:crypto_nacl_win64',
            '../ipc/ipc.gyp:ipc_win64',
            '../sandbox/sandbox.gyp:sandbox_win64',
            '../cloud_print/virtual_driver/win/virtual_driver64.gyp:gcp_portmon64',
            '../cloud_print/virtual_driver/win/virtual_driver64.gyp:virtual_driver_lib64',
          ],
        }],
        ['OS=="win" and target_arch=="ia32" and configuration_policy==1', {
          'dependencies': [
            # TODO(GYP): All of these targets need to be ported over.
            '../components/components.gyp:policy_win64',
          ]
        }],
      ],
    },
  ]
}

