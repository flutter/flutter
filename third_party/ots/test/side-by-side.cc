// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <fcntl.h>
#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_OUTLINE_H
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include <cstdio>
#include <cstdlib>
#include <cstring>

#include "opentype-sanitiser.h"
#include "ots-memory-stream.h"

namespace {

void DumpBitmap(const FT_Bitmap *bitmap) {
  for (int i = 0; i < bitmap->rows * bitmap->width; ++i) {
    if (bitmap->buffer[i] > 192) {
      std::fprintf(stderr, "#");
    } else if (bitmap->buffer[i] > 128) {
      std::fprintf(stderr, "*");
    } else if (bitmap->buffer[i] > 64) {
      std::fprintf(stderr, "+");
    } else if (bitmap->buffer[i] > 32) {
      std::fprintf(stderr, ".");
    } else {
      std::fprintf(stderr, " ");
    }

    if ((i + 1) % bitmap->width == 0) {
      std::fprintf(stderr, "\n");
    }
  }
}

int CompareBitmaps(const FT_Bitmap *orig, const FT_Bitmap *trans) {
  int ret = 0;

  if (orig->width == trans->width &&
      orig->rows == trans->rows) {
    for (int i = 0; i < orig->rows * orig->width; ++i) {
      if (orig->buffer[i] != trans->buffer[i]) {
        std::fprintf(stderr, "bitmap data doesn't match!\n");
        ret = 1;
        break;
      }
    }
  } else {
    std::fprintf(stderr, "bitmap metrics doesn't match! (%d, %d), (%d, %d)\n",
                 orig->width, orig->rows, trans->width, trans->rows);
    ret = 1;
  }

  if (ret) {
    std::fprintf(stderr, "EXPECTED:\n");
    DumpBitmap(orig);
    std::fprintf(stderr, "\nACTUAL:\n");
    DumpBitmap(trans);
    std::fprintf(stderr, "\n\n");
  }

  delete[] orig->buffer;
  delete[] trans->buffer;
  return ret;
}

int GetBitmap(FT_Library library, FT_Outline *outline, FT_Bitmap *bitmap) {
  FT_BBox bbox;
  FT_Outline_Get_CBox(outline, &bbox);

  bbox.xMin &= ~63;
  bbox.yMin &= ~63;
  bbox.xMax = (bbox.xMax + 63) & ~63;
  bbox.yMax = (bbox.yMax + 63) & ~63;
  FT_Outline_Translate(outline, -bbox.xMin, -bbox.yMin);

  const int w = (bbox.xMax - bbox.xMin) >> 6;
  const int h = (bbox.yMax - bbox.yMin) >> 6;

  if (w == 0 || h == 0) {
    return -1;  // white space
  }
  if (w < 0 || h < 0) {
    std::fprintf(stderr, "bad width/height\n");
    return 1;  // error
  }

  uint8_t *buf = new uint8_t[w * h];
  std::memset(buf, 0x0, w * h);

  bitmap->width = w;
  bitmap->rows = h;
  bitmap->pitch = w;
  bitmap->buffer = buf;
  bitmap->pixel_mode = FT_PIXEL_MODE_GRAY;
  bitmap->num_grays = 256;
  if (FT_Outline_Get_Bitmap(library, outline, bitmap)) {
    std::fprintf(stderr, "can't get outline\n");
    delete[] buf;
    return 1;  // error.
  }

  return 0;
}

int LoadChar(FT_Face face, bool use_bitmap, int pt, FT_ULong c) {
  static const int kDpi = 72;

  FT_Matrix matrix;
  matrix.xx = matrix.yy = 1 << 16;
  matrix.xy = matrix.yx = 0 << 16;

  FT_Int32 flags = FT_LOAD_DEFAULT | FT_LOAD_TARGET_NORMAL;
  if (!use_bitmap) {
    // Since the transcoder drops embedded bitmaps from the transcoded one,
    // we have to use FT_LOAD_NO_BITMAP flag for the original face.
    flags |= FT_LOAD_NO_BITMAP;
  }

  FT_Error error = FT_Set_Char_Size(face, pt * (1 << 6), 0, kDpi, 0);
  if (error) {
    std::fprintf(stderr, "Failed to set the char size!\n");
    return 1;
  }

  FT_Set_Transform(face, &matrix, 0);

  error = FT_Load_Char(face, c, flags);
  if (error) return -1;  // no such glyf in the font.

  if (face->glyph->format != FT_GLYPH_FORMAT_OUTLINE) {
    std::fprintf(stderr, "bad format\n");
    return 1;
  }

  return 0;
}

int LoadCharThenCompare(FT_Library library,
                        FT_Face orig_face, FT_Face trans_face,
                        int pt, FT_ULong c) {
  FT_Bitmap orig_bitmap, trans_bitmap;

  // Load original bitmap.
  int ret = LoadChar(orig_face, false, pt, c);
  if (ret) return ret;  // 1: error, -1: no such glyph

  FT_Outline *outline = &orig_face->glyph->outline;
  ret = GetBitmap(library, outline, &orig_bitmap);
  if (ret) return ret;  // white space?

  // Load transformed bitmap.
  ret = LoadChar(trans_face, true, pt, c);
  if (ret == -1) {
    std::fprintf(stderr, "the glyph is not found on the transcoded font\n");
  }
  if (ret) return 1;  // -1 should be treated as error.
  outline = &trans_face->glyph->outline;
  ret = GetBitmap(library, outline, &trans_bitmap);
  if (ret) return ret;  // white space?

  return CompareBitmaps(&orig_bitmap, &trans_bitmap);
}

int SideBySide(FT_Library library, const char *file_name,
               uint8_t *orig_font, size_t orig_len,
               uint8_t *trans_font, size_t trans_len) {
  FT_Face orig_face;
  FT_Error error
      = FT_New_Memory_Face(library, orig_font, orig_len, 0, &orig_face);
  if (error) {
    std::fprintf(stderr, "Failed to open the original font: %s!\n", file_name);
    return 1;
  }

  FT_Face trans_face;
  error = FT_New_Memory_Face(library, trans_font, trans_len, 0, &trans_face);
  if (error) {
    std::fprintf(stderr, "Failed to open the transcoded font: %s!\n",
                 file_name);
    return 1;
  }

  static const int kPts[] = {100, 20, 18, 16, 12, 10, 8};  // pt
  static const size_t kPtsLen = sizeof(kPts) / sizeof(kPts[0]);

  static const int kUnicodeRanges[] = {
    0x0020, 0x007E,  // Basic Latin (ASCII)
    0x00A1, 0x017F,  // Latin-1
    0x1100, 0x11FF,  // Hangul
    0x3040, 0x309F,  // Japanese HIRAGANA letters
    0x3130, 0x318F,  // Hangul
    0x4E00, 0x4F00,  // CJK Kanji/Hanja
    0xAC00, 0xAD00,  // Hangul
  };
  static const size_t kUnicodeRangesLen
      = sizeof(kUnicodeRanges) / sizeof(kUnicodeRanges[0]);

  for (size_t i = 0; i < kPtsLen; ++i) {
    for (size_t j = 0; j < kUnicodeRangesLen; j += 2) {
      for (int k = 0; k <= kUnicodeRanges[j + 1] - kUnicodeRanges[j]; ++k) {
        int ret = LoadCharThenCompare(library, orig_face, trans_face,
                                      kPts[i],
                                      kUnicodeRanges[j] + k);
        if (ret > 0) {
          std::fprintf(stderr, "Glyph mismatch! (file: %s, U+%04x, %dpt)!\n",
                       file_name, kUnicodeRanges[j] + k, kPts[i]);
          return 1;
        }
      }
    }
  }

  return 0;
}

}  // namespace

