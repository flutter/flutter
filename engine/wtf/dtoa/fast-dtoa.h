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

#ifndef DOUBLE_CONVERSION_FAST_DTOA_H_
#define DOUBLE_CONVERSION_FAST_DTOA_H_

#include "utils.h"

namespace WTF {

namespace double_conversion {

    enum FastDtoaMode {
        // Computes the shortest representation of the given input. The returned
        // result will be the most accurate number of this length. Longer
        // representations might be more accurate.
        FAST_DTOA_SHORTEST,
        // Computes a representation where the precision (number of digits) is
        // given as input. The precision is independent of the decimal point.
        FAST_DTOA_PRECISION
    };

    // FastDtoa will produce at most kFastDtoaMaximalLength digits. This does not
    // include the terminating '\0' character.
    static const int kFastDtoaMaximalLength = 17;

    // Provides a decimal representation of v.
    // The result should be interpreted as buffer * 10^(point - length).
    //
    // Precondition:
    //   * v must be a strictly positive finite double.
    //
    // Returns true if it succeeds, otherwise the result can not be trusted.
    // There will be *length digits inside the buffer followed by a null terminator.
    // If the function returns true and mode equals
    //   - FAST_DTOA_SHORTEST, then
    //     the parameter requested_digits is ignored.
    //     The result satisfies
    //         v == (double) (buffer * 10^(point - length)).
    //     The digits in the buffer are the shortest representation possible. E.g.
    //     if 0.099999999999 and 0.1 represent the same double then "1" is returned
    //     with point = 0.
    //     The last digit will be closest to the actual v. That is, even if several
    //     digits might correctly yield 'v' when read again, the buffer will contain
    //     the one closest to v.
    //   - FAST_DTOA_PRECISION, then
    //     the buffer contains requested_digits digits.
    //     the difference v - (buffer * 10^(point-length)) is closest to zero for
    //     all possible representations of requested_digits digits.
    //     If there are two values that are equally close, then FastDtoa returns
    //     false.
    // For both modes the buffer must be large enough to hold the result.
    bool FastDtoa(double d,
                  FastDtoaMode mode,
                  int requested_digits,
                  Vector<char> buffer,
                  int* length,
                  int* decimal_point);

}  // namespace double_conversion

} // namespace WTF

#endif  // DOUBLE_CONVERSION_FAST_DTOA_H_
