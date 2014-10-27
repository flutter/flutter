/*
 * Copyright (C) 2005, 2006, 2011 Apple Inc. All rights reserved.
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

#ifndef ResourceLoader_h
#define ResourceLoader_h

#include "core/fetch/ResourceLoaderOptions.h"
#include "platform/network/ResourceRequest.h"
#include "public/platform/WebURLLoader.h"
#include "public/platform/WebURLLoaderClient.h"
#include "wtf/Forward.h"
#include "wtf/RefCounted.h"

namespace blink {

class Resource;
class KURL;
class ResourceError;
class ResourceResponse;
class ResourceLoaderHost;

class ResourceLoader final : public RefCounted<ResourceLoader>, protected WebURLLoaderClient {
public:
    static PassRefPtr<ResourceLoader> create(ResourceLoaderHost*, Resource*, const ResourceRequest&, const ResourceLoaderOptions&);
    virtual ~ResourceLoader();
    void trace(Visitor*);

    void start();

    void cancel();
    void cancel(const ResourceError&);
    void cancelIfNotFinishing();

    Resource* cachedResource() { return m_resource; }

    void releaseResources();

    void didChangePriority(ResourceLoadPriority, int intraPriorityValue);

    // WebURLLoaderClient
    virtual void willSendRequest(blink::WebURLLoader*, blink::WebURLRequest&, const blink::WebURLResponse& redirectResponse) override;
    virtual void didSendData(blink::WebURLLoader*, unsigned long long bytesSent, unsigned long long totalBytesToBeSent) override;
    virtual void didReceiveResponse(blink::WebURLLoader*, const blink::WebURLResponse&) override;
    virtual void didReceiveData(blink::WebURLLoader*, const char*, int, int encodedDataLength) override;
    virtual void didFinishLoading(blink::WebURLLoader*, double finishTime, int64 encodedDataLength) override;
    virtual void didFail(blink::WebURLLoader*, const blink::WebURLError&) override;
    virtual void didDownloadData(blink::WebURLLoader*, int, int) override;

    const KURL& url() const { return m_request.url(); }
    bool isLoadedBy(ResourceLoaderHost*) const;

    bool reachedTerminalState() const { return m_state == Terminated; }
    const ResourceRequest& request() const { return m_request; }

    class RequestCountTracker {
    public:
        RequestCountTracker(ResourceLoaderHost*, Resource*);
        RequestCountTracker(const RequestCountTracker&);
        ~RequestCountTracker();
    private:
        ResourceLoaderHost* m_host;
        Resource* m_resource;
    };

private:
    ResourceLoader(ResourceLoaderHost*, Resource*, const ResourceLoaderOptions&);

    void init(const ResourceRequest&);

    void didFinishLoadingOnePart(double finishTime, int64_t encodedDataLength);

    ResourceRequest& applyOptions(ResourceRequest&) const;

    OwnPtr<blink::WebURLLoader> m_loader;
    RefPtr<ResourceLoaderHost> m_host;

    ResourceRequest m_request;

    bool m_notifiedLoadComplete;

    ResourceLoaderOptions m_options;

    enum ResourceLoaderState {
        Initialized,
        Finishing,
        Terminated
    };

    enum ConnectionState {
        ConnectionStateNew,
        ConnectionStateStarted,
        ConnectionStateReceivedResponse,
        ConnectionStateReceivingData,
        ConnectionStateFinishedLoading,
        ConnectionStateCanceled,
        ConnectionStateFailed,
    };

    RawPtr<Resource> m_resource;
    ResourceLoaderState m_state;

    // Used for sanity checking to make sure we don't experience illegal state
    // transitions.
    ConnectionState m_connectionState;

    OwnPtr<RequestCountTracker> m_requestCountTracker;
};

}

#endif
