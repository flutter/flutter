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

#ifndef SharedPersistent_h
#define SharedPersistent_h

#include "bindings/core/v8/ScopedPersistent.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"
#include <v8.h>

namespace blink {

template <typename T>
class SharedPersistent : public RefCounted<SharedPersistent<T> > {
WTF_MAKE_NONCOPYABLE(SharedPersistent);
public:
    static PassRefPtr<SharedPersistent<T> > create(v8::Handle<T> value, v8::Isolate* isolate)
    {
        return adoptRef(new SharedPersistent<T>(value, isolate));
    }

    v8::Local<T> newLocal(v8::Isolate* isolate) const
    {
        return m_value.newLocal(isolate);
    }

    bool isEmpty() { return m_value.isEmpty(); }

    bool operator==(const SharedPersistent<T>& other)
    {
        return m_value == other.m_value;
    }

private:
    explicit SharedPersistent(v8::Handle<T> value, v8::Isolate* isolate) : m_value(isolate, value) { }
    ScopedPersistent<T> m_value;
};

} // namespace blink

#endif // SharedPersistent_h
