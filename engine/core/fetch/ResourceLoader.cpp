/*
 * Copyright (C) 2006, 2007, 2010, 2011 Apple Inc. All rights reserved.
 *           (C) 2007 Graham Dennis (graham.dennis@gmail.com)
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

#include "config.h"
#include "core/fetch/ResourceLoader.h"

#include "core/fetch/Resource.h"
#include "core/fetch/ResourceLoaderHost.h"
#include "core/fetch/ResourcePtr.h"
#include "platform/Logging.h"
#include "platform/SharedBuffer.h"
#include "platform/exported/WrappedResourceRequest.h"
#include "platform/exported/WrappedResourceResponse.h"
#include "platform/network/ResourceError.h"
#include "public/platform/Platform.h"
#include "public/platform/WebData.h"
#include "public/platform/WebURLError.h"
#include "public/platform/WebURLRequest.h"
#include "public/platform/WebURLResponse.h"
#include "wtf/Assertions.h"
#include "wtf/CurrentTime.h"

namespace blink {

ResourceLoader::RequestCountTracker::RequestCountTracker(ResourceLoaderHost* host, Resource* resource)
    : m_host(host)
    , m_resource(resource)
{
    m_host->incrementRequestCount(m_resource);
}

ResourceLoader::RequestCountTracker::~RequestCountTracker()
{
    m_host->decrementRequestCount(m_resource);
}

ResourceLoader::RequestCountTracker::RequestCountTracker(const RequestCountTracker& other)
{
    m_host = other.m_host;
    m_resource = other.m_resource;
    m_host->incrementRequestCount(m_resource);
}

PassRefPtrWillBeRawPtr<ResourceLoader> ResourceLoader::create(ResourceLoaderHost* host, Resource* resource, const ResourceRequest& request, const ResourceLoaderOptions& options)
{
    RefPtrWillBeRawPtr<ResourceLoader> loader(adoptRefWillBeNoop(new ResourceLoader(host, resource, options)));
    loader->init(request);
    return loader.release();
}

ResourceLoader::ResourceLoader(ResourceLoaderHost* host, Resource* resource, const ResourceLoaderOptions& options)
    : m_host(host)
    , m_notifiedLoadComplete(false)
    , m_options(options)
    , m_resource(resource)
    , m_state(Initialized)
    , m_connectionState(ConnectionStateNew)
    , m_requestCountTracker(adoptPtr(new RequestCountTracker(host, resource)))
{
}

ResourceLoader::~ResourceLoader()
{
    ASSERT(m_state == Terminated);
}

void ResourceLoader::trace(Visitor* visitor)
{
    visitor->trace(m_host);
    visitor->trace(m_resource);
}

void ResourceLoader::releaseResources()
{
    ASSERT(m_state != Terminated);
    ASSERT(m_notifiedLoadComplete);
    m_requestCountTracker.clear();
    m_host->didLoadResource(m_resource);
    if (m_state == Terminated)
        return;
    m_resource->clearLoader();
    m_resource->deleteIfPossible();
    m_resource = nullptr;
    m_host->willTerminateResourceLoader(this);

    ASSERT(m_state != Terminated);

    // It's possible that when we release the loader, it will be
    // deallocated and release the last reference to this object.
    // We need to retain to avoid accessing the object after it
    // has been deallocated and also to avoid reentering this method.
    RefPtrWillBeRawPtr<ResourceLoader> protector(this);

    m_host.clear();
    m_state = Terminated;

    if (m_loader) {
        m_loader->cancel();
        m_loader.clear();
    }
}

void ResourceLoader::init(const ResourceRequest& passedRequest)
{
    ASSERT(m_state != Terminated);
    ResourceRequest request(passedRequest);
    m_host->willSendRequest(m_resource->identifier(), request, ResourceResponse(), m_options.initiatorInfo);
    ASSERT(m_state != Terminated);
    ASSERT(!request.isNull());
    m_request = applyOptions(request);
    m_resource->updateRequest(request);
    ASSERT(m_state != Terminated);
    m_host->didInitializeResourceLoader(this);
}

void ResourceLoader::start()
{
    ASSERT(!m_loader);
    ASSERT(!m_request.isNull());

    m_host->willStartLoadingResource(m_resource, m_request);

    if (m_state == Terminated)
        return;

    RELEASE_ASSERT(m_connectionState == ConnectionStateNew);
    m_connectionState = ConnectionStateStarted;

    m_loader = adoptPtr(blink::Platform::current()->createURLLoader());
    ASSERT(m_loader);
    blink::WrappedResourceRequest wrappedRequest(m_request);
    m_loader->loadAsynchronously(wrappedRequest, this);
}

void ResourceLoader::didDownloadData(blink::WebURLLoader*, int length, int encodedDataLength)
{
    ASSERT(m_state != Terminated);
    RefPtrWillBeRawPtr<ResourceLoader> protect(this);
    RELEASE_ASSERT(m_connectionState == ConnectionStateReceivedResponse);
    m_host->didDownloadData(m_resource, length, encodedDataLength);
    if (m_state == Terminated)
        return;
    m_resource->didDownloadData(length);
}

void ResourceLoader::didFinishLoadingOnePart(double finishTime, int64 encodedDataLength)
{
    // If load has been cancelled after finishing (which could happen with a
    // JavaScript that changes the window location), do nothing.
    if (m_state == Terminated)
        return;

    if (m_notifiedLoadComplete)
        return;
    m_notifiedLoadComplete = true;
    m_host->didFinishLoading(m_resource, finishTime, encodedDataLength);
}

void ResourceLoader::didChangePriority(ResourceLoadPriority loadPriority, int intraPriorityValue)
{
    if (m_loader) {
        m_host->didChangeLoadingPriority(m_resource, loadPriority, intraPriorityValue);
        ASSERT(m_state != Terminated);
        m_loader->didChangePriority(static_cast<blink::WebURLRequest::Priority>(loadPriority), intraPriorityValue);
    }
}

void ResourceLoader::cancelIfNotFinishing()
{
    if (m_state != Initialized)
        return;
    cancel();
}

void ResourceLoader::cancel()
{
    cancel(ResourceError());
}

void ResourceLoader::cancel(const ResourceError& error)
{
    // If the load has already completed - succeeded, failed, or previously cancelled - do nothing.
    if (m_state == Terminated)
        return;
    if (m_state == Finishing) {
        releaseResources();
        return;
    }

    ResourceError nonNullError = error.isNull() ? ResourceError::cancelledError(m_request.url()) : error;

    // This function calls out to clients at several points that might do
    // something that causes the last reference to this object to go away.
    RefPtrWillBeRawPtr<ResourceLoader> protector(this);

    WTF_LOG(ResourceLoading, "Cancelled load of '%s'.\n", m_resource->url().string().latin1().data());
    if (m_state == Initialized)
        m_state = Finishing;
    m_resource->setResourceError(nonNullError);

    if (m_loader) {
        m_connectionState = ConnectionStateCanceled;
        m_loader->cancel();
        m_loader.clear();
    }

    if (!m_notifiedLoadComplete) {
        m_notifiedLoadComplete = true;
        m_host->didFailLoading(m_resource, nonNullError);
    }

    if (m_state == Finishing)
        m_resource->error(Resource::LoadError);
    if (m_state != Terminated)
        releaseResources();
}

void ResourceLoader::willSendRequest(blink::WebURLLoader*, blink::WebURLRequest& passedRequest, const blink::WebURLResponse& passedRedirectResponse)
{
    ASSERT(m_state != Terminated);
    RefPtrWillBeRawPtr<ResourceLoader> protect(this);

    ResourceRequest& request(applyOptions(passedRequest.toMutableResourceRequest()));

    // FIXME: We should have a real context for redirect requests. Currently, we don't: see WebURLLoaderImpl::Context::OnReceivedRedirect in content/.
    request.setRequestContext(blink::WebURLRequest::RequestContextInternal);

    ASSERT(!request.isNull());
    const ResourceResponse& redirectResponse(passedRedirectResponse.toResourceResponse());
    ASSERT(!redirectResponse.isNull());
    ASSERT(m_state != Terminated);

    applyOptions(request); // canAccessRedirect() can modify m_options so we should re-apply it.
    ASSERT(m_state != Terminated);
    m_resource->willSendRequest(request, redirectResponse);
    if (request.isNull() || m_state == Terminated)
        return;

    m_host->willSendRequest(m_resource->identifier(), request, redirectResponse, m_options.initiatorInfo);
    ASSERT(m_state != Terminated);
    ASSERT(!request.isNull());
    m_resource->updateRequest(request);
    m_request = request;
}

void ResourceLoader::didSendData(blink::WebURLLoader*, unsigned long long bytesSent, unsigned long long totalBytesToBeSent)
{
    ASSERT(m_state == Initialized);
    RefPtrWillBeRawPtr<ResourceLoader> protect(this);
    m_resource->didSendData(bytesSent, totalBytesToBeSent);
}

void ResourceLoader::didReceiveResponse(blink::WebURLLoader*, const blink::WebURLResponse& response)
{
    ASSERT(!response.isNull());
    ASSERT(m_state == Initialized);

    bool isMultipartPayload = response.isMultipartPayload();
    bool isValidStateTransition = (m_connectionState == ConnectionStateStarted || m_connectionState == ConnectionStateReceivedResponse);
    // In the case of multipart loads, calls to didReceiveData & didReceiveResponse can be interleaved.
    RELEASE_ASSERT(isMultipartPayload || isValidStateTransition);
    m_connectionState = ConnectionStateReceivedResponse;

    const ResourceResponse& resourceResponse = response.toResourceResponse();

    // Reference the object in this method since the additional processing can do
    // anything including removing the last reference to this object.
    RefPtrWillBeRawPtr<ResourceLoader> protect(this);
    m_resource->responseReceived(resourceResponse);
    if (m_state == Terminated)
        return;

    m_host->didReceiveResponse(m_resource, resourceResponse);
    if (m_state == Terminated)
        return;

    if (response.toResourceResponse().isMultipart()) {
        // We don't count multiParts in a ResourceFetcher's request count
        m_requestCountTracker.clear();
        if (!m_resource->isImage()) {
            cancel();
            return;
        }
    } else if (isMultipartPayload) {
        // Since a subresource loader does not load multipart sections progressively, data was delivered to the loader all at once.
        // After the first multipart section is complete, signal to delegates that this load is "finished"
        m_host->subresourceLoaderFinishedLoadingOnePart(this);
        ASSERT(m_state != Terminated);
        didFinishLoadingOnePart(0, blink::WebURLLoaderClient::kUnknownEncodedDataLength);
    }
    if (m_state == Terminated)
        return;

    if (m_resource->response().httpStatusCode() < 400 || m_resource->shouldIgnoreHTTPStatusCodeErrors())
        return;
    m_state = Finishing;

    if (!m_notifiedLoadComplete) {
        m_notifiedLoadComplete = true;
        m_host->didFailLoading(m_resource, ResourceError::cancelledError(m_request.url()));
    }

    ASSERT(m_state != Terminated);
    m_resource->error(Resource::LoadError);
    cancel();
}

void ResourceLoader::didReceiveData(blink::WebURLLoader*, const char* data, int length, int encodedDataLength)
{
    ASSERT(m_state != Terminated);
    RELEASE_ASSERT(m_connectionState == ConnectionStateReceivedResponse || m_connectionState == ConnectionStateReceivingData);
    m_connectionState = ConnectionStateReceivingData;

    // It is possible to receive data on uninitialized resources if it had an error status code, and we are running a nested message
    // loop. When this occurs, ignoring the data is the correct action.
    if (m_resource->response().httpStatusCode() >= 400 && !m_resource->shouldIgnoreHTTPStatusCodeErrors())
        return;
    ASSERT(m_state == Initialized);

    // Reference the object in this method since the additional processing can do
    // anything including removing the last reference to this object.
    RefPtrWillBeRawPtr<ResourceLoader> protect(this);

    // FIXME: If we get a resource with more than 2B bytes, this code won't do the right thing.
    // However, with today's computers and networking speeds, this won't happen in practice.
    // Could be an issue with a giant local file.
    m_host->didReceiveData(m_resource, data, length, encodedDataLength);
    if (m_state == Terminated)
        return;
    m_resource->appendData(data, length);
}

void ResourceLoader::didFinishLoading(blink::WebURLLoader*, double finishTime, int64 encodedDataLength)
{
    RELEASE_ASSERT(m_connectionState == ConnectionStateReceivedResponse || m_connectionState == ConnectionStateReceivingData);
    m_connectionState = ConnectionStateFinishedLoading;
    if (m_state != Initialized)
        return;
    ASSERT(m_state != Terminated);
    WTF_LOG(ResourceLoading, "Received '%s'.", m_resource->url().string().latin1().data());

    RefPtrWillBeRawPtr<ResourceLoader> protect(this);
    ResourcePtr<Resource> protectResource(m_resource);
    m_state = Finishing;
    didFinishLoadingOnePart(finishTime, encodedDataLength);
    if (m_state == Terminated)
        return;
    m_resource->finish(finishTime);

    // If the load has been cancelled by a delegate in response to didFinishLoad(), do not release
    // the resources a second time, they have been released by cancel.
    if (m_state == Terminated)
        return;
    releaseResources();
}

void ResourceLoader::didFail(blink::WebURLLoader*, const blink::WebURLError& error)
{
    m_connectionState = ConnectionStateFailed;
    ASSERT(m_state != Terminated);
    WTF_LOG(ResourceLoading, "Failed to load '%s'.\n", m_resource->url().string().latin1().data());

    RefPtrWillBeRawPtr<ResourceLoader> protect(this);
    RefPtrWillBeRawPtr<ResourceLoaderHost> protectHost(m_host.get());
    ResourcePtr<Resource> protectResource(m_resource);
    m_state = Finishing;
    m_resource->setResourceError(error);

    if (!m_notifiedLoadComplete) {
        m_notifiedLoadComplete = true;
        m_host->didFailLoading(m_resource, error);
    }
    if (m_state == Terminated)
        return;

    m_resource->error(Resource::LoadError);

    if (m_state == Terminated)
        return;

    releaseResources();
}

bool ResourceLoader::isLoadedBy(ResourceLoaderHost* loader) const
{
    return m_host->isLoadedBy(loader);
}

ResourceRequest& ResourceLoader::applyOptions(ResourceRequest& request) const
{
    request.setAllowStoredCredentials(m_options.allowCredentials == AllowStoredCredentials);
    return request;
}

}
