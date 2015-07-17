# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    'chromium_code': 1,
  },
  'includes': [
    # base.gypi must be included before common_untrusted.gypi.
    #
    # TODO(sergeyu): Replace the target_defaults magic in base.gypi with a
    # sources variables lists. That way order of includes will not matter.
    'base.gypi',
    '../build/common_untrusted.gypi',
  ],
  'conditions': [
    ['disable_nacl==0 and disable_nacl_untrusted==0', {
      'targets': [
        {
          'target_name': 'base_nacl',
          'type': 'none',
          'variables': {
            'base_target': 1,
            'nacl_untrusted_build': 1,
            'nlib_target': 'libbase_nacl.a',
            'build_glibc': 0,
            'build_newlib': 0,
            'build_irt': 1,
            'build_pnacl_newlib': 1,
            'sources': [
              'base_switches.cc',
              'base_switches.h',
              'strings/string16.cc',
              'sync_socket_nacl.cc',
              'time/time_posix.cc',
            ],
            'gcc_compile_flags': [
              '-fno-strict-aliasing',
            ],
          },
        },
        {
          'target_name': 'base_i18n_nacl',
          'type': 'none',
          'variables': {
            'base_i18n_target': 1,
            'nacl_untrusted_build': 1,
            'nlib_target': 'libbase_i18n_nacl.a',
            'build_glibc': 0,
            'build_newlib': 0,
            'build_irt': 0,
            'build_pnacl_newlib': 1,
            'sources': [
              'base_switches.cc',
              'base_switches.h',
              'strings/string16.cc',
              'sync_socket_nacl.cc',
              'time/time_posix.cc',
            ],
          },
          'dependencies': [
            '../third_party/icu/icu_nacl.gyp:icudata_nacl',
            '../third_party/icu/icu_nacl.gyp:icui18n_nacl',
            '../third_party/icu/icu_nacl.gyp:icuuc_nacl',
          ],
        },
        {
          'target_name': 'base_nacl_nonsfi',
          'type': 'none',
          'variables': {
            'base_target': 1,
            'nacl_untrusted_build': 1,
            'nlib_target': 'libbase_nacl_nonsfi.a',
            'build_glibc': 0,
            'build_newlib': 0,
            'build_irt': 0,
            'build_pnacl_newlib': 0,
            'build_nonsfi_helper': 1,

            'sources': [
              'base_switches.cc',
              'base_switches.h',

              # For PathExists and ReadFromFD.
              'files/file_util.cc',
              'files/file_util_posix.cc',

              # For MessageLoopForIO based on libevent.
              'message_loop/message_pump_libevent.cc',
              'message_loop/message_pump_libevent.h',

              # For UnixDomainSocket::SendMsg and RecvMsg.
              'posix/unix_domain_socket_linux.cc',

              # For GetKnownDeadTerminationStatus and GetTerminationStatus.
              'process/kill_posix.cc',

              # For ForkWithFlags.
              'process/launch.h',
              'process/launch_posix.cc',

              # Unlike libbase_nacl, for Non-SFI build, we need to use
              # rand_util_posix for random implementation, instead of
              # rand_util_nacl.cc, which is based on IRT. rand_util_nacl.cc is
              # excluded below.
              'rand_util_posix.cc',

              # For CancelableSyncSocket.
              'sync_socket_nacl.cc',
            ],
          },
          'sources!': [
            'rand_util_nacl.cc',
          ],
          'dependencies': [
            '../third_party/libevent/libevent_nacl_nonsfi.gyp:event_nacl_nonsfi',
          ],
        },
        {
          'target_name': 'test_support_base_nacl_nonsfi',
          'type': 'none',
          'variables': {
            'nacl_untrusted_build': 1,
            'nlib_target': 'libtest_support_base_nacl_nonsfi.a',
            'build_glibc': 0,
            'build_newlib': 0,
            'build_irt': 0,
            'build_pnacl_newlib': 0,
            'build_nonsfi_helper': 1,

            'sources': [
              'test/gtest_util.cc',
              'test/launcher/unit_test_launcher_nacl_nonsfi.cc',
              'test/gtest_xml_unittest_result_printer.cc',
              'test/test_switches.cc',
            ],
          },
          'dependencies': [
            'base_nacl_nonsfi',
            '../testing/gtest_nacl.gyp:gtest_nacl',
          ],
        },
      ],
    }],
  ],
}
