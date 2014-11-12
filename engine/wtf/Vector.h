/*
 *  Copyright (C) 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Library General Public
 *  License as published by the Free Software Foundation; either
 *  version 2 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Library General Public License for more details.
 *
 *  You should have received a copy of the GNU Library General Public License
 *  along with this library; see the file COPYING.LIB.  If not, write to
 *  the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301, USA.
 *
 */

#ifndef WTF_Vector_h
#define WTF_Vector_h

#include "wtf/Alignment.h"
#include "wtf/DefaultAllocator.h"
#include "wtf/FastAllocBase.h"
#include "wtf/Noncopyable.h"
#include "wtf/NotFound.h"
#include "wtf/StdLibExtras.h"
#include "wtf/VectorTraits.h"
#include "wtf/WTF.h"
#include <string.h>
#include <utility>

namespace WTF {

#if defined(MEMORY_SANITIZER_INITIAL_SIZE)
static const size_t kInitialVectorSize = 1;
#else
#ifndef WTF_VECTOR_INITIAL_SIZE
#define WTF_VECTOR_INITIAL_SIZE 4
#endif
static const size_t kInitialVectorSize = WTF_VECTOR_INITIAL_SIZE;
#endif

    template<typename T, size_t inlineBuffer, typename Allocator>
    class Deque;

    template <bool needsDestruction, typename T>
    struct VectorDestructor;

    template<typename T>
    struct VectorDestructor<false, T>
    {
        static void destruct(T*, T*) {}
    };

    template<typename T>
    struct VectorDestructor<true, T>
    {
        static void destruct(T* begin, T* end)
        {
            for (T* cur = begin; cur != end; ++cur)
                cur->~T();
        }
    };

    template <bool unusedSlotsMustBeZeroed, typename T>
    struct VectorUnusedSlotClearer;

    template<typename T>
    struct VectorUnusedSlotClearer<false, T> {
        static void clear(T*, T*) { }
    };

    template<typename T>
    struct VectorUnusedSlotClearer<true, T> {
        static void clear(T* begin, T* end)
        {
            // We clear out unused slots so that the visitor and the finalizer
            // do not visit them (or at least it does not matter if they do).
            memset(begin, 0, sizeof(T) * (end - begin));
        }
    };

    template <bool canInitializeWithMemset, typename T>
    struct VectorInitializer;

    template<typename T>
    struct VectorInitializer<false, T>
    {
        static void initialize(T* begin, T* end)
        {
            for (T* cur = begin; cur != end; ++cur)
                new (NotNull, cur) T;
        }
    };

    template<typename T>
    struct VectorInitializer<true, T>
    {
        static void initialize(T* begin, T* end)
        {
            memset(begin, 0, reinterpret_cast<char*>(end) - reinterpret_cast<char*>(begin));
        }
    };

    template <bool canMoveWithMemcpy, typename T>
    struct VectorMover;

    template<typename T>
    struct VectorMover<false, T>
    {
        static void move(const T* src, const T* srcEnd, T* dst)
        {
            while (src != srcEnd) {
                new (NotNull, dst) T(*src);
                src->~T();
                ++dst;
                ++src;
            }
        }
        static void moveOverlapping(const T* src, const T* srcEnd, T* dst)
        {
            if (src > dst)
                move(src, srcEnd, dst);
            else {
                T* dstEnd = dst + (srcEnd - src);
                while (src != srcEnd) {
                    --srcEnd;
                    --dstEnd;
                    new (NotNull, dstEnd) T(*srcEnd);
                    srcEnd->~T();
                }
            }
        }
        static void swap(T* src, T* srcEnd, T* dst)
        {
            std::swap_ranges(src, srcEnd, dst);
        }
    };

    template<typename T>
    struct VectorMover<true, T>
    {
        static void move(const T* src, const T* srcEnd, T* dst)
        {
            memcpy(dst, src, reinterpret_cast<const char*>(srcEnd) - reinterpret_cast<const char*>(src));
        }
        static void moveOverlapping(const T* src, const T* srcEnd, T* dst)
        {
            memmove(dst, src, reinterpret_cast<const char*>(srcEnd) - reinterpret_cast<const char*>(src));
        }
        static void swap(T* src, T* srcEnd, T* dst)
        {
            std::swap_ranges(reinterpret_cast<char*>(src), reinterpret_cast<char*>(srcEnd), reinterpret_cast<char*>(dst));
        }
    };

    template <bool canCopyWithMemcpy, typename T>
    struct VectorCopier;

    template<typename T>
    struct VectorCopier<false, T>
    {
        template<typename U>
        static void uninitializedCopy(const U* src, const U* srcEnd, T* dst)
        {
            while (src != srcEnd) {
                new (NotNull, dst) T(*src);
                ++dst;
                ++src;
            }
        }
    };

    template<typename T>
    struct VectorCopier<true, T>
    {
        static void uninitializedCopy(const T* src, const T* srcEnd, T* dst)
        {
            memcpy(dst, src, reinterpret_cast<const char*>(srcEnd) - reinterpret_cast<const char*>(src));
        }
        template<typename U>
        static void uninitializedCopy(const U* src, const U* srcEnd, T* dst)
        {
            VectorCopier<false, T>::uninitializedCopy(src, srcEnd, dst);
        }
    };

