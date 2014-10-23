/*
 * Copyright (c) 2010, Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/image-encoders/skia/PNGImageEncoder.h"

#include "SkBitmap.h"
#include "SkColorPriv.h"
#include "SkUnPreMultiply.h"
#include "platform/geometry/IntSize.h"
#include "platform/graphics/ImageBuffer.h"
extern "C" {
#include "png.h"
}

namespace blink {

static void writeOutput(png_structp png, png_bytep data, png_size_t size)
{
    static_cast<Vector<unsigned char>*>(png_get_io_ptr(png))->append(data, size);
}

static void preMultipliedBGRAtoRGBA(const void* pixels, int pixelCount, unsigned char* output)
{
    static const SkUnPreMultiply::Scale* scale = SkUnPreMultiply::GetScaleTable();
    const SkPMColor* input = static_cast<const SkPMColor*>(pixels);

    for (; pixelCount-- > 0; ++input) {
        const unsigned alpha = SkGetPackedA32(*input);
        if ((alpha != 0) && (alpha != 255)) {
            *output++ = SkUnPreMultiply::ApplyScale(scale[alpha], SkGetPackedR32(*input));
            *output++ = SkUnPreMultiply::ApplyScale(scale[alpha], SkGetPackedG32(*input));
            *output++ = SkUnPreMultiply::ApplyScale(scale[alpha], SkGetPackedB32(*input));
            *output++ = alpha;
        } else {
            *output++ = SkGetPackedR32(*input);
            *output++ = SkGetPackedG32(*input);
            *output++ = SkGetPackedB32(*input);
            *output++ = alpha;
        }
    }
}

static bool encodePixels(IntSize imageSize, unsigned char* inputPixels, bool premultiplied, Vector<unsigned char>* output)
{
    imageSize.clampNegativeToZero();
    Vector<unsigned char> row;

    png_struct* png = png_create_write_struct(PNG_LIBPNG_VER_STRING, 0, 0, 0);
    png_info* info = png_create_info_struct(png);
    if (!png || !info || setjmp(png_jmpbuf(png))) {
        png_destroy_write_struct(png ? &png : 0, info ? &info : 0);
        return false;
    }

    // Optimize compression for speed.
    // The parameters are the same as what libpng uses by default for RGB and RGBA images, except:
    // - the zlib compression level is 3 instead of 6, to avoid the lazy Ziv-Lempel match searching;
    // - the delta filter is 1 ("sub") instead of 5 ("all"), to reduce the filter computations.
    // The zlib memory level (8) and strategy (Z_FILTERED) will be set inside libpng.
    //
    // Avoid the zlib strategies Z_HUFFMAN_ONLY or Z_RLE.
    // Although they are the fastest for poorly-compressible images (e.g. photographs),
    // they are very slow for highly-compressible images (e.g. text, drawings or business graphics).
    png_set_compression_level(png, 3);
    png_set_filter(png, PNG_FILTER_TYPE_BASE, PNG_FILTER_SUB);

    png_set_write_fn(png, output, writeOutput, 0);
    png_set_IHDR(png, info, imageSize.width(), imageSize.height(),
                 8, PNG_COLOR_TYPE_RGB_ALPHA, 0, 0, 0);
    png_write_info(png, info);

    unsigned char* pixels = inputPixels;
    row.resize(imageSize.width() * sizeof(SkPMColor));
    const size_t pixelRowStride = imageSize.width() * 4;
    for (int y = 0; y < imageSize.height(); ++y) {
        if (premultiplied) {
            preMultipliedBGRAtoRGBA(pixels, imageSize.width(), row.data());
            png_write_row(png, row.data());
        } else
            png_write_row(png, pixels);
        pixels += pixelRowStride;
    }

    png_write_end(png, info);
    png_destroy_write_struct(&png, &info);
    return true;
}

bool PNGImageEncoder::encode(const SkBitmap& bitmap, Vector<unsigned char>* output)
{
    SkAutoLockPixels bitmapLock(bitmap);

    if (bitmap.colorType() != kN32_SkColorType || !bitmap.getPixels())
        return false; // Only support 32 bit/pixel skia bitmaps.

    return encodePixels(IntSize(bitmap.width(), bitmap.height()), static_cast<unsigned char*>(bitmap.getPixels()), true, output);
}

bool PNGImageEncoder::encode(const ImageDataBuffer& imageData, Vector<unsigned char>* output)
{
    return encodePixels(imageData.size(), imageData.data(), false, output);
}

} // namespace blink
