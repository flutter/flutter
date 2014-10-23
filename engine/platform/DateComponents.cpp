/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
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
#include "platform/DateComponents.h"

#include <limits.h>
#include "wtf/ASCIICType.h"
#include "wtf/DateMath.h"
#include "wtf/MathExtras.h"
#include "wtf/text/WTFString.h"

namespace blink {

// HTML5 specification defines minimum week of year is one.
const int DateComponents::minimumWeekNumber = 1;

// HTML5 specification defines maximum week of year is 53.
const int DateComponents::maximumWeekNumber = 53;

static const int maximumMonthInMaximumYear = 8; // This is September, since months are 0 based.
static const int maximumDayInMaximumMonth = 13;
static const int maximumWeekInMaximumYear = 37; // The week of 275760-09-13

static const int daysInMonth[12] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};

// 'month' is 0-based.
static int maxDayOfMonth(int year, int month)
{
    if (month != 1) // February?
        return daysInMonth[month];
    return isLeapYear(year) ? 29 : 28;
}

// 'month' is 0-based.
static int dayOfWeek(int year, int month, int day)
{
    int shiftedMonth = month + 2;
    // 2:January, 3:Feburuary, 4:March, ...

    // Zeller's congruence
    if (shiftedMonth <= 3) {
        shiftedMonth += 12;
        year--;
    }
    // 4:March, ..., 14:January, 15:February

    int highYear = year / 100;
    int lowYear = year % 100;
    // We add 6 to make the result Sunday-origin.
    int result = (day + 13 * shiftedMonth / 5 + lowYear + lowYear / 4 + highYear / 4 + 5 * highYear + 6) % 7;
    return result;
}

int DateComponents::weekDay() const
{
    return dayOfWeek(m_year, m_month, m_monthDay);
}

int DateComponents::maxWeekNumberInYear() const
{
    int day = dayOfWeek(m_year, 0, 1); // January 1.
    return day == Thursday || (day == Wednesday && isLeapYear(m_year)) ? maximumWeekNumber : maximumWeekNumber - 1;
}

static unsigned countDigits(const String& src, unsigned start)
{
    unsigned index = start;
    for (; index < src.length(); ++index) {
        if (!isASCIIDigit(src[index]))
            break;
    }
    return index - start;
}

// Very strict integer parser. Do not allow leading or trailing whitespace unlike charactersToIntStrict().
static bool toInt(const String& src, unsigned parseStart, unsigned parseLength, int& out)
{
    if (parseStart + parseLength > src.length() || !parseLength)
        return false;
    int value = 0;
    unsigned current = parseStart;
    unsigned end = current + parseLength;

    // We don't need to handle negative numbers for ISO 8601.
    for (; current < end; ++current) {
        if (!isASCIIDigit(src[current]))
            return false;
        int digit = src[current] - '0';
        if (value > (INT_MAX - digit) / 10) // Check for overflow.
            return false;
        value = value * 10 + digit;
    }
    out = value;
    return true;
}

bool DateComponents::parseYear(const String& src, unsigned start, unsigned& end)
{
    unsigned digitsLength = countDigits(src, start);
    // Needs at least 4 digits according to the standard.
    if (digitsLength < 4)
        return false;
    int year;
    if (!toInt(src, start, digitsLength, year))
        return false;
    if (year < minimumYear() || year > maximumYear())
        return false;
    m_year = year;
    end = start + digitsLength;
    return true;
}

static bool withinHTMLDateLimits(int year, int month)
{
    if (year < DateComponents::minimumYear())
        return false;
    if (year < DateComponents::maximumYear())
        return true;
    return month <= maximumMonthInMaximumYear;
}

static bool withinHTMLDateLimits(int year, int month, int monthDay)
{
    if (year < DateComponents::minimumYear())
        return false;
    if (year < DateComponents::maximumYear())
        return true;
    if (month < maximumMonthInMaximumYear)
        return true;
    return monthDay <= maximumDayInMaximumMonth;
}