    template <bool canFillWithMemset, typename T>
    struct VectorFiller;

    template<typename T>
    struct VectorFiller<false, T>
    {
        static void uninitializedFill(T* dst, T* dstEnd, const T& val)
        {
            while (dst != dstEnd) {
                new (NotNull, dst) T(val);
                ++dst;
            }
        }
    };

    template<typename T>
    struct VectorFiller<true, T>
    {
        static void uninitializedFill(T* dst, T* dstEnd, const T& val)
        {
            COMPILE_ASSERT(sizeof(T) == sizeof(char), Size_of_type_should_be_equal_to_one);
#if COMPILER(GCC) && defined(_FORTIFY_SOURCE)
            if (!__builtin_constant_p(dstEnd - dst) || (!(dstEnd - dst)))
#endif
                memset(dst, val, dstEnd - dst);
        }
    };

    template<bool canCompareWithMemcmp, typename T>
    struct VectorComparer;

    template<typename T>
    struct VectorComparer<false, T>
    {
        static bool compare(const T* a, const T* b, size_t size)
        {
            if (LIKELY(a && b))
                return std::equal(a, a + size, b);
            return !a && !b;
        }
    };

    template<typename T>
    struct VectorComparer<true, T>
    {
        static bool compare(const T* a, const T* b, size_t size)
        {
            return memcmp(a, b, sizeof(T) * size) == 0;
        }
    };

    template<typename T>
    struct VectorTypeOperations
    {
        static void destruct(T* begin, T* end)
        {
            VectorDestructor<VectorTraits<T>::needsDestruction, T>::destruct(begin, end);
        }

        static void initialize(T* begin, T* end)
        {
            VectorInitializer<VectorTraits<T>::canInitializeWithMemset, T>::initialize(begin, end);
        }

        static void move(const T* src, const T* srcEnd, T* dst)
        {
            VectorMover<VectorTraits<T>::canMoveWithMemcpy, T>::move(src, srcEnd, dst);
        }

        static void moveOverlapping(const T* src, const T* srcEnd, T* dst)
        {
            VectorMover<VectorTraits<T>::canMoveWithMemcpy, T>::moveOverlapping(src, srcEnd, dst);
        }

        static void swap(T* src, T* srcEnd, T* dst)
        {
            VectorMover<VectorTraits<T>::canMoveWithMemcpy, T>::swap(src, srcEnd, dst);
        }

        static void uninitializedCopy(const T* src, const T* srcEnd, T* dst)
        {
            VectorCopier<VectorTraits<T>::canCopyWithMemcpy, T>::uninitializedCopy(src, srcEnd, dst);
        }

        static void uninitializedFill(T* dst, T* dstEnd, const T& val)
        {
            VectorFiller<VectorTraits<T>::canFillWithMemset, T>::uninitializedFill(dst, dstEnd, val);
        }

        static bool compare(const T* a, const T* b, size_t size)
        {
            return VectorComparer<VectorTraits<T>::canCompareWithMemcmp, T>::compare(a, b, size);
        }
    };

    template<typename T, typename Allocator>
    class VectorBufferBase {
        WTF_MAKE_NONCOPYABLE(VectorBufferBase);
    public:
        void allocateBuffer(size_t newCapacity)
        {
            typedef typename Allocator::template VectorBackingHelper<T, VectorTraits<T> >::Type VectorBacking;
            ASSERT(newCapacity);
            size_t sizeToAllocate = allocationSize(newCapacity);
            m_buffer = Allocator::template backingMalloc<T*, VectorBacking>(sizeToAllocate);
            m_capacity = sizeToAllocate / sizeof(T);
        }

        size_t allocationSize(size_t capacity) const
        {
            return Allocator::Quantizer::template quantizedSize<T>(capacity);
        }

        T* buffer() { return m_buffer; }
        const T* buffer() const { return m_buffer; }
        size_t capacity() const { return m_capacity; }

        void clearUnusedSlots(T* from, T* to)
        {
            VectorUnusedSlotClearer<Allocator::isGarbageCollected && (VectorTraits<T>::needsDestruction || ShouldBeTraced<VectorTraits<T> >::value), T>::clear(from, to);
        }

    protected:
        VectorBufferBase()
            : m_buffer(0)
            , m_capacity(0)
        {
        }

        VectorBufferBase(T* buffer, size_t capacity)
            : m_buffer(buffer)
            , m_capacity(capacity)
        {
        }

        T* m_buffer;
        unsigned m_capacity;
        unsigned m_size;
    };

    template<typename T, size_t inlineCapacity, typename Allocator = DefaultAllocator>
    class VectorBuffer;

    template<typename T, typename Allocator>
    class VectorBuffer<T, 0, Allocator> : protected VectorBufferBase<T, Allocator> {
    private:
        typedef VectorBufferBase<T, Allocator> Base;
    public:
        VectorBuffer()
        {
        }

        VectorBuffer(size_t capacity)
        {
            // Calling malloc(0) might take a lock and may actually do an
            // allocation on some systems.
            if (capacity)
                allocateBuffer(capacity);
        }

