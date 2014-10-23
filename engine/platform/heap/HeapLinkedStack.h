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

#ifndef HeapLinkedStack_h
#define HeapLinkedStack_h

#include "platform/heap/Heap.h"
#include "platform/heap/Visitor.h"

namespace blink {

template <typename T>
class HeapLinkedStack : public GarbageCollected<HeapLinkedStack<T> > {
public:
    HeapLinkedStack() : m_size(0) { }

    bool isEmpty();

    void push(const T&);
    const T& peek();
    void pop();

    size_t size();

    void trace(Visitor* visitor)
    {
        for (Node* current = m_head; current; current = current->m_next)
            visitor->trace(current);
    }

private:
    class Node : public GarbageCollected<Node> {
    public:
        Node(const T&, Node* next);

        void trace(Visitor* visitor) { visitor->trace(m_data); }

        T m_data;
        Member<Node> m_next;
    };

    Member<Node> m_head;
    size_t m_size;
};

template <typename T>
HeapLinkedStack<T>::Node::Node(const T& data, Node* next)
    : m_data(data)
    , m_next(next)
{
}

template <typename T>
inline bool HeapLinkedStack<T>::isEmpty()
{
    return !m_head;
}

template <typename T>
inline void HeapLinkedStack<T>::push(const T& data)
{
    m_head = new Node(data, m_head);
    ++m_size;
}

template <typename T>
inline const T& HeapLinkedStack<T>::peek()
{
    return m_head->m_data;
}

template <typename T>
inline void HeapLinkedStack<T>::pop()
{
    ASSERT(m_head && m_size);
    m_head = m_head->m_next;
    --m_size;
}

template <typename T>
inline size_t HeapLinkedStack<T>::size()
{
    return m_size;
}

}

#endif // HeapLinkedStack_h
