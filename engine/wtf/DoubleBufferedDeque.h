// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef DoubleBufferedDeque_h
#define DoubleBufferedDeque_h

#include "wtf/Deque.h"
#include "wtf/Noncopyable.h"

namespace WTF {

// A helper class for managing double buffered deques, typically where the client locks when appending or swapping.
template <typename T> class DoubleBufferedDeque {
    WTF_MAKE_NONCOPYABLE(DoubleBufferedDeque);
public:
    DoubleBufferedDeque()
        : m_activeIndex(0) { }

    void append(const T& value)
    {
        m_queue[m_activeIndex].append(value);
    }

    bool isEmpty() const
    {
        return m_queue[m_activeIndex].isEmpty();
    }

    Deque<T>& swapBuffers()
    {
        int oldIndex = m_activeIndex;
        m_activeIndex ^= 1;
        ASSERT(m_queue[m_activeIndex].isEmpty());
        return m_queue[oldIndex];
    }

private:
    Deque<T> m_queue[2];
    int m_activeIndex;
};

} // namespace WTF

using WTF::DoubleBufferedDeque;

#endif // DoubleBufferedDeque_h