        void destruct()
        {
            deallocateBuffer(m_buffer);
            m_buffer = 0;
        }

        void deallocateBuffer(T* bufferToDeallocate)
        {
            Allocator::backingFree(bufferToDeallocate);
        }

        void resetBufferPointer()
        {
            m_buffer = 0;
            m_capacity = 0;
        }

        void swapVectorBuffer(VectorBuffer<T, 0, Allocator>& other)
        {
            std::swap(m_buffer, other.m_buffer);
            std::swap(m_capacity, other.m_capacity);
        }

        using Base::allocateBuffer;
        using Base::allocationSize;

        using Base::buffer;
        using Base::capacity;

        using Base::clearUnusedSlots;

        bool hasOutOfLineBuffer() const
        {
            // When inlineCapacity is 0 we have an out of line buffer if we have a buffer.
            return buffer();
        }

    protected:
        using Base::m_size;

    private:
        using Base::m_buffer;
        using Base::m_capacity;
    };

    template<typename T, size_t inlineCapacity, typename Allocator>
    class VectorBuffer : protected VectorBufferBase<T, Allocator> {
        WTF_MAKE_NONCOPYABLE(VectorBuffer);
    private:
        typedef VectorBufferBase<T, Allocator> Base;
    public:
        VectorBuffer()
            : Base(inlineBuffer(), inlineCapacity)
        {
        }

        VectorBuffer(size_t capacity)
            : Base(inlineBuffer(), inlineCapacity)
        {
            if (capacity > inlineCapacity)
                Base::allocateBuffer(capacity);
        }

        void destruct()
        {
            deallocateBuffer(m_buffer);
            m_buffer = 0;
        }

        NEVER_INLINE void reallyDeallocateBuffer(T* bufferToDeallocate)
        {
            Allocator::backingFree(bufferToDeallocate);
        }

        void deallocateBuffer(T* bufferToDeallocate)
        {
            if (UNLIKELY(bufferToDeallocate != inlineBuffer()))
                reallyDeallocateBuffer(bufferToDeallocate);
        }

        void resetBufferPointer()
        {
            m_buffer = inlineBuffer();
            m_capacity = inlineCapacity;
        }

        void allocateBuffer(size_t newCapacity)
        {
            // FIXME: This should ASSERT(!m_buffer) to catch misuse/leaks.
            if (newCapacity > inlineCapacity)
                Base::allocateBuffer(newCapacity);
            else
                resetBufferPointer();
        }

        size_t allocationSize(size_t capacity) const
        {
            if (capacity <= inlineCapacity)
                return m_inlineBufferSize;
            return Base::allocationSize(capacity);
        }

        void swapVectorBuffer(VectorBuffer<T, inlineCapacity, Allocator>& other)
        {
            typedef VectorTypeOperations<T> TypeOperations;

            if (buffer() == inlineBuffer() && other.buffer() == other.inlineBuffer()) {
                ASSERT(m_capacity == other.m_capacity);
                if (m_size > other.m_size) {
                    TypeOperations::swap(inlineBuffer(), inlineBuffer() + other.m_size, other.inlineBuffer());
                    TypeOperations::move(inlineBuffer() + other.m_size, inlineBuffer() + m_size, other.inlineBuffer() + other.m_size);
                } else {
                    TypeOperations::swap(inlineBuffer(), inlineBuffer() + m_size, other.inlineBuffer());
                    TypeOperations::move(other.inlineBuffer() + m_size, other.inlineBuffer() + other.m_size, inlineBuffer() + m_size);
                }
            } else if (buffer() == inlineBuffer()) {
                m_buffer = other.m_buffer;
                other.m_buffer = other.inlineBuffer();
                TypeOperations::move(inlineBuffer(), inlineBuffer() + m_size, other.inlineBuffer());
                std::swap(m_capacity, other.m_capacity);
            } else if (other.buffer() == other.inlineBuffer()) {
                other.m_buffer = m_buffer;
                m_buffer = inlineBuffer();
                TypeOperations::move(other.inlineBuffer(), other.inlineBuffer() + other.m_size, inlineBuffer());
                std::swap(m_capacity, other.m_capacity);
            } else {
                std::swap(m_buffer, other.m_buffer);
                std::swap(m_capacity, other.m_capacity);
            }
        }

        using Base::buffer;
        using Base::capacity;

        bool hasOutOfLineBuffer() const
        {
            return buffer() && buffer() != inlineBuffer();
        }

    protected:
        using Base::m_size;

    private:
        using Base::m_buffer;
        using Base::m_capacity;

        static const size_t m_inlineBufferSize = inlineCapacity * sizeof(T);
        T* inlineBuffer() { return reinterpret_cast_ptr<T*>(m_inlineBuffer.buffer); }
        const T* inlineBuffer() const { return reinterpret_cast_ptr<const T*>(m_inlineBuffer.buffer); }

        AlignedBuffer<m_inlineBufferSize, WTF_ALIGN_OF(T)> m_inlineBuffer;
        template<typename U, size_t inlineBuffer, typename V>
        friend class Deque;
    };

