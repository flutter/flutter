/*
 * Copyright (C) 2008, 2009, 2010, 2012 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/graphics/GradientGeneratedImage.h"

#include "platform/geometry/FloatRect.h"
#include "platform/graphics/GraphicsContextStateSaver.h"

namespace blink {

void GradientGeneratedImage::draw(GraphicsContext* destContext, const FloatRect& destRect, const FloatRect& srcRect, CompositeOperator compositeOp, WebBlendMode blendMode)
{
    GraphicsContextStateSaver stateSaver(*destContext);
    destContext->setCompositeOperation(compositeOp, blendMode);
    destContext->clip(destRect);
    destContext->translate(destRect.x(), destRect.y());
    if (destRect.size() != srcRect.size())
        destContext->scale(destRect.width() / srcRect.width(), destRect.height() / srcRect.height());
    destContext->translate(-srcRect.x(), -srcRect.y());
    destContext->setFillGradient(m_gradient);
    destContext->fillRect(FloatRect(FloatPoint(), m_size));
}

void GradientGeneratedImage::drawPattern(GraphicsContext* destContext, const FloatRect& srcRect, const FloatSize& scale,
    const FloatPoint& phase, CompositeOperator compositeOp, const FloatRect& destRect, WebBlendMode blendMode, const IntSize& repeatSpacing)
{
    float stepX = srcRect.width() + repeatSpacing.width();
    float stepY = srcRect.height() + repeatSpacing.height();
    int firstColumn = static_cast<int>(floorf((((destRect.x() - phase.x()) / scale.width()) - srcRect.x()) / srcRect.width()));
    int firstRow = static_cast<int>(floorf((((destRect.y() - phase.y()) / scale.height())  - srcRect.y()) / srcRect.height()));
    for (int i = firstColumn; ; ++i) {
        float dstX = (srcRect.x() + i * stepX) * scale.width() + phase.x();
        // assert that first column encroaches left edge of dstRect.
        ASSERT(i > firstColumn || dstX <= destRect.x());
        ASSERT(i == firstColumn || dstX > destRect.x());

        if (dstX >= destRect.maxX())
            break;
        float dstMaxX = dstX + srcRect.width() * scale.width();
        if (dstX < destRect.x())
            dstX = destRect.x();
        if (dstMaxX > destRect.maxX())
            dstMaxX = destRect.maxX();
        if (dstX >= dstMaxX)
            continue;

        FloatRect visibleSrcRect;
        FloatRect tileDstRect;
        tileDstRect.setX(dstX);
        tileDstRect.setWidth(dstMaxX - dstX);
        visibleSrcRect.setX((tileDstRect.x() - phase.x()) / scale.width() - i * stepX);
        visibleSrcRect.setWidth(tileDstRect.width() / scale.width());

        for (int j = firstRow; ; j++) {
            float dstY = (srcRect.y() + j * stepY) * scale.height() + phase.y();
            // assert that first row encroaches top edge of dstRect.
            ASSERT(j > firstRow || dstY <= destRect.y());
            ASSERT(j == firstRow || dstY > destRect.y());

            if (dstY >= destRect.maxY())
                break;
            float dstMaxY = dstY + srcRect.height() * scale.height();
            if (dstY < destRect.y())
                dstY = destRect.y();
            if (dstMaxY > destRect.maxY())
                dstMaxY = destRect.maxY();
            if (dstY >= dstMaxY)
                continue;

            tileDstRect.setY(dstY);
            tileDstRect.setHeight(dstMaxY - dstY);
            visibleSrcRect.setY((tileDstRect.y() - phase.y()) / scale.height() - j * stepY);
            visibleSrcRect.setHeight(tileDstRect.height() / scale.height());
            draw(destContext, tileDstRect, visibleSrcRect, compositeOp, blendMode);
        }
    }
}

} // namespace blink