static bool withinHTMLDateLimits(int year, int month, int monthDay, int hour, int minute, int second, int millisecond)
{
    if (year < DateComponents::minimumYear())
        return false;
    if (year < DateComponents::maximumYear())
        return true;
    if (month < maximumMonthInMaximumYear)
        return true;
    if (monthDay < maximumDayInMaximumMonth)
        return true;
    if (monthDay > maximumDayInMaximumMonth)
        return false;
    // (year, month, monthDay) = (maximumYear, maximumMonthInMaximumYear, maximumDayInMaximumMonth)
    return !hour && !minute && !second && !millisecond;
}

bool DateComponents::addDay(int dayDiff)
{
    ASSERT(m_monthDay);

    int day = m_monthDay + dayDiff;
    if (day > maxDayOfMonth(m_year, m_month)) {
        day = m_monthDay;
        int year = m_year;
        int month = m_month;
        int maxDay = maxDayOfMonth(year, month);
        for (; dayDiff > 0; --dayDiff) {
            ++day;
            if (day > maxDay) {
                day = 1;
                ++month;
                if (month >= 12) { // month is 0-origin.
                    month = 0;
                    ++year;
                }
                maxDay = maxDayOfMonth(year, month);
            }
        }
        if (!withinHTMLDateLimits(year, month, day))
            return false;
        m_year = year;
        m_month = month;
    } else if (day < 1) {
        int month = m_month;
        int year = m_year;
        day = m_monthDay;
        for (; dayDiff < 0; ++dayDiff) {
            --day;
            if (day < 1) {
                --month;
                if (month < 0) {
                    month = 11;
                    --year;
                }
                day = maxDayOfMonth(year, month);
            }
        }
        if (!withinHTMLDateLimits(year, month, day))
            return false;
        m_year = year;
        m_month = month;
    } else {
        if (!withinHTMLDateLimits(m_year, m_month, day))
            return false;
    }
    m_monthDay = day;
    return true;
}

bool DateComponents::addMinute(int minute)
{
    // This function is used to adjust timezone offset. So m_year, m_month,
    // m_monthDay have values between the lower and higher limits.
    ASSERT(withinHTMLDateLimits(m_year, m_month, m_monthDay));

    int carry;
    // minute can be negative or greater than 59.
    minute += m_minute;
    if (minute > 59) {
        carry = minute / 60;
        minute = minute % 60;
    } else if (minute < 0) {
        carry = (59 - minute) / 60;
        minute += carry * 60;
        carry = -carry;
        ASSERT(minute >= 0 && minute <= 59);
    } else {
        if (!withinHTMLDateLimits(m_year, m_month, m_monthDay, m_hour, minute, m_second, m_millisecond))
            return false;
        m_minute = minute;
        return true;
    }

    int hour = m_hour + carry;
    if (hour > 23) {
        carry = hour / 24;
        hour = hour % 24;
    } else if (hour < 0) {
        carry = (23 - hour) / 24;
        hour += carry * 24;
        carry = -carry;
        ASSERT(hour >= 0 && hour <= 23);
    } else {
        if (!withinHTMLDateLimits(m_year, m_month, m_monthDay, hour, minute, m_second, m_millisecond))
            return false;
        m_minute = minute;
        m_hour = hour;
        return true;
    }
    if (!addDay(carry))
        return false;
    if (!withinHTMLDateLimits(m_year, m_month, m_monthDay, hour, minute, m_second, m_millisecond))
        return false;
    m_minute = minute;
    m_hour = hour;
    return true;
}

// Parses a timezone part, and adjust year, month, monthDay, hour, minute, second, millisecond.
bool DateComponents::parseTimeZone(const String& src, unsigned start, unsigned& end)
{
    if (start >= src.length())
        return false;
    unsigned index = start;
    if (src[index] == 'Z') {
        end = index + 1;
        return true;
    }

    bool minus;
    if (src[index] == '+')
        minus = false;
    else if (src[index] == '-')
        minus = true;
    else
        return false;
    ++index;

    int hour;
    int minute;
    if (!toInt(src, index, 2, hour) || hour < 0 || hour > 23)
        return false;
    index += 2;

    if (index >= src.length() || src[index] != ':')
        return false;
    ++index;

    if (!toInt(src, index, 2, minute) || minute < 0 || minute > 59)
        return false;
    index += 2;

    if (minus) {
        hour = -hour;
        minute = -minute;
    }

    // Subtract the timezone offset.
    if (!addMinute(-(hour * 60 + minute)))
        return false;
    end = index;
    return true;
}

