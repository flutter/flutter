// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Functions for converting between numbers and their representations as strings
// (in decimal, in a locale-independent way).

#ifndef MOJO_EDK_UTIL_STRING_NUMBER_CONVERSIONS_H_
#define MOJO_EDK_UTIL_STRING_NUMBER_CONVERSIONS_H_

#include <string>

namespace mojo {
namespace util {

// Converts |number| to a string with a locale-independent decimal
// representation of it. This is available for all |NumberType|s (u)intN_t (from
// <stdint.h>) and also (unsigned) int.
template <typename NumberType>
std::string NumberToString(NumberType number);

// Converts |string| containing a locale-independent decimal representation of a
// number to a numeric representation of that number. (On error, this returns
// false and leaves |*number| alone.) This is available for all |NumberType|s
// (u)intN_t (from <stdint.h>) and also (unsigned) int.
//
// Notes: Unary '+' is not allowed. Leading zeros are allowed (and ignored). For
// unsigned types, unary '-' is not allowed. For signed types, "-0", "-00", etc.
// are also allowed.
template <typename NumberType>
bool StringToNumberWithError(const std::string& string, NumberType* number);

// Converts |string| containing a locale-independent decimal representation of a
// number to a numeric representation of that number. (On error, this returns
// zero.) This is available for all |NumberType|s (u)intN_t (from <stdint.h>)
// and also (unsigned) int. (See |StringToNumberWithError()| for more details.)
template <typename NumberType>
NumberType StringToNumber(const std::string& string) {
  NumberType rv = static_cast<NumberType>(0);
  return StringToNumberWithError(string, &rv) ? rv : static_cast<NumberType>(0);
}

}  // namespace util
}  // namespace mojo

#endif  // MOJO_EDK_UTIL_STRING_NUMBER_CONVERSIONS_H_
