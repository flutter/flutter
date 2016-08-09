# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'includes': [
    '../../build/common_untrusted.gypi',
  ],
  'conditions': [
    ['disable_nacl==0 and disable_nacl_untrusted==0', {
      'targets': [
        {
          'target_name': 'event_nacl_nonsfi',
          'type': 'none',
          'sources': [
            'buffer.c',
            'evbuffer.c',
            'event.c',
            'evutil.c',
            'log.c',
            'poll.c',
            'strlcpy.c',
            'nacl_nonsfi/config.h',
            'nacl_nonsfi/event-config.h',
            'nacl_nonsfi/random.c',
            'nacl_nonsfi/signal_stub.c',
          ],
          'defines': [
            'HAVE_CONFIG_H',
          ],
          'include_dirs': [
            'nacl_nonsfi',
          ],
          'variables': {
            'nacl_untrusted_build': 1,
            'nlib_target': 'libevent_nacl_nonsfi.a',
            'build_glibc': 0,
            'build_newlib': 0,
            'build_irt': 0,
            'build_pnacl_newlib': 0,
            'build_nonsfi_helper': 1,
          },
        },
      ],
    }],
  ],
}