bool DateComponents::parseMonth(const String& src, unsigned start, unsigned& end)
{
    unsigned index;
    if (!parseYear(src, start, index))
        return false;
    if (index >= src.length() || src[index] != '-')
        return false;
    ++index;

    int month;
    if (!toInt(src, index, 2, month) || month < 1 || month > 12)
        return false;
    --month;
    if (!withinHTMLDateLimits(m_year, month))
        return false;
    m_month = month;
    end = index + 2;
    m_type = Month;
    return true;
}

bool DateComponents::parseDate(const String& src, unsigned start, unsigned& end)
{
    unsigned index;
    if (!parseMonth(src, start, index))
        return false;
    // '-' and 2-digits are needed.
    if (index + 2 >= src.length())
        return false;
    if (src[index] != '-')
        return false;
    ++index;

    int day;
    if (!toInt(src, index, 2, day) || day < 1 || day > maxDayOfMonth(m_year, m_month))
        return false;
    if (!withinHTMLDateLimits(m_year, m_month, day))
        return false;
    m_monthDay = day;
    end = index + 2;
    m_type = Date;
    return true;
}

bool DateComponents::parseWeek(const String& src, unsigned start, unsigned& end)
{
    unsigned index;
    if (!parseYear(src, start, index))
        return false;

    // 4 characters ('-' 'W' digit digit) are needed.
    if (index + 3 >= src.length())
        return false;
    if (src[index] != '-')
        return false;
    ++index;
    if (src[index] != 'W')
        return false;
    ++index;

    int week;
    if (!toInt(src, index, 2, week) || week < minimumWeekNumber || week > maxWeekNumberInYear())
        return false;
    if (m_year == maximumYear() && week > maximumWeekInMaximumYear)
        return false;
    m_week = week;
    end = index + 2;
    m_type = Week;
    return true;
}

bool DateComponents::parseTime(const String& src, unsigned start, unsigned& end)
{
    int hour;
    if (!toInt(src, start, 2, hour) || hour < 0 || hour > 23)
        return false;
    unsigned index = start + 2;
    if (index >= src.length())
        return false;
    if (src[index] != ':')
        return false;
    ++index;

    int minute;
    if (!toInt(src, index, 2, minute) || minute < 0 || minute > 59)
        return false;
    index += 2;

    int second = 0;
    int millisecond = 0;
    // Optional second part.
    // Do not return with false because the part is optional.
    if (index + 2 < src.length() && src[index] == ':') {
        if (toInt(src, index + 1, 2, second) && second >= 0 && second <= 59) {
            index += 3;

            // Optional fractional second part.
            if (index < src.length() && src[index] == '.') {
                unsigned digitsLength = countDigits(src, index + 1);
                if (digitsLength >  0) {
                    ++index;
                    bool ok;
                    if (digitsLength == 1) {
                        ok = toInt(src, index, 1, millisecond);
                        millisecond *= 100;
                    } else if (digitsLength == 2) {
                        ok = toInt(src, index, 2, millisecond);
                        millisecond *= 10;
                    } else { // digitsLength >= 3
                        ok = toInt(src, index, 3, millisecond);
                    }
                    ASSERT_UNUSED(ok, ok);
                    index += digitsLength;
                }
            }
        }
    }
    m_hour = hour;
    m_minute = minute;
    m_second = second;
    m_millisecond = millisecond;
    end = index;
    m_type = Time;
    return true;
}

bool DateComponents::parseDateTimeLocal(const String& src, unsigned start, unsigned& end)
{
    unsigned index;
    if (!parseDate(src, start, index))
        return false;
    if (index >= src.length())
        return false;
    if (src[index] != 'T')
        return false;
    ++index;
    if (!parseTime(src, index, end))
        return false;
    if (!withinHTMLDateLimits(m_year, m_month, m_monthDay, m_hour, m_minute, m_second, m_millisecond))
        return false;
    m_type = DateTimeLocal;
    return true;
}

