/*
 * Copyright (C) 2012 Apple Inc. All Rights Reserved.
 * Copyright (C) 2012 Patrick Gansterer <paroga@paroga.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#ifndef IntegerToStringConversion_h
#define IntegerToStringConversion_h

#include "wtf/text/StringBuilder.h"
#include "wtf/text/StringImpl.h"

namespace WTF {

enum PositiveOrNegativeNumber {
    PositiveNumber,
    NegativeNumber
};

template<typename T> struct ConversionTrait;

template<> struct ConversionTrait<String> {
    typedef PassRefPtr<StringImpl> ReturnType;
    typedef void AdditionalArgumentType;
    static inline ReturnType flush(LChar* characters, unsigned length, void*) { return StringImpl::create(characters, length); }
};
template<> struct ConversionTrait<StringBuilder> {
    typedef void ReturnType;
    typedef StringBuilder AdditionalArgumentType;
    static inline ReturnType flush(LChar* characters, unsigned length, StringBuilder* stringBuilder) { stringBuilder->append(characters, length); }
};
template<> struct ConversionTrait<AtomicString> {
    typedef AtomicString ReturnType;
    typedef void AdditionalArgumentType;
    static inline ReturnType flush(LChar* characters, unsigned length, void*) { return AtomicString(characters, length); }
};

template<typename T> struct UnsignedIntegerTrait;

template<> struct UnsignedIntegerTrait<int> {
    typedef unsigned Type;
};
template<> struct UnsignedIntegerTrait<long> {
    typedef unsigned long Type;
};
template<> struct UnsignedIntegerTrait<long long> {
    typedef unsigned long long Type;
};

template<typename T, typename UnsignedIntegerType, PositiveOrNegativeNumber NumberType>
static typename ConversionTrait<T>::ReturnType numberToStringImpl(UnsignedIntegerType number, typename ConversionTrait<T>::AdditionalArgumentType* additionalArgument)
{
    LChar buf[sizeof(UnsignedIntegerType) * 3 + 1];
    LChar* end = buf + WTF_ARRAY_LENGTH(buf);
    LChar* p = end;

    do {
        *--p = static_cast<LChar>((number % 10) + '0');
        number /= 10;
    } while (number);

    if (NumberType == NegativeNumber)
        *--p = '-';

    return ConversionTrait<T>::flush(p, static_cast<unsigned>(end - p), additionalArgument);
}

template<typename T, typename SignedIntegerType>
inline typename ConversionTrait<T>::ReturnType numberToStringSigned(SignedIntegerType number, typename ConversionTrait<T>::AdditionalArgumentType* additionalArgument = 0)
{
    if (number < 0)
        return numberToStringImpl<T, typename UnsignedIntegerTrait<SignedIntegerType>::Type, NegativeNumber>(-number, additionalArgument);
    return numberToStringImpl<T, typename UnsignedIntegerTrait<SignedIntegerType>::Type, PositiveNumber>(number, additionalArgument);
}

template<typename T, typename UnsignedIntegerType>
inline typename ConversionTrait<T>::ReturnType numberToStringUnsigned(UnsignedIntegerType number, typename ConversionTrait<T>::AdditionalArgumentType* additionalArgument = 0)
{
    return numberToStringImpl<T, UnsignedIntegerType, PositiveNumber>(number, additionalArgument);
}

} // namespace WTF

#endif // IntegerToStringConversion_h
