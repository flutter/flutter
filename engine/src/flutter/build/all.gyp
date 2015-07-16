# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    # A hook that can be overridden in other repositories to add additional
    # compilation targets to 'All'.
    'app_targets%': [],
    # For Android-specific targets.
    'android_app_targets%': [],
  },
  'targets': [
    {
      'target_name': 'All',
      'type': 'none',
      'xcode_create_dependents_test_runner': 1,
      'dependencies': [
        '<@(app_targets)',
        'some.gyp:*',
        '../base/base.gyp:*',
        '../components/components.gyp:*',
        '../components/components_tests.gyp:*',
        '../content/content.gyp:*',
        '../crypto/crypto.gyp:*',
        '../net/net.gyp:*',
        '../sdch/sdch.gyp:*',
        '../sql/sql.gyp:*',
        '../testing/gmock.gyp:*',
        '../testing/gtest.gyp:*',
        '../third_party/icu/icu.gyp:*',
        '../third_party/libxml/libxml.gyp:*',
        '../third_party/sqlite/sqlite.gyp:*',
        '../third_party/zlib/zlib.gyp:*',
        '../ui/accessibility/accessibility.gyp:*',
        '../ui/base/ui_base.gyp:*',
        '../ui/display/display.gyp:display_unittests',
        '../ui/snapshot/snapshot.gyp:*',
        '../url/url.gyp:*',
      ],
      'conditions': [
        ['OS!="ios" and OS!="mac"', {
          'dependencies': [
            '../ui/touch_selection/ui_touch_selection.gyp:*',
          ],
        }],
        ['OS=="ios"', {
          'dependencies': [
            '../chrome/chrome.gyp:browser',
            '../chrome/chrome.gyp:browser_ui',
            '../ios/ios.gyp:*',
            # NOTE: This list of targets is present because
            # mojo_base.gyp:mojo_base cannot be built on iOS, as
            # javascript-related targets cause v8 to be built.
            '../mojo/mojo_base.gyp:mojo_common_lib',
            '../mojo/mojo_base.gyp:mojo_common_unittests',
            '../google_apis/google_apis.gyp:google_apis_unittests',
            '../skia/skia_tests.gyp:skia_unittests',
            '../third_party/mojo/mojo_edk.gyp:mojo_system_impl',
            '../third_party/mojo/mojo_edk_tests.gyp:mojo_public_bindings_unittests',
            '../third_party/mojo/mojo_edk_tests.gyp:mojo_public_environment_unittests',
            '../third_party/mojo/mojo_edk_tests.gyp:mojo_public_system_unittests',
            '../third_party/mojo/mojo_edk_tests.gyp:mojo_public_utility_unittests',
            '../third_party/mojo/mojo_edk_tests.gyp:mojo_system_unittests',
            '../third_party/mojo/mojo_public.gyp:mojo_cpp_bindings',
            '../third_party/mojo/mojo_public.gyp:mojo_public_test_utils',
            '../third_party/mojo/mojo_public.gyp:mojo_system',
            '../ui/base/ui_base_tests.gyp:ui_base_unittests',
            '../ui/gfx/gfx_tests.gyp:gfx_unittests',
          ],
        }],
        ['OS=="android"', {
          'dependencies': [
            '../content/content_shell_and_tests.gyp:content_shell_apk',
            '<@(android_app_targets)',
            'android_builder_tests',
            '../tools/telemetry/telemetry.gyp:*#host',
            # TODO(nyquist) This should instead by a target for sync when all of
            # the sync-related code for Android has been upstreamed.
            # See http://crbug.com/159203
            '../third_party/cacheinvalidation/cacheinvalidation.gyp:cacheinvalidation_javalib',
          ],
          'conditions': [
            ['chromecast==0', {
              'dependencies': [
                '../android_webview/android_webview.gyp:android_webview_apk',
                '../android_webview/android_webview.gyp:system_webview_apk',
                '../android_webview/android_webview_shell.gyp:android_webview_shell_apk',
                '../android_webview/android_webview_telemetry_shell.gyp:android_webview_telemetry_shell_apk',
                '../chrome/android/chrome_apk.gyp:chrome_public_apk',
                '../chrome/chrome.gyp:chrome_shell_apk',
                '../chrome/chrome.gyp:chrome_sync_shell_apk',
                '../remoting/remoting.gyp:remoting_apk',
              ],
            }],
            ['target_arch == "arm" or target_arch == "arm64"', {
              'dependencies': [
                # The relocation packer is currently used only for ARM or ARM64.
                '../third_party/android_platform/relocation_packer.gyp:android_relocation_packer_unittests#host',
              ],
            }],
          ],
        }, {
          'dependencies': [
            '../content/content_shell_and_tests.gyp:*',
            # TODO: This should build on Android and the target should move to the list above.
            '../sync/sync.gyp:*',
          ],
        }],
        ['OS!="ios" and OS!="android" and chromecast==0', {
          'dependencies': [
            '../third_party/re2/re2.gyp:re2',
            '../chrome/chrome.gyp:*',
            '../chrome/tools/profile_reset/jtl_compiler.gyp:*',
            '../cc/blink/cc_blink_tests.gyp:*',
            '../cc/cc_tests.gyp:*',
            '../device/usb/usb.gyp:*',
            '../extensions/extensions.gyp:*',
            '../extensions/extensions_tests.gyp:*',
            '../gin/gin.gyp:*',
            '../gpu/gpu.gyp:*',
            '../gpu/tools/tools.gyp:*',
            '../ipc/ipc.gyp:*',
            '../ipc/mojo/ipc_mojo.gyp:*',
            '../jingle/jingle.gyp:*',
            '../media/cast/cast.gyp:*',
            '../media/media.gyp:*',
            '../media/midi/midi.gyp:*',
            '../mojo/mojo.gyp:*',
            '../mojo/mojo_base.gyp:*',
            '../ppapi/ppapi.gyp:*',
            '../ppapi/ppapi_internal.gyp:*',
            '../ppapi/tools/ppapi_tools.gyp:*',
            '../printing/printing.gyp:*',
            '../skia/skia.gyp:*',
            '../sync/tools/sync_tools.gyp:*',
            '../third_party/WebKit/public/all.gyp:*',
            '../third_party/cacheinvalidation/cacheinvalidation.gyp:*',
            '../third_party/codesighs/codesighs.gyp:*',
            '../third_party/ffmpeg/ffmpeg.gyp:*',
            '../third_party/iccjpeg/iccjpeg.gyp:*',
            '../third_party/libpng/libpng.gyp:*',
            '../third_party/libusb/libusb.gyp:*',
            '../third_party/libwebp/libwebp.gyp:*',
            '../third_party/libxslt/libxslt.gyp:*',
            '../third_party/lzma_sdk/lzma_sdk.gyp:*',
            '../third_party/mesa/mesa.gyp:*',
            '../third_party/modp_b64/modp_b64.gyp:*',
            '../third_party/npapi/npapi.gyp:*',
            '../third_party/ots/ots.gyp:*',
            '../third_party/pdfium/samples/samples.gyp:*',
            '../third_party/qcms/qcms.gyp:*',
            '../tools/gn/gn.gyp:*',
            '../tools/perf/clear_system_cache/clear_system_cache.gyp:*',
            '../tools/telemetry/telemetry.gyp:*',
            '../v8/tools/gyp/v8.gyp:*',
            '<(libjpeg_gyp_path):*',
          ],
        }],
        ['OS!="ios"', {
          'dependencies': [
            '../device/bluetooth/bluetooth.gyp:*',
            '../device/device_tests.gyp:*',
          ],
        }],
        ['use_openssl==0 and (OS=="mac" or OS=="ios" or OS=="win")', {
          'dependencies': [
            '../third_party/nss/nss.gyp:*',
           ],
        }],
        ['OS=="win" or OS=="ios" or OS=="linux"', {
          'dependencies': [
            '../breakpad/breakpad.gyp:*',
           ],
        }],
        ['OS=="mac"', {
          'dependencies': [
            '../sandbox/sandbox.gyp:*',
            '../third_party/crashpad/crashpad/crashpad.gyp:*',
            '../third_party/ocmock/ocmock.gyp:*',
          ],
        }],
        ['OS=="linux"', {
          'dependencies': [
            '../courgette/courgette.gyp:*',
            '../sandbox/sandbox.gyp:*',
          ],
          'conditions': [
            ['branding=="Chrome"', {
              'dependencies': [
                '../chrome/chrome.gyp:linux_packages_<(channel)',
              ],
            }],
            ['enable_ipc_fuzzer==1', {
              'dependencies': [
                '../tools/ipc_fuzzer/ipc_fuzzer.gyp:*',
              ],
            }],
            ['use_dbus==1', {
              'dependencies': [
                '../dbus/dbus.gyp:*',
              ],
            }],
          ],
        }],
        ['chromecast==1', {
          'dependencies': [
            '../chromecast/chromecast.gyp:*',
          ],
        }],
        ['use_x11==1', {
          'dependencies': [
            '../tools/xdisplaycheck/xdisplaycheck.gyp:*',
          ],
        }],
        ['OS=="win"', {
          'conditions': [
            ['win_use_allocator_shim==1', {
              'dependencies': [
                '../base/allocator/allocator.gyp:*',
              ],
            }],
          ],
          'dependencies': [
            '../chrome/tools/crash_service/caps/caps.gyp:*',
            '../chrome_elf/chrome_elf.gyp:*',
            '../cloud_print/cloud_print.gyp:*',
            '../courgette/courgette.gyp:*',
            '../rlz/rlz.gyp:*',
            '../sandbox/sandbox.gyp:*',
            '<(angle_path)/src/angle.gyp:*',
            '../third_party/bspatch/bspatch.gyp:*',
            '../tools/win/static_initializers/static_initializers.gyp:*',
          ],
        }, {
          'dependencies': [
            '../third_party/libevent/libevent.gyp:*',
          ],
        }],
        ['toolkit_views==1', {
          'dependencies': [
            '../ui/views/controls/webview/webview.gyp:*',
            '../ui/views/views.gyp:*',
          ],
        }],
        ['use_aura==1', {
          'dependencies': [
            '../ui/aura/aura.gyp:*',
            '../ui/aura_extra/aura_extra.gyp:*',
          ],
        }],
        ['use_ash==1', {
          'dependencies': [
            '../ash/ash.gyp:*',
          ],
        }],
        ['remoting==1', {
          'dependencies': [
            '../remoting/remoting_all.gyp:remoting_all',
          ],
        }],
        ['use_openssl==0', {
          'dependencies': [
            '../net/third_party/nss/ssl.gyp:*',
          ],
        }],
        ['use_openssl==1', {
          'dependencies': [
            '../third_party/boringssl/boringssl.gyp:*',
            '../third_party/boringssl/boringssl_tests.gyp:*',
          ],
        }],
        ['enable_app_list==1', {
          'dependencies': [
            '../ui/app_list/app_list.gyp:*',
          ],
        }],
        ['OS!="android" and OS!="ios"', {
          'dependencies': [
            '../google_apis/gcm/gcm.gyp:*',
          ],
        }],
        ['(chromeos==1 or OS=="linux" or OS=="win" or OS=="mac") and chromecast==0', {
          'dependencies': [
            '../extensions/shell/app_shell.gyp:*',
          ],
        }],
        ['envoy==1', {
          'dependencies': [
            '../envoy/envoy.gyp:*',
          ],
        }],
      ],
    }, # target_name: All
    {
      'target_name': 'All_syzygy',
      'type': 'none',
      'conditions': [
        ['OS=="win" and fastbuild==0 and target_arch=="ia32" and '
            '(syzyasan==1 or syzygy_optimize==1)', {
          'dependencies': [
            '../chrome/installer/mini_installer_syzygy.gyp:*',
          ],
        }],
      ],
    }, # target_name: All_syzygy
    {
      # Note: Android uses android_builder_tests below.
      # TODO: Consider merging that with this target.
      'target_name': 'chromium_builder_tests',
      'type': 'none',
      'dependencies': [
        '../base/base.gyp:base_unittests',
        '../components/components_tests.gyp:components_unittests',
        '../crypto/crypto.gyp:crypto_unittests',
        '../net/net.gyp:net_unittests',
        '../skia/skia_tests.gyp:skia_unittests',
        '../sql/sql.gyp:sql_unittests',
        '../sync/sync.gyp:sync_unit_tests',
        '../ui/base/ui_base_tests.gyp:ui_base_unittests',
        '../ui/display/display.gyp:display_unittests',
        '../ui/gfx/gfx_tests.gyp:gfx_unittests',
        '../url/url.gyp:url_unittests',
      ],
      'conditions': [
        ['OS!="ios"', {
          'dependencies': [
            '../ui/gl/gl_tests.gyp:gl_unittests',
          ],
        }],
        ['OS!="ios" and OS!="mac"', {
          'dependencies': [
            '../ui/touch_selection/ui_touch_selection.gyp:ui_touch_selection_unittests',
          ],
        }],
        ['OS!="ios" and OS!="android"', {
          'dependencies': [
            '../cc/blink/cc_blink_tests.gyp:cc_blink_unittests',
            '../cc/cc_tests.gyp:cc_unittests',
            '../cloud_print/cloud_print.gyp:cloud_print_unittests',
            '../content/content_shell_and_tests.gyp:content_browsertests',
            '../content/content_shell_and_tests.gyp:content_shell',
            '../content/content_shell_and_tests.gyp:content_unittests',
            '../device/device_tests.gyp:device_unittests',
            '../gin/gin.gyp:gin_unittests',
            '../google_apis/google_apis.gyp:google_apis_unittests',
            '../gpu/gles2_conform_support/gles2_conform_support.gyp:gles2_conform_support',
            '../gpu/gpu.gyp:gpu_unittests',
            '../ipc/ipc.gyp:ipc_tests',
            '../ipc/mojo/ipc_mojo.gyp:ipc_mojo_unittests',
            '../jingle/jingle.gyp:jingle_unittests',
            '../media/cast/cast.gyp:cast_unittests',
            '../media/media.gyp:media_unittests',
            '../media/midi/midi.gyp:midi_unittests',
            '../mojo/mojo.gyp:mojo',
            '../ppapi/ppapi_internal.gyp:ppapi_unittests',
            '../remoting/remoting.gyp:remoting_unittests',
            '../third_party/WebKit/public/all.gyp:all_blink',
            '../third_party/cacheinvalidation/cacheinvalidation.gyp:cacheinvalidation_unittests',
            '../third_party/leveldatabase/leveldatabase.gyp:env_chromium_unittests',
            '../third_party/libaddressinput/libaddressinput.gyp:libaddressinput_unittests',
            '../third_party/libphonenumber/libphonenumber.gyp:libphonenumber_unittests',
            '../tools/telemetry/telemetry.gyp:*',
          ],
        }],
        ['OS!="ios" and OS!="android" and chromecast==0', {
          'dependencies': [
            '../chrome/chrome.gyp:browser_tests',
            '../chrome/chrome.gyp:chromedriver_tests',
            '../chrome/chrome.gyp:chromedriver_unittests',
            '../chrome/chrome.gyp:interactive_ui_tests',
            '../chrome/chrome.gyp:sync_integration_tests',
            '../chrome/chrome.gyp:unit_tests',
            '../extensions/extensions_tests.gyp:extensions_browsertests',
            '../extensions/extensions_tests.gyp:extensions_unittests',
          ],
        }],
        ['OS=="win"', {
          'dependencies': [
            '../chrome/chrome.gyp:crash_service',
            '../chrome/chrome.gyp:installer_util_unittests',
            # ../chrome/test/mini_installer requires mini_installer.
            '../chrome/installer/mini_installer.gyp:mini_installer',
            '../chrome_elf/chrome_elf.gyp:chrome_elf_unittests',
            '../content/content_shell_and_tests.gyp:copy_test_netscape_plugin',
            '../courgette/courgette.gyp:courgette_unittests',
            '../sandbox/sandbox.gyp:sbox_integration_tests',
            '../sandbox/sandbox.gyp:sbox_unittests',
            '../sandbox/sandbox.gyp:sbox_validation_tests',
            '../ui/app_list/app_list.gyp:app_list_unittests',
          ],
          'conditions': [
            # remoting_host_installation uses lots of non-trivial GYP that tend
            # to break because of differences between ninja and msbuild. Make
            # sure this target is built by the builders on the main waterfall.
            # See http://crbug.com/180600.
            ['wix_exists == "True" and sas_dll_exists == "True"', {
              'dependencies': [
                '../remoting/remoting.gyp:remoting_host_installation',
              ],
            }],
            ['syzyasan==1', {
              'variables': {
                # Disable incremental linking for all modules.
                # 0: inherit, 1: disabled, 2: enabled.
                'msvs_debug_link_incremental': '1',
                'msvs_large_module_debug_link_mode': '1',
                # Disable RTC. Syzygy explicitly doesn't support RTC
                # instrumented binaries for now.
                'win_debug_RuntimeChecks': '0',
              },
              'defines': [
                # Disable iterator debugging (huge speed boost).
                '_HAS_ITERATOR_DEBUGGING=0',
              ],
              'msvs_settings': {
                'VCLinkerTool': {
                  # Enable profile information (necessary for SyzyAsan
                  # instrumentation). This is incompatible with incremental
                  # linking.
                  'Profile': 'true',
                },
              }
            }],
          ],
        }],
        ['chromeos==1', {
          'dependencies': [
            '../ui/chromeos/ui_chromeos.gyp:ui_chromeos_unittests',
          ],
        }],
        ['OS=="linux"', {
          'dependencies': [
            '../sandbox/sandbox.gyp:sandbox_linux_unittests',
          ],
        }],
        ['OS=="linux" and use_dbus==1', {
          'dependencies': [
            '../dbus/dbus.gyp:dbus_unittests',
          ],
        }],
        ['OS=="mac"', {
          'dependencies': [
            '../ui/app_list/app_list.gyp:app_list_unittests',
            '../ui/message_center/message_center.gyp:*',
          ],
        }],
        ['test_isolation_mode != "noop"', {
          'dependencies': [
            'chromium_swarm_tests',
          ],
        }],
        ['OS!="android"', {
          'dependencies': [
            '../google_apis/gcm/gcm.gyp:gcm_unit_tests',
          ],
        }],
        ['enable_basic_printing==1 or enable_print_preview==1', {
          'dependencies': [
            '../printing/printing.gyp:printing_unittests',
          ],
        }],
        ['use_aura==1', {
          'dependencies': [
            '../ui/app_list/app_list.gyp:app_list_unittests',
            '../ui/aura/aura.gyp:aura_unittests',
            '../ui/compositor/compositor.gyp:compositor_unittests',
          ],
        }],
        ['use_aura==1 and chromecast==0', {
          'dependencies': [
            '../ui/keyboard/keyboard.gyp:keyboard_unittests',
            '../ui/views/views.gyp:views_unittests',
          ],
        }],
        ['use_aura==1 or toolkit_views==1', {
          'dependencies': [
            '../ui/events/events.gyp:events_unittests',
          ],
        }],
        ['use_ash==1', {
          'dependencies': [
            '../ash/ash.gyp:ash_unittests',
          ],
        }],
        ['disable_nacl==0', {
          'dependencies': [
            '../components/nacl.gyp:nacl_loader_unittests',
          ],
        }],
        ['disable_nacl==0 and disable_nacl_untrusted==0 and enable_nacl_nonsfi_test==1', {
          'dependencies': [
            '../components/nacl.gyp:nacl_helper_nonsfi_unittests',
          ],
        }],
        ['disable_nacl==0 and disable_nacl_untrusted==0', {
          'dependencies': [
            '../mojo/mojo_nacl_untrusted.gyp:libmojo',
            '../mojo/mojo_nacl.gyp:monacl_codegen',
            '../mojo/mojo_nacl.gyp:monacl_sel',
            '../mojo/mojo_nacl.gyp:monacl_shell',
          ],
        }],
      ],
    }, # target_name: chromium_builder_tests
  ],
  'conditions': [
    # TODO(GYP): make gn_migration.gypi work unconditionally.
    ['OS=="mac" or OS=="win" or (OS=="linux" and target_arch=="x64" and chromecast==0)', {
      'includes': [
        'gn_migration.gypi',
      ],
    }],
    ['OS!="ios"', {
      'targets': [
        {
          'target_name': 'blink_tests',
          'type': 'none',
          'dependencies': [
            '../third_party/WebKit/public/all.gyp:all_blink',
          ],
          'conditions': [
            ['OS=="android"', {
              'dependencies': [
                '../content/content_shell_and_tests.gyp:content_shell_apk',
                '../breakpad/breakpad.gyp:dump_syms#host',
                '../breakpad/breakpad.gyp:minidump_stackwalk#host',
              ],
            }, {  # OS!="android"
              'dependencies': [
                '../content/content_shell_and_tests.gyp:content_shell',
              ],
            }],
            ['OS=="win"', {
              'dependencies': [
                '../components/test_runner/test_runner.gyp:layout_test_helper',
                '../content/content_shell_and_tests.gyp:content_shell_crash_service',
              ],
            }],
            ['OS!="win" and OS!="android"', {
              'dependencies': [
                '../breakpad/breakpad.gyp:minidump_stackwalk',
              ],
            }],
            ['OS=="mac"', {
              'dependencies': [
                '../components/test_runner/test_runner.gyp:layout_test_helper',
                '../breakpad/breakpad.gyp:dump_syms#host',
              ],
            }],
            ['OS=="linux"', {
              'dependencies': [
                '../breakpad/breakpad.gyp:dump_syms#host',
              ],
            }],
          ],
        }, # target_name: blink_tests
      ],
    }], # OS!=ios
    ['OS!="ios" and OS!="android" and chromecast==0', {
      'targets': [
        {
          'target_name': 'chromium_builder_nacl_win_integration',
          'type': 'none',
          'dependencies': [
            'chromium_builder_tests',
          ],
        }, # target_name: chromium_builder_nacl_win_integration
        {
          'target_name': 'chromium_builder_perf',
          'type': 'none',
          'dependencies': [
            '../cc/cc_tests.gyp:cc_perftests',
            '../chrome/chrome.gyp:chrome',
            '../chrome/chrome.gyp:load_library_perf_tests',
            '../chrome/chrome.gyp:performance_browser_tests',
            '../chrome/chrome.gyp:sync_performance_tests',
            '../content/content_shell_and_tests.gyp:content_shell',
            '../gpu/gpu.gyp:gpu_perftests',
            '../media/media.gyp:media_perftests',
            '../media/midi/midi.gyp:midi_unittests',
            '../tools/perf/clear_system_cache/clear_system_cache.gyp:*',
            '../tools/telemetry/telemetry.gyp:*',
          ],
          'conditions': [
            ['OS!="ios" and OS!="win"', {
              'dependencies': [
                '../breakpad/breakpad.gyp:minidump_stackwalk',
              ],
            }],
            ['OS=="linux"', {
              'dependencies': [
                '../chrome/chrome.gyp:linux_symbols'
              ],
            }],
            ['OS=="win"', {
              'dependencies': [
                '../chrome/chrome.gyp:crash_service',
                '../gpu/gpu.gyp:angle_perftests',
              ],
            }],
            ['OS=="win" and target_arch=="ia32"', {
              'dependencies': [
                '../chrome/chrome.gyp:crash_service_win64',
              ],
            }],
          ],
        }, # target_name: chromium_builder_perf
        {
          'target_name': 'chromium_gpu_builder',
          'type': 'none',
          'dependencies': [
            '../chrome/chrome.gyp:chrome',
            '../chrome/chrome.gyp:performance_browser_tests',
            '../content/content_shell_and_tests.gyp:content_browsertests',
            '../content/content_shell_and_tests.gyp:content_gl_tests',
            '../gpu/gles2_conform_support/gles2_conform_test.gyp:gles2_conform_test',
            '../gpu/khronos_glcts_support/khronos_glcts_test.gyp:khronos_glcts_test',
            '../gpu/gpu.gyp:gl_tests',
            '../gpu/gpu.gyp:angle_unittests',
            '../gpu/gpu.gyp:gpu_unittests',
            '../tools/telemetry/telemetry.gyp:*',
          ],
          'conditions': [
            ['OS!="ios" and OS!="win"', {
              'dependencies': [
                '../breakpad/breakpad.gyp:minidump_stackwalk',
              ],
            }],
            ['OS=="linux"', {
              'dependencies': [
                '../chrome/chrome.gyp:linux_symbols'
              ],
            }],
            ['OS=="win"', {
              'dependencies': [
                '../chrome/chrome.gyp:crash_service',
              ],
            }],
            ['OS=="win" and target_arch=="ia32"', {
              'dependencies': [
                '../chrome/chrome.gyp:crash_service_win64',
              ],
            }],
          ],
        }, # target_name: chromium_gpu_builder
        {
          'target_name': 'chromium_gpu_debug_builder',
          'type': 'none',
          'dependencies': [
            '../chrome/chrome.gyp:chrome',
            '../content/content_shell_and_tests.gyp:content_browsertests',
            '../content/content_shell_and_tests.gyp:content_gl_tests',
            '../gpu/gles2_conform_support/gles2_conform_test.gyp:gles2_conform_test',
            '../gpu/khronos_glcts_support/khronos_glcts_test.gyp:khronos_glcts_test',
            '../gpu/gpu.gyp:gl_tests',
            '../gpu/gpu.gyp:angle_unittests',
            '../gpu/gpu.gyp:gpu_unittests',
            '../tools/telemetry/telemetry.gyp:*',
          ],
          'conditions': [
            ['OS!="ios" and OS!="win"', {
              'dependencies': [
                '../breakpad/breakpad.gyp:minidump_stackwalk',
              ],
            }],
            ['OS=="linux"', {
              'dependencies': [
                '../chrome/chrome.gyp:linux_symbols'
              ],
            }],
            ['OS=="win"', {
              'dependencies': [
                '../chrome/chrome.gyp:crash_service',
              ],
            }],
            ['OS=="win" and target_arch=="ia32"', {
              'dependencies': [
                '../chrome/chrome.gyp:crash_service_win64',
              ],
            }],
          ],
        }, # target_name: chromium_gpu_debug_builder
        {
          # This target contains everything we need to run tests on the special
          # device-equipped WebRTC bots. We have device-requiring tests in
          # browser_tests and content_browsertests.
          'target_name': 'chromium_builder_webrtc',
          'type': 'none',
          'dependencies': [
            'chromium_builder_perf',
            '../chrome/chrome.gyp:browser_tests',
            '../content/content_shell_and_tests.gyp:content_browsertests',
            '../content/content_shell_and_tests.gyp:content_unittests',
            '../media/media.gyp:media_unittests',
            '../media/midi/midi.gyp:midi_unittests',
            '../third_party/webrtc/tools/tools.gyp:frame_analyzer',
            '../third_party/webrtc/tools/tools.gyp:rgba_to_i420_converter',
          ],
          'conditions': [
            ['remoting==1', {
              'dependencies': [
                '../remoting/remoting.gyp:*',
              ],
            }],
          ],
        },  # target_name: chromium_builder_webrtc
        {
          'target_name': 'chromium_builder_chromedriver',
          'type': 'none',
          'dependencies': [
            '../chrome/chrome.gyp:chromedriver',
            '../chrome/chrome.gyp:chromedriver_tests',
            '../chrome/chrome.gyp:chromedriver_unittests',
          ],
        },  # target_name: chromium_builder_chromedriver
        {
          'target_name': 'chromium_builder_asan',
          'type': 'none',
          'dependencies': [
            '../chrome/chrome.gyp:chrome',

            # We refer to content_shell directly rather than blink_tests
            # because we don't want the _unittests binaries.
            '../content/content_shell_and_tests.gyp:content_shell',
          ],
          'conditions': [
            ['OS!="win"', {
              'dependencies': [
                '../net/net.gyp:hpack_fuzz_wrapper',
                '../net/net.gyp:dns_fuzz_stub',
                '../skia/skia.gyp:filter_fuzz_stub',
              ],
            }],
            ['enable_ipc_fuzzer==1 and component!="shared_library" and '
                 '(OS=="linux" or OS=="win")', {
              'dependencies': [
                '../tools/ipc_fuzzer/ipc_fuzzer.gyp:*',
              ],
            }],
            ['chromeos==0', {
              'dependencies': [
                '../v8/src/d8.gyp:d8#host',
                '../third_party/pdfium/samples/samples.gyp:pdfium_test',
              ],
            }],
            ['internal_filter_fuzzer==1', {
              'dependencies': [
                '../skia/tools/clusterfuzz-data/fuzzers/filter_fuzzer/filter_fuzzer.gyp:filter_fuzzer',
              ],
            }], # internal_filter_fuzzer
            ['clang==1', {
              'dependencies': [
                'sanitizers/sanitizers.gyp:llvm-symbolizer',
              ],
            }],
            ['OS=="win" and fastbuild==0 and target_arch=="ia32" and syzyasan==1', {
              'dependencies': [
                '../chrome/chrome_syzygy.gyp:chrome_dll_syzygy',
                '../content/content_shell_and_tests.gyp:content_shell_syzyasan',
              ],
              'conditions': [
                ['chrome_multiple_dll==1', {
                  'dependencies': [
                    '../chrome/chrome_syzygy.gyp:chrome_child_dll_syzygy',
                  ],
                }],
              ],
            }],
          ],
        },
        {
          'target_name': 'chromium_builder_nacl_sdk',
          'type': 'none',
          'dependencies': [
            '../chrome/chrome.gyp:chrome',
          ],
          'conditions': [
            ['OS=="win"', {
              'dependencies': [
                '../chrome/chrome.gyp:chrome_nacl_win64',
              ]
            }],
          ],
        },  #target_name: chromium_builder_nacl_sdk
      ],  # targets
    }], #OS!=ios and OS!=android
    ['OS=="android"', {
      'targets': [
        {
          # The current list of tests for android.  This is temporary
          # until the full set supported.  If adding a new test here,
          # please also add it to build/android/pylib/gtest/gtest_config.py,
          # else the test is not run.
          #
          # WARNING:
          # Do not add targets here without communicating the implications
          # on tryserver triggers and load.  Discuss with
          # chrome-infrastructure-team please.
          'target_name': 'android_builder_tests',
          'type': 'none',
          'dependencies': [
            '../base/android/jni_generator/jni_generator.gyp:jni_generator_tests',
            '../base/base.gyp:base_unittests',
            '../breakpad/breakpad.gyp:breakpad_unittests_deps',
            # Also compile the tools needed to deal with minidumps, they are
            # needed to run minidump tests upstream.
            '../breakpad/breakpad.gyp:dump_syms#host',
            '../breakpad/breakpad.gyp:symupload#host',
            '../breakpad/breakpad.gyp:minidump_dump#host',
            '../breakpad/breakpad.gyp:minidump_stackwalk#host',
            '../build/android/tests/multiple_proguards/multiple_proguards.gyp:multiple_proguards_test_apk',
            '../build/android/pylib/device/commands/commands.gyp:chromium_commands',
            '../cc/blink/cc_blink_tests.gyp:cc_blink_unittests',
            '../cc/cc_tests.gyp:cc_perftests_apk',
            '../cc/cc_tests.gyp:cc_unittests',
            '../components/components_tests.gyp:components_unittests',
            '../content/content_shell_and_tests.gyp:content_browsertests',
            '../content/content_shell_and_tests.gyp:content_gl_tests',
            '../content/content_shell_and_tests.gyp:content_junit_tests',
            '../content/content_shell_and_tests.gyp:chromium_linker_test_apk',
            '../content/content_shell_and_tests.gyp:content_shell_test_apk',
            '../content/content_shell_and_tests.gyp:content_unittests',
            '../gpu/gpu.gyp:gl_tests',
            '../gpu/gpu.gyp:gpu_perftests_apk',
            '../gpu/gpu.gyp:gpu_unittests',
            '../ipc/ipc.gyp:ipc_tests',
            '../media/media.gyp:media_perftests_apk',
            '../media/media.gyp:media_unittests',
            '../media/midi/midi.gyp:midi_unittests_apk',
            '../media/midi/midi.gyp:midi_unittests',
            '../net/net.gyp:net_unittests',
            '../sandbox/sandbox.gyp:sandbox_linux_unittests_deps',
            '../skia/skia_tests.gyp:skia_unittests',
            '../sql/sql.gyp:sql_unittests',
            '../sync/sync.gyp:sync_unit_tests',
            '../testing/android/junit/junit_test.gyp:junit_unit_tests',
            '../third_party/leveldatabase/leveldatabase.gyp:env_chromium_unittests',
            '../third_party/WebKit/public/all.gyp:*',
            '../tools/android/android_tools.gyp:android_tools',
            '../tools/android/android_tools.gyp:memconsumer',
            '../tools/android/findbugs_plugin/findbugs_plugin.gyp:findbugs_plugin_test',
            '../ui/android/ui_android.gyp:ui_android_unittests',
            '../ui/base/ui_base_tests.gyp:ui_base_unittests',
            '../ui/events/events.gyp:events_unittests',
            '../ui/touch_selection/ui_touch_selection.gyp:ui_touch_selection_unittests',
            # Unit test bundles packaged as an apk.
            '../base/base.gyp:base_unittests_apk',
            '../cc/blink/cc_blink_tests.gyp:cc_blink_unittests_apk',
            '../cc/cc_tests.gyp:cc_unittests_apk',
            '../components/components_tests.gyp:components_browsertests_apk',
            '../components/components_tests.gyp:components_unittests_apk',
            '../content/content_shell_and_tests.gyp:content_browsertests_apk',
            '../content/content_shell_and_tests.gyp:content_gl_tests_apk',
            '../content/content_shell_and_tests.gyp:content_unittests_apk',
            '../content/content_shell_and_tests.gyp:video_decode_accelerator_unittest_apk',
            '../gpu/gpu.gyp:gl_tests_apk',
            '../gpu/gpu.gyp:gpu_unittests_apk',
            '../ipc/ipc.gyp:ipc_tests_apk',
            '../media/media.gyp:media_unittests_apk',
            '../media/midi/midi.gyp:midi_unittests_apk',
            '../net/net.gyp:net_unittests_apk',
            '../sandbox/sandbox.gyp:sandbox_linux_jni_unittests_apk',
            '../skia/skia_tests.gyp:skia_unittests_apk',
            '../sql/sql.gyp:sql_unittests_apk',
            '../sync/sync.gyp:sync_unit_tests_apk',
            '../tools/android/heap_profiler/heap_profiler.gyp:heap_profiler_unittests_apk',
            '../ui/android/ui_android.gyp:ui_android_unittests_apk',
            '../ui/base/ui_base_tests.gyp:ui_base_unittests_apk',
            '../ui/events/events.gyp:events_unittests_apk',
            '../ui/gfx/gfx_tests.gyp:gfx_unittests_apk',
            '../ui/gl/gl_tests.gyp:gl_unittests_apk',
            '../ui/touch_selection/ui_touch_selection.gyp:ui_touch_selection_unittests_apk',
          ],
          'conditions': [
            ['chromecast==0', {
              'dependencies': [
                '../android_webview/android_webview.gyp:android_webview_unittests',
                '../chrome/chrome.gyp:unit_tests',
                # Unit test bundles packaged as an apk.
                '../android_webview/android_webview.gyp:android_webview_test_apk',
                '../android_webview/android_webview.gyp:android_webview_unittests_apk',
                '../chrome/android/chrome_apk.gyp:chrome_public_test_apk',
                '../chrome/chrome.gyp:chrome_junit_tests',
                '../chrome/chrome.gyp:chrome_shell_test_apk',
                '../chrome/chrome.gyp:chrome_sync_shell_test_apk',
                '../chrome/chrome.gyp:chrome_shell_uiautomator_tests',
                '../chrome/chrome.gyp:chromedriver_webview_shell_apk',
                '../chrome/chrome.gyp:unit_tests_apk',
              ],
            }],
          ],
        },
        {
          # WebRTC Chromium tests to run on Android.
          'target_name': 'android_builder_chromium_webrtc',
          'type': 'none',
          'dependencies': [
            '../build/android/pylib/device/commands/commands.gyp:chromium_commands',
            '../content/content_shell_and_tests.gyp:content_browsertests',
            '../tools/android/android_tools.gyp:android_tools',
            '../tools/android/android_tools.gyp:memconsumer',
            '../content/content_shell_and_tests.gyp:content_browsertests_apk',
          ],
        },  # target_name: android_builder_chromium_webrtc
      ], # targets
    }], # OS="android"
    ['OS=="mac"', {
      'targets': [
        {
          # Target to build everything plus the dmg.  We don't put the dmg
          # in the All target because developers really don't need it.
          'target_name': 'all_and_dmg',
          'type': 'none',
          'dependencies': [
            'All',
            '../chrome/chrome.gyp:build_app_dmg',
          ],
        },
        # These targets are here so the build bots can use them to build
        # subsets of a full tree for faster cycle times.
        {
          'target_name': 'chromium_builder_dbg',
          'type': 'none',
          'dependencies': [
            '../cc/blink/cc_blink_tests.gyp:cc_blink_unittests',
            '../cc/cc_tests.gyp:cc_unittests',
            '../chrome/chrome.gyp:browser_tests',
            '../chrome/chrome.gyp:interactive_ui_tests',
            '../chrome/chrome.gyp:sync_integration_tests',
            '../chrome/chrome.gyp:unit_tests',
            '../cloud_print/cloud_print.gyp:cloud_print_unittests',
            '../components/components_tests.gyp:components_unittests',
            '../content/content_shell_and_tests.gyp:content_browsertests',
            '../content/content_shell_and_tests.gyp:content_unittests',
            '../device/device_tests.gyp:device_unittests',
            '../google_apis/gcm/gcm.gyp:gcm_unit_tests',
            '../gpu/gpu.gyp:gpu_unittests',
            '../ipc/ipc.gyp:ipc_tests',
            '../ipc/mojo/ipc_mojo.gyp:ipc_mojo_unittests',
            '../jingle/jingle.gyp:jingle_unittests',
            '../media/media.gyp:media_unittests',
            '../media/midi/midi.gyp:midi_unittests',
            '../ppapi/ppapi_internal.gyp:ppapi_unittests',
            '../printing/printing.gyp:printing_unittests',
            '../remoting/remoting.gyp:remoting_unittests',
            '../rlz/rlz.gyp:*',
            '../skia/skia_tests.gyp:skia_unittests',
            '../sql/sql.gyp:sql_unittests',
            '../sync/sync.gyp:sync_unit_tests',
            '../third_party/cacheinvalidation/cacheinvalidation.gyp:cacheinvalidation_unittests',
            '../third_party/leveldatabase/leveldatabase.gyp:env_chromium_unittests',
            '../third_party/libaddressinput/libaddressinput.gyp:libaddressinput_unittests',
            '../third_party/libphonenumber/libphonenumber.gyp:libphonenumber_unittests',
            '../tools/perf/clear_system_cache/clear_system_cache.gyp:*',
            '../tools/telemetry/telemetry.gyp:*',
            '../ui/base/ui_base_tests.gyp:ui_base_unittests',
            '../ui/gfx/gfx_tests.gyp:gfx_unittests',
            '../ui/gl/gl_tests.gyp:gl_unittests',
            '../url/url.gyp:url_unittests',
          ],
        },
        {
          'target_name': 'chromium_builder_rel',
          'type': 'none',
          'dependencies': [
            '../cc/blink/cc_blink_tests.gyp:cc_blink_unittests',
            '../cc/cc_tests.gyp:cc_unittests',
            '../chrome/chrome.gyp:browser_tests',
            '../chrome/chrome.gyp:performance_browser_tests',
            '../chrome/chrome.gyp:sync_integration_tests',
            '../chrome/chrome.gyp:unit_tests',
            '../cloud_print/cloud_print.gyp:cloud_print_unittests',
            '../components/components_tests.gyp:components_unittests',
            '../content/content_shell_and_tests.gyp:content_browsertests',
            '../content/content_shell_and_tests.gyp:content_unittests',
            '../device/device_tests.gyp:device_unittests',
            '../google_apis/gcm/gcm.gyp:gcm_unit_tests',
            '../gpu/gpu.gyp:gpu_unittests',
            '../ipc/ipc.gyp:ipc_tests',
            '../ipc/mojo/ipc_mojo.gyp:ipc_mojo_unittests',
            '../jingle/jingle.gyp:jingle_unittests',
            '../media/media.gyp:media_unittests',
            '../media/midi/midi.gyp:midi_unittests',
            '../ppapi/ppapi_internal.gyp:ppapi_unittests',
            '../printing/printing.gyp:printing_unittests',
            '../remoting/remoting.gyp:remoting_unittests',
            '../skia/skia_tests.gyp:skia_unittests',
            '../sql/sql.gyp:sql_unittests',
            '../sync/sync.gyp:sync_unit_tests',
            '../third_party/cacheinvalidation/cacheinvalidation.gyp:cacheinvalidation_unittests',
            '../third_party/leveldatabase/leveldatabase.gyp:env_chromium_unittests',
            '../third_party/libaddressinput/libaddressinput.gyp:libaddressinput_unittests',
            '../third_party/libphonenumber/libphonenumber.gyp:libphonenumber_unittests',
            '../tools/perf/clear_system_cache/clear_system_cache.gyp:*',
            '../tools/telemetry/telemetry.gyp:*',
            '../ui/base/ui_base_tests.gyp:ui_base_unittests',
            '../ui/gfx/gfx_tests.gyp:gfx_unittests',
            '../ui/gl/gl_tests.gyp:gl_unittests',
            '../url/url.gyp:url_unittests',
          ],
        },
        {
          'target_name': 'chromium_builder_dbg_tsan_mac',
          'type': 'none',
          'dependencies': [
            '../base/base.gyp:base_unittests',
            '../cloud_print/cloud_print.gyp:cloud_print_unittests',
            '../crypto/crypto.gyp:crypto_unittests',
            '../ipc/ipc.gyp:ipc_tests',
            '../jingle/jingle.gyp:jingle_unittests',
            '../media/media.gyp:media_unittests',
            '../media/midi/midi.gyp:midi_unittests',
            '../net/net.gyp:net_unittests',
            '../printing/printing.gyp:printing_unittests',
            '../remoting/remoting.gyp:remoting_unittests',
            '../third_party/cacheinvalidation/cacheinvalidation.gyp:cacheinvalidation_unittests',
            '../third_party/libaddressinput/libaddressinput.gyp:libaddressinput_unittests',
            '../third_party/libphonenumber/libphonenumber.gyp:libphonenumber_unittests',
            '../url/url.gyp:url_unittests',
          ],
        },
        {
          'target_name': 'chromium_builder_dbg_valgrind_mac',
          'type': 'none',
          'dependencies': [
            '../base/base.gyp:base_unittests',
            '../chrome/chrome.gyp:unit_tests',
            '../cloud_print/cloud_print.gyp:cloud_print_unittests',
            '../components/components_tests.gyp:components_unittests',
            '../content/content_shell_and_tests.gyp:content_unittests',
            '../crypto/crypto.gyp:crypto_unittests',
            '../device/device_tests.gyp:device_unittests',
            '../ipc/ipc.gyp:ipc_tests',
            '../jingle/jingle.gyp:jingle_unittests',
            '../media/media.gyp:media_unittests',
            '../media/midi/midi.gyp:midi_unittests',
            '../net/net.gyp:net_unittests',
            '../google_apis/gcm/gcm.gyp:gcm_unit_tests',
            '../printing/printing.gyp:printing_unittests',
            '../remoting/remoting.gyp:remoting_unittests',
            '../skia/skia_tests.gyp:skia_unittests',
            '../sql/sql.gyp:sql_unittests',
            '../sync/sync.gyp:sync_unit_tests',
            '../third_party/cacheinvalidation/cacheinvalidation.gyp:cacheinvalidation_unittests',
            '../third_party/leveldatabase/leveldatabase.gyp:env_chromium_unittests',
            '../third_party/libaddressinput/libaddressinput.gyp:libaddressinput_unittests',
            '../third_party/libphonenumber/libphonenumber.gyp:libphonenumber_unittests',
            '../ui/base/ui_base_tests.gyp:ui_base_unittests',
            '../ui/gfx/gfx_tests.gyp:gfx_unittests',
            '../ui/gl/gl_tests.gyp:gl_unittests',
            '../url/url.gyp:url_unittests',
          ],
        },
      ],  # targets
    }], # OS="mac"
    ['OS=="win"', {
      'targets': [
        # These targets are here so the build bots can use them to build
        # subsets of a full tree for faster cycle times.
        {
          'target_name': 'chromium_builder',
          'type': 'none',
          'dependencies': [
            '../cc/blink/cc_blink_tests.gyp:cc_blink_unittests',
            '../cc/cc_tests.gyp:cc_unittests',
            '../chrome/chrome.gyp:browser_tests',
            '../chrome/chrome.gyp:crash_service',
            '../chrome/chrome.gyp:gcapi_test',
            '../chrome/chrome.gyp:installer_util_unittests',
            '../chrome/chrome.gyp:interactive_ui_tests',
            '../chrome/chrome.gyp:performance_browser_tests',
            '../chrome/chrome.gyp:sync_integration_tests',
            '../chrome/chrome.gyp:unit_tests',
            '../cloud_print/cloud_print.gyp:cloud_print_unittests',
            '../components/components_tests.gyp:components_unittests',
            '../content/content_shell_and_tests.gyp:content_browsertests',
            '../content/content_shell_and_tests.gyp:content_unittests',
            '../content/content_shell_and_tests.gyp:copy_test_netscape_plugin',
            # ../chrome/test/mini_installer requires mini_installer.
            '../chrome/installer/mini_installer.gyp:mini_installer',
            '../courgette/courgette.gyp:courgette_unittests',
            '../device/device_tests.gyp:device_unittests',
            '../google_apis/gcm/gcm.gyp:gcm_unit_tests',
            '../gpu/gpu.gyp:gpu_unittests',
            '../ipc/ipc.gyp:ipc_tests',
            '../ipc/mojo/ipc_mojo.gyp:ipc_mojo_unittests',
            '../jingle/jingle.gyp:jingle_unittests',
            '../media/media.gyp:media_unittests',
            '../media/midi/midi.gyp:midi_unittests',
            '../ppapi/ppapi_internal.gyp:ppapi_unittests',
            '../printing/printing.gyp:printing_unittests',
            '../remoting/remoting.gyp:remoting_unittests',
            '../skia/skia_tests.gyp:skia_unittests',
            '../sql/sql.gyp:sql_unittests',
            '../sync/sync.gyp:sync_unit_tests',
            '../third_party/cacheinvalidation/cacheinvalidation.gyp:cacheinvalidation_unittests',
            '../third_party/leveldatabase/leveldatabase.gyp:env_chromium_unittests',
            '../third_party/libaddressinput/libaddressinput.gyp:libaddressinput_unittests',
            '../third_party/libphonenumber/libphonenumber.gyp:libphonenumber_unittests',
            '../tools/perf/clear_system_cache/clear_system_cache.gyp:*',
            '../tools/telemetry/telemetry.gyp:*',
            '../ui/base/ui_base_tests.gyp:ui_base_unittests',
            '../ui/events/events.gyp:events_unittests',
            '../ui/gfx/gfx_tests.gyp:gfx_unittests',
            '../ui/gl/gl_tests.gyp:gl_unittests',
            '../ui/touch_selection/ui_touch_selection.gyp:ui_touch_selection_unittests',
            '../ui/views/views.gyp:views_unittests',
            '../url/url.gyp:url_unittests',
          ],
          'conditions': [
            ['target_arch=="ia32"', {
              'dependencies': [
                '../chrome/chrome.gyp:crash_service_win64',
              ],
            }],
          ],
        },
        {
          'target_name': 'chromium_builder_dbg_tsan_win',
          'type': 'none',
          'dependencies': [
            '../base/base.gyp:base_unittests',
            '../cloud_print/cloud_print.gyp:cloud_print_unittests',
            '../components/components_tests.gyp:components_unittests',
            '../content/content_shell_and_tests.gyp:content_unittests',
            '../crypto/crypto.gyp:crypto_unittests',
            '../ipc/ipc.gyp:ipc_tests',
            '../jingle/jingle.gyp:jingle_unittests',
            '../media/media.gyp:media_unittests',
            '../media/midi/midi.gyp:midi_unittests',
            '../net/net.gyp:net_unittests',
            '../printing/printing.gyp:printing_unittests',
            '../remoting/remoting.gyp:remoting_unittests',
            '../sql/sql.gyp:sql_unittests',
            '../third_party/cacheinvalidation/cacheinvalidation.gyp:cacheinvalidation_unittests',
            '../third_party/leveldatabase/leveldatabase.gyp:env_chromium_unittests',
            '../third_party/libaddressinput/libaddressinput.gyp:libaddressinput_unittests',
            '../third_party/libphonenumber/libphonenumber.gyp:libphonenumber_unittests',
            '../url/url.gyp:url_unittests',
          ],
        },
        {
          'target_name': 'chromium_builder_lkgr_drmemory_win',
          'type': 'none',
          'dependencies': [
            '../components/test_runner/test_runner.gyp:layout_test_helper',
            '../content/content_shell_and_tests.gyp:content_shell',
            '../content/content_shell_and_tests.gyp:content_shell_crash_service',
          ],
        },
        {
          'target_name': 'chromium_builder_dbg_drmemory_win',
          'type': 'none',
          'dependencies': [
            '../ash/ash.gyp:ash_shell_unittests',
            '../ash/ash.gyp:ash_unittests',
            '../base/base.gyp:base_unittests',
            '../cc/blink/cc_blink_tests.gyp:cc_blink_unittests',
            '../cc/cc_tests.gyp:cc_unittests',
            '../chrome/chrome.gyp:browser_tests',
            '../chrome/chrome.gyp:chrome_app_unittests',
            '../chrome/chrome.gyp:chromedriver_unittests',
            '../chrome/chrome.gyp:installer_util_unittests',
            '../chrome/chrome.gyp:unit_tests',
            '../chrome_elf/chrome_elf.gyp:chrome_elf_unittests',
            '../cloud_print/cloud_print.gyp:cloud_print_unittests',
            '../components/components_tests.gyp:components_unittests',
            '../components/test_runner/test_runner.gyp:layout_test_helper',
            '../content/content_shell_and_tests.gyp:content_browsertests',
            '../content/content_shell_and_tests.gyp:content_shell',
            '../content/content_shell_and_tests.gyp:content_shell_crash_service',
            '../content/content_shell_and_tests.gyp:content_unittests',
            '../courgette/courgette.gyp:courgette_unittests',
            '../crypto/crypto.gyp:crypto_unittests',
            '../device/device_tests.gyp:device_unittests',
            '../extensions/extensions_tests.gyp:extensions_browsertests',
            '../extensions/extensions_tests.gyp:extensions_unittests',
            '../gin/gin.gyp:gin_shell',
            '../gin/gin.gyp:gin_unittests',
            '../google_apis/gcm/gcm.gyp:gcm_unit_tests',
            '../google_apis/google_apis.gyp:google_apis_unittests',
            '../gpu/gpu.gyp:angle_unittests',
            '../gpu/gpu.gyp:gpu_unittests',
            '../ipc/ipc.gyp:ipc_tests',
            '../ipc/mojo/ipc_mojo.gyp:ipc_mojo_unittests',
            '../jingle/jingle.gyp:jingle_unittests',
            '../media/cast/cast.gyp:cast_unittests',
            '../media/media.gyp:media_unittests',
            '../media/midi/midi.gyp:midi_unittests',
            '../mojo/mojo.gyp:mojo',
            '../net/net.gyp:net_unittests',
            '../printing/printing.gyp:printing_unittests',
            '../remoting/remoting.gyp:remoting_unittests',
            '../skia/skia_tests.gyp:skia_unittests',
            '../sql/sql.gyp:sql_unittests',
            '../sync/sync.gyp:sync_unit_tests',
            '../third_party/cacheinvalidation/cacheinvalidation.gyp:cacheinvalidation_unittests',
            '../third_party/leveldatabase/leveldatabase.gyp:env_chromium_unittests',
            '../third_party/libaddressinput/libaddressinput.gyp:libaddressinput_unittests',
            '../third_party/libphonenumber/libphonenumber.gyp:libphonenumber_unittests',
            '../third_party/WebKit/Source/platform/blink_platform_tests.gyp:blink_heap_unittests',
            '../third_party/WebKit/Source/platform/blink_platform_tests.gyp:blink_platform_unittests',
            '../ui/accessibility/accessibility.gyp:accessibility_unittests',
            '../ui/app_list/app_list.gyp:app_list_unittests',
            '../ui/aura/aura.gyp:aura_unittests',
            '../ui/compositor/compositor.gyp:compositor_unittests',
            '../ui/display/display.gyp:display_unittests',
            '../ui/events/events.gyp:events_unittests',
            '../ui/gfx/gfx_tests.gyp:gfx_unittests',
            '../ui/gl/gl_tests.gyp:gl_unittests',
            '../ui/keyboard/keyboard.gyp:keyboard_unittests',
            '../ui/touch_selection/ui_touch_selection.gyp:ui_touch_selection_unittests',
            '../url/url.gyp:url_unittests',
          ],
        },
      ],  # targets
      'conditions': [
        ['branding=="Chrome"', {
          'targets': [
            {
              'target_name': 'chrome_official_builder_no_unittests',
              'type': 'none',
              'dependencies': [
                '../chrome/chrome.gyp:crash_service',
                '../chrome/chrome.gyp:gcapi_dll',
                '../chrome/chrome.gyp:pack_policy_templates',
                '../chrome/installer/mini_installer.gyp:mini_installer',
                '../cloud_print/cloud_print.gyp:cloud_print',
                '../courgette/courgette.gyp:courgette',
                '../courgette/courgette.gyp:courgette64',
                '../remoting/remoting.gyp:remoting_webapp',
                '../third_party/widevine/cdm/widevine_cdm.gyp:widevinecdmadapter',
              ],
              'conditions': [
                ['target_arch=="ia32"', {
                  'dependencies': [
                    '../chrome/chrome.gyp:crash_service_win64',
                  ],
                }],
                ['component != "shared_library" and wix_exists == "True" and \
                    sas_dll_exists == "True"', {
                  'dependencies': [
                    '../remoting/remoting.gyp:remoting_host_installation',
                  ],
                }], # component != "shared_library"
              ]
            }, {
              'target_name': 'chrome_official_builder',
              'type': 'none',
              'dependencies': [
                'chrome_official_builder_no_unittests',
                '../base/base.gyp:base_unittests',
                '../chrome/chrome.gyp:browser_tests',
                '../chrome/chrome.gyp:sync_integration_tests',
                '../ipc/ipc.gyp:ipc_tests',
                '../media/media.gyp:media_unittests',
                '../media/midi/midi.gyp:midi_unittests',
                '../net/net.gyp:net_unittests',
                '../printing/printing.gyp:printing_unittests',
                '../sql/sql.gyp:sql_unittests',
                '../sync/sync.gyp:sync_unit_tests',
                '../ui/base/ui_base_tests.gyp:ui_base_unittests',
                '../ui/gfx/gfx_tests.gyp:gfx_unittests',
                '../ui/gl/gl_tests.gyp:gl_unittests',
                '../ui/touch_selection/ui_touch_selection.gyp:ui_touch_selection_unittests',
                '../ui/views/views.gyp:views_unittests',
                '../url/url.gyp:url_unittests',
              ],
            },
          ], # targets
        }], # branding=="Chrome"
       ], # conditions
    }], # OS="win"
    ['use_aura==1', {
      'targets': [
        {
          'target_name': 'aura_builder',
          'type': 'none',
          'dependencies': [
            '../cc/blink/cc_blink_tests.gyp:cc_blink_unittests',
            '../cc/cc_tests.gyp:cc_unittests',
            '../components/components_tests.gyp:components_unittests',
            '../content/content_shell_and_tests.gyp:content_browsertests',
            '../content/content_shell_and_tests.gyp:content_unittests',
            '../device/device_tests.gyp:device_unittests',
            '../google_apis/gcm/gcm.gyp:gcm_unit_tests',
            '../ppapi/ppapi_internal.gyp:ppapi_unittests',
            '../remoting/remoting.gyp:remoting_unittests',
            '../skia/skia_tests.gyp:skia_unittests',
            '../ui/app_list/app_list.gyp:*',
            '../ui/aura/aura.gyp:*',
            '../ui/aura_extra/aura_extra.gyp:*',
            '../ui/base/ui_base_tests.gyp:ui_base_unittests',
            '../ui/compositor/compositor.gyp:*',
            '../ui/display/display.gyp:display_unittests',
            '../ui/events/events.gyp:*',
            '../ui/gfx/gfx_tests.gyp:gfx_unittests',
            '../ui/gl/gl_tests.gyp:gl_unittests',
            '../ui/keyboard/keyboard.gyp:*',
            '../ui/snapshot/snapshot.gyp:snapshot_unittests',
            '../ui/touch_selection/ui_touch_selection.gyp:ui_touch_selection_unittests',
            '../ui/wm/wm.gyp:*',
            'blink_tests',
          ],
          'conditions': [
            ['OS=="win"', {
              'dependencies': [
                '../chrome/chrome.gyp:crash_service',
              ],
            }],
            ['OS=="win" and target_arch=="ia32"', {
              'dependencies': [
                '../chrome/chrome.gyp:crash_service_win64',
              ],
            }],
            ['use_ash==1', {
              'dependencies': [
                '../ash/ash.gyp:ash_shell',
                '../ash/ash.gyp:ash_unittests',
              ],
            }],
            ['OS=="linux"', {
              # Tests that currently only work on Linux.
              'dependencies': [
                '../base/base.gyp:base_unittests',
                '../ipc/ipc.gyp:ipc_tests',
                '../sql/sql.gyp:sql_unittests',
                '../sync/sync.gyp:sync_unit_tests',
              ],
            }],
            ['chromeos==1', {
              'dependencies': [
                '../chromeos/chromeos.gyp:chromeos_unittests',
                '../ui/chromeos/ui_chromeos.gyp:ui_chromeos_unittests',
              ],
            }],
            ['use_ozone==1', {
              'dependencies': [
                '../ui/ozone/ozone.gyp:*',
                '../ui/ozone/demo/ozone_demos.gyp:*',
              ],
            }],
            ['chromecast==0', {
              'dependencies': [
                '../chrome/chrome.gyp:browser_tests',
                '../chrome/chrome.gyp:chrome',
                '../chrome/chrome.gyp:interactive_ui_tests',
                '../chrome/chrome.gyp:unit_tests',
                '../ui/message_center/message_center.gyp:*',
                '../ui/views/examples/examples.gyp:views_examples_with_content_exe',
                '../ui/views/views.gyp:views',
                '../ui/views/views.gyp:views_unittests',
              ],
            }],
          ],
        },
      ],  # targets
    }], # "use_aura==1"
    ['test_isolation_mode != "noop"', {
      'targets': [
        {
          'target_name': 'chromium_swarm_tests',
          'type': 'none',
          'dependencies': [
            '../base/base.gyp:base_unittests_run',
            '../content/content_shell_and_tests.gyp:content_browsertests_run',
            '../content/content_shell_and_tests.gyp:content_unittests_run',
            '../net/net.gyp:net_unittests_run',
          ],
          'conditions': [
            ['chromecast==0', {
              'dependencies': [
                '../chrome/chrome.gyp:browser_tests_run',
                '../chrome/chrome.gyp:interactive_ui_tests_run',
                '../chrome/chrome.gyp:sync_integration_tests_run',
                '../chrome/chrome.gyp:unit_tests_run',
              ],
            }],
          ],
        }, # target_name: chromium_swarm_tests
      ],
    }],
    ['archive_chromoting_tests==1', {
      'targets': [
        {
          'target_name': 'chromoting_swarm_tests',
          'type': 'none',
          'dependencies': [
            '../testing/chromoting/integration_tests.gyp:chromoting_integration_tests_run',
          ],
        }, # target_name: chromoting_swarm_tests
      ]
    }],
    ['OS=="mac" and toolkit_views==1', {
      'targets': [
        {
          'target_name': 'macviews_builder',
          'type': 'none',
          'dependencies': [
            '../ui/views/examples/examples.gyp:views_examples_with_content_exe',
            '../ui/views/views.gyp:views',
            '../ui/views/views.gyp:views_unittests',
          ],
        },  # target_name: macviews_builder
      ],  # targets
    }],  # os=='mac' and toolkit_views==1
  ],  # conditions
}
