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

#include "config.h"
#include "platform/heap/Heap.h"

#include "platform/ScriptForbiddenScope.h"
#include "platform/TraceEvent.h"
#include "platform/heap/ThreadState.h"
#include "public/platform/Platform.h"
#include "wtf/AddressSpaceRandomization.h"
#include "wtf/Assertions.h"
#include "wtf/LeakAnnotations.h"
#include "wtf/PassOwnPtr.h"
#if ENABLE(GC_PROFILE_MARKING)
#include "wtf/HashMap.h"
#include "wtf/HashSet.h"
#include "wtf/text/StringBuilder.h"
#include "wtf/text/StringHash.h"
#include <stdio.h>
#include <utility>
#endif
#if ENABLE(GC_PROFILE_HEAP)
#include "platform/TracedValue.h"
#endif

#include <sys/mman.h>
#include <unistd.h>

namespace blink {

#if ENABLE(GC_PROFILE_MARKING)
static String classOf(const void* object)
{
    const GCInfo* gcInfo = Heap::findGCInfo(reinterpret_cast<Address>(const_cast<void*>(object)));
    if (gcInfo)
        return gcInfo->m_className;

    return "unknown";
}
#endif

static bool vTableInitialized(void* objectPointer)
{
    return !!(*reinterpret_cast<Address*>(objectPointer));
}

static Address roundToBlinkPageBoundary(void* base)
{
    return reinterpret_cast<Address>((reinterpret_cast<uintptr_t>(base) + blinkPageOffsetMask) & blinkPageBaseMask);
}

static size_t roundToOsPageSize(size_t size)
{
    return (size + osPageSize() - 1) & ~(osPageSize() - 1);
}

size_t osPageSize()
{
#if OS(POSIX)
    static const size_t pageSize = getpagesize();
#else
    static size_t pageSize = 0;
    if (!pageSize) {
        SYSTEM_INFO info;
        GetSystemInfo(&info);
        pageSize = info.dwPageSize;
        ASSERT(IsPowerOf2(pageSize));
    }
#endif
    return pageSize;
}

class MemoryRegion {
public:
    MemoryRegion(Address base, size_t size)
        : m_base(base)
        , m_size(size)
    {
        ASSERT(size > 0);
    }

    bool contains(Address addr) const
    {
        return m_base <= addr && addr < (m_base + m_size);
    }


    bool contains(const MemoryRegion& other) const
    {
        return contains(other.m_base) && contains(other.m_base + other.m_size - 1);
    }

    void release()
    {
#if OS(POSIX)
        int err = munmap(m_base, m_size);
        RELEASE_ASSERT(!err);
#else
        bool success = VirtualFree(m_base, 0, MEM_RELEASE);
        RELEASE_ASSERT(success);
#endif
    }

    WARN_UNUSED_RETURN bool commit()
    {
        ASSERT(Heap::heapDoesNotContainCacheIsEmpty());
#if OS(POSIX)
        int err = mprotect(m_base, m_size, PROT_READ | PROT_WRITE);
        if (!err) {
            madvise(m_base, m_size, MADV_NORMAL);
            return true;
        }
        return false;
#else
        void* result = VirtualAlloc(m_base, m_size, MEM_COMMIT, PAGE_READWRITE);
        return !!result;
#endif
    }

    void decommit()
    {
#if OS(POSIX)
        int err = mprotect(m_base, m_size, PROT_NONE);
        RELEASE_ASSERT(!err);
        // FIXME: Consider using MADV_FREE on MacOS.
        madvise(m_base, m_size, MADV_DONTNEED);
#else
        bool success = VirtualFree(m_base, m_size, MEM_DECOMMIT);
        RELEASE_ASSERT(success);
#endif
    }

    Address base() const { return m_base; }
    size_t size() const { return m_size; }

private:
    Address m_base;
    size_t m_size;
};

// A PageMemoryRegion represents a chunk of reserved virtual address
// space containing a number of blink heap pages. On Windows, reserved
// virtual address space can only be given back to the system as a
// whole. The PageMemoryRegion allows us to do that by keeping track
// of the number of pages using it in order to be able to release all
// of the virtual address space when there are no more pages using it.
class PageMemoryRegion : public MemoryRegion {
public:
    ~PageMemoryRegion()
    {
        release();
    }

    void pageRemoved()
    {
        if (!--m_numPages)
            delete this;
    }

    static PageMemoryRegion* allocate(size_t size, unsigned numPages)
    {
        ASSERT(Heap::heapDoesNotContainCacheIsEmpty());

        // Compute a random blink page aligned address for the page memory
        // region and attempt to get the memory there.
        Address randomAddress = reinterpret_cast<Address>(WTF::getRandomPageBase());
        Address alignedRandomAddress = roundToBlinkPageBoundary(randomAddress);

#if OS(POSIX)
        Address base = static_cast<Address>(mmap(alignedRandomAddress, size, PROT_NONE, MAP_ANON | MAP_PRIVATE, -1, 0));
        RELEASE_ASSERT(base != MAP_FAILED);
        if (base == roundToBlinkPageBoundary(base))
            return new PageMemoryRegion(base, size, numPages);

        // We failed to get a blink page aligned chunk of
        // memory. Unmap the chunk that we got and fall back to
        // overallocating and selecting an aligned sub part of what
        // we allocate.
        int error = munmap(base, size);
        RELEASE_ASSERT(!error);
        size_t allocationSize = size + blinkPageSize;
        base = static_cast<Address>(mmap(alignedRandomAddress, allocationSize, PROT_NONE, MAP_ANON | MAP_PRIVATE, -1, 0));
        RELEASE_ASSERT(base != MAP_FAILED);

        Address end = base + allocationSize;
        Address alignedBase = roundToBlinkPageBoundary(base);
        Address regionEnd = alignedBase + size;

        // If the allocated memory was not blink page aligned release
        // the memory before the aligned address.
        if (alignedBase != base)
            MemoryRegion(base, alignedBase - base).release();

        // Free the additional memory at the end of the page if any.
        if (regionEnd < end)
            MemoryRegion(regionEnd, end - regionEnd).release();

        return new PageMemoryRegion(alignedBase, size, numPages);
#else
        Address base = static_cast<Address>(VirtualAlloc(alignedRandomAddress, size, MEM_RESERVE, PAGE_NOACCESS));
        if (base) {
            ASSERT(base == alignedRandomAddress);
            return new PageMemoryRegion(base, size, numPages);
        }

        // We failed to get the random aligned address that we asked
        // for. Fall back to overallocating. On Windows it is
        // impossible to partially release a region of memory
        // allocated by VirtualAlloc. To avoid wasting virtual address
        // space we attempt to release a large region of memory
        // returned as a whole and then allocate an aligned region
        // inside this larger region.
        size_t allocationSize = size + blinkPageSize;
        for (int attempt = 0; attempt < 3; attempt++) {
            base = static_cast<Address>(VirtualAlloc(0, allocationSize, MEM_RESERVE, PAGE_NOACCESS));
            RELEASE_ASSERT(base);
            VirtualFree(base, 0, MEM_RELEASE);

            Address alignedBase = roundToBlinkPageBoundary(base);
            base = static_cast<Address>(VirtualAlloc(alignedBase, size, MEM_RESERVE, PAGE_NOACCESS));
            if (base) {
                ASSERT(base == alignedBase);
                return new PageMemoryRegion(alignedBase, size, numPages);
            }
        }

        // We failed to avoid wasting virtual address space after
        // several attempts.
        base = static_cast<Address>(VirtualAlloc(0, allocationSize, MEM_RESERVE, PAGE_NOACCESS));
        RELEASE_ASSERT(base);

        // FIXME: If base is by accident blink page size aligned
        // here then we can create two pages out of reserved
        // space. Do this.
        Address alignedBase = roundToBlinkPageBoundary(base);

        return new PageMemoryRegion(alignedBase, size, numPages);
#endif
    }

private:
    PageMemoryRegion(Address base, size_t size, unsigned numPages)
        : MemoryRegion(base, size)
        , m_numPages(numPages)
    {
    }

    unsigned m_numPages;
};

// Representation of the memory used for a Blink heap page.
//
// The representation keeps track of two memory regions:
//
// 1. The virtual memory reserved from the system in order to be able
//    to free all the virtual memory reserved. Multiple PageMemory
//    instances can share the same reserved memory region and
//    therefore notify the reserved memory region on destruction so
//    that the system memory can be given back when all PageMemory
//    instances for that memory are gone.
//
// 2. The writable memory (a sub-region of the reserved virtual
//    memory region) that is used for the actual heap page payload.
//
// Guard pages are created before and after the writable memory.
class PageMemory {
public:
    ~PageMemory()
    {
        __lsan_unregister_root_region(m_writable.base(), m_writable.size());
        m_reserved->pageRemoved();
    }

    bool commit() WARN_UNUSED_RETURN { return m_writable.commit(); }
    void decommit() { m_writable.decommit(); }

    Address writableStart() { return m_writable.base(); }

    static PageMemory* setupPageMemoryInRegion(PageMemoryRegion* region, size_t pageOffset, size_t payloadSize)
    {
        // Setup the payload one OS page into the page memory. The
        // first os page is the guard page.
        Address payloadAddress = region->base() + pageOffset + osPageSize();
        return new PageMemory(region, MemoryRegion(payloadAddress, payloadSize));
    }

    // Allocate a virtual address space for one blink page with the
    // following layout:
    //
    //    [ guard os page | ... payload ... | guard os page ]
    //    ^---{ aligned to blink page size }
    //
    static PageMemory* allocate(size_t payloadSize)
    {
        ASSERT(payloadSize > 0);

        // Virtual memory allocation routines operate in OS page sizes.
        // Round up the requested size to nearest os page size.
        payloadSize = roundToOsPageSize(payloadSize);

        // Overallocate by 2 times OS page size to have space for a
        // guard page at the beginning and end of blink heap page.
        size_t allocationSize = payloadSize + 2 * osPageSize();
        PageMemoryRegion* pageMemoryRegion = PageMemoryRegion::allocate(allocationSize, 1);
        PageMemory* storage = setupPageMemoryInRegion(pageMemoryRegion, 0, payloadSize);
        RELEASE_ASSERT(storage->commit());
        return storage;
    }

private:
    PageMemory(PageMemoryRegion* reserved, const MemoryRegion& writable)
        : m_reserved(reserved)
        , m_writable(writable)
    {
        ASSERT(reserved->contains(writable));

        // Register the writable area of the memory as part of the LSan root set.
        // Only the writable area is mapped and can contain C++ objects. Those
        // C++ objects can contain pointers to objects outside of the heap and
        // should therefore be part of the LSan root set.
        __lsan_register_root_region(m_writable.base(), m_writable.size());
    }


    PageMemoryRegion* m_reserved;
    MemoryRegion m_writable;
};

class GCScope {
public:
    explicit GCScope(ThreadState::StackState stackState)
        : m_state(ThreadState::current())
        , m_safePointScope(stackState)
        , m_parkedAllThreads(false)
    {
        TRACE_EVENT0("blink_gc", "Heap::GCScope");
        const char* samplingState = TRACE_EVENT_GET_SAMPLING_STATE();
        if (m_state->isMainThread())
            TRACE_EVENT_SET_SAMPLING_STATE("blink_gc", "BlinkGCWaiting");

        m_state->checkThread();

        // FIXME: in an unlikely coincidence that two threads decide
        // to collect garbage at the same time, avoid doing two GCs in
        // a row.
        RELEASE_ASSERT(!m_state->isInGC());
        RELEASE_ASSERT(!m_state->isSweepInProgress());
        if (LIKELY(ThreadState::stopThreads())) {
            m_parkedAllThreads = true;
            m_state->enterGC();
        }
        if (m_state->isMainThread())
            TRACE_EVENT_SET_NONCONST_SAMPLING_STATE(samplingState);
    }

    bool allThreadsParked() { return m_parkedAllThreads; }

