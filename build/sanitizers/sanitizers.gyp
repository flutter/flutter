# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'sanitizer_options',
      'type': 'static_library',
      'toolsets': ['host', 'target'],
      'variables': {
         # Every target is going to depend on sanitizer_options, so allow
         # this one to depend on itself.
         'prune_self_dependency': 1,
         # Do not let 'none' targets depend on this one, they don't need to.
         'link_dependency': 1,
       },
      'sources': [
        'sanitizer_options.cc',
      ],
      'include_dirs': [
        '../..',
      ],
      # Some targets may want to opt-out from ASan, TSan and MSan and link
      # without the corresponding runtime libraries. We drop the libc++
      # dependency and omit the compiler flags to avoid bringing instrumented
      # code to those targets.
      'conditions': [
        ['use_custom_libcxx==1', {
          'dependencies!': [
            '../../buildtools/third_party/libc++/libc++.gyp:libcxx_proxy',
          ],
        }],
        ['tsan==1', {
          'sources': [
            'tsan_suppressions.cc',
          ],
        }],
        ['lsan==1', {
          'sources': [
            'lsan_suppressions.cc',
          ],
        }],
        ['asan==1', {
          'sources': [
            'asan_suppressions.cc',
          ],
        }],
      ],
      'cflags/': [
        ['exclude', '-fsanitize='],
        ['exclude', '-fsanitize-'],
      ],
      'direct_dependent_settings': {
        'ldflags': [
          '-Wl,-u_sanitizer_options_link_helper',
        ],
        'target_conditions': [
          ['_type=="executable"', {
            'xcode_settings': {
              'OTHER_LDFLAGS': [
                '-Wl,-u,__sanitizer_options_link_helper',
              ],
            },
          }],
        ],
      },
    },
    {
      # Copy llvm-symbolizer to the product dir so that LKGR bots can package it.
      'target_name': 'llvm-symbolizer',
      'type': 'none',
      'variables': {

       # Path is relative to this GYP file.
       'llvm_symbolizer_path':
           '../../third_party/llvm-build/Release+Asserts/bin/llvm-symbolizer<(EXECUTABLE_SUFFIX)',
      },
      'conditions': [
        ['clang==1', {
          'copies': [{
            'destination': '<(PRODUCT_DIR)',
            'files': [
              '<(llvm_symbolizer_path)',
            ],
          }],
        }],
      ],
    },
  ],
}

