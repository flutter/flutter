/*
    Copyright (C) 1998 Lars Knoll (knoll@mpi-hd.mpg.de)
    Copyright (C) 2001 Dirk Mueller <mueller@kde.org>
    Copyright (C) 2006 Samuel Weinig (sam.weinig@gmail.com)
    Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011 Apple Inc. All rights reserved.

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
*/

#ifndef Resource_h
#define Resource_h

#include "core/fetch/ResourceLoaderOptions.h"
#include "platform/Timer.h"
#include "platform/network/ResourceError.h"
#include "platform/network/ResourceLoadPriority.h"
#include "platform/network/ResourceRequest.h"
#include "platform/network/ResourceResponse.h"
#include "wtf/HashCountedSet.h"
#include "wtf/HashSet.h"
#include "wtf/OwnPtr.h"
#include "wtf/text/WTFString.h"

// FIXME(crbug.com/352043): This is temporarily enabled even on RELEASE to diagnose a wild crash.
#define ENABLE_RESOURCE_IS_DELETED_CHECK

namespace blink {

struct FetchInitiatorInfo;
class MemoryCache;
class ResourceClient;
class ResourcePtrBase;
class ResourceFetcher;
class InspectorResource;
class ResourceLoader;
class SharedBuffer;

// A resource that is held in the cache. Classes who want to use this object should derive
// from ResourceClient, to get the function calls in case the requested data has arrived.
// This class also does the actual communication with the loader to obtain the resource from the network.
class Resource : public NoBaseWillBeGarbageCollectedFinalized<Resource> {
    WTF_MAKE_NONCOPYABLE(Resource); WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
    friend class InspectorResource;

public:
    enum Type {
        MainResource,
        Image,
        Font,
        Raw,
        LinkPrefetch,
        LinkSubresource,
        ImportResource,
        Media // Audio or video file requested by a HTML5 media element
    };

    enum Status {
        Unknown, // let cache decide what to do with it
        Pending, // only partially loaded
        Cached, // regular case
        LoadError,
        DecodeError
    };

    Resource(const ResourceRequest&, Type);
#if ENABLE(OILPAN)
    virtual ~Resource();
#else
protected:
    // Only deleteIfPossible should delete this.
    virtual ~Resource();
public:
#endif
    virtual void dispose();
    virtual void trace(Visitor*);
    static unsigned instanceCount() { return s_instanceCount; }

    virtual void load(ResourceFetcher*, const ResourceLoaderOptions&);

    virtual void setEncoding(const String&) { }
    virtual String encoding() const { return String(); }
    virtual void appendData(const char*, int);
    virtual void error(Resource::Status);

    void setNeedsSynchronousCacheHit(bool needsSynchronousCacheHit) { m_needsSynchronousCacheHit = needsSynchronousCacheHit; }

    void setResourceError(const ResourceError& error) { m_error = error; }
    const ResourceError& resourceError() const { return m_error; }

    void setIdentifier(unsigned long identifier) { m_identifier = identifier; }
    unsigned long identifier() const { return m_identifier; }

    virtual bool shouldIgnoreHTTPStatusCodeErrors() const { return false; }

    ResourceRequest& mutableResourceRequest() { return m_resourceRequest; }
    const ResourceRequest& resourceRequest() const { return m_resourceRequest; }

    const KURL& url() const { return m_resourceRequest.url();}
    Type type() const { return static_cast<Type>(m_type); }
    const ResourceLoaderOptions& options() const { return m_options; }
    void setOptions(const ResourceLoaderOptions& options) { m_options = options; }

    void didChangePriority(ResourceLoadPriority, int intraPriorityValue);

    void addClient(ResourceClient*);
    void removeClient(ResourceClient*);
    bool hasClients() const { return !m_clients.isEmpty() || !m_clientsAwaitingCallback.isEmpty(); }
    bool deleteIfPossible();

    enum PreloadResult {
        PreloadNotReferenced,
        PreloadReferenced,
        PreloadReferencedWhileLoading,
        PreloadReferencedWhileComplete
    };
    PreloadResult preloadResult() const { return static_cast<PreloadResult>(m_preloadResult); }

    virtual void didAddClient(ResourceClient*);
    virtual void didRemoveClient(ResourceClient*) { }
    virtual void allClientsRemoved();

    unsigned count() const { return m_clients.size(); }