    ~GCScope()
    {
        // Only cleanup if we parked all threads in which case the GC happened
        // and we need to resume the other threads.
        if (LIKELY(m_parkedAllThreads)) {
            m_state->leaveGC();
            ASSERT(!m_state->isInGC());
            ThreadState::resumeThreads();
        }
    }

private:
    ThreadState* m_state;
    ThreadState::SafePointScope m_safePointScope;
    bool m_parkedAllThreads; // False if we fail to park all threads
};

NO_SANITIZE_ADDRESS
bool HeapObjectHeader::isMarked() const
{
    checkHeader();
    unsigned size = acquireLoad(&m_size);
    return size & markBitMask;
}

NO_SANITIZE_ADDRESS
void HeapObjectHeader::unmark()
{
    checkHeader();
    m_size &= ~markBitMask;
}

NO_SANITIZE_ADDRESS
bool HeapObjectHeader::hasDeadMark() const
{
    checkHeader();
    return m_size & deadBitMask;
}

NO_SANITIZE_ADDRESS
void HeapObjectHeader::clearDeadMark()
{
    checkHeader();
    m_size &= ~deadBitMask;
}

NO_SANITIZE_ADDRESS
void HeapObjectHeader::setDeadMark()
{
    ASSERT(!isMarked());
    checkHeader();
    m_size |= deadBitMask;
}

#if ENABLE(ASSERT)
NO_SANITIZE_ADDRESS
void HeapObjectHeader::zapMagic()
{
    m_magic = zappedMagic;
}
#endif

HeapObjectHeader* HeapObjectHeader::fromPayload(const void* payload)
{
    Address addr = reinterpret_cast<Address>(const_cast<void*>(payload));
    HeapObjectHeader* header =
        reinterpret_cast<HeapObjectHeader*>(addr - objectHeaderSize);
    return header;
}

void HeapObjectHeader::finalize(const GCInfo* gcInfo, Address object, size_t objectSize)
{
    ASSERT(gcInfo);
    if (gcInfo->hasFinalizer()) {
        gcInfo->m_finalize(object);
    }

#if ENABLE(ASSERT) || defined(LEAK_SANITIZER) || defined(ADDRESS_SANITIZER)
    // In Debug builds, memory is zapped when it's freed, and the zapped memory is
    // zeroed out when the memory is reused. Memory is also zapped when using Leak
    // Sanitizer because the heap is used as a root region for LSan and therefore
    // pointers in unreachable memory could hide leaks.
    for (size_t i = 0; i < objectSize; i++)
        object[i] = finalizedZapValue;

    // Zap the primary vTable entry (secondary vTable entries are not zapped).
    *(reinterpret_cast<uintptr_t*>(object)) = zappedVTable;
#endif
    // In Release builds, the entire object is zeroed out when it is added to the free list.
    // This happens right after sweeping the page and before the thread commences execution.
}

NO_SANITIZE_ADDRESS
void FinalizedHeapObjectHeader::finalize()
{
    HeapObjectHeader::finalize(m_gcInfo, payload(), payloadSize());
}

template<typename Header>
void LargeHeapObject<Header>::unmark()
{
    return heapObjectHeader()->unmark();
}

template<typename Header>
bool LargeHeapObject<Header>::isMarked()
{
    return heapObjectHeader()->isMarked();
}

template<typename Header>
void LargeHeapObject<Header>::setDeadMark()
{
    heapObjectHeader()->setDeadMark();
}

template<typename Header>
void LargeHeapObject<Header>::checkAndMarkPointer(Visitor* visitor, Address address)
{
    ASSERT(contains(address));
    if (!objectContains(address) || heapObjectHeader()->hasDeadMark())
        return;
#if ENABLE(GC_PROFILE_MARKING)
    visitor->setHostInfo(&address, "stack");
#endif
    mark(visitor);
}

#if ENABLE(ASSERT)
static bool isUninitializedMemory(void* objectPointer, size_t objectSize)
{
    // Scan through the object's fields and check that they are all zero.
    Address* objectFields = reinterpret_cast<Address*>(objectPointer);
    for (size_t i = 0; i < objectSize / sizeof(Address); ++i) {
        if (objectFields[i] != 0)
            return false;
    }
    return true;
}
#endif

template<>
void LargeHeapObject<FinalizedHeapObjectHeader>::mark(Visitor* visitor)
{
    if (heapObjectHeader()->hasVTable() && !vTableInitialized(payload())) {
        FinalizedHeapObjectHeader* header = heapObjectHeader();
        visitor->markNoTracing(header);
        ASSERT(isUninitializedMemory(header->payload(), header->payloadSize()));
    } else {
        visitor->mark(heapObjectHeader(), heapObjectHeader()->traceCallback());
    }
}

template<>
void LargeHeapObject<HeapObjectHeader>::mark(Visitor* visitor)
{
    ASSERT(gcInfo());
    if (gcInfo()->hasVTable() && !vTableInitialized(payload())) {
        HeapObjectHeader* header = heapObjectHeader();
        visitor->markNoTracing(header);
        ASSERT(isUninitializedMemory(header->payload(), header->payloadSize()));
    } else {
        visitor->mark(heapObjectHeader(), gcInfo()->m_trace);
    }
}

template<>
void LargeHeapObject<FinalizedHeapObjectHeader>::finalize()
{
    heapObjectHeader()->finalize();
}

template<>
void LargeHeapObject<HeapObjectHeader>::finalize()
{
    ASSERT(gcInfo());
    HeapObjectHeader::finalize(gcInfo(), payload(), payloadSize());
}

FinalizedHeapObjectHeader* FinalizedHeapObjectHeader::fromPayload(const void* payload)
{
    Address addr = reinterpret_cast<Address>(const_cast<void*>(payload));
    FinalizedHeapObjectHeader* header =
        reinterpret_cast<FinalizedHeapObjectHeader*>(addr - finalizedHeaderSize);
    return header;
}

template<typename Header>
ThreadHeap<Header>::ThreadHeap(ThreadState* state, int index)
    : m_currentAllocationPoint(0)
    , m_remainingAllocationSize(0)
    , m_firstPage(0)
    , m_firstLargeHeapObject(0)
    , m_firstPageAllocatedDuringSweeping(0)
    , m_lastPageAllocatedDuringSweeping(0)
    , m_mergePoint(0)
    , m_biggestFreeListIndex(0)
    , m_threadState(state)
    , m_index(index)
    , m_numberOfNormalPages(0)
    , m_promptlyFreedCount(0)
{
    clearFreeLists();
}

template<typename Header>
ThreadHeap<Header>::~ThreadHeap()
{
    ASSERT(!m_firstPage);
    ASSERT(!m_firstLargeHeapObject);
}

template<typename Header>
void ThreadHeap<Header>::cleanupPages()
{
    clearFreeLists();
    flushHeapContainsCache();

    // Add the ThreadHeap's pages to the orphanedPagePool.
    for (HeapPage<Header>* page = m_firstPage; page; page = page->m_next)
        Heap::orphanedPagePool()->addOrphanedPage(m_index, page);
    m_firstPage = 0;

    for (LargeHeapObject<Header>* largeObject = m_firstLargeHeapObject; largeObject; largeObject = largeObject->m_next)
        Heap::orphanedPagePool()->addOrphanedPage(m_index, largeObject);
    m_firstLargeHeapObject = 0;
}

template<typename Header>
Address ThreadHeap<Header>::outOfLineAllocate(size_t size, const GCInfo* gcInfo)
{
    size_t allocationSize = allocationSizeFromSize(size);
    if (threadState()->shouldGC()) {
        if (threadState()->shouldForceConservativeGC())
            Heap::collectGarbage(ThreadState::HeapPointersOnStack);
        else
            threadState()->setGCRequested();
    }
    ensureCurrentAllocation(allocationSize, gcInfo);
    return allocate(size, gcInfo);
}

template<typename Header>
bool ThreadHeap<Header>::allocateFromFreeList(size_t minSize)
{
    size_t bucketSize = 1 << m_biggestFreeListIndex;
    int i = m_biggestFreeListIndex;
    for (; i > 0; i--, bucketSize >>= 1) {
        if (bucketSize < minSize)
            break;
        FreeListEntry* entry = m_freeLists[i];
        if (entry) {
            m_biggestFreeListIndex = i;
            entry->unlink(&m_freeLists[i]);
            setAllocationPoint(entry->address(), entry->size());
            ASSERT(currentAllocationPoint() && remainingAllocationSize() >= minSize);
            return true;
        }
    }
    m_biggestFreeListIndex = i;
    return false;
}

template<typename Header>
void ThreadHeap<Header>::ensureCurrentAllocation(size_t minSize, const GCInfo* gcInfo)
{
    ASSERT(minSize >= allocationGranularity);
    if (remainingAllocationSize() >= minSize)
        return;

    if (remainingAllocationSize() > 0)
        addToFreeList(currentAllocationPoint(), remainingAllocationSize());
    if (allocateFromFreeList(minSize))
        return;
    if (coalesce(minSize) && allocateFromFreeList(minSize))
        return;
    addPageToHeap(gcInfo);
    bool success = allocateFromFreeList(minSize);
    RELEASE_ASSERT(success);
}

template<typename Header>
BaseHeapPage* ThreadHeap<Header>::heapPageFromAddress(Address address)
{
    for (HeapPage<Header>* page = m_firstPage; page; page = page->next()) {
        if (page->contains(address))
            return page;
    }
    for (HeapPage<Header>* page = m_firstPageAllocatedDuringSweeping; page; page = page->next()) {
        if (page->contains(address))
            return page;
    }
    for (LargeHeapObject<Header>* current = m_firstLargeHeapObject; current; current = current->next()) {
        // Check that large pages are blinkPageSize aligned (modulo the
        // osPageSize for the guard page).
        ASSERT(reinterpret_cast<Address>(current) - osPageSize() == roundToBlinkPageStart(reinterpret_cast<Address>(current)));
        if (current->contains(address))
            return current;
    }
    return 0;
}

#if ENABLE(GC_PROFILE_MARKING)
template<typename Header>
const GCInfo* ThreadHeap<Header>::findGCInfoOfLargeHeapObject(Address address)
{
    for (LargeHeapObject<Header>* current = m_firstLargeHeapObject; current; current = current->next()) {
        if (current->contains(address))
            return current->gcInfo();
    }
    return 0;
}
#endif

#if ENABLE(GC_PROFILE_HEAP)
#define GC_PROFILE_HEAP_PAGE_SNAPSHOT_THRESHOLD 0
template<typename Header>
void ThreadHeap<Header>::snapshot(TracedValue* json, ThreadState::SnapshotInfo* info)
{
    size_t previousPageCount = info->pageCount;

    json->beginArray("pages");
    for (HeapPage<Header>* page = m_firstPage; page; page = page->next(), ++info->pageCount) {
        // FIXME: To limit the size of the snapshot we only output "threshold" many page snapshots.
        if (info->pageCount < GC_PROFILE_HEAP_PAGE_SNAPSHOT_THRESHOLD) {
            json->beginArray();
            json->pushInteger(reinterpret_cast<intptr_t>(page));
            page->snapshot(json, info);
            json->endArray();
        } else {
            page->snapshot(0, info);
        }
    }
    json->endArray();

    json->beginArray("largeObjects");
    for (LargeHeapObject<Header>* current = m_firstLargeHeapObject; current; current = current->next()) {
        json->beginDictionary();
        current->snapshot(json, info);
        json->endDictionary();
    }
    json->endArray();

    json->setInteger("pageCount", info->pageCount - previousPageCount);
}
#endif

template<typename Header>
void ThreadHeap<Header>::addToFreeList(Address address, size_t size)
{
    ASSERT(heapPageFromAddress(address));
    ASSERT(heapPageFromAddress(address + size - 1));
    ASSERT(size < blinkPagePayloadSize());
    // The free list entries are only pointer aligned (but when we allocate
    // from them we are 8 byte aligned due to the header size).
    ASSERT(!((reinterpret_cast<uintptr_t>(address) + sizeof(Header)) & allocationMask));
    ASSERT(!(size & allocationMask));
    ASAN_POISON_MEMORY_REGION(address, size);
    FreeListEntry* entry;
    if (size < sizeof(*entry)) {
        // Create a dummy header with only a size and freelist bit set.
        ASSERT(size >= sizeof(BasicObjectHeader));
        // Free list encode the size to mark the lost memory as freelist memory.
        new (NotNull, address) BasicObjectHeader(BasicObjectHeader::freeListEncodedSize(size));
        // This memory gets lost. Sweeping can reclaim it.
        return;
    }
    entry = new (NotNull, address) FreeListEntry(size);
#if defined(ADDRESS_SANITIZER)
    // For ASan we don't add the entry to the free lists until the asanDeferMemoryReuseCount
    // reaches zero. However we always add entire pages to ensure that adding a new page will
    // increase the allocation space.
    if (HeapPage<Header>::payloadSize() != size && !entry->shouldAddToFreeList())
        return;
#endif
    int index = bucketIndexForSize(size);
    entry->link(&m_freeLists[index]);
    if (!m_lastFreeListEntries[index])
        m_lastFreeListEntries[index] = entry;
    if (index > m_biggestFreeListIndex)
        m_biggestFreeListIndex = index;
}

template<typename Header>
void ThreadHeap<Header>::promptlyFreeObject(Header* header)
{
    ASSERT(!m_threadState->isSweepInProgress());
    header->checkHeader();
    Address address = reinterpret_cast<Address>(header);
    Address payload = header->payload();
    size_t size = header->size();
    size_t payloadSize = header->payloadSize();
    BaseHeapPage* page = pageHeaderFromObject(address);
    ASSERT(size > 0);
    ASSERT(page == heapPageFromAddress(address));

    {
        ThreadState::NoSweepScope scope(m_threadState);
        HeapObjectHeader::finalize(header->gcInfo(), payload, payloadSize);
#if !ENABLE(ASSERT) && !defined(LEAK_SANITIZER) && !defined(ADDRESS_SANITIZER)
        memset(payload, 0, payloadSize);
#endif
        header->markPromptlyFreed();
    }

    page->addToPromptlyFreedSize(size);
    m_promptlyFreedCount++;
}

template<typename Header>
bool ThreadHeap<Header>::coalesce(size_t minSize)
{
    if (m_threadState->isSweepInProgress())
        return false;

    if (m_promptlyFreedCount < 256)
        return false;

    // The smallest bucket able to satisfy an allocation request for minSize is
    // the bucket where all free-list entries are guarantied to be larger than
    // minSize. That bucket is one larger than the bucket minSize would go into.
    size_t neededBucketIndex = bucketIndexForSize(minSize) + 1;
    size_t neededFreeEntrySize = 1 << neededBucketIndex;
    size_t neededPromptlyFreedSize = neededFreeEntrySize * 3;
    size_t foundFreeEntrySize = 0;

    // Bailout early on large requests because it is unlikely we will find a free-list entry.
    if (neededPromptlyFreedSize >= blinkPageSize)
        return false;

    TRACE_EVENT_BEGIN2("blink_gc", "ThreadHeap::coalesce" , "requestedSize", (unsigned)minSize , "neededSize", (unsigned)neededFreeEntrySize);

    // Search for a coalescing candidate.
    ASSERT(!ownsNonEmptyAllocationArea());
    size_t pageCount = 0;
    HeapPage<Header>* page = m_firstPage;
    while (page) {
        // Only consider one of the first 'n' pages. A "younger" page is more likely to have freed backings.
        if (++pageCount > numberOfPagesToConsiderForCoalescing) {
            page = 0;
            break;
        }
        // Only coalesce pages with "sufficient" promptly freed space.
        if (page->promptlyFreedSize() >= neededPromptlyFreedSize) {
            break;
        }
        page = page->next();
    }

    // If we found a likely candidate, fully coalesce all its promptly-freed entries.
    if (page) {
        page->clearObjectStartBitMap();
        page->resetPromptlyFreedSize();
        size_t freedCount = 0;
        Address startOfGap = page->payload();
        for (Address headerAddress = startOfGap; headerAddress < page->end(); ) {
            BasicObjectHeader* basicHeader = reinterpret_cast<BasicObjectHeader*>(headerAddress);
            ASSERT(basicHeader->size() > 0);
            ASSERT(basicHeader->size() < blinkPagePayloadSize());

            if (basicHeader->isPromptlyFreed()) {
                stats().decreaseObjectSpace(reinterpret_cast<Header*>(basicHeader)->payloadSize());
                size_t size = basicHeader->size();
                ASSERT(size >= sizeof(Header));
#if !ENABLE(ASSERT) && !defined(LEAK_SANITIZER) && !defined(ADDRESS_SANITIZER)
                memset(headerAddress, 0, sizeof(Header));
#endif
                ++freedCount;
                headerAddress += size;
                continue;
            }

            if (startOfGap != headerAddress) {
                size_t size = headerAddress - startOfGap;
                addToFreeList(startOfGap, size);
                if (size > foundFreeEntrySize)
                    foundFreeEntrySize = size;
            }

            headerAddress += basicHeader->size();
            startOfGap = headerAddress;
        }

        if (startOfGap != page->end()) {
            size_t size = page->end() - startOfGap;
            addToFreeList(startOfGap, size);
            if (size > foundFreeEntrySize)
                foundFreeEntrySize = size;
        }

        // Check before subtracting because freedCount might not be balanced with freed entries.
        if (freedCount < m_promptlyFreedCount)
            m_promptlyFreedCount -= freedCount;
        else
            m_promptlyFreedCount = 0;
    }

    TRACE_EVENT_END1("blink_gc", "ThreadHeap::coalesce", "foundFreeEntrySize", (unsigned)foundFreeEntrySize);

    if (foundFreeEntrySize < neededFreeEntrySize) {
        // If coalescing failed, reset the freed count to delay coalescing again.
        m_promptlyFreedCount = 0;
        return false;
    }

    return true;
}

template<typename Header>
Address ThreadHeap<Header>::allocateLargeObject(size_t size, const GCInfo* gcInfo)
{
    // Caller already added space for object header and rounded up to allocation alignment
    ASSERT(!(size & allocationMask));

    size_t allocationSize = sizeof(LargeHeapObject<Header>) + size;

    // Ensure that there is enough space for alignment. If the header
    // is not a multiple of 8 bytes we will allocate an extra
    // headerPadding<Header> bytes to ensure it 8 byte aligned.
    allocationSize += headerPadding<Header>();

    // If ASan is supported we add allocationGranularity bytes to the allocated space and
    // poison that to detect overflows
#if defined(ADDRESS_SANITIZER)
    allocationSize += allocationGranularity;
#endif
    if (threadState()->shouldGC())
        threadState()->setGCRequested();
    Heap::flushHeapDoesNotContainCache();
    PageMemory* pageMemory = PageMemory::allocate(allocationSize);
    Address largeObjectAddress = pageMemory->writableStart();
    Address headerAddress = largeObjectAddress + sizeof(LargeHeapObject<Header>) + headerPadding<Header>();
    memset(headerAddress, 0, size);
    Header* header = new (NotNull, headerAddress) Header(size, gcInfo);
    Address result = headerAddress + sizeof(*header);
    ASSERT(!(reinterpret_cast<uintptr_t>(result) & allocationMask));
    LargeHeapObject<Header>* largeObject = new (largeObjectAddress) LargeHeapObject<Header>(pageMemory, gcInfo, threadState());

    // Poison the object header and allocationGranularity bytes after the object
    ASAN_POISON_MEMORY_REGION(header, sizeof(*header));
    ASAN_POISON_MEMORY_REGION(largeObject->address() + largeObject->size(), allocationGranularity);
    largeObject->link(&m_firstLargeHeapObject);
    stats().increaseAllocatedSpace(largeObject->size());
    stats().increaseObjectSpace(largeObject->payloadSize());
    return result;
}

template<typename Header>
void ThreadHeap<Header>::freeLargeObject(LargeHeapObject<Header>* object, LargeHeapObject<Header>** previousNext)
{
    flushHeapContainsCache();
    object->unlink(previousNext);
    object->finalize();

    // Unpoison the object header and allocationGranularity bytes after the
    // object before freeing.
    ASAN_UNPOISON_MEMORY_REGION(object->heapObjectHeader(), sizeof(Header));
    ASAN_UNPOISON_MEMORY_REGION(object->address() + object->size(), allocationGranularity);

    if (object->terminating()) {
        ASSERT(ThreadState::current()->isTerminating());
        // The thread is shutting down so this object is being removed as part
        // of a thread local GC. In that case the object could be traced in the
        // next global GC either due to a dead object being traced via a
        // conservative pointer or due to a programming error where an object
        // in another thread heap keeps a dangling pointer to this object.
        // To guard against this we put the large object memory in the
        // orphanedPagePool to ensure it is still reachable. After the next global
        // GC it can be released assuming no rogue/dangling pointers refer to
        // it.
        // NOTE: large objects are not moved to the free page pool as it is
        // unlikely they can be reused due to their individual sizes.
        Heap::orphanedPagePool()->addOrphanedPage(m_index, object);
    } else {
        ASSERT(!ThreadState::current()->isTerminating());
        PageMemory* memory = object->storage();
        object->~LargeHeapObject<Header>();
        delete memory;
    }
}

template<typename DataType>
PagePool<DataType>::PagePool()
{
    for (int i = 0; i < NumberOfHeaps; ++i) {
        m_pool[i] = 0;
    }
}

FreePagePool::~FreePagePool()
{
    for (int index = 0; index < NumberOfHeaps; ++index) {
        while (PoolEntry* entry = m_pool[index]) {
            m_pool[index] = entry->next;
            PageMemory* memory = entry->data;
            ASSERT(memory);
            delete memory;
            delete entry;
        }
    }
}

void FreePagePool::addFreePage(int index, PageMemory* memory)
{
    // When adding a page to the pool we decommit it to ensure it is unused
    // while in the pool. This also allows the physical memory, backing the
    // page, to be given back to the OS.
    memory->decommit();
    MutexLocker locker(m_mutex[index]);
    PoolEntry* entry = new PoolEntry(memory, m_pool[index]);
    m_pool[index] = entry;
}

PageMemory* FreePagePool::takeFreePage(int index)
{
    MutexLocker locker(m_mutex[index]);
    while (PoolEntry* entry = m_pool[index]) {
        m_pool[index] = entry->next;
        PageMemory* memory = entry->data;
        ASSERT(memory);
        delete entry;
        if (memory->commit())
            return memory;

        // We got some memory, but failed to commit it, try again.
        delete memory;
    }
    return 0;
}

OrphanedPagePool::~OrphanedPagePool()
{
    for (int index = 0; index < NumberOfHeaps; ++index) {
        while (PoolEntry* entry = m_pool[index]) {
            m_pool[index] = entry->next;
            BaseHeapPage* page = entry->data;
            delete entry;
            PageMemory* memory = page->storage();
            ASSERT(memory);
            page->~BaseHeapPage();
            delete memory;
        }
    }
}

void OrphanedPagePool::addOrphanedPage(int index, BaseHeapPage* page)
{
    page->markOrphaned();
    PoolEntry* entry = new PoolEntry(page, m_pool[index]);
    m_pool[index] = entry;
}

NO_SANITIZE_ADDRESS
void OrphanedPagePool::decommitOrphanedPages()
{
#if ENABLE(ASSERT)
    // No locking needed as all threads are at safepoints at this point in time.
    ThreadState::AttachedThreadStateSet& threads = ThreadState::attachedThreads();
    for (ThreadState::AttachedThreadStateSet::iterator it = threads.begin(), end = threads.end(); it != end; ++it)
        ASSERT((*it)->isAtSafePoint());
#endif

    for (int index = 0; index < NumberOfHeaps; ++index) {
        PoolEntry* entry = m_pool[index];
        PoolEntry** prevNext = &m_pool[index];
        while (entry) {
            BaseHeapPage* page = entry->data;
            if (page->tracedAfterOrphaned()) {
                // If the orphaned page was traced in the last GC it is not
                // decommited. We only decommit a page, ie. put it in the
                // memory pool, when the page has no objects pointing to it.
                // We remark the page as orphaned to clear the tracedAfterOrphaned
                // flag and any object trace bits that were set during tracing.
                page->markOrphaned();
                prevNext = &entry->next;
                entry = entry->next;
                continue;
            }

            // Page was not traced. Check if we should reuse the memory or just
            // free it. Large object memory is not reused, but freed, normal
            // blink heap pages are reused.
            // NOTE: We call the destructor before freeing or adding to the
            // free page pool.
            PageMemory* memory = page->storage();
            if (page->isLargeObject()) {
                page->~BaseHeapPage();
                delete memory;
            } else {
                page->~BaseHeapPage();
                // Clear out the page's memory before adding it to the free page
                // pool to ensure it is zero filled when being reused.
                clearMemory(memory);
                Heap::freePagePool()->addFreePage(index, memory);
            }

            PoolEntry* deadEntry = entry;
            entry = entry->next;
            *prevNext = entry;
            delete deadEntry;
        }
    }
}

NO_SANITIZE_ADDRESS
void OrphanedPagePool::clearMemory(PageMemory* memory)
{
#if defined(ADDRESS_SANITIZER)
    // Don't use memset when running with ASan since this needs to zap
    // poisoned memory as well and the NO_SANITIZE_ADDRESS annotation
    // only works for code in this method and not for calls to memset.
    Address base = memory->writableStart();
    for (Address current = base; current < base + blinkPagePayloadSize(); ++current)
        *current = 0;
#else
    memset(memory->writableStart(), 0, blinkPagePayloadSize());
#endif
}

#if ENABLE(ASSERT)
bool OrphanedPagePool::contains(void* object)
{
    for (int index = 0; index < NumberOfHeaps; ++index) {
        for (PoolEntry* entry = m_pool[index]; entry; entry = entry->next) {
            BaseHeapPage* page = entry->data;
            if (page->contains(reinterpret_cast<Address>(object)))
                return true;
        }
    }
    return false;
}
#endif

template<>
void ThreadHeap<FinalizedHeapObjectHeader>::addPageToHeap(const GCInfo* gcInfo)
{
    // When adding a page to the ThreadHeap using FinalizedHeapObjectHeaders the GCInfo on
    // the heap should be unused (ie. 0).
    allocatePage(0);
}

template<>
void ThreadHeap<HeapObjectHeader>::addPageToHeap(const GCInfo* gcInfo)
{
    // When adding a page to the ThreadHeap using HeapObjectHeaders store the GCInfo on the heap
    // since it is the same for all objects
    ASSERT(gcInfo);
    allocatePage(gcInfo);
}

template <typename Header>
void ThreadHeap<Header>::removePageFromHeap(HeapPage<Header>* page)
{
    MutexLocker locker(m_threadState->sweepMutex());
    flushHeapContainsCache();
    if (page->terminating()) {
        // The thread is shutting down so this page is being removed as part
        // of a thread local GC. In that case the page could be accessed in the
        // next global GC either due to a dead object being traced via a
        // conservative pointer or due to a programming error where an object
        // in another thread heap keeps a dangling pointer to this object.
        // To guard against this we put the page in the orphanedPagePool to
        // ensure it is still reachable. After the next global GC it can be
        // decommitted and moved to the page pool assuming no rogue/dangling
        // pointers refer to it.
        Heap::orphanedPagePool()->addOrphanedPage(m_index, page);
    } else {
        PageMemory* memory = page->storage();
        page->~HeapPage<Header>();
        Heap::freePagePool()->addFreePage(m_index, memory);
    }
}

template<typename Header>
void ThreadHeap<Header>::allocatePage(const GCInfo* gcInfo)
{
    Heap::flushHeapDoesNotContainCache();
    PageMemory* pageMemory = Heap::freePagePool()->takeFreePage(m_index);
    // We continue allocating page memory until we succeed in getting one.
    // Since the FreePagePool is global other threads could use all the
    // newly allocated page memory before this thread calls takeFreePage.
    while (!pageMemory) {
        // Allocate a memory region for blinkPagesPerRegion pages that
        // will each have the following layout.
        //
        //    [ guard os page | ... payload ... | guard os page ]
        //    ^---{ aligned to blink page size }
        PageMemoryRegion* region = PageMemoryRegion::allocate(blinkPageSize * blinkPagesPerRegion, blinkPagesPerRegion);
        // Setup the PageMemory object for each of the pages in the
        // region.
        size_t offset = 0;
        for (size_t i = 0; i < blinkPagesPerRegion; i++) {
            Heap::freePagePool()->addFreePage(m_index, PageMemory::setupPageMemoryInRegion(region, offset, blinkPagePayloadSize()));
            offset += blinkPageSize;
        }
        pageMemory = Heap::freePagePool()->takeFreePage(m_index);
    }
    HeapPage<Header>* page = new (pageMemory->writableStart()) HeapPage<Header>(pageMemory, this, gcInfo);
    // Use a separate list for pages allocated during sweeping to make
    // sure that we do not accidentally sweep objects that have been
    // allocated during sweeping.
    if (m_threadState->isSweepInProgress()) {
        if (!m_lastPageAllocatedDuringSweeping)
            m_lastPageAllocatedDuringSweeping = page;
        page->link(&m_firstPageAllocatedDuringSweeping);
    } else {
        page->link(&m_firstPage);
    }
    ++m_numberOfNormalPages;
    addToFreeList(page->payload(), HeapPage<Header>::payloadSize());
}

#if ENABLE(ASSERT)
template<typename Header>
bool ThreadHeap<Header>::pagesToBeSweptContains(Address address)
{
    for (HeapPage<Header>* page = m_firstPage; page; page = page->next()) {
        if (page->contains(address))
            return true;
    }
    return false;
}

template<typename Header>
bool ThreadHeap<Header>::pagesAllocatedDuringSweepingContains(Address address)
{
    for (HeapPage<Header>* page = m_firstPageAllocatedDuringSweeping; page; page = page->next()) {
        if (page->contains(address))
            return true;
    }
    return false;
}

template<typename Header>
void ThreadHeap<Header>::getScannedStats(HeapStats& scannedStats)
{
    ASSERT(!m_firstPageAllocatedDuringSweeping);
    for (HeapPage<Header>* page = m_firstPage; page; page = page->next())
        page->getStats(scannedStats);
    for (LargeHeapObject<Header>* current = m_firstLargeHeapObject; current; current = current->next())
        current->getStats(scannedStats);
}
#endif

template<typename Header>
void ThreadHeap<Header>::sweepNormalPages(HeapStats* stats)
{
    HeapPage<Header>* page = m_firstPage;
    HeapPage<Header>** previousNext = &m_firstPage;
    HeapPage<Header>* previous = 0;
    while (page) {
        page->resetPromptlyFreedSize();
        if (page->isEmpty()) {
            HeapPage<Header>* unused = page;
            if (unused == m_mergePoint)
                m_mergePoint = previous;
            page = page->next();
            HeapPage<Header>::unlink(this, unused, previousNext);
            --m_numberOfNormalPages;
        } else {
            page->sweep(stats, this);
            previousNext = &page->m_next;
            previous = page;
            page = page->next();
        }
    }
}

template<typename Header>
void ThreadHeap<Header>::sweepLargePages(HeapStats* stats)
{
    LargeHeapObject<Header>** previousNext = &m_firstLargeHeapObject;
    for (LargeHeapObject<Header>* current = m_firstLargeHeapObject; current;) {
        if (current->isMarked()) {
            stats->increaseAllocatedSpace(current->size());
            stats->increaseObjectSpace(current->payloadSize());
            current->unmark();
            previousNext = &current->m_next;
            current = current->next();
        } else {
            LargeHeapObject<Header>* next = current->next();
            freeLargeObject(current, previousNext);
            current = next;
        }
    }
}


// STRICT_ASAN_finalIZATION_CHECKING turns on poisoning of all objects during
// sweeping to catch cases where dead objects touch each other. This is not
// turned on by default because it also triggers for cases that are safe.
// Examples of such safe cases are context life cycle observers and timers
// embedded in garbage collected objects.
#define STRICT_ASAN_finalIZATION_CHECKING 0

template<typename Header>
void ThreadHeap<Header>::sweep(HeapStats* stats)
{
    ASSERT(isConsistentForSweeping());
#if defined(ADDRESS_SANITIZER) && STRICT_ASAN_finalIZATION_CHECKING
    // When using ASan do a pre-sweep where all unmarked objects are
    // poisoned before calling their finalizer methods. This can catch
    // the case where the finalizer of an object tries to modify
    // another object as part of finalization.
    for (HeapPage<Header>* page = m_firstPage; page; page = page->next())
        page->poisonUnmarkedObjects();
#endif
    sweepNormalPages(stats);
    sweepLargePages(stats);
}

template<typename Header>
void ThreadHeap<Header>::postSweepProcessing()
{
    // If pages have been allocated during sweeping, link them into
    // the list of pages.
    if (m_firstPageAllocatedDuringSweeping) {
        m_lastPageAllocatedDuringSweeping->m_next = m_firstPage;
        m_firstPage = m_firstPageAllocatedDuringSweeping;
        m_lastPageAllocatedDuringSweeping = 0;
        m_firstPageAllocatedDuringSweeping = 0;
    }
}

#if ENABLE(ASSERT)
template<typename Header>
bool ThreadHeap<Header>::isConsistentForSweeping()
{
    // A thread heap is consistent for sweeping if none of the pages to
    // be swept contain a freelist block or the current allocation
    // point.
    for (size_t i = 0; i < blinkPageSizeLog2; i++) {
        for (FreeListEntry* freeListEntry = m_freeLists[i]; freeListEntry; freeListEntry = freeListEntry->next()) {
            if (pagesToBeSweptContains(freeListEntry->address())) {
                return false;
            }
            ASSERT(pagesAllocatedDuringSweepingContains(freeListEntry->address()));
        }
    }
    if (ownsNonEmptyAllocationArea()) {
        ASSERT(pagesToBeSweptContains(currentAllocationPoint())
            || pagesAllocatedDuringSweepingContains(currentAllocationPoint()));
        return !pagesToBeSweptContains(currentAllocationPoint());
    }
    return true;
}
#endif

template<typename Header>
void ThreadHeap<Header>::makeConsistentForSweeping()
{
    if (ownsNonEmptyAllocationArea())
        addToFreeList(currentAllocationPoint(), remainingAllocationSize());
    setAllocationPoint(0, 0);
    clearFreeLists();
}

template<typename Header>
void ThreadHeap<Header>::clearLiveAndMarkDead()
{
    ASSERT(isConsistentForSweeping());
    for (HeapPage<Header>* page = m_firstPage; page; page = page->next())
        page->clearLiveAndMarkDead();
    for (LargeHeapObject<Header>* current = m_firstLargeHeapObject; current; current = current->next()) {
        if (current->isMarked())
            current->unmark();
        else
            current->setDeadMark();
    }
}

template<typename Header>
void ThreadHeap<Header>::clearFreeLists()
{
    m_promptlyFreedCount = 0;
    for (size_t i = 0; i < blinkPageSizeLog2; i++) {
        m_freeLists[i] = 0;
        m_lastFreeListEntries[i] = 0;
    }
}

int BaseHeap::bucketIndexForSize(size_t size)
{
    ASSERT(size > 0);
    int index = -1;
    while (size) {
        size >>= 1;
        index++;
    }
    return index;
}

template<typename Header>
HeapPage<Header>::HeapPage(PageMemory* storage, ThreadHeap<Header>* heap, const GCInfo* gcInfo)
    : BaseHeapPage(storage, gcInfo, heap->threadState())
    , m_next(0)
{
    COMPILE_ASSERT(!(sizeof(HeapPage<Header>) & allocationMask), page_header_incorrectly_aligned);
    m_objectStartBitMapComputed = false;
    ASSERT(isPageHeaderAddress(reinterpret_cast<Address>(this)));
    heap->stats().increaseAllocatedSpace(blinkPageSize);
}

template<typename Header>
void HeapPage<Header>::link(HeapPage** prevNext)
{
    m_next = *prevNext;
    *prevNext = this;
}

template<typename Header>
void HeapPage<Header>::unlink(ThreadHeap<Header>* heap, HeapPage* unused, HeapPage** prevNext)
{
    *prevNext = unused->m_next;
    heap->removePageFromHeap(unused);
}

template<typename Header>
void HeapPage<Header>::getStats(HeapStats& stats)
{
    stats.increaseAllocatedSpace(blinkPageSize);
    Address headerAddress = payload();
    ASSERT(headerAddress != end());
    do {
        Header* header = reinterpret_cast<Header*>(headerAddress);
        if (!header->isFree())
            stats.increaseObjectSpace(header->payloadSize());
        ASSERT(header->size() < blinkPagePayloadSize());
        headerAddress += header->size();
        ASSERT(headerAddress <= end());
    } while (headerAddress < end());
}

template<typename Header>
bool HeapPage<Header>::isEmpty()
{
    BasicObjectHeader* header = reinterpret_cast<BasicObjectHeader*>(payload());
    return header->isFree() && (header->size() == payloadSize());
}

template<typename Header>
void HeapPage<Header>::sweep(HeapStats* stats, ThreadHeap<Header>* heap)
{
    clearObjectStartBitMap();
    stats->increaseAllocatedSpace(blinkPageSize);
    Address startOfGap = payload();
    for (Address headerAddress = startOfGap; headerAddress < end(); ) {
        BasicObjectHeader* basicHeader = reinterpret_cast<BasicObjectHeader*>(headerAddress);
        ASSERT(basicHeader->size() > 0);
        ASSERT(basicHeader->size() < blinkPagePayloadSize());

        if (basicHeader->isFree()) {
            size_t size = basicHeader->size();
#if !ENABLE(ASSERT) && !defined(LEAK_SANITIZER) && !defined(ADDRESS_SANITIZER)
            // Zero the memory in the free list header to maintain the
            // invariant that memory on the free list is zero filled.
            // The rest of the memory is already on the free list and is
            // therefore already zero filled.
            if (size < sizeof(FreeListEntry))
                memset(headerAddress, 0, size);
            else
                memset(headerAddress, 0, sizeof(FreeListEntry));
#endif
            headerAddress += size;
            continue;
        }
        // At this point we know this is a valid object of type Header
        Header* header = static_cast<Header*>(basicHeader);

        if (!header->isMarked()) {
            // For ASan we unpoison the specific object when calling the finalizer and
            // poison it again when done to allow the object's own finalizer to operate
            // on the object, but not have other finalizers be allowed to access it.
            ASAN_UNPOISON_MEMORY_REGION(header->payload(), header->payloadSize());
            finalize(header);
            size_t size = header->size();
#if !ENABLE(ASSERT) && !defined(LEAK_SANITIZER) && !defined(ADDRESS_SANITIZER)
            // This memory will be added to the freelist. Maintain the invariant
            // that memory on the freelist is zero filled.
            memset(headerAddress, 0, size);
#endif
            ASAN_POISON_MEMORY_REGION(header->payload(), header->payloadSize());
            headerAddress += size;
            continue;
        }

        if (startOfGap != headerAddress)
            heap->addToFreeList(startOfGap, headerAddress - startOfGap);
        header->unmark();
        headerAddress += header->size();
        stats->increaseObjectSpace(header->payloadSize());
        startOfGap = headerAddress;
    }
    if (startOfGap != end())
        heap->addToFreeList(startOfGap, end() - startOfGap);
}

template<typename Header>
void HeapPage<Header>::clearLiveAndMarkDead()
{
    for (Address headerAddress = payload(); headerAddress < end();) {
        Header* header = reinterpret_cast<Header*>(headerAddress);
        ASSERT(header->size() < blinkPagePayloadSize());
        // Check if a free list entry first since we cannot call
        // isMarked on a free list entry.
        if (header->isFree()) {
            headerAddress += header->size();
            continue;
        }
        if (header->isMarked())
            header->unmark();
        else
            header->setDeadMark();
        headerAddress += header->size();
    }
}

template<typename Header>
void HeapPage<Header>::populateObjectStartBitMap()
{
    memset(&m_objectStartBitMap, 0, objectStartBitMapSize);
    Address start = payload();
    for (Address headerAddress = start; headerAddress < end();) {
        Header* header = reinterpret_cast<Header*>(headerAddress);
        size_t objectOffset = headerAddress - start;
        ASSERT(!(objectOffset & allocationMask));
        size_t objectStartNumber = objectOffset / allocationGranularity;
        size_t mapIndex = objectStartNumber / 8;
        ASSERT(mapIndex < objectStartBitMapSize);
        m_objectStartBitMap[mapIndex] |= (1 << (objectStartNumber & 7));
        headerAddress += header->size();
        ASSERT(headerAddress <= end());
    }
    m_objectStartBitMapComputed = true;
}

template<typename Header>
void HeapPage<Header>::clearObjectStartBitMap()
{
    m_objectStartBitMapComputed = false;
}

static int numberOfLeadingZeroes(uint8_t byte)
{
    if (!byte)
        return 8;
    int result = 0;
    if (byte <= 0x0F) {
        result += 4;
        byte = byte << 4;
    }
    if (byte <= 0x3F) {
        result += 2;
        byte = byte << 2;
    }
    if (byte <= 0x7F)
        result++;
    return result;
}

template<typename Header>
Header* HeapPage<Header>::findHeaderFromAddress(Address address)
{
    if (address < payload())
        return 0;
    if (!isObjectStartBitMapComputed())
        populateObjectStartBitMap();
    size_t objectOffset = address - payload();
    size_t objectStartNumber = objectOffset / allocationGranularity;
    size_t mapIndex = objectStartNumber / 8;
    ASSERT(mapIndex < objectStartBitMapSize);
    size_t bit = objectStartNumber & 7;
    uint8_t byte = m_objectStartBitMap[mapIndex] & ((1 << (bit + 1)) - 1);
    while (!byte) {
        ASSERT(mapIndex > 0);
        byte = m_objectStartBitMap[--mapIndex];
    }
    int leadingZeroes = numberOfLeadingZeroes(byte);
    objectStartNumber = (mapIndex * 8) + 7 - leadingZeroes;
    objectOffset = objectStartNumber * allocationGranularity;
    Address objectAddress = objectOffset + payload();
    Header* header = reinterpret_cast<Header*>(objectAddress);
    if (header->isFree())
        return 0;
    return header;
}

template<typename Header>
void HeapPage<Header>::checkAndMarkPointer(Visitor* visitor, Address address)
{
    ASSERT(contains(address));
    Header* header = findHeaderFromAddress(address);
    if (!header || header->hasDeadMark())
        return;

#if ENABLE(GC_PROFILE_MARKING)
    visitor->setHostInfo(&address, "stack");
#endif
    if (hasVTable(header) && !vTableInitialized(header->payload())) {
        visitor->markNoTracing(header);
        ASSERT(isUninitializedMemory(header->payload(), header->payloadSize()));
    } else {
        visitor->mark(header, traceCallback(header));
    }
}

#if ENABLE(GC_PROFILE_MARKING)
template<typename Header>
const GCInfo* HeapPage<Header>::findGCInfo(Address address)
{
    if (address < payload())
        return 0;

    if (gcInfo()) // for non FinalizedObjectHeader
        return gcInfo();

    Header* header = findHeaderFromAddress(address);
    if (!header)
        return 0;

    return header->gcInfo();
}
#endif

#if ENABLE(GC_PROFILE_HEAP)
template<typename Header>
void HeapPage<Header>::snapshot(TracedValue* json, ThreadState::SnapshotInfo* info)
{
    Header* header = 0;
    for (Address addr = payload(); addr < end(); addr += header->size()) {
        header = reinterpret_cast<Header*>(addr);
        if (json)
            json->pushInteger(header->encodedSize());
        if (header->isFree()) {
            info->freeSize += header->size();
            continue;
        }

        const GCInfo* gcinfo = header->gcInfo() ? header->gcInfo() : gcInfo();
        size_t tag = info->getClassTag(gcinfo);
        size_t age = header->age();
        if (json)
            json->pushInteger(tag);
        if (header->isMarked()) {
            info->liveCount[tag] += 1;
            info->liveSize[tag] += header->size();
            // Count objects that are live when promoted to the final generation.
            if (age == maxHeapObjectAge - 1)
                info->generations[tag][maxHeapObjectAge] += 1;
            header->incAge();
        } else {
            info->deadCount[tag] += 1;
            info->deadSize[tag] += header->size();
            // Count objects that are dead before the final generation.
            if (age < maxHeapObjectAge)
                info->generations[tag][age] += 1;
        }
    }
}
#endif

#if defined(ADDRESS_SANITIZER)
template<typename Header>
void HeapPage<Header>::poisonUnmarkedObjects()
{
    for (Address headerAddress = payload(); headerAddress < end(); ) {
        Header* header = reinterpret_cast<Header*>(headerAddress);
        ASSERT(header->size() < blinkPagePayloadSize());

        if (!header->isFree() && !header->isMarked())
            ASAN_POISON_MEMORY_REGION(header->payload(), header->payloadSize());
        headerAddress += header->size();
    }
}
#endif

template<>
inline void HeapPage<FinalizedHeapObjectHeader>::finalize(FinalizedHeapObjectHeader* header)
{
    header->finalize();
}

template<>
inline void HeapPage<HeapObjectHeader>::finalize(HeapObjectHeader* header)
{
    ASSERT(gcInfo());
    HeapObjectHeader::finalize(gcInfo(), header->payload(), header->payloadSize());
}

template<>
inline TraceCallback HeapPage<HeapObjectHeader>::traceCallback(HeapObjectHeader* header)
{
    ASSERT(gcInfo());
    return gcInfo()->m_trace;
}

template<>
inline TraceCallback HeapPage<FinalizedHeapObjectHeader>::traceCallback(FinalizedHeapObjectHeader* header)
{
    return header->traceCallback();
}

template<>
inline bool HeapPage<HeapObjectHeader>::hasVTable(HeapObjectHeader* header)
{
    ASSERT(gcInfo());
    return gcInfo()->hasVTable();
}

template<>
inline bool HeapPage<FinalizedHeapObjectHeader>::hasVTable(FinalizedHeapObjectHeader* header)
{
    return header->hasVTable();
}

template<typename Header>
void LargeHeapObject<Header>::getStats(HeapStats& stats)
{
    stats.increaseAllocatedSpace(size());
    stats.increaseObjectSpace(payloadSize());
}

#if ENABLE(GC_PROFILE_HEAP)
template<typename Header>
void LargeHeapObject<Header>::snapshot(TracedValue* json, ThreadState::SnapshotInfo* info)
{
    Header* header = heapObjectHeader();
    size_t tag = info->getClassTag(header->gcInfo());
    size_t age = header->age();
    if (isMarked()) {
        info->liveCount[tag] += 1;
        info->liveSize[tag] += header->size();
        // Count objects that are live when promoted to the final generation.
        if (age == maxHeapObjectAge - 1)
            info->generations[tag][maxHeapObjectAge] += 1;
        header->incAge();
    } else {
        info->deadCount[tag] += 1;
        info->deadSize[tag] += header->size();
        // Count objects that are dead before the final generation.
        if (age < maxHeapObjectAge)
            info->generations[tag][age] += 1;
    }

    if (json) {
        json->setInteger("class", tag);
        json->setInteger("size", header->size());
        json->setInteger("isMarked", isMarked());
    }
}
#endif

template<typename Entry>
void HeapExtentCache<Entry>::flush()
{
    if (m_hasEntries) {
        for (int i = 0; i < numberOfEntries; i++)
            m_entries[i] = Entry();
        m_hasEntries = false;
    }
}

template<typename Entry>
size_t HeapExtentCache<Entry>::hash(Address address)
{
    size_t value = (reinterpret_cast<size_t>(address) >> blinkPageSizeLog2);
    value ^= value >> numberOfEntriesLog2;
    value ^= value >> (numberOfEntriesLog2 * 2);
    value &= numberOfEntries - 1;
    return value & ~1; // Returns only even number.
}

template<typename Entry>
typename Entry::LookupResult HeapExtentCache<Entry>::lookup(Address address)
{
    size_t index = hash(address);
    ASSERT(!(index & 1));
    Address cachePage = roundToBlinkPageStart(address);
    if (m_entries[index].address() == cachePage)
        return m_entries[index].result();
    if (m_entries[index + 1].address() == cachePage)
        return m_entries[index + 1].result();
    return 0;
}

template<typename Entry>
void HeapExtentCache<Entry>::addEntry(Address address, typename Entry::LookupResult entry)
{
    m_hasEntries = true;
    size_t index = hash(address);
    ASSERT(!(index & 1));
    Address cachePage = roundToBlinkPageStart(address);
    m_entries[index + 1] = m_entries[index];
    m_entries[index] = Entry(cachePage, entry);
}

// These should not be needed, but it seems impossible to persuade clang to
// instantiate the template functions and export them from a shared library, so
// we add these in the non-templated subclass, which does not have that issue.
void HeapContainsCache::addEntry(Address address, BaseHeapPage* page)
{
    HeapExtentCache<PositiveEntry>::addEntry(address, page);
}

BaseHeapPage* HeapContainsCache::lookup(Address address)
{
    return HeapExtentCache<PositiveEntry>::lookup(address);
}

void Heap::flushHeapDoesNotContainCache()
{
    s_heapDoesNotContainCache->flush();
}

void CallbackStack::init(CallbackStack** first)
{
    // The stacks are chained, so we start by setting this to null as terminator.
    *first = 0;
    *first = new CallbackStack(first);
}

void CallbackStack::shutdown(CallbackStack** first)
{
    CallbackStack* next;
    for (CallbackStack* current = *first; current; current = next) {
        next = current->m_next;
        delete current;
    }
    *first = 0;
}

CallbackStack::~CallbackStack()
{
#if ENABLE(ASSERT)
    clearUnused();
#endif
}

void CallbackStack::clearUnused()
{
    for (size_t i = 0; i < bufferSize; i++)
        m_buffer[i] = Item(0, 0);
}

bool CallbackStack::isEmpty()
{
    return currentBlockIsEmpty() && !m_next;
}

CallbackStack* CallbackStack::takeCallbacks(CallbackStack** first)
{
    // If there is a full next block unlink and return it.
    if (m_next) {
        CallbackStack* result = m_next;
        m_next = result->m_next;
        result->m_next = 0;
        return result;
    }
    // Only the current block is in the stack. If the current block is
    // empty return 0.
    if (currentBlockIsEmpty())
        return 0;
    // The current block is not empty. Return this block and insert a
    // new empty block as the marking stack.
    *first = 0;
    *first = new CallbackStack(first);
    return this;
}

template<CallbackInvocationMode Mode>
bool CallbackStack::popAndInvokeCallback(CallbackStack** first, Visitor* visitor)
{
    if (currentBlockIsEmpty()) {
        if (!m_next) {
#if ENABLE(ASSERT)
            clearUnused();
#endif
            return false;
        }
        CallbackStack* nextStack = m_next;
        *first = nextStack;
        delete this;
        return nextStack->popAndInvokeCallback<Mode>(first, visitor);
    }
    Item* item = --m_current;

    // If the object being traced is located on a page which is dead don't
    // trace it. This can happen when a conservative GC kept a dead object
    // alive which pointed to a (now gone) object on the cleaned up page.
    // Also if doing a thread local GC don't trace objects that are located
    // on other thread's heaps, ie. pages where the terminating flag is not
    // set.
    BaseHeapPage* heapPage = pageHeaderFromObject(item->object());
    if (Mode == GlobalMarking && heapPage->orphaned()) {
        // When doing a global GC we should only get a trace callback to an orphaned
        // page if the GC is conservative. If it is not conservative there is
        // a bug in the code where we have a dangling pointer to a page
        // on the dead thread.
        RELEASE_ASSERT(Heap::lastGCWasConservative());
        heapPage->setTracedAfterOrphaned();
        return true;
    }
    if (Mode == ThreadLocalMarking && (heapPage->orphaned() || !heapPage->terminating()))
        return true;
    // For WeaknessProcessing we should never reach orphaned pages since
    // they should never be registered as objects on orphaned pages are not
    // traced. We cannot assert this here since we might have an off-heap
    // collection. However we assert it in Heap::pushWeakObjectPointerCallback.

    VisitorCallback callback = item->callback();
#if ENABLE(GC_PROFILE_MARKING)
    if (ThreadState::isAnyThreadInGC()) // weak-processing will also use popAndInvokeCallback
        visitor->setHostInfo(item->object(), classOf(item->object()));
#endif
    callback(visitor, item->object());

    return true;
}

void CallbackStack::invokeCallbacks(CallbackStack** first, Visitor* visitor)
{
    CallbackStack* stack = 0;
    // The first block is the only one where new ephemerons are added, so we
    // call the callbacks on that last, to catch any new ephemerons discovered
    // in the callbacks.
    // However, if enough ephemerons were added, we may have a new block that
    // has been prepended to the chain. This will be very rare, but we can
    // handle the situation by starting again and calling all the callbacks
    // a second time.
    while (stack != *first) {
        stack = *first;
        stack->invokeOldestCallbacks(visitor);
    }
}

void CallbackStack::invokeOldestCallbacks(Visitor* visitor)
{
    // Recurse first (bufferSize at a time) so we get to the newly added entries
    // last.
    if (m_next)
        m_next->invokeOldestCallbacks(visitor);

    // This loop can tolerate entries being added by the callbacks after
    // iteration starts.
    for (unsigned i = 0; m_buffer + i < m_current; i++) {
        Item& item = m_buffer[i];

        // We don't need to check for orphaned pages when popping an ephemeron
        // callback since the callback is only pushed after the object containing
        // it has been traced. There are basically three cases to consider:
        // 1. Member<EphemeronCollection>
        // 2. EphemeronCollection is part of a containing object
        // 3. EphemeronCollection is a value object in a collection
        //
        // Ad. 1. In this case we push the start of the ephemeron on the
        // marking stack and do the orphaned page check when popping it off
        // the marking stack.
        // Ad. 2. The containing object cannot be on an orphaned page since
        // in that case we wouldn't have traced its parts. This also means
        // the ephemeron collection is not on the orphaned page.
        // Ad. 3. Is the same as 2. The collection containing the ephemeron
        // collection as a value object cannot be on an orphaned page since
        // it would not have traced its values in that case.
        item.callback()(visitor, item.object());
    }
}

#if ENABLE(ASSERT)
bool CallbackStack::hasCallbackForObject(const void* object)
{
    for (unsigned i = 0; m_buffer + i < m_current; i++) {
        Item* item = &m_buffer[i];
        if (item->object() == object) {
            return true;
        }
    }
    if (m_next)
        return m_next->hasCallbackForObject(object);

    return false;
}
#endif

// The marking mutex is used to ensure sequential access to data
// structures during marking. The marking mutex needs to be acquired
// during marking when elements are taken from the global marking
// stack or when elements are added to the global ephemeron,
// post-marking, and weak processing stacks. In debug mode the mutex
// also needs to be acquired when asserts use the heap contains
// caches.
static Mutex& markingMutex()
{
    AtomicallyInitializedStatic(Mutex&, mutex = *new Mutex);
    return mutex;
}

static ThreadCondition& markingCondition()
{
    AtomicallyInitializedStatic(ThreadCondition&, condition = *new ThreadCondition);
    return condition;
}

static void markNoTracingCallback(Visitor* visitor, void* object)
{
    visitor->markNoTracing(object);
}

class MarkingVisitor : public Visitor {
public:
#if ENABLE(GC_PROFILE_MARKING)
    typedef HashSet<uintptr_t> LiveObjectSet;
    typedef HashMap<String, LiveObjectSet> LiveObjectMap;
    typedef HashMap<uintptr_t, std::pair<uintptr_t, String> > ObjectGraph;
#endif

