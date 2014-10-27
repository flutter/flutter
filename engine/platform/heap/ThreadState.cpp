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
#include "platform/heap/ThreadState.h"

#include "platform/ScriptForbiddenScope.h"
#include "platform/TraceEvent.h"
#include "platform/heap/AddressSanitizer.h"
#include "platform/heap/Handle.h"
#include "platform/heap/Heap.h"
#include "public/platform/Platform.h"
#include "public/platform/WebThread.h"
#include "wtf/ThreadingPrimitives.h"
#if ENABLE(GC_PROFILE_HEAP)
#include "platform/TracedValue.h"
#endif

#if defined(__GLIBC__)
extern "C" void* __libc_stack_end;  // NOLINT
#endif

#if defined(MEMORY_SANITIZER)
#include <sanitizer/msan_interface.h>
#endif

namespace blink {

static void* getStackStart()
{
#if defined(__GLIBC__) || OS(ANDROID)
    pthread_attr_t attr;
    if (!pthread_getattr_np(pthread_self(), &attr)) {
        void* base;
        size_t size;
        int error = pthread_attr_getstack(&attr, &base, &size);
        RELEASE_ASSERT(!error);
        pthread_attr_destroy(&attr);
        return reinterpret_cast<Address>(base) + size;
    }
#if defined(__GLIBC__)
    // pthread_getattr_np can fail for the main thread. In this case
    // just like NaCl we rely on the __libc_stack_end to give us
    // the start of the stack.
    // See https://code.google.com/p/nativeclient/issues/detail?id=3431.
    return __libc_stack_end;
#else
    ASSERT_NOT_REACHED();
    return 0;
#endif
#elif OS(MACOSX)
    return pthread_get_stackaddr_np(pthread_self());
#else
#error Unsupported getStackStart on this platform.
#endif
}

// The maximum number of WrapperPersistentRegions to keep around in the
// m_pooledWrapperPersistentRegions pool.
static const size_t MaxPooledWrapperPersistentRegionCount = 2;

WTF::ThreadSpecific<ThreadState*>* ThreadState::s_threadSpecific = 0;
uint8_t ThreadState::s_mainThreadStateStorage[sizeof(ThreadState)];
SafePointBarrier* ThreadState::s_safePointBarrier = 0;
bool ThreadState::s_inGC = false;

static Mutex& threadAttachMutex()
{
    AtomicallyInitializedStatic(Mutex&, mutex = *new Mutex);
    return mutex;
}

class SafePointBarrier {
public:
    SafePointBarrier() : m_canResume(1), m_unparkedThreadCount(0) { }
    ~SafePointBarrier() { }

    // Request other attached threads that are not at safe points to park themselves on safepoints.
    bool parkOthers()
    {
        return true;
    }

    void resumeOthers(bool barrierLocked = false)
    {
    }

    void checkAndPark(ThreadState* state, SafePointAwareMutexLocker* locker = 0)
    {
    }

    void enterSafePoint(ThreadState* state)
    {
    }

    void leaveSafePoint(ThreadState* state, SafePointAwareMutexLocker* locker = 0)
    {
    }

private:
    void doPark(ThreadState* state, intptr_t* stackEnd)
    {
        state->recordStackEnd(stackEnd);
        MutexLocker locker(m_mutex);
        if (!atomicDecrement(&m_unparkedThreadCount))
            m_parked.signal();
        while (!acquireLoad(&m_canResume))
            m_resume.wait(m_mutex);
        atomicIncrement(&m_unparkedThreadCount);
    }

    static void parkAfterPushRegisters(SafePointBarrier* barrier, ThreadState* state, intptr_t* stackEnd)
    {
        barrier->doPark(state, stackEnd);
    }

