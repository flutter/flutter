/*
 * Copyright (C) 2004, 2006, 2007 Apple Inc. All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/core/rendering/RenderHTMLCanvas.h"

#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/html/HTMLCanvasElement.h"
#include "sky/engine/core/html/canvas/CanvasRenderingContext.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/PaintInfo.h"
#include "sky/engine/core/rendering/RenderView.h"

namespace blink {

RenderHTMLCanvas::RenderHTMLCanvas(HTMLCanvasElement* element)
    : RenderReplaced(element, element->size())
{
}

LayerType RenderHTMLCanvas::layerTypeRequired() const
{
    return NormalLayer;
}

void RenderHTMLCanvas::paintReplaced(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    GraphicsContext* context = paintInfo.context;

    LayoutRect contentRect = contentBoxRect();
    contentRect.moveBy(paintOffset);
    LayoutRect paintRect = replacedContentRect();
    paintRect.moveBy(paintOffset);

    bool clip = !contentRect.contains(paintRect);
    if (clip) {
        // Not allowed to overflow the content box.
        paintInfo.context->save();
        paintInfo.context->clip(pixelSnappedIntRect(contentRect));
    }

    // FIXME: InterpolationNone should be used if ImageRenderingOptimizeContrast is set.
    // See bug for more details: crbug.com/353716.
    InterpolationQuality interpolationQuality = style()->imageRendering() == ImageRenderingOptimizeContrast ? InterpolationLow : CanvasDefaultInterpolationQuality;

    HTMLCanvasElement* canvas = toHTMLCanvasElement(node());
    LayoutSize layoutSize = contentRect.size();
    if (style()->imageRendering() == ImageRenderingPixelated
        && (layoutSize.width() > canvas->width() || layoutSize.height() > canvas->height() || layoutSize == canvas->size())) {
        interpolationQuality = InterpolationNone;
    }

    InterpolationQuality previousInterpolationQuality = context->imageInterpolationQuality();
    context->setImageInterpolationQuality(interpolationQuality);
    canvas->paint(context, paintRect);
    context->setImageInterpolationQuality(previousInterpolationQuality);

    if (clip)
        context->restore();
}

void RenderHTMLCanvas::canvasSizeChanged()
{
    IntSize canvasSize = toHTMLCanvasElement(node())->size();

    if (canvasSize == intrinsicSize())
        return;

    setIntrinsicSize(canvasSize);

    if (!parent())
        return;

    if (!preferredLogicalWidthsDirty())
        setPreferredLogicalWidthsDirty();

    LayoutSize oldSize = size();
    updateLogicalWidth();
    updateLogicalHeight();
    if (oldSize == size())
        return;

    if (!selfNeedsLayout())
        setNeedsLayoutAndFullPaintInvalidation();
}

} // namespace blink
