/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef WebContentLayerClient_h
#define WebContentLayerClient_h

#include "WebCanvas.h"
#include "WebCommon.h"

namespace blink {

struct WebRect;
struct WebFloatRect;

class BLINK_PLATFORM_EXPORT WebContentLayerClient {
public:
    enum GraphicsContextStatus { GraphicsContextEnabled, GraphicsContextDisabled };

    // Paints the content area for the layer, typically dirty rects submitted
    // through WebContentLayer::setNeedsDisplay, submitting drawing commands
    // through the WebCanvas.
    // The canvas is already clipped to the |clip| rect.
    // Optionally, the implementation may set |opaque| to a rect covering pixels that
    // the implementation knows are opaque. This information can be used for various
    // optimizations.
    // The |disableContext| enum controls most processing in
    // GraphicsContext to isolate the painting code in performance tests.
    virtual void paintContents(WebCanvas*, const WebRect& clip, bool canPaintLCDText, WebFloatRect& opaque, GraphicsContextStatus = GraphicsContextEnabled) = 0;

protected:
    virtual ~WebContentLayerClient() { }
};

} // namespace blink

#endif // WebContentLayerClient_h
