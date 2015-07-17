# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    'chromium_code': 1,
  },
  'includes': [
    '../native_client/build/untrusted.gypi',
    'crypto.gypi',
  ],
  'targets': [
    {
      'target_name': 'crypto_nacl',
      'type': 'none',
      'variables': {
        'nacl_untrusted_build': 1,
        'nlib_target': 'libcrypto_nacl.a',
        'build_glibc': 0,
        'build_newlib': 0,
        'build_pnacl_newlib': 1,
      },
      'dependencies': [
        '../third_party/boringssl/boringssl_nacl.gyp:boringssl_nacl',
        '../native_client_sdk/native_client_sdk_untrusted.gyp:nacl_io_untrusted',
      ],
      'defines': [
        'CRYPTO_IMPLEMENTATION',
      ],
      'sources': [
        '<@(crypto_sources)',
      ],
      'sources/': [
        ['exclude', '_nss\.(cc|h)$'],
        ['exclude', '^(mock_)?apple_'],
        ['exclude', '^capi_'],
        ['exclude', '^cssm_'],
        ['exclude', '^nss_'],
        ['exclude', '^mac_'],
        ['exclude', '^third_party/nss/'],
        ['include', '^third_party/nss/sha512.cc'],
      ],
    },
  ],
}
