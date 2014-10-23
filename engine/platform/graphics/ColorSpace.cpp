/*
 * Copyright (c) 2008, Google Inc. All rights reserved.
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
 * Copyright (C) 2010 Torch Mobile (Beijing) Co. Ltd. All rights reserved.
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
#include "platform/graphics/ColorSpace.h"

#include "wtf/MathExtras.h"

namespace blink {

namespace ColorSpaceUtilities {

static const uint8_t* getLinearRgbLUT()
{
    static uint8_t linearRgbLUT[256];
    static bool initialized;
    if (!initialized) {
        for (unsigned i = 0; i < 256; i++) {
            float color = i  / 255.0f;
            color = (color <= 0.04045f ? color / 12.92f : pow((color + 0.055f) / 1.055f, 2.4f));
            color = std::max(0.0f, color);
            color = std::min(1.0f, color);
            linearRgbLUT[i] = static_cast<uint8_t>(round(color * 255));
        }
        initialized = true;
    }
    return linearRgbLUT;
}

static const uint8_t* getDeviceRgbLUT()
{
    static uint8_t deviceRgbLUT[256];
    static bool initialized;
    if (!initialized) {
        for (unsigned i = 0; i < 256; i++) {
            float color = i / 255.0f;
            color = (powf(color, 1.0f / 2.4f) * 1.055f) - 0.055f;
            color = std::max(0.0f, color);
            color = std::min(1.0f, color);
            deviceRgbLUT[i] = static_cast<uint8_t>(round(color * 255));
        }
        initialized = true;
    }
    return deviceRgbLUT;
}

const uint8_t* getConversionLUT(ColorSpace dstColorSpace, ColorSpace srcColorSpace)
{
    // Identity.
    if (srcColorSpace == dstColorSpace)
        return 0;

    // Only sRGB/DeviceRGB <-> linearRGB are supported at the moment.
    if ((srcColorSpace != ColorSpaceLinearRGB && srcColorSpace != ColorSpaceDeviceRGB)
        || (dstColorSpace != ColorSpaceLinearRGB && dstColorSpace != ColorSpaceDeviceRGB))
        return 0;

    if (dstColorSpace == ColorSpaceLinearRGB)
        return getLinearRgbLUT();
    if (dstColorSpace == ColorSpaceDeviceRGB)
        return getDeviceRgbLUT();

    ASSERT_NOT_REACHED();
    return 0;
}

Color convertColor(const Color& srcColor, ColorSpace dstColorSpace, ColorSpace srcColorSpace)
{
    const uint8_t* lookupTable = getConversionLUT(dstColorSpace, srcColorSpace);
    if (!lookupTable)
        return srcColor;

    return Color(lookupTable[srcColor.red()], lookupTable[srcColor.green()], lookupTable[srcColor.blue()], srcColor.alpha());
}

} // namespace ColorSpaceUtilities

} // namespace blink
