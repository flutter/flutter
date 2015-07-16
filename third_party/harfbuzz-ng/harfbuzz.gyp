# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'includes': [
    '../../build/win_precompile.gypi',
  ],
  'variables': {
    'variables': {
      'conditions': [
        ['sysroot!=""', {
          'pkg-config': '<(chroot_cmd) ../../build/linux/pkg-config-wrapper "<(sysroot)" "<(target_arch)" "<(system_libdir)"',
        }, {
          'pkg-config': 'pkg-config'
        }],
      ],
    },

    'pkg-config': '<(pkg-config)',

    'conditions': [
      ['OS=="linux" and (buildtype!="Official" or chromeos==1) and embedded==0', {
        # Since version 1.31.0, pangoft2 which we depend on pulls in harfbuzz
        # anyways. However, we want to have control of the version of harfbuzz
        # we use, so don't use system harfbuzz for official builds, unless we
        # are building for chrome os, where we have the system harfbuzz under
        # control as well.
        'use_system_harfbuzz%': '<!(python ../../build/check_return_value.py <(pkg-config) --atleast-version=1.31.0 pangoft2)',
      }, {
        'use_system_harfbuzz': 0,
      }],
      ['OS=="linux" and target_arch=="arm" and chromeos==0', {
        # Override use_system_harfbuzz for ARM cross compiling so system
        # harfbuzz is not used because the corresponding package is not
        # available.
        'use_system_harfbuzz': 0,
      }],
    ],
  },
  'conditions': [
    ['use_system_harfbuzz==0', {
      'targets': [
        {
          'target_name': 'harfbuzz-ng',
          'type': 'static_library',
          'defines': [
            'HAVE_OT',
            'HAVE_ICU',
            'HAVE_ICU_BUILTIN',
            'HB_NO_MT',
          ],
          'sources': [
            'src/hb-atomic-private.hh',
            'src/hb-blob.cc',
            'src/hb-blob.h',
            'src/hb-buffer.cc',
            'src/hb-buffer-deserialize-json.hh',
            'src/hb-buffer-deserialize-text.hh',
            'src/hb-buffer.h',
            'src/hb-buffer-private.hh',
            'src/hb-buffer-serialize.cc',
            'src/hb-cache-private.hh',
            'src/hb-common.cc',
            'src/hb-common.h',
            'src/hb-deprecated.h',
            'src/hb-face.cc',
            'src/hb-face.h',
            'src/hb-face-private.hh',
            'src/hb-fallback-shape.cc',
            'src/hb-font.cc',
            'src/hb-font.h',
            'src/hb-font-private.hh',
            'src/hb.h',
            'src/hb-icu.cc',
            'src/hb-icu.h',
            'src/hb-mutex-private.hh',
            'src/hb-object-private.hh',
            'src/hb-open-file-private.hh',
            'src/hb-open-type-private.hh',
            'src/hb-ot.h',
            'src/hb-ot-head-table.hh',
            'src/hb-ot-hhea-table.hh',
            'src/hb-ot-hmtx-table.hh',
            'src/hb-ot-layout.cc',
            'src/hb-ot-layout-common-private.hh',
            'src/hb-ot-layout-gdef-table.hh',
            'src/hb-ot-layout-gpos-table.hh',
            'src/hb-ot-layout-gsubgpos-private.hh',
            'src/hb-ot-layout-gsub-table.hh',
            'src/hb-ot-layout.h',
            'src/hb-ot-layout-private.hh',
            'src/hb-ot-map.cc',
            'src/hb-ot-map-private.hh',
            'src/hb-ot-maxp-table.hh',
            'src/hb-ot-name-table.hh',
            'src/hb-ot-shape.cc',
            'src/hb-ot-shape-complex-arabic.cc',
            'src/hb-ot-shape-complex-arabic-fallback.hh',
            'src/hb-ot-shape-complex-arabic-table.hh',
            'src/hb-ot-shape-complex-default.cc',
            'src/hb-ot-shape-complex-hangul.cc',
            'src/hb-ot-shape-complex-hebrew.cc',
            'src/hb-ot-shape-complex-indic.cc',
            'src/hb-ot-shape-complex-indic-machine.hh',
            'src/hb-ot-shape-complex-indic-private.hh',
            'src/hb-ot-shape-complex-indic-table.cc',
            'src/hb-ot-shape-complex-myanmar.cc',
            'src/hb-ot-shape-complex-myanmar-machine.hh',
            'src/hb-ot-shape-complex-private.hh',
            'src/hb-ot-shape-complex-sea.cc',
            'src/hb-ot-shape-complex-sea-machine.hh',
            'src/hb-ot-shape-complex-thai.cc',
            'src/hb-ot-shape-complex-tibetan.cc',
            'src/hb-ot-shape-fallback.cc',
            'src/hb-ot-shape-fallback-private.hh',
            'src/hb-ot-shape.h',
            'src/hb-ot-shape-normalize.cc',
            'src/hb-ot-shape-normalize-private.hh',
            'src/hb-ot-shape-private.hh',
            'src/hb-ot-tag.cc',
            'src/hb-ot-tag.h',
            'src/hb-private.hh',
            'src/hb-set.cc',
            'src/hb-set.h',
            'src/hb-set-private.hh',
            'src/hb-shape.cc',
            'src/hb-shape.h',
            'src/hb-shape-plan.cc',
            'src/hb-shape-plan.h',
            'src/hb-shape-plan-private.hh',
            'src/hb-shaper.cc',
            'src/hb-shaper-impl-private.hh',
            'src/hb-shaper-list.hh',
            'src/hb-shaper-private.hh',
            'src/hb-unicode.cc',
            'src/hb-unicode.h',
            'src/hb-unicode-private.hh',
            'src/hb-utf-private.hh',
            'src/hb-version.h',
            'src/hb-warning.cc',
          ],
          'include_dirs': [
            'src',
          ],
          'direct_dependent_settings': {
            'include_dirs': [
              'src',
            ],
          },
          'dependencies': [
            '../../third_party/icu/icu.gyp:icuuc',
          ],
          'variables': {
            'clang_warning_flags': [ '-Wno-unused-value', ],
          },
          'conditions': [
            ['OS=="win"', {
              # TODO(eae): C4267 on amd64. size_t -> int, size_t -> unsigned int
              'msvs_disabled_warnings': [4267, 4334],
            }],
            ['OS=="mac"', {
              'defines': [
                'HAVE_CORETEXT',
              ],
              'sources': [
                'src/hb-coretext.cc',
                'src/hb-coretext.h',
              ],
            }],
          ],
        },
      ],
    }, {  # use_system_harfbuzz==1
      'targets': [
        {
          'target_name': 'harfbuzz-ng',
          'type': 'none',
          'cflags': [
            '<!@(<(pkg-config) --cflags harfbuzz)',
          ],
          'direct_dependent_settings': {
            'cflags': [
              '<!@(<(pkg-config) --cflags harfbuzz)',
            ],
          },
          'link_settings': {
            'ldflags': [
              '<!@(<(pkg-config) --libs-only-L --libs-only-other harfbuzz)',
            ],
            'libraries': [
              '<!@(<(pkg-config) --libs-only-l harfbuzz)',
            ],
          },
        },
      ],
    }],
  ],
}
