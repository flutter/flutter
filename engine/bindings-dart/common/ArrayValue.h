/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
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

#include "bindings/common/AbstractArrayValue.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"

namespace blink {

class Dictionary;

class ArrayValue {
public:
    ArrayValue() : m_arrayValueImpl() { }
    explicit ArrayValue(PassRefPtr<AbstractArrayValue> impl) : m_arrayValueImpl(impl) { }

    bool isUndefinedOrNull() const
    {
        return !m_arrayValueImpl || m_arrayValueImpl->isUndefinedOrNull();
    }

    bool length(size_t& length) const
    {
        if (!m_arrayValueImpl)
            return false;
        return m_arrayValueImpl->length(length);
    }

    bool get(size_t index, Dictionary& value) const
    {
        if (!m_arrayValueImpl)
            return false;
        return m_arrayValueImpl->get(index, value);
    }

private:
    RefPtr<AbstractArrayValue> m_arrayValueImpl;

    // Disallow heap allocation. Only valid to use this object within a handle scope.
    static void* operator new(size_t);
    static void* operator new[](size_t);
    static void operator delete(void *);
};

}

#endif // ArrayValue_h
