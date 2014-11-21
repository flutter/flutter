// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"

#include "sky/engine/core/rendering/RenderIFrame.h"

#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/html/HTMLIFrameElement.h"
#include "sky/engine/core/loader/FrameLoaderClient.h"
#include "sky/engine/core/rendering/PaintInfo.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/platform/geometry/LayoutPoint.h"

namespace blink {

RenderIFrame::RenderIFrame(HTMLIFrameElement* iframe)
    : RenderReplaced(iframe)
{
    view()->addIFrame(this);
}

RenderIFrame::~RenderIFrame()
{
    if (view())
        view()->removeIFrame(this);
}

void RenderIFrame::updateWidgetBounds()
{
    mojo::View* contentView = toHTMLIFrameElement(node())->contentView();
    if (!contentView)
        return;

    IntRect bounds = absoluteContentBox();
    mojo::Rect mojoBounds;
    mojoBounds.x = bounds.x();
    mojoBounds.y = bounds.y();
    mojoBounds.width = bounds.width();
    mojoBounds.height = bounds.height();
    contentView->SetBounds(mojoBounds);
}

void RenderIFrame::paintReplaced(PaintInfo& paintInfo,
                                 const LayoutPoint& paintOffset)
{
    // Draw a gray background. This should be painted over by the actual
    // content.
    // TODO(mpcomplete): figure out what we should actually do here.
    GraphicsContext* context = paintInfo.context;

    IntRect paintRect = pixelSnappedIntRect(LayoutRect(
        paintOffset.x(), paintOffset.y(), contentWidth(), contentHeight()));
    context->setStrokeStyle(SolidStroke);
    context->setStrokeColor(Color::lightGray);
    context->setFillColor(Color::darkGray);
    context->drawRect(paintRect);
}

} // namespace blink
