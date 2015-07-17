# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    'verbose_libraries_build%': 0,
    'instrumented_libraries_jobs%': 1,
    'instrumented_libraries_cc%': '<!(cd <(DEPTH) && pwd -P)/<(make_clang_dir)/bin/clang',
    'instrumented_libraries_cxx%': '<!(cd <(DEPTH) && pwd -P)/<(make_clang_dir)/bin/clang++',
  },

  'libdir': 'lib',
  'ubuntu_release': '<!(lsb_release -cs)',

  'conditions': [
    ['asan==1', {
      'sanitizer_type': 'asan',
    }],
    ['msan==1', {
      'sanitizer_type': 'msan',
    }],
    ['tsan==1', {
      'sanitizer_type': 'tsan',
    }],
    ['use_goma==1', {
      'cc': '<(gomadir)/gomacc <(instrumented_libraries_cc)',
      'cxx': '<(gomadir)/gomacc <(instrumented_libraries_cxx)',
    }, {
      'cc': '<(instrumented_libraries_cc)',
      'cxx': '<(instrumented_libraries_cxx)',
    }],
  ],

  'target_defaults': {
    'build_method': 'destdir',
    # Every package must have --disable-static in configure flags to avoid
    # building unnecessary static libs. Ideally we should add it here.
    # Unfortunately, zlib1g doesn't support that flag and for some reason it
    # can't be removed with a GYP exclusion list. So instead we add that flag
    # manually to every package but zlib1g.
    'extra_configure_flags': [],
    'jobs': '<(instrumented_libraries_jobs)',
    'package_cflags': [
      '-O2',
      '-gline-tables-only',
      '-fPIC',
      '-w',
      '-U_FORITFY_SOURCE',
      '-fno-omit-frame-pointer'
    ],
    'package_ldflags': [
      '-Wl,-z,origin',
      # We set RPATH=XORIGIN when building the package and replace it with
      # $ORIGIN later. The reason is that this flag goes through configure/make
      # differently for different packages. Because of this, we can't escape the
      # $ character in a way that would work for every package.
      '-Wl,-R,XORIGIN/.'
    ],
    'patch': '',
    'pre_build': '',
    'asan_blacklist': '',
    'msan_blacklist': '',
    'tsan_blacklist': '',

    'conditions': [
      ['asan==1', {
        'package_cflags': ['-fsanitize=address'],
        'package_ldflags': ['-fsanitize=address'],
      }],
      ['msan==1', {
        'package_cflags': [
          '-fsanitize=memory',
          '-fsanitize-memory-track-origins=<(msan_track_origins)'
        ],
        'package_ldflags': ['-fsanitize=memory'],
      }],
      ['tsan==1', {
        'package_cflags': ['-fsanitize=thread'],
        'package_ldflags': ['-fsanitize=thread'],
      }],
    ],
  },

  'targets': [
    {
      'target_name': 'prebuilt_instrumented_libraries',
      'type': 'none',
      'variables': {
        'prune_self_dependency': 1,
        # Don't add this target to the dependencies of targets with type=none.
        'link_dependency': 1,
        'conditions': [
          ['msan==1', {
            'conditions': [
              ['msan_track_origins==2', {
                'archive_prefix': 'msan-chained-origins',
              }, {
                'conditions': [
                  ['msan_track_origins==0', {
                    'archive_prefix': 'msan-no-origins',
                  }, {
                    'archive_prefix': 'UNSUPPORTED_CONFIGURATION'
                  }],
              ]}],
          ]}, {
              'archive_prefix': 'UNSUPPORTED_CONFIGURATION'
          }],
        ],
      },
      'actions': [
        {
          'action_name': 'unpack_<(archive_prefix)-<(_ubuntu_release).tgz',
          'inputs': [
            'binaries/<(archive_prefix)-<(_ubuntu_release).tgz',
          ],
          'outputs': [
            '<(PRODUCT_DIR)/instrumented_libraries_prebuilt/<(archive_prefix).txt',
          ],
          'action': [
            'scripts/unpack_binaries.py',
            '<(archive_prefix)',
            'binaries',
            '<(PRODUCT_DIR)/instrumented_libraries_prebuilt/',
          ],
        },
      ],
      'direct_dependent_settings': {
        'target_conditions': [
          ['_toolset=="target"', {
            'ldflags': [
              # Add a relative RPATH entry to Chromium binaries. This puts
              # instrumented DSOs before system-installed versions in library
              # search path.
              '-Wl,-R,\$$ORIGIN/instrumented_libraries_prebuilt/<(_sanitizer_type)/<(_libdir)/',
              '-Wl,-z,origin',
            ],
          }],
        ],
      },
    },
    {
      'target_name': 'instrumented_libraries',
      'type': 'none',
      'variables': {
        'prune_self_dependency': 1,
        # Don't add this target to the dependencies of targets with type=none.
        'link_dependency': 1,
      },
      # NOTE: Please keep install-build-deps.sh in sync with this list.
      'dependencies': [
        '<(_sanitizer_type)-freetype',
        '<(_sanitizer_type)-libcairo2',
        '<(_sanitizer_type)-libexpat1',
        '<(_sanitizer_type)-libffi6',
        '<(_sanitizer_type)-libgcrypt11',
        '<(_sanitizer_type)-libgpg-error0',
        '<(_sanitizer_type)-libnspr4',
        '<(_sanitizer_type)-libp11-kit0',
        '<(_sanitizer_type)-libpcre3',
        '<(_sanitizer_type)-libpng12-0',
        '<(_sanitizer_type)-libx11-6',
        '<(_sanitizer_type)-libxau6',
        '<(_sanitizer_type)-libxcb1',
        '<(_sanitizer_type)-libxcomposite1',
        '<(_sanitizer_type)-libxcursor1',
        '<(_sanitizer_type)-libxdamage1',
        '<(_sanitizer_type)-libxdmcp6',
        '<(_sanitizer_type)-libxext6',
        '<(_sanitizer_type)-libxfixes3',
        '<(_sanitizer_type)-libxi6',
        '<(_sanitizer_type)-libxinerama1',
        '<(_sanitizer_type)-libxrandr2',
        '<(_sanitizer_type)-libxrender1',
        '<(_sanitizer_type)-libxss1',
        '<(_sanitizer_type)-libxtst6',
        '<(_sanitizer_type)-zlib1g',
        '<(_sanitizer_type)-libglib2.0-0',
        '<(_sanitizer_type)-libdbus-1-3',
        '<(_sanitizer_type)-libdbus-glib-1-2',
        '<(_sanitizer_type)-nss',
        '<(_sanitizer_type)-libfontconfig1',
        '<(_sanitizer_type)-pulseaudio',
        '<(_sanitizer_type)-libasound2',
        '<(_sanitizer_type)-pango1.0',
        '<(_sanitizer_type)-libcap2',
        '<(_sanitizer_type)-udev',
        '<(_sanitizer_type)-libgnome-keyring0',
        '<(_sanitizer_type)-libgtk2.0-0',
        '<(_sanitizer_type)-libgdk-pixbuf2.0-0',
        '<(_sanitizer_type)-libpci3',
        '<(_sanitizer_type)-libdbusmenu-glib4',
        '<(_sanitizer_type)-libgconf-2-4',
        '<(_sanitizer_type)-libappindicator1',
        '<(_sanitizer_type)-libdbusmenu',
        '<(_sanitizer_type)-atk1.0',
        '<(_sanitizer_type)-libunity9',
        '<(_sanitizer_type)-dee',
        '<(_sanitizer_type)-libpixman-1-0',
        '<(_sanitizer_type)-brltty',
        '<(_sanitizer_type)-libva1',
      ],
      'conditions': [
        ['"<(_ubuntu_release)"=="precise"', {
          'dependencies': [
            '<(_sanitizer_type)-libtasn1-3',
          ],
        }, {
          'dependencies': [
            # Trusty and above.
            '<(_sanitizer_type)-libtasn1-6',
            '<(_sanitizer_type)-harfbuzz',
            '<(_sanitizer_type)-libsecret',
          ],
        }],
        ['msan==1', {
          'dependencies': [
            '<(_sanitizer_type)-libcups2',
          ],
        }],
        ['tsan==1', {
          'dependencies!': [
            '<(_sanitizer_type)-libpng12-0',
          ],
        }],
      ],
      'direct_dependent_settings': {
        'target_conditions': [
          ['_toolset=="target"', {
            'ldflags': [
              # Add a relative RPATH entry to Chromium binaries. This puts
              # instrumented DSOs before system-installed versions in library
              # search path.
              '-Wl,-R,\$$ORIGIN/instrumented_libraries/<(_sanitizer_type)/<(_libdir)/',
              '-Wl,-z,origin',
            ],
          }],
        ],
      },
    },
    {
      'package_name': 'freetype',
      'dependencies=': [],
      'extra_configure_flags': ['--disable-static'],
      'pre_build': 'scripts/pre-build/freetype.sh',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libcairo2',
      'dependencies=': [],
      'extra_configure_flags': [
          '--disable-gtk-doc',
          '--disable-static',
      ],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libdbus-1-3',
      'dependencies=': [],
      'extra_configure_flags': [
        '--disable-static',
        # From debian/rules.
        '--disable-libaudit',
        '--enable-apparmor',
        '--enable-systemd',
        '--libexecdir=/lib/dbus-1.0',
        '--with-systemdsystemunitdir=/lib/systemd/system',
        '--disable-tests',
        '--exec-prefix=/',
        # From dh_auto_configure.
        '--prefix=/usr',
        '--localstatedir=/var',
      ],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libdbus-glib-1-2',
      'dependencies=': [],
      'extra_configure_flags': [
          # Use system dbus-binding-tool. The just-built one is instrumented but
          # doesn't have the correct RPATH, and will crash.
          '--with-dbus-binding-tool=dbus-binding-tool',
          '--disable-static',
      ],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libexpat1',
      'dependencies=': [],
      'extra_configure_flags': ['--disable-static'],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libffi6',
      'dependencies=': [],
      'extra_configure_flags': ['--disable-static'],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libfontconfig1',
      'dependencies=': [],
      'extra_configure_flags': [
        '--disable-docs',
        '--sysconfdir=/etc/',
        '--disable-static',
        # From debian/rules.
        '--with-add-fonts=/usr/X11R6/lib/X11/fonts,/usr/local/share/fonts',
      ],
      'conditions': [
        ['"<(_ubuntu_release)"=="precise"', {
          'patch': 'patches/libfontconfig.precise.diff',
        }, {
          'patch': 'patches/libfontconfig.trusty.diff',
        }],
      ],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libgcrypt11',
      'dependencies=': [],
      'package_ldflags': ['-Wl,-z,muldefs'],
      'extra_configure_flags': [
        # From debian/rules.
        '--enable-noexecstack',
        '--enable-ld-version-script',
        '--disable-static',
        # http://crbug.com/344505
        '--disable-asm'
      ],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libglib2.0-0',
      'dependencies=': [],
      'extra_configure_flags': [
        '--disable-gtk-doc',
        '--disable-gtk-doc-html',
        '--disable-gtk-doc-pdf',
        '--disable-static',
      ],
      'asan_blacklist': 'blacklists/asan/libglib2.0-0.txt',
      'msan_blacklist': 'blacklists/msan/libglib2.0-0.txt',
      'pre_build': 'scripts/pre-build/autogen.sh',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libgpg-error0',
      'dependencies=': [],
      'extra_configure_flags': ['--disable-static'],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libnspr4',
      'dependencies=': [],
      'extra_configure_flags': [
        '--enable-64bit',
        '--disable-static',
        # TSan reports data races on debug variables.
        '--disable-debug',
      ],
      'pre_build': 'scripts/pre-build/libnspr4.sh',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libp11-kit0',
      'dependencies=': [],
      'extra_configure_flags': ['--disable-static'],
      # Required on Trusty due to autoconf version mismatch.
      'pre_build': 'scripts/pre-build/autoreconf.sh',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libpcre3',
      'dependencies=': [],
      'extra_configure_flags': [
        '--enable-utf8',
        '--enable-unicode-properties',
        '--disable-static',
      ],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libpixman-1-0',
      'dependencies=': [],
      'extra_configure_flags': [
        '--disable-static',
        # From debian/rules.
        '--disable-gtk',
        '--disable-silent-rules',
        # Avoid a clang issue. http://crbug.com/449183
        '--disable-mmx',
      ],
      'patch': 'patches/libpixman-1-0.diff',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libpng12-0',
      'dependencies=': [],
      'extra_configure_flags': ['--disable-static'],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libx11-6',
      'dependencies=': [],
      'extra_configure_flags': [
          '--disable-specs',
          '--disable-static',
      ],
      'msan_blacklist': 'blacklists/msan/libx11-6.txt',
      # Required on Trusty due to autoconf version mismatch.
      'pre_build': 'scripts/pre-build/autoreconf.sh',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libxau6',
      'dependencies=': [],
      'extra_configure_flags': ['--disable-static'],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libxcb1',
      'dependencies=': [],
      'extra_configure_flags': [
          '--disable-build-docs',
          '--disable-static',
      ],
      'conditions': [
        ['"<(_ubuntu_release)"=="precise"', {
          # Backport fix for https://bugs.freedesktop.org/show_bug.cgi?id=54671
          'patch': 'patches/libxcb1.precise.diff',
        }],
      ],
      # Required on Trusty due to autoconf version mismatch.
      'pre_build': 'scripts/pre-build/autoreconf.sh',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libxcomposite1',
      'dependencies=': [],
      'extra_configure_flags': ['--disable-static'],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libxcursor1',
      'dependencies=': [],
      'extra_configure_flags': ['--disable-static'],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libxdamage1',
      'dependencies=': [],
      'extra_configure_flags': ['--disable-static'],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libxdmcp6',
      'dependencies=': [],
      'extra_configure_flags': [
          '--disable-docs',
          '--disable-static',
      ],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libxext6',
      'dependencies=': [],
      'extra_configure_flags': [
          '--disable-specs',
          '--disable-static',
      ],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libxfixes3',
      'dependencies=': [],
      'extra_configure_flags': ['--disable-static'],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libxi6',
      'dependencies=': [],
      'extra_configure_flags': [
        '--disable-specs',
        '--disable-docs',
        '--disable-static',
      ],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libxinerama1',
      'dependencies=': [],
      'extra_configure_flags': ['--disable-static'],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libxrandr2',
      'dependencies=': [],
      'extra_configure_flags': ['--disable-static'],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libxrender1',
      'dependencies=': [],
      'extra_configure_flags': ['--disable-static'],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libxss1',
      'dependencies=': [],
      'extra_configure_flags': ['--disable-static'],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libxtst6',
      'dependencies=': [],
      'extra_configure_flags': [
          '--disable-specs',
          '--disable-static',
      ],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'zlib1g',
      'dependencies=': [],
      # --disable-static is not supported
      'patch': 'patches/zlib1g.diff',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'nss',
      'dependencies=': [
        # TODO(earthdok): get rid of this dependency
        '<(_sanitizer_type)-libnspr4',
      ],
      'patch': 'patches/nss.diff',
      'build_method': 'custom_nss',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'pulseaudio',
      'dependencies=': [],
      'conditions': [
        ['"<(_ubuntu_release)"=="precise"', {
          'patch': 'patches/pulseaudio.precise.diff',
          'jobs': 1,
        }, {
          # New location of libpulsecommon.
          'package_ldflags': [ '-Wl,-R,XORIGIN/pulseaudio/.' ],
        }],
      ],
      'extra_configure_flags': [
          '--disable-static',
          # From debian/rules.
          '--enable-x11',
          '--disable-hal-compat',
          # Disable some ARM-related code that fails compilation. No idea why
          # this even impacts x86-64 builds.
          '--disable-neon-opt'
      ],
      'pre_build': 'scripts/pre-build/pulseaudio.sh',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libasound2',
      'dependencies=': [],
      'extra_configure_flags': ['--disable-static'],
      'pre_build': 'scripts/pre-build/libasound2.sh',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libcups2',
      'dependencies=': [],
      'patch': 'patches/libcups2.diff',
      'jobs': 1,
      'extra_configure_flags': [
        '--disable-static',
        # All from debian/rules.
        '--localedir=/usr/share/cups/locale',
        '--enable-slp',
        '--enable-libpaper',
        '--enable-ssl',
        '--enable-gnutls',
        '--disable-openssl',
        '--enable-threads',
        '--enable-debug',
        '--enable-dbus',
        '--with-dbusdir=/etc/dbus-1',
        '--enable-gssapi',
        '--enable-avahi',
        '--with-pdftops=/usr/bin/gs',
        '--disable-launchd',
        '--with-cups-group=lp',
        '--with-system-groups=lpadmin',
        '--with-printcap=/var/run/cups/printcap',
        '--with-log-file-perm=0640',
        '--with-local_protocols="CUPS dnssd"',
        '--with-remote_protocols="CUPS dnssd"',
        '--enable-libusb',
      ],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'pango1.0',
      'dependencies=': [],
      'extra_configure_flags': [
        '--disable-static',
        # Avoid https://bugs.gentoo.org/show_bug.cgi?id=425620
        '--enable-introspection=no',
        # Pango is normally used with dynamically loaded modules. However,
        # ensuring pango is able to find instrumented versions of those modules
        # is a huge pain in the neck. Let's link them statically instead, and
        # hope for the best.
        '--with-included-modules=yes'
      ],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libcap2',
      'dependencies=': [],
      'extra_configure_flags': ['--disable-static'],
      'build_method': 'custom_libcap',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'udev',
      'dependencies=': [],
      'extra_configure_flags': [
          '--disable-static',
          # Without this flag there's a linking step that doesn't honor LDFLAGS
          # and fails.
          # TODO(earthdok): find a better fix.
          '--disable-gudev'
      ],
      'pre_build': 'scripts/pre-build/udev.sh',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libtasn1-3',
      'dependencies=': [],
      'extra_configure_flags': [
          '--disable-static',
          # From debian/rules.
          '--enable-ld-version-script',
      ],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libtasn1-6',
      'dependencies=': [],
      'extra_configure_flags': [
          '--disable-static',
          # From debian/rules.
          '--enable-ld-version-script',
      ],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libgnome-keyring0',
      'extra_configure_flags': [
          '--disable-static',
          '--enable-tests=no',
          # Make the build less problematic.
          '--disable-introspection',
      ],
      'package_ldflags': ['-Wl,--as-needed'],
      'dependencies=': [],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libgtk2.0-0',
      'package_cflags': ['-Wno-return-type'],
      'extra_configure_flags': [
          '--disable-static',
          # From debian/rules.
          '--prefix=/usr',
          '--sysconfdir=/etc',
          '--enable-test-print-backend',
          '--enable-introspection=no',
          '--with-xinput=yes',
      ],
      'dependencies=': [],
      'conditions': [
        ['"<(_ubuntu_release)"=="precise"', {
          'patch': 'patches/libgtk2.0-0.precise.diff',
        }, {
          'patch': 'patches/libgtk2.0-0.trusty.diff',
        }],
      ],
      'pre_build': 'scripts/pre-build/libgtk2.0-0.sh',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libgdk-pixbuf2.0-0',
      'extra_configure_flags': [
          '--disable-static',
          # From debian/rules.
          '--with-libjasper',
          '--with-x11',
          # Make the build less problematic.
          '--disable-introspection',
          # Do not use loadable modules. Same as with Pango, there's no easy way
          # to make gdk-pixbuf pick instrumented versions over system-installed
          # ones.
          '--disable-modules',
      ],
      'dependencies=': [],
      'pre_build': 'scripts/pre-build/libgdk-pixbuf2.0-0.sh',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libpci3',
      'dependencies=': [],
      'extra_configure_flags': ['--disable-static'],
      'build_method': 'custom_libpci3',
      'jobs': 1,
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libdbusmenu-glib4',
      'extra_configure_flags': [
          '--disable-static',
          # From debian/rules.
          '--disable-scrollkeeper',
          '--enable-gtk-doc',
          # --enable-introspection introduces a build step that attempts to run
          # a just-built binary and crashes. Vala requires introspection.
          # TODO(earthdok): find a better fix.
          '--disable-introspection',
          '--disable-vala',
      ],
      'dependencies=': [],
      'pre_build': 'scripts/pre-build/autogen.sh',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libgconf-2-4',
      'extra_configure_flags': [
          '--disable-static',
          # From debian/rules. (Even though --with-gtk=3.0 doesn't make sense.)
          '--with-gtk=3.0',
          '--disable-orbit',
          # See above.
          '--disable-introspection',
      ],
      'dependencies=': [],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libappindicator1',
      'extra_configure_flags': [
          '--disable-static',
          # See above.
          '--disable-introspection',
      ],
      'dependencies=': [],
      'jobs': 1,
      'pre_build': 'scripts/pre-build/autogen.sh',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libdbusmenu',
      'extra_configure_flags': [
          '--disable-static',
          # From debian/rules.
          '--disable-scrollkeeper',
          '--with-gtk=2',
          # See above.
          '--disable-introspection',
          '--disable-vala',
      ],
      'dependencies=': [],
      'pre_build': 'scripts/pre-build/autogen.sh',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'atk1.0',
      'extra_configure_flags': [
          '--disable-static',
          # See above.
          '--disable-introspection',
      ],
      'dependencies=': [],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libunity9',
      'dependencies=': [],
      'extra_configure_flags': ['--disable-static'],
      'pre_build': 'scripts/pre-build/autogen.sh',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'dee',
      'extra_configure_flags': [
          '--disable-static',
          # See above.
          '--disable-introspection',
      ],
      'dependencies=': [],
      'pre_build': 'scripts/pre-build/autogen.sh',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'harfbuzz',
      'package_cflags': ['-Wno-c++11-narrowing'],
      'extra_configure_flags': [
          '--disable-static',
          # From debian/rules.
          '--with-graphite2=yes',
          '--with-gobject',
          # See above.
          '--disable-introspection',
      ],
      'dependencies=': [],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'brltty',
      'extra_configure_flags': [
          '--disable-static',
          # From debian/rules.
          '--without-viavoice',
          '--without-theta',
          '--without-swift',
          '--bindir=/sbin',
          '--with-curses=ncursesw',
          '--disable-stripping',
          # We don't need any of those.
          '--disable-java-bindings',
          '--disable-lisp-bindings',
          '--disable-ocaml-bindings',
          '--disable-python-bindings',
          '--disable-tcl-bindings'
      ],
      'dependencies=': [],
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libva1',
      'dependencies=': [],
      'extra_configure_flags': ['--disable-static'],
      # Backport a use-after-free fix:
      # http://cgit.freedesktop.org/libva/diff/va/va.c?h=staging&id=d4988142a3f2256e38c5c5cdcdfc1b4f5f3c1ea9
      'patch': 'patches/libva1.diff',
      'pre_build': 'scripts/pre-build/libva1.sh',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
    {
      'package_name': 'libsecret',
      'dependencies=': [],
      'extra_configure_flags': [
          '--disable-static',
          # See above.
          '--disable-introspection',
      ],
      'pre_build': 'scripts/pre-build/autoreconf.sh',
      'includes': ['standard_instrumented_package_target.gypi'],
    },
  ],
}
