/*
 * Copyright (C) 2009 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef ColorSpace_h
#define ColorSpace_h

#include "platform/PlatformExport.h"
#include "platform/graphics/Color.h"

namespace blink {

enum ColorSpace {
    ColorSpaceDeviceRGB,
    ColorSpaceSRGB,
    ColorSpaceLinearRGB
};

namespace ColorSpaceUtilities {

// Get a pointer to a 8-bit lookup table that will convert color components
// in the |srcColorSpace| to the |dstColorSpace|.
// If the conversion cannot be performed, or is a no-op (identity transform),
// then 0 is returned.
// (Note that a round-trip - f(B,A)[f(A,B)[x]] - is not lossless in general.)
const uint8_t* getConversionLUT(ColorSpace dstColorSpace, ColorSpace srcColorSpace = ColorSpaceDeviceRGB);

// Convert a Color assumed to be in the |srcColorSpace| into the |dstColorSpace|.
Color convertColor(const Color& srcColor, ColorSpace dstColorSpace, ColorSpace srcColorSpace = ColorSpaceDeviceRGB);

} // namespace ColorSpaceUtilities

} // namespace blink

#endif // ColorSpace_h
