// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "platform/graphics/gpu/WebGLImageConversion.h"

#include "platform/CheckedInt.h"
#include "platform/graphics/ImageObserver.h"
#include "platform/graphics/cpu/arm/WebGLImageConversionNEON.h"
#include "platform/image-decoders/ImageDecoder.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"

namespace blink {

namespace {

WebGLImageConversion::DataFormat getDataFormat(GLenum destinationFormat, GLenum destinationType)
{
    WebGLImageConversion::DataFormat dstFormat = WebGLImageConversion::DataFormatRGBA8;
    switch (destinationType) {
    case GL_UNSIGNED_BYTE:
        switch (destinationFormat) {
        case GL_RGB:
            dstFormat = WebGLImageConversion::DataFormatRGB8;
            break;
        case GL_RGBA:
            dstFormat = WebGLImageConversion::DataFormatRGBA8;
            break;
        case GL_ALPHA:
            dstFormat = WebGLImageConversion::DataFormatA8;
            break;
        case GL_LUMINANCE:
            dstFormat = WebGLImageConversion::DataFormatR8;
            break;
        case GL_LUMINANCE_ALPHA:
            dstFormat = WebGLImageConversion::DataFormatRA8;
            break;
        default:
            ASSERT_NOT_REACHED();
        }
        break;
    case GL_UNSIGNED_SHORT_4_4_4_4:
        dstFormat = WebGLImageConversion::DataFormatRGBA4444;
        break;
    case GL_UNSIGNED_SHORT_5_5_5_1:
        dstFormat = WebGLImageConversion::DataFormatRGBA5551;
        break;
    case GL_UNSIGNED_SHORT_5_6_5:
        dstFormat = WebGLImageConversion::DataFormatRGB565;
        break;
    case GL_HALF_FLOAT_OES: // OES_texture_half_float
        switch (destinationFormat) {
        case GL_RGB:
            dstFormat = WebGLImageConversion::DataFormatRGB16F;
            break;
        case GL_RGBA:
            dstFormat = WebGLImageConversion::DataFormatRGBA16F;
            break;
        case GL_ALPHA:
            dstFormat = WebGLImageConversion::DataFormatA16F;
            break;
        case GL_LUMINANCE:
            dstFormat = WebGLImageConversion::DataFormatR16F;
            break;
        case GL_LUMINANCE_ALPHA:
            dstFormat = WebGLImageConversion::DataFormatRA16F;
            break;
        default:
            ASSERT_NOT_REACHED();
        }
        break;
    case GL_FLOAT: // OES_texture_float
        switch (destinationFormat) {
        case GL_RGB:
            dstFormat = WebGLImageConversion::DataFormatRGB32F;
            break;
        case GL_RGBA:
            dstFormat = WebGLImageConversion::DataFormatRGBA32F;
            break;
        case GL_ALPHA:
            dstFormat = WebGLImageConversion::DataFormatA32F;
            break;
        case GL_LUMINANCE:
            dstFormat = WebGLImageConversion::DataFormatR32F;
            break;
        case GL_LUMINANCE_ALPHA:
            dstFormat = WebGLImageConversion::DataFormatRA32F;
            break;
        default:
            ASSERT_NOT_REACHED();
        }
        break;
    default:
        ASSERT_NOT_REACHED();
    }
    return dstFormat;
}

// Following Float to Half-Float converion code is from the implementation of ftp://www.fox-toolkit.org/pub/fasthalffloatconversion.pdf,
// "Fast Half Float Conversions" by Jeroen van der Zijp, November 2008 (Revised September 2010).
// Specially, the basetable[512] and shifttable[512] are generated as follows:
/*
unsigned short basetable[512];
unsigned char shifttable[512];

void generatetables(){
    unsigned int i;
    int e;
    for (i = 0; i < 256; ++i){
        e = i - 127;
        if (e < -24){ // Very small numbers map to zero
            basetable[i | 0x000] = 0x0000;
            basetable[i | 0x100] = 0x8000;
            shifttable[i | 0x000] = 24;
            shifttable[i | 0x100] = 24;
        }
        else if (e < -14) { // Small numbers map to denorms
            basetable[i | 0x000] = (0x0400>>(-e-14));
            basetable[i | 0x100] = (0x0400>>(-e-14)) | 0x8000;
            shifttable[i | 0x000] = -e-1;
            shifttable[i | 0x100] = -e-1;
        }
        else if (e <= 15){ // Normal numbers just lose precision
            basetable[i | 0x000] = ((e+15)<<10);
            basetable[i| 0x100] = ((e+15)<<10) | 0x8000;
            shifttable[i|0x000] = 13;
            shifttable[i|0x100] = 13;
        }
        else if (e<128){ // Large numbers map to Infinity
            basetable[i|0x000] = 0x7C00;
            basetable[i|0x100] = 0xFC00;
            shifttable[i|0x000] = 24;
            shifttable[i|0x100] = 24;
        }
        else { // Infinity and NaN's stay Infinity and NaN's
            basetable[i|0x000] = 0x7C00;
            basetable[i|0x100] = 0xFC00;
            shifttable[i|0x000] = 13;
            shifttable[i|0x100] = 13;
       }
    }
}
*/

unsigned short baseTable[512] = {
0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,
0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,
0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,
0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,
0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,
0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0,
0,      0,      0,      0,      0,      0,      0,      1,      2,      4,      8,      16,     32,     64,     128,    256,
512,    1024,   2048,   3072,   4096,   5120,   6144,   7168,   8192,   9216,   10240,  11264,  12288,  13312,  14336,  15360,
16384,  17408,  18432,  19456,  20480,  21504,  22528,  23552,  24576,  25600,  26624,  27648,  28672,  29696,  30720,  31744,
31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,
31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,
31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,
31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,
31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,
31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,
31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,  31744,
32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,
32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,
32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,
32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,
32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,
32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,  32768,
32768,  32768,  32768,  32768,  32768,  32768,  32768,  32769,  32770,  32772,  32776,  32784,  32800,  32832,  32896,  33024,
33280,  33792,  34816,  35840,  36864,  37888,  38912,  39936,  40960,  41984,  43008,  44032,  45056,  46080,  47104,  48128,
49152,  50176,  51200,  52224,  53248,  54272,  55296,  56320,  57344,  58368,  59392,  60416,  61440,  62464,  63488,  64512,
64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,
64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,
64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,
64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,
64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,
64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,
64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512,  64512
};

unsigned char shiftTable[512] = {
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     23,     22,     21,     20,     19,     18,     17,     16,     15,
14,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,
13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     13,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     23,     22,     21,     20,     19,     18,     17,     16,     15,
14,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,
13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     13,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,
24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     24,     13
};

unsigned short convertFloatToHalfFloat(float f)
{
    unsigned temp = *(reinterpret_cast<unsigned *>(&f));
    unsigned signexp = (temp >> 23) & 0x1ff;
    return baseTable[signexp] + ((temp & 0x007fffff) >> shiftTable[signexp]);
}

/* BEGIN CODE SHARED WITH MOZILLA FIREFOX */

// The following packing and unpacking routines are expressed in terms of function templates and inline functions to achieve generality and speedup.
// Explicit template specializations correspond to the cases that would occur.
// Some code are merged back from Mozilla code in http://mxr.mozilla.org/mozilla-central/source/content/canvas/src/WebGLTexelConversions.h

//----------------------------------------------------------------------
// Pixel unpacking routines.
template<int format, typename SourceType, typename DstType>
void unpack(const SourceType*, DstType*, unsigned)
{
    ASSERT_NOT_REACHED();
}

template<> void unpack<WebGLImageConversion::DataFormatRGB8, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[0];
        destination[1] = source[1];
        destination[2] = source[2];
        destination[3] = 0xFF;
        source += 3;
        destination += 4;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatBGR8, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[2];
        destination[1] = source[1];
        destination[2] = source[0];
        destination[3] = 0xFF;
        source += 3;
        destination += 4;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatARGB8, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[1];
        destination[1] = source[2];
        destination[2] = source[3];
        destination[3] = source[0];
        source += 4;
        destination += 4;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatABGR8, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[3];
        destination[1] = source[2];
        destination[2] = source[1];
        destination[3] = source[0];
        source += 4;
        destination += 4;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatBGRA8, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    const uint32_t* source32 = reinterpret_cast_ptr<const uint32_t*>(source);
    uint32_t* destination32 = reinterpret_cast_ptr<uint32_t*>(destination);
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        uint32_t bgra = source32[i];
#if CPU(BIG_ENDIAN)
        uint32_t brMask = 0xff00ff00;
        uint32_t gaMask = 0x00ff00ff;
#else
        uint32_t brMask = 0x00ff00ff;
        uint32_t gaMask = 0xff00ff00;
#endif
        uint32_t rgba = (((bgra >> 16) | (bgra << 16)) & brMask) | (bgra & gaMask);
        destination32[i] = rgba;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatRGBA5551, uint16_t, uint8_t>(const uint16_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
#if HAVE(ARM_NEON_INTRINSICS)
    SIMD::unpackOneRowOfRGBA5551ToRGBA8(source, destination, pixelsPerRow);
#endif
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        uint16_t packedValue = source[0];
        uint8_t r = packedValue >> 11;
        uint8_t g = (packedValue >> 6) & 0x1F;
        uint8_t b = (packedValue >> 1) & 0x1F;
        destination[0] = (r << 3) | (r & 0x7);
        destination[1] = (g << 3) | (g & 0x7);
        destination[2] = (b << 3) | (b & 0x7);
        destination[3] = (packedValue & 0x1) ? 0xFF : 0x0;
        source += 1;
        destination += 4;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatRGBA4444, uint16_t, uint8_t>(const uint16_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
#if HAVE(ARM_NEON_INTRINSICS)
    SIMD::unpackOneRowOfRGBA4444ToRGBA8(source, destination, pixelsPerRow);
#endif
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        uint16_t packedValue = source[0];
        uint8_t r = packedValue >> 12;
        uint8_t g = (packedValue >> 8) & 0x0F;
        uint8_t b = (packedValue >> 4) & 0x0F;
        uint8_t a = packedValue & 0x0F;
        destination[0] = r << 4 | r;
        destination[1] = g << 4 | g;
        destination[2] = b << 4 | b;
        destination[3] = a << 4 | a;
        source += 1;
        destination += 4;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatRGB565, uint16_t, uint8_t>(const uint16_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
#if HAVE(ARM_NEON_INTRINSICS)
    SIMD::unpackOneRowOfRGB565ToRGBA8(source, destination, pixelsPerRow);
#endif
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        uint16_t packedValue = source[0];
        uint8_t r = packedValue >> 11;
        uint8_t g = (packedValue >> 5) & 0x3F;
        uint8_t b = packedValue & 0x1F;
        destination[0] = (r << 3) | (r & 0x7);
        destination[1] = (g << 2) | (g & 0x3);
        destination[2] = (b << 3) | (b & 0x7);
        destination[3] = 0xFF;
        source += 1;
        destination += 4;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatR8, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[0];
        destination[1] = source[0];
        destination[2] = source[0];
        destination[3] = 0xFF;
        source += 1;
        destination += 4;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatRA8, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[0];
        destination[1] = source[0];
        destination[2] = source[0];
        destination[3] = source[1];
        source += 2;
        destination += 4;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatAR8, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[1];
        destination[1] = source[1];
        destination[2] = source[1];
        destination[3] = source[0];
        source += 2;
        destination += 4;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatA8, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = 0x0;
        destination[1] = 0x0;
        destination[2] = 0x0;
        destination[3] = source[0];
        source += 1;
        destination += 4;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatRGBA8, uint8_t, float>(const uint8_t* source, float* destination, unsigned pixelsPerRow)
{
    const float scaleFactor = 1.0f / 255.0f;
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[0] * scaleFactor;
        destination[1] = source[1] * scaleFactor;
        destination[2] = source[2] * scaleFactor;
        destination[3] = source[3] * scaleFactor;
        source += 4;
        destination += 4;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatBGRA8, uint8_t, float>(const uint8_t* source, float* destination, unsigned pixelsPerRow)
{
    const float scaleFactor = 1.0f / 255.0f;
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[2] * scaleFactor;
        destination[1] = source[1] * scaleFactor;
        destination[2] = source[0] * scaleFactor;
        destination[3] = source[3] * scaleFactor;
        source += 4;
        destination += 4;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatABGR8, uint8_t, float>(const uint8_t* source, float* destination, unsigned pixelsPerRow)
{
    const float scaleFactor = 1.0f / 255.0f;
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[3] * scaleFactor;
        destination[1] = source[2] * scaleFactor;
        destination[2] = source[1] * scaleFactor;
        destination[3] = source[0] * scaleFactor;
        source += 4;
        destination += 4;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatARGB8, uint8_t, float>(const uint8_t* source, float* destination, unsigned pixelsPerRow)
{
    const float scaleFactor = 1.0f / 255.0f;
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[1] * scaleFactor;
        destination[1] = source[2] * scaleFactor;
        destination[2] = source[3] * scaleFactor;
        destination[3] = source[0] * scaleFactor;
        source += 4;
        destination += 4;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatRGB8, uint8_t, float>(const uint8_t* source, float* destination, unsigned pixelsPerRow)
{
    const float scaleFactor = 1.0f / 255.0f;
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[0] * scaleFactor;
        destination[1] = source[1] * scaleFactor;
        destination[2] = source[2] * scaleFactor;
        destination[3] = 1;
        source += 3;
        destination += 4;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatBGR8, uint8_t, float>(const uint8_t* source, float* destination, unsigned pixelsPerRow)
{
    const float scaleFactor = 1.0f / 255.0f;
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[2] * scaleFactor;
        destination[1] = source[1] * scaleFactor;
        destination[2] = source[0] * scaleFactor;
        destination[3] = 1;
        source += 3;
        destination += 4;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatRGB32F, float, float>(const float* source, float* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[0];
        destination[1] = source[1];
        destination[2] = source[2];
        destination[3] = 1;
        source += 3;
        destination += 4;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatR32F, float, float>(const float* source, float* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[0];
        destination[1] = source[0];
        destination[2] = source[0];
        destination[3] = 1;
        source += 1;
        destination += 4;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatRA32F, float, float>(const float* source, float* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[0];
        destination[1] = source[0];
        destination[2] = source[0];
        destination[3] = source[1];
        source += 2;
        destination += 4;
    }
}

template<> void unpack<WebGLImageConversion::DataFormatA32F, float, float>(const float* source, float* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = 0;
        destination[1] = 0;
        destination[2] = 0;
        destination[3] = source[0];
        source += 1;
        destination += 4;
    }
}

//----------------------------------------------------------------------
// Pixel packing routines.
//

template<int format, int alphaOp, typename SourceType, typename DstType>
void pack(const SourceType*, DstType*, unsigned)
{
    ASSERT_NOT_REACHED();
}

template<> void pack<WebGLImageConversion::DataFormatA8, WebGLImageConversion::AlphaDoNothing, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[3];
        source += 4;
        destination += 1;
    }
}

template<> void pack<WebGLImageConversion::DataFormatR8, WebGLImageConversion::AlphaDoNothing, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[0];
        source += 4;
        destination += 1;
    }
}

template<> void pack<WebGLImageConversion::DataFormatR8, WebGLImageConversion::AlphaDoPremultiply, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] / 255.0f;
        uint8_t sourceR = static_cast<uint8_t>(static_cast<float>(source[0]) * scaleFactor);
        destination[0] = sourceR;
        source += 4;
        destination += 1;
    }
}

// FIXME: this routine is lossy and must be removed.
template<> void pack<WebGLImageConversion::DataFormatR8, WebGLImageConversion::AlphaDoUnmultiply, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] ? 255.0f / source[3] : 1.0f;
        uint8_t sourceR = static_cast<uint8_t>(static_cast<float>(source[0]) * scaleFactor);
        destination[0] = sourceR;
        source += 4;
        destination += 1;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRA8, WebGLImageConversion::AlphaDoNothing, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[0];
        destination[1] = source[3];
        source += 4;
        destination += 2;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRA8, WebGLImageConversion::AlphaDoPremultiply, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] / 255.0f;
        uint8_t sourceR = static_cast<uint8_t>(static_cast<float>(source[0]) * scaleFactor);
        destination[0] = sourceR;
        destination[1] = source[3];
        source += 4;
        destination += 2;
    }
}

