/*
 * Copyright (C) 2010 Apple Inc. All rights reserved.
 * Copyright (c) 2010, Google Inc. All rights reserved.
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

#ifndef IntegralTypedArrayBase_h
#define IntegralTypedArrayBase_h

#include "wtf/TypedArrayBase.h"
#include <limits>
#include "wtf/MathExtras.h"

// Base class for all WebGL<T>Array types holding integral
// (non-floating-point) values.

namespace WTF {

template <typename T>
class IntegralTypedArrayBase : public TypedArrayBase<T> {
  public:
    void set(unsigned index, double value)
    {
        if (index >= TypedArrayBase<T>::m_length)
            return;
        if (std::isnan(value)) // Clamp NaN to 0
            value = 0;
        // The double cast is necessary to get the correct wrapping
        // for out-of-range values with Int32Array and Uint32Array.
        TypedArrayBase<T>::data()[index] = static_cast<T>(static_cast<int64_t>(value));
    }

  protected:
    IntegralTypedArrayBase(PassRefPtr<ArrayBuffer> buffer, unsigned byteOffset, unsigned length)
        : TypedArrayBase<T>(buffer, byteOffset, length)
    {
    }
};

} // namespace WTF

using WTF::IntegralTypedArrayBase;

#endif // IntegralTypedArrayBase_h
