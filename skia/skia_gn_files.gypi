# This file is read into the GN build.

# Files are relative to third_party/skia.
{
  'skia_library_sources': [
    '<(skia_src_path)/ports/SkImageGenerator_none.cpp',

    '<(skia_include_path)/images/SkMovie.h',
    '<(skia_include_path)/images/SkPageFlipper.h',
    '<(skia_include_path)/ports/SkTypeface_win.h',
    '<(skia_src_path)/fonts/SkFontMgr_fontconfig.cpp',
    '<(skia_src_path)/fonts/SkFontMgr_indirect.cpp',
    '<(skia_src_path)/fonts/SkRemotableFontMgr.cpp',
    '<(skia_src_path)/images/SkScaledBitmapSampler.cpp',
    '<(skia_src_path)/images/SkScaledBitmapSampler.h',
    '<(skia_src_path)/ports/SkFontConfigInterface_direct.cpp',
    '<(skia_src_path)/ports/SkFontConfigInterface_direct_factory.cpp',
    '<(skia_src_path)/ports/SkFontHost_fontconfig.cpp',
    '<(skia_src_path)/ports/SkFontHost_FreeType_common.cpp',
    '<(skia_src_path)/ports/SkFontHost_FreeType_common.h',
    '<(skia_src_path)/ports/SkFontHost_FreeType.cpp',
    '<(skia_src_path)/ports/SkFontHost_mac.cpp',
    '<(skia_src_path)/ports/SkFontHost_win.cpp',
    '<(skia_src_path)/ports/SkFontMgr_android.cpp',
    '<(skia_src_path)/ports/SkFontMgr_android_factory.cpp',
    '<(skia_src_path)/ports/SkFontMgr_android_parser.cpp',
    '<(skia_src_path)/ports/SkFontMgr_win_dw.cpp',
    '<(skia_src_path)/ports/SkGlobalInitialization_chromium.cpp',
    '<(skia_src_path)/ports/SkImageDecoder_empty.cpp',
    '<(skia_src_path)/ports/SkOSFile_posix.cpp',
    '<(skia_src_path)/ports/SkRemotableFontMgr_win_dw.cpp',
    '<(skia_src_path)/ports/SkOSFile_stdio.cpp',
    '<(skia_src_path)/ports/SkOSFile_win.cpp',
    '<(skia_src_path)/ports/SkScalerContext_win_dw.cpp',
    '<(skia_src_path)/ports/SkScalerContext_win_dw.h',
    '<(skia_src_path)/ports/SkTime_Unix.cpp',
    '<(skia_src_path)/ports/SkTLS_pthread.cpp',
    '<(skia_src_path)/ports/SkTLS_win.cpp',
    '<(skia_src_path)/ports/SkTypeface_win_dw.cpp',
    '<(skia_src_path)/ports/SkTypeface_win_dw.h',
    '<(skia_src_path)/sfnt/SkOTTable_name.cpp',
    '<(skia_src_path)/sfnt/SkOTTable_name.h',
    '<(skia_src_path)/sfnt/SkOTUtils.cpp',
    '<(skia_src_path)/sfnt/SkOTUtils.h',

    #mac
    '<(skia_src_path)/utils/mac/SkStream_mac.cpp',

    #windows

    #testing
    '<(skia_src_path)/fonts/SkGScalerContext.cpp',
    '<(skia_src_path)/fonts/SkGScalerContext.h',
  ],
}