// FIXME: this routine is lossy and must be removed.
template<> void pack<WebGLImageConversion::DataFormatRA8, WebGLImageConversion::AlphaDoUnmultiply, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] ? 255.0f / source[3] : 1.0f;
        uint8_t sourceR = static_cast<uint8_t>(static_cast<float>(source[0]) * scaleFactor);
        destination[0] = sourceR;
        destination[1] = source[3];
        source += 4;
        destination += 2;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRGB8, WebGLImageConversion::AlphaDoNothing, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[0];
        destination[1] = source[1];
        destination[2] = source[2];
        source += 4;
        destination += 3;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRGB8, WebGLImageConversion::AlphaDoPremultiply, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] / 255.0f;
        uint8_t sourceR = static_cast<uint8_t>(static_cast<float>(source[0]) * scaleFactor);
        uint8_t sourceG = static_cast<uint8_t>(static_cast<float>(source[1]) * scaleFactor);
        uint8_t sourceB = static_cast<uint8_t>(static_cast<float>(source[2]) * scaleFactor);
        destination[0] = sourceR;
        destination[1] = sourceG;
        destination[2] = sourceB;
        source += 4;
        destination += 3;
    }
}

// FIXME: this routine is lossy and must be removed.
template<> void pack<WebGLImageConversion::DataFormatRGB8, WebGLImageConversion::AlphaDoUnmultiply, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] ? 255.0f / source[3] : 1.0f;
        uint8_t sourceR = static_cast<uint8_t>(static_cast<float>(source[0]) * scaleFactor);
        uint8_t sourceG = static_cast<uint8_t>(static_cast<float>(source[1]) * scaleFactor);
        uint8_t sourceB = static_cast<uint8_t>(static_cast<float>(source[2]) * scaleFactor);
        destination[0] = sourceR;
        destination[1] = sourceG;
        destination[2] = sourceB;
        source += 4;
        destination += 3;
    }
}


