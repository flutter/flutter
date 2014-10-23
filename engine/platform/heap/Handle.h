/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
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

#ifndef Handle_h
#define Handle_h

#include "platform/heap/Heap.h"
#include "platform/heap/ThreadState.h"
#include "platform/heap/Visitor.h"
#include "wtf/Functional.h"
#include "wtf/HashFunctions.h"
#include "wtf/Locker.h"
#include "wtf/RawPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/TypeTraits.h"

namespace blink {

template<typename T> class HeapTerminatedArray;

// Template to determine if a class is a GarbageCollectedMixin by checking if it
// has adjustAndMark and isAlive. We can't check directly if the class is a
// GarbageCollectedMixin because casting to it is potentially ambiguous.
template<typename T>
struct IsGarbageCollectedMixin {
    typedef char TrueType;
    struct FalseType {
        char dummy[2];
    };

#if COMPILER(MSVC)
    template<typename U> static TrueType hasAdjustAndMark(char[&U::adjustAndMark != 0]);
    template<typename U> static TrueType hasIsAlive(char[&U::isAlive != 0]);
#else
    template<size_t> struct F;
    template<typename U> static TrueType hasAdjustAndMark(F<sizeof(&U::adjustAndMark)>*);
    template<typename U> static TrueType hasIsAlive(F<sizeof(&U::isAlive)>*);
#endif
    template<typename U> static FalseType hasIsAlive(...);
    template<typename U> static FalseType hasAdjustAndMark(...);

    static bool const value = (sizeof(TrueType) == sizeof(hasAdjustAndMark<T>(0))) && (sizeof(TrueType) == sizeof(hasIsAlive<T>(0)));
};

template <typename T>
struct IsGarbageCollectedType {
    typedef char TrueType;
    struct FalseType {
        char dummy[2];
    };

    typedef typename WTF::RemoveConst<T>::Type NonConstType;
    typedef WTF::IsSubclassOfTemplate<NonConstType, GarbageCollected> GarbageCollectedSubclass;
    typedef IsGarbageCollectedMixin<NonConstType> GarbageCollectedMixinSubclass;
    typedef WTF::IsSubclassOfTemplate3<NonConstType, HeapHashSet> HeapHashSetSubclass;
    typedef WTF::IsSubclassOfTemplate3<NonConstType, HeapLinkedHashSet> HeapLinkedHashSetSubclass;
    typedef WTF::IsSubclassOfTemplateTypenameSizeTypename<NonConstType, HeapListHashSet> HeapListHashSetSubclass;
    typedef WTF::IsSubclassOfTemplate5<NonConstType, HeapHashMap> HeapHashMapSubclass;
    typedef WTF::IsSubclassOfTemplateTypenameSize<NonConstType, HeapVector> HeapVectorSubclass;
    typedef WTF::IsSubclassOfTemplateTypenameSize<NonConstType, HeapDeque> HeapDequeSubclass;
    typedef WTF::IsSubclassOfTemplate3<NonConstType, HeapHashCountedSet> HeapHashCountedSetSubclass;
    typedef WTF::IsSubclassOfTemplate<NonConstType, HeapTerminatedArray> HeapTerminatedArraySubclass;

    template<typename U, size_t inlineCapacity> static TrueType listHashSetNodeIsHeapAllocated(WTF::ListHashSetNode<U, HeapListHashSetAllocator<U, inlineCapacity> >*);
    static FalseType listHashSetNodeIsHeapAllocated(...);
    static const bool isHeapAllocatedListHashSetNode = sizeof(TrueType) == sizeof(listHashSetNodeIsHeapAllocated(reinterpret_cast<NonConstType*>(0)));

    static const bool value =
        GarbageCollectedSubclass::value
        || GarbageCollectedMixinSubclass::value
        || HeapHashSetSubclass::value
        || HeapLinkedHashSetSubclass::value
        || HeapListHashSetSubclass::value
        || HeapHashMapSubclass::value
        || HeapVectorSubclass::value
        || HeapDequeSubclass::value
        || HeapHashCountedSetSubclass::value
        || HeapTerminatedArraySubclass::value
        || isHeapAllocatedListHashSetNode;
};

#define COMPILE_ASSERT_IS_GARBAGE_COLLECTED(T, ErrorMessage) \
    COMPILE_ASSERT(IsGarbageCollectedType<T>::value, ErrorMessage)

template<typename T> class Member;

class PersistentNode {
public:
    explicit PersistentNode(TraceCallback trace)
        : m_trace(trace)
    {
    }

    bool isAlive() { return m_trace; }

    virtual ~PersistentNode()
    {
        ASSERT(isAlive());
        m_trace = 0;
    }

    // Ideally the trace method should be virtual and automatically dispatch
    // to the most specific implementation. However having a virtual method
    // on PersistentNode leads to too eager template instantiation with MSVC
    // which leads to include cycles.
    // Instead we call the constructor with a TraceCallback which knows the
    // type of the most specific child and calls trace directly. See
    // TraceMethodDelegate in Visitor.h for how this is done.
    void trace(Visitor* visitor)
    {
        m_trace(visitor, this);
    }

protected:
    TraceCallback m_trace;

private:
    PersistentNode* m_next;
    PersistentNode* m_prev;

    template<typename RootsAccessor, typename Owner> friend class PersistentBase;
    friend class PersistentAnchor;
    friend class ThreadState;
};


const int wrapperPersistentsPerRegion = 256;
const size_t wrapperPersistentOffsetMask = ~static_cast<size_t>(3);
const size_t wrapperPersistentLiveBitMask = 1;

class WrapperPersistentNode {
    WTF_MAKE_NONCOPYABLE(WrapperPersistentNode);
public:
    bool isAlive() { return m_regionOffset & wrapperPersistentLiveBitMask; }

    WrapperPersistentRegion* region()
    {
        return reinterpret_cast<WrapperPersistentRegion*>(
            reinterpret_cast<Address>(this) - (m_regionOffset & wrapperPersistentOffsetMask));
    }

    virtual ~WrapperPersistentNode()
    {
        m_regionOffset &= ~wrapperPersistentLiveBitMask;
    }

    virtual void trace(Visitor* visitor) { }

protected:
    WrapperPersistentNode() : m_raw(0), m_regionOffset(0) { }

    explicit WrapperPersistentNode(void* raw)
    {
        // When the constructor is called the slot should have been taken (takeSlot)
        // as part of allocating the memory (via operator new). Hence the m_raw
        // pointer should be 0.
        ASSERT(!m_raw);
        m_raw = raw;
        // The m_regionOffset should always be set as an offset to the containing
        // region. However it should not have the live bit set when the constructor
        // is called.
        ASSERT(m_regionOffset);
        ASSERT(!isAlive());
        m_regionOffset |= wrapperPersistentLiveBitMask;
    }

private:
    void initSlot(size_t regionOffset, WrapperPersistentNode* nextFree)
    {
        ASSERT(!m_raw);
        ASSERT(!m_regionOffset);
        ASSERT(!(regionOffset & ~wrapperPersistentOffsetMask));
        m_raw = nextFree;
        m_regionOffset = regionOffset;
    }

