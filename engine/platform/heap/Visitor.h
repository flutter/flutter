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

#ifndef Visitor_h
#define Visitor_h

#include "platform/PlatformExport.h"
#include "platform/heap/ThreadState.h"
#include "wtf/Assertions.h"
#include "wtf/Deque.h"
#include "wtf/Forward.h"
#include "wtf/HashMap.h"
#include "wtf/HashTraits.h"
#include "wtf/InstanceCounter.h"
#include "wtf/OwnPtr.h"
#include "wtf/RefPtr.h"
#include "wtf/TypeTraits.h"
#include "wtf/WeakPtr.h"
#if ENABLE(GC_PROFILING)
#include "wtf/text/WTFString.h"
#endif

#if ENABLE(ASSERT)
#define DEBUG_ONLY(x) x
#else
#define DEBUG_ONLY(x)
#endif

namespace blink {

class FinalizedHeapObjectHeader;
template<typename T> class GarbageCollectedFinalized;
class HeapObjectHeader;
template<typename T> class Member;
template<typename T> class WeakMember;
class Visitor;

template<bool needsTracing, WTF::WeakHandlingFlag weakHandlingFlag, WTF::ShouldWeakPointersBeMarkedStrongly strongify, typename T, typename Traits> struct CollectionBackingTraceTrait;

// The TraceMethodDelegate is used to convert a trace method for type T to a TraceCallback.
// This allows us to pass a type's trace method as a parameter to the PersistentNode
// constructor. The PersistentNode constructor needs the specific trace method due an issue
// with the Windows compiler which instantiates even unused variables. This causes problems
// in header files where we have only forward declarations of classes.
template<typename T, void (T::*method)(Visitor*)>
struct TraceMethodDelegate {
    static void trampoline(Visitor* visitor, void* self) { (reinterpret_cast<T*>(self)->*method)(visitor); }
};

// GCInfo contains meta-data associated with objects allocated in the
// Blink heap. This meta-data consists of a function pointer used to
// trace the pointers in the object during garbage collection, an
// indication of whether or not the object needs a finalization
// callback, and a function pointer used to finalize the object when
// the garbage collector determines that the object is no longer
// reachable. There is a GCInfo struct for each class that directly
// inherits from GarbageCollected or GarbageCollectedFinalized.
struct GCInfo {
    bool hasFinalizer() const { return m_nonTrivialFinalizer; }
    bool hasVTable() const { return m_hasVTable; }
    TraceCallback m_trace;
    FinalizationCallback m_finalize;
    bool m_nonTrivialFinalizer;
    bool m_hasVTable;
#if ENABLE(GC_PROFILING)
    // |m_className| is held as a reference to prevent dtor being called at exit.
    const String& m_className;
#endif
};

// The FinalizerTraitImpl specifies how to finalize objects. Object
// that inherit from GarbageCollectedFinalized are finalized by
// calling their 'finalize' method which by default will call the
// destructor on the object.
template<typename T, bool isGarbageCollectedFinalized>
struct FinalizerTraitImpl;

template<typename T>
struct FinalizerTraitImpl<T, true> {
    static void finalize(void* obj) { static_cast<T*>(obj)->finalizeGarbageCollectedObject(); };
};

template<typename T>
struct FinalizerTraitImpl<T, false> {
    static void finalize(void* obj) { };
};

// The FinalizerTrait is used to determine if a type requires
// finalization and what finalization means.
//
// By default classes that inherit from GarbageCollectedFinalized need
// finalization and finalization means calling the 'finalize' method
// of the object. The FinalizerTrait can be specialized if the default
// behavior is not desired.
template<typename T>
struct FinalizerTrait {
    static const bool nonTrivialFinalizer = WTF::IsSubclassOfTemplate<typename WTF::RemoveConst<T>::Type, GarbageCollectedFinalized>::value;
    static void finalize(void* obj) { FinalizerTraitImpl<T, nonTrivialFinalizer>::finalize(obj); }
};

// Trait to get the GCInfo structure for types that have their
// instances allocated in the Blink garbage-collected heap.
template<typename T> struct GCInfoTrait;

template<typename T> class GarbageCollected;
class GarbageCollectedMixin;
template<typename T, bool = WTF::IsSubclassOfTemplate<typename WTF::RemoveConst<T>::Type, GarbageCollected>::value> class NeedsAdjustAndMark;

template<typename T>
class NeedsAdjustAndMark<T, true> {
public:
    static const bool value = false;
};

template <typename T> const bool NeedsAdjustAndMark<T, true>::value;

template<typename T>
class NeedsAdjustAndMark<T, false> {
public:
    static const bool value = WTF::IsSubclass<typename WTF::RemoveConst<T>::Type, GarbageCollectedMixin>::value;
};

template <typename T> const bool NeedsAdjustAndMark<T, false>::value;

template<typename T, bool = NeedsAdjustAndMark<T>::value> class DefaultTraceTrait;

// The TraceTrait is used to specify how to mark an object pointer and
// how to trace all of the pointers in the object.
//
// By default, the 'trace' method implemented on an object itself is
// used to trace the pointers to other heap objects inside the object.
//
// However, the TraceTrait can be specialized to use a different
// implementation. A common case where a TraceTrait specialization is
// needed is when multiple inheritance leads to pointers that are not
// to the start of the object in the Blink garbage-collected heap. In
// that case the pointer has to be adjusted before marking.
template<typename T>
class TraceTrait {
public:
    // Default implementation of TraceTrait<T>::trace just statically
    // dispatches to the trace method of the class T.
    static void trace(Visitor* visitor, void* self)
    {
        static_cast<T*>(self)->trace(visitor);
    }

