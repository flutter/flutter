/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#ifndef WebWidgetClient_h
#define WebWidgetClient_h

#include "sky/engine/public/platform/WebCommon.h"
#include "sky/engine/public/platform/WebLayerTreeView.h"
#include "sky/engine/public/platform/WebRect.h"
#include "sky/engine/public/platform/WebScreenInfo.h"
#include "sky/engine/public/web/WebNavigationPolicy.h"
#include "sky/engine/public/web/WebTouchAction.h"

namespace blink {

class WebGestureEvent;
class WebString;
class WebWidget;
struct WebCursorInfo;
struct WebSize;

class WebWidgetClient {
public:
    // Called when a region of the WebWidget needs to be re-painted.
    virtual void didInvalidateRect(const WebRect&) { }

    // Called when the Widget has changed size as a result of an auto-resize.
    virtual void didAutoResize(const WebSize& newSize) { }

    // Initialize compositing for this widget.
    // Return a compositing view used for this widget owned by the
    // WebWidgetClient.
    virtual WebLayerTreeView* initializeLayerTreeView() { BLINK_ASSERT_NOT_REACHED(); return 0; }

    // Sometimes the WebWidget enters a state where it will generate a sequence
    // of invalidations that should not, by themselves, trigger the compositor
    // to schedule a new frame. This call indicates to the embedder that it
    // should suppress compositor scheduling temporarily.
    virtual void suppressCompositorScheduling(bool enable) { }

    // Indicates to the embedder that the compositor is about to begin a
    // frame. This is primarily to signal to flow control mechanisms that a
    // frame is beginning, not to perform actual painting work.
    virtual void willBeginCompositorFrame() { }

    // Indicates to the embedder that the WebWidget is ready for additional
    // input.
    virtual void didBecomeReadyForAdditionalInput() { }

    // Called for compositing mode when a frame commit operation has finished.
    virtual void didCommitCompositorFrame() { }

    // Called for compositing mode when the draw commands for a WebKit-side
    // frame have been issued.
    virtual void didCommitAndDrawCompositorFrame() { }

    // Called for compositing mode when swapbuffers has been posted in the GPU
    // process.
    virtual void didCompleteSwapBuffers() { }

    // Called when a call to WebWidget::animate is required
    virtual void scheduleAnimation() { }

    // Called when the widget acquires or loses focus, respectively.
    virtual void didFocus() { }
    virtual void didBlur() { }

    // Called when the cursor for the widget changes.
    virtual void didChangeCursor(const WebCursorInfo&) { }

    // Called when the widget should be closed.  WebWidget::close() should
    // be called asynchronously as a result of this notification.
    virtual void closeWidgetSoon() { }

    // Called to show the widget according to the given policy.
    virtual void show(WebNavigationPolicy) { }

    // Called to enter/exit fullscreen mode. If enterFullScreen returns true,
    // then WebWidget::{will,Did}EnterFullScreen should bound resizing the
    // WebWidget into fullscreen mode. Similarly, when exitFullScreen is
    // called, WebWidget::{will,Did}ExitFullScreen should bound resizing the
    // WebWidget out of fullscreen mode.
    virtual bool enterFullScreen() { return false; }
    virtual void exitFullScreen() { }

    // Called to get/set the position of the widget in screen coordinates.
    virtual WebRect windowRect() { return WebRect(); }
    virtual void setWindowRect(const WebRect&) { }

    // Called when a tooltip should be shown at the current cursor position.
    virtual void setToolTipText(const WebString&, WebTextDirection hint) { }

    // Called to get the position of the resizer rect in window coordinates.
    virtual WebRect windowResizerRect() { return WebRect(); }

    // Called to get the position of the root window containing the widget
    // in screen coordinates.
    virtual WebRect rootWindowRect() { return WebRect(); }

    // Called to query information about the screen where this widget is
    // displayed.
    virtual WebScreenInfo screenInfo() { return WebScreenInfo(); }

    // Called to get the scale factor of the display.
    virtual float deviceScaleFactor() { return 1; }

    // When this method gets called, WebWidgetClient implementation should
    // reset the input method by cancelling any ongoing composition.
    virtual void resetInputMethod() { }

    // Requests to lock the mouse cursor. If true is returned, the success
    // result will be asynchronously returned via a single call to
    // WebWidget::didAcquirePointerLock() or
    // WebWidget::didNotAcquirePointerLock().
    // If false, the request has been denied synchronously.
    virtual bool requestPointerLock() { return false; }

    // Cause the pointer lock to be released. This may be called at any time,
    // including when a lock is pending but not yet acquired.
    // WebWidget::didLosePointerLock() is called when unlock is complete.
    virtual void requestPointerUnlock() { }

    // Returns true iff the pointer is locked to this widget.
    virtual bool isPointerLocked() { return false; }

    // Called when a gesture event is handled.
    virtual void didHandleGestureEvent(const WebGestureEvent& event, bool eventCancelled) { }

    // Called during WebWidget::HandleInputEvent for a TouchStart event to inform the embedder
    // of the touch actions that are permitted for this touch.
    virtual void setTouchAction(WebTouchAction touchAction) { }

    // Called when value of focused text field gets dirty, e.g. value is
    // modified by script, not by user input.
    virtual void didUpdateTextOfFocusedElementByNonUserInput() { }

    // Request the browser to show the IME for current input type.
    virtual void showImeIfNeeded() { }

protected:
    ~WebWidgetClient() { }
};

} // namespace blink

#endif
