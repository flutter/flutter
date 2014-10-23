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
#include "platform/image-encoders/skia/JPEGImageEncoder.h"

#include "SkBitmap.h"
#include "SkColorPriv.h"
#include "platform/geometry/IntSize.h"
#include "platform/graphics/ImageBuffer.h"
extern "C" {
#include <setjmp.h>
#include <stdio.h> // jpeglib.h needs stdio.h FILE
#include "jpeglib.h"
}

namespace blink {

struct JPEGOutputBuffer : public jpeg_destination_mgr {
    Vector<unsigned char>* output;
    Vector<unsigned char> buffer;
};

static void prepareOutput(j_compress_ptr cinfo)
{
    JPEGOutputBuffer* out = static_cast<JPEGOutputBuffer*>(cinfo->dest);
    const size_t internalBufferSize = 8192;
    out->buffer.resize(internalBufferSize);
    out->next_output_byte = out->buffer.data();
    out->free_in_buffer = out->buffer.size();
}

static boolean writeOutput(j_compress_ptr cinfo)
{
    JPEGOutputBuffer* out = static_cast<JPEGOutputBuffer*>(cinfo->dest);
    out->output->append(out->buffer.data(), out->buffer.size());
    out->next_output_byte = out->buffer.data();
    out->free_in_buffer = out->buffer.size();
    return TRUE;
}

static void finishOutput(j_compress_ptr cinfo)
{
    JPEGOutputBuffer* out = static_cast<JPEGOutputBuffer*>(cinfo->dest);
    const size_t size = out->buffer.size() - out->free_in_buffer;
    out->output->append(out->buffer.data(), size);
}

static void handleError(j_common_ptr common)
{
    jmp_buf* jumpBufferPtr = static_cast<jmp_buf*>(common->client_data);
    longjmp(*jumpBufferPtr, -1);
}

static void preMultipliedBGRAtoRGB(const unsigned char* pixels, unsigned pixelCount, unsigned char* output)
{
    const SkPMColor* input = reinterpret_cast_ptr<const SkPMColor*>(pixels);
    for (; pixelCount-- > 0; ++input) {
        *output++ = SkGetPackedR32(*input);
        *output++ = SkGetPackedG32(*input);
        *output++ = SkGetPackedB32(*input);
    }
}

static void RGBAtoRGB(const unsigned char* pixels, unsigned pixelCount, unsigned char* output)
{
    for (; pixelCount-- > 0; pixels += 4) {
        // Do source-over composition on black.
        unsigned char alpha = pixels[3];
        if (alpha != 255) {
            *output++ = SkMulDiv255Round(pixels[0], alpha);
            *output++ = SkMulDiv255Round(pixels[1], alpha);
            *output++ = SkMulDiv255Round(pixels[2], alpha);
        } else {
            *output++ = pixels[0];
            *output++ = pixels[1];
            *output++ = pixels[2];
        }
    }
}

static void disableSubsamplingForHighQuality(jpeg_compress_struct* cinfo, int quality)
{
    if (quality < 100)
        return;

    for (int i = 0; i < MAX_COMPONENTS; ++i) {
        cinfo->comp_info[i].h_samp_factor = 1;
        cinfo->comp_info[i].v_samp_factor = 1;
    }
}

static bool encodePixels(IntSize imageSize, unsigned char* inputPixels, bool premultiplied, int quality, Vector<unsigned char>* output)
{
    JPEGOutputBuffer destination;
    destination.output = output;
    Vector<JSAMPLE> row;

    jpeg_compress_struct cinfo;
    jpeg_error_mgr error;
    cinfo.err = jpeg_std_error(&error);
    error.error_exit = handleError;
    jmp_buf jumpBuffer;
    cinfo.client_data = &jumpBuffer;

    if (setjmp(jumpBuffer)) {
        jpeg_destroy_compress(&cinfo);
        return false;
    }

    jpeg_create_compress(&cinfo);
    cinfo.dest = &destination;
    cinfo.dest->init_destination = prepareOutput;
    cinfo.dest->empty_output_buffer = writeOutput;
    cinfo.dest->term_destination = finishOutput;

    imageSize.clampNegativeToZero();
    cinfo.image_height = imageSize.height();
    cinfo.image_width = imageSize.width();

#if defined(JCS_EXTENSIONS)
    if (premultiplied) {
        cinfo.in_color_space = SK_B32_SHIFT ? JCS_EXT_RGBX : JCS_EXT_BGRX;

        cinfo.input_components = 4;

        jpeg_set_defaults(&cinfo);
        jpeg_set_quality(&cinfo, quality, TRUE);
        disableSubsamplingForHighQuality(&cinfo, quality);
        jpeg_start_compress(&cinfo, TRUE);

        unsigned char* pixels = inputPixels;
        const size_t pixelRowStride = cinfo.image_width * 4;
        while (cinfo.next_scanline < cinfo.image_height) {
            jpeg_write_scanlines(&cinfo, &pixels, 1);
            pixels += pixelRowStride;
        }

        jpeg_finish_compress(&cinfo);
        jpeg_destroy_compress(&cinfo);
        return true;
    }
#endif

    cinfo.in_color_space = JCS_RGB;
    cinfo.input_components = 3;

    void (*extractRowRGB)(const unsigned char*, unsigned, unsigned char* output);
    extractRowRGB = &RGBAtoRGB;
    if (premultiplied)
        extractRowRGB = &preMultipliedBGRAtoRGB;

    jpeg_set_defaults(&cinfo);
    jpeg_set_quality(&cinfo, quality, TRUE);
    disableSubsamplingForHighQuality(&cinfo, quality);
    jpeg_start_compress(&cinfo, TRUE);

    unsigned char* pixels = inputPixels;
    row.resize(cinfo.image_width * cinfo.input_components);
    const size_t pixelRowStride = cinfo.image_width * 4;
    while (cinfo.next_scanline < cinfo.image_height) {
        JSAMPLE* rowData = row.data();
        extractRowRGB(pixels, cinfo.image_width, rowData);
        jpeg_write_scanlines(&cinfo, &rowData, 1);
        pixels += pixelRowStride;
    }

    jpeg_finish_compress(&cinfo);
    jpeg_destroy_compress(&cinfo);
    return true;
}

bool JPEGImageEncoder::encode(const SkBitmap& bitmap, int quality, Vector<unsigned char>* output)
{
    SkAutoLockPixels bitmapLock(bitmap);

    if (bitmap.colorType() != kN32_SkColorType || !bitmap.getPixels())
        return false; // Only support 32 bit/pixel skia bitmaps.

    return encodePixels(IntSize(bitmap.width(), bitmap.height()), static_cast<unsigned char *>(bitmap.getPixels()), true, quality, output);
}

bool JPEGImageEncoder::encode(const ImageDataBuffer& imageData, int quality, Vector<unsigned char>* output)
{
    return encodePixels(imageData.size(), imageData.data(), false, quality, output);
}

} // namespace blink
