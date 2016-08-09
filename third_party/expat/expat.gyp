# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    'conditions': [
      # On Linux, we implicitly already depend on expat via fontconfig;
      # let's not pull it in twice.
      ['os_posix == 1 and OS != "mac" and OS != "ios" and OS != "android"', {
        'use_system_expat%': 1,
      }, {
        'use_system_expat%': 0,
      }],
    ],
  },
  'target_defaults': {
    'defines': [
      '_LIB',
      'XML_STATIC',  # Compile for static linkage.
    ],
    'include_dirs': [
      'files/lib',
    ],
  },
  'conditions': [
    ['use_system_expat == 1', {
      'targets': [
        {
          'target_name': 'expat',
          'type': 'none',
          'link_settings': {
            'libraries': [
              '-lexpat',
            ],
          },
        },
      ],
    }, {  # else: use_system_expat != 1
      'targets': [
        {
          'target_name': 'expat',
          'type': 'static_library',
          'sources': [
            'files/lib/expat.h',
            'files/lib/xmlparse.c',
            'files/lib/xmlrole.c',
            'files/lib/xmltok.c',
          ],

          # Prefer adding a dependency to expat and relying on the following
          # direct_dependent_settings rule over manually adding the include
          # path.  This is because you'll want any translation units that
          # #include these files to pick up the #defines as well.
          'direct_dependent_settings': {
            'include_dirs': [
              'files/lib'
            ],
            'defines': [
              'XML_STATIC',  # Tell dependants to expect static linkage.
            ],
          },
          'conditions': [
            ['OS=="win"', {
              'defines': [
                'COMPILED_FROM_DSP',
              ],
            }],
            ['OS=="mac" or OS=="ios" or OS=="android" or os_bsd==1', {
              'defines': [
                'HAVE_EXPAT_CONFIG_H',
              ],
            }],
          ],
        },
      ],
    }],
  ],
}