    static void mark(Visitor* visitor, const T* t)
    {
        DefaultTraceTrait<T>::mark(visitor, t);
    }

#if ENABLE(ASSERT)
    static void checkGCInfo(Visitor* visitor, const T* t)
    {
        DefaultTraceTrait<T>::checkGCInfo(visitor, t);
    }
#endif
};

template<typename T> class TraceTrait<const T> : public TraceTrait<T> { };

template<typename Collection>
struct OffHeapCollectionTraceTrait;

template<typename T>
struct ObjectAliveTrait {
    static bool isAlive(Visitor*, T*);
};

// Visitor is used to traverse the Blink object graph. Used for the
// marking phase of the mark-sweep garbage collector.
//
// Pointers are marked and pushed on the marking stack by calling the
// |mark| method with the pointer as an argument.
//
// Pointers within objects are traced by calling the |trace| methods
// with the object as an argument. Tracing objects will mark all of the
// contained pointers and push them on the marking stack.
class PLATFORM_EXPORT Visitor {
public:
    virtual ~Visitor() { }

    template<typename T>
    static void verifyGarbageCollectedIfMember(T*)
    {
    }

    template<typename T>
    static void verifyGarbageCollectedIfMember(Member<T>* t)
    {
        t->verifyTypeIsGarbageCollected();
    }

    // One-argument templated mark method. This uses the static type of
    // the argument to get the TraceTrait. By default, the mark method
    // of the TraceTrait just calls the virtual two-argument mark method on this
    // visitor, where the second argument is the static trace method of the trait.
    template<typename T>
    void mark(T* t)
    {
        if (!t)
            return;
#if ENABLE(ASSERT)
        TraceTrait<T>::checkGCInfo(this, t);
#endif
        TraceTrait<T>::mark(this, t);

        reinterpret_cast<const Member<T>*>(0)->verifyTypeIsGarbageCollected();
    }

    // Member version of the one-argument templated trace method.
    template<typename T>
    void trace(const Member<T>& t)
    {
        mark(t.get());
    }

