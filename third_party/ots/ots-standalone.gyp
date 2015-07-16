# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    'gcc_cflags': [
      '-ggdb',
      '-W',
      '-Wall',
      '-Wshadow',
      '-Wno-unused-parameter',
      '-fPIE',
      '-fstack-protector',
    ],
    'gcc_ldflags': [
      '-ggdb',
      '-fpie',
      '-Wl,-z,relro',
      '-Wl,-z,now',
    ],
  },
  'includes': [
    'ots-common.gypi',
  ],
  'target_defaults': {
    'include_dirs': [
      '.',
      'third_party/brotli/dec',
    ],
    'conditions': [
      ['OS=="linux"', {
        'cflags': [
          '<@(gcc_cflags)',
          '-O',
        ],
        'ldflags': [
          '<@(gcc_ldflags)',
        ],
        'defines': [
          '_FORTIFY_SOURCE=2',
        ],
        'link_settings': {
          'libraries': ['-lz'],
        },
      }],
      ['OS=="mac"', {
        'xcode_settings': {
          'GCC_DYNAMIC_NO_PIC': 'NO',            # No -mdynamic-no-pic
          'GCC_SYMBOLS_PRIVATE_EXTERN': 'YES',   # -fvisibility=hidden
          'OTHER_CFLAGS': [
            '<@(gcc_cflags)',
          ],
        },
        'link_settings': {
          'libraries': [
            '/System/Library/Frameworks/ApplicationServices.framework',
            '/usr/lib/libz.dylib'
          ],
        },
      }],
      ['OS=="win"', {
        'link_settings': {
          'libraries': [
            '-lzdll.lib',
          ],
        },
        'msvs_settings': {
          'VCLinkerTool': {
            'AdditionalLibraryDirectories': ['third_party/zlib'],
            'DelayLoadDLLs': ['zlib1.dll'],
          },
        },
        'include_dirs': [
          'third_party/zlib',
        ],
        'defines': [
          'NOMINMAX', # To suppress max/min macro definition.
          'WIN32',
        ],
      }],
    ],
  },
  'targets': [
    {
      'target_name': 'ots',
      'type': 'static_library',
      'sources': [
        '<@(ots_sources)',
      ],
      'dependencies': [
        'third_party/brotli.gyp:brotli',
      ],
      'include_dirs': [
        '<@(ots_include_dirs)',
      ],
      'direct_dependent_settings': {
        'include_dirs': [
          '<@(ots_include_dirs)',
        ],
      },
    },
    {
      'target_name': 'freetype2',
      'type': 'none',
      'conditions': [
        ['OS=="linux"', {
          'direct_dependent_settings': {
            'cflags': [
              '<!(pkg-config freetype2 --cflags)',
            ],
            'link_settings': {
              'libraries': [
                '<!(pkg-config freetype2 --libs)',
              ],
            },
          },
        }],
      ],
    },
    {
      'target_name': 'idempotent',
      'type': 'executable',
      'sources': [
        'test/idempotent.cc',
      ],
      'dependencies': [
        'ots',
      ],
      'conditions': [
        ['OS=="linux"', {
          'dependencies': [
            'freetype2',
          ]
        }],
        ['OS=="win"', {
          'link_settings': {
            'libraries': [
              '-lgdi32.lib',
            ],
          },
        }],
      ],
    },
    {
      'target_name': 'ot-sanitise',
      'type': 'executable',
      'sources': [
        'test/ot-sanitise.cc',
        'test/file-stream.h',
      ],
      'dependencies': [
        'ots',
      ],
    },
  ],
  'conditions': [
    ['OS=="linux" or OS=="mac"', {
      'targets': [
        {
          'target_name': 'validator_checker',
          'type': 'executable',
          'sources': [
            'test/validator-checker.cc',
          ],
          'dependencies': [
            'ots',
          ],
          'conditions': [
            ['OS=="linux"', {
              'dependencies': [
                'freetype2',
              ]
            }],
          ],
        },
        {
          'target_name': 'perf',
          'type': 'executable',
          'sources': [
            'test/perf.cc',
          ],
          'dependencies': [
            'ots',
          ],
        },
        {
          'target_name': 'cff_type2_charstring_test',
          'type': 'executable',
          'sources': [
            'test/cff_type2_charstring_test.cc',
          ],
          'dependencies': [
            'ots',
          ],
          'libraries': [
            '-lgtest',
            '-lgtest_main',
          ],
          'include_dirs': [
            'src',
          ],
        },
        {
          'target_name': 'layout_common_table_test',
          'type': 'executable',
          'sources': [
            'test/layout_common_table_test.cc',
          ],
          'dependencies': [
            'ots',
          ],
          'libraries': [
            '-lgtest',
            '-lgtest_main',
          ],
          'include_dirs': [
            'src',
          ],
        },
        {
          'target_name': 'table_dependencies_test',
          'type': 'executable',
          'sources': [
            'test/table_dependencies_test.cc',
          ],
          'dependencies': [
            'ots',
          ],
          'libraries': [
            '-lgtest',
            '-lgtest_main',
          ],
          'include_dirs': [
            'src',
          ],
        },
      ],
    }],
    ['OS=="linux"', {
      'targets': [
        {
          'target_name': 'side_by_side',
          'type': 'executable',
          'sources': [
            'test/side-by-side.cc',
          ],
          'dependencies': [
            'freetype2',
            'ots',
          ],
        },
      ],
    }],
  ],
}
