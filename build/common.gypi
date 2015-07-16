# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# IMPORTANT:
# Please don't directly include this file if you are building via gyp_chromium,
# since gyp_chromium is automatically forcing its inclusion.
{
  # Variables expected to be overriden on the GYP command line (-D) or by
  # ~/.gyp/include.gypi.
  'variables': {
    # Putting a variables dict inside another variables dict looks kind of
    # weird.  This is done so that 'host_arch', 'chromeos', etc are defined as
    # variables within the outer variables dict here.  This is necessary
    # to get these variables defined for the conditions within this variables
    # dict that operate on these variables.
    'variables': {
      'variables': {
        'variables': {
          'variables': {
            # Whether we're building a ChromeOS build.
            'chromeos%': 0,

            # Whether we're building the cast (chromecast) shell
            'chromecast%': 0,

            # Whether or not we are using the Aura windowing framework.
            'use_aura%': 0,

            # Whether or not we are building the Ash shell.
            'use_ash%': 0,

            # Whether or not we are using CRAS, the ChromeOS Audio Server.
            'use_cras%': 0,

            # Use a raw surface abstraction.
            'use_ozone%': 0,

            # Configure the build for small devices. See crbug.com/318413
            'embedded%': 0,

            'conditions': [
              # Compute the architecture that we're building on.
              ['OS=="win" or OS=="ios"', {
                'host_arch%': 'ia32',
              }, {
                'host_arch%': '<!pymod_do_main(detect_host_arch)',
              }],
            ],
          },
          # Copy conditionally-set variables out one scope.
          'chromeos%': '<(chromeos)',
          'chromecast%': '<(chromecast)',
          'use_aura%': '<(use_aura)',
          'use_ash%': '<(use_ash)',
          'use_cras%': '<(use_cras)',
          'use_ozone%': '<(use_ozone)',
          'embedded%': '<(embedded)',
          'host_arch%': '<(host_arch)',

          # Whether we are using Views Toolkit
          'toolkit_views%': 0,

          # Use the PCI lib to collect GPU information.
          'use_libpci%': 1,

          # Use OpenSSL instead of NSS as the underlying SSL and crypto
          # implementation. Certificate verification will in most cases be
          # handled by the OS. If OpenSSL's struct X509 is used to represent
          # certificates, use_openssl_certs must be set.
          'use_openssl%': 0,

          # Use OpenSSL for representing certificates. When targeting Android,
          # the platform certificate library is used for certificate
          # verification. On other targets, this flag also enables OpenSSL for
          # certificate verification, but this configuration is unsupported.
          'use_openssl_certs%': 0,

          # Disable viewport meta tag by default.
          'enable_viewport%': 0,

          # Enable HiDPI support.
          'enable_hidpi%': 0,

          # Enable top chrome material design.
          'enable_topchrome_md%' : 0,

          # Force building against pre-built sysroot image on linux.  By default
          # the sysroot image is only used for Official builds  or when cross
          # compiling to arm or mips.
          'use_sysroot%': 0,

          # Override buildtype to select the desired build flavor.
          # Dev - everyday build for development/testing
          # Official - release build (generally implies additional processing)
          # TODO(mmoss) Once 'buildtype' is fully supported (e.g. Windows gyp
          # conversion is done), some of the things which are now controlled by
          # 'branding', such as symbol generation, will need to be refactored
          # based on 'buildtype' (i.e. we don't care about saving symbols for
          # non-Official # builds).
          'buildtype%': 'Dev',

          # Override branding to select the desired branding flavor.
          'branding%': 'Chromium',

          'conditions': [
            # ChromeOS and Windows use Aura and Ash.
            ['chromeos==1 or OS=="win" or OS=="linux"', {
              'use_ash%': 1,
              'use_aura%': 1,
            }],

            ['chromecast==1 and OS!="android"', {
              'embedded%': 1,
              'use_ozone%': 1,
            }],

            # Ozone uses Aura.
            ['use_ozone==1', {
              'use_aura%': 1,
            }],

            # Whether we're a traditional desktop unix.
            ['(OS=="linux" or OS=="freebsd" or OS=="openbsd" or OS=="solaris") and chromeos==0', {
              'desktop_linux%': 1,
            }, {
              'desktop_linux%': 0,
            }],

            # Embedded implies ozone.
            ['embedded==1', {
              'use_ozone%': 1,
            }],

            ['OS=="android"', {
              'target_arch%': 'arm',
            }, {
              # Default architecture we're building for is the architecture we're
              # building on, and possibly sub-architecture (for iOS builds).
              'target_arch%': '<(host_arch)',
            }],
          ],
        },
        # Copy conditionally-set variables out one scope.
        'chromeos%': '<(chromeos)',
        'chromecast%': '<(chromecast)',
        'desktop_linux%': '<(desktop_linux)',
        'use_aura%': '<(use_aura)',
        'use_ash%': '<(use_ash)',
        'use_cras%': '<(use_cras)',
        'use_ozone%': '<(use_ozone)',
        'embedded%': '<(embedded)',
        'use_libpci%': '<(use_libpci)',
        'use_openssl%': '<(use_openssl)',
        'use_openssl_certs%': '<(use_openssl_certs)',
        'enable_viewport%': '<(enable_viewport)',
        'enable_hidpi%': '<(enable_hidpi)',
        'enable_topchrome_md%': '<(enable_topchrome_md)',
        'buildtype%': '<(buildtype)',
        'branding%': '<(branding)',
        'branding_path_component%': '<(branding)',
        'host_arch%': '<(host_arch)',
        'target_arch%': '<(target_arch)',

        'target_subarch%': '',

        # The channel to build on Android: stable, beta, dev, canary, or
        # default. "default" should be used on non-official builds.
        'android_channel%': 'default',

        # Set ARM architecture version.
        'arm_version%': 7,

        # Use aurax11 for clipboard implementation. This is true on linux_aura.
        'use_clipboard_aurax11%': 0,

        # goma settings.
        # 1 to use goma.
        # If no gomadir is set, it uses the default gomadir.
        'use_goma%': 0,
        'gomadir%': '',

        # The system root for cross-compiles. Default: none.
        'sysroot%': '',
        'chroot_cmd%': '',

        # The system libdir used for this ABI.
        'system_libdir%': 'lib',

        # Default MIPS arch variant. This is set in the conditions block
        # below for MIPS targets.
        'mips_arch_variant%': '',

        # MIPS DSP ASE revision. Possible values are:
        #   0: unavailable
        #   1: revision 1
        #   2: revision 2
        'mips_dsp_rev%': 0,

        'conditions': [
          ['branding == "Chrome"', {
            'branding_path_component%': 'google_chrome',
          }],

          ['branding == "Chromium"', {
            'branding_path_component%': 'chromium',
          }],

          # Ash needs Aura.
          ['use_aura==0', {
            'use_ash%': 0,
          }],

          # Set default value of toolkit_views based on OS.
          ['OS=="mac" or OS=="win" or chromeos==1 or use_aura==1', {
            'toolkit_views%': 1,
          }, {
            'toolkit_views%': 0,
          }],

          # Embedded builds use aura without ash or views.
          ['embedded==1', {
            'use_aura%': 1,
            'use_ash%': 0,
            'toolkit_views%': 0,
          }],

          # Enable HiDPI on Mac OS, Chrome OS, Windows and Linux.
          ['OS=="mac" or chromeos==1 or OS=="win" or OS=="linux"', {
            'enable_hidpi%': 1,
          }],

          # Enable Top Chrome Material Design on Chrome OS, and Windows.
          ['chromeos==1 or OS=="win"', {
            'enable_topchrome_md%': 1,
          }],

          # Enable the OpenSSL backend on Mac OS and Windows.
          ['OS=="mac" or OS=="win"', {
            'use_openssl%': 1,
          }],

          # Enable App Launcher everywhere but mobile.
          ['OS!="ios" and OS!="android"', {
            'enable_app_list%': 1,
          }, {
            'enable_app_list%': 0,
          }],

          ['use_aura==1 and OS!="android"', {
            'use_default_render_theme%': 1,
          }, {
            'use_default_render_theme%': 0,
          }],

          ['use_ozone==1', {
            'use_ozone_evdev%': 1,
          }, {
            'use_ozone_evdev%': 0,
          }],

          # Set default gomadir.
          ['OS=="win"', {
            'gomadir': 'c:\\goma\\goma-win',
          }, {
            'gomadir': '<!(/bin/echo -n ${HOME}/goma)',
          }],

          # Set the default "target_subarch" on iOS. Valid values are "arm32",
          # "arm64" and "both" (meaning a fat binary).
          ['OS=="ios"', {
            'target_subarch%': 'arm64',
          }],

          # Set arch variants for MIPS platforms.
          ['target_arch=="mips64el"', {
            'conditions': [
              ['OS=="android"', {
                'mips_arch_variant%': 'r6',
              }, {
                'mips_arch_variant%': 'r2',
              }],
            ],
          }],

          ['target_arch=="mipsel"', {
            'mips_arch_variant%': 'r1',
          }],

          ['OS=="linux" and target_arch=="arm" and chromeos==0', {
            # sysroot needs to be an absolute path otherwise it generates
            # incorrect results when passed to pkg-config
            'sysroot%': '<!(cd <(DEPTH) && pwd -P)/chrome/installer/linux/debian_wheezy_arm-sysroot',
          }], # OS=="linux" and target_arch=="arm" and chromeos==0

          ['OS=="linux" and ((branding=="Chrome" and buildtype=="Official" and chromeos==0) or use_sysroot==1)' , {
            'conditions': [
              ['target_arch=="x64"', {
                'sysroot%': '<!(cd <(DEPTH) && pwd -P)/chrome/installer/linux/debian_wheezy_amd64-sysroot',
              }],
              ['target_arch=="ia32"', {
                'sysroot%': '<!(cd <(DEPTH) && pwd -P)/chrome/installer/linux/debian_wheezy_i386-sysroot',
              }],
          ],
          }], # OS=="linux" and branding=="Chrome" and buildtype=="Official" and chromeos==0

          ['OS=="linux" and target_arch=="mipsel"', {
            'sysroot%': '<!(cd <(DEPTH) && pwd -P)/mipsel-sysroot/sysroot',
          }],
        ],
      },

      # Copy conditionally-set variables out one scope.
      'chromeos%': '<(chromeos)',
      'chromecast%': '<(chromecast)',
      'host_arch%': '<(host_arch)',
      'target_arch%': '<(target_arch)',
      'target_subarch%': '<(target_subarch)',
      'mips_arch_variant%': '<(mips_arch_variant)',
      'mips_dsp_rev%': '<(mips_dsp_rev)',
      'toolkit_views%': '<(toolkit_views)',
      'desktop_linux%': '<(desktop_linux)',
      'use_aura%': '<(use_aura)',
      'use_ash%': '<(use_ash)',
      'use_cras%': '<(use_cras)',
      'use_libpci%': '<(use_libpci)',
      'use_ozone%': '<(use_ozone)',
      'use_ozone_evdev%': '<(use_ozone_evdev)',
      'use_clipboard_aurax11%': '<(use_clipboard_aurax11)',
      'embedded%': '<(embedded)',
      'use_openssl%': '<(use_openssl)',
      'use_openssl_certs%': '<(use_openssl_certs)',
      'enable_viewport%': '<(enable_viewport)',
      'enable_hidpi%': '<(enable_hidpi)',
      'enable_topchrome_md%': '<(enable_topchrome_md)',
      'android_channel%': '<(android_channel)',
      'use_goma%': '<(use_goma)',
      'gomadir%': '<(gomadir)',
      'enable_app_list%': '<(enable_app_list)',
      'use_default_render_theme%': '<(use_default_render_theme)',
      'buildtype%': '<(buildtype)',
      'branding%': '<(branding)',
      'branding_path_component%': '<(branding_path_component)',
      'arm_version%': '<(arm_version)',
      'sysroot%': '<(sysroot)',
      'chroot_cmd%': '<(chroot_cmd)',
      'system_libdir%': '<(system_libdir)',

      # Set to 1 to enable fast builds. Set to 2 for even faster builds
      # (it disables debug info for fastest compilation - only for use
      # on compile-only bots).
      'fastbuild%': 0,

      # Set to 1 to not store any build metadata, e.g. ifdef out all __DATE__
      # and __TIME__. Set to 0 to reenable the use of these macros in the code
      # base. See http://crbug.com/314403.
      'dont_embed_build_metadata%': 1,

      # Set to 1 to force Visual C++ to use legacy debug information format /Z7.
      # This is useful for parallel compilation tools which can't support /Zi.
      # Only used on Windows.
      'win_z7%' : 0,

      # Set to 1 to enable dcheck in Release build.
      'dcheck_always_on%': 0,

      # Set to 1 to make a build that disables unshipped tracing events.
      # Note: this setting is ignored if buildtype=="Official".
      'tracing_like_official_build%': 0,

      # Disable image loader component extension by default.
      'image_loader_extension%': 0,

      # Set NEON compilation flags.
      'arm_neon%': 1,

      # Detect NEON support at run-time.
      'arm_neon_optional%': 0,

      # Use libjpeg-turbo as the JPEG codec used by Chromium.
      'use_libjpeg_turbo%': 1,

      # Use system libjpeg. Note that the system's libjepg will be used even if
      # use_libjpeg_turbo is set.
      'use_system_libjpeg%': 0,

      # By default, component is set to static_library and it can be overriden
      # by the GYP command line or by ~/.gyp/include.gypi.
      'component%': 'static_library',

      # /analyze is off by default on Windows because it is very slow and noisy.
      # Enable with GYP_DEFINES=win_analyze=1
      'win_analyze%': 0,

      # Set to select the Title Case versions of strings in GRD files.
      'use_titlecase_in_grd%': 0,

      # Use translations provided by volunteers at launchpad.net.  This
      # currently only works on Linux.
      'use_third_party_translations%': 0,

      # Remoting compilation is enabled by default. Set to 0 to disable.
      'remoting%': 1,

      # Configuration policy is enabled by default. Set to 0 to disable.
      'configuration_policy%': 1,

      # Variable safe_browsing is used to control the build time configuration
      # for safe browsing feature. Safe browsing can be compiled in 4 different
      # levels: 0 disables it, 1 enables it fully, and 2 enables only UI and
      # reporting features for use with Data Saver on Mobile, and 3 enables
      # extended mobile protection via an external API.  When 3 is fully
      # deployed, it will replace 2.
      'safe_browsing%': 1,

      # Web speech is enabled by default. Set to 0 to disable.
      'enable_web_speech%': 1,

      # 'Ok Google' hotwording is enabled by default. Set to 0 to disable.
      'enable_hotwording%': 1,

      # Notifications are compiled in by default. Set to 0 to disable.
      'notifications%' : 1,

      # Use dsymutil to generate real .dSYM files on Mac. The default is 0 for
      # regular builds and 1 for ASan builds.
      'mac_want_real_dsym%': 'default',

      # If this is set, the clang plugins used on the buildbot will be used.
      # Run tools/clang/scripts/update.sh to make sure they are compiled.
      # This causes 'clang_chrome_plugins_flags' to be set.
      # Has no effect if 'clang' is not set as well.
      'clang_use_chrome_plugins%': 1,

      # Enable building with ASAN (Clang's -fsanitize=address option).
      # -fsanitize=address only works with clang, but asan=1 implies clang=1
      # See https://sites.google.com/a/chromium.org/dev/developers/testing/addresssanitizer
      'asan%': 0,
      'asan_blacklist%': '<(PRODUCT_DIR)/../../tools/memory/asan/blacklist.txt',
      # Enable coverage gathering instrumentation in sanitizer tools. This flag
      # also controls coverage granularity (1 for function-level coverage, 2
      # for block-level coverage).
      'sanitizer_coverage%': 0,
      # Deprecated, only works if |sanitizer_coverage| isn't set.
      # TODO(glider): remove this flag.
      'asan_coverage%': 0,
      # Enable intra-object-overflow detection in ASan (experimental).
      'asan_field_padding%': 0,

      # Enable Chromium overrides of the default configurations for various
      # dynamic tools (like ASan).
      'use_sanitizer_options%': 0,

      # Enable building with SyzyAsan.
      # See https://code.google.com/p/sawbuck/wiki/SyzyASanHowTo
      'syzyasan%': 0,

      # Enable crash reporting via Kasko.
      'kasko%': 0,

      # Enable building with LSan (Clang's -fsanitize=leak option).
      # -fsanitize=leak only works with clang, but lsan=1 implies clang=1
      # See https://sites.google.com/a/chromium.org/dev/developers/testing/leaksanitizer
      'lsan%': 0,

      # Enable building with TSan (Clang's -fsanitize=thread option).
      # -fsanitize=thread only works with clang, but tsan=1 implies clang=1
      # See http://clang.llvm.org/docs/ThreadSanitizer.html
      'tsan%': 0,
      'tsan_blacklist%': '<(PRODUCT_DIR)/../../tools/memory/tsan_v2/ignores.txt',

      # Enable building with MSan (Clang's -fsanitize=memory option).
      # MemorySanitizer only works with clang, but msan=1 implies clang=1
      # See http://clang.llvm.org/docs/MemorySanitizer.html
      'msan%': 0,
      'msan_blacklist%': '<(PRODUCT_DIR)/../../tools/msan/blacklist.txt',
      # Track where uninitialized memory originates from. From fastest to
      # slowest: 0 - no tracking, 1 - track only the initial allocation site, 2
      # - track the chain of stores leading from allocation site to use site.
      'msan_track_origins%': 2,

      # Enable building with UBSan (Clang's -fsanitize=undefined option).
      # -fsanitize=undefined only works with clang, but ubsan=1 implies clang=1
      # See http://clang.llvm.org/docs/UsersManual.html
      'ubsan%': 0,
      'ubsan_blacklist%': '<(PRODUCT_DIR)/../../tools/ubsan/blacklist.txt',
      'ubsan_vptr_blacklist%': '<(PRODUCT_DIR)/../../tools/ubsan/vptr_blacklist.txt',

      # Enable building with UBsan's vptr (Clang's -fsanitize=vptr option).
      # -fsanitize=vptr only works with clang, but ubsan_vptr=1 implies clang=1
      'ubsan_vptr%': 0,

      # Use dynamic libraries instrumented by one of the sanitizers
      # instead of the standard system libraries. Set this flag to build the
      # libraries from source.
      'use_instrumented_libraries%': 0,

      # Use dynamic libraries instrumented by one of the sanitizers
      # instead of the standard system libraries. Set this flag to download
      # prebuilt binaries from GCS.
      'use_prebuilt_instrumented_libraries%': 0,

      # Use libc++ (third_party/libc++ and third_party/libc++abi) instead of
      # stdlibc++ as standard library. This is intended to use for instrumented
      # builds.
      'use_custom_libcxx%': 0,

      # Use system libc++ instead of the default C++ library, usually libstdc++.
      # This is intended for iOS builds only.
      'use_system_libcxx%': 0,

      # Use a modified version of Clang to intercept allocated types and sizes
      # for allocated objects. clang_type_profiler=1 implies clang=1.
      # See http://dev.chromium.org/developers/deep-memory-profiler/cpp-object-type-identifier
      # TODO(dmikurube): Support mac.  See http://crbug.com/123758#c11
      'clang_type_profiler%': 0,

      # Set to true to instrument the code with function call logger.
      # See src/third_party/cygprofile/cyg-profile.cc for details.
      'order_profiling%': 0,

      # Use the provided profiled order file to link Chrome image with it.
      # This makes Chrome faster by better using CPU cache when executing code.
      # This is known as PGO (profile guided optimization).
      # See https://sites.google.com/a/google.com/chrome-msk/dev/boot-speed-up-effort
      'order_text_section%' : "",

      # Set to 1 compile with -fPIC cflag on linux. This is a must for shared
      # libraries on linux x86-64 and arm, plus ASLR.
      'linux_fpic%': 1,

      # Whether one-click signin is enabled or not.
      'enable_one_click_signin%': 0,

      # Whether to back up data before sync.
      'enable_pre_sync_backup%': 0,

      # Enable Chrome browser extensions
      'enable_extensions%': 1,

      # Enable Google Now.
      'enable_google_now%': 1,

      # Enable basic printing support and UI.
      'enable_basic_printing%': 1,

      # Enable printing with print preview. It does not imply
      # enable_basic_printing. It's possible to build Chrome with preview only.
      'enable_print_preview%': 1,

      # Set the version of CLD.
      #   0: Don't specify the version. This option is for the Finch testing.
      #   1: Use only CLD1.
      #   2: Use only CLD2.
      'cld_version%': 2,

      # For CLD2, the size of the tables that should be included in the build
      # Only evaluated if cld_version == 2 or if building the CLD2 dynamic data
      # tool explicitly.
      # See third_party/cld_2/cld_2.gyp for more information.
      #   0: Small tables, lower accuracy
      #   2: Large tables, high accuracy
      'cld2_table_size%': 2,

      # Enable spell checker.
      'enable_spellcheck%': 1,

      # Webrtc compilation is enabled by default. Set to 0 to disable.
      'enable_webrtc%': 1,

      # Media router support is enabled by default. Set to 0 to disable.
      'enable_media_router%': 1,

      # Enables use of the session service, which is enabled by default.
      # Support for disabling depends on the platform.
      'enable_session_service%': 1,

      # Enables theme support, which is enabled by default.  Support for
      # disabling depends on the platform.
      'enable_themes%': 1,

      # Enables autofill dialog and associated features; disabled by default.
      'enable_autofill_dialog%' : 0,

      # Defaults Wallet integration in Autofill dialog to use production
      # servers. Unofficial builds won't have the proper API keys.
      'enable_prod_wallet_service%': 0,

      # Enables support for background apps.
      'enable_background%': 1,

      # Enable the task manager by default.
      'enable_task_manager%': 1,

      # Enables used resource whitelist generation; disabled by default.
      'enable_resource_whitelist_generation%': 0,

      # Enable FILE support by default.
      'disable_file_support%': 0,

      # Enable FTP support by default.
      'disable_ftp_support%': 0,

      # Use native android functions in place of ICU.  Not supported by most
      # components.
      'use_icu_alternatives_on_android%': 0,

      # Use of precompiled headers on Windows.
      #
      # This variable may be explicitly set to 1 (enabled) or 0
      # (disabled) in ~/.gyp/include.gypi or via the GYP command line.
      # This setting will override the default.
      #
      # See
      # http://code.google.com/p/chromium/wiki/WindowsPrecompiledHeaders
      # for details.
      'chromium_win_pch%': 0,

      # Clang stuff.
      'make_clang_dir%': 'third_party/llvm-build/Release+Asserts',
      # Set this to true when building with Clang.
      # See http://code.google.com/p/chromium/wiki/Clang for details.
      # If this is set, clang is used as both host and target compiler in
      # cross-compile builds.
      'clang%': 0,

      # Use experimental lld linker instead of the platform's default linker.
      'use_lld%': 0,

      # Enable plugin installation by default.
      'enable_plugin_installation%': 1,

      # Specifies whether to use canvas_skia.cc in place of platform
      # specific implementations of gfx::Canvas. Affects text drawing in the
      # Chrome UI.
      # TODO(asvitkine): Enable this on all platforms and delete this flag.
      #                  http://crbug.com/105550
      'use_canvas_skia%': 0,

      # Set to "tsan", "memcheck", or "drmemory" to configure the build to work
      # with one of those tools.
      'build_for_tool%': '',

      'wix_path%': '<(DEPTH)/third_party/wix',

      # Supervised users are enabled by default.
      'enable_supervised_users%': 1,

      # Platform sends memory pressure signals natively.
      'native_memory_pressure_signals%': 0,

      'enable_mdns%' : 0,
      'enable_service_discovery%': 0,
      'enable_wifi_bootstrapping%': 0,
      'enable_hangout_services_extension%': 0,

       # Enable the Syzygy optimization step.
      'syzygy_optimize%': 0,

      # Enable hole punching for the protected video.
      'video_hole%': 0,

      # Automatically select platforms under ozone. Turn this off to
      # build only explicitly selected platforms.
      'ozone_auto_platforms%': 1,

      # If this is set clang is used as host compiler, but not as target
      # compiler. Always do this by default.
      'host_clang%': 1,

      # Variables to control Link-Time Optimization (LTO).
      # On Android, the variable use_lto enables LTO on code compiled with -Os,
      # and use_lto_o2 enables LTO on code compiled with -O2. On other
      # platforms, use_lto enables LTO in all translation units, and use_lto_o2
      # has no effect.
      #
      # On Linux and Android, when using LLVM LTO, the script
      # build/download_gold_plugin.py must be run to download a linker plugin.
      # On Mac, LLVM needs to be built from scratch using
      # tools/clang/scripts/update.py and the absolute path to
      # third_party/llvm-build/Release+Asserts/lib must be added to
      # $DYLD_LIBRARY_PATH to pick up the right version of the linker plugin.
      #
      # On Android, the variables must *not* be enabled at the same time.
      # In this case LTO would 'merge' the optimization flags at link-time
      # which would lead to all code be optimized with -O2. See crbug.com/407544
      'use_lto%': 0,
      'use_lto_o2%': 0,

      # Libxkbcommon usage.
      'use_xkbcommon%': 0,

      # Control Flow Integrity for virtual calls and casts.
      # See http://clang.llvm.org/docs/ControlFlowIntegrity.html
      'cfi_vptr%': 0,

      'cfi_blacklist%': '<(PRODUCT_DIR)/../../tools/cfi/blacklist.txt',

      # Whether the entire browser uses toolkit-views on Mac instead of Cocoa.
      'mac_views_browser%': 0,

      # By default, use ICU data file (icudtl.dat).
      'icu_use_data_file_flag%': 1,

      # Turn on JNI generation optimizations by default.
      'optimize_jni_generation%': 1,

      'conditions': [
        # A flag for POSIX platforms
        ['OS=="win"', {
          'os_posix%': 0,
        }, {
          'os_posix%': 1,
        }],

        # A flag for BSD platforms
        ['OS=="freebsd" or OS=="openbsd"', {
          'os_bsd%': 1,
        }, {
          'os_bsd%': 0,
        }],

        # NSS usage.
        ['(OS=="linux" or OS=="freebsd" or OS=="openbsd" or OS=="solaris")', {
          'use_nss_certs%': 1,
        }, {
          'use_nss_certs%': 0,
        }],

        # libudev usage.  This currently only affects the content layer.
        ['OS=="linux" and embedded==0', {
          'use_udev%': 1,
        }, {
          'use_udev%': 0,
        }],

        # Flags to use X11 on non-Mac POSIX platforms.
        ['OS=="win" or OS=="mac" or OS=="ios" or OS=="android" or use_ozone==1', {
          'use_x11%': 0,
        }, {
          'use_x11%': 1,
        }],

        # Flags to use glib.
        ['OS=="win" or OS=="mac" or OS=="ios" or OS=="android" or use_ozone==1', {
          'use_glib%': 0,
        }, {
          'use_glib%': 1,
        }],

        # Flags to use pango and cairo.
        ['OS=="win" or OS=="mac" or OS=="ios" or OS=="android" or embedded==1', {
          'use_pango%': 0,
          'use_cairo%': 0,
        }, {
          'use_pango%': 1,
          'use_cairo%': 1,
        }],

        # DBus usage.
        ['OS=="linux" and embedded==0', {
          'use_dbus%': 1,
        }, {
          'use_dbus%': 0,
        }],

        # We always use skia text rendering in Aura on Windows, since GDI
        # doesn't agree with our BackingStore.
        # TODO(beng): remove once skia text rendering is on by default.
        ['use_aura==1 and OS=="win"', {
          'enable_skia_text%': 1,
        }],

        # A flag to enable or disable our compile-time dependency
        # on gnome-keyring. If that dependency is disabled, no gnome-keyring
        # support will be available. This option is useful
        # for Linux distributions and for Aura.
        ['OS!="linux" or chromeos==1', {
          'use_gnome_keyring%': 0,
        }, {
          'use_gnome_keyring%': 1,
        }],

        ['OS=="mac" or OS=="ios"', {
          # Mac and iOS want Title Case strings
          'use_titlecase_in_grd%': 1,
        }],

        # Enable loader extensions on Chrome OS.
        ['chromeos==1', {
          'image_loader_extension%': 1,
        }, {
          'image_loader_extension%': 0,
        }],

        ['OS=="win" or OS=="mac" or (OS=="linux" and chromeos==0)', {
          'enable_one_click_signin%': 1,
          'enable_pre_sync_backup%': 1,
        }],

        ['OS=="android"', {
          'enable_extensions%': 0,
          'enable_google_now%': 0,
          'cld_version%': 1,
          'enable_spellcheck%': 0,
          'enable_themes%': 0,
          'remoting%': 0,
          'arm_neon%': 0,
          'arm_neon_optional%': 1,
          'native_memory_pressure_signals%': 1,
          'enable_basic_printing%': 1,
          'enable_print_preview%': 0,
          'enable_task_manager%':0,
          'video_hole%': 1,
        }],

        # Android OS includes support for proprietary codecs regardless of
        # building Chromium or Google Chrome. We also ship Google Chrome and
        # Chromecast with proprietary codecs.
        ['OS=="android" or branding=="Chrome" or chromecast==1', {
          'proprietary_codecs%': 1,
        }, {
          'proprietary_codecs%': 0,
        }],

        ['OS=="mac" or OS=="ios"', {
          'native_memory_pressure_signals%': 1,
        }],

        # Enable autofill dialog when not on iOS.
        ['OS!="ios"', {
          'enable_autofill_dialog%': 1,
        }],

        ['buildtype=="Official"', {
          'enable_prod_wallet_service%': 1,
        }],

        ['OS=="android"', {
          'enable_webrtc%': 1,
        }],

        ['OS=="ios"', {
          'disable_ftp_support%': 1,
          'enable_extensions%': 0,
          'enable_google_now%': 0,
          'cld_version%': 2,
          'cld2_table_size%': 0,
          'enable_basic_printing%': 0,
          'enable_print_preview%': 0,
          'enable_session_service%': 0,
          'enable_spellcheck%': 0,
          'enable_themes%': 0,
          'enable_webrtc%': 0,
          'notifications%': 0,
          'remoting%': 0,
          'safe_browsing%': 0,
          'enable_supervised_users%': 0,
          'enable_task_manager%': 0,
          'use_system_libcxx%': 1,
        }],

        # Use GPU accelerated cross process image transport by default
        # on linux builds with the Aura window manager
        ['use_aura==1 and OS=="linux"', {
          'ui_compositor_image_transport%': 1,
        }, {
          'ui_compositor_image_transport%': 0,
        }],

        # Turn precompiled headers on by default.
        ['OS=="win" and buildtype!="Official"', {
          'chromium_win_pch%': 1
        }],

        ['chromeos==1 or OS=="android" or OS=="ios" or desktop_linux==1', {
          'enable_plugin_installation%': 0,
        }, {
          'enable_plugin_installation%': 1,
        }],

        # Whether PPAPI is enabled.
        ['OS=="android" or OS=="ios" or embedded==1', {
          'enable_plugins%': 0,
        }, {
          'enable_plugins%': 1,
        }],

        # linux_use_bundled_gold: whether to use the gold linker binary checked
        # into third_party/binutils.  Force this off via GYP_DEFINES when you
        # are using a custom toolchain and need to control -B in ldflags.
        # Do not use 32-bit gold on 32-bit hosts as it runs out address space
        # for component=static_library builds.
        ['(OS=="linux" or OS=="android") and (target_arch=="x64" or target_arch=="arm")', {
          'linux_use_bundled_gold%': 1,
        }, {
          'linux_use_bundled_gold%': 0,
        }],

        # linux_use_bundled_binutils: whether to use the binary binutils
        # checked into third_party/binutils.  These are not multi-arch so cannot
        # be used except on x86 and x86-64 (the only two architectures which
        # are currently checke in).  Force this off via GYP_DEFINES when you
        # are using a custom toolchain and need to control -B in cflags.
        ['OS=="linux" and (target_arch=="x64")', {
          'linux_use_bundled_binutils%': 1,
        }, {
          'linux_use_bundled_binutils%': 0,
        }],

        # linux_use_gold_flags: whether to use build flags that rely on gold.
        # On by default for x64 Linux.
        ['OS=="linux" and target_arch=="x64"', {
          'linux_use_gold_flags%': 1,
        }, {
          'linux_use_gold_flags%': 0,
        }],

        # linux_use_debug_fission: whether to use split DWARF debug info
        # files. This can reduce link time significantly, but is incompatible
        # with some utilities such as icecc and ccache. Requires gold and
        # gcc >= 4.8 or clang.
        # http://gcc.gnu.org/wiki/DebugFission
        ['OS=="linux" and target_arch=="x64"', {
          'linux_use_debug_fission%': 1,
        }, {
          'linux_use_debug_fission%': 0,
        }],

        ['OS=="android" or OS=="ios"', {
          'enable_captive_portal_detection%': 0,
          'enable_media_router%': 0,
        }, {
          'enable_captive_portal_detection%': 1,
          'enable_media_router%': 1,
        }],

        # Enable Skia UI text drawing incrementally on different platforms.
        # http://crbug.com/105550
        #
        # On Aura, this allows per-tile painting to be used in the browser
        # compositor.
        ['OS!="android" and OS!="ios"', {
          'use_canvas_skia%': 1,
        }],

        ['chromeos==1', {
          'enable_basic_printing%': 0,
          'enable_print_preview%': 1,
        }],

        # Do not enable the Settings App on ChromeOS.
        ['enable_app_list==1 and chromeos==0', {
          'enable_settings_app%': 1,
        }, {
          'enable_settings_app%': 0,
        }],

        # Whether tests targets should be run, archived or just have the
        # dependencies verified. All the tests targets have the '_run' suffix,
        # e.g. base_unittests_run runs the target base_unittests. The test
        # target always calls tools/swarming_client/isolate.py. See the script's
        # --help for more information. Meant to be overriden with GYP_DEFINES.
        # TODO(maruel): Remove the conditions as more configurations are
        # supported.
        ['OS!="ios" and OS!="android" and chromeos==0', {
          'test_isolation_mode%': 'check',
        }, {
          'test_isolation_mode%': 'noop',
        }],
        # Whether Android build uses OpenMAX DL FFT.
        ['OS=="android" and ((target_arch=="arm" and arm_version >= 7) or target_arch=="ia32" or target_arch=="x64" or target_arch=="arm64" or target_arch=="mipsel")', {
          # Currently only supported on Android ARMv7+, ARM64, ia32, x64 and mipsel.
          # When enabled, this will also enable WebAudio support on
          # Android for these architectures.  Default is enabled.  Whether
          # WebAudio is actually available depends on runtime settings
          # and flags.
          'use_openmax_dl_fft%': 1,
        }, {
          'use_openmax_dl_fft%': 0,
        }],
        ['OS=="win" or OS=="linux"', {
            'enable_mdns%' : 1,
        }],

        # Turns on compiler optimizations in V8 in Debug build, except
        # on android_clang, where we're hitting a weird linker error.
        # TODO(dpranke): http://crbug.com/266155 .
        ['OS=="android"', {
          'v8_optimized_debug%': 1,
        }, {
          'v8_optimized_debug%': 2,
        }],

        # Disable various features by default on embedded.
        ['embedded==1', {
          'remoting%': 0,
          'enable_basic_printing%': 0,
          'enable_print_preview%': 0,
        }],

        ['OS=="win" or OS=="mac"', {
          'enable_wifi_bootstrapping%' : 1,
        }],

        # Path to sas.dll, which provides the SendSAS function.
        # http://msdn.microsoft.com/en-us/library/windows/desktop/dd979761(v=vs.85).aspx
        ['target_arch=="x64"', {
          'sas_dll_path%': '<(DEPTH)/third_party/platformsdk_win7/files/redist/amd64',
        }, {
          'sas_dll_path%': '<(DEPTH)/third_party/platformsdk_win7/files/redist/x86',
        }],

        ['sysroot!=""', {
          'pkg-config': '<(DEPTH)/build/linux/pkg-config-wrapper "<(sysroot)" "<(target_arch)" "<(system_libdir)"',
        }, {
          'pkg-config': 'pkg-config'
        }],
      ],

      # Setting this to '0' will cause V8's startup snapshot to be
      # embedded in the binary instead of being a external files.
      'v8_use_external_startup_data%': 1,

      # Set this to 1 to enable use of concatenated impulse responses
      # for the HRTF panner in WebAudio.
      'use_concatenated_impulse_responses': 1,

      # You can set the variable 'use_official_google_api_keys' to 1
      # to use the Google-internal file containing official API keys
      # for Google Chrome even in a developer build.  Setting this
      # variable explicitly to 1 will cause your build to fail if the
      # internal file is missing.
      #
      # The variable is documented here, but not handled in this file;
      # see //google_apis/determine_use_official_keys.gypi for the
      # implementation.
      #
      # Set the variable to 0 to not use the internal file, even when
      # it exists in your checkout.
      #
      # Leave it unset in your include.gypi to have the variable
      # implicitly set to 1 if you have
      # src/google_apis/internal/google_chrome_api_keys.h in your
      # checkout, and implicitly set to 0 if not.
      #
      # Note that official builds always behave as if the variable
      # was explicitly set to 1, i.e. they always use official keys,
      # and will fail to build if the internal file is missing.
      #
      # NOTE: You MUST NOT explicitly set the variable to 2 in your
      # include.gypi or by other means. Due to subtleties of GYP, this
      # is not the same as leaving the variable unset, even though its
      # default value in
      # //google_apis/determine_use_official_keys.gypi is 2.

      # Set these to bake the specified API keys and OAuth client
      # IDs/secrets into your build.
      #
      # If you create a build without values baked in, you can instead
      # set environment variables to provide the keys at runtime (see
      # src/google_apis/google_api_keys.h for details).  Features that
      # require server-side APIs may fail to work if no keys are
      # provided.
      #
      # Note that if you are building an official build or if
      # use_official_google_api_keys has been set to 1 (explicitly or
      # implicitly), these values will be ignored and the official
      # keys will be used instead.
      'google_api_key%': '',
      'google_default_client_id%': '',
      'google_default_client_secret%': '',
      # Native Client is enabled by default.
      'disable_nacl%': '0',

      # Sets the default version name and code for Android app, by default we
      # do a developer build.
      'android_app_version_name%': 'Developer Build',
      'android_app_version_code%': 1,
    },

    # Copy conditionally-set variables out one scope.
    'branding%': '<(branding)',
    'branding_path_component%': '<(branding_path_component)',
    'buildtype%': '<(buildtype)',
    'target_arch%': '<(target_arch)',
    'target_subarch%': '<(target_subarch)',
    'mips_arch_variant%': '<(mips_arch_variant)',
    'mips_dsp_rev%': '<(mips_dsp_rev)',
    'host_arch%': '<(host_arch)',
    'toolkit_views%': '<(toolkit_views)',
    'ui_compositor_image_transport%': '<(ui_compositor_image_transport)',
    'use_aura%': '<(use_aura)',
    'use_ash%': '<(use_ash)',
    'use_cras%': '<(use_cras)',
    'use_libpci%': '<(use_libpci)',
    'use_openssl%': '<(use_openssl)',
    'use_openssl_certs%': '<(use_openssl_certs)',
    'use_nss_certs%': '<(use_nss_certs)',
    'use_udev%': '<(use_udev)',
    'os_bsd%': '<(os_bsd)',
    'os_posix%': '<(os_posix)',
    'use_dbus%': '<(use_dbus)',
    'use_glib%': '<(use_glib)',
    'use_pango%': '<(use_pango)',
    'use_cairo%': '<(use_cairo)',
    'use_ozone%': '<(use_ozone)',
    'use_ozone_evdev%': '<(use_ozone_evdev)',
    'use_xkbcommon%': '<(use_xkbcommon)',
    'use_clipboard_aurax11%': '<(use_clipboard_aurax11)',
    'desktop_linux%': '<(desktop_linux)',
    'use_x11%': '<(use_x11)',
    'use_gnome_keyring%': '<(use_gnome_keyring)',
    'linux_fpic%': '<(linux_fpic)',
    'chromeos%': '<(chromeos)',
    'chromecast%': '<(chromecast)',
    'enable_viewport%': '<(enable_viewport)',
    'enable_hidpi%': '<(enable_hidpi)',
    'enable_topchrome_md%': '<(enable_topchrome_md)',
    'image_loader_extension%': '<(image_loader_extension)',
    'fastbuild%': '<(fastbuild)',
    'dont_embed_build_metadata%': '<(dont_embed_build_metadata)',
    'win_z7%': '<(win_z7)',
    'dcheck_always_on%': '<(dcheck_always_on)',
    'tracing_like_official_build%': '<(tracing_like_official_build)',
    'arm_version%': '<(arm_version)',
    'arm_neon%': '<(arm_neon)',
    'arm_neon_optional%': '<(arm_neon_optional)',
    'sysroot%': '<(sysroot)',
    'pkg-config%': '<(pkg-config)',
    'chroot_cmd%': '<(chroot_cmd)',
    'system_libdir%': '<(system_libdir)',
    'component%': '<(component)',
    'win_analyze%': '<(win_analyze)',
    'enable_resource_whitelist_generation%': '<(enable_resource_whitelist_generation)',
    'use_titlecase_in_grd%': '<(use_titlecase_in_grd)',
    'use_third_party_translations%': '<(use_third_party_translations)',
    'remoting%': '<(remoting)',
    'enable_one_click_signin%': '<(enable_one_click_signin)',
    'enable_pre_sync_backup%': '<(enable_pre_sync_backup)',
    'enable_media_router%': '<(enable_media_router)',
    'enable_webrtc%': '<(enable_webrtc)',
    'chromium_win_pch%': '<(chromium_win_pch)',
    'configuration_policy%': '<(configuration_policy)',
    'safe_browsing%': '<(safe_browsing)',
    'enable_web_speech%': '<(enable_web_speech)',
    'enable_hotwording%': '<(enable_hotwording)',
    'notifications%': '<(notifications)',
    'clang_use_chrome_plugins%': '<(clang_use_chrome_plugins)',
    'mac_want_real_dsym%': '<(mac_want_real_dsym)',
    'asan%': '<(asan)',
    'asan_blacklist%': '<(asan_blacklist)',
    'asan_coverage%': '<(asan_coverage)',
    'sanitizer_coverage%': '<(sanitizer_coverage)',
    'asan_field_padding%': '<(asan_field_padding)',
    'use_sanitizer_options%': '<(use_sanitizer_options)',
    'syzyasan%': '<(syzyasan)',
    'kasko%': '<(kasko)',
    'syzygy_optimize%': '<(syzygy_optimize)',
    'lsan%': '<(lsan)',
    'msan%': '<(msan)',
    'msan_blacklist%': '<(msan_blacklist)',
    'msan_track_origins%': '<(msan_track_origins)',
    'tsan%': '<(tsan)',
    'tsan_blacklist%': '<(tsan_blacklist)',
    'ubsan%': '<(ubsan)',
    'ubsan_blacklist%': '<(ubsan_blacklist)',
    'ubsan_vptr_blacklist%': '<(ubsan_vptr_blacklist)',
    'ubsan_vptr%': '<(ubsan_vptr)',
    'use_instrumented_libraries%': '<(use_instrumented_libraries)',
    'use_prebuilt_instrumented_libraries%': '<(use_prebuilt_instrumented_libraries)',
    'use_custom_libcxx%': '<(use_custom_libcxx)',
    'use_system_libcxx%': '<(use_system_libcxx)',
    'clang_type_profiler%': '<(clang_type_profiler)',
    'order_profiling%': '<(order_profiling)',
    'order_text_section%': '<(order_text_section)',
    'enable_extensions%': '<(enable_extensions)',
    'enable_plugin_installation%': '<(enable_plugin_installation)',
    'enable_plugins%': '<(enable_plugins)',
    'enable_session_service%': '<(enable_session_service)',
    'enable_themes%': '<(enable_themes)',
    'enable_autofill_dialog%': '<(enable_autofill_dialog)',
    'enable_prod_wallet_service%': '<(enable_prod_wallet_service)',
    'enable_background%': '<(enable_background)',
    'linux_use_bundled_gold%': '<(linux_use_bundled_gold)',
    'linux_use_bundled_binutils%': '<(linux_use_bundled_binutils)',
    'linux_use_gold_flags%': '<(linux_use_gold_flags)',
    'linux_use_debug_fission%': '<(linux_use_debug_fission)',
    'use_canvas_skia%': '<(use_canvas_skia)',
    'test_isolation_mode%': '<(test_isolation_mode)',
    'enable_basic_printing%': '<(enable_basic_printing)',
    'enable_print_preview%': '<(enable_print_preview)',
    'enable_spellcheck%': '<(enable_spellcheck)',
    'enable_google_now%': '<(enable_google_now)',
    'cld_version%': '<(cld_version)',
    'cld2_table_size%': '<(cld2_table_size)',
    'enable_captive_portal_detection%': '<(enable_captive_portal_detection)',
    'disable_file_support%': '<(disable_file_support)',
    'disable_ftp_support%': '<(disable_ftp_support)',
    'use_icu_alternatives_on_android%': '<(use_icu_alternatives_on_android)',
    'enable_task_manager%': '<(enable_task_manager)',
    'sas_dll_path%': '<(sas_dll_path)',
    'wix_path%': '<(wix_path)',
    'use_libjpeg_turbo%': '<(use_libjpeg_turbo)',
    'use_system_libjpeg%': '<(use_system_libjpeg)',
    'android_channel%': '<(android_channel)',
    'icu_use_data_file_flag%': '<(icu_use_data_file_flag)',
    'gyp_managed_install%': 0,
    'create_standalone_apk%': 1,
    'enable_app_list%': '<(enable_app_list)',
    'use_default_render_theme%': '<(use_default_render_theme)',
    'enable_settings_app%': '<(enable_settings_app)',
    'google_api_key%': '<(google_api_key)',
    'google_default_client_id%': '<(google_default_client_id)',
    'google_default_client_secret%': '<(google_default_client_secret)',
    'enable_supervised_users%': '<(enable_supervised_users)',
    'native_memory_pressure_signals%': '<(native_memory_pressure_signals)',
    'enable_mdns%' : '<(enable_mdns)',
    'enable_service_discovery%' : '<(enable_service_discovery)',
    'enable_wifi_bootstrapping%': '<(enable_wifi_bootstrapping)',
    'enable_hangout_services_extension%' : '<(enable_hangout_services_extension)',
    'v8_optimized_debug%': '<(v8_optimized_debug)',
    'proprietary_codecs%': '<(proprietary_codecs)',
    'use_goma%': '<(use_goma)',
    'gomadir%': '<(gomadir)',
    'use_lto%': '<(use_lto)',
    'use_lto_o2%': '<(use_lto_o2)',
    'video_hole%': '<(video_hole)',
    'v8_use_external_startup_data%': '<(v8_use_external_startup_data)',
    'cfi_vptr%': '<(cfi_vptr)',
    'cfi_blacklist%': '<(cfi_blacklist)',
    'mac_views_browser%': '<(mac_views_browser)',
    'android_app_version_name%': '<(android_app_version_name)',
    'android_app_version_code%': '<(android_app_version_code)',

    # Use system protobuf instead of bundled one.
    'use_system_protobuf%': 0,

    # Use system yasm instead of bundled one.
    'use_system_yasm%': 0,

    # Use system ICU instead of bundled one.
    'use_system_icu%' : 0,

    # Default to enabled PIE; this is important for ASLR but we may need to be
    # able to turn it off for various reasons.
    'linux_disable_pie%': 0,

    # The release channel that this build targets. This is used to restrict
    # channel-specific build options, like which installer packages to create.
    # The default is 'all', which does no channel-specific filtering.
    'channel%': 'all',

    # Override chromium_mac_pch and set it to 0 to suppress the use of
    # precompiled headers on the Mac.  Prefix header injection may still be
    # used, but prefix headers will not be precompiled.  This is useful when
    # using distcc to distribute a build to compile slaves that don't
    # share the same compiler executable as the system driving the compilation,
    # because precompiled headers rely on pointers into a specific compiler
    # executable's image.  Setting this to 0 is needed to use an experimental
    # Linux-Mac cross compiler distcc farm.
    'chromium_mac_pch%': 1,

    # The default value for mac_strip in target_defaults. This cannot be
    # set there, per the comment about variable% in a target_defaults.
    'mac_strip_release%': 0,

    # Set to 1 to enable java code coverage. Instruments classes during build
    # to produce .ec files during runtime.
    'emma_coverage%': 0,

    # EMMA filter string consisting of a list of inclusion/exclusion patterns
    # separated with whitespace and/or comma. Only has effect if
    # 'emma_coverage=1'.
    'emma_filter%': '',

    # Set to 1 to enable running Android lint on java/class files.
    'android_lint%': 1,

    # Although base/allocator lets you select a heap library via an
    # environment variable, the libcmt shim it uses sometimes gets in
    # the way.  To disable it entirely, and switch to normal msvcrt, do e.g.
    #  'win_use_allocator_shim': 0,
    #  'win_release_RuntimeLibrary': 2
    # to ~/.gyp/include.gypi, gclient runhooks --force, and do a release build.
    'win_use_allocator_shim%': 1, # 1 = shim allocator via libcmt; 0 = msvcrt

    # TODO(bradnelson): eliminate this when possible.
    # To allow local gyp files to prevent release.vsprops from being included.
    # Yes(1) means include release.vsprops.
    # Once all vsprops settings are migrated into gyp, this can go away.
    'msvs_use_common_release%': 1,

    # TODO(bradnelson): eliminate this when possible.
    # To allow local gyp files to override additional linker options for msvs.
    # Yes(1) means set use the common linker options.
    'msvs_use_common_linker_extras%': 1,

    # TODO(sgk): eliminate this if possible.
    # It would be nicer to support this via a setting in 'target_defaults'
    # in chrome/app/locales/locales.gypi overriding the setting in the
    # 'Debug' configuration in the 'target_defaults' dict below,
    # but that doesn't work as we'd like.
    'msvs_debug_link_incremental%': '2',

    # Needed for some of the largest modules.
    'msvs_debug_link_nonincremental%': '1',

    # Turns on Use Library Dependency Inputs for linking chrome.dll on Windows
    # to get incremental linking to be faster in debug builds.
    'incremental_chrome_dll%': '0',

    # Experimental setting to break chrome.dll into multiple pieces based on
    # process type.
    'chrome_multiple_dll%': '0',

    # Experimental setting to optimize Chrome's DLLs with PGO.
    'chrome_pgo_phase%': '0',

    # Whether the VS xtree header has been patched to disable warning 4702. If
    # it has, then we don't need to disable 4702 (unreachable code warning).
    # The patch is preapplied to the internal toolchain and hence all bots.
    'msvs_xtree_patched%': '<!pymod_do_main(win_is_xtree_patched)',

    # Clang stuff.
    'clang%': '<(clang)',
    'host_clang%': '<(host_clang)',
    'make_clang_dir%': '<(make_clang_dir)',
    'use_lld%': '<(use_lld)',

    # Control which version of clang to use when building for iOS.  If set to
    # '1', uses the version of clang that ships with Xcode.  If set to '0', uses
    # the version of clang that ships with the Chromium source.  This variable
    # is automatically set to '1' when using the Xcode generator.
    'clang_xcode%': 0,

    # These two variables can be set in GYP_DEFINES while running
    # |gclient runhooks| to let clang run a plugin in every compilation.
    # Only has an effect if 'clang=1' is in GYP_DEFINES as well.
    # Example:
    #     GYP_DEFINES='clang=1 clang_load=/abs/path/to/libPrintFunctionNames.dylib clang_add_plugin=print-fns' gclient runhooks

    'clang_load%': '',
    'clang_add_plugin%': '',

    # Tell ld64 to write map files describing binary layout. Useful
    # for looking at what contributes to binary size, e.g. with
    # https://github.com/nico/bloat
    'mac_write_linker_maps%': 0,

    # The default type of gtest.
    'gtest_target_type%': 'executable',

    # Enable sampling based profiler.
    # See http://google-perftools.googlecode.com/svn/trunk/doc/cpuprofile.html
    'profiling%': '0',
    # Profile without optimizing out stack frames when profiling==1.
    'profiling_full_stack_frames%': '0',

    # And if we want to dump symbols for Breakpad-enabled builds.
    'linux_dump_symbols%': 0,
    # And if we want to strip the binary after dumping symbols.
    'linux_strip_binary%': 0,
    # If we want stack unwind support for backtrace().
    'debug_unwind_tables%': 1,
    'release_unwind_tables%': 1,

    # Override where to find binutils
    'binutils_version%': 0,
    'binutils_dir%': '',

    # Enable TCMalloc.
    # Default of 'use_allocator' is set to 'none' if OS=='android' later.
    'use_allocator%': 'tcmalloc',

    # Set to 1 to link against libgnome-keyring instead of using dlopen().
    'linux_link_gnome_keyring%': 0,
    # Set to 1 to link against gsettings APIs instead of using dlopen().
    'linux_link_gsettings%': 0,

    # Enable use of OpenMAX DL FFT routines.
    'use_openmax_dl_fft%': '<(use_openmax_dl_fft)',

    # Enable new NPDevice API.
    'enable_new_npdevice_api%': 0,

    # .gyp files or targets should set chromium_code to 1 if they build
    # Chromium-specific code, as opposed to external code.  This variable is
    # used to control such things as the set of warnings to enable, and
    # whether warnings are treated as errors.
    'chromium_code%': 0,

    # Disable fatal linker warnings, similarly to how we make it possible
    # to disable -Werror (e.g. for different toolchain versions).
    'disable_fatal_linker_warnings%': 0,

    'release_valgrind_build%': 0,

    # TODO(thakis): Make this a blacklist instead, http://crbug.com/101600
    'enable_wexit_time_destructors%': 0,

    # Build libpeerconnection as a static library by default.
    'libpeer_target_type%': 'static_library',

    # Set to 1 to compile with the OpenGL ES 2.0 conformance tests.
    'internal_gles2_conform_tests%': 0,

    # Set to 1 to compile with the Khronos GL-CTS conformance tests.
    'internal_khronos_glcts_tests%': 0,

    # Set to 1 to compile the filter fuzzer.
    'internal_filter_fuzzer%': 0,

    # NOTE: When these end up in the Mac bundle, we need to replace '-' for '_'
    # so Cocoa is happy (http://crbug.com/20441).
    'locales': [
      'am', 'ar', 'bg', 'bn', 'ca', 'cs', 'da', 'de', 'el', 'en-GB',
      'en-US', 'es-419', 'es', 'et', 'fa', 'fi', 'fil', 'fr', 'gu', 'he',
      'hi', 'hr', 'hu', 'id', 'it', 'ja', 'kn', 'ko', 'lt', 'lv',
      'ml', 'mr', 'ms', 'nb', 'nl', 'pl', 'pt-BR', 'pt-PT', 'ro', 'ru',
      'sk', 'sl', 'sr', 'sv', 'sw', 'ta', 'te', 'th', 'tr', 'uk',
      'vi', 'zh-CN', 'zh-TW',
    ],

    # Pseudo locales are special locales which are used for testing and
    # debugging. They don't get copied to the final app. For more info,
    # check out https://www.chromium.org/developers/testing/fake-bidi
    'pseudo_locales': [
      'fake-bidi',
    ],

    'grit_defines': [],

    # If debug_devtools is set to 1, JavaScript files for DevTools are
    # stored as is and loaded from disk. Otherwise, a concatenated file
    # is stored in resources.pak. It is still possible to load JS files
    # from disk by passing --debug-devtools cmdline switch.
    'debug_devtools%': 0,

    # The Java Bridge is not compiled in by default.
    'java_bridge%': 0,

    # Code signing for iOS binaries.  The bots need to be able to disable this.
    'chromium_ios_signing%': 1,

    # This flag is only used when disable_nacl==0 and disables all those
    # subcomponents which would require the installation of a native_client
    # untrusted toolchain.
    'disable_nacl_untrusted%': 0,

    # PNaCl toolchain does not support sanitizers. Disable by default.
    'enable_nacl_nonsfi_test%': 0,

    # Disable Dart by default.
    'enable_dart%': 0,

    # Copy out the setting of disable_nacl.
    'disable_nacl%': '<(disable_nacl)',

    # Portable Native Client is enabled by default.
    'disable_pnacl%': 0,

    # Whether to build full debug version for Debug configuration on Android.
    # Compared to full debug version, the default Debug configuration on Android
    # has no full v8 debug, has size optimization and linker gc section, so that
    # we can build a debug version with acceptable size and performance.
    'android_full_debug%': 0,

    # Contains data about the attached devices for gyp_managed_install.
    'build_device_config_path': '<(PRODUCT_DIR)/build_devices.cfg',

    'sas_dll_exists': '<!pymod_do_main(dir_exists "<(sas_dll_path)")',
    'wix_exists': '<!pymod_do_main(dir_exists "<(wix_path)")',

    'windows_sdk_path%': 'C:/Program Files (x86)/Windows Kits/8.1',
    'directx_sdk_default_path': '<(DEPTH)/third_party/directxsdk/files',

    # Whether we are using the rlz library or not.  Platforms like Android send
    # rlz codes for searches but do not use the library.
    'enable_rlz%': 0,

    # Turns on the i18n support in V8.
    'v8_enable_i18n_support': 1,

    # Compile d8 for the host toolset.
    'v8_toolset_for_d8': 'host',

    # Use brlapi from brltty for braille display support.
    'use_brlapi%': 0,

    # Relative path to icu.gyp from this file.
    'icu_gyp_path': '../third_party/icu/icu.gyp',

    # IPC fuzzer is disabled by default.
    'enable_ipc_fuzzer%': 0,

    # Force disable libstdc++ debug mode.
    'disable_glibcxx_debug%': 0,

    # Set to 1 to compile with MSE support for MPEG2 TS
    'enable_mpeg2ts_stream_parser%': 0,

    # Support ChromeOS touchpad gestures with ozone.
    'use_evdev_gestures%': 0,

    # Default ozone platform (if no --ozone-platform flag).
    'ozone_platform%': "",

    # Ozone platforms to include in the build.
    'ozone_platform_caca%': 0,
    'ozone_platform_cast%': 0,
    'ozone_platform_dri%': 0,
    'ozone_platform_drm%': 0,
    'ozone_platform_egltest%': 0,
    'ozone_platform_gbm%': 0,
    'ozone_platform_ozonex%': 0,
    'ozone_platform_test%': 0,

    # Experiment: http://crbug.com/426914
    'envoy%': 0,

    # Used to set libjpeg_gyp_path. Chrome OS ui/gfx/gfx.gyp uses the IJG path
    # for robust login screen decoding.
    'libjpeg_ijg_gyp_path': '<(DEPTH)/third_party/libjpeg/libjpeg.gyp',
    'libjpeg_turbo_gyp_path': '<(DEPTH)/third_party/libjpeg_turbo/libjpeg.gyp',

    'conditions': [
      ['buildtype=="Official"', {
        # Continue to embed build meta data in Official builds, basically the
        # time it was built.
        # TODO(maruel): This decision should be revisited because having an
        # official deterministic build has high value too but MSVC toolset can't
        # generate anything deterministic with WPO enabled AFAIK.
        'dont_embed_build_metadata%': 0,
      }],
      # Enable the Syzygy optimization step for the official builds.
      ['OS=="win" and buildtype=="Official" and syzyasan!=1 and clang!=1', {
        'syzygy_optimize%': 1,
      }, {
        'syzygy_optimize%': 0,
      }],
      # Get binutils version so we can enable debug fission if we can.
      ['os_posix==1 and OS!="mac" and OS!="ios"', {
        'conditions': [
          # compiler_version doesn't work with clang
          # TODO(mithro): Land https://codereview.chromium.org/199793014/ so
          # compiler_version works with clang.
          # TODO(glider): set clang to 1 earlier for ASan and TSan builds so
          # that it takes effect here.
          ['clang==0 and asan==0 and lsan==0 and tsan==0 and msan==0 and ubsan==0 and ubsan_vptr==0', {
            'binutils_version%': '<!pymod_do_main(compiler_version target assembler)',
          }],
          # On Android we know the binutils version in the toolchain.
          ['OS=="android"', {
            'binutils_version%': 222,
          }],
          ['host_arch=="x64"', {
            'binutils_dir%': 'third_party/binutils/Linux_x64/Release/bin',
          }],
          ['host_arch=="ia32"', {
            'binutils_dir%': 'third_party/binutils/Linux_ia32/Release/bin',
          }],
          # Our version of binutils in third_party/binutils
          ['linux_use_bundled_binutils==1', {
            'binutils_version%': 224,
          }],
        ],
      }, {
        'binutils_version%': 0,
      }],
      # The version of GCC in use, set later in platforms that use GCC and have
      # not explicitly chosen to build with clang. Currently, this means all
      # platforms except Windows, Mac and iOS.
      # TODO(glider): set clang to 1 earlier for ASan and TSan builds so that
      # it takes effect here.
      ['os_posix==1 and OS!="mac" and OS!="ios" and clang==0 and asan==0 and lsan==0 and tsan==0 and msan==0 and ubsan_vptr==0', {
        'conditions': [
          ['OS=="android"', {
            'host_gcc_version%': '<!pymod_do_main(compiler_version host compiler)',
            # We directly set the gcc version since we know what we use.
            'gcc_version%': 49,
          }, {
            'host_gcc_version%': '<!pymod_do_main(compiler_version host compiler)',
            'gcc_version%': '<!pymod_do_main(compiler_version target compiler)',
          }],
        ],
      }, {
        'host_gcc_version%': 0,
        'gcc_version%': 0,
      }],
      ['OS=="win" and "<!pymod_do_main(dir_exists <(directx_sdk_default_path))"=="True"', {
        'directx_sdk_path%': '<(directx_sdk_default_path)',
      }, {
        'directx_sdk_path%': '$(DXSDK_DIR)',
      }],
      ['OS=="win"', {
        'windows_driver_kit_path%': '$(WDK_DIR)',
      }],
      ['os_posix==1 and OS!="mac" and OS!="ios"', {
        'conditions': [
          ['target_arch=="mipsel" or target_arch=="mips64el"', {
            'werror%': '',
            'disable_nacl%': 1,
            'nacl_untrusted_build%': 0,
            'use_allocator%': 'none',
          }],
          # Use a 64-bit linker to avoid running out of address space. The
          # buildbots should have a 64-bit kernel and a 64-bit libc installed.
          ['host_arch=="ia32" and target_arch=="ia32"', {
            # TODO(thestig) This is a horrible way to force the desired
            # configuration. Our gyp variable scoping is likely wrong and
            # needs to be cleaned up. The GN configuration should be changed
            # to match.
            'binutils_version%': 224,
            'linux_use_bundled_binutils%': '1',
            'linux_use_bundled_gold%': '1',
            'binutils_dir%': 'third_party/binutils/Linux_x64/Release/bin',
          }],
          # All Chrome builds have breakpad symbols, but only process the
          # symbols from official builds.
          ['(branding=="Chrome" and buildtype=="Official")', {
            'linux_dump_symbols%': 1,

            # Omit unwind support in official release builds to save space. We
            # can use breakpad for these builds.
            'release_unwind_tables%': 0,
          }],
        ],
      }],  # os_posix==1 and OS!="mac" and OS!="ios"
      ['OS=="ios"', {
        'disable_nacl%': 1,
        'enable_background%': 0,
        'icu_use_data_file_flag%': 1,
        'enable_web_speech%': 0,
        'use_system_libxml%': 1,
        'use_system_sqlite%': 1,
        'locales==': [
          'ar', 'ca', 'cs', 'da', 'de', 'el', 'en-GB', 'en-US', 'es', 'es-MX',
          'fi', 'fr', 'he', 'hi', 'hr', 'hu', 'id', 'it', 'ja', 'ko', 'ms',
          'nb', 'nl', 'pl', 'pt', 'pt-PT', 'ro', 'ru', 'sk', 'sv', 'th', 'tr',
          'uk', 'vi', 'zh-CN', 'zh-TW',
        ],

        # iOS SDK and deployment target support.  The |ios_sdk| value is left
        # blank so that when it is set in the project files it will be the
        # "current" iOS SDK.  Forcing a specific SDK even if it is "current"
        # causes Xcode to spit out a warning for every single project file for
        # not using the "current" SDK.
        'ios_sdk%': '',
        'ios_sdk_path%': '',
        'ios_deployment_target%': '7.0',

        'conditions': [
          # ios_product_name is set to the name of the .app bundle as it should
          # appear on disk.
          ['branding=="Chrome"', {
            'ios_product_name%': 'Chrome',
          }, { # else: branding!="Chrome"
            'ios_product_name%': 'Chromium',
          }],
          ['branding=="Chrome" and buildtype=="Official"', {
            'ios_breakpad%': 1,
          }, { # else: branding!="Chrome" or buildtype!="Official"
            'ios_breakpad%': 0,
          }],
        ],
      }],  # OS=="ios"
      ['OS=="android"', {
        # Location of Android NDK.
        'variables': {
          'variables': {
            # Standard libraries can use the relative path to the NDK.
            'android_ndk_root%': '../../third_party/android_tools/ndk/',
            # Unfortunately, it is required to use the absolute path to the SDK
            # because it us passed to ant which uses a different relative path
            # from GYP.
            'android_sdk_root%': '<!(cd <(DEPTH) && pwd -P)/third_party/android_tools/sdk/',
            # Similarly, gdbserver and the Android toolchain need to use the
            # absolute path to the NDK because they are used at different levels
            # in the GYP files.
            'android_ndk_absolute_root%': '<!(cd <(DEPTH) && pwd -P)/third_party/android_tools/ndk/',
            'android_host_arch%': '<!(uname -m)',
            # Android API-level of the SDK used for compilation.
            'android_sdk_version%': '22',
            'android_sdk_build_tools_version%': '22.0.1',
            'host_os%': "<!(uname -s | sed -e 's/Linux/linux/;s/Darwin/mac/')",
          },
          # Copy conditionally-set variables out one scope.
          'android_ndk_root%': '<(android_ndk_root)',
          'android_ndk_absolute_root%': '<(android_ndk_absolute_root)',
          'android_sdk_root%': '<(android_sdk_root)',
          'android_sdk_version%': '<(android_sdk_version)',
          'android_libcpp_root': '<(android_ndk_root)/sources/cxx-stl/llvm-libc++',
          'host_os%': '<(host_os)',

          'android_sdk%': '<(android_sdk_root)/platforms/android-<(android_sdk_version)',
          # Android SDK build tools (e.g. dx, aidl)
          'android_sdk_tools%': '<(android_sdk_root)/build-tools/<(android_sdk_build_tools_version)',

          # Android API level 16 is JB (Android 4.1) which is the minimum
          # platform requirement for Chrome on Android, we use it for native
          # code compilation.
          'conditions': [
            ['target_arch == "ia32"', {
              'android_app_abi%': 'x86',
              'android_gdbserver%': '<(android_ndk_absolute_root)/prebuilt/android-x86/gdbserver/gdbserver',
              'android_ndk_sysroot%': '<(android_ndk_root)/platforms/android-16/arch-x86',
              'android_ndk_lib_dir%': 'usr/lib',
              'android_toolchain%': '<(android_ndk_absolute_root)/toolchains/x86-4.9/prebuilt/<(host_os)-<(android_host_arch)/bin',
            }],
            ['target_arch == "x64"', {
              'android_app_abi%': 'x86_64',
              'android_gdbserver%': '<(android_ndk_absolute_root)/prebuilt/android-x86_64/gdbserver/gdbserver',
              'android_ndk_sysroot%': '<(android_ndk_root)/platforms/android-21/arch-x86_64',
              'android_ndk_lib_dir%': 'usr/lib64',
              'android_toolchain%': '<(android_ndk_absolute_root)/toolchains/x86_64-4.9/prebuilt/<(host_os)-<(android_host_arch)/bin',
            }],
            ['target_arch=="arm"', {
              'conditions': [
                ['arm_version<7', {
                  'android_app_abi%': 'armeabi',
                }, {
                  'android_app_abi%': 'armeabi-v7a',
                }],
              ],
              'android_gdbserver%': '<(android_ndk_absolute_root)/prebuilt/android-arm/gdbserver/gdbserver',
              'android_ndk_sysroot%': '<(android_ndk_root)/platforms/android-16/arch-arm',
              'android_ndk_lib_dir%': 'usr/lib',
              'android_toolchain%': '<(android_ndk_absolute_root)/toolchains/arm-linux-androideabi-4.9/prebuilt/<(host_os)-<(android_host_arch)/bin',
            }],
            ['target_arch == "arm64"', {
              'android_app_abi%': 'arm64-v8a',
              'android_gdbserver%': '<(android_ndk_absolute_root)/prebuilt/android-arm64/gdbserver/gdbserver',
              'android_ndk_sysroot%': '<(android_ndk_root)/platforms/android-21/arch-arm64',
              'android_ndk_lib_dir%': 'usr/lib',
              'android_toolchain%': '<(android_ndk_absolute_root)/toolchains/aarch64-linux-android-4.9/prebuilt/<(host_os)-<(android_host_arch)/bin',
            }],
            ['target_arch == "mipsel"', {
              'android_app_abi%': 'mips',
              'android_gdbserver%': '<(android_ndk_absolute_root)/prebuilt/android-mips/gdbserver/gdbserver',
              'android_ndk_sysroot%': '<(android_ndk_root)/platforms/android-16/arch-mips',
              'android_ndk_lib_dir%': 'usr/lib',
              'android_toolchain%': '<(android_ndk_absolute_root)/toolchains/mipsel-linux-android-4.9/prebuilt/<(host_os)-<(android_host_arch)/bin',
            }],
            ['target_arch == "mips64el"', {
              'android_app_abi%': 'mips64',
              'android_gdbserver%': '<(android_ndk_absolute_root)/prebuilt/android-mips64/gdbserver/gdbserver',
              'android_ndk_sysroot%': '<(android_ndk_root)/platforms/android-21/arch-mips64',
              'android_ndk_lib_dir%': 'usr/lib64',
              'android_toolchain%': '<(android_ndk_absolute_root)/toolchains/mips64el-linux-android-4.9/prebuilt/<(host_os)-<(android_host_arch)/bin',
            }],
          ],
        },
        # Copy conditionally-set variables out one scope.
        'android_app_abi%': '<(android_app_abi)',
        'android_gdbserver%': '<(android_gdbserver)',
        'android_ndk_root%': '<(android_ndk_root)',
        'android_ndk_sysroot%': '<(android_ndk_sysroot)',
        'android_sdk_root%': '<(android_sdk_root)',
        'android_sdk_version%': '<(android_sdk_version)',
        'android_toolchain%': '<(android_toolchain)',

        'android_ndk_include': '<(android_ndk_sysroot)/usr/include',
        'android_ndk_lib': '<(android_ndk_sysroot)/<(android_ndk_lib_dir)',
        'android_sdk_tools%': '<(android_sdk_tools)',
        'android_aapt_path%': '<(android_sdk_tools)/aapt',
        'android_sdk%': '<(android_sdk)',
        'android_sdk_jar%': '<(android_sdk)/android.jar',

        'android_libcpp_root': '<(android_libcpp_root)',
        'android_libcpp_include': '<(android_libcpp_root)/libcxx/include',
        'android_libcpp_libs_dir': '<(android_libcpp_root)/libs/<(android_app_abi)',
        'host_os%': '<(host_os)',

        # Location of the "objcopy" binary, used by both gyp and scripts.
        'android_objcopy%' : '<!(/bin/echo -n <(android_toolchain)/*-objcopy)',

        # Location of the "strip" binary, used by both gyp and scripts.
        'android_strip%' : '<!(/bin/echo -n <(android_toolchain)/*-strip)',

        # Location of the "readelf" binary.
        'android_readelf%' : '<!(/bin/echo -n <(android_toolchain)/*-readelf)',

        # Determines whether we should optimize JNI generation at the cost of
        # breaking assumptions in the build system that when inputs have changed
        # the outputs should always change as well.  This is meant purely for
        # developer builds, to avoid spurious re-linking of native files.
        'optimize_jni_generation%': '<(optimize_jni_generation)',

        # Always uses openssl.
        'use_openssl%': 1,
        'use_openssl_certs%': 1,

        'proprietary_codecs%': '<(proprietary_codecs)',
        'safe_browsing%': 2,
        'enable_web_speech%': 0,
        'java_bridge%': 1,
        'build_ffmpegsumo%': 0,
        'use_allocator%': 'none',

        # Disable Native Client.
        'disable_nacl%': 1,

        # Android does not support background apps.
        'enable_background%': 0,

        # Sessions are store separately in the Java side.
        'enable_session_service%': 0,

        'p2p_apis%' : 0,

        'gtest_target_type%': 'shared_library',
      }],  # OS=="android"
      ['embedded==1', {
        'use_system_fontconfig%': 0,
      }, {
        'use_system_fontconfig%': 1,
      }],
      ['chromecast==1', {
        'enable_mpeg2ts_stream_parser%': 1,
        'ffmpeg_branding%': 'ChromeOS',
        'ozone_platform_ozonex%': 1,
        'use_playready%': 0,
        'conditions': [
          ['target_arch=="arm"', {
            'arm_arch%': '',
            'arm_tune%': 'cortex-a9',
            'arm_thumb%': 1,
            'video_hole%': 1,
          }],
        ],
      }],
      ['chromecast==1 and OS!="android"', {
        'ozone_platform_cast%': 1
      }],
      ['OS=="linux" and target_arch!="mipsel"', {
        'clang%': 1,
      }],  # OS=="mac"
      ['OS=="mac"', {
        'conditions': [
          # All Chrome builds have breakpad symbols, but only process the
          # symbols from official builds.
          ['(branding=="Chrome" and buildtype=="Official")', {
            'mac_strip_release%': 1,
          }],
        ],
      }],  # OS=="mac"
      ['OS=="mac" or OS=="ios"', {
        'clang%': 1,

        'variables': {
          # Mac OS X SDK and deployment target support.  The SDK identifies
          # the version of the system headers that will be used, and
          # corresponds to the MAC_OS_X_VERSION_MAX_ALLOWED compile-time
          # macro.  "Maximum allowed" refers to the operating system version
          # whose APIs are available in the headers.  The deployment target
          # identifies the minimum system version that the built products are
          # expected to function on.  It corresponds to the
          # MAC_OS_X_VERSION_MIN_REQUIRED compile-time macro.  To ensure these
          # macros are available, #include <AvailabilityMacros.h>.  Additional
          # documentation on these macros is available at
          # http://developer.apple.com/mac/library/technotes/tn2002/tn2064.html#SECTION3
          # Chrome normally builds with the Mac OS X 10.6 SDK and sets the
          # deployment target to 10.6.  Other projects, such as O3D, may
          # override these defaults.

          # Normally, mac_sdk_min is used to find an SDK that Xcode knows
          # about that is at least the specified version. In official builds,
          # the SDK must match mac_sdk_min exactly. If the SDK is installed
          # someplace that Xcode doesn't know about, set mac_sdk_path to the
          # path to the SDK; when set to a non-empty string, SDK detection
          # based on mac_sdk_min will be bypassed entirely.
          'conditions': [
            ['OS=="ios"', {
              'mac_sdk_min%': '10.8',
            }, {  # else OS!="ios"
              'mac_sdk_min%': '10.6',
            }],
          ],
          'mac_sdk_path%': '',

          'mac_deployment_target%': '10.6',
        },

        'mac_sdk_min': '<(mac_sdk_min)',
        'mac_sdk_path': '<(mac_sdk_path)',
        'mac_deployment_target': '<(mac_deployment_target)',

        # Compile in Breakpad support by default so that it can be
        # tested, even if it is not enabled by default at runtime.
        'mac_breakpad_compiled_in%': 1,
        'conditions': [
          # mac_product_name is set to the name of the .app bundle as it should
          # appear on disk.  This duplicates data from
          # chrome/app/theme/chromium/BRANDING and
          # chrome/app/theme/google_chrome/BRANDING, but is necessary to get
          # these names into the build system.
          ['branding=="Chrome"', {
            'mac_product_name%': 'Google Chrome',
          }, { # else: branding!="Chrome"
            'mac_product_name%': 'Chromium',
          }],
          # Official mac builds require a specific OS X SDK, but iOS and
          # non-official mac builds do not.
          ['branding=="Chrome" and buildtype=="Official" and OS=="mac"', {
            'mac_sdk%': '<!(python <(DEPTH)/build/mac/find_sdk.py --verify <(mac_sdk_min) --sdk_path=<(mac_sdk_path))',
          }, {
            'mac_sdk%': '<!(python <(DEPTH)/build/mac/find_sdk.py <(mac_sdk_min))',
          }],
          ['branding=="Chrome" and buildtype=="Official"', {
            # Enable uploading crash dumps.
            'mac_breakpad_uploads%': 1,
            # Enable dumping symbols at build time for use by Mac Breakpad.
            'mac_breakpad%': 1,
            # Enable Keystone auto-update support.
            'mac_keystone%': 1,
          }, { # else: branding!="Chrome" or buildtype!="Official"
            'mac_breakpad_uploads%': 0,
            'mac_breakpad%': 0,
            'mac_keystone%': 0,
          }],
        ],
      }],  # OS=="mac" or OS=="ios"
      ['OS=="win"', {
        'conditions': [
          # This is the architecture convention used in WinSDK paths.
          ['target_arch=="ia32"', {
            'winsdk_arch%': 'x86',
          },{
            'winsdk_arch%': '<(target_arch)',
          }],
          ['component=="shared_library" or MSVS_VERSION == "2015"', {
            # TODO(scottmg): The allocator shimming doesn't work on the 2015 CRT
            # and we are hoping to be able to remove it if an additional feature
            # lands in the 2015 CRT API. For now, don't shim and revisit once
            # VS2015 is RTM: http://crbug.com/481611.
            'win_use_allocator_shim%': 0,
          }],
          ['component=="static_library"', {
            # Turn on multiple dll by default on Windows when in static_library.
            'chrome_multiple_dll%': 1,
          }],
          ['asan==1 or syzyasan==1', {
            'win_use_allocator_shim%': 0,
          }],
          ['syzyasan==1', {
            'kasko%': 1,
          }],
          ['component=="shared_library" and "<(GENERATOR)"=="ninja"', {
            # Only enabled by default for ninja because it's buggy in VS.
            # Not enabled for component=static_library because some targets
            # are too large and the toolchain fails due to the size of the
            # .obj files.
            'incremental_chrome_dll%': 1,
          }],
          # Don't do incremental linking for large modules on 32-bit or when
          # component=static_library as the toolchain fails due to the size of
          # the .ilk files.
          ['MSVS_OS_BITS==32 or component=="static_library"', {
            'msvs_large_module_debug_link_mode%': '1',  # No
          },{
            'msvs_large_module_debug_link_mode%': '2',  # Yes
          }],
        ],
        'nacl_win64_defines': [
          # This flag is used to minimize dependencies when building
          # Native Client loader for 64-bit Windows.
          'NACL_WIN64',
        ],
        # Need to include allocator target, but exclude tcmalloc files.
        'use_allocator%': 'winheap',
      }],

      ['os_posix==1 and chromeos==0 and OS!="android" and OS!="ios" and embedded==0', {
        'use_cups%': 1,
      }, {
        'use_cups%': 0,
      }],

      ['enable_plugins==1 and (OS=="linux" or OS=="mac" or OS=="win") and chromecast==0', {
        'enable_pepper_cdms%': 1,
      }, {
        'enable_pepper_cdms%': 0,
      }],

      ['OS=="android" or chromecast==1', {
        'enable_browser_cdms%': 1,
      }, {
        'enable_browser_cdms%': 0,
      }],

      # Native Client glibc toolchain is enabled
      # by default except on arm, mips and mips64.
      ['target_arch=="arm" or target_arch=="mipsel" or target_arch=="mips64el"', {
        'disable_glibc%': 1,
      }, {
        'disable_glibc%': 0,
      }],

      # Set the relative path from this file to the GYP file of the JPEG
      # library used by Chromium.
      ['use_system_libjpeg==1 or use_libjpeg_turbo==0', {
        # Configuration for using the system libjeg is here.
        'libjpeg_gyp_path': '<(libjpeg_ijg_gyp_path)',
      }, {
        'libjpeg_gyp_path': '<(libjpeg_turbo_gyp_path)',
      }],

      # Options controlling the use of GConf (the classic GNOME configuration
      # system) and GIO, which contains GSettings (the new GNOME config system).
      ['chromeos==1 or embedded==1', {
        'use_gconf%': 0,
        'use_gio%': 0,
      }, {
        'use_gconf%': 1,
        'use_gio%': 1,
      }],

      # Set up -D and -E flags passed into grit.
      ['branding=="Chrome"', {
        # TODO(mmoss) The .grd files look for _google_chrome, but for
        # consistency they should look for google_chrome_build like C++.
        'grit_defines': ['-D', '_google_chrome',
                         '-E', 'CHROMIUM_BUILD=google_chrome'],
      }, {
        'grit_defines': ['-D', '_chromium',
                         '-E', 'CHROMIUM_BUILD=chromium'],
      }],
      ['chromeos==1', {
        'grit_defines': ['-D', 'chromeos', '-D', 'scale_factors=2x'],
      }],
      ['desktop_linux==1', {
        'grit_defines': ['-D', 'desktop_linux'],
      }],
      ['toolkit_views==1', {
        'grit_defines': ['-D', 'toolkit_views'],
      }],
      ['use_aura==1', {
        'grit_defines': ['-D', 'use_aura'],
      }],
      ['use_ash==1', {
        'grit_defines': ['-D', 'use_ash'],
      }],
      ['use_nss_certs==1', {
        'grit_defines': ['-D', 'use_nss_certs'],
      }],
      ['use_ozone==1', {
        'grit_defines': ['-D', 'use_ozone'],
      }],
      ['image_loader_extension==1', {
        'grit_defines': ['-D', 'image_loader_extension'],
      }],
      ['remoting==1', {
        'grit_defines': ['-D', 'remoting'],
      }],
      ['use_titlecase_in_grd==1', {
        'grit_defines': ['-D', 'use_titlecase'],
      }],
      ['use_third_party_translations==1', {
        'grit_defines': ['-D', 'use_third_party_translations'],
        'locales': [
          'ast', 'bs', 'ca@valencia', 'en-AU', 'eo', 'eu', 'gl', 'hy', 'ia',
          'ka', 'ku', 'kw', 'ms', 'ug'
        ],
      }],
      ['OS=="android"', {
        'grit_defines': [
          '-t', 'android',
          '-E', 'ANDROID_JAVA_TAGGED_ONLY=true',
          '--no-output-all-resource-defines',
        ],
      }],
      ['OS=="mac" or OS=="ios"', {
        'grit_defines': ['-D', 'scale_factors=2x'],
      }],
      ['OS == "ios"', {
        'variables': {
          'enable_coverage%': 0,
        },
        'grit_defines': [
          '-t', 'ios',
          '--no-output-all-resource-defines',
        ],
        # iOS uses a whitelist to filter resources.
        'grit_whitelist%': '<(DEPTH)/build/ios/grit_whitelist.txt',

        # Enable host builds when generating with ninja-ios.
        'conditions': [
          ['"<(GENERATOR)"=="ninja"', {
            'host_os%': "mac",
          }],

          # Use the version of clang shipped with Xcode when building official
          # version of Chrome for iOS.
          #
          # TODO(eugenebut): Remove enable_coverage check once
          # libclang_rt.profile_ios.a is bundled with Chromium's clang.
          # http://crbug.com/450379
          ['buildtype=="Official" or enable_coverage', {
            'clang_xcode%': 1,
          }],
        ],
      }],
      ['enable_extensions==1', {
        'grit_defines': ['-D', 'enable_extensions'],
      }],
      ['enable_plugins!=0', {
        'grit_defines': ['-D', 'enable_plugins'],
      }],
      ['enable_basic_printing==1 or enable_print_preview==1', {
        'grit_defines': ['-D', 'enable_printing'],
      }],
      ['enable_print_preview==1', {
        'grit_defines': ['-D', 'enable_print_preview'],
      }],
      ['enable_themes==1', {
        'grit_defines': ['-D', 'enable_themes'],
      }],
      ['enable_app_list==1', {
        'grit_defines': ['-D', 'enable_app_list'],
      }],
      ['enable_settings_app==1', {
        'grit_defines': ['-D', 'enable_settings_app'],
      }],
      ['enable_google_now==1', {
        'grit_defines': ['-D', 'enable_google_now'],
      }],
      ['use_concatenated_impulse_responses==1', {
        'grit_defines': ['-D', 'use_concatenated_impulse_responses'],
      }],
      ['enable_media_router==1', {
        'grit_defines': ['-D', 'enable_media_router'],
      }],
      ['enable_webrtc==1', {
        'grit_defines': ['-D', 'enable_webrtc'],
      }],
      ['enable_hangout_services_extension==1', {
        'grit_defines': ['-D', 'enable_hangout_services_extension'],
      }],
      ['enable_task_manager==1', {
        'grit_defines': ['-D', 'enable_task_manager'],
      }],
      ['notifications==1', {
        'grit_defines': ['-D', 'enable_notifications'],
      }],
      ['enable_wifi_bootstrapping==1', {
        'grit_defines': ['-D', 'enable_wifi_bootstrapping'],
      }],
      ['mac_views_browser==1', {
        'grit_defines': ['-D', 'mac_views_browser'],
      }],
      ['enable_resource_whitelist_generation==1 and OS!="win"', {
        'grit_rc_header_format': ['-h', '#define {textual_id} _Pragma("whitelisted_resource_{numeric_id}") {numeric_id}'],
      }],
      ['enable_resource_whitelist_generation==1 and OS=="win"', {
        'grit_rc_header_format': ['-h', '#define {textual_id} __pragma(message("whitelisted_resource_{numeric_id}")) {numeric_id}'],
      }],
      ['enable_mdns==1 or OS=="mac"', {
        'grit_defines': ['-D', 'enable_service_discovery'],
        'enable_service_discovery%': 1
      }],
      ['clang_use_chrome_plugins==1', {
        'variables': {
          'conditions': [
            ['OS!="win"', {
              'variables': {
                'conditions': [
                  ['OS=="mac" or OS=="ios"', {
                    'clang_lib_path%': '<!(cd <(DEPTH) && pwd -P)/third_party/llvm-build/Release+Asserts/lib/libFindBadConstructs.dylib',
                  }, { # OS != "mac" or OS != "ios"
                    'clang_lib_path%': '<!(cd <(DEPTH) && pwd -P)/third_party/llvm-build/Release+Asserts/lib/libFindBadConstructs.so',
                  }],
                ],
              },
              'clang_dynlib_flags%': '-Xclang -load -Xclang <(clang_lib_path) ',
            }, { # OS == "win"
              # On Windows, the plugin is built directly into clang, so there's
              # no need to load it dynamically.
              'clang_dynlib_flags%': '',
            }],
            # https://crbug.com/441916
            ['OS=="android" or OS=="linux" or OS=="mac"', {
              'clang_plugin_args%': '-Xclang -plugin-arg-find-bad-constructs -Xclang check-templates ',
            }, { # OS != "linux"
              'clang_plugin_args%': ''
            }],
          ],
        },
        # If you change these, also change build/config/clang/BUILD.gn.
        'clang_chrome_plugins_flags%':
          '<(clang_dynlib_flags)'
          '-Xclang -add-plugin -Xclang find-bad-constructs <(clang_plugin_args)',
      }],
      ['asan==1 or msan==1 or lsan==1 or tsan==1', {
        'clang%': 1,
        'use_allocator%': 'none',
        'use_sanitizer_options%': 1,
      }],

      # Allowed level of identical code folding in the gold linker.
      ['OS=="linux" and target_arch=="x64"', {
        # --icf=safe disables much more folding on x86_64 than elsewhere, see
        # http://crbug.com/492177.  Turning it on saves over 12 MB of binary
        # size, but it seems to regress cold startup time by over a second
        # (see http://crbug.com/492809).
        # TODO(thakis): Check if disabling ICF would inmprove android cold start
        # times by several seconds too.
        'gold_icf_level%': 'safe',
      }, {
        'gold_icf_level%': 'all',
      }],

      ['OS=="linux" and asan==0 and msan==0 and lsan==0 and tsan==0', {
        # PNaCl toolchain Non-SFI build only supports linux OS build.
        # Also, it does not support sanitizers.
        'enable_nacl_nonsfi_test%': 1,
      }],
      ['asan==1 and OS=="linux" and chromeos==0', {
        'use_custom_libcxx%': 1,
      }],
      ['ubsan==1', {
        'clang%': 1,
      }],
      ['ubsan_vptr==1', {
        'clang%': 1,
      }],
      ['asan==1 and OS=="mac"', {
        'mac_strip_release': 1,
      }],
      ['tsan==1', {
        'use_custom_libcxx%': 1,
      }],
      ['msan==1', {
        # Use a just-built, MSan-instrumented libc++ instead of the system-wide
        # libstdc++. This is required to avoid false positive reports whenever
        # the C++ standard library is used.
        'use_custom_libcxx%': 1,
        # Running the V8-generated code on an ARM simulator is a powerful hack
        # that allows the tool to see the memory accesses from JITted code.
        # Without this flag, JS code causes false positive reports from MSan.
        'v8_target_arch': 'arm64',
      }],

      ['OS=="linux" and clang_type_profiler==1', {
        'clang%': 1,
        'clang_use_chrome_plugins%': 0,
        'conditions': [
          ['host_arch=="x64"', {
            'make_clang_dir%': 'third_party/llvm-allocated-type/Linux_x64',
          }],
          ['host_arch=="ia32"', {
            # 32-bit Clang is unsupported.  It may not build.  Put your 32-bit
            # Clang in this directory at your own risk if needed for some
            # purpose (e.g. to compare 32-bit and 64-bit behavior like memory
            # usage).  Any failure by this compiler should not close the tree.
            'make_clang_dir%': 'third_party/llvm-allocated-type/Linux_ia32',
          }],
        ],
      }],

      # On valgrind bots, override the optimizer settings so we don't inline too
      # much and make the stacks harder to figure out.
      #
      # TODO(rnk): Kill off variables that no one else uses and just implement
      # them under a build_for_tool== condition.
      ['build_for_tool=="memcheck" or build_for_tool=="tsan"', {
        # gcc flags
        'mac_debug_optimization': '1',
        'mac_release_optimization': '1',
        'release_optimize': '1',
        'no_gc_sections': 1,
        'debug_extra_cflags': '-g -fno-inline -fno-omit-frame-pointer '
                              '-fno-builtin -fno-optimize-sibling-calls',
        'release_extra_cflags': '-g -fno-inline -fno-omit-frame-pointer '
                                '-fno-builtin -fno-optimize-sibling-calls',

        # MSVS flags for TSan on Pin and Windows.
        'win_debug_RuntimeChecks': '0',
        'win_debug_disable_iterator_debugging': '1',
        'win_debug_Optimization': '1',
        'win_debug_InlineFunctionExpansion': '0',
        'win_release_InlineFunctionExpansion': '0',
        'win_release_OmitFramePointers': '0',

        'use_allocator': 'tcmalloc',
        'release_valgrind_build': 1,
        'werror': '',
        'component': 'static_library',
        'use_system_zlib': 0,
      }],

      # Build tweaks for DrMemory.
      # TODO(rnk): Combine with tsan config to share the builder.
      # http://crbug.com/108155
      ['build_for_tool=="drmemory"', {
        # These runtime checks force initialization of stack vars which blocks
        # DrMemory's uninit detection.
        'win_debug_RuntimeChecks': '0',
        # Iterator debugging is slow.
        'win_debug_disable_iterator_debugging': '1',
        # Try to disable optimizations that mess up stacks in a release build.
        # DrM-i#1054 (https://github.com/DynamoRIO/drmemory/issues/1054)
        # /O2 and /Ob0 (disable inline) cannot be used together because of a
        # compiler bug, so we use /Ob1 instead.
        'win_release_InlineFunctionExpansion': '1',
        'win_release_OmitFramePointers': '0',
        # Ditto for debug, to support bumping win_debug_Optimization.
        'win_debug_InlineFunctionExpansion': 0,
        'win_debug_OmitFramePointers': 0,
        # Keep the code under #ifndef NVALGRIND.
        'release_valgrind_build': 1,
      }],

      # Enable RLZ on Win, Mac, iOS and ChromeOS.
      ['branding=="Chrome" and (OS=="win" or OS=="mac" or OS=="ios" or chromeos==1)', {
        'enable_rlz%': 1,
      }],

      # Set default compiler flags depending on ARM version.
      ['arm_version==6', {
        'arm_arch%': 'armv6',
        'arm_tune%': '',
        'arm_fpu%': 'vfp',
        'arm_float_abi%': 'softfp',
        'arm_thumb%': 0,
      }],
      ['arm_version==7', {
        'arm_arch%': 'armv7-a',
        'arm_tune%': 'generic-armv7-a',
        'conditions': [
          ['arm_neon==1', {
            'arm_fpu%': 'neon',
          }, {
            'arm_fpu%': 'vfpv3-d16',
          }],
          ['OS=="android"', {
            'arm_float_abi%': 'softfp',
          }, {
            'arm_float_abi%': 'hard',
          }],
        ],
        'arm_thumb%': 1,
      }],

      # Set default compiler flags for MIPS floating-point support.
      ['target_arch=="mipsel"', {
        'mips_float_abi%': 'hard',
      }],
      ['target_arch=="mipsel" and mips_arch_variant=="r2"', {
        'mips_fpu_mode%': 'fp32',
      }],

      # Enable brlapi by default for chromeos.
      [ 'chromeos==1', {
        'use_brlapi%': 1,
      }],

      ['use_ozone==1 and ozone_auto_platforms==1', {
        # Use test as the default platform.
        'ozone_platform%': 'test',

        # Build all platforms whose deps are in install-build-deps.sh.
        # Only these platforms will be compile tested by buildbots.
        'ozone_platform_dri%': 1,
        'ozone_platform_drm%': 1,
        'ozone_platform_test%': 1,
        'ozone_platform_egltest%': 1,
      }],

      ['desktop_linux==1 and use_aura==1 and use_x11==1', {
        'use_clipboard_aurax11%': 1,
      }],

      ['OS=="win" and use_goma==1', {
        # goma doesn't support pch yet.
        'chromium_win_pch': 0,
        # goma doesn't support PDB yet, so win_z7=1 or fastbuild=1.
        'conditions': [
          ['win_z7==0 and fastbuild==0', {
            'fastbuild': 1,
          }],
        ],
      }],

      ['OS=="win" and (clang==1 or asan==1)', {
        'chromium_win_pch': 0,
      }],

      ['host_clang==1', {
        'host_cc': '<(make_clang_dir)/bin/clang',
        'host_cxx': '<(make_clang_dir)/bin/clang++',
      }, {
        'host_cc': '<!(which gcc)',
        'host_cxx': '<!(which g++)',
      }],

      # The seccomp-bpf sandbox is only supported on five architectures
      # currently.
      # Do not disable seccomp_bpf anywhere without talking to
      # security@chromium.org!
      ['((OS=="linux" or OS=="android") and '
           '(target_arch=="ia32" or target_arch=="x64" or '
             'target_arch=="arm" or target_arch=="mipsel" or '
             'target_arch=="arm64"))', {
         'use_seccomp_bpf%': 1,
      }, {
         'use_seccomp_bpf%': 0,
      }],

      ['cfi_vptr==1', {
        'use_lto%': 1,
      }],

      ['branding=="Chrome" and buildtype=="Official"', {
        'enable_hangout_services_extension%': 1,
      }, {
        'enable_hangout_services_extension%': 0,
      }],
    ],

    # The path to the ANGLE library.
    'angle_path': '<(DEPTH)/third_party/angle',

    # List of default apps to install in new profiles.  The first list contains
    # the source files as found in svn.  The second list, used only for linux,
    # contains the destination location for each of the files.  When a crx
    # is added or removed from the list, the chrome/browser/resources/
    # default_apps/external_extensions.json file must also be updated.
    #
    # README: GN version of these is in the target //chrome:default_apps
    # (there's no global variable like in GYP). Be sure to update that target
    # if you change these lists!
    'default_apps_list': [
      'browser/resources/default_apps/external_extensions.json',
      'browser/resources/default_apps/gmail.crx',
      'browser/resources/default_apps/search.crx',
      'browser/resources/default_apps/youtube.crx',
      'browser/resources/default_apps/drive.crx',
      'browser/resources/default_apps/docs.crx',
    ],
    'default_apps_list_linux_dest': [
      '<(PRODUCT_DIR)/default_apps/external_extensions.json',
      '<(PRODUCT_DIR)/default_apps/gmail.crx',
      '<(PRODUCT_DIR)/default_apps/search.crx',
      '<(PRODUCT_DIR)/default_apps/youtube.crx',
      '<(PRODUCT_DIR)/default_apps/drive.crx',
      '<(PRODUCT_DIR)/default_apps/docs.crx',
    ],

    # Whether to allow building of the GPU-related isolates.
    'archive_gpu_tests%': 0,

     # Whether to allow building of chromoting related isolates.
    'archive_chromoting_tests%': 0,
  },
  'target_defaults': {
    'variables': {
      # The condition that operates on chromium_code is in a target_conditions
      # section, and will not have access to the default fallback value of
      # chromium_code at the top of this file, or to the chromium_code
      # variable placed at the root variables scope of .gyp files, because
      # those variables are not set at target scope.  As a workaround,
      # if chromium_code is not set at target scope, define it in target scope
      # to contain whatever value it has during early variable expansion.
      # That's enough to make it available during target conditional
      # processing.
      'chromium_code%': '<(chromium_code)',

      'component%': '<(component)',

      'chromecast%': '<(chromecast)',

      # See http://msdn.microsoft.com/en-us/library/aa652360(VS.71).aspx
      'win_release_Optimization%': '2', # 2 = /O2
      'win_debug_Optimization%': '0',   # 0 = /Od

      # See http://msdn.microsoft.com/en-us/library/2kxx5t2c(v=vs.80).aspx
      # Tri-state: blank is default, 1 on, 0 off
      'win_release_OmitFramePointers%': '0',
      # Tri-state: blank is default, 1 on, 0 off
      'win_debug_OmitFramePointers%': '',

      # See http://msdn.microsoft.com/en-us/library/8wtf2dfz(VS.71).aspx
      'win_debug_RuntimeChecks%': '3',    # 3 = all checks enabled, 0 = off

      # See http://msdn.microsoft.com/en-us/library/47238hez(VS.71).aspx
      'win_debug_InlineFunctionExpansion%': '',    # empty = default, 0 = off,
      'win_release_InlineFunctionExpansion%': '2', # 1 = only __inline, 2 = max

      # VS inserts quite a lot of extra checks to algorithms like
      # std::partial_sort in Debug build which make them O(N^2)
      # instead of O(N*logN). This is particularly slow under memory
      # tools like ThreadSanitizer so we want it to be disablable.
      # See http://msdn.microsoft.com/en-us/library/aa985982(v=VS.80).aspx
      'win_debug_disable_iterator_debugging%': '0',

      # An application manifest fragment to declare compatibility settings for
      # 'executable' targets. Ignored in other target type.
      'win_exe_compatibility_manifest%':
          '<(DEPTH)\\build\\win\\compatibility.manifest',

      'release_extra_cflags%': '',
      'debug_extra_cflags%': '',

      'release_valgrind_build%': '<(release_valgrind_build)',

      # the non-qualified versions are widely assumed to be *nix-only
      'win_release_extra_cflags%': '',
      'win_debug_extra_cflags%': '',

      # TODO(thakis): Make this a blacklist instead, http://crbug.com/101600
      'enable_wexit_time_destructors%': '<(enable_wexit_time_destructors)',

      # Only used by Windows build for now.  Can be used to build into a
      # differet output directory, e.g., a build_dir_prefix of VS2010_ would
      # output files in src/build/VS2010_{Debug,Release}.
      'build_dir_prefix%': '',

      # Targets are by default not nacl untrusted code.
      'nacl_untrusted_build%': 0,

      'pnacl_compile_flags': [
        # pnacl uses the clang compiler so we need to suppress all the
        # same warnings as we do for clang.
        # TODO(sbc): Remove these if/when they are removed from the clang
        # build.
        '-Wno-unused-function',
        '-Wno-char-subscripts',
        '-Wno-c++11-extensions',
        '-Wno-unnamed-type-template-args',
      ],

      # By default, Android targets have their exported JNI symbols stripped,
      # so we test the manual JNI registration code paths that are required
      # when using the crazy linker. To allow use of native JNI exports (lazily
      # resolved by the JVM), targets can enable this variable, which will stop
      # the stripping from happening. Only targets which do not need to be
      # compatible with the crazy linker are permitted to set this.
      'use_native_jni_exports%': 0,

      'conditions': [
        ['OS=="win" and component=="shared_library"', {
          # See http://msdn.microsoft.com/en-us/library/aa652367.aspx
          'win_release_RuntimeLibrary%': '2', # 2 = /MD (nondebug DLL)
          'win_debug_RuntimeLibrary%': '3',   # 3 = /MDd (debug DLL)
        }, {
          # See http://msdn.microsoft.com/en-us/library/aa652367.aspx
          'win_release_RuntimeLibrary%': '0', # 0 = /MT (nondebug static)
          'win_debug_RuntimeLibrary%': '1',   # 1 = /MTd (debug static)
        }],
        ['OS=="ios"', {
          # See http://gcc.gnu.org/onlinedocs/gcc-4.4.2/gcc/Optimize-Options.html
          'mac_release_optimization%': 's', # Use -Os unless overridden
          'mac_debug_optimization%': '0',   # Use -O0 unless overridden
        }, {
          # See http://gcc.gnu.org/onlinedocs/gcc-4.4.2/gcc/Optimize-Options.html
          'mac_release_optimization%': '2', # Use -O2 unless overridden
          'mac_debug_optimization%': '0',   # Use -O0 unless overridden
        }],
        ['OS=="android"', {
          'host_os%': '<(host_os)',  # See comment above chromium_code.
        }],
      ],
      'clang_warning_flags': [
        '-Wheader-hygiene',

        # Don't die on dtoa code that uses a char as an array index.
        # This is required solely for base/third_party/dmg_fp/dtoa.cc.
        '-Wno-char-subscripts',

        # TODO(thakis): This used to be implied by -Wno-unused-function,
        # which we no longer use. Check if it makes sense to remove
        # this as well. http://crbug.com/316352
        '-Wno-unneeded-internal-declaration',

        # Warns on switches on enums that cover all enum values but
        # also contain a default: branch. Chrome is full of that.
        '-Wno-covered-switch-default',

        # Warns when a const char[] is converted to bool.
        '-Wstring-conversion',

        # C++11-related flags:

        # This warns on using ints as initializers for floats in
        # initializer lists (e.g. |int a = f(); CGSize s = { a, a };|),
        # which happens in several places in chrome code. Not sure if
        # this is worth fixing.
        '-Wno-c++11-narrowing',

        # Clang considers the `register` keyword as deprecated, but e.g.
        # code generated by flex (used in angle) contains that keyword.
        # http://crbug.com/255186
        '-Wno-deprecated-register',

        # TODO(hans): Get this cleaned up.
        '-Wno-inconsistent-missing-override',
      ],
    },
    'includes': [ 'set_clang_warning_flags.gypi', ],
    'defines': [
      # Don't use deprecated V8 APIs anywhere.
      'V8_DEPRECATION_WARNINGS',
    ],
    'include_dirs': [
      '<(SHARED_INTERMEDIATE_DIR)',
    ],
    'conditions': [
      ['OS=="mac"', {
        # When compiling Objective C, warns if a method is used whose
        # availability is newer than the deployment target.
        'xcode_settings': { 'WARNING_CFLAGS': ['-Wpartial-availability']},
      }],
      ['(OS=="mac" or OS=="ios") and asan==1', {
        'dependencies': [
          '<(DEPTH)/build/mac/asan.gyp:asan_dynamic_runtime',
        ],
      }],
      ['OS=="win" and asan==1 and component=="shared_library"', {
        'dependencies': [
          '<(DEPTH)/build/win/asan.gyp:asan_dynamic_runtime',
        ],
      }],
      ['OS=="linux" and use_allocator!="none" and clang_type_profiler==1', {
        'cflags_cc!': ['-fno-rtti'],
        'cflags_cc+': [
          '-frtti',
          '-gline-tables-only',
          '-fintercept-allocation-functions',
        ],
        'defines': ['TYPE_PROFILING'],
        'dependencies': [
          '<(DEPTH)/base/allocator/allocator.gyp:type_profiler',
        ],
      }],
      ['branding=="Chrome"', {
        'defines': ['GOOGLE_CHROME_BUILD'],
      }, {  # else: branding!="Chrome"
        'defines': ['CHROMIUM_BUILD'],
      }],
      ['OS=="mac" and component=="shared_library"', {
        'xcode_settings': {
          'DYLIB_INSTALL_NAME_BASE': '@rpath',
          'LD_RUNPATH_SEARCH_PATHS': [
            # For unbundled binaries.
            '@loader_path/.',
            # For bundled binaries, to get back from Binary.app/Contents/MacOS.
            '@loader_path/../../..',
          ],
        },
      }],
      ['clang==1 or host_clang==1', {
        # This is here so that all files get recompiled after a clang roll and
        # when turning clang on or off.
        # (defines are passed via the command line, and build systems rebuild
        # things when their commandline changes). Nothing should ever read this
        # define.
        'defines': ['CR_CLANG_REVISION=<!(python <(DEPTH)/tools/clang/scripts/update.py --print-revision)'],
      }],
      ['enable_rlz==1', {
        'defines': ['ENABLE_RLZ'],
      }],
      ['component=="shared_library"', {
        'defines': ['COMPONENT_BUILD'],
      }],
      ['toolkit_views==1', {
        'defines': ['TOOLKIT_VIEWS=1'],
      }],
      ['ui_compositor_image_transport==1', {
        'defines': ['UI_COMPOSITOR_IMAGE_TRANSPORT'],
      }],
      ['use_aura==1', {
        'defines': ['USE_AURA=1'],
      }],
      ['use_ash==1', {
        'defines': ['USE_ASH=1'],
      }],
      ['use_pango==1', {
        'defines': ['USE_PANGO=1'],
      }],
      ['use_cairo==1', {
        'defines': ['USE_CAIRO=1'],
      }],
      ['use_cras==1', {
        'defines': ['USE_CRAS=1'],
      }],
      ['use_ozone==1', {
        'defines': ['USE_OZONE=1'],
      }],
      ['use_default_render_theme==1', {
        'defines': ['USE_DEFAULT_RENDER_THEME=1'],
      }],
      ['use_libjpeg_turbo==1', {
        'defines': ['USE_LIBJPEG_TURBO=1'],
      }],
      ['use_x11==1', {
        'defines': ['USE_X11=1'],
      }],
      ['use_clipboard_aurax11==1', {
        'defines': ['USE_CLIPBOARD_AURAX11=1'],
      }],
      ['enable_one_click_signin==1', {
        'defines': ['ENABLE_ONE_CLICK_SIGNIN'],
      }],
      ['enable_pre_sync_backup==1', {
        'defines': ['ENABLE_PRE_SYNC_BACKUP'],
      }],
      ['image_loader_extension==1', {
        'defines': ['IMAGE_LOADER_EXTENSION=1'],
      }],
      ['profiling==1', {
        'defines': ['ENABLE_PROFILING=1'],
      }],
      ['remoting==1', {
        'defines': ['ENABLE_REMOTING=1'],
      }],
      ['enable_webrtc==1', {
        'defines': ['ENABLE_WEBRTC=1'],
      }],
      ['enable_media_router==1', {
        'defines': ['ENABLE_MEDIA_ROUTER=1'],
      }],
      ['proprietary_codecs==1', {
        'defines': ['USE_PROPRIETARY_CODECS'],
        'conditions': [
          ['enable_mpeg2ts_stream_parser==1', {
            'defines': ['ENABLE_MPEG2TS_STREAM_PARSER'],
          }],
        ],
      }],
      ['enable_viewport==1', {
        'defines': ['ENABLE_VIEWPORT'],
      }],
      ['enable_pepper_cdms==1', {
        'defines': ['ENABLE_PEPPER_CDMS'],
      }],
      ['enable_browser_cdms==1', {
        'defines': ['ENABLE_BROWSER_CDMS'],
      }],
      ['configuration_policy==1', {
        'defines': ['ENABLE_CONFIGURATION_POLICY'],
      }],
      ['notifications==1', {
        'defines': ['ENABLE_NOTIFICATIONS'],
      }],
      ['enable_hidpi==1', {
        'defines': ['ENABLE_HIDPI=1'],
      }],
      ['enable_topchrome_md==1', {
        'defines': ['ENABLE_TOPCHROME_MD=1'],
      }],
      ['native_memory_pressure_signals==1', {
        'defines': ['SYSTEM_NATIVELY_SIGNALS_MEMORY_PRESSURE'],
      }],
      ['use_udev==1', {
        'defines': ['USE_UDEV'],
      }],
      ['fastbuild!=0', {
        'xcode_settings': {
          'GCC_GENERATE_DEBUGGING_SYMBOLS': 'NO',
        },
        'conditions': [
          ['OS=="win" and fastbuild==2', {
            # Completely disable debug information.
            'msvs_settings': {
              'VCLinkerTool': {
                'GenerateDebugInformation': 'false',
              },
              'VCCLCompilerTool': {
                'DebugInformationFormat': '0',
              },
            },
          }],
          ['OS=="win" and fastbuild==1', {
            'msvs_settings': {
              'VCLinkerTool': {
                # This tells the linker to generate .pdbs, so that
                # we can get meaningful stack traces.
                'GenerateDebugInformation': 'true',
              },
              'VCCLCompilerTool': {
                # No debug info to be generated by compiler.
                'DebugInformationFormat': '0',
              },
            },
          }],
          ['(OS=="android" or OS=="linux") and fastbuild==2', {
            'variables': { 'debug_extra_cflags': '-g0', },
          }],
          ['(OS=="android" or OS=="linux") and fastbuild==1', {
            # TODO(thakis): Change this to -g1 once http://crbug.com/456947 is
            # fixed.
            'variables': { 'debug_extra_cflags': '-g0', },
          }],
          # Android builds symbols on release by default, disable them.
          ['OS=="android" and fastbuild==2', {
            'variables': { 'release_extra_cflags': '-g0', },
          }],
          ['OS=="android" and fastbuild==1', {
            # TODO(thakis): Change this to -g1 once http://crbug.com/456947 is
            # fixed.
            'variables': { 'release_extra_cflags': '-g0', },
          }],
        ],
      }],  # fastbuild!=0
      ['dont_embed_build_metadata==1', {
        'defines': [
          'DONT_EMBED_BUILD_METADATA',
        ],
      }],  # dont_embed_build_metadata==1
      ['dcheck_always_on!=0', {
        'defines': ['DCHECK_ALWAYS_ON=1'],
      }],  # dcheck_always_on!=0
      ['tracing_like_official_build!=0', {
        'defines': ['TRACING_IS_OFFICIAL_BUILD=1'],
      }],  # tracing_like_official_build!=0
      ['OS=="win"', {
        'defines': ['NO_TCMALLOC'],
        'conditions': [
          ['win_use_allocator_shim==1', {
            'defines': ['ALLOCATOR_SHIM'],
          }],
        ],
      }],
      ['asan==1', {
        'defines': [
          'ADDRESS_SANITIZER',
          'MEMORY_TOOL_REPLACES_ALLOCATOR',
          'MEMORY_SANITIZER_INITIAL_SIZE',
        ],
      }],
      ['syzyasan==1', {
        # SyzyAsan needs /PROFILE turned on to produce appropriate pdbs.
        'msvs_settings': {
          'VCLinkerTool': {
            'Profile': 'true',
          },
        },
        'defines': [
            'SYZYASAN',
            'MEMORY_TOOL_REPLACES_ALLOCATOR',
            'MEMORY_SANITIZER_INITIAL_SIZE',
        ],
      }],
      ['kasko==1', {
        'defines': [
            'KASKO',
        ],
        'include_dirs': [
          '<(DEPTH)/third_party/kasko/include',
        ],
      }],
      ['OS=="win"', {
        'defines': [
          '__STD_C',
          '_CRT_SECURE_NO_DEPRECATE',
          '_SCL_SECURE_NO_DEPRECATE',
          # This define is required to pull in the new Win8 interfaces from
          # system headers like ShObjIdl.h.
          'NTDDI_VERSION=0x06030000',
          # This is required for ATL to use XP-safe versions of its functions.
          '_USING_V110_SDK71_',
        ],
        'include_dirs': [
          '<(DEPTH)/third_party/wtl/include',
        ],
        'conditions': [
          ['win_z7!=0', {
            'msvs_settings': {
              # Generates debug info when win_z7=1
              # even if fastbuild=1 (that makes GenerateDebugInformation false).
              'VCLinkerTool': {
                'GenerateDebugInformation': 'true',
              },
              'VCCLCompilerTool': {
                'DebugInformationFormat': '1',
              }
            }
          }],  # win_z7!=0
          ['win_analyze', {
            'defines!': [
              # This is prohibited when running /analyze.
              '_USING_V110_SDK71_',
            ],
            'msvs_settings': {
              'VCCLCompilerTool': {
                # Set WarnAsError to false to disable this setting for most
                # projects so that compilation continues.
                'WarnAsError': 'false',
                # When win_analyze is specified add the /analyze switch.
                # Also add /WX- to force-disable WarnAsError for projects that
                # override WarnAsError.
                # Also, disable various noisy warnings that have low value.
                'AdditionalOptions': [
                  '/analyze',
                  '/WX-',
                  '/wd6011',  # Dereferencing NULL pointer
                  '/wd6312',  # Possible infinite loop: use of the constant
                    # EXCEPTION_CONTINUE_EXECUTION in the exception-filter
                  '/wd6326',  # Potential comparison of constant with constant
                  '/wd28159', # Consider using 'GetTickCount64'
                  '/wd28204', # Inconsistent SAL annotations
                  '/wd28251', # Inconsistent SAL annotations
                  '/wd28252', # Inconsistent SAL annotations
                  '/wd28253', # Inconsistent SAL annotations
                  '/wd28196', # The precondition is not satisfied
                  '/wd28301', # Inconsistent SAL annotations
                  '/wd6340',  # Sign mismatch in function parameter
                  '/wd28182', # Dereferencing NULL pointer
                  # C6285 is ~16% of raw warnings and has low value
                  '/wd6285',  # non-zero constant || non-zero constant
                  # C6334 is ~80% of raw warnings and has low value
                  '/wd6334',  # sizeof applied to an expression with an operator
                ],
              },
            },
          }],  # win_analyze
        ],
      }],  # OS==win
      ['chromecast==1', {
        'defines': [
          'LOG_DISABLED=0',
        ],
        'conditions': [
          ['use_playready==1', {
            'defines': [
              'PLAYREADY_CDM_AVAILABLE',
            ],
          }],
        ],
      }],
      ['enable_task_manager==1', {
        'defines': [
          'ENABLE_TASK_MANAGER=1',
        ],
      }],
      ['enable_extensions==1', {
        'defines': [
          'ENABLE_EXTENSIONS=1',
        ],
      }],
      ['OS=="win" and branding=="Chrome"', {
        'defines': ['ENABLE_SWIFTSHADER'],
      }],
      ['enable_dart==1', {
        'defines': ['WEBKIT_USING_DART=1'],
      }],
      ['enable_plugin_installation==1', {
        'defines': ['ENABLE_PLUGIN_INSTALLATION=1'],
      }],
      ['enable_plugins==1', {
        'defines': ['ENABLE_PLUGINS=1'],
      }],
      ['enable_session_service==1', {
        'defines': ['ENABLE_SESSION_SERVICE=1'],
      }],
      ['enable_themes==1', {
        'defines': ['ENABLE_THEMES=1'],
      }],
      ['enable_autofill_dialog==1', {
        'defines': ['ENABLE_AUTOFILL_DIALOG=1'],
      }],
      ['enable_prod_wallet_service==1', {
        # In GN, this is set on the autofill tagets only. See
        # //components/autofill/core/browser:wallet_service
        'defines': ['ENABLE_PROD_WALLET_SERVICE=1'],
      }],
      ['enable_background==1', {
        'defines': ['ENABLE_BACKGROUND=1'],
      }],
      ['enable_google_now==1', {
        'defines': ['ENABLE_GOOGLE_NOW=1'],
      }],
      ['cld_version!=0', {
        'defines': ['CLD_VERSION=<(cld_version)'],
      }],
      ['enable_basic_printing==1 or enable_print_preview==1', {
        # Convenience define for ENABLE_BASIC_PRINTING || ENABLE_PRINT_PREVIEW.
        'defines': ['ENABLE_PRINTING=1'],
      }],
      ['enable_basic_printing==1', {
        # Enable basic printing support and UI.
        'defines': ['ENABLE_BASIC_PRINTING=1'],
      }],
      ['enable_print_preview==1', {
        # Enable printing with print preview.
        # Can be defined without ENABLE_BASIC_PRINTING.
        'defines': ['ENABLE_PRINT_PREVIEW=1'],
      }],
      ['enable_spellcheck==1', {
        'defines': ['ENABLE_SPELLCHECK=1'],
      }],
      ['enable_captive_portal_detection==1', {
        'defines': ['ENABLE_CAPTIVE_PORTAL_DETECTION=1'],
      }],
      ['enable_app_list==1', {
        'defines': ['ENABLE_APP_LIST=1'],
      }],
      ['enable_settings_app==1', {
        'defines': ['ENABLE_SETTINGS_APP=1'],
      }],
      ['disable_file_support==1', {
        'defines': ['DISABLE_FILE_SUPPORT=1'],
      }],
      ['disable_ftp_support==1', {
        'defines': ['DISABLE_FTP_SUPPORT=1'],
      }],
      ['enable_supervised_users==1', {
        'defines': ['ENABLE_SUPERVISED_USERS=1'],
      }],
      ['enable_mdns==1', {
        'defines': ['ENABLE_MDNS=1'],
      }],
      ['enable_service_discovery==1', {
        'defines' : [ 'ENABLE_SERVICE_DISCOVERY=1' ],
      }],
      ['enable_wifi_bootstrapping==1', {
        'defines' : [ 'ENABLE_WIFI_BOOTSTRAPPING=1' ],
      }],
      ['enable_hangout_services_extension==1', {
        'defines': ['ENABLE_HANGOUT_SERVICES_EXTENSION=1'],
      }],
      ['enable_ipc_fuzzer==1', {
        'defines': ['ENABLE_IPC_FUZZER=1'],
      }],
      ['video_hole==1', {
        'defines': ['VIDEO_HOLE=1'],
      }],
      ['v8_use_external_startup_data==1', {
       'defines': ['V8_USE_EXTERNAL_STARTUP_DATA'],
      }],

      # SAFE_BROWSING_SERVICE - browser manages a safe-browsing service.
      # SAFE_BROWSING_DB_LOCAL - service manages a local database.
      # SAFE_BROWSING_DB_REMOTE - service talks via API to a database
      # SAFE_BROWSING_CSD - enable client-side phishing detection.
      ['safe_browsing==1', {
        'defines': [
          # TODO(nparker): Remove existing uses of FULL_SAFE_BROWSING
          'FULL_SAFE_BROWSING',
          'SAFE_BROWSING_CSD',
          'SAFE_BROWSING_DB_LOCAL',
          'SAFE_BROWSING_SERVICE',
        ],
      }],
      ['safe_browsing==2', {
        'defines': [
          # TODO(nparker): Remove existing uses of MOBILE_SAFE_BROWSING
          'MOBILE_SAFE_BROWSING',
          'SAFE_BROWSING_SERVICE',
        ],
      }],
      ['safe_browsing==3', {
        'defines': [
          # TODO(nparker): Remove existing uses of MOBILE_SAFE_BROWSING
          'MOBILE_SAFE_BROWSING',
          'SAFE_BROWSING_DB_REMOTE',
          'SAFE_BROWSING_SERVICE',
        ],
      }],
    ],  # conditions for 'target_defaults'
    'target_conditions': [
      ['<(use_libpci)==1', {
        'defines': ['USE_LIBPCI=1'],
      }],
      ['<(use_openssl)==1', {
        'defines': ['USE_OPENSSL=1'],
      }],
      ['<(use_openssl_certs)==1', {
        'defines': ['USE_OPENSSL_CERTS=1'],
      }],
      ['>(nacl_untrusted_build)==1', {
        'defines': [
          'USE_OPENSSL=1',
          'USE_OPENSSL_CERTS=1',
        ],
      }],
      ['<(use_glib)==1 and >(nacl_untrusted_build)==0', {
        'defines': ['USE_GLIB=1'],
      }],
      ['<(use_nss_certs)==1 and >(nacl_untrusted_build)==0', {
        'defines': ['USE_NSS_CERTS=1'],
      }],
      ['<(chromeos)==1 and >(nacl_untrusted_build)==0', {
        'defines': ['OS_CHROMEOS=1'],
      }],
      ['enable_wexit_time_destructors==1 and OS!="win"', {
        # TODO: Enable on Windows too, http://crbug.com/404525
        'variables': { 'clang_warning_flags': ['-Wexit-time-destructors']},
      }],
      ['chromium_code==0', {
        'conditions': [
          [ 'os_posix==1 and OS!="mac" and OS!="ios"', {
            # We don't want to get warnings from third-party code,
            # so remove any existing warning-enabling flags like -Wall.
            'cflags!': [
              '-Wall',
              '-Wextra',
            ],
            'cflags_cc': [
              # Don't warn about hash_map in third-party code.
              '-Wno-deprecated',
            ],
            'cflags': [
              # Don't warn about printf format problems.
              # This is off by default in gcc but on in Ubuntu's gcc(!).
              '-Wno-format',
            ],
            'cflags_cc!': [
              # Necessary because llvm.org/PR10448 is WONTFIX (crbug.com/90453).
              '-Wsign-compare',
            ]
          }],
          # TODO: Fix all warnings on chromeos too.
          [ 'os_posix==1 and OS!="mac" and OS!="ios" and (clang!=1 or chromeos==1)', {
            'cflags!': [
              '-Werror',
            ],
          }],
          [ 'os_posix==1 and os_bsd!=1 and OS!="mac" and OS!="android"', {
            'cflags': [
              # Don't warn about ignoring the return value from e.g. close().
              # This is off by default in some gccs but on by default in others.
              # BSD systems do not support this option, since they are usually
              # using gcc 4.2.1, which does not have this flag yet.
              '-Wno-unused-result',
            ],
          }],
          [ 'OS=="win"', {
            'defines': [
              '_CRT_SECURE_NO_DEPRECATE',
              '_CRT_NONSTDC_NO_WARNINGS',
              '_CRT_NONSTDC_NO_DEPRECATE',
              '_SCL_SECURE_NO_DEPRECATE',
            ],
            'msvs_disabled_warnings': [
              4800,
            ],
            'msvs_settings': {
              'VCCLCompilerTool': {
                'WarningLevel': '3',
                'WarnAsError': 'true',
                'Detect64BitPortabilityProblems': 'false',
              },
            },
            'conditions': [
              ['buildtype=="Official"', {
                'msvs_settings': {
                  'VCCLCompilerTool': { 'WarnAsError': 'false' },
                }
              }],
              [ 'component=="shared_library"', {
              # TODO(darin): Unfortunately, some third_party code depends on base.
                'msvs_disabled_warnings': [
                  4251,  # class 'std::xx' needs to have dll-interface.
                 ],
              }],
            ],
          }],

          [ 'OS=="mac" or OS=="ios"', {
            'xcode_settings': {
              'WARNING_CFLAGS!': ['-Wall', '-Wextra'],
            },
            'conditions': [
              ['buildtype=="Official"', {
                'xcode_settings': {
                  'GCC_TREAT_WARNINGS_AS_ERRORS': 'NO',    # -Werror
                },
              }],
            ],
          }],
          [ 'OS=="ios"', {
            'xcode_settings': {
              # TODO(ios): Fix remaining warnings in third-party code, then
              # remove this; the Mac cleanup didn't get everything that's
              # flagged in an iOS build.
              'GCC_TREAT_WARNINGS_AS_ERRORS': 'NO',
              'RUN_CLANG_STATIC_ANALYZER': 'NO',
              # Several internal ios directories generate numerous warnings for
              # -Wobjc-missing-property-synthesis.
              'CLANG_WARN_OBJC_MISSING_PROPERTY_SYNTHESIS': 'NO',
            },
          }],
        ],
      }, {
        'includes': [
           # Rules for excluding e.g. foo_win.cc from the build on non-Windows.
          'filename_rules.gypi',
        ],
        # In Chromium code, we define __STDC_foo_MACROS in order to get the
        # C99 macros on Mac and Linux.
        'defines': [
          '__STDC_CONSTANT_MACROS',
          '__STDC_FORMAT_MACROS',
        ],
        'conditions': [
          ['OS=="win"', {
            # turn on warnings for signed/unsigned mismatch on chromium code.
            'msvs_settings': {
              'VCCLCompilerTool': {
                'AdditionalOptions': ['/we4389'],
              },
            },
          }],
          ['OS=="win" and component=="shared_library"', {
            'msvs_disabled_warnings': [
              4251,  # class 'std::xx' needs to have dll-interface.
            ],
          }],
        ],
      }],
    ],  # target_conditions for 'target_defaults'
    'default_configuration': 'Debug',
    'configurations': {
      # VCLinkerTool LinkIncremental values below:
      #   0 == default
      #   1 == /INCREMENTAL:NO
      #   2 == /INCREMENTAL
      # Debug links incremental, Release does not.
      #
      # Abstract base configurations to cover common attributes.
      #
      'Common_Base': {
        'abstract': 1,
        'msvs_configuration_attributes': {
          'OutputDirectory': '<(DEPTH)\\build\\<(build_dir_prefix)$(ConfigurationName)',
          'IntermediateDirectory': '$(OutDir)\\obj\\$(ProjectName)',
          'CharacterSet': '1',
        },
        # Add the default import libs.
        'msvs_settings':{
          'VCLinkerTool': {
            'AdditionalDependencies': [
              'kernel32.lib',
              'gdi32.lib',
              'winspool.lib',
              'comdlg32.lib',
              'advapi32.lib',
              'shell32.lib',
              'ole32.lib',
              'oleaut32.lib',
              'user32.lib',
              'uuid.lib',
              'odbc32.lib',
              'odbccp32.lib',
              'delayimp.lib',
              'credui.lib',
              'netapi32.lib',
            ],
            'AdditionalOptions': [
              # Suggested by Microsoft Devrel to avoid
              #   LINK : fatal error LNK1248: image size (80000000) exceeds maximum allowable size (80000000)
              # which started happening more regularly after VS2013 Update 4.
              # Needs to be a bit lower for VS2015, or else errors out.
              '/maxilksize:0x7ff00000',
            ],
          },
        },
      },
      'x86_Base': {
        'abstract': 1,
        'msvs_settings': {
          'VCLinkerTool': {
            'MinimumRequiredVersion': '5.01',  # XP.
            'TargetMachine': '1',
          },
          'VCLibrarianTool': {
            'TargetMachine': '1',
          },
        },
        'msvs_configuration_platform': 'Win32',
      },
      'x64_Base': {
        'abstract': 1,
        'msvs_configuration_platform': 'x64',
        'msvs_settings': {
          'VCLinkerTool': {
            # Make sure to understand http://crbug.com/361720 if you want to
            # increase this.
            'MinimumRequiredVersion': '5.02',  # Server 2003.
            'TargetMachine': '17', # x86 - 64
            'AdditionalLibraryDirectories!':
              ['<(windows_sdk_path)/Lib/win8/um/x86'],
            'AdditionalLibraryDirectories':
              ['<(windows_sdk_path)/Lib/win8/um/x64'],
            # Doesn't exist x64 SDK. Should use oleaut32 in any case.
            'IgnoreDefaultLibraryNames': [ 'olepro32.lib' ],
          },
          'VCLibrarianTool': {
            'AdditionalLibraryDirectories!':
              ['<(windows_sdk_path)/Lib/win8/um/x86'],
            'AdditionalLibraryDirectories':
              ['<(windows_sdk_path)/Lib/win8/um/x64'],
            'TargetMachine': '17', # x64
          },
        },
      },
      'Debug_Base': {
        'abstract': 1,
        'defines': [
          'DYNAMIC_ANNOTATIONS_ENABLED=1',
          'WTF_USE_DYNAMIC_ANNOTATIONS=1',
        ],
        'xcode_settings': {
          'GCC_OPTIMIZATION_LEVEL': '<(mac_debug_optimization)',
          'OTHER_CFLAGS': [
            '<@(debug_extra_cflags)',
          ],
        },
        'msvs_settings': {
          'VCCLCompilerTool': {
            'Optimization': '<(win_debug_Optimization)',
            'PreprocessorDefinitions': ['_DEBUG'],
            'BasicRuntimeChecks': '<(win_debug_RuntimeChecks)',
            'RuntimeLibrary': '<(win_debug_RuntimeLibrary)',
            'conditions': [
              # According to MSVS, InlineFunctionExpansion=0 means
              # "default inlining", not "/Ob0".
              # Thus, we have to handle InlineFunctionExpansion==0 separately.
              ['win_debug_InlineFunctionExpansion==0', {
                'AdditionalOptions': ['/Ob0'],
              }],
              ['win_debug_InlineFunctionExpansion!=""', {
                'InlineFunctionExpansion':
                  '<(win_debug_InlineFunctionExpansion)',
              }],
              ['win_debug_disable_iterator_debugging==1', {
                'PreprocessorDefinitions': ['_HAS_ITERATOR_DEBUGGING=0'],
              }],

              # if win_debug_OmitFramePointers is blank, leave as default
              ['win_debug_OmitFramePointers==1', {
                'OmitFramePointers': 'true',
              }],
              ['win_debug_OmitFramePointers==0', {
                'OmitFramePointers': 'false',
                # The above is not sufficient (http://crbug.com/106711): it
                # simply eliminates an explicit "/Oy", but both /O2 and /Ox
                # perform FPO regardless, so we must explicitly disable.
                # We still want the false setting above to avoid having
                # "/Oy /Oy-" and warnings about overriding.
                'AdditionalOptions': ['/Oy-'],
              }],
            ],
            'AdditionalOptions': [ '<@(win_debug_extra_cflags)', ],
          },
          'VCLinkerTool': {
            'LinkIncremental': '<(msvs_debug_link_incremental)',
            # ASLR makes debugging with windbg difficult because Chrome.exe and
            # Chrome.dll share the same base name. As result, windbg will
            # name the Chrome.dll module like chrome_<base address>, where
            # <base address> typically changes with each launch. This in turn
            # means that breakpoints in Chrome.dll don't stick from one launch
            # to the next. For this reason, we turn ASLR off in debug builds.
            # Note that this is a three-way bool, where 0 means to pick up
            # the default setting, 1 is off and 2 is on.
            'RandomizedBaseAddress': 1,
          },
          'VCResourceCompilerTool': {
            'PreprocessorDefinitions': ['_DEBUG'],
          },
        },
        'conditions': [
          ['OS=="linux" or OS=="android"', {
            'target_conditions': [
              ['_toolset=="target"', {
                'cflags': [
                  '<@(debug_extra_cflags)',
                ],
              }],
            ],
          }],
          ['OS=="linux" and target_arch!="ia32" and disable_glibcxx_debug==0', {
            # Enable libstdc++ debugging facilities to help catch problems
            # early, see http://crbug.com/65151 .
            # TODO(phajdan.jr): Should we enable this for all of POSIX?
            'defines': ['_GLIBCXX_DEBUG=1',],
          }],
          ['release_valgrind_build==0', {
            'xcode_settings': {
              'OTHER_CFLAGS': [
                '-fstack-protector-all',  # Implies -fstack-protector
              ],
            },
          }],
          ['clang==1', {
            'cflags': [
              # Allow comparing the address of references and 'this' against 0
              # in debug builds. Technically, these can never be null in
              # well-defined C/C++ and Clang can optimize such checks away in
              # release builds, but they may be used in asserts in debug builds.
              '-Wno-undefined-bool-conversion',
              '-Wno-tautological-undefined-compare',
            ],
            'xcode_settings': {
              'OTHER_CFLAGS': [
                '-Wno-undefined-bool-conversion',
                '-Wno-tautological-undefined-compare',
              ],
            },
            'msvs_settings': {
              'VCCLCompilerTool': {
                'AdditionalOptions': [
                  '-Wno-undefined-bool-conversion',
                  '-Wno-tautological-undefined-compare',
                ],
              },
            },
          }],
        ],
      },
      'Release_Base': {
        'abstract': 1,
        'defines': [
          'NDEBUG',
        ],
        'xcode_settings': {
          'DEAD_CODE_STRIPPING': 'YES',  # -Wl,-dead_strip
          'GCC_OPTIMIZATION_LEVEL': '<(mac_release_optimization)',
          'OTHER_CFLAGS': [ '<@(release_extra_cflags)', ],
        },
        'msvs_settings': {
          'VCCLCompilerTool': {
            'RuntimeLibrary': '<(win_release_RuntimeLibrary)',
            'conditions': [
              # In official builds, each target will self-select
              # an optimization level.
              ['buildtype!="Official"', {
                  'Optimization': '<(win_release_Optimization)',
                },
              ],
              # According to MSVS, InlineFunctionExpansion=0 means
              # "default inlining", not "/Ob0".
              # Thus, we have to handle InlineFunctionExpansion==0 separately.
              ['win_release_InlineFunctionExpansion==0', {
                'AdditionalOptions': ['/Ob0'],
              }],
              ['win_release_InlineFunctionExpansion!=""', {
                'InlineFunctionExpansion':
                  '<(win_release_InlineFunctionExpansion)',
              }],

              # if win_release_OmitFramePointers is blank, leave as default
              ['win_release_OmitFramePointers==1', {
                'OmitFramePointers': 'true',
              }],
              ['win_release_OmitFramePointers==0', {
                'OmitFramePointers': 'false',
                # The above is not sufficient (http://crbug.com/106711): it
                # simply eliminates an explicit "/Oy", but both /O2 and /Ox
                # perform FPO regardless, so we must explicitly disable.
                # We still want the false setting above to avoid having
                # "/Oy /Oy-" and warnings about overriding.
                'AdditionalOptions': ['/Oy-'],
              }],
              ['asan==0', {
                # Put data in separate COMDATs. This allows the linker
                # to put bit-identical constants at the same address even if
                # they're unrelated constants, which saves binary size.
                # This optimization can't be used when ASan is enabled because
                # it is not compatible with the ASan ODR checker.
                'AdditionalOptions': ['/Gw'],
              }],
            ],
            'AdditionalOptions': [
                '/d2Zi+',  # Improve debugging of Release builds.
                '/Zc:inline',  # Remove unreferenced COMDAT (faster links).
                '<@(win_release_extra_cflags)',
            ],
          },
          'VCLinkerTool': {
            # LinkIncremental is a tri-state boolean, where 0 means default
            # (i.e., inherit from parent solution), 1 means false, and
            # 2 means true.
            'LinkIncremental': '1',
            # This corresponds to the /PROFILE flag which ensures the PDB
            # file contains FIXUP information (growing the PDB file by about
            # 5%) but does not otherwise alter the output binary. This
            # information is used by the Syzygy optimization tool when
            # decomposing the release image.
            'Profile': 'true',
          },
        },
        'conditions': [
          ['msvs_use_common_release', {
            'includes': ['release.gypi'],
          }],
          ['release_valgrind_build==0 and tsan==0', {
            'defines': [
              'NVALGRIND',
              'DYNAMIC_ANNOTATIONS_ENABLED=0',
            ],
          }, {
            'defines': [
              'MEMORY_TOOL_REPLACES_ALLOCATOR',
              'MEMORY_SANITIZER_INITIAL_SIZE',
              'DYNAMIC_ANNOTATIONS_ENABLED=1',
              'WTF_USE_DYNAMIC_ANNOTATIONS=1',
            ],
          }],
          ['OS=="win"', {
            'defines': ['NO_TCMALLOC'],
          }],
          # _FORTIFY_SOURCE isn't really supported by Clang now, see
          # http://llvm.org/bugs/show_bug.cgi?id=16821.
          # It seems to work fine with Ubuntu 12 headers though, so use it
          # in official builds.
          ['os_posix==1 and (asan!=1 and msan!=1 and tsan!=1 and lsan!=1 and ubsan!=1) and (OS!="linux" or clang!=1 or buildtype=="Official")', {
            'target_conditions': [
              ['chromium_code==1', {
                # Non-chromium code is not guaranteed to compile cleanly
                # with _FORTIFY_SOURCE. Also, fortified build may fail
                # when optimizations are disabled, so only do that for Release
                # build.
                'defines': [
                  '_FORTIFY_SOURCE=2',
                ],
              }],
            ],
          }],
          ['OS=="linux" or OS=="android"', {
            'target_conditions': [
              ['_toolset=="target"', {
                'cflags': [
                  '<@(release_extra_cflags)',
                ],
                'conditions': [
                  ['enable_resource_whitelist_generation==1', {
                    'cflags': [
                      '-Wunknown-pragmas -Wno-error=unknown-pragmas',
                    ],
                  }],
                ],
              }],
            ],
          }],
          ['OS=="ios"', {
            'defines': [
              'NS_BLOCK_ASSERTIONS=1',
            ],
          }],
        ],
      },
      #
      # Concrete configurations
      #
      'Debug': {
        'inherit_from': ['Common_Base', 'x86_Base', 'Debug_Base'],
      },
      'Release': {
        'inherit_from': ['Common_Base', 'x86_Base', 'Release_Base'],
      },
      'conditions': [
        [ 'OS=="ios"', {
          'Profile': {
            'inherit_from': ['Common_Base', 'x86_Base', 'Release_Base'],
            'target_conditions': [
              [ '_type=="executable"', {
                # To get a real .dSYM bundle produced by dsymutil, set the
                # debug information format to dwarf-with-dsym.  Since
                # strip_from_xcode will not be used, set Xcode to do the
                # stripping as well.
                'xcode_settings': {
                  'DEBUG_INFORMATION_FORMAT': 'dwarf-with-dsym',
                  'DEPLOYMENT_POSTPROCESSING': 'YES',
                  'STRIP_INSTALLED_PRODUCT': 'YES',
                },
              }],
            ],
          },
        }],
        [ 'OS=="win"', {
          # TODO(bradnelson): add a gyp mechanism to make this more graceful.
          'Debug_x64': {
            'inherit_from': ['Common_Base', 'x64_Base', 'Debug_Base'],
          },
          'Release_x64': {
            'inherit_from': ['Common_Base', 'x64_Base', 'Release_Base'],
          },
        }],
      ],
    },
  },
  'conditions': [
    ['os_posix==1', {
      'target_defaults': {
        'ldflags': [
          '-Wl,-z,now',
          '-Wl,-z,relro',
        ],
        # TODO(glider): enable the default options on other systems.
        'conditions': [
          ['use_sanitizer_options==1 and ((OS=="linux" and (chromeos==0 or target_arch!="ia32")) or OS=="mac")', {
            'dependencies': [
              '<(DEPTH)/build/sanitizers/sanitizers.gyp:sanitizer_options',
            ],
          }],
        ],
      },
    }],
    # TODO(jochen): Enable this on chromeos on arm. http://crbug.com/356580
    ['os_posix==1 and disable_fatal_linker_warnings==0 and use_evdev_gestures==0 and (chromeos==0 or target_arch!="arm")', {
      'target_defaults': {
        'ldflags': [
          '-Wl,--fatal-warnings',
        ],
      },
    }],
    # -Wl,-z,-defs doesn't work with the sanitiziers, http://crbug.com/452065
    ['(OS=="linux" or OS=="android") and asan==0 and msan==0 and tsan==0 and ubsan==0 and ubsan_vptr==0', {
      'target_defaults': {
        'ldflags': [
          '-Wl,-z,defs',
        ],
      },
    }],
    ['os_posix==1 and chromeos==0', {
      # Chrome OS enables -fstack-protector-strong via its build wrapper,
      # and we want to avoid overriding this, so stack-protector is only
      # enabled when not building on Chrome OS.
      # TODO(phajdan.jr): Use -fstack-protector-strong when our gcc
      # supports it.
      'target_defaults': {
        'cflags': [
          '-fstack-protector',
          '--param=ssp-buffer-size=4',
        ],
      },
    }],
    ['os_posix==1 and OS=="linux"', {
      'defines': [
        '_LARGEFILE_SOURCE',
        '_LARGEFILE64_SOURCE',
        '_FILE_OFFSET_BITS=64',
      ],
    }],
    ['os_posix==1 and OS!="mac" and OS!="ios"', {
      'target_defaults': {
        # Enable -Werror by default, but put it in a variable so it can
        # be disabled in ~/.gyp/include.gypi on the valgrind builders.
        'variables': {
          'werror%': '-Werror',
          'libraries_for_target%': '',
        },
        'defines': [
          '_FILE_OFFSET_BITS=64',
        ],
        'cflags': [
          '<(werror)',  # See note above about the werror variable.
          '-pthread',
          '-fno-strict-aliasing',  # See http://crbug.com/32204
          '-Wall',
          # Don't warn about unused function params.  We use those everywhere.
          '-Wno-unused-parameter',
          # Don't warn about the "struct foo f = {0};" initialization pattern.
          '-Wno-missing-field-initializers',
          # Don't export any symbols (for example, to plugins we dlopen()).
          # Note: this is *required* to make some plugins work.
          '-fvisibility=hidden',
          '-pipe',
        ],
        'cflags_cc': [
          '-fno-exceptions',
          '-fno-rtti',
          '-fno-threadsafe-statics',
          # Make inline functions have hidden visiblity by default.
          # Surprisingly, not covered by -fvisibility=hidden.
          '-fvisibility-inlines-hidden',
          # GCC turns on -Wsign-compare for C++ under -Wall, but clang doesn't,
          # so we specify it explicitly.  (llvm.org/PR10448, crbug.com/90453)
          '-Wsign-compare',
        ],
        'ldflags': [
          '-pthread', '-Wl,-z,noexecstack',
        ],
        'libraries' : [
          '<(libraries_for_target)',
        ],
        'configurations': {
          'Debug_Base': {
            'variables': {
              'debug_optimize%': '0',
            },
            'defines': [
              '_DEBUG',
            ],
            'cflags': [
              '-O>(debug_optimize)',
              '-g',
              '-gdwarf-4',
            ],
            'conditions' : [
              ['OS=="android" and target_arch!="mipsel" and target_arch!="mips64el"', {
                # TODO(jdduke) Re-enable on mips after resolving linking
                # issues with libc++ (crbug.com/456380).
                'ldflags': [
                  # Warn in case of text relocations.
                  '-Wl,--warn-shared-textrel',
                ],
              }],
              ['OS=="android" and android_full_debug==0', {
                # Some configurations are copied from Release_Base to reduce
                # the binary size.
                'variables': {
                  'debug_optimize%': 's',
                },
                'cflags': [
                  '-fdata-sections',
                  '-ffunction-sections',
                ],
                'ldflags': [
                  '-Wl,-O1',
                  '-Wl,--as-needed',
                ],
              }],
              ['OS=="android" and android_full_debug==0 and target_arch!="arm64"', {
                # We don't omit frame pointers on arm64 since they are required
                # to correctly unwind stackframes which contain system library
                # function frames (crbug.com/391706).
                'cflags': [
                  '-fomit-frame-pointer',
                ],
              }],
              ['OS=="linux" and target_arch=="ia32"', {
                'ldflags': [
                  '-Wl,--no-as-needed',
                ],
              }],
              ['debug_unwind_tables==1', {
                'cflags': ['-funwind-tables'],
              }, {
                'cflags': ['-fno-unwind-tables', '-fno-asynchronous-unwind-tables'],
                'defines': ['NO_UNWIND_TABLES'],
              }],
              # TODO(mostynb): shuffle clang/gcc_version/binutils_version
              # definitions in to the right scope to use them when setting
              # linux_use_debug_fission, so it can be used here alone.
              ['linux_use_debug_fission==1 and linux_use_gold_flags==1 and (clang==1 or gcc_version>=48) and binutils_version>=223', {
                'cflags': ['-gsplit-dwarf'],
              }],
            ],
          },
          'Release_Base': {
            'variables': {
              'release_optimize%': '2',
              # Binaries become big and gold is unable to perform GC
              # and remove unused sections for some of test targets
              # on 32 bit platform.
              # (This is currently observed only in chromeos valgrind bots)
              # The following flag is to disable --gc-sections linker
              # option for these bots.
              'no_gc_sections%': 0,

              # TODO(bradnelson): reexamine how this is done if we change the
              # expansion of configurations
              'release_valgrind_build%': 0,
            },
            'cflags': [
              '-O<(release_optimize)',
              # Don't emit the GCC version ident directives, they just end up
              # in the .comment section taking up binary size.
              '-fno-ident',
              # Put data and code in their own sections, so that unused symbols
              # can be removed at link time with --gc-sections.
              '-fdata-sections',
              '-ffunction-sections',
            ],
            'ldflags': [
              # Specifically tell the linker to perform optimizations.
              # See http://lwn.net/Articles/192624/ .
              '-Wl,-O1',
              '-Wl,--as-needed',
            ],
            'conditions' : [
              ['no_gc_sections==0', {
                'ldflags': [
                  '-Wl,--gc-sections',
                ],
              }],
              ['OS=="android" and target_arch!="arm64"', {
                # We don't omit frame pointers on arm64 since they are required
                # to correctly unwind stackframes which contain system library
                # function frames (crbug.com/391706).
                'cflags': [
                  '-fomit-frame-pointer',
                ]
              }],
              ['OS=="android" and target_arch!="mipsel" and target_arch!="mips64el"', {
                # TODO(jdduke) Re-enable on mips after resolving linking
                # issues with libc++ (crbug.com/456380).
                'ldflags': [
                  # Warn in case of text relocations.
                  '-Wl,--warn-shared-textrel',
                ],
              }],
              ['OS=="android"', {
                'variables': {
                  'release_optimize%': 's',
                },
              }],
              ['profiling==1', {
                'cflags': [
                  '-fno-omit-frame-pointer',
                  '-g',
                ],
                'conditions' : [
                  ['profiling_full_stack_frames==1', {
                    'cflags': [
                      '-fno-inline',
                      '-fno-optimize-sibling-calls',
                    ],
                  }],
                ],
              }],
              ['release_unwind_tables==1', {
                'cflags': ['-funwind-tables'],
              }, {
                'cflags': ['-fno-unwind-tables', '-fno-asynchronous-unwind-tables'],
                'defines': ['NO_UNWIND_TABLES'],
              }],
              ['clang==1', {
                # Non-unique section names appears to make linker dead stripping
                # less effective. See http://crbug.com/483026#c20
                # TODO(hans): Remove this if resolved upstream.
                'cflags': [
                  '-funique-section-names',
                ],
              }],
            ],
          },
        },
        'conditions': [
          ['target_arch=="ia32"', {
            'target_conditions': [
              ['_toolset=="target"', {
                'asflags': [
                  # Needed so that libs with .s files (e.g. libicudata.a)
                  # are compatible with the general 32-bit-ness.
                  '-32',
                ],
                # All floating-point computations on x87 happens in 80-bit
                # precision.  Because the C and C++ language standards allow
                # the compiler to keep the floating-point values in higher
                # precision than what's specified in the source and doing so
                # is more efficient than constantly rounding up to 64-bit or
                # 32-bit precision as specified in the source, the compiler,
                # especially in the optimized mode, tries very hard to keep
                # values in x87 floating-point stack (in 80-bit precision)
                # as long as possible. This has important side effects, that
                # the real value used in computation may change depending on
                # how the compiler did the optimization - that is, the value
                # kept in 80-bit is different than the value rounded down to
                # 64-bit or 32-bit. There are possible compiler options to
                # make this behavior consistent (e.g. -ffloat-store would keep
                # all floating-values in the memory, thus force them to be
                # rounded to its original precision) but they have significant
                # runtime performance penalty.
                #
                # -mfpmath=sse -msse2 makes the compiler use SSE instructions
                # which keep floating-point values in SSE registers in its
                # native precision (32-bit for single precision, and 64-bit
                # for double precision values). This means the floating-point
                # value used during computation does not change depending on
                # how the compiler optimized the code, since the value is
                # always kept in its specified precision.
                #
                # Refer to http://crbug.com/348761 for rationale behind SSE2
                # being a minimum requirement for 32-bit Linux builds and
                # http://crbug.com/313032 for an example where this has "bit"
                # us in the past.
                'cflags': [
                  '-msse2',
                  '-mfpmath=sse',
                  '-mmmx',  # Allows mmintrin.h for MMX intrinsics.
                  '-m32',
                ],
                'ldflags': [
                  '-m32',
                ],
                'conditions': [
                  # Use gold linker for Android ia32 target.
                  ['OS=="android"', {
                    'ldflags': [
                      '-fuse-ld=gold',
                    ],
                  }],
                ],
              }],
            ],
          }],
          ['target_arch=="x64"', {
            'target_conditions': [
              ['_toolset=="target"', {
                'conditions': [
                  # Use gold linker for Android x64 target.
                  ['OS=="android"', {
                    'ldflags': [
                      '-fuse-ld=gold',
                    ],
                  }],
                ],
                'cflags': [
                  '-m64',
                  '-march=x86-64',
                ],
                'ldflags': [
                  '-m64',
                ],
              }],
            ],
          }],
          ['target_arch=="arm"', {
            'target_conditions': [
              ['_toolset=="target"', {
                'conditions': [
                  ['clang==0', {
                    'cflags_cc': [
                      # The codesourcery arm-2009q3 toolchain warns at that the ABI
                      # has changed whenever it encounters a varargs function. This
                      # silences those warnings, as they are not helpful and
                      # clutter legitimate warnings.
                      '-Wno-abi',
                    ],
                  }],
                  ['clang==1 and arm_arch!="" and OS!="android"', {
                    'cflags': [
                      '-target arm-linux-gnueabihf',
                    ],
                    'ldflags': [
                      '-target arm-linux-gnueabihf',
                    ],
                  }],
                  ['arm_arch!=""', {
                    'cflags': [
                      '-march=<(arm_arch)',
                    ],
                    'conditions': [
                      ['use_lto==1 or use_lto_o2==1', {
                        'ldflags': [
                          '-march=<(arm_arch)',
                        ],
                      }],
                    ],
                  }],
                  ['clang==1 and OS!="android"', {
                    'cflags': [
                      # We need to disable clang's builtin assembler as it can't
                      # handle several asm files, crbug.com/124610
                      '-no-integrated-as',
                    ],
                  }],
                  ['arm_tune!=""', {
                    'cflags': [
                      '-mtune=<(arm_tune)',
                    ],
                    'conditions': [
                      ['use_lto==1 or use_lto_o2==1', {
                        'ldflags': [
                          '-mtune=<(arm_tune)',
                        ],
                      }],
                    ],
                  }],
                  ['arm_fpu!=""', {
                    'cflags': [
                      '-mfpu=<(arm_fpu)',
                    ],
                    'conditions': [
                      ['use_lto==1 or use_lto_o2==1', {
                        'ldflags': [
                          '-mfpu=<(arm_fpu)',
                        ],
                      }],
                    ],
                  }],
                  ['arm_float_abi!=""', {
                    'cflags': [
                      '-mfloat-abi=<(arm_float_abi)',
                    ],
                    'conditions': [
                      ['use_lto==1 or use_lto_o2==1', {
                        'ldflags': [
                          '-mfloat-abi=<(arm_float_abi)',
                        ],
                      }],
                    ],
                  }],
                  ['arm_thumb==1', {
                    'cflags': [
                      '-mthumb',
                    ],
                    'conditions': [
                      ['use_lto==1 or use_lto_o2==1', {
                        'ldflags': [
                          '-mthumb',
                        ],
                      }],
                    ],
                  }],
                  ['OS=="android"', {
                    # Most of the following flags are derived from what Android
                    # uses by default when building for arm, reference for which
                    # can be found in the following file in the Android NDK:
                    # toolchains/arm-linux-androideabi-4.9/setup.mk
                    'cflags': [
                      # The tree-sra optimization (scalar replacement for
                      # aggregates enabling subsequent optimizations) leads to
                      # invalid code generation when using the Android NDK's
                      # compiler (r5-r7). This can be verified using
                      # webkit_unit_tests' WTF.Checked_int8_t test.
                      '-fno-tree-sra',
                      # The following option is disabled to improve binary
                      # size and performance in gcc 4.9.
                      '-fno-caller-saves',
                      '-Wno-psabi',
                    ],
                    # Android now supports .relro sections properly.
                    # NOTE: While these flags enable the generation of .relro
                    # sections, the generated libraries can still be loaded on
                    # older Android platform versions.
                    'ldflags': [
                        '-Wl,-z,relro',
                        '-Wl,-z,now',
                        '-fuse-ld=gold',
                    ],
                    'conditions': [
                      ['gcc_version==48 and clang==0', {
                        'cflags': [
                          # The following 5 options are disabled to save on
                          # binary size in GCC 4.8.
                          '-fno-partial-inlining',
                          '-fno-early-inlining',
                          '-fno-tree-copy-prop',
                          '-fno-tree-loop-optimize',
                          '-fno-move-loop-invariants',
                        ],
                      }],
                      ['arm_thumb==1', {
                        'cflags': [ '-mthumb-interwork' ],
                      }],
                      ['profiling==1', {
                        'cflags': [
                          # Thumb code with frame pointer makes chrome crash
                          # early.
                          '-marm',
                          '-mapcs-frame', # Required by -fno-omit-frame-pointer.
                          # The perf report sometimes incorrectly attributes
                          # code from tail calls.
                          '-fno-optimize-sibling-calls',
                        ],
                        'cflags!': [
                          '-fomit-frame-pointer',
                        ],
                      }],
                      ['clang==1', {
                        'cflags!': [
                          # Clang does not support the following options.
                          '-mapcs-frame',
                          '-mthumb-interwork',
                          '-finline-limit=64',
                          '-fno-tree-sra',
                          '-fno-caller-saves',
                          '-Wno-psabi',
                        ],
                        'cflags': [
                          # TODO(hans) Enable integrated-as (crbug.com/124610).
                          '-no-integrated-as',
                          '-B<(android_toolchain)',  # Else /usr/bin/as gets picked up.
                        ],
                      }],
                      ['clang==1 and linux_use_bundled_gold==0', {
                        'ldflags': [
                          # Let clang find the ld.gold in the NDK.
                          '--gcc-toolchain=<(android_toolchain)/..',
                        ],
                      }],
                      ['asan==1', {
                        'cflags': [
                          '-marm', # Required for frame pointer based stack traces.
                        ],
                      }],
                    ],
                  }],
                  ['chromecast==1', {
                    'cflags': [
                      # We set arm_arch to "" so that -march compiler option
                      # is not set.  Otherwise a gcc bug that would complain
                      # about it conflicting with '-mcpu=cortex-a9'. The flag
                      # '-march=armv7-a' is actually redundant anyway because
                      # it is enabled by default when we built the toolchain.
                      # And using '-mcpu=cortex-a9' should be sufficient.
                      '-mcpu=cortex-a9',
                      '-funwind-tables',
                      # Breakpad requires symbols with debugging information
                      '-g',
                    ],
                    'ldflags': [
                      # We want to statically link libstdc++/libgcc_s.
                      '-static-libstdc++',
                      '-static-libgcc',
                    ],
                    'cflags!': [
                      # Some components in Chromium (e.g. v8, skia, ffmpeg)
                      # define their own cflags for arm builds that could
                      # conflict with the flags we set here (e.g.
                      # '-mcpu=cortex-a9'). Remove these flags explicitly.
                      '-march=armv7-a',
                      '-mtune=cortex-a8',
                    ],
                  }],
                ],
              }],
            ],
          }],
          ['target_arch=="arm64"', {
            'target_conditions': [
              ['_toolset=="target"', {
                'conditions': [
                  ['OS=="android"', {
                    'cflags!': [
                       '-fstack-protector',  # stack protector is always enabled on arm64.
                    ],
                  }],
                ],
              }],
            ],
          }],
          ['target_arch=="mipsel"', {
            'target_conditions': [
              ['_toolset=="target"', {
                'conditions': [
                  ['mips_arch_variant=="r6"', {
                    'conditions': [
                      ['clang==1', {
                        'cflags': [ '-target mipsel-linux-gnu', '-march=mips32r6', ],
                        'ldflags': [ '-target mipsel-linux-gnu', ],
                      }, { # clang==0
                        'cflags': ['-mips32r6', '-Wa,-mips32r6', ],
                      }],
                      ['clang==0 and OS=="android"', {
                        'ldflags': ['-mips32r6', '-Wl,-melf32ltsmip',],
                      }],
                    ],
                  }],
                  ['mips_arch_variant=="r2"', {
                    'conditions': [
                      ['mips_float_abi=="hard" and mips_fpu_mode!=""', {
                        'cflags': ['-m<(mips_fpu_mode)'],
                      }],
                      ['clang==1', {
                         'conditions': [
                          ['OS=="android"', {
                            'cflags': [ '-target mipsel-linux-android', '-march=mipsel', '-mcpu=mips32r2'],
                            'ldflags': [ '-target mipsel-linux-android', ],
                          }, {
                            'cflags': [ '-target mipsel-linux-gnu', '-march=mipsel', '-mcpu=mips32r2'],
                            'ldflags': [ '-target mipsel-linux-gnu', ],
                          }],
                         ],
                      }, { # clang==0
                        'cflags': ['-mips32r2', '-Wa,-mips32r2', ],
                      }],
                    ],
                  }],
                  ['mips_arch_variant=="r1"', {
                    'conditions': [
                      ['clang==1', {
                        'conditions': [
                          ['OS=="android"', {
                            'cflags': [ '-target mipsel-linux-android', '-march=mipsel', '-mcpu=mips32'],
                            'ldflags': [ '-target mipsel-linux-android', ],
                          }, {
                            'cflags': [ '-target mipsel-linux-gnu', '-march=mipsel', '-mcpu=mips32'],
                            'ldflags': [ '-target mipsel-linux-gnu', ],
                          }],
                        ],
                      }, { # clang==0
                        'cflags': ['-mips32', '-Wa,-mips32', ],
                      }],
                    ],
                  }],
                  ['clang==1', {
                    'cflags!': [
                      # Clang does not support the following options.
                      '-finline-limit=64',
                    ],
                    'cflags': [
                      # TODO(gordanac) Enable integrated-as.
                      '-no-integrated-as',
                    ],
                  }],
                  ['clang==1 and OS=="android"', {
                    'cflags': [
                      '-B<(android_toolchain)',  # Else /usr/bin/as gets picked up.
                    ],
                    'ldflags': [
                      # Let clang find the ld in the NDK.
                      '--gcc-toolchain=<(android_toolchain)/..',
                    ],
                  }],
                  ['mips_dsp_rev==1', {
                    'cflags': ['-mdsp'],
                  }],
                  ['mips_dsp_rev==2', {
                    'cflags': ['-mdspr2'],
                  }],
                ],
                'cflags': [
                  '-m<(mips_float_abi)-float'
                ],
                'ldflags': [
                  '-Wl,--no-keep-memory'
                ],
                'cflags_cc': [
                  '-Wno-uninitialized',
                ],
              }],
            ],
          }],
          ['target_arch=="mips64el"', {
            'target_conditions': [
              ['_toolset=="target"', {
                'conditions': [
                  ['mips_arch_variant=="r6"', {
                    'cflags': ['-mips64r6', '-Wa,-mips64r6'],
                    'ldflags': ['-mips64r6'],
                  }],
                  ['mips_arch_variant=="r2"', {
                    'cflags': ['-mips64r2', '-Wa,-mips64r2'],
                    'ldflags': ['-mips64r2'],
                  }],
                ],
                'cflags_cc': [
                  '-Wno-uninitialized',
                ],
              }],
            ],
          }],
          ['linux_fpic==1', {
            'cflags': [
              '-fPIC',
            ],
            'ldflags': [
              '-fPIC',
            ],
          }],
          ['sysroot!=""', {
            'target_conditions': [
              ['_toolset=="target"', {
                'cflags': [
                  '--sysroot=<(sysroot)',
                ],
                'ldflags': [
                  '--sysroot=<(sysroot)',
                  '<!(<(DEPTH)/build/linux/sysroot_ld_path.sh <(sysroot))',
                ],
              }]]
          }],
          ['clang==1', {
            'cflags': [
              # TODO(thakis): Remove, http://crbug.com/263960
              '-Wno-reserved-user-defined-literal',
            ],
            'cflags_cc': [
              # gnu++11 instead of c++11 is needed because some code uses
              # typeof() (a GNU extension).
              # TODO(thakis): Eventually switch this to c++11 instead,
              # http://crbug.com/427584
              '-std=gnu++11',
            ],
          }],
          ['clang==0 and host_clang==1', {
            'target_conditions': [
              ['_toolset=="host"', {
                'cflags_cc': [ '-std=gnu++11', ],
              }],
            ],
          }],
          ['clang==1 and clang_use_chrome_plugins==1', {
            'cflags': [
              '<@(clang_chrome_plugins_flags)',
            ],
          }],
          ['clang==1 and clang_load!=""', {
            'cflags': [
              '-Xclang', '-load', '-Xclang', '<(clang_load)',
            ],
          }],
          ['clang==1 and clang_add_plugin!=""', {
            'cflags': [
              '-Xclang', '-add-plugin', '-Xclang', '<(clang_add_plugin)',
            ],
          }],
          ['clang==1 and target_arch=="ia32"', {
            'cflags': [
              # Else building libyuv gives clang's register allocator issues,
              # see llvm.org/PR15798 / crbug.com/233709
              '-momit-leaf-frame-pointer',
              # Align the stack on 16-byte boundaries, http://crbug.com/418554.
              '-mstack-alignment=16',
              '-mstackrealign',
            ],
          }],
          ['clang==1 and "<(GENERATOR)"=="ninja"', {
            'cflags': [
              # See http://crbug.com/110262
              '-fcolor-diagnostics',
            ],
          }],
          # Common options for AddressSanitizer, LeakSanitizer,
          # ThreadSanitizer and MemorySanitizer.
          ['asan==1 or lsan==1 or tsan==1 or msan==1 or ubsan==1 or ubsan_vptr==1', {
            'target_conditions': [
              ['_toolset=="target"', {
                'cflags': [
                  '-fno-omit-frame-pointer',
                  '-gline-tables-only',
                ],
                'cflags!': [
                  '-fomit-frame-pointer',
                ],
              }],
            ],
          }],
          ['asan==1 or lsan==1 or tsan==1 or msan==1', {
            'target_conditions': [
              ['_toolset=="target"', {
                'ldflags!': [
                  # Functions interposed by the sanitizers can make ld think
                  # that some libraries aren't needed when they actually are,
                  # http://crbug.com/234010. As workaround, disable --as-needed.
                  '-Wl,--as-needed',
                ],
                'defines': [
                  'MEMORY_TOOL_REPLACES_ALLOCATOR',
                  'MEMORY_SANITIZER_INITIAL_SIZE',
                ],
              }],
            ],
          }],
          ['asan==1', {
            'target_conditions': [
              ['_toolset=="target"', {
                'cflags': [
                  '-fsanitize=address',
                  # TODO(earthdok): Re-enable. http://crbug.com/427202
                  #'-fsanitize-blacklist=<(asan_blacklist)',
                ],
                'ldflags': [
                  '-fsanitize=address',
                ],
              }],
            ],
            'conditions': [
              ['OS=="mac"', {
                'cflags': [
                  '-mllvm -asan-globals=0',  # http://crbug.com/352073
                ],
              }],
            ],
          }],
          ['ubsan==1', {
            'target_conditions': [
              ['_toolset=="target"', {
                'cflags': [
                  # FIXME: work on enabling more flags and getting rid of false
                  # positives. http://crbug.com/174801.
                  '-fsanitize=bounds',
                  '-fsanitize=float-divide-by-zero',
                  '-fsanitize=integer-divide-by-zero',
                  '-fsanitize=null',
                  '-fsanitize=object-size',
                  '-fsanitize=return',
                  '-fsanitize=returns-nonnull-attribute',
                  '-fsanitize=shift-exponent',
                  '-fsanitize=signed-integer-overflow',
                  '-fsanitize=unreachable',
                  '-fsanitize=vla-bound',
                  '-fsanitize-blacklist=<(ubsan_blacklist)',
                  # Employ the experimental PBQP register allocator to avoid
                  # slow compilation on files with too many basic blocks.
                  # See http://crbug.com/426271.
                  '-mllvm -regalloc=pbqp',
                  # Speculatively use coalescing to slightly improve the code
                  # generated by PBQP regallocator. May increase compile time.
                  '-mllvm -pbqp-coalescing',
                ],
                'cflags_cc!': [
                  '-fno-rtti',
                ],
                'cflags!': [
                  '-fno-rtti',
                ],
                'ldflags': [
                  '-fsanitize=undefined',
                ],
                'defines': [
                  'UNDEFINED_SANITIZER',
                ],
              }],
            ],
          }],
          ['ubsan_vptr==1', {
            'target_conditions': [
              ['_toolset=="target"', {
                'cflags': [
                  '-fsanitize=vptr',
                  '-fsanitize-blacklist=<(ubsan_vptr_blacklist)',
                ],
                'cflags_cc!': [
                  '-fno-rtti',
                ],
                'cflags!': [
                  '-fno-rtti',
                ],
                'ldflags': [
                  '-fsanitize=vptr',
                ],
                'defines': [
                  'UNDEFINED_SANITIZER',
                ],
              }],
            ],
          }],
          ['asan_coverage!=0 and sanitizer_coverage==0', {
            'target_conditions': [
              ['_toolset=="target"', {
                'cflags': [
                  '-fsanitize-coverage=<(asan_coverage)',
                ],
                'defines': [
                  'SANITIZER_COVERAGE',
                ],
              }],
            ],
          }],
          ['sanitizer_coverage!=0', {
            'target_conditions': [
              ['_toolset=="target"', {
                'cflags': [
                  '-fsanitize-coverage=<(sanitizer_coverage)',
                ],
                'defines': [
                  'SANITIZER_COVERAGE',
                ],
              }],
            ],
          }],
          ['asan_field_padding!=0', {
            'target_conditions': [
              ['_toolset=="target"', {
                'cflags': [
                  '-fsanitize-address-field-padding=<(asan_field_padding)',
                ],
              }],
            ],
          }],
          ['lsan==1', {
            'target_conditions': [
              ['_toolset=="target"', {
                'cflags': [
                  '-fsanitize=leak',
                ],
                'ldflags': [
                  '-fsanitize=leak',
                ],
                'defines': [
                  'LEAK_SANITIZER',
                  'WTF_USE_LEAK_SANITIZER=1',
                ],
              }],
            ],
          }],
          ['tsan==1', {
            'target_conditions': [
              ['_toolset=="target"', {
                'cflags': [
                  '-fsanitize=thread',
                  '-fsanitize-blacklist=<(tsan_blacklist)',
                ],
                'ldflags': [
                  '-fsanitize=thread',
                ],
                'defines': [
                  'THREAD_SANITIZER',
                  'DYNAMIC_ANNOTATIONS_EXTERNAL_IMPL=1',
                  'WTF_USE_DYNAMIC_ANNOTATIONS_NOIMPL=1',
                ],
              }],
            ],
          }],
          ['msan==1', {
            'target_conditions': [
              ['_toolset=="target"', {
                'cflags': [
                  '-fsanitize=memory',
                  '-fsanitize-memory-track-origins=<(msan_track_origins)',
                  '-fsanitize-blacklist=<(msan_blacklist)',
                ],
                'ldflags': [
                  '-fsanitize=memory',
                ],
                'defines': [
                  'MEMORY_SANITIZER',
                ],
              }],
            ],
          }],
          ['use_instrumented_libraries==1', {
            'dependencies': [
              '<(DEPTH)/third_party/instrumented_libraries/instrumented_libraries.gyp:instrumented_libraries',
            ],
          }],
          ['use_prebuilt_instrumented_libraries==1', {
            'dependencies': [
              '<(DEPTH)/third_party/instrumented_libraries/instrumented_libraries.gyp:prebuilt_instrumented_libraries',
            ],
          }],
          ['use_custom_libcxx==1', {
            'dependencies': [
              '<(DEPTH)/buildtools/third_party/libc++/libc++.gyp:libcxx_proxy',
            ],
          }],
          ['order_profiling!=0 and (chromeos==1 or OS=="linux" or OS=="android")', {
            'target_conditions' : [
              # crazy_linker has an upstream gyp file we can't edit, and we
              # don't want to instrument it.
              ['_toolset=="target" and _target_name!="crazy_linker"', {
                'cflags': [
                  '-finstrument-functions',
                  # Allow mmx intrinsics to inline, so that the
                  #0 compiler can expand the intrinsics.
                  '-finstrument-functions-exclude-file-list=mmintrin.h',
                ],
              }],
              ['_toolset=="target" and OS=="android"', {
                'cflags': [
                  # Avoids errors with current NDK:
                  # "third_party/android_tools/ndk/toolchains/arm-linux-androideabi-4.6/prebuilt/linux-x86_64/bin/../lib/gcc/arm-linux-androideabi/4.6/include/arm_neon.h:3426:3: error: argument must be a constant"
                  '-finstrument-functions-exclude-file-list=arm_neon.h,SaturatedArithmeticARM.h',
                ],
              }],
            ],
          }],
          ['linux_dump_symbols==1', {
            'cflags': [ '-g' ],
            'conditions': [
              ['OS=="linux" and host_arch=="ia32" and linux_use_bundled_gold==0', {
                'target_conditions': [
                  ['_toolset=="target"', {
                    'ldflags': [
                      # Attempt to use less memory to prevent the linker from
                      # running out of address space. Considering installing a
                      # 64-bit kernel and switching to a 64-bit linker.
                      '-Wl,--no-keep-memory',
                    ],
                  }],
                ],
              }],
            ],
          }],
          ['use_allocator!="tcmalloc"', {
            'defines': ['NO_TCMALLOC'],
          }],
          ['linux_use_gold_flags==1', {
            # Newer gccs and clangs support -fuse-ld, use the flag to force gold
            # selection.
            # gcc -- http://gcc.gnu.org/onlinedocs/gcc-4.8.0/gcc/Optimize-Options.html
            'ldflags': [ '-fuse-ld=gold', ],

            'target_conditions': [
              ['_toolset=="target"', {
                'ldflags': [
                  # Experimentation found that using four linking threads
                  # saved ~20% of link time.
                  # https://groups.google.com/a/chromium.org/group/chromium-dev/browse_thread/thread/281527606915bb36
                  # Only apply this to the target linker, since the host
                  # linker might not be gold, but isn't used much anyway.
                  # TODO(raymes): Disable threading because gold is frequently
                  # crashing on the bots: crbug.com/161942.
                  # '-Wl,--threads',
                  # '-Wl,--thread-count=4',
                ],
                'conditions': [
                  # TODO(thestig): Enable this for disabled cases.
                  [ 'buildtype!="Official" and chromeos==0 and release_valgrind_build==0 and asan==0 and lsan==0 and tsan==0 and msan==0 and ubsan==0 and ubsan_vptr==0', {
                    'ldflags': [
                      '-Wl,--detect-odr-violations',
                    ],
                  }],
                ],
              }],
            ],
            'conditions': [
              ['release_valgrind_build==0 and order_profiling==0 and asan==0 and msan==0 and lsan==0 and tsan==0', {
                'target_conditions': [
                  ['_toolset=="target"', {
                    'ldflags': [
                      '-Wl,--icf=<(gold_icf_level)',
                    ],
                  }],
                ],
              }],
            ],
          }],
          ['linux_use_bundled_binutils==1', {
            'cflags': [
              '-B<!(cd <(DEPTH) && pwd -P)/<(binutils_dir)',
            ],
          }],
          ['linux_use_bundled_gold==1 and '
           'not (clang==0 and (use_lto==1 or use_lto_o2==1))', {
            # Put our binutils, which contains gold in the search path. We pass
            # the path to gold to the compiler. gyp leaves unspecified what the
            # cwd is when running the compiler, so the normal gyp path-munging
            # fails us. This hack gets the right path.
            #
            # Disabled when using GCC LTO because GCC also uses the -B search
            # path at link time to find "as", and our bundled "as" can only
            # target x86.
            'ldflags': [
              '-B<!(cd <(DEPTH) && pwd -P)/<(binutils_dir)',
            ],
          }],
          # Some binutils 2.23 releases may or may not have new dtags enabled,
          # but they are all compatible with --disable-new-dtags,
          # because the new dynamic tags are not created by default.
          ['binutils_version>=223', {
            # Newer binutils don't set DT_RPATH unless you disable "new" dtags
            # and the new DT_RUNPATH doesn't work without --no-as-needed flag.
            # FIXME(mithro): Figure out the --as-needed/--no-as-needed flags
            # inside this file to allow usage of --no-as-needed and removal of
            # this flag.
            'ldflags': [
              '-Wl,--disable-new-dtags',
            ],
          }],
          ['gcc_version>=47 and clang==0', {
            'target_conditions': [
              ['_toolset=="target"', {
                'cflags_cc': [
                  '-std=gnu++11',
                  # See comment for -Wno-c++11-narrowing.
                  '-Wno-narrowing',
                  # TODO(thakis): Remove, http://crbug.com/263960
                  '-Wno-literal-suffix',
                ],
              }],
            ],
          }],
          ['host_gcc_version>=47 and clang==0 and host_clang==0', {
            'target_conditions': [
              ['_toolset=="host"', {
                'cflags_cc': [
                  '-std=gnu++11',
                  # See comment for -Wno-c++11-narrowing.
                  '-Wno-narrowing',
                  # TODO(thakis): Remove, http://crbug.com/263960
                  '-Wno-literal-suffix',
                ],
              }],
            ],
          }],
        ],
      },
    }],
    # FreeBSD-specific options; note that most FreeBSD options are set above,
    # with Linux.
    ['OS=="freebsd"', {
      'target_defaults': {
        'ldflags': [
          '-Wl,--no-keep-memory',
        ],
      },
    }],
    # Android-specific options; note that most are set above with Linux.
    ['OS=="android"', {
      'variables': {
        # This is a unique identifier for a given build. It's used for
        # identifying various build artifacts corresponding to a particular
        # build of chrome (e.g. where to find archived symbols).
        'chrome_build_id%': '',
        'conditions': [
          # Figure this out early since it needs symbols from libgcc.a, so it
          # has to be before that in the set of libraries.
          ['component=="shared_library"', {
              'android_libcpp_library': 'c++_shared',
          }, {
              'android_libcpp_library': 'c++_static',
          }],
        ],

        # Placing this variable here prevents from forking libvpx, used
        # by remoting.  Remoting is off, so it needn't built,
        # so forking it's deps seems like overkill.
        # But this variable need defined to properly run gyp.
        # A proper solution is to have an OS==android conditional
        # in third_party/libvpx/libvpx.gyp to define it.
        'libvpx_path': 'lib/linux/arm',
      },
      'target_defaults': {
        'variables': {
          'release_extra_cflags%': '',
          'conditions': [
            # If we're using the components build, append "cr" to all shared
            # libraries to avoid naming collisions with android system library
            # versions with the same name (e.g. skia, icu).
            ['component=="shared_library"', {
              'android_product_extension': 'cr.so',
            }, {
              'android_product_extension': 'so',
            } ],
          ],
        },
        'target_conditions': [
          ['_type=="shared_library"', {
            'product_extension': '<(android_product_extension)',
          }],

          # Settings for building device targets using Android's toolchain.
          # These are based on the setup.mk file from the Android NDK.
          #
          # The NDK Android executable link step looks as follows:
          #  $LDFLAGS
          #  $(TARGET_CRTBEGIN_DYNAMIC_O)  <-- crtbegin.o
          #  $(PRIVATE_OBJECTS)            <-- The .o that we built
          #  $(PRIVATE_STATIC_LIBRARIES)   <-- The .a that we built
          #  $(TARGET_LIBGCC)              <-- libgcc.a
          #  $(PRIVATE_SHARED_LIBRARIES)   <-- The .so that we built
          #  $(PRIVATE_LDLIBS)             <-- System .so
          #  $(TARGET_CRTEND_O)            <-- crtend.o
          #
          # For now the above are approximated for executables by adding
          # crtbegin.o to the end of the ldflags and 'crtend.o' to the end
          # of 'libraries'.
          #
          # The NDK Android shared library link step looks as follows:
          #  $LDFLAGS
          #  $(PRIVATE_OBJECTS)            <-- The .o that we built
          #  -l,--whole-archive
          #  $(PRIVATE_WHOLE_STATIC_LIBRARIES)
          #  -l,--no-whole-archive
          #  $(PRIVATE_STATIC_LIBRARIES)   <-- The .a that we built
          #  $(TARGET_LIBGCC)              <-- libgcc.a
          #  $(PRIVATE_SHARED_LIBRARIES)   <-- The .so that we built
          #  $(PRIVATE_LDLIBS)             <-- System .so
          #
          # For now, assume that whole static libraries are not needed.
          #
          # For both executables and shared libraries, add the proper
          # libgcc.a to the start of libraries which puts it in the
          # proper spot after .o and .a files get linked in.
          #
          # TODO: The proper thing to do longer-tem would be proper gyp
          # support for a custom link command line.
          ['_toolset=="target"', {
            'cflags!': [
              '-pthread',  # Not supported by Android toolchain.
            ],
            'cflags': [
              '-ffunction-sections',
              '-funwind-tables',
              '-g',
              '-fstack-protector',
              '-fno-short-enums',
              '-finline-limit=64',
              '<@(release_extra_cflags)',
              '--sysroot=<(android_ndk_sysroot)',
              # NOTE: The libc++ header include paths below are specified in
              # cflags rather than include_dirs because they need to come
              # after include_dirs.
              # The include ordering here is important; change with caution.
              '-isystem<(android_libcpp_include)',
              '-isystem<(android_ndk_root)/sources/cxx-stl/llvm-libc++abi/libcxxabi/include',
              '-isystem<(android_ndk_root)/sources/android/support/include',
            ],
            'defines': [
              'ANDROID',
              '__GNU_SOURCE=1',  # Necessary for clone()
              'CHROME_BUILD_ID="<(chrome_build_id)"',
              # The NDK has these things, but doesn't define the constants
              # to say that it does. Define them here instead.
              'HAVE_SYS_UIO_H',
            ],
            'ldflags!': [
              '-pthread',  # Not supported by Android toolchain.
            ],
            'ldflags': [
              '-Wl,--no-undefined',
              '--sysroot=<(android_ndk_sysroot)',
              '-nostdlib',
              '-L<(android_libcpp_libs_dir)',
              # Don't allow visible symbols from libgcc or libc++ to be
              # re-exported.
              '-Wl,--exclude-libs=libgcc.a',
              '-Wl,--exclude-libs=libc++_static.a',
              # Don't allow visible symbols from libraries that contain
              # assembly code with symbols that aren't hidden properly.
              # http://crbug.com/448386
              '-Wl,--exclude-libs=libcommon_audio.a',
              '-Wl,--exclude-libs=libcommon_audio_neon.a',
              '-Wl,--exclude-libs=libcommon_audio_sse2.a',
              '-Wl,--exclude-libs=libiSACFix.a',
              '-Wl,--exclude-libs=libisac_neon.a',
              '-Wl,--exclude-libs=libopus.a',
              '-Wl,--exclude-libs=libvpx.a',
            ],
            'libraries': [
              '-l<(android_libcpp_library)',
              '-latomic',
              # Manually link the libgcc.a that the cross compiler uses.
              '<!(<(android_toolchain)/*-gcc -print-libgcc-file-name)',
              '-lc',
              '-ldl',
              '-lm',
            ],
            'conditions': [
              ['component=="static_library"', {
                'target_conditions': [
                  ['use_native_jni_exports==0', {
                    # Use a linker version script to strip JNI exports from
                    # binaries which have not specifically asked to use them.
                    'ldflags': [
                      '-Wl,--version-script=<!(cd <(DEPTH) && pwd -P)/build/android/android_no_jni_exports.lst',
                    ],
                  }],
                ],
              }],
              ['clang==1', {
                'libraries!': [
                  # Clang with libc++ does not require an explicit atomic
                  # library reference.
                  '-latomic',
                ],
                'cflags': [
                  # Work around incompatibilities between bionic and clang
                  # headers.
                  '-D__compiler_offsetof=__builtin_offsetof',
                  '-Dnan=__builtin_nan',
                ],
                'conditions': [
                  ['target_arch=="arm"', {
                    'cflags': [
                      '-target arm-linux-androideabi',
                    ],
                    'ldflags': [
                      '-target arm-linux-androideabi',
                    ],
                  }],
                  ['target_arch=="ia32"', {
                    'cflags': [
                      '-target x86-linux-androideabi',
                    ],
                    'ldflags': [
                      '-target x86-linux-androideabi',
                    ],
                  }],
                  # Place holder for x64 support, not tested.
                  # TODO: Enable clang support for Android x64. http://crbug.com/346626
                  ['target_arch=="x64"', {
                    'cflags': [
                      '-target x86_64-linux-androideabi',
                    ],
                    'ldflags': [
                      '-target x86_64-linux-androideabi',
                    ],
                  }],
                ],
              }],
              ['asan==1', {
                'cflags': [
                  # Android build relies on -Wl,--gc-sections removing
                  # unreachable code. ASan instrumentation for globals inhibits
                  # this and results in a library with unresolvable relocations.
                  # TODO(eugenis): find a way to reenable this.
                  '-mllvm -asan-globals=0',
                ],
              }],
              ['target_arch == "arm" and order_profiling==0', {
                'ldflags': [
                  # Enable identical code folding to reduce size.
                  '-Wl,--icf=<(gold_icf_level)',
                ],
              }],
              ['target_arch=="ia32"', {
                # The x86 toolchain currently has problems with stack-protector.
                'cflags!': [
                  '-fstack-protector',
                ],
                'cflags': [
                  '-fno-stack-protector',
                ],
              }],
            ],
            'target_conditions': [
              ['_type=="executable"', {
                # Force android tools to export the "main" symbol so they can be
                # loaded on ICS using the run_pie wrapper. See crbug.com/373219.
                # TODO(primiano): remove -fvisibility and -rdynamic flags below
                # when ICS support will be dropped.
                'cflags': [
                  '-fPIE',
                  '-fvisibility=default',
                ],
                'ldflags': [
                  '-Bdynamic',
                  '-Wl,--gc-sections',
                  '-Wl,-z,nocopyreloc',
                  '-pie',
                  '-rdynamic',
                  # crtbegin_dynamic.o should be the last item in ldflags.
                  '<(android_ndk_lib)/crtbegin_dynamic.o',
                ],
                'libraries': [
                  # crtend_android.o needs to be the last item in libraries.
                  # Do not add any libraries after this!
                  '<(android_ndk_lib)/crtend_android.o',
                ],
              }],
              ['_type=="shared_library" or _type=="loadable_module"', {
                'ldflags': [
                  '-Wl,-shared,-Bsymbolic',
                  # crtbegin_so.o should be the last item in ldflags.
                  '<(android_ndk_lib)/crtbegin_so.o',
                ],
                'libraries': [
                  # crtend_so.o needs to be the last item in libraries.
                  # Do not add any libraries after this!
                  '<(android_ndk_lib)/crtend_so.o',
                ],
              }],
            ],
          }],
          # Settings for building host targets using the system toolchain.
          ['_toolset=="host"', {
            'cflags!': [
              # Due to issues in Clang build system, using ASan on 32-bit
              # binaries on x86_64 host is problematic.
              # TODO(eugenis): re-enable.
              '-fsanitize=address',
            ],
            'ldflags!': [
              '-fsanitize=address',
              '-Wl,-z,noexecstack',
              '-Wl,--gc-sections',
              '-Wl,-O1',
              '-Wl,--as-needed',
              '-Wl,--warn-shared-textrel',
              '-Wl,--fatal-warnings',
            ],
          }],
          # Settings for building host targets on mac.
          ['_toolset=="host" and host_os=="mac"', {
            'ldflags!': [
              '-Wl,-z,now',
              '-Wl,-z,relro',
            ],
          }],
        ],
      },
    }],
    ['OS=="solaris"', {
      'cflags!': ['-fvisibility=hidden'],
      'cflags_cc!': ['-fvisibility-inlines-hidden'],
    }],
    ['OS=="mac" or OS=="ios"', {
      'target_defaults': {
        'mac_bundle': 0,
        'xcode_settings': {
          'ALWAYS_SEARCH_USER_PATHS': 'NO',
          # Don't link in libarclite_macosx.a, see http://crbug.com/156530.
          'CLANG_LINK_OBJC_RUNTIME': 'NO',          # -fno-objc-link-runtime
          'COPY_PHASE_STRIP': 'NO',
          'GCC_C_LANGUAGE_STANDARD': 'c99',         # -std=c99
          'GCC_CW_ASM_SYNTAX': 'NO',                # No -fasm-blocks
          'GCC_ENABLE_CPP_EXCEPTIONS': 'NO',        # -fno-exceptions
          'GCC_ENABLE_CPP_RTTI': 'NO',              # -fno-rtti
          'GCC_ENABLE_PASCAL_STRINGS': 'NO',        # No -mpascal-strings
          # GCC_INLINES_ARE_PRIVATE_EXTERN maps to -fvisibility-inlines-hidden
          'GCC_INLINES_ARE_PRIVATE_EXTERN': 'YES',
          'GCC_OBJC_CALL_CXX_CDTORS': 'YES',        # -fobjc-call-cxx-cdtors
          'GCC_SYMBOLS_PRIVATE_EXTERN': 'YES',      # -fvisibility=hidden
          'GCC_THREADSAFE_STATICS': 'NO',           # -fno-threadsafe-statics
          'GCC_TREAT_WARNINGS_AS_ERRORS': 'YES',    # -Werror
          'GCC_VERSION': '4.2',
          'GCC_WARN_ABOUT_MISSING_NEWLINE': 'YES',  # -Wnewline-eof
          'USE_HEADERMAP': 'NO',
          'WARNING_CFLAGS': [
            '-Wall',
            '-Wendif-labels',
            '-Wextra',
            # Don't warn about unused function parameters.
            '-Wno-unused-parameter',
            # Don't warn about the "struct foo f = {0};" initialization
            # pattern.
            '-Wno-missing-field-initializers',
          ],
          'conditions': [
            ['chromium_mac_pch', {'GCC_PRECOMPILE_PREFIX_HEADER': 'YES'},
                                 {'GCC_PRECOMPILE_PREFIX_HEADER': 'NO'}
            ],
            # Note that the prebuilt Clang binaries should not be used for iOS
            # development except for ASan builds.
            ['clang==1', {
              'CLANG_CXX_LANGUAGE_STANDARD': 'c++11',  # -std=c++11
              # Warn if automatic synthesis is triggered with
              # the -Wobjc-missing-property-synthesis flag.
              'CLANG_WARN_OBJC_MISSING_PROPERTY_SYNTHESIS': 'YES',
              'GCC_VERSION': 'com.apple.compilers.llvm.clang.1_0',
              'WARNING_CFLAGS': [
                # This warns on selectors from Cocoa headers (-length, -set).
                # cfe-dev is currently discussing the merits of this warning.
                # TODO(thakis): Reevaluate what to do with this, based one
                # cfe-dev discussion.
                '-Wno-selector-type-mismatch',
              ],
              'conditions': [
                ['clang_xcode==0', {
                  'CC': '$(SOURCE_ROOT)/<(clang_dir)/clang',
                  'LDPLUSPLUS': '$(SOURCE_ROOT)/<(clang_dir)/clang++',
                }],
              ],
            }],
            ['clang==1 and clang_xcode==0 and clang_use_chrome_plugins==1', {
              'OTHER_CFLAGS': [
                '<@(clang_chrome_plugins_flags)',
              ],
            }],
            ['clang==1 and clang_xcode==0 and clang_load!=""', {
              'OTHER_CFLAGS': [
                '-Xclang', '-load', '-Xclang', '<(clang_load)',
              ],
            }],
            ['clang==1 and clang_xcode==0 and clang_add_plugin!=""', {
              'OTHER_CFLAGS': [
                '-Xclang', '-add-plugin', '-Xclang', '<(clang_add_plugin)',
              ],
            }],
            ['clang==1 and "<(GENERATOR)"=="ninja"', {
              'OTHER_CFLAGS': [
                # See http://crbug.com/110262
                '-fcolor-diagnostics',
              ],
            }],
            ['OS=="ios" and target_subarch!="arm32" and \
              "<(GENERATOR)"=="xcode"', {
              'OTHER_CFLAGS': [
                # TODO(ios): when building Chrome for iOS on 64-bit platform
                # with Xcode, the -Wshorted-64-to-32 warning is automatically
                # enabled. This cause failures when compiling protobuf code,
                # so disable the warning. http://crbug.com/359107
                '-Wno-shorten-64-to-32',
              ],
            }],
          ],
        },
        'conditions': [
          ['clang==1', {
            'variables': {
              'clang_dir': '../third_party/llvm-build/Release+Asserts/bin',
            },
          }],
          ['asan==1', {
            'xcode_settings': {
              'OTHER_CFLAGS': [
                '-fsanitize=address',
                '-mllvm -asan-globals=0',  # http://crbug.com/352073
                '-gline-tables-only',
              ],
            },
          }],
          ['asan_coverage!=0 and sanitizer_coverage==0', {
            'target_conditions': [
              ['_toolset=="target"', {
                'cflags': [
                  '-fsanitize-coverage=<(asan_coverage)',
                ],
                'defines': [
                  'SANITIZER_COVERAGE',
                ],
              }],
            ],
          }],
          ['sanitizer_coverage!=0', {
            'target_conditions': [
              ['_toolset=="target"', {
                'cflags': [
                  '-fsanitize-coverage=<(sanitizer_coverage)',
                ],
                'defines': [
                  'SANITIZER_COVERAGE',
                ],
              }],
            ],
          }],
        ],
        'target_conditions': [
          ['_type!="static_library"', {
            'xcode_settings': {'OTHER_LDFLAGS': ['-Wl,-search_paths_first']},
            'conditions': [
              ['asan==1', {
                'xcode_settings': {
                  'OTHER_LDFLAGS': [
                    '-fsanitize=address',
                  ],
                },
              }],
              ['mac_write_linker_maps==1', {
                'xcode_settings': {
                  'OTHER_LDFLAGS': [
                    '-Wl,-map,>(_target_name).map',
                  ],
                },
              }],
            ],
          }],
          ['_mac_bundle', {
            'xcode_settings': {'OTHER_LDFLAGS': ['-Wl,-ObjC']},
            'target_conditions': [
              ['_type=="executable"', {
                'conditions': [
                  ['asan==1', {
                    'postbuilds': [
                      {
                        'variables': {
                          # Define copy_asan_dylib_path in a variable ending in
                          # _path so that gyp understands it's a path and
                          # performs proper relativization during dict merging.
                          'copy_asan_dylib_path':
                            'mac/copy_asan_runtime_dylib.sh',
                        },
                        'postbuild_name': 'Copy ASan runtime dylib',
                        'action': [
                          '<(copy_asan_dylib_path)',
                        ],
                      },
                    ],
                  }],
                ],
              }],
            ],
          }],
        ],  # target_conditions
      },  # target_defaults
    }],  # OS=="mac" or OS=="ios"
    ['OS=="mac"', {
      'target_defaults': {
        'defines': [
          # Prevent Mac OS X AssertMacros.h from defining macros that collide
          # with common names, like 'check', 'require', and 'verify'.
          # (Included by system header. Also exists on iOS but not included.)
          # http://opensource.apple.com/source/CarbonHeaders/CarbonHeaders-18.1/AssertMacros.h
          '__ASSERT_MACROS_DEFINE_VERSIONS_WITHOUT_UNDERSCORE=0',
        ],
        'variables': {
          # These should end with %, but there seems to be a bug with % in
          # variables that are intended to be set to different values in
          # different targets, like these.
          'mac_pie': 1,        # Most executables can be position-independent.
          # Strip debugging symbols from the target.
          'mac_strip': '<(mac_strip_release)',
          'conditions': [
            ['asan==1', {
              'conditions': [
                ['mac_want_real_dsym=="default"', {
                  'mac_real_dsym': 1,
                }, {
                  'mac_real_dsym': '<(mac_want_real_dsym)'
                }],
              ],
            }, {
              'conditions': [
                ['mac_want_real_dsym=="default"', {
                  'mac_real_dsym': 0, # Fake .dSYMs are fine in most cases.
                }, {
                  'mac_real_dsym': '<(mac_want_real_dsym)'
                }],
              ],
            }],
          ],
        },
        'configurations': {
          'Release_Base': {
            'conditions': [
              ['branding=="Chrome" and buildtype=="Official"', {
                'xcode_settings': {
                  'OTHER_CFLAGS': [
                    # The Google Chrome Framework dSYM generated by dsymutil has
                    # grown larger than 4GB, which dsymutil can't handle. Reduce
                    # the amount of debug symbols.
                    '-fno-standalone-debug',  # See http://crbug.com/479841
                  ]
                },
              }],
            ],
          },  # configuration "Release"
        },  # configurations
        'xcode_settings': {
          'GCC_DYNAMIC_NO_PIC': 'NO',               # No -mdynamic-no-pic
                                                    # (Equivalent to -fPIC)
          # MACOSX_DEPLOYMENT_TARGET maps to -mmacosx-version-min
          'MACOSX_DEPLOYMENT_TARGET': '<(mac_deployment_target)',
          # Keep pch files below xcodebuild/.
          'SHARED_PRECOMPS_DIR': '$(CONFIGURATION_BUILD_DIR)/SharedPrecompiledHeaders',
          'OTHER_CFLAGS': [
            # Someday this can be replaced by an 'GCC_STRICT_ALIASING': 'NO'
            # xcode_setting, but not until all downstream projects' mac bots are
            # using xcode >= 4.6, because that's when the default value of the
            # flag in the compiler switched.  Pre-4.6, the value 'NO' for that
            # setting is a no-op as far as xcode is concerned, but the compiler
            # behaves differently based on whether -fno-strict-aliasing is
            # specified or not.
            '-fno-strict-aliasing',  # See http://crbug.com/32204.
          ],
        },
        'target_conditions': [
          ['_type=="executable"', {
            'postbuilds': [
              {
                # Arranges for data (heap) pages to be protected against
                # code execution when running on Mac OS X 10.7 ("Lion"), and
                # ensures that the position-independent executable (PIE) bit
                # is set for ASLR when running on Mac OS X 10.5 ("Leopard").
                'variables': {
                  # Define change_mach_o_flags in a variable ending in _path
                  # so that GYP understands it's a path and performs proper
                  # relativization during dict merging.
                  'change_mach_o_flags_path':
                      'mac/change_mach_o_flags_from_xcode.sh',
                  'change_mach_o_flags_options%': [
                  ],
                  'target_conditions': [
                    ['mac_pie==0 or release_valgrind_build==1', {
                      # Don't enable PIE if it's unwanted. It's unwanted if
                      # the target specifies mac_pie=0 or if building for
                      # Valgrind, because Valgrind doesn't understand slide.
                      # See the similar mac_pie/release_valgrind_build check
                      # below.
                      'change_mach_o_flags_options': [
                        '--no-pie',
                      ],
                    }],
                  ],
                },
                'postbuild_name': 'Change Mach-O Flags',
                'action': [
                  '<(change_mach_o_flags_path)',
                  '>@(change_mach_o_flags_options)',
                ],
              },
            ],
            'target_conditions': [
              ['mac_pie==1 and release_valgrind_build==0', {
                # Turn on position-independence (ASLR) for executables. When
                # PIE is on for the Chrome executables, the framework will
                # also be subject to ASLR.
                # Don't do this when building for Valgrind, because Valgrind
                # doesn't understand slide. TODO: Make Valgrind on Mac OS X
                # understand slide, and get rid of the Valgrind check.
                'xcode_settings': {
                  'OTHER_LDFLAGS': [
                    '-Wl,-pie',  # Position-independent executable (MH_PIE)
                  ],
                },
              }],
            ],
          }],
          ['(_type=="executable" or _type=="shared_library" or \
             _type=="loadable_module") and mac_strip!=0', {
            'target_conditions': [
              ['mac_real_dsym == 1', {
                # To get a real .dSYM bundle produced by dsymutil, set the
                # debug information format to dwarf-with-dsym.  Since
                # strip_from_xcode will not be used, set Xcode to do the
                # stripping as well.
                'configurations': {
                  'Release_Base': {
                    'xcode_settings': {
                      'DEBUG_INFORMATION_FORMAT': 'dwarf-with-dsym',
                      'DEPLOYMENT_POSTPROCESSING': 'YES',
                      'STRIP_INSTALLED_PRODUCT': 'YES',
                      'conditions': [
                        # Only strip non-ASan builds.
                        ['asan==0', {
                          'target_conditions': [
                            ['_type=="shared_library" or _type=="loadable_module"', {
                              # The Xcode default is to strip debugging symbols
                              # only (-S).  Local symbols should be stripped as
                              # well, which will be handled by -x.  Xcode will
                              # continue to insert -S when stripping even when
                              # additional flags are added with STRIPFLAGS.
                              'STRIPFLAGS': '-x',
                            }],  # _type=="shared_library" or _type=="loadable_module"
                          ],  # target_conditions
                        }, {  # asan != 0
                          'STRIPFLAGS': '-S',
                        }],
                      ],
                    },  # xcode_settings
                  },  # configuration "Release"
                },  # configurations
              }, {  # mac_real_dsym != 1
                # To get a fast fake .dSYM bundle, use a post-build step to
                # produce the .dSYM and strip the executable.  strip_from_xcode
                # only operates in the Release configuration.
                'postbuilds': [
                  {
                    'variables': {
                      # Define strip_from_xcode in a variable ending in _path
                      # so that gyp understands it's a path and performs proper
                      # relativization during dict merging.
                      'strip_from_xcode_path': 'mac/strip_from_xcode',
                    },
                    'postbuild_name': 'Strip If Needed',
                    'action': ['<(strip_from_xcode_path)'],
                  },
                ],  # postbuilds
              }],  # mac_real_dsym
            ],  # target_conditions
          }],  # (_type=="executable" or _type=="shared_library" or
               #  _type=="loadable_module") and mac_strip!=0
        ],  # target_conditions
      },  # target_defaults
    }],  # OS=="mac"
    ['OS=="ios"', {
      'includes': [
        'ios/coverage.gypi',
      ],
      'target_defaults': {
        'xcode_settings' : {
          'CLANG_CXX_LANGUAGE_STANDARD': 'c++11',

          'conditions': [
            # Older Xcodes do not support -Wno-deprecated-register, so pass an
            # additional flag to suppress the "unknown compiler option" error.
            # Restrict this flag to builds that are either compiling with Xcode
            # or compiling with Xcode's Clang.  This will allow Ninja builds to
            # continue failing on unknown compiler options.
            # TODO(rohitrao): This flag is temporary and should be removed as
            # soon as the iOS bots are updated to use Xcode 5.1.
            ['clang_xcode==1', {
              'WARNING_CFLAGS': [
                '-Wno-unknown-warning-option',
              ],
            }],

            # Limit the valid architectures depending on "target_subarch".
            # This need to include the "arm" architectures but also the "x86"
            # ones (they are used when building for the simulator).
            ['target_subarch=="arm32"', {
              'VALID_ARCHS': ['armv7', 'i386'],
            }],
            ['target_subarch=="arm64"', {
              'VALID_ARCHS': ['arm64', 'x86_64'],
            }],
            ['target_subarch=="both"', {
              'VALID_ARCHS': ['arm64', 'armv7', 'x86_64', 'i386'],
            }],
            ['use_system_libcxx==1', {
              'target_conditions': [
                # Only use libc++ when building target for iOS not when building
                # tools for the host (OS X) as Mac targets OS X SDK 10.6 which
                # does not support libc++.
                ['_toolset=="target"', {
                  'CLANG_CXX_LIBRARY': 'libc++',  # -stdlib=libc++
                }]
              ],
            }, {
              # The default for deployment target of 7.0+ is libc++, so force
              # the old behavior unless libc++ is enabled.
              'CLANG_CXX_LIBRARY': 'libstdc++',  # -stdlib=libstdc++
            }],
          ],
        },
        'target_conditions': [
          ['_toolset=="host"', {
            'xcode_settings': {
              'SDKROOT': 'macosx<(mac_sdk)',  # -isysroot
              'MACOSX_DEPLOYMENT_TARGET': '<(mac_deployment_target)',
              'VALID_ARCHS': [
                'x86_64',
              ],
              'ARCHS': [
                'x86_64',
              ],
            },
          }],
          ['_toolset=="target"', {
            'xcode_settings': {
              # This section should be for overriding host settings. But,
              # since we can't negate the iphone deployment target above, we
              # instead set it here for target only.
              'IPHONEOS_DEPLOYMENT_TARGET': '<(ios_deployment_target)',
              'ARCHS': ['$(ARCHS_STANDARD_INCLUDING_64_BIT)'],
            },
          }],
          ['_type=="executable"', {
            'configurations': {
              'Release_Base': {
                'xcode_settings': {
                  'DEPLOYMENT_POSTPROCESSING': 'YES',
                  'STRIP_INSTALLED_PRODUCT': 'YES',
                },
              },
              'Debug_Base': {
                'xcode_settings': {
                  # Remove dSYM to reduce build time.
                  'DEBUG_INFORMATION_FORMAT': 'dwarf',
                },
              },
            },
            'xcode_settings': {
              'conditions': [
                ['chromium_ios_signing', {
                  # iOS SDK wants everything for device signed.
                  'CODE_SIGN_IDENTITY[sdk=iphoneos*]': 'iPhone Developer',
                }, {
                  'CODE_SIGNING_REQUIRED': 'NO',
                  'CODE_SIGN_IDENTITY[sdk=iphoneos*]': '',
                }],
              ],
            },
          }],
        ],  # target_conditions
      },  # target_defaults
    }],  # OS=="ios"
    ['OS=="win"', {
      'target_defaults': {
        'defines': [
          '_WIN32_WINNT=0x0603',
          'WINVER=0x0603',
          'WIN32',
          '_WINDOWS',
          'NOMINMAX',
          'PSAPI_VERSION=1',
          '_CRT_RAND_S',
          'CERT_CHAIN_PARA_HAS_EXTRA_FIELDS',
          'WIN32_LEAN_AND_MEAN',
          '_ATL_NO_OPENGL',
          '_SECURE_ATL',
          # _HAS_EXCEPTIONS must match ExceptionHandling in msvs_settings.
          '_HAS_EXCEPTIONS=0',
          # Silence some warnings; we can't switch the the 'recommended'
          # versions as they're not available on old OSs.
          '_WINSOCK_DEPRECATED_NO_WARNINGS',
        ],
        'conditions': [
          ['buildtype=="Official"', {
              # In official builds, targets can self-select an optimization
              # level by defining a variable named 'optimize', and setting it
              # to one of
              # - "size", optimizes for minimal code size - the default.
              # - "speed", optimizes for speed over code size.
              # - "max", whole program optimization and link-time code
              #   generation. This is very expensive and should be used
              #   sparingly.
              'variables': {
                'optimize%': 'size',
              },
              'msvs_settings': {
                'VCLinkerTool': {
                  # Set /LTCG for the official builds.
                  'LinkTimeCodeGeneration': '1',
                  'AdditionalOptions': [
                    # Set the number of LTCG code-gen threads to eight.
                    # The default is four. This gives a 5-10% link speedup.
                    '/cgthreads:8',
                  ],
                },
              },
              'target_conditions': [
                ['optimize=="size"', {
                    'msvs_settings': {
                      'VCCLCompilerTool': {
                        # 1, optimizeMinSpace, Minimize Size (/O1)
                        'Optimization': '1',
                        # 2, favorSize - Favor small code (/Os)
                        'FavorSizeOrSpeed': '2',
                      },
                    },
                  },
                ],
                # This config is used to avoid a problem in ffmpeg, see
                # http://crbug.com/264459.
                ['optimize=="size_no_ltcg"', {
                    'msvs_settings': {
                      'VCCLCompilerTool': {
                        # 1, optimizeMinSpace, Minimize Size (/O1)
                        'Optimization': '1',
                        # 2, favorSize - Favor small code (/Os)
                        'FavorSizeOrSpeed': '2',
                      },
                    },
                  },
                ],
                ['optimize=="speed"', {
                    'msvs_settings': {
                      'VCCLCompilerTool': {
                        # 2, optimizeMaxSpeed, Maximize Speed (/O2)
                        'Optimization': '2',
                        # 1, favorSpeed - Favor fast code (/Ot)
                        'FavorSizeOrSpeed': '1',
                      },
                    },
                  },
                ],
                ['optimize=="max"', {
                    # Disable Warning 4702 ("Unreachable code") for the WPO/PGO
                    # builds. Probably anything that this would catch that
                    # wouldn't be caught in a normal build isn't going to
                    # actually be a bug, so the incremental value of C4702 for
                    # PGO builds is likely very small.
                    'msvs_disabled_warnings': [
                      4702
                    ],
                    'msvs_settings': {
                      'VCCLCompilerTool': {
                        # 2, optimizeMaxSpeed, Maximize Speed (/O2)
                        'Optimization': '2',
                        # 1, favorSpeed - Favor fast code (/Ot)
                        'FavorSizeOrSpeed': '1',
                        # This implies link time code generation.
                        'WholeProgramOptimization': 'true',
                      },
                    },
                  },
                ],
              ],
            },
          ],
          ['msvs_xtree_patched!=1', {
            # If xtree hasn't been patched, then we disable C4702. Otherwise,
            # it's enabled. This will generally only be true for system-level
            # installed Express users.
            'msvs_disabled_warnings': [
              4702,
            ],
          }],
        ],
        'msvs_system_include_dirs': [
          '<(windows_sdk_path)/Include/shared',
          '<(windows_sdk_path)/Include/um',
          '<(windows_sdk_path)/Include/winrt',
          '$(VSInstallDir)/VC/atlmfc/include',
        ],
        'msvs_cygwin_shell': 0,
        'msvs_disabled_warnings': [
          # C4091: 'typedef ': ignored on left of 'X' when no variable is
          #                    declared.
          # This happens in a number of Windows headers. Dumb.
          4091,

          # C4127: conditional expression is constant
          # This warning can in theory catch dead code and other problems, but
          # triggers in far too many desirable cases where the conditional
          # expression is either set by macros or corresponds some legitimate
          # compile-time constant expression (due to constant template args,
          # conditionals comparing the sizes of different types, etc.).  Some of
          # these can be worked around, but it's not worth it.
          4127,

          # C4351: new behavior: elements of array 'array' will be default
          #        initialized
          # This is a silly "warning" that basically just alerts you that the
          # compiler is going to actually follow the language spec like it's
          # supposed to, instead of not following it like old buggy versions
          # did.  There's absolutely no reason to turn this on.
          4351,

          # C4355: 'this': used in base member initializer list
          # It's commonly useful to pass |this| to objects in a class'
          # initializer list.  While this warning can catch real bugs, most of
          # the time the constructors in question don't attempt to call methods
          # on the passed-in pointer (until later), and annotating every legit
          # usage of this is simply more hassle than the warning is worth.
          4355,

          # C4503: 'identifier': decorated name length exceeded, name was
          #        truncated
          # This only means that some long error messages might have truncated
          # identifiers in the presence of lots of templates.  It has no effect
          # on program correctness and there's no real reason to waste time
          # trying to prevent it.
          4503,

          # C4611: interaction between 'function' and C++ object destruction is
          #        non-portable
          # This warning is unavoidable when using e.g. setjmp/longjmp.  MSDN
          # suggests using exceptions instead of setjmp/longjmp for C++, but
          # Chromium code compiles without exception support.  We therefore have
          # to use setjmp/longjmp for e.g. JPEG decode error handling, which
          # means we have to turn off this warning (and be careful about how
          # object destruction happens in such cases).
          4611,

          # TODO(maruel): These warnings are level 4. They will be slowly
          # removed as code is fixed.
          4100, # Unreferenced formal parameter
          4121, # Alignment of a member was sensitive to packing
          4244, # Conversion from 'type1' to 'type2', possible loss of data
          4481, # Nonstandard extension used: override specifier 'keyword'
          4505, # Unreferenced local function has been removed
          4510, # Default constructor could not be generated
          4512, # Assignment operator could not be generated
          4610, # Object can never be instantiated
          4838, # Narrowing conversion. Doesn't seem to be very useful.
          4996, # 'X': was declared deprecated (for GetVersionEx).

          # These are variable shadowing warnings that are new in VS2015. We
          # should work through these at some point -- they may be removed from
          # the RTM release in the /W4 set.
          4456, 4457, 4458, 4459,
        ],
        'msvs_settings': {
          'VCCLCompilerTool': {
            'AdditionalOptions': ['/MP'],
            'MinimalRebuild': 'false',
            'BufferSecurityCheck': 'true',
            'EnableFunctionLevelLinking': 'true',
            'RuntimeTypeInfo': 'false',
            'WarningLevel': '4',
            'WarnAsError': 'true',
            'DebugInformationFormat': '3',
            # ExceptionHandling must match _HAS_EXCEPTIONS above.
            'ExceptionHandling': '0',
          },
          'VCLibrarianTool': {
            'AdditionalOptions': ['/ignore:4221'],
            'AdditionalLibraryDirectories': [
              '<(windows_sdk_path)/Lib/win8/um/x86',
            ],
          },
          'VCLinkerTool': {
            'AdditionalDependencies': [
              'wininet.lib',
              'dnsapi.lib',
              'version.lib',
              'msimg32.lib',
              'ws2_32.lib',
              'usp10.lib',
              'psapi.lib',
              'dbghelp.lib',
              'winmm.lib',
              'shlwapi.lib',
            ],
            'AdditionalLibraryDirectories': [
              '<(windows_sdk_path)/Lib/win8/um/x86',
            ],
            'GenerateDebugInformation': 'true',
            'MapFileName': '$(OutDir)\\$(TargetName).map',
            'ImportLibrary': '$(OutDir)\\lib\\$(TargetName).lib',
            'FixedBaseAddress': '1',
            # SubSystem values:
            #   0 == not set
            #   1 == /SUBSYSTEM:CONSOLE
            #   2 == /SUBSYSTEM:WINDOWS
            # Most of the executables we'll ever create are tests
            # and utilities with console output.
            'SubSystem': '1',
          },
          'VCMIDLTool': {
            'GenerateStublessProxies': 'true',
            'TypeLibraryName': '$(InputName).tlb',
            'OutputDirectory': '$(IntDir)',
            'HeaderFileName': '$(InputName).h',
            'DLLDataFileName': '$(InputName).dlldata.c',
            'InterfaceIdentifierFileName': '$(InputName)_i.c',
            'ProxyFileName': '$(InputName)_p.c',
          },
          'VCResourceCompilerTool': {
            'Culture' : '1033',
            'AdditionalIncludeDirectories': [
              '<(DEPTH)',
              '<(SHARED_INTERMEDIATE_DIR)',
            ],
          },
          'target_conditions': [
            ['_type=="executable"', {
              'VCManifestTool': {
                'EmbedManifest': 'true',
              },
            }],
            ['_type=="executable" and ">(win_exe_compatibility_manifest)"!=""', {
              'VCManifestTool': {
                'AdditionalManifestFiles': [
                  '>(win_exe_compatibility_manifest)',
                ],
              },
            }],
          ],
          'conditions': [
            # Building with Clang on Windows is a work in progress and very
            # experimental. See crbug.com/82385.
            # Keep this in sync with the similar blocks in build/config/compiler/BUILD.gn
            ['clang==1', {
              'VCCLCompilerTool': {
                'AdditionalOptions': [
                  # Many files use intrinsics without including this header.
                  # TODO(hans): Fix those files, or move this to sub-GYPs.
                  '/FIIntrin.h',

                  # TODO(hans): Make this list shorter eventually.
                  '-Qunused-arguments',
                  '-Wno-c++11-compat-deprecated-writable-strings',
                  '-Wno-deprecated-declarations',
                  '-Wno-empty-body',
                  '-Wno-enum-conversion',
                  '-Wno-extra-tokens',
                  '-Wno-ignored-attributes',
                  '-Wno-incompatible-pointer-types',
                  '-Wno-int-to-void-pointer-cast',
                  '-Wno-invalid-noreturn',
                  '-Wno-logical-op-parentheses',
                  '-Wno-microsoft',
                  '-Wno-missing-braces',
                  '-Wno-missing-declarations',
                  '-Wno-msvc-include',
                  '-Wno-null-dereference',
                  '-Wno-overloaded-virtual',
                  '-Wno-parentheses',
                  '-Wno-pointer-sign',
                  '-Wno-reorder',
                  '-Wno-return-type-c-linkage',
                  '-Wno-self-assign',
                  '-Wno-sometimes-uninitialized',
                  '-Wno-switch',
                  '-Wno-tautological-compare',
                  '-Wno-unknown-pragmas',
                  '-Wno-unsequenced',
                  '-Wno-unused-function',
                  '-Wno-unused-private-field',
                  '-Wno-unused-value',
                  '-Wno-unused-variable',
                  '-Wno-unused-local-typedef',  # http://crbug.com/411648
                  '-Wno-inconsistent-missing-override', #http://crbug.com/428099
                ],
              },
            }],
            ['clang==1 and target_arch=="ia32"', {
              'VCCLCompilerTool': {
                'WarnAsError': 'false',
                'AdditionalOptions': [
                  '/fallback',
                ],
              },
            }],
            ['clang==1 and clang_use_chrome_plugins==1', {
              'VCCLCompilerTool': {
                'AdditionalOptions': [
                  '<@(clang_chrome_plugins_flags)',
                ],
              },
            }],
            ['clang==1 and MSVS_VERSION == "2013"', {
              'VCCLCompilerTool': {
                'AdditionalOptions': [
                  '-fmsc-version=1800',
                ],
              },
            }],
            ['clang==1 and MSVS_VERSION == "2015"', {
              'VCCLCompilerTool': {
                'AdditionalOptions': [
                  '-fmsc-version=1900',
                ],
              },
            }],
          ],
        },
      },
    }],
    ['disable_nacl==1', {
      'target_defaults': {
        'defines': [
          'DISABLE_NACL',
        ],
      },
    }],
    ['OS=="win" and msvs_use_common_linker_extras', {
      'target_defaults': {
        'msvs_settings': {
          'VCLinkerTool': {
            'DelayLoadDLLs': [
              'dbghelp.dll',
              'dwmapi.dll',
              'shell32.dll',
              'uxtheme.dll',
            ],
          },
        },
        'configurations': {
          'x86_Base': {
            'msvs_settings': {
              'VCLinkerTool': {
                'AdditionalOptions': [
                  '/safeseh',
                  '/dynamicbase',
                  '/ignore:4199',
                  '/ignore:4221',
                  '/nxcompat',
                ],
              },
              'conditions': [
                ['syzyasan==0', {
                  'VCLinkerTool': {
                    'AdditionalOptions': ['/largeaddressaware'],
                  },
                }],
                ['asan==1', {
                  # TODO(asan/win): Move this down into the general
                  # win-target_defaults section once the 64-bit asan runtime
                  # exists.  See crbug.com/345874.
                  'VCCLCompilerTool': {
                    'AdditionalOptions': [
                      '-fsanitize=address',
                      '-fsanitize-blacklist=<(PRODUCT_DIR)/../../tools/memory/asan/blacklist_win.txt',
                    ],
                    'AdditionalIncludeDirectories': [
                      # MSVC needs to be able to find the sanitizer headers when
                      # invoked via /fallback. This is critical for using macros
                      # like ASAN_UNPOISON_MEMORY_REGION in files where we fall
                      # back.
                      '<(DEPTH)/<(make_clang_dir)/lib/clang/3.7.0/include_sanitizer',
                    ],
                  },
                  'VCLinkerTool': {
                    'AdditionalLibraryDirectories': [
                      # TODO(hans): If make_clang_dir is absolute, this breaks.
                      '<(DEPTH)/<(make_clang_dir)/lib/clang/3.7.0/lib/windows',
                    ],
                  },
                  'target_conditions': [
                    ['component=="shared_library"', {
                      'VCLinkerTool': {
                        'AdditionalDependencies': [
                           'clang_rt.asan_dynamic-i386.lib',
                           'clang_rt.asan_dynamic_runtime_thunk-i386.lib',
                        ],
                      },
                    }],
                    ['_type=="executable" and component=="static_library"', {
                      'VCLinkerTool': {
                        'AdditionalDependencies': [
                           'clang_rt.asan-i386.lib',
                        ],
                      },
                    }],
                    ['(_type=="shared_library" or _type=="loadable_module") and component=="static_library"', {
                      'VCLinkerTool': {
                        'AdditionalDependencies': [
                           'clang_rt.asan_dll_thunk-i386.lib',
                        ],
                      },
                    }],
                  ],
                }],
                ['sanitizer_coverage!=0', {
                  # TODO(asan/win): Move this down into the general
                  # win-target_defaults section once the 64-bit asan runtime
                  # exists.  See crbug.com/345874.
                  'VCCLCompilerTool': {
                    'AdditionalOptions': [
                      '-fsanitize-coverage=<(sanitizer_coverage)',
                    ],
                  },
                }],
              ],
            },
            'conditions': [
              ['sanitizer_coverage!=0', {
                # TODO(asan/win): Move this down into the general
                # win-target_defaults section once the 64-bit asan runtime
                # exists.  See crbug.com/345874.
                'defines': [
                  'SANITIZER_COVERAGE',
                ],
              }],
            ],
          },
          'x64_Base': {
            'msvs_settings': {
              'VCLinkerTool': {
                'AdditionalOptions': [
                  # safeseh is not compatible with x64
                  '/dynamicbase',
                  '/ignore:4199',
                  '/ignore:4221',
                  '/nxcompat',
                ],
              },
            },
          },
        },
      },
    }],
    ['enable_new_npdevice_api==1', {
      'target_defaults': {
        'defines': [
          'ENABLE_NEW_NPDEVICE_API',
        ],
      },
    }],
    # Don't warn about the "typedef 'foo' locally defined but not used"
    # for gcc 4.8 and higher.
    # TODO: remove this flag once all builds work. See crbug.com/227506
    ['gcc_version>=48 and clang==0', {
      'target_defaults': {
        'cflags': [
          '-Wno-unused-local-typedefs',
        ],
      },
    }],
    ['gcc_version>=48 and clang==0 and host_clang==1', {
      'target_defaults': {
        'target_conditions': [
          ['_toolset=="host"', { 'cflags!': [ '-Wno-unused-local-typedefs' ]}],
        ],
      },
    }],
    ['clang==1 and ((OS!="mac" and OS!="ios") or clang_xcode==0) '
        'and OS!="win"', {
      'make_global_settings': [
        ['CC', '<(make_clang_dir)/bin/clang'],
        ['CXX', '<(make_clang_dir)/bin/clang++'],
        ['CC.host', '$(CC)'],
        ['CXX.host', '$(CXX)'],
      ],
    }],
    ['clang==1 and OS=="win"', {
      'make_global_settings': [
        # On Windows, gyp's ninja generator only looks at CC.
        ['CC', '<(make_clang_dir)/bin/clang-cl'],
      ],
    }],
    ['use_lld==1 and OS=="win"', {
      'make_global_settings': [
        # Limited to Windows because lld-link is the driver that is compatible
        # to link.exe.
        ['LD', '<(make_clang_dir)/bin/lld-link'],
      ],
    }],
    ['OS=="android" and clang==0', {
      # Hardcode the compiler names in the Makefile so that
      # it won't depend on the environment at make time.
      'make_global_settings': [
        ['CC', '<!(/bin/echo -n <(android_toolchain)/*-gcc)'],
        ['CXX', '<!(/bin/echo -n <(android_toolchain)/*-g++)'],
        ['CC.host', '<(host_cc)'],
        ['CXX.host', '<(host_cxx)'],
      ],
    }],
    ['OS=="linux" and target_arch=="mipsel" and clang==0', {
      'make_global_settings': [
        ['CC', '<(sysroot)/../bin/mipsel-linux-gnu-gcc'],
        ['CXX', '<(sysroot)/../bin/mipsel-linux-gnu-g++'],
        ['CC.host', '<(host_cc)'],
        ['CXX.host', '<(host_cxx)'],
      ],
    }],
    ['OS=="linux" and target_arch=="arm" and host_arch!="arm" and chromeos==0 and clang==0', {
      # Set default ARM cross compiling on linux.  These can be overridden
      # using CC/CXX/etc environment variables.
      'make_global_settings': [
        ['CC', '<!(which arm-linux-gnueabihf-gcc)'],
        ['CXX', '<!(which arm-linux-gnueabihf-g++)'],
        ['CC.host', '<(host_cc)'],
        ['CXX.host', '<(host_cxx)'],
      ],
    }],

    # TODO(yyanagisawa): supports GENERATOR==make
    #  make generator doesn't support CC_wrapper without CC
    #  in make_global_settings yet.
    ['use_goma==1 and ("<(GENERATOR)"=="ninja" or clang==1)', {
      'make_global_settings': [
       ['CC_wrapper', '<(gomadir)/gomacc'],
       ['CXX_wrapper', '<(gomadir)/gomacc'],
       ['CC.host_wrapper', '<(gomadir)/gomacc'],
       ['CXX.host_wrapper', '<(gomadir)/gomacc'],
      ],
    }],
    ['use_lto==1', {
      'target_defaults': {
        'target_conditions': [
          ['_toolset=="target"', {
            'cflags': [
              '-flto',
            ],
            'xcode_settings': {
              'LLVM_LTO': 'YES',
            },
          }],
          # Work-around for http://openradar.appspot.com/20356002
          ['_toolset=="target" and _type!="static_library"', {
            'xcode_settings': {
              'OTHER_LDFLAGS': [
                '-Wl,-all_load',
              ],
            },
          }],
        ],
      },
    }],
    ['use_lto==1 and clang==0', {
      'target_defaults': {
        'target_conditions': [
          ['_toolset=="target"', {
            'cflags': [
              '-ffat-lto-objects',
            ],
          }],
        ],
      },
    }],
    ['use_lto==1 and clang==1', {
      'target_defaults': {
        'target_conditions': [
          ['_toolset=="target"', {
            'arflags': [
              '--plugin', '../../<(make_clang_dir)/lib/LLVMgold.so',
            ],
          }],
        ],
      },
    }],
    # Apply a lower LTO optimization level in non-official builds.
    ['use_lto==1 and clang==1 and buildtype!="Official"', {
      'target_defaults': {
        'target_conditions': [
          ['_toolset=="target"', {
            'ldflags': [
              '-Wl,--plugin-opt,O1',
            ],
          }],
          ['_toolset=="target" and _type!="static_library"', {
            'xcode_settings':  {
              'OTHER_LDFLAGS': [
                '-Wl,-mllvm,-O1',
              ],
            },
          }],
        ],
      },
    }],
    ['use_lto==1 and clang==1 and target_arch=="arm"', {
      'target_defaults': {
        'target_conditions': [
          ['_toolset=="target"', {
            # Without this flag, LTO produces a .text section that is larger
            # than the maximum call displacement, preventing the linker from
            # relocating calls (http://llvm.org/PR22999).
            'ldflags': [
              '-Wl,-plugin-opt,-function-sections',
            ],
          }],
        ],
      },
    }],
    ['(use_lto==1 or use_lto_o2==1) and clang==0', {
      'target_defaults': {
        'target_conditions': [
          ['_toolset=="target"', {
            'ldflags': [
              '-flto=32',
            ],
          }],
        ],
      },
    }],
    ['(use_lto==1 or use_lto_o2==1) and clang==1', {
      'target_defaults': {
        'target_conditions': [
          ['_toolset=="target"', {
            'ldflags': [
              '-flto',
            ],
          }],
        ],
      },
    }],
    ['cfi_vptr==1', {
      'target_defaults': {
        'target_conditions': [
          ['_toolset=="target"', {
            'cflags': [
              '-fsanitize=cfi-vcall',
              '-fsanitize=cfi-derived-cast',
              '-fsanitize=cfi-unrelated-cast',
            ],
            'ldflags': [
              '-fsanitize=cfi-vcall',
              '-fsanitize=cfi-derived-cast',
              '-fsanitize=cfi-unrelated-cast',
            ],
            'xcode_settings': {
              'OTHER_CFLAGS': [
                '-fsanitize=cfi-vcall',
                '-fsanitize=cfi-derived-cast',
                '-fsanitize=cfi-unrelated-cast',
              ],
            },
          }],
          ['_toolset=="target" and _type!="static_library"', {
            'xcode_settings':  {
              'OTHER_LDFLAGS': [
                '-fsanitize=cfi-vcall',
                '-fsanitize=cfi-derived-cast',
                '-fsanitize=cfi-unrelated-cast',
              ],
            },
          }],
        ],
      },
    }],
    ['cfi_vptr==1', {
      'target_defaults': {
        'target_conditions': [
          ['_toolset=="target"', {
            'cflags': [
              '-fsanitize-blacklist=<(cfi_blacklist)',
            ],
            'xcode_settings': {
              'OTHER_CFLAGS': [
                '-fsanitize-blacklist=<(cfi_blacklist)',
              ],
            },
          }],
        ],
      },
    }],
  ],
  'xcode_settings': {
    # DON'T ADD ANYTHING NEW TO THIS BLOCK UNLESS YOU REALLY REALLY NEED IT!
    # This block adds *project-wide* configuration settings to each project
    # file.  It's almost always wrong to put things here.  Specify your
    # custom xcode_settings in target_defaults to add them to targets instead.

    'conditions': [
      # In an Xcode Project Info window, the "Base SDK for All Configurations"
      # setting sets the SDK on a project-wide basis. In order to get the
      # configured SDK to show properly in the Xcode UI, SDKROOT must be set
      # here at the project level.
      ['OS=="mac"', {
        'conditions': [
          ['mac_sdk_path==""', {
            'SDKROOT': 'macosx<(mac_sdk)',  # -isysroot
          }, {
            'SDKROOT': '<(mac_sdk_path)',  # -isysroot
          }],
        ],
      }],
      ['OS=="ios"', {
        'conditions': [
          ['ios_sdk_path==""', {
            'conditions': [
              # TODO(justincohen): Ninja only supports simulator for now.
              ['"<(GENERATOR)"=="xcode"', {
                'SDKROOT': 'iphoneos<(ios_sdk)',  # -isysroot
              }, {
                'SDKROOT': 'iphonesimulator<(ios_sdk)',  # -isysroot
              }],
            ],
          }, {
            'SDKROOT': '<(ios_sdk_path)',  # -isysroot
          }],
        ],
      }],
      ['OS=="ios"', {
        # Target both iPhone and iPad.
        'TARGETED_DEVICE_FAMILY': '1,2',
      }, {  # OS!="ios"
        'conditions': [
          ['target_arch=="x64"', {
            'ARCHS': [
              'x86_64'
            ],
          }],
          ['target_arch=="ia32"', {
            'ARCHS': [
              'i386'
            ],
          }],
        ],
      }],
    ],

    # The Xcode generator will look for an xcode_settings section at the root
    # of each dict and use it to apply settings on a file-wide basis.  Most
    # settings should not be here, they should be in target-specific
    # xcode_settings sections, or better yet, should use non-Xcode-specific
    # settings in target dicts.  SYMROOT is a special case, because many other
    # Xcode variables depend on it, including variables such as
    # PROJECT_DERIVED_FILE_DIR.  When a source group corresponding to something
    # like PROJECT_DERIVED_FILE_DIR is added to a project, in order for the
    # files to appear (when present) in the UI as actual files and not red
    # red "missing file" proxies, the correct path to PROJECT_DERIVED_FILE_DIR,
    # and therefore SYMROOT, needs to be set at the project level.
    'SYMROOT': '<(DEPTH)/xcodebuild',
  },
}
