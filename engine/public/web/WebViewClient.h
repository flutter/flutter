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

#ifndef WebViewClient_h
#define WebViewClient_h

#include "../platform/WebGraphicsContext3D.h"
#include "../platform/WebString.h"
#include "WebContentDetectionResult.h"
#include "WebFrame.h"
#include "WebNavigatorContentUtilsClient.h"
#include "WebPageVisibilityState.h"
#include "WebTextAffinity.h"
#include "WebTextDirection.h"
#include "WebWidgetClient.h"

namespace blink {

class ServiceProvider;
class WebCompositorOutputSurface;
class WebElement;
class WebGestureEvent;
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

// Since a WebView is a WebWidget, a WebViewClient is a WebWidgetClient.
// Virtual inheritance allows an implementation of WebWidgetClient to be
// easily reused as part of an implementation of WebViewClient.
class WebViewClient : virtual public WebWidgetClient {
public:
    virtual ServiceProvider& services() = 0;

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

    // Called when hovering over an anchor with the given URL.
    virtual void setMouseOverURL(const WebURL&) { }

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

    // Indicates two things:
    //   1) This view may have a new layout now.
    //   2) Calling layout() is a no-op.
    // After calling WebWidget::layout(), expect to get this notification
    // unless the view did not need a layout.
    virtual void didUpdateLayout() { }

    // Return true to swallow the input event if the embedder will start a disambiguation popup
    virtual bool didTapMultipleTargets(const WebGestureEvent&, const WebVector<WebRect>& targetRects) { return false; }

    // Returns comma separated list of accept languages.
    virtual WebString acceptLanguages() { return WebString(); }

    // Developer tools -----------------------------------------------------

    // Called to notify the client that the inspector's settings were
    // changed and should be saved.  See WebView::inspectorSettings.
    virtual void didUpdateInspectorSettings() { }

    virtual void didUpdateInspectorSetting(const WebString& key, const WebString& value) { }


    // Zoom ----------------------------------------------------------------

    // Informs the browser that the zoom levels for this frame have changed from
    // the default values.
    virtual void zoomLimitsChanged(double minimumLevel, double maximumLevel) { }

    // Informs the browser that the zoom level has changed as a result of an
    // action that wasn't initiated by the client.
    virtual void zoomLevelChanged() { }


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

    // Content detection ----------------------------------------------------

    // Retrieves detectable content (e.g., email addresses, phone numbers)
    // around a hit test result. The embedder should use platform-specific
    // content detectors to analyze the region around the hit test result.
    virtual WebContentDetectionResult detectContentAround(const WebHitTestResult&) { return WebContentDetectionResult(); }

    // Schedules a new content intent with the provided url.
    virtual void scheduleContentIntent(const WebURL&) { }

    // Cancels any previously scheduled content intents that have not yet launched.
    virtual void cancelScheduledContentIntents() { }

protected:
    ~WebViewClient() { }
};

} // namespace blink

#endif