    WrapperPersistentNode* takeSlot()
    {
        // The slot should not be alive at the point where it is allocated.
        ASSERT(!isAlive());
        WrapperPersistentNode* nextFree = reinterpret_cast<WrapperPersistentNode*>(m_raw);
        m_raw = 0;
        return nextFree;
    }

    WrapperPersistentNode* freeSlot(WrapperPersistentNode* nextFree)
    {
        // When the slot is freed the destructor should already have cleared the live bit.
        ASSERT(!isAlive());
        m_raw = nextFree;
        return this;
    }

protected:
    // m_raw is used both to point to the object when the WrapperPersistentNode is used/alive
    // and to point to the next free wrapperPersistentNode in the region when the node is
    // unused/dead.
    void* m_raw;

    // The m_regionOffset field is an offset from this node to the base of the containing
    // WrapperPersistentRegion.
    size_t m_regionOffset;

    friend class WrapperPersistentRegion;
};

template<typename T>
class WrapperPersistent FINAL : public WrapperPersistentNode {
public:
    WrapperPersistent() : WrapperPersistentNode(0) { }
    WrapperPersistent(std::nullptr_t) : WrapperPersistentNode(0) { }
    WrapperPersistent(T* raw) : WrapperPersistentNode(raw) { }
    WrapperPersistent(T& raw) : WrapperPersistentNode(&raw) { }

    void* operator new(size_t);
    void operator delete(void*);

    virtual void trace(Visitor* visitor)
    {
        ASSERT(isAlive());
        visitor->mark(static_cast<T*>(m_raw));
    }
};

class PLATFORM_EXPORT WrapperPersistentRegion {
    WTF_MAKE_NONCOPYABLE(WrapperPersistentRegion);
public:
    WrapperPersistentRegion()
    {
        WrapperPersistentNode* nextFree = 0;
        for (int i = wrapperPersistentsPerRegion - 1; i >= 0; --i) {
            size_t regionOffset = reinterpret_cast<Address>(&m_entries[i]) - reinterpret_cast<Address>(this);
            // Setup the free slot with an offset to the containing region's base and a pointer to the next
            // free slot in the region.
            m_entries[i].initSlot(regionOffset, nextFree);
            nextFree = &m_entries[i];
        }
        m_prev = 0;
        m_next = 0;
        m_freeHead = nextFree;
        m_count = 0;
    }

    void* allocate()
    {
        if (!m_freeHead) {
            ASSERT(m_count == wrapperPersistentsPerRegion);
            return 0;
        }
        // We have a free persistent slot in this region.
        WrapperPersistentNode* freeSlot = m_freeHead;
        // Take the slot and advance m_freeHead to the next free slot.
        m_freeHead = freeSlot->takeSlot();
        ASSERT(m_count < wrapperPersistentsPerRegion);
        m_count++;
        return reinterpret_cast<void*>(freeSlot);
    }

    void free(WrapperPersistentNode* object)
    {
        ASSERT(object);
        ASSERT(!object->isAlive());
        m_freeHead = object->freeSlot(m_freeHead);
        ASSERT(m_count > 0);
        m_count--;
        if (!m_count)
            ThreadState::current()->freeWrapperPersistentRegion(this);
    }

    bool removeIfNotLast(WrapperPersistentRegion** headPtr);
    static void insertHead(WrapperPersistentRegion** headPtr, WrapperPersistentRegion* newHead);
    static WrapperPersistentRegion* removeHead(WrapperPersistentRegion** headPtr);
    static void* outOfLineAllocate(ThreadState*, WrapperPersistentRegion*);
    static void trace(WrapperPersistentRegion* head, Visitor* visitor)
    {
        for (WrapperPersistentRegion* current = head; current; current = current->m_next)
            current->traceRegion(visitor);
    }

private:
    void traceRegion(Visitor* visitor)
    {
        size_t live = 0;

#ifdef NDEBUG
        for (int i = 0; i < wrapperPersistentsPerRegion && live < m_count; ++i) {
#else
        // In DEBUG mode we scan all entries to validate we only have m_count
        // live entries.
        for (int i = 0; i < wrapperPersistentsPerRegion; ++i) {
#endif
            if (m_entries[i].isAlive()) {
                m_entries[i].trace(visitor);
                live++;
            }
        }
        ASSERT(live == m_count);
    }

    WrapperPersistentRegion* m_prev;
    WrapperPersistentRegion* m_next;
    WrapperPersistentNode* m_freeHead;
    size_t m_count;
    WrapperPersistentNode m_entries[wrapperPersistentsPerRegion];
};

template<typename T>
void* WrapperPersistent<T>::operator new(size_t size)
{
    ASSERT(size == sizeof(WrapperPersistent<T>));
    ThreadState* state = ThreadState::current();
    WrapperPersistentRegion* region = state->wrapperRoots();
    ASSERT(region);
    void* persistent = region->allocate();
    if (!persistent)
        return WrapperPersistentRegion::outOfLineAllocate(state, region);
    return persistent;
}

template<typename T>
void WrapperPersistent<T>::operator delete(void* object)
{
    WrapperPersistentNode* persistent = static_cast<WrapperPersistentNode*>(object);
    persistent->region()->free(persistent);
}

// RootsAccessor for Persistent that provides access to thread-local list
// of persistent handles. Can only be used to create handles that
// are constructed and destructed on the same thread.
template<ThreadAffinity Affinity>
class ThreadLocalPersistents {
public:
    static PersistentNode* roots() { return state()->roots(); }

    // No locking required. Just check that we are at the right thread.
    class Lock {
    public:
        Lock() { state()->checkThread(); }
    };

private:
    static ThreadState* state() { return ThreadStateFor<Affinity>::state(); }
};

// RootsAccessor for Persistent that provides synchronized access to global
// list of persistent handles. Can be used for persistent handles that are
// passed between threads.
class GlobalPersistents {
public:
    static PersistentNode* roots() { return ThreadState::globalRoots(); }

    class Lock {
    public:
        Lock() : m_locker(ThreadState::globalRootsMutex()) { }
    private:
        MutexLocker m_locker;
    };
};

// Base class for persistent handles. RootsAccessor specifies which list to
// link resulting handle into. Owner specifies the class containing trace
// method.
template<typename RootsAccessor, typename Owner>
class PersistentBase : public PersistentNode {
public:
    ~PersistentBase()
    {
        typename RootsAccessor::Lock lock;
        ASSERT(m_roots == RootsAccessor::roots()); // Check that the thread is using the same roots list.
        ASSERT(isAlive());
        ASSERT(m_next->isAlive());
        ASSERT(m_prev->isAlive());
        m_next->m_prev = m_prev;
        m_prev->m_next = m_next;
    }

protected:
    inline PersistentBase()
        : PersistentNode(TraceMethodDelegate<Owner, &Owner::trace>::trampoline)
#if ENABLE(ASSERT)
        , m_roots(RootsAccessor::roots())
#endif
    {
        typename RootsAccessor::Lock lock;
        m_prev = RootsAccessor::roots();
        m_next = m_prev->m_next;
        m_prev->m_next = this;
        m_next->m_prev = this;
    }

