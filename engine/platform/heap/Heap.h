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

#ifndef Heap_h
#define Heap_h

#include "platform/PlatformExport.h"
#include "platform/heap/AddressSanitizer.h"
#include "platform/heap/ThreadState.h"
#include "platform/heap/Visitor.h"
#include "public/platform/WebThread.h"
#include "wtf/Assertions.h"
#include "wtf/HashCountedSet.h"
#include "wtf/LinkedHashSet.h"
#include "wtf/ListHashSet.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassRefPtr.h"
#include "wtf/ThreadSafeRefCounted.h"

#include <stdint.h>

namespace blink {

const size_t blinkPageSizeLog2 = 17;
const size_t blinkPageSize = 1 << blinkPageSizeLog2;
const size_t blinkPageOffsetMask = blinkPageSize - 1;
const size_t blinkPageBaseMask = ~blinkPageOffsetMask;

// We allocate pages at random addresses but in groups of
// blinkPagesPerRegion at a given random address. We group pages to
// not spread out too much over the address space which would blow
// away the page tables and lead to bad performance.
const size_t blinkPagesPerRegion = 10;

// Double precision floats are more efficient when 8 byte aligned, so we 8 byte
// align all allocations even on 32 bit.
const size_t allocationGranularity = 8;
const size_t allocationMask = allocationGranularity - 1;
const size_t objectStartBitMapSize = (blinkPageSize + ((8 * allocationGranularity) - 1)) / (8 * allocationGranularity);
const size_t reservedForObjectBitMap = ((objectStartBitMapSize + allocationMask) & ~allocationMask);
const size_t maxHeapObjectSizeLog2 = 27;
const size_t maxHeapObjectSize = 1 << maxHeapObjectSizeLog2;

const size_t markBitMask = 1;
const size_t freeListMask = 2;
// The dead bit is used for objects that have gone through a GC marking, but did
// not get swept before a new GC started. In that case we set the dead bit on
// objects that were not marked in the previous GC to ensure we are not tracing
// them via a conservatively found pointer. Tracing dead objects could lead to
// tracing of already finalized objects in another thread's heap which is a
// use-after-free situation.
const size_t deadBitMask = 4;
// On free-list entries we reuse the dead bit to distinguish a normal free-list
// entry from one that has been promptly freed.
const size_t promptlyFreedMask = freeListMask | deadBitMask;
#if ENABLE(GC_PROFILE_HEAP)
const size_t heapObjectGenerations = 8;
const size_t maxHeapObjectAge = heapObjectGenerations - 1;
const size_t heapObjectAgeMask = ~(maxHeapObjectSize - 1);
const size_t sizeMask = ~heapObjectAgeMask & ~static_cast<size_t>(7);
#else
const size_t sizeMask = ~static_cast<size_t>(7);
#endif
const uint8_t freelistZapValue = 42;
const uint8_t finalizedZapValue = 24;
// The orphaned zap value must be zero in the lowest bits to allow for using
// the mark bit when tracing.
const uint8_t orphanedZapValue = 240;

const int numberOfMarkingThreads = 2;

const int numberOfPagesToConsiderForCoalescing = 100;

enum CallbackInvocationMode {
    GlobalMarking,
    ThreadLocalMarking,
    PostMarking,
    WeaknessProcessing,
};

class HeapStats;
class PageMemory;
template<ThreadAffinity affinity> class ThreadLocalPersistents;
template<typename T, typename RootsAccessor = ThreadLocalPersistents<ThreadingTrait<T>::Affinity > > class Persistent;

#if ENABLE(GC_PROFILE_HEAP)
class TracedValue;
#endif

PLATFORM_EXPORT size_t osPageSize();

// Blink heap pages are set up with a guard page before and after the
// payload.
inline size_t blinkPagePayloadSize()
{
    return blinkPageSize - 2 * osPageSize();
}

// Blink heap pages are aligned to the Blink heap page size.
// Therefore, the start of a Blink page can be obtained by
// rounding down to the Blink page size.
inline Address roundToBlinkPageStart(Address address)
{
    return reinterpret_cast<Address>(reinterpret_cast<uintptr_t>(address) & blinkPageBaseMask);
}

inline Address roundToBlinkPageEnd(Address address)
{
    return reinterpret_cast<Address>(reinterpret_cast<uintptr_t>(address - 1) & blinkPageBaseMask) + blinkPageSize;
}

// Compute the amount of padding we have to add to a header to make
// the size of the header plus the padding a multiple of 8 bytes.
template<typename Header>
inline size_t headerPadding()
{
    return (allocationGranularity - (sizeof(Header) % allocationGranularity)) % allocationGranularity;
}

// Masks an address down to the enclosing blink page base address.
inline Address blinkPageAddress(Address address)
{
    return reinterpret_cast<Address>(reinterpret_cast<uintptr_t>(address) & blinkPageBaseMask);
}

#if ENABLE(ASSERT)

// Sanity check for a page header address: the address of the page
// header should be OS page size away from being Blink page size
// aligned.
inline bool isPageHeaderAddress(Address address)
{
    return !((reinterpret_cast<uintptr_t>(address) & blinkPageOffsetMask) - osPageSize());
}
#endif

// Mask an address down to the enclosing oilpan heap base page.
// All oilpan heap pages are aligned at blinkPageBase plus an OS page size.
// FIXME: Remove PLATFORM_EXPORT once we get a proper public interface to our typed heaps.
// This is only exported to enable tests in HeapTest.cpp.
PLATFORM_EXPORT inline BaseHeapPage* pageHeaderFromObject(const void* object)
{
    Address address = reinterpret_cast<Address>(const_cast<void*>(object));
    return reinterpret_cast<BaseHeapPage*>(blinkPageAddress(address) + osPageSize());
}

// Large allocations are allocated as separate objects and linked in a
// list.
//
// In order to use the same memory allocation routines for everything
// allocated in the heap, large objects are considered heap pages
// containing only one object.
//
// The layout of a large heap object is as follows:
//
// | BaseHeapPage | next pointer | FinalizedHeapObjectHeader or HeapObjectHeader | payload |
template<typename Header>
class LargeHeapObject : public BaseHeapPage {
public:
    LargeHeapObject(PageMemory* storage, const GCInfo* gcInfo, ThreadState* state) : BaseHeapPage(storage, gcInfo, state)
    {
        COMPILE_ASSERT(!(sizeof(LargeHeapObject<Header>) & allocationMask), large_heap_object_header_misaligned);
    }

    virtual void checkAndMarkPointer(Visitor*, Address) override;
    virtual bool isLargeObject() override { return true; }

#if ENABLE(GC_PROFILE_MARKING)
    virtual const GCInfo* findGCInfo(Address address)
    {
        if (!objectContains(address))
            return 0;
        return gcInfo();
    }
#endif

#if ENABLE(GC_PROFILE_HEAP)
    void snapshot(TracedValue*, ThreadState::SnapshotInfo*);
#endif

