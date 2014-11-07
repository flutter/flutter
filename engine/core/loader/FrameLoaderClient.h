/*
 * Copyright (C) 2006, 2007, 2008, 2009, 2010, 2011, 2012 Apple Inc. All rights reserved.
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef FrameLoaderClient_h
#define FrameLoaderClient_h

#include "core/frame/FrameClient.h"
#include "core/loader/FrameLoaderTypes.h"
#include "core/loader/NavigationPolicy.h"
#include "platform/network/ResourceLoadPriority.h"
#include "platform/weborigin/Referrer.h"
#include "wtf/Forward.h"
#include "wtf/Vector.h"
#include <v8.h>

namespace blink {

    class Color;
    class Document;
    class DOMWindowExtension;
    class DOMWrapperWorld;
    class Element;
    class FetchRequest;
    class FrameLoader;
    class FrameNetworkingContext;
    class IntSize;
    class KURL;
    class LocalFrame;
    class Page;
    class ResourceError;
    class ResourceHandle;
    class ResourceRequest;
    class ResourceResponse;
    class SharedBuffer;
    class Widget;

    class FrameLoaderClient : public FrameClient {
    public:
        virtual ~FrameLoaderClient() { }

        virtual void detachedFromParent() = 0;

        virtual void dispatchWillSendRequest(Document*, unsigned long identifier, ResourceRequest&, const ResourceResponse& redirectResponse) = 0;
        virtual void dispatchDidReceiveResponse(Document*, unsigned long identifier, const ResourceResponse&) = 0;
        virtual void dispatchDidFinishLoading(Document*, unsigned long identifier) = 0;
        virtual void dispatchDidLoadResourceFromMemoryCache(const ResourceRequest&, const ResourceResponse&) = 0;

        virtual void dispatchDidHandleOnloadEvents() = 0;
        virtual void dispatchWillClose() = 0;
        virtual void dispatchDidReceiveTitle(const String&) = 0;
        virtual void dispatchDidFailLoad(const ResourceError&) = 0;

        virtual NavigationPolicy decidePolicyForNavigation(const ResourceRequest&, Document*, NavigationPolicy, bool isTransitionNavigation) = 0;

        virtual void dispatchAddNavigationTransitionData(const String& origin, const String& selector, const String& markup) { }
        virtual void dispatchWillRequestResource(FetchRequest*) { }

        virtual void didStartLoading(LoadStartType) = 0;
        virtual void progressEstimateChanged(double progressEstimate) = 0;
        virtual void didStopLoading() = 0;

        virtual void loadURLExternally(const ResourceRequest&, NavigationPolicy, const String& suggestedName = String()) = 0;

        // TODO(mpcomplete): return surface ID?
        virtual void createView(const KURL&) = 0;

        // Transmits the change in the set of watched CSS selectors property
        // that match any element on the frame.
        virtual void selectorMatchChanged(const Vector<String>& addedSelectors, const Vector<String>& removedSelectors) = 0;

        virtual void transitionToCommittedForNewPage() = 0;


        virtual void documentElementAvailable() = 0;

        virtual void didCreateScriptContext(v8::Handle<v8::Context>, int extensionGroup, int worldId) = 0;
        virtual void willReleaseScriptContext(v8::Handle<v8::Context>, int worldId) = 0;

        virtual void didChangeScrollOffset() { }
        virtual void didRemoveAllPendingStylesheet() { }

        // Informs the embedder that a WebGL canvas inside this frame received a lost context
        // notification with the given GL_ARB_robustness guilt/innocence code (see Extensions3D.h).
        virtual void didLoseWebGLContext(int) { }

        virtual void dispatchDidChangeResourcePriority(unsigned long identifier, ResourceLoadPriority, int intraPriorityValue) { }

        virtual void dispatchDidChangeManifest() { }

        virtual bool isFrameLoaderClientImpl() const { return false; }
    };

} // namespace blink

#endif // FrameLoaderClient_h
