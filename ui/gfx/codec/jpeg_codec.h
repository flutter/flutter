// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_CODEC_JPEG_CODEC_H_
#define UI_GFX_CODEC_JPEG_CODEC_H_

#include <stddef.h>
#include <vector>

#include "ui/gfx/gfx_export.h"

class SkBitmap;

namespace gfx {

// Interface for encoding/decoding JPEG data. This is a wrapper around libjpeg,
// which has an inconvenient interface for callers. This is only used for UI
// elements, WebKit has its own more complicated JPEG decoder which handles,
// among other things, partially downloaded data.
class GFX_EXPORT JPEGCodec {
 public:
  enum ColorFormat {
    // 3 bytes per pixel (packed), in RGB order regardless of endianness.
    // This is the native JPEG format.
    FORMAT_RGB,

    // 4 bytes per pixel, in RGBA order in mem regardless of endianness.
    FORMAT_RGBA,

    // 4 bytes per pixel, in BGRA order in mem regardless of endianness.
    // This is the default Windows DIB order.
    FORMAT_BGRA,

    // 4 bytes per pixel, it can be either RGBA or BGRA. It depends on the bit
    // order in kARGB_8888_Config skia bitmap.
    FORMAT_SkBitmap
  };

  enum LibraryVariant {
    SYSTEM_LIBJPEG = 0,
    LIBJPEG_TURBO,
    IJG_LIBJPEG,
  };

  // This method helps identify at run time which library chromium is using.
  static LibraryVariant JpegLibraryVariant();

  // Encodes the given raw 'input' data, with each pixel being represented as
  // given in 'format'. The encoded JPEG data will be written into the supplied
  // vector and true will be returned on success. On failure (false), the
  // contents of the output buffer are undefined.
  //
  // w, h: dimensions of the image
  // row_byte_width: the width in bytes of each row. This may be greater than
  //   w * bytes_per_pixel if there is extra padding at the end of each row
  //   (often, each row is padded to the next machine word).
  // quality: an integer in the range 0-100, where 100 is the highest quality.
  static bool Encode(const unsigned char* input, ColorFormat format,
                     int w, int h, int row_byte_width,
                     int quality, std::vector<unsigned char>* output);

  // Decodes the JPEG data contained in input of length input_size. The
  // decoded data will be placed in *output with the dimensions in *w and *h
  // on success (returns true). This data will be written in the'format'
  // format. On failure, the values of these output variables is undefined.
  static bool Decode(const unsigned char* input, size_t input_size,
                     ColorFormat format, std::vector<unsigned char>* output,
                     int* w, int* h);

  // Decodes the JPEG data contained in input of length input_size. If
  // successful, a SkBitmap is created and returned. It is up to the caller
  // to delete the returned bitmap.
  static SkBitmap* Decode(const unsigned char* input, size_t input_size);
};

}  // namespace gfx

#endif  // UI_GFX_CODEC_JPEG_CODEC_H_
