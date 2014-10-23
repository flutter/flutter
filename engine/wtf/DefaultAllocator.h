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

#ifndef WTF_DefaultAllocator_h
#define WTF_DefaultAllocator_h

// This is the allocator that is used for allocations that are not on the
// traced, garbage collected heap. It uses FastMalloc for collections,
// but uses the partition allocator for the backing store of the collections.

#include "wtf/Assertions.h"
#include "wtf/FastAllocBase.h"
#include "wtf/PartitionAlloc.h"
#include "wtf/WTF.h"

#include <string.h>

namespace WTF {

class DefaultAllocatorDummyVisitor;

class DefaultAllocatorQuantizer {
public:
    template<typename T>
    static size_t quantizedSize(size_t count)
    {
        RELEASE_ASSERT(count <= kMaxUnquantizedAllocation / sizeof(T));
        return partitionAllocActualSize(Partitions::getBufferPartition(), count * sizeof(T));
    }
    static const size_t kMaxUnquantizedAllocation = kGenericMaxDirectMapped;
};

class DefaultAllocator {
public:
    typedef DefaultAllocatorQuantizer Quantizer;
    typedef DefaultAllocatorDummyVisitor Visitor;
    static const bool isGarbageCollected = false;
    template<typename T, typename Traits>
    struct VectorBackingHelper {
        typedef void Type;
    };
    template<typename T>
    struct HashTableBackingHelper {
        typedef void Type;
    };
    template <typename Return, typename Metadata>
    static Return backingMalloc(size_t size)
    {
        return reinterpret_cast<Return>(backingAllocate(size));
    }
    template <typename Return, typename Metadata>
    static Return zeroedBackingMalloc(size_t size)
    {
        void* result = backingAllocate(size);
        memset(result, 0, size);
        return reinterpret_cast<Return>(result);
    }
    template <typename Return, typename Metadata>
    static Return malloc(size_t size)
    {
        return reinterpret_cast<Return>(fastMalloc(size));
    }
    WTF_EXPORT static void backingFree(void* address);
    static void free(void* address)
    {
        fastFree(address);
    }
    template<typename T>
    static void* newArray(size_t bytes)
    {
        return malloc<void*, void>(bytes);
    }
    static void
    deleteArray(void* ptr)
    {
        free(ptr); // Not the system free, the one from this class.
    }

    static bool isAllocationAllowed() { return true; }

    static void markNoTracing(...)
    {
        ASSERT_NOT_REACHED();
    }

    static void registerDelayedMarkNoTracing(...)
    {
        ASSERT_NOT_REACHED();
    }

    static void registerWeakMembers(...)
    {
        ASSERT_NOT_REACHED();
    }

    static void registerWeakTable(...)
    {
        ASSERT_NOT_REACHED();
    }

#if ENABLE(ASSERT)
    static bool weakTableRegistered(...)
    {
        ASSERT_NOT_REACHED();
        return false;
    }
#endif

    template<typename T, typename Traits>
    static void trace(...)
    {
        ASSERT_NOT_REACHED();
    }

    template<typename T>
    struct OtherType {
        typedef T* Type;
    };

    template<typename T>
    static T& getOther(T* other)
    {
        return *other;
    }

    static void enterNoAllocationScope() { }
    static void leaveNoAllocationScope() { }

private:
    WTF_EXPORT static void* backingAllocate(size_t);
};

// The Windows compiler seems to be very eager to instantiate things it won't
// need, so unless we have this class we get compile errors.
class DefaultAllocatorDummyVisitor {
public:
    template<typename T> inline bool isAlive(T obj)
    {
        ASSERT_NOT_REACHED();
        return false;
    }
};

} // namespace WTF

#define WTF_USE_ALLOCATOR(ClassName, Allocator) \
public: \
    void* operator new(size_t size) \
    { \
        return Allocator::template malloc<void*, ClassName>(size); \
    } \
    void operator delete(void* p) { Allocator::free(p); } \
    void* operator new[](size_t size) { return Allocator::template newArray<ClassName>(size); } \
    void operator delete[](void* p) { Allocator::deleteArray(p); } \
    void* operator new(size_t, NotNullTag, void* location) \
    { \
        ASSERT(location); \
        return location; \
    } \
private: \
typedef int __thisIsHereToForceASemicolonAfterThisMacro

using WTF::DefaultAllocator;

#endif // WTF_DefaultAllocator_h
