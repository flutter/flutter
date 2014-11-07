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

#ifndef FrameLoaderClientImpl_h
#define FrameLoaderClientImpl_h

#include "core/loader/FrameLoaderClient.h"
#include "platform/weborigin/KURL.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/RefPtr.h"

namespace blink {

class WebLocalFrameImpl;

class FrameLoaderClientImpl FINAL : public FrameLoaderClient {
public:
    explicit FrameLoaderClientImpl(WebLocalFrameImpl* webFrame);
    virtual ~FrameLoaderClientImpl();

    WebLocalFrameImpl* webFrame() const { return m_webFrame; }

    // FrameLoaderClient ----------------------------------------------

    virtual void documentElementAvailable() override;

    virtual void didCreateScriptContext(v8::Handle<v8::Context>, int extensionGroup, int worldId) override;
    virtual void willReleaseScriptContext(v8::Handle<v8::Context>, int worldId) override;

    virtual void detachedFromParent() override;
    virtual void dispatchWillSendRequest(Document*, unsigned long identifier, ResourceRequest&, const ResourceResponse& redirectResponse) override;
    virtual void dispatchDidReceiveResponse(Document*, unsigned long identifier, const ResourceResponse&) override;
    virtual void dispatchDidChangeResourcePriority(unsigned long identifier, ResourceLoadPriority, int intraPriorityValue) override;
    virtual void dispatchDidFinishLoading(Document*, unsigned long identifier) override;
    virtual void dispatchDidLoadResourceFromMemoryCache(const ResourceRequest&, const ResourceResponse&) override;
    virtual void dispatchDidHandleOnloadEvents() override;
    virtual void dispatchWillClose() override;
    virtual void dispatchDidReceiveTitle(const String&) override;
    virtual void dispatchDidFailLoad(const ResourceError&) override;

    virtual NavigationPolicy decidePolicyForNavigation(const ResourceRequest&, Document*, NavigationPolicy, bool isTransitionNavigation) override;
    virtual void dispatchAddNavigationTransitionData(const String& allowedDestinationOrigin, const String& selector, const String& markup) override;
    virtual void dispatchWillRequestResource(FetchRequest*) override;
    virtual void didStartLoading(LoadStartType) override;
    virtual void didStopLoading() override;
    virtual void progressEstimateChanged(double progressEstimate) override;
    virtual void loadURLExternally(const ResourceRequest&, NavigationPolicy, const String& suggestedName = String()) override;
    virtual void createView(const KURL&) override;
    virtual void selectorMatchChanged(const Vector<String>& addedSelectors, const Vector<String>& removedSelectors) override;
    virtual void transitionToCommittedForNewPage() override;
    virtual void didChangeScrollOffset() override;
    virtual void didRemoveAllPendingStylesheet() override;

    virtual void didLoseWebGLContext(int arbRobustnessContextLostReason) override;

    virtual void dispatchDidChangeManifest() override;

private:
    virtual bool isFrameLoaderClientImpl() const override { return true; }

    // The WebFrame that owns this object and manages its lifetime. Therefore,
    // the web frame object is guaranteed to exist.
    WebLocalFrameImpl* m_webFrame;
};

DEFINE_TYPE_CASTS(FrameLoaderClientImpl, FrameLoaderClient, client, client->isFrameLoaderClientImpl(), client.isFrameLoaderClientImpl());

} // namespace blink

#endif
