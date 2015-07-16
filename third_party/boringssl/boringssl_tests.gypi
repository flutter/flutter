# Copyright (c) 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is created by update_gypi_and_asm.py. Do not edit manually.

{
  'targets': [
    {
      'target_name': 'boringssl_base64_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/base64/base64_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_bio_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/bio/bio_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_bn_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/bn/bn_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_bytestring_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/bytestring/bytestring_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_aead_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/cipher/aead_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_cipher_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/cipher/cipher_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_constant_time_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/constant_time_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_dh_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/dh/dh_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_digest_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/digest/digest_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_dsa_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/dsa/dsa_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_ec_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/ec/ec_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_example_mul',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/ec/example_mul.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_ecdsa_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/ecdsa/ecdsa_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_err_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/err/err_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_evp_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/evp/evp_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_pbkdf_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/evp/pbkdf_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_hkdf_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/hkdf/hkdf_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_hmac_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/hmac/hmac_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_lhash_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/lhash/lhash_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_gcm_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/modes/gcm_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_pkcs12_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/pkcs8/pkcs12_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_rsa_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/rsa/rsa_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_pkcs7_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/x509/pkcs7_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_pqueue_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/ssl/pqueue/pqueue_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_ssl_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/ssl/ssl_test.c',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
  ],
  'variables': {
    'boringssl_test_targets': [
      'boringssl_aead_test',
      'boringssl_base64_test',
      'boringssl_bio_test',
      'boringssl_bn_test',
      'boringssl_bytestring_test',
      'boringssl_cipher_test',
      'boringssl_constant_time_test',
      'boringssl_dh_test',
      'boringssl_digest_test',
      'boringssl_dsa_test',
      'boringssl_ec_test',
      'boringssl_ecdsa_test',
      'boringssl_err_test',
      'boringssl_evp_test',
      'boringssl_example_mul',
      'boringssl_gcm_test',
      'boringssl_hkdf_test',
      'boringssl_hmac_test',
      'boringssl_lhash_test',
      'boringssl_pbkdf_test',
      'boringssl_pkcs12_test',
      'boringssl_pkcs7_test',
      'boringssl_pqueue_test',
      'boringssl_rsa_test',
      'boringssl_ssl_test',
    ],
  }
}