    MarkingVisitor(CallbackStack** markingStack) : m_markingStack(markingStack)
    {
    }

    inline void visitHeader(HeapObjectHeader* header, const void* objectPointer, TraceCallback callback)
    {
        ASSERT(header);
#if ENABLE(ASSERT)
        {
            // Check that we are not marking objects that are outside
            // the heap by calling Heap::contains. However we cannot
            // call Heap::contains when outside a GC and we call mark
            // when doing weakness for ephemerons. Hence we only check
            // when called within.
            MutexLocker locker(markingMutex());
            ASSERT(!ThreadState::isAnyThreadInGC() || Heap::containedInHeapOrOrphanedPage(header));
        }
#endif
        ASSERT(objectPointer);
        if (header->isMarked())
            return;
        header->mark();
#if ENABLE(GC_PROFILE_MARKING)
        MutexLocker locker(objectGraphMutex());
        String className(classOf(objectPointer));
        {
            LiveObjectMap::AddResult result = currentlyLive().add(className, LiveObjectSet());
            result.storedValue->value.add(reinterpret_cast<uintptr_t>(objectPointer));
        }
        ObjectGraph::AddResult result = objectGraph().add(reinterpret_cast<uintptr_t>(objectPointer), std::make_pair(reinterpret_cast<uintptr_t>(m_hostObject), m_hostName));
        ASSERT(result.isNewEntry);
        // fprintf(stderr, "%s[%p] -> %s[%p]\n", m_hostName.ascii().data(), m_hostObject, className.ascii().data(), objectPointer);
#endif
        if (callback)
            Heap::pushTraceCallback(m_markingStack, const_cast<void*>(objectPointer), callback);
    }

