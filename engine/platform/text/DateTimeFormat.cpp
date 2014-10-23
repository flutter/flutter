/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include "config.h"
#include "platform/text/DateTimeFormat.h"

#include "wtf/ASCIICType.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

static const DateTimeFormat::FieldType lowerCaseToFieldTypeMap[26] = {
    DateTimeFormat::FieldTypePeriod, // a
    DateTimeFormat::FieldTypeInvalid, // b
    DateTimeFormat::FieldTypeLocalDayOfWeekStandAlon, // c
    DateTimeFormat::FieldTypeDayOfMonth, // d
    DateTimeFormat::FieldTypeLocalDayOfWeek, // e
    DateTimeFormat::FieldTypeInvalid, // f
    DateTimeFormat::FieldTypeModifiedJulianDay, // g
    DateTimeFormat::FieldTypeHour12, // h
    DateTimeFormat::FieldTypeInvalid, // i
    DateTimeFormat::FieldTypeInvalid, // j
    DateTimeFormat::FieldTypeHour24, // k
    DateTimeFormat::FieldTypeInvalid, // l
    DateTimeFormat::FieldTypeMinute, // m
    DateTimeFormat::FieldTypeInvalid, // n
    DateTimeFormat::FieldTypeInvalid, // o
    DateTimeFormat::FieldTypeInvalid, // p
    DateTimeFormat::FieldTypeQuaterStandAlone, // q
    DateTimeFormat::FieldTypeInvalid, // r
    DateTimeFormat::FieldTypeSecond, // s
    DateTimeFormat::FieldTypeInvalid, // t
    DateTimeFormat::FieldTypeExtendedYear, // u
    DateTimeFormat::FieldTypeNonLocationZone, // v
    DateTimeFormat::FieldTypeWeekOfYear, // w
    DateTimeFormat::FieldTypeInvalid, // x
    DateTimeFormat::FieldTypeYear, // y
    DateTimeFormat::FieldTypeZone, // z
};

static const DateTimeFormat::FieldType upperCaseToFieldTypeMap[26] = {
    DateTimeFormat::FieldTypeMillisecondsInDay, // A
    DateTimeFormat::FieldTypeInvalid, // B
    DateTimeFormat::FieldTypeInvalid, // C
    DateTimeFormat::FieldTypeDayOfYear, // D
    DateTimeFormat::FieldTypeDayOfWeek, // E
    DateTimeFormat::FieldTypeDayOfWeekInMonth, // F
    DateTimeFormat::FieldTypeEra, // G
    DateTimeFormat::FieldTypeHour23, // H
    DateTimeFormat::FieldTypeInvalid, // I
    DateTimeFormat::FieldTypeInvalid, // J
    DateTimeFormat::FieldTypeHour11, // K
    DateTimeFormat::FieldTypeMonthStandAlone, // L
    DateTimeFormat::FieldTypeMonth, // M
    DateTimeFormat::FieldTypeInvalid, // N
    DateTimeFormat::FieldTypeInvalid, // O
    DateTimeFormat::FieldTypeInvalid, // P
    DateTimeFormat::FieldTypeQuater, // Q
    DateTimeFormat::FieldTypeInvalid, // R
    DateTimeFormat::FieldTypeFractionalSecond, // S
    DateTimeFormat::FieldTypeInvalid, // T
    DateTimeFormat::FieldTypeInvalid, // U
    DateTimeFormat::FieldTypeInvalid, // V
    DateTimeFormat::FieldTypeWeekOfMonth, // W
    DateTimeFormat::FieldTypeInvalid, // X
    DateTimeFormat::FieldTypeYearOfWeekOfYear, // Y
    DateTimeFormat::FieldTypeRFC822Zone, // Z
};

static DateTimeFormat::FieldType mapCharacterToFieldType(const UChar ch)
{
    if (isASCIIUpper(ch))
        return upperCaseToFieldTypeMap[ch - 'A'];

    if (isASCIILower(ch))
        return lowerCaseToFieldTypeMap[ch - 'a'];

    return DateTimeFormat::FieldTypeLiteral;
}