int main(int argc, char **argv) {
  if (argc != 2) {
    std::fprintf(stderr, "Usage: %s ttf_or_otf_filename\n", argv[0]);
    return 1;
  }

  // load the font to memory.
  const int fd = ::open(argv[1], O_RDONLY);
  if (fd < 0) {
    ::perror("open");
    return 1;
  }

  struct stat st;
  ::fstat(fd, &st);
  const off_t orig_len = st.st_size;

  uint8_t *orig_font = new uint8_t[orig_len];
  if (::read(fd, orig_font, orig_len) != orig_len) {
    std::fprintf(stderr, "Failed to read file!\n");
    return 1;
  }
  ::close(fd);

  // check if FreeType2 can open the original font.
  FT_Library library;
  FT_Error error = FT_Init_FreeType(&library);
  if (error) {
    std::fprintf(stderr, "Failed to initialize FreeType2!\n");
    return 1;
  }
  FT_Face dummy;
  error = FT_New_Memory_Face(library, orig_font, orig_len, 0, &dummy);
  if (error) {
    std::fprintf(stderr, "Failed to open the original font with FT2! %s\n",
                 argv[1]);
    return 1;
  }

  // transcode the original font.
  static const size_t kPadLen = 20 * 1024;
  uint8_t *trans_font = new uint8_t[orig_len + kPadLen];
  ots::MemoryStream output(trans_font, orig_len + kPadLen);
  ots::OTSContext context;

  bool result = context.Process(&output, orig_font, orig_len);
  if (!result) {
    std::fprintf(stderr, "Failed to sanitise file! %s\n", argv[1]);
    return 1;
  }
  const size_t trans_len = output.Tell();

  // perform side-by-side tests.
  return SideBySide(library, argv[1],
                    orig_font, orig_len,
                    trans_font, trans_len);
}
