/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#include "config.h"
#include "platform/Decimal.h"

#include "wtf/MathExtras.h"
#include "wtf/Noncopyable.h"
#include "wtf/text/StringBuilder.h"

#include <algorithm>
#include <float.h>

namespace blink {

namespace DecimalPrivate {

static int const ExponentMax = 1023;
static int const ExponentMin = -1023;
static int const Precision = 18;

static const uint64_t MaxCoefficient = UINT64_C(0xDE0B6B3A763FFFF); // 999999999999999999 == 18 9's

// This class handles Decimal special values.
class SpecialValueHandler {
    WTF_MAKE_NONCOPYABLE(SpecialValueHandler);
public:
    enum HandleResult {
        BothFinite,
        BothInfinity,
        EitherNaN,
        LHSIsInfinity,
        RHSIsInfinity,
    };

    SpecialValueHandler(const Decimal& lhs, const Decimal& rhs);
    HandleResult handle();
    Decimal value() const;

private:
    enum Result {
        ResultIsLHS,
        ResultIsRHS,
        ResultIsUnknown,
    };

    const Decimal& m_lhs;
    const Decimal& m_rhs;
    Result m_result;
};

SpecialValueHandler::SpecialValueHandler(const Decimal& lhs, const Decimal& rhs)
    : m_lhs(lhs), m_rhs(rhs), m_result(ResultIsUnknown)
{
}

SpecialValueHandler::HandleResult SpecialValueHandler::handle()
{
    if (m_lhs.isFinite() && m_rhs.isFinite())
        return BothFinite;

    const Decimal::EncodedData::FormatClass lhsClass = m_lhs.value().formatClass();
    const Decimal::EncodedData::FormatClass rhsClass = m_rhs.value().formatClass();
    if (lhsClass == Decimal::EncodedData::ClassNaN) {
        m_result = ResultIsLHS;
        return EitherNaN;
    }

    if (rhsClass == Decimal::EncodedData::ClassNaN) {
        m_result = ResultIsRHS;
        return EitherNaN;
    }

    if (lhsClass == Decimal::EncodedData::ClassInfinity)
        return rhsClass == Decimal::EncodedData::ClassInfinity ? BothInfinity : LHSIsInfinity;

    if (rhsClass == Decimal::EncodedData::ClassInfinity)
        return RHSIsInfinity;

    ASSERT_NOT_REACHED();
    return BothFinite;
}

Decimal SpecialValueHandler::value() const
{
    switch (m_result) {
    case ResultIsLHS:
        return m_lhs;
    case ResultIsRHS:
        return m_rhs;
    case ResultIsUnknown:
    default:
        ASSERT_NOT_REACHED();
        return m_lhs;
    }
}

// This class is used for 128 bit unsigned integer arithmetic.
class UInt128 {
public:
    UInt128(uint64_t low, uint64_t high)
        : m_high(high), m_low(low)
    {
    }

    UInt128& operator/=(uint32_t);

    uint64_t high() const { return m_high; }
    uint64_t low() const { return m_low; }

    static UInt128 multiply(uint64_t u, uint64_t v) { return UInt128(u * v, multiplyHigh(u, v)); }

private:
    static uint32_t highUInt32(uint64_t x) { return static_cast<uint32_t>(x >> 32); }
    static uint32_t lowUInt32(uint64_t x) { return static_cast<uint32_t>(x & ((static_cast<uint64_t>(1) << 32) - 1)); }
    static uint64_t makeUInt64(uint32_t low, uint32_t high) { return low | (static_cast<uint64_t>(high) << 32); }

    static uint64_t multiplyHigh(uint64_t, uint64_t);

