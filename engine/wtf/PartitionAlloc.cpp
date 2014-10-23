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
#include "wtf/PartitionAlloc.h"

#include <string.h>

#ifndef NDEBUG
#include <stdio.h>
#endif

// Two partition pages are used as guard / metadata page so make sure the super
// page size is bigger.
COMPILE_ASSERT(WTF::kPartitionPageSize * 4 <= WTF::kSuperPageSize, ok_super_page_size);
COMPILE_ASSERT(!(WTF::kSuperPageSize % WTF::kPartitionPageSize), ok_super_page_multiple);
// Four system pages gives us room to hack out a still-guard-paged piece
// of metadata in the middle of a guard partition page.
COMPILE_ASSERT(WTF::kSystemPageSize * 4 <= WTF::kPartitionPageSize, ok_partition_page_size);
COMPILE_ASSERT(!(WTF::kPartitionPageSize % WTF::kSystemPageSize), ok_partition_page_multiple);
COMPILE_ASSERT(sizeof(WTF::PartitionPage) <= WTF::kPageMetadataSize, PartitionPage_not_too_big);
COMPILE_ASSERT(sizeof(WTF::PartitionBucket) <= WTF::kPageMetadataSize, PartitionBucket_not_too_big);
COMPILE_ASSERT(sizeof(WTF::PartitionSuperPageExtentEntry) <= WTF::kPageMetadataSize, PartitionSuperPageExtentEntry_not_too_big);
COMPILE_ASSERT(WTF::kPageMetadataSize * WTF::kNumPartitionPagesPerSuperPage <= WTF::kSystemPageSize, page_metadata_fits_in_hole);
// Check that some of our zanier calculations worked out as expected.
COMPILE_ASSERT(WTF::kGenericSmallestBucket == 8, generic_smallest_bucket);
COMPILE_ASSERT(WTF::kGenericMaxBucketed == 983040, generic_max_bucketed);