bool DateTimeFormat::parse(const String& source, TokenHandler& tokenHandler)
{
    enum State {
        StateInQuote,
        StateInQuoteQuote,
        StateLiteral,
        StateQuote,
        StateSymbol,
    } state = StateLiteral;

    FieldType fieldType = FieldTypeLiteral;
    StringBuilder literalBuffer;
    int fieldCounter = 0;

    for (unsigned index = 0; index < source.length(); ++index) {
        const UChar ch = source[index];
        switch (state) {
        case StateInQuote:
            if (ch == '\'') {
                state = StateInQuoteQuote;
                break;
            }

            literalBuffer.append(ch);
            break;

        case StateInQuoteQuote:
            if (ch == '\'') {
                literalBuffer.append('\'');
                state = StateInQuote;
                break;
            }

            fieldType = mapCharacterToFieldType(ch);
            if (fieldType == FieldTypeInvalid)
                return false;

            if (fieldType == FieldTypeLiteral) {
                literalBuffer.append(ch);
                state = StateLiteral;
                break;
            }

            if (literalBuffer.length()) {
                tokenHandler.visitLiteral(literalBuffer.toString());
                literalBuffer.clear();
            }

            fieldCounter = 1;
            state = StateSymbol;
            break;

        case StateLiteral:
            if (ch == '\'') {
                state = StateQuote;
                break;
            }

            fieldType = mapCharacterToFieldType(ch);
            if (fieldType == FieldTypeInvalid)
                return false;

            if (fieldType == FieldTypeLiteral) {
                literalBuffer.append(ch);
                break;
            }

            if (literalBuffer.length()) {
                tokenHandler.visitLiteral(literalBuffer.toString());
                literalBuffer.clear();
            }

            fieldCounter = 1;
            state = StateSymbol;
            break;

        case StateQuote:
            literalBuffer.append(ch);
            state = ch == '\'' ? StateLiteral : StateInQuote;
            break;

        case StateSymbol: {
            ASSERT(fieldType != FieldTypeInvalid);
            ASSERT(fieldType != FieldTypeLiteral);
            ASSERT(literalBuffer.isEmpty());

            FieldType fieldType2 = mapCharacterToFieldType(ch);
            if (fieldType2 == FieldTypeInvalid)
                return false;

            if (fieldType == fieldType2) {
                ++fieldCounter;
                break;
            }

            tokenHandler.visitField(fieldType, fieldCounter);

            if (fieldType2 == FieldTypeLiteral) {
                if (ch == '\'') {
                    state = StateQuote;
                } else {
                    literalBuffer.append(ch);
                    state = StateLiteral;
                }
                break;
            }

            fieldCounter = 1;
            fieldType = fieldType2;
            break;
        }
        }
    }

    ASSERT(fieldType != FieldTypeInvalid);

    switch (state) {
    case StateLiteral:
    case StateInQuoteQuote:
        if (literalBuffer.length())
            tokenHandler.visitLiteral(literalBuffer.toString());
        return true;

    case StateQuote:
    case StateInQuote:
        if (literalBuffer.length())
            tokenHandler.visitLiteral(literalBuffer.toString());
        return false;

    case StateSymbol:
        ASSERT(fieldType != FieldTypeLiteral);
        ASSERT(!literalBuffer.length());
        tokenHandler.visitField(fieldType, fieldCounter);
        return true;
    }

    ASSERT_NOT_REACHED();
    return false;
}

static bool isASCIIAlphabetOrQuote(UChar ch)
{
    return isASCIIAlpha(ch) || ch == '\'';
}

void DateTimeFormat::quoteAndAppendLiteral(const String& literal, StringBuilder& buffer)
{
    if (literal.length() <= 0)
        return;

    if (literal.find(isASCIIAlphabetOrQuote) == kNotFound) {
        buffer.append(literal);
        return;
    }

    if (literal.find('\'') == kNotFound) {
        buffer.append('\'');
        buffer.append(literal);
        buffer.append('\'');
        return;
    }

    for (unsigned i = 0; i < literal.length(); ++i) {
        if (literal[i] == '\'') {
            buffer.appendLiteral("''");
        } else {
            String escaped = literal.substring(i);
            escaped.replace("'", "''");
            buffer.append('\'');
            buffer.append(escaped);
            buffer.append('\'');
            return;
        }
    }
}

} // namespace blink