template<> void pack<WebGLImageConversion::DataFormatRGBA8, WebGLImageConversion::AlphaDoNothing, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    memcpy(destination, source, pixelsPerRow * 4);
}

template<> void pack<WebGLImageConversion::DataFormatRGBA8, WebGLImageConversion::AlphaDoPremultiply, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] / 255.0f;
        uint8_t sourceR = static_cast<uint8_t>(static_cast<float>(source[0]) * scaleFactor);
        uint8_t sourceG = static_cast<uint8_t>(static_cast<float>(source[1]) * scaleFactor);
        uint8_t sourceB = static_cast<uint8_t>(static_cast<float>(source[2]) * scaleFactor);
        destination[0] = sourceR;
        destination[1] = sourceG;
        destination[2] = sourceB;
        destination[3] = source[3];
        source += 4;
        destination += 4;
    }
}

// FIXME: this routine is lossy and must be removed.
template<> void pack<WebGLImageConversion::DataFormatRGBA8, WebGLImageConversion::AlphaDoUnmultiply, uint8_t, uint8_t>(const uint8_t* source, uint8_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] ? 255.0f / source[3] : 1.0f;
        uint8_t sourceR = static_cast<uint8_t>(static_cast<float>(source[0]) * scaleFactor);
        uint8_t sourceG = static_cast<uint8_t>(static_cast<float>(source[1]) * scaleFactor);
        uint8_t sourceB = static_cast<uint8_t>(static_cast<float>(source[2]) * scaleFactor);
        destination[0] = sourceR;
        destination[1] = sourceG;
        destination[2] = sourceB;
        destination[3] = source[3];
        source += 4;
        destination += 4;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRGBA4444, WebGLImageConversion::AlphaDoNothing, uint8_t, uint16_t>(const uint8_t* source, uint16_t* destination, unsigned pixelsPerRow)
{
#if HAVE(ARM_NEON_INTRINSICS)
    SIMD::packOneRowOfRGBA8ToUnsignedShort4444(source, destination, pixelsPerRow);
#endif
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        *destination = (((source[0] & 0xF0) << 8)
                        | ((source[1] & 0xF0) << 4)
                        | (source[2] & 0xF0)
                        | (source[3] >> 4));
        source += 4;
        destination += 1;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRGBA4444, WebGLImageConversion::AlphaDoPremultiply, uint8_t, uint16_t>(const uint8_t* source, uint16_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] / 255.0f;
        uint8_t sourceR = static_cast<uint8_t>(static_cast<float>(source[0]) * scaleFactor);
        uint8_t sourceG = static_cast<uint8_t>(static_cast<float>(source[1]) * scaleFactor);
        uint8_t sourceB = static_cast<uint8_t>(static_cast<float>(source[2]) * scaleFactor);
        *destination = (((sourceR & 0xF0) << 8)
                        | ((sourceG & 0xF0) << 4)
                        | (sourceB & 0xF0)
                        | (source[3] >> 4));
        source += 4;
        destination += 1;
    }
}

// FIXME: this routine is lossy and must be removed.
template<> void pack<WebGLImageConversion::DataFormatRGBA4444, WebGLImageConversion::AlphaDoUnmultiply, uint8_t, uint16_t>(const uint8_t* source, uint16_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] ? 255.0f / source[3] : 1.0f;
        uint8_t sourceR = static_cast<uint8_t>(static_cast<float>(source[0]) * scaleFactor);
        uint8_t sourceG = static_cast<uint8_t>(static_cast<float>(source[1]) * scaleFactor);
        uint8_t sourceB = static_cast<uint8_t>(static_cast<float>(source[2]) * scaleFactor);
        *destination = (((sourceR & 0xF0) << 8)
                        | ((sourceG & 0xF0) << 4)
                        | (sourceB & 0xF0)
                        | (source[3] >> 4));
        source += 4;
        destination += 1;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRGBA5551, WebGLImageConversion::AlphaDoNothing, uint8_t, uint16_t>(const uint8_t* source, uint16_t* destination, unsigned pixelsPerRow)
{
#if HAVE(ARM_NEON_INTRINSICS)
    SIMD::packOneRowOfRGBA8ToUnsignedShort5551(source, destination, pixelsPerRow);
#endif
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        *destination = (((source[0] & 0xF8) << 8)
                        | ((source[1] & 0xF8) << 3)
                        | ((source[2] & 0xF8) >> 2)
                        | (source[3] >> 7));
        source += 4;
        destination += 1;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRGBA5551, WebGLImageConversion::AlphaDoPremultiply, uint8_t, uint16_t>(const uint8_t* source, uint16_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] / 255.0f;
        uint8_t sourceR = static_cast<uint8_t>(static_cast<float>(source[0]) * scaleFactor);
        uint8_t sourceG = static_cast<uint8_t>(static_cast<float>(source[1]) * scaleFactor);
        uint8_t sourceB = static_cast<uint8_t>(static_cast<float>(source[2]) * scaleFactor);
        *destination = (((sourceR & 0xF8) << 8)
                        | ((sourceG & 0xF8) << 3)
                        | ((sourceB & 0xF8) >> 2)
                        | (source[3] >> 7));
        source += 4;
        destination += 1;
    }
}

// FIXME: this routine is lossy and must be removed.
template<> void pack<WebGLImageConversion::DataFormatRGBA5551, WebGLImageConversion::AlphaDoUnmultiply, uint8_t, uint16_t>(const uint8_t* source, uint16_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] ? 255.0f / source[3] : 1.0f;
        uint8_t sourceR = static_cast<uint8_t>(static_cast<float>(source[0]) * scaleFactor);
        uint8_t sourceG = static_cast<uint8_t>(static_cast<float>(source[1]) * scaleFactor);
        uint8_t sourceB = static_cast<uint8_t>(static_cast<float>(source[2]) * scaleFactor);
        *destination = (((sourceR & 0xF8) << 8)
                        | ((sourceG & 0xF8) << 3)
                        | ((sourceB & 0xF8) >> 2)
                        | (source[3] >> 7));
        source += 4;
        destination += 1;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRGB565, WebGLImageConversion::AlphaDoNothing, uint8_t, uint16_t>(const uint8_t* source, uint16_t* destination, unsigned pixelsPerRow)
{
#if HAVE(ARM_NEON_INTRINSICS)
    SIMD::packOneRowOfRGBA8ToUnsignedShort565(source, destination, pixelsPerRow);
#endif
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        *destination = (((source[0] & 0xF8) << 8)
                        | ((source[1] & 0xFC) << 3)
                        | ((source[2] & 0xF8) >> 3));
        source += 4;
        destination += 1;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRGB565, WebGLImageConversion::AlphaDoPremultiply, uint8_t, uint16_t>(const uint8_t* source, uint16_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] / 255.0f;
        uint8_t sourceR = static_cast<uint8_t>(static_cast<float>(source[0]) * scaleFactor);
        uint8_t sourceG = static_cast<uint8_t>(static_cast<float>(source[1]) * scaleFactor);
        uint8_t sourceB = static_cast<uint8_t>(static_cast<float>(source[2]) * scaleFactor);
        *destination = (((sourceR & 0xF8) << 8)
                        | ((sourceG & 0xFC) << 3)
                        | ((sourceB & 0xF8) >> 3));
        source += 4;
        destination += 1;
    }
}