    void link(LargeHeapObject<Header>** previousNext)
    {
        m_next = *previousNext;
        *previousNext = this;
    }

    void unlink(LargeHeapObject<Header>** previousNext)
    {
        *previousNext = m_next;
    }

    // The LargeHeapObject pseudo-page contains one actual object. Determine
    // whether the pointer is within that object.
    bool objectContains(Address object)
    {
        return (payload() <= object) && (object < address() + size());
    }

    // Returns true for any address that is on one of the pages that this
    // large object uses. That ensures that we can use a negative result to
    // populate the negative page cache.
    virtual bool contains(Address object) override
    {
        return roundToBlinkPageStart(address()) <= object && object < roundToBlinkPageEnd(address() + size());
    }

    LargeHeapObject<Header>* next()
    {
        return m_next;
    }

    size_t size()
    {
        return heapObjectHeader()->size() + sizeof(LargeHeapObject<Header>) + headerPadding<Header>();
    }

    Address payload() { return heapObjectHeader()->payload(); }
    size_t payloadSize() { return heapObjectHeader()->payloadSize(); }

    Header* heapObjectHeader()
    {
        Address headerAddress = address() + sizeof(LargeHeapObject<Header>) + headerPadding<Header>();
        return reinterpret_cast<Header*>(headerAddress);
    }

    bool isMarked();
    void unmark();
    void getStats(HeapStats&);
    void mark(Visitor*);
    void finalize();
    void setDeadMark();
    virtual void markOrphaned()
    {
        // Zap the payload with a recognizable value to detect any incorrect
        // cross thread pointer usage.
        memset(payload(), orphanedZapValue, payloadSize());
        BaseHeapPage::markOrphaned();
    }

private:
    friend class ThreadHeap<Header>;

    LargeHeapObject<Header>* m_next;
};

// The BasicObjectHeader is the minimal object header. It is used when
// encountering heap space of size allocationGranularity to mark it as
// as freelist entry.
class PLATFORM_EXPORT BasicObjectHeader {
public:
    NO_SANITIZE_ADDRESS
    explicit BasicObjectHeader(size_t encodedSize)
        : m_size(encodedSize) { }

    static size_t freeListEncodedSize(size_t size) { return size | freeListMask; }

    NO_SANITIZE_ADDRESS
    bool isFree() { return m_size & freeListMask; }

    NO_SANITIZE_ADDRESS
    bool isPromptlyFreed() { return (m_size & promptlyFreedMask) == promptlyFreedMask; }

    NO_SANITIZE_ADDRESS
    void markPromptlyFreed() { m_size |= promptlyFreedMask; }

    NO_SANITIZE_ADDRESS
    size_t size() const { return m_size & sizeMask; }

#if ENABLE(GC_PROFILE_HEAP)
    NO_SANITIZE_ADDRESS
    size_t encodedSize() const { return m_size; }

    NO_SANITIZE_ADDRESS
    size_t age() const { return m_size >> maxHeapObjectSizeLog2; }

    NO_SANITIZE_ADDRESS
    void incAge()
    {
        size_t current = age();
        if (current < maxHeapObjectAge)
            m_size = ((current + 1) << maxHeapObjectSizeLog2) | (m_size & ~heapObjectAgeMask);
    }
#endif

protected:
    volatile unsigned m_size;
};

// Our heap object layout is layered with the HeapObjectHeader closest
// to the payload, this can be wrapped in a FinalizedObjectHeader if the
// object is on the GeneralHeap and not on a specific TypedHeap.
// Finally if the object is a large object (> blinkPageSize/2) then it is
// wrapped with a LargeObjectHeader.
//
// Object memory layout:
// [ LargeObjectHeader | ] [ FinalizedObjectHeader | ] HeapObjectHeader | payload
// The [ ] notation denotes that the LargeObjectHeader and the FinalizedObjectHeader
// are independently optional.
class PLATFORM_EXPORT HeapObjectHeader : public BasicObjectHeader {
public:
    NO_SANITIZE_ADDRESS
    explicit HeapObjectHeader(size_t encodedSize)
        : BasicObjectHeader(encodedSize)
#if ENABLE(ASSERT)
        , m_magic(magic)
#endif
    { }

    NO_SANITIZE_ADDRESS
    HeapObjectHeader(size_t encodedSize, const GCInfo*)
        : BasicObjectHeader(encodedSize)
#if ENABLE(ASSERT)
        , m_magic(magic)
#endif
    { }

    inline void checkHeader() const;
    inline bool isMarked() const;

    inline void mark();
    inline void unmark();

    inline const GCInfo* gcInfo() { return 0; }

    inline Address payload();
    inline size_t payloadSize();
    inline Address payloadEnd();

    inline void setDeadMark();
    inline void clearDeadMark();
    inline bool hasDeadMark() const;

    // Zap magic number with a new magic number that means there was once an
    // object allocated here, but it was freed because nobody marked it during
    // GC.
    void zapMagic();

    static void finalize(const GCInfo*, Address, size_t);
    static HeapObjectHeader* fromPayload(const void*);

    static const intptr_t magic = 0xc0de247;
    static const intptr_t zappedMagic = 0xC0DEdead;
    // The zap value for vtables should be < 4K to ensure it cannot be
    // used for dispatch.
    static const intptr_t zappedVTable = 0xd0d;

private:
#if ENABLE(ASSERT)
    intptr_t m_magic;
#endif
};

const size_t objectHeaderSize = sizeof(HeapObjectHeader);

// Each object on the GeneralHeap needs to carry a pointer to its
// own GCInfo structure for tracing and potential finalization.
class PLATFORM_EXPORT FinalizedHeapObjectHeader : public HeapObjectHeader {
public:
    NO_SANITIZE_ADDRESS
    FinalizedHeapObjectHeader(size_t encodedSize, const GCInfo* gcInfo)
        : HeapObjectHeader(encodedSize)
        , m_gcInfo(gcInfo)
    {
    }

    inline Address payload();
    inline size_t payloadSize();

    NO_SANITIZE_ADDRESS
    const GCInfo* gcInfo() { return m_gcInfo; }

    NO_SANITIZE_ADDRESS
    TraceCallback traceCallback() { return m_gcInfo->m_trace; }

    void finalize();

    NO_SANITIZE_ADDRESS
    inline bool hasFinalizer() { return m_gcInfo->hasFinalizer(); }

    static FinalizedHeapObjectHeader* fromPayload(const void*);