    virtual void mark(HeapObjectHeader* header, TraceCallback callback) override
    {
        // We need both the HeapObjectHeader and FinalizedHeapObjectHeader
        // version to correctly find the payload.
        visitHeader(header, header->payload(), callback);
    }

    virtual void mark(FinalizedHeapObjectHeader* header, TraceCallback callback) override
    {
        // We need both the HeapObjectHeader and FinalizedHeapObjectHeader
        // version to correctly find the payload.
        visitHeader(header, header->payload(), callback);
    }

    virtual void mark(const void* objectPointer, TraceCallback callback) override
    {
        if (!objectPointer)
            return;
        FinalizedHeapObjectHeader* header = FinalizedHeapObjectHeader::fromPayload(objectPointer);
        visitHeader(header, header->payload(), callback);
    }

    virtual void registerDelayedMarkNoTracing(const void* object) override
    {
        Heap::pushPostMarkingCallback(const_cast<void*>(object), markNoTracingCallback);
    }

    virtual void registerWeakMembers(const void* closure, const void* containingObject, WeakPointerCallback callback) override
    {
        Heap::pushWeakObjectPointerCallback(const_cast<void*>(closure), const_cast<void*>(containingObject), callback);
    }

    virtual void registerWeakTable(const void* closure, EphemeronCallback iterationCallback, EphemeronCallback iterationDoneCallback)
    {
        Heap::registerWeakTable(const_cast<void*>(closure), iterationCallback, iterationDoneCallback);
    }

#if ENABLE(ASSERT)
    virtual bool weakTableRegistered(const void* closure)
    {
        return Heap::weakTableRegistered(closure);
    }
#endif

