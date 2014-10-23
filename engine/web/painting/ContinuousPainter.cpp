/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * 1. Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY GOOGLE INC. AND ITS CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL GOOGLE INC.
 * OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "web/painting/ContinuousPainter.h"

#include "platform/TraceEvent.h"
#include "platform/graphics/GraphicsLayer.h"
#include "web/PageOverlayList.h"

using namespace blink;

namespace blink {

void ContinuousPainter::setNeedsDisplayRecursive(GraphicsLayer* layer, PageOverlayList* pageOverlays)
{
    if (!layer)
        return;

    if (pageOverlays && pageOverlays->findGraphicsLayer(layer) != WTF::kNotFound)
        return;

    TRACE_EVENT0("blink", "ContinuousPainter::setNeedsDisplayRecursive");
    layer->setNeedsDisplay();

    setNeedsDisplayRecursive(layer->maskLayer(), pageOverlays);
    setNeedsDisplayRecursive(layer->contentsClippingMaskLayer(), pageOverlays);

    const Vector<GraphicsLayer*>& children = layer->children();
    Vector<GraphicsLayer*>::const_iterator it;
    for (it = children.begin(); it != children.end(); ++it)
        setNeedsDisplayRecursive(*it, pageOverlays);
}

} // namespace blink
