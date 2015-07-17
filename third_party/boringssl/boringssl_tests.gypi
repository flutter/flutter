# Copyright (c) 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is created by generate_build_files.py. Do not edit manually.

{
  'targets': [
    {
      'target_name': 'boringssl_aes_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/aes/aes_test.cc',
        '<@(boringssl_test_support_sources)',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_base64_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/base64/base64_test.cc',
        '<@(boringssl_test_support_sources)',
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
        'src/crypto/bio/bio_test.cc',
        '<@(boringssl_test_support_sources)',
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
        'src/crypto/bn/bn_test.cc',
        '<@(boringssl_test_support_sources)',
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
        'src/crypto/bytestring/bytestring_test.cc',
        '<@(boringssl_test_support_sources)',
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
        'src/crypto/cipher/aead_test.cc',
        '<@(boringssl_test_support_sources)',
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
        'src/crypto/cipher/cipher_test.cc',
        '<@(boringssl_test_support_sources)',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_cmac_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/cmac/cmac_test.cc',
        '<@(boringssl_test_support_sources)',
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
        '<@(boringssl_test_support_sources)',
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
        'src/crypto/dh/dh_test.cc',
        '<@(boringssl_test_support_sources)',
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
        'src/crypto/digest/digest_test.cc',
        '<@(boringssl_test_support_sources)',
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
        '<@(boringssl_test_support_sources)',
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
        'src/crypto/ec/ec_test.cc',
        '<@(boringssl_test_support_sources)',
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
        '<@(boringssl_test_support_sources)',
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
        'src/crypto/ecdsa/ecdsa_test.cc',
        '<@(boringssl_test_support_sources)',
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
        'src/crypto/err/err_test.cc',
        '<@(boringssl_test_support_sources)',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_evp_extra_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/evp/evp_extra_test.cc',
        '<@(boringssl_test_support_sources)',
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
        'src/crypto/evp/evp_test.cc',
        '<@(boringssl_test_support_sources)',
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
        'src/crypto/evp/pbkdf_test.cc',
        '<@(boringssl_test_support_sources)',
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
        '<@(boringssl_test_support_sources)',
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
        'src/crypto/hmac/hmac_test.cc',
        '<@(boringssl_test_support_sources)',
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
        '<@(boringssl_test_support_sources)',
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
        '<@(boringssl_test_support_sources)',
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
        'src/crypto/pkcs8/pkcs12_test.cc',
        '<@(boringssl_test_support_sources)',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_poly1305_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/poly1305/poly1305_test.cc',
        '<@(boringssl_test_support_sources)',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_refcount_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/refcount_test.c',
        '<@(boringssl_test_support_sources)',
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
        'src/crypto/rsa/rsa_test.cc',
        '<@(boringssl_test_support_sources)',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_thread_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/thread_test.c',
        '<@(boringssl_test_support_sources)',
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
        '<@(boringssl_test_support_sources)',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_tab_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/x509v3/tab_test.c',
        '<@(boringssl_test_support_sources)',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
    {
      'target_name': 'boringssl_v3name_test',
      'type': 'executable',
      'dependencies': [
        'boringssl.gyp:boringssl',
      ],
      'sources': [
        'src/crypto/x509v3/v3name_test.c',
        '<@(boringssl_test_support_sources)',
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
        '<@(boringssl_test_support_sources)',
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
        'src/ssl/ssl_test.cc',
        '<@(boringssl_test_support_sources)',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
    },
  ],
  'variables': {
    'boringssl_test_support_sources': [
      'src/crypto/test/file_test.cc',
      'src/crypto/test/malloc.cc',
    ],
    'boringssl_test_targets': [
      'boringssl_aead_test',
      'boringssl_aes_test',
      'boringssl_base64_test',
      'boringssl_bio_test',
      'boringssl_bn_test',
      'boringssl_bytestring_test',
      'boringssl_cipher_test',
      'boringssl_cmac_test',
      'boringssl_constant_time_test',
      'boringssl_dh_test',
      'boringssl_digest_test',
      'boringssl_dsa_test',
      'boringssl_ec_test',
      'boringssl_ecdsa_test',
      'boringssl_err_test',
      'boringssl_evp_extra_test',
      'boringssl_evp_test',
      'boringssl_example_mul',
      'boringssl_gcm_test',
      'boringssl_hkdf_test',
      'boringssl_hmac_test',
      'boringssl_lhash_test',
      'boringssl_pbkdf_test',
      'boringssl_pkcs12_test',
      'boringssl_pkcs7_test',
      'boringssl_poly1305_test',
      'boringssl_pqueue_test',
      'boringssl_refcount_test',
      'boringssl_rsa_test',
      'boringssl_ssl_test',
      'boringssl_tab_test',
      'boringssl_thread_test',
      'boringssl_v3name_test',
    ],
  }
}
