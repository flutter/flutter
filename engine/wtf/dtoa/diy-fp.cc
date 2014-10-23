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

#include "config.h"

#include "diy-fp.h"
#include "utils.h"

namespace WTF {

namespace double_conversion {

    void DiyFp::Multiply(const DiyFp& other) {
        // Simply "emulates" a 128 bit multiplication.
        // However: the resulting number only contains 64 bits. The least
        // significant 64 bits are only used for rounding the most significant 64
        // bits.
        const uint64_t kM32 = 0xFFFFFFFFU;
        uint64_t a = f_ >> 32;
        uint64_t b = f_ & kM32;
        uint64_t c = other.f_ >> 32;
        uint64_t d = other.f_ & kM32;
        uint64_t ac = a * c;
        uint64_t bc = b * c;
        uint64_t ad = a * d;
        uint64_t bd = b * d;
        uint64_t tmp = (bd >> 32) + (ad & kM32) + (bc & kM32);
        // By adding 1U << 31 to tmp we round the final result.
        // Halfway cases will be round up.
        tmp += 1U << 31;
        uint64_t result_f = ac + (ad >> 32) + (bc >> 32) + (tmp >> 32);
        e_ += other.e_ + 64;
        f_ = result_f;
    }

}  // namespace double_conversion

} // namespace WTF
