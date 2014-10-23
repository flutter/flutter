/*
 * Copyright (C) 2011 Apple Inc.  All rights reserved.
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

#ifndef PODFreeListArena_h
#define PODFreeListArena_h

#include "platform/PODArena.h"

namespace blink {

template <class T>
class PODFreeListArena : public RefCounted<PODFreeListArena<T> > {
public:
    static PassRefPtr<PODFreeListArena> create()
    {
        return adoptRef(new PODFreeListArena);
    }

    // Creates a new PODFreeListArena configured with the given Allocator.
    static PassRefPtr<PODFreeListArena> create(PassRefPtr<PODArena::Allocator> allocator)
    {
        return adoptRef(new PODFreeListArena(allocator));
    }

    // Allocates an object from the arena.
    T* allocateObject()
    {
        void* ptr = allocateFromFreeList();

        if (ptr) {
            // Use placement operator new to allocate a T at this location.
            new(ptr) T();
            return static_cast<T*>(ptr);
        }

        // PODArena::allocateObject calls T's constructor.
        return static_cast<T*>(m_arena->allocateObject<T>());
    }

    template<class Argument1Type> T* allocateObject(const Argument1Type& argument1)
    {
        void* ptr = allocateFromFreeList();

        if (ptr) {
            // Use placement operator new to allocate a T at this location.
            new(ptr) T(argument1);
            return static_cast<T*>(ptr);
        }

        // PODArena::allocateObject calls T's constructor.
        return static_cast<T*>(m_arena->allocateObject<T>(argument1));
    }

    void freeObject(T* ptr)
    {
        FixedSizeMemoryChunk* oldFreeList = m_freeList;

        m_freeList = reinterpret_cast<FixedSizeMemoryChunk*>(ptr);
        m_freeList->next = oldFreeList;
    }

private:
    PODFreeListArena()
        : m_arena(PODArena::create()), m_freeList(0) { }

    explicit PODFreeListArena(PassRefPtr<PODArena::Allocator> allocator)
        : m_arena(PODArena::create(allocator)), m_freeList(0) { }

    ~PODFreeListArena() { }

    void* allocateFromFreeList()
    {
        if (m_freeList) {
            void* memory = m_freeList;
            m_freeList = m_freeList->next;
            return memory;
        }
        return 0;
    }

    int getFreeListSizeForTesting() const
    {
        int total = 0;
        for (FixedSizeMemoryChunk* cur = m_freeList; cur; cur = cur->next) {
            total++;
        }
        return total;
    }

    RefPtr<PODArena> m_arena;

    // This free list contains pointers within every chunk that's been allocated so
    // far. None of the individual chunks can be freed until the arena is
    // destroyed.
    struct FixedSizeMemoryChunk {
        FixedSizeMemoryChunk* next;
    };
    FixedSizeMemoryChunk* m_freeList;

    COMPILE_ASSERT(sizeof(T) >= sizeof(FixedSizeMemoryChunk), PODFreeListArena_type_should_be_larger);

    friend class WTF::RefCounted<PODFreeListArena>;
    friend class PODFreeListArenaTest;
};

} // namespace blink

#endif
