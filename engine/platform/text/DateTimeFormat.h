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
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */

#ifndef DateTimeFormat_h
#define DateTimeFormat_h

#include "platform/PlatformExport.h"
#include "wtf/Forward.h"

namespace blink {

// DateTimeFormat parses date time format defined in Unicode Technical
// standard 35, Locale Data Markup Language (LDML)[1].
// [1] LDML http://unicode.org/reports/tr35/tr35-6.html#Date_Format_Patterns
class PLATFORM_EXPORT DateTimeFormat {
public:
    enum FieldType {
        FieldTypeInvalid,
        FieldTypeLiteral,

        // Era: AD
        FieldTypeEra = 'G',

        // Year: 1996
        FieldTypeYear = 'y',
        FieldTypeYearOfWeekOfYear = 'Y',
        FieldTypeExtendedYear = 'u',

        // Quater: Q2
        FieldTypeQuater = 'Q',
        FieldTypeQuaterStandAlone = 'q',

        // Month: September
        FieldTypeMonth = 'M',
        FieldTypeMonthStandAlone = 'L',

        // Week: 42
        FieldTypeWeekOfYear = 'w',
        FieldTypeWeekOfMonth = 'W',

        // Day: 12
        FieldTypeDayOfMonth = 'd',
        FieldTypeDayOfYear = 'D',
        FieldTypeDayOfWeekInMonth = 'F',
        FieldTypeModifiedJulianDay = 'g',

        // Week Day: Tuesday
        FieldTypeDayOfWeek = 'E',
        FieldTypeLocalDayOfWeek = 'e',
        FieldTypeLocalDayOfWeekStandAlon = 'c',

        // Period: AM or PM
        FieldTypePeriod = 'a',

        // Hour: 7
        FieldTypeHour12 = 'h',
        FieldTypeHour23 = 'H',
        FieldTypeHour11 = 'K',
        FieldTypeHour24 = 'k',

        // Minute: 59
        FieldTypeMinute = 'm',

        // Second: 12
        FieldTypeSecond = 's',
        FieldTypeFractionalSecond = 'S',
        FieldTypeMillisecondsInDay = 'A',

        // Zone: PDT
        FieldTypeZone = 'z',
        FieldTypeRFC822Zone = 'Z',
        FieldTypeNonLocationZone = 'v',
    };

    class TokenHandler {
    public:
        virtual ~TokenHandler() { }
        virtual void visitField(FieldType, int numberOfPatternCharacters) = 0;
        virtual void visitLiteral(const String&) = 0;
    };

    // Returns true if succeeded, false if failed.
    static bool parse(const String&, TokenHandler&);
    static void quoteAndAppendLiteral(const String&, StringBuilder&);
};

} // namespace blink

#endif // DateTimeFormat_h
