# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'qcms',
      'product_name': 'qcms',
      'type': 'static_library',
      'sources': [
        'src/chain.c',
        'src/chain.h',
        'src/iccread.c',
        'src/matrix.c',
        'src/matrix.h',
        'src/qcms.h',
        'src/qcmsint.h',
        'src/qcmstypes.h',
        'src/transform.c',
        'src/transform_util.c',
        'src/transform_util.h',
      ],
      'direct_dependent_settings': {
        'include_dirs': [
          './src',
        ],
      },
      # Warning (sign-conversion) fixed upstream by large refactoring. Can be
      # removed on next roll.
      'msvs_disabled_warnings': [ 4018 ],

      'conditions': [
        ['target_arch=="ia32" or target_arch=="x64"', {
          'defines': [
            'SSE2_ENABLE',
          ],
          'sources': [
            'src/transform-sse1.c',
            'src/transform-sse2.c',
          ],
        }],
        # QCMS assumes this target isn't compiled since MSVC x64 doesn't support
        # the MMX intrinsics present in the SSE1 code.
        ['OS=="win" and target_arch=="x64"', {
          'sources!': [
            'src/transform-sse1.c',
          ],
        }],
        ['OS == "win"', {
          'msvs_disabled_warnings': [
            4056,  # overflow in floating-point constant arithmetic (INFINITY)
            4756,  # overflow in constant arithmetic (INFINITY)
          ],
        }],
      ],
    },
  ],
}

# Local Variables:
# tab-width:2
# indent-tabs-mode:nil
# End:
# vim: set expandtab tabstop=2 shiftwidth=2:
