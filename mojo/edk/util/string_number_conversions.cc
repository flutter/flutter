// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/util/string_number_conversions.h"

#include <assert.h>
#include <stdint.h>

#include <limits>
#include <type_traits>

namespace mojo {
namespace util {
namespace {

// Helper for |StringToNumberWithError()|. Note that this may modify |*number|
// even on failure.
template <typename NumberType>
bool StringToPositiveNumberWithError(const char* s,
                                     size_t length,
                                     NumberType* number) {
  constexpr NumberType kBase = static_cast<NumberType>(10);
  constexpr NumberType kMaxAllowed = std::numeric_limits<NumberType>::max();

  assert(s);
  assert(length > 0u);
  assert(number);

  *number = 0;
  for (size_t i = 0; i < length; i++) {
    if (s[i] < '0' || s[i] > '9')
      return false;
    NumberType new_digit = static_cast<NumberType>(s[i] - '0');
    // This is really a check of "*number * kBase + new_digit > kMaxAllowed":
    if (*number > kMaxAllowed / kBase ||
        (*number == kMaxAllowed / kBase && new_digit > kMaxAllowed % kBase))
      return false;
    *number = *number * kBase + new_digit;
  }

  return true;
}

// Helper for |StringToNumberWithError()|. Note that this may modify |*number|
// even on failure.
template <typename NumberType>
bool StringToNegativeNumberWithError(const char* s,
                                     size_t length,
                                     NumberType* number) {
  constexpr NumberType kBase = static_cast<NumberType>(10);
  constexpr NumberType kMinAllowed = std::numeric_limits<NumberType>::min();

  assert(s);
  assert(length > 0u);
  assert(number);

  *number = 0;
  for (size_t i = 0; i < length; i++) {
    if (s[i] < '0' || s[i] > '9')
      return false;
    NumberType new_digit = static_cast<NumberType>(s[i] - '0');
    // This is really a check of "*number * kBase - new_digit > kMinAllowed":
    if (*number < kMinAllowed / kBase ||
        (kMinAllowed / kBase == *number && new_digit > -(kMinAllowed % kBase)))
      return false;
    *number = *number * kBase - new_digit;
  }

  return true;
}

}  // namespace

template <typename NumberType>
std::string NumberToString(NumberType number) {
  // Special-case zero (since nonzero cases naturally produce digits).
  if (!number)
    return std::string("0");

  using UnsignedNumberType = typename std::make_unsigned<NumberType>::type;
  // Note: The negative case is safe, since the standard requires that, e.g.,
  // for n a negative int32_t, |static_cast<uint32_t>(n)| = 2^32 - n and for a
  // uint32_t m, |-m| = 2^32 - m.
  bool number_is_negative = (number < static_cast<NumberType>(0));
  UnsignedNumberType abs_number = number_is_negative
                                      ? -static_cast<UnsignedNumberType>(number)
                                      : static_cast<UnsignedNumberType>(number);

  char buf[50];  // Big enough to hold the result from even a 128-bit number.
  size_t i = sizeof(buf);
  while (abs_number) {
    i--;
    buf[i] = '0' + abs_number % 10u;
    abs_number /= 10u;
  }
  if (number_is_negative) {
    i--;
    buf[i] = '-';
  }

  return std::string(buf + i, buf + sizeof(buf));
}

template <typename NumberType>
bool StringToNumberWithError(const std::string& string, NumberType* number) {
  assert(number);

  if (string.empty())
    return false;

  const char* s = &string[0];
  size_t length = string.length();
  NumberType result = 0;
  if (std::is_signed<NumberType>::value && string[0] == '-') {
    if (length < 2)
      return false;
    if (!StringToNegativeNumberWithError<NumberType>(s + 1, length - 1u,
                                                     &result))
      return false;
  } else {
    if (!StringToPositiveNumberWithError<NumberType>(s, length, &result))
      return false;
  }

  *number = result;
  return true;
}

// Explicit instantiatiations for (u)intN_t; count on (unsigned) int being one
// of these:
template std::string NumberToString<int8_t>(int8_t number);
template std::string NumberToString<uint8_t>(uint8_t number);
template std::string NumberToString<int16_t>(int16_t number);
template std::string NumberToString<uint16_t>(uint16_t number);
template std::string NumberToString<int32_t>(int32_t number);
template std::string NumberToString<uint32_t>(uint32_t number);
template std::string NumberToString<int64_t>(int64_t number);
template std::string NumberToString<uint64_t>(uint64_t number);
template bool StringToNumberWithError<int8_t>(const std::string& string,
                                              int8_t* number);
template bool StringToNumberWithError<uint8_t>(const std::string& string,
                                               uint8_t* number);
template bool StringToNumberWithError<int16_t>(const std::string& string,
                                               int16_t* number);
template bool StringToNumberWithError<uint16_t>(const std::string& string,
                                                uint16_t* number);
template bool StringToNumberWithError<int32_t>(const std::string& string,
                                               int32_t* number);
template bool StringToNumberWithError<uint32_t>(const std::string& string,
                                                uint32_t* number);
template bool StringToNumberWithError<int64_t>(const std::string& string,
                                               int64_t* number);
template bool StringToNumberWithError<uint64_t>(const std::string& string,
                                                uint64_t* number);

}  // namespace util
}  // namespace mojo