    template<typename T, size_t inlineCapacity, typename Allocator>
    class Vector;

    // VectorDestructorBase defines the destructor of a vector. This base is used in order to
    // completely avoid creating a destructor for a vector that does not need to be destructed.
    // By doing so, the clang compiler will have correct information about whether or not a
    // vector has a trivial destructor and we use that in a compiler plugin to ensure the
    // correctness of non-finalized garbage-collected classes and the use of VectorTraits::needsDestruction.

    // All non-GC managed vectors need a destructor. This destructor will simply call finalize on the actual vector type.
    template<typename Derived, typename Elements, bool hasInlineCapacity, bool isGarbageCollected>
    class VectorDestructorBase {
    public:
        ~VectorDestructorBase() { static_cast<Derived*>(this)->finalize(); }
    };

    // Heap-allocated vectors with no inlineCapacity never need a destructor.
    template<typename Derived, typename Elements>
    class VectorDestructorBase<Derived, Elements, false, true> { };

    // Heap-allocator vectors with inlineCapacity need a destructor if the inline elements do.
    // The use of VectorTraits<Elements>::needsDestruction is delayed until we know that
    // inlineCapacity is non-zero to allow classes that recursively refer to themselves in vector
    // members. If inlineCapacity is non-zero doing so would have undefined meaning, so in this
    // case we can use HeapVectorWithInlineCapacityDestructorBase to define a destructor
    // depending on the value of VectorTraits<Elements>::needsDestruction.
    template<typename Derived, bool elementsNeedsDestruction>
    class HeapVectorWithInlineCapacityDestructorBase;

    template<typename Derived>
    class HeapVectorWithInlineCapacityDestructorBase<Derived, true> {
    public:
        ~HeapVectorWithInlineCapacityDestructorBase() { static_cast<Derived*>(this)->finalize(); }
    };

    template<typename Derived>
    class HeapVectorWithInlineCapacityDestructorBase<Derived, false> { };

    template<typename Derived, typename Elements>
    class VectorDestructorBase<Derived, Elements, true, true> : public HeapVectorWithInlineCapacityDestructorBase<Derived, VectorTraits<Elements>::needsDestruction> { };

    template<typename T, size_t inlineCapacity = 0, typename Allocator = DefaultAllocator>
    class Vector : private VectorBuffer<T, inlineCapacity, Allocator>, public VectorDestructorBase<Vector<T, inlineCapacity, Allocator>, T, (inlineCapacity > 0), Allocator::isGarbageCollected> {
        WTF_USE_ALLOCATOR(Vector, Allocator);
    private:
        typedef VectorBuffer<T, inlineCapacity, Allocator> Base;
        typedef VectorTypeOperations<T> TypeOperations;

    public:
        typedef T ValueType;

        typedef T* iterator;
        typedef const T* const_iterator;
        typedef std::reverse_iterator<iterator> reverse_iterator;
        typedef std::reverse_iterator<const_iterator> const_reverse_iterator;

        Vector()
        {
            // Unused slots are initialized to zero so that the visitor and the
            // finalizer can visit them safely. canInitializeWithMemset tells us
            // that the class does not expect matching constructor and
            // destructor calls as long as the memory is zeroed.
            COMPILE_ASSERT(!Allocator::isGarbageCollected || !VectorTraits<T>::needsDestruction || VectorTraits<T>::canInitializeWithMemset, ClassHasProblemsWithFinalizersCalledOnClearedMemory);
            COMPILE_ASSERT(!WTF::IsPolymorphic<T>::value || !VectorTraits<T>::canInitializeWithMemset, CantInitializeWithMemsetIfThereIsAVtable);
            m_size = 0;
        }

        explicit Vector(size_t size)
            : Base(size)
        {
            // Unused slots are initialized to zero so that the visitor and the
            // finalizer can visit them safely. canInitializeWithMemset tells us
            // that the class does not expect matching constructor and
            // destructor calls as long as the memory is zeroed.
            COMPILE_ASSERT(!Allocator::isGarbageCollected || !VectorTraits<T>::needsDestruction || VectorTraits<T>::canInitializeWithMemset, ClassHasProblemsWithFinalizersCalledOnClearedMemory);
            m_size = size;
            TypeOperations::initialize(begin(), end());
        }

        // Off-GC-heap vectors: Destructor should be called.
        // On-GC-heap vectors: Destructor should be called for inline buffers
        // (if any) but destructor shouldn't be called for vector backing since
        // it is managed by the traced GC heap.
        void finalize()
        {
            if (!inlineCapacity) {
                if (LIKELY(!Base::buffer()))
                    return;
            }
            if (LIKELY(m_size) && !(Allocator::isGarbageCollected && this->hasOutOfLineBuffer())) {
                TypeOperations::destruct(begin(), end());
                m_size = 0; // Partial protection against use-after-free.
            }

            Base::destruct();
        }

        void finalizeGarbageCollectedObject()
        {
            finalize();
        }

        Vector(const Vector&);
        template<size_t otherCapacity>
        explicit Vector(const Vector<T, otherCapacity, Allocator>&);