// FIXME: this routine is lossy and must be removed.
template<> void pack<WebGLImageConversion::DataFormatRGB565, WebGLImageConversion::AlphaDoUnmultiply, uint8_t, uint16_t>(const uint8_t* source, uint16_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] ? 255.0f / source[3] : 1.0f;
        uint8_t sourceR = static_cast<uint8_t>(static_cast<float>(source[0]) * scaleFactor);
        uint8_t sourceG = static_cast<uint8_t>(static_cast<float>(source[1]) * scaleFactor);
        uint8_t sourceB = static_cast<uint8_t>(static_cast<float>(source[2]) * scaleFactor);
        *destination = (((sourceR & 0xF8) << 8)
                        | ((sourceG & 0xFC) << 3)
                        | ((sourceB & 0xF8) >> 3));
        source += 4;
        destination += 1;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRGB32F, WebGLImageConversion::AlphaDoNothing, float, float>(const float* source, float* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[0];
        destination[1] = source[1];
        destination[2] = source[2];
        source += 4;
        destination += 3;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRGB32F, WebGLImageConversion::AlphaDoPremultiply, float, float>(const float* source, float* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3];
        destination[0] = source[0] * scaleFactor;
        destination[1] = source[1] * scaleFactor;
        destination[2] = source[2] * scaleFactor;
        source += 4;
        destination += 3;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRGB32F, WebGLImageConversion::AlphaDoUnmultiply, float, float>(const float* source, float* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] ? 1.0f / source[3] : 1.0f;
        destination[0] = source[0] * scaleFactor;
        destination[1] = source[1] * scaleFactor;
        destination[2] = source[2] * scaleFactor;
        source += 4;
        destination += 3;
    }
}

// Used only during RGBA8 or BGRA8 -> floating-point uploads.
template<> void pack<WebGLImageConversion::DataFormatRGBA32F, WebGLImageConversion::AlphaDoNothing, float, float>(const float* source, float* destination, unsigned pixelsPerRow)
{
    memcpy(destination, source, pixelsPerRow * 4 * sizeof(float));
}

template<> void pack<WebGLImageConversion::DataFormatRGBA32F, WebGLImageConversion::AlphaDoPremultiply, float, float>(const float* source, float* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3];
        destination[0] = source[0] * scaleFactor;
        destination[1] = source[1] * scaleFactor;
        destination[2] = source[2] * scaleFactor;
        destination[3] = source[3];
        source += 4;
        destination += 4;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRGBA32F, WebGLImageConversion::AlphaDoUnmultiply, float, float>(const float* source, float* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] ? 1.0f / source[3] : 1.0f;
        destination[0] = source[0] * scaleFactor;
        destination[1] = source[1] * scaleFactor;
        destination[2] = source[2] * scaleFactor;
        destination[3] = source[3];
        source += 4;
        destination += 4;
    }
}

template<> void pack<WebGLImageConversion::DataFormatA32F, WebGLImageConversion::AlphaDoNothing, float, float>(const float* source, float* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[3];
        source += 4;
        destination += 1;
    }
}

template<> void pack<WebGLImageConversion::DataFormatR32F, WebGLImageConversion::AlphaDoNothing, float, float>(const float* source, float* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[0];
        source += 4;
        destination += 1;
    }
}

template<> void pack<WebGLImageConversion::DataFormatR32F, WebGLImageConversion::AlphaDoPremultiply, float, float>(const float* source, float* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3];
        destination[0] = source[0] * scaleFactor;
        source += 4;
        destination += 1;
    }
}

template<> void pack<WebGLImageConversion::DataFormatR32F, WebGLImageConversion::AlphaDoUnmultiply, float, float>(const float* source, float* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] ? 1.0f / source[3] : 1.0f;
        destination[0] = source[0] * scaleFactor;
        source += 4;
        destination += 1;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRA32F, WebGLImageConversion::AlphaDoNothing, float, float>(const float* source, float* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = source[0];
        destination[1] = source[3];
        source += 4;
        destination += 2;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRA32F, WebGLImageConversion::AlphaDoPremultiply, float, float>(const float* source, float* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3];
        destination[0] = source[0] * scaleFactor;
        destination[1] = source[3];
        source += 4;
        destination += 2;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRA32F, WebGLImageConversion::AlphaDoUnmultiply, float, float>(const float* source, float* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] ? 1.0f / source[3] : 1.0f;
        destination[0] = source[0] * scaleFactor;
        destination[1] = source[3];
        source += 4;
        destination += 2;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRGBA16F, WebGLImageConversion::AlphaDoNothing, float, uint16_t>(const float* source, uint16_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = convertFloatToHalfFloat(source[0]);
        destination[1] = convertFloatToHalfFloat(source[1]);
        destination[2] = convertFloatToHalfFloat(source[2]);
        destination[3] = convertFloatToHalfFloat(source[3]);
        source += 4;
        destination += 4;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRGBA16F, WebGLImageConversion::AlphaDoPremultiply, float, uint16_t>(const float* source, uint16_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3];
        destination[0] = convertFloatToHalfFloat(source[0] * scaleFactor);
        destination[1] = convertFloatToHalfFloat(source[1] * scaleFactor);
        destination[2] = convertFloatToHalfFloat(source[2] * scaleFactor);
        destination[3] = convertFloatToHalfFloat(source[3]);
        source += 4;
        destination += 4;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRGBA16F, WebGLImageConversion::AlphaDoUnmultiply, float, uint16_t>(const float* source, uint16_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] ? 1.0f / source[3] : 1.0f;
        destination[0] = convertFloatToHalfFloat(source[0] * scaleFactor);
        destination[1] = convertFloatToHalfFloat(source[1] * scaleFactor);
        destination[2] = convertFloatToHalfFloat(source[2] * scaleFactor);
        destination[3] = convertFloatToHalfFloat(source[3]);
        source += 4;
        destination += 4;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRGB16F, WebGLImageConversion::AlphaDoNothing, float, uint16_t>(const float* source, uint16_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = convertFloatToHalfFloat(source[0]);
        destination[1] = convertFloatToHalfFloat(source[1]);
        destination[2] = convertFloatToHalfFloat(source[2]);
        source += 4;
        destination += 3;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRGB16F, WebGLImageConversion::AlphaDoPremultiply, float, uint16_t>(const float* source, uint16_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3];
        destination[0] = convertFloatToHalfFloat(source[0] * scaleFactor);
        destination[1] = convertFloatToHalfFloat(source[1] * scaleFactor);
        destination[2] = convertFloatToHalfFloat(source[2] * scaleFactor);
        source += 4;
        destination += 3;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRGB16F, WebGLImageConversion::AlphaDoUnmultiply, float, uint16_t>(const float* source, uint16_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] ? 1.0f / source[3] : 1.0f;
        destination[0] = convertFloatToHalfFloat(source[0] * scaleFactor);
        destination[1] = convertFloatToHalfFloat(source[1] * scaleFactor);
        destination[2] = convertFloatToHalfFloat(source[2] * scaleFactor);
        source += 4;
        destination += 3;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRA16F, WebGLImageConversion::AlphaDoNothing, float, uint16_t>(const float* source, uint16_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = convertFloatToHalfFloat(source[0]);
        destination[1] = convertFloatToHalfFloat(source[3]);
        source += 4;
        destination += 2;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRA16F, WebGLImageConversion::AlphaDoPremultiply, float, uint16_t>(const float* source, uint16_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3];
        destination[0] = convertFloatToHalfFloat(source[0] * scaleFactor);
        destination[1] = convertFloatToHalfFloat(source[3]);
        source += 4;
        destination += 2;
    }
}

template<> void pack<WebGLImageConversion::DataFormatRA16F, WebGLImageConversion::AlphaDoUnmultiply, float, uint16_t>(const float* source, uint16_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] ? 1.0f / source[3] : 1.0f;
        destination[0] = convertFloatToHalfFloat(source[0] * scaleFactor);
        destination[1] = convertFloatToHalfFloat(source[3]);
        source += 4;
        destination += 2;
    }
}

