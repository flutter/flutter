/*
 * Copyright (c) 2012, Google Inc. All rights reserved.
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

#ifndef LayoutUnit_h
#define LayoutUnit_h

#include "wtf/Assertions.h"
#include "wtf/MathExtras.h"
#include "wtf/SaturatedArithmetic.h"
#include <limits.h>
#include <limits>
#include <stdlib.h>

namespace blink {

#if !ERROR_DISABLED

#define REPORT_OVERFLOW(doesOverflow) ((void)0)

#else

#define REPORT_OVERFLOW(doesOverflow) do \
    if (!(doesOverflow)) { \
        WTFReportError(__FILE__, __LINE__, WTF_PRETTY_FUNCTION, "!(%s)", #doesOverflow); \
    } \
while (0)

#endif

static const int kLayoutUnitFractionalBits = 6;
static const int kFixedPointDenominator = 1 << kLayoutUnitFractionalBits;

const int intMaxForLayoutUnit = INT_MAX / kFixedPointDenominator;
const int intMinForLayoutUnit = INT_MIN / kFixedPointDenominator;

class LayoutUnit {
public:
    LayoutUnit() : m_value(0) { }
    LayoutUnit(int value) { setValue(value); }
    LayoutUnit(unsigned short value) { setValue(value); }
    LayoutUnit(unsigned value) { setValue(value); }
    LayoutUnit(unsigned long value) { m_value = clampTo<int>(value * kFixedPointDenominator); }
    LayoutUnit(unsigned long long value) { m_value = clampTo<int>(value * kFixedPointDenominator); }
    LayoutUnit(float value) { m_value = clampTo<int>(value * kFixedPointDenominator); }
    LayoutUnit(double value) { m_value = clampTo<int>(value * kFixedPointDenominator); }

    static LayoutUnit fromFloatCeil(float value)
    {
        LayoutUnit v;
        v.m_value = clampToInteger(ceilf(value * kFixedPointDenominator));
        return v;
    }

    static LayoutUnit fromFloatFloor(float value)
    {
        LayoutUnit v;
        v.m_value = clampToInteger(floorf(value * kFixedPointDenominator));
        return v;
    }

    static LayoutUnit fromFloatRound(float value)
    {
        if (value >= 0)
            return clamp(value + epsilon() / 2.0f);
        return clamp(value - epsilon() / 2.0f);
    }

    int toInt() const { return m_value / kFixedPointDenominator; }
    float toFloat() const { return static_cast<float>(m_value) / kFixedPointDenominator; }
    double toDouble() const { return static_cast<double>(m_value) / kFixedPointDenominator; }
    float ceilToFloat() const
    {
        float floatValue = toFloat();
        if (static_cast<int>(floatValue * kFixedPointDenominator) == m_value)
            return floatValue;
        if (floatValue > 0)
            return nextafterf(floatValue, std::numeric_limits<float>::max());
        return nextafterf(floatValue, std::numeric_limits<float>::min());
    }
    unsigned toUnsigned() const { REPORT_OVERFLOW(m_value >= 0); return toInt(); }

    operator int() const { return toInt(); }
    operator unsigned() const { return toUnsigned(); }
    operator double() const { return toDouble(); }
    operator bool() const { return m_value; }

    LayoutUnit operator++(int)
    {
        m_value += kFixedPointDenominator;
        return *this;
    }

    inline int rawValue() const { return m_value; }
    inline void setRawValue(int value) { m_value = value; }
    void setRawValue(long long value)
    {
        REPORT_OVERFLOW(value > std::numeric_limits<int>::min() && value < std::numeric_limits<int>::max());
        m_value = static_cast<int>(value);
    }

    LayoutUnit abs() const
    {
        LayoutUnit returnValue;
        returnValue.setRawValue(::abs(m_value));
        return returnValue;
    }
#if OS(MACOSX)
    int wtf_ceil() const
#else
    int ceil() const
#endif
    {
        if (UNLIKELY(m_value >= INT_MAX - kFixedPointDenominator + 1))
            return intMaxForLayoutUnit;

        if (m_value >= 0)
            return (m_value + kFixedPointDenominator - 1) / kFixedPointDenominator;
        return toInt();
    }
    ALWAYS_INLINE int round() const
    {
        return saturatedAddition(rawValue(), kFixedPointDenominator / 2) >> kLayoutUnitFractionalBits;
    }

    int floor() const
    {
        if (UNLIKELY(m_value <= INT_MIN + kFixedPointDenominator - 1))
            return intMinForLayoutUnit;

        return m_value >> kLayoutUnitFractionalBits;
    }

    LayoutUnit fraction() const
    {
        // Add the fraction to the size (as opposed to the full location) to avoid overflows.
        // Compute fraction using the mod operator to preserve the sign of the value as it may affect rounding.
        LayoutUnit fraction;
        fraction.setRawValue(rawValue() % kFixedPointDenominator);
        return fraction;
    }

    bool mightBeSaturated() const
    {
        return rawValue() == std::numeric_limits<int>::max()
            || rawValue() == std::numeric_limits<int>::min();
    }

    static float epsilon() { return 1.0f / kFixedPointDenominator; }

    static const LayoutUnit max()
    {
        LayoutUnit m;
        m.m_value = std::numeric_limits<int>::max();
        return m;
    }
    static const LayoutUnit min()
    {
        LayoutUnit m;
        m.m_value = std::numeric_limits<int>::min();
        return m;
    }

    // Versions of max/min that are slightly smaller/larger than max/min() to allow for roinding without overflowing.
    static const LayoutUnit nearlyMax()
    {
        LayoutUnit m;
        m.m_value = std::numeric_limits<int>::max() - kFixedPointDenominator / 2;
        return m;
    }
    static const LayoutUnit nearlyMin()
    {
        LayoutUnit m;
        m.m_value = std::numeric_limits<int>::min() + kFixedPointDenominator / 2;
        return m;
    }

    static LayoutUnit clamp(double value)
    {
        return clampTo<LayoutUnit>(value, LayoutUnit::min(), LayoutUnit::max());
    }

private:
    static bool isInBounds(int value)
    {
        return ::abs(value) <= std::numeric_limits<int>::max() / kFixedPointDenominator;
    }
    static bool isInBounds(unsigned value)
    {
        return value <= static_cast<unsigned>(std::numeric_limits<int>::max()) / kFixedPointDenominator;
    }
    static bool isInBounds(double value)
    {
        return ::fabs(value) <= std::numeric_limits<int>::max() / kFixedPointDenominator;
    }

    ALWAYS_INLINE void setValue(int value)
    {
        m_value = saturatedSet(value, kLayoutUnitFractionalBits);
    }

    inline void setValue(unsigned value)
    {
        m_value = saturatedSet(value, kLayoutUnitFractionalBits);
    }

    int m_value;
};

inline bool operator<=(const LayoutUnit& a, const LayoutUnit& b)
{
    return a.rawValue() <= b.rawValue();
}

inline bool operator<=(const LayoutUnit& a, float b)
{
    return a.toFloat() <= b;
}

inline bool operator<=(const LayoutUnit& a, int b)
{
    return a <= LayoutUnit(b);
}

inline bool operator<=(const float a, const LayoutUnit& b)
{
    return a <= b.toFloat();
}

inline bool operator<=(const int a, const LayoutUnit& b)
{
    return LayoutUnit(a) <= b;
}

inline bool operator>=(const LayoutUnit& a, const LayoutUnit& b)
{
    return a.rawValue() >= b.rawValue();
}

inline bool operator>=(const LayoutUnit& a, int b)
{
    return a >= LayoutUnit(b);
}

inline bool operator>=(const float a, const LayoutUnit& b)
{
    return a >= b.toFloat();
}

inline bool operator>=(const LayoutUnit& a, float b)
{
    return a.toFloat() >= b;
}

inline bool operator>=(const int a, const LayoutUnit& b)
{
    return LayoutUnit(a) >= b;
}

inline bool operator<(const LayoutUnit& a, const LayoutUnit& b)
{
    return a.rawValue() < b.rawValue();
}

inline bool operator<(const LayoutUnit& a, int b)
{
    return a < LayoutUnit(b);
}

inline bool operator<(const LayoutUnit& a, float b)
{
    return a.toFloat() < b;
}

inline bool operator<(const LayoutUnit& a, double b)
{
    return a.toDouble() < b;
}

inline bool operator<(const int a, const LayoutUnit& b)
{
    return LayoutUnit(a) < b;
}

inline bool operator<(const float a, const LayoutUnit& b)
{
    return a < b.toFloat();
}

inline bool operator>(const LayoutUnit& a, const LayoutUnit& b)
{
    return a.rawValue() > b.rawValue();
}

inline bool operator>(const LayoutUnit& a, double b)
{
    return a.toDouble() > b;
}

inline bool operator>(const LayoutUnit& a, float b)
{
    return a.toFloat() > b;
}

inline bool operator>(const LayoutUnit& a, int b)
{
    return a > LayoutUnit(b);
}

inline bool operator>(const int a, const LayoutUnit& b)
{
    return LayoutUnit(a) > b;
}

inline bool operator>(const float a, const LayoutUnit& b)
{
    return a > b.toFloat();
}

inline bool operator>(const double a, const LayoutUnit& b)
{
    return a > b.toDouble();
}

inline bool operator!=(const LayoutUnit& a, const LayoutUnit& b)
{
    return a.rawValue() != b.rawValue();
}

inline bool operator!=(const LayoutUnit& a, float b)
{
    return a != LayoutUnit(b);
}

inline bool operator!=(const int a, const LayoutUnit& b)
{
    return LayoutUnit(a) != b;
}

inline bool operator!=(const LayoutUnit& a, int b)
{
    return a != LayoutUnit(b);
}

inline bool operator==(const LayoutUnit& a, const LayoutUnit& b)
{
    return a.rawValue() == b.rawValue();
}

inline bool operator==(const LayoutUnit& a, int b)
{
    return a == LayoutUnit(b);
}

inline bool operator==(const int a, const LayoutUnit& b)
{
    return LayoutUnit(a) == b;
}

inline bool operator==(const LayoutUnit& a, float b)
{
    return a.toFloat() == b;
}

inline bool operator==(const float a, const LayoutUnit& b)
{
    return a == b.toFloat();
}

// For multiplication that's prone to overflow, this bounds it to LayoutUnit::max() and ::min()
inline LayoutUnit boundedMultiply(const LayoutUnit& a, const LayoutUnit& b)
{
    int64_t result = static_cast<int64_t>(a.rawValue()) * static_cast<int64_t>(b.rawValue()) / kFixedPointDenominator;
    int32_t high = static_cast<int32_t>(result >> 32);
    int32_t low = static_cast<int32_t>(result);
    uint32_t saturated = (static_cast<uint32_t>(a.rawValue() ^ b.rawValue()) >> 31) + std::numeric_limits<int>::max();
    // If the higher 32 bits does not match the lower 32 with sign extension the operation overflowed.
    if (high != low >> 31)
        result = saturated;

    LayoutUnit returnVal;
    returnVal.setRawValue(static_cast<int>(result));
    return returnVal;
}

inline LayoutUnit operator*(const LayoutUnit& a, const LayoutUnit& b)
{
    return boundedMultiply(a, b);
}

inline double operator*(const LayoutUnit& a, double b)
{
    return a.toDouble() * b;
}

inline float operator*(const LayoutUnit& a, float b)
{
    return a.toFloat() * b;
}

inline LayoutUnit operator*(const LayoutUnit& a, int b)
{
    return a * LayoutUnit(b);
}

inline LayoutUnit operator*(const LayoutUnit& a, unsigned short b)
{
    return a * LayoutUnit(b);
}

inline LayoutUnit operator*(const LayoutUnit& a, unsigned b)
{
    return a * LayoutUnit(b);
}

inline LayoutUnit operator*(const LayoutUnit& a, unsigned long b)
{
    return a * LayoutUnit(b);
}

inline LayoutUnit operator*(const LayoutUnit& a, unsigned long long b)
{
    return a * LayoutUnit(b);
}

inline LayoutUnit operator*(unsigned short a, const LayoutUnit& b)
{
    return LayoutUnit(a) * b;
}

inline LayoutUnit operator*(unsigned a, const LayoutUnit& b)
{
    return LayoutUnit(a) * b;
}

inline LayoutUnit operator*(unsigned long a, const LayoutUnit& b)
{
    return LayoutUnit(a) * b;
}

inline LayoutUnit operator*(unsigned long long a, const LayoutUnit& b)
{
    return LayoutUnit(a) * b;
}

inline LayoutUnit operator*(const int a, const LayoutUnit& b)
{
    return LayoutUnit(a) * b;
}

inline float operator*(const float a, const LayoutUnit& b)
{
    return a * b.toFloat();
}

inline double operator*(const double a, const LayoutUnit& b)
{
    return a * b.toDouble();
}

inline LayoutUnit operator/(const LayoutUnit& a, const LayoutUnit& b)
{
    LayoutUnit returnVal;
    long long rawVal = static_cast<long long>(kFixedPointDenominator) * a.rawValue() / b.rawValue();
    returnVal.setRawValue(clampTo<int>(rawVal));
    return returnVal;
}

inline float operator/(const LayoutUnit& a, float b)
{
    return a.toFloat() / b;
}

inline double operator/(const LayoutUnit& a, double b)
{
    return a.toDouble() / b;
}

inline LayoutUnit operator/(const LayoutUnit& a, int b)
{
    return a / LayoutUnit(b);
}

inline LayoutUnit operator/(const LayoutUnit& a, unsigned short b)
{
    return a / LayoutUnit(b);
}

inline LayoutUnit operator/(const LayoutUnit& a, unsigned b)
{
    return a / LayoutUnit(b);
}

inline LayoutUnit operator/(const LayoutUnit& a, unsigned long b)
{
    return a / LayoutUnit(b);
}

inline LayoutUnit operator/(const LayoutUnit& a, unsigned long long b)
{
    return a / LayoutUnit(b);
}

inline float operator/(const float a, const LayoutUnit& b)
{
    return a / b.toFloat();
}

inline double operator/(const double a, const LayoutUnit& b)
{
    return a / b.toDouble();
}

inline LayoutUnit operator/(const int a, const LayoutUnit& b)
{
    return LayoutUnit(a) / b;
}

inline LayoutUnit operator/(unsigned short a, const LayoutUnit& b)
{
    return LayoutUnit(a) / b;
}

inline LayoutUnit operator/(unsigned a, const LayoutUnit& b)
{
    return LayoutUnit(a) / b;
}

inline LayoutUnit operator/(unsigned long a, const LayoutUnit& b)
{
    return LayoutUnit(a) / b;
}

inline LayoutUnit operator/(unsigned long long a, const LayoutUnit& b)
{
    return LayoutUnit(a) / b;
}

ALWAYS_INLINE LayoutUnit operator+(const LayoutUnit& a, const LayoutUnit& b)
{
    LayoutUnit returnVal;
    returnVal.setRawValue(saturatedAddition(a.rawValue(), b.rawValue()));
    return returnVal;
}

inline LayoutUnit operator+(const LayoutUnit& a, int b)
{
    return a + LayoutUnit(b);
}

inline float operator+(const LayoutUnit& a, float b)
{
    return a.toFloat() + b;
}

inline double operator+(const LayoutUnit& a, double b)
{
    return a.toDouble() + b;
}

inline LayoutUnit operator+(const int a, const LayoutUnit& b)
{
    return LayoutUnit(a) + b;
}

inline float operator+(const float a, const LayoutUnit& b)
{
    return a + b.toFloat();
}

inline double operator+(const double a, const LayoutUnit& b)
{
    return a + b.toDouble();
}

ALWAYS_INLINE LayoutUnit operator-(const LayoutUnit& a, const LayoutUnit& b)
{
    LayoutUnit returnVal;
    returnVal.setRawValue(saturatedSubtraction(a.rawValue(), b.rawValue()));
    return returnVal;
}

inline LayoutUnit operator-(const LayoutUnit& a, int b)
{
    return a - LayoutUnit(b);
}

inline LayoutUnit operator-(const LayoutUnit& a, unsigned b)
{
    return a - LayoutUnit(b);
}

inline float operator-(const LayoutUnit& a, float b)
{
    return a.toFloat() - b;
}

inline LayoutUnit operator-(const int a, const LayoutUnit& b)
{
    return LayoutUnit(a) - b;
}

inline float operator-(const float a, const LayoutUnit& b)
{
    return a - b.toFloat();
}

inline LayoutUnit operator-(const LayoutUnit& a)
{
    LayoutUnit returnVal;
    returnVal.setRawValue(-a.rawValue());
    return returnVal;
}

// For returning the remainder after a division with integer results.
inline LayoutUnit intMod(const LayoutUnit& a, const LayoutUnit& b)
{
    // This calculates the modulo so that: a = static_cast<int>(a / b) * b + intMod(a, b).
    LayoutUnit returnVal;
    returnVal.setRawValue(a.rawValue() % b.rawValue());
    return returnVal;
}

inline LayoutUnit operator%(const LayoutUnit& a, const LayoutUnit& b)
{
    // This calculates the modulo so that: a = (a / b) * b + a % b.
    LayoutUnit returnVal;
    long long rawVal = (static_cast<long long>(kFixedPointDenominator) * a.rawValue()) % b.rawValue();
    returnVal.setRawValue(rawVal / kFixedPointDenominator);
    return returnVal;
}

inline LayoutUnit operator%(const LayoutUnit& a, int b)
{
    return a % LayoutUnit(b);
}

inline LayoutUnit operator%(int a, const LayoutUnit& b)
{
    return LayoutUnit(a) % b;
}

inline LayoutUnit& operator+=(LayoutUnit& a, const LayoutUnit& b)
{
    a.setRawValue(saturatedAddition(a.rawValue(), b.rawValue()));
    return a;
}

inline LayoutUnit& operator+=(LayoutUnit& a, int b)
{
    a = a + b;
    return a;
}

inline LayoutUnit& operator+=(LayoutUnit& a, float b)
{
    a = a + b;
    return a;
}

inline float& operator+=(float& a, const LayoutUnit& b)
{
    a = a + b;
    return a;
}

inline LayoutUnit& operator-=(LayoutUnit& a, int b)
{
    a = a - b;
    return a;
}

inline LayoutUnit& operator-=(LayoutUnit& a, const LayoutUnit& b)
{
    a.setRawValue(saturatedSubtraction(a.rawValue(), b.rawValue()));
    return a;
}

inline LayoutUnit& operator-=(LayoutUnit& a, float b)
{
    a = a - b;
    return a;
}

inline float& operator-=(float& a, const LayoutUnit& b)
{
    a = a - b;
    return a;
}

inline LayoutUnit& operator*=(LayoutUnit& a, const LayoutUnit& b)
{
    a = a * b;
    return a;
}
// operator*=(LayoutUnit& a, int b) is supported by the operator above plus LayoutUnit(int).

inline LayoutUnit& operator*=(LayoutUnit& a, float b)
{
    a = a * b;
    return a;
}

inline float& operator*=(float& a, const LayoutUnit& b)
{
    a = a * b;
    return a;
}

inline LayoutUnit& operator/=(LayoutUnit& a, const LayoutUnit& b)
{
    a = a / b;
    return a;
}
// operator/=(LayoutUnit& a, int b) is supported by the operator above plus LayoutUnit(int).

inline LayoutUnit& operator/=(LayoutUnit& a, float b)
{
    a = a / b;
    return a;
}

inline float& operator/=(float& a, const LayoutUnit& b)
{
    a = a / b;
    return a;
}

inline int snapSizeToPixel(LayoutUnit size, LayoutUnit location)
{
    LayoutUnit fraction = location.fraction();
    return (fraction + size).round() - fraction.round();
}

inline int roundToInt(LayoutUnit value)
{
    return value.round();
}

inline int floorToInt(LayoutUnit value)
{
    return value.floor();
}

inline LayoutUnit absoluteValue(const LayoutUnit& value)
{
    return value.abs();
}

inline LayoutUnit layoutMod(const LayoutUnit& numerator, const LayoutUnit& denominator)
{
    return numerator % denominator;
}

inline bool isIntegerValue(const LayoutUnit value)
{
    return value.toInt() == value;
}

inline LayoutUnit clampToLayoutUnit(LayoutUnit value, LayoutUnit min, LayoutUnit max)
{
    if (value >= max)
        return max;
    if (value <= min)
        return min;
    return value;
}

} // namespace blink

#endif // LayoutUnit_h
