# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    'chromium_code': 1,
  },
  'includes': [
    '../build/common_untrusted.gypi',
    'url_srcs.gypi',
  ],
  'targets': [
    {
      'target_name': 'url_nacl',
      'type': 'none',
      'variables': {
        'nlib_target': 'liburl_nacl.a',
        'build_glibc': 0,
        'build_newlib': 0,
        'build_pnacl_newlib': 1,
      },
      'dependencies': [
        '../third_party/icu/icu_nacl.gyp:icudata_nacl',
        '../third_party/icu/icu_nacl.gyp:icui18n_nacl',
        '../third_party/icu/icu_nacl.gyp:icuuc_nacl',
      ],
      'export_dependent_settings': [
        '../third_party/icu/icu_nacl.gyp:icui18n_nacl',
        '../third_party/icu/icu_nacl.gyp:icuuc_nacl',
      ],
      'sources': [
        '<@(gurl_sources)',
      ],
    },  # end of target 'url_nacl'
  ],
}