    // Fallback method used only when we need to trace raw pointers of T.
    // This is the case when a member is a union where we do not support members.
    template<typename T>
    void trace(const T* t)
    {
        mark(const_cast<T*>(t));
    }

    template<typename T>
    void trace(T* t)
    {
        mark(t);
    }

    // WeakMember version of the templated trace method. It doesn't keep
    // the traced thing alive, but will write null to the WeakMember later
    // if the pointed-to object is dead. It's lying for this to be const,
    // but the overloading resolver prioritizes constness too high when
    // picking the correct overload, so all these trace methods have to have
    // the same constness on their argument to allow the type to decide.
    template<typename T>
    void trace(const WeakMember<T>& t)
    {
        // Check that we actually know the definition of T when tracing.
        COMPILE_ASSERT(sizeof(T), WeNeedToKnowTheDefinitionOfTheTypeWeAreTracing);
        registerWeakCell(const_cast<WeakMember<T>&>(t).cell());
        reinterpret_cast<const Member<T>*>(0)->verifyTypeIsGarbageCollected();
    }

    template<typename T>
    void traceInCollection(T& t, WTF::ShouldWeakPointersBeMarkedStrongly strongify)
    {
        HashTraits<T>::traceInCollection(this, t, strongify);
    }

    // Fallback trace method for part objects to allow individual trace methods
    // to trace through a part object with visitor->trace(m_partObject). This
    // takes a const argument, because otherwise it will match too eagerly: a
    // non-const argument would match a non-const Vector<T>& argument better
    // than the specialization that takes const Vector<T>&. For a similar reason,
    // the other specializations take a const argument even though they are
    // usually used with non-const arguments, otherwise this function would match
    // too well.
    template<typename T>
    void trace(const T& t)
    {
        if (WTF::IsPolymorphic<T>::value) {
            intptr_t vtable = *reinterpret_cast<const intptr_t*>(&t);
            if (!vtable)
                return;
        }
        const_cast<T&>(t).trace(this);
    }

    // The following trace methods are for off-heap collections.
    template<typename T, size_t inlineCapacity>
    void trace(const Vector<T, inlineCapacity>& vector)
    {
        OffHeapCollectionTraceTrait<Vector<T, inlineCapacity, WTF::DefaultAllocator> >::trace(this, vector);
    }

    template<typename T, size_t N>
    void trace(const Deque<T, N>& deque)
    {
        OffHeapCollectionTraceTrait<Deque<T, N> >::trace(this, deque);
    }

#if !ENABLE(OILPAN)
    // These trace methods are needed to allow compiling and calling trace on
    // transition types. We need to support calls in the non-oilpan build
    // because a fully transitioned type (which will have its trace method
    // called) might trace a field that is in transition. Once transition types
    // are removed these can be removed.
    template<typename T> void trace(const OwnPtr<T>&) { }
    template<typename T> void trace(const RefPtr<T>&) { }
    template<typename T> void trace(const RawPtr<T>&) { }
    template<typename T> void trace(const WeakPtr<T>&) { }
#endif

    // This method marks an object and adds it to the set of objects
    // that should have their trace method called. Since not all
    // objects have vtables we have to have the callback as an
    // explicit argument, but we can use the templated one-argument
    // mark method above to automatically provide the callback
    // function.
    virtual void mark(const void*, TraceCallback) = 0;
    virtual void markNoTracing(const void* pointer) { mark(pointer, reinterpret_cast<TraceCallback>(0)); }
    virtual void markNoTracing(HeapObjectHeader* header) { mark(header, reinterpret_cast<TraceCallback>(0)); }
    virtual void markNoTracing(FinalizedHeapObjectHeader* header) { mark(header, reinterpret_cast<TraceCallback>(0)); }

    // Used to mark objects during conservative scanning.
    virtual void mark(HeapObjectHeader*, TraceCallback) = 0;
    virtual void mark(FinalizedHeapObjectHeader*, TraceCallback) = 0;