    inline explicit PersistentBase(const PersistentBase& otherref)
        : PersistentNode(otherref.m_trace)
#if ENABLE(ASSERT)
        , m_roots(RootsAccessor::roots())
#endif
    {
        // We don't support allocation of thread local Persistents while doing
        // thread shutdown/cleanup.
        ASSERT(!ThreadState::current()->isTerminating());
        typename RootsAccessor::Lock lock;
        ASSERT(otherref.m_roots == m_roots); // Handles must belong to the same list.
        PersistentBase* other = const_cast<PersistentBase*>(&otherref);
        m_prev = other;
        m_next = other->m_next;
        other->m_next = this;
        m_next->m_prev = this;
    }

    inline PersistentBase& operator=(const PersistentBase& otherref) { return *this; }

#if ENABLE(ASSERT)
private:
    PersistentNode* m_roots;
#endif
};

// A dummy Persistent handle that ensures the list of persistents is never null.
// This removes a test from a hot path.
class PersistentAnchor : public PersistentNode {
public:
    void trace(Visitor* visitor)
    {
        for (PersistentNode* current = m_next; current != this; current = current->m_next)
            current->trace(visitor);
    }

    int numberOfPersistents()
    {
        int numberOfPersistents = 0;
        for (PersistentNode* current = m_next; current != this; current = current->m_next)
            ++numberOfPersistents;
        return numberOfPersistents;
    }

    virtual ~PersistentAnchor()
    {
        // FIXME: oilpan: Ideally we should have no left-over persistents at this point. However currently there is a
        // large number of objects leaked when we tear down the main thread. Since some of these might contain a
        // persistent or e.g. be RefCountedGarbageCollected we cannot guarantee there are no remaining Persistents at
        // this point.
    }

private:
    PersistentAnchor() : PersistentNode(TraceMethodDelegate<PersistentAnchor, &PersistentAnchor::trace>::trampoline)
    {
        m_next = this;
        m_prev = this;
    }

    friend class ThreadState;
};

#if ENABLE(ASSERT)
    // For global persistent handles we cannot check that the
    // pointer is in the heap because that would involve
    // inspecting the heap of running threads.
#define ASSERT_IS_VALID_PERSISTENT_POINTER(pointer) \
    bool isGlobalPersistent = WTF::IsSubclass<RootsAccessor, GlobalPersistents>::value; \
    ASSERT(!pointer || isGlobalPersistent || ThreadStateFor<ThreadingTrait<T>::Affinity>::state()->contains(pointer))
#else
#define ASSERT_IS_VALID_PERSISTENT_POINTER(pointer)
#endif

template<typename T>
class CrossThreadPersistent;

// Persistent handles are used to store pointers into the
// managed heap. As long as the Persistent handle is alive
// the GC will keep the object pointed to alive. Persistent
// handles can be stored in objects and they are not scoped.
// Persistent handles must not be used to contain pointers
// between objects that are in the managed heap. They are only
// meant to point to managed heap objects from variables/members
// outside the managed heap.
//
// A Persistent is always a GC root from the point of view of
// the garbage collector.
//
// We have to construct and destruct Persistent with default RootsAccessor in
// the same thread.
template<typename T, typename RootsAccessor /* = ThreadLocalPersistents<ThreadingTrait<T>::Affinity > */ >
class Persistent : public PersistentBase<RootsAccessor, Persistent<T, RootsAccessor> > {
    WTF_DISALLOW_CONSTRUCTION_FROM_ZERO(Persistent);
    WTF_DISALLOW_ZERO_ASSIGNMENT(Persistent);
public:
    Persistent() : m_raw(0) { }

    Persistent(std::nullptr_t) : m_raw(0) { }

    Persistent(T* raw) : m_raw(raw)
    {
        ASSERT_IS_VALID_PERSISTENT_POINTER(m_raw);
        recordBacktrace();
    }

    explicit Persistent(T& raw) : m_raw(&raw)
    {
        ASSERT_IS_VALID_PERSISTENT_POINTER(m_raw);
        recordBacktrace();
    }

    Persistent(const Persistent& other) : m_raw(other) { recordBacktrace(); }

    template<typename U>
    Persistent(const Persistent<U, RootsAccessor>& other) : m_raw(other) { recordBacktrace(); }

    template<typename U>
    Persistent(const Member<U>& other) : m_raw(other) { recordBacktrace(); }

    template<typename U>
    Persistent(const RawPtr<U>& other) : m_raw(other.get()) { recordBacktrace(); }

    template<typename U>
    Persistent& operator=(U* other)
    {
        m_raw = other;
        recordBacktrace();
        return *this;
    }

    Persistent& operator=(std::nullptr_t)
    {
        m_raw = 0;
        return *this;
    }

    void clear() { m_raw = 0; }

    virtual ~Persistent()
    {
        m_raw = 0;
    }

    template<typename U>
    U* as() const
    {
        return static_cast<U*>(m_raw);
    }

    void trace(Visitor* visitor)
    {
        COMPILE_ASSERT_IS_GARBAGE_COLLECTED(T, NonGarbageCollectedObjectInPersistent);
#if ENABLE(GC_PROFILE_MARKING)
        visitor->setHostInfo(this, m_tracingName.isEmpty() ? "Persistent" : m_tracingName);
#endif
        visitor->mark(m_raw);
    }

    RawPtr<T> release()
    {
        RawPtr<T> result = m_raw;
        m_raw = 0;
        return result;
    }

    T& operator*() const { return *m_raw; }

    bool operator!() const { return !m_raw; }

    operator T*() const { return m_raw; }
    operator RawPtr<T>() const { return m_raw; }

    T* operator->() const { return *this; }

    Persistent& operator=(const Persistent& other)
    {
        m_raw = other;
        recordBacktrace();
        return *this;
    }

    template<typename U>
    Persistent& operator=(const Persistent<U, RootsAccessor>& other)
    {
        m_raw = other;
        recordBacktrace();
        return *this;
    }

    template<typename U>
    Persistent& operator=(const Member<U>& other)
    {
        m_raw = other;
        recordBacktrace();
        return *this;
    }

    template<typename U>
    Persistent& operator=(const RawPtr<U>& other)
    {
        m_raw = other;
        recordBacktrace();
        return *this;
    }

    T* get() const { return m_raw; }

private:
#if ENABLE(GC_PROFILE_MARKING)
    void recordBacktrace()
    {
        if (m_raw)
            m_tracingName = Heap::createBacktraceString();
    }

    String m_tracingName;
#else
    inline void recordBacktrace() const { }
#endif
    T* m_raw;

    friend class CrossThreadPersistent<T>;
};

// Unlike Persistent, we can destruct a CrossThreadPersistent in a thread
// different from the construction thread.
template<typename T>
class CrossThreadPersistent : public Persistent<T, GlobalPersistents> {
    WTF_DISALLOW_CONSTRUCTION_FROM_ZERO(CrossThreadPersistent);
    WTF_DISALLOW_ZERO_ASSIGNMENT(CrossThreadPersistent);
public:
    CrossThreadPersistent(T* raw) : Persistent<T, GlobalPersistents>(raw) { }

