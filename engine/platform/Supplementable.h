/*
 * Copyright (C) 2012 Google, Inc. All Rights Reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef Supplementable_h
#define Supplementable_h

#include "platform/heap/Handle.h"
#include "wtf/Assertions.h"
#include "wtf/HashMap.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"

#if ENABLE(ASSERT)
#include "wtf/Threading.h"
#endif

namespace blink {

// What you should know about Supplementable and Supplement
// ========================================================
// Supplementable and Supplement instances are meant to be thread local. They
// should only be accessed from within the thread that created them. The
// 2 classes are not designed for safe access from another thread. Violating
// this design assumption can result in memory corruption and unpredictable
// behavior.
//
// What you should know about the Supplement keys
// ==============================================
// The Supplement is expected to use the same const char* string instance
// as its key. The Supplementable's SupplementMap will use the address of the
// string as the key and not the characters themselves. Hence, 2 strings with
// the same characters will be treated as 2 different keys.
//
// In practice, it is recommended that Supplements implements a static method
// for returning its key to use. For example:
//
//     class MyClass : public Supplement<MySupplementable> {
//         ...
//         static const char* supplementName();
//     }
//
//     const char* MyClass::supplementName()
//     {
//         return "MyClass";
//     }
//
// An example of the using the key:
//
//     MyClass* MyClass::from(MySupplementable* host)
//     {
//         return reinterpret_cast<MyClass*>(Supplement<MySupplementable>::from(host, supplementName()));
//     }
//
// What you should know about thread checks
// ========================================
// When assertion is enabled this class performs thread-safety check so that
// provideTo and from happen on the same thread. If you want to provide
// some value for Workers this thread check may not work very well though,
// since in most case you'd provide the value while worker preparation is
// being done on the main thread, even before the worker thread is started.
// If that's the case you can explicitly call reattachThread() when the
// Supplementable object is passed to the final destination thread (i.e.
// worker thread). Please be extremely careful to use the method though,
// as randomly calling the method could easily cause racy condition.
//
// Note that reattachThread() does nothing if assertion is not enabled.
//

template<typename T, bool isGarbageCollected>
class SupplementBase;

template<typename T, bool isGarbageCollected>
class SupplementableBase;

template<typename T, bool isGarbageCollected>
struct SupplementableTraits;

template<typename T>
struct SupplementableTraits<T, true> {
    typedef RawPtr<SupplementBase<T, true> > SupplementArgumentType;
    typedef HeapHashMap<const char*, Member<SupplementBase<T, true> >, PtrHash<const char*> > SupplementMap;
};

template<typename T>
struct SupplementableTraits<T, false> {
    typedef PassOwnPtr<SupplementBase<T, false> > SupplementArgumentType;
    typedef HashMap<const char*, OwnPtr<SupplementBase<T, false> >, PtrHash<const char*> > SupplementMap;
};

template<bool>
class SupplementTracing;

template<>
class SupplementTracing<true> : public GarbageCollectedMixin { };

template<>
class SupplementTracing<false> {
public:
    virtual ~SupplementTracing() { }
    virtual void trace(Visitor*) { }
};

template<typename T, bool isGarbageCollected = false>
class SupplementBase : public SupplementTracing<isGarbageCollected> {
public:
#if ENABLE(SECURITY_ASSERT)
    virtual bool isRefCountedWrapper() const { return false; }
#endif

    static void provideTo(SupplementableBase<T, isGarbageCollected>& host, const char* key, typename SupplementableTraits<T, isGarbageCollected>::SupplementArgumentType supplement)
    {
        host.provideSupplement(key, supplement);
    }

    static SupplementBase<T, isGarbageCollected>* from(SupplementableBase<T, isGarbageCollected>& host, const char* key)
    {
        return host.requireSupplement(key);
    }

    static SupplementBase<T, isGarbageCollected>* from(SupplementableBase<T, isGarbageCollected>* host, const char* key)
    {
        return host ? host->requireSupplement(key) : 0;
    }

    // FIXME: Oilpan: Remove this callback once PersistentHeapSupplementable is removed again.
    virtual void persistentHostHasBeenDestroyed() { }
};

// Helper class for implementing Supplementable, HeapSupplementable, and
// PersistentHeapSupplementable.
template<typename T, bool isGarbageCollected = false>
class SupplementableBase {
public:
    void provideSupplement(const char* key, typename SupplementableTraits<T, isGarbageCollected>::SupplementArgumentType supplement)
    {
        ASSERT(m_threadId == currentThread());
        ASSERT(!this->m_supplements.get(key));
        this->m_supplements.set(key, supplement);
    }

    void removeSupplement(const char* key)
    {
        ASSERT(m_threadId == currentThread());
        this->m_supplements.remove(key);
    }

    SupplementBase<T, isGarbageCollected>* requireSupplement(const char* key)
    {
        ASSERT(m_threadId == currentThread());
        return this->m_supplements.get(key);
    }

    void reattachThread()
    {
#if ENABLE(ASSERT)
        m_threadId = currentThread();
#endif
    }

    // We have a trace method in the SupplementableBase class to ensure we have
    // the vtable at the first word of the object. However we don't trace the
    // m_supplements here, but in the partially specialized template subclasses
    // since we only want to trace it for garbage collected classes.
    virtual void trace(Visitor*) { }

    // FIXME: Oilpan: Make private and remove this ignore once PersistentHeapSupplementable is removed again.
protected:
    GC_PLUGIN_IGNORE("")
    typename SupplementableTraits<T, isGarbageCollected>::SupplementMap m_supplements;

#if ENABLE(ASSERT)
protected:
    SupplementableBase() : m_threadId(currentThread()) { }

private:
    ThreadIdentifier m_threadId;
#endif
};

// This class is used to make an on-heap class supplementable. Its supplements
// must be HeapSupplement.
template<typename T>
class HeapSupplement : public SupplementBase<T, true> { };

// FIXME: Oilpan: Move GarbageCollectedMixin to SupplementableBase<T, true> once PersistentHeapSupplementable is removed again.
template<typename T>
class GC_PLUGIN_IGNORE("http://crbug.com/395036") HeapSupplementable : public SupplementableBase<T, true>, public GarbageCollectedMixin {
public:
    virtual void trace(Visitor* visitor) OVERRIDE
    {
        visitor->trace(this->m_supplements);
        SupplementableBase<T, true>::trace(visitor);
    }
};

// This class is used to make an off-heap class supplementable with supplements
// that are on-heap, aka. HeapSupplements.
template<typename T>
class GC_PLUGIN_IGNORE("http://crbug.com/395036") PersistentHeapSupplementable : public SupplementableBase<T, true> {
public:
    PersistentHeapSupplementable() : m_root(this) { }
    virtual ~PersistentHeapSupplementable()
    {
        typedef typename SupplementableTraits<T, true>::SupplementMap::iterator SupplementIterator;
        for (SupplementIterator it = this->m_supplements.begin(); it != this->m_supplements.end(); ++it)
            it->value->persistentHostHasBeenDestroyed();
    }

    virtual void trace(Visitor* visitor)
    {
        visitor->trace(this->m_supplements);
        SupplementableBase<T, true>::trace(visitor);
    }

private:
    class TraceDelegate : PersistentBase<ThreadLocalPersistents<AnyThread>, TraceDelegate> {
    public:
        TraceDelegate(PersistentHeapSupplementable* owner) : m_owner(owner) { }
        void trace(Visitor* visitor) { m_owner->trace(visitor); }
    private:
        PersistentHeapSupplementable* m_owner;
    };

    TraceDelegate m_root;
};

template<typename T>
class Supplement : public SupplementBase<T, false> { };

// This class is used to make an off-heap class supplementable with off-heap
// supplements (Supplement).
template<typename T>
class GC_PLUGIN_IGNORE("http://crbug.com/395036") Supplementable : public SupplementableBase<T, false> {
public:
    virtual void trace(Visitor* visitor)
    {
        // No tracing of off-heap supplements. We should not have any Supplementable
        // object on the heap. Either the object is HeapSupplementable or if it is
        // off heap it should use PersistentHeapSupplementable to trace any on-heap
        // supplements.
        COMPILE_ASSERT(!IsGarbageCollectedType<T>::value, GarbageCollectedObjectMustBeHeapSupplementable);
        SupplementableBase<T, false>::trace(visitor);
    }
};

template<typename T>
struct ThreadingTrait<SupplementBase<T, true> > {
    static const ThreadAffinity Affinity = ThreadingTrait<T>::Affinity;
};

template<typename T>
struct ThreadingTrait<SupplementableBase<T, true> > {
    static const ThreadAffinity Affinity = ThreadingTrait<T>::Affinity;
};

} // namespace blink

#endif // Supplementable_h
