/*
 * Copyright (C) 2009 Apple Inc. All rights reserved.
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

#ifndef Int16Array_h
#define Int16Array_h

#include "wtf/IntegralTypedArrayBase.h"

namespace WTF {

class ArrayBuffer;

class Int16Array final : public IntegralTypedArrayBase<short> {
public:
    static inline PassRefPtr<Int16Array> create(unsigned length);
    static inline PassRefPtr<Int16Array> create(const short* array, unsigned length);
    static inline PassRefPtr<Int16Array> create(PassRefPtr<ArrayBuffer>, unsigned byteOffset, unsigned length);

    // Should only be used when it is known the entire array will be filled. Do
    // not return these results directly to JavaScript without filling first.
    static inline PassRefPtr<Int16Array> createUninitialized(unsigned length);

    using TypedArrayBase<short>::set;
    using IntegralTypedArrayBase<short>::set;

    inline PassRefPtr<Int16Array> subarray(int start) const;
    inline PassRefPtr<Int16Array> subarray(int start, int end) const;

    virtual ViewType type() const override
    {
        return TypeInt16;
    }

private:
    inline Int16Array(PassRefPtr<ArrayBuffer>,
                    unsigned byteOffset,
                    unsigned length);
    // Make constructor visible to superclass.
    friend class TypedArrayBase<short>;
};

PassRefPtr<Int16Array> Int16Array::create(unsigned length)
{
    return TypedArrayBase<short>::create<Int16Array>(length);
}

PassRefPtr<Int16Array> Int16Array::create(const short* array, unsigned length)
{
    return TypedArrayBase<short>::create<Int16Array>(array, length);
}

PassRefPtr<Int16Array> Int16Array::create(PassRefPtr<ArrayBuffer> buffer, unsigned byteOffset, unsigned length)
{
    return TypedArrayBase<short>::create<Int16Array>(buffer, byteOffset, length);
}

PassRefPtr<Int16Array> Int16Array::createUninitialized(unsigned length)
{
    return TypedArrayBase<short>::createUninitialized<Int16Array>(length);
}

Int16Array::Int16Array(PassRefPtr<ArrayBuffer> buffer, unsigned byteOffset, unsigned length)
    : IntegralTypedArrayBase<short>(buffer, byteOffset, length)
{
}

PassRefPtr<Int16Array> Int16Array::subarray(int start) const
{
    return subarray(start, length());
}

PassRefPtr<Int16Array> Int16Array::subarray(int start, int end) const
{
    return subarrayImpl<Int16Array>(start, end);
}

} // namespace WTF

using WTF::Int16Array;

#endif // Int16Array_h
