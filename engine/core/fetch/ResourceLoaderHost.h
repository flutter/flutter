/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef ResourceLoaderHost_h
#define ResourceLoaderHost_h

#include "platform/network/ResourceError.h"
#include "platform/network/ResourceLoadPriority.h"

namespace blink {

class Resource;
class ResourceFetcher;
class LocalFrame;
class ResourceLoader;
class ResourceRequest;
class ResourceResponse;

struct FetchInitiatorInfo;

class ResourceLoaderHost : public DummyBase<void> {
public:
    virtual void incrementRequestCount(const Resource*) = 0;
    virtual void decrementRequestCount(const Resource*) = 0;
    virtual void didLoadResource(Resource*) = 0;

    virtual void didFinishLoading(const Resource*, double finishTime, int64_t encodedDataLength) = 0;
    virtual void didChangeLoadingPriority(const Resource*, ResourceLoadPriority, int intraPriorityValue) = 0;
    virtual void didFailLoading(const Resource*, const ResourceError&) = 0;

    virtual void willSendRequest(unsigned long identifier, ResourceRequest&, const ResourceResponse& redirectResponse, const FetchInitiatorInfo&) = 0;
    virtual void didReceiveResponse(const Resource*, const ResourceResponse&) = 0;
    virtual void didReceiveData(const Resource*, const char* data, int dataLength, int encodedDataLength) = 0;
    virtual void didDownloadData(const Resource*, int dataLength, int encodedDataLength) = 0;

    virtual void subresourceLoaderFinishedLoadingOnePart(ResourceLoader*) = 0;
    virtual void didInitializeResourceLoader(ResourceLoader*) = 0;
    virtual void willTerminateResourceLoader(ResourceLoader*) = 0;
    virtual void willStartLoadingResource(Resource*, ResourceRequest&) = 0;

    virtual bool isLoadedBy(ResourceLoaderHost*) const = 0;

    virtual void trace(Visitor*) { }

#if !ENABLE(OILPAN)
    virtual void refResourceLoaderHost() = 0;
    virtual void derefResourceLoaderHost() = 0;

    void ref() { refResourceLoaderHost(); }
    void deref() { derefResourceLoaderHost(); }
#endif
};

}

#endif // ResourceLoaderHost_h