    NO_SANITIZE_ADDRESS
    bool hasVTable() { return m_gcInfo->hasVTable(); }

private:
    const GCInfo* m_gcInfo;
};

const size_t finalizedHeaderSize = sizeof(FinalizedHeapObjectHeader);

class FreeListEntry : public HeapObjectHeader {
public:
    NO_SANITIZE_ADDRESS
    explicit FreeListEntry(size_t size)
        : HeapObjectHeader(freeListEncodedSize(size))
        , m_next(0)
    {
#if ENABLE(ASSERT) && !defined(ADDRESS_SANITIZER)
        // Zap free area with asterisks, aka 0x2a2a2a2a.
        // For ASan don't zap since we keep accounting in the freelist entry.
        for (size_t i = sizeof(*this); i < size; i++)
            reinterpret_cast<Address>(this)[i] = freelistZapValue;
        ASSERT(size >= objectHeaderSize);
        zapMagic();
#endif
    }

    Address address() { return reinterpret_cast<Address>(this); }

    NO_SANITIZE_ADDRESS
    void unlink(FreeListEntry** prevNext)
    {
        *prevNext = m_next;
        m_next = 0;
    }

    NO_SANITIZE_ADDRESS
    void link(FreeListEntry** prevNext)
    {
        m_next = *prevNext;
        *prevNext = this;
    }

    NO_SANITIZE_ADDRESS
    FreeListEntry* next() const { return m_next; }

    NO_SANITIZE_ADDRESS
    void append(FreeListEntry* next)
    {
        ASSERT(!m_next);
        m_next = next;
    }

#if defined(ADDRESS_SANITIZER)
    NO_SANITIZE_ADDRESS
    bool shouldAddToFreeList()
    {
        // Init if not already magic.
        if ((m_asanMagic & ~asanDeferMemoryReuseMask) != asanMagic) {
            m_asanMagic = asanMagic | asanDeferMemoryReuseCount;
            return false;
        }
        // Decrement if count part of asanMagic > 0.
        if (m_asanMagic & asanDeferMemoryReuseMask)
            m_asanMagic--;
        return !(m_asanMagic & asanDeferMemoryReuseMask);
    }
#endif

private:
    FreeListEntry* m_next;
#if defined(ADDRESS_SANITIZER)
    unsigned m_asanMagic;
#endif
};

// Representation of Blink heap pages.
//
// Pages are specialized on the type of header on the object they
// contain. If a heap page only contains a certain type of object all
// of the objects will have the same GCInfo pointer and therefore that
// pointer can be stored in the HeapPage instead of in the header of
// each object. In that case objects have only a HeapObjectHeader and
// not a FinalizedHeapObjectHeader saving a word per object.
template<typename Header>
class HeapPage : public BaseHeapPage {
public:
    HeapPage(PageMemory*, ThreadHeap<Header>*, const GCInfo*);

    void link(HeapPage**);
    static void unlink(ThreadHeap<Header>*, HeapPage*, HeapPage**);

    bool isEmpty();

    // Returns true for the whole blinkPageSize page that the page is on, even
    // for the header, and the unmapped guard page at the start. That ensures
    // the result can be used to populate the negative page cache.
    virtual bool contains(Address addr) override
    {
        Address blinkPageStart = roundToBlinkPageStart(address());
        ASSERT(blinkPageStart == address() - osPageSize()); // Page is at aligned address plus guard page size.
        return blinkPageStart <= addr && addr < blinkPageStart + blinkPageSize;
    }

    HeapPage* next() { return m_next; }

    Address payload()
    {
        return address() + sizeof(*this) + headerPadding<Header>();
    }

    static size_t payloadSize()
    {
        return (blinkPagePayloadSize() - sizeof(HeapPage) - headerPadding<Header>()) & ~allocationMask;
    }

    Address end() { return payload() + payloadSize(); }

    void getStats(HeapStats&);
    void clearLiveAndMarkDead();
    void sweep(HeapStats*, ThreadHeap<Header>*);
    void clearObjectStartBitMap();
    void finalize(Header*);
    virtual void checkAndMarkPointer(Visitor*, Address) override;
#if ENABLE(GC_PROFILE_MARKING)
    const GCInfo* findGCInfo(Address) override;
#endif
#if ENABLE(GC_PROFILE_HEAP)
    virtual void snapshot(TracedValue*, ThreadState::SnapshotInfo*);
#endif

#if defined(ADDRESS_SANITIZER)
    void poisonUnmarkedObjects();
#endif
    NO_SANITIZE_ADDRESS
    virtual void markOrphaned()
    {
        // Zap the payload with a recognizable value to detect any incorrect
        // cross thread pointer usage.
#if defined(ADDRESS_SANITIZER)
        // Don't use memset when running with ASan since this needs to zap
        // poisoned memory as well and the NO_SANITIZE_ADDRESS annotation
        // only works for code in this method and not for calls to memset.
        for (Address current = payload(); current < payload() + payloadSize(); ++current)
            *current = orphanedZapValue;
#else
        memset(payload(), orphanedZapValue, payloadSize());
#endif
        BaseHeapPage::markOrphaned();
    }

protected:
    Header* findHeaderFromAddress(Address);
    void populateObjectStartBitMap();
    bool isObjectStartBitMapComputed() { return m_objectStartBitMapComputed; }
    TraceCallback traceCallback(Header*);
    bool hasVTable(Header*);

    intptr_t padding() const { return m_padding; }

    HeapPage<Header>* m_next;
    intptr_t m_padding; // Preserve 8-byte alignment on 32-bit systems.
    bool m_objectStartBitMapComputed;
    uint8_t m_objectStartBitMap[reservedForObjectBitMap];

    friend class ThreadHeap<Header>;
};

class AddressEntry {
public:
    AddressEntry() : m_address(0) { }

    explicit AddressEntry(Address address) : m_address(address) { }

    Address address() const { return m_address; }

private:
    Address m_address;
};

class PositiveEntry : public AddressEntry {
public:
    PositiveEntry()
        : AddressEntry()
        , m_containingPage(0)
    {
    }

    PositiveEntry(Address address, BaseHeapPage* containingPage)
        : AddressEntry(address)
        , m_containingPage(containingPage)
    {
    }

    BaseHeapPage* result() const { return m_containingPage; }

    typedef BaseHeapPage* LookupResult;

private:
    BaseHeapPage* m_containingPage;
};

class NegativeEntry : public AddressEntry {
public:
    NegativeEntry() : AddressEntry() { }

    NegativeEntry(Address address, bool) : AddressEntry(address) { }

    bool result() const { return true; }

    typedef bool LookupResult;
};

// A HeapExtentCache provides a fast way of taking an arbitrary
// pointer-sized word, and determining whether it can be interpreted
// as a pointer to an area that is managed by the garbage collected
// Blink heap. There is a cache of 'pages' that have previously been
// determined to be wholly inside the heap. The size of these pages must be
// smaller than the allocation alignment of the heap pages. We determine
// on-heap-ness by rounding down the pointer to the nearest page and looking up
// the page in the cache. If there is a miss in the cache we can ask the heap
// to determine the status of the pointer by iterating over all of the heap.
// The result is then cached in the two-way associative page cache.
//
// A HeapContainsCache is a positive cache. Therefore, it must be flushed when
// memory is removed from the Blink heap. The HeapDoesNotContainCache is a
// negative cache, so it must be flushed when memory is added to the heap.
template<typename Entry>
class HeapExtentCache {
public:
    HeapExtentCache()
        : m_entries(adoptArrayPtr(new Entry[HeapExtentCache::numberOfEntries]))
        , m_hasEntries(false)
    {
    }

    void flush();
    bool contains(Address);
    bool isEmpty() { return !m_hasEntries; }

    // Perform a lookup in the cache.
    //
    // If lookup returns null/false the argument address was not found in
    // the cache and it is unknown if the address is in the Blink
    // heap.
    //
    // If lookup returns true/a page, the argument address was found in the
    // cache. For the HeapContainsCache this means the address is in the heap.
    // For the HeapDoesNotContainCache this means the address is not in the
    // heap.
    PLATFORM_EXPORT typename Entry::LookupResult lookup(Address);

    // Add an entry to the cache.
    PLATFORM_EXPORT void addEntry(Address, typename Entry::LookupResult);

private:
    static const int numberOfEntriesLog2 = 12;
    static const int numberOfEntries = 1 << numberOfEntriesLog2;

    static size_t hash(Address);

    WTF::OwnPtr<Entry[]> m_entries;
    bool m_hasEntries;

    friend class ThreadState;
};

// Normally these would be typedefs instead of subclasses, but that makes them
// very hard to forward declare.
class HeapContainsCache : public HeapExtentCache<PositiveEntry> {
public:
    BaseHeapPage* lookup(Address);
    void addEntry(Address, BaseHeapPage*);
};

class HeapDoesNotContainCache : public HeapExtentCache<NegativeEntry> { };

template<typename DataType>
class PagePool {
protected:
    PagePool();

    class PoolEntry {
    public:
        PoolEntry(DataType* data, PoolEntry* next)
            : data(data)
            , next(next)
        { }

        DataType* data;
        PoolEntry* next;
    };

    PoolEntry* m_pool[NumberOfHeaps];
};

// Once pages have been used for one type of thread heap they will never be
// reused for another type of thread heap. Instead of unmapping, we add the
// pages to a pool of pages to be reused later by a thread heap of the same
// type. This is done as a security feature to avoid type confusion. The
// heaps are type segregated by having separate thread heaps for different
// types of objects. Holding on to pages ensures that the same virtual address
// space cannot be used for objects of another type than the type contained
// in this page to begin with.
class FreePagePool : public PagePool<PageMemory> {
public:
    ~FreePagePool();
    void addFreePage(int, PageMemory*);
    PageMemory* takeFreePage(int);

private:
    Mutex m_mutex[NumberOfHeaps];
};

class OrphanedPagePool : public PagePool<BaseHeapPage> {
public:
    ~OrphanedPagePool();
    void addOrphanedPage(int, BaseHeapPage*);
    void decommitOrphanedPages();
#if ENABLE(ASSERT)
    bool contains(void*);
#endif
private:
    void clearMemory(PageMemory*);
};

// The CallbackStack contains all the visitor callbacks used to trace and mark
// objects. A specific CallbackStack instance contains at most bufferSize elements.
// If more space is needed a new CallbackStack instance is created and chained
// together with the former instance. I.e. a logical CallbackStack can be made of
// multiple chained CallbackStack object instances.
// There are two logical callback stacks. One containing all the marking callbacks and
// one containing the weak pointer callbacks.
class CallbackStack {
public:
    CallbackStack(CallbackStack** first)
        : m_limit(&(m_buffer[bufferSize]))
        , m_current(&(m_buffer[0]))
        , m_next(*first)
    {
#if ENABLE(ASSERT)
        clearUnused();
#endif
        *first = this;
    }

    ~CallbackStack();
    void clearUnused();

    bool isEmpty();

    CallbackStack* takeCallbacks(CallbackStack** first);

    class Item {
    public:
        Item() { }
        Item(void* object, VisitorCallback callback)
            : m_object(object)
            , m_callback(callback)
        {
        }
        void* object() { return m_object; }
        VisitorCallback callback() { return m_callback; }

    private:
        void* m_object;
        VisitorCallback m_callback;
    };

    static void init(CallbackStack** first);
    static void shutdown(CallbackStack** first);
    static void clear(CallbackStack** first)
    {
        if (!(*first)->isEmpty()) {
            shutdown(first);
            init(first);
        }
    }
    template<CallbackInvocationMode Mode> bool popAndInvokeCallback(CallbackStack** first, Visitor*);
    static void invokeCallbacks(CallbackStack** first, Visitor*);

    Item* allocateEntry(CallbackStack** first)
    {
        if (m_current < m_limit)
            return m_current++;
        return (new CallbackStack(first))->allocateEntry(first);
    }

#if ENABLE(ASSERT)
    bool hasCallbackForObject(const void*);
#endif

    bool numberOfBlocksExceeds(int blocks)
    {
        CallbackStack* current = this;
        for (int i = 0; i < blocks; ++i) {
            if (!current->m_next)
                return false;
            current = current->m_next;
        }
        return true;
    }

private:
    void invokeOldestCallbacks(Visitor*);
    bool currentBlockIsEmpty() { return m_current == &(m_buffer[0]); }

    static const size_t bufferSize = 200;
    Item m_buffer[bufferSize];
    Item* m_limit;
    Item* m_current;
    CallbackStack* m_next;
};

// Non-template super class used to pass a heap around to other classes.
class BaseHeap {
public:
    virtual ~BaseHeap() { }
    virtual void cleanupPages() = 0;

    // Find the page in this thread heap containing the given
    // address. Returns 0 if the address is not contained in any
    // page in this thread heap.
    virtual BaseHeapPage* heapPageFromAddress(Address) = 0;

#if ENABLE(GC_PROFILE_MARKING)
    virtual const GCInfo* findGCInfoOfLargeHeapObject(Address) = 0;
#endif

#if ENABLE(GC_PROFILE_HEAP)
    virtual void snapshot(TracedValue*, ThreadState::SnapshotInfo*) = 0;
#endif

    // Sweep this part of the Blink heap. This finalizes dead objects
    // and builds freelists for all the unused memory.
    virtual void sweep(HeapStats*) = 0;
    virtual void postSweepProcessing() = 0;

    virtual void clearFreeLists() = 0;
    virtual void clearLiveAndMarkDead() = 0;

    virtual void makeConsistentForSweeping() = 0;

#if ENABLE(ASSERT)
    virtual bool isConsistentForSweeping() = 0;

    virtual void getScannedStats(HeapStats&) = 0;
#endif

    virtual void prepareHeapForTermination() = 0;

    virtual int normalPageCount() = 0;

    virtual BaseHeap* split(int normalPages) = 0;
    virtual void merge(BaseHeap* other) = 0;

    // Returns a bucket number for inserting a FreeListEntry of a
    // given size. All FreeListEntries in the given bucket, n, have
    // size >= 2^n.
    static int bucketIndexForSize(size_t);
};

// Thread heaps represent a part of the per-thread Blink heap.
//
// Each Blink thread has a number of thread heaps: one general heap
// that contains any type of object and a number of heaps specialized
// for specific object types (such as Node).
//
// Each thread heap contains the functionality to allocate new objects
// (potentially adding new pages to the heap), to find and mark
// objects during conservative stack scanning and to sweep the set of
// pages after a GC.
template<typename Header>
class ThreadHeap : public BaseHeap {
public:
    ThreadHeap(ThreadState*, int);
    virtual ~ThreadHeap();
    virtual void cleanupPages();

    virtual BaseHeapPage* heapPageFromAddress(Address);
#if ENABLE(GC_PROFILE_MARKING)
    virtual const GCInfo* findGCInfoOfLargeHeapObject(Address);
#endif
#if ENABLE(GC_PROFILE_HEAP)
    virtual void snapshot(TracedValue*, ThreadState::SnapshotInfo*);
#endif

    virtual void sweep(HeapStats*);
    virtual void postSweepProcessing();

    virtual void clearFreeLists();
    virtual void clearLiveAndMarkDead();

    virtual void makeConsistentForSweeping();

#if ENABLE(ASSERT)
    virtual bool isConsistentForSweeping();

    virtual void getScannedStats(HeapStats&);
#endif

    ThreadState* threadState() { return m_threadState; }
    HeapStats& stats() { return m_threadState->stats(); }
    void flushHeapContainsCache()
    {
        m_threadState->heapContainsCache()->flush();
    }

    inline Address allocate(size_t, const GCInfo*);
    void addToFreeList(Address, size_t);
    inline static size_t roundedAllocationSize(size_t size)
    {
        return allocationSizeFromSize(size) - sizeof(Header);
    }

    virtual void prepareHeapForTermination();

    virtual int normalPageCount() { return m_numberOfNormalPages; }

    virtual BaseHeap* split(int numberOfNormalPages);
    virtual void merge(BaseHeap* splitOffBase);

    void removePageFromHeap(HeapPage<Header>*);

    PLATFORM_EXPORT void promptlyFreeObject(Header*);

private:
    void addPageToHeap(const GCInfo*);
    PLATFORM_EXPORT Address outOfLineAllocate(size_t, const GCInfo*);
    static size_t allocationSizeFromSize(size_t);
    PLATFORM_EXPORT Address allocateLargeObject(size_t, const GCInfo*);
    Address currentAllocationPoint() const { return m_currentAllocationPoint; }
    size_t remainingAllocationSize() const { return m_remainingAllocationSize; }
    bool ownsNonEmptyAllocationArea() const { return currentAllocationPoint() && remainingAllocationSize(); }
    void setAllocationPoint(Address point, size_t size)
    {
        ASSERT(!point || heapPageFromAddress(point));
        ASSERT(size <= HeapPage<Header>::payloadSize());
        m_currentAllocationPoint = point;
        m_remainingAllocationSize = size;
    }
    void ensureCurrentAllocation(size_t, const GCInfo*);
    bool allocateFromFreeList(size_t);

    void freeLargeObject(LargeHeapObject<Header>*, LargeHeapObject<Header>**);
    void allocatePage(const GCInfo*);

#if ENABLE(ASSERT)
    bool pagesToBeSweptContains(Address);
    bool pagesAllocatedDuringSweepingContains(Address);
#endif

    void sweepNormalPages(HeapStats*);
    void sweepLargePages(HeapStats*);
    bool coalesce(size_t);

    Address m_currentAllocationPoint;
    size_t m_remainingAllocationSize;

    HeapPage<Header>* m_firstPage;
    LargeHeapObject<Header>* m_firstLargeHeapObject;

    HeapPage<Header>* m_firstPageAllocatedDuringSweeping;
    HeapPage<Header>* m_lastPageAllocatedDuringSweeping;

    // Merge point for parallel sweep.
    HeapPage<Header>* m_mergePoint;

    int m_biggestFreeListIndex;

    ThreadState* m_threadState;

    // All FreeListEntries in the nth list have size >= 2^n.
    FreeListEntry* m_freeLists[blinkPageSizeLog2];
    FreeListEntry* m_lastFreeListEntries[blinkPageSizeLog2];

    // Index into the page pools. This is used to ensure that the pages of the
    // same type go into the correct page pool and thus avoid type confusion.
    int m_index;

    int m_numberOfNormalPages;

    // The promptly freed count contains the number of promptly freed objects
    // since the last sweep or since it was manually reset to delay coalescing.
    size_t m_promptlyFreedCount;
};

class PLATFORM_EXPORT Heap {
public:
    static BaseHeapPage* contains(Address);
    static BaseHeapPage* contains(void* pointer) { return contains(reinterpret_cast<Address>(pointer)); }
    static BaseHeapPage* contains(const void* pointer) { return contains(const_cast<void*>(pointer)); }
#if ENABLE(ASSERT)
    static bool containedInHeapOrOrphanedPage(void*);
#endif

    // Push a trace callback on the marking stack.
    static void pushTraceCallback(CallbackStack**, void* containerObject, TraceCallback);

    // Push a trace callback on the post-marking callback stack. These callbacks
    // are called after normal marking (including ephemeron iteration).
    static void pushPostMarkingCallback(void*, TraceCallback);

    // Add a weak pointer callback to the weak callback work list. General
    // object pointer callbacks are added to a thread local weak callback work
    // list and the callback is called on the thread that owns the object, with
    // the closure pointer as an argument. Most of the time, the closure and
    // the containerObject can be the same thing, but the containerObject is
    // constrained to be on the heap, since the heap is used to identify the
    // correct thread.
    static void pushWeakObjectPointerCallback(void* closure, void* containerObject, WeakPointerCallback);

    // Similar to the more general pushWeakObjectPointerCallback, but cell
    // pointer callbacks are added to a static callback work list and the weak
    // callback is performed on the thread performing garbage collection. This
    // is OK because cells are just cleared and no deallocation can happen.
    static void pushWeakCellPointerCallback(void** cell, WeakPointerCallback);

    // Pop the top of the marking stack and call the callback with the visitor
    // and the object. Returns false when there is nothing more to do.
    template<CallbackInvocationMode Mode> static bool popAndInvokeTraceCallback(Visitor*);

    // Remove an item from the post-marking callback stack and call
    // the callback with the visitor and the object pointer. Returns
    // false when there is nothing more to do.
    static bool popAndInvokePostMarkingCallback(Visitor*);

    // Remove an item from the weak callback work list and call the callback
    // with the visitor and the closure pointer. Returns false when there is
    // nothing more to do.
    static bool popAndInvokeWeakPointerCallback(Visitor*);

    // Register an ephemeron table for fixed-point iteration.
    static void registerWeakTable(void* containerObject, EphemeronCallback, EphemeronCallback);
#if ENABLE(ASSERT)
    static bool weakTableRegistered(const void*);
#endif

    template<typename T, typename HeapTraits = HeapTypeTrait<T> > static Address allocate(size_t);
    template<typename T> static Address reallocate(void* previous, size_t);

    static void collectGarbage(ThreadState::StackState);
    static void collectGarbageForTerminatingThread(ThreadState*);
    static void collectAllGarbage();
    static void processMarkingStackEntries(int* numberOfMarkingThreads);
    static void processMarkingStackOnMultipleThreads();
    static void processMarkingStackInParallel();
    template<CallbackInvocationMode Mode> static void processMarkingStack();
    static void postMarkingProcessing();
    static void globalWeakProcessing();
    static void setForcePreciseGCForTesting();

    static void prepareForGC();

    // Conservatively checks whether an address is a pointer in any of the thread
    // heaps. If so marks the object pointed to as live.
    static Address checkAndMarkPointer(Visitor*, Address);

#if ENABLE(GC_PROFILE_MARKING)
    // Dump the path to specified object on the next GC. This method is to be invoked from GDB.
    static void dumpPathToObjectOnNextGC(void* p);

    // Forcibly find GCInfo of the object at Address.
    // This is slow and should only be used for debug purposes.
    // It involves finding the heap page and scanning the heap page for an object header.
    static const GCInfo* findGCInfo(Address);

    static String createBacktraceString();
#endif

    // Collect heap stats for all threads attached to the Blink
    // garbage collector. Should only be called during garbage
    // collection where threads are known to be at safe points.
    static void getStats(HeapStats*);

    static void getHeapSpaceSize(uint64_t*, uint64_t*);

    static void makeConsistentForSweeping();

#if ENABLE(ASSERT)
    static bool isConsistentForSweeping();
#endif

    static void flushHeapDoesNotContainCache();
    static bool heapDoesNotContainCacheIsEmpty() { return s_heapDoesNotContainCache->isEmpty(); }

    // Return true if the last GC found a pointer into a heap page
    // during conservative scanning.
    static bool lastGCWasConservative() { return s_lastGCWasConservative; }

    static FreePagePool* freePagePool() { return s_freePagePool; }
    static OrphanedPagePool* orphanedPagePool() { return s_orphanedPagePool; }

private:
    static Visitor* s_markingVisitor;
    static Vector<OwnPtr<blink::WebThread> >* s_markingThreads;
    static CallbackStack* s_markingStack;
    static CallbackStack* s_postMarkingCallbackStack;
    static CallbackStack* s_weakCallbackStack;
    static CallbackStack* s_ephemeronStack;
    static HeapDoesNotContainCache* s_heapDoesNotContainCache;
    static bool s_shutdownCalled;
    static bool s_lastGCWasConservative;
    static FreePagePool* s_freePagePool;
    static OrphanedPagePool* s_orphanedPagePool;
    friend class ThreadState;
};

// The NoAllocationScope class is used in debug mode to catch unwanted
// allocations. E.g. allocations during GC.
template<ThreadAffinity Affinity>
class NoAllocationScope {
public:
    NoAllocationScope() : m_active(true) { enter(); }

    explicit NoAllocationScope(bool active) : m_active(active) { enter(); }

    NoAllocationScope(const NoAllocationScope& other) : m_active(other.m_active) { enter(); }

    NoAllocationScope& operator=(const NoAllocationScope& other)
    {
        release();
        m_active = other.m_active;
        enter();
        return *this;
    }

    ~NoAllocationScope() { release(); }

    void release()
    {
        if (m_active) {
            ThreadStateFor<Affinity>::state()->leaveNoAllocationScope();
            m_active = false;
        }
    }

private:
    void enter() const
    {
        if (m_active)
            ThreadStateFor<Affinity>::state()->enterNoAllocationScope();
    }

