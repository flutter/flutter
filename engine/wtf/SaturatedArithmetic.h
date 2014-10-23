/*
 * Copyright (c) 2012, Google Inc. All rights reserved.
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

#ifndef SaturatedArithmetic_h
#define SaturatedArithmetic_h

#include "wtf/CPU.h"
#include <limits>
#include <stdint.h>

#if CPU(ARM) && COMPILER(GCC) && __OPTIMIZE__

// If we're building ARM on GCC we replace the C++ versions with some
// native ARM assembly for speed.
#include "wtf/asm/SaturatedArithmeticARM.h"

#else

ALWAYS_INLINE int32_t saturatedAddition(int32_t a, int32_t b)
{
    uint32_t ua = a;
    uint32_t ub = b;
    uint32_t result = ua + ub;

    // Can only overflow if the signed bit of the two values match. If the
    // signed bit of the result and one of the values differ it overflowed.

    if (~(ua ^ ub) & (result ^ ua) & (1 << 31))
        return std::numeric_limits<int>::max() + (ua >> 31);

    return result;
}

ALWAYS_INLINE int32_t saturatedSubtraction(int32_t a, int32_t b)
{
    uint32_t ua = a;
    uint32_t ub = b;
    uint32_t result = ua - ub;

    // Can only overflow if the signed bit of the two input values differ. If
    // the signed bit of the result and the first value differ it overflowed.

    if ((ua ^ ub) & (result ^ ua) & (1 << 31))
        return std::numeric_limits<int>::max() + (ua >> 31);

    return result;
}

inline int getMaxSaturatedSetResultForTesting(int FractionalShift)
{
    // For C version the set function maxes out to max int, this differs from
    // the ARM asm version, see SaturatedArithmetiARM.h for the equivalent asm
    // version.
    return std::numeric_limits<int>::max();
}

inline int getMinSaturatedSetResultForTesting(int FractionalShift)
{
    return std::numeric_limits<int>::min();
}

ALWAYS_INLINE int saturatedSet(int value, int FractionalShift)
{
    const int intMaxForLayoutUnit =
        std::numeric_limits<int>::max() >> FractionalShift;

    const int intMinForLayoutUnit =
        std::numeric_limits<int>::min() >> FractionalShift;

    if (value > intMaxForLayoutUnit)
        return std::numeric_limits<int>::max();

    if (value < intMinForLayoutUnit)
        return std::numeric_limits<int>::min();

    return value << FractionalShift;
}


ALWAYS_INLINE int saturatedSet(unsigned value, int FractionalShift)
{
    const unsigned intMaxForLayoutUnit =
        std::numeric_limits<int>::max() >> FractionalShift;

    if (value >= intMaxForLayoutUnit)
        return std::numeric_limits<int>::max();

    return value << FractionalShift;
}

#endif // CPU(ARM) && COMPILER(GCC)
#endif // SaturatedArithmetic_h
