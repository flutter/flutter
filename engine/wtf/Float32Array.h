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

#ifndef Float32Array_h
#define Float32Array_h

#include "wtf/TypedArrayBase.h"
#include "wtf/MathExtras.h"

namespace WTF {

class Float32Array final : public TypedArrayBase<float> {
public:
    static inline PassRefPtr<Float32Array> create(unsigned length);
    static inline PassRefPtr<Float32Array> create(const float* array, unsigned length);
    static inline PassRefPtr<Float32Array> create(PassRefPtr<ArrayBuffer>, unsigned byteOffset, unsigned length);

    // Should only be used when it is known the entire array will be filled. Do
    // not return these results directly to JavaScript without filling first.
    static inline PassRefPtr<Float32Array> createUninitialized(unsigned length);

    using TypedArrayBase<float>::set;

    void set(unsigned index, double value)
    {
        if (index >= TypedArrayBase<float>::m_length)
            return;
        TypedArrayBase<float>::data()[index] = static_cast<float>(value);
    }

    inline PassRefPtr<Float32Array> subarray(int start) const;
    inline PassRefPtr<Float32Array> subarray(int start, int end) const;

    virtual ViewType type() const override
    {
        return TypeFloat32;
    }

private:
    inline Float32Array(PassRefPtr<ArrayBuffer>,
                    unsigned byteOffset,
                    unsigned length);
    // Make constructor visible to superclass.
    friend class TypedArrayBase<float>;
};

PassRefPtr<Float32Array> Float32Array::create(unsigned length)
{
    return TypedArrayBase<float>::create<Float32Array>(length);
}

PassRefPtr<Float32Array> Float32Array::create(const float* array, unsigned length)
{
    return TypedArrayBase<float>::create<Float32Array>(array, length);
}

PassRefPtr<Float32Array> Float32Array::create(PassRefPtr<ArrayBuffer> buffer, unsigned byteOffset, unsigned length)
{
    return TypedArrayBase<float>::create<Float32Array>(buffer, byteOffset, length);
}

PassRefPtr<Float32Array> Float32Array::createUninitialized(unsigned length)
{
    return TypedArrayBase<float>::createUninitialized<Float32Array>(length);
}

Float32Array::Float32Array(PassRefPtr<ArrayBuffer> buffer, unsigned byteOffset, unsigned length)
    : TypedArrayBase<float>(buffer, byteOffset, length)
{
}

PassRefPtr<Float32Array> Float32Array::subarray(int start) const
{
    return subarray(start, length());
}

PassRefPtr<Float32Array> Float32Array::subarray(int start, int end) const
{
    return subarrayImpl<Float32Array>(start, end);
}

} // namespace WTF

using WTF::Float32Array;

#endif // Float32Array_h