bool DateComponents::parseDateTime(const String& src, unsigned start, unsigned& end)
{
    unsigned index;
    if (!parseDate(src, start, index))
        return false;
    if (index >= src.length())
        return false;
    if (src[index] != 'T')
        return false;
    ++index;
    if (!parseTime(src, index, index))
        return false;
    if (!parseTimeZone(src, index, end))
        return false;
    if (!withinHTMLDateLimits(m_year, m_month, m_monthDay, m_hour, m_minute, m_second, m_millisecond))
        return false;
    m_type = DateTime;
    return true;
}

static inline double positiveFmod(double value, double divider)
{
    double remainder = fmod(value, divider);
    return remainder < 0 ? remainder + divider : remainder;
}

void DateComponents::setMillisecondsSinceMidnightInternal(double msInDay)
{
    ASSERT(msInDay >= 0 && msInDay < msPerDay);
    m_millisecond = static_cast<int>(fmod(msInDay, msPerSecond));
    double value = std::floor(msInDay / msPerSecond);
    m_second = static_cast<int>(fmod(value, secondsPerMinute));
    value = std::floor(value / secondsPerMinute);
    m_minute = static_cast<int>(fmod(value, minutesPerHour));
    m_hour = static_cast<int>(value / minutesPerHour);
}

bool DateComponents::setMillisecondsSinceEpochForDateInternal(double ms)
{
    m_year = msToYear(ms);
    int yearDay = dayInYear(ms, m_year);
    m_month = monthFromDayInYear(yearDay, isLeapYear(m_year));
    m_monthDay = dayInMonthFromDayInYear(yearDay, isLeapYear(m_year));
    return true;
}

bool DateComponents::setMillisecondsSinceEpochForDate(double ms)
{
    m_type = Invalid;
    if (!std::isfinite(ms))
        return false;
    if (!setMillisecondsSinceEpochForDateInternal(round(ms)))
        return false;
    if (!withinHTMLDateLimits(m_year, m_month, m_monthDay))
        return false;
    m_type = Date;
    return true;
}

bool DateComponents::setMillisecondsSinceEpochForDateTime(double ms)
{
    m_type = Invalid;
    if (!std::isfinite(ms))
        return false;
    ms = round(ms);
    setMillisecondsSinceMidnightInternal(positiveFmod(ms, msPerDay));
    if (!setMillisecondsSinceEpochForDateInternal(ms))
        return false;
    if (!withinHTMLDateLimits(m_year, m_month, m_monthDay, m_hour, m_minute, m_second, m_millisecond))
        return false;
    m_type = DateTime;
    return true;
}

bool DateComponents::setMillisecondsSinceEpochForDateTimeLocal(double ms)
{
    // Internal representation of DateTimeLocal is the same as DateTime except m_type.
    if (!setMillisecondsSinceEpochForDateTime(ms))
        return false;
    m_type = DateTimeLocal;
    return true;
}

bool DateComponents::setMillisecondsSinceEpochForMonth(double ms)
{
    m_type = Invalid;
    if (!std::isfinite(ms))
        return false;
    if (!setMillisecondsSinceEpochForDateInternal(round(ms)))
        return false;
    if (!withinHTMLDateLimits(m_year, m_month))
        return false;
    m_type = Month;
    return true;
}

bool DateComponents::setMillisecondsSinceMidnight(double ms)
{
    m_type = Invalid;
    if (!std::isfinite(ms))
        return false;
    setMillisecondsSinceMidnightInternal(positiveFmod(round(ms), msPerDay));
    m_type = Time;
    return true;
}

bool DateComponents::setMonthsSinceEpoch(double months)
{
    if (!std::isfinite(months))
        return false;
    months = round(months);
    double doubleMonth = positiveFmod(months, 12);
    double doubleYear = 1970 + (months - doubleMonth) / 12;
    if (doubleYear < minimumYear() || maximumYear() < doubleYear)
        return false;
    int year = static_cast<int>(doubleYear);
    int month = static_cast<int>(doubleMonth);
    if (!withinHTMLDateLimits(year, month))
        return false;
    m_year = year;
    m_month = month;
    m_type = Month;
    return true;
}

