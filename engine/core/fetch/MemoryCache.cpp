/*
    Copyright (C) 1998 Lars Knoll (knoll@mpi-hd.mpg.de)
    Copyright (C) 2001 Dirk Mueller (mueller@kde.org)
    Copyright (C) 2002 Waldo Bastian (bastian@kde.org)
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
*/

#include "config.h"
#include "core/fetch/MemoryCache.h"

#include "base/bind.h"
#include "core/dom/Microtask.h"
#include "core/fetch/ResourcePtr.h"
#include "core/frame/FrameView.h"
#include "platform/Logging.h"
#include "platform/TraceEvent.h"
#include "wtf/Assertions.h"
#include "wtf/CurrentTime.h"
#include "wtf/MainThread.h"
#include "wtf/MathExtras.h"
#include "wtf/TemporaryChange.h"
#include "wtf/text/CString.h"

namespace blink {

static OwnPtr<MemoryCache>* gMemoryCache;

static const unsigned cDefaultCacheCapacity = 8192 * 1024;
static const unsigned cDeferredPruneDeadCapacityFactor = 2;
static const int cMinDelayBeforeLiveDecodedPrune = 1; // Seconds.
static const double cMaxPruneDeferralDelay = 0.5; // Seconds.
static const float cTargetPrunePercentage = .95f; // Percentage of capacity toward which we prune, to avoid immediately pruning again.

MemoryCache* memoryCache()
{
    ASSERT(WTF::isMainThread());
    if (!gMemoryCache)
        gMemoryCache = new OwnPtr<MemoryCache>(MemoryCache::create());
    return gMemoryCache->get();
}

PassOwnPtr<MemoryCache> replaceMemoryCacheForTesting(PassOwnPtr<MemoryCache> cache)
{
    // Make sure we have non-empty gMemoryCache.
    memoryCache();
    OwnPtr<MemoryCache> oldCache = gMemoryCache->release();
    *gMemoryCache = cache;
    return oldCache.release();
}

void MemoryCacheEntry::trace(Visitor* visitor)
{
    visitor->trace(m_previousInLiveResourcesList);
    visitor->trace(m_nextInLiveResourcesList);
    visitor->trace(m_previousInAllResourcesList);
    visitor->trace(m_nextInAllResourcesList);
}

void MemoryCacheLRUList::trace(Visitor* visitor)
{
    visitor->trace(m_head);
    visitor->trace(m_tail);
}

inline MemoryCache::MemoryCache()
    : m_inPruneResources(false)
    , m_maxPruneDeferralDelay(cMaxPruneDeferralDelay)
    , m_capacity(cDefaultCacheCapacity)
    , m_minDeadCapacity(0)
    , m_maxDeadCapacity(cDefaultCacheCapacity)
    , m_maxDeferredPruneDeadCapacity(cDeferredPruneDeadCapacityFactor * cDefaultCacheCapacity)
    , m_delayBeforeLiveDecodedPrune(cMinDelayBeforeLiveDecodedPrune)
    , m_liveSize(0)
    , m_deadSize(0)
#ifdef MEMORY_CACHE_STATS
    , m_statsTimer(this, &MemoryCache::dumpStats)
#endif
{
#ifdef MEMORY_CACHE_STATS
    const double statsIntervalInSeconds = 15;
    m_statsTimer.startRepeating(statsIntervalInSeconds, FROM_HERE);
#endif
    m_pruneTimeStamp = m_pruneFrameTimeStamp = FrameView::currentFrameTimeStamp();
}

PassOwnPtr<MemoryCache> MemoryCache::create()
{
    return adoptPtr(new MemoryCache());
}

MemoryCache::~MemoryCache()
{
}

void MemoryCache::trace(Visitor* visitor)
{
#if ENABLE(OILPAN)
    visitor->trace(m_allResources);
    for (size_t i = 0; i < WTF_ARRAY_LENGTH(m_liveDecodedResources); ++i)
        visitor->trace(m_liveDecodedResources[i]);
    visitor->trace(m_resources);
    visitor->trace(m_liveResources);
#endif
}

KURL MemoryCache::removeFragmentIdentifierIfNeeded(const KURL& originalURL)
{
    if (!originalURL.hasFragmentIdentifier())
        return originalURL;
    // Strip away fragment identifier from HTTP URLs.
    // Data URLs must be unmodified. For file and custom URLs clients may expect resources
    // to be unique even when they differ by the fragment identifier only.
    if (!originalURL.protocolIsInHTTPFamily())
        return originalURL;
    KURL url = originalURL;
    url.removeFragmentIdentifier();
    return url;
}

void MemoryCache::add(Resource* resource)
{
    ASSERT(WTF::isMainThread());
    ASSERT(resource->url().isValid());
    RELEASE_ASSERT(!m_resources.contains(resource->url()));
    m_resources.set(resource->url().string(), MemoryCacheEntry::create(resource));
    update(resource, 0, resource->size(), true);

    WTF_LOG(ResourceLoading, "MemoryCache::add Added '%s', resource %p\n", resource->url().string().latin1().data(), resource);
}

void MemoryCache::replace(Resource* newResource, Resource* oldResource)
{
    if (MemoryCacheEntry* oldEntry = m_resources.get(oldResource->url()))
        evict(oldEntry);
    add(newResource);
    if (newResource->decodedSize() && newResource->hasClients())
        insertInLiveDecodedResourcesList(m_resources.get(newResource->url()));
}

void MemoryCache::remove(Resource* resource)
{
    // The resource may have already been removed by someone other than our caller,
    // who needed a fresh copy for a reload.
    if (!contains(resource))
        return;
    evict(m_resources.get(resource->url()));
}

bool MemoryCache::contains(const Resource* resource) const
{
    if (resource->url().isNull())
        return false;
    const MemoryCacheEntry* entry = m_resources.get(resource->url());
    return entry && entry->m_resource == resource;
}

Resource* MemoryCache::resourceForURL(const KURL& resourceURL)
{
    ASSERT(WTF::isMainThread());
    KURL url = removeFragmentIdentifierIfNeeded(resourceURL);
    MemoryCacheEntry* entry = m_resources.get(url);
    if (!entry)
        return 0;
    Resource* resource = entry->m_resource.get();
    if (resource && !resource->lock()) {
        ASSERT(!resource->hasClients());
        bool didEvict = evict(entry);
        ASSERT_UNUSED(didEvict, didEvict);
        return 0;
    }
    return resource;
}

size_t MemoryCache::deadCapacity() const
{
    // Dead resource capacity is whatever space is not occupied by live resources, bounded by an independent minimum and maximum.
    size_t capacity = m_capacity - std::min(m_liveSize, m_capacity); // Start with available capacity.
    capacity = std::max(capacity, m_minDeadCapacity); // Make sure it's above the minimum.
    capacity = std::min(capacity, m_maxDeadCapacity); // Make sure it's below the maximum.
    return capacity;
}

size_t MemoryCache::liveCapacity() const
{
    // Live resource capacity is whatever is left over after calculating dead resource capacity.
    return m_capacity - deadCapacity();
}

void MemoryCache::pruneLiveResources()
{
    ASSERT(!prunePending());
    size_t capacity = liveCapacity();
    if (!m_liveSize || (capacity && m_liveSize <= capacity))
        return;

    size_t targetSize = static_cast<size_t>(capacity * cTargetPrunePercentage); // Cut by a percentage to avoid immediately pruning again.

    // Destroy any decoded data in live objects that we can.
    // Start from the tail, since this is the lowest priority
    // and least recently accessed of the objects.

    // The list might not be sorted by the m_lastDecodedFrameTimeStamp. The impact
    // of this weaker invariant is minor as the below if statement to check the
    // elapsedTime will evaluate to false as the current time will be a lot
    // greater than the current->m_lastDecodedFrameTimeStamp.
    // For more details see: https://bugs.webkit.org/show_bug.cgi?id=30209

    // Start pruning from the lowest priority list.
    for (int priority = MemoryCacheLiveResourcePriorityLow; priority <= MemoryCacheLiveResourcePriorityHigh; ++priority) {
        MemoryCacheEntry* current = m_liveDecodedResources[priority].m_tail;
        while (current) {
            MemoryCacheEntry* previous = current->m_previousInLiveResourcesList;
            ASSERT(current->m_resource->hasClients());
            if (current->m_resource->isLoaded() && current->m_resource->decodedSize()) {
                // Check to see if the remaining resources are too new to prune.
                double elapsedTime = m_pruneFrameTimeStamp - current->m_lastDecodedAccessTime;
                if (elapsedTime < m_delayBeforeLiveDecodedPrune)
                    return;

                // Destroy our decoded data if possible. This will remove us
                // from m_liveDecodedResources, and possibly move us to a
                // different LRU list in m_allResources.
                current->m_resource->prune();

                if (targetSize && m_liveSize <= targetSize)
                    return;
            }
            current = previous;
        }
    }
}

void MemoryCache::pruneDeadResources()
{
    size_t capacity = deadCapacity();
    if (!m_deadSize || (capacity && m_deadSize <= capacity))
        return;

    size_t targetSize = static_cast<size_t>(capacity * cTargetPrunePercentage); // Cut by a percentage to avoid immediately pruning again.

    int size = m_allResources.size();

    // See if we have any purged resources we can evict.
    for (int i = 0; i < size; i++) {
        MemoryCacheEntry* current = m_allResources[i].m_tail;
        while (current) {
            MemoryCacheEntry* previous = current->m_previousInAllResourcesList;
            // Main Resources in the cache are only substitue data that was
            // precached and should not be evicted.
            if (current->m_resource->wasPurged() && current->m_resource->canDelete()
                && current->m_resource->type() != Resource::MainResource) {
                ASSERT(!current->m_resource->hasClients());
                bool wasEvicted = evict(current);
                ASSERT_UNUSED(wasEvicted, wasEvicted);
            }
            current = previous;
        }
    }
    if (targetSize && m_deadSize <= targetSize)
        return;

    bool canShrinkLRULists = true;
    for (int i = size - 1; i >= 0; i--) {
        // Remove from the tail, since this is the least frequently accessed of the objects.
        MemoryCacheEntry* current = m_allResources[i].m_tail;

        // First flush all the decoded data in this queue.
        while (current) {
            // Protect 'previous' so it can't get deleted during destroyDecodedData().
            MemoryCacheEntry* previous = current->m_previousInAllResourcesList;
            ASSERT(!previous || contains(previous->m_resource.get()));
            if (!current->m_resource->hasClients() && current->m_resource->isLoaded()) {
                // Destroy our decoded data. This will remove us from
                // m_liveDecodedResources, and possibly move us to a different
                // LRU list in m_allResources.
                current->m_resource->prune();

                if (targetSize && m_deadSize <= targetSize)
                    return;
            }
            // Decoded data may reference other resources. Stop iterating if 'previous' somehow got
            // kicked out of cache during destroyDecodedData().
            if (previous && !contains(previous->m_resource.get()))
                break;
            current = previous;
        }

        // Now evict objects from this queue.
        current = m_allResources[i].m_tail;
        while (current) {
            MemoryCacheEntry* previous = current->m_previousInAllResourcesList;
            ASSERT(!previous || contains(previous->m_resource.get()));
            if (!current->m_resource->hasClients()
                && !current->m_resource->isCacheValidator() && current->m_resource->canDelete()
                && current->m_resource->type() != Resource::MainResource) {
                // Main Resources in the cache are only substitue data that was
                // precached and should not be evicted.
                bool wasEvicted = evict(current);
                ASSERT_UNUSED(wasEvicted, wasEvicted);
                if (targetSize && m_deadSize <= targetSize)
                    return;
            }
            if (previous && !contains(previous->m_resource.get()))
                break;
            current = previous;
        }

        // Shrink the vector back down so we don't waste time inspecting
        // empty LRU lists on future prunes.
        if (m_allResources[i].m_head)
            canShrinkLRULists = false;
        else if (canShrinkLRULists)
            m_allResources.resize(i);
    }
}

void MemoryCache::setCapacities(size_t minDeadBytes, size_t maxDeadBytes, size_t totalBytes)
{
    ASSERT(minDeadBytes <= maxDeadBytes);
    ASSERT(maxDeadBytes <= totalBytes);
    m_minDeadCapacity = minDeadBytes;
    m_maxDeadCapacity = maxDeadBytes;
    m_maxDeferredPruneDeadCapacity = cDeferredPruneDeadCapacityFactor * maxDeadBytes;
    m_capacity = totalBytes;
    prune();
}

bool MemoryCache::evict(MemoryCacheEntry* entry)
{
    ASSERT(WTF::isMainThread());

    Resource* resource = entry->m_resource.get();
    bool canDelete = resource->canDelete();
    WTF_LOG(ResourceLoading, "Evicting resource %p for '%s' from cache", resource, resource->url().string().latin1().data());
    // The resource may have already been removed by someone other than our caller,
    // who needed a fresh copy for a reload. See <http://bugs.webkit.org/show_bug.cgi?id=12479#c6>.
    update(resource, resource->size(), 0, false);
    removeFromLiveDecodedResourcesList(entry);

    ResourceMap::iterator it = m_resources.find(resource->url());
    ASSERT(it != m_resources.end());
#if !ENABLE(OILPAN)
    OwnPtr<MemoryCacheEntry> entryPtr;
    entryPtr.swap(it->value);
#endif
    m_resources.remove(it);
    return canDelete;
}

MemoryCacheLRUList* MemoryCache::lruListFor(unsigned accessCount, size_t size)
{
    ASSERT(accessCount > 0);
    unsigned queueIndex = WTF::fastLog2(size / accessCount);
    if (m_allResources.size() <= queueIndex)
        m_allResources.grow(queueIndex + 1);
    return &m_allResources[queueIndex];
}

void MemoryCache::removeFromLRUList(MemoryCacheEntry* entry, MemoryCacheLRUList* list)
{
#if ENABLE(ASSERT)
    // Verify that we are in fact in this list.
    bool found = false;
    for (MemoryCacheEntry* current = list->m_head; current; current = current->m_nextInAllResourcesList) {
        if (current == entry) {
            found = true;
            break;
        }
    }
    ASSERT(found);
#endif

    MemoryCacheEntry* next = entry->m_nextInAllResourcesList;
    MemoryCacheEntry* previous = entry->m_previousInAllResourcesList;
    entry->m_nextInAllResourcesList = nullptr;
    entry->m_previousInAllResourcesList = nullptr;

    if (next)
        next->m_previousInAllResourcesList = previous;
    else
        list->m_tail = previous;

    if (previous)
        previous->m_nextInAllResourcesList = next;
    else
        list->m_head = next;
}

void MemoryCache::insertInLRUList(MemoryCacheEntry* entry, MemoryCacheLRUList* list)
{
    ASSERT(!entry->m_nextInAllResourcesList && !entry->m_previousInAllResourcesList);

    entry->m_nextInAllResourcesList = list->m_head;
    list->m_head = entry;

    if (entry->m_nextInAllResourcesList)
        entry->m_nextInAllResourcesList->m_previousInAllResourcesList = entry;
    else
        list->m_tail = entry;

#if ENABLE(ASSERT)
    // Verify that we are in now in the list like we should be.
    bool found = false;
    for (MemoryCacheEntry* current = list->m_head; current; current = current->m_nextInAllResourcesList) {
        if (current == entry) {
            found = true;
            break;
        }
    }
    ASSERT(found);
#endif
}

void MemoryCache::removeFromLiveDecodedResourcesList(MemoryCacheEntry* entry)
{
    // If we've never been accessed, then we're brand new and not in any list.
    if (!entry->m_inLiveDecodedResourcesList)
        return;
    entry->m_inLiveDecodedResourcesList = false;

    MemoryCacheLRUList* list = &m_liveDecodedResources[entry->m_liveResourcePriority];

#if ENABLE(ASSERT)
    // Verify that we are in fact in this list.
    bool found = false;
    for (MemoryCacheEntry* current = list->m_head; current; current = current->m_nextInLiveResourcesList) {
        if (current == entry) {
            found = true;
            break;
        }
    }
    ASSERT(found);
#endif

    MemoryCacheEntry* next = entry->m_nextInLiveResourcesList;
    MemoryCacheEntry* previous = entry->m_previousInLiveResourcesList;

    entry->m_nextInLiveResourcesList = nullptr;
    entry->m_previousInLiveResourcesList = nullptr;

    if (next)
        next->m_previousInLiveResourcesList = previous;
    else
        list->m_tail = previous;

    if (previous)
        previous->m_nextInLiveResourcesList = next;
    else
        list->m_head = next;
}

void MemoryCache::insertInLiveDecodedResourcesList(MemoryCacheEntry* entry)
{
    // Make sure we aren't in the list already.
    ASSERT(!entry->m_nextInLiveResourcesList && !entry->m_previousInLiveResourcesList && !entry->m_inLiveDecodedResourcesList);
    entry->m_inLiveDecodedResourcesList = true;

    MemoryCacheLRUList* list = &m_liveDecodedResources[entry->m_liveResourcePriority];
    entry->m_nextInLiveResourcesList = list->m_head;
    if (list->m_head)
        list->m_head->m_previousInLiveResourcesList = entry;
    list->m_head = entry;

    if (!entry->m_nextInLiveResourcesList)
        list->m_tail = entry;

#if ENABLE(ASSERT)
    // Verify that we are in now in the list like we should be.
    bool found = false;
    for (MemoryCacheEntry* current = list->m_head; current; current = current->m_nextInLiveResourcesList) {
        if (current == entry) {
            found = true;
            break;
        }
    }
    ASSERT(found);
#endif
}

void MemoryCache::makeLive(Resource* resource)
{
    if (!contains(resource))
        return;
    ASSERT(m_deadSize >= resource->size());
    m_liveSize += resource->size();
    m_deadSize -= resource->size();
}

void MemoryCache::makeDead(Resource* resource)
{
    if (!contains(resource))
        return;
    m_liveSize -= resource->size();
    m_deadSize += resource->size();
    removeFromLiveDecodedResourcesList(m_resources.get(resource->url()));
}

void MemoryCache::update(Resource* resource, size_t oldSize, size_t newSize, bool wasAccessed)
{
    if (!contains(resource))
        return;
    MemoryCacheEntry* entry = m_resources.get(resource->url());

    // The object must now be moved to a different queue, since either its size or its accessCount has been changed,
    // and both of those are used to determine which LRU queue the resource should be in.
    if (oldSize)
        removeFromLRUList(entry, lruListFor(entry->m_accessCount, oldSize));
    if (wasAccessed)
        entry->m_accessCount++;
    if (newSize)
        insertInLRUList(entry, lruListFor(entry->m_accessCount, newSize));

    ptrdiff_t delta = newSize - oldSize;
    if (resource->hasClients()) {
        ASSERT(delta >= 0 || m_liveSize >= static_cast<size_t>(-delta) );
        m_liveSize += delta;
    } else {
        ASSERT(delta >= 0 || m_deadSize >= static_cast<size_t>(-delta) );
        m_deadSize += delta;
    }
}

void MemoryCache::updateDecodedResource(Resource* resource, UpdateReason reason, MemoryCacheLiveResourcePriority priority)
{
    if (!contains(resource))
        return;
    MemoryCacheEntry* entry = m_resources.get(resource->url());

    removeFromLiveDecodedResourcesList(entry);
    if (priority != MemoryCacheLiveResourcePriorityUnknown && priority != entry->m_liveResourcePriority)
        entry->m_liveResourcePriority = priority;
    if (resource->decodedSize() && resource->hasClients())
        insertInLiveDecodedResourcesList(entry);

    if (reason != UpdateForAccess)
        return;

    double timestamp = resource->isImage() ? FrameView::currentFrameTimeStamp() : 0.0;
    if (!timestamp)
        timestamp = currentTime();
    entry->m_lastDecodedAccessTime = timestamp;
}

MemoryCacheLiveResourcePriority MemoryCache::priority(Resource* resource) const
{
    if (!contains(resource))
        return MemoryCacheLiveResourcePriorityUnknown;
    MemoryCacheEntry* entry = m_resources.get(resource->url());
    return entry->m_liveResourcePriority;
}

void MemoryCache::removeURLFromCache(ExecutionContext* context, const KURL& url)
{
    removeURLFromCacheInternal(context, url);
}

void MemoryCache::removeURLFromCacheInternal(ExecutionContext*, const KURL& url)
{
    if (Resource* resource = memoryCache()->resourceForURL(url))
        memoryCache()->remove(resource);
}

void MemoryCache::TypeStatistic::addResource(Resource* o)
{
    bool purged = o->wasPurged();
    bool purgeable = o->isPurgeable() && !purged;
    size_t pageSize = (o->encodedSize() + o->overheadSize() + 4095) & ~4095;
    count++;
    size += purged ? 0 : o->size();
    liveSize += o->hasClients() ? o->size() : 0;
    decodedSize += o->decodedSize();
    encodedSize += o->encodedSize();
    encodedSizeDuplicatedInDataURLs += o->url().protocolIsData() ? o->encodedSize() : 0;
    purgeableSize += purgeable ? pageSize : 0;
    purgedSize += purged ? pageSize : 0;
}

MemoryCache::Statistics MemoryCache::getStatistics()
{
    Statistics stats;
    ResourceMap::iterator e = m_resources.end();
    for (ResourceMap::iterator i = m_resources.begin(); i != e; ++i) {
        Resource* resource = i->value->m_resource.get();
        switch (resource->type()) {
        case Resource::Image:
            stats.images.addResource(resource);
            break;
        case Resource::Font:
            stats.fonts.addResource(resource);
            break;
        default:
            stats.other.addResource(resource);
            break;
        }
    }
    return stats;
}

void MemoryCache::evictResources()
{
    for (;;) {
        ResourceMap::iterator i = m_resources.begin();
        if (i == m_resources.end())
            break;
        evict(i->value.get());
    }
}

void MemoryCache::prune(Resource* justReleasedResource)
{
    TRACE_EVENT0("renderer", "MemoryCache::prune()");

    if (m_inPruneResources)
        return;
    if (m_liveSize + m_deadSize <= m_capacity && m_maxDeadCapacity && m_deadSize <= m_maxDeadCapacity) // Fast path.
        return;

    // To avoid burdening the current thread with repetitive pruning jobs,
    // pruning is postponed until the end of the current task. If it has
    // been more than m_maxPruneDeferralDelay since the last prune,
    // then we prune immediately.
    // If the current thread's run loop is not active, then pruning will happen
    // immediately only if it has been over m_maxPruneDeferralDelay
    // since the last prune.
    double currentTime = WTF::currentTime();
    if (prunePending()) {
        if (currentTime - m_pruneTimeStamp >= m_maxPruneDeferralDelay)
            pruneNow(currentTime);
    } else {
        if (currentTime - m_pruneTimeStamp >= m_maxPruneDeferralDelay) {
            pruneNow(currentTime); // Delay exceeded, prune now.
        } else {
            m_pendingPrune.Reset(base::Bind(&MemoryCache::pruneMicrotask, base::Unretained(this)));
            Microtask::enqueueMicrotask(m_pendingPrune.callback());
        }
    }

    if (prunePending() && m_deadSize > m_maxDeferredPruneDeadCapacity && justReleasedResource) {
        // The following eviction does not respect LRU order, but it can be done
        // immediately in constant time, as opposed to pruneDeadResources, which
        // we would rather defer because it is O(N), which would make tear-down of N
        // objects O(N^2) if we pruned immediately. This immediate eviction is a
        // safeguard against runaway memory consumption by dead resources
        // while a prune is pending.
        // Main Resources in the cache are only substitue data that was
        // precached and should not be evicted.
        if (contains(justReleasedResource) && justReleasedResource->type() != Resource::MainResource)
            evict(m_resources.get(justReleasedResource->url()));

        // As a last resort, prune immediately
        if (m_deadSize > m_maxDeferredPruneDeadCapacity)
            pruneNow(currentTime);
    }
}

void MemoryCache::pruneMicrotask()
{
    pruneNow(WTF::currentTime());
}

void MemoryCache::pruneNow(double currentTime)
{
    if (prunePending())
        m_pendingPrune.Cancel();

    TemporaryChange<bool> reentrancyProtector(m_inPruneResources, true);
    pruneDeadResources(); // Prune dead first, in case it was "borrowing" capacity from live.
    pruneLiveResources();
    m_pruneFrameTimeStamp = FrameView::currentFrameTimeStamp();
    m_pruneTimeStamp = currentTime;
}

#if ENABLE(OILPAN)
void MemoryCache::registerLiveResource(Resource& resource)
{
    ASSERT(!m_liveResources.contains(&resource));
    m_liveResources.add(&resource);
}

void MemoryCache::unregisterLiveResource(Resource& resource)
{
    ASSERT(m_liveResources.contains(&resource));
    m_liveResources.remove(&resource);
}

#else

void MemoryCache::registerLiveResource(Resource&)
{
}

void MemoryCache::unregisterLiveResource(Resource&)
{
}
#endif

#ifdef MEMORY_CACHE_STATS

void MemoryCache::dumpStats(Timer<MemoryCache>*)
{
    Statistics s = getStatistics();
    printf("%-13s %-13s %-13s %-13s %-13s %-13s %-13s\n", "", "Count", "Size", "LiveSize", "DecodedSize", "PurgeableSize", "PurgedSize");
    printf("%-13s %-13s %-13s %-13s %-13s %-13s %-13s\n", "-------------", "-------------", "-------------", "-------------", "-------------", "-------------", "-------------");
    printf("%-13s %13d %13d %13d %13d %13d %13d\n", "Images", s.images.count, s.images.size, s.images.liveSize, s.images.decodedSize, s.images.purgeableSize, s.images.purgedSize);
    printf("%-13s %13d %13d %13d %13d %13d %13d\n", "CSS", s.cssStyleSheets.count, s.cssStyleSheets.size, s.cssStyleSheets.liveSize, s.cssStyleSheets.decodedSize, s.cssStyleSheets.purgeableSize, s.cssStyleSheets.purgedSize);
    printf("%-13s %13d %13d %13d %13d %13d %13d\n", "JavaScript", s.scripts.count, s.scripts.size, s.scripts.liveSize, s.scripts.decodedSize, s.scripts.purgeableSize, s.scripts.purgedSize);
    printf("%-13s %13d %13d %13d %13d %13d %13d\n", "Fonts", s.fonts.count, s.fonts.size, s.fonts.liveSize, s.fonts.decodedSize, s.fonts.purgeableSize, s.fonts.purgedSize);
    printf("%-13s %13d %13d %13d %13d %13d %13d\n", "Other", s.other.count, s.other.size, s.other.liveSize, s.other.decodedSize, s.other.purgeableSize, s.other.purgedSize);
    printf("%-13s %-13s %-13s %-13s %-13s %-13s %-13s\n\n", "-------------", "-------------", "-------------", "-------------", "-------------", "-------------", "-------------");

    printf("Duplication of encoded data from data URLs\n");
    printf("%-13s %13d of %13d\n", "Images",     s.images.encodedSizeDuplicatedInDataURLs,         s.images.encodedSize);
    printf("%-13s %13d of %13d\n", "CSS",        s.cssStyleSheets.encodedSizeDuplicatedInDataURLs, s.cssStyleSheets.encodedSize);
    printf("%-13s %13d of %13d\n", "JavaScript", s.scripts.encodedSizeDuplicatedInDataURLs,        s.scripts.encodedSize);
    printf("%-13s %13d of %13d\n", "Fonts",      s.fonts.encodedSizeDuplicatedInDataURLs,          s.fonts.encodedSize);
    printf("%-13s %13d of %13d\n", "Other",      s.other.encodedSizeDuplicatedInDataURLs,          s.other.encodedSize);
}

void MemoryCache::dumpLRULists(bool includeLive) const
{
    printf("LRU-SP lists in eviction order (Kilobytes decoded, Kilobytes encoded, Access count, Referenced, isPurgeable, wasPurged):\n");

    int size = m_allResources.size();
    for (int i = size - 1; i >= 0; i--) {
        printf("\n\nList %d: ", i);
        Resource* current = m_allResources[i].m_tail;
        while (current) {
            Resource* prev = current->m_prevInAllResourcesList;
            if (includeLive || !current->hasClients())
                printf("(%.1fK, %.1fK, %uA, %dR, %d, %d); ", current->decodedSize() / 1024.0f, (current->encodedSize() + current->overheadSize()) / 1024.0f, current->accessCount(), current->hasClients(), current->isPurgeable(), current->wasPurged());

            current = prev;
        }
    }
}

#endif // MEMORY_CACHE_STATS

} // namespace blink