    void doEnterSafePoint(ThreadState* state, intptr_t* stackEnd)
    {
        state->recordStackEnd(stackEnd);
        state->copyStackUntilSafePointScope();
        // m_unparkedThreadCount tracks amount of unparked threads. It is
        // positive if and only if we have requested other threads to park
        // at safe-points in preparation for GC. The last thread to park
        // itself will make the counter hit zero and should notify GC thread
        // that it is safe to proceed.
        // If no other thread is waiting for other threads to park then
        // this counter can be negative: if N threads are at safe-points
        // the counter will be -N.
        if (!atomicDecrement(&m_unparkedThreadCount)) {
            MutexLocker locker(m_mutex);
            m_parked.signal(); // Safe point reached.
        }
    }

    static void enterSafePointAfterPushRegisters(SafePointBarrier* barrier, ThreadState* state, intptr_t* stackEnd)
    {
        barrier->doEnterSafePoint(state, stackEnd);
    }

    volatile int m_canResume;
    volatile int m_unparkedThreadCount;
    Mutex m_mutex;
    ThreadCondition m_parked;
    ThreadCondition m_resume;
};

BaseHeapPage::BaseHeapPage(PageMemory* storage, const GCInfo* gcInfo, ThreadState* state)
    : m_storage(storage)
    , m_gcInfo(gcInfo)
    , m_threadState(state)
    , m_terminating(false)
    , m_tracedAfterOrphaned(false)
{
    ASSERT(isPageHeaderAddress(reinterpret_cast<Address>(this)));
}

// Statically unfold the heap initialization loop so the compiler statically
// knows the heap index when using HeapIndexTrait.
template<int num> struct InitializeHeaps {
    static const int index = num - 1;
    static void init(BaseHeap** heaps, ThreadState* state)
    {
        InitializeHeaps<index>::init(heaps, state);
        heaps[index] = new typename HeapIndexTrait<index>::HeapType(state, index);
    }
};
template<> struct InitializeHeaps<0> {
    static void init(BaseHeap** heaps, ThreadState* state) { }
};

ThreadState::ThreadState()
    : m_thread(currentThread())
    , m_liveWrapperPersistents(new WrapperPersistentRegion())
    , m_pooledWrapperPersistents(0)
    , m_pooledWrapperPersistentRegionCount(0)
    , m_persistents(adoptPtr(new PersistentAnchor()))
    , m_startOfStack(reinterpret_cast<intptr_t*>(getStackStart()))
    , m_endOfStack(reinterpret_cast<intptr_t*>(getStackStart()))
    , m_safePointScopeMarker(0)
    , m_atSafePoint(false)
    , m_interruptors()
    , m_gcRequested(false)
    , m_forcePreciseGCForTesting(false)
    , m_sweepRequested(0)
    , m_sweepInProgress(false)
    , m_noAllocationCount(0)
    , m_inGC(false)
    , m_heapContainsCache(adoptPtr(new HeapContainsCache()))
    , m_isTerminating(false)
    , m_lowCollectionRate(false)
    , m_numberOfSweeperTasks(0)
#if defined(ADDRESS_SANITIZER)
    , m_asanFakeStack(__asan_get_current_fake_stack())
#endif
{
    ASSERT(!**s_threadSpecific);
    **s_threadSpecific = this;

    InitializeHeaps<NumberOfHeaps>::init(m_heaps, this);

    CallbackStack::init(&m_weakCallbackStack);
}

ThreadState::~ThreadState()
{
    checkThread();
    CallbackStack::shutdown(&m_weakCallbackStack);
    for (int i = 0; i < NumberOfHeaps; i++)
        delete m_heaps[i];
    deleteAllValues(m_interruptors);
    while (m_liveWrapperPersistents) {
        WrapperPersistentRegion* region = WrapperPersistentRegion::removeHead(&m_liveWrapperPersistents);
        delete region;
    }
    while (m_pooledWrapperPersistents) {
        WrapperPersistentRegion* region = WrapperPersistentRegion::removeHead(&m_pooledWrapperPersistents);
        delete region;
    }
    **s_threadSpecific = 0;
}

void ThreadState::attach()
{
    RELEASE_ASSERT(!Heap::s_shutdownCalled);
    MutexLocker locker(threadAttachMutex());
    ThreadState* state = new ThreadState();
    attachedThreads().add(state);
}

void ThreadState::cleanupPages()
{
    for (int i = 0; i < NumberOfHeaps; ++i)
        m_heaps[i]->cleanupPages();
}

void ThreadState::cleanup()
{
    for (size_t i = 0; i < m_cleanupTasks.size(); i++)
        m_cleanupTasks[i]->preCleanup();

    {
        // Grab the threadAttachMutex to ensure only one thread can shutdown at
        // a time and that no other thread can do a global GC. It also allows
        // safe iteration of the attachedThreads set which happens as part of
        // thread local GC asserts. We enter a safepoint while waiting for the
        // lock to avoid a dead-lock where another thread has already requested
        // GC.
        SafePointAwareMutexLocker locker(threadAttachMutex(), NoHeapPointersOnStack);

        // From here on ignore all conservatively discovered
        // pointers into the heap owned by this thread.
        m_isTerminating = true;

        // Set the terminate flag on all heap pages of this thread. This is used to
        // ensure we don't trace pages on other threads that are not part of the
        // thread local GC.
        setupHeapsForTermination();

        // Do thread local GC's as long as the count of thread local Persistents
        // changes and is above zero.
        PersistentAnchor* anchor = static_cast<PersistentAnchor*>(m_persistents.get());
        int oldCount = -1;
        int currentCount = anchor->numberOfPersistents();
        ASSERT(currentCount >= 0);
        while (currentCount != oldCount) {
            Heap::collectGarbageForTerminatingThread(this);
            oldCount = currentCount;
            currentCount = anchor->numberOfPersistents();
        }
        // We should not have any persistents left when getting to this point,
        // if we have it is probably a bug so adding a debug ASSERT to catch this.
        ASSERT(!currentCount);

        // Add pages to the orphaned page pool to ensure any global GCs from this point
        // on will not trace objects on this thread's heaps.
        cleanupPages();

        ASSERT(attachedThreads().contains(this));
        attachedThreads().remove(this);
    }

    for (size_t i = 0; i < m_cleanupTasks.size(); i++)
        m_cleanupTasks[i]->postCleanup();
    m_cleanupTasks.clear();
}


void ThreadState::visitPersistentRoots(Visitor* visitor)
{
    {
        // All threads are at safepoints so this is not strictly necessary.
        // However we acquire the mutex to make mutation and traversal of this
        // list symmetrical.
        MutexLocker locker(globalRootsMutex());
        globalRoots()->trace(visitor);
    }

    AttachedThreadStateSet& threads = attachedThreads();
    for (AttachedThreadStateSet::iterator it = threads.begin(), end = threads.end(); it != end; ++it)
        (*it)->visitPersistents(visitor);
}

void ThreadState::visitStackRoots(Visitor* visitor)
{
    AttachedThreadStateSet& threads = attachedThreads();
    for (AttachedThreadStateSet::iterator it = threads.begin(), end = threads.end(); it != end; ++it)
        (*it)->visitStack(visitor);
}

NO_SANITIZE_ADDRESS
void ThreadState::visitAsanFakeStackForPointer(Visitor* visitor, Address ptr)
{
#if defined(ADDRESS_SANITIZER)
    Address* start = reinterpret_cast<Address*>(m_startOfStack);
    Address* end = reinterpret_cast<Address*>(m_endOfStack);
    Address* fakeFrameStart = 0;
    Address* fakeFrameEnd = 0;
    Address* maybeFakeFrame = reinterpret_cast<Address*>(ptr);
    Address* realFrameForFakeFrame =
        reinterpret_cast<Address*>(
            __asan_addr_is_in_fake_stack(
                m_asanFakeStack, maybeFakeFrame,
                reinterpret_cast<void**>(&fakeFrameStart),
                reinterpret_cast<void**>(&fakeFrameEnd)));
    if (realFrameForFakeFrame) {
        // This is a fake frame from the asan fake stack.
        if (realFrameForFakeFrame > end && start > realFrameForFakeFrame) {
            // The real stack address for the asan fake frame is
            // within the stack range that we need to scan so we need
            // to visit the values in the fake frame.
            for (Address* p = fakeFrameStart; p < fakeFrameEnd; p++)
                Heap::checkAndMarkPointer(visitor, *p);
        }
    }
#endif
}

NO_SANITIZE_ADDRESS
void ThreadState::visitStack(Visitor* visitor)
{
    if (m_stackState == NoHeapPointersOnStack)
        return;

    Address* start = reinterpret_cast<Address*>(m_startOfStack);
    // If there is a safepoint scope marker we should stop the stack
    // scanning there to not touch active parts of the stack. Anything
    // interesting beyond that point is in the safepoint stack copy.
    // If there is no scope marker the thread is blocked and we should
    // scan all the way to the recorded end stack pointer.
    Address* end = reinterpret_cast<Address*>(m_endOfStack);
    Address* safePointScopeMarker = reinterpret_cast<Address*>(m_safePointScopeMarker);
    Address* current = safePointScopeMarker ? safePointScopeMarker : end;

    // Ensure that current is aligned by address size otherwise the loop below
    // will read past start address.
    current = reinterpret_cast<Address*>(reinterpret_cast<intptr_t>(current) & ~(sizeof(Address) - 1));

    for (; current < start; ++current) {
        Address ptr = *current;
#if defined(MEMORY_SANITIZER)
        // |ptr| may be uninitialized by design. Mark it as initialized to keep
        // MSan from complaining.
        // Note: it may be tempting to get rid of |ptr| and simply use |current|
        // here, but that would be incorrect. We intentionally use a local
        // variable because we don't want to unpoison the original stack.
        __msan_unpoison(&ptr, sizeof(ptr));
#endif
        Heap::checkAndMarkPointer(visitor, ptr);
        visitAsanFakeStackForPointer(visitor, ptr);
    }

    for (Vector<Address>::iterator it = m_safePointStackCopy.begin(); it != m_safePointStackCopy.end(); ++it) {
        Address ptr = *it;
#if defined(MEMORY_SANITIZER)
        // See the comment above.
        __msan_unpoison(&ptr, sizeof(ptr));
#endif
        Heap::checkAndMarkPointer(visitor, ptr);
        visitAsanFakeStackForPointer(visitor, ptr);
    }
}

void ThreadState::visitPersistents(Visitor* visitor)
{
    m_persistents->trace(visitor);
    WrapperPersistentRegion::trace(m_liveWrapperPersistents, visitor);
}

bool ThreadState::checkAndMarkPointer(Visitor* visitor, Address address)
{
    // If thread is terminating ignore conservative pointers.
    if (m_isTerminating)
        return false;

    // This checks for normal pages and for large objects which span the extent
    // of several normal pages.
    BaseHeapPage* page = heapPageFromAddress(address);
    if (page) {
        page->checkAndMarkPointer(visitor, address);
        // Whether or not the pointer was within an object it was certainly
        // within a page that is part of the heap, so we don't want to ask the
        // other other heaps or put this address in the
        // HeapDoesNotContainCache.
        return true;
    }

    return false;
}

#if ENABLE(GC_PROFILE_MARKING)
const GCInfo* ThreadState::findGCInfo(Address address)
{
    BaseHeapPage* page = heapPageFromAddress(address);
    if (page) {
        return page->findGCInfo(address);
    }
    return 0;
}
#endif

#if ENABLE(GC_PROFILE_HEAP)
size_t ThreadState::SnapshotInfo::getClassTag(const GCInfo* gcinfo)
{
    HashMap<const GCInfo*, size_t>::AddResult result = classTags.add(gcinfo, classTags.size());
    if (result.isNewEntry) {
        liveCount.append(0);
        deadCount.append(0);
        liveSize.append(0);
        deadSize.append(0);
        generations.append(Vector<int, 8>());
        generations.last().fill(0, 8);
    }
    return result.storedValue->value;
}

void ThreadState::snapshot()
{
    SnapshotInfo info(this);
    RefPtr<TracedValue> json = TracedValue::create();

#define SNAPSHOT_HEAP(HeapType)                                           \
    {                                                                     \
        json->beginDictionary();                                          \
        json->setString("name", #HeapType);                               \
        m_heaps[HeapType##Heap]->snapshot(json.get(), &info);             \
        json->endDictionary();                                            \
        json->beginDictionary();                                          \
        json->setString("name", #HeapType"NonFinalized");                 \
        m_heaps[HeapType##HeapNonFinalized]->snapshot(json.get(), &info); \
        json->endDictionary();                                            \
    }
    json->beginArray("heaps");
    SNAPSHOT_HEAP(General);
    SNAPSHOT_HEAP(CollectionBacking);
    FOR_EACH_TYPED_HEAP(SNAPSHOT_HEAP);
    json->endArray();
#undef SNAPSHOT_HEAP

    json->setInteger("allocatedSpace", m_stats.totalAllocatedSpace());
    json->setInteger("objectSpace", m_stats.totalObjectSpace());
    json->setInteger("pageCount", info.pageCount);
    json->setInteger("freeSize", info.freeSize);

    Vector<String> classNameVector(info.classTags.size());
    for (HashMap<const GCInfo*, size_t>::iterator it = info.classTags.begin(); it != info.classTags.end(); ++it)
        classNameVector[it->value] = it->key->m_className;

    size_t liveSize = 0;
    size_t deadSize = 0;
    json->beginArray("classes");
    for (size_t i = 0; i < classNameVector.size(); ++i) {
        json->beginDictionary();
        json->setString("name", classNameVector[i]);
        json->setInteger("liveCount", info.liveCount[i]);
        json->setInteger("deadCount", info.deadCount[i]);
        json->setInteger("liveSize", info.liveSize[i]);
        json->setInteger("deadSize", info.deadSize[i]);
        liveSize += info.liveSize[i];
        deadSize += info.deadSize[i];

        json->beginArray("generations");
        for (size_t j = 0; j < heapObjectGenerations; ++j)
            json->pushInteger(info.generations[i][j]);
        json->endArray();
        json->endDictionary();
    }
    json->endArray();
    json->setInteger("liveSize", liveSize);
    json->setInteger("deadSize", deadSize);

    TRACE_EVENT_OBJECT_SNAPSHOT_WITH_ID("blink_gc", "ThreadState", this, json.release());
}
#endif

void ThreadState::pushWeakObjectPointerCallback(void* object, WeakPointerCallback callback)
{
    CallbackStack::Item* slot = m_weakCallbackStack->allocateEntry(&m_weakCallbackStack);
    *slot = CallbackStack::Item(object, callback);
}

bool ThreadState::popAndInvokeWeakPointerCallback(Visitor* visitor)
{
    return m_weakCallbackStack->popAndInvokeCallback<WeaknessProcessing>(&m_weakCallbackStack, visitor);
}

WrapperPersistentRegion* ThreadState::takeWrapperPersistentRegion()
{
    WrapperPersistentRegion* region;
    if (m_pooledWrapperPersistentRegionCount) {
        region = WrapperPersistentRegion::removeHead(&m_pooledWrapperPersistents);
        m_pooledWrapperPersistentRegionCount--;
    } else {
        region = new WrapperPersistentRegion();
    }
    ASSERT(region);
    WrapperPersistentRegion::insertHead(&m_liveWrapperPersistents, region);
    return region;
}

void ThreadState::freeWrapperPersistentRegion(WrapperPersistentRegion* region)
{
    if (!region->removeIfNotLast(&m_liveWrapperPersistents))
        return;

    // Region was removed, ie. it was not the last region in the list.
    if (m_pooledWrapperPersistentRegionCount < MaxPooledWrapperPersistentRegionCount) {
        WrapperPersistentRegion::insertHead(&m_pooledWrapperPersistents, region);
        m_pooledWrapperPersistentRegionCount++;
    } else {
        delete region;
    }
}

PersistentNode* ThreadState::globalRoots()
{
    AtomicallyInitializedStatic(PersistentNode*, anchor = new PersistentAnchor);
    return anchor;
}

Mutex& ThreadState::globalRootsMutex()
{
    AtomicallyInitializedStatic(Mutex&, mutex = *new Mutex);
    return mutex;
}

// Trigger garbage collection on a 50% increase in size, but not for
// less than 512kbytes.
bool ThreadState::increasedEnoughToGC(size_t newSize, size_t oldSize)
{
    if (newSize < 1 << 19)
        return false;
    size_t limit = oldSize + (oldSize >> 1);
    return newSize > limit;
}

// FIXME: The heuristics are local for a thread at this
// point. Consider using heuristics that take memory for all threads
// into account.
bool ThreadState::shouldGC()
{
    // Do not GC during sweeping. We allow allocation during
    // finalization, but those allocations are not allowed
    // to lead to nested garbage collections.
    return !m_sweepInProgress && increasedEnoughToGC(m_stats.totalObjectSpace(), m_statsAfterLastGC.totalObjectSpace());
}

// Trigger conservative garbage collection on a 100% increase in size,
// but not for less than 4Mbytes. If the system currently has a low
// collection rate, then require a 300% increase in size.
bool ThreadState::increasedEnoughToForceConservativeGC(size_t newSize, size_t oldSize)
{
    if (newSize < 1 << 22)
        return false;
    size_t limit = (m_lowCollectionRate ? 4 : 2) * oldSize;
    return newSize > limit;
}

// FIXME: The heuristics are local for a thread at this
// point. Consider using heuristics that take memory for all threads
// into account.
bool ThreadState::shouldForceConservativeGC()
{
    // Do not GC during sweeping. We allow allocation during
    // finalization, but those allocations are not allowed
    // to lead to nested garbage collections.
    return !m_sweepInProgress && increasedEnoughToForceConservativeGC(m_stats.totalObjectSpace(), m_statsAfterLastGC.totalObjectSpace());
}

bool ThreadState::sweepRequested()
{
    ASSERT(isAnyThreadInGC() || checkThread());
    return m_sweepRequested;
}

void ThreadState::setSweepRequested()
{
    // Sweep requested is set from the thread that initiates garbage
    // collection which could be different from the thread for this
    // thread state. Therefore the setting of m_sweepRequested needs a
    // barrier.
    atomicTestAndSetToOne(&m_sweepRequested);
}

void ThreadState::clearSweepRequested()
{
    checkThread();
    m_sweepRequested = 0;
}

bool ThreadState::gcRequested()
{
    checkThread();
    return m_gcRequested;
}

void ThreadState::setGCRequested()
{
    checkThread();
    m_gcRequested = true;
}

void ThreadState::clearGCRequested()
{
    checkThread();
    m_gcRequested = false;
}

void ThreadState::performPendingGC(StackState stackState)
{
    if (stackState == NoHeapPointersOnStack) {
        if (forcePreciseGCForTesting()) {
            setForcePreciseGCForTesting(false);
            Heap::collectAllGarbage();
        } else if (gcRequested()) {
            Heap::collectGarbage(NoHeapPointersOnStack);
        }
    }
}

void ThreadState::setForcePreciseGCForTesting(bool value)
{
    checkThread();
    m_forcePreciseGCForTesting = value;
}

bool ThreadState::forcePreciseGCForTesting()
{
    checkThread();
    return m_forcePreciseGCForTesting;
}

void ThreadState::makeConsistentForSweeping()
{
    for (int i = 0; i < NumberOfHeaps; i++)
        m_heaps[i]->makeConsistentForSweeping();
}

#if ENABLE(ASSERT)
bool ThreadState::isConsistentForSweeping()
{
    for (int i = 0; i < NumberOfHeaps; i++) {
        if (!m_heaps[i]->isConsistentForSweeping())
            return false;
    }
    return true;
}
#endif

void ThreadState::prepareForGC()
{
    for (int i = 0; i < NumberOfHeaps; i++) {
        BaseHeap* heap = m_heaps[i];
        heap->makeConsistentForSweeping();
        // If a new GC is requested before this thread got around to sweep, ie. due to the
        // thread doing a long running operation, we clear the mark bits and mark any of
        // the dead objects as dead. The latter is used to ensure the next GC marking does
        // not trace already dead objects. If we trace a dead object we could end up tracing
        // into garbage or the middle of another object via the newly conservatively found
        // object.
        if (sweepRequested())
            heap->clearLiveAndMarkDead();
    }
    setSweepRequested();
}

void ThreadState::setupHeapsForTermination()
{
    for (int i = 0; i < NumberOfHeaps; i++)
        m_heaps[i]->prepareHeapForTermination();
}

BaseHeapPage* ThreadState::heapPageFromAddress(Address address)
{
    BaseHeapPage* cachedPage = heapContainsCache()->lookup(address);
#if !ENABLE(ASSERT)
    if (cachedPage)
        return cachedPage;
#endif

    for (int i = 0; i < NumberOfHeaps; i++) {
        BaseHeapPage* page = m_heaps[i]->heapPageFromAddress(address);
        if (page) {
            // Asserts that make sure heapPageFromAddress takes addresses from
            // the whole aligned blinkPageSize memory area. This is necessary
            // for the negative cache to work.
            ASSERT(page->isLargeObject() || page == m_heaps[i]->heapPageFromAddress(roundToBlinkPageStart(address)));
            if (roundToBlinkPageStart(address) != roundToBlinkPageEnd(address))
                ASSERT(page->isLargeObject() || page == m_heaps[i]->heapPageFromAddress(roundToBlinkPageEnd(address) - 1));
            ASSERT(!cachedPage || page == cachedPage);
            if (!cachedPage)
                heapContainsCache()->addEntry(address, page);
            return page;
        }
    }
    ASSERT(!cachedPage);
    return 0;
}

void ThreadState::getStats(HeapStats& stats)
{
    stats = m_stats;
#if ENABLE(ASSERT)
    if (isConsistentForSweeping()) {
        HeapStats scannedStats;
        for (int i = 0; i < NumberOfHeaps; i++)
            m_heaps[i]->getScannedStats(scannedStats);
        ASSERT(scannedStats == stats);
    }
#endif
}

bool ThreadState::stopThreads()
{
    return s_safePointBarrier->parkOthers();
}

void ThreadState::resumeThreads()
{
    s_safePointBarrier->resumeOthers();
}

void ThreadState::safePoint(StackState stackState)
{
    checkThread();
    performPendingGC(stackState);
    ASSERT(!m_atSafePoint);
    m_stackState = stackState;
    m_atSafePoint = true;
    s_safePointBarrier->checkAndPark(this);
    m_atSafePoint = false;
    m_stackState = HeapPointersOnStack;
    performPendingSweep();
}

#ifdef ADDRESS_SANITIZER
// When we are running under AddressSanitizer with detect_stack_use_after_return=1
// then stack marker obtained from SafePointScope will point into a fake stack.
// Detect this case by checking if it falls in between current stack frame
// and stack start and use an arbitrary high enough value for it.
// Don't adjust stack marker in any other case to match behavior of code running
// without AddressSanitizer.
NO_SANITIZE_ADDRESS static void* adjustScopeMarkerForAdressSanitizer(void* scopeMarker)
{
    Address start = reinterpret_cast<Address>(getStackStart());
    Address end = reinterpret_cast<Address>(&start);
    RELEASE_ASSERT(end < start);

    if (end <= scopeMarker && scopeMarker < start)
        return scopeMarker;

    // 256 is as good an approximation as any else.
    const size_t bytesToCopy = sizeof(Address) * 256;
    if (static_cast<size_t>(start - end) < bytesToCopy)
        return start;

    return end + bytesToCopy;
}
#endif

void ThreadState::enterSafePoint(StackState stackState, void* scopeMarker)
{
#ifdef ADDRESS_SANITIZER
    if (stackState == HeapPointersOnStack)
        scopeMarker = adjustScopeMarkerForAdressSanitizer(scopeMarker);
#endif
    ASSERT(stackState == NoHeapPointersOnStack || scopeMarker);
    performPendingGC(stackState);
    checkThread();
    ASSERT(!m_atSafePoint);
    m_atSafePoint = true;
    m_stackState = stackState;
    m_safePointScopeMarker = scopeMarker;
    s_safePointBarrier->enterSafePoint(this);
}

void ThreadState::leaveSafePoint(SafePointAwareMutexLocker* locker)
{
    checkThread();
    ASSERT(m_atSafePoint);
    s_safePointBarrier->leaveSafePoint(this, locker);
    m_atSafePoint = false;
    m_stackState = HeapPointersOnStack;
    clearSafePointScopeMarker();
    performPendingSweep();
}

void ThreadState::copyStackUntilSafePointScope()
{
    if (!m_safePointScopeMarker || m_stackState == NoHeapPointersOnStack)
        return;

    Address* to = reinterpret_cast<Address*>(m_safePointScopeMarker);
    Address* from = reinterpret_cast<Address*>(m_endOfStack);
    RELEASE_ASSERT(from < to);
    RELEASE_ASSERT(to <= reinterpret_cast<Address*>(m_startOfStack));
    size_t slotCount = static_cast<size_t>(to - from);
    // Catch potential performance issues.
#if defined(LEAK_SANITIZER) || defined(ADDRESS_SANITIZER)
    // ASan/LSan use more space on the stack and we therefore
    // increase the allowed stack copying for those builds.
    ASSERT(slotCount < 2048);
#else
    ASSERT(slotCount < 1024);
#endif

    ASSERT(!m_safePointStackCopy.size());
    m_safePointStackCopy.resize(slotCount);
    for (size_t i = 0; i < slotCount; ++i) {
        m_safePointStackCopy[i] = from[i];
    }
}

void ThreadState::registerSweepingTask()
{
    MutexLocker locker(m_sweepMutex);
    ++m_numberOfSweeperTasks;
}

void ThreadState::unregisterSweepingTask()
{
    MutexLocker locker(m_sweepMutex);
    ASSERT(m_numberOfSweeperTasks > 0);
    if (!--m_numberOfSweeperTasks)
        m_sweepThreadCondition.signal();
}

void ThreadState::waitUntilSweepersDone()
{
    MutexLocker locker(m_sweepMutex);
    while (m_numberOfSweeperTasks > 0)
        m_sweepThreadCondition.wait(m_sweepMutex);
}

void ThreadState::performPendingSweep()
{
}

void ThreadState::addInterruptor(Interruptor* interruptor)
{
    SafePointScope scope(HeapPointersOnStack, SafePointScope::AllowNesting);

    {
        MutexLocker locker(threadAttachMutex());
        m_interruptors.append(interruptor);
    }
}

void ThreadState::removeInterruptor(Interruptor* interruptor)
{
    SafePointScope scope(HeapPointersOnStack, SafePointScope::AllowNesting);

    {
        MutexLocker locker(threadAttachMutex());
        size_t index = m_interruptors.find(interruptor);
        RELEASE_ASSERT(index >= 0);
        m_interruptors.remove(index);
    }
}

void ThreadState::Interruptor::onInterrupted()
{
    ThreadState* state = ThreadState::current();
    ASSERT(state);
    ASSERT(!state->isAtSafePoint());
    state->safePoint(HeapPointersOnStack);
}

ThreadState::AttachedThreadStateSet& ThreadState::attachedThreads()
{
    DEFINE_STATIC_LOCAL(AttachedThreadStateSet, threads, ());
    return threads;
}

#if ENABLE(GC_PROFILE_MARKING)
const GCInfo* ThreadState::findGCInfoFromAllThreads(Address address)
{
    bool needLockForIteration = !isAnyThreadInGC();
    if (needLockForIteration)
        threadAttachMutex().lock();

    ThreadState::AttachedThreadStateSet& threads = attachedThreads();
    for (ThreadState::AttachedThreadStateSet::iterator it = threads.begin(), end = threads.end(); it != end; ++it) {
        if (const GCInfo* gcInfo = (*it)->findGCInfo(address)) {
            if (needLockForIteration)
                threadAttachMutex().unlock();
            return gcInfo;
        }
    }
    if (needLockForIteration)
        threadAttachMutex().unlock();
    return 0;
}
#endif

}
