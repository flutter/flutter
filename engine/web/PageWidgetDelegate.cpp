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

#include "sky/engine/config.h"
#include "sky/engine/web/PageWidgetDelegate.h"

#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/page/AutoscrollController.h"
#include "sky/engine/core/page/EventHandler.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/platform/Logging.h"
#include "sky/engine/platform/graphics/GraphicsContext.h"
#include "sky/engine/public/platform/WebInputEvent.h"
#include "sky/engine/web/WebInputEventConversion.h"
#include "sky/engine/wtf/CurrentTime.h"

namespace blink {

static inline FrameView* rootFrameView(Page* page, LocalFrame* rootFrame)
{
    if (rootFrame)
        return rootFrame->view();
    if (!page)
        return 0;
    return page->mainFrame()->view();
}

void PageWidgetDelegate::animate(Page* page, double monotonicFrameBeginTime, LocalFrame* rootFrame)
{
    RefPtr<FrameView> view = rootFrameView(page, rootFrame);
    WTF_LOG(ScriptedAnimationController, "PageWidgetDelegate::animate: view = %d", !view ? 0 : 1);
    if (!view)
        return;
    page->autoscrollController().animate(monotonicFrameBeginTime);
    page->animator().serviceScriptedAnimations(monotonicFrameBeginTime);
}

void PageWidgetDelegate::layout(Page* page, LocalFrame* rootFrame)
{
    if (!page)
        return;

    if (!rootFrame) {
        if (!page->mainFrame())
            return;
        rootFrame = page->mainFrame();
    }

    page->animator().updateLayoutAndStyleForPainting(rootFrame);
}

void PageWidgetDelegate::paint(Page* page, WebCanvas* canvas, const WebRect& rect, CanvasBackground background, LocalFrame* rootFrame)
{
    if (rect.isEmpty())
        return;
    GraphicsContext gc(canvas);
    gc.setCertainlyOpaque(background == Opaque);
    gc.applyDeviceScaleFactor(page->deviceScaleFactor());
    gc.setDeviceScaleFactor(page->deviceScaleFactor());
    IntRect dirtyRect(rect);
    gc.save(); // Needed to save the canvas, not the GraphicsContext.
    FrameView* view = rootFrameView(page, rootFrame);
    if (view) {
        gc.clip(dirtyRect);
        view->paint(&gc, dirtyRect);
    } else {
        gc.fillRect(dirtyRect, Color::white);
    }
    gc.restore();
}

bool PageWidgetDelegate::handleInputEvent(Page* page, PageWidgetEventHandler& handler, const WebInputEvent& event, LocalFrame* rootFrame)
{
    LocalFrame* frame = rootFrame;
    if (!frame)
        frame = page ? page->mainFrame() : 0;
    switch (event.type) {

    // FIXME: WebKit seems to always return false on mouse events processing
    // methods. For now we'll assume it has processed them (as we are only
    // interested in whether keyboard events are processed).
    case WebInputEvent::MouseMove:
        if (!frame || !frame->view())
            return true;
        handler.handleMouseMove(*frame, static_cast<const WebMouseEvent&>(event));
        return true;
    case WebInputEvent::MouseLeave:
        if (!frame || !frame->view())
            return true;
        handler.handleMouseLeave(*frame, static_cast<const WebMouseEvent&>(event));
        return true;
    case WebInputEvent::MouseDown:
        if (!frame || !frame->view())
            return true;
        handler.handleMouseDown(*frame, static_cast<const WebMouseEvent&>(event));
        return true;
    case WebInputEvent::MouseUp:
        if (!frame || !frame->view())
            return true;
        handler.handleMouseUp(*frame, static_cast<const WebMouseEvent&>(event));
        return true;

    case WebInputEvent::MouseWheel:
        if (!frame || !frame->view())
            return false;
        return handler.handleMouseWheel(*frame, static_cast<const WebMouseWheelEvent&>(event));

    case WebInputEvent::RawKeyDown:
    case WebInputEvent::KeyDown:
    case WebInputEvent::KeyUp:
        return handler.handleKeyEvent(static_cast<const WebKeyboardEvent&>(event));

    case WebInputEvent::Char:
        return handler.handleCharEvent(static_cast<const WebKeyboardEvent&>(event));
    case WebInputEvent::GestureScrollBegin:
    case WebInputEvent::GestureScrollEnd:
    case WebInputEvent::GestureScrollUpdate:
    case WebInputEvent::GestureScrollUpdateWithoutPropagation:
    case WebInputEvent::GestureFlingStart:
    case WebInputEvent::GestureFlingCancel:
    case WebInputEvent::GestureTap:
    case WebInputEvent::GestureTapUnconfirmed:
    case WebInputEvent::GestureTapDown:
    case WebInputEvent::GestureShowPress:
    case WebInputEvent::GestureTapCancel:
    case WebInputEvent::GestureDoubleTap:
    case WebInputEvent::GestureTwoFingerTap:
    case WebInputEvent::GestureLongPress:
    case WebInputEvent::GestureLongTap:
        return handler.handleGestureEvent(static_cast<const WebGestureEvent&>(event));

    case WebInputEvent::TouchStart:
    case WebInputEvent::TouchMove:
    case WebInputEvent::TouchEnd:
    case WebInputEvent::TouchCancel:
        if (!frame || !frame->view())
            return false;
        return handler.handleTouchEvent(*frame, static_cast<const WebTouchEvent&>(event));

    case WebInputEvent::GesturePinchBegin:
    case WebInputEvent::GesturePinchEnd:
    case WebInputEvent::GesturePinchUpdate:
        // FIXME: Once PlatformGestureEvent is updated to support pinch, this
        // should call handleGestureEvent, just like it currently does for
        // gesture scroll.
        return false;

    default:
        return false;
    }
}

// ----------------------------------------------------------------
// Default handlers for PageWidgetEventHandler

void PageWidgetEventHandler::handleMouseMove(LocalFrame& mainFrame, const WebMouseEvent& event)
{
    mainFrame.eventHandler().handleMouseMoveEvent(PlatformMouseEventBuilder(mainFrame.view(), event));
}

void PageWidgetEventHandler::handleMouseLeave(LocalFrame& mainFrame, const WebMouseEvent& event)
{
    mainFrame.eventHandler().handleMouseLeaveEvent(PlatformMouseEventBuilder(mainFrame.view(), event));
}

void PageWidgetEventHandler::handleMouseDown(LocalFrame& mainFrame, const WebMouseEvent& event)
{
    mainFrame.eventHandler().handleMousePressEvent(PlatformMouseEventBuilder(mainFrame.view(), event));
}

void PageWidgetEventHandler::handleMouseUp(LocalFrame& mainFrame, const WebMouseEvent& event)
{
    mainFrame.eventHandler().handleMouseReleaseEvent(PlatformMouseEventBuilder(mainFrame.view(), event));
}

bool PageWidgetEventHandler::handleMouseWheel(LocalFrame& mainFrame, const WebMouseWheelEvent& event)
{
    return mainFrame.eventHandler().handleWheelEvent(PlatformWheelEventBuilder(mainFrame.view(), event));
}

bool PageWidgetEventHandler::handleTouchEvent(LocalFrame& mainFrame, const WebTouchEvent& event)
{
    return mainFrame.eventHandler().handleTouchEvent(PlatformTouchEventBuilder(mainFrame.view(), event));
}

} // namespace blink
