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
#include "platform/text/LocaleICU.h"

#include <unicode/udatpg.h>
#include <unicode/uloc.h>
#include <limits>
#include "wtf/DateMath.h"
#include "wtf/PassOwnPtr.h"
#include "wtf/text/StringBuffer.h"
#include "wtf/text/StringBuilder.h"

using namespace icu;

namespace blink {

PassOwnPtr<Locale> Locale::create(const String& locale)
{
    return LocaleICU::create(locale.utf8().data());
}

LocaleICU::LocaleICU(const char* locale)
    : m_locale(locale)
    , m_numberFormat(0)
    , m_shortDateFormat(0)
    , m_didCreateDecimalFormat(false)
    , m_didCreateShortDateFormat(false)
    , m_firstDayOfWeek(0)
    , m_mediumTimeFormat(0)
    , m_shortTimeFormat(0)
    , m_didCreateTimeFormat(false)
{
}

LocaleICU::~LocaleICU()
{
    unum_close(m_numberFormat);
    udat_close(m_shortDateFormat);
    udat_close(m_mediumTimeFormat);
    udat_close(m_shortTimeFormat);
}

PassOwnPtr<LocaleICU> LocaleICU::create(const char* localeString)
{
    return adoptPtr(new LocaleICU(localeString));
}

String LocaleICU::decimalSymbol(UNumberFormatSymbol symbol)
{
    UErrorCode status = U_ZERO_ERROR;
    int32_t bufferLength = unum_getSymbol(m_numberFormat, symbol, 0, 0, &status);
    ASSERT(U_SUCCESS(status) || status == U_BUFFER_OVERFLOW_ERROR);
    if (U_FAILURE(status) && status != U_BUFFER_OVERFLOW_ERROR)
        return String();
    StringBuffer<UChar> buffer(bufferLength);
    status = U_ZERO_ERROR;
    unum_getSymbol(m_numberFormat, symbol, buffer.characters(), bufferLength, &status);
    if (U_FAILURE(status))
        return String();
    return String::adopt(buffer);
}

String LocaleICU::decimalTextAttribute(UNumberFormatTextAttribute tag)
{
    UErrorCode status = U_ZERO_ERROR;
    int32_t bufferLength = unum_getTextAttribute(m_numberFormat, tag, 0, 0, &status);
    ASSERT(U_SUCCESS(status) || status == U_BUFFER_OVERFLOW_ERROR);
    if (U_FAILURE(status) && status != U_BUFFER_OVERFLOW_ERROR)
        return String();
    StringBuffer<UChar> buffer(bufferLength);
    status = U_ZERO_ERROR;
    unum_getTextAttribute(m_numberFormat, tag, buffer.characters(), bufferLength, &status);
    ASSERT(U_SUCCESS(status));
    if (U_FAILURE(status))
        return String();
    return String::adopt(buffer);
}

void LocaleICU::initializeLocaleData()
{
    if (m_didCreateDecimalFormat)
        return;
    m_didCreateDecimalFormat = true;
    UErrorCode status = U_ZERO_ERROR;
    m_numberFormat = unum_open(UNUM_DECIMAL, 0, 0, m_locale.data(), 0, &status);
    if (!U_SUCCESS(status))
        return;

    Vector<String, DecimalSymbolsSize> symbols;
    symbols.append(decimalSymbol(UNUM_ZERO_DIGIT_SYMBOL));
    symbols.append(decimalSymbol(UNUM_ONE_DIGIT_SYMBOL));
    symbols.append(decimalSymbol(UNUM_TWO_DIGIT_SYMBOL));
    symbols.append(decimalSymbol(UNUM_THREE_DIGIT_SYMBOL));
    symbols.append(decimalSymbol(UNUM_FOUR_DIGIT_SYMBOL));
    symbols.append(decimalSymbol(UNUM_FIVE_DIGIT_SYMBOL));
    symbols.append(decimalSymbol(UNUM_SIX_DIGIT_SYMBOL));
    symbols.append(decimalSymbol(UNUM_SEVEN_DIGIT_SYMBOL));
    symbols.append(decimalSymbol(UNUM_EIGHT_DIGIT_SYMBOL));
    symbols.append(decimalSymbol(UNUM_NINE_DIGIT_SYMBOL));
    symbols.append(decimalSymbol(UNUM_DECIMAL_SEPARATOR_SYMBOL));
    symbols.append(decimalSymbol(UNUM_GROUPING_SEPARATOR_SYMBOL));
    ASSERT(symbols.size() == DecimalSymbolsSize);
    setLocaleData(symbols, decimalTextAttribute(UNUM_POSITIVE_PREFIX), decimalTextAttribute(UNUM_POSITIVE_SUFFIX), decimalTextAttribute(UNUM_NEGATIVE_PREFIX), decimalTextAttribute(UNUM_NEGATIVE_SUFFIX));
}

bool LocaleICU::initializeShortDateFormat()
{
    if (m_didCreateShortDateFormat)
        return m_shortDateFormat;
    m_shortDateFormat = openDateFormat(UDAT_NONE, UDAT_SHORT);
    m_didCreateShortDateFormat = true;
    return m_shortDateFormat;
}

UDateFormat* LocaleICU::openDateFormat(UDateFormatStyle timeStyle, UDateFormatStyle dateStyle) const
{
    const UChar gmtTimezone[3] = {'G', 'M', 'T'};
    UErrorCode status = U_ZERO_ERROR;
    return udat_open(timeStyle, dateStyle, m_locale.data(), gmtTimezone, WTF_ARRAY_LENGTH(gmtTimezone), 0, -1, &status);
}

static String getDateFormatPattern(const UDateFormat* dateFormat)
{
    if (!dateFormat)
        return emptyString();

    UErrorCode status = U_ZERO_ERROR;
    int32_t length = udat_toPattern(dateFormat, TRUE, 0, 0, &status);
    if (status != U_BUFFER_OVERFLOW_ERROR || !length)
        return emptyString();
    StringBuffer<UChar> buffer(length);
    status = U_ZERO_ERROR;
    udat_toPattern(dateFormat, TRUE, buffer.characters(), length, &status);
    if (U_FAILURE(status))
        return emptyString();
    return String::adopt(buffer);
}

PassOwnPtr<Vector<String> > LocaleICU::createLabelVector(const UDateFormat* dateFormat, UDateFormatSymbolType type, int32_t startIndex, int32_t size)
{
    if (!dateFormat)
        return PassOwnPtr<Vector<String> >();
    if (udat_countSymbols(dateFormat, type) != startIndex + size)
        return PassOwnPtr<Vector<String> >();

    OwnPtr<Vector<String> > labels = adoptPtr(new Vector<String>());
    labels->reserveCapacity(size);
    for (int32_t i = 0; i < size; ++i) {
        UErrorCode status = U_ZERO_ERROR;
        int32_t length = udat_getSymbols(dateFormat, type, startIndex + i, 0, 0, &status);
        if (status != U_BUFFER_OVERFLOW_ERROR)
            return PassOwnPtr<Vector<String> >();
        StringBuffer<UChar> buffer(length);
        status = U_ZERO_ERROR;
        udat_getSymbols(dateFormat, type, startIndex + i, buffer.characters(), length, &status);
        if (U_FAILURE(status))
            return PassOwnPtr<Vector<String> >();
        labels->append(String::adopt(buffer));
    }
    return labels.release();
}

static PassOwnPtr<Vector<String> > createFallbackWeekDayShortLabels()
{
    OwnPtr<Vector<String> > labels = adoptPtr(new Vector<String>());
    labels->reserveCapacity(7);
    labels->append("Sun");
    labels->append("Mon");
    labels->append("Tue");
    labels->append("Wed");
    labels->append("Thu");
    labels->append("Fri");
    labels->append("Sat");
    return labels.release();
}

void LocaleICU::initializeCalendar()
{
    if (m_weekDayShortLabels)
        return;

    if (!initializeShortDateFormat()) {
        m_firstDayOfWeek = 0;
        m_weekDayShortLabels = createFallbackWeekDayShortLabels();
        return;
    }
    m_firstDayOfWeek = ucal_getAttribute(udat_getCalendar(m_shortDateFormat), UCAL_FIRST_DAY_OF_WEEK) - UCAL_SUNDAY;

    m_weekDayShortLabels = createLabelVector(m_shortDateFormat, UDAT_SHORT_WEEKDAYS, UCAL_SUNDAY, 7);
    if (!m_weekDayShortLabels)
        m_weekDayShortLabels = createFallbackWeekDayShortLabels();
}

static PassOwnPtr<Vector<String> > createFallbackMonthLabels()
{
    OwnPtr<Vector<String> > labels = adoptPtr(new Vector<String>());
    labels->reserveCapacity(WTF_ARRAY_LENGTH(WTF::monthFullName));
    for (unsigned i = 0; i < WTF_ARRAY_LENGTH(WTF::monthFullName); ++i)
        labels->append(WTF::monthFullName[i]);
    return labels.release();
}

const Vector<String>& LocaleICU::monthLabels()
{
    if (m_monthLabels)
        return *m_monthLabels;
    if (initializeShortDateFormat()) {
        m_monthLabels = createLabelVector(m_shortDateFormat, UDAT_MONTHS, UCAL_JANUARY, 12);
        if (m_monthLabels)
            return *m_monthLabels;
    }
    m_monthLabels = createFallbackMonthLabels();
    return *m_monthLabels;
}

const Vector<String>& LocaleICU::weekDayShortLabels()
{
    initializeCalendar();
    return *m_weekDayShortLabels;
}

unsigned LocaleICU::firstDayOfWeek()
{
    initializeCalendar();
    return m_firstDayOfWeek;
}

bool LocaleICU::isRTL()
{
    UErrorCode status = U_ZERO_ERROR;
    return uloc_getCharacterOrientation(m_locale.data(), &status) == ULOC_LAYOUT_RTL;
}

static PassOwnPtr<Vector<String> > createFallbackAMPMLabels()
{
    OwnPtr<Vector<String> > labels = adoptPtr(new Vector<String>());
    labels->reserveCapacity(2);
    labels->append("AM");
    labels->append("PM");
    return labels.release();
}

void LocaleICU::initializeDateTimeFormat()
{
    if (m_didCreateTimeFormat)
        return;

    // We assume ICU medium time pattern and short time pattern are compatible
    // with LDML, because ICU specific pattern character "V" doesn't appear
    // in both medium and short time pattern.
    m_mediumTimeFormat = openDateFormat(UDAT_MEDIUM, UDAT_NONE);
    m_timeFormatWithSeconds = getDateFormatPattern(m_mediumTimeFormat);

    m_shortTimeFormat = openDateFormat(UDAT_SHORT, UDAT_NONE);
    m_timeFormatWithoutSeconds = getDateFormatPattern(m_shortTimeFormat);

    UDateFormat* dateTimeFormatWithSeconds = openDateFormat(UDAT_MEDIUM, UDAT_SHORT);
    m_dateTimeFormatWithSeconds = getDateFormatPattern(dateTimeFormatWithSeconds);
    udat_close(dateTimeFormatWithSeconds);

    UDateFormat* dateTimeFormatWithoutSeconds = openDateFormat(UDAT_SHORT, UDAT_SHORT);
    m_dateTimeFormatWithoutSeconds = getDateFormatPattern(dateTimeFormatWithoutSeconds);
    udat_close(dateTimeFormatWithoutSeconds);

    OwnPtr<Vector<String> > timeAMPMLabels = createLabelVector(m_mediumTimeFormat, UDAT_AM_PMS, UCAL_AM, 2);
    if (!timeAMPMLabels)
        timeAMPMLabels = createFallbackAMPMLabels();
    m_timeAMPMLabels = *timeAMPMLabels;

    m_didCreateTimeFormat = true;
}

String LocaleICU::dateFormat()
{
    if (!m_dateFormat.isNull())
        return m_dateFormat;
    if (!initializeShortDateFormat())
        return "yyyy-MM-dd";
    m_dateFormat = getDateFormatPattern(m_shortDateFormat);
    return m_dateFormat;
}

static String getFormatForSkeleton(const char* locale, const String& skeleton)
{
    String format = "yyyy-MM";
    UErrorCode status = U_ZERO_ERROR;
    UDateTimePatternGenerator* patternGenerator = udatpg_open(locale, &status);
    if (!patternGenerator)
        return format;
    status = U_ZERO_ERROR;
    Vector<UChar> skeletonCharacters;
    skeleton.appendTo(skeletonCharacters);
    int32_t length = udatpg_getBestPattern(patternGenerator, skeletonCharacters.data(), skeletonCharacters.size(), 0, 0, &status);
    if (status == U_BUFFER_OVERFLOW_ERROR && length) {
        StringBuffer<UChar> buffer(length);
        status = U_ZERO_ERROR;
        udatpg_getBestPattern(patternGenerator, skeletonCharacters.data(), skeletonCharacters.size(), buffer.characters(), length, &status);
        if (U_SUCCESS(status))
            format = String::adopt(buffer);
    }
    udatpg_close(patternGenerator);
    return format;
}

String LocaleICU::monthFormat()
{
    if (!m_monthFormat.isNull())
        return m_monthFormat;
    // Gets a format for "MMMM" because Windows API always provides formats for
    // "MMMM" in some locales.
    m_monthFormat = getFormatForSkeleton(m_locale.data(), "yyyyMMMM");
    return m_monthFormat;
}

String LocaleICU::shortMonthFormat()
{
    if (!m_shortMonthFormat.isNull())
        return m_shortMonthFormat;
    m_shortMonthFormat = getFormatForSkeleton(m_locale.data(), "yyyyMMM");
    return m_shortMonthFormat;
}

String LocaleICU::timeFormat()
{
    initializeDateTimeFormat();
    return m_timeFormatWithSeconds;
}

String LocaleICU::shortTimeFormat()
{
    initializeDateTimeFormat();
    return m_timeFormatWithoutSeconds;
}

String LocaleICU::dateTimeFormatWithSeconds()
{
    initializeDateTimeFormat();
    return m_dateTimeFormatWithSeconds;
}

String LocaleICU::dateTimeFormatWithoutSeconds()
{
    initializeDateTimeFormat();
    return m_dateTimeFormatWithoutSeconds;
}

const Vector<String>& LocaleICU::shortMonthLabels()
{
    if (!m_shortMonthLabels.isEmpty())
        return m_shortMonthLabels;
    if (initializeShortDateFormat()) {
        if (OwnPtr<Vector<String> > labels = createLabelVector(m_shortDateFormat, UDAT_SHORT_MONTHS, UCAL_JANUARY, 12)) {
            m_shortMonthLabels = *labels;
            return m_shortMonthLabels;
        }
    }
    m_shortMonthLabels.reserveCapacity(WTF_ARRAY_LENGTH(WTF::monthName));
    for (unsigned i = 0; i < WTF_ARRAY_LENGTH(WTF::monthName); ++i)
        m_shortMonthLabels.append(WTF::monthName[i]);
    return m_shortMonthLabels;
}

const Vector<String>& LocaleICU::standAloneMonthLabels()
{
    if (!m_standAloneMonthLabels.isEmpty())
        return m_standAloneMonthLabels;
    if (initializeShortDateFormat()) {
        if (OwnPtr<Vector<String> > labels = createLabelVector(m_shortDateFormat, UDAT_STANDALONE_MONTHS, UCAL_JANUARY, 12)) {
            m_standAloneMonthLabels = *labels;
            return m_standAloneMonthLabels;
        }
    }
    m_standAloneMonthLabels = monthLabels();
    return m_standAloneMonthLabels;
}

const Vector<String>& LocaleICU::shortStandAloneMonthLabels()
{
    if (!m_shortStandAloneMonthLabels.isEmpty())
        return m_shortStandAloneMonthLabels;
    if (initializeShortDateFormat()) {
        if (OwnPtr<Vector<String> > labels = createLabelVector(m_shortDateFormat, UDAT_STANDALONE_SHORT_MONTHS, UCAL_JANUARY, 12)) {
            m_shortStandAloneMonthLabels = *labels;
            return m_shortStandAloneMonthLabels;
        }
    }
    m_shortStandAloneMonthLabels = shortMonthLabels();
    return m_shortStandAloneMonthLabels;
}

const Vector<String>& LocaleICU::timeAMPMLabels()
{
    initializeDateTimeFormat();
    return m_timeAMPMLabels;
}

} // namespace blink

