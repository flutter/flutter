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

#ifndef ImageDecodingStore_h
#define ImageDecodingStore_h

#include "SkSize.h"
#include "SkTypes.h"
#include "platform/PlatformExport.h"
#include "platform/graphics/skia/SkSizeHash.h"
#include "platform/image-decoders/ImageDecoder.h"

#include "wtf/DoublyLinkedList.h"
#include "wtf/HashSet.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/ThreadingPrimitives.h"
#include "wtf/Vector.h"

namespace blink {

class ImageFrameGenerator;

// FUNCTION
//
// ImageDecodingStore is a class used to manage cached decoder objects.
//
// EXTERNAL OBJECTS
//
// ImageDecoder
//   A decoder object. It is used to decode raw data into bitmap images.
//
// ImageFrameGenerator
//   This is a direct user of this cache. Responsible for generating bitmap images
//   using an ImageDecoder. It contains encoded image data and is used to represent
//   one image file. It is used to index image and decoder objects in the cache.
//
// THREAD SAFETY
//
// All public methods can be used on any thread.

class PLATFORM_EXPORT ImageDecodingStore {
public:
    static PassOwnPtr<ImageDecodingStore> create() { return adoptPtr(new ImageDecodingStore); }
    ~ImageDecodingStore();

    static ImageDecodingStore* instance();

    // Access a cached decoder object. A decoder is indexed by origin (ImageFrameGenerator)
    // and scaled size. Return true if the cached object is found.
    bool lockDecoder(const ImageFrameGenerator*, const SkISize& scaledSize, ImageDecoder**);
    void unlockDecoder(const ImageFrameGenerator*, const ImageDecoder*);
    void insertDecoder(const ImageFrameGenerator*, PassOwnPtr<ImageDecoder>);
    void removeDecoder(const ImageFrameGenerator*, const ImageDecoder*);

    // Remove all cache entries indexed by ImageFrameGenerator.
    void removeCacheIndexedByGenerator(const ImageFrameGenerator*);

    void clear();
    void setCacheLimitInBytes(size_t);
    size_t memoryUsageInBytes();
    int cacheEntries();
    int decoderCacheEntries();

private:
    // Decoder cache entry is identified by:
    // 1. Pointer to ImageFrameGenerator.
    // 2. Size of the image.
    typedef std::pair<const ImageFrameGenerator*, SkISize> DecoderCacheKey;

    // Base class for all cache entries.
    class CacheEntry : public DoublyLinkedListNode<CacheEntry> {
        friend class WTF::DoublyLinkedListNode<CacheEntry>;
    public:
        enum CacheType {
            TypeDecoder,
        };

        CacheEntry(const ImageFrameGenerator* generator, int useCount)
            : m_generator(generator)
            , m_useCount(useCount)
            , m_prev(0)
            , m_next(0)
        {
        }

        virtual ~CacheEntry()
        {
            ASSERT(!m_useCount);
        }

        const ImageFrameGenerator* generator() const { return m_generator; }
        int useCount() const { return m_useCount; }
        void incrementUseCount() { ++m_useCount; }
        void decrementUseCount() { --m_useCount; ASSERT(m_useCount >= 0); }

        // FIXME: getSafeSize() returns size in bytes truncated to a 32-bits integer.
        //        Find a way to get the size in 64-bits.
        virtual size_t memoryUsageInBytes() const = 0;
        virtual CacheType type() const = 0;

    protected:
        const ImageFrameGenerator* m_generator;
        int m_useCount;

    private:
        CacheEntry* m_prev;
        CacheEntry* m_next;
    };

    class DecoderCacheEntry final : public CacheEntry {
    public:
        static PassOwnPtr<DecoderCacheEntry> create(const ImageFrameGenerator* generator, PassOwnPtr<ImageDecoder> decoder)
        {
            return adoptPtr(new DecoderCacheEntry(generator, 0, decoder));
        }

