# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'conditions': [
    # In component mode (shared_lib), we build all of skia as a single DLL.
    # However, in the static mode, we need to build skia as multiple targets
    # in order to support the use case where a platform (e.g. Android) may
    # already have a copy of skia as a system library.
    ['component=="static_library"', {
      'targets': [
        {
          'target_name': 'skia_library',
          'type': 'static_library',
          'includes': [
            'skia_library.gypi',
            'skia_common.gypi',
            '../build/android/increase_size_for_speed.gypi',
            # Disable LTO due to compiler error
            # in mems_in_disjoint_alias_sets_p, at alias.c:393
            # crbug.com/422255
            '../build/android/disable_lto.gypi',
          ],
        },
      ],
    }],
    ['component=="static_library"', {
      'targets': [
        {
          'target_name': 'skia',
          'type': 'none',
          'dependencies': [
            'skia_library',
            'skia_chrome',
          ],
          'export_dependent_settings': [
            'skia_library',
            'skia_chrome',
          ],
        },
        {
          'target_name': 'skia_chrome',
          'type': 'static_library',
          'includes': [
            'skia_chrome.gypi',
            'skia_common.gypi',
            '../build/android/increase_size_for_speed.gypi',
          ],
        },
      ],
    },
    {  # component != static_library
      'targets': [
        {
          'target_name': 'skia',
          'type': 'shared_library',
          'includes': [
            'skia_library.gypi',
            'skia_chrome.gypi',
            'skia_common.gypi',
            '../build/android/increase_size_for_speed.gypi',
          ],
          'defines': [
            'SKIA_DLL',
            'SKIA_IMPLEMENTATION=1',
            'GR_GL_IGNORE_ES3_MSAA=0',
          ],
          'direct_dependent_settings': {
            'defines': [
              'SKIA_DLL',
              'GR_GL_IGNORE_ES3_MSAA=0',
            ],
          },
        },
        {
          'target_name': 'skia_library',
          'type': 'none',
        },
        {
          'target_name': 'skia_chrome',
          'type': 'none',
        },
      ],
    }],
  ],

  # targets that are not dependent upon the component type
  'targets': [
    {
      'target_name': 'skia_chrome_opts',
      'type': 'static_library',
      'include_dirs': [
        '..',
        'config',
        '../third_party/skia/include/core',
      ],
      'conditions': [
        [ 'os_posix == 1 and OS != "mac" and OS != "android" and \
            target_arch != "arm" and target_arch != "mipsel" and \
            target_arch != "arm64" and target_arch != "mips64el"', {
          'cflags': [
            '-msse2',
          ],
        }],
        [ 'target_arch != "arm" and target_arch != "mipsel" and \
           target_arch != "arm64" and target_arch != "mips64el"', {
          'sources': [
            'ext/convolver_SSE2.cc',
            'ext/convolver_SSE2.h',
          ],
        }],
        [ 'target_arch == "mipsel" and mips_dsp_rev >= 2',{
          'sources': [
            'ext/convolver_mips_dspr2.cc',
            'ext/convolver_mips_dspr2.h',
          ],
        }],
      ],
    },
    {
      'target_name': 'image_operations_bench',
      'type': 'executable',
      'dependencies': [
        '../base/base.gyp:base',
        'skia',
      ],
      'include_dirs': [
        '..',
      ],
      'sources': [
        'ext/image_operations_bench.cc',
      ],
    },
    {
      'target_name': 'filter_fuzz_stub',
      'type': 'executable',
      'dependencies': [
        '../base/base.gyp:base',
        'skia.gyp:skia',
      ],
      'sources': [
        'tools/filter_fuzz_stub/filter_fuzz_stub.cc',
      ],
      'includes': [
        '../build/android/increase_size_for_speed.gypi',
      ],
    },
  ],
}
