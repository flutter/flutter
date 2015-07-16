# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'boringssl',
      'type': '<(component)',
      'includes': [
        'boringssl.gypi',
      ],
      'sources': [
        '<@(boringssl_lib_sources)',
      ],
      'defines': [
        'BORINGSSL_IMPLEMENTATION',
        'BORINGSSL_NO_STATIC_INITIALIZER',
      ],
      # TODO(davidben): Fix size_t truncations in BoringSSL.
      # https://crbug.com/429039
      'msvs_disabled_warnings': [ 4267, ],
      'conditions': [
        ['component == "shared_library"', {
          'defines': [
            'BORINGSSL_SHARED_LIBRARY',
          ],
        }],
        ['target_arch == "arm"', {
          'sources': [ '<@(boringssl_linux_arm_sources)' ],
        }],
        ['target_arch == "arm64"', {
          'sources': [ '<@(boringssl_linux_aarch64_sources)' ],
        }],
        ['target_arch == "ia32"', {
          'conditions': [
            ['OS == "mac"', {
              'sources': [ '<@(boringssl_mac_x86_sources)' ],
            }],
            ['OS == "linux" or OS == "android"', {
              'sources': [ '<@(boringssl_linux_x86_sources)' ],
            }],
            ['OS == "win"', {
              'sources': [ '<@(boringssl_win_x86_sources)' ],
              # Windows' assembly is built with Yasm. The other platforms use
              # the platform assembler.
              'variables': {
                'yasm_output_path': '<(SHARED_INTERMEDIATE_DIR)/third_party/boringssl',
              },
              'includes': [
                '../yasm/yasm_compile.gypi',
              ],
            }],
            ['OS != "mac" and OS != "linux" and OS != "win" and OS != "android"', {
              'defines': [ 'OPENSSL_NO_ASM' ],
            }],
          ]
        }],
        ['target_arch == "x64"', {
          'conditions': [
            ['OS == "mac"', {
              'sources': [ '<@(boringssl_mac_x86_64_sources)' ],
            }],
            ['OS == "linux" or OS == "android"', {
              'sources': [ '<@(boringssl_linux_x86_64_sources)' ],
            }],
            ['OS == "win"', {
              'sources': [ '<@(boringssl_win_x86_64_sources)' ],
              # Windows' assembly is built with Yasm. The other platforms use
              # the platform assembler.
              'variables': {
                'yasm_output_path': '<(SHARED_INTERMEDIATE_DIR)/third_party/boringssl',
              },
              'includes': [
                '../yasm/yasm_compile.gypi',
              ],
            }],
            ['OS != "mac" and OS != "linux" and OS != "win" and OS != "android"', {
              'defines': [ 'OPENSSL_NO_ASM' ],
            }],
          ]
        }],
        ['target_arch != "arm" and target_arch != "ia32" and target_arch != "x64" and target_arch != "arm64"', {
          'defines': [ 'OPENSSL_NO_ASM' ],
        }],
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
        'conditions': [
          ['component == "shared_library"', {
            'defines': [
              'BORINGSSL_SHARED_LIBRARY',
            ],
          }],
        ],
      },
    },
  ],
}