    using Persistent<T, GlobalPersistents>::operator=;
};

// FIXME: derive affinity based on the collection.
template<typename Collection, ThreadAffinity Affinity = AnyThread>
class PersistentHeapCollectionBase
    : public Collection
    , public PersistentBase<ThreadLocalPersistents<Affinity>, PersistentHeapCollectionBase<Collection, Affinity> > {
    // We overload the various new and delete operators with using the WTF DefaultAllocator to ensure persistent
    // heap collections are always allocated off-heap. This allows persistent collections to be used in
    // DEFINE_STATIC_LOCAL et. al.
    WTF_USE_ALLOCATOR(PersistentHeapCollectionBase, WTF::DefaultAllocator);
public:
    PersistentHeapCollectionBase() { }

    template<typename OtherCollection>
    PersistentHeapCollectionBase(const OtherCollection& other) : Collection(other) { }

    void trace(Visitor* visitor)
    {
#if ENABLE(GC_PROFILE_MARKING)
        visitor->setHostInfo(this, "PersistentHeapCollectionBase");
#endif
        visitor->trace(*static_cast<Collection*>(this));
    }
};

template<
    typename KeyArg,
    typename MappedArg,
    typename HashArg = typename DefaultHash<KeyArg>::Hash,
    typename KeyTraitsArg = HashTraits<KeyArg>,
    typename MappedTraitsArg = HashTraits<MappedArg> >
class PersistentHeapHashMap : public PersistentHeapCollectionBase<HeapHashMap<KeyArg, MappedArg, HashArg, KeyTraitsArg, MappedTraitsArg> > { };

template<
    typename ValueArg,
    typename HashArg = typename DefaultHash<ValueArg>::Hash,
    typename TraitsArg = HashTraits<ValueArg> >
class PersistentHeapHashSet : public PersistentHeapCollectionBase<HeapHashSet<ValueArg, HashArg, TraitsArg> > { };

template<
    typename ValueArg,
    typename HashArg = typename DefaultHash<ValueArg>::Hash,
    typename TraitsArg = HashTraits<ValueArg> >
class PersistentHeapLinkedHashSet : public PersistentHeapCollectionBase<HeapLinkedHashSet<ValueArg, HashArg, TraitsArg> > { };

template<
    typename ValueArg,
    size_t inlineCapacity = 0,
    typename HashArg = typename DefaultHash<ValueArg>::Hash>
class PersistentHeapListHashSet : public PersistentHeapCollectionBase<HeapListHashSet<ValueArg, inlineCapacity, HashArg> > { };

template<typename T, typename U, typename V>
class PersistentHeapHashCountedSet : public PersistentHeapCollectionBase<HeapHashCountedSet<T, U, V> > { };

template<typename T, size_t inlineCapacity = 0>
class PersistentHeapVector : public PersistentHeapCollectionBase<HeapVector<T, inlineCapacity> > {
public:
    PersistentHeapVector() { }

    template<size_t otherCapacity>
    PersistentHeapVector(const HeapVector<T, otherCapacity>& other)
        : PersistentHeapCollectionBase<HeapVector<T, inlineCapacity> >(other)
    {
    }
};

template<typename T, size_t inlineCapacity = 0>
class PersistentHeapDeque : public PersistentHeapCollectionBase<HeapDeque<T, inlineCapacity> > {
public:
    PersistentHeapDeque() { }

    template<size_t otherCapacity>
    PersistentHeapDeque(const HeapDeque<T, otherCapacity>& other)
        : PersistentHeapCollectionBase<HeapDeque<T, inlineCapacity> >(other)
    {
    }
};

// Members are used in classes to contain strong pointers to other oilpan heap
// allocated objects.
// All Member fields of a class must be traced in the class' trace method.
// During the mark phase of the GC all live objects are marked as live and
// all Member fields of a live object will be traced marked as live as well.
template<typename T>
class Member {
    WTF_DISALLOW_CONSTRUCTION_FROM_ZERO(Member);
    WTF_DISALLOW_ZERO_ASSIGNMENT(Member);
public:
    Member() : m_raw(0)
    {
    }

    Member(std::nullptr_t) : m_raw(0)
    {
    }

    Member(T* raw) : m_raw(raw)
    {
    }

    explicit Member(T& raw) : m_raw(&raw)
    {
    }

    template<typename U>
    Member(const RawPtr<U>& other) : m_raw(other.get())
    {
    }

    Member(WTF::HashTableDeletedValueType) : m_raw(reinterpret_cast<T*>(-1))
    {
    }

    bool isHashTableDeletedValue() const { return m_raw == reinterpret_cast<T*>(-1); }

    template<typename U>
    Member(const Persistent<U>& other) : m_raw(other) { }

    Member(const Member& other) : m_raw(other) { }

    template<typename U>
    Member(const Member<U>& other) : m_raw(other) { }

    T* release()
    {
        T* result = m_raw;
        m_raw = 0;
        return result;
    }

    template<typename U>
    U* as() const
    {
        return static_cast<U*>(m_raw);
    }

    bool operator!() const { return !m_raw; }

    operator T*() const { return m_raw; }

    T* operator->() const { return m_raw; }
    T& operator*() const { return *m_raw; }
    template<typename U>
    operator RawPtr<U>() const { return m_raw; }

    template<typename U>
    Member& operator=(const Persistent<U>& other)
    {
        m_raw = other;
        return *this;
    }

    template<typename U>
    Member& operator=(const Member<U>& other)
    {
        m_raw = other;
        return *this;
    }

    template<typename U>
    Member& operator=(U* other)
    {
        m_raw = other;
        return *this;
    }

    template<typename U>
    Member& operator=(RawPtr<U> other)
    {
        m_raw = other;
        return *this;
    }

    Member& operator=(std::nullptr_t)
    {
        m_raw = 0;
        return *this;
    }

    void swap(Member<T>& other) { std::swap(m_raw, other.m_raw); }

    T* get() const { return m_raw; }

    void clear() { m_raw = 0; }


protected:
    void verifyTypeIsGarbageCollected() const
    {
        COMPILE_ASSERT_IS_GARBAGE_COLLECTED(T, NonGarbageCollectedObjectInMember);
    }

    T* m_raw;