    virtual bool isMarked(const void* objectPointer) override
    {
        return FinalizedHeapObjectHeader::fromPayload(objectPointer)->isMarked();
    }

    // This macro defines the necessary visitor methods for typed heaps
#define DEFINE_VISITOR_METHODS(Type)                                              \
    virtual void mark(const Type* objectPointer, TraceCallback callback) override \
    {                                                                             \
        if (!objectPointer)                                                       \
            return;                                                               \
        HeapObjectHeader* header =                                                \
            HeapObjectHeader::fromPayload(objectPointer);                         \
        visitHeader(header, header->payload(), callback);                         \
    }                                                                             \
    virtual bool isMarked(const Type* objectPointer) override                     \
    {                                                                             \
        return HeapObjectHeader::fromPayload(objectPointer)->isMarked();          \
    }

    FOR_EACH_TYPED_HEAP(DEFINE_VISITOR_METHODS)
#undef DEFINE_VISITOR_METHODS

#if ENABLE(GC_PROFILE_MARKING)
    void reportStats()
    {
        fprintf(stderr, "\n---------- AFTER MARKING -------------------\n");
        for (LiveObjectMap::iterator it = currentlyLive().begin(), end = currentlyLive().end(); it != end; ++it) {
            fprintf(stderr, "%s %u", it->key.ascii().data(), it->value.size());

            if (it->key == "blink::Document")
                reportStillAlive(it->value, previouslyLive().get(it->key));

            fprintf(stderr, "\n");
        }

        previouslyLive().swap(currentlyLive());
        currentlyLive().clear();

        for (HashSet<uintptr_t>::iterator it = objectsToFindPath().begin(), end = objectsToFindPath().end(); it != end; ++it) {
            dumpPathToObjectFromObjectGraph(objectGraph(), *it);
        }
    }