    // Used to delay the marking of objects until the usual marking
    // including emphemeron iteration is done. This is used to delay
    // the marking of collection backing stores until we know if they
    // are reachable from locations other than the collection front
    // object. If collection backings are reachable from other
    // locations we strongify them to avoid issues with iterators and
    // weak processing.
    virtual void registerDelayedMarkNoTracing(const void*) = 0;

    // If the object calls this during the regular trace callback, then the
    // WeakPointerCallback argument may be called later, when the strong roots
    // have all been found. The WeakPointerCallback will normally use isAlive
    // to find out whether some pointers are pointing to dying objects. When
    // the WeakPointerCallback is done the object must have purged all pointers
    // to objects where isAlive returned false. In the weak callback it is not
    // allowed to touch other objects (except using isAlive) or to allocate on
    // the GC heap. Note that even removing things from HeapHashSet or
    // HeapHashMap can cause an allocation if the backing store resizes, but
    // these collections know to remove WeakMember elements safely.
    //
    // The weak pointer callbacks are run on the thread that owns the
    // object and other threads are not stopped during the
    // callbacks. Since isAlive is used in the callback to determine
    // if objects pointed to are alive it is crucial that the object
    // pointed to belong to the same thread as the object receiving
    // the weak callback. Since other threads have been resumed the
    // mark bits are not valid for objects from other threads.
    virtual void registerWeakMembers(const void* object, WeakPointerCallback callback) { registerWeakMembers(object, object, callback); }
    virtual void registerWeakMembers(const void*, const void*, WeakPointerCallback) = 0;

    template<typename T, void (T::*method)(Visitor*)>
    void registerWeakMembers(const T* obj)
    {
        registerWeakMembers(obj, &TraceMethodDelegate<T, method>::trampoline);
    }

    // For simple cases where you just want to zero out a cell when the thing
    // it is pointing at is garbage, you can use this. This will register a
    // callback for each cell that needs to be zeroed, so if you have a lot of
    // weak cells in your object you should still consider using
    // registerWeakMembers above.
    //
    // In contrast to registerWeakMembers, the weak cell callbacks are
    // run on the thread performing garbage collection. Therefore, all
    // threads are stopped during weak cell callbacks.
    template<typename T>
    void registerWeakCell(T** cell)
    {
        registerWeakCell(reinterpret_cast<void**>(cell), &handleWeakCell<T>);
    }

    virtual void registerWeakTable(const void*, EphemeronCallback, EphemeronCallback) = 0;
#if ENABLE(ASSERT)
    virtual bool weakTableRegistered(const void*) = 0;
#endif

    virtual bool isMarked(const void*) = 0;

    template<typename T> inline bool isAlive(T* obj)
    {
        // Check that we actually know the definition of T when tracing.
        COMPILE_ASSERT(sizeof(T), WeNeedToKnowTheDefinitionOfTheTypeWeAreTracing);
        // The strongification of collections relies on the fact that once a
        // collection has been strongified, there is no way that it can contain
        // non-live entries, so no entries will be removed. Since you can't set
        // the mark bit on a null pointer, that means that null pointers are
        // always 'alive'.
        if (!obj)
            return true;
        return ObjectAliveTrait<T>::isAlive(this, obj);
    }
    template<typename T> inline bool isAlive(const Member<T>& member)
    {
        return isAlive(member.get());
    }
    template<typename T> inline bool isAlive(RawPtr<T> ptr)
    {
        return isAlive(ptr.get());
    }

#if ENABLE(ASSERT)
    void checkGCInfo(const void*, const GCInfo*);
#endif

    // Macro to declare methods needed for each typed heap.
#define DECLARE_VISITOR_METHODS(Type)                                  \
    DEBUG_ONLY(void checkGCInfo(const Type*, const GCInfo*);)          \
    virtual void mark(const Type*, TraceCallback) = 0;                 \
    virtual bool isMarked(const Type*) = 0;

