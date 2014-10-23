/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#ifndef ArrayValue_h
#define ArrayValue_h

#include "wtf/Assertions.h"
#include <v8.h>

namespace blink {

class Dictionary;

class ArrayValue {
public:
    ArrayValue() : m_isolate(0) { }
    explicit ArrayValue(const v8::Local<v8::Array>& array, v8::Isolate* isolate)
        : m_array(array)
        , m_isolate(isolate)
    {
        ASSERT(m_isolate);
    }
    ~ArrayValue() { }

    ArrayValue& operator=(const ArrayValue&);

    bool isUndefinedOrNull() const;

    bool length(size_t&) const;
    bool get(size_t index, Dictionary&) const;

private:
    // This object can only be used safely when stack allocated because of v8::Local.
    static void* operator new(size_t);
    static void* operator new[](size_t);
    static void operator delete(void *);

    v8::Local<v8::Array> m_array;
    v8::Isolate* m_isolate;
};

}

#endif // ArrayValue_h