    uint64_t m_high;
    uint64_t m_low;
};

UInt128& UInt128::operator/=(const uint32_t divisor)
{
    ASSERT(divisor);

    if (!m_high) {
        m_low /= divisor;
        return *this;
    }

    uint32_t dividend[4];
    dividend[0] = lowUInt32(m_low);
    dividend[1] = highUInt32(m_low);
    dividend[2] = lowUInt32(m_high);
    dividend[3] = highUInt32(m_high);

    uint32_t quotient[4];
    uint32_t remainder = 0;
    for (int i = 3; i >= 0; --i) {
        const uint64_t work = makeUInt64(dividend[i], remainder);
        remainder = static_cast<uint32_t>(work % divisor);
        quotient[i] = static_cast<uint32_t>(work / divisor);
    }
    m_low = makeUInt64(quotient[0], quotient[1]);
    m_high = makeUInt64(quotient[2], quotient[3]);
    return *this;
}

// Returns high 64bit of 128bit product.
uint64_t UInt128::multiplyHigh(uint64_t u, uint64_t v)
{
    const uint64_t uLow = lowUInt32(u);
    const uint64_t uHigh = highUInt32(u);
    const uint64_t vLow = lowUInt32(v);
    const uint64_t vHigh = highUInt32(v);
    const uint64_t partialProduct = uHigh * vLow + highUInt32(uLow * vLow);
    return uHigh * vHigh + highUInt32(partialProduct) + highUInt32(uLow * vHigh + lowUInt32(partialProduct));
}

static int countDigits(uint64_t x)
{
    int numberOfDigits = 0;
    for (uint64_t powerOfTen = 1; x >= powerOfTen; powerOfTen *= 10) {
        ++numberOfDigits;
        if (powerOfTen >= std::numeric_limits<uint64_t>::max() / 10)
            break;
    }
    return numberOfDigits;
}

static uint64_t scaleDown(uint64_t x, int n)
{
    ASSERT(n >= 0);
    while (n > 0 && x) {
        x /= 10;
        --n;
    }
    return x;
}

static uint64_t scaleUp(uint64_t x, int n)
{
    ASSERT(n >= 0);
    ASSERT(n < Precision);

    uint64_t y = 1;
    uint64_t z = 10;
    for (;;) {
        if (n & 1)
            y = y * z;

        n >>= 1;
        if (!n)
            return x * y;

        z = z * z;
    }
}

} // namespace DecimalPrivate

using namespace DecimalPrivate;

Decimal::EncodedData::EncodedData(Sign sign, FormatClass formatClass)
    : m_coefficient(0)
    , m_exponent(0)
    , m_formatClass(formatClass)
    , m_sign(sign)
{
}

Decimal::EncodedData::EncodedData(Sign sign, int exponent, uint64_t coefficient)
    : m_formatClass(coefficient ? ClassNormal : ClassZero)
    , m_sign(sign)
{
    if (exponent >= ExponentMin && exponent <= ExponentMax) {
        while (coefficient > MaxCoefficient) {
            coefficient /= 10;
            ++exponent;
        }
    }

    if (exponent > ExponentMax) {
        m_coefficient = 0;
        m_exponent = 0;
        m_formatClass = ClassInfinity;
        return;
    }

    if (exponent < ExponentMin) {
        m_coefficient = 0;
        m_exponent = 0;
        m_formatClass = ClassZero;
        return;
    }

    m_coefficient = coefficient;
    m_exponent = static_cast<int16_t>(exponent);
}

bool Decimal::EncodedData::operator==(const EncodedData& another) const
{
    return m_sign == another.m_sign
        && m_formatClass == another.m_formatClass
        && m_exponent == another.m_exponent
        && m_coefficient == another.m_coefficient;
}

Decimal::Decimal(int32_t i32)
    : m_data(i32 < 0 ? Negative : Positive, 0, i32 < 0 ? static_cast<uint64_t>(-static_cast<int64_t>(i32)) : static_cast<uint64_t>(i32))
{
}

Decimal::Decimal(Sign sign, int exponent, uint64_t coefficient)
    : m_data(sign, exponent, coefficient)
{
}

Decimal::Decimal(const EncodedData& data)
    : m_data(data)
{
}

Decimal::Decimal(const Decimal& other)
    : m_data(other.m_data)
{
}

Decimal& Decimal::operator=(const Decimal& other)
{
    m_data = other.m_data;
    return *this;
}

Decimal& Decimal::operator+=(const Decimal& other)
{
    m_data = (*this + other).m_data;
    return *this;
}

Decimal& Decimal::operator-=(const Decimal& other)
{
    m_data = (*this - other).m_data;
    return *this;
}

Decimal& Decimal::operator*=(const Decimal& other)
{
    m_data = (*this * other).m_data;
    return *this;
}

Decimal& Decimal::operator/=(const Decimal& other)
{
    m_data = (*this / other).m_data;
    return *this;
}

Decimal Decimal::operator-() const
{
    if (isNaN())
        return *this;

    Decimal result(*this);
    result.m_data.setSign(invertSign(m_data.sign()));
    return result;
}

Decimal Decimal::operator+(const Decimal& rhs) const
{
    const Decimal& lhs = *this;
    const Sign lhsSign = lhs.sign();
    const Sign rhsSign = rhs.sign();

    SpecialValueHandler handler(lhs, rhs);
    switch (handler.handle()) {
    case SpecialValueHandler::BothFinite:
        break;

    case SpecialValueHandler::BothInfinity:
        return lhsSign == rhsSign ? lhs : nan();

    case SpecialValueHandler::EitherNaN:
        return handler.value();

    case SpecialValueHandler::LHSIsInfinity:
        return lhs;

    case SpecialValueHandler::RHSIsInfinity:
        return rhs;
    }

    const AlignedOperands alignedOperands = alignOperands(lhs, rhs);

    const uint64_t result = lhsSign == rhsSign
        ? alignedOperands.lhsCoefficient + alignedOperands.rhsCoefficient
        : alignedOperands.lhsCoefficient - alignedOperands.rhsCoefficient;

    if (lhsSign == Negative && rhsSign == Positive && !result)
        return Decimal(Positive, alignedOperands.exponent, 0);

    return static_cast<int64_t>(result) >= 0
        ? Decimal(lhsSign, alignedOperands.exponent, result)
        : Decimal(invertSign(lhsSign), alignedOperands.exponent, -static_cast<int64_t>(result));
}

Decimal Decimal::operator-(const Decimal& rhs) const
{
    const Decimal& lhs = *this;
    const Sign lhsSign = lhs.sign();
    const Sign rhsSign = rhs.sign();

    SpecialValueHandler handler(lhs, rhs);
    switch (handler.handle()) {
    case SpecialValueHandler::BothFinite:
        break;

    case SpecialValueHandler::BothInfinity:
        return lhsSign == rhsSign ? nan() : lhs;

    case SpecialValueHandler::EitherNaN:
        return handler.value();

    case SpecialValueHandler::LHSIsInfinity:
        return lhs;

    case SpecialValueHandler::RHSIsInfinity:
        return infinity(invertSign(rhsSign));
    }

    const AlignedOperands alignedOperands = alignOperands(lhs, rhs);

    const uint64_t result = lhsSign == rhsSign
        ? alignedOperands.lhsCoefficient - alignedOperands.rhsCoefficient
        : alignedOperands.lhsCoefficient + alignedOperands.rhsCoefficient;

    if (lhsSign == Negative && rhsSign == Negative && !result)
        return Decimal(Positive, alignedOperands.exponent, 0);

    return static_cast<int64_t>(result) >= 0
        ? Decimal(lhsSign, alignedOperands.exponent, result)
        : Decimal(invertSign(lhsSign), alignedOperands.exponent, -static_cast<int64_t>(result));
}

Decimal Decimal::operator*(const Decimal& rhs) const
{
    const Decimal& lhs = *this;
    const Sign lhsSign = lhs.sign();
    const Sign rhsSign = rhs.sign();
    const Sign resultSign = lhsSign == rhsSign ? Positive : Negative;

    SpecialValueHandler handler(lhs, rhs);
    switch (handler.handle()) {
    case SpecialValueHandler::BothFinite: {
        const uint64_t lhsCoefficient = lhs.m_data.coefficient();
        const uint64_t rhsCoefficient = rhs.m_data.coefficient();
        int resultExponent = lhs.exponent() + rhs.exponent();
        UInt128 work(UInt128::multiply(lhsCoefficient, rhsCoefficient));
        while (work.high()) {
            work /= 10;
            ++resultExponent;
        }
        return Decimal(resultSign, resultExponent, work.low());
    }

    case SpecialValueHandler::BothInfinity:
        return infinity(resultSign);

    case SpecialValueHandler::EitherNaN:
        return handler.value();

    case SpecialValueHandler::LHSIsInfinity:
        return rhs.isZero() ? nan() : infinity(resultSign);

    case SpecialValueHandler::RHSIsInfinity:
        return lhs.isZero() ? nan() : infinity(resultSign);
    }

    ASSERT_NOT_REACHED();
    return nan();
}

Decimal Decimal::operator/(const Decimal& rhs) const
{
    const Decimal& lhs = *this;
    const Sign lhsSign = lhs.sign();
    const Sign rhsSign = rhs.sign();
    const Sign resultSign = lhsSign == rhsSign ? Positive : Negative;

    SpecialValueHandler handler(lhs, rhs);
    switch (handler.handle()) {
    case SpecialValueHandler::BothFinite:
        break;

    case SpecialValueHandler::BothInfinity:
        return nan();

    case SpecialValueHandler::EitherNaN:
        return handler.value();

    case SpecialValueHandler::LHSIsInfinity:
        return infinity(resultSign);

    case SpecialValueHandler::RHSIsInfinity:
        return zero(resultSign);
    }

    ASSERT(lhs.isFinite());
    ASSERT(rhs.isFinite());

    if (rhs.isZero())
        return lhs.isZero() ? nan() : infinity(resultSign);

    int resultExponent = lhs.exponent() - rhs.exponent();

    if (lhs.isZero())
        return Decimal(resultSign, resultExponent, 0);

    uint64_t remainder = lhs.m_data.coefficient();
    const uint64_t divisor = rhs.m_data.coefficient();
    uint64_t result = 0;
    while (result < MaxCoefficient / 100) {
        while (remainder < divisor) {
            remainder *= 10;
            result *= 10;
            --resultExponent;
        }
        result += remainder / divisor;
        remainder %= divisor;
        if (!remainder)
            break;
    }

    if (remainder > divisor / 2)
        ++result;

    return Decimal(resultSign, resultExponent, result);
}

bool Decimal::operator==(const Decimal& rhs) const
{
    return m_data == rhs.m_data || compareTo(rhs).isZero();
}

bool Decimal::operator!=(const Decimal& rhs) const
{
    if (m_data == rhs.m_data)
        return false;
    const Decimal result = compareTo(rhs);
    if (result.isNaN())
        return false;
    return !result.isZero();
}

bool Decimal::operator<(const Decimal& rhs) const
{
    const Decimal result = compareTo(rhs);
    if (result.isNaN())
        return false;
    return !result.isZero() && result.isNegative();
}

bool Decimal::operator<=(const Decimal& rhs) const
{
    if (m_data == rhs.m_data)
        return true;
    const Decimal result = compareTo(rhs);
    if (result.isNaN())
        return false;
    return result.isZero() || result.isNegative();
}

bool Decimal::operator>(const Decimal& rhs) const
{
    const Decimal result = compareTo(rhs);
    if (result.isNaN())
        return false;
    return !result.isZero() && result.isPositive();
}

bool Decimal::operator>=(const Decimal& rhs) const
{
    if (m_data == rhs.m_data)
        return true;
    const Decimal result = compareTo(rhs);
    if (result.isNaN())
        return false;
    return result.isZero() || !result.isNegative();
}

Decimal Decimal::abs() const
{
    Decimal result(*this);
    result.m_data.setSign(Positive);
    return result;
}

Decimal::AlignedOperands Decimal::alignOperands(const Decimal& lhs, const Decimal& rhs)
{
    ASSERT(lhs.isFinite());
    ASSERT(rhs.isFinite());

    const int lhsExponent = lhs.exponent();
    const int rhsExponent = rhs.exponent();
    int exponent = std::min(lhsExponent, rhsExponent);
    uint64_t lhsCoefficient = lhs.m_data.coefficient();
    uint64_t rhsCoefficient = rhs.m_data.coefficient();

    if (lhsExponent > rhsExponent) {
        const int numberOfLHSDigits = countDigits(lhsCoefficient);
        if (numberOfLHSDigits) {
            const int lhsShiftAmount = lhsExponent - rhsExponent;
            const int overflow = numberOfLHSDigits + lhsShiftAmount - Precision;
            if (overflow <= 0) {
                lhsCoefficient = scaleUp(lhsCoefficient, lhsShiftAmount);
            } else {
                lhsCoefficient = scaleUp(lhsCoefficient, lhsShiftAmount - overflow);
                rhsCoefficient = scaleDown(rhsCoefficient, overflow);
                exponent += overflow;
            }
        }

    } else if (lhsExponent < rhsExponent) {
        const int numberOfRHSDigits = countDigits(rhsCoefficient);
        if (numberOfRHSDigits) {
            const int rhsShiftAmount = rhsExponent - lhsExponent;
            const int overflow = numberOfRHSDigits + rhsShiftAmount - Precision;
            if (overflow <= 0) {
                rhsCoefficient = scaleUp(rhsCoefficient, rhsShiftAmount);
            } else {
                rhsCoefficient = scaleUp(rhsCoefficient, rhsShiftAmount - overflow);
                lhsCoefficient = scaleDown(lhsCoefficient, overflow);
                exponent += overflow;
            }
        }
    }

    AlignedOperands alignedOperands;
    alignedOperands.exponent = exponent;
    alignedOperands.lhsCoefficient = lhsCoefficient;
    alignedOperands.rhsCoefficient = rhsCoefficient;
    return alignedOperands;
}

static bool isMultiplePowersOfTen(uint64_t coefficient, int n)
{
    return !coefficient || !(coefficient % scaleUp(1, n));
}

// Round toward positive infinity.
// Note: Mac ports defines ceil(x) as wtf_ceil(x), so we can't use name "ceil" here.
Decimal Decimal::ceiling() const
{
    if (isSpecial())
        return *this;

    if (exponent() >= 0)
        return *this;

    uint64_t result = m_data.coefficient();
    const int numberOfDigits = countDigits(result);
    const int numberOfDropDigits = -exponent();
    if (numberOfDigits < numberOfDropDigits)
        return isPositive() ? Decimal(1) : zero(Positive);

    result = scaleDown(result, numberOfDropDigits);
    if (isPositive() && !isMultiplePowersOfTen(m_data.coefficient(), numberOfDropDigits))
        ++result;
    return Decimal(sign(), 0, result);
}

Decimal Decimal::compareTo(const Decimal& rhs) const
{
    const Decimal result(*this - rhs);
    switch (result.m_data.formatClass()) {
    case EncodedData::ClassInfinity:
        return result.isNegative() ? Decimal(-1) : Decimal(1);

    case EncodedData::ClassNaN:
    case EncodedData::ClassNormal:
        return result;

    case EncodedData::ClassZero:
        return zero(Positive);

    default:
        ASSERT_NOT_REACHED();
        return nan();
    }
}

// Round toward negative infinity.
Decimal Decimal::floor() const
{
    if (isSpecial())
        return *this;

    if (exponent() >= 0)
        return *this;

    uint64_t result = m_data.coefficient();
    const int numberOfDigits = countDigits(result);
    const int numberOfDropDigits = -exponent();
    if (numberOfDigits < numberOfDropDigits)
        return isPositive() ? zero(Positive) : Decimal(-1);

    result = scaleDown(result, numberOfDropDigits);
    if (isNegative() && !isMultiplePowersOfTen(m_data.coefficient(), numberOfDropDigits))
        ++result;
    return Decimal(sign(), 0, result);
}

Decimal Decimal::fromDouble(double doubleValue)
{
    if (std::isfinite(doubleValue))
        return fromString(String::numberToStringECMAScript(doubleValue));

    if (std::isinf(doubleValue))
        return infinity(doubleValue < 0 ? Negative : Positive);

    return nan();
}

Decimal Decimal::fromString(const String& str)
{
    int exponent = 0;
    Sign exponentSign = Positive;
    int numberOfDigits = 0;
    int numberOfDigitsAfterDot = 0;
    int numberOfExtraDigits = 0;
    Sign sign = Positive;

    enum {
        StateDigit,
        StateDot,
        StateDotDigit,
        StateE,
        StateEDigit,
        StateESign,
        StateSign,
        StateStart,
        StateZero,
    } state = StateStart;

#define HandleCharAndBreak(expected, nextState) \
    if (ch == expected) { \
        state = nextState; \
        break; \
    }

#define HandleTwoCharsAndBreak(expected1, expected2, nextState) \
    if (ch == expected1 || ch == expected2) { \
        state = nextState; \
        break; \
    }

    uint64_t accumulator = 0;
    for (unsigned index = 0; index < str.length(); ++index) {
        const int ch = str[index];
        switch (state) {
        case StateDigit:
            if (ch >= '0' && ch <= '9') {
                if (numberOfDigits < Precision) {
                    ++numberOfDigits;
                    accumulator *= 10;
                    accumulator += ch - '0';
                } else {
                    ++numberOfExtraDigits;
                }
                break;
            }

            HandleCharAndBreak('.', StateDot);
            HandleTwoCharsAndBreak('E', 'e', StateE);
            return nan();

        case StateDot:
        case StateDotDigit:
            if (ch >= '0' && ch <= '9') {
                if (numberOfDigits < Precision) {
                    ++numberOfDigits;
                    ++numberOfDigitsAfterDot;
                    accumulator *= 10;
                    accumulator += ch - '0';
                }
                state = StateDotDigit;
                break;
            }

            HandleTwoCharsAndBreak('E', 'e', StateE);
            return nan();

        case StateE:
            if (ch == '+') {
                exponentSign = Positive;
                state = StateESign;
                break;
            }

            if (ch == '-') {
                exponentSign = Negative;
                state = StateESign;
                break;
            }

            if (ch >= '0' && ch <= '9') {
                exponent = ch - '0';
                state = StateEDigit;
                break;
            }

            return nan();

        case StateEDigit:
            if (ch >= '0' && ch <= '9') {
                exponent *= 10;
                exponent += ch - '0';
                if (exponent > ExponentMax + Precision) {
                    if (accumulator)
                        return exponentSign == Negative ? zero(Positive) : infinity(sign);
                    return zero(sign);
                }
                state = StateEDigit;
                break;
            }

            return nan();

        case StateESign:
            if (ch >= '0' && ch <= '9') {
                exponent = ch - '0';
                state = StateEDigit;
                break;
            }

            return nan();

        case StateSign:
            if (ch >= '1' && ch <= '9') {
                accumulator = ch - '0';
                numberOfDigits = 1;
                state = StateDigit;
                break;
            }

            HandleCharAndBreak('0', StateZero);
            return nan();

        case StateStart:
            if (ch >= '1' && ch <= '9') {
                accumulator = ch - '0';
                numberOfDigits = 1;
                state = StateDigit;
                break;
            }

            if (ch == '-') {
                sign = Negative;
                state = StateSign;
                break;
            }

            if (ch == '+') {
                sign = Positive;
                state = StateSign;
                break;
            }

            HandleCharAndBreak('0', StateZero);
            HandleCharAndBreak('.', StateDot);
            return nan();

        case StateZero:
            if (ch == '0')
                break;

            if (ch >= '1' && ch <= '9') {
                accumulator = ch - '0';
                numberOfDigits = 1;
                state = StateDigit;
                break;
            }

            HandleCharAndBreak('.', StateDot);
            HandleTwoCharsAndBreak('E', 'e', StateE);
            return nan();

        default:
            ASSERT_NOT_REACHED();
            return nan();
        }
    }

    if (state == StateZero)
        return zero(sign);

    if (state == StateDigit || state == StateEDigit || state == StateDotDigit) {
        int resultExponent = exponent * (exponentSign == Negative ? -1 : 1) - numberOfDigitsAfterDot + numberOfExtraDigits;
        if (resultExponent < ExponentMin)
            return zero(Positive);

        const int overflow = resultExponent - ExponentMax + 1;
        if (overflow > 0) {
            if (overflow + numberOfDigits - numberOfDigitsAfterDot > Precision)
                return infinity(sign);
            accumulator = scaleUp(accumulator, overflow);
            resultExponent -= overflow;
        }

        return Decimal(sign, resultExponent, accumulator);
    }

    return nan();
}

Decimal Decimal::infinity(const Sign sign)
{
    return Decimal(EncodedData(sign, EncodedData::ClassInfinity));
}

Decimal Decimal::nan()
{
    return Decimal(EncodedData(Positive, EncodedData::ClassNaN));
}

Decimal Decimal::remainder(const Decimal& rhs) const
{
    const Decimal quotient = *this / rhs;
    return quotient.isSpecial() ? quotient : *this - (quotient.isNegative() ? quotient.ceiling() : quotient.floor()) * rhs;
}

Decimal Decimal::round() const
{
    if (isSpecial())
        return *this;

    if (exponent() >= 0)
        return *this;

    uint64_t result = m_data.coefficient();
    const int numberOfDigits = countDigits(result);
    const int numberOfDropDigits = -exponent();
    if (numberOfDigits < numberOfDropDigits)
        return zero(Positive);

    result = scaleDown(result, numberOfDropDigits - 1);
    if (result % 10 >= 5)
        result += 10;
    result /= 10;
    return Decimal(sign(), 0, result);
}

double Decimal::toDouble() const
{
    if (isFinite()) {
        bool valid;
        const double doubleValue = toString().toDouble(&valid);
        return valid ? doubleValue : std::numeric_limits<double>::quiet_NaN();
    }

    if (isInfinity())
        return isNegative() ? -std::numeric_limits<double>::infinity() : std::numeric_limits<double>::infinity();

    return std::numeric_limits<double>::quiet_NaN();
}

String Decimal::toString() const
{
    switch (m_data.formatClass()) {
    case EncodedData::ClassInfinity:
        return sign() ? "-Infinity" : "Infinity";

    case EncodedData::ClassNaN:
        return "NaN";

    case EncodedData::ClassNormal:
    case EncodedData::ClassZero:
        break;

    default:
        ASSERT_NOT_REACHED();
        return "";
    }

    StringBuilder builder;
    if (sign())
        builder.append('-');

    int originalExponent = exponent();
    uint64_t coefficient = m_data.coefficient();

    if (originalExponent < 0) {
        const int maxDigits = DBL_DIG;
        uint64_t lastDigit = 0;
        while (countDigits(coefficient) > maxDigits) {
            lastDigit = coefficient % 10;
            coefficient /= 10;
            ++originalExponent;
        }

        if (lastDigit >= 5)
            ++coefficient;

        while (originalExponent < 0 && coefficient && !(coefficient % 10)) {
            coefficient /= 10;
            ++originalExponent;
        }
    }

    const String digits = String::number(coefficient);
    int coefficientLength = static_cast<int>(digits.length());
    const int adjustedExponent = originalExponent + coefficientLength - 1;
    if (originalExponent <= 0 && adjustedExponent >= -6) {
        if (!originalExponent) {
            builder.append(digits);
            return builder.toString();
        }

        if (adjustedExponent >= 0) {
            for (int i = 0; i < coefficientLength; ++i) {
                builder.append(digits[i]);
                if (i == adjustedExponent)
                    builder.append('.');
            }
            return builder.toString();
        }

        builder.appendLiteral("0.");
        for (int i = adjustedExponent + 1; i < 0; ++i)
            builder.append('0');

        builder.append(digits);

    } else {
        builder.append(digits[0]);
        while (coefficientLength >= 2 && digits[coefficientLength - 1] == '0')
            --coefficientLength;
        if (coefficientLength >= 2) {
            builder.append('.');
            for (int i = 1; i < coefficientLength; ++i)
                builder.append(digits[i]);
        }

        if (adjustedExponent) {
            builder.append(adjustedExponent < 0 ? "e" : "e+");
            builder.appendNumber(adjustedExponent);
        }
    }
    return builder.toString();
}

Decimal Decimal::zero(Sign sign)
{
    return Decimal(EncodedData(sign, EncodedData::ClassZero));
}

} // namespace blink
