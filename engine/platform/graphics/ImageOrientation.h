/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef ImageOrientation_h
#define ImageOrientation_h

#include "platform/PlatformExport.h"

namespace blink {

class AffineTransform;
class FloatSize;

// This enum intentionally matches the orientation values from the EXIF spec.
// See JEITA CP-3451, page 18. http://www.exif.org/Exif2-2.PDF
enum ImageOrientationEnum {
    // "TopLeft" means that the 0 row starts at the Top, the 0 column starts at the Left.
    OriginTopLeft = 1, // default
    OriginTopRight = 2, // mirror along y-axis
    OriginBottomRight = 3, // 180 degree rotation
    OriginBottomLeft = 4, // mirror along the x-axis
    OriginLeftTop = 5, // mirror along x-axis + 270 degree CW rotation
    OriginRightTop = 6, // 90 degree CW rotation
    OriginRightBottom = 7, // mirror along x-axis + 90 degree CW rotation
    OriginLeftBottom = 8, // 270 degree CW rotation
    // All other values are "reserved" as of EXIF 2.2
    DefaultImageOrientation = OriginTopLeft,
};

enum RespectImageOrientationEnum {
    DoNotRespectImageOrientation = 0,
    RespectImageOrientation = 1
};

class PLATFORM_EXPORT ImageOrientation {
public:
    ImageOrientation(ImageOrientationEnum orientation = DefaultImageOrientation)
        : m_orientation(orientation)
    {
    }

    bool usesWidthAsHeight() const
    {
        // Values 5 through 8 all flip the width/height.
        return m_orientation >= OriginLeftTop;
    }

    // ImageOrientationEnum currently matches EXIF values, however code outside
    // this function should never assume that.
    static ImageOrientation fromEXIFValue(int exifValue)
    {
        // Values direct from images may be invalid, in which case we use the default.
        if (exifValue < OriginTopLeft || exifValue > OriginLeftBottom)
            return DefaultImageOrientation;
        return static_cast<ImageOrientationEnum>(exifValue);
    }

    // This transform can be used for drawing an image according to the orientation.
    // It should be used in a right-handed coordinate system.
    AffineTransform transformFromDefault(const FloatSize& drawnSize) const;

    inline bool operator==(const ImageOrientation& other) const { return other.m_orientation == m_orientation; }
    inline bool operator!=(const ImageOrientation& other) const { return !(*this == other); }

private:
    // FIXME: This only needs to be one byte.
    ImageOrientationEnum m_orientation;
};

} // namespace blink

#endif // ImageOrientation_h