namespace WTF {

int PartitionRootBase::gInitializedLock = 0;
bool PartitionRootBase::gInitialized = false;
PartitionPage PartitionRootBase::gSeedPage;
PartitionBucket PartitionRootBase::gPagedBucket;

static size_t partitionBucketNumSystemPages(size_t size)
{
    // This works out reasonably for the current bucket sizes of the generic
    // allocator, and the current values of partition page size and constants.
    // Specifically, we have enough room to always pack the slots perfectly into
    // some number of system pages. The only waste is the waste associated with
    // unfaulted pages (i.e. wasted address space).
    // TODO: we end up using a lot of system pages for very small sizes. For
    // example, we'll use 12 system pages for slot size 24. The slot size is
    // so small that the waste would be tiny with just 4, or 1, system pages.
    // Later, we can investigate whether there are anti-fragmentation benefits
    // to using fewer system pages.
    double bestWasteRatio = 1.0f;
    size_t bestPages = 0;
    if (size > kMaxSystemPagesPerSlotSpan * kSystemPageSize) {
        ASSERT(!(size % kSystemPageSize));
        return size / kSystemPageSize;
    }
    ASSERT(size <= kMaxSystemPagesPerSlotSpan * kSystemPageSize);
    for (size_t i = kNumSystemPagesPerPartitionPage - 1; i <= kMaxSystemPagesPerSlotSpan; ++i) {
        size_t pageSize = kSystemPageSize * i;
        size_t numSlots = pageSize / size;
        size_t waste = pageSize - (numSlots * size);
        // Leaving a page unfaulted is not free; the page will occupy an empty page table entry.
        // Make a simple attempt to account for that.
        size_t numRemainderPages = i & (kNumSystemPagesPerPartitionPage - 1);
        size_t numUnfaultedPages = numRemainderPages ? (kNumSystemPagesPerPartitionPage - numRemainderPages) : 0;
        waste += sizeof(void*) * numUnfaultedPages;
        double wasteRatio = (double) waste / (double) pageSize;
        if (wasteRatio < bestWasteRatio) {
            bestWasteRatio = wasteRatio;
            bestPages = i;
        }
    }
    ASSERT(bestPages > 0);
    return bestPages;
}

static void parititonAllocBaseInit(PartitionRootBase* root)
{
    ASSERT(!root->initialized);

    spinLockLock(&PartitionRootBase::gInitializedLock);
    if (!PartitionRootBase::gInitialized) {
        PartitionRootBase::gInitialized = true;
        // We mark the seed page as free to make sure it is skipped by our
        // logic to find a new active page.
        PartitionRootBase::gPagedBucket.activePagesHead = &PartitionRootGeneric::gSeedPage;
    }
    spinLockUnlock(&PartitionRootBase::gInitializedLock);

    root->initialized = true;
    root->totalSizeOfCommittedPages = 0;
    root->totalSizeOfSuperPages = 0;
    root->nextSuperPage = 0;
    root->nextPartitionPage = 0;
    root->nextPartitionPageEnd = 0;
    root->firstExtent = 0;
    root->currentExtent = 0;

    memset(&root->globalEmptyPageRing, '\0', sizeof(root->globalEmptyPageRing));
    root->globalEmptyPageRingIndex = 0;

    // This is a "magic" value so we can test if a root pointer is valid.
    root->invertedSelf = ~reinterpret_cast<uintptr_t>(root);
}

static void partitionBucketInitBase(PartitionBucket* bucket, PartitionRootBase* root)
{
    bucket->activePagesHead = &PartitionRootGeneric::gSeedPage;
    bucket->freePagesHead = 0;
    bucket->numFullPages = 0;
    bucket->numSystemPagesPerSlotSpan = partitionBucketNumSystemPages(bucket->slotSize);
}

void partitionAllocInit(PartitionRoot* root, size_t numBuckets, size_t maxAllocation)
{
    parititonAllocBaseInit(root);

    root->numBuckets = numBuckets;
    root->maxAllocation = maxAllocation;
    size_t i;
    for (i = 0; i < root->numBuckets; ++i) {
        PartitionBucket* bucket = &root->buckets()[i];
        if (!i)
            bucket->slotSize = kAllocationGranularity;
        else
            bucket->slotSize = i << kBucketShift;
        partitionBucketInitBase(bucket, root);
    }
}

void partitionAllocGenericInit(PartitionRootGeneric* root)
{
    parititonAllocBaseInit(root);

    root->lock = 0;

    // Precalculate some shift and mask constants used in the hot path.
    // Example: malloc(41) == 101001 binary.
    // Order is 6 (1 << 6-1)==32 is highest bit set.
    // orderIndex is the next three MSB == 010 == 2.
    // subOrderIndexMask is a mask for the remaining bits == 11 (masking to 01 for the subOrderIndex).
    size_t order;
    for (order = 0; order <= kBitsPerSizet; ++order) {
        size_t orderIndexShift;
        if (order < kGenericNumBucketsPerOrderBits + 1)
            orderIndexShift = 0;
        else
            orderIndexShift = order - (kGenericNumBucketsPerOrderBits + 1);
        root->orderIndexShifts[order] = orderIndexShift;
        size_t subOrderIndexMask;
        if (order == kBitsPerSizet) {
            // This avoids invoking undefined behavior for an excessive shift.
            subOrderIndexMask = static_cast<size_t>(-1) >> (kGenericNumBucketsPerOrderBits + 1);
        } else {
            subOrderIndexMask = ((1 << order) - 1) >> (kGenericNumBucketsPerOrderBits + 1);
        }
        root->orderSubIndexMasks[order] = subOrderIndexMask;
    }

    // Set up the actual usable buckets first.
    // Note that typical values (i.e. min allocation size of 8) will result in
    // invalid buckets (size==9 etc. or more generally, size is not a multiple
    // of the smallest allocation granularity).
    // We avoid them in the bucket lookup map, but we tolerate them to keep the
    // code simpler and the structures more generic.
    size_t i, j;
    size_t currentSize = kGenericSmallestBucket;
    size_t currentIncrement = kGenericSmallestBucket >> kGenericNumBucketsPerOrderBits;
    PartitionBucket* bucket = &root->buckets[0];
    for (i = 0; i < kGenericNumBucketedOrders; ++i) {
        for (j = 0; j < kGenericNumBucketsPerOrder; ++j) {
            bucket->slotSize = currentSize;
            partitionBucketInitBase(bucket, root);
            // Disable invalid buckets so that touching them faults.
            if (currentSize % kGenericSmallestBucket)
                bucket->activePagesHead = 0;
            currentSize += currentIncrement;
            ++bucket;
        }
        currentIncrement <<= 1;
    }
    ASSERT(currentSize == 1 << kGenericMaxBucketedOrder);
    ASSERT(bucket == &root->buckets[0] + (kGenericNumBucketedOrders * kGenericNumBucketsPerOrder));

    // Then set up the fast size -> bucket lookup table.
    bucket = &root->buckets[0];
    PartitionBucket** bucketPtr = &root->bucketLookups[0];
    for (order = 0; order <= kBitsPerSizet; ++order) {
        for (j = 0; j < kGenericNumBucketsPerOrder; ++j) {
            if (order < kGenericMinBucketedOrder) {
                // Use the bucket of finest granularity for malloc(0) etc.
                *bucketPtr++ = &root->buckets[0];
            } else if (order > kGenericMaxBucketedOrder) {
                *bucketPtr++ = &PartitionRootGeneric::gPagedBucket;
            } else {
                PartitionBucket* validBucket = bucket;
                // Skip over invalid buckets.
                while (validBucket->slotSize % kGenericSmallestBucket)
                    validBucket++;
                *bucketPtr++ = validBucket;
                bucket++;
            }
        }
    }
    ASSERT(bucket == &root->buckets[0] + (kGenericNumBucketedOrders * kGenericNumBucketsPerOrder));
    ASSERT(bucketPtr == &root->bucketLookups[0] + ((kBitsPerSizet + 1) * kGenericNumBucketsPerOrder));
    // And there's one last bucket lookup that will be hit for e.g. malloc(-1),
    // which tries to overflow to a non-existant order.
    *bucketPtr = &PartitionRootGeneric::gPagedBucket;
}

static bool partitionAllocShutdownBucket(PartitionBucket* bucket)
{
    // Failure here indicates a memory leak.
    bool noLeaks = !bucket->numFullPages;
    PartitionPage* page = bucket->activePagesHead;
    while (page) {
        if (page->numAllocatedSlots)
            noLeaks = false;
        page = page->nextPage;
    }

    return noLeaks;
}

static void partitionAllocBaseShutdown(PartitionRootBase* root)
{
    ASSERT(root->initialized);
    root->initialized = false;

    // Now that we've examined all partition pages in all buckets, it's safe
    // to free all our super pages. We first collect the super page pointers
    // on the stack because some of them are themselves store in super pages.
    char* superPages[kMaxPartitionSize / kSuperPageSize];
    size_t numSuperPages = 0;
    PartitionSuperPageExtentEntry* entry = root->firstExtent;
    while (entry) {
        char* superPage = entry->superPageBase;
        while (superPage != entry->superPagesEnd) {
            superPages[numSuperPages] = superPage;
            numSuperPages++;
            superPage += kSuperPageSize;
        }
        entry = entry->next;
    }
    ASSERT(numSuperPages == root->totalSizeOfSuperPages / kSuperPageSize);
    for (size_t i = 0; i < numSuperPages; ++i)
        freePages(superPages[i], kSuperPageSize);
}

bool partitionAllocShutdown(PartitionRoot* root)
{
    bool noLeaks = true;
    size_t i;
    for (i = 0; i < root->numBuckets; ++i) {
        PartitionBucket* bucket = &root->buckets()[i];
        if (!partitionAllocShutdownBucket(bucket))
            noLeaks = false;
    }

    partitionAllocBaseShutdown(root);
    return noLeaks;
}

bool partitionAllocGenericShutdown(PartitionRootGeneric* root)
{
    bool noLeaks = true;
    size_t i;
    for (i = 0; i < kGenericNumBucketedOrders * kGenericNumBucketsPerOrder; ++i) {
        PartitionBucket* bucket = &root->buckets[i];
        if (!partitionAllocShutdownBucket(bucket))
            noLeaks = false;
    }
    partitionAllocBaseShutdown(root);
    return noLeaks;
}

static NEVER_INLINE void partitionOutOfMemory()
{
    IMMEDIATE_CRASH();
}

static NEVER_INLINE void partitionFull()
{
    IMMEDIATE_CRASH();
}

static ALWAYS_INLINE void partitionDecommitSystemPages(PartitionRootBase* root, void* addr, size_t len)
{
    decommitSystemPages(addr, len);
    ASSERT(root->totalSizeOfCommittedPages > len);
    root->totalSizeOfCommittedPages -= len;
}

static ALWAYS_INLINE void partitionRecommitSystemPages(PartitionRootBase* root, void* addr, size_t len)
{
    recommitSystemPages(addr, len);
    root->totalSizeOfCommittedPages += len;
}

static ALWAYS_INLINE void* partitionAllocPartitionPages(PartitionRootBase* root, int flags, size_t numPartitionPages)
{
    ASSERT(!(reinterpret_cast<uintptr_t>(root->nextPartitionPage) % kPartitionPageSize));
    ASSERT(!(reinterpret_cast<uintptr_t>(root->nextPartitionPageEnd) % kPartitionPageSize));
    RELEASE_ASSERT(numPartitionPages <= kNumPartitionPagesPerSuperPage);
    size_t totalSize = kPartitionPageSize * numPartitionPages;
    root->totalSizeOfCommittedPages += totalSize;
    size_t numPartitionPagesLeft = (root->nextPartitionPageEnd - root->nextPartitionPage) >> kPartitionPageShift;
    if (LIKELY(numPartitionPagesLeft >= numPartitionPages)) {
        // In this case, we can still hand out pages from the current super page
        // allocation.
        char* ret = root->nextPartitionPage;
        root->nextPartitionPage += totalSize;
        return ret;
    }

    // Need a new super page.
    root->totalSizeOfSuperPages += kSuperPageSize;
    if (root->totalSizeOfSuperPages > kMaxPartitionSize)
        partitionFull();
    char* requestedAddress = root->nextSuperPage;
    char* superPage = reinterpret_cast<char*>(allocPages(requestedAddress, kSuperPageSize, kSuperPageSize));
    if (UNLIKELY(!superPage)) {
        if (flags & PartitionAllocReturnNull)
            return 0;
        partitionOutOfMemory();
    }
    root->nextSuperPage = superPage + kSuperPageSize;
    char* ret = superPage + kPartitionPageSize;
    root->nextPartitionPage = ret + totalSize;
    root->nextPartitionPageEnd = root->nextSuperPage - kPartitionPageSize;
    // Make the first partition page in the super page a guard page, but leave a
    // hole in the middle.
    // This is where we put page metadata and also a tiny amount of extent
    // metadata.
    setSystemPagesInaccessible(superPage, kSystemPageSize);
    setSystemPagesInaccessible(superPage + (kSystemPageSize * 2), kPartitionPageSize - (kSystemPageSize * 2));
    // Also make the last partition page a guard page.
    setSystemPagesInaccessible(superPage + (kSuperPageSize - kPartitionPageSize), kPartitionPageSize);

    // If we were after a specific address, but didn't get it, assume that
    // the system chose a lousy address and re-randomize the next
    // allocation.
    if (requestedAddress && requestedAddress != superPage)
        root->nextSuperPage = 0;

    // We allocated a new super page so update super page metadata.
    // First check if this is a new extent or not.
    PartitionSuperPageExtentEntry* latestExtent = reinterpret_cast<PartitionSuperPageExtentEntry*>(partitionSuperPageToMetadataArea(superPage));
    PartitionSuperPageExtentEntry* currentExtent = root->currentExtent;
    bool isNewExtent = (superPage != requestedAddress);
    if (UNLIKELY(isNewExtent)) {
        latestExtent->next = 0;
        if (UNLIKELY(!currentExtent)) {
            root->firstExtent = latestExtent;
        } else {
            ASSERT(currentExtent->superPageBase);
            currentExtent->next = latestExtent;
        }
        root->currentExtent = latestExtent;
        currentExtent = latestExtent;
        currentExtent->superPageBase = superPage;
        currentExtent->superPagesEnd = superPage + kSuperPageSize;
    } else {
        // We allocated next to an existing extent so just nudge the size up a little.
        currentExtent->superPagesEnd += kSuperPageSize;
        ASSERT(ret >= currentExtent->superPageBase && ret < currentExtent->superPagesEnd);
    }
    // By storing the root in every extent metadata object, we have a fast way
    // to go from a pointer within the partition to the root object.
    latestExtent->root = root;

    return ret;
}

static ALWAYS_INLINE void partitionUnusePage(PartitionRootBase* root, PartitionPage* page)
{
    ASSERT(page->bucket->numSystemPagesPerSlotSpan);
    void* addr = partitionPageToPointer(page);
    partitionDecommitSystemPages(root, addr, page->bucket->numSystemPagesPerSlotSpan * kSystemPageSize);
}

static ALWAYS_INLINE size_t partitionBucketSlots(const PartitionBucket* bucket)
{
    return (bucket->numSystemPagesPerSlotSpan * kSystemPageSize) / bucket->slotSize;
}

static ALWAYS_INLINE size_t partitionBucketPartitionPages(const PartitionBucket* bucket)
{
    return (bucket->numSystemPagesPerSlotSpan + (kNumSystemPagesPerPartitionPage - 1)) / kNumSystemPagesPerPartitionPage;
}

static ALWAYS_INLINE void partitionPageReset(PartitionPage* page, PartitionBucket* bucket)
{
    ASSERT(page != &PartitionRootGeneric::gSeedPage);
    page->numAllocatedSlots = 0;
    page->numUnprovisionedSlots = partitionBucketSlots(bucket);
    ASSERT(page->numUnprovisionedSlots);
    page->bucket = bucket;
    page->nextPage = 0;
    // NULLing the freelist is not strictly necessary but it makes an ASSERT in partitionPageFillFreelist simpler.
    page->freelistHead = 0;
    page->pageOffset = 0;
    page->freeCacheIndex = -1;
    size_t numPartitionPages = partitionBucketPartitionPages(bucket);
    size_t i;
    char* pageCharPtr = reinterpret_cast<char*>(page);
    for (i = 1; i < numPartitionPages; ++i) {
        pageCharPtr += kPageMetadataSize;
        PartitionPage* secondaryPage = reinterpret_cast<PartitionPage*>(pageCharPtr);
        secondaryPage->pageOffset = i;
    }
}

static ALWAYS_INLINE char* partitionPageAllocAndFillFreelist(PartitionPage* page)
{
    ASSERT(page != &PartitionRootGeneric::gSeedPage);
    size_t numSlots = page->numUnprovisionedSlots;
    ASSERT(numSlots);
    PartitionBucket* bucket = page->bucket;
    // We should only get here when _every_ slot is either used or unprovisioned.
    // (The third state is "on the freelist". If we have a non-empty freelist, we should not get here.)
    ASSERT(numSlots + page->numAllocatedSlots == partitionBucketSlots(bucket));
    // Similarly, make explicitly sure that the freelist is empty.
    ASSERT(!page->freelistHead);
    ASSERT(page->numAllocatedSlots >= 0);

    size_t size = bucket->slotSize;
    char* base = reinterpret_cast<char*>(partitionPageToPointer(page));
    char* returnObject = base + (size * page->numAllocatedSlots);
    char* firstFreelistPointer = returnObject + size;
    char* firstFreelistPointerExtent = firstFreelistPointer + sizeof(PartitionFreelistEntry*);
    // Our goal is to fault as few system pages as possible. We calculate the
    // page containing the "end" of the returned slot, and then allow freelist
    // pointers to be written up to the end of that page.
    char* subPageLimit = reinterpret_cast<char*>((reinterpret_cast<uintptr_t>(firstFreelistPointer) + kSystemPageOffsetMask) & kSystemPageBaseMask);
    char* slotsLimit = returnObject + (size * page->numUnprovisionedSlots);
    char* freelistLimit = subPageLimit;
    if (UNLIKELY(slotsLimit < freelistLimit))
        freelistLimit = slotsLimit;

    size_t numNewFreelistEntries = 0;
    if (LIKELY(firstFreelistPointerExtent <= freelistLimit)) {
        // Only consider used space in the slot span. If we consider wasted
        // space, we may get an off-by-one when a freelist pointer fits in the
        // wasted space, but a slot does not.
        // We know we can fit at least one freelist pointer.
        numNewFreelistEntries = 1;
        // Any further entries require space for the whole slot span.
        numNewFreelistEntries += (freelistLimit - firstFreelistPointerExtent) / size;
    }

    // We always return an object slot -- that's the +1 below.
    // We do not neccessarily create any new freelist entries, because we cross sub page boundaries frequently for large bucket sizes.
    ASSERT(numNewFreelistEntries + 1 <= numSlots);
    numSlots -= (numNewFreelistEntries + 1);
    page->numUnprovisionedSlots = numSlots;
    page->numAllocatedSlots++;

    if (LIKELY(numNewFreelistEntries)) {
        char* freelistPointer = firstFreelistPointer;
        PartitionFreelistEntry* entry = reinterpret_cast<PartitionFreelistEntry*>(freelistPointer);
        page->freelistHead = entry;
        while (--numNewFreelistEntries) {
            freelistPointer += size;
            PartitionFreelistEntry* nextEntry = reinterpret_cast<PartitionFreelistEntry*>(freelistPointer);
            entry->next = partitionFreelistMask(nextEntry);
            entry = nextEntry;
        }
        entry->next = partitionFreelistMask(0);
    } else {
        page->freelistHead = 0;
    }
    return returnObject;
}

// This helper function scans the active page list for a suitable new active
// page, starting at the passed in page.
// When it finds a suitable new active page (one that has free slots), it is
// set as the new active page and true is returned. If there is no suitable new
// active page, false is returned and the current active page is set to null.
// As potential pages are scanned, they are tidied up according to their state.
// Freed pages are swept on to the free page list and full pages are unlinked
// from any list.
static ALWAYS_INLINE bool partitionSetNewActivePage(PartitionPage* page)
{
    if (page == &PartitionRootBase::gSeedPage) {
        ASSERT(!page->nextPage);
        return false;
    }

    PartitionPage* nextPage = 0;
    PartitionBucket* bucket = page->bucket;

    for (; page; page = nextPage) {
        nextPage = page->nextPage;
        ASSERT(page->bucket == bucket);
        ASSERT(page != bucket->freePagesHead);
        ASSERT(!bucket->freePagesHead || page != bucket->freePagesHead->nextPage);

        // Page is usable if it has something on the freelist, or unprovisioned
        // slots that can be turned into a freelist.
        if (LIKELY(page->freelistHead != 0) || LIKELY(page->numUnprovisionedSlots)) {
            bucket->activePagesHead = page;
            return true;
        }

        ASSERT(page->numAllocatedSlots >= 0);
        if (LIKELY(page->numAllocatedSlots == 0)) {
            ASSERT(page->freeCacheIndex == -1);
            // We hit a free page, so shepherd it on to the free page list.
            page->nextPage = bucket->freePagesHead;
            bucket->freePagesHead = page;
        } else {
            // If we get here, we found a full page. Skip over it too, and also
            // tag it as full (via a negative value). We need it tagged so that
            // free'ing can tell, and move it back into the active page list.
            ASSERT(page->numAllocatedSlots == static_cast<int>(partitionBucketSlots(bucket)));
            page->numAllocatedSlots = -page->numAllocatedSlots;
            ++bucket->numFullPages;
            // numFullPages is a uint16_t for efficient packing so guard against
            // overflow to be safe.
            RELEASE_ASSERT(bucket->numFullPages);
            // Not necessary but might help stop accidents.
            page->nextPage = 0;
        }
    }

    bucket->activePagesHead = 0;
    return false;
}

struct PartitionDirectMapExtent {
    size_t mapSize; // Mapped size, not including guard pages and meta-data.
};

static ALWAYS_INLINE PartitionDirectMapExtent* partitionPageToDirectMapExtent(PartitionPage* page)
{
    ASSERT(partitionBucketIsDirectMapped(page->bucket));
    return reinterpret_cast<PartitionDirectMapExtent*>(reinterpret_cast<char*>(page) + 2 * kPageMetadataSize);
}

static ALWAYS_INLINE void* partitionDirectMap(PartitionRootBase* root, int flags, size_t size)
{
    size = partitionDirectMapSize(size);

    // Because we need to fake looking like a super page, We need to allocate
    // a bunch of system pages more than "size":
    // - The first few system pages are the partition page in which the super
    // page metadata is stored. We fault just one system page out of a partition
    // page sized clump.
    // - We add a trailing guard page.
    size_t mapSize = size + kPartitionPageSize + kSystemPageSize;
    // Round up to the allocation granularity.
    mapSize += kPageAllocationGranularityOffsetMask;
    mapSize &= kPageAllocationGranularityBaseMask;

    // TODO: we may want to let the operating system place these allocations
    // where it pleases. On 32-bit, this might limit address space
    // fragmentation and on 64-bit, this might have useful savings for TLB
    // and page table overhead.
    // TODO: if upsizing realloc()s are common on large sizes, we could
    // consider over-allocating address space on 64-bit, "just in case".
    // TODO: consider pre-populating page tables (e.g. MAP_POPULATE on Linux,
    // MADV_WILLNEED on POSIX).
    // TODO: these pages will be zero-filled. Consider internalizing an
    // allocZeroed() API so we can avoid a memset() entirely in this case.
    char* ptr = reinterpret_cast<char*>(allocPages(0, mapSize, kSuperPageSize));
    if (!ptr) {
        if (flags & PartitionAllocReturnNull)
            return 0;
        partitionOutOfMemory();
    }
    char* ret = ptr + kPartitionPageSize;
    // TODO: due to all the guard paging, this arrangement creates 4 mappings.
    // We could get it down to three by using read-only for the metadata page,
    // or perhaps two by leaving out the trailing guard page on 64-bit.
    setSystemPagesInaccessible(ptr, kSystemPageSize);
    setSystemPagesInaccessible(ptr + (kSystemPageSize * 2), kPartitionPageSize - (kSystemPageSize * 2));
    setSystemPagesInaccessible(ret + size, kSystemPageSize);

    PartitionSuperPageExtentEntry* extent = reinterpret_cast<PartitionSuperPageExtentEntry*>(partitionSuperPageToMetadataArea(ptr));
    extent->root = root;
    PartitionPage* page = partitionPointerToPageNoAlignmentCheck(ret);
    PartitionBucket* bucket = reinterpret_cast<PartitionBucket*>(reinterpret_cast<char*>(page) + kPageMetadataSize);
    page->freelistHead = 0;
    page->nextPage = 0;
    page->bucket = bucket;
    page->numAllocatedSlots = 1;
    page->numUnprovisionedSlots = 0;
    page->pageOffset = 0;
    page->freeCacheIndex = 0;

    bucket->activePagesHead = 0;
    bucket->freePagesHead = 0;
    bucket->slotSize = size;
    bucket->numSystemPagesPerSlotSpan = 0;
    bucket->numFullPages = 0;

    PartitionDirectMapExtent* mapExtent = partitionPageToDirectMapExtent(page);
    mapExtent->mapSize = mapSize - kPartitionPageSize - kSystemPageSize;

    return ret;
}

static ALWAYS_INLINE void partitionDirectUnmap(PartitionPage* page)
{
    size_t unmapSize = partitionPageToDirectMapExtent(page)->mapSize;

    // Add on the size of the trailing guard page and preceeding partition
    // page.
    unmapSize += kPartitionPageSize + kSystemPageSize;

    ASSERT(!(unmapSize & kPageAllocationGranularityOffsetMask));

    char* ptr = reinterpret_cast<char*>(partitionPageToPointer(page));
    // Account for the mapping starting a partition page before the actual
    // allocation address.
    ptr -= kPartitionPageSize;

    freePages(ptr, unmapSize);
}

void* partitionAllocSlowPath(PartitionRootBase* root, int flags, size_t size, PartitionBucket* bucket)
{
    // The slow path is called when the freelist is empty.
    ASSERT(!bucket->activePagesHead->freelistHead);

    // For the partitionAllocGeneric API, we have a bunch of buckets marked
    // as special cases. We bounce them through to the slow path so that we
    // can still have a blazing fast hot path due to lack of corner-case
    // branches.
    bool returnNull = flags & PartitionAllocReturnNull;
    if (UNLIKELY(partitionBucketIsDirectMapped(bucket))) {
        ASSERT(size > kGenericMaxBucketed);
        ASSERT(bucket == &PartitionRootBase::gPagedBucket);
        if (size > kGenericMaxDirectMapped) {
            if (returnNull)
                return 0;
            RELEASE_ASSERT(false);
        }
        return partitionDirectMap(root, flags, size);
    }

    // First, look for a usable page in the existing active pages list.
    // Change active page, accepting the current page as a candidate.
    if (LIKELY(partitionSetNewActivePage(bucket->activePagesHead))) {
        PartitionPage* newPage = bucket->activePagesHead;
        if (LIKELY(newPage->freelistHead != 0)) {
            PartitionFreelistEntry* ret = newPage->freelistHead;
            newPage->freelistHead = partitionFreelistMask(ret->next);
            newPage->numAllocatedSlots++;
            return ret;
        }
        ASSERT(newPage->numUnprovisionedSlots);
        return partitionPageAllocAndFillFreelist(newPage);
    }

    // Second, look in our list of freed but reserved pages.
    PartitionPage* newPage = bucket->freePagesHead;
    if (LIKELY(newPage != 0)) {
        ASSERT(newPage != &PartitionRootGeneric::gSeedPage);
        ASSERT(!newPage->freelistHead);
        ASSERT(!newPage->numAllocatedSlots);
        ASSERT(!newPage->numUnprovisionedSlots);
        ASSERT(newPage->freeCacheIndex == -1);
        bucket->freePagesHead = newPage->nextPage;
        void* addr = partitionPageToPointer(newPage);
        partitionRecommitSystemPages(root, addr, newPage->bucket->numSystemPagesPerSlotSpan * kSystemPageSize);
    } else {
        // Third. If we get here, we need a brand new page.
        size_t numPartitionPages = partitionBucketPartitionPages(bucket);
        void* rawNewPage = partitionAllocPartitionPages(root, flags, numPartitionPages);
        if (UNLIKELY(!rawNewPage)) {
            ASSERT(returnNull);
            return 0;
        }
        // Skip the alignment check because it depends on page->bucket, which is not yet set.
        newPage = partitionPointerToPageNoAlignmentCheck(rawNewPage);
    }

    partitionPageReset(newPage, bucket);
    bucket->activePagesHead = newPage;
    return partitionPageAllocAndFillFreelist(newPage);
}

static ALWAYS_INLINE void partitionFreePage(PartitionRootBase* root, PartitionPage* page)
{
    ASSERT(page->freelistHead);
    ASSERT(!page->numAllocatedSlots);
    partitionUnusePage(root, page);
    // We actually leave the freed page in the active list. We'll sweep it on
    // to the free page list when we next walk the active page list. Pulling
    // this trick enables us to use a singly-linked page list for all cases,
    // which is critical in keeping the page metadata structure down to 32
    // bytes in size.
    page->freelistHead = 0;
    page->numUnprovisionedSlots = 0;
}

static ALWAYS_INLINE void partitionRegisterEmptyPage(PartitionPage* page)
{
    PartitionRootBase* root = partitionPageToRoot(page);

    // If the page is already registered as empty, give it another life.
    if (page->freeCacheIndex != -1) {
        ASSERT(page->freeCacheIndex >= 0);
        ASSERT(static_cast<unsigned>(page->freeCacheIndex) < kMaxFreeableSpans);
        ASSERT(root->globalEmptyPageRing[page->freeCacheIndex] == page);
        root->globalEmptyPageRing[page->freeCacheIndex] = 0;
    }

    size_t currentIndex = root->globalEmptyPageRingIndex;
    PartitionPage* pageToFree = root->globalEmptyPageRing[currentIndex];
    // The page might well have been re-activated, filled up, etc. before we get
    // around to looking at it here.
    if (pageToFree) {
        ASSERT(pageToFree != &PartitionRootBase::gSeedPage);
        ASSERT(pageToFree->freeCacheIndex >= 0);
        ASSERT(static_cast<unsigned>(pageToFree->freeCacheIndex) < kMaxFreeableSpans);
        ASSERT(pageToFree == root->globalEmptyPageRing[pageToFree->freeCacheIndex]);
        if (!pageToFree->numAllocatedSlots && pageToFree->freelistHead) {
            // The page is still empty, and not freed, so _really_ free it.
            partitionFreePage(root, pageToFree);
        }
        pageToFree->freeCacheIndex = -1;
    }

    // We put the empty slot span on our global list of "pages that were once
    // empty". thus providing it a bit of breathing room to get re-used before
    // we really free it. This improves performance, particularly on Mac OS X
    // which has subpar memory management performance.
    root->globalEmptyPageRing[currentIndex] = page;
    page->freeCacheIndex = currentIndex;
    ++currentIndex;
    if (currentIndex == kMaxFreeableSpans)
        currentIndex = 0;
    root->globalEmptyPageRingIndex = currentIndex;
}

void partitionFreeSlowPath(PartitionPage* page)
{
    PartitionBucket* bucket = page->bucket;
    ASSERT(page != &PartitionRootGeneric::gSeedPage);
    ASSERT(bucket->activePagesHead != &PartitionRootGeneric::gSeedPage);
    if (LIKELY(page->numAllocatedSlots == 0)) {
        // Page became fully unused.
        if (UNLIKELY(partitionBucketIsDirectMapped(bucket))) {
            partitionDirectUnmap(page);
            return;
        }
        // If it's the current active page, attempt to change it. We'd prefer to leave
        // the page empty as a gentle force towards defragmentation.
        if (LIKELY(page == bucket->activePagesHead) && page->nextPage) {
            if (partitionSetNewActivePage(page->nextPage)) {
                ASSERT(bucket->activePagesHead != page);
                // Link the empty page back in after the new current page, to
                // avoid losing a reference to it.
                // TODO: consider walking the list to link the empty page after
                // all non-empty pages?
                PartitionPage* currentPage = bucket->activePagesHead;
                page->nextPage = currentPage->nextPage;
                currentPage->nextPage = page;
            } else {
                bucket->activePagesHead = page;
                page->nextPage = 0;
            }
        }
        partitionRegisterEmptyPage(page);
    } else {
        // Ensure that the page is full. That's the only valid case if we
        // arrive here.
        ASSERT(page->numAllocatedSlots < 0);
        // A transition of numAllocatedSlots from 0 to -1 is not legal, and
        // likely indicates a double-free.
        RELEASE_ASSERT(page->numAllocatedSlots != -1);
        page->numAllocatedSlots = -page->numAllocatedSlots - 2;
        ASSERT(page->numAllocatedSlots == static_cast<int>(partitionBucketSlots(bucket) - 1));
        // Fully used page became partially used. It must be put back on the
        // non-full page list. Also make it the current page to increase the
        // chances of it being filled up again. The old current page will be
        // the next page.
        page->nextPage = bucket->activePagesHead;
        bucket->activePagesHead = page;
        --bucket->numFullPages;
        // Special case: for a partition page with just a single slot, it may
        // now be empty and we want to run it through the empty logic.
        if (UNLIKELY(page->numAllocatedSlots == 0))
            partitionFreeSlowPath(page);
    }
}

bool partitionReallocDirectMappedInPlace(PartitionRootGeneric* root, PartitionPage* page, size_t newSize)
{
    ASSERT(partitionBucketIsDirectMapped(page->bucket));

    newSize = partitionCookieSizeAdjustAdd(newSize);

    // Note that the new size might be a bucketed size; this function is called
    // whenever we're reallocating a direct mapped allocation.
    newSize = partitionDirectMapSize(newSize);
    if (newSize < kGenericMinDirectMappedDownsize)
        return false;

    // bucket->slotSize is the current size of the allocation.
    size_t currentSize = page->bucket->slotSize;
    if (newSize == currentSize)
        return true;

    char* charPtr = static_cast<char*>(partitionPageToPointer(page));

    if (newSize < currentSize) {
        size_t mapSize = partitionPageToDirectMapExtent(page)->mapSize;

        // Don't reallocate in-place if new size is less than 80 % of the full
        // map size, to avoid holding on to too much unused address space.
        if ((newSize / kSystemPageSize) * 5 < (mapSize / kSystemPageSize) * 4)
            return false;

        // Shrink by decommitting unneeded pages and making them inaccessible.
        size_t decommitSize = currentSize - newSize;
        partitionDecommitSystemPages(root, charPtr + newSize, decommitSize);
        setSystemPagesInaccessible(charPtr + newSize, decommitSize);
    } else if (newSize <= partitionPageToDirectMapExtent(page)->mapSize) {
        // Grow within the actually allocated memory. Just need to make the
        // pages accessible again.
        size_t recommitSize = newSize - currentSize;
        setSystemPagesAccessible(charPtr + currentSize, recommitSize);
        partitionRecommitSystemPages(root, charPtr + currentSize, recommitSize);

#if ENABLE(ASSERT)
        memset(charPtr + currentSize, kUninitializedByte, recommitSize);
#endif
    } else {
        // We can't perform the realloc in-place.
        // TODO: support this too when possible.
        return false;
    }

#if ENABLE(ASSERT)
    // Write a new trailing cookie.
    partitionCookieWriteValue(charPtr + newSize - kCookieSize);
#endif

    page->bucket->slotSize = newSize;
    return true;
}

void* partitionReallocGeneric(PartitionRootGeneric* root, void* ptr, size_t newSize)
{
#if defined(MEMORY_TOOL_REPLACES_ALLOCATOR)
    return realloc(ptr, newSize);
#else
    if (UNLIKELY(!ptr))
        return partitionAllocGeneric(root, newSize);
    if (UNLIKELY(!newSize)) {
        partitionFreeGeneric(root, ptr);
        return 0;
    }

    RELEASE_ASSERT(newSize <= kGenericMaxDirectMapped);

    ASSERT(partitionPointerIsValid(partitionCookieFreePointerAdjust(ptr)));

    PartitionPage* page = partitionPointerToPage(partitionCookieFreePointerAdjust(ptr));

    if (UNLIKELY(partitionBucketIsDirectMapped(page->bucket))) {
        // We may be able to perform the realloc in place by changing the
        // accessibility of memory pages and, if reducing the size, decommitting
        // them.
        if (partitionReallocDirectMappedInPlace(root, page, newSize))
            return ptr;
    }

    size_t actualNewSize = partitionAllocActualSize(root, newSize);
    size_t actualOldSize = partitionAllocGetSize(ptr);

    // TODO: note that tcmalloc will "ignore" a downsizing realloc() unless the
    // new size is a significant percentage smaller. We could do the same if we
    // determine it is a win.
    if (actualNewSize == actualOldSize) {
        // Trying to allocate a block of size newSize would give us a block of
        // the same size as the one we've already got, so no point in doing
        // anything here.
        return ptr;
    }

    // This realloc cannot be resized in-place. Sadness.
    void* ret = partitionAllocGeneric(root, newSize);
    size_t copySize = actualOldSize;
    if (newSize < copySize)
        copySize = newSize;

    memcpy(ret, ptr, copySize);
    partitionFreeGeneric(root, ptr);
    return ret;
#endif
}

#ifndef NDEBUG

void partitionDumpStats(const PartitionRoot& root)
{
    size_t i;
    size_t totalLive = 0;
    size_t totalResident = 0;
    size_t totalFreeable = 0;
    for (i = 0; i < root.numBuckets; ++i) {
        const PartitionBucket& bucket = root.buckets()[i];
        if (bucket.activePagesHead == &PartitionRootGeneric::gSeedPage && !bucket.freePagesHead && !bucket.numFullPages) {
            // Empty bucket with no freelist or full pages. Skip reporting it.
            continue;
        }
        size_t numFreePages = 0;
        PartitionPage* freePages = bucket.freePagesHead;
        while (freePages) {
            ++numFreePages;
            freePages = freePages->nextPage;
        }
        size_t bucketSlotSize = bucket.slotSize;
        size_t bucketNumSlots = partitionBucketSlots(&bucket);
        size_t bucketUsefulStorage = bucketSlotSize * bucketNumSlots;
        size_t bucketPageSize = bucket.numSystemPagesPerSlotSpan * kSystemPageSize;
        size_t bucketWaste = bucketPageSize - bucketUsefulStorage;
        size_t numActiveBytes = bucket.numFullPages * bucketUsefulStorage;
        size_t numResidentBytes = bucket.numFullPages * bucketPageSize;
        size_t numFreeableBytes = 0;
        size_t numActivePages = 0;
        const PartitionPage* page = bucket.activePagesHead;
        while (page) {
            ASSERT(page != &PartitionRootGeneric::gSeedPage);
            // A page may be on the active list but freed and not yet swept.
            if (!page->freelistHead && !page->numUnprovisionedSlots && !page->numAllocatedSlots) {
                ++numFreePages;
            } else {
                ++numActivePages;
                numActiveBytes += (page->numAllocatedSlots * bucketSlotSize);
                size_t pageBytesResident = (bucketNumSlots - page->numUnprovisionedSlots) * bucketSlotSize;
                // Round up to system page size.
                pageBytesResident = (pageBytesResident + kSystemPageOffsetMask) & kSystemPageBaseMask;
                numResidentBytes += pageBytesResident;
                if (!page->numAllocatedSlots)
                    numFreeableBytes += pageBytesResident;
            }
            page = page->nextPage;
        }
        totalLive += numActiveBytes;
        totalResident += numResidentBytes;
        totalFreeable += numFreeableBytes;
        printf("bucket size %zu (pageSize %zu waste %zu): %zu alloc/%zu commit/%zu freeable bytes, %zu/%zu/%zu full/active/free pages\n", bucketSlotSize, bucketPageSize, bucketWaste, numActiveBytes, numResidentBytes, numFreeableBytes, static_cast<size_t>(bucket.numFullPages), numActivePages, numFreePages);
    }
    printf("total live: %zu bytes\n", totalLive);
    printf("total resident: %zu bytes\n", totalResident);
    printf("total freeable: %zu bytes\n", totalFreeable);
    fflush(stdout);
}

#endif // !NDEBUG

} // namespace WTF

