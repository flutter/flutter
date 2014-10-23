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

#ifndef DOUBLE_CONVERSION_FIXED_DTOA_H_
#define DOUBLE_CONVERSION_FIXED_DTOA_H_

#include "utils.h"

namespace WTF {

namespace double_conversion {

    // Produces digits necessary to print a given number with
    // 'fractional_count' digits after the decimal point.
    // The buffer must be big enough to hold the result plus one terminating null
    // character.
    //
    // The produced digits might be too short in which case the caller has to fill
    // the gaps with '0's.
    // Example: FastFixedDtoa(0.001, 5, ...) is allowed to return buffer = "1", and
    // decimal_point = -2.
    // Halfway cases are rounded towards +/-Infinity (away from 0). The call
    // FastFixedDtoa(0.15, 2, ...) thus returns buffer = "2", decimal_point = 0.
    // The returned buffer may contain digits that would be truncated from the
    // shortest representation of the input.
    //
    // This method only works for some parameters. If it can't handle the input it
    // returns false. The output is null-terminated when the function succeeds.
    bool FastFixedDtoa(double v, int fractional_count,
                       Vector<char> buffer, int* length, int* decimal_point);

}  // namespace double_conversion

} // namespace WTF

#endif  // DOUBLE_CONVERSION_FIXED_DTOA_H_