template<> void pack<WebGLImageConversion::DataFormatR16F, WebGLImageConversion::AlphaDoNothing, float, uint16_t>(const float* source, uint16_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = convertFloatToHalfFloat(source[0]);
        source += 4;
        destination += 1;
    }
}

template<> void pack<WebGLImageConversion::DataFormatR16F, WebGLImageConversion::AlphaDoPremultiply, float, uint16_t>(const float* source, uint16_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3];
        destination[0] = convertFloatToHalfFloat(source[0] * scaleFactor);
        source += 4;
        destination += 1;
    }
}

template<> void pack<WebGLImageConversion::DataFormatR16F, WebGLImageConversion::AlphaDoUnmultiply, float, uint16_t>(const float* source, uint16_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        float scaleFactor = source[3] ? 1.0f / source[3] : 1.0f;
        destination[0] = convertFloatToHalfFloat(source[0] * scaleFactor);
        source += 4;
        destination += 1;
    }
}

template<> void pack<WebGLImageConversion::DataFormatA16F, WebGLImageConversion::AlphaDoNothing, float, uint16_t>(const float* source, uint16_t* destination, unsigned pixelsPerRow)
{
    for (unsigned i = 0; i < pixelsPerRow; ++i) {
        destination[0] = convertFloatToHalfFloat(source[3]);
        source += 4;
        destination += 1;
    }
}

bool HasAlpha(int format)
{
    return format == WebGLImageConversion::DataFormatA8
        || format == WebGLImageConversion::DataFormatA16F
        || format == WebGLImageConversion::DataFormatA32F
        || format == WebGLImageConversion::DataFormatRA8
        || format == WebGLImageConversion::DataFormatAR8
        || format == WebGLImageConversion::DataFormatRA16F
        || format == WebGLImageConversion::DataFormatRA32F
        || format == WebGLImageConversion::DataFormatRGBA8
        || format == WebGLImageConversion::DataFormatBGRA8
        || format == WebGLImageConversion::DataFormatARGB8
        || format == WebGLImageConversion::DataFormatABGR8
        || format == WebGLImageConversion::DataFormatRGBA16F
        || format == WebGLImageConversion::DataFormatRGBA32F
        || format == WebGLImageConversion::DataFormatRGBA4444
        || format == WebGLImageConversion::DataFormatRGBA5551;
}

bool HasColor(int format)
{
    return format == WebGLImageConversion::DataFormatRGBA8
        || format == WebGLImageConversion::DataFormatRGBA16F
        || format == WebGLImageConversion::DataFormatRGBA32F
        || format == WebGLImageConversion::DataFormatRGB8
        || format == WebGLImageConversion::DataFormatRGB16F
        || format == WebGLImageConversion::DataFormatRGB32F
        || format == WebGLImageConversion::DataFormatBGR8
        || format == WebGLImageConversion::DataFormatBGRA8
        || format == WebGLImageConversion::DataFormatARGB8
        || format == WebGLImageConversion::DataFormatABGR8
        || format == WebGLImageConversion::DataFormatRGBA5551
        || format == WebGLImageConversion::DataFormatRGBA4444
        || format == WebGLImageConversion::DataFormatRGB565
        || format == WebGLImageConversion::DataFormatR8
        || format == WebGLImageConversion::DataFormatR16F
        || format == WebGLImageConversion::DataFormatR32F
        || format == WebGLImageConversion::DataFormatRA8
        || format == WebGLImageConversion::DataFormatRA16F
        || format == WebGLImageConversion::DataFormatRA32F
        || format == WebGLImageConversion::DataFormatAR8;
}

template<int Format>
struct IsFloatFormat {
    static const bool Value =
        Format == WebGLImageConversion::DataFormatRGBA32F
        || Format == WebGLImageConversion::DataFormatRGB32F
        || Format == WebGLImageConversion::DataFormatRA32F
        || Format == WebGLImageConversion::DataFormatR32F
        || Format == WebGLImageConversion::DataFormatA32F;
};

template<int Format>
struct IsHalfFloatFormat {
    static const bool Value =
        Format == WebGLImageConversion::DataFormatRGBA16F
        || Format == WebGLImageConversion::DataFormatRGB16F
        || Format == WebGLImageConversion::DataFormatRA16F
        || Format == WebGLImageConversion::DataFormatR16F
        || Format == WebGLImageConversion::DataFormatA16F;
};

template<int Format>
struct Is16bppFormat {
    static const bool Value =
        Format == WebGLImageConversion::DataFormatRGBA5551
        || Format == WebGLImageConversion::DataFormatRGBA4444
        || Format == WebGLImageConversion::DataFormatRGB565;
};

template<int Format, bool IsFloat = IsFloatFormat<Format>::Value, bool IsHalfFloat = IsHalfFloatFormat<Format>::Value, bool Is16bpp = Is16bppFormat<Format>::Value>
struct DataTypeForFormat {
    typedef uint8_t Type;
};

template<int Format>
struct DataTypeForFormat<Format, true, false, false> {
    typedef float Type;
};

template<int Format>
struct DataTypeForFormat<Format, false, true, false> {
    typedef uint16_t Type;
};

template<int Format>
struct DataTypeForFormat<Format, false, false, true> {
    typedef uint16_t Type;
};

template<int Format>
struct IntermediateFormat {
    static const int Value = (IsFloatFormat<Format>::Value || IsHalfFloatFormat<Format>::Value) ? WebGLImageConversion::DataFormatRGBA32F : WebGLImageConversion::DataFormatRGBA8;
};

unsigned TexelBytesForFormat(WebGLImageConversion::DataFormat format)
{
    switch (format) {
    case WebGLImageConversion::DataFormatR8:
    case WebGLImageConversion::DataFormatA8:
        return 1;
    case WebGLImageConversion::DataFormatRA8:
    case WebGLImageConversion::DataFormatAR8:
    case WebGLImageConversion::DataFormatRGBA5551:
    case WebGLImageConversion::DataFormatRGBA4444:
    case WebGLImageConversion::DataFormatRGB565:
    case WebGLImageConversion::DataFormatA16F:
    case WebGLImageConversion::DataFormatR16F:
        return 2;
    case WebGLImageConversion::DataFormatRGB8:
    case WebGLImageConversion::DataFormatBGR8:
        return 3;
    case WebGLImageConversion::DataFormatRGBA8:
    case WebGLImageConversion::DataFormatARGB8:
    case WebGLImageConversion::DataFormatABGR8:
    case WebGLImageConversion::DataFormatBGRA8:
    case WebGLImageConversion::DataFormatR32F:
    case WebGLImageConversion::DataFormatA32F:
    case WebGLImageConversion::DataFormatRA16F:
        return 4;
    case WebGLImageConversion::DataFormatRGB16F:
        return 6;
    case WebGLImageConversion::DataFormatRA32F:
    case WebGLImageConversion::DataFormatRGBA16F:
        return 8;
    case WebGLImageConversion::DataFormatRGB32F:
        return 12;
    case WebGLImageConversion::DataFormatRGBA32F:
        return 16;
    default:
        return 0;
    }
}

/* END CODE SHARED WITH MOZILLA FIREFOX */

class FormatConverter {
public:
    FormatConverter(unsigned width, unsigned height,
        const void* srcStart, void* dstStart, int srcStride, int dstStride)
        : m_width(width), m_height(height), m_srcStart(srcStart), m_dstStart(dstStart), m_srcStride(srcStride), m_dstStride(dstStride), m_success(false)
    {
        const unsigned MaxNumberOfComponents = 4;
        const unsigned MaxBytesPerComponent  = 4;
        m_unpackedIntermediateSrcData = adoptArrayPtr(new uint8_t[m_width * MaxNumberOfComponents *MaxBytesPerComponent]);
        ASSERT(m_unpackedIntermediateSrcData.get());
    }

