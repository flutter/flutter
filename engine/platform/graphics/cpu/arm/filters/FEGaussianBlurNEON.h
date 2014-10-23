/*
 * Copyright (C) 2011 University of Szeged
 * Copyright (C) 2011 Zoltan Herczeg
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

#ifndef FEGaussianBlurNEON_h
#define FEGaussianBlurNEON_h

#if HAVE(ARM_NEON_INTRINSICS)

#include "platform/graphics/cpu/arm/filters/NEONHelpers.h"
#include "platform/graphics/filters/FEGaussianBlur.h"

namespace blink {

inline void boxBlurNEON(Uint8ClampedArray* srcPixelArray, Uint8ClampedArray* dstPixelArray,
                        unsigned dx, int dxLeft, int dxRight, int stride, int strideLine, int effectWidth, int effectHeight)
{
    uint32_t* sourcePixel = reinterpret_cast<uint32_t*>(srcPixelArray->data());
    uint32_t* destinationPixel = reinterpret_cast<uint32_t*>(dstPixelArray->data());

    float32x4_t deltaX = vdupq_n_f32(1.0 / dx);
    int pixelLine = strideLine / 4;
    int pixelStride = stride / 4;

    for (int y = 0; y < effectHeight; ++y) {
        int line = y * pixelLine;
        float32x4_t sum = vdupq_n_f32(0);
        // Fill the kernel
        int maxKernelSize = std::min(dxRight, effectWidth);
        for (int i = 0; i < maxKernelSize; ++i) {
            float32x4_t sourcePixelAsFloat = loadRGBA8AsFloat(sourcePixel + line + i * pixelStride);
            sum = vaddq_f32(sum, sourcePixelAsFloat);
        }

        // Blurring
        for (int x = 0; x < effectWidth; ++x) {
            int pixelOffset = line + x * pixelStride;
            float32x4_t result = vmulq_f32(sum, deltaX);
            storeFloatAsRGBA8(result, destinationPixel + pixelOffset);
            if (x >= dxLeft) {
                float32x4_t sourcePixelAsFloat = loadRGBA8AsFloat(sourcePixel + pixelOffset - dxLeft * pixelStride);
                sum = vsubq_f32(sum, sourcePixelAsFloat);
            }
            if (x + dxRight < effectWidth) {
                float32x4_t sourcePixelAsFloat = loadRGBA8AsFloat(sourcePixel + pixelOffset + dxRight * pixelStride);
                sum = vaddq_f32(sum, sourcePixelAsFloat);
            }
        }
    }
}

} // namespace blink

#endif // HAVE(ARM_NEON_INTRINSICS)

#endif // FEGaussianBlurNEON_h
