// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"

#include "core/rendering/RenderRemote.h"

#include "core/editing/FrameSelection.h"
#include "core/html/HTMLIFrameElement.h"
#include "core/rendering/PaintInfo.h"
#include "platform/geometry/LayoutPoint.h"

namespace blink {

RenderRemote::RenderRemote(HTMLIFrameElement* view)
    : RenderReplaced(view)
{
}

RenderRemote::~RenderRemote()
{
}

void RenderRemote::paintReplaced(PaintInfo& paintInfo,
                                 const LayoutPoint& paintOffset) {
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