    static void reportStillAlive(LiveObjectSet current, LiveObjectSet previous)
    {
        int count = 0;

        fprintf(stderr, " [previously %u]", previous.size());
        for (LiveObjectSet::iterator it = current.begin(), end = current.end(); it != end; ++it) {
            if (previous.find(*it) == previous.end())
                continue;
            count++;
        }

        if (!count)
            return;

        fprintf(stderr, " {survived 2GCs %d: ", count);
        for (LiveObjectSet::iterator it = current.begin(), end = current.end(); it != end; ++it) {
            if (previous.find(*it) == previous.end())
                continue;
            fprintf(stderr, "%ld", *it);
            if (--count)
                fprintf(stderr, ", ");
        }
        ASSERT(!count);
        fprintf(stderr, "}");
    }

    static void dumpPathToObjectFromObjectGraph(const ObjectGraph& graph, uintptr_t target)
    {
        ObjectGraph::const_iterator it = graph.find(target);
        if (it == graph.end())
            return;
        fprintf(stderr, "Path to %lx of %s\n", target, classOf(reinterpret_cast<const void*>(target)).ascii().data());
        while (it != graph.end()) {
            fprintf(stderr, "<- %lx of %s\n", it->value.first, it->value.second.utf8().data());
            it = graph.find(it->value.first);
        }
        fprintf(stderr, "\n");
    }