    void convert(WebGLImageConversion::DataFormat srcFormat, WebGLImageConversion::DataFormat dstFormat, WebGLImageConversion::AlphaOp);
    bool Success() const { return m_success; }

private:
    template<WebGLImageConversion::DataFormat SrcFormat>
    void convert(WebGLImageConversion::DataFormat dstFormat, WebGLImageConversion::AlphaOp);

    template<WebGLImageConversion::DataFormat SrcFormat, WebGLImageConversion::DataFormat DstFormat>
    void convert(WebGLImageConversion::AlphaOp);

    template<WebGLImageConversion::DataFormat SrcFormat, WebGLImageConversion::DataFormat DstFormat, WebGLImageConversion::AlphaOp alphaOp>
    void convert();

    const unsigned m_width, m_height;
    const void* const m_srcStart;
    void* const m_dstStart;
    const int m_srcStride, m_dstStride;
    bool m_success;
    OwnPtr<uint8_t[]> m_unpackedIntermediateSrcData;
};

void FormatConverter::convert(WebGLImageConversion::DataFormat srcFormat, WebGLImageConversion::DataFormat dstFormat, WebGLImageConversion::AlphaOp alphaOp)
{
#define FORMATCONVERTER_CASE_SRCFORMAT(SrcFormat) \
    case SrcFormat: \
        return convert<SrcFormat>(dstFormat, alphaOp);

        switch (srcFormat) {
            FORMATCONVERTER_CASE_SRCFORMAT(WebGLImageConversion::DataFormatR8)
            FORMATCONVERTER_CASE_SRCFORMAT(WebGLImageConversion::DataFormatA8)
            FORMATCONVERTER_CASE_SRCFORMAT(WebGLImageConversion::DataFormatR32F)
            FORMATCONVERTER_CASE_SRCFORMAT(WebGLImageConversion::DataFormatA32F)
            FORMATCONVERTER_CASE_SRCFORMAT(WebGLImageConversion::DataFormatRA8)
            FORMATCONVERTER_CASE_SRCFORMAT(WebGLImageConversion::DataFormatRA32F)
            FORMATCONVERTER_CASE_SRCFORMAT(WebGLImageConversion::DataFormatRGB8)
            FORMATCONVERTER_CASE_SRCFORMAT(WebGLImageConversion::DataFormatBGR8)
            FORMATCONVERTER_CASE_SRCFORMAT(WebGLImageConversion::DataFormatRGB565)
            FORMATCONVERTER_CASE_SRCFORMAT(WebGLImageConversion::DataFormatRGB32F)
            FORMATCONVERTER_CASE_SRCFORMAT(WebGLImageConversion::DataFormatRGBA8)
            FORMATCONVERTER_CASE_SRCFORMAT(WebGLImageConversion::DataFormatARGB8)
            FORMATCONVERTER_CASE_SRCFORMAT(WebGLImageConversion::DataFormatABGR8)
            FORMATCONVERTER_CASE_SRCFORMAT(WebGLImageConversion::DataFormatAR8)
            FORMATCONVERTER_CASE_SRCFORMAT(WebGLImageConversion::DataFormatBGRA8)
            FORMATCONVERTER_CASE_SRCFORMAT(WebGLImageConversion::DataFormatRGBA5551)
            FORMATCONVERTER_CASE_SRCFORMAT(WebGLImageConversion::DataFormatRGBA4444)
            FORMATCONVERTER_CASE_SRCFORMAT(WebGLImageConversion::DataFormatRGBA32F)
        default:
            ASSERT_NOT_REACHED();
        }
#undef FORMATCONVERTER_CASE_SRCFORMAT
}

template<WebGLImageConversion::DataFormat SrcFormat>
void FormatConverter::convert(WebGLImageConversion::DataFormat dstFormat, WebGLImageConversion::AlphaOp alphaOp)
{
#define FORMATCONVERTER_CASE_DSTFORMAT(DstFormat) \
    case DstFormat: \
        return convert<SrcFormat, DstFormat>(alphaOp);

        switch (dstFormat) {
            FORMATCONVERTER_CASE_DSTFORMAT(WebGLImageConversion::DataFormatR8)
            FORMATCONVERTER_CASE_DSTFORMAT(WebGLImageConversion::DataFormatR16F)
            FORMATCONVERTER_CASE_DSTFORMAT(WebGLImageConversion::DataFormatR32F)
            FORMATCONVERTER_CASE_DSTFORMAT(WebGLImageConversion::DataFormatA8)
            FORMATCONVERTER_CASE_DSTFORMAT(WebGLImageConversion::DataFormatA16F)
            FORMATCONVERTER_CASE_DSTFORMAT(WebGLImageConversion::DataFormatA32F)
            FORMATCONVERTER_CASE_DSTFORMAT(WebGLImageConversion::DataFormatRA8)
            FORMATCONVERTER_CASE_DSTFORMAT(WebGLImageConversion::DataFormatRA16F)
            FORMATCONVERTER_CASE_DSTFORMAT(WebGLImageConversion::DataFormatRA32F)
            FORMATCONVERTER_CASE_DSTFORMAT(WebGLImageConversion::DataFormatRGB8)
            FORMATCONVERTER_CASE_DSTFORMAT(WebGLImageConversion::DataFormatRGB565)
            FORMATCONVERTER_CASE_DSTFORMAT(WebGLImageConversion::DataFormatRGB16F)
            FORMATCONVERTER_CASE_DSTFORMAT(WebGLImageConversion::DataFormatRGB32F)
            FORMATCONVERTER_CASE_DSTFORMAT(WebGLImageConversion::DataFormatRGBA8)
            FORMATCONVERTER_CASE_DSTFORMAT(WebGLImageConversion::DataFormatRGBA5551)
            FORMATCONVERTER_CASE_DSTFORMAT(WebGLImageConversion::DataFormatRGBA4444)
            FORMATCONVERTER_CASE_DSTFORMAT(WebGLImageConversion::DataFormatRGBA16F)
            FORMATCONVERTER_CASE_DSTFORMAT(WebGLImageConversion::DataFormatRGBA32F)
        default:
            ASSERT_NOT_REACHED();
        }

#undef FORMATCONVERTER_CASE_DSTFORMAT
}

template<WebGLImageConversion::DataFormat SrcFormat, WebGLImageConversion::DataFormat DstFormat>
void FormatConverter::convert(WebGLImageConversion::AlphaOp alphaOp)
{
#define FORMATCONVERTER_CASE_ALPHAOP(alphaOp) \
    case alphaOp: \
        return convert<SrcFormat, DstFormat, alphaOp>();

        switch (alphaOp) {
            FORMATCONVERTER_CASE_ALPHAOP(WebGLImageConversion::AlphaDoNothing)
            FORMATCONVERTER_CASE_ALPHAOP(WebGLImageConversion::AlphaDoPremultiply)
            FORMATCONVERTER_CASE_ALPHAOP(WebGLImageConversion::AlphaDoUnmultiply)
        default:
            ASSERT_NOT_REACHED();
        }
#undef FORMATCONVERTER_CASE_ALPHAOP
}

