/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/graphics/ImageDecodingStore.h"

#include "platform/TraceEvent.h"
#include "wtf/Threading.h"

namespace blink {

namespace {

static const size_t defaultMaxTotalSizeOfHeapEntries = 32 * 1024 * 1024;

} // namespace

ImageDecodingStore::ImageDecodingStore()
    : m_heapLimitInBytes(defaultMaxTotalSizeOfHeapEntries)
    , m_heapMemoryUsageInBytes(0)
{
}

ImageDecodingStore::~ImageDecodingStore()
{
#if ENABLE(ASSERT)
    setCacheLimitInBytes(0);
    ASSERT(!m_decoderCacheMap.size());
    ASSERT(!m_orderedCacheList.size());
    ASSERT(!m_decoderCacheKeyMap.size());
#endif
}

ImageDecodingStore* ImageDecodingStore::instance()
{
    AtomicallyInitializedStatic(ImageDecodingStore*, store = ImageDecodingStore::create().leakPtr());
    return store;
}

bool ImageDecodingStore::lockDecoder(const ImageFrameGenerator* generator, const SkISize& scaledSize, ImageDecoder** decoder)
{
    ASSERT(decoder);

    MutexLocker lock(m_mutex);
    DecoderCacheMap::iterator iter = m_decoderCacheMap.find(DecoderCacheEntry::makeCacheKey(generator, scaledSize));
    if (iter == m_decoderCacheMap.end())
        return false;

    DecoderCacheEntry* cacheEntry = iter->value.get();

    // There can only be one user of a decoder at a time.
    ASSERT(!cacheEntry->useCount());
    cacheEntry->incrementUseCount();
    *decoder = cacheEntry->cachedDecoder();
    return true;
}

void ImageDecodingStore::unlockDecoder(const ImageFrameGenerator* generator, const ImageDecoder* decoder)
{
    MutexLocker lock(m_mutex);
    DecoderCacheMap::iterator iter = m_decoderCacheMap.find(DecoderCacheEntry::makeCacheKey(generator, decoder));
    ASSERT_WITH_SECURITY_IMPLICATION(iter != m_decoderCacheMap.end());

    CacheEntry* cacheEntry = iter->value.get();
    cacheEntry->decrementUseCount();

    // Put the entry to the end of list.
    m_orderedCacheList.remove(cacheEntry);
    m_orderedCacheList.append(cacheEntry);
}

void ImageDecodingStore::insertDecoder(const ImageFrameGenerator* generator, PassOwnPtr<ImageDecoder> decoder)
{
    // Prune old cache entries to give space for the new one.
    prune();

    OwnPtr<DecoderCacheEntry> newCacheEntry = DecoderCacheEntry::create(generator, decoder);

    MutexLocker lock(m_mutex);
    ASSERT(!m_decoderCacheMap.contains(newCacheEntry->cacheKey()));
    insertCacheInternal(newCacheEntry.release(), &m_decoderCacheMap, &m_decoderCacheKeyMap);
}

void ImageDecodingStore::removeDecoder(const ImageFrameGenerator* generator, const ImageDecoder* decoder)
{
    Vector<OwnPtr<CacheEntry> > cacheEntriesToDelete;
    {
        MutexLocker lock(m_mutex);
        DecoderCacheMap::iterator iter = m_decoderCacheMap.find(DecoderCacheEntry::makeCacheKey(generator, decoder));
        ASSERT_WITH_SECURITY_IMPLICATION(iter != m_decoderCacheMap.end());

        CacheEntry* cacheEntry = iter->value.get();
        ASSERT(cacheEntry->useCount());
        cacheEntry->decrementUseCount();

        // Delete only one decoder cache entry. Ownership of the cache entry
        // is transfered to cacheEntriesToDelete such that object can be deleted
        // outside of the lock.
        removeFromCacheInternal(cacheEntry, &cacheEntriesToDelete);

        // Remove from LRU list.
        removeFromCacheListInternal(cacheEntriesToDelete);
    }
}

void ImageDecodingStore::removeCacheIndexedByGenerator(const ImageFrameGenerator* generator)
{
    Vector<OwnPtr<CacheEntry> > cacheEntriesToDelete;
    {
        MutexLocker lock(m_mutex);

        // Remove image cache objects and decoder cache objects associated
        // with a ImageFrameGenerator.
        removeCacheIndexedByGeneratorInternal(&m_decoderCacheMap, &m_decoderCacheKeyMap, generator, &cacheEntriesToDelete);

        // Remove from LRU list as well.
        removeFromCacheListInternal(cacheEntriesToDelete);
    }
}

void ImageDecodingStore::clear()
{
    size_t cacheLimitInBytes;
    {
        MutexLocker lock(m_mutex);
        cacheLimitInBytes = m_heapLimitInBytes;
        m_heapLimitInBytes = 0;
    }

    prune();

    {
        MutexLocker lock(m_mutex);
        m_heapLimitInBytes = cacheLimitInBytes;
    }
}

void ImageDecodingStore::setCacheLimitInBytes(size_t cacheLimit)
{
    {
        MutexLocker lock(m_mutex);
        m_heapLimitInBytes = cacheLimit;
    }
    prune();
}

size_t ImageDecodingStore::memoryUsageInBytes()
{
    MutexLocker lock(m_mutex);
    return m_heapMemoryUsageInBytes;
}

int ImageDecodingStore::cacheEntries()
{
    MutexLocker lock(m_mutex);
    return m_decoderCacheMap.size();
}

int ImageDecodingStore::decoderCacheEntries()
{
    MutexLocker lock(m_mutex);
    return m_decoderCacheMap.size();
}

void ImageDecodingStore::prune()
{
    TRACE_EVENT0(TRACE_DISABLED_BY_DEFAULT("blink.image_decoding"), "ImageDecodingStore::prune");

    Vector<OwnPtr<CacheEntry> > cacheEntriesToDelete;
    {
        MutexLocker lock(m_mutex);

        // Head of the list is the least recently used entry.
        const CacheEntry* cacheEntry = m_orderedCacheList.head();

        // Walk the list of cache entries starting from the least recently used
        // and then keep them for deletion later.
        while (cacheEntry) {
            const bool isPruneNeeded = m_heapMemoryUsageInBytes > m_heapLimitInBytes || !m_heapLimitInBytes;
            if (!isPruneNeeded)
                break;

            // Cache is not used; Remove it.
            if (!cacheEntry->useCount())
                removeFromCacheInternal(cacheEntry, &cacheEntriesToDelete);
            cacheEntry = cacheEntry->next();
        }

        // Remove from cache list as well.
        removeFromCacheListInternal(cacheEntriesToDelete);
    }
}

template<class T, class U, class V>
void ImageDecodingStore::insertCacheInternal(PassOwnPtr<T> cacheEntry, U* cacheMap, V* identifierMap)
{
    const size_t cacheEntryBytes = cacheEntry->memoryUsageInBytes();
    m_heapMemoryUsageInBytes += cacheEntryBytes;

    // m_orderedCacheList is used to support LRU operations to reorder cache
    // entries quickly.
    m_orderedCacheList.append(cacheEntry.get());

    typename U::KeyType key = cacheEntry->cacheKey();
    typename V::AddResult result = identifierMap->add(cacheEntry->generator(), typename V::MappedType());
    result.storedValue->value.add(key);
    cacheMap->add(key, cacheEntry);

    TRACE_COUNTER1(TRACE_DISABLED_BY_DEFAULT("blink.image_decoding"), "ImageDecodingStoreHeapMemoryUsageBytes", m_heapMemoryUsageInBytes);
    TRACE_COUNTER1(TRACE_DISABLED_BY_DEFAULT("blink.image_decoding"), "ImageDecodingStoreNumOfDecoders", m_decoderCacheMap.size());
}

template<class T, class U, class V>
void ImageDecodingStore::removeFromCacheInternal(const T* cacheEntry, U* cacheMap, V* identifierMap, Vector<OwnPtr<CacheEntry> >* deletionList)
{
    const size_t cacheEntryBytes = cacheEntry->memoryUsageInBytes();
    ASSERT(m_heapMemoryUsageInBytes >= cacheEntryBytes);
    m_heapMemoryUsageInBytes -= cacheEntryBytes;

    // Remove entry from identifier map.
    typename V::iterator iter = identifierMap->find(cacheEntry->generator());
    ASSERT(iter != identifierMap->end());
    iter->value.remove(cacheEntry->cacheKey());
    if (!iter->value.size())
        identifierMap->remove(iter);

    // Remove entry from cache map.
    deletionList->append(cacheMap->take(cacheEntry->cacheKey()));

    TRACE_COUNTER1(TRACE_DISABLED_BY_DEFAULT("blink.image_decoding"), "ImageDecodingStoreHeapMemoryUsageBytes", m_heapMemoryUsageInBytes);
    TRACE_COUNTER1(TRACE_DISABLED_BY_DEFAULT("blink.image_decoding"), "ImageDecodingStoreNumOfDecoders", m_decoderCacheMap.size());
}

void ImageDecodingStore::removeFromCacheInternal(const CacheEntry* cacheEntry, Vector<OwnPtr<CacheEntry> >* deletionList)
{
    if (cacheEntry->type() == CacheEntry::TypeDecoder) {
        removeFromCacheInternal(static_cast<const DecoderCacheEntry*>(cacheEntry), &m_decoderCacheMap, &m_decoderCacheKeyMap, deletionList);
    } else {
        ASSERT(false);
    }
}

template<class U, class V>
void ImageDecodingStore::removeCacheIndexedByGeneratorInternal(U* cacheMap, V* identifierMap, const ImageFrameGenerator* generator, Vector<OwnPtr<CacheEntry> >* deletionList)
{
    typename V::iterator iter = identifierMap->find(generator);
    if (iter == identifierMap->end())
        return;

    // Get all cache identifiers associated with generator.
    Vector<typename U::KeyType> cacheIdentifierList;
    copyToVector(iter->value, cacheIdentifierList);

    // For each cache identifier find the corresponding CacheEntry and remove it.
    for (size_t i = 0; i < cacheIdentifierList.size(); ++i) {
        ASSERT(cacheMap->contains(cacheIdentifierList[i]));
        const typename U::MappedType::PtrType cacheEntry = cacheMap->get(cacheIdentifierList[i]);
        ASSERT(!cacheEntry->useCount());
        removeFromCacheInternal(cacheEntry, cacheMap, identifierMap, deletionList);
    }
}

void ImageDecodingStore::removeFromCacheListInternal(const Vector<OwnPtr<CacheEntry> >& deletionList)
{
    for (size_t i = 0; i < deletionList.size(); ++i)
        m_orderedCacheList.remove(deletionList[i].get());
}

} // namespace blink
