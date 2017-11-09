/*
 *  Copyright (C) 2003, 2008, 2012 Apple Inc. All rights reserved.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Library General Public
 *  License as published by the Free Software Foundation; either
 *  version 2 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Library General Public License for more details.
 *
 *  You should have received a copy of the GNU Library General Public License
 *  along with this library; see the file COPYING.LIB.  If not, write to
 *  the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301, USA.
 *
 */

#ifndef SKY_ENGINE_WTF_DTOA_H_
#define SKY_ENGINE_WTF_DTOA_H_

#include "flutter/sky/engine/wtf/ASCIICType.h"
#include "flutter/sky/engine/wtf/WTFExport.h"
#include "flutter/sky/engine/wtf/unicode/Unicode.h"
#include "wtf/dtoa/double-conversion.h"

namespace WTF {

class Mutex;

extern Mutex* s_dtoaP5Mutex;

typedef char DtoaBuffer[80];

WTF_EXPORT void dtoa(DtoaBuffer result,
                     double dd,
                     bool& sign,
                     int& exponent,
                     unsigned& precision);
WTF_EXPORT void dtoaRoundSF(DtoaBuffer result,
                            double dd,
                            int ndigits,
                            bool& sign,
                            int& exponent,
                            unsigned& precision);
WTF_EXPORT void dtoaRoundDP(DtoaBuffer result,
                            double dd,
                            int ndigits,
                            bool& sign,
                            int& exponent,
                            unsigned& precision);

// Size = 80 for sizeof(DtoaBuffer) + some sign bits, decimal point, 'e',
// exponent digits.
const unsigned NumberToStringBufferLength = 96;
typedef char NumberToStringBuffer[NumberToStringBufferLength];
typedef LChar NumberToLStringBuffer[NumberToStringBufferLength];

WTF_EXPORT const char* numberToString(double, NumberToStringBuffer);
WTF_EXPORT const char* numberToFixedPrecisionString(
    double,
    unsigned significantFigures,
    NumberToStringBuffer,
    bool truncateTrailingZeros = false);
WTF_EXPORT const char* numberToFixedWidthString(double,
                                                unsigned decimalPlaces,
                                                NumberToStringBuffer);

WTF_EXPORT double parseDouble(const LChar* string,
                              size_t length,
                              size_t& parsedLength);
WTF_EXPORT double parseDouble(const UChar* string,
                              size_t length,
                              size_t& parsedLength);

namespace Internal {
double parseDoubleFromLongString(const UChar* string,
                                 size_t length,
                                 size_t& parsedLength);
}

inline double parseDouble(const LChar* string,
                          size_t length,
                          size_t& parsedLength) {
  return double_conversion::StringToDoubleConverter::StringToDouble(
      reinterpret_cast<const char*>(string), length, &parsedLength);
}

inline double parseDouble(const UChar* string,
                          size_t length,
                          size_t& parsedLength) {
  const size_t conversionBufferSize = 64;
  if (length > conversionBufferSize)
    return Internal::parseDoubleFromLongString(string, length, parsedLength);
  LChar conversionBuffer[conversionBufferSize];
  for (int i = 0; i < static_cast<int>(length); ++i)
    conversionBuffer[i] = isASCII(string[i]) ? string[i] : 0;
  return parseDouble(conversionBuffer, length, parsedLength);
}

}  // namespace WTF

using WTF::NumberToLStringBuffer;
using WTF::NumberToStringBuffer;
using WTF::numberToFixedPrecisionString;
using WTF::numberToFixedWidthString;
using WTF::numberToString;
using WTF::parseDouble;

#endif  // SKY_ENGINE_WTF_DTOA_H_
