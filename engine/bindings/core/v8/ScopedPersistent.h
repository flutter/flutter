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

#ifndef ScopedPersistent_h
#define ScopedPersistent_h

#include "wtf/Noncopyable.h"
#include <v8.h>

namespace blink {

template<typename T>
class ScopedPersistent {
    WTF_MAKE_NONCOPYABLE(ScopedPersistent);
public:
    ScopedPersistent() { }

    ScopedPersistent(v8::Isolate* isolate, v8::Handle<T> handle)
        : m_handle(isolate, handle)
    {
    }

    ~ScopedPersistent()
    {
        clear();
    }

    ALWAYS_INLINE v8::Local<T> newLocal(v8::Isolate* isolate) const
    {
        return v8::Local<T>::New(isolate, m_handle);
    }

    template<typename P>
    void setWeak(P* parameters, void (*callback)(const v8::WeakCallbackData<T, P>&))
    {
        m_handle.SetWeak(parameters, callback);
    }

    bool isEmpty() const { return m_handle.IsEmpty(); }
    bool isWeak() const { return m_handle.IsWeak(); }

    void set(v8::Isolate* isolate, v8::Handle<T> handle)
    {
        m_handle.Reset(isolate, handle);
    }

    // Note: This is clear in the OwnPtr sense, not the v8::Handle sense.
    void clear()
    {
        m_handle.Reset();
    }

    bool operator==(const ScopedPersistent<T>& other)
    {
        return m_handle == other.m_handle;
    }

    template <class S>
    bool operator==(const v8::Handle<S> other) const
    {
        return m_handle == other;
    }

private:
    // FIXME: This function does an unsafe handle access. Remove it.
    friend class V8AbstractEventListener;
    friend class V8PerIsolateData;
    ALWAYS_INLINE v8::Persistent<T>& getUnsafe()
    {
        return m_handle;
    }

    v8::Persistent<T> m_handle;
};

} // namespace blink

#endif // ScopedPersistent_h
