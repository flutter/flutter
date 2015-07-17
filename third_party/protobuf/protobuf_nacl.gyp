# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'includes': [
    '../../native_client/build/untrusted.gypi',
  ],
  'targets': [
    {
      'target_name': 'protobuf_lite_nacl',
      'type': 'none',
      'variables': {
        'nlib_target': 'libprotobuf_lite_nacl.a',
        'build_glibc': 0,
        'build_newlib': 0,
        'build_pnacl_newlib': 1,
        'config_h_dir': '.',
      },
      'pnacl_compile_flags': [
        # This disables #warning in hash_map/hash_set headers which are
        # deprecated but still used in protobuf.
        #
        # TODO(sergeyu): Migrate protobuf to unordered_man and unordered_set
        # and remove this flag.
        '-Wno-#warnings',
      ],
      'includes': [
        'protobuf_lite.gypi',
      ],
    },  # end of target 'protobuf_lite_nacl'
  ]
}
