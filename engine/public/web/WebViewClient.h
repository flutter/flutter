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

#ifndef SKY_ENGINE_PUBLIC_WEB_WEBVIEWCLIENT_H_
#define SKY_ENGINE_PUBLIC_WEB_WEBVIEWCLIENT_H_

#include "../platform/WebGraphicsContext3D.h"
#include "../platform/WebString.h"
#include "sky/engine/public/platform/WebCommon.h"
#include "sky/engine/public/platform/WebRect.h"
#include "sky/engine/public/platform/WebScreenInfo.h"
#include "sky/engine/public/web/WebFrame.h"
#include "sky/engine/public/web/WebNavigatorContentUtilsClient.h"
#include "sky/engine/public/web/WebPageVisibilityState.h"
#include "sky/engine/public/web/WebTextAffinity.h"
#include "sky/engine/public/web/WebTextDirection.h"

namespace blink {

class ServiceProvider;
class WebElement;
class WebHitTestResult;
class WebImage;
class WebKeyboardEvent;
class WebNode;
class WebRange;
class WebURL;
class WebURLRequest;
class WebView;
class WebWidget;
struct WebConsoleMessage;
struct WebPoint;
struct WebRect;
struct WebSize;

class WebViewClient {
public:
    virtual ServiceProvider& services() = 0;

    // Initialize compositing for this widget.
    virtual void initializeLayerTreeView() { BLINK_ASSERT_NOT_REACHED(); };

    // Called when the page should pump a frame.
    virtual void scheduleVisualUpdate() { }

    // TODO(esprehn): Sky needs to implement these to control the mojo::View.

    // Called to get/set the position of the widget in screen coordinates.
    virtual WebRect windowRect() { return WebRect(); }
    virtual void setWindowRect(const WebRect&) { }

    // Called to get the position of the root window containing the widget
    // in screen coordinates.
    virtual WebRect rootWindowRect() { return WebRect(); }

    // Called to query information about the screen where this widget is
    // displayed.
    virtual WebScreenInfo screenInfo() { return WebScreenInfo(); }

    // Called to get the scale factor of the display.
    virtual float deviceScaleFactor() { return 1; }

    // Editing -------------------------------------------------------------

    // This method is called in response to WebView's handleInputEvent()
    // when the default action for the current keyboard event is not
    // suppressed by the page, to give the embedder a chance to handle
    // the keyboard event specially.
    //
    // Returns true if the keyboard event was handled by the embedder,
    // indicating that the default action should be suppressed.
    virtual bool handleCurrentKeyboardEvent() { return false; }

    // UI ------------------------------------------------------------------

    // Called when script modifies window.status
    virtual void setStatusText(const WebString&) { }

    // Called when keyboard focus switches to an anchor with the given URL.
    virtual void setKeyboardFocusURL(const WebURL&) { }

    // Called to determine if drag-n-drop operations may initiate a page
    // navigation.
    virtual bool acceptsLoadDrops() { return true; }

    // Take focus away from the WebView by focusing an adjacent UI element
    // in the containing window.
    virtual void focusNext() { }
    virtual void focusPrevious() { }

    // Called when a new node gets focused.
    virtual void focusedNodeChanged(const WebNode&) { }

    // Returns comma separated list of accept languages.
    virtual WebString acceptLanguages() { return WebString(); }

    // Developer tools -----------------------------------------------------

    // Called to notify the client that the inspector's settings were
    // changed and should be saved.  See WebView::inspectorSettings.
    virtual void didUpdateInspectorSettings() { }

    virtual void didUpdateInspectorSetting(const WebString& key, const WebString& value) { }

    // Navigator Content Utils  --------------------------------------------

    // Registers a new URL handler for the given protocol.
    virtual void registerProtocolHandler(const WebString& scheme,
        const WebURL& baseUrl,
        const WebURL& url,
        const WebString& title) { }

    // Unregisters a given URL handler for the given protocol.
    virtual void unregisterProtocolHandler(const WebString& scheme, const WebURL& baseUrl, const WebURL& url) { }

    // Check if a given URL handler is registered for the given protocol.
    virtual WebCustomHandlersState isProtocolHandlerRegistered(const WebString& scheme, const WebURL& baseUrl, const WebURL& url)
    {
        return WebCustomHandlersNew;
    }


    // Visibility -----------------------------------------------------------

    // Returns the current visibility of the WebView.
    virtual WebPageVisibilityState visibilityState() const
    {
        return WebPageVisibilityStateVisible;
    }

protected:
    ~WebViewClient() { }
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_WEB_WEBVIEWCLIENT_H_