    bool m_active;
};

// Classes that contain heap references but aren't themselves heap
// allocated, have some extra macros available which allows their use
// to be restricted to cases where the garbage collector is able
// to discover their heap references.
//
// STACK_ALLOCATED(): Use if the object is only stack allocated. Heap objects
// should be in Members but you do not need the trace method as they are on
// the stack. (Down the line these might turn in to raw pointers, but for
// now Members indicates that we have thought about them and explicitly
// taken care of them.)
//
// DISALLOW_ALLOCATION(): Cannot be allocated with new operators but can
// be a part object. If it has Members you need a trace method and the
// containing object needs to call that trace method.
//
// ALLOW_ONLY_INLINE_ALLOCATION(): Allows only placement new operator.
// This disallows general allocation of this object but allows to put
// the object as a value object in collections. If these have Members you
// need to have a trace method. That trace method will be called
// automatically by the Heap collections.
//
#define DISALLOW_ALLOCATION()                                   \
    private:                                                    \
        void* operator new(size_t) = delete;                    \
        void* operator new(size_t, NotNullTag, void*) = delete; \
        void* operator new(size_t, void*) = delete;

#define ALLOW_ONLY_INLINE_ALLOCATION()                                              \
    public:                                                                         \
        void* operator new(size_t, NotNullTag, void* location) { return location; } \
        void* operator new(size_t, void* location) { return location; }             \
    private:                                                                        \
        void* operator new(size_t) = delete;

#define STATIC_ONLY(Type) \
    private:              \
        Type() = delete;

// These macros insert annotations that the Blink GC plugin for clang uses for
// verification. STACK_ALLOCATED is used to declare that objects of this type
// are always stack allocated. GC_PLUGIN_IGNORE is used to make the plugin
// ignore a particular class or field when checking for proper usage. When using
// GC_PLUGIN_IGNORE a bug-number should be provided as an argument where the
// bug describes what needs to happen to remove the GC_PLUGIN_IGNORE again.
#if COMPILER(CLANG)
#define STACK_ALLOCATED()                                       \
    private:                                                    \
        __attribute__((annotate("blink_stack_allocated")))      \
        void* operator new(size_t) = delete;                    \
        void* operator new(size_t, NotNullTag, void*) = delete; \
        void* operator new(size_t, void*) = delete;

#define GC_PLUGIN_IGNORE(bug)                           \
    __attribute__((annotate("blink_gc_plugin_ignore")))
#else
#define STACK_ALLOCATED() DISALLOW_ALLOCATION()
#define GC_PLUGIN_IGNORE(bug)
#endif

NO_SANITIZE_ADDRESS
void HeapObjectHeader::checkHeader() const
{
#if ENABLE(ASSERT)
    BaseHeapPage* page = pageHeaderFromObject(this);
    ASSERT(page->orphaned() || m_magic == magic);
#endif
}

Address HeapObjectHeader::payload()
{
    return reinterpret_cast<Address>(this) + objectHeaderSize;
}

size_t HeapObjectHeader::payloadSize()
{
    return size() - objectHeaderSize;
}

Address HeapObjectHeader::payloadEnd()
{
    return reinterpret_cast<Address>(this) + size();
}

NO_SANITIZE_ADDRESS
void HeapObjectHeader::mark()
{
    checkHeader();
    // The use of atomic ops guarantees that the reads and writes are
    // atomic and that no memory operation reorderings take place.
    // Multiple threads can still read the old value and all store the
    // new value. However, the new value will be the same for all of
    // the threads and the end result is therefore consistent.
    unsigned size = acquireLoad(&m_size);
    releaseStore(&m_size, size | markBitMask);
}

Address FinalizedHeapObjectHeader::payload()
{
    return reinterpret_cast<Address>(this) + finalizedHeaderSize;
}

size_t FinalizedHeapObjectHeader::payloadSize()
{
    return size() - finalizedHeaderSize;
}

template<typename Header>
size_t ThreadHeap<Header>::allocationSizeFromSize(size_t size)
{
    // Check the size before computing the actual allocation size. The
    // allocation size calculation can overflow for large sizes and
    // the check therefore has to happen before any calculation on the
    // size.
    RELEASE_ASSERT(size < maxHeapObjectSize);

    // Add space for header.
    size_t allocationSize = size + sizeof(Header);
    // Align size with allocation granularity.
    allocationSize = (allocationSize + allocationMask) & ~allocationMask;
    return allocationSize;
}

template<typename Header>
Address ThreadHeap<Header>::allocate(size_t size, const GCInfo* gcInfo)
{
    size_t allocationSize = allocationSizeFromSize(size);
    bool isLargeObject = allocationSize > blinkPageSize / 2;
    if (isLargeObject)
        return allocateLargeObject(allocationSize, gcInfo);
    if (m_remainingAllocationSize < allocationSize)
        return outOfLineAllocate(size, gcInfo);
    Address headerAddress = m_currentAllocationPoint;
    m_currentAllocationPoint += allocationSize;
    m_remainingAllocationSize -= allocationSize;
    Header* header = new (NotNull, headerAddress) Header(allocationSize, gcInfo);
    size_t payloadSize = allocationSize - sizeof(Header);
    stats().increaseObjectSpace(payloadSize);
    Address result = headerAddress + sizeof(*header);
    ASSERT(!(reinterpret_cast<uintptr_t>(result) & allocationMask));
    // Unpoison the memory used for the object (payload).
    ASAN_UNPOISON_MEMORY_REGION(result, payloadSize);
#if ENABLE(ASSERT) || defined(LEAK_SANITIZER) || defined(ADDRESS_SANITIZER)
    memset(result, 0, payloadSize);
#endif
    ASSERT(heapPageFromAddress(headerAddress + allocationSize - 1));
    return result;
}

template<typename T, typename HeapTraits>
Address Heap::allocate(size_t size)
{
    ASSERT_NOT_REACHED();
    return 0;
}

template<typename T>
Address Heap::reallocate(void* previous, size_t size)
{
    if (!size) {
        // If the new size is 0 this is equivalent to either
        // free(previous) or malloc(0). In both cases we do
        // nothing and return 0.
        return 0;
    }
    ThreadState* state = ThreadStateFor<ThreadingTrait<T>::Affinity>::state();
    ASSERT(state->isAllocationAllowed());
    const GCInfo* gcInfo = GCInfoTrait<T>::get();
    int heapIndex = HeapTypeTrait<T>::index(gcInfo->hasFinalizer());
    // FIXME: Currently only supports raw allocation on the
    // GeneralHeap. Hence we assume the header is a
    // FinalizedHeapObjectHeader.
    ASSERT(heapIndex == GeneralHeap || heapIndex == GeneralHeapNonFinalized);
    BaseHeap* heap = state->heap(heapIndex);
    Address address = static_cast<typename HeapTypeTrait<T>::HeapType*>(heap)->allocate(size, gcInfo);
    if (!previous) {
        // This is equivalent to malloc(size).
        return address;
    }
    FinalizedHeapObjectHeader* previousHeader = FinalizedHeapObjectHeader::fromPayload(previous);
    ASSERT(!previousHeader->hasFinalizer());
    ASSERT(previousHeader->gcInfo() == gcInfo);
    size_t copySize = previousHeader->payloadSize();
    if (copySize > size)
        copySize = size;
    memcpy(address, previous, copySize);
    return address;
}

class HeapAllocatorQuantizer {
public:
    template<typename T>
    static size_t quantizedSize(size_t count)
    {
        RELEASE_ASSERT(count <= kMaxUnquantizedAllocation / sizeof(T));
        return HeapIndexTrait<CollectionBackingHeap>::HeapType::roundedAllocationSize(count * sizeof(T));
    }
    static const size_t kMaxUnquantizedAllocation = maxHeapObjectSize;
};

// This is a static-only class used as a trait on collections to make them heap allocated.
// However see also HeapListHashSetAllocator.
class HeapAllocator {
public:
    typedef HeapAllocatorQuantizer Quantizer;
    typedef blink::Visitor Visitor;
    static const bool isGarbageCollected = true;

    template <typename Return, typename Metadata>
    static Return backingMalloc(size_t size)
    {
        return reinterpret_cast<Return>(Heap::allocate<Metadata, HeapIndexTrait<CollectionBackingHeap> >(size));
    }
    template <typename Return, typename Metadata>
    static Return zeroedBackingMalloc(size_t size)
    {
        return backingMalloc<Return, Metadata>(size);
    }
    template <typename Return, typename Metadata>
    static Return malloc(size_t size)
    {
        return reinterpret_cast<Return>(Heap::allocate<Metadata>(size));
    }
    PLATFORM_EXPORT static void backingFree(void* address);

    static void free(void* address) { }
    template<typename T>
    static void* newArray(size_t bytes)
    {
        ASSERT_NOT_REACHED();
        return 0;
    }

    static void deleteArray(void* ptr)
    {
        ASSERT_NOT_REACHED();
    }

