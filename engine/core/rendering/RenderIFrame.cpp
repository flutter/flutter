// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"

#include "core/rendering/RenderIFrame.h"

#include "core/editing/FrameSelection.h"
#include "core/html/HTMLIFrameElement.h"
#include "core/loader/FrameLoaderClient.h"
#include "core/rendering/PaintInfo.h"
#include "platform/geometry/LayoutPoint.h"

namespace blink {

RenderIFrame::RenderIFrame(HTMLIFrameElement* iframe)
    : RenderReplaced(iframe)
{
}

RenderIFrame::~RenderIFrame()
{
}

void RenderIFrame::layout()
{
    RenderReplaced::layout();

    // TODO(mpcomplete): This will generate extra SetBounds calls in some cases
    // because some layout modules involve multiple passes (e.g., flexbox).
    // Instead, we'll need to defer the work to later in the pipeline.
    mojo::View* contentView = toHTMLIFrameElement(node())->contentView();
    if (!contentView)
        return;

    IntRect bounds = pixelSnappedIntRect(frameRect());
    mojo::Rect mojo_bounds;
    mojo_bounds.x = bounds.x();
    mojo_bounds.y = bounds.y();
    mojo_bounds.width = bounds.width();
    mojo_bounds.height = bounds.height();
    contentView->SetBounds(mojo_bounds);
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
