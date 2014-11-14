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

#ifndef Uint16Array_h
#define Uint16Array_h

#include "wtf/IntegralTypedArrayBase.h"

namespace WTF {

class ArrayBuffer;

class Uint16Array final : public IntegralTypedArrayBase<unsigned short> {
public:
    static inline PassRefPtr<Uint16Array> create(unsigned length);
    static inline PassRefPtr<Uint16Array> create(const unsigned short* array, unsigned length);
    static inline PassRefPtr<Uint16Array> create(PassRefPtr<ArrayBuffer>, unsigned byteOffset, unsigned length);

    // Should only be used when it is known the entire array will be filled. Do
    // not return these results directly to JavaScript without filling first.
    static inline PassRefPtr<Uint16Array> createUninitialized(unsigned length);

    using TypedArrayBase<unsigned short>::set;
    using IntegralTypedArrayBase<unsigned short>::set;

    inline PassRefPtr<Uint16Array> subarray(int start) const;
    inline PassRefPtr<Uint16Array> subarray(int start, int end) const;

    virtual ViewType type() const override
    {
        return TypeUint16;
    }

private:
    inline Uint16Array(PassRefPtr<ArrayBuffer>,
                            unsigned byteOffset,
                            unsigned length);
    // Make constructor visible to superclass.
    friend class TypedArrayBase<unsigned short>;
};

PassRefPtr<Uint16Array> Uint16Array::create(unsigned length)
{
    return TypedArrayBase<unsigned short>::create<Uint16Array>(length);
}

PassRefPtr<Uint16Array> Uint16Array::create(const unsigned short* array, unsigned length)
{
    return TypedArrayBase<unsigned short>::create<Uint16Array>(array, length);
}

PassRefPtr<Uint16Array> Uint16Array::create(PassRefPtr<ArrayBuffer> buffer, unsigned byteOffset, unsigned length)
{
    return TypedArrayBase<unsigned short>::create<Uint16Array>(buffer, byteOffset, length);
}

PassRefPtr<Uint16Array> Uint16Array::createUninitialized(unsigned length)
{
    return TypedArrayBase<unsigned short>::createUninitialized<Uint16Array>(length);
}

Uint16Array::Uint16Array(PassRefPtr<ArrayBuffer> buffer, unsigned byteOffset, unsigned length)
    : IntegralTypedArrayBase<unsigned short>(buffer, byteOffset, length)
{
}

PassRefPtr<Uint16Array> Uint16Array::subarray(int start) const
{
    return subarray(start, length());
}

PassRefPtr<Uint16Array> Uint16Array::subarray(int start, int end) const
{
    return subarrayImpl<Uint16Array>(start, end);
}

} // namespace WTF

using WTF::Uint16Array;

#endif // Uint16Array_h