        Vector& operator=(const Vector&);
        template<size_t otherCapacity>
        Vector& operator=(const Vector<T, otherCapacity, Allocator>&);

#if COMPILER_SUPPORTS(CXX_RVALUE_REFERENCES)
        Vector(Vector&&);
        Vector& operator=(Vector&&);
#endif

        size_t size() const { return m_size; }
        size_t capacity() const { return Base::capacity(); }
        bool isEmpty() const { return !size(); }

        T& at(size_t i)
        {
            RELEASE_ASSERT(i < size());
            return Base::buffer()[i];
        }
        const T& at(size_t i) const
        {
            RELEASE_ASSERT(i < size());
            return Base::buffer()[i];
        }

        T& operator[](size_t i) { return at(i); }
        const T& operator[](size_t i) const { return at(i); }

        T* data() { return Base::buffer(); }
        const T* data() const { return Base::buffer(); }

        iterator begin() { return data(); }
        iterator end() { return begin() + m_size; }
        const_iterator begin() const { return data(); }
        const_iterator end() const { return begin() + m_size; }

        reverse_iterator rbegin() { return reverse_iterator(end()); }
        reverse_iterator rend() { return reverse_iterator(begin()); }
        const_reverse_iterator rbegin() const { return const_reverse_iterator(end()); }
        const_reverse_iterator rend() const { return const_reverse_iterator(begin()); }

        T& first() { return at(0); }
        const T& first() const { return at(0); }
        T& last() { return at(size() - 1); }
        const T& last() const { return at(size() - 1); }

        template<typename U> bool contains(const U&) const;
        template<typename U> size_t find(const U&) const;
        template<typename U> size_t reverseFind(const U&) const;

        void shrink(size_t size);
        void grow(size_t size);
        void resize(size_t size);
        void reserveCapacity(size_t newCapacity);
        void reserveInitialCapacity(size_t initialCapacity);
        void shrinkToFit() { shrinkCapacity(size()); }
        void shrinkToReasonableCapacity()
        {
            if (size() * 2 < capacity())
                shrinkCapacity(size() + size() / 4 + 1);
        }

        void clear() { shrinkCapacity(0); }

        template<typename U> void append(const U*, size_t);
        template<typename U> void append(const U&);
        template<typename U> void uncheckedAppend(const U& val);
        template<typename U, size_t otherCapacity, typename V> void appendVector(const Vector<U, otherCapacity, V>&);

        template<typename U> void insert(size_t position, const U*, size_t);
        template<typename U> void insert(size_t position, const U&);
        template<typename U, size_t c, typename V> void insert(size_t position, const Vector<U, c, V>&);

        template<typename U> void prepend(const U*, size_t);
        template<typename U> void prepend(const U&);
        template<typename U, size_t c, typename V> void prepend(const Vector<U, c, V>&);

        void remove(size_t position);
        void remove(size_t position, size_t length);

        void removeLast()
        {
            ASSERT(!isEmpty());
            shrink(size() - 1);
        }

        Vector(size_t size, const T& val)
            : Base(size)
        {
            m_size = size;
            TypeOperations::uninitializedFill(begin(), end(), val);
        }

        void fill(const T&, size_t);
        void fill(const T& val) { fill(val, size()); }

        template<typename Iterator> void appendRange(Iterator start, Iterator end);

        void swap(Vector& other)
        {
            Base::swapVectorBuffer(other);
            std::swap(m_size, other.m_size);
        }

        void reverse();

        void trace(typename Allocator::Visitor*);

    private:
        void expandCapacity(size_t newMinCapacity);
        const T* expandCapacity(size_t newMinCapacity, const T*);
        template<typename U> U* expandCapacity(size_t newMinCapacity, U*);
        void shrinkCapacity(size_t newCapacity);
        template<typename U> void appendSlowCase(const U&);

        using Base::m_size;
        using Base::buffer;
        using Base::capacity;
        using Base::swapVectorBuffer;
        using Base::allocateBuffer;
        using Base::allocationSize;
        using Base::clearUnusedSlots;
    };

