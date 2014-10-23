/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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
#include "platform/graphics/DrawLooperBuilder.h"

#include "platform/geometry/FloatSize.h"
#include "platform/graphics/Color.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkColorFilter.h"
#include "third_party/skia/include/core/SkDrawLooper.h"
#include "third_party/skia/include/core/SkPaint.h"
#include "third_party/skia/include/core/SkXfermode.h"
#include "third_party/skia/include/effects/SkBlurMaskFilter.h"
#include "wtf/RefPtr.h"

namespace blink {

DrawLooperBuilder::DrawLooperBuilder() { }

DrawLooperBuilder::~DrawLooperBuilder() { }

PassOwnPtr<DrawLooperBuilder> DrawLooperBuilder::create()
{
    return adoptPtr(new DrawLooperBuilder);
}

PassRefPtr<SkDrawLooper> DrawLooperBuilder::detachDrawLooper()
{
    return adoptRef(m_skDrawLooperBuilder.detachLooper());
}

void DrawLooperBuilder::addUnmodifiedContent()
{
    SkLayerDrawLooper::LayerInfo info;
    m_skDrawLooperBuilder.addLayerOnTop(info);
}

// This replicates the old skia behavior when it used to take radius for blur. Now it takes sigma.
static SkScalar RadiusToSigma(SkScalar radius)
{
    SkASSERT(radius > 0);
    return 0.57735f * radius + 0.5f;
}

void DrawLooperBuilder::addShadow(const FloatSize& offset, float blur, const Color& color,
    ShadowTransformMode shadowTransformMode, ShadowAlphaMode shadowAlphaMode)
{
    // Detect when there's no effective shadow.
    if (!color.alpha())
        return;

    SkColor skColor = color.rgb();

    SkLayerDrawLooper::LayerInfo info;

    switch (shadowAlphaMode) {
    case ShadowRespectsAlpha:
        info.fColorMode = SkXfermode::kDst_Mode;
        break;
    case ShadowIgnoresAlpha:
        info.fColorMode = SkXfermode::kSrc_Mode;
        break;
    default:
        ASSERT_NOT_REACHED();
    }

    if (blur)
        info.fPaintBits |= SkLayerDrawLooper::kMaskFilter_Bit; // our blur
    info.fPaintBits |= SkLayerDrawLooper::kColorFilter_Bit;
    info.fOffset.set(offset.width(), offset.height());
    info.fPostTranslate = (shadowTransformMode == ShadowIgnoresTransforms);

    SkPaint* paint = m_skDrawLooperBuilder.addLayerOnTop(info);

    if (blur) {
        const SkScalar sigma = RadiusToSigma(blur / 2);
        uint32_t mfFlags = SkBlurMaskFilter::kHighQuality_BlurFlag;
        if (shadowTransformMode == ShadowIgnoresTransforms)
            mfFlags |= SkBlurMaskFilter::kIgnoreTransform_BlurFlag;
        RefPtr<SkMaskFilter> mf = adoptRef(SkBlurMaskFilter::Create(kNormal_SkBlurStyle, sigma, mfFlags));
        paint->setMaskFilter(mf.get());
    }

    RefPtr<SkColorFilter> cf = adoptRef(SkColorFilter::CreateModeFilter(skColor, SkXfermode::kSrcIn_Mode));
    paint->setColorFilter(cf.get());
}

} // namespace blink
