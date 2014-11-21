// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_HTML_CANVAS_MOUSEEVENTHITREGION_H_
#define SKY_ENGINE_CORE_HTML_CANVAS_MOUSEEVENTHITREGION_H_

#include "sky/engine/core/events/MouseEvent.h"
#include "sky/engine/core/html/HTMLCanvasElement.h"
#include "sky/engine/core/html/canvas/CanvasRenderingContext.h"
#include "sky/engine/core/html/canvas/CanvasRenderingContext2D.h"

namespace blink {

class MouseEventHitRegion {
public:
    static String region(MouseEvent& event)
    {
        if (!event.target() || !isHTMLCanvasElement(event.target()->toNode()))
            return String();

        HTMLCanvasElement* canvas = toHTMLCanvasElement(event.target()->toNode());
        CanvasRenderingContext* context = canvas->renderingContext();
        if (!context || !context->is2d())
            return String();

        HitRegion* hitRegion = toCanvasRenderingContext2D(context)->
            hitRegionAtPoint(LayoutPoint(event.offsetX(), event.offsetY()));

        if (!hitRegion)
            return String();

        String id = hitRegion->id();
        if (id.isEmpty())
            return String();

        return id;
    }
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_HTML_CANVAS_MOUSEEVENTHITREGION_H_
