/*
 * Copyright (C) 2012 Gabor Rapcsanyi (rgabor@inf.u-szeged.hu), University of Szeged
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY UNIVERSITY OF SZEGED ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL UNIVERSITY OF SZEGED OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef WebGLImageConversionNEON_h
#define WebGLImageConversionNEON_h

#if HAVE(ARM_NEON_INTRINSICS)

#include <arm_neon.h>

namespace blink {

namespace SIMD {

ALWAYS_INLINE void unpackOneRowOfRGBA16LittleToRGBA8(const uint16_t*& source, uint8_t*& destination, unsigned& pixelsPerRow)
{
    unsigned componentsPerRow = pixelsPerRow * 4;
    unsigned tailComponents = componentsPerRow % 16;
    unsigned componentsSize = componentsPerRow - tailComponents;
    const uint8_t* src = reinterpret_cast<const uint8_t*>(source);

    for (unsigned i = 0; i < componentsSize; i += 16) {
        uint8x16x2_t components = vld2q_u8(src + i * 2);
        vst1q_u8(destination + i, components.val[1]);
    }

    source += componentsSize;
    destination += componentsSize;
    pixelsPerRow = tailComponents / 4;
}

ALWAYS_INLINE void unpackOneRowOfRGB16LittleToRGBA8(const uint16_t*& source, uint8_t*& destination, unsigned& pixelsPerRow)
{
    unsigned componentsPerRow = pixelsPerRow * 3;
    unsigned tailComponents = componentsPerRow % 24;
    unsigned componentsSize = componentsPerRow - tailComponents;

    uint8x8_t componentA = vdup_n_u8(0xFF);
    for (unsigned i = 0; i < componentsSize; i += 24) {
        uint16x8x3_t RGB16 = vld3q_u16(source + i);
        uint8x8_t componentR = vqmovn_u16(vshrq_n_u16(RGB16.val[0], 8));
        uint8x8_t componentG = vqmovn_u16(vshrq_n_u16(RGB16.val[1], 8));
        uint8x8_t componentB = vqmovn_u16(vshrq_n_u16(RGB16.val[2], 8));
        uint8x8x4_t RGBA8 = {{componentR, componentG, componentB, componentA}};
        vst4_u8(destination, RGBA8);
        destination += 32;
    }

    source += componentsSize;
    pixelsPerRow = tailComponents / 3;
}

ALWAYS_INLINE void unpackOneRowOfARGB16LittleToRGBA8(const uint16_t*& source, uint8_t*& destination, unsigned& pixelsPerRow)
{
    unsigned componentsPerRow = pixelsPerRow * 4;
    unsigned tailComponents = componentsPerRow % 32;
    unsigned componentsSize = componentsPerRow - tailComponents;

    for (unsigned i = 0; i < componentsSize; i += 32) {
        uint16x8x4_t ARGB16 = vld4q_u16(source + i);
        uint8x8_t componentA = vqmovn_u16(vshrq_n_u16(ARGB16.val[0], 8));
        uint8x8_t componentR = vqmovn_u16(vshrq_n_u16(ARGB16.val[1], 8));
        uint8x8_t componentG = vqmovn_u16(vshrq_n_u16(ARGB16.val[2], 8));
        uint8x8_t componentB = vqmovn_u16(vshrq_n_u16(ARGB16.val[3], 8));
        uint8x8x4_t RGBA8 = {{componentR, componentG, componentB, componentA}};
        vst4_u8(destination + i, RGBA8);
    }

    source += componentsSize;
    destination += componentsSize;
    pixelsPerRow = tailComponents / 4;
}

ALWAYS_INLINE void unpackOneRowOfBGRA16LittleToRGBA8(const uint16_t*& source, uint8_t*& destination, unsigned& pixelsPerRow)
{
    unsigned componentsPerRow = pixelsPerRow * 4;
    unsigned tailComponents = componentsPerRow % 32;
    unsigned componentsSize = componentsPerRow - tailComponents;

    for (unsigned i = 0; i < componentsSize; i += 32) {
        uint16x8x4_t ARGB16 = vld4q_u16(source + i);
        uint8x8_t componentB = vqmovn_u16(vshrq_n_u16(ARGB16.val[0], 8));
        uint8x8_t componentG = vqmovn_u16(vshrq_n_u16(ARGB16.val[1], 8));
        uint8x8_t componentR = vqmovn_u16(vshrq_n_u16(ARGB16.val[2], 8));
        uint8x8_t componentA = vqmovn_u16(vshrq_n_u16(ARGB16.val[3], 8));
        uint8x8x4_t RGBA8 = {{componentR, componentG, componentB, componentA}};
        vst4_u8(destination + i, RGBA8);
    }

    source += componentsSize;
    destination += componentsSize;
    pixelsPerRow = tailComponents / 4;
}

ALWAYS_INLINE void unpackOneRowOfRGBA4444ToRGBA8(const uint16_t*& source, uint8_t*& destination, unsigned& pixelsPerRow)
{
    unsigned tailPixels = pixelsPerRow % 8;
    unsigned pixelSize = pixelsPerRow - tailPixels;

    uint16x8_t immediate0x0f = vdupq_n_u16(0x0F);
    for (unsigned i = 0; i < pixelSize; i += 8) {
        uint16x8_t eightPixels = vld1q_u16(source + i);

        uint8x8_t componentR = vqmovn_u16(vshrq_n_u16(eightPixels, 12));
        uint8x8_t componentG = vqmovn_u16(vandq_u16(vshrq_n_u16(eightPixels, 8), immediate0x0f));
        uint8x8_t componentB = vqmovn_u16(vandq_u16(vshrq_n_u16(eightPixels, 4), immediate0x0f));
        uint8x8_t componentA = vqmovn_u16(vandq_u16(eightPixels, immediate0x0f));

        componentR = vorr_u8(vshl_n_u8(componentR, 4), componentR);
        componentG = vorr_u8(vshl_n_u8(componentG, 4), componentG);
        componentB = vorr_u8(vshl_n_u8(componentB, 4), componentB);
        componentA = vorr_u8(vshl_n_u8(componentA, 4), componentA);

        uint8x8x4_t destComponents = {{componentR, componentG, componentB, componentA}};
        vst4_u8(destination, destComponents);
        destination += 32;
    }

    source += pixelSize;
    pixelsPerRow = tailPixels;
}

ALWAYS_INLINE void packOneRowOfRGBA8ToUnsignedShort4444(const uint8_t*& source, uint16_t*& destination, unsigned& pixelsPerRow)
{
    unsigned componentsPerRow = pixelsPerRow * 4;
    unsigned tailComponents = componentsPerRow % 32;
    unsigned componentsSize = componentsPerRow - tailComponents;

    uint8_t* dst = reinterpret_cast<uint8_t*>(destination);
    uint8x8_t immediate0xf0 = vdup_n_u8(0xF0);
    for (unsigned i = 0; i < componentsSize; i += 32) {
        uint8x8x4_t RGBA8 = vld4_u8(source + i);

        uint8x8_t componentR = vand_u8(RGBA8.val[0], immediate0xf0);
        uint8x8_t componentG = vshr_n_u8(vand_u8(RGBA8.val[1], immediate0xf0), 4);
        uint8x8_t componentB = vand_u8(RGBA8.val[2], immediate0xf0);
        uint8x8_t componentA = vshr_n_u8(vand_u8(RGBA8.val[3], immediate0xf0), 4);

        uint8x8x2_t RGBA4;
        RGBA4.val[0] = vorr_u8(componentB, componentA);
        RGBA4.val[1] = vorr_u8(componentR, componentG);
        vst2_u8(dst, RGBA4);
        dst += 16;
    }

    source += componentsSize;
    destination += componentsSize / 4;
    pixelsPerRow = tailComponents / 4;
}

ALWAYS_INLINE void unpackOneRowOfRGBA5551ToRGBA8(const uint16_t*& source, uint8_t*& destination, unsigned& pixelsPerRow)
{
    unsigned tailPixels = pixelsPerRow % 8;
    unsigned pixelSize = pixelsPerRow - tailPixels;

    uint8x8_t immediate0x7 = vdup_n_u8(0x7);
    uint8x8_t immediate0xff = vdup_n_u8(0xFF);
    uint16x8_t immediate0x1f = vdupq_n_u16(0x1F);
    uint16x8_t immediate0x1 = vdupq_n_u16(0x1);

    for (unsigned i = 0; i < pixelSize; i += 8) {
        uint16x8_t eightPixels = vld1q_u16(source + i);

        uint8x8_t componentR = vqmovn_u16(vshrq_n_u16(eightPixels, 11));
        uint8x8_t componentG = vqmovn_u16(vandq_u16(vshrq_n_u16(eightPixels, 6), immediate0x1f));
        uint8x8_t componentB = vqmovn_u16(vandq_u16(vshrq_n_u16(eightPixels, 1), immediate0x1f));
        uint8x8_t componentA = vqmovn_u16(vandq_u16(eightPixels, immediate0x1));

        componentR = vorr_u8(vshl_n_u8(componentR, 3), vand_u8(componentR, immediate0x7));
        componentG = vorr_u8(vshl_n_u8(componentG, 3), vand_u8(componentG, immediate0x7));
        componentB = vorr_u8(vshl_n_u8(componentB, 3), vand_u8(componentB, immediate0x7));
        componentA = vmul_u8(componentA, immediate0xff);

        uint8x8x4_t destComponents = {{componentR, componentG, componentB, componentA}};
        vst4_u8(destination, destComponents);
        destination += 32;
    }

    source += pixelSize;
    pixelsPerRow = tailPixels;
}

ALWAYS_INLINE void packOneRowOfRGBA8ToUnsignedShort5551(const uint8_t*& source, uint16_t*& destination, unsigned& pixelsPerRow)
{
    unsigned componentsPerRow = pixelsPerRow * 4;
    unsigned tailComponents = componentsPerRow % 32;
    unsigned componentsSize = componentsPerRow - tailComponents;

    uint8_t* dst = reinterpret_cast<uint8_t*>(destination);

    uint8x8_t immediate0xf8 = vdup_n_u8(0xF8);
    uint8x8_t immediate0x18 = vdup_n_u8(0x18);
    for (unsigned i = 0; i < componentsSize; i += 32) {
        uint8x8x4_t RGBA8 = vld4_u8(source + i);

        uint8x8_t componentR = vand_u8(RGBA8.val[0], immediate0xf8);
        uint8x8_t componentG3bit = vshr_n_u8(RGBA8.val[1], 5);

        uint8x8_t componentG2bit = vshl_n_u8(vand_u8(RGBA8.val[1], immediate0x18), 3);
        uint8x8_t componentB = vshr_n_u8(vand_u8(RGBA8.val[2], immediate0xf8), 2);
        uint8x8_t componentA = vshr_n_u8(RGBA8.val[3], 7);

        uint8x8x2_t RGBA5551;
        RGBA5551.val[0] = vorr_u8(vorr_u8(componentG2bit, componentB), componentA);
        RGBA5551.val[1] = vorr_u8(componentR, componentG3bit);
        vst2_u8(dst, RGBA5551);
        dst += 16;
    }

    source += componentsSize;
    destination += componentsSize / 4;
    pixelsPerRow = tailComponents / 4;
}

ALWAYS_INLINE void unpackOneRowOfRGB565ToRGBA8(const uint16_t*& source, uint8_t*& destination, unsigned& pixelsPerRow)
{
    unsigned tailPixels = pixelsPerRow % 8;
    unsigned pixelSize = pixelsPerRow - tailPixels;

    uint16x8_t immediate0x3f = vdupq_n_u16(0x3F);
    uint16x8_t immediate0x1f = vdupq_n_u16(0x1F);
    uint8x8_t immediate0x3 = vdup_n_u8(0x3);
    uint8x8_t immediate0x7 = vdup_n_u8(0x7);

    uint8x8_t componentA = vdup_n_u8(0xFF);

    for (unsigned i = 0; i < pixelSize; i += 8) {
        uint16x8_t eightPixels = vld1q_u16(source + i);

        uint8x8_t componentR = vqmovn_u16(vshrq_n_u16(eightPixels, 11));
        uint8x8_t componentG = vqmovn_u16(vandq_u16(vshrq_n_u16(eightPixels, 5), immediate0x3f));
        uint8x8_t componentB = vqmovn_u16(vandq_u16(eightPixels, immediate0x1f));

        componentR = vorr_u8(vshl_n_u8(componentR, 3), vand_u8(componentR, immediate0x7));
        componentG = vorr_u8(vshl_n_u8(componentG, 2), vand_u8(componentG, immediate0x3));
        componentB = vorr_u8(vshl_n_u8(componentB, 3), vand_u8(componentB, immediate0x7));

        uint8x8x4_t destComponents = {{componentR, componentG, componentB, componentA}};
        vst4_u8(destination, destComponents);
        destination += 32;
    }

    source += pixelSize;
    pixelsPerRow = tailPixels;
}

ALWAYS_INLINE void packOneRowOfRGBA8ToUnsignedShort565(const uint8_t*& source, uint16_t*& destination, unsigned& pixelsPerRow)
{
    unsigned componentsPerRow = pixelsPerRow * 4;
    unsigned tailComponents = componentsPerRow % 32;
    unsigned componentsSize = componentsPerRow - tailComponents;
    uint8_t* dst = reinterpret_cast<uint8_t*>(destination);

    uint8x8_t immediate0xf8 = vdup_n_u8(0xF8);
    uint8x8_t immediate0x1c = vdup_n_u8(0x1C);
    for (unsigned i = 0; i < componentsSize; i += 32) {
        uint8x8x4_t RGBA8 = vld4_u8(source + i);

        uint8x8_t componentR = vand_u8(RGBA8.val[0], immediate0xf8);
        uint8x8_t componentGLeft = vshr_n_u8(RGBA8.val[1], 5);
        uint8x8_t componentGRight = vshl_n_u8(vand_u8(RGBA8.val[1], immediate0x1c), 3);
        uint8x8_t componentB = vshr_n_u8(vand_u8(RGBA8.val[2], immediate0xf8), 3);

        uint8x8x2_t RGB565;
        RGB565.val[0] = vorr_u8(componentGRight, componentB);
        RGB565.val[1] = vorr_u8(componentR, componentGLeft);
        vst2_u8(dst, RGB565);
        dst += 16;
    }

    source += componentsSize;
    destination += componentsSize / 4;
    pixelsPerRow = tailComponents / 4;
}

} // namespace SIMD

} // namespace blink

#endif // HAVE(ARM_NEON_INTRINSICS)

#endif // WebGLImageConversionNEON_h
