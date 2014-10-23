/*
 * Copyright (C) 2007-2009 Google Inc. All rights reserved.
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

#ifndef V8PersistentValueVector_h
#define V8PersistentValueVector_h

#include "wtf/Vector.h"
#include <v8-util.h>
#include <v8.h>

namespace blink {

class WTFVectorPersistentValueVectorTraits {
public:
    typedef Vector<v8::PersistentContainerValue> Impl;
    static void Append(Impl* impl, v8::PersistentContainerValue value)
    {
        impl->append(value);
    }
    static bool IsEmpty(const Impl* impl)
    {
        return impl->isEmpty();
    }
    static size_t Size(const Impl* impl)
    {
        return impl->size();
    }
    static v8::PersistentContainerValue Get(const Impl* impl, size_t i)
    {
        return (i < impl->size()) ? impl->at(i) : v8::kPersistentContainerNotFound;
    }
    static void ReserveCapacity(Impl* impl, size_t capacity)
    {
        impl->reserveCapacity(capacity);
    }
    static void Clear(Impl* impl)
    {
        impl->clear();
    }
};

template<class ValueType>
class V8PersistentValueVector : public v8::PersistentValueVector<ValueType, WTFVectorPersistentValueVectorTraits> {
public:
    explicit V8PersistentValueVector(v8::Isolate* isolate) : v8::PersistentValueVector<ValueType, WTFVectorPersistentValueVectorTraits>(isolate) { }
};

} // namespace blink

#endif // V8PersistentValueVector_h
