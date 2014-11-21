/*
    Copyright (C) 1998 Lars Knoll (knoll@mpi-hd.mpg.de)
    Copyright (C) 2001 Dirk Mueller <mueller@kde.org>
    Copyright (C) 2004, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.

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

#ifndef SKY_ENGINE_CORE_FETCH_MEMORYCACHE_H_
#define SKY_ENGINE_CORE_FETCH_MEMORYCACHE_H_

#include "base/cancelable_callback.h"
#include "sky/engine/core/fetch/Resource.h"
#include "sky/engine/core/fetch/ResourcePtr.h"
#include "sky/engine/public/platform/WebThread.h"
#include "sky/engine/wtf/HashMap.h"
#include "sky/engine/wtf/Noncopyable.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/text/StringHash.h"
#include "sky/engine/wtf/text/WTFString.h"

namespace blink  {

class Resource;
class ResourceFetcher;
class KURL;
class ExecutionContext;

// This cache holds subresources used by Web pages: images, scripts, stylesheets, etc.

// The cache keeps a flexible but bounded window of dead resources that grows/shrinks
// depending on the live resource load. Here's an example of cache growth over time,
// with a min dead resource capacity of 25% and a max dead resource capacity of 50%:

//        |-----|                              Dead: -
//        |----------|                         Live: +
//      --|----------|                         Cache boundary: | (objects outside this mark have been evicted)
//      --|----------++++++++++|
// -------|-----+++++++++++++++|
// -------|-----+++++++++++++++|+++++

// Enable this macro to periodically log information about the memory cache.
#undef MEMORY_CACHE_STATS

// Determines the order in which CachedResources are evicted
// from the decoded resources cache.
enum MemoryCacheLiveResourcePriority {
    MemoryCacheLiveResourcePriorityLow = 0,
    MemoryCacheLiveResourcePriorityHigh,
    MemoryCacheLiveResourcePriorityUnknown
};

enum UpdateReason {
    UpdateForAccess,
    UpdateForPropertyChange
};

// MemoryCacheEntry class is used only in MemoryCache class, but we don't make
// MemoryCacheEntry class an inner class of MemoryCache because of dependency
// from MemoryCacheLRUList.
class MemoryCacheEntry final {
public:
    static PassOwnPtr<MemoryCacheEntry> create(Resource* resource) { return adoptPtr(new MemoryCacheEntry(resource)); }

    ResourcePtr<Resource> m_resource;
    bool m_inLiveDecodedResourcesList;
    unsigned m_accessCount;
    MemoryCacheLiveResourcePriority m_liveResourcePriority;
    double m_lastDecodedAccessTime; // Used as a thrash guard

    RawPtr<MemoryCacheEntry> m_previousInLiveResourcesList;
    RawPtr<MemoryCacheEntry> m_nextInLiveResourcesList;
    RawPtr<MemoryCacheEntry> m_previousInAllResourcesList;
    RawPtr<MemoryCacheEntry> m_nextInAllResourcesList;

private:
    explicit MemoryCacheEntry(Resource* resource)
        : m_resource(resource)
        , m_inLiveDecodedResourcesList(false)
        , m_accessCount(0)
        , m_liveResourcePriority(MemoryCacheLiveResourcePriorityLow)
        , m_lastDecodedAccessTime(0.0)
        , m_previousInLiveResourcesList(nullptr)
        , m_nextInLiveResourcesList(nullptr)
        , m_previousInAllResourcesList(nullptr)
        , m_nextInAllResourcesList(nullptr)
    {
    }
};

// MemoryCacheLRUList is used only in MemoryCache class, but we don't make
// MemoryCacheLRUList an inner struct of MemoryCache because we can't define
// VectorTraits for inner structs.
struct MemoryCacheLRUList final {
    ALLOW_ONLY_INLINE_ALLOCATION();
public:
    RawPtr<MemoryCacheEntry> m_head;
    RawPtr<MemoryCacheEntry> m_tail;

    MemoryCacheLRUList() : m_head(nullptr), m_tail(nullptr) { }
};

}

WTF_ALLOW_MOVE_INIT_AND_COMPARE_WITH_MEM_FUNCTIONS(blink::MemoryCacheLRUList);

namespace blink {

class MemoryCache final {
    WTF_MAKE_NONCOPYABLE(MemoryCache); WTF_MAKE_FAST_ALLOCATED;
public:
    static PassOwnPtr<MemoryCache> create();
    ~MemoryCache();

    struct TypeStatistic {
        int count;
        int size;
        int liveSize;
        int decodedSize;
        int encodedSize;
        int encodedSizeDuplicatedInDataURLs;
        int purgeableSize;
        int purgedSize;

        TypeStatistic()
            : count(0)
            , size(0)
            , liveSize(0)
            , decodedSize(0)
            , encodedSize(0)
            , encodedSizeDuplicatedInDataURLs(0)
            , purgeableSize(0)
            , purgedSize(0)
        {
        }

        void addResource(Resource*);
    };

    struct Statistics {
        TypeStatistic images;
        TypeStatistic cssStyleSheets;
        TypeStatistic scripts;
        TypeStatistic xslStyleSheets;
        TypeStatistic fonts;
        TypeStatistic other;
    };

    Resource* resourceForURL(const KURL&);

    void add(Resource*);
    void replace(Resource* newResource, Resource* oldResource);
    void remove(Resource*);
    bool contains(const Resource*) const;

    static KURL removeFragmentIdentifierIfNeeded(const KURL& originalURL);

    // Sets the cache's memory capacities, in bytes. These will hold only approximately,
    // since the decoded cost of resources like scripts and stylesheets is not known.
    //  - minDeadBytes: The maximum number of bytes that dead resources should consume when the cache is under pressure.
    //  - maxDeadBytes: The maximum number of bytes that dead resources should consume when the cache is not under pressure.
    //  - totalBytes: The maximum number of bytes that the cache should consume overall.
    void setCapacities(size_t minDeadBytes, size_t maxDeadBytes, size_t totalBytes);
    void setDelayBeforeLiveDecodedPrune(double seconds) { m_delayBeforeLiveDecodedPrune = seconds; }
    void setMaxPruneDeferralDelay(double seconds) { m_maxPruneDeferralDelay = seconds; }

    void evictResources();

    void prune(Resource* justReleasedResource = 0);

    // Called to adjust a resource's size, lru list position, and access count.
    void update(Resource*, size_t oldSize, size_t newSize, bool wasAccessed = false);
    void updateForAccess(Resource* resource) { update(resource, resource->size(), resource->size(), true); }
    void updateDecodedResource(Resource*, UpdateReason, MemoryCacheLiveResourcePriority = MemoryCacheLiveResourcePriorityUnknown);

    void makeLive(Resource*);
    void makeDead(Resource*);

    // This should be called when a Resource object is created.
    void registerLiveResource(Resource&);
    // This should be called when a Resource object becomes unnecesarry.
    void unregisterLiveResource(Resource&);

    static void removeURLFromCache(ExecutionContext*, const KURL&);

    Statistics getStatistics();

    size_t minDeadCapacity() const { return m_minDeadCapacity; }
    size_t maxDeadCapacity() const { return m_maxDeadCapacity; }
    size_t capacity() const { return m_capacity; }
    size_t liveSize() const { return m_liveSize; }
    size_t deadSize() const { return m_deadSize; }

    // Exposed for testing
    MemoryCacheLiveResourcePriority priority(Resource*) const;

private:
    MemoryCache();

    MemoryCacheLRUList* lruListFor(unsigned accessCount, size_t);

#ifdef MEMORY_CACHE_STATS
    void dumpStats(Timer<MemoryCache>*);
    void dumpLRULists(bool includeLive) const;
#endif

    // Calls to put the cached resource into and out of LRU lists.
    void insertInLRUList(MemoryCacheEntry*, MemoryCacheLRUList*);
    void removeFromLRUList(MemoryCacheEntry*, MemoryCacheLRUList*);

    // Track decoded resources that are in the cache and referenced by a Web page.
    void insertInLiveDecodedResourcesList(MemoryCacheEntry*);
    void removeFromLiveDecodedResourcesList(MemoryCacheEntry*);

    size_t liveCapacity() const;
    size_t deadCapacity() const;

    void pruneMicrotask();
    // pruneDeadResources() - Flush decoded and encoded data from resources not referenced by Web pages.
    // pruneLiveResources() - Flush decoded data from resources still referenced by Web pages.
    void pruneDeadResources(); // Automatically decide how much to prune.
    void pruneLiveResources();
    void pruneNow(double currentTime);

    bool evict(MemoryCacheEntry*);

    bool prunePending() const { return !m_pendingPrune.IsCancelled(); }

    static void removeURLFromCacheInternal(ExecutionContext*, const KURL&);

    bool m_inPruneResources;
    double m_maxPruneDeferralDelay;
    double m_pruneTimeStamp;
    double m_pruneFrameTimeStamp;

    size_t m_capacity;
    size_t m_minDeadCapacity;
    size_t m_maxDeadCapacity;
    size_t m_maxDeferredPruneDeadCapacity;
    double m_delayBeforeLiveDecodedPrune;

    size_t m_liveSize; // The number of bytes currently consumed by "live" resources in the cache.
    size_t m_deadSize; // The number of bytes currently consumed by "dead" resources in the cache.

    base::CancelableClosure m_pendingPrune;

    // Size-adjusted and popularity-aware LRU list collection for cache objects. This collection can hold
    // more resources than the cached resource map, since it can also hold "stale" multiple versions of objects that are
    // waiting to die when the clients referencing them go away.
    Vector<MemoryCacheLRUList, 32> m_allResources;

    // Lists just for live resources with decoded data. Access to this list is based off of painting the resource.
    // The lists are ordered by decode priority, with higher indices having higher priorities.
    MemoryCacheLRUList m_liveDecodedResources[MemoryCacheLiveResourcePriorityHigh + 1];

    // A URL-based map of all resources that are in the cache (including the freshest version of objects that are currently being
    // referenced by a Web page).
    typedef HashMap<String, OwnPtr<MemoryCacheEntry> > ResourceMap;
    ResourceMap m_resources;

    friend class MemoryCacheTest;
#ifdef MEMORY_CACHE_STATS
    Timer<MemoryCache> m_statsTimer;
#endif
};

// Returns the global cache.
MemoryCache* memoryCache();

// Sets the global cache, used to swap in a test instance. Returns the old
// MemoryCache object.
PassOwnPtr<MemoryCache> replaceMemoryCacheForTesting(PassOwnPtr<MemoryCache>);

}

#endif  // SKY_ENGINE_CORE_FETCH_MEMORYCACHE_H_
