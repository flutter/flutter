/*
 * Copyright (C) 2011, 2012 Google Inc. All rights reserved.
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

#ifndef WebFrameClient_h
#define WebFrameClient_h

#include "../platform/WebColor.h"
#include "WebFrame.h"
#include "WebNavigationPolicy.h"
#include "WebNavigationType.h"
#include "WebTextDirection.h"
#include "public/platform/WebCommon.h"
#include "public/platform/WebURLError.h"
#include "public/platform/WebURLRequest.h"
#include <v8.h>

namespace blink {

class WebCachedURLRequest;
class WebInputEvent;
class WebNode;
class WebString;
class WebURL;
class WebURLLoader;
class WebURLResponse;
struct WebConsoleMessage;
struct WebRect;
struct WebSize;
struct WebURLError;

class WebFrameClient {
public:
    // General notifications -----------------------------------------------

    // A child frame was created in this frame. This is called when the frame
    // is created and initialized. Takes the name of the new frame, the parent
    // frame and returns a new WebFrame. The WebFrame is considered in-use
    // until frameDetached() is called on it.
    // Note: If you override this, you should almost certainly be overriding
    // frameDetached().
    virtual WebFrame* createChildFrame(WebLocalFrame* parent, const WebString& frameName) { return 0; }

    virtual void createChildView(const WebURL& url) { }

    // This frame has been detached from the view, but has not been closed yet.
    virtual void frameDetached(WebFrame*) { }

    // This frame has become focused..
    virtual void frameFocused() { }

    // This frame is about to be closed. This is called after frameDetached,
    // when the document is being unloaded, due to new one committing.
    virtual void willClose(WebFrame*) { }

    // FIXME(sky): remove.
    // Called when a watched CSS selector matches or stops matching.
    virtual void didMatchCSS(WebLocalFrame*, const WebVector<WebString>& newlyMatchingSelectors, const WebVector<WebString>& stoppedMatchingSelectors) { }


    // Console messages ----------------------------------------------------

    // Whether or not we should report a detailed message for the given source.
    virtual bool shouldReportDetailedMessageForSource(const WebString& source) { return false; }

    // A new message was added to the console.
    virtual void didAddMessageToConsole(const WebConsoleMessage&, const WebString& sourceName, unsigned sourceLine, const WebString& stackTrace) { }


    // Load commands -------------------------------------------------------

    // The client should handle the navigation externally.
    virtual void loadURLExternally(
        WebLocalFrame*, const WebURLRequest&, WebNavigationPolicy, const WebString& downloadName) { }


    // Navigational queries ------------------------------------------------

    // The client may choose to alter the navigation policy.  Otherwise,
    // defaultPolicy should just be returned.

    struct NavigationPolicyInfo {
        WebLocalFrame* frame;
        const WebURLRequest& urlRequest;
        WebNavigationType navigationType;
        WebNavigationPolicy defaultPolicy;
        bool isTransitionNavigation;

        NavigationPolicyInfo(const WebURLRequest& urlRequest)
            : frame(0)
            , urlRequest(urlRequest)
            , navigationType(WebNavigationTypeOther)
            , defaultPolicy(WebNavigationPolicyIgnore)
            , isTransitionNavigation(false) { }
    };

    virtual WebNavigationPolicy decidePolicyForNavigation(const NavigationPolicyInfo& info)
    {
        return info.defaultPolicy;
    }


    // Navigational notifications ------------------------------------------

    // These notifications bracket any loading that occurs in the WebFrame.
    virtual void didStartLoading(bool toDifferentDocument) { }
    virtual void didStopLoading() { }

    // Notification that some progress was made loading the current frame.
    // loadProgress is a value between 0 (nothing loaded) and 1.0 (frame fully
    // loaded).
    virtual void didChangeLoadProgress(double loadProgress) { }

    // The document element has been created.
    virtual void didCreateDocumentElement(WebLocalFrame*) { }

    // The page title is available.
    virtual void didReceiveTitle(WebLocalFrame* frame, const WebString& title, WebTextDirection direction) { }

    // The 'load' event was dispatched.
    virtual void didHandleOnloadEvents(WebLocalFrame*) { }

    // The frame's document or one of its subresources failed to load.
    virtual void didFailLoad(WebLocalFrame*, const WebURLError&) { }

    // The frame's manifest has changed.
    virtual void didChangeManifest(WebLocalFrame*) { }


    // Transition navigations -----------------------------------------------

    // Provides serialized markup of transition elements for use in the following navigation.
    virtual void addNavigationTransitionData(const WebString& allowedDestinationOrigin, const WebString& selector, const WebString& markup) { }

    // Editing -------------------------------------------------------------

    // These methods allow the client to intercept and overrule editing
    // operations.
    virtual void didChangeSelection(bool isSelectionEmpty) { }

    // Low-level resource notifications ------------------------------------

    // An element will request a resource.
    virtual void willRequestResource(WebLocalFrame*, const WebCachedURLRequest&) { }

    // A request is about to be sent out, and the client may modify it.  Request
    // is writable, and changes to the URL, for example, will change the request
    // made.  If this request is the result of a redirect, then redirectResponse
    // will be non-null and contain the response that triggered the redirect.
    virtual void willSendRequest(
        WebLocalFrame*, unsigned identifier, WebURLRequest&,
        const WebURLResponse& redirectResponse) { }

    // Response headers have been received for the resource request given
    // by identifier.
    virtual void didReceiveResponse(
        WebLocalFrame*, unsigned identifier, const WebURLResponse&) { }

    virtual void didChangeResourcePriority(
        WebLocalFrame* webFrame, unsigned identifier, const WebURLRequest::Priority& priority, int) { }

    // The resource request given by identifier succeeded.
    virtual void didFinishResourceLoad(
        WebLocalFrame*, unsigned identifier) { }

    // The specified request was satified from WebCore's memory cache.
    virtual void didLoadResourceFromMemoryCache(
        WebLocalFrame*, const WebURLRequest&, const WebURLResponse&) { }

    // Script notifications ------------------------------------------------

    // Notifies that a new script context has been created for this frame.
    // This is similar to didClearWindowObject but only called once per
    // frame context.
    virtual void didCreateScriptContext(WebLocalFrame*, v8::Handle<v8::Context>, int extensionGroup, int worldId) { }

    // WebKit is about to release its reference to a v8 context for a frame.
    virtual void willReleaseScriptContext(WebLocalFrame*, v8::Handle<v8::Context>, int worldId) { }


    // Geometry notifications ----------------------------------------------

    // The main frame scrolled.
    virtual void didChangeScrollOffset(WebLocalFrame*) { }


    // Find-in-page notifications ------------------------------------------

    // Notifies how many matches have been found so far, for a given
    // identifier.  |finalUpdate| specifies whether this is the last update
    // (all frames have completed scoping).
    virtual void reportFindInPageMatchCount(
        int identifier, int count, bool finalUpdate) { }

    // Notifies what tick-mark rect is currently selected.   The given
    // identifier lets the client know which request this message belongs
    // to, so that it can choose to ignore the message if it has moved on
    // to other things.  The selection rect is expected to have coordinates
    // relative to the top left corner of the web page area and represent
    // where on the screen the selection rect is currently located.
    virtual void reportFindInPageSelection(
        int identifier, int activeMatchOrdinal, const WebRect& selection) { }


    // WebGL ------------------------------------------------------

    // Notifies the client that a WebGL context was lost on this page with the
    // given reason (one of the GL_ARB_robustness status codes; see
    // Extensions3D.h in WebCore/platform/graphics).
    virtual void didLoseWebGLContext(WebLocalFrame*, int) { }

    // FIXME: Remove this method once we have input routing in the browser
    // process. See http://crbug.com/339659.
    virtual void forwardInputEvent(const WebInputEvent*) { }

    // Send initial drawing parameters to a child frame that is being rendered out of process.
    virtual void initializeChildFrame(const WebRect& frameRect, float scaleFactor) { }

protected:
    virtual ~WebFrameClient() { }
};

} // namespace blink

#endif
