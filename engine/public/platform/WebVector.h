/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

#ifndef WebVector_h
#define WebVector_h

#include "WebCommon.h"

#include <algorithm>
#include <limits>
#include <stdlib.h>

namespace blink {

// A simple vector class.
//
// Sample usage:
//
//   void Foo(WebVector<int>& result)
//   {
//       WebVector<int> data(10);
//       for (size_t i = 0; i < data.size(); ++i)
//           data[i] = ...
//       result.swap(data);
//   }
//
// It is also possible to assign from other types of random access
// containers:
//
//   void Foo(const std::vector<std::string>& input)
//   {
//       WebVector<WebCString> cstrings = input;
//       ...
//   }
//
template <typename T>
class WebVector {
public:
    typedef T ValueType;

    ~WebVector()
    {
        destroy();
    }

    explicit WebVector(size_t size = 0)
    {
        initialize(size);
    }

    template <typename U>
    WebVector(const U* values, size_t size)
    {
        initializeFrom(values, size);
    }

    WebVector(const WebVector<T>& other)
    {
        initializeFrom(other.m_ptr, other.m_size);
    }

    template <typename C>
    WebVector(const C& other)
    {
        initializeFrom(other.size() ? &other[0] : 0, other.size());
    }

    WebVector& operator=(const WebVector& other)
    {
        if (this != &other)
            assign(other);
        return *this;
    }

    template <typename C>
    WebVector<T>& operator=(const C& other)
    {
        if (this != reinterpret_cast<const WebVector<T>*>(&other))
            assign(other);
        return *this;
    }

    template <typename C>
    void assign(const C& other)
    {
        assign(other.size() ? &other[0] : 0, other.size());
    }

    template <typename U>
    void assign(const U* values, size_t size)
    {
        destroy();
        initializeFrom(values, size);
    }

    size_t size() const { return m_size; }
    bool isEmpty() const { return !m_size; }

    T& operator[](size_t i)
    {
        BLINK_ASSERT(i < m_size);
        return m_ptr[i];
    }
    const T& operator[](size_t i) const
    {
        BLINK_ASSERT(i < m_size);
        return m_ptr[i];
    }

    bool contains(const T& value) const
    {
        for (size_t i = 0; i < m_size; i++) {
            if (m_ptr[i] == value)
                return true;
        }
        return false;
    }

    T* data() { return m_ptr; }
    const T* data() const { return m_ptr; }

    void swap(WebVector<T>& other)
    {
        std::swap(m_ptr, other.m_ptr);
        std::swap(m_size, other.m_size);
    }

private:
    void initialize(size_t size)
    {
        validateSize(size);
        m_size = size;
        if (!m_size)
            m_ptr = 0;
        else {
            m_ptr = static_cast<T*>(::operator new(sizeof(T) * m_size));
            for (size_t i = 0; i < m_size; ++i)
                new (&m_ptr[i]) T();
        }
    }

    template <typename U>
    void initializeFrom(const U* values, size_t size)
    {
        validateSize(size);
        m_size = size;
        if (!m_size)
            m_ptr = 0;
        else {
            m_ptr = static_cast<T*>(::operator new(sizeof(T) * m_size));
            for (size_t i = 0; i < m_size; ++i)
                new (&m_ptr[i]) T(values[i]);
        }
    }

    void validateSize(size_t size)
    {
        if (std::numeric_limits<size_t>::max() / sizeof(T) < size)
            abort();
    }

    void destroy()
    {
        for (size_t i = 0; i < m_size; ++i)
            m_ptr[i].~T();
        ::operator delete(m_ptr);
    }

    T* m_ptr;
    size_t m_size;
};

} // namespace blink

#endif