// Offset from January 1st to Monday of the ISO 8601's first week.
//   ex. If January 1st is Friday, such Monday is 3 days later. Returns 3.
static int offsetTo1stWeekStart(int year)
{
    int offsetTo1stWeekStart = 1 - dayOfWeek(year, 0, 1);
    if (offsetTo1stWeekStart <= -4)
        offsetTo1stWeekStart += 7;
    return offsetTo1stWeekStart;
}

bool DateComponents::setMillisecondsSinceEpochForWeek(double ms)
{
    m_type = Invalid;
    if (!std::isfinite(ms))
        return false;
    ms = round(ms);

    m_year = msToYear(ms);
    if (m_year < minimumYear() || m_year > maximumYear())
        return false;

    int yearDay = dayInYear(ms, m_year);
    int offset = offsetTo1stWeekStart(m_year);
    if (yearDay < offset) {
        // The day belongs to the last week of the previous year.
        m_year--;
        if (m_year <= minimumYear())
            return false;
        m_week = maxWeekNumberInYear();
    } else {
        m_week = ((yearDay - offset) / 7) + 1;
        if (m_week > maxWeekNumberInYear()) {
            m_year++;
            m_week = 1;
        }
        if (m_year > maximumYear() || (m_year == maximumYear() && m_week > maximumWeekInMaximumYear))
            return false;
    }
    m_type = Week;
    return true;
}

double DateComponents::millisecondsSinceEpochForTime() const
{
    ASSERT(m_type == Time || m_type == DateTime || m_type == DateTimeLocal);
    return ((m_hour * minutesPerHour + m_minute) * secondsPerMinute + m_second) * msPerSecond + m_millisecond;
}

double DateComponents::millisecondsSinceEpoch() const
{
    switch (m_type) {
    case Date:
        return dateToDaysFrom1970(m_year, m_month, m_monthDay) * msPerDay;
    case DateTime:
    case DateTimeLocal:
        return dateToDaysFrom1970(m_year, m_month, m_monthDay) * msPerDay + millisecondsSinceEpochForTime();
    case Month:
        return dateToDaysFrom1970(m_year, m_month, 1) * msPerDay;
    case Time:
        return millisecondsSinceEpochForTime();
    case Week:
        return (dateToDaysFrom1970(m_year, 0, 1) + offsetTo1stWeekStart(m_year) + (m_week - 1) * 7) * msPerDay;
    case Invalid:
        break;
    }
    ASSERT_NOT_REACHED();
    return invalidMilliseconds();
}

double DateComponents::monthsSinceEpoch() const
{
    ASSERT(m_type == Month);
    return (m_year - 1970) * 12 + m_month;
}

String DateComponents::toStringForTime(SecondFormat format) const
{
    ASSERT(m_type == DateTime || m_type == DateTimeLocal || m_type == Time);
    SecondFormat effectiveFormat = format;
    if (m_millisecond)
        effectiveFormat = Millisecond;
    else if (format == None && m_second)
        effectiveFormat = Second;

    switch (effectiveFormat) {
    default:
        ASSERT_NOT_REACHED();
        // Fallback to None.
    case None:
        return String::format("%02d:%02d", m_hour, m_minute);
    case Second:
        return String::format("%02d:%02d:%02d", m_hour, m_minute, m_second);
    case Millisecond:
        return String::format("%02d:%02d:%02d.%03d", m_hour, m_minute, m_second, m_millisecond);
    }
}

String DateComponents::toString(SecondFormat format) const
{
    switch (m_type) {
    case Date:
        return String::format("%04d-%02d-%02d", m_year, m_month + 1, m_monthDay);
    case DateTime:
        return String::format("%04d-%02d-%02dT", m_year, m_month + 1, m_monthDay)
            + toStringForTime(format) + String("Z");
    case DateTimeLocal:
        return String::format("%04d-%02d-%02dT", m_year, m_month + 1, m_monthDay)
            + toStringForTime(format);
    case Month:
        return String::format("%04d-%02d", m_year, m_month + 1);
    case Time:
        return toStringForTime(format);
    case Week:
        return String::format("%04d-W%02d", m_year, m_week);
    case Invalid:
        break;
    }
    ASSERT_NOT_REACHED();
    return String("(Invalid DateComponents)");
}

} // namespace blink
