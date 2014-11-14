/*
 * Copyright (C) 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef Int32Array_h
#define Int32Array_h

#include "wtf/IntegralTypedArrayBase.h"

namespace WTF {

class Int32Array final : public IntegralTypedArrayBase<int> {
public:
    static inline PassRefPtr<Int32Array> create(unsigned length);
    static inline PassRefPtr<Int32Array> create(const int* array, unsigned length);
    static inline PassRefPtr<Int32Array> create(PassRefPtr<ArrayBuffer>, unsigned byteOffset, unsigned length);

    // Should only be used when it is known the entire array will be filled. Do
    // not return these results directly to JavaScript without filling first.
    static inline PassRefPtr<Int32Array> createUninitialized(unsigned length);

    using TypedArrayBase<int>::set;
    using IntegralTypedArrayBase<int>::set;

    inline PassRefPtr<Int32Array> subarray(int start) const;
    inline PassRefPtr<Int32Array> subarray(int start, int end) const;

    virtual ViewType type() const override
    {
        return TypeInt32;
    }

private:
    inline Int32Array(PassRefPtr<ArrayBuffer>,
                  unsigned byteOffset,
                  unsigned length);
    // Make constructor visible to superclass.
    friend class TypedArrayBase<int>;
};

PassRefPtr<Int32Array> Int32Array::create(unsigned length)
{
    return TypedArrayBase<int>::create<Int32Array>(length);
}

PassRefPtr<Int32Array> Int32Array::create(const int* array, unsigned length)
{
    return TypedArrayBase<int>::create<Int32Array>(array, length);
}

PassRefPtr<Int32Array> Int32Array::create(PassRefPtr<ArrayBuffer> buffer, unsigned byteOffset, unsigned length)
{
    return TypedArrayBase<int>::create<Int32Array>(buffer, byteOffset, length);
}

PassRefPtr<Int32Array> Int32Array::createUninitialized(unsigned length)
{
    return TypedArrayBase<int>::createUninitialized<Int32Array>(length);
}

Int32Array::Int32Array(PassRefPtr<ArrayBuffer> buffer, unsigned byteOffset, unsigned length)
    : IntegralTypedArrayBase<int>(buffer, byteOffset, length)
{
}

PassRefPtr<Int32Array> Int32Array::subarray(int start) const
{
    return subarray(start, length());
}

PassRefPtr<Int32Array> Int32Array::subarray(int start, int end) const
{
    return subarrayImpl<Int32Array>(start, end);
}

} // namespace WTF

using WTF::Int32Array;

#endif // Int32Array_h