    template<bool x, WTF::WeakHandlingFlag y, WTF::ShouldWeakPointersBeMarkedStrongly z, typename U, typename V> friend struct CollectionBackingTraceTrait;
    friend class Visitor;
};

template<typename T>
class TraceTrait<Member<T> > {
public:
    static void trace(Visitor* visitor, void* self)
    {
        TraceTrait<T>::mark(visitor, *static_cast<Member<T>*>(self));
    }
};

// TraceTrait to allow compilation of trace method bodies when oilpan is disabled.
// This should never be called, but is needed to compile.
template<typename T>
class TraceTrait<RefPtr<T> > {
public:
    static void trace(Visitor*, void*)
    {
        ASSERT_NOT_REACHED();
    }
};

template<typename T>
class TraceTrait<OwnPtr<T> > {
public:
    static void trace(Visitor* visitor, OwnPtr<T>* ptr)
    {
        ASSERT_NOT_REACHED();
    }
};

template<typename T, bool needsTracing>
struct TraceIfEnabled;

template<typename T>
struct TraceIfEnabled<T, false>  {
    static void trace(Visitor*, T*) { }
};

template<typename T>
struct TraceIfEnabled<T, true> {
    static void trace(Visitor* visitor, T* t)
    {
        visitor->trace(*t);
    }
};

template <typename T> struct RemoveHeapPointerWrapperTypes {
    typedef typename WTF::RemoveTemplate<typename WTF::RemoveTemplate<typename WTF::RemoveTemplate<T, Member>::Type, WeakMember>::Type, RawPtr>::Type Type;
};

// FIXME: Oilpan: TraceIfNeeded should be implemented ala:
// NeedsTracing<T>::value || IsWeakMember<T>::value. It should not need to test
// raw pointer types. To remove these tests, we may need support for
// instantiating a template with a RawPtrOrMember'ish template.
template<typename T>
struct TraceIfNeeded : public TraceIfEnabled<T, WTF::NeedsTracing<T>::value || blink::IsGarbageCollectedType<typename RemoveHeapPointerWrapperTypes<typename WTF::RemovePointer<T>::Type>::Type>::value> { };

// This trace trait for std::pair will null weak members if their referent is
// collected. If you have a collection that contain weakness it does not remove
// entries from the collection that contain nulled weak members.
template<typename T, typename U>
class TraceTrait<std::pair<T, U> > {
public:
    static const bool firstNeedsTracing = WTF::NeedsTracing<T>::value || WTF::IsWeak<T>::value;
    static const bool secondNeedsTracing = WTF::NeedsTracing<U>::value || WTF::IsWeak<U>::value;
    static void trace(Visitor* visitor, std::pair<T, U>* pair)
    {
        TraceIfEnabled<T, firstNeedsTracing>::trace(visitor, &pair->first);
        TraceIfEnabled<U, secondNeedsTracing>::trace(visitor, &pair->second);
    }
};

// WeakMember is similar to Member in that it is used to point to other oilpan
// heap allocated objects.
// However instead of creating a strong pointer to the object, the WeakMember creates
// a weak pointer, which does not keep the pointee alive. Hence if all pointers to
// to a heap allocated object are weak the object will be garbage collected. At the
// time of GC the weak pointers will automatically be set to null.
template<typename T>
class WeakMember : public Member<T> {
    WTF_DISALLOW_CONSTRUCTION_FROM_ZERO(WeakMember);
    WTF_DISALLOW_ZERO_ASSIGNMENT(WeakMember);
public:
    WeakMember() : Member<T>() { }

    WeakMember(std::nullptr_t) : Member<T>(nullptr) { }

    WeakMember(T* raw) : Member<T>(raw) { }

    WeakMember(WTF::HashTableDeletedValueType x) : Member<T>(x) { }

    template<typename U>
    WeakMember(const Persistent<U>& other) : Member<T>(other) { }

    template<typename U>
    WeakMember(const Member<U>& other) : Member<T>(other) { }

    template<typename U>
    WeakMember& operator=(const Persistent<U>& other)
    {
        this->m_raw = other;
        return *this;
    }

    template<typename U>
    WeakMember& operator=(const Member<U>& other)
    {
        this->m_raw = other;
        return *this;
    }

    template<typename U>
    WeakMember& operator=(U* other)
    {
        this->m_raw = other;
        return *this;
    }

    template<typename U>
    WeakMember& operator=(const RawPtr<U>& other)
    {
        this->m_raw = other;
        return *this;
    }

    WeakMember& operator=(std::nullptr_t)
    {
        this->m_raw = 0;
        return *this;
    }

private:
    T** cell() const { return const_cast<T**>(&this->m_raw); }

