# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

{
  'targets': [
    {
      'target_name': 'ffmpeg',
      'type': 'none',
      'direct_dependent_settings': {
        'cflags': [
          '<!@(pkg-config --cflags libavcodec libavformat libavutil)',

          '<!(python <(DEPTH)/tools/compile_test/compile_test.py '
              '--code "#define __STDC_CONSTANT_MACROS\n'
              '#include <libavcodec/avcodec.h>\n'
              'int test() { return AV_CODEC_ID_OPUS; }" '
              '--on-failure -DCHROMIUM_OMIT_AV_CODEC_ID_OPUS=1)',

          '<!(python <(DEPTH)/tools/compile_test/compile_test.py '
              '--code "#define __STDC_CONSTANT_MACROS\n'
              '#include <libavcodec/avcodec.h>\n'
              'int test() { return AV_CODEC_ID_VP9; }" '
              '--on-failure -DCHROMIUM_OMIT_AV_CODEC_ID_VP9=1)',

          '<!(python <(DEPTH)/tools/compile_test/compile_test.py '
              '--code "#define __STDC_CONSTANT_MACROS\n'
              '#include <libavcodec/avcodec.h>\n'
              'int test() { return AV_PKT_DATA_MATROSKA_BLOCKADDITIONAL; }" '
              '--on-failure -DCHROMIUM_OMIT_AV_PKT_DATA_MATROSKA_BLOCKADDITIONAL=1)',

          '<!(python <(DEPTH)/tools/compile_test/compile_test.py '
              '--code "#define __STDC_CONSTANT_MACROS\n'
              '#include <libavcodec/avcodec.h>\n'
              'int test() { struct AVFrame frame;\n'
              'return av_frame_get_channels(&frame); }" '
              '--on-failure -DCHROMIUM_NO_AVFRAME_CHANNELS=1)',
        ],
        'defines': [
          '__STDC_CONSTANT_MACROS',
          'USE_SYSTEM_FFMPEG',
        ],
      },
      'link_settings': {
        'ldflags': [
          '<!@(pkg-config --libs-only-L --libs-only-other libavcodec libavformat libavutil)',
        ],
        'libraries': [
          '<!@(pkg-config --libs-only-l libavcodec libavformat libavutil)',
        ],
      },
    },
  ],
}