    FOR_EACH_TYPED_HEAP(DECLARE_VISITOR_METHODS)
#undef DECLARE_VISITOR_METHODS

#if ENABLE(GC_PROFILE_MARKING)
    void setHostInfo(void* object, const String& name)
    {
        m_hostObject = object;
        m_hostName = name;
    }
#endif

protected:
    virtual void registerWeakCell(void**, WeakPointerCallback) = 0;
#if ENABLE(GC_PROFILE_MARKING)
    void* m_hostObject;
    String m_hostName;
#endif

private:
    template<typename T>
    static void handleWeakCell(Visitor* self, void* obj)
    {
        T** cell = reinterpret_cast<T**>(obj);
        if (*cell && !self->isAlive(*cell))
            *cell = 0;
    }
};

// We trace vectors by using the trace trait on each element, which means you
// can have vectors of general objects (not just pointers to objects) that can
// be traced.
template<typename T, size_t N>
struct OffHeapCollectionTraceTrait<WTF::Vector<T, N, WTF::DefaultAllocator> > {
    typedef WTF::Vector<T, N, WTF::DefaultAllocator> Vector;

    static void trace(Visitor* visitor, const Vector& vector)
    {
        if (vector.isEmpty())
            return;
        for (typename Vector::const_iterator it = vector.begin(), end = vector.end(); it != end; ++it)
            TraceTrait<T>::trace(visitor, const_cast<T*>(it));
    }
};

template<typename T, size_t N>
struct OffHeapCollectionTraceTrait<WTF::Deque<T, N> > {
    typedef WTF::Deque<T, N> Deque;

