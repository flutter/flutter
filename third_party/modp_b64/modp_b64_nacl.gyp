# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'includes': [
    '../../native_client/build/untrusted.gypi',
  ],
  'targets': [
    {
      'target_name': 'modp_b64_nacl',
      'type': 'none',
      'variables': {
        'nlib_target': 'libmodp_b64_nacl.a',
        'build_glibc': 0,
        'build_newlib': 1,
        'build_pnacl_newlib': 1,
      },
      'sources': [
        'modp_b64.cc',
        'modp_b64.h',
        'modp_b64_data.h',
      ],
    },
  ],
}
