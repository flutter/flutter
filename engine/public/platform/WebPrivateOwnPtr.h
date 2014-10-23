/*
 * Copyright (C) 2010 Google Inc. All rights reserved.
 * Copyright (C) 2013 Intel Corporation. All rights reserved.
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

#ifndef WebPrivateOwnPtr_h
#define WebPrivateOwnPtr_h

#include "WebCommon.h"
#include "WebNonCopyable.h"

#if INSIDE_BLINK
#include "wtf/PassOwnPtr.h"
#endif

namespace blink {

// This class is an implementation detail of the WebKit API.  It exists
// to help simplify the implementation of WebKit interfaces that merely
// wrap a pointer to a WebCore class. It's similar to WebPrivatePtr, but it
// wraps a naked pointer rather than a reference counted.
// Note: you must call reset(0) on the implementation side in order to delete
// the WebCore pointer.
template <typename T>
class WebPrivateOwnPtr : public WebNonCopyable {
public:
    WebPrivateOwnPtr() : m_ptr(0) {}
    ~WebPrivateOwnPtr() { BLINK_ASSERT(!m_ptr); }

    explicit WebPrivateOwnPtr(T* ptr)
        : m_ptr(ptr)
    {
    }

    T* get() const { return m_ptr; }

#if INSIDE_BLINK
    template<typename U> WebPrivateOwnPtr(const PassOwnPtr<U>&, EnsurePtrConvertibleArgDecl(U, T));

    void reset(T* ptr)
    {
        delete m_ptr;
        m_ptr = ptr;
    }

    void reset(const PassOwnPtr<T>& o)
    {
        reset(o.leakPtr());
    }

    PassOwnPtr<T> release()
    {
        T* ptr = m_ptr;
        m_ptr = 0;
        return adoptPtr(ptr);
    }

    T* operator->() const
    {
        BLINK_ASSERT(m_ptr);
        return m_ptr;
    }
#endif // INSIDE_BLINK

private:
    T* m_ptr;
};

#if INSIDE_BLINK
template<typename T> template<typename U> inline WebPrivateOwnPtr<T>::WebPrivateOwnPtr(const PassOwnPtr<U>& o, EnsurePtrConvertibleArgDefn(U, T))
    : m_ptr(o.leakPtr())
{
    COMPILE_ASSERT(!WTF::IsArray<T>::value, Pointers_to_array_must_never_be_converted);
}
#endif

} // namespace blink

#endif