    template<typename T, size_t inlineCapacity, typename Allocator>
    Vector<T, inlineCapacity, Allocator>::Vector(const Vector& other)
        : Base(other.capacity())
    {
        m_size = other.size();
        TypeOperations::uninitializedCopy(other.begin(), other.end(), begin());
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    template<size_t otherCapacity>
    Vector<T, inlineCapacity, Allocator>::Vector(const Vector<T, otherCapacity, Allocator>& other)
        : Base(other.capacity())
    {
        m_size = other.size();
        TypeOperations::uninitializedCopy(other.begin(), other.end(), begin());
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    Vector<T, inlineCapacity, Allocator>& Vector<T, inlineCapacity, Allocator>::operator=(const Vector<T, inlineCapacity, Allocator>& other)
    {
        if (UNLIKELY(&other == this))
            return *this;

        if (size() > other.size())
            shrink(other.size());
        else if (other.size() > capacity()) {
            clear();
            reserveCapacity(other.size());
            ASSERT(begin());
        }

        std::copy(other.begin(), other.begin() + size(), begin());
        TypeOperations::uninitializedCopy(other.begin() + size(), other.end(), end());
        m_size = other.size();

        return *this;
    }

    inline bool typelessPointersAreEqual(const void* a, const void* b) { return a == b; }

    template<typename T, size_t inlineCapacity, typename Allocator>
    template<size_t otherCapacity>
    Vector<T, inlineCapacity, Allocator>& Vector<T, inlineCapacity, Allocator>::operator=(const Vector<T, otherCapacity, Allocator>& other)
    {
        // If the inline capacities match, we should call the more specific
        // template.  If the inline capacities don't match, the two objects
        // shouldn't be allocated the same address.
        ASSERT(!typelessPointersAreEqual(&other, this));

        if (size() > other.size())
            shrink(other.size());
        else if (other.size() > capacity()) {
            clear();
            reserveCapacity(other.size());
            ASSERT(begin());
        }

        std::copy(other.begin(), other.begin() + size(), begin());
        TypeOperations::uninitializedCopy(other.begin() + size(), other.end(), end());
        m_size = other.size();

        return *this;
    }

#if COMPILER_SUPPORTS(CXX_RVALUE_REFERENCES)
    template<typename T, size_t inlineCapacity, typename Allocator>
    Vector<T, inlineCapacity, Allocator>::Vector(Vector<T, inlineCapacity, Allocator>&& other)
    {
        m_size = 0;
        // It's a little weird to implement a move constructor using swap but this way we
        // don't have to add a move constructor to VectorBuffer.
        swap(other);
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    Vector<T, inlineCapacity, Allocator>& Vector<T, inlineCapacity, Allocator>::operator=(Vector<T, inlineCapacity, Allocator>&& other)
    {
        swap(other);
        return *this;
    }
#endif

    template<typename T, size_t inlineCapacity, typename Allocator>
    template<typename U>
    bool Vector<T, inlineCapacity, Allocator>::contains(const U& value) const
    {
        return find(value) != kNotFound;
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    template<typename U>
    size_t Vector<T, inlineCapacity, Allocator>::find(const U& value) const
    {
        const T* b = begin();
        const T* e = end();
        for (const T* iter = b; iter < e; ++iter) {
            if (*iter == value)
                return iter - b;
        }
        return kNotFound;
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    template<typename U>
    size_t Vector<T, inlineCapacity, Allocator>::reverseFind(const U& value) const
    {
        const T* b = begin();
        const T* iter = end();
        while (iter > b) {
            --iter;
            if (*iter == value)
                return iter - b;
        }
        return kNotFound;
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    void Vector<T, inlineCapacity, Allocator>::fill(const T& val, size_t newSize)
    {
        if (size() > newSize)
            shrink(newSize);
        else if (newSize > capacity()) {
            clear();
            reserveCapacity(newSize);
            ASSERT(begin());
        }

        std::fill(begin(), end(), val);
        TypeOperations::uninitializedFill(end(), begin() + newSize, val);
        m_size = newSize;
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    template<typename Iterator>
    void Vector<T, inlineCapacity, Allocator>::appendRange(Iterator start, Iterator end)
    {
        for (Iterator it = start; it != end; ++it)
            append(*it);
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    void Vector<T, inlineCapacity, Allocator>::expandCapacity(size_t newMinCapacity)
    {
        size_t oldCapacity = capacity();
        size_t expandedCapacity = oldCapacity;
        // We use a more aggressive expansion strategy for Vectors with inline storage.
        // This is because they are more likely to be on the stack, so the risk of heap bloat is minimized.
        // Furthermore, exceeding the inline capacity limit is not supposed to happen in the common case and may indicate a pathological condition or microbenchmark.
        if (inlineCapacity) {
            expandedCapacity *= 2;
            // Check for integer overflow, which could happen in the 32-bit build.
            RELEASE_ASSERT(expandedCapacity > oldCapacity);
        } else {
            // This cannot integer overflow.
            // On 64-bit, the "expanded" integer is 32-bit, and any encroachment above 2^32 will fail allocation in allocateBuffer().
            // On 32-bit, there's not enough address space to hold the old and new buffers.
            // In addition, our underlying allocator is supposed to always fail on > (2^31 - 1) allocations.
            expandedCapacity += (expandedCapacity / 4) + 1;
        }
        reserveCapacity(std::max(newMinCapacity, std::max(static_cast<size_t>(kInitialVectorSize), expandedCapacity)));
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    const T* Vector<T, inlineCapacity, Allocator>::expandCapacity(size_t newMinCapacity, const T* ptr)
    {
        if (ptr < begin() || ptr >= end()) {
            expandCapacity(newMinCapacity);
            return ptr;
        }
        size_t index = ptr - begin();
        expandCapacity(newMinCapacity);
        return begin() + index;
    }

    template<typename T, size_t inlineCapacity, typename Allocator> template<typename U>
    inline U* Vector<T, inlineCapacity, Allocator>::expandCapacity(size_t newMinCapacity, U* ptr)
    {
        expandCapacity(newMinCapacity);
        return ptr;
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline void Vector<T, inlineCapacity, Allocator>::resize(size_t size)
    {
        if (size <= m_size)
            TypeOperations::destruct(begin() + size, end());
        else {
            if (size > capacity())
                expandCapacity(size);
            TypeOperations::initialize(end(), begin() + size);
        }

        m_size = size;
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    void Vector<T, inlineCapacity, Allocator>::shrink(size_t size)
    {
        ASSERT(size <= m_size);
        TypeOperations::destruct(begin() + size, end());
        clearUnusedSlots(begin() + size, end());
        m_size = size;
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    void Vector<T, inlineCapacity, Allocator>::grow(size_t size)
    {
        ASSERT(size >= m_size);
        if (size > capacity())
            expandCapacity(size);
        TypeOperations::initialize(end(), begin() + size);
        m_size = size;
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    void Vector<T, inlineCapacity, Allocator>::reserveCapacity(size_t newCapacity)
    {
        if (UNLIKELY(newCapacity <= capacity()))
            return;
        T* oldBuffer = begin();
        T* oldEnd = end();
        Base::allocateBuffer(newCapacity);
        TypeOperations::move(oldBuffer, oldEnd, begin());
        Base::deallocateBuffer(oldBuffer);
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline void Vector<T, inlineCapacity, Allocator>::reserveInitialCapacity(size_t initialCapacity)
    {
        ASSERT(!m_size);
        ASSERT(capacity() == inlineCapacity);
        if (initialCapacity > inlineCapacity)
            Base::allocateBuffer(initialCapacity);
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    void Vector<T, inlineCapacity, Allocator>::shrinkCapacity(size_t newCapacity)
    {
        if (newCapacity >= capacity())
            return;

        if (newCapacity < size())
            shrink(newCapacity);

        T* oldBuffer = begin();
        if (newCapacity > 0) {
            // Optimization: if we're downsizing inside the same allocator bucket, we can exit with no additional work.
            if (Base::allocationSize(capacity()) == Base::allocationSize(newCapacity))
                return;

            T* oldEnd = end();
            Base::allocateBuffer(newCapacity);
            if (begin() != oldBuffer)
                TypeOperations::move(oldBuffer, oldEnd, begin());
        } else {
            Base::resetBufferPointer();
        }

        Base::deallocateBuffer(oldBuffer);
    }

    // Templatizing these is better than just letting the conversion happen implicitly,
    // because for instance it allows a PassRefPtr to be appended to a RefPtr vector
    // without refcount thrash.

    template<typename T, size_t inlineCapacity, typename Allocator> template<typename U>
    void Vector<T, inlineCapacity, Allocator>::append(const U* data, size_t dataSize)
    {
        ASSERT(Allocator::isAllocationAllowed());
        size_t newSize = m_size + dataSize;
        if (newSize > capacity()) {
            data = expandCapacity(newSize, data);
            ASSERT(begin());
        }
        RELEASE_ASSERT(newSize >= m_size);
        T* dest = end();
        VectorCopier<VectorTraits<T>::canCopyWithMemcpy, T>::uninitializedCopy(data, &data[dataSize], dest);
        m_size = newSize;
    }

    template<typename T, size_t inlineCapacity, typename Allocator> template<typename U>
    ALWAYS_INLINE void Vector<T, inlineCapacity, Allocator>::append(const U& val)
    {
        ASSERT(Allocator::isAllocationAllowed());
        if (LIKELY(size() != capacity())) {
            new (NotNull, end()) T(val);
            ++m_size;
            return;
        }

        appendSlowCase(val);
    }

    template<typename T, size_t inlineCapacity, typename Allocator> template<typename U>
    NEVER_INLINE void Vector<T, inlineCapacity, Allocator>::appendSlowCase(const U& val)
    {
        ASSERT(size() == capacity());

        const U* ptr = &val;
        ptr = expandCapacity(size() + 1, ptr);
        ASSERT(begin());

        new (NotNull, end()) T(*ptr);
        ++m_size;
    }

    // This version of append saves a branch in the case where you know that the
    // vector's capacity is large enough for the append to succeed.

    template<typename T, size_t inlineCapacity, typename Allocator> template<typename U>
    ALWAYS_INLINE void Vector<T, inlineCapacity, Allocator>::uncheckedAppend(const U& val)
    {
        ASSERT(size() < capacity());
        const U* ptr = &val;
        new (NotNull, end()) T(*ptr);
        ++m_size;
    }

    template<typename T, size_t inlineCapacity, typename Allocator> template<typename U, size_t otherCapacity, typename OtherAllocator>
    inline void Vector<T, inlineCapacity, Allocator>::appendVector(const Vector<U, otherCapacity, OtherAllocator>& val)
    {
        append(val.begin(), val.size());
    }

    template<typename T, size_t inlineCapacity, typename Allocator> template<typename U>
    void Vector<T, inlineCapacity, Allocator>::insert(size_t position, const U* data, size_t dataSize)
    {
        ASSERT(Allocator::isAllocationAllowed());
        RELEASE_ASSERT(position <= size());
        size_t newSize = m_size + dataSize;
        if (newSize > capacity()) {
            data = expandCapacity(newSize, data);
            ASSERT(begin());
        }
        RELEASE_ASSERT(newSize >= m_size);
        T* spot = begin() + position;
        TypeOperations::moveOverlapping(spot, end(), spot + dataSize);
        VectorCopier<VectorTraits<T>::canCopyWithMemcpy, T>::uninitializedCopy(data, &data[dataSize], spot);
        m_size = newSize;
    }

    template<typename T, size_t inlineCapacity, typename Allocator> template<typename U>
    inline void Vector<T, inlineCapacity, Allocator>::insert(size_t position, const U& val)
    {
        ASSERT(Allocator::isAllocationAllowed());
        RELEASE_ASSERT(position <= size());
        const U* data = &val;
        if (size() == capacity()) {
            data = expandCapacity(size() + 1, data);
            ASSERT(begin());
        }
        T* spot = begin() + position;
        TypeOperations::moveOverlapping(spot, end(), spot + 1);
        new (NotNull, spot) T(*data);
        ++m_size;
    }

    template<typename T, size_t inlineCapacity, typename Allocator> template<typename U, size_t c, typename OtherAllocator>
    inline void Vector<T, inlineCapacity, Allocator>::insert(size_t position, const Vector<U, c, OtherAllocator>& val)
    {
        insert(position, val.begin(), val.size());
    }

    template<typename T, size_t inlineCapacity, typename Allocator> template<typename U>
    void Vector<T, inlineCapacity, Allocator>::prepend(const U* data, size_t dataSize)
    {
        insert(0, data, dataSize);
    }

    template<typename T, size_t inlineCapacity, typename Allocator> template<typename U>
    inline void Vector<T, inlineCapacity, Allocator>::prepend(const U& val)
    {
        insert(0, val);
    }

    template<typename T, size_t inlineCapacity, typename Allocator> template<typename U, size_t c, typename V>
    inline void Vector<T, inlineCapacity, Allocator>::prepend(const Vector<U, c, V>& val)
    {
        insert(0, val.begin(), val.size());
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline void Vector<T, inlineCapacity, Allocator>::remove(size_t position)
    {
        RELEASE_ASSERT(position < size());
        T* spot = begin() + position;
        spot->~T();
        TypeOperations::moveOverlapping(spot + 1, end(), spot);
        clearUnusedSlots(end() - 1, end());
        --m_size;
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline void Vector<T, inlineCapacity, Allocator>::remove(size_t position, size_t length)
    {
        ASSERT_WITH_SECURITY_IMPLICATION(position <= size());
        RELEASE_ASSERT(position + length <= size());
        T* beginSpot = begin() + position;
        T* endSpot = beginSpot + length;
        TypeOperations::destruct(beginSpot, endSpot);
        TypeOperations::moveOverlapping(endSpot, end(), beginSpot);
        clearUnusedSlots(end() - length, end());
        m_size -= length;
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline void Vector<T, inlineCapacity, Allocator>::reverse()
    {
        for (size_t i = 0; i < m_size / 2; ++i)
            std::swap(at(i), at(m_size - 1 - i));
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    void deleteAllValues(const Vector<T, inlineCapacity, Allocator>& collection)
    {
        typedef typename Vector<T, inlineCapacity, Allocator>::const_iterator iterator;
        iterator end = collection.end();
        for (iterator it = collection.begin(); it != end; ++it)
            delete *it;
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline void swap(Vector<T, inlineCapacity, Allocator>& a, Vector<T, inlineCapacity, Allocator>& b)
    {
        a.swap(b);
    }

    template<typename T, size_t inlineCapacityA, size_t inlineCapacityB, typename Allocator>
    bool operator==(const Vector<T, inlineCapacityA, Allocator>& a, const Vector<T, inlineCapacityB, Allocator>& b)
    {
        if (a.size() != b.size())
            return false;

        return VectorTypeOperations<T>::compare(a.data(), b.data(), a.size());
    }

    template<typename T, size_t inlineCapacityA, size_t inlineCapacityB, typename Allocator>
    inline bool operator!=(const Vector<T, inlineCapacityA, Allocator>& a, const Vector<T, inlineCapacityB, Allocator>& b)
    {
        return !(a == b);
    }

    // This is only called if the allocator is a HeapAllocator. It is used when
    // visiting during a tracing GC.
    template<typename T, size_t inlineCapacity, typename Allocator>
    void Vector<T, inlineCapacity, Allocator>::trace(typename Allocator::Visitor* visitor)
    {
        ASSERT(Allocator::isGarbageCollected); // Garbage collector must be enabled.
        const T* bufferBegin = buffer();
        const T* bufferEnd = buffer() + size();
        if (ShouldBeTraced<VectorTraits<T> >::value) {
            for (const T* bufferEntry = bufferBegin; bufferEntry != bufferEnd; bufferEntry++)
                Allocator::template trace<T, VectorTraits<T> >(visitor, *const_cast<T*>(bufferEntry));
        }
        if (this->hasOutOfLineBuffer())
            Allocator::markNoTracing(visitor, buffer());
    }

#if !ENABLE(OILPAN)
    template<typename T, size_t N>
    struct NeedsTracing<Vector<T, N> > {
        static const bool value = false;
    };
#endif

} // namespace WTF

using WTF::Vector;

#endif // WTF_Vector_h
