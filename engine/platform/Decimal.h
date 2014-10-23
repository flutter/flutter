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

#ifndef Decimal_h
#define Decimal_h

#include "platform/PlatformExport.h"
#include "wtf/Assertions.h"
#include "wtf/text/WTFString.h"
#include <stdint.h>

namespace blink {

namespace DecimalPrivate {
class SpecialValueHandler;
}

// This class represents decimal base floating point number.
//
// FIXME: Once all C++ compiler support decimal type, we should replace this
// class to compiler supported one. See below URI for current status of decimal
// type for C++: // http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2006/n1977.html
class PLATFORM_EXPORT Decimal {
    WTF_MAKE_FAST_ALLOCATED;
public:
    enum Sign {
        Positive,
        Negative,
    };

    // You should not use EncodedData other than unit testing.
    class EncodedData {
        // For accessing FormatClass.
        friend class Decimal;
        friend class DecimalPrivate::SpecialValueHandler;
    public:
        EncodedData(Sign, int exponent, uint64_t coefficient);

        bool operator==(const EncodedData&) const;
        bool operator!=(const EncodedData& another) const { return !operator==(another); }

        uint64_t coefficient() const { return m_coefficient; }
        int countDigits() const;
        int exponent() const { return m_exponent; }
        bool isFinite() const { return !isSpecial(); }
        bool isInfinity() const { return m_formatClass == ClassInfinity; }
        bool isNaN() const { return m_formatClass == ClassNaN; }
        bool isSpecial() const { return m_formatClass == ClassInfinity || m_formatClass == ClassNaN; }
        bool isZero() const { return m_formatClass == ClassZero; }
        Sign sign() const { return m_sign; }
        void setSign(Sign sign) { m_sign = sign; }

    private:
        enum FormatClass {
            ClassInfinity,
            ClassNormal,
            ClassNaN,
            ClassZero,
        };

        EncodedData(Sign, FormatClass);
        FormatClass formatClass() const { return m_formatClass; }

        uint64_t m_coefficient;
        int16_t m_exponent;
        FormatClass m_formatClass;
        Sign m_sign;
    };

    Decimal(int32_t = 0);
    Decimal(Sign, int exponent, uint64_t coefficient);
    Decimal(const Decimal&);

    Decimal& operator=(const Decimal&);
    Decimal& operator+=(const Decimal&);
    Decimal& operator-=(const Decimal&);
    Decimal& operator*=(const Decimal&);
    Decimal& operator/=(const Decimal&);

    Decimal operator-() const;

    bool operator==(const Decimal&) const;
    bool operator!=(const Decimal&) const;
    bool operator<(const Decimal&) const;
    bool operator<=(const Decimal&) const;
    bool operator>(const Decimal&) const;
    bool operator>=(const Decimal&) const;

    Decimal operator+(const Decimal&) const;
    Decimal operator-(const Decimal&) const;
    Decimal operator*(const Decimal&) const;
    Decimal operator/(const Decimal&) const;

    int exponent() const
    {
        ASSERT(isFinite());
        return m_data.exponent();
    }

    bool isFinite() const { return m_data.isFinite(); }
    bool isInfinity() const { return m_data.isInfinity(); }
    bool isNaN() const { return m_data.isNaN(); }
    bool isNegative() const { return sign() == Negative; }
    bool isPositive() const { return sign() == Positive; }
    bool isSpecial() const { return m_data.isSpecial(); }
    bool isZero() const { return m_data.isZero(); }

    Decimal abs() const;
    Decimal ceiling() const;
    Decimal floor() const;
    Decimal remainder(const Decimal&) const;
    Decimal round() const;

    double toDouble() const;
    // Note: toString method supports infinity and nan but fromString not.
    String toString() const;

    static Decimal fromDouble(double);
    // fromString supports following syntax EBNF:
    //  number ::= sign? digit+ ('.' digit*) (exponent-marker sign? digit+)?
    //          | sign? '.' digit+ (exponent-marker sign? digit+)?
    //  sign ::= '+' | '-'
    //  exponent-marker ::= 'e' | 'E'
    //  digit ::= '0' | '1' | ... | '9'
    // Note: fromString doesn't support "infinity" and "nan".
    static Decimal fromString(const String&);
    static Decimal infinity(Sign);
    static Decimal nan();
    static Decimal zero(Sign);

    // You should not use below methods. We expose them for unit testing.
    explicit Decimal(const EncodedData&);
    const EncodedData& value() const { return m_data; }

private:
    struct AlignedOperands {
        uint64_t lhsCoefficient;
        uint64_t rhsCoefficient;
        int exponent;
    };

    Decimal(double);
    Decimal compareTo(const Decimal&) const;

    static AlignedOperands alignOperands(const Decimal& lhs, const Decimal& rhs);
    static inline Sign invertSign(Sign sign) { return sign == Negative ? Positive : Negative; }

    Sign sign() const { return m_data.sign(); }

    EncodedData m_data;
};

} // namespace blink

#endif // Decimal_h
