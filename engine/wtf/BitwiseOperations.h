/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

#ifndef WTF_BitwiseOperations_h
#define WTF_BitwiseOperations_h

// DESCRIPTION
// countLeadingZeros() is a bitwise operation that counts the number of leading
// zeros in a binary value, starting with the most significant bit. C does not
// have an operator to do this, but fortunately the various compilers have
// built-ins that map to fast underlying processor instructions.

#include "wtf/CPU.h"
#include "wtf/Compiler.h"

#include <stdint.h>

#if COMPILER(MSVC)
#include <intrin.h>
#endif

namespace WTF {

#if COMPILER(MSVC)

ALWAYS_INLINE uint32_t countLeadingZeros32(uint32_t x)
{
    unsigned long index;
    return LIKELY(_BitScanReverse(&index, x)) ? (31 - index) : 32;
}

#if CPU(64BIT)

// MSVC only supplies _BitScanForward64 when building for a 64-bit target.
ALWAYS_INLINE uint64_t countLeadingZeros64(uint64_t x)
{
    unsigned long index;
    return LIKELY(_BitScanReverse64(&index, x)) ? (63 - index) : 64;
}

#endif

#elif COMPILER(GCC)

// This is very annoying. __builtin_clz has undefined behaviour for an input of
// 0, even though these's clearly a return value that makes sense, and even
// though nascent processor clz instructions have defined behaviour for 0.
// We could drop to raw __asm__ to do better, but we'll avoid doing that unless
// we see proof that we need to.
ALWAYS_INLINE uint32_t countLeadingZeros32(uint32_t x)
{
    return LIKELY(x) ? __builtin_clz(x) : 32;
}

ALWAYS_INLINE uint64_t countLeadingZeros64(uint64_t x)
{
    return LIKELY(x) ? __builtin_clzll(x) : 64;
}

#endif

#if CPU(64BIT)

ALWAYS_INLINE size_t countLeadingZerosSizet(size_t x) { return countLeadingZeros64(x); }

#else

ALWAYS_INLINE size_t countLeadingZerosSizet(size_t x) { return countLeadingZeros32(x); }

#endif

} // namespace WTF

#endif // WTF_BitwiseOperations_h