    friend class Visitor;
};

// Comparison operators between (Weak)Members and Persistents
template<typename T, typename U> inline bool operator==(const Member<T>& a, const Member<U>& b) { return a.get() == b.get(); }
template<typename T, typename U> inline bool operator!=(const Member<T>& a, const Member<U>& b) { return a.get() != b.get(); }
template<typename T, typename U> inline bool operator==(const Member<T>& a, const Persistent<U>& b) { return a.get() == b.get(); }
template<typename T, typename U> inline bool operator!=(const Member<T>& a, const Persistent<U>& b) { return a.get() != b.get(); }
template<typename T, typename U> inline bool operator==(const Persistent<T>& a, const Member<U>& b) { return a.get() == b.get(); }
template<typename T, typename U> inline bool operator!=(const Persistent<T>& a, const Member<U>& b) { return a.get() != b.get(); }
template<typename T, typename U> inline bool operator==(const Persistent<T>& a, const Persistent<U>& b) { return a.get() == b.get(); }
template<typename T, typename U> inline bool operator!=(const Persistent<T>& a, const Persistent<U>& b) { return a.get() != b.get(); }

// CPP-defined type names for the transition period where we want to
// support both reference counting and garbage collection based on a
// compile-time flag.
//
// C++11 template aliases were initially used (with clang only, not
// with GCC nor MSVC.) However, supporting both CPP defines and
// template aliases is problematic from outside a WebCore namespace
// when Oilpan is disabled: e.g.,
// blink::RefCountedWillBeGarbageCollected as a template alias would
// uniquely resolve from within any namespace, but if it is backed by
// a CPP #define, it would expand to blink::RefCounted, and not the
// required WTF::RefCounted.
//
// Having the CPP expansion instead be fully namespace qualified, and the
// transition type be unqualified, would dually not work for template
// aliases. So, slightly unfortunately, fall back/down to the lowest
// commmon denominator of using CPP macros only.
#if ENABLE(OILPAN)
#define PassRefPtrWillBeRawPtr WTF::RawPtr
#define RefCountedWillBeGarbageCollected blink::GarbageCollected
#define RefCountedWillBeGarbageCollectedFinalized blink::GarbageCollectedFinalized
#define RefCountedWillBeRefCountedGarbageCollected blink::RefCountedGarbageCollected
#define RefCountedGarbageCollectedWillBeGarbageCollectedFinalized blink::GarbageCollectedFinalized
#define ThreadSafeRefCountedWillBeGarbageCollected blink::GarbageCollected
#define ThreadSafeRefCountedWillBeGarbageCollectedFinalized blink::GarbageCollectedFinalized
#define ThreadSafeRefCountedWillBeThreadSafeRefCountedGarbageCollected blink::ThreadSafeRefCountedGarbageCollected
#define PersistentWillBeMember blink::Member
#define RefPtrWillBePersistent blink::Persistent
#define RefPtrWillBeRawPtr WTF::RawPtr
#define RefPtrWillBeMember blink::Member
#define RefPtrWillBeWeakMember blink::WeakMember
#define RefPtrWillBeCrossThreadPersistent blink::CrossThreadPersistent
#define RawPtrWillBeMember blink::Member
#define RawPtrWillBePersistent blink::Persistent
#define RawPtrWillBeWeakMember blink::WeakMember
#define OwnPtrWillBeMember blink::Member
#define OwnPtrWillBePersistent blink::Persistent
#define OwnPtrWillBeRawPtr WTF::RawPtr
#define PassOwnPtrWillBeRawPtr WTF::RawPtr
#define WeakPtrWillBeMember blink::Member
#define WeakPtrWillBeRawPtr WTF::RawPtr
#define WeakPtrWillBeMember blink::Member
#define WeakPtrWillBeWeakMember blink::WeakMember
#define NoBaseWillBeGarbageCollected blink::GarbageCollected
#define NoBaseWillBeGarbageCollectedFinalized blink::GarbageCollectedFinalized
#define NoBaseWillBeRefCountedGarbageCollected blink::RefCountedGarbageCollected
#define WillBeHeapHashMap blink::HeapHashMap
#define WillBePersistentHeapHashMap blink::PersistentHeapHashMap
#define WillBeHeapHashSet blink::HeapHashSet
#define WillBePersistentHeapHashSet blink::PersistentHeapHashSet
#define WillBeHeapLinkedHashSet blink::HeapLinkedHashSet
#define WillBePersistentHeapLinkedHashSet blink::PersistentHeapLinkedHashSet
#define WillBeHeapListHashSet blink::HeapListHashSet
#define WillBePersistentHeapListHashSet blink::PersistentHeapListHashSet
#define WillBeHeapVector blink::HeapVector
#define WillBePersistentHeapVector blink::PersistentHeapVector
#define WillBeHeapDeque blink::HeapDeque
#define WillBePersistentHeapDeque blink::PersistentHeapDeque
#define WillBeHeapHashCountedSet blink::HeapHashCountedSet
#define WillBePersistentHeapHashCountedSet blink::PersistentHeapHashCountedSet
#define WillBeGarbageCollectedMixin blink::GarbageCollectedMixin
#define WillBeHeapSupplement blink::HeapSupplement
#define WillBeHeapSupplementable blink::HeapSupplementable
#define WillBePersistentHeapSupplementable blink::PersistentHeapSupplementable
#define WillBeHeapTerminatedArray blink::HeapTerminatedArray
#define WillBeHeapTerminatedArrayBuilder blink::HeapTerminatedArrayBuilder
#define WillBeHeapLinkedStack blink::HeapLinkedStack
#define PersistentHeapHashSetWillBeHeapHashSet blink::HeapHashSet
#define PersistentHeapDequeWillBeHeapDeque blink::HeapDeque
#define PersistentHeapVectorWillBeHeapVector blink::HeapVector

template<typename T> PassRefPtrWillBeRawPtr<T> adoptRefWillBeNoop(T* ptr)
{
    static const bool notRefCountedGarbageCollected = !WTF::IsSubclassOfTemplate<typename WTF::RemoveConst<T>::Type, RefCountedGarbageCollected>::value;
    static const bool notRefCounted = !WTF::IsSubclassOfTemplate<typename WTF::RemoveConst<T>::Type, RefCounted>::value;
    COMPILE_ASSERT(notRefCountedGarbageCollected, useAdoptRefCountedWillBeRefCountedGarbageCollected);
    COMPILE_ASSERT(notRefCounted, youMustAdopt);
    return PassRefPtrWillBeRawPtr<T>(ptr);
}

template<typename T> PassRefPtrWillBeRawPtr<T> adoptRefWillBeRefCountedGarbageCollected(T* ptr)
{
    static const bool isRefCountedGarbageCollected = WTF::IsSubclassOfTemplate<typename WTF::RemoveConst<T>::Type, RefCountedGarbageCollected>::value;
    COMPILE_ASSERT(isRefCountedGarbageCollected, useAdoptRefWillBeNoop);
    return PassRefPtrWillBeRawPtr<T>(adoptRefCountedGarbageCollected(ptr));
}

template<typename T> PassRefPtrWillBeRawPtr<T> adoptRefWillBeThreadSafeRefCountedGarbageCollected(T* ptr)
{
    static const bool isThreadSafeRefCountedGarbageCollected = WTF::IsSubclassOfTemplate<typename WTF::RemoveConst<T>::Type, ThreadSafeRefCountedGarbageCollected>::value;
    COMPILE_ASSERT(isThreadSafeRefCountedGarbageCollected, useAdoptRefWillBeNoop);
    return PassRefPtrWillBeRawPtr<T>(adoptRefCountedGarbageCollected(ptr));
}

template<typename T> PassOwnPtrWillBeRawPtr<T> adoptPtrWillBeNoop(T* ptr)
{
    static const bool notRefCountedGarbageCollected = !WTF::IsSubclassOfTemplate<typename WTF::RemoveConst<T>::Type, RefCountedGarbageCollected>::value;
    static const bool notRefCounted = !WTF::IsSubclassOfTemplate<typename WTF::RemoveConst<T>::Type, RefCounted>::value;
    COMPILE_ASSERT(notRefCountedGarbageCollected, useAdoptRefCountedWillBeRefCountedGarbageCollected);
    COMPILE_ASSERT(notRefCounted, youMustAdopt);
    return PassOwnPtrWillBeRawPtr<T>(ptr);
}

template<typename T> T* adoptPtrWillBeRefCountedGarbageCollected(T* ptr)
{
    static const bool isRefCountedGarbageCollected = WTF::IsSubclassOfTemplate<typename WTF::RemoveConst<T>::Type, RefCountedGarbageCollected>::value;
    COMPILE_ASSERT(isRefCountedGarbageCollected, useAdoptRefWillBeNoop);
    return adoptRefCountedGarbageCollected(ptr);
}

template<typename T> T* adoptRefCountedGarbageCollectedWillBeNoop(T* ptr)
{
    static const bool notRefCountedGarbageCollected = !WTF::IsSubclassOfTemplate<typename WTF::RemoveConst<T>::Type, RefCountedGarbageCollected>::value;
    static const bool notRefCounted = !WTF::IsSubclassOfTemplate<typename WTF::RemoveConst<T>::Type, RefCounted>::value;
    COMPILE_ASSERT(notRefCountedGarbageCollected, useAdoptRefCountedWillBeRefCountedGarbageCollected);
    COMPILE_ASSERT(notRefCounted, youMustAdopt);
    return ptr;
}

#define WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED // do nothing when oilpan is enabled.
#define DECLARE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(type) // do nothing
#define DECLARE_EMPTY_VIRTUAL_DESTRUCTOR_WILL_BE_REMOVED(type) // do nothing
#define DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(type) // do nothing

#define DEFINE_STATIC_REF_WILL_BE_PERSISTENT(type, name, arguments) \
    static type* name = (new Persistent<type>(arguments))->get();

#else // !ENABLE(OILPAN)

template<typename T>
class DummyBase {
public:
    DummyBase() { }
    ~DummyBase() { }
};

#define PassRefPtrWillBeRawPtr WTF::PassRefPtr
#define RefCountedWillBeGarbageCollected WTF::RefCounted
#define RefCountedWillBeGarbageCollectedFinalized WTF::RefCounted
#define RefCountedWillBeRefCountedGarbageCollected WTF::RefCounted
#define RefCountedGarbageCollectedWillBeGarbageCollectedFinalized blink::RefCountedGarbageCollected
#define ThreadSafeRefCountedWillBeGarbageCollected WTF::ThreadSafeRefCounted
#define ThreadSafeRefCountedWillBeGarbageCollectedFinalized WTF::ThreadSafeRefCounted
#define ThreadSafeRefCountedWillBeThreadSafeRefCountedGarbageCollected WTF::ThreadSafeRefCounted
#define PersistentWillBeMember blink::Persistent
#define RefPtrWillBePersistent WTF::RefPtr
#define RefPtrWillBeRawPtr WTF::RefPtr
#define RefPtrWillBeMember WTF::RefPtr
#define RefPtrWillBeWeakMember WTF::RefPtr
#define RefPtrWillBeCrossThreadPersistent WTF::RefPtr
#define RawPtrWillBeMember WTF::RawPtr
#define RawPtrWillBePersistent WTF::RawPtr
#define RawPtrWillBeWeakMember WTF::RawPtr
#define OwnPtrWillBeMember WTF::OwnPtr
#define OwnPtrWillBePersistent WTF::OwnPtr
#define OwnPtrWillBeRawPtr WTF::OwnPtr
#define PassOwnPtrWillBeRawPtr WTF::PassOwnPtr
#define WeakPtrWillBeMember WTF::WeakPtr
#define WeakPtrWillBeRawPtr WTF::WeakPtr
#define WeakPtrWillBeMember WTF::WeakPtr
#define WeakPtrWillBeWeakMember WTF::WeakPtr
#define NoBaseWillBeGarbageCollected blink::DummyBase
#define NoBaseWillBeGarbageCollectedFinalized blink::DummyBase
#define NoBaseWillBeRefCountedGarbageCollected blink::DummyBase
#define WillBeHeapHashMap WTF::HashMap
#define WillBePersistentHeapHashMap WTF::HashMap
#define WillBeHeapHashSet WTF::HashSet
#define WillBePersistentHeapHashSet WTF::HashSet
#define WillBeHeapLinkedHashSet WTF::LinkedHashSet
#define WillBePersistentLinkedHeapHashSet WTF::LinkedHashSet
#define WillBeHeapListHashSet WTF::ListHashSet
#define WillBePersistentListHeapHashSet WTF::ListHashSet
#define WillBeHeapVector WTF::Vector
#define WillBePersistentHeapVector WTF::Vector
#define WillBeHeapDeque WTF::Deque
#define WillBePersistentHeapDeque WTF::Deque
#define WillBeHeapHashCountedSet WTF::HashCountedSet
#define WillBePersistentHeapHashCountedSet WTF::HashCountedSet
#define WillBeGarbageCollectedMixin blink::DummyBase<void>
#define WillBeHeapSupplement blink::Supplement
#define WillBeHeapSupplementable blink::Supplementable
#define WillBePersistentHeapSupplementable blink::Supplementable
#define WillBeHeapTerminatedArray WTF::TerminatedArray
#define WillBeHeapTerminatedArrayBuilder WTF::TerminatedArrayBuilder
#define WillBeHeapLinkedStack WTF::LinkedStack
#define PersistentHeapHashSetWillBeHeapHashSet blink::PersistentHeapHashSet
#define PersistentHeapDequeWillBeHeapDeque blink::PersistentHeapDeque
#define PersistentHeapVectorWillBeHeapVector blink::PersistentHeapVector

template<typename T> PassRefPtrWillBeRawPtr<T> adoptRefWillBeNoop(T* ptr) { return adoptRef(ptr); }
template<typename T> PassRefPtrWillBeRawPtr<T> adoptRefWillBeRefCountedGarbageCollected(T* ptr) { return adoptRef(ptr); }
template<typename T> PassRefPtrWillBeRawPtr<T> adoptRefWillBeThreadSafeRefCountedGarbageCollected(T* ptr) { return adoptRef(ptr); }
template<typename T> PassOwnPtrWillBeRawPtr<T> adoptPtrWillBeNoop(T* ptr) { return adoptPtr(ptr); }
template<typename T> PassOwnPtrWillBeRawPtr<T> adoptPtrWillBeRefCountedGarbageCollected(T* ptr) { return adoptPtr(ptr); }

template<typename T> T* adoptRefCountedGarbageCollectedWillBeNoop(T* ptr)
{
    static const bool isRefCountedGarbageCollected = WTF::IsSubclassOfTemplate<typename WTF::RemoveConst<T>::Type, RefCountedGarbageCollected>::value;
    COMPILE_ASSERT(isRefCountedGarbageCollected, useAdoptRefWillBeNoop);
    return adoptRefCountedGarbageCollected(ptr);
}


#define WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED WTF_MAKE_FAST_ALLOCATED
#define DECLARE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(type) \
    public:                                            \
        ~type();                                       \
    private:
#define DECLARE_EMPTY_VIRTUAL_DESTRUCTOR_WILL_BE_REMOVED(type) \
    public:                                                    \
        virtual ~type();                                       \
    private:

#define DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(type) \
    type::~type() { }

#define DEFINE_STATIC_REF_WILL_BE_PERSISTENT(type, name, arguments) \
    DEFINE_STATIC_REF(type, name, arguments)

#endif // ENABLE(OILPAN)

} // namespace blink

namespace WTF {

template <typename T> struct VectorTraits<blink::Member<T> > : VectorTraitsBase<blink::Member<T> > {
    static const bool needsDestruction = false;
    static const bool canInitializeWithMemset = true;
    static const bool canMoveWithMemcpy = true;
};

template <typename T> struct VectorTraits<blink::WeakMember<T> > : VectorTraitsBase<blink::WeakMember<T> > {
    static const bool needsDestruction = false;
    static const bool canInitializeWithMemset = true;
    static const bool canMoveWithMemcpy = true;
};

template <typename T> struct VectorTraits<blink::HeapVector<T, 0> > : VectorTraitsBase<blink::HeapVector<T, 0> > {
    static const bool needsDestruction = false;
    static const bool canInitializeWithMemset = true;
    static const bool canMoveWithMemcpy = true;
};

template <typename T> struct VectorTraits<blink::HeapDeque<T, 0> > : VectorTraitsBase<blink::HeapDeque<T, 0> > {
    static const bool needsDestruction = false;
    static const bool canInitializeWithMemset = true;
    static const bool canMoveWithMemcpy = true;
};

template <typename T, size_t inlineCapacity> struct VectorTraits<blink::HeapVector<T, inlineCapacity> > : VectorTraitsBase<blink::HeapVector<T, inlineCapacity> > {
    static const bool needsDestruction = VectorTraits<T>::needsDestruction;
    static const bool canInitializeWithMemset = VectorTraits<T>::canInitializeWithMemset;
    static const bool canMoveWithMemcpy = VectorTraits<T>::canMoveWithMemcpy;
};

template <typename T, size_t inlineCapacity> struct VectorTraits<blink::HeapDeque<T, inlineCapacity> > : VectorTraitsBase<blink::HeapDeque<T, inlineCapacity> > {
    static const bool needsDestruction = VectorTraits<T>::needsDestruction;
    static const bool canInitializeWithMemset = VectorTraits<T>::canInitializeWithMemset;
    static const bool canMoveWithMemcpy = VectorTraits<T>::canMoveWithMemcpy;
};

template<typename T> struct HashTraits<blink::Member<T> > : SimpleClassHashTraits<blink::Member<T> > {
    static const bool needsDestruction = false;
    // FIXME: The distinction between PeekInType and PassInType is there for
    // the sake of the reference counting handles. When they are gone the two
    // types can be merged into PassInType.
    // FIXME: Implement proper const'ness for iterator types. Requires support
    // in the marking Visitor.
    typedef RawPtr<T> PeekInType;
    typedef RawPtr<T> PassInType;
    typedef blink::Member<T>* IteratorGetType;
    typedef const blink::Member<T>* IteratorConstGetType;
    typedef blink::Member<T>& IteratorReferenceType;
    typedef T* const IteratorConstReferenceType;
    static IteratorReferenceType getToReferenceConversion(IteratorGetType x) { return *x; }
    static IteratorConstReferenceType getToReferenceConstConversion(IteratorConstGetType x) { return x->get(); }
    // FIXME: Similarly, there is no need for a distinction between PeekOutType
    // and PassOutType without reference counting.
    typedef T* PeekOutType;
    typedef T* PassOutType;

    template<typename U>
    static void store(const U& value, blink::Member<T>& storage) { storage = value; }

    static PeekOutType peek(const blink::Member<T>& value) { return value; }
    static PassOutType passOut(const blink::Member<T>& value) { return value; }
};

template<typename T> struct HashTraits<blink::WeakMember<T> > : SimpleClassHashTraits<blink::WeakMember<T> > {
    static const bool needsDestruction = false;
    // FIXME: The distinction between PeekInType and PassInType is there for
    // the sake of the reference counting handles. When they are gone the two
    // types can be merged into PassInType.
    // FIXME: Implement proper const'ness for iterator types. Requires support
    // in the marking Visitor.
    typedef RawPtr<T> PeekInType;
    typedef RawPtr<T> PassInType;
    typedef blink::WeakMember<T>* IteratorGetType;
    typedef const blink::WeakMember<T>* IteratorConstGetType;
    typedef blink::WeakMember<T>& IteratorReferenceType;
    typedef T* const IteratorConstReferenceType;
    static IteratorReferenceType getToReferenceConversion(IteratorGetType x) { return *x; }
    static IteratorConstReferenceType getToReferenceConstConversion(IteratorConstGetType x) { return x->get(); }
    // FIXME: Similarly, there is no need for a distinction between PeekOutType
    // and PassOutType without reference counting.
    typedef T* PeekOutType;
    typedef T* PassOutType;

    template<typename U>
    static void store(const U& value, blink::WeakMember<T>& storage) { storage = value; }

    static PeekOutType peek(const blink::WeakMember<T>& value) { return value; }
    static PassOutType passOut(const blink::WeakMember<T>& value) { return value; }
    static bool traceInCollection(blink::Visitor* visitor, blink::WeakMember<T>& weakMember, ShouldWeakPointersBeMarkedStrongly strongify)
    {
        if (strongify == WeakPointersActStrong) {
            visitor->trace(reinterpret_cast<blink::Member<T>&>(weakMember)); // Strongified visit.
            return false;
        }
        return !visitor->isAlive(weakMember);
    }
};

template<typename T> struct PtrHash<blink::Member<T> > : PtrHash<T*> {
    template<typename U>
    static unsigned hash(const U& key) { return PtrHash<T*>::hash(key); }
    static bool equal(T* a, const blink::Member<T>& b) { return a == b; }
    static bool equal(const blink::Member<T>& a, T* b) { return a == b; }
    template<typename U, typename V>
    static bool equal(const U& a, const V& b) { return a == b; }
};

template<typename T> struct PtrHash<blink::WeakMember<T> > : PtrHash<blink::Member<T> > {
};

template<typename P> struct PtrHash<blink::Persistent<P> > : PtrHash<P*> {
    using PtrHash<P*>::hash;
    static unsigned hash(const RefPtr<P>& key) { return hash(key.get()); }
    using PtrHash<P*>::equal;
    static bool equal(const RefPtr<P>& a, const RefPtr<P>& b) { return a == b; }
    static bool equal(P* a, const RefPtr<P>& b) { return a == b; }
    static bool equal(const RefPtr<P>& a, P* b) { return a == b; }
};

// PtrHash is the default hash for hash tables with members.
template<typename T> struct DefaultHash<blink::Member<T> > {
    typedef PtrHash<blink::Member<T> > Hash;
};

template<typename T> struct DefaultHash<blink::WeakMember<T> > {
    typedef PtrHash<blink::WeakMember<T> > Hash;
};

template<typename T> struct DefaultHash<blink::Persistent<T> > {
    typedef PtrHash<blink::Persistent<T> > Hash;
};

template<typename T>
struct NeedsTracing<blink::Member<T> > {
    static const bool value = true;
};

template<typename T>
struct IsWeak<blink::WeakMember<T> > {
    static const bool value = true;
};

template<typename T> inline T* getPtr(const blink::Member<T>& p)
{
    return p.get();
}

template<typename T> inline T* getPtr(const blink::Persistent<T>& p)
{
    return p.get();
}

template<typename T, size_t inlineCapacity>
struct NeedsTracing<ListHashSetNode<T, blink::HeapListHashSetAllocator<T, inlineCapacity> > *> {
    // All heap allocated node pointers need visiting to keep the nodes alive,
    // regardless of whether they contain pointers to other heap allocated
    // objects.
    static const bool value = true;
};

// For wtf/Functional.h
template<typename T, bool isGarbageCollected> struct PointerParamStorageTraits;

template<typename T>
struct PointerParamStorageTraits<T*, false> {
    typedef T* StorageType;

    static StorageType wrap(T* value) { return value; }
    static T* unwrap(const StorageType& value) { return value; }
};

template<typename T>
struct PointerParamStorageTraits<T*, true> {
    typedef blink::CrossThreadPersistent<T> StorageType;

    static StorageType wrap(T* value) { return value; }
    static T* unwrap(const StorageType& value) { return value.get(); }
};

template<typename T>
struct ParamStorageTraits<T*> : public PointerParamStorageTraits<T*, blink::IsGarbageCollectedType<T>::value> {
};

template<typename T>
struct ParamStorageTraits<RawPtr<T> > : public PointerParamStorageTraits<T*, blink::IsGarbageCollectedType<T>::value> {
};

} // namespace WTF

#endif
