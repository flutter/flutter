/*
 * Copyright (C) 2009, 2012 Google Inc. All rights reserved.
 * Copyright (C) 2011 Apple Inc. All rights reserved.
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

#include "config.h"
#include "web/FrameLoaderClientImpl.h"

#include "bindings/core/v8/ScriptController.h"
#include "core/dom/Document.h"
#include "core/events/MessageEvent.h"
#include "core/events/MouseEvent.h"
#include "core/frame/FrameView.h"
#include "core/frame/Settings.h"
#include "core/page/Chrome.h"
#include "core/page/EventHandler.h"
#include "core/page/Page.h"
#include "core/rendering/HitTestResult.h"
#include "platform/MIMETypeRegistry.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "platform/UserGestureIndicator.h"
#include "platform/exported/WrappedResourceRequest.h"
#include "platform/exported/WrappedResourceResponse.h"
#include "platform/network/HTTPParsers.h"
#include "public/platform/Platform.h"
#include "public/platform/WebMimeRegistry.h"
#include "public/platform/WebURL.h"
#include "public/platform/WebURLError.h"
#include "public/platform/WebVector.h"
#include "public/web/WebCachedURLRequest.h"
#include "public/web/WebDOMEvent.h"
#include "public/web/WebDocument.h"
#include "public/web/WebFrameClient.h"
#include "public/web/WebNode.h"
#include "public/web/WebViewClient.h"
#include "web/WebLocalFrameImpl.h"
#include "web/WebViewImpl.h"
#include "wtf/StringExtras.h"
#include "wtf/text/CString.h"
#include "wtf/text/WTFString.h"
#include <v8.h>

namespace blink {

FrameLoaderClientImpl::FrameLoaderClientImpl(WebLocalFrameImpl* frame)
    : m_webFrame(frame)
{
}

FrameLoaderClientImpl::~FrameLoaderClientImpl()
{
}

void FrameLoaderClientImpl::documentElementAvailable()
{
    if (m_webFrame->client())
        m_webFrame->client()->didCreateDocumentElement(m_webFrame);
}

void FrameLoaderClientImpl::didCreateScriptContext(v8::Handle<v8::Context> context, int extensionGroup, int worldId)
{
    if (m_webFrame->client())
        m_webFrame->client()->didCreateScriptContext(m_webFrame, context, extensionGroup, worldId);
}

void FrameLoaderClientImpl::willReleaseScriptContext(v8::Handle<v8::Context> context, int worldId)
{
    if (m_webFrame->client())
        m_webFrame->client()->willReleaseScriptContext(m_webFrame, context, worldId);
}

void FrameLoaderClientImpl::didChangeScrollOffset()
{
    if (m_webFrame->client())
        m_webFrame->client()->didChangeScrollOffset(m_webFrame);
}

void FrameLoaderClientImpl::didRemoveAllPendingStylesheet()
{
    WebViewImpl* webview = m_webFrame->viewImpl();
    if (webview)
        webview->didRemoveAllPendingStylesheet(m_webFrame);
}

void FrameLoaderClientImpl::detachedFromParent()
{
    // Alert the client that the frame is being detached. This is the last
    // chance we have to communicate with the client.
    RefPtr<WebLocalFrameImpl> protector(m_webFrame);

    WebFrameClient* client = m_webFrame->client();
    if (!client)
        return;

    // Signal that no further communication with WebFrameClient should take
    // place at this point since we are no longer associated with the Page.
    m_webFrame->setClient(0);

    client->frameDetached(m_webFrame);
    // Clear our reference to LocalFrame at the very end, in case the client
    // refers to it.
    m_webFrame->setCoreFrame(nullptr);
}

void FrameLoaderClientImpl::dispatchWillSendRequest(
    Document*, unsigned long identifier, ResourceRequest& request,
    const ResourceResponse& redirectResponse)
{
    // Give the WebFrameClient a crack at the request.
    if (m_webFrame->client()) {
        WrappedResourceRequest webreq(request);
        WrappedResourceResponse webresp(redirectResponse);
        m_webFrame->client()->willSendRequest(
            m_webFrame, identifier, webreq, webresp);
    }
}

void FrameLoaderClientImpl::dispatchDidReceiveResponse(Document*,
                                                       unsigned long identifier,
                                                       const ResourceResponse& response)
{
    if (m_webFrame->client()) {
        WrappedResourceResponse webresp(response);
        m_webFrame->client()->didReceiveResponse(m_webFrame, identifier, webresp);
    }
}

void FrameLoaderClientImpl::dispatchDidChangeResourcePriority(unsigned long identifier, ResourceLoadPriority priority, int intraPriorityValue)
{
    if (m_webFrame->client())
        m_webFrame->client()->didChangeResourcePriority(m_webFrame, identifier, static_cast<WebURLRequest::Priority>(priority), intraPriorityValue);
}

// Called when a particular resource load completes
void FrameLoaderClientImpl::dispatchDidFinishLoading(Document*,
                                                    unsigned long identifier)
{
    if (m_webFrame->client())
        m_webFrame->client()->didFinishResourceLoad(m_webFrame, identifier);
}

void FrameLoaderClientImpl::dispatchDidLoadResourceFromMemoryCache(const ResourceRequest& request, const ResourceResponse& response)
{
    if (m_webFrame->client())
        m_webFrame->client()->didLoadResourceFromMemoryCache(m_webFrame, WrappedResourceRequest(request), WrappedResourceResponse(response));
}

void FrameLoaderClientImpl::dispatchDidHandleOnloadEvents()
{
    if (m_webFrame->client())
        m_webFrame->client()->didHandleOnloadEvents(m_webFrame);
}

void FrameLoaderClientImpl::dispatchWillClose()
{
    if (m_webFrame->client())
        m_webFrame->client()->willClose(m_webFrame);
}

void FrameLoaderClientImpl::dispatchDidReceiveTitle(const String& title)
{
    if (m_webFrame->client())
        m_webFrame->client()->didReceiveTitle(m_webFrame, title, WebTextDirectionLeftToRight);
}

void FrameLoaderClientImpl::dispatchDidFailLoad(const ResourceError& error)
{
    m_webFrame->didFail(error);
}

NavigationPolicy FrameLoaderClientImpl::decidePolicyForNavigation(const ResourceRequest& request, Document*, NavigationPolicy policy, bool isTransitionNavigation)
{
    if (!m_webFrame->client())
        return NavigationPolicyIgnore;

    WrappedResourceRequest wrappedResourceRequest(request);
    WebFrameClient::NavigationPolicyInfo navigationInfo(wrappedResourceRequest);
    navigationInfo.frame = m_webFrame;
    navigationInfo.defaultPolicy = static_cast<WebNavigationPolicy>(policy);
    navigationInfo.isTransitionNavigation = isTransitionNavigation;

    WebNavigationPolicy webPolicy = m_webFrame->client()->decidePolicyForNavigation(navigationInfo);
    return static_cast<NavigationPolicy>(webPolicy);
}

void FrameLoaderClientImpl::dispatchAddNavigationTransitionData(const String& allowedDestinationOrigin, const String& selector, const String& markup)
{
    if (m_webFrame->client())
        m_webFrame->client()->addNavigationTransitionData(allowedDestinationOrigin, selector, markup);
}

void FrameLoaderClientImpl::dispatchWillRequestResource(FetchRequest* request)
{
    if (m_webFrame->client()) {
        WebCachedURLRequest urlRequest(request);
        m_webFrame->client()->willRequestResource(m_webFrame, urlRequest);
    }
}

void FrameLoaderClientImpl::didStartLoading(LoadStartType loadStartType)
{
    if (m_webFrame->client())
        m_webFrame->client()->didStartLoading(loadStartType == NavigationToDifferentDocument);
}

void FrameLoaderClientImpl::progressEstimateChanged(double progressEstimate)
{
    if (m_webFrame->client())
        m_webFrame->client()->didChangeLoadProgress(progressEstimate);
}

void FrameLoaderClientImpl::didStopLoading()
{
    if (m_webFrame->client())
        m_webFrame->client()->didStopLoading();
}

void FrameLoaderClientImpl::loadURLExternally(const ResourceRequest& request, NavigationPolicy policy, const String& suggestedName)
{
    if (m_webFrame->client()) {
        ASSERT(m_webFrame->frame()->document());
        WrappedResourceRequest webreq(request);
        m_webFrame->client()->loadURLExternally(
            m_webFrame, webreq, static_cast<WebNavigationPolicy>(policy), suggestedName);
    }
}

void FrameLoaderClientImpl::selectorMatchChanged(const Vector<String>& addedSelectors, const Vector<String>& removedSelectors)
{
    if (WebFrameClient* client = m_webFrame->client())
        client->didMatchCSS(m_webFrame, WebVector<WebString>(addedSelectors), WebVector<WebString>(removedSelectors));
}

// Called when the FrameLoader goes into a state in which a new page load
// will occur.
void FrameLoaderClientImpl::transitionToCommittedForNewPage()
{
    m_webFrame->createFrameView();
}

void FrameLoaderClientImpl::didLoseWebGLContext(int arbRobustnessContextLostReason)
{
    if (m_webFrame->client())
        m_webFrame->client()->didLoseWebGLContext(m_webFrame, arbRobustnessContextLostReason);
}

void FrameLoaderClientImpl::dispatchDidChangeManifest()
{
    if (m_webFrame->client())
        m_webFrame->client()->didChangeManifest(m_webFrame);
}

} // namespace blink
