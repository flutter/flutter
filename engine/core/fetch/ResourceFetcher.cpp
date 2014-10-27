/*
    Copyright (C) 1998 Lars Knoll (knoll@mpi-hd.mpg.de)
    Copyright (C) 2001 Dirk Mueller (mueller@kde.org)
    Copyright (C) 2002 Waldo Bastian (bastian@kde.org)
    Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.
    Copyright (C) 2009 Torch Mobile Inc. http://www.torchmobile.com/

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.

    This class provides all functionality needed for loading images, style sheets and html
    pages from the web. It has a memory cache for these objects.
*/

#include "config.h"
#include "core/fetch/ResourceFetcher.h"

#include "bindings/core/v8/ScriptController.h"
#include "core/FetchInitiatorTypeNames.h"
#include "core/dom/Document.h"
#include "core/fetch/FetchContext.h"
#include "core/fetch/FontResource.h"
#include "core/fetch/ImageResource.h"
#include "core/fetch/MemoryCache.h"
#include "core/fetch/RawResource.h"
#include "core/fetch/ResourceLoader.h"
#include "core/fetch/ResourceLoaderSet.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/frame/UseCounter.h"
#include "core/html/HTMLElement.h"
#include "core/html/imports/HTMLImportsController.h"
#include "core/inspector/ConsoleMessage.h"
#include "core/loader/FrameLoaderClient.h"
#include "core/loader/UniqueIdentifier.h"
#include "core/page/Page.h"
#include "platform/Logging.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "platform/SharedBuffer.h"
#include "platform/TraceEvent.h"
#include "platform/weborigin/SecurityPolicy.h"
#include "public/platform/Platform.h"
#include "public/platform/WebURL.h"
#include "public/platform/WebURLRequest.h"
#include "wtf/text/CString.h"
#include "wtf/text/WTFString.h"

#define PRELOAD_DEBUG 0

using blink::WebURLRequest;