template<WebGLImageConversion::DataFormat SrcFormat, WebGLImageConversion::DataFormat DstFormat, WebGLImageConversion::AlphaOp alphaOp>
void FormatConverter::convert()
{
    // Many instantiations of this template function will never be entered, so we try
    // to return immediately in these cases to avoid the compiler to generate useless code.
    if (SrcFormat == DstFormat && alphaOp == WebGLImageConversion::AlphaDoNothing) {
        ASSERT_NOT_REACHED();
        return;
    }
    if (!IsFloatFormat<DstFormat>::Value && IsFloatFormat<SrcFormat>::Value) {
        ASSERT_NOT_REACHED();
        return;
    }

    // Only textures uploaded from DOM elements or ImageData can allow DstFormat != SrcFormat.
    const bool srcFormatComesFromDOMElementOrImageData = WebGLImageConversion::srcFormatComeFromDOMElementOrImageData(SrcFormat);
    if (!srcFormatComesFromDOMElementOrImageData && SrcFormat != DstFormat) {
        ASSERT_NOT_REACHED();
        return;
    }
    // Likewise, only textures uploaded from DOM elements or ImageData can possibly have to be unpremultiplied.
    if (!srcFormatComesFromDOMElementOrImageData && alphaOp == WebGLImageConversion::AlphaDoUnmultiply) {
        ASSERT_NOT_REACHED();
        return;
    }
    if ((!HasAlpha(SrcFormat) || !HasColor(SrcFormat) || !HasColor(DstFormat)) && alphaOp != WebGLImageConversion::AlphaDoNothing) {
        ASSERT_NOT_REACHED();
        return;
    }

    typedef typename DataTypeForFormat<SrcFormat>::Type SrcType;
    typedef typename DataTypeForFormat<DstFormat>::Type DstType;
    const int IntermediateSrcFormat = IntermediateFormat<DstFormat>::Value;
    typedef typename DataTypeForFormat<IntermediateSrcFormat>::Type IntermediateSrcType;
    const ptrdiff_t srcStrideInElements = m_srcStride / sizeof(SrcType);
    const ptrdiff_t dstStrideInElements = m_dstStride / sizeof(DstType);
    const bool trivialUnpack = (SrcFormat == WebGLImageConversion::DataFormatRGBA8 && !IsFloatFormat<DstFormat>::Value && !IsHalfFloatFormat<DstFormat>::Value) || SrcFormat == WebGLImageConversion::DataFormatRGBA32F;
    const bool trivialPack = (DstFormat == WebGLImageConversion::DataFormatRGBA8 || DstFormat == WebGLImageConversion::DataFormatRGBA32F) && alphaOp == WebGLImageConversion::AlphaDoNothing && m_dstStride > 0;
    ASSERT(!trivialUnpack || !trivialPack);

    const SrcType *srcRowStart = static_cast<const SrcType*>(m_srcStart);
    DstType* dstRowStart = static_cast<DstType*>(m_dstStart);
    if (!trivialUnpack && trivialPack) {
        for (size_t i = 0; i < m_height; ++i) {
            unpack<SrcFormat>(srcRowStart, dstRowStart, m_width);
            srcRowStart += srcStrideInElements;
            dstRowStart += dstStrideInElements;
        }
    } else if (!trivialUnpack && !trivialPack) {
        for (size_t i = 0; i < m_height; ++i) {
            unpack<SrcFormat>(srcRowStart, reinterpret_cast<IntermediateSrcType*>(m_unpackedIntermediateSrcData.get()), m_width);
            pack<DstFormat, alphaOp>(reinterpret_cast<IntermediateSrcType*>(m_unpackedIntermediateSrcData.get()), dstRowStart, m_width);
            srcRowStart += srcStrideInElements;
            dstRowStart += dstStrideInElements;
        }
    } else {
        for (size_t i = 0; i < m_height; ++i) {
            pack<DstFormat, alphaOp>(srcRowStart, dstRowStart, m_width);
            srcRowStart += srcStrideInElements;
            dstRowStart += dstStrideInElements;
        }
    }
    m_success = true;
    return;
}

} // anonymous namespace

bool WebGLImageConversion::computeFormatAndTypeParameters(GLenum format, GLenum type, unsigned* componentsPerPixel, unsigned* bytesPerComponent)
{
    switch (format) {
    case GL_ALPHA:
    case GL_LUMINANCE:
    case GL_DEPTH_COMPONENT:
    case GL_DEPTH_STENCIL_OES:
        *componentsPerPixel = 1;
        break;
    case GL_LUMINANCE_ALPHA:
        *componentsPerPixel = 2;
        break;
    case GL_RGB:
        *componentsPerPixel = 3;
        break;
    case GL_RGBA:
    case GL_BGRA_EXT: // GL_EXT_texture_format_BGRA8888
        *componentsPerPixel = 4;
        break;
    default:
        return false;
    }
    switch (type) {
    case GL_UNSIGNED_BYTE:
        *bytesPerComponent = sizeof(GLubyte);
        break;
    case GL_UNSIGNED_SHORT:
        *bytesPerComponent = sizeof(GLushort);
        break;
    case GL_UNSIGNED_SHORT_5_6_5:
    case GL_UNSIGNED_SHORT_4_4_4_4:
    case GL_UNSIGNED_SHORT_5_5_5_1:
        *componentsPerPixel = 1;
        *bytesPerComponent = sizeof(GLushort);
        break;
    case GL_UNSIGNED_INT_24_8_OES:
    case GL_UNSIGNED_INT:
        *bytesPerComponent = sizeof(GLuint);
        break;
    case GL_FLOAT: // OES_texture_float
        *bytesPerComponent = sizeof(GLfloat);
        break;
    case GL_HALF_FLOAT_OES: // OES_texture_half_float
        *bytesPerComponent = sizeof(GLushort);
        break;
    default:
        return false;
    }
    return true;
}

GLenum WebGLImageConversion::computeImageSizeInBytes(GLenum format, GLenum type, GLsizei width, GLsizei height, GLint alignment, unsigned* imageSizeInBytes, unsigned* paddingInBytes)
{
    ASSERT(imageSizeInBytes);
    ASSERT(alignment == 1 || alignment == 2 || alignment == 4 || alignment == 8);
    if (width < 0 || height < 0)
        return GL_INVALID_VALUE;
    unsigned bytesPerComponent, componentsPerPixel;
    if (!computeFormatAndTypeParameters(format, type, &bytesPerComponent, &componentsPerPixel))
        return GL_INVALID_ENUM;
    if (!width || !height) {
        *imageSizeInBytes = 0;
        if (paddingInBytes)
            *paddingInBytes = 0;
        return GL_NO_ERROR;
    }
    CheckedInt<uint32_t> checkedValue(bytesPerComponent * componentsPerPixel);
    checkedValue *=  width;
    if (!checkedValue.isValid())
        return GL_INVALID_VALUE;
    unsigned validRowSize = checkedValue.value();
    unsigned padding = 0;
    unsigned residual = validRowSize % alignment;
    if (residual) {
        padding = alignment - residual;
        checkedValue += padding;
    }
    // Last row needs no padding.
    checkedValue *= (height - 1);
    checkedValue += validRowSize;
    if (!checkedValue.isValid())
        return GL_INVALID_VALUE;
    *imageSizeInBytes = checkedValue.value();
    if (paddingInBytes)
        *paddingInBytes = padding;
    return GL_NO_ERROR;
}

WebGLImageConversion::ImageExtractor::ImageExtractor(Image* image, ImageHtmlDomSource imageHtmlDomSource, bool premultiplyAlpha, bool ignoreGammaAndColorProfile)
{
    m_image = image;
    m_imageHtmlDomSource = imageHtmlDomSource;
    m_extractSucceeded = extractImage(premultiplyAlpha, ignoreGammaAndColorProfile);
}

WebGLImageConversion::ImageExtractor::~ImageExtractor()
{
    if (m_skiaImage)
        m_skiaImage->bitmap().unlockPixels();
}

