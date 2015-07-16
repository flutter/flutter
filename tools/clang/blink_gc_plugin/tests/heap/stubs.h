// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef HEAP_STUBS_H_
#define HEAP_STUBS_H_

#include "stddef.h"

#define WTF_MAKE_FAST_ALLOCATED                 \
    public:                                     \
    void* operator new(size_t, void* p);        \
    void* operator new[](size_t, void* p);      \
    void* operator new(size_t size);            \
    private:                                    \
    typedef int __thisIsHereToForceASemicolonAfterThisMacro

namespace WTF {

template<typename T> class RefCounted { };

template<typename T> class RawPtr {
public:
    operator T*() const { return 0; }
    T* operator->() { return 0; }
};

template<typename T> class RefPtr {
public:
    ~RefPtr() { }
    operator T*() const { return 0; }
    T* operator->() { return 0; }
};

template<typename T> class OwnPtr {
public:
    ~OwnPtr() { }
    operator T*() const { return 0; }
    T* operator->() { return 0; }
};

class DefaultAllocator {
public:
    static const bool isGarbageCollected = false;
};

template<typename T>
struct VectorTraits {
    static const bool needsDestruction = true;
};

template<size_t inlineCapacity, bool isGarbageCollected, bool tNeedsDestruction>
class VectorDestructorBase {
public:
    ~VectorDestructorBase() {}
};

template<size_t inlineCapacity>
class VectorDestructorBase<inlineCapacity, true, false> {};

template<>
class VectorDestructorBase<0, true, true> {};

template<
    typename T,
    size_t inlineCapacity = 0,
    typename Allocator = DefaultAllocator>
class Vector : public VectorDestructorBase<inlineCapacity,
                                           Allocator::isGarbageCollected,
                                           VectorTraits<T>::needsDestruction> {
public:
    size_t size();
    T& operator[](size_t);
};

template<
    typename T,
    size_t inlineCapacity = 0,
    typename Allocator = DefaultAllocator>
class Deque {};

template<
    typename ValueArg,
    typename HashArg = void,
    typename TraitsArg = void,
    typename Allocator = DefaultAllocator>
class HashSet {};

template<
    typename ValueArg,
    typename HashArg = void,
    typename TraitsArg = void,
    typename Allocator = DefaultAllocator>
class ListHashSet {};

template<
    typename ValueArg,
    typename HashArg = void,
    typename TraitsArg = void,
    typename Allocator = DefaultAllocator>
class LinkedHashSet {};

template<
    typename ValueArg,
    typename HashArg = void,
    typename TraitsArg = void,
    typename Allocator = DefaultAllocator>
class HashCountedSet {};

template<
    typename KeyArg,
    typename MappedArg,
    typename HashArg = void,
    typename KeyTraitsArg = void,
    typename MappedTraitsArg = void,
    typename Allocator = DefaultAllocator>
class HashMap {};

}

namespace blink {

using namespace WTF;

#define DISALLOW_ALLOCATION()                   \
    private:                                    \
    void* operator new(size_t) = delete;        \
    void* operator new(size_t, void*) = delete;

#define STACK_ALLOCATED()                                   \
    private:                                                \
    __attribute__((annotate("blink_stack_allocated")))      \
    void* operator new(size_t) = delete;                    \
    void* operator new(size_t, void*) = delete;

#define ALLOW_ONLY_INLINE_ALLOCATION()    \
    public:                               \
    void* operator new(size_t, void*);    \
    private:                              \
    void* operator new(size_t) = delete;

#define GC_PLUGIN_IGNORE(bug)                           \
    __attribute__((annotate("blink_gc_plugin_ignore")))

#define USING_GARBAGE_COLLECTED_MIXIN(type)                     \
public:                                                         \
    virtual void adjustAndMark(Visitor*) const override { }     \
    virtual bool isHeapObjectAlive(Visitor*) const override { return 0; }

#define EAGERLY_FINALIZED() typedef int IsEagerlyFinalizedMarker

template<typename T> class GarbageCollected { };

template<typename T>
class GarbageCollectedFinalized : public GarbageCollected<T> { };

template<typename T> class Member {
public:
    operator T*() const { return 0; }
    T* operator->() { return 0; }
    bool operator!() const { return false; }
};

template<typename T> class WeakMember {
public:
    operator T*() const { return 0; }
    T* operator->() { return 0; }
    bool operator!() const { return false; }
};

template<typename T> class Persistent {
public:
    operator T*() const { return 0; }
    T* operator->() { return 0; }
    bool operator!() const { return false; }
};

class HeapAllocator {
public:
    static const bool isGarbageCollected = true;
};

template<typename T, size_t inlineCapacity = 0>
class HeapVector : public Vector<T, inlineCapacity, HeapAllocator> { };

template<typename T, size_t inlineCapacity = 0>
class HeapDeque : public Vector<T, inlineCapacity, HeapAllocator> { };

template<typename T>
class HeapHashSet : public HashSet<T, void, void, HeapAllocator> { };

template<typename T>
class HeapListHashSet : public ListHashSet<T, void, void, HeapAllocator> { };

template<typename T>
class HeapLinkedHashSet : public LinkedHashSet<T, void, void, HeapAllocator> {
};

template<typename T>
class HeapHashCountedSet : public HashCountedSet<T, void, void, HeapAllocator> {
};

template<typename K, typename V>
class HeapHashMap : public HashMap<K, V, void, void, void, HeapAllocator> { };

template<typename T>
class PersistentHeapVector : public Vector<T, 0, HeapAllocator> { };

template <typename Derived>
class VisitorHelper {
public:
    template<typename T>
    void trace(const T&);
};

class Visitor : public VisitorHelper<Visitor> {
public:
    template<typename T, void (T::*method)(Visitor*)>
    void registerWeakMembers(const T* obj);
};

class InlinedGlobalMarkingVisitor
    : public VisitorHelper<InlinedGlobalMarkingVisitor> {
public:
    InlinedGlobalMarkingVisitor* operator->() { return this; }

    template<typename T, void (T::*method)(Visitor*)>
    void registerWeakMembers(const T* obj);
};

class GarbageCollectedMixin {
public:
    virtual void adjustAndMark(Visitor*) const = 0;
    virtual bool isHeapObjectAlive(Visitor*) const = 0;
    virtual void trace(Visitor*) { }
};

template<typename T>
struct TraceIfNeeded {
    static void trace(Visitor*, T*);
};

// blink::ScriptWrappable receives special treatment
// so as to allow it to be used together with GarbageCollected<T>,
// even when its user-declared destructor is provided.
// As it is with Oilpan disabled.
class ScriptWrappable {
public:
    ~ScriptWrappable() { /* user-declared, thus, non-trivial */ }
};

}

namespace WTF {

template<typename T>
struct VectorTraits<blink::Member<T> > {
    static const bool needsDestruction = false;
};

}

#endif
