/*
 * Copyright (C) 2006, 2007, 2008 Apple Computer, Inc.  All rights reserved.
 * Copyright (C) 2008 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2013 Google, Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/graphics/Pattern.h"

#include <v8.h>
#include "SkCanvas.h"
#include "SkColorShader.h"
#include "platform/graphics/skia/SkiaUtils.h"

namespace blink {

PassRefPtr<Pattern> Pattern::createBitmapPattern(PassRefPtr<Image> tileImage, RepeatMode repeatMode)
{
    return adoptRef(new Pattern(tileImage, repeatMode));
}

Pattern::Pattern(PassRefPtr<Image> image, RepeatMode repeatMode)
    : m_repeatMode(repeatMode)
    , m_externalMemoryAllocated(0)
{
    if (image) {
        m_tileImage = image->nativeImageForCurrentFrame();
    }
}

Pattern::~Pattern()
{
    if (m_externalMemoryAllocated)
        v8::Isolate::GetCurrent()->AdjustAmountOfExternalAllocatedMemory(-m_externalMemoryAllocated);
}

SkShader* Pattern::shader()
{
    if (m_pattern)
        return m_pattern.get();

    SkMatrix localMatrix = affineTransformToSkMatrix(m_patternSpaceTransformation);

    // If we don't have a bitmap, return a transparent shader.
    if (!m_tileImage) {
        m_pattern = adoptRef(new SkColorShader(SK_ColorTRANSPARENT));
    } else if (m_repeatMode == RepeatModeXY) {
        m_pattern = adoptRef(SkShader::CreateBitmapShader(m_tileImage->bitmap(),
            SkShader::kRepeat_TileMode, SkShader::kRepeat_TileMode, &localMatrix));
    } else {
        // Skia does not have a "draw the tile only once" option. Clamp_TileMode
        // repeats the last line of the image after drawing one tile. To avoid
        // filling the space with arbitrary pixels, this workaround forces the
        // image to have a line of transparent pixels on the "repeated" edge(s),
        // thus causing extra space to be transparent filled.
        SkShader::TileMode tileModeX = (m_repeatMode & RepeatModeX)
            ? SkShader::kRepeat_TileMode
            : SkShader::kClamp_TileMode;
        SkShader::TileMode tileModeY = (m_repeatMode & RepeatModeY)
            ? SkShader::kRepeat_TileMode
            : SkShader::kClamp_TileMode;
        int expandW = (m_repeatMode & RepeatModeX) ? 0 : 1;
        int expandH = (m_repeatMode & RepeatModeY) ? 0 : 1;

        // Create a transparent bitmap 1 pixel wider and/or taller than the
        // original, then copy the orignal into it.
        // FIXME: Is there a better way to pad (not scale) an image in skia?
        SkImageInfo info = m_tileImage->bitmap().info();
        info.fWidth += expandW;
        info.fHeight += expandH;
        // we explicitly require non-opaquness, since we are going to add a transparent strip.
        info.fAlphaType = kPremul_SkAlphaType;

        SkBitmap bm2;
        bm2.allocPixels(info);
        bm2.eraseARGB(0x00, 0x00, 0x00, 0x00);
        SkCanvas canvas(bm2);
        canvas.drawBitmap(m_tileImage->bitmap(), 0, 0);
        bm2.setImmutable();
        m_pattern = adoptRef(SkShader::CreateBitmapShader(bm2, tileModeX, tileModeY, &localMatrix));

        // Clamp to int, since that's what the adjust function takes.
        m_externalMemoryAllocated = static_cast<int>(std::min(static_cast<size_t>(INT_MAX), bm2.getSafeSize()));
        v8::Isolate::GetCurrent()->AdjustAmountOfExternalAllocatedMemory(m_externalMemoryAllocated);
    }
    return m_pattern.get();
}

void Pattern::setPatternSpaceTransform(const AffineTransform& patternSpaceTransformation)
{
    if (patternSpaceTransformation == m_patternSpaceTransformation)
        return;

    m_patternSpaceTransformation = patternSpaceTransformation;
    m_pattern.clear();
}

} // namespace blink