bool WebGLImageConversion::ImageExtractor::extractImage(bool premultiplyAlpha, bool ignoreGammaAndColorProfile)
{
    if (!m_image)
        return false;
    m_skiaImage = m_image->nativeImageForCurrentFrame();
    m_alphaOp = AlphaDoNothing;
    bool hasAlpha = m_skiaImage ? !m_skiaImage->bitmap().isOpaque() : true;
    if ((!m_skiaImage || ignoreGammaAndColorProfile || (hasAlpha && !premultiplyAlpha)) && m_image->data()) {
        // Attempt to get raw unpremultiplied image data.
        OwnPtr<ImageDecoder> decoder(ImageDecoder::create(
            *(m_image->data()), ImageSource::AlphaNotPremultiplied,
            ignoreGammaAndColorProfile ? ImageSource::GammaAndColorProfileIgnored : ImageSource::GammaAndColorProfileApplied));
        if (!decoder)
            return false;
        decoder->setData(m_image->data(), true);
        if (!decoder->frameCount())
            return false;
        ImageFrame* frame = decoder->frameBufferAtIndex(0);
        if (!frame || frame->status() != ImageFrame::FrameComplete)
            return false;
        hasAlpha = frame->hasAlpha();
        m_nativeImage = frame->asNewNativeImage();
        if (!m_nativeImage.get() || !m_nativeImage->isDataComplete() || !m_nativeImage->bitmap().width() || !m_nativeImage->bitmap().height())
            return false;
        if (m_nativeImage->bitmap().colorType() != kN32_SkColorType)
            return false;
        m_skiaImage = m_nativeImage.get();
        if (hasAlpha && premultiplyAlpha)
            m_alphaOp = AlphaDoPremultiply;
    } else if (!premultiplyAlpha && hasAlpha) {
        // 1. For texImage2D with HTMLVideoElment input, assume no PremultiplyAlpha had been applied and the alpha value for each pixel is 0xFF
        // which is true at present and may be changed in the future and needs adjustment accordingly.
        // 2. For texImage2D with HTMLCanvasElement input in which Alpha is already Premultiplied in this port,
        // do AlphaDoUnmultiply if UNPACK_PREMULTIPLY_ALPHA_WEBGL is set to false.
        if (m_imageHtmlDomSource != HtmlDomVideo)
            m_alphaOp = AlphaDoUnmultiply;
    }
    if (!m_skiaImage)
        return false;

    m_imageSourceFormat = SK_B32_SHIFT ? DataFormatRGBA8 : DataFormatBGRA8;
    m_imageWidth = m_skiaImage->bitmap().width();
    m_imageHeight = m_skiaImage->bitmap().height();
    if (!m_imageWidth || !m_imageHeight) {
        m_skiaImage.clear();
        return false;
    }
    // Fail if the image was downsampled because of memory limits.
    if (m_imageWidth != (unsigned)m_image->size().width() || m_imageHeight != (unsigned)m_image->size().height()) {
        m_skiaImage.clear();
        return false;
    }
    m_imageSourceUnpackAlignment = 0;
    m_skiaImage->bitmap().lockPixels();
    m_imagePixelData = m_skiaImage->bitmap().getPixels();
    return true;
}

unsigned WebGLImageConversion::getClearBitsByFormat(GLenum format)
{
    switch (format) {
    case GL_ALPHA:
    case GL_LUMINANCE:
    case GL_LUMINANCE_ALPHA:
    case GL_RGB:
    case GL_RGB565:
    case GL_RGBA:
    case GL_RGBA4:
    case GL_RGB5_A1:
        return GL_COLOR_BUFFER_BIT;
    case GL_DEPTH_COMPONENT16:
    case GL_DEPTH_COMPONENT:
        return GL_DEPTH_BUFFER_BIT;
    case GL_STENCIL_INDEX8:
        return GL_STENCIL_BUFFER_BIT;
    case GL_DEPTH_STENCIL_OES:
        return GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT;
    default:
        return 0;
    }
}

unsigned WebGLImageConversion::getChannelBitsByFormat(GLenum format)
{
    switch (format) {
    case GL_ALPHA:
        return ChannelAlpha;
    case GL_LUMINANCE:
        return ChannelRGB;
    case GL_LUMINANCE_ALPHA:
        return ChannelRGBA;
    case GL_RGB:
    case GL_RGB565:
        return ChannelRGB;
    case GL_RGBA:
    case GL_RGBA4:
    case GL_RGB5_A1:
        return ChannelRGBA;
    case GL_DEPTH_COMPONENT16:
    case GL_DEPTH_COMPONENT:
        return ChannelDepth;
    case GL_STENCIL_INDEX8:
        return ChannelStencil;
    case GL_DEPTH_STENCIL_OES:
        return ChannelDepth | ChannelStencil;
    default:
        return 0;
    }
}

bool WebGLImageConversion::packImageData(
    Image* image,
    const void* pixels,
    GLenum format,
    GLenum type,
    bool flipY,
    AlphaOp alphaOp,
    DataFormat sourceFormat,
    unsigned width,
    unsigned height,
    unsigned sourceUnpackAlignment,
    Vector<uint8_t>& data)
{
    if (!pixels)
        return false;

    unsigned packedSize;
    // Output data is tightly packed (alignment == 1).
    if (computeImageSizeInBytes(format, type, width, height, 1, &packedSize, 0) != GL_NO_ERROR)
        return false;
    data.resize(packedSize);

    if (!packPixels(reinterpret_cast<const uint8_t*>(pixels), sourceFormat, width, height, sourceUnpackAlignment, format, type, alphaOp, data.data(), flipY))
        return false;
    if (ImageObserver *observer = image->imageObserver())
        observer->didDraw(image);
    return true;
}

bool WebGLImageConversion::extractImageData(
    const uint8_t* imageData,
    const IntSize& imageDataSize,
    GLenum format,
    GLenum type,
    bool flipY,
    bool premultiplyAlpha,
    Vector<uint8_t>& data)
{
    if (!imageData)
        return false;
    int width = imageDataSize.width();
    int height = imageDataSize.height();

    unsigned packedSize;
    // Output data is tightly packed (alignment == 1).
    if (computeImageSizeInBytes(format, type, width, height, 1, &packedSize, 0) != GL_NO_ERROR)
        return false;
    data.resize(packedSize);

    if (!packPixels(imageData, DataFormatRGBA8, width, height, 0, format, type, premultiplyAlpha ? AlphaDoPremultiply : AlphaDoNothing, data.data(), flipY))
        return false;

    return true;
}

bool WebGLImageConversion::extractTextureData(
    unsigned width,
    unsigned height,
    GLenum format, GLenum type,
    unsigned unpackAlignment,
    bool flipY, bool premultiplyAlpha,
    const void* pixels,
    Vector<uint8_t>& data)
{
    // Assumes format, type, etc. have already been validated.
    DataFormat sourceDataFormat = getDataFormat(format, type);

    // Resize the output buffer.
    unsigned int componentsPerPixel, bytesPerComponent;
    if (!computeFormatAndTypeParameters(format, type, &componentsPerPixel, &bytesPerComponent))
        return false;
    unsigned bytesPerPixel = componentsPerPixel * bytesPerComponent;
    data.resize(width * height * bytesPerPixel);

    if (!packPixels(static_cast<const uint8_t*>(pixels), sourceDataFormat, width, height, unpackAlignment, format, type, (premultiplyAlpha ? AlphaDoPremultiply : AlphaDoNothing), data.data(), flipY))
        return false;

    return true;
}

bool WebGLImageConversion::packPixels(
    const uint8_t* sourceData,
    DataFormat sourceDataFormat,
    unsigned width,
    unsigned height,
    unsigned sourceUnpackAlignment,
    unsigned destinationFormat,
    unsigned destinationType,
    AlphaOp alphaOp,
    void* destinationData,
    bool flipY)
{
    int validSrc = width * TexelBytesForFormat(sourceDataFormat);
    int remainder = sourceUnpackAlignment ? (validSrc % sourceUnpackAlignment) : 0;
    int srcStride = remainder ? (validSrc + sourceUnpackAlignment - remainder) : validSrc;

    DataFormat dstDataFormat = getDataFormat(destinationFormat, destinationType);
    int dstStride = width * TexelBytesForFormat(dstDataFormat);
    if (flipY) {
        destinationData = static_cast<uint8_t*>(destinationData) + dstStride*(height - 1);
        dstStride = -dstStride;
    }
    if (!HasAlpha(sourceDataFormat) || !HasColor(sourceDataFormat) || !HasColor(dstDataFormat))
        alphaOp = AlphaDoNothing;

    if (sourceDataFormat == dstDataFormat && alphaOp == AlphaDoNothing) {
        const uint8_t* ptr = sourceData;
        const uint8_t* ptrEnd = sourceData + srcStride * height;
        unsigned rowSize = (dstStride > 0) ? dstStride: -dstStride;
        uint8_t* dst = static_cast<uint8_t*>(destinationData);
        while (ptr < ptrEnd) {
            memcpy(dst, ptr, rowSize);
            ptr += srcStride;
            dst += dstStride;
        }
        return true;
    }

    FormatConverter converter(width, height, sourceData, destinationData, srcStride, dstStride);
    converter.convert(sourceDataFormat, dstDataFormat, alphaOp);
    if (!converter.Success())
        return false;
    return true;
}

} // namespace blink
