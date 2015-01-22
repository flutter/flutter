/*
 * Copyright (C) 2009, 2010, 2011, 2012 Google Inc. All rights reserved.
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

#ifndef SKY_ENGINE_PUBLIC_WEB_WEBVIEW_H_
#define SKY_ENGINE_PUBLIC_WEB_WEBVIEW_H_

#include "../platform/WebColor.h"
#include "../platform/WebString.h"
#include "../platform/WebVector.h"
#include "sky/engine/public/web/WebPageVisibilityState.h"
#include "sky/engine/public/web/WebWidget.h"

namespace blink {

class WebFrame;
class WebFrameClient;
class WebHitTestResult;
class WebSettings;
class WebSpellCheckClient;
class WebViewClient;
struct WebActiveWheelFlingParameters;
struct WebPoint;

class WebView : public WebWidget {
public:
    // Initialization ------------------------------------------------------

    // Creates a WebView that is NOT yet initialized. You will need to
    // call setMainFrame to finish the initialization. It is valid
    // to pass a null client pointer.
    BLINK_EXPORT static WebView* create(WebViewClient*);

    // After creating a WebView, you should immediately call this method.
    // You can optionally modify the settings before calling this method.
    // This WebFrame will receive events for the main frame and must not
    // be null.
    virtual void setMainFrame(WebFrame*) = 0;

    // Initializes the various client interfaces.
    virtual void setSpellCheckClient(WebSpellCheckClient*) = 0;

    // Options -------------------------------------------------------------

    // The returned pointer is valid for the lifetime of the WebView.
    virtual WebSettings* settings() = 0;

    // Corresponds to the encoding of the main frame.  Setting the page
    // encoding may cause the main frame to reload.
    virtual WebString pageEncoding() const = 0;
    virtual void setPageEncoding(const WebString&) = 0;

    // Makes the WebView transparent.  This is useful if you want to have
    // some custom background rendered behind it.
    virtual bool isTransparent() const = 0;
    virtual void setIsTransparent(bool) = 0;

    // Sets the base color used for this WebView's background. This is in effect
    // the default background color used for pages with no background-color
    // style in effect, or used as the alpha-blended basis for any pages with
    // translucent background-color style. (For pages with opaque
    // background-color style, this property is effectively ignored).
    // Setting this takes effect for the currently loaded page, if any, and
    // persists across subsequent navigations. Defaults to white prior to the
    // first call to this method.
    virtual void setBaseBackgroundColor(WebColor) = 0;

    // Controls whether pressing Tab key advances focus to links.
    virtual bool tabsToLinks() const = 0;
    virtual void setTabsToLinks(bool) = 0;

    // Controls the WebView's active state, which may affect the rendering
    // of elements on the page (i.e., tinting of input elements).
    virtual bool isActive() const = 0;
    virtual void setIsActive(bool) = 0;

    // Frames --------------------------------------------------------------

    virtual WebFrame* mainFrame() = 0;

    virtual void injectModule(const WebString& path) = 0;

    // Focus ---------------------------------------------------------------

    virtual WebFrame* focusedFrame() = 0;
    virtual void setFocusedFrame(WebFrame*) = 0;

    // Focus the first (last if reverse is true) focusable node.
    virtual void setInitialFocus(bool reverse) = 0;

    // Clears the focused element (and selection if a text field is focused)
    // to ensure that a text field on the page is not eating keystrokes we
    // send it.
    virtual void clearFocusedElement() = 0;

    // Advance the focus of the WebView forward to the next element or to the
    // previous element in the tab sequence (if reverse is true).
    virtual void advanceFocus(bool reverse) { }


    // Zoom ----------------------------------------------------------------

    // The ratio of the current device's screen DPI to the target device's screen DPI.
    virtual float deviceScaleFactor() const = 0;

    // Sets the ratio as computed by computePageScaleConstraints.
    virtual void setDeviceScaleFactor(float) = 0;


    // Data exchange -------------------------------------------------------

    // Do a hit test at given point and return the HitTestResult.
    virtual WebHitTestResult hitTestResultAt(const WebPoint&) = 0;

    // Retrieves a list of spelling markers.
    virtual void spellingMarkers(WebVector<uint32_t>* markers) = 0;
    virtual void removeSpellingMarkersUnderWords(const WebVector<WebString>& words) = 0;


    // Developer tools -----------------------------------------------------

    // Set an override of device scale factor passed from WebView to
    // compositor. Pass zero to cancel override. This is used to implement
    // device metrics emulation.
    virtual void setCompositorDeviceScaleFactorOverride(float) = 0;

    virtual void setShowPaintRects(bool) = 0;
    virtual void setContinuousPaintingEnabled(bool) = 0;
    virtual void setShowScrollBottleneckRects(bool) = 0;

    // Visibility -----------------------------------------------------------

    // Sets the visibility of the WebView.
    virtual void setVisibilityState(WebPageVisibilityState visibilityState,
                                    bool isInitialState) { }

    // i18n -----------------------------------------------------------------

    // Inform the WebView that the accept languages have changed.
    // If the WebView wants to get the accept languages value, it will have
    // to call the WebViewClient::acceptLanguages().
    virtual void acceptLanguagesChanged() = 0;

    // Testing functionality for TestRunner ---------------------------------

protected:
    ~WebView() {}
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_WEB_WEBVIEW_H_