    static void dumpPathToObjectOnNextGC(void* p)
    {
        objectsToFindPath().add(reinterpret_cast<uintptr_t>(p));
    }

    static Mutex& objectGraphMutex()
    {
        AtomicallyInitializedStatic(Mutex&, mutex = *new Mutex);
        return mutex;
    }

    static LiveObjectMap& previouslyLive()
    {
        DEFINE_STATIC_LOCAL(LiveObjectMap, map, ());
        return map;
    }

    static LiveObjectMap& currentlyLive()
    {
        DEFINE_STATIC_LOCAL(LiveObjectMap, map, ());
        return map;
    }

    static ObjectGraph& objectGraph()
    {
        DEFINE_STATIC_LOCAL(ObjectGraph, graph, ());
        return graph;
    }

    static HashSet<uintptr_t>& objectsToFindPath()
    {
        DEFINE_STATIC_LOCAL(HashSet<uintptr_t>, set, ());
        return set;
    }
#endif

protected:
    virtual void registerWeakCell(void** cell, WeakPointerCallback callback) override
    {
        Heap::pushWeakCellPointerCallback(cell, callback);
    }

private:
    CallbackStack** m_markingStack;
};

void Heap::init()
{
    ThreadState::init();
    CallbackStack::init(&s_markingStack);
    CallbackStack::init(&s_postMarkingCallbackStack);
    CallbackStack::init(&s_weakCallbackStack);
    CallbackStack::init(&s_ephemeronStack);
    s_heapDoesNotContainCache = new HeapDoesNotContainCache();
    s_markingVisitor = new MarkingVisitor(&s_markingStack);
    s_freePagePool = new FreePagePool();
    s_orphanedPagePool = new OrphanedPagePool();
    s_markingThreads = new Vector<OwnPtr<blink::WebThread> >();
}

void Heap::shutdown()
{
    s_shutdownCalled = true;
    ThreadState::shutdownHeapIfNecessary();
}

void Heap::doShutdown()
{
    // We don't want to call doShutdown() twice.
    if (!s_markingVisitor)
        return;

    ASSERT(!ThreadState::isAnyThreadInGC());
    ASSERT(!ThreadState::attachedThreads().size());
    delete s_markingThreads;
    s_markingThreads = 0;
    delete s_markingVisitor;
    s_markingVisitor = 0;
    delete s_heapDoesNotContainCache;
    s_heapDoesNotContainCache = 0;
    delete s_freePagePool;
    s_freePagePool = 0;
    delete s_orphanedPagePool;
    s_orphanedPagePool = 0;
    CallbackStack::shutdown(&s_weakCallbackStack);
    CallbackStack::shutdown(&s_postMarkingCallbackStack);
    CallbackStack::shutdown(&s_markingStack);
    CallbackStack::shutdown(&s_ephemeronStack);
    ThreadState::shutdown();
}

BaseHeapPage* Heap::contains(Address address)
{
    ASSERT(ThreadState::isAnyThreadInGC());
    ThreadState::AttachedThreadStateSet& threads = ThreadState::attachedThreads();
    for (ThreadState::AttachedThreadStateSet::iterator it = threads.begin(), end = threads.end(); it != end; ++it) {
        BaseHeapPage* page = (*it)->contains(address);
        if (page)
            return page;
    }
    return 0;
}

#if ENABLE(ASSERT)
bool Heap::containedInHeapOrOrphanedPage(void* object)
{
    return contains(object) || orphanedPagePool()->contains(object);
}
#endif

Address Heap::checkAndMarkPointer(Visitor* visitor, Address address)
{
    ASSERT(ThreadState::isAnyThreadInGC());

#if !ENABLE(ASSERT)
    if (s_heapDoesNotContainCache->lookup(address))
        return 0;
#endif

    ThreadState::AttachedThreadStateSet& threads = ThreadState::attachedThreads();
    for (ThreadState::AttachedThreadStateSet::iterator it = threads.begin(), end = threads.end(); it != end; ++it) {
        if ((*it)->checkAndMarkPointer(visitor, address)) {
            // Pointer was in a page of that thread. If it actually pointed
            // into an object then that object was found and marked.
            ASSERT(!s_heapDoesNotContainCache->lookup(address));
            s_lastGCWasConservative = true;
            return address;
        }
    }

#if !ENABLE(ASSERT)
    s_heapDoesNotContainCache->addEntry(address, true);
#else
    if (!s_heapDoesNotContainCache->lookup(address))
        s_heapDoesNotContainCache->addEntry(address, true);
#endif
    return 0;
}

#if ENABLE(GC_PROFILE_MARKING)
const GCInfo* Heap::findGCInfo(Address address)
{
    return ThreadState::findGCInfoFromAllThreads(address);
}
#endif

#if ENABLE(GC_PROFILE_MARKING)
void Heap::dumpPathToObjectOnNextGC(void* p)
{
    static_cast<MarkingVisitor*>(s_markingVisitor)->dumpPathToObjectOnNextGC(p);
}

String Heap::createBacktraceString()
{
    int framesToShow = 3;
    int stackFrameSize = 16;
    ASSERT(stackFrameSize >= framesToShow);
    typedef void* FramePointer;
    FramePointer* stackFrame = static_cast<FramePointer*>(alloca(sizeof(FramePointer) * stackFrameSize));
    WTFGetBacktrace(stackFrame, &stackFrameSize);

    StringBuilder builder;
    builder.append("Persistent");
    bool didAppendFirstName = false;
    // Skip frames before/including "blink::Persistent".
    bool didSeePersistent = false;
    for (int i = 0; i < stackFrameSize && framesToShow > 0; ++i) {
        FrameToNameScope frameToName(stackFrame[i]);
        if (!frameToName.nullableName())
            continue;
        if (strstr(frameToName.nullableName(), "blink::Persistent")) {
            didSeePersistent = true;
            continue;
        }
        if (!didSeePersistent)
            continue;
        if (!didAppendFirstName) {
            didAppendFirstName = true;
            builder.append(" ... Backtrace:");
        }
        builder.append("\n\t");
        builder.append(frameToName.nullableName());
        --framesToShow;
    }
    return builder.toString().replace("blink::", "");
}
#endif

void Heap::pushTraceCallback(CallbackStack** stack, void* object, TraceCallback callback)
{
#if ENABLE(ASSERT)
    {
        MutexLocker locker(markingMutex());
        ASSERT(Heap::containedInHeapOrOrphanedPage(object));
    }
#endif
    CallbackStack::Item* slot = (*stack)->allocateEntry(stack);
    *slot = CallbackStack::Item(object, callback);
}

template<CallbackInvocationMode Mode>
bool Heap::popAndInvokeTraceCallback(Visitor* visitor)
{
    return s_markingStack->popAndInvokeCallback<Mode>(&s_markingStack, visitor);
}

void Heap::pushPostMarkingCallback(void* object, TraceCallback callback)
{
    MutexLocker locker(markingMutex());
    ASSERT(!Heap::orphanedPagePool()->contains(object));
    CallbackStack::Item* slot = s_postMarkingCallbackStack->allocateEntry(&s_postMarkingCallbackStack);
    *slot = CallbackStack::Item(object, callback);
}

bool Heap::popAndInvokePostMarkingCallback(Visitor* visitor)
{
    return s_postMarkingCallbackStack->popAndInvokeCallback<PostMarking>(&s_postMarkingCallbackStack, visitor);
}

void Heap::pushWeakCellPointerCallback(void** cell, WeakPointerCallback callback)
{
    MutexLocker locker(markingMutex());
    ASSERT(!Heap::orphanedPagePool()->contains(cell));
    CallbackStack::Item* slot = s_weakCallbackStack->allocateEntry(&s_weakCallbackStack);
    *slot = CallbackStack::Item(cell, callback);
}

void Heap::pushWeakObjectPointerCallback(void* closure, void* object, WeakPointerCallback callback)
{
    MutexLocker locker(markingMutex());
    ASSERT(Heap::contains(object));
    BaseHeapPage* heapPageForObject = pageHeaderFromObject(object);
    ASSERT(!heapPageForObject->orphaned());
    ASSERT(Heap::contains(object) == heapPageForObject);
    ThreadState* state = heapPageForObject->threadState();
    state->pushWeakObjectPointerCallback(closure, callback);
}

bool Heap::popAndInvokeWeakPointerCallback(Visitor* visitor)
{
    return s_weakCallbackStack->popAndInvokeCallback<WeaknessProcessing>(&s_weakCallbackStack, visitor);
}

void Heap::registerWeakTable(void* table, EphemeronCallback iterationCallback, EphemeronCallback iterationDoneCallback)
{
    {
        MutexLocker locker(markingMutex());
        // Check that the ephemeron table being pushed onto the stack is not on an
        // orphaned page.
        ASSERT(!Heap::orphanedPagePool()->contains(table));
        CallbackStack::Item* slot = s_ephemeronStack->allocateEntry(&s_ephemeronStack);
        *slot = CallbackStack::Item(table, iterationCallback);
    }

    // Register a post-marking callback to tell the tables that
    // ephemeron iteration is complete.
    pushPostMarkingCallback(table, iterationDoneCallback);
}

#if ENABLE(ASSERT)
bool Heap::weakTableRegistered(const void* table)
{
    MutexLocker locker(markingMutex());
    ASSERT(s_ephemeronStack);
    return s_ephemeronStack->hasCallbackForObject(table);
}
#endif

void Heap::prepareForGC()
{
    ASSERT(ThreadState::isAnyThreadInGC());
    ThreadState::AttachedThreadStateSet& threads = ThreadState::attachedThreads();
    for (ThreadState::AttachedThreadStateSet::iterator it = threads.begin(), end = threads.end(); it != end; ++it)
        (*it)->prepareForGC();
}

void Heap::collectGarbage(ThreadState::StackState stackState)
{
    ThreadState* state = ThreadState::current();
    state->clearGCRequested();

    GCScope gcScope(stackState);
    // Check if we successfully parked the other threads. If not we bail out of the GC.
    if (!gcScope.allThreadsParked()) {
        ThreadState::current()->setGCRequested();
        return;
    }

    if (state->isMainThread())
        ScriptForbiddenScope::enter();

    s_lastGCWasConservative = false;

    TRACE_EVENT0("blink_gc", "Heap::collectGarbage");
    TRACE_EVENT_SCOPED_SAMPLING_STATE("blink_gc", "BlinkGC");
    double timeStamp = WTF::currentTimeMS();
#if ENABLE(GC_PROFILE_MARKING)
    static_cast<MarkingVisitor*>(s_markingVisitor)->objectGraph().clear();
#endif

    // Disallow allocation during garbage collection (but not
    // during the finalization that happens when the gcScope is
    // torn down).
    NoAllocationScope<AnyThread> noAllocationScope;

    prepareForGC();

    // 1. trace persistent roots.
    ThreadState::visitPersistentRoots(s_markingVisitor);

    // 2. trace objects reachable from the persistent roots including ephemerons.
    processMarkingStackInParallel();

    // 3. trace objects reachable from the stack. We do this independent of the
    // given stackState since other threads might have a different stack state.
    ThreadState::visitStackRoots(s_markingVisitor);

    // 4. trace objects reachable from the stack "roots" including ephemerons.
    // Only do the processing if we found a pointer to an object on one of the
    // thread stacks.
    if (lastGCWasConservative())
        processMarkingStackInParallel();

    postMarkingProcessing();
    globalWeakProcessing();

    // After a global marking we know that any orphaned page that was not reached
    // cannot be reached in a subsequent GC. This is due to a thread either having
    // swept its heap or having done a "poor mans sweep" in prepareForGC which marks
    // objects that are dead, but not swept in the previous GC as dead. In this GC's
    // marking we check that any object marked as dead is not traced. E.g. via a
    // conservatively found pointer or a programming error with an object containing
    // a dangling pointer.
    orphanedPagePool()->decommitOrphanedPages();

#if ENABLE(GC_PROFILE_MARKING)
    static_cast<MarkingVisitor*>(s_markingVisitor)->reportStats();
#endif

    if (blink::Platform::current()) {
        uint64_t objectSpaceSize;
        uint64_t allocatedSpaceSize;
        getHeapSpaceSize(&objectSpaceSize, &allocatedSpaceSize);
        blink::Platform::current()->histogramCustomCounts("BlinkGC.CollectGarbage", WTF::currentTimeMS() - timeStamp, 0, 10 * 1000, 50);
        blink::Platform::current()->histogramCustomCounts("BlinkGC.TotalObjectSpace", objectSpaceSize / 1024, 0, 4 * 1024 * 1024, 50);
        blink::Platform::current()->histogramCustomCounts("BlinkGC.TotalAllocatedSpace", allocatedSpaceSize / 1024, 0, 4 * 1024 * 1024, 50);
    }

    if (state->isMainThread())
        ScriptForbiddenScope::exit();
}

void Heap::collectGarbageForTerminatingThread(ThreadState* state)
{
    // We explicitly do not enter a safepoint while doing thread specific
    // garbage collection since we don't want to allow a global GC at the
    // same time as a thread local GC.

    {
        NoAllocationScope<AnyThread> noAllocationScope;

        state->enterGC();
        state->prepareForGC();

        // 1. trace the thread local persistent roots. For thread local GCs we
        // don't trace the stack (ie. no conservative scanning) since this is
        // only called during thread shutdown where there should be no objects
        // on the stack.
        // We also assume that orphaned pages have no objects reachable from
        // persistent handles on other threads or CrossThreadPersistents. The
        // only cases where this could happen is if a subsequent conservative
        // global GC finds a "pointer" on the stack or due to a programming
        // error where an object has a dangling cross-thread pointer to an
        // object on this heap.
        state->visitPersistents(s_markingVisitor);

        // 2. trace objects reachable from the thread's persistent roots
        // including ephemerons.
        processMarkingStack<ThreadLocalMarking>();

        postMarkingProcessing();
        globalWeakProcessing();

        state->leaveGC();
    }
    state->performPendingSweep();
}

void Heap::processMarkingStackEntries(int* runningMarkingThreads)
{
    CallbackStack* stack = 0;
    MarkingVisitor visitor(&stack);
    {
        MutexLocker locker(markingMutex());
        stack = s_markingStack->takeCallbacks(&s_markingStack);
    }
    while (stack) {
        while (stack->popAndInvokeCallback<GlobalMarking>(&stack, &visitor)) { }
        delete stack;
        {
            MutexLocker locker(markingMutex());
            stack = s_markingStack->takeCallbacks(&s_markingStack);
        }
    }
    {
        MutexLocker locker(markingMutex());
        if (!--(*runningMarkingThreads))
            markingCondition().signal();
    }
}

void Heap::processMarkingStackOnMultipleThreads()
{
}

void Heap::processMarkingStackInParallel()
{
    static const int numberOfBlocksForParallelMarking = 2;
    // Ephemeron fixed point loop run on the garbage collecting thread.
    do {
        // Iteratively mark all objects that are reachable from the objects
        // currently pushed onto the marking stack. Do so in parallel if there
        // are multiple blocks on the global marking stack.
        if (s_markingStack->numberOfBlocksExceeds(numberOfBlocksForParallelMarking)) {
            processMarkingStackOnMultipleThreads();
        } else {
            while (popAndInvokeTraceCallback<GlobalMarking>(s_markingVisitor)) { }
        }

        // Mark any strong pointers that have now become reachable in ephemeron
        // maps.
        CallbackStack::invokeCallbacks(&s_ephemeronStack, s_markingVisitor);

        // Rerun loop if ephemeron processing queued more objects for tracing.
    } while (!s_markingStack->isEmpty());
}

template<CallbackInvocationMode Mode>
void Heap::processMarkingStack()
{
    // Ephemeron fixed point loop.
    do {
        // Iteratively mark all objects that are reachable from the objects
        // currently pushed onto the marking stack. If Mode is ThreadLocalMarking
        // don't continue tracing if the trace hits an object on another thread's
        // heap.
        while (popAndInvokeTraceCallback<Mode>(s_markingVisitor)) { }

        // Mark any strong pointers that have now become reachable in ephemeron
        // maps.
        CallbackStack::invokeCallbacks(&s_ephemeronStack, s_markingVisitor);

        // Rerun loop if ephemeron processing queued more objects for tracing.
    } while (!s_markingStack->isEmpty());
}

void Heap::postMarkingProcessing()
{
    // Call post-marking callbacks including:
    // 1. the ephemeronIterationDone callbacks on weak tables to do cleanup
    //    (specifically to clear the queued bits for weak hash tables), and
    // 2. the markNoTracing callbacks on collection backings to mark them
    //    if they are only reachable from their front objects.
    while (popAndInvokePostMarkingCallback(s_markingVisitor)) { }

    CallbackStack::clear(&s_ephemeronStack);

    // Post-marking callbacks should not trace any objects and
    // therefore the marking stack should be empty after the
    // post-marking callbacks.
    ASSERT(s_markingStack->isEmpty());
}

void Heap::globalWeakProcessing()
{
    // Call weak callbacks on objects that may now be pointing to dead
    // objects.
    while (popAndInvokeWeakPointerCallback(s_markingVisitor)) { }

    // It is not permitted to trace pointers of live objects in the weak
    // callback phase, so the marking stack should still be empty here.
    ASSERT(s_markingStack->isEmpty());
}

void Heap::collectAllGarbage()
{
    // FIXME: oilpan: we should perform a single GC and everything
    // should die. Unfortunately it is not the case for all objects
    // because the hierarchy was not completely moved to the heap and
    // some heap allocated objects own objects that contain persistents
    // pointing to other heap allocated objects.
    for (int i = 0; i < 5; i++)
        collectGarbage(ThreadState::NoHeapPointersOnStack);
}

void Heap::setForcePreciseGCForTesting()
{
    ThreadState::current()->setForcePreciseGCForTesting(true);
}

template<typename Header>
void ThreadHeap<Header>::prepareHeapForTermination()
{
    for (HeapPage<Header>* page = m_firstPage; page; page = page->next()) {
        page->setTerminating();
    }
    for (LargeHeapObject<Header>* current = m_firstLargeHeapObject; current; current = current->next()) {
        current->setTerminating();
    }
}

template<typename Header>
BaseHeap* ThreadHeap<Header>::split(int numberOfNormalPages)
{
    // Create a new split off thread heap containing
    // |numberOfNormalPages| of the pages of this ThreadHeap for
    // parallel sweeping. The split off thread heap will be merged
    // with this heap at the end of sweeping and the temporary
    // ThreadHeap object will be deallocated after the merge.
    ASSERT(numberOfNormalPages > 0);
    ThreadHeap<Header>* splitOff = new ThreadHeap(m_threadState, m_index);
    HeapPage<Header>* splitPoint = m_firstPage;
    for (int i = 1; i < numberOfNormalPages; i++)
        splitPoint = splitPoint->next();
    splitOff->m_firstPage = m_firstPage;
    m_firstPage = splitPoint->m_next;
    splitOff->m_mergePoint = splitPoint;
    splitOff->m_numberOfNormalPages = numberOfNormalPages;
    m_numberOfNormalPages -= numberOfNormalPages;
    splitPoint->m_next = 0;
    return splitOff;
}

template<typename Header>
void ThreadHeap<Header>::merge(BaseHeap* splitOffBase)
{
    ThreadHeap<Header>* splitOff = static_cast<ThreadHeap<Header>*>(splitOffBase);
    // If the mergePoint is zero all split off pages became empty in
    // this round and we don't have to merge. There are no pages and
    // nothing on the freelists.
    ASSERT(splitOff->m_mergePoint || splitOff->m_numberOfNormalPages == 0);
    if (splitOff->m_mergePoint) {
        // Link the split off pages into the beginning of the list again.
        splitOff->m_mergePoint->m_next = m_firstPage;
        m_firstPage = splitOff->m_firstPage;
        m_numberOfNormalPages += splitOff->m_numberOfNormalPages;
        splitOff->m_firstPage = 0;
        // Merge free lists.
        for (size_t i = 0; i < blinkPageSizeLog2; i++) {
            if (!m_freeLists[i]) {
                m_freeLists[i] = splitOff->m_freeLists[i];
            } else if (splitOff->m_freeLists[i]) {
                m_lastFreeListEntries[i]->append(splitOff->m_freeLists[i]);
                m_lastFreeListEntries[i] = splitOff->m_lastFreeListEntries[i];
            }
        }
    }
    delete splitOffBase;
}

void Heap::getHeapSpaceSize(uint64_t* objectSpaceSize, uint64_t* allocatedSpaceSize)
{
    *objectSpaceSize = 0;
    *allocatedSpaceSize = 0;
    ASSERT(ThreadState::isAnyThreadInGC());
    ThreadState::AttachedThreadStateSet& threads = ThreadState::attachedThreads();
    typedef ThreadState::AttachedThreadStateSet::iterator ThreadStateIterator;
    for (ThreadStateIterator it = threads.begin(), end = threads.end(); it != end; ++it) {
        *objectSpaceSize += (*it)->stats().totalObjectSpace();
        *allocatedSpaceSize += (*it)->stats().totalAllocatedSpace();
    }
}

void Heap::getStats(HeapStats* stats)
{
    stats->clear();
    ASSERT(ThreadState::isAnyThreadInGC());
    ThreadState::AttachedThreadStateSet& threads = ThreadState::attachedThreads();
    typedef ThreadState::AttachedThreadStateSet::iterator ThreadStateIterator;
    for (ThreadStateIterator it = threads.begin(), end = threads.end(); it != end; ++it) {
        HeapStats temp;
        (*it)->getStats(temp);
        stats->add(&temp);
    }
}

#if ENABLE(ASSERT)
bool Heap::isConsistentForSweeping()
{
    ASSERT(ThreadState::isAnyThreadInGC());
    ThreadState::AttachedThreadStateSet& threads = ThreadState::attachedThreads();
    for (ThreadState::AttachedThreadStateSet::iterator it = threads.begin(), end = threads.end(); it != end; ++it) {
        if (!(*it)->isConsistentForSweeping())
            return false;
    }
    return true;
}
#endif

void Heap::makeConsistentForSweeping()
{
    ASSERT(ThreadState::isAnyThreadInGC());
    ThreadState::AttachedThreadStateSet& threads = ThreadState::attachedThreads();
    for (ThreadState::AttachedThreadStateSet::iterator it = threads.begin(), end = threads.end(); it != end; ++it)
        (*it)->makeConsistentForSweeping();
}

void HeapAllocator::backingFree(void* address)
{
    if (!address || ThreadState::isAnyThreadInGC())
        return;

    ThreadState* state = ThreadState::current();
    if (state->isSweepInProgress())
        return;

    // Don't promptly free large objects because their page is never reused
    // and don't free backings allocated on other threads.
    BaseHeapPage* page = pageHeaderFromObject(address);
    if (page->isLargeObject() || page->threadState() != state)
        return;

    typedef HeapIndexTrait<CollectionBackingHeap> HeapTraits;
    typedef HeapTraits::HeapType HeapType;
    typedef HeapTraits::HeaderType HeaderType;

    HeaderType* header = HeaderType::fromPayload(address);
    header->checkHeader();

    const GCInfo* gcInfo = header->gcInfo();
    int heapIndex = HeapTraits::index(gcInfo->hasFinalizer());
    HeapType* heap = static_cast<HeapType*>(state->heap(heapIndex));
    heap->promptlyFreeObject(header);
}

// Force template instantiations for the types that we need.
template class HeapPage<FinalizedHeapObjectHeader>;
template class HeapPage<HeapObjectHeader>;
template class ThreadHeap<FinalizedHeapObjectHeader>;
template class ThreadHeap<HeapObjectHeader>;
template bool CallbackStack::popAndInvokeCallback<GlobalMarking>(CallbackStack**, Visitor*);
template bool CallbackStack::popAndInvokeCallback<ThreadLocalMarking>(CallbackStack**, Visitor*);
template bool CallbackStack::popAndInvokeCallback<WeaknessProcessing>(CallbackStack**, Visitor*);

Visitor* Heap::s_markingVisitor;
Vector<OwnPtr<blink::WebThread> >* Heap::s_markingThreads;
CallbackStack* Heap::s_markingStack;
CallbackStack* Heap::s_postMarkingCallbackStack;
CallbackStack* Heap::s_weakCallbackStack;
CallbackStack* Heap::s_ephemeronStack;
HeapDoesNotContainCache* Heap::s_heapDoesNotContainCache;
bool Heap::s_shutdownCalled = false;
bool Heap::s_lastGCWasConservative = false;
FreePagePool* Heap::s_freePagePool;
OrphanedPagePool* Heap::s_orphanedPagePool;
}
