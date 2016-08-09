# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'includes': [
    '../../native_client/build/untrusted.gypi',
  ],
  'targets': [
    {
      'target_name': 'expat_nacl',
      'type': 'none',
      'variables': {
        'nlib_target': 'libexpat_nacl.a',
        'build_glibc': 0,
        'build_newlib': 0,
        'build_pnacl_newlib': 1,
      },
      'sources': [
        'files/lib/expat.h',
        'files/lib/xmlparse.c',
        'files/lib/xmlrole.c',
        'files/lib/xmltok.c',
      ],
      'include_dirs': [
        'files/lib',
      ],
      'defines': [
        '_LIB',
        'XML_STATIC',
        'HAVE_MEMMOVE',
      ],
      'compile_flags': [
        '-Wno-enum-conversion',
        '-Wno-switch',
      ],
      'direct_dependent_settings': {
        'include_dirs': [
          'files/lib'
        ],
        'defines': [
          'XML_STATIC',  # Tell dependants to expect static linkage.
        ],
      },
    },
  ],
}
