// Copyright 2010 the V8 project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#ifndef DOUBLE_CONVERSION_CACHED_POWERS_H_
#define DOUBLE_CONVERSION_CACHED_POWERS_H_

#include "diy-fp.h"

namespace WTF {

namespace double_conversion {

    class PowersOfTenCache {
    public:

        // Not all powers of ten are cached. The decimal exponent of two neighboring
        // cached numbers will differ by kDecimalExponentDistance.
        static const int kDecimalExponentDistance;

        static const int kMinDecimalExponent;
        static const int kMaxDecimalExponent;

        // Returns a cached power-of-ten with a binary exponent in the range
        // [min_exponent; max_exponent] (boundaries included).
        static void GetCachedPowerForBinaryExponentRange(int min_exponent,
                                                         int max_exponent,
                                                         DiyFp* power,
                                                         int* decimal_exponent);

        // Returns a cached power of ten x ~= 10^k such that
        //   k <= decimal_exponent < k + kCachedPowersDecimalDistance.
        // The given decimal_exponent must satisfy
        //   kMinDecimalExponent <= requested_exponent, and
        //   requested_exponent < kMaxDecimalExponent + kDecimalExponentDistance.
        static void GetCachedPowerForDecimalExponent(int requested_exponent,
                                                     DiyFp* power,
                                                     int* found_exponent);
    };
}  // namespace double_conversion

} // namespace WTF

#endif  // DOUBLE_CONVERSION_CACHED_POWERS_H_
