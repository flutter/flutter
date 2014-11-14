/*
 * Copyright (C) 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Google Inc. All rights reserved.
 * Copyright (C) 2012 Nokia Corporation and/or its subsidiary(-ies).
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

#ifndef Uint8ClampedArray_h
#define Uint8ClampedArray_h

#include "wtf/Uint8Array.h"
#include "wtf/MathExtras.h"

namespace WTF {

class Uint8ClampedArray final : public Uint8Array {
public:
    static inline PassRefPtr<Uint8ClampedArray> create(unsigned length);
    static inline PassRefPtr<Uint8ClampedArray> create(const unsigned char* array, unsigned length);
    static inline PassRefPtr<Uint8ClampedArray> create(PassRefPtr<ArrayBuffer>, unsigned byteOffset, unsigned length);

    // Should only be used when it is known the entire array will be filled. Do
    // not return these results directly to JavaScript without filling first.
    static inline PassRefPtr<Uint8ClampedArray> createUninitialized(unsigned length);

    // It's only needed to potentially call this method if the array
    // was created uninitialized -- the default initialization paths
    // zero the allocated memory.
    inline void zeroFill();

    using TypedArrayBase<unsigned char>::set;
    inline void set(unsigned index, double value);

    inline PassRefPtr<Uint8ClampedArray> subarray(int start) const;
    inline PassRefPtr<Uint8ClampedArray> subarray(int start, int end) const;

    virtual ViewType type() const override
    {
        return TypeUint8Clamped;
    }

private:
    inline Uint8ClampedArray(PassRefPtr<ArrayBuffer>,
                             unsigned byteOffset,
                             unsigned length);
    // Make constructor visible to superclass.
    friend class TypedArrayBase<unsigned char>;
};

PassRefPtr<Uint8ClampedArray> Uint8ClampedArray::create(unsigned length)
{
    return TypedArrayBase<unsigned char>::create<Uint8ClampedArray>(length);
}

PassRefPtr<Uint8ClampedArray> Uint8ClampedArray::create(const unsigned char* array, unsigned length)
{
    return TypedArrayBase<unsigned char>::create<Uint8ClampedArray>(array, length);
}

PassRefPtr<Uint8ClampedArray> Uint8ClampedArray::create(PassRefPtr<ArrayBuffer> buffer, unsigned byteOffset, unsigned length)
{
    return TypedArrayBase<unsigned char>::create<Uint8ClampedArray>(buffer, byteOffset, length);
}

PassRefPtr<Uint8ClampedArray> Uint8ClampedArray::createUninitialized(unsigned length)
{
    return TypedArrayBase<unsigned char>::createUninitialized<Uint8ClampedArray>(length);
}

void Uint8ClampedArray::zeroFill()
{
    zeroRange(0, length());
}

void Uint8ClampedArray::set(unsigned index, double value)
{
    if (index >= m_length)
        return;
    if (std::isnan(value) || value < 0)
        value = 0;
    else if (value > 255)
        value = 255;
    data()[index] = static_cast<unsigned char>(lrint(value));
}

Uint8ClampedArray::Uint8ClampedArray(PassRefPtr<ArrayBuffer> buffer, unsigned byteOffset, unsigned length)
: Uint8Array(buffer, byteOffset, length)
{
}

PassRefPtr<Uint8ClampedArray> Uint8ClampedArray::subarray(int start) const
{
    return subarray(start, length());
}

PassRefPtr<Uint8ClampedArray> Uint8ClampedArray::subarray(int start, int end) const
{
    return subarrayImpl<Uint8ClampedArray>(start, end);
}

} // namespace WTF

using WTF::Uint8ClampedArray;

#endif // Uint8ClampedArray_h