    static bool isAllocationAllowed()
    {
        ASSERT_NOT_REACHED();
        return false;
    }

    static void markUsingGCInfo(Visitor* visitor, const void* buffer)
    {
        visitor->mark(buffer, FinalizedHeapObjectHeader::fromPayload(buffer)->traceCallback());
    }

    static void markNoTracing(Visitor* visitor, const void* t) { visitor->markNoTracing(t); }

    template<typename T, typename Traits>
    static void trace(Visitor* visitor, T& t)
    {
    }

    static void registerDelayedMarkNoTracing(Visitor* visitor, const void* object)
    {
        visitor->registerDelayedMarkNoTracing(object);
    }

    static void registerWeakMembers(Visitor* visitor, const void* closure, const void* object, WeakPointerCallback callback)
    {
        visitor->registerWeakMembers(closure, object, callback);
    }

    static void registerWeakTable(Visitor* visitor, const void* closure, EphemeronCallback iterationCallback, EphemeronCallback iterationDoneCallback)
    {
        visitor->registerWeakTable(closure, iterationCallback, iterationDoneCallback);
    }

#if ENABLE(ASSERT)
    static bool weakTableRegistered(Visitor* visitor, const void* closure)
    {
        return visitor->weakTableRegistered(closure);
    }
#endif

    template<typename T>
    struct ResultType {
        typedef T* Type;
    };

    template<typename T>
    struct OtherType {
        typedef T* Type;
    };

    template<typename T>
    static T& getOther(T* other)
    {
        return *other;
    }

    static void enterNoAllocationScope()
    {
#if ENABLE(ASSERT)
        ThreadStateFor<AnyThread>::state()->enterNoAllocationScope();
#endif
    }

    static void leaveNoAllocationScope()
    {
#if ENABLE(ASSERT)
        ThreadStateFor<AnyThread>::state()->leaveNoAllocationScope();
#endif
    }

private:
    template<typename T, size_t u, typename V> friend class WTF::Vector;
    template<typename T, typename U, typename V, typename W> friend class WTF::HashSet;
    template<typename T, typename U, typename V, typename W, typename X, typename Y> friend class WTF::HashMap;
};

template<typename Value>
static void traceListHashSetValue(Visitor* visitor, Value& value)
{
}

// The inline capacity is just a dummy template argument to match the off-heap
// allocator.
// This inherits from the static-only HeapAllocator trait class, but we do
// declare pointers to instances. These pointers are always null, and no
// objects are instantiated.
template<typename ValueArg, size_t inlineCapacity>
struct HeapListHashSetAllocator : public HeapAllocator {
    typedef HeapAllocator TableAllocator;
    typedef WTF::ListHashSetNode<ValueArg, HeapListHashSetAllocator> Node;

public:
    class AllocatorProvider {
    public:
        // For the heap allocation we don't need an actual allocator object, so we just
        // return null.
        HeapListHashSetAllocator* get() const { return 0; }

        // No allocator object is needed.
        void createAllocatorIfNeeded() { }

        // There is no allocator object in the HeapListHashSet (unlike in
        // the regular ListHashSet) so there is nothing to swap.
        void swap(AllocatorProvider& other) { }
    };

    void deallocate(void* dummy) { }

    // This is not a static method even though it could be, because it
    // needs to match the one that the (off-heap) ListHashSetAllocator
    // has. The 'this' pointer will always be null.
    void* allocateNode()
    {
        COMPILE_ASSERT(!WTF::IsWeak<ValueArg>::value, WeakPointersInAListHashSetWillJustResultInNullEntriesInTheSetThatsNotWhatYouWantConsiderUsingLinkedHashSetInstead);
        return malloc<void*, Node>(sizeof(Node));
    }

    static void traceValue(Visitor* visitor, Node* node)
    {
        traceListHashSetValue(visitor, node->m_value);
    }
};

// CollectionBackingTraceTrait. Do nothing for things in collections that don't
// need tracing, or call TraceInCollectionTrait for those that do.

// Specialization for things that don't need marking and have no weak pointers. We
// do nothing, even if WTF::WeakPointersActStrong.
template<WTF::ShouldWeakPointersBeMarkedStrongly strongify, typename T, typename Traits>
struct CollectionBackingTraceTrait<false, WTF::NoWeakHandlingInCollections, strongify, T, Traits> {
    static bool trace(Visitor*, T&) { return false; }
};

// Specialization for things that either need marking or have weak pointers or
// both.
template<bool needsTracing, WTF::WeakHandlingFlag weakHandlingFlag, WTF::ShouldWeakPointersBeMarkedStrongly strongify, typename T, typename Traits>
struct CollectionBackingTraceTrait {
    static bool trace(Visitor* visitor, T&t)
    {
        return false;
    }
};

template<typename T> struct WeakHandlingHashTraits : WTF::SimpleClassHashTraits<T> {
    // We want to treat the object as a weak object in the sense that it can
    // disappear from hash sets and hash maps.
    static const WTF::WeakHandlingFlag weakHandlingFlag = WTF::WeakHandlingInCollections;
    // Normally whether or not an object needs tracing is inferred
    // automatically from the presence of the trace method, but we don't
    // necessarily have a trace method, and we may not need one because T
    // can perhaps only be allocated inside collections, never as indpendent
    // objects. Explicitly mark this as needing tracing and it will be traced
    // in collections using the traceInCollection method, which it must have.
    template<typename U = void> struct NeedsTracingLazily {
        static const bool value = true;
    };
    // The traceInCollection method traces differently depending on whether we
    // are strongifying the trace operation. We strongify the trace operation
    // when there are active iterators on the object. In this case all
    // WeakMembers are marked like strong members so that elements do not
    // suddenly disappear during iteration. Returns true if weak pointers to
    // dead objects were found: In this case any strong pointers were not yet
    // traced and the entry should be removed from the collection.
    static bool traceInCollection(Visitor* visitor, T& t, WTF::ShouldWeakPointersBeMarkedStrongly strongify)
    {
        return t.traceInCollection(visitor, strongify);
    }
};

template<typename T, typename Traits>
struct TraceTrait<HeapVectorBacking<T, Traits> > {
    typedef HeapVectorBacking<T, Traits> Backing;
    static void trace(Visitor* visitor, void* self)
    {
    }
    static void mark(Visitor* visitor, const Backing* backing)
    {
    }
};

template<typename T>
struct IfWeakMember;

template<typename T>
struct IfWeakMember {
    template<typename U>
    static bool isDead(Visitor*, const U&) { return false; }
};

template<typename T>
struct IfWeakMember<WeakMember<T> > {
    static bool isDead(Visitor* visitor, const WeakMember<T>& t) { return !visitor->isAlive(t.get()); }
};

}

#endif // Heap_h
