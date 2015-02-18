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

#ifndef SKY_ENGINE_PUBLIC_WEB_WEBWIDGET_H_
#define SKY_ENGINE_PUBLIC_WEB_WEBWIDGET_H_

#include "../platform/WebCanvas.h"
#include "../platform/WebCommon.h"
#include "../platform/WebRect.h"
#include "../platform/WebSize.h"
#include "sky/engine/public/web/WebBeginFrameArgs.h"
#include "sky/engine/public/web/WebCompositionUnderline.h"
#include "sky/engine/public/web/WebTextDirection.h"
#include "sky/engine/public/web/WebTextInputInfo.h"

namespace blink {

class WebInputEvent;
class WebLayerTreeView;
class WebString;
struct WebPoint;
struct WebRenderingStats;
template <typename T> class WebVector;

class WebWidget {
public:
    // This method closes and deletes the WebWidget.
    virtual void close() = 0;

    // Returns the current size of the WebWidget.
    virtual WebSize size() = 0;

    // Called to resize the WebWidget.
    virtual void resize(const WebSize&) = 0;

    virtual void beginFrame(const WebBeginFrameArgs& frameTime) = 0;

    // Called to layout the WebWidget. This MUST be called before Paint.
    virtual void layout() = 0;

    // Called to paint the rectangular region within the WebWidget
    // onto the specified canvas at (viewPort.x,viewPort.y). You MUST call
    // Layout before calling this method. It is okay to call paint
    // multiple times once layout has been called, assuming no other
    // changes are made to the WebWidget (e.g., once events are
    // processed, it should be assumed that another call to layout is
    // warranted before painting again).
    virtual void paint(WebCanvas*, const WebRect& viewPort) = 0;

    // Called to inform the WebWidget of an input event. Returns true if
    // the event has been processed, false otherwise.
    virtual bool handleInputEvent(const WebInputEvent&) = 0;

    // Called to inform the WebWidget that it has gained or lost keyboard focus.
    virtual void setFocus(bool) = 0;

    // Called to inform the WebWidget of a new composition text.
    // If selectionStart and selectionEnd has the same value, then it indicates
    // the input caret position. If the text is empty, then the existing
    // composition text will be cancelled.
    // Returns true if the composition text was set successfully.
    virtual bool setComposition(
        const WebString& text,
        const WebVector<WebCompositionUnderline>& underlines,
        int selectionStart,
        int selectionEnd) = 0;

    enum ConfirmCompositionBehavior {
        DoNotKeepSelection,
        KeepSelection,
    };

    // Called to inform the WebWidget to confirm an ongoing composition.
    // This method is same as confirmComposition(WebString());
    // Returns true if there is an ongoing composition.
    virtual bool confirmComposition() = 0; // Deprecated
    virtual bool confirmComposition(ConfirmCompositionBehavior selectionBehavior) = 0;

    // Called to inform the WebWidget to confirm an ongoing composition with a
    // new composition text. If the text is empty then the current composition
    // text is confirmed. If there is no ongoing composition, then deletes the
    // current selection and inserts the text. This method has no effect if
    // there is no ongoing composition and the text is empty.
    // Returns true if there is an ongoing composition or the text is inserted.
    virtual bool confirmComposition(const WebString& text) = 0;

    // Returns information about the current text input of this WebWidget.
    virtual WebTextInputInfo textInputInfo() = 0;

protected:
    ~WebWidget() { }
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_WEB_WEBWIDGET_H_