    Status status() const { return static_cast<Status>(m_status); }
    void setStatus(Status status) { m_status = status; }

    size_t size() const { return encodedSize() + decodedSize() + overheadSize(); }
    size_t encodedSize() const { return m_encodedSize; }
    size_t decodedSize() const { return m_decodedSize; }
    size_t overheadSize() const;

    bool isLoaded() const { return !m_loading; } // FIXME. Method name is inaccurate. Loading might not have started yet.

    bool isLoading() const { return m_loading; }
    void setLoading(bool b) { m_loading = b; }
    virtual bool stillNeedsLoad() const { return false; }

    ResourceLoader* loader() const { return m_loader.get(); }

    virtual bool isImage() const { return false; }
    bool ignoreForRequestCount() const
    {
        return type() == MainResource
            || type() == LinkPrefetch
            || type() == LinkSubresource
            || type() == Media
            || type() == Raw;
    }

    // Computes the status of an object after loading.
    // Updates the expire date on the cache entry file
    void finish(double finishTime = 0.0);

    void clearLoader();

    SharedBuffer* resourceBuffer() const { return m_data.get(); }
    void setResourceBuffer(PassRefPtr<SharedBuffer>);

    virtual void willSendRequest(ResourceRequest&, const ResourceResponse&);

    virtual void updateRequest(const ResourceRequest&) { }
    virtual void responseReceived(const ResourceResponse&);
    void setResponse(const ResourceResponse& response) { m_response = response; }
    const ResourceResponse& response() const { return m_response; }

    bool hasOneHandle() const;
    bool canDelete() const;

    // List of acceptable MIME types separated by ",".
    // A MIME type may contain a wildcard, e.g. "text/*".
    AtomicString accept() const { return m_accept; }
    void setAccept(const AtomicString& accept) { m_accept = accept; }

    bool wasCanceled() const { return m_error.isCancellation(); }
    bool errorOccurred() const { return m_status == LoadError || m_status == DecodeError; }
    bool loadFailedOrCanceled() { return !m_error.isNull(); }

    DataBufferingPolicy dataBufferingPolicy() const { return m_options.dataBufferingPolicy; }
    void setDataBufferingPolicy(DataBufferingPolicy);

    bool isUnusedPreload() const { return isPreloaded() && preloadResult() == PreloadNotReferenced; }
    bool isPreloaded() const { return m_preloadCount; }
    void increasePreloadCount() { ++m_preloadCount; }
    void decreasePreloadCount() { ASSERT(m_preloadCount); --m_preloadCount; }

    void registerHandle(ResourcePtrBase* h);
    void unregisterHandle(ResourcePtrBase* h);

    bool mustRevalidateDueToCacheHeaders();
    bool canUseCacheValidator();
    bool isCacheValidator() const { return m_resourceToRevalidate; }
    Resource* resourceToRevalidate() const { return m_resourceToRevalidate; }
    void setResourceToRevalidate(Resource*);
    bool hasCacheControlNoStoreHeader();

    bool isPurgeable() const;
    bool wasPurged() const;
    bool lock();

    virtual void didSendData(unsigned long long /* bytesSent */, unsigned long long /* totalBytesToBeSent */) { }
    virtual void didDownloadData(int) { }

    double loadFinishTime() const { return m_loadFinishTime; }

    virtual bool canReuse(const ResourceRequest&) const { return true; }

    // Used by the MemoryCache to reduce the memory consumption of the entry.
    void prune();

    static const char* resourceTypeToString(Type, const FetchInitiatorInfo&);

#ifdef ENABLE_RESOURCE_IS_DELETED_CHECK
    void assertAlive() const { RELEASE_ASSERT(!m_deleted); }
#else
    void assertAlive() const { }
#endif

protected:
    virtual void checkNotify();
    virtual void finishOnePart();

    // Normal resource pointers will silently switch what Resource* they reference when we
    // successfully revalidated the resource. We need a way to guarantee that the Resource
    // that received the 304 response survives long enough to switch everything over to the
    // revalidatedresource. The normal mechanisms for keeping a Resource alive externally
    // (ResourcePtrs and ResourceClients registering themselves) don't work in this case, so
    // have a separate internal protector).
    class InternalResourcePtr {
    public:
        explicit InternalResourcePtr(Resource* resource)
            : m_resource(resource)
        {
            m_resource->incrementProtectorCount();
        }