namespace blink {

static Resource* createResource(Resource::Type type, const ResourceRequest& request, const String& charset)
{
    switch (type) {
    case Resource::Image:
        return new ImageResource(request);
    case Resource::Font:
        return new FontResource(request);
    case Resource::MainResource:
    case Resource::Raw:
    case Resource::Media:
        return new RawResource(request, type);
    case Resource::LinkPrefetch:
        return new Resource(request, Resource::LinkPrefetch);
    case Resource::LinkSubresource:
        return new Resource(request, Resource::LinkSubresource);
    case Resource::ImportResource:
        return new RawResource(request, type);
    }

    ASSERT_NOT_REACHED();
    return 0;
}

static ResourceLoadPriority loadPriority(Resource::Type type, const FetchRequest& request)
{
    if (request.priority() != ResourceLoadPriorityUnresolved)
        return request.priority();

    switch (type) {
    case Resource::MainResource:
        return ResourceLoadPriorityVeryHigh;
    case Resource::Raw:
    case Resource::Font:
    case Resource::ImportResource:
        return ResourceLoadPriorityMedium;
    case Resource::Image:
        // We'll default images to VeryLow, and promote whatever is visible. This improves
        // speed-index by ~5% on average, ~14% at the 99th percentile.
        return ResourceLoadPriorityVeryLow;
    case Resource::Media:
        return ResourceLoadPriorityLow;
    case Resource::LinkPrefetch:
        return ResourceLoadPriorityVeryLow;
    case Resource::LinkSubresource:
        return ResourceLoadPriorityLow;
    }
    ASSERT_NOT_REACHED();
    return ResourceLoadPriorityUnresolved;
}

static Resource* resourceFromDataURIRequest(const ResourceRequest& request, const ResourceLoaderOptions& resourceOptions)
{
    const KURL& url = request.url();
    ASSERT(url.protocolIsData());

    blink::WebString mimetype;
    blink::WebString charset;
    RefPtr<SharedBuffer> data = PassRefPtr<SharedBuffer>(blink::Platform::current()->parseDataURL(url, mimetype, charset));
    if (!data)
        return 0;
    ResourceResponse response(url, mimetype, data->size(), charset, String());

    Resource* resource = createResource(Resource::Image, request, charset);
    resource->setOptions(resourceOptions);
    resource->responseReceived(response);
    if (data->size())
        resource->setResourceBuffer(data);
    resource->finish();
    return resource;
}

static WebURLRequest::RequestContext requestContextFromType(const ResourceFetcher* fetcher, Resource::Type type)
{
    switch (type) {
    case Resource::MainResource:
        // FIXME: Change this to a context frame type (once we introduce them): http://fetch.spec.whatwg.org/#concept-request-context-frame-type
        return WebURLRequest::RequestContextHyperlink;
    case Resource::Font:
        return WebURLRequest::RequestContextFont;
    case Resource::Image:
        return WebURLRequest::RequestContextImage;
    case Resource::Raw:
        return WebURLRequest::RequestContextSubresource;
    case Resource::ImportResource:
        return WebURLRequest::RequestContextImport;
    case Resource::LinkPrefetch:
        return WebURLRequest::RequestContextPrefetch;
    case Resource::LinkSubresource:
        return WebURLRequest::RequestContextSubresource;
    case Resource::Media: // TODO: Split this.
        return WebURLRequest::RequestContextVideo;
    }
    ASSERT_NOT_REACHED();
    return WebURLRequest::RequestContextSubresource;
}

ResourceFetcher::ResourceFetcher(Document* document)
    : m_document(document)
    , m_requestCount(0)
    , m_garbageCollectDocumentResourcesTimer(this, &ResourceFetcher::garbageCollectDocumentResourcesTimerFired)
    , m_autoLoadImages(true)
    , m_imagesEnabled(true)
    , m_allowStaleResources(false)
{
}

ResourceFetcher::~ResourceFetcher()
{
    m_document = nullptr;

    clearPreloads();

    // Make sure no requests still point to this ResourceFetcher
    ASSERT(!m_requestCount);
}

Resource* ResourceFetcher::cachedResource(const KURL& resourceURL) const
{
    KURL url = MemoryCache::removeFragmentIdentifierIfNeeded(resourceURL);
    return m_documentResources.get(url).get();
}

LocalFrame* ResourceFetcher::frame() const
{
    // FIXME(sky): This used to prefer DocumentLoader::frame
    // over importsController->master()->frame(), but in our
    // world we should always just have one frame.
    if (!m_document)
        return 0;
    if (m_document->importsController())
        return m_document->importsController()->master()->frame();
    return m_document->frame();
}

FetchContext& ResourceFetcher::context() const
{
    if (LocalFrame* frame = this->frame())
        return frame->fetchContext();
    return FetchContext::nullInstance();
}

ResourcePtr<ImageResource> ResourceFetcher::fetchImage(FetchRequest& request)
{
    if (request.resourceRequest().url().protocolIsData())
        preCacheDataURIImage(request);

    request.setDefer(clientDefersImage(request.resourceRequest().url()) ? FetchRequest::DeferredByClient : FetchRequest::NoDefer);
    ResourcePtr<Resource> resource = requestResource(Resource::Image, request);
    return resource && resource->type() == Resource::Image ? toImageResource(resource) : 0;
}

void ResourceFetcher::preCacheDataURIImage(const FetchRequest& request)
{
    const KURL& url = request.resourceRequest().url();
    ASSERT(url.protocolIsData());

    if (memoryCache()->resourceForURL(url))
        return;

    if (Resource* resource = resourceFromDataURIRequest(request.resourceRequest(), request.options())) {
        memoryCache()->add(resource);
        scheduleDocumentResourcesGC();
    }
}

ResourcePtr<FontResource> ResourceFetcher::fetchFont(FetchRequest& request)
{
    ASSERT(request.resourceRequest().frameType() == WebURLRequest::FrameTypeNone);
    request.mutableResourceRequest().setRequestContext(WebURLRequest::RequestContextFont);
    return toFontResource(requestResource(Resource::Font, request));
}

ResourcePtr<RawResource> ResourceFetcher::fetchImport(FetchRequest& request)
{
    ASSERT(request.resourceRequest().frameType() == WebURLRequest::FrameTypeNone);
    request.mutableResourceRequest().setRequestContext(WebURLRequest::RequestContextImport);
    return toRawResource(requestResource(Resource::ImportResource, request));
}

ResourcePtr<Resource> ResourceFetcher::fetchLinkResource(Resource::Type type, FetchRequest& request)
{
    ASSERT(frame());
    ASSERT(type == Resource::LinkPrefetch || type == Resource::LinkSubresource);
    ASSERT(request.resourceRequest().frameType() == WebURLRequest::FrameTypeNone);
    request.mutableResourceRequest().setRequestContext(type == Resource::LinkPrefetch ? WebURLRequest::RequestContextPrefetch : WebURLRequest::RequestContextSubresource);
    return requestResource(type, request);
}

ResourcePtr<RawResource> ResourceFetcher::fetchRawResource(FetchRequest& request)
{
    ASSERT(request.resourceRequest().frameType() == WebURLRequest::FrameTypeNone);
    ASSERT(request.resourceRequest().requestContext() != WebURLRequest::RequestContextUnspecified);
    return toRawResource(requestResource(Resource::Raw, request));
}

ResourcePtr<RawResource> ResourceFetcher::fetchMedia(FetchRequest& request)
{
    ASSERT(request.resourceRequest().frameType() == WebURLRequest::FrameTypeNone);
    // FIXME: Split this into audio and video.
    request.mutableResourceRequest().setRequestContext(WebURLRequest::RequestContextVideo);
    return toRawResource(requestResource(Resource::Media, request));
}

bool ResourceFetcher::canRequest(Resource::Type type, const KURL& url, const ResourceLoaderOptions& options, bool forPreload, FetchRequest::OriginRestriction originRestriction) const
{
    // FIXME(sky): Remove
    return true;
}

bool ResourceFetcher::shouldLoadNewResource(Resource::Type type) const
{
    if (!frame())
        return false;
    return true;
}

bool ResourceFetcher::resourceNeedsLoad(Resource* resource, const FetchRequest& request, RevalidationPolicy policy)
{
    if (FetchRequest::DeferredByClient == request.defer())
        return false;
    if (policy != Use)
        return true;
    return resource->stillNeedsLoad();
}

void ResourceFetcher::requestLoadStarted(Resource* resource, const FetchRequest& request, ResourceLoadStartType type)
{
    if (type == ResourceLoadingFromCache)
        notifyLoadedFromMemoryCache(resource);

    if (request.resourceRequest().url().protocolIsData())
        return;

    m_validatedURLs.add(request.resourceRequest().url());
}

ResourcePtr<Resource> ResourceFetcher::requestResource(Resource::Type type, FetchRequest& request)
{
    ASSERT(request.options().synchronousPolicy == RequestAsynchronously || type == Resource::Raw);

    TRACE_EVENT0("blink", "ResourceFetcher::requestResource");

    KURL url = request.resourceRequest().url();

    WTF_LOG(ResourceLoading, "ResourceFetcher::requestResource '%s', charset '%s', priority=%d, forPreload=%u, type=%s", url.elidedString().latin1().data(), request.charset().latin1().data(), request.priority(), request.forPreload(), ResourceTypeName(type));

    // If only the fragment identifiers differ, it is the same resource.
    url = MemoryCache::removeFragmentIdentifierIfNeeded(url);

    if (!url.isValid())
        return 0;

    if (!canRequest(type, url, request.options(), request.forPreload(), request.originRestriction()))
        return 0;

    if (LocalFrame* f = frame())
        f->loaderClient()->dispatchWillRequestResource(&request);

    // See if we can use an existing resource from the cache.
    ResourcePtr<Resource> resource = memoryCache()->resourceForURL(url);

    const RevalidationPolicy policy = determineRevalidationPolicy(type, request, resource.get());
    switch (policy) {
    case Reload:
        memoryCache()->remove(resource.get());
        // Fall through
    case Load:
        resource = createResourceForLoading(type, request, request.charset());
        break;
    case Revalidate:
        resource = createResourceForRevalidation(request, resource.get());
        break;
    case Use:
        memoryCache()->updateForAccess(resource.get());
        break;
    }

    if (!resource)
        return 0;

    if (!resource->hasClients())
        m_deadStatsRecorder.update(policy);

    if (policy != Use)
        resource->setIdentifier(createUniqueIdentifier());

    if (!request.forPreload() || policy != Use) {
        ResourceLoadPriority priority = loadPriority(type, request);
        if (priority != resource->resourceRequest().priority()) {
            resource->mutableResourceRequest().setPriority(priority);
            resource->didChangePriority(priority, 0);
        }
    }

    if (resourceNeedsLoad(resource.get(), request, policy)) {
        if (!shouldLoadNewResource(type)) {
            if (memoryCache()->contains(resource.get()))
                memoryCache()->remove(resource.get());
            return 0;
        }

        resource->load(this, request.options());

        // For asynchronous loads that immediately fail, it's sufficient to return a
        // null Resource, as it indicates that something prevented the load from starting.
        // If there's a network error, that failure will happen asynchronously. However, if
        // a sync load receives a network error, it will have already happened by this point.
        // In that case, the requester should have access to the relevant ResourceError, so
        // we need to return a non-null Resource.
        if (resource->errorOccurred()) {
            if (memoryCache()->contains(resource.get()))
                memoryCache()->remove(resource.get());
            return 0;
        }
    }

    requestLoadStarted(resource.get(), request, policy == Use ? ResourceLoadingFromCache : ResourceLoadingFromNetwork);

    ASSERT(resource->url() == url.string());
    m_documentResources.set(resource->url(), resource);
    return resource;
}

void ResourceFetcher::determineRequestContext(ResourceRequest& request, Resource::Type type)
{
    WebURLRequest::RequestContext requestContext = requestContextFromType(this, type);
    request.setRequestContext(requestContext);
}

ResourceRequestCachePolicy ResourceFetcher::resourceRequestCachePolicy(const ResourceRequest& request, Resource::Type type)
{
    if (request.isConditional())
        return ReloadIgnoringCacheData;

    return UseProtocolCachePolicy;
}

void ResourceFetcher::addAdditionalRequestHeaders(ResourceRequest& request, Resource::Type type)
{
    if (!frame())
        return;

    if (request.cachePolicy() == UseProtocolCachePolicy)
        request.setCachePolicy(resourceRequestCachePolicy(request, type));
    if (request.requestContext() == WebURLRequest::RequestContextUnspecified)
        determineRequestContext(request, type);
    if (type == Resource::LinkPrefetch || type == Resource::LinkSubresource)
        request.setHTTPHeaderField("Purpose", "prefetch");

    context().addAdditionalRequestHeaders(document(), request, (type == Resource::MainResource) ? FetchMainResource : FetchSubresource);
}

ResourcePtr<Resource> ResourceFetcher::createResourceForRevalidation(const FetchRequest& request, Resource* resource)
{
    ASSERT(resource);
    ASSERT(memoryCache()->contains(resource));
    ASSERT(resource->isLoaded());
    ASSERT(resource->canUseCacheValidator());
    ASSERT(!resource->resourceToRevalidate());

    ResourceRequest revalidatingRequest(resource->resourceRequest());
    revalidatingRequest.clearHTTPReferrer();
    addAdditionalRequestHeaders(revalidatingRequest, resource->type());

    const AtomicString& lastModified = resource->response().httpHeaderField("Last-Modified");
    const AtomicString& eTag = resource->response().httpHeaderField("ETag");
    if (!lastModified.isEmpty() || !eTag.isEmpty()) {
        ASSERT(context().cachePolicy(document()) != CachePolicyReload);
        if (context().cachePolicy(document()) == CachePolicyRevalidate)
            revalidatingRequest.setHTTPHeaderField("Cache-Control", "max-age=0");
    }
    if (!lastModified.isEmpty())
        revalidatingRequest.setHTTPHeaderField("If-Modified-Since", lastModified);
    if (!eTag.isEmpty())
        revalidatingRequest.setHTTPHeaderField("If-None-Match", eTag);

    ResourcePtr<Resource> newResource = createResource(resource->type(), revalidatingRequest, resource->encoding());
    WTF_LOG(ResourceLoading, "Resource %p created to revalidate %p", newResource.get(), resource);

    newResource->setResourceToRevalidate(resource);

    memoryCache()->remove(resource);
    memoryCache()->add(newResource.get());
    return newResource;
}

ResourcePtr<Resource> ResourceFetcher::createResourceForLoading(Resource::Type type, FetchRequest& request, const String& charset)
{
    ASSERT(!memoryCache()->resourceForURL(request.resourceRequest().url()));

    WTF_LOG(ResourceLoading, "Loading Resource for '%s'.", request.resourceRequest().url().elidedString().latin1().data());

    addAdditionalRequestHeaders(request.mutableResourceRequest(), type);
    ResourcePtr<Resource> resource = createResource(type, request.resourceRequest(), charset);

    memoryCache()->add(resource.get());
    return resource;
}

ResourceFetcher::RevalidationPolicy ResourceFetcher::determineRevalidationPolicy(Resource::Type type, const FetchRequest& fetchRequest, Resource* existingResource) const
{
    const ResourceRequest& request = fetchRequest.resourceRequest();

    if (!existingResource)
        return Load;

    // We already have a preload going for this URL.
    if (fetchRequest.forPreload() && existingResource->isPreloaded())
        return Use;

    // If the same URL has been loaded as a different type, we need to reload.
    if (existingResource->type() != type) {
        // FIXME: If existingResource is a Preload and the new type is LinkPrefetch
        // We really should discard the new prefetch since the preload has more
        // specific type information! crbug.com/379893
        // fast/dom/HTMLLinkElement/link-and-subresource-test hits this case.
        WTF_LOG(ResourceLoading, "ResourceFetcher::determineRevalidationPolicy reloading due to type mismatch.");
        return Reload;
    }

    // Do not load from cache if images are not enabled. The load for this image will be blocked
    // in ImageResource::load.
    if (FetchRequest::DeferredByClient == fetchRequest.defer())
        return Reload;

    // Always use data uris.
    // FIXME: Extend this to non-images.
    if (type == Resource::Image && request.url().protocolIsData())
        return Use;

    if (!existingResource->canReuse(request))
        return Reload;

    // Never use cache entries for downloadToFile requests. The caller expects the resource in a file.
    if (request.downloadToFile())
        return Reload;

    // Certain requests (e.g., XHRs) might have manually set headers that require revalidation.
    // FIXME: In theory, this should be a Revalidate case. In practice, the MemoryCache revalidation path assumes a whole bunch
    // of things about how revalidation works that manual headers violate, so punt to Reload instead.
    if (request.isConditional())
        return Reload;

    // Don't reload resources while pasting.
    if (m_allowStaleResources)
        return Use;

    if (!fetchRequest.options().canReuseRequest(existingResource->options()))
        return Reload;

    // Always use preloads.
    if (existingResource->isPreloaded())
        return Use;

    // CachePolicyHistoryBuffer uses the cache no matter what.
    CachePolicy cachePolicy = context().cachePolicy(document());
    if (cachePolicy == CachePolicyHistoryBuffer)
        return Use;

    // Don't reuse resources with Cache-control: no-store.
    if (existingResource->hasCacheControlNoStoreHeader()) {
        WTF_LOG(ResourceLoading, "ResourceFetcher::determineRevalidationPolicy reloading due to Cache-control: no-store.");
        return Reload;
    }

    // If credentials were sent with the previous request and won't be
    // with this one, or vice versa, re-fetch the resource.
    //
    // This helps with the case where the server sends back
    // "Access-Control-Allow-Origin: *" all the time, but some of the
    // client's requests are made without CORS and some with.
    if (existingResource->resourceRequest().allowStoredCredentials() != request.allowStoredCredentials()) {
        WTF_LOG(ResourceLoading, "ResourceFetcher::determineRevalidationPolicy reloading due to difference in credentials settings.");
        return Reload;
    }

    // During the initial load, avoid loading the same resource multiple times for a single document,
    // even if the cache policies would tell us to.
    // We also group loads of the same resource together.
    // Raw resources are exempted, as XHRs fall into this category and may have user-set Cache-Control:
    // headers or other factors that require separate requests.
    if (type != Resource::Raw) {
        if (document() && !document()->loadEventFinished() && m_validatedURLs.contains(existingResource->url()))
            return Use;
        if (existingResource->isLoading())
            return Use;
    }

    // CachePolicyReload always reloads
    if (cachePolicy == CachePolicyReload) {
        WTF_LOG(ResourceLoading, "ResourceFetcher::determineRevalidationPolicy reloading due to CachePolicyReload.");
        return Reload;
    }

    // We'll try to reload the resource if it failed last time.
    if (existingResource->errorOccurred()) {
        WTF_LOG(ResourceLoading, "ResourceFetcher::determineRevalidationPolicye reloading due to resource being in the error state");
        return Reload;
    }

    // List of available images logic allows images to be re-used without cache validation. We restrict this only to images
    // from memory cache which are the same as the version in the current document.
    if (type == Resource::Image && existingResource == cachedResource(request.url()))
        return Use;

    // Check if the cache headers requires us to revalidate (cache expiration for example).
    if (cachePolicy == CachePolicyRevalidate || existingResource->mustRevalidateDueToCacheHeaders()
        || request.cacheControlContainsNoCache()) {
        // See if the resource has usable ETag or Last-modified headers.
        if (existingResource->canUseCacheValidator())
            return Revalidate;

        // No, must reload.
        WTF_LOG(ResourceLoading, "ResourceFetcher::determineRevalidationPolicy reloading due to missing cache validators.");
        return Reload;
    }

    return Use;
}

void ResourceFetcher::printAccessDeniedMessage(const KURL& url) const
{
    if (url.isNull())
        return;

    if (!frame())
        return;

    String message;
    if (!m_document || m_document->url().isNull())
        message = "Unsafe attempt to load URL " + url.elidedString() + '.';
    else
        message = "Unsafe attempt to load URL " + url.elidedString() + " from frame with URL " + m_document->url().elidedString() + ". Domains, protocols and ports must match.\n";

    frame()->document()->addConsoleMessage(ConsoleMessage::create(SecurityMessageSource, ErrorMessageLevel, message));
}

void ResourceFetcher::setAutoLoadImages(bool enable)
{
    if (enable == m_autoLoadImages)
        return;

    m_autoLoadImages = enable;

    if (!m_autoLoadImages)
        return;

    reloadImagesIfNotDeferred();
}

void ResourceFetcher::setImagesEnabled(bool enable)
{
    if (enable == m_imagesEnabled)
        return;

    m_imagesEnabled = enable;

    if (!m_imagesEnabled)
        return;

    reloadImagesIfNotDeferred();
}

bool ResourceFetcher::clientDefersImage(const KURL& url) const
{
    // FIXME(sky): remove
    return false;
}

bool ResourceFetcher::shouldDeferImageLoad(const KURL& url) const
{
    return clientDefersImage(url) || !m_autoLoadImages;
}

void ResourceFetcher::reloadImagesIfNotDeferred()
{
    DocumentResourceMap::iterator end = m_documentResources.end();
    for (DocumentResourceMap::iterator it = m_documentResources.begin(); it != end; ++it) {
        Resource* resource = it->value.get();
        if (resource->type() == Resource::Image && resource->stillNeedsLoad() && !clientDefersImage(resource->url()))
            const_cast<Resource*>(resource)->load(this, defaultResourceOptions());
    }
}

void ResourceFetcher::didLoadResource(Resource* resource)
{
    RefPtr<Document> protectDocument(m_document);
    if (m_document)
        m_document->checkCompleted();
    scheduleDocumentResourcesGC();
}

void ResourceFetcher::scheduleDocumentResourcesGC()
{
    if (!m_garbageCollectDocumentResourcesTimer.isActive())
        m_garbageCollectDocumentResourcesTimer.startOneShot(0, FROM_HERE);
}

// Garbage collecting m_documentResources is a workaround for the
// ResourcePtrs on the RHS being strong references. Ideally this
// would be a weak map, however ResourcePtrs perform additional
// bookkeeping on Resources, so instead pseudo-GC them -- when the
// reference count reaches 1, m_documentResources is the only reference, so
// remove it from the map.
void ResourceFetcher::garbageCollectDocumentResourcesTimerFired(Timer<ResourceFetcher>* timer)
{
    ASSERT_UNUSED(timer, timer == &m_garbageCollectDocumentResourcesTimer);
    garbageCollectDocumentResources();
}

void ResourceFetcher::garbageCollectDocumentResources()
{
    typedef Vector<String, 10> StringVector;
    StringVector resourcesToDelete;

    for (DocumentResourceMap::iterator it = m_documentResources.begin(); it != m_documentResources.end(); ++it) {
        if (it->value->hasOneHandle())
            resourcesToDelete.append(it->key);
    }

    m_documentResources.removeAll(resourcesToDelete);
}

void ResourceFetcher::notifyLoadedFromMemoryCache(Resource* resource)
{
    if (!frame() || !frame()->page() || resource->status() != Resource::Cached || m_validatedURLs.contains(resource->url()))
        return;

    ResourceRequest request(resource->url());
    unsigned long identifier = createUniqueIdentifier();
    context().dispatchDidLoadResourceFromMemoryCache(request, resource->response());
    // FIXME: If willSendRequest changes the request, we don't respect it.
    willSendRequest(identifier, request, ResourceResponse(), resource->options().initiatorInfo);
    context().sendRemainingDelegateMessages(m_document, identifier, resource->response(), resource->encodedSize());
}

void ResourceFetcher::incrementRequestCount(const Resource* res)
{
    if (res->ignoreForRequestCount())
        return;

    ++m_requestCount;
}

void ResourceFetcher::decrementRequestCount(const Resource* res)
{
    if (res->ignoreForRequestCount())
        return;

    --m_requestCount;
    ASSERT(m_requestCount > -1);
}

void ResourceFetcher::preload(Resource::Type type, FetchRequest& request, const String& charset)
{
    requestPreload(type, request, charset);
}

void ResourceFetcher::requestPreload(Resource::Type type, FetchRequest& request, const String& charset)
{
    // Ensure main resources aren't preloaded, since the cache can't actually reuse the preload.
    if (type == Resource::MainResource)
        return;

    String encoding;
    request.setCharset(encoding);
    request.setForPreload(true);

    ResourcePtr<Resource> resource;
    // Loading images involves several special cases, so use dedicated fetch method instead.
    if (type == Resource::Image)
        resource = fetchImage(request);
    if (!resource)
        resource = requestResource(type, request);
    if (!resource || (m_preloads && m_preloads->contains(resource.get())))
        return;
    TRACE_EVENT_ASYNC_STEP_INTO0("net", "Resource", resource.get(), "Preload");
    resource->increasePreloadCount();

    if (!m_preloads)
        m_preloads = adoptPtr(new ListHashSet<Resource*>);
    m_preloads->add(resource.get());

#if PRELOAD_DEBUG
    printf("PRELOADING %s\n",  resource->url().string().latin1().data());
#endif
}

bool ResourceFetcher::isPreloaded(const String& urlString) const
{
    const KURL& url = m_document->completeURL(urlString);

    if (m_preloads) {
        ListHashSet<Resource*>::iterator end = m_preloads->end();
        for (ListHashSet<Resource*>::iterator it = m_preloads->begin(); it != end; ++it) {
            Resource* resource = *it;
            if (resource->url() == url)
                return true;
        }
    }

    return false;
}

void ResourceFetcher::clearPreloads()
{
#if PRELOAD_DEBUG
    printPreloadStats();
#endif
    if (!m_preloads)
        return;

    ListHashSet<Resource*>::iterator end = m_preloads->end();
    for (ListHashSet<Resource*>::iterator it = m_preloads->begin(); it != end; ++it) {
        Resource* res = *it;
        res->decreasePreloadCount();
        bool deleted = res->deleteIfPossible();
        if (!deleted && res->preloadResult() == Resource::PreloadNotReferenced)
            memoryCache()->remove(res);
    }
    m_preloads.clear();
}

void ResourceFetcher::didFinishLoading(const Resource* resource, double finishTime, int64_t encodedDataLength)
{
    TRACE_EVENT_ASYNC_END0("net", "Resource", resource);
    context().dispatchDidFinishLoading(m_document, resource->identifier(), finishTime, encodedDataLength);
}

void ResourceFetcher::didChangeLoadingPriority(const Resource* resource, ResourceLoadPriority loadPriority, int intraPriorityValue)
{
    TRACE_EVENT_ASYNC_STEP_INTO1("net", "Resource", resource, "ChangePriority", "priority", loadPriority);
    context().dispatchDidChangeResourcePriority(resource->identifier(), loadPriority, intraPriorityValue);
}

void ResourceFetcher::didFailLoading(const Resource* resource, const ResourceError& error)
{
    TRACE_EVENT_ASYNC_END0("net", "Resource", resource);
    context().dispatchDidFail(m_document, resource->identifier(), error);
}

void ResourceFetcher::willSendRequest(unsigned long identifier, ResourceRequest& request, const ResourceResponse& redirectResponse, const FetchInitiatorInfo& initiatorInfo)
{
    context().dispatchWillSendRequest(m_document, identifier, request, redirectResponse, initiatorInfo);
}

void ResourceFetcher::didReceiveResponse(const Resource* resource, const ResourceResponse& response)
{
    context().dispatchDidReceiveResponse(m_document, resource->identifier(), response, resource->loader());
}

void ResourceFetcher::didReceiveData(const Resource* resource, const char* data, int dataLength, int encodedDataLength)
{
    context().dispatchDidReceiveData(m_document, resource->identifier(), data, dataLength, encodedDataLength);
}

void ResourceFetcher::didDownloadData(const Resource* resource, int dataLength, int encodedDataLength)
{
    context().dispatchDidDownloadData(m_document, resource->identifier(), dataLength, encodedDataLength);
}

void ResourceFetcher::subresourceLoaderFinishedLoadingOnePart(ResourceLoader* loader)
{
    if (!m_multipartLoaders)
        m_multipartLoaders = ResourceLoaderSet::create();
    m_multipartLoaders->add(loader);
    m_loaders->remove(loader);
}

void ResourceFetcher::didInitializeResourceLoader(ResourceLoader* loader)
{
    if (!m_document)
        return;
    if (!m_loaders)
        m_loaders = ResourceLoaderSet::create();
    ASSERT(!m_loaders->contains(loader));
    m_loaders->add(loader);
}

void ResourceFetcher::willTerminateResourceLoader(ResourceLoader* loader)
{
    if (m_loaders && m_loaders->contains(loader))
        m_loaders->remove(loader);
    if (m_multipartLoaders && m_multipartLoaders->contains(loader))
        m_multipartLoaders->remove(loader);
}

void ResourceFetcher::willStartLoadingResource(Resource* resource, ResourceRequest& request)
{
    TRACE_EVENT_ASYNC_BEGIN2("net", "Resource", resource, "url", resource->url().string().ascii(), "priority", resource->resourceRequest().priority());
}

void ResourceFetcher::stopFetching()
{
    if (m_multipartLoaders)
        m_multipartLoaders->cancelAll();
    if (m_loaders)
        m_loaders->cancelAll();
}

bool ResourceFetcher::isFetching() const
{
    return m_loaders && !m_loaders->isEmpty();
}

bool ResourceFetcher::isLoadedBy(ResourceLoaderHost* possibleOwner) const
{
    return this == possibleOwner;
}

#if !ENABLE(OILPAN)
void ResourceFetcher::refResourceLoaderHost()
{
    ref();
}

void ResourceFetcher::derefResourceLoaderHost()
{
    deref();
}
#endif

#if PRELOAD_DEBUG
void ResourceFetcher::printPreloadStats()
{
    if (!m_preloads)
        return;

    unsigned scripts = 0;
    unsigned scriptMisses = 0;
    unsigned stylesheets = 0;
    unsigned stylesheetMisses = 0;
    unsigned images = 0;
    unsigned imageMisses = 0;
    ListHashSet<Resource*>::iterator end = m_preloads->end();
    for (ListHashSet<Resource*>::iterator it = m_preloads->begin(); it != end; ++it) {
        Resource* res = *it;
        if (res->preloadResult() == Resource::PreloadNotReferenced)
            printf("!! UNREFERENCED PRELOAD %s\n", res->url().string().latin1().data());
        else if (res->preloadResult() == Resource::PreloadReferencedWhileComplete)
            printf("HIT COMPLETE PRELOAD %s\n", res->url().string().latin1().data());
        else if (res->preloadResult() == Resource::PreloadReferencedWhileLoading)
            printf("HIT LOADING PRELOAD %s\n", res->url().string().latin1().data());

        images++;
        if (res->preloadResult() < Resource::PreloadReferencedWhileLoading)
            imageMisses++;

        if (res->errorOccurred())
            memoryCache()->remove(res);

        res->decreasePreloadCount();
    }
    m_preloads.clear();

    if (scripts)
        printf("SCRIPTS: %d (%d hits, hit rate %d%%)\n", scripts, scripts - scriptMisses, (scripts - scriptMisses) * 100 / scripts);
    if (stylesheets)
        printf("STYLESHEETS: %d (%d hits, hit rate %d%%)\n", stylesheets, stylesheets - stylesheetMisses, (stylesheets - stylesheetMisses) * 100 / stylesheets);
    if (images)
        printf("IMAGES:  %d (%d hits, hit rate %d%%)\n", images, images - imageMisses, (images - imageMisses) * 100 / images);
}
#endif

const ResourceLoaderOptions& ResourceFetcher::defaultResourceOptions()
{
    DEFINE_STATIC_LOCAL(ResourceLoaderOptions, options, (BufferData, AllowStoredCredentials, ClientRequestedCredentials, DocumentContext));
    return options;
}

ResourceFetcher::DeadResourceStatsRecorder::DeadResourceStatsRecorder()
    : m_useCount(0)
    , m_revalidateCount(0)
    , m_loadCount(0)
{
}

ResourceFetcher::DeadResourceStatsRecorder::~DeadResourceStatsRecorder()
{
    blink::Platform::current()->histogramCustomCounts(
        "WebCore.ResourceFetcher.HitCount", m_useCount, 0, 1000, 50);
    blink::Platform::current()->histogramCustomCounts(
        "WebCore.ResourceFetcher.RevalidateCount", m_revalidateCount, 0, 1000, 50);
    blink::Platform::current()->histogramCustomCounts(
        "WebCore.ResourceFetcher.LoadCount", m_loadCount, 0, 1000, 50);
}

void ResourceFetcher::DeadResourceStatsRecorder::update(RevalidationPolicy policy)
{
    switch (policy) {
    case Reload:
    case Load:
        ++m_loadCount;
        return;
    case Revalidate:
        ++m_revalidateCount;
        return;
    case Use:
        ++m_useCount;
        return;
    }
}

}
