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
#include "core/rendering/style/ShadowList.h"

#include "platform/geometry/FloatRect.h"
#include "wtf/OwnPtr.h"

namespace blink {

static inline void calculateShadowExtent(const ShadowList* shadowList, float& shadowLeft, float& shadowRight, float& shadowTop, float& shadowBottom)
{
    ASSERT(shadowList);
    size_t shadowCount = shadowList->shadows().size();
    for (size_t i = 0; i < shadowCount; ++i) {
        const ShadowData& shadow = shadowList->shadows()[i];
        if (shadow.style() == Inset)
            continue;
        float blurAndSpread = shadow.blur() + shadow.spread();
        shadowLeft = std::min(shadow.x() - blurAndSpread, shadowLeft);
        shadowRight = std::max(shadow.x() + blurAndSpread, shadowRight);
        shadowTop = std::min(shadow.y() - blurAndSpread, shadowTop);
        shadowBottom = std::max(shadow.y() + blurAndSpread, shadowBottom);
    }
}

void ShadowList::adjustRectForShadow(LayoutRect& rect) const
{
    FloatRect floatRect(rect);
    adjustRectForShadow(floatRect);
    rect = LayoutRect(floatRect);
}

void ShadowList::adjustRectForShadow(FloatRect& rect) const
{
    float shadowLeft = 0;
    float shadowRight = 0;
    float shadowTop = 0;
    float shadowBottom = 0;
    calculateShadowExtent(this, shadowLeft, shadowRight, shadowTop, shadowBottom);

    rect.move(shadowLeft, shadowTop);
    rect.setWidth(rect.width() - shadowLeft + shadowRight);
    rect.setHeight(rect.height() - shadowTop + shadowBottom);
}

PassRefPtr<ShadowList> ShadowList::blend(const ShadowList* from, const ShadowList* to, double progress)
{
    size_t fromLength = from ? from->shadows().size() : 0;
    size_t toLength = to ? to->shadows().size() : 0;
    if (!fromLength && !toLength)
        return nullptr;

    ShadowDataVector shadows;

    DEFINE_STATIC_LOCAL(ShadowData, defaultShadowData, (FloatPoint(), 0, 0, Normal, Color::transparent));
    DEFINE_STATIC_LOCAL(ShadowData, defaultInsetShadowData, (FloatPoint(), 0, 0, Inset, Color::transparent));

    size_t maxLength = std::max(fromLength, toLength);
    for (size_t i = 0; i < maxLength; ++i) {
        const ShadowData* fromShadow = i < fromLength ? &from->shadows()[i] : 0;
        const ShadowData* toShadow = i < toLength ? &to->shadows()[i] : 0;
        if (!fromShadow)
            fromShadow = toShadow->style() == Inset ? &defaultInsetShadowData : &defaultShadowData;
        else if (!toShadow)
            toShadow = fromShadow->style() == Inset ? &defaultInsetShadowData : &defaultShadowData;
        shadows.append(toShadow->blend(*fromShadow, progress));
    }

    return ShadowList::adopt(shadows);
}

PassOwnPtr<DrawLooperBuilder> ShadowList::createDrawLooper(DrawLooperBuilder::ShadowAlphaMode alphaMode, bool isHorizontal) const
{
    OwnPtr<DrawLooperBuilder> drawLooperBuilder = DrawLooperBuilder::create();
    for (size_t i = shadows().size(); i--; ) {
        const ShadowData& shadow = shadows()[i];
        float shadowX = isHorizontal ? shadow.x() : shadow.y();
        float shadowY = isHorizontal ? shadow.y() : -shadow.x();
        drawLooperBuilder->addShadow(FloatSize(shadowX, shadowY), shadow.blur(), shadow.color(),
            DrawLooperBuilder::ShadowRespectsTransforms, alphaMode);
    }
    drawLooperBuilder->addUnmodifiedContent();
    return drawLooperBuilder.release();
}

} // namespace blink