        ~InternalResourcePtr()
        {
            m_resource->decrementProtectorCount();
            m_resource->deleteIfPossible();
        }
    private:
        Resource* m_resource;
    };

    void incrementProtectorCount() { m_protectorCount++; }
    void decrementProtectorCount() { m_protectorCount--; }

    void setEncodedSize(size_t);
    void setDecodedSize(size_t);
    void didAccessDecodedData();

    virtual void switchClientsToRevalidatedResource();
    void clearResourceToRevalidate();
    void updateResponseAfterRevalidation(const ResourceResponse& validatingResponse);

    void finishPendingClients();

    HashCountedSet<ResourceClient*> m_clients;
    HashCountedSet<ResourceClient*> m_clientsAwaitingCallback;

    class ResourceCallback {
    public:
        static ResourceCallback* callbackHandler();
        void schedule(Resource*);
        void cancel(Resource*);
        bool isScheduled(Resource*) const;
    private:
        ResourceCallback();
        void timerFired(Timer<ResourceCallback>*);
        Timer<ResourceCallback> m_callbackTimer;
        HashSet<Resource*> m_resourcesWithPendingClients;
    };

    bool hasClient(ResourceClient* client) { return m_clients.contains(client) || m_clientsAwaitingCallback.contains(client); }

    virtual bool isSafeToUnlock() const { return false; }
    virtual void destroyDecodedDataIfPossible() { }

    ResourceRequest m_resourceRequest;
    AtomicString m_accept;
    RefPtrWillBeMember<ResourceLoader> m_loader;
    ResourceLoaderOptions m_options;

    ResourceResponse m_response;
    double m_responseTimestamp;

    RefPtr<SharedBuffer> m_data;
    Timer<Resource> m_cancelTimer;

private:
    bool addClientToSet(ResourceClient*);
    void cancelTimerFired(Timer<Resource>*);

    void revalidationSucceeded(const ResourceResponse&);
    void revalidationFailed();

    bool unlock();

    bool hasRightHandleCountApartFromCache(unsigned targetCount) const;

    void failBeforeStarting();

    String m_fragmentIdentifierForRequest;

    ResourceError m_error;

    double m_loadFinishTime;

    unsigned long m_identifier;

    size_t m_encodedSize;
    size_t m_decodedSize;
    unsigned m_handleCount;
    unsigned m_preloadCount;
    unsigned m_protectorCount;

    unsigned m_preloadResult : 2; // PreloadResult
    unsigned m_requestedFromNetworkingLayer : 1;

    unsigned m_loading : 1;

    unsigned m_switchingClientsToRevalidatedResource : 1;

    unsigned m_type : 4; // Type
    unsigned m_status : 3; // Status

    unsigned m_wasPurged : 1;

    unsigned m_needsSynchronousCacheHit : 1;

#ifdef ENABLE_RESOURCE_IS_DELETED_CHECK
    bool m_deleted;
#endif

    // If this field is non-null we are using the resource as a proxy for checking whether an existing resource is still up to date
    // using HTTP If-Modified-Since/If-None-Match headers. If the response is 304 all clients of this resource are moved
    // to to be clients of m_resourceToRevalidate and the resource is deleted. If not, the field is zeroed and this
    // resources becomes normal resource load.
    RawPtrWillBeMember<Resource> m_resourceToRevalidate;

    // If this field is non-null, the resource has a proxy for checking whether it is still up to date (see m_resourceToRevalidate).
    RawPtrWillBeMember<Resource> m_proxyResource;

    // These handles will need to be updated to point to the m_resourceToRevalidate in case we get 304 response.
    HashSet<ResourcePtrBase*> m_handlesToRevalidate;

    static unsigned s_instanceCount;
};

#if !LOG_DISABLED
// Intended to be used in LOG statements.
const char* ResourceTypeName(Resource::Type);
#endif

#define DEFINE_RESOURCE_TYPE_CASTS(typeName) \
    DEFINE_TYPE_CASTS(typeName##Resource, Resource, resource, resource->type() == Resource::typeName, resource.type() == Resource::typeName); \
    inline typeName##Resource* to##typeName##Resource(const ResourcePtr<Resource>& ptr) { return to##typeName##Resource(ptr.get()); }

}

#endif
