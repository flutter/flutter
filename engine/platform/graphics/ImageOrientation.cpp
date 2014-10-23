
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

#include "config.h"
#include "platform/graphics/ImageOrientation.h"

#include "platform/transforms/AffineTransform.h"

namespace blink {

AffineTransform ImageOrientation::transformFromDefault(const FloatSize& drawnSize) const
{
    float w = drawnSize.width();
    float h = drawnSize.height();

    switch (m_orientation) {
    case OriginTopLeft:
        return AffineTransform();
    case OriginTopRight:
        return AffineTransform(-1,  0,  0,  1,  w, 0);
    case OriginBottomRight:
        return AffineTransform(-1,  0,  0, -1,  w, h);
    case OriginBottomLeft:
        return AffineTransform( 1,  0,  0, -1,  0, h);
    case OriginLeftTop:
        return AffineTransform( 0,  1,  1,  0,  0, 0);
    case OriginRightTop:
        return AffineTransform( 0,  1, -1,  0,  w, 0);
    case OriginRightBottom:
        return AffineTransform( 0, -1, -1,  0,  w, h);
    case OriginLeftBottom:
        return AffineTransform( 0, -1,  1,  0,  0, h);
    }

    ASSERT_NOT_REACHED();
    return AffineTransform();
}

} // namespace blink
