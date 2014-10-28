/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#ifndef PageWidgetDelegate_h
#define PageWidgetDelegate_h

#include "public/platform/WebCanvas.h"
#include "public/web/WebWidget.h"
#include "wtf/OwnPtr.h"

namespace blink {

class LocalFrame;
class Page;
class WebGestureEvent;
class WebInputEvent;
class WebKeyboardEvent;
class WebMouseEvent;
class WebMouseWheelEvent;
class WebTouchEvent;

class PageWidgetEventHandler {
public:
    virtual void handleMouseMove(LocalFrame& mainFrame, const WebMouseEvent&);
    virtual void handleMouseLeave(LocalFrame& mainFrame, const WebMouseEvent&);
    virtual void handleMouseDown(LocalFrame& mainFrame, const WebMouseEvent&);
    virtual void handleMouseUp(LocalFrame& mainFrame, const WebMouseEvent&);
    virtual bool handleMouseWheel(LocalFrame& mainFrame, const WebMouseWheelEvent&);
    virtual bool handleKeyEvent(const WebKeyboardEvent&) = 0;
    virtual bool handleCharEvent(const WebKeyboardEvent&) = 0;
    virtual bool handleGestureEvent(const WebGestureEvent&) = 0;
    virtual bool handleTouchEvent(LocalFrame& mainFrame, const WebTouchEvent&);
    virtual ~PageWidgetEventHandler() { }
};


// Common implementation of WebViewImpl.
class PageWidgetDelegate {
public:
    enum CanvasBackground {
        Opaque,
        Translucent,
    };
    // rootFrame arguments indicate a root localFrame from which to start performing the
    // specified operation. If rootFrame is 0, these methods will attempt to use the
    // Page's mainFrame(), if it is a LocalFrame.
    static void animate(Page*, double monotonicFrameBeginTime, LocalFrame* rootFrame = 0);
    static void layout(Page*, LocalFrame* rootFrame = 0);
    static void paint(Page*, WebCanvas*, const WebRect&, CanvasBackground, LocalFrame* rootFrame = 0);
    static bool handleInputEvent(Page*, PageWidgetEventHandler&, const WebInputEvent&, LocalFrame* rootFrame = 0);

private:
    PageWidgetDelegate() { }
};

}
#endif
