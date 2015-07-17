# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'variables': {
    'ft2_dir': 'src',
  },
  'conditions': [
    [ 'OS == "android"', {
      'targets': [
        {
          'target_name': 'ft2',
          'type': 'static_library',
          'toolsets': ['target'],
          'sources': [
            # The following files are not sorted alphabetically, but in the
            # same order as in Android.mk to ease maintenance.
            '<(ft2_dir)/src/base/ftbbox.c',
            '<(ft2_dir)/src/base/ftbitmap.c',
            '<(ft2_dir)/src/base/ftfntfmt.c',
            '<(ft2_dir)/src/base/ftfstype.c',
            '<(ft2_dir)/src/base/ftglyph.c',
            '<(ft2_dir)/src/base/ftlcdfil.c',
            '<(ft2_dir)/src/base/ftstroke.c',
            '<(ft2_dir)/src/base/fttype1.c',
            '<(ft2_dir)/src/base/ftbase.c',
            '<(ft2_dir)/src/base/ftsystem.c',
            '<(ft2_dir)/src/base/ftinit.c',
            '<(ft2_dir)/src/base/ftgasp.c',
            '<(ft2_dir)/src/base/ftmm.c',
            '<(ft2_dir)/src/gzip/ftgzip.c',
            '<(ft2_dir)/src/raster/raster.c',
            '<(ft2_dir)/src/sfnt/sfnt.c',
            '<(ft2_dir)/src/smooth/smooth.c',
            '<(ft2_dir)/src/autofit/autofit.c',
            '<(ft2_dir)/src/truetype/truetype.c',
            '<(ft2_dir)/src/cff/cff.c',
            '<(ft2_dir)/src/psnames/psnames.c',
            '<(ft2_dir)/src/pshinter/pshinter.c',
          ],
          'dependencies': [
            '../libpng/libpng.gyp:libpng',
            '../zlib/zlib.gyp:zlib',
          ],
          'include_dirs': [
            'include',
            '<(ft2_dir)/include',
          ],
          'defines': [
            'FT2_BUILD_LIBRARY',
            'DARWIN_NO_CARBON',
            # Long directory name to avoid accidentally using wrong headers.
            'FT_CONFIG_MODULES_H=<freetype-android-config/ftmodule.h>',
            'FT_CONFIG_OPTIONS_H=<freetype-android-config/ftoption.h>',
          ],
          'direct_dependent_settings': {
            'include_dirs': [
              'include',
              '<(ft2_dir)/include',
            ],
          },
        },
      ],
    }],
  ],
}
