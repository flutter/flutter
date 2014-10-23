/*
 * Copyright (C) 2011,2012 Google Inc. All rights reserved.
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
#include "platform/text/PlatformLocale.h"

#include "platform/text/DateTimeFormat.h"
#include "public/platform/Platform.h"
#include "wtf/MainThread.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

using blink::Platform;
using blink::WebLocalizedString;

class DateTimeStringBuilder : private DateTimeFormat::TokenHandler {
    WTF_MAKE_NONCOPYABLE(DateTimeStringBuilder);
public:
    // The argument objects must be alive until this object dies.
    DateTimeStringBuilder(Locale&, const DateComponents&);

    bool build(const String&);
    String toString();

private:
    // DateTimeFormat::TokenHandler functions.
    virtual void visitField(DateTimeFormat::FieldType, int) OVERRIDE FINAL;
    virtual void visitLiteral(const String&) OVERRIDE FINAL;

    String zeroPadString(const String&, size_t width);
    void appendNumber(int number, size_t width);

    StringBuilder m_builder;
    Locale& m_localizer;
    const DateComponents& m_date;
};

DateTimeStringBuilder::DateTimeStringBuilder(Locale& localizer, const DateComponents& date)
    : m_localizer(localizer)
    , m_date(date)
{
}

bool DateTimeStringBuilder::build(const String& formatString)
{
    m_builder.reserveCapacity(formatString.length());
    return DateTimeFormat::parse(formatString, *this);
}

String DateTimeStringBuilder::zeroPadString(const String& string, size_t width)
{
    if (string.length() >= width)
        return string;
    StringBuilder zeroPaddedStringBuilder;
    zeroPaddedStringBuilder.reserveCapacity(width);
    for (size_t i = string.length(); i < width; ++i)
        zeroPaddedStringBuilder.append('0');
    zeroPaddedStringBuilder.append(string);
    return zeroPaddedStringBuilder.toString();
}

void DateTimeStringBuilder::appendNumber(int number, size_t width)
{
    String zeroPaddedNumberString = zeroPadString(String::number(number), width);
    m_builder.append(m_localizer.convertToLocalizedNumber(zeroPaddedNumberString));
}

void DateTimeStringBuilder::visitField(DateTimeFormat::FieldType fieldType, int numberOfPatternCharacters)
{
    switch (fieldType) {
    case DateTimeFormat::FieldTypeYear:
        // Always use padding width of 4 so it matches DateTimeEditElement.
        appendNumber(m_date.fullYear(), 4);
        return;
    case DateTimeFormat::FieldTypeMonth:
        if (numberOfPatternCharacters == 3) {
            m_builder.append(m_localizer.shortMonthLabels()[m_date.month()]);
        } else if (numberOfPatternCharacters == 4) {
            m_builder.append(m_localizer.monthLabels()[m_date.month()]);
        } else {
            // Always use padding width of 2 so it matches DateTimeEditElement.
            appendNumber(m_date.month() + 1, 2);
        }
        return;
    case DateTimeFormat::FieldTypeMonthStandAlone:
        if (numberOfPatternCharacters == 3) {
            m_builder.append(m_localizer.shortStandAloneMonthLabels()[m_date.month()]);
        } else if (numberOfPatternCharacters == 4) {
            m_builder.append(m_localizer.standAloneMonthLabels()[m_date.month()]);
        } else {
            // Always use padding width of 2 so it matches DateTimeEditElement.
            appendNumber(m_date.month() + 1, 2);
        }
        return;
    case DateTimeFormat::FieldTypeDayOfMonth:
        // Always use padding width of 2 so it matches DateTimeEditElement.
        appendNumber(m_date.monthDay(), 2);
        return;
    case DateTimeFormat::FieldTypeWeekOfYear:
        // Always use padding width of 2 so it matches DateTimeEditElement.
        appendNumber(m_date.week(), 2);
        return;
    case DateTimeFormat::FieldTypePeriod:
        m_builder.append(m_localizer.timeAMPMLabels()[(m_date.hour() >= 12 ? 1 : 0)]);
        return;
    case DateTimeFormat::FieldTypeHour12: {
        int hour12 = m_date.hour() % 12;
        if (!hour12)
            hour12 = 12;
        appendNumber(hour12, numberOfPatternCharacters);
        return;
    }
    case DateTimeFormat::FieldTypeHour23:
        appendNumber(m_date.hour(), numberOfPatternCharacters);
        return;
    case DateTimeFormat::FieldTypeHour11:
        appendNumber(m_date.hour() % 12, numberOfPatternCharacters);
        return;
    case DateTimeFormat::FieldTypeHour24: {
        int hour24 = m_date.hour();
        if (!hour24)
            hour24 = 24;
        appendNumber(hour24, numberOfPatternCharacters);
        return;
    }
    case DateTimeFormat::FieldTypeMinute:
        appendNumber(m_date.minute(), numberOfPatternCharacters);
        return;
    case DateTimeFormat::FieldTypeSecond:
        if (!m_date.millisecond()) {
            appendNumber(m_date.second(), numberOfPatternCharacters);
        } else {
            double second = m_date.second() + m_date.millisecond() / 1000.0;
            String zeroPaddedSecondString = zeroPadString(String::format("%.03f", second), numberOfPatternCharacters + 4);
            m_builder.append(m_localizer.convertToLocalizedNumber(zeroPaddedSecondString));
        }
        return;
    default:
        return;
    }
}

void DateTimeStringBuilder::visitLiteral(const String& text)
{
    ASSERT(text.length());
    m_builder.append(text);
}

String DateTimeStringBuilder::toString()
{
    return m_builder.toString();
}

Locale& Locale::defaultLocale()
{
    static Locale* locale = Locale::create(defaultLanguage()).leakPtr();
    ASSERT(isMainThread());
    return *locale;
}

Locale::~Locale()
{
}

String Locale::queryString(WebLocalizedString::Name name)
{
    // FIXME: Returns a string locazlied for this locale.
    return Platform::current()->queryLocalizedString(name);
}

String Locale::queryString(WebLocalizedString::Name name, const String& parameter)
{
    // FIXME: Returns a string locazlied for this locale.
    return Platform::current()->queryLocalizedString(name, parameter);
}

String Locale::queryString(WebLocalizedString::Name name, const String& parameter1, const String& parameter2)
{
    // FIXME: Returns a string locazlied for this locale.
    return Platform::current()->queryLocalizedString(name, parameter1, parameter2);
}

String Locale::validationMessageTooLongText(unsigned valueLength, int maxLength)
{
    return queryString(WebLocalizedString::ValidationTooLong, convertToLocalizedNumber(String::number(valueLength)), convertToLocalizedNumber(String::number(maxLength)));
}

String Locale::weekFormatInLDML()
{
    String templ = queryString(WebLocalizedString::WeekFormatTemplate);
    // Converts a string like "Week $2, $1" to an LDML date format pattern like
    // "'Week 'ww', 'yyyy".
    StringBuilder builder;
    unsigned literalStart = 0;
    unsigned length = templ.length();
    for (unsigned i = 0; i + 1 < length; ++i) {
        if (templ[i] == '$' && (templ[i + 1] == '1' || templ[i + 1] == '2')) {
            if (literalStart < i)
                DateTimeFormat::quoteAndAppendLiteral(templ.substring(literalStart, i - literalStart), builder);
            builder.append(templ[++i] == '1' ? "yyyy" : "ww");
            literalStart = i + 1;
        }
    }
    if (literalStart < length)
        DateTimeFormat::quoteAndAppendLiteral(templ.substring(literalStart, length - literalStart), builder);
    return builder.toString();
}

void Locale::setLocaleData(const Vector<String, DecimalSymbolsSize>& symbols, const String& positivePrefix, const String& positiveSuffix, const String& negativePrefix, const String& negativeSuffix)
{
    for (size_t i = 0; i < symbols.size(); ++i) {
        ASSERT(!symbols[i].isEmpty());
        m_decimalSymbols[i] = symbols[i];
    }
    m_positivePrefix = positivePrefix;
    m_positiveSuffix = positiveSuffix;
    m_negativePrefix = negativePrefix;
    m_negativeSuffix = negativeSuffix;
    ASSERT(!m_positivePrefix.isEmpty() || !m_positiveSuffix.isEmpty() || !m_negativePrefix.isEmpty() || !m_negativeSuffix.isEmpty());
    m_hasLocaleData = true;
}

String Locale::convertToLocalizedNumber(const String& input)
{
    initializeLocaleData();
    if (!m_hasLocaleData || input.isEmpty())
        return input;

    unsigned i = 0;
    bool isNegative = false;
    StringBuilder builder;
    builder.reserveCapacity(input.length());

    if (input[0] == '-') {
        ++i;
        isNegative = true;
        builder.append(m_negativePrefix);
    } else {
        builder.append(m_positivePrefix);
    }

    for (; i < input.length(); ++i) {
        switch (input[i]) {
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
            builder.append(m_decimalSymbols[input[i] - '0']);
            break;
        case '.':
            builder.append(m_decimalSymbols[DecimalSeparatorIndex]);
            break;
        default:
            ASSERT_NOT_REACHED();
        }
    }

    builder.append(isNegative ? m_negativeSuffix : m_positiveSuffix);

    return builder.toString();
}

static bool matches(const String& text, unsigned position, const String& part)
{
    if (part.isEmpty())
        return true;
    if (position + part.length() > text.length())
        return false;
    for (unsigned i = 0; i < part.length(); ++i) {
        if (text[position + i] != part[i])
            return false;
    }
    return true;
}

bool Locale::detectSignAndGetDigitRange(const String& input, bool& isNegative, unsigned& startIndex, unsigned& endIndex)
{
    startIndex = 0;
    endIndex = input.length();
    if (m_negativePrefix.isEmpty() && m_negativeSuffix.isEmpty()) {
        if (input.startsWith(m_positivePrefix) && input.endsWith(m_positiveSuffix)) {
            isNegative = false;
            startIndex = m_positivePrefix.length();
            endIndex -= m_positiveSuffix.length();
        } else {
            isNegative = true;
        }
    } else {
        if (input.startsWith(m_negativePrefix) && input.endsWith(m_negativeSuffix)) {
            isNegative = true;
            startIndex = m_negativePrefix.length();
            endIndex -= m_negativeSuffix.length();
        } else {
            isNegative = false;
            if (input.startsWith(m_positivePrefix) && input.endsWith(m_positiveSuffix)) {
                startIndex = m_positivePrefix.length();
                endIndex -= m_positiveSuffix.length();
            } else {
                return false;
            }
        }
    }
    return true;
}

unsigned Locale::matchedDecimalSymbolIndex(const String& input, unsigned& position)
{
    for (unsigned symbolIndex = 0; symbolIndex < DecimalSymbolsSize; ++symbolIndex) {
        if (m_decimalSymbols[symbolIndex].length() && matches(input, position, m_decimalSymbols[symbolIndex])) {
            position += m_decimalSymbols[symbolIndex].length();
            return symbolIndex;
        }
    }
    return DecimalSymbolsSize;
}

String Locale::convertFromLocalizedNumber(const String& localized)
{
    initializeLocaleData();
    String input = localized.removeCharacters(isASCIISpace);
    if (!m_hasLocaleData || input.isEmpty())
        return input;

    bool isNegative;
    unsigned startIndex;
    unsigned endIndex;
    if (!detectSignAndGetDigitRange(input, isNegative, startIndex, endIndex))
        return input;

    StringBuilder builder;
    builder.reserveCapacity(input.length());
    if (isNegative)
        builder.append('-');
    for (unsigned i = startIndex; i < endIndex;) {
        unsigned symbolIndex = matchedDecimalSymbolIndex(input, i);
        if (symbolIndex >= DecimalSymbolsSize)
            return input;
        if (symbolIndex == DecimalSeparatorIndex)
            builder.append('.');
        else if (symbolIndex == GroupSeparatorIndex)
            return input;
        else
            builder.append(static_cast<UChar>('0' + symbolIndex));
    }
    return builder.toString();
}

String Locale::formatDateTime(const DateComponents& date, FormatType formatType)
{
    if (date.type() == DateComponents::Invalid)
        return String();

    DateTimeStringBuilder builder(*this, date);
    switch (date.type()) {
    case DateComponents::Time:
        builder.build(formatType == FormatTypeShort ? shortTimeFormat() : timeFormat());
        break;
    case DateComponents::Date:
        builder.build(dateFormat());
        break;
    case DateComponents::Month:
        builder.build(formatType == FormatTypeShort ? shortMonthFormat() : monthFormat());
        break;
    case DateComponents::Week:
        builder.build(weekFormatInLDML());
        break;
    case DateComponents::DateTime:
    case DateComponents::DateTimeLocal:
        builder.build(formatType == FormatTypeShort ? dateTimeFormatWithoutSeconds() : dateTimeFormatWithSeconds());
        break;
    case DateComponents::Invalid:
        ASSERT_NOT_REACHED();
        break;
    }
    return builder.toString();
}

}
