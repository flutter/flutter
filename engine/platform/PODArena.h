/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef PODArena_h
#define PODArena_h

#include <stdint.h>
#include "wtf/Assertions.h"
#include "wtf/FastMalloc.h"
#include "wtf/Noncopyable.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/RefCounted.h"
#include "wtf/Vector.h"

namespace blink {

// An arena which allocates only Plain Old Data (POD), or classes and
// structs bottoming out in Plain Old Data. NOTE: the constructors of
// the objects allocated in this arena are called, but _not_ their
// destructors.

class PODArena FINAL : public RefCounted<PODArena> {
public:
    // The arena is configured with an allocator, which is responsible
    // for allocating and freeing chunks of memory at a time.
    class Allocator : public RefCounted<Allocator> {
    public:
        virtual void* allocate(size_t size) = 0;
        virtual void free(void* ptr) = 0;
    protected:
        virtual ~Allocator() { }
        friend class WTF::RefCounted<Allocator>;
    };

    // The Arena's default allocator, which uses fastMalloc and
    // fastFree to allocate chunks of storage.
    class FastMallocAllocator : public Allocator {
    public:
        static PassRefPtr<FastMallocAllocator> create()
        {
            return adoptRef(new FastMallocAllocator);
        }

        virtual void* allocate(size_t size) OVERRIDE { return fastMalloc(size); }
        virtual void free(void* ptr) OVERRIDE { fastFree(ptr); }

    protected:
        FastMallocAllocator() { }
    };

    // Creates a new PODArena configured with a FastMallocAllocator.
    static PassRefPtr<PODArena> create()
    {
        return adoptRef(new PODArena);
    }

    // Creates a new PODArena configured with the given Allocator.
    static PassRefPtr<PODArena> create(PassRefPtr<Allocator> allocator)
    {
        return adoptRef(new PODArena(allocator));
    }

    // Allocates an object from the arena.
    template<class T> T* allocateObject()
    {
        return new (allocateBase<T>()) T();
    }

    // Allocates an object from the arena, calling a single-argument constructor.
    template<class T, class Argument1Type> T* allocateObject(const Argument1Type& argument1)
    {
        return new (allocateBase<T>()) T(argument1);
    }

    // The initial size of allocated chunks; increases as necessary to
    // satisfy large allocations. Mainly public for unit tests.
    enum {
        DefaultChunkSize = 16384
    };

protected:
    friend class WTF::RefCounted<PODArena>;

    PODArena()
        : m_allocator(FastMallocAllocator::create())
        , m_current(0)
        , m_currentChunkSize(DefaultChunkSize) { }

    explicit PODArena(PassRefPtr<Allocator> allocator)
        : m_allocator(allocator)
        , m_current(0)
        , m_currentChunkSize(DefaultChunkSize) { }

    // Returns the alignment requirement for classes and structs on the
    // current platform.
    template <class T> static size_t minAlignment()
    {
        return WTF_ALIGN_OF(T);
    }

    template<class T> void* allocateBase()
    {
        void* ptr = 0;
        size_t roundedSize = roundUp(sizeof(T), minAlignment<T>());
        if (m_current)
            ptr = m_current->allocate(roundedSize);

        if (!ptr) {
            if (roundedSize > m_currentChunkSize)
                m_currentChunkSize = roundedSize;
            m_chunks.append(adoptPtr(new Chunk(m_allocator.get(), m_currentChunkSize)));
            m_current = m_chunks.last().get();
            ptr = m_current->allocate(roundedSize);
        }
        return ptr;
    }

    // Rounds up the given allocation size to the specified alignment.
    size_t roundUp(size_t size, size_t alignment)
    {
        ASSERT(!(alignment % 2));
        return (size + alignment - 1) & ~(alignment - 1);
    }

    // Manages a chunk of memory and individual allocations out of it.
    class Chunk FINAL {
        WTF_MAKE_NONCOPYABLE(Chunk);
    public:
        // Allocates a block of memory of the given size from the passed
        // Allocator.
        Chunk(Allocator* allocator, size_t size)
            : m_allocator(allocator)
            , m_size(size)
            , m_currentOffset(0)
        {
            m_base = static_cast<uint8_t*>(m_allocator->allocate(size));
        }

        // Frees the memory allocated from the Allocator in the
        // constructor.
        ~Chunk()
        {
            m_allocator->free(m_base);
        }

        // Returns a pointer to "size" bytes of storage, or 0 if this
        // Chunk could not satisfy the allocation.
        void* allocate(size_t size)
        {
            // Check for overflow
            if (m_currentOffset + size < m_currentOffset)
                return 0;

            if (m_currentOffset + size > m_size)
                return 0;

            void* result = m_base + m_currentOffset;
            m_currentOffset += size;
            return result;
        }

    protected:
        Allocator* m_allocator;
        uint8_t* m_base;
        size_t m_size;
        size_t m_currentOffset;
    };

    RefPtr<Allocator> m_allocator;
    Chunk* m_current;
    size_t m_currentChunkSize;
    Vector<OwnPtr<Chunk> > m_chunks;
};

} // namespace blink

#endif // PODArena_h
