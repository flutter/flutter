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

#ifndef DOUBLE_CONVERSION_DIY_FP_H_
#define DOUBLE_CONVERSION_DIY_FP_H_

#include "utils.h"

namespace WTF {

namespace double_conversion {

    // This "Do It Yourself Floating Point" class implements a floating-point number
    // with a uint64 significand and an int exponent. Normalized DiyFp numbers will
    // have the most significant bit of the significand set.
    // Multiplication and Subtraction do not normalize their results.
    // DiyFp are not designed to contain special doubles (NaN and Infinity).
    class DiyFp {
    public:
        static const int kSignificandSize = 64;

        DiyFp() : f_(0), e_(0) {}
        DiyFp(uint64_t f, int e) : f_(f), e_(e) {}

        // this = this - other.
        // The exponents of both numbers must be the same and the significand of this
        // must be bigger than the significand of other.
        // The result will not be normalized.
        void Subtract(const DiyFp& other) {
            ASSERT(e_ == other.e_);
            ASSERT(f_ >= other.f_);
            f_ -= other.f_;
        }

        // Returns a - b.
        // The exponents of both numbers must be the same and this must be bigger
        // than other. The result will not be normalized.
        static DiyFp Minus(const DiyFp& a, const DiyFp& b) {
            DiyFp result = a;
            result.Subtract(b);
            return result;
        }


        // this = this * other.
        void Multiply(const DiyFp& other);

        // returns a * b;
        static DiyFp Times(const DiyFp& a, const DiyFp& b) {
            DiyFp result = a;
            result.Multiply(b);
            return result;
        }

        void Normalize() {
            ASSERT(f_ != 0);
            uint64_t f = f_;
            int e = e_;

            // This method is mainly called for normalizing boundaries. In general
            // boundaries need to be shifted by 10 bits. We thus optimize for this case.
            const uint64_t k10MSBits = UINT64_2PART_C(0xFFC00000, 00000000);
            while ((f & k10MSBits) == 0) {
                f <<= 10;
                e -= 10;
            }
            while ((f & kUint64MSB) == 0) {
                f <<= 1;
                e--;
            }
            f_ = f;
            e_ = e;
        }

        static DiyFp Normalize(const DiyFp& a) {
            DiyFp result = a;
            result.Normalize();
            return result;
        }

        uint64_t f() const { return f_; }
        int e() const { return e_; }

        void set_f(uint64_t new_value) { f_ = new_value; }
        void set_e(int new_value) { e_ = new_value; }

    private:
        static const uint64_t kUint64MSB = UINT64_2PART_C(0x80000000, 00000000);

        uint64_t f_;
        int e_;
    };

}  // namespace double_conversion

} // namespace WTF

#endif  // DOUBLE_CONVERSION_DIY_FP_H_