    static void trace(Visitor* visitor, const Deque& deque)
    {
        if (deque.isEmpty())
            return;
        for (typename Deque::const_iterator it = deque.begin(), end = deque.end(); it != end; ++it)
            TraceTrait<T>::trace(visitor, const_cast<T*>(&(*it)));
    }
};

template<typename T, typename Traits = WTF::VectorTraits<T> >
class HeapVectorBacking;

template<typename Table>
class HeapHashTableBacking {
public:
    static void finalize(void* pointer);
};

template<typename T>
class DefaultTraceTrait<T, false> {
public:
    static void mark(Visitor* visitor, const T* t)
    {
        // Default mark method of the trait just calls the two-argument mark
        // method on the visitor. The second argument is the static trace method
        // of the trait, which by default calls the instance method
        // trace(Visitor*) on the object.
        visitor->mark(const_cast<T*>(t), &TraceTrait<T>::trace);
    }

#if ENABLE(ASSERT)
    static void checkGCInfo(Visitor* visitor, const T* t)
    {
        visitor->checkGCInfo(const_cast<T*>(t), GCInfoTrait<T>::get());
    }
#endif
};

template<typename T>
class DefaultTraceTrait<T, true> {
public:
    static void mark(Visitor* visitor, const T* self)
    {
        if (!self)
            return;

        // Before doing adjustAndMark we need to check if the page is orphaned
        // since we cannot call adjustAndMark if so, as there will be no vtable.
        // If orphaned just mark the page as traced.
        BaseHeapPage* heapPage = pageHeaderFromObject(self);
        if (heapPage->orphaned()) {
            heapPage->setTracedAfterOrphaned();
            return;
        }
        self->adjustAndMark(visitor);
    }

#if ENABLE(ASSERT)
    static void checkGCInfo(Visitor*, const T*) { }
#endif
};

template<typename T, bool = NeedsAdjustAndMark<T>::value> class DefaultObjectAliveTrait;

template<typename T>
class DefaultObjectAliveTrait<T, false> {
public:
    static bool isAlive(Visitor* visitor, T* obj)
    {
        return visitor->isMarked(obj);
    }
};

template<typename T>
class DefaultObjectAliveTrait<T, true> {
public:
    static bool isAlive(Visitor* visitor, T* obj)
    {
        return obj->isAlive(visitor);
    }
};

template<typename T> bool ObjectAliveTrait<T>::isAlive(Visitor* visitor, T* obj)
{
    return DefaultObjectAliveTrait<T>::isAlive(visitor, obj);
}

// The GarbageCollectedMixin interface and helper macro
// USING_GARBAGE_COLLECTED_MIXIN can be used to automatically define
// TraceTrait/ObjectAliveTrait on non-leftmost deriving classes
// which need to be garbage collected.
//
// Consider the following case:
// class B {};
// class A : public GarbageCollected, public B {};
//
// We can't correctly handle "Member<B> p = &a" as we can't compute addr of
// object header statically. This can be solved by using GarbageCollectedMixin:
// class B : public GarbageCollectedMixin {};
// class A : public GarbageCollected, public B {
//   USING_GARBAGE_COLLECTED_MIXIN(A)
// };
//
// With the helper, as long as we are using Member<B>, TypeTrait<B> will
// dispatch adjustAndMark dynamically to find collect addr of the object header.
// Note that this is only enabled for Member<B>. For Member<A> which we can
// compute the object header addr statically, this dynamic dispatch is not used.

class PLATFORM_EXPORT GarbageCollectedMixin {
public:
    virtual void adjustAndMark(Visitor*) const { };
    virtual bool isAlive(Visitor*) const { return true; };
    virtual void trace(Visitor*) { }
};

#define USING_GARBAGE_COLLECTED_MIXIN(TYPE) \
public: \
    virtual void adjustAndMark(blink::Visitor* visitor) const OVERRIDE    \
    { \
        typedef WTF::IsSubclassOfTemplate<typename WTF::RemoveConst<TYPE>::Type, blink::GarbageCollected> IsSubclassOfGarbageCollected; \
        COMPILE_ASSERT(IsSubclassOfGarbageCollected::value, OnlyGarbageCollectedObjectsCanHaveGarbageCollectedMixins); \
        visitor->mark(static_cast<const TYPE*>(this), &blink::TraceTrait<TYPE>::trace); \
    } \
    virtual bool isAlive(blink::Visitor* visitor) const OVERRIDE  \
    { \
        return visitor->isAlive(this); \
    } \
private:

#if ENABLE(OILPAN)
#define WILL_BE_USING_GARBAGE_COLLECTED_MIXIN(TYPE) USING_GARBAGE_COLLECTED_MIXIN(TYPE)
#else
#define WILL_BE_USING_GARBAGE_COLLECTED_MIXIN(TYPE)
#endif

#if ENABLE(GC_PROFILING)
template<typename T>
struct TypenameStringTrait {
    static const String& get()
    {
        DEFINE_STATIC_LOCAL(String, typenameString, (WTF::extractTypeNameFromFunctionName(WTF::extractNameFunction<T>())));
        return typenameString;
    }
};
#endif

template<typename T>
struct GCInfoAtBase {
    static const GCInfo* get()
    {
        static const GCInfo gcInfo = {
            TraceTrait<T>::trace,
            FinalizerTrait<T>::finalize,
            FinalizerTrait<T>::nonTrivialFinalizer,
            WTF::IsPolymorphic<T>::value,
#if ENABLE(GC_PROFILING)
            TypenameStringTrait<T>::get()
#endif
        };
        return &gcInfo;
    }
};

template<typename T> class GarbageCollected;
template<typename T, bool = WTF::IsSubclassOfTemplate<typename WTF::RemoveConst<T>::Type, GarbageCollected>::value> struct GetGarbageCollectedBase;

template<typename T>
struct GetGarbageCollectedBase<T, true> {
    typedef typename T::GarbageCollectedBase type;
};

template<typename T>
struct GetGarbageCollectedBase<T, false> {
    typedef T type;
};

template<typename T>
struct GCInfoTrait {
    static const GCInfo* get()
    {
        return GCInfoAtBase<typename GetGarbageCollectedBase<T>::type>::get();
    }
};

}

#endif
