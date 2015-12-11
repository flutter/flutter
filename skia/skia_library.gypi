# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


# This gypi file contains the Skia library.
# In component mode (shared_lib) it is folded into a single shared library with
# the Chrome-specific enhancements but in all other cases it is a separate lib.

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!WARNING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# variables and defines should go in skia_common.gypi so they can be seen
# by files listed here and in skia_library_opts.gypi.
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!WARNING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
{
  'dependencies': [
    'skia_library_opts.gyp:skia_opts',
    '../third_party/zlib/zlib.gyp:zlib',
  ],

  'includes': [
    '../third_party/skia/gyp/core.gypi',
    '../third_party/skia/gyp/effects.gypi',
    '../third_party/skia/gyp/pdf.gypi',
    '../third_party/skia/gyp/utils.gypi',
  ],

  'sources': [
    '../third_party/skia/src/ports/SkImageDecoder_empty.cpp',
    '../third_party/skia/src/images/SkScaledBitmapSampler.cpp',
    '../third_party/skia/src/images/SkScaledBitmapSampler.h',

    '../third_party/skia/src/ports/SkFontConfigInterface_direct.cpp',
    '../third_party/skia/src/ports/SkFontConfigInterface_direct_factory.cpp',

    '../third_party/skia/src/fonts/SkFontMgr_fontconfig.cpp',
    '../third_party/skia/src/ports/SkFontHost_fontconfig.cpp',

    '../third_party/skia/src/fonts/SkFontMgr_indirect.cpp',
    '../third_party/skia/src/fonts/SkRemotableFontMgr.cpp',
    '../third_party/skia/src/ports/SkRemotableFontMgr_win_dw.cpp',

    '../third_party/skia/src/ports/SkImageGenerator_none.cpp',

    '../third_party/skia/src/ports/SkFontHost_FreeType.cpp',
    '../third_party/skia/src/ports/SkFontHost_FreeType_common.cpp',
    '../third_party/skia/src/ports/SkFontHost_FreeType_common.h',
    '../third_party/skia/src/ports/SkFontHost_mac.cpp',
    '../third_party/skia/src/ports/SkFontHost_win.cpp',
    '../third_party/skia/src/ports/SkFontMgr_android.cpp',
    '../third_party/skia/src/ports/SkFontMgr_android_factory.cpp',
    '../third_party/skia/src/ports/SkFontMgr_android_parser.cpp',
    '../third_party/skia/src/ports/SkFontMgr_win_dw.cpp',
    '../third_party/skia/src/ports/SkGlobalInitialization_chromium.cpp',
    '../third_party/skia/src/ports/SkOSFile_posix.cpp',
    '../third_party/skia/src/ports/SkOSFile_stdio.cpp',
    '../third_party/skia/src/ports/SkOSFile_win.cpp',
    '../third_party/skia/src/ports/SkScalerContext_win_dw.cpp',
    '../third_party/skia/src/ports/SkScalerContext_win_dw.h',
    '../third_party/skia/src/ports/SkTime_Unix.cpp',
    '../third_party/skia/src/ports/SkTLS_pthread.cpp',
    '../third_party/skia/src/ports/SkTLS_win.cpp',
    '../third_party/skia/src/ports/SkTypeface_win_dw.cpp',
    '../third_party/skia/src/ports/SkTypeface_win_dw.h',

    '../third_party/skia/src/sfnt/SkOTTable_name.cpp',
    '../third_party/skia/src/sfnt/SkOTTable_name.h',
    '../third_party/skia/src/sfnt/SkOTUtils.cpp',
    '../third_party/skia/src/sfnt/SkOTUtils.h',

    '../third_party/skia/include/core/SkFontStyle.h',

    '../third_party/skia/include/images/SkMovie.h',
    '../third_party/skia/include/images/SkPageFlipper.h',

    '../third_party/skia/include/ports/SkFontConfigInterface.h',
    '../third_party/skia/include/ports/SkFontMgr.h',
    '../third_party/skia/include/ports/SkFontMgr_indirect.h',
    '../third_party/skia/include/ports/SkRemotableFontMgr.h',
    '../third_party/skia/include/ports/SkTypeface_win.h',
  ],

  # Exclude all unused files in skia utils.gypi file
  'sources!': [
  '../third_party/skia/include/utils/SkBoundaryPatch.h',
  '../third_party/skia/include/utils/SkFrontBufferedStream.h',
  '../third_party/skia/include/utils/SkCamera.h',
  '../third_party/skia/include/utils/SkCanvasStateUtils.h',
  '../third_party/skia/include/utils/SkCubicInterval.h',
  '../third_party/skia/include/utils/SkCullPoints.h',
  '../third_party/skia/include/utils/SkDebugUtils.h',
  '../third_party/skia/include/utils/SkDumpCanvas.h',
  '../third_party/skia/include/utils/SkEventTracer.h',
  '../third_party/skia/include/utils/SkInterpolator.h',
  '../third_party/skia/include/utils/SkLayer.h',
  '../third_party/skia/include/utils/SkMeshUtils.h',
  '../third_party/skia/include/utils/SkNinePatch.h',
  '../third_party/skia/include/utils/SkParsePaint.h',
  '../third_party/skia/include/utils/SkParsePath.h',
  '../third_party/skia/include/utils/SkRandom.h',

  '../third_party/skia/src/utils/SkBitmapHasher.cpp',
  '../third_party/skia/src/utils/SkBitmapHasher.h',
  '../third_party/skia/src/utils/SkBoundaryPatch.cpp',
  '../third_party/skia/src/utils/SkFrontBufferedStream.cpp',
  '../third_party/skia/src/utils/SkCamera.cpp',
  '../third_party/skia/src/utils/SkCanvasStack.h',
  '../third_party/skia/src/utils/SkCubicInterval.cpp',
  '../third_party/skia/src/utils/SkCullPoints.cpp',
  '../third_party/skia/src/utils/SkDumpCanvas.cpp',
  '../third_party/skia/src/utils/SkFloatUtils.h',
  '../third_party/skia/src/utils/SkInterpolator.cpp',
  '../third_party/skia/src/utils/SkLayer.cpp',
  '../third_party/skia/src/utils/SkMD5.cpp',
  '../third_party/skia/src/utils/SkMD5.h',
  '../third_party/skia/src/utils/SkMeshUtils.cpp',
  '../third_party/skia/src/utils/SkNinePatch.cpp',
  '../third_party/skia/src/utils/SkOSFile.cpp',
  '../third_party/skia/src/utils/SkParsePath.cpp',
  '../third_party/skia/src/utils/SkPathUtils.cpp',
  '../third_party/skia/src/utils/SkSHA1.cpp',
  '../third_party/skia/src/utils/SkSHA1.h',
  '../third_party/skia/src/utils/SkTFitsIn.h',
  '../third_party/skia/src/utils/SkTLogic.h',

  # We don't currently need to change thread affinity, so leave out this complexity for now.
  "../third_party/skia/src/utils/SkThreadUtils_pthread_mach.cpp",
  "../third_party/skia/src/utils/SkThreadUtils_pthread_linux.cpp",

#windows
  '../third_party/skia/include/utils/win/SkAutoCoInitialize.h',
  '../third_party/skia/include/utils/win/SkHRESULT.h',
  '../third_party/skia/include/utils/win/SkIStream.h',
  '../third_party/skia/include/utils/win/SkTScopedComPtr.h',
  '../third_party/skia/src/utils/win/SkAutoCoInitialize.cpp',
  '../third_party/skia/src/utils/win/SkIStream.cpp',
  '../third_party/skia/src/utils/win/SkWGL_win.cpp',

#testing
  '../third_party/skia/src/fonts/SkGScalerContext.cpp',
  '../third_party/skia/src/fonts/SkGScalerContext.h',
  ],

  'include_dirs': [
    '../third_party/skia/include/c',
    '../third_party/skia/include/core',
    '../third_party/skia/include/effects',
    '../third_party/skia/include/images',
    '../third_party/skia/include/lazy',
    '../third_party/skia/include/pathops',
    '../third_party/skia/include/pdf',
    '../third_party/skia/include/pipe',
    '../third_party/skia/include/ports',
    '../third_party/skia/include/record',
    '../third_party/skia/include/utils',
    '../third_party/skia/src/core',
    '../third_party/skia/src/opts',
    '../third_party/skia/src/image',
    '../third_party/skia/src/pdf',
    '../third_party/skia/src/ports',
    '../third_party/skia/src/sfnt',
    '../third_party/skia/src/utils',
    '../third_party/skia/src/lazy',
  ],
  'conditions': [
    ['skia_support_gpu != 0', {
      'includes': [
        '../third_party/skia/gyp/gpu.gypi',
      ],
      'sources': [
        '<@(skgpu_null_gl_sources)',
        '<@(skgpu_sources)',
      ],
      'include_dirs': [
        '../third_party/skia/include/gpu',
        '../third_party/skia/src/gpu',
      ],
    }],
    ['skia_support_pdf == 0', {
      'sources/': [
        ['exclude', '../third_party/skia/src/doc/SkDocument_PDF.cpp'],
        ['exclude', '../third_party/skia/src/pdf/'],
      ],
    }],
    ['skia_support_pdf == 1', {
      'dependencies': [
        '../third_party/sfntly/sfntly.gyp:sfntly',
      ],
    }],

    [ 'OS == "win"', {
      'sources!': [
        # Keeping _win.cpp
        "../third_party/skia/src/utils/SkThreadUtils_pthread.cpp",
        "../third_party/skia/src/utils/SkThreadUtils_pthread_other.cpp",
      ],
    },{
      'sources!': [
        # Keeping _pthread.cpp and _pthread_other.cpp
        "../third_party/skia/src/utils/SkThreadUtils_win.cpp",
      ],
    }],

    [ 'OS != "mac"', {
      'sources/': [
        ['exclude', '/mac/']
      ],
    }],
    [ 'OS == "android" and target_arch == "arm"', {
      'sources': [
        '../third_party/skia/src/core/SkUtilsArm.cpp',
      ],
      'includes': [
        '../build/android/cpufeatures.gypi',
      ],
    }],
    [ 'desktop_linux == 1 or chromeos == 1', {
      'dependencies': [
        '../build/linux/system.gyp:fontconfig',
        '../build/linux/system.gyp:freetype2',
        '../third_party/icu/icu.gyp:icuuc',
      ],
      'cflags': [
        '-Wno-unused',
        '-Wno-unused-function',
      ],
    }],
    [ 'use_cairo == 1 and use_pango == 1', {
      'dependencies': [
        '../build/linux/system.gyp:pangocairo',
      ],
    }],
    [ 'OS=="win" or OS=="mac" or OS=="ios" or OS=="android"', {
      'sources!': [
        '../third_party/skia/src/ports/SkFontConfigInterface_direct.cpp',
        '../third_party/skia/src/ports/SkFontConfigInterface_direct_factory.cpp',
        '../third_party/skia/src/ports/SkFontHost_fontconfig.cpp',
        '../third_party/skia/src/fonts/SkFontMgr_fontconfig.cpp',
      ],
    }],
    [ 'OS=="win" or OS=="mac" or OS=="ios"', {
      'sources!': [
        '../third_party/skia/src/ports/SkFontHost_FreeType.cpp',
        '../third_party/skia/src/ports/SkFontHost_FreeType_common.cpp',

      ],
    }],
    [ 'OS == "android"', {
      'dependencies': [
        '../third_party/expat/expat.gyp:expat',
        '../third_party/freetype/freetype.gyp:ft2',
      ],
      # This exports a hard dependency because it needs to run its
      # symlink action in order to expose the skia header files.
      'hard_dependency': 1,
      'include_dirs': [
        '../third_party/expat/files/lib',
      ],
    }, { # not 'OS == "android"'
      'sources!': [
        "../third_party/skia/src/ports/SkFontMgr_android_factory.cpp",
        '../third_party/skia/src/ports/SkFontMgr_android_parser.cpp',
      ],
    }],
    [ 'OS == "ios"', {
      'include_dirs': [
        '../third_party/skia/include/utils/ios',
        '../third_party/skia/include/utils/mac',
      ],
      'link_settings': {
        'libraries': [
          '$(SDKROOT)/System/Library/Frameworks/ImageIO.framework',
        ],
      },
      'sources': [
        # This file is used on both iOS and Mac, so it should be removed
        #  from the ios and mac conditions and moved into the main sources
        #  list.
        '../third_party/skia/src/utils/mac/SkStream_mac.cpp',
      ],

      # The main skia_opts target does not currently work on iOS because the
      # target architecture on iOS is determined at compile time rather than
      # gyp time (simulator builds are x86, device builds are arm).  As a
      # temporary measure, this is a separate opts target for iOS-only, using
      # the _none.cpp files to avoid architecture-dependent implementations.
      'dependencies': [
        'skia_library_opts.gyp:skia_opts_none',
      ],
      'dependencies!': [
        'skia_library_opts.gyp:skia_opts',
      ],
    }],
    [ 'OS == "mac"', {
      'direct_dependent_settings': {
        'include_dirs': [
          '../third_party/skia/include/utils/mac',
        ],
      },
      'include_dirs': [
        '../third_party/skia/include/utils/mac',
      ],
      'link_settings': {
        'libraries': [
          '$(SDKROOT)/System/Library/Frameworks/AppKit.framework',
        ],
      },
      'sources': [
        '../third_party/skia/src/utils/mac/SkStream_mac.cpp',
      ],
    }],
    [ 'OS == "win"', {
      'sources!': [
        '../third_party/skia/src/ports/SkOSFile_posix.cpp',
        '../third_party/skia/src/ports/SkTime_Unix.cpp',
        '../third_party/skia/src/ports/SkTLS_pthread.cpp',
      ],
      'include_dirs': [
        '../third_party/skia/include/utils/win',
        '../third_party/skia/src/utils/win',
      ],
    },{ # not 'OS == "win"'
      'sources!': [
        '../third_party/skia/src/ports/SkFontMgr_win_dw.cpp',
        '../third_party/skia/src/ports/SkRemotableFontMgr_win_dw.cpp',
        '../third_party/skia/src/ports/SkScalerContext_win_dw.cpp',
        '../third_party/skia/src/ports/SkScalerContext_win_dw.h',
        '../third_party/skia/src/ports/SkTypeface_win_dw.cpp',
        '../third_party/skia/src/ports/SkTypeface_win_dw.h',

        '../third_party/skia/src/utils/win/SkDWrite.h',
        '../third_party/skia/src/utils/win/SkDWrite.cpp',
        '../third_party/skia/src/utils/win/SkDWriteFontFileStream.cpp',
        '../third_party/skia/src/utils/win/SkDWriteFontFileStream.h',
        '../third_party/skia/src/utils/win/SkDWriteGeometrySink.cpp',
        '../third_party/skia/src/utils/win/SkDWriteGeometrySink.h',
        '../third_party/skia/src/utils/win/SkHRESULT.cpp',
      ],
    }],
  ],
  'target_conditions': [
    # Pull in specific Mac files for iOS (which have been filtered out
    # by file name rules).
    [ 'OS == "ios"', {
      'sources/': [
        ['include', 'SkFontHost_mac\\.cpp$',],
        ['include', 'SkStream_mac\\.cpp$',],
        ['include', 'SkCreateCGImageRef\\.cpp$',],
      ],
      'xcode_settings' : {
        'WARNING_CFLAGS': [
          # SkFontHost_mac.cpp uses API deprecated in iOS 7.
          # crbug.com/408571
          '-Wno-deprecated-declarations',
        ],
      },
    }],
  ],

  'direct_dependent_settings': {
    'include_dirs': [
      '../third_party/skia/include/core',
      '../third_party/skia/include/effects',
      '../third_party/skia/include/pdf',
      '../third_party/skia/include/gpu',
      '../third_party/skia/include/lazy',
      '../third_party/skia/include/pathops',
      '../third_party/skia/include/pipe',
      '../third_party/skia/include/ports',
      '../third_party/skia/include/utils',
    ],
  },
}
