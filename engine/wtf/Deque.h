/*
 * Copyright (C) 2007, 2008 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Google Inc. All rights reserved.
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
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
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

#ifndef WTF_Deque_h
#define WTF_Deque_h

// FIXME: Could move what Vector and Deque share into a separate file.
// Deque doesn't actually use Vector.

#include "wtf/PassTraits.h"
#include "wtf/Vector.h"
#include <iterator>

namespace WTF {
    template<typename T, size_t inlineCapacity, typename Allocator> class DequeIteratorBase;
    template<typename T, size_t inlineCapacity, typename Allocator> class DequeIterator;
    template<typename T, size_t inlineCapacity, typename Allocator> class DequeConstIterator;

    template<typename T, size_t inlineCapacity = 0, typename Allocator = DefaultAllocator>
    class Deque : public VectorDestructorBase<Deque<T, inlineCapacity, Allocator>, T, (inlineCapacity > 0), Allocator::isGarbageCollected> {
        WTF_USE_ALLOCATOR(Deque, Allocator);
    public:
        typedef DequeIterator<T, inlineCapacity, Allocator> iterator;
        typedef DequeConstIterator<T, inlineCapacity, Allocator> const_iterator;
        typedef std::reverse_iterator<iterator> reverse_iterator;
        typedef std::reverse_iterator<const_iterator> const_reverse_iterator;
        typedef PassTraits<T> Pass;
        typedef typename PassTraits<T>::PassType PassType;

        Deque();
        Deque(const Deque<T, inlineCapacity, Allocator>&);
        // FIXME: Doesn't work if there is an inline buffer, due to crbug.com/360572
        Deque<T, 0, Allocator>& operator=(const Deque&);

        void finalize();
        void finalizeGarbageCollectedObject() { finalize(); }

        // We hard wire the inlineCapacity to zero here, due to crbug.com/360572
        void swap(Deque<T, 0, Allocator>&);

        size_t size() const { return m_start <= m_end ? m_end - m_start : m_end + m_buffer.capacity() - m_start; }
        bool isEmpty() const { return m_start == m_end; }

        iterator begin() { return iterator(this, m_start); }
        iterator end() { return iterator(this, m_end); }
        const_iterator begin() const { return const_iterator(this, m_start); }
        const_iterator end() const { return const_iterator(this, m_end); }
        reverse_iterator rbegin() { return reverse_iterator(end()); }
        reverse_iterator rend() { return reverse_iterator(begin()); }
        const_reverse_iterator rbegin() const { return const_reverse_iterator(end()); }
        const_reverse_iterator rend() const { return const_reverse_iterator(begin()); }

        T& first() { ASSERT(m_start != m_end); return m_buffer.buffer()[m_start]; }
        const T& first() const { ASSERT(m_start != m_end); return m_buffer.buffer()[m_start]; }
        PassType takeFirst();

        T& last() { ASSERT(m_start != m_end); return *(--end()); }
        const T& last() const { ASSERT(m_start != m_end); return *(--end()); }
        PassType takeLast();

        T& at(size_t i)
        {
            RELEASE_ASSERT(i < size());
            size_t right = m_buffer.capacity() - m_start;
            return i < right ? m_buffer.buffer()[m_start + i] : m_buffer.buffer()[i - right];
        }
        const T& at(size_t i) const
        {
            RELEASE_ASSERT(i < size());
            size_t right = m_buffer.capacity() - m_start;
            return i < right ? m_buffer.buffer()[m_start + i] : m_buffer.buffer()[i - right];
        }

        T& operator[](size_t i) { return at(i); }
        const T& operator[](size_t i) const { return at(i); }

        template<typename U> void append(const U&);
        template<typename U> void prepend(const U&);
        void removeFirst();
        void removeLast();
        void remove(iterator&);
        void remove(const_iterator&);

        void clear();

        template<typename Predicate>
        iterator findIf(Predicate&);

        void trace(typename Allocator::Visitor*);

    private:
        friend class DequeIteratorBase<T, inlineCapacity, Allocator>;

        typedef VectorBuffer<T, inlineCapacity, Allocator> Buffer;
        typedef VectorTypeOperations<T> TypeOperations;
        typedef DequeIteratorBase<T, inlineCapacity, Allocator> IteratorBase;

        void remove(size_t position);
        void destroyAll();
        void expandCapacityIfNeeded();
        void expandCapacity();

        Buffer m_buffer;
        unsigned m_start;
        unsigned m_end;
    };

    template<typename T, size_t inlineCapacity, typename Allocator>
    class DequeIteratorBase {
    protected:
        DequeIteratorBase();
        DequeIteratorBase(const Deque<T, inlineCapacity, Allocator>*, size_t);
        DequeIteratorBase(const DequeIteratorBase&);
        DequeIteratorBase<T, 0, Allocator>& operator=(const DequeIteratorBase<T, 0, Allocator>&);
        ~DequeIteratorBase();

        void assign(const DequeIteratorBase& other) { *this = other; }

        void increment();
        void decrement();

        T* before() const;
        T* after() const;

        bool isEqual(const DequeIteratorBase&) const;

    private:
        Deque<T, inlineCapacity, Allocator>* m_deque;
        unsigned m_index;

        friend class Deque<T, inlineCapacity, Allocator>;
    };

    template<typename T, size_t inlineCapacity = 0, typename Allocator = DefaultAllocator>
    class DequeIterator : public DequeIteratorBase<T, inlineCapacity, Allocator> {
    private:
        typedef DequeIteratorBase<T, inlineCapacity, Allocator> Base;
        typedef DequeIterator<T, inlineCapacity, Allocator> Iterator;

    public:
        typedef ptrdiff_t difference_type;
        typedef T value_type;
        typedef T* pointer;
        typedef T& reference;
        typedef std::bidirectional_iterator_tag iterator_category;

        DequeIterator(Deque<T, inlineCapacity, Allocator>* deque, size_t index) : Base(deque, index) { }

        DequeIterator(const Iterator& other) : Base(other) { }
        DequeIterator& operator=(const Iterator& other) { Base::assign(other); return *this; }

        T& operator*() const { return *Base::after(); }
        T* operator->() const { return Base::after(); }

        bool operator==(const Iterator& other) const { return Base::isEqual(other); }
        bool operator!=(const Iterator& other) const { return !Base::isEqual(other); }

        Iterator& operator++() { Base::increment(); return *this; }
        // postfix ++ intentionally omitted
        Iterator& operator--() { Base::decrement(); return *this; }
        // postfix -- intentionally omitted
    };

    template<typename T, size_t inlineCapacity = 0, typename Allocator = DefaultAllocator>
    class DequeConstIterator : public DequeIteratorBase<T, inlineCapacity, Allocator> {
    private:
        typedef DequeIteratorBase<T, inlineCapacity, Allocator> Base;
        typedef DequeConstIterator<T, inlineCapacity, Allocator> Iterator;
        typedef DequeIterator<T, inlineCapacity, Allocator> NonConstIterator;

    public:
        typedef ptrdiff_t difference_type;
        typedef T value_type;
        typedef const T* pointer;
        typedef const T& reference;
        typedef std::bidirectional_iterator_tag iterator_category;

        DequeConstIterator(const Deque<T, inlineCapacity, Allocator>* deque, size_t index) : Base(deque, index) { }

        DequeConstIterator(const Iterator& other) : Base(other) { }
        DequeConstIterator(const NonConstIterator& other) : Base(other) { }
        DequeConstIterator& operator=(const Iterator& other) { Base::assign(other); return *this; }
        DequeConstIterator& operator=(const NonConstIterator& other) { Base::assign(other); return *this; }

        const T& operator*() const { return *Base::after(); }
        const T* operator->() const { return Base::after(); }

        bool operator==(const Iterator& other) const { return Base::isEqual(other); }
        bool operator!=(const Iterator& other) const { return !Base::isEqual(other); }

        Iterator& operator++() { Base::increment(); return *this; }
        // postfix ++ intentionally omitted
        Iterator& operator--() { Base::decrement(); return *this; }
        // postfix -- intentionally omitted
    };

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline Deque<T, inlineCapacity, Allocator>::Deque()
        : m_start(0)
        , m_end(0)
    {
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline Deque<T, inlineCapacity, Allocator>::Deque(const Deque<T, inlineCapacity, Allocator>& other)
        : m_buffer(other.m_buffer.capacity())
        , m_start(other.m_start)
        , m_end(other.m_end)
    {
        const T* otherBuffer = other.m_buffer.buffer();
        if (m_start <= m_end)
            TypeOperations::uninitializedCopy(otherBuffer + m_start, otherBuffer + m_end, m_buffer.buffer() + m_start);
        else {
            TypeOperations::uninitializedCopy(otherBuffer, otherBuffer + m_end, m_buffer.buffer());
            TypeOperations::uninitializedCopy(otherBuffer + m_start, otherBuffer + m_buffer.capacity(), m_buffer.buffer() + m_start);
        }
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline Deque<T, 0, Allocator>& Deque<T, inlineCapacity, Allocator>::operator=(const Deque& other)
    {
        Deque<T> copy(other);
        swap(copy);
        return *this;
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline void Deque<T, inlineCapacity, Allocator>::destroyAll()
    {
        if (m_start <= m_end) {
            TypeOperations::destruct(m_buffer.buffer() + m_start, m_buffer.buffer() + m_end);
            m_buffer.clearUnusedSlots(m_buffer.buffer() + m_start, m_buffer.buffer() + m_end);
        } else {
            TypeOperations::destruct(m_buffer.buffer(), m_buffer.buffer() + m_end);
            m_buffer.clearUnusedSlots(m_buffer.buffer(), m_buffer.buffer() + m_end);
            TypeOperations::destruct(m_buffer.buffer() + m_start, m_buffer.buffer() + m_buffer.capacity());
            m_buffer.clearUnusedSlots(m_buffer.buffer() + m_start, m_buffer.buffer() + m_buffer.capacity());
        }
    }

    // Off-GC-heap deques: Destructor should be called.
    // On-GC-heap deques: Destructor should be called for inline buffers
    // (if any) but destructor shouldn't be called for vector backing since
    // it is managed by the traced GC heap.
    template<typename T, size_t inlineCapacity, typename Allocator>
    inline void Deque<T, inlineCapacity, Allocator>::finalize()
    {
        if (!inlineCapacity && !m_buffer.buffer())
            return;
        if (!isEmpty() && !(Allocator::isGarbageCollected && m_buffer.hasOutOfLineBuffer()))
            destroyAll();

        m_buffer.destruct();
    }

    // FIXME: Doesn't work if there is an inline buffer, due to crbug.com/360572
    template<typename T, size_t inlineCapacity, typename Allocator>
    inline void Deque<T, inlineCapacity, Allocator>::swap(Deque<T, 0, Allocator>& other)
    {
        std::swap(m_start, other.m_start);
        std::swap(m_end, other.m_end);
        m_buffer.swapVectorBuffer(other.m_buffer);
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline void Deque<T, inlineCapacity, Allocator>::clear()
    {
        destroyAll();
        m_start = 0;
        m_end = 0;
        m_buffer.deallocateBuffer(m_buffer.buffer());
        m_buffer.resetBufferPointer();
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    template<typename Predicate>
    inline DequeIterator<T, inlineCapacity, Allocator> Deque<T, inlineCapacity, Allocator>::findIf(Predicate& predicate)
    {
        iterator end_iterator = end();
        for (iterator it = begin(); it != end_iterator; ++it) {
            if (predicate(*it))
                return it;
        }
        return end_iterator;
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline void Deque<T, inlineCapacity, Allocator>::expandCapacityIfNeeded()
    {
        if (m_start) {
            if (m_end + 1 != m_start)
                return;
        } else if (m_end) {
            if (m_end != m_buffer.capacity() - 1)
                return;
        } else if (m_buffer.capacity())
            return;

        expandCapacity();
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    void Deque<T, inlineCapacity, Allocator>::expandCapacity()
    {
        size_t oldCapacity = m_buffer.capacity();
        T* oldBuffer = m_buffer.buffer();
        m_buffer.allocateBuffer(std::max(static_cast<size_t>(16), oldCapacity + oldCapacity / 4 + 1));
        if (m_start <= m_end)
            TypeOperations::move(oldBuffer + m_start, oldBuffer + m_end, m_buffer.buffer() + m_start);
        else {
            TypeOperations::move(oldBuffer, oldBuffer + m_end, m_buffer.buffer());
            size_t newStart = m_buffer.capacity() - (oldCapacity - m_start);
            TypeOperations::move(oldBuffer + m_start, oldBuffer + oldCapacity, m_buffer.buffer() + newStart);
            m_start = newStart;
        }
        m_buffer.deallocateBuffer(oldBuffer);
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline typename Deque<T, inlineCapacity, Allocator>::PassType Deque<T, inlineCapacity, Allocator>::takeFirst()
    {
        T oldFirst = Pass::transfer(first());
        removeFirst();
        return Pass::transfer(oldFirst);
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline typename Deque<T, inlineCapacity, Allocator>::PassType Deque<T, inlineCapacity, Allocator>::takeLast()
    {
        T oldLast = Pass::transfer(last());
        removeLast();
        return Pass::transfer(oldLast);
    }

    template<typename T, size_t inlineCapacity, typename Allocator> template<typename U>
    inline void Deque<T, inlineCapacity, Allocator>::append(const U& value)
    {
        expandCapacityIfNeeded();
        new (NotNull, &m_buffer.buffer()[m_end]) T(value);
        if (m_end == m_buffer.capacity() - 1)
            m_end = 0;
        else
            ++m_end;
    }

    template<typename T, size_t inlineCapacity, typename Allocator> template<typename U>
    inline void Deque<T, inlineCapacity, Allocator>::prepend(const U& value)
    {
        expandCapacityIfNeeded();
        if (!m_start)
            m_start = m_buffer.capacity() - 1;
        else
            --m_start;
        new (NotNull, &m_buffer.buffer()[m_start]) T(value);
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline void Deque<T, inlineCapacity, Allocator>::removeFirst()
    {
        ASSERT(!isEmpty());
        TypeOperations::destruct(&m_buffer.buffer()[m_start], &m_buffer.buffer()[m_start + 1]);
        m_buffer.clearUnusedSlots(&m_buffer.buffer()[m_start], &m_buffer.buffer()[m_start + 1]);
        if (m_start == m_buffer.capacity() - 1)
            m_start = 0;
        else
            ++m_start;
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline void Deque<T, inlineCapacity, Allocator>::removeLast()
    {
        ASSERT(!isEmpty());
        if (!m_end)
            m_end = m_buffer.capacity() - 1;
        else
            --m_end;
        TypeOperations::destruct(&m_buffer.buffer()[m_end], &m_buffer.buffer()[m_end + 1]);
        m_buffer.clearUnusedSlots(&m_buffer.buffer()[m_end], &m_buffer.buffer()[m_end + 1]);
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline void Deque<T, inlineCapacity, Allocator>::remove(iterator& it)
    {
        remove(it.m_index);
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline void Deque<T, inlineCapacity, Allocator>::remove(const_iterator& it)
    {
        remove(it.m_index);
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline void Deque<T, inlineCapacity, Allocator>::remove(size_t position)
    {
        if (position == m_end)
            return;

        T* buffer = m_buffer.buffer();
        TypeOperations::destruct(&buffer[position], &buffer[position + 1]);

        // Find which segment of the circular buffer contained the remove element, and only move elements in that part.
        if (position >= m_start) {
            TypeOperations::moveOverlapping(buffer + m_start, buffer + position, buffer + m_start + 1);
            m_buffer.clearUnusedSlots(buffer + m_start, buffer + m_start + 1);
            m_start = (m_start + 1) % m_buffer.capacity();
        } else {
            TypeOperations::moveOverlapping(buffer + position + 1, buffer + m_end, buffer + position);
            m_buffer.clearUnusedSlots(buffer + m_end - 1, buffer + m_end);
            m_end = (m_end - 1 + m_buffer.capacity()) % m_buffer.capacity();
        }
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline DequeIteratorBase<T, inlineCapacity, Allocator>::DequeIteratorBase()
        : m_deque(0)
    {
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline DequeIteratorBase<T, inlineCapacity, Allocator>::DequeIteratorBase(const Deque<T, inlineCapacity, Allocator>* deque, size_t index)
        : m_deque(const_cast<Deque<T, inlineCapacity, Allocator>*>(deque))
        , m_index(index)
    {
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline DequeIteratorBase<T, inlineCapacity, Allocator>::DequeIteratorBase(const DequeIteratorBase& other)
        : m_deque(other.m_deque)
        , m_index(other.m_index)
    {
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline DequeIteratorBase<T, 0, Allocator>& DequeIteratorBase<T, inlineCapacity, Allocator>::operator=(const DequeIteratorBase<T, 0, Allocator>& other)
    {
        m_deque = other.m_deque;
        m_index = other.m_index;
        return *this;
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline DequeIteratorBase<T, inlineCapacity, Allocator>::~DequeIteratorBase()
    {
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline bool DequeIteratorBase<T, inlineCapacity, Allocator>::isEqual(const DequeIteratorBase& other) const
    {
        return m_index == other.m_index;
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline void DequeIteratorBase<T, inlineCapacity, Allocator>::increment()
    {
        ASSERT(m_index != m_deque->m_end);
        ASSERT(m_deque->m_buffer.capacity());
        if (m_index == m_deque->m_buffer.capacity() - 1)
            m_index = 0;
        else
            ++m_index;
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline void DequeIteratorBase<T, inlineCapacity, Allocator>::decrement()
    {
        ASSERT(m_index != m_deque->m_start);
        ASSERT(m_deque->m_buffer.capacity());
        if (!m_index)
            m_index = m_deque->m_buffer.capacity() - 1;
        else
            --m_index;
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline T* DequeIteratorBase<T, inlineCapacity, Allocator>::after() const
    {
        ASSERT(m_index != m_deque->m_end);
        return &m_deque->m_buffer.buffer()[m_index];
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline T* DequeIteratorBase<T, inlineCapacity, Allocator>::before() const
    {
        ASSERT(m_index != m_deque->m_start);
        if (!m_index)
            return &m_deque->m_buffer.buffer()[m_deque->m_buffer.capacity() - 1];
        return &m_deque->m_buffer.buffer()[m_index - 1];
    }

    // This is only called if the allocator is a HeapAllocator. It is used when
    // visiting during a tracing GC.
    template<typename T, size_t inlineCapacity, typename Allocator>
    void Deque<T, inlineCapacity, Allocator>::trace(typename Allocator::Visitor* visitor)
    {
        ASSERT(Allocator::isGarbageCollected); // Garbage collector must be enabled.
        const T* bufferBegin = m_buffer.buffer();
        const T* end = bufferBegin + m_end;
        if (ShouldBeTraced<VectorTraits<T> >::value) {
            if (m_start <= m_end) {
                for (const T* bufferEntry = bufferBegin + m_start; bufferEntry != end; bufferEntry++)
                    Allocator::template trace<T, VectorTraits<T> >(visitor, *const_cast<T*>(bufferEntry));
            } else {
                for (const T* bufferEntry = bufferBegin; bufferEntry != end; bufferEntry++)
                    Allocator::template trace<T, VectorTraits<T> >(visitor, *const_cast<T*>(bufferEntry));
                const T* bufferEnd = m_buffer.buffer() + m_buffer.capacity();
                for (const T* bufferEntry = bufferBegin + m_start; bufferEntry != bufferEnd; bufferEntry++)
                    Allocator::template trace<T, VectorTraits<T> >(visitor, *const_cast<T*>(bufferEntry));
            }
        }
        if (m_buffer.hasOutOfLineBuffer())
            Allocator::markNoTracing(visitor, m_buffer.buffer());
    }

    template<typename T, size_t inlineCapacity, typename Allocator>
    inline void swap(Deque<T, inlineCapacity, Allocator>& a, Deque<T, inlineCapacity, Allocator>& b)
    {
        a.swap(b);
    }

#if !ENABLE(OILPAN)
    template<typename T, size_t N>
    struct NeedsTracing<Deque<T, N> > {
        static const bool value = false;
    };
#endif

} // namespace WTF

using WTF::Deque;

#endif // WTF_Deque_h