        DecoderCacheEntry(const ImageFrameGenerator* generator, int count, PassOwnPtr<ImageDecoder> decoder)
            : CacheEntry(generator, count)
            , m_cachedDecoder(decoder)
            , m_size(SkISize::Make(m_cachedDecoder->decodedSize().width(), m_cachedDecoder->decodedSize().height()))
        {
        }

        virtual size_t memoryUsageInBytes() const override { return m_size.width() * m_size.height() * 4; }
        virtual CacheType type() const override { return TypeDecoder; }

        static DecoderCacheKey makeCacheKey(const ImageFrameGenerator* generator, const SkISize& size)
        {
            return std::make_pair(generator, size);
        }
        static DecoderCacheKey makeCacheKey(const ImageFrameGenerator* generator, const ImageDecoder* decoder)
        {
            return std::make_pair(generator, SkISize::Make(decoder->decodedSize().width(), decoder->decodedSize().height()));
        }
        DecoderCacheKey cacheKey() const { return makeCacheKey(m_generator, m_size); }
        ImageDecoder* cachedDecoder() const { return m_cachedDecoder.get(); }

    private:
        OwnPtr<ImageDecoder> m_cachedDecoder;
        SkISize m_size;
    };

    ImageDecodingStore();

    void prune();

    // These helper methods are called while m_mutex is locked.
    template<class T, class U, class V> void insertCacheInternal(PassOwnPtr<T> cacheEntry, U* cacheMap, V* identifierMap);

    // Helper method to remove a cache entry. Ownership is transferred to
    // deletionList. Use of Vector<> is handy when removing multiple entries.
    template<class T, class U, class V> void removeFromCacheInternal(const T* cacheEntry, U* cacheMap, V* identifierMap, Vector<OwnPtr<CacheEntry> >* deletionList);

    // Helper method to remove a cache entry. Uses the templated version base on
    // the type of cache entry.
    void removeFromCacheInternal(const CacheEntry*, Vector<OwnPtr<CacheEntry> >* deletionList);

    // Helper method to remove all cache entries associated with a ImageFraneGenerator.
    // Ownership of cache entries is transferred to deletionList.
    template<class U, class V> void removeCacheIndexedByGeneratorInternal(U* cacheMap, V* identifierMap, const ImageFrameGenerator*, Vector<OwnPtr<CacheEntry> >* deletionList);

    // Helper method to remove cache entry pointers from the LRU list.
    void removeFromCacheListInternal(const Vector<OwnPtr<CacheEntry> >& deletionList);

    // A doubly linked list that maintains usage history of cache entries.
    // This is used for eviction of old entries.
    // Head of this list is the least recently used cache entry.
    // Tail of this list is the most recently used cache entry.
    DoublyLinkedList<CacheEntry> m_orderedCacheList;

    // A lookup table for all decoder cache objects. Owns all decoder cache objects.
    typedef HashMap<DecoderCacheKey, OwnPtr<DecoderCacheEntry> > DecoderCacheMap;
    DecoderCacheMap m_decoderCacheMap;

    // A lookup table to map ImageFrameGenerator to all associated
    // decoder cache keys.
    typedef HashSet<DecoderCacheKey> DecoderCacheKeySet;
    typedef HashMap<const ImageFrameGenerator*, DecoderCacheKeySet> DecoderCacheKeyMap;
    DecoderCacheKeyMap m_decoderCacheKeyMap;

    size_t m_heapLimitInBytes;
    size_t m_heapMemoryUsageInBytes;

    // Protect concurrent access to these members:
    //   m_orderedCacheList
    //   m_decoderCacheMap and all CacheEntrys stored in it
    //   m_decoderCacheKeyMap
    //   m_heapLimitInBytes
    //   m_heapMemoryUsageInBytes
    // This mutex also protects calls to underlying skBitmap's
    // lockPixels()/unlockPixels() as they are not threadsafe.
    Mutex m_mutex;
};

} // namespace blink

#endif
