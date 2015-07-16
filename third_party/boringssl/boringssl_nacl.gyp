# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
{
  'includes': [
    '../../native_client/build/untrusted.gypi',
  ],
  'targets': [
    {
      'target_name': 'boringssl_nacl',
      'type': 'none',
      'variables': {
        'nlib_target': 'libboringssl_nacl.a',
        'build_glibc': 0,
        'build_newlib': 0,
        'build_pnacl_newlib': 1,
      },
      'dependencies': [
        '<(DEPTH)/native_client/tools.gyp:prep_toolchain',
        '<(DEPTH)/native_client_sdk/native_client_sdk_untrusted.gyp:nacl_io_untrusted',
      ],
      'includes': [
        # Include the auto-generated gypi file.
        'boringssl.gypi'
      ],
      'sources': [
        '<@(boringssl_lib_sources)',
      ],
      'defines': [
        'OPENSSL_NO_ASM',
      ],
      'include_dirs': [
        'src/include',
        # This is for arm_arch.h, which is needed by some asm files. Since the
        # asm files are generated and kept in a different directory, they
        # cannot use relative paths to find this file.
        'src/crypto',
      ],
      'direct_dependent_settings': {
        'include_dirs': [
          'src/include',
        ],
      },
      'pnacl_compile_flags': [
        '-Wno-sometimes-uninitialized',
        '-Wno-unused-variable',
      ],
    },  # target boringssl_nacl
  ],
}
