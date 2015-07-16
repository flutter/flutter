/* Portions are Copyright (C) 2011 Google Inc */
/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Netscape Portable Runtime (NSPR).
 *
 * The Initial Developer of the Original Code is
 * Netscape Communications Corporation.
 * Portions created by the Initial Developer are Copyright (C) 1998-2000
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

/*
 * prtime.cc --
 * NOTE: The original nspr file name is prtime.c
 *
 *     NSPR date and time functions
 *
 * CVS revision 3.37
 */

/*
 * The following functions were copied from the NSPR prtime.c file.
 * PR_ParseTimeString
 *   We inlined the new PR_ParseTimeStringToExplodedTime function to avoid
 *   copying PR_ExplodeTime and PR_LocalTimeParameters.  (The PR_ExplodeTime
 *   and PR_ImplodeTime calls cancel each other out.)
 * PR_NormalizeTime
 * PR_GMTParameters
 * PR_ImplodeTime
 *   This was modified to use the Win32 SYSTEMTIME/FILETIME structures
 *   and the timezone offsets are applied to the FILETIME structure.
 * All types and macros are defined in the base/third_party/prtime.h file.
 * These have been copied from the following nspr files. We have only copied
 * over the types we need.
 * 1. prtime.h
 * 2. prtypes.h
 * 3. prlong.h
 *
 * Unit tests are in base/time/pr_time_unittest.cc.
 */

#include "base/logging.h"
#include "base/third_party/nspr/prtime.h"
#include "build/build_config.h"

#if defined(OS_WIN)
#include <windows.h>
#elif defined(OS_MACOSX)
#include <CoreFoundation/CoreFoundation.h>
#elif defined(OS_ANDROID)
#include <ctype.h>
#include "base/os_compat_android.h"  // For timegm()
#elif defined(OS_NACL)
#include "base/os_compat_nacl.h"  // For timegm()
#endif
#include <errno.h>  /* for EINVAL */
#include <time.h>

/* Implements the Unix localtime_r() function for windows */
#if defined(OS_WIN)
static void localtime_r(const time_t* secs, struct tm* time) {
  (void) localtime_s(time, secs);
}
#endif

/*
 *------------------------------------------------------------------------
 *
 * PR_ImplodeTime --
 *
 *     Cf. time_t mktime(struct tm *tp)
 *     Note that 1 year has < 2^25 seconds.  So an PRInt32 is large enough.
 *
 *------------------------------------------------------------------------
 */
PRTime
PR_ImplodeTime(const PRExplodedTime *exploded)
{
    // This is important, we want to make sure multiplications are
    // done with the correct precision.
    static const PRTime kSecondsToMicroseconds = static_cast<PRTime>(1000000);
#if defined(OS_WIN)
   // Create the system struct representing our exploded time.
    SYSTEMTIME st = {0};
    FILETIME ft = {0};
    ULARGE_INTEGER uli = {0};

    st.wYear = exploded->tm_year;
    st.wMonth = static_cast<WORD>(exploded->tm_month + 1);
    st.wDayOfWeek = exploded->tm_wday;
    st.wDay = static_cast<WORD>(exploded->tm_mday);
    st.wHour = static_cast<WORD>(exploded->tm_hour);
    st.wMinute = static_cast<WORD>(exploded->tm_min);
    st.wSecond = static_cast<WORD>(exploded->tm_sec);
    st.wMilliseconds = static_cast<WORD>(exploded->tm_usec/1000);
     // Convert to FILETIME.
    if (!SystemTimeToFileTime(&st, &ft)) {
      NOTREACHED() << "Unable to convert time";
      return 0;
    }
    // Apply offsets.
    uli.LowPart = ft.dwLowDateTime;
    uli.HighPart = ft.dwHighDateTime;
    // Convert from Windows epoch to NSPR epoch, and 100-nanoseconds units
    // to microsecond units.
    PRTime result =
        static_cast<PRTime>((uli.QuadPart / 10) - 11644473600000000i64);
    // Adjust for time zone and dst.  Convert from seconds to microseconds.
    result -= (exploded->tm_params.tp_gmt_offset +
               exploded->tm_params.tp_dst_offset) * kSecondsToMicroseconds;
    // Add microseconds that cannot be represented in |st|.
    result += exploded->tm_usec % 1000;
    return result;
#elif defined(OS_MACOSX)
    // Create the system struct representing our exploded time.
    CFGregorianDate gregorian_date;
    gregorian_date.year = exploded->tm_year;
    gregorian_date.month = exploded->tm_month + 1;
    gregorian_date.day = exploded->tm_mday;
    gregorian_date.hour = exploded->tm_hour;
    gregorian_date.minute = exploded->tm_min;
    gregorian_date.second = exploded->tm_sec;

    // Compute |absolute_time| in seconds, correct for gmt and dst
    // (note the combined offset will be negative when we need to add it), then
    // convert to microseconds which is what PRTime expects.
    CFAbsoluteTime absolute_time =
        CFGregorianDateGetAbsoluteTime(gregorian_date, NULL);
    PRTime result = static_cast<PRTime>(absolute_time);
    result -= exploded->tm_params.tp_gmt_offset +
              exploded->tm_params.tp_dst_offset;
    result += kCFAbsoluteTimeIntervalSince1970;  // PRTime epoch is 1970
    result *= kSecondsToMicroseconds;
    result += exploded->tm_usec;
    return result;
#elif defined(OS_POSIX)
    struct tm exp_tm = {0};
    exp_tm.tm_sec  = exploded->tm_sec;
    exp_tm.tm_min  = exploded->tm_min;
    exp_tm.tm_hour = exploded->tm_hour;
    exp_tm.tm_mday = exploded->tm_mday;
    exp_tm.tm_mon  = exploded->tm_month;
    exp_tm.tm_year = exploded->tm_year - 1900;

    time_t absolute_time = timegm(&exp_tm);

    // If timegm returned -1.  Since we don't pass it a time zone, the only
    // valid case of returning -1 is 1 second before Epoch (Dec 31, 1969).
    if (absolute_time == -1 &&
        !(exploded->tm_year == 1969 && exploded->tm_month == 11 &&
        exploded->tm_mday == 31 && exploded->tm_hour == 23 &&
        exploded->tm_min == 59 && exploded->tm_sec == 59)) {
      // If we get here, time_t must be 32 bits.
      // Date was possibly too far in the future and would overflow.  Return
      // the most future date possible (year 2038).
      if (exploded->tm_year >= 1970)
        return INT_MAX * kSecondsToMicroseconds;
      // Date was possibly too far in the past and would underflow.  Return
      // the most past date possible (year 1901).
      return INT_MIN * kSecondsToMicroseconds;
    }

    PRTime result = static_cast<PRTime>(absolute_time);
    result -= exploded->tm_params.tp_gmt_offset +
              exploded->tm_params.tp_dst_offset;
    result *= kSecondsToMicroseconds;
    result += exploded->tm_usec;
    return result;
#else
#error No PR_ImplodeTime implemented on your platform.
#endif
}

/* 
 * The COUNT_LEAPS macro counts the number of leap years passed by
 * till the start of the given year Y.  At the start of the year 4
 * A.D. the number of leap years passed by is 0, while at the start of
 * the year 5 A.D. this count is 1. The number of years divisible by
 * 100 but not divisible by 400 (the non-leap years) is deducted from
 * the count to get the correct number of leap years.
 *
 * The COUNT_DAYS macro counts the number of days since 01/01/01 till the
 * start of the given year Y. The number of days at the start of the year
 * 1 is 0 while the number of days at the start of the year 2 is 365
 * (which is ((2)-1) * 365) and so on. The reference point is 01/01/01
 * midnight 00:00:00.
 */

#define COUNT_LEAPS(Y)   ( ((Y)-1)/4 - ((Y)-1)/100 + ((Y)-1)/400 )
#define COUNT_DAYS(Y)  ( ((Y)-1)*365 + COUNT_LEAPS(Y) )
#define DAYS_BETWEEN_YEARS(A, B)  (COUNT_DAYS(B) - COUNT_DAYS(A))

/*
 * Static variables used by functions in this file
 */

/*
 * The following array contains the day of year for the last day of
 * each month, where index 1 is January, and day 0 is January 1.
 */

static const int lastDayOfMonth[2][13] = {
    {-1, 30, 58, 89, 119, 150, 180, 211, 242, 272, 303, 333, 364},
    {-1, 30, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365}
};

/*
 * The number of days in a month
 */

static const PRInt8 nDays[2][12] = {
    {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31},
    {31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
};

/*
 *-------------------------------------------------------------------------
 *
 * IsLeapYear --
 *
 *     Returns 1 if the year is a leap year, 0 otherwise.
 *
 *-------------------------------------------------------------------------
 */

static int IsLeapYear(PRInt16 year)
{
    if ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0)
        return 1;
    else
        return 0;
}

/*
 * 'secOffset' should be less than 86400 (i.e., a day).
 * 'time' should point to a normalized PRExplodedTime.
 */

static void
ApplySecOffset(PRExplodedTime *time, PRInt32 secOffset)
{
    time->tm_sec += secOffset;

    /* Note that in this implementation we do not count leap seconds */
    if (time->tm_sec < 0 || time->tm_sec >= 60) {
        time->tm_min += time->tm_sec / 60;
        time->tm_sec %= 60;
        if (time->tm_sec < 0) {
            time->tm_sec += 60;
            time->tm_min--;
        }
    }

    if (time->tm_min < 0 || time->tm_min >= 60) {
        time->tm_hour += time->tm_min / 60;
        time->tm_min %= 60;
        if (time->tm_min < 0) {
            time->tm_min += 60;
            time->tm_hour--;
        }
    }

    if (time->tm_hour < 0) {
        /* Decrement mday, yday, and wday */
        time->tm_hour += 24;
        time->tm_mday--;
        time->tm_yday--;
        if (time->tm_mday < 1) {
            time->tm_month--;
            if (time->tm_month < 0) {
                time->tm_month = 11;
                time->tm_year--;
                if (IsLeapYear(time->tm_year))
                    time->tm_yday = 365;
                else
                    time->tm_yday = 364;
            }
            time->tm_mday = nDays[IsLeapYear(time->tm_year)][time->tm_month];
        }
        time->tm_wday--;
        if (time->tm_wday < 0)
            time->tm_wday = 6;
    } else if (time->tm_hour > 23) {
        /* Increment mday, yday, and wday */
        time->tm_hour -= 24;
        time->tm_mday++;
        time->tm_yday++;
        if (time->tm_mday >
                nDays[IsLeapYear(time->tm_year)][time->tm_month]) {
            time->tm_mday = 1;
            time->tm_month++;
            if (time->tm_month > 11) {
                time->tm_month = 0;
                time->tm_year++;
                time->tm_yday = 0;
            }
        }
        time->tm_wday++;
        if (time->tm_wday > 6)
            time->tm_wday = 0;
    }
}

void
PR_NormalizeTime(PRExplodedTime *time, PRTimeParamFn params)
{
    int daysInMonth;
    PRInt32 numDays;

    /* Get back to GMT */
    time->tm_sec -= time->tm_params.tp_gmt_offset
            + time->tm_params.tp_dst_offset;
    time->tm_params.tp_gmt_offset = 0;
    time->tm_params.tp_dst_offset = 0;

    /* Now normalize GMT */

    if (time->tm_usec < 0 || time->tm_usec >= 1000000) {
        time->tm_sec +=  time->tm_usec / 1000000;
        time->tm_usec %= 1000000;
        if (time->tm_usec < 0) {
            time->tm_usec += 1000000;
            time->tm_sec--;
        }
    }

    /* Note that we do not count leap seconds in this implementation */
    if (time->tm_sec < 0 || time->tm_sec >= 60) {
        time->tm_min += time->tm_sec / 60;
        time->tm_sec %= 60;
        if (time->tm_sec < 0) {
            time->tm_sec += 60;
            time->tm_min--;
        }
    }

    if (time->tm_min < 0 || time->tm_min >= 60) {
        time->tm_hour += time->tm_min / 60;
        time->tm_min %= 60;
        if (time->tm_min < 0) {
            time->tm_min += 60;
            time->tm_hour--;
        }
    }

    if (time->tm_hour < 0 || time->tm_hour >= 24) {
        time->tm_mday += time->tm_hour / 24;
        time->tm_hour %= 24;
        if (time->tm_hour < 0) {
            time->tm_hour += 24;
            time->tm_mday--;
        }
    }

    /* Normalize month and year before mday */
    if (time->tm_month < 0 || time->tm_month >= 12) {
        time->tm_year += static_cast<PRInt16>(time->tm_month / 12);
        time->tm_month %= 12;
        if (time->tm_month < 0) {
            time->tm_month += 12;
            time->tm_year--;
        }
    }

    /* Now that month and year are in proper range, normalize mday */

    if (time->tm_mday < 1) {
        /* mday too small */
        do {
            /* the previous month */
            time->tm_month--;
            if (time->tm_month < 0) {
                time->tm_month = 11;
                time->tm_year--;
            }
            time->tm_mday += nDays[IsLeapYear(time->tm_year)][time->tm_month];
        } while (time->tm_mday < 1);
    } else {
        daysInMonth = nDays[IsLeapYear(time->tm_year)][time->tm_month];
        while (time->tm_mday > daysInMonth) {
            /* mday too large */
            time->tm_mday -= daysInMonth;
            time->tm_month++;
            if (time->tm_month > 11) {
                time->tm_month = 0;
                time->tm_year++;
            }
            daysInMonth = nDays[IsLeapYear(time->tm_year)][time->tm_month];
        }
    }

    /* Recompute yday and wday */
    time->tm_yday = static_cast<PRInt16>(time->tm_mday +
            lastDayOfMonth[IsLeapYear(time->tm_year)][time->tm_month]);

    numDays = DAYS_BETWEEN_YEARS(1970, time->tm_year) + time->tm_yday;
    time->tm_wday = (numDays + 4) % 7;
    if (time->tm_wday < 0) {
        time->tm_wday += 7;
    }

    /* Recompute time parameters */

    time->tm_params = params(time);

    ApplySecOffset(time, time->tm_params.tp_gmt_offset
            + time->tm_params.tp_dst_offset);
}

/*
 *------------------------------------------------------------------------
 *
 * PR_GMTParameters --
 *
 *     Returns the PRTimeParameters for Greenwich Mean Time.
 *     Trivially, both the tp_gmt_offset and tp_dst_offset fields are 0.
 *
 *------------------------------------------------------------------------
 */

PRTimeParameters
PR_GMTParameters(const PRExplodedTime *gmt)
{
    PRTimeParameters retVal = { 0, 0 };
    return retVal;
}

/*
 * The following code implements PR_ParseTimeString().  It is based on
 * ns/lib/xp/xp_time.c, revision 1.25, by Jamie Zawinski <jwz@netscape.com>.
 */

/*
 * We only recognize the abbreviations of a small subset of time zones
 * in North America, Europe, and Japan.
 *
 * PST/PDT: Pacific Standard/Daylight Time
 * MST/MDT: Mountain Standard/Daylight Time
 * CST/CDT: Central Standard/Daylight Time
 * EST/EDT: Eastern Standard/Daylight Time
 * AST: Atlantic Standard Time
 * NST: Newfoundland Standard Time
 * GMT: Greenwich Mean Time
 * BST: British Summer Time
 * MET: Middle Europe Time
 * EET: Eastern Europe Time
 * JST: Japan Standard Time
 */

typedef enum
{
  TT_UNKNOWN,

  TT_SUN, TT_MON, TT_TUE, TT_WED, TT_THU, TT_FRI, TT_SAT,

  TT_JAN, TT_FEB, TT_MAR, TT_APR, TT_MAY, TT_JUN,
  TT_JUL, TT_AUG, TT_SEP, TT_OCT, TT_NOV, TT_DEC,

  TT_PST, TT_PDT, TT_MST, TT_MDT, TT_CST, TT_CDT, TT_EST, TT_EDT,
  TT_AST, TT_NST, TT_GMT, TT_BST, TT_MET, TT_EET, TT_JST
} TIME_TOKEN;

/*
 * This parses a time/date string into a PRTime
 * (microseconds after "1-Jan-1970 00:00:00 GMT").
 * It returns PR_SUCCESS on success, and PR_FAILURE
 * if the time/date string can't be parsed.
 *
 * Many formats are handled, including:
 *
 *   14 Apr 89 03:20:12
 *   14 Apr 89 03:20 GMT
 *   Fri, 17 Mar 89 4:01:33
 *   Fri, 17 Mar 89 4:01 GMT
 *   Mon Jan 16 16:12 PDT 1989
 *   Mon Jan 16 16:12 +0130 1989
 *   6 May 1992 16:41-JST (Wednesday)
 *   22-AUG-1993 10:59:12.82
 *   22-AUG-1993 10:59pm
 *   22-AUG-1993 12:59am
 *   22-AUG-1993 12:59 PM
 *   Friday, August 04, 1995 3:54 PM
 *   06/21/95 04:24:34 PM
 *   20/06/95 21:07
 *   95-06-08 19:32:48 EDT
 *   1995-06-17T23:11:25.342156Z
 *
 * If the input string doesn't contain a description of the timezone,
 * we consult the `default_to_gmt' to decide whether the string should
 * be interpreted relative to the local time zone (PR_FALSE) or GMT (PR_TRUE).
 * The correct value for this argument depends on what standard specified
 * the time string which you are parsing.
 */

PRStatus
PR_ParseTimeString(
        const char *string,
        PRBool default_to_gmt,
        PRTime *result_imploded)
{
  PRExplodedTime tm;
  PRExplodedTime *result = &tm;
  TIME_TOKEN dotw = TT_UNKNOWN;
  TIME_TOKEN month = TT_UNKNOWN;
  TIME_TOKEN zone = TT_UNKNOWN;
  int zone_offset = -1;
  int dst_offset = 0;
  int date = -1;
  PRInt32 year = -1;
  int hour = -1;
  int min = -1;
  int sec = -1;
  int usec = -1;

  const char *rest = string;

  int iterations = 0;

  PR_ASSERT(string && result);
  if (!string || !result) return PR_FAILURE;

  while (*rest)
        {

          if (iterations++ > 1000)
                {
                  return PR_FAILURE;
                }

          switch (*rest)
                {
                case 'a': case 'A':
                  if (month == TT_UNKNOWN &&
                          (rest[1] == 'p' || rest[1] == 'P') &&
                          (rest[2] == 'r' || rest[2] == 'R'))
                        month = TT_APR;
                  else if (zone == TT_UNKNOWN &&
                                   (rest[1] == 's' || rest[1] == 'S') &&
                                   (rest[2] == 't' || rest[2] == 'T'))
                        zone = TT_AST;
                  else if (month == TT_UNKNOWN &&
                                   (rest[1] == 'u' || rest[1] == 'U') &&
                                   (rest[2] == 'g' || rest[2] == 'G'))
                        month = TT_AUG;
                  break;
                case 'b': case 'B':
                  if (zone == TT_UNKNOWN &&
                          (rest[1] == 's' || rest[1] == 'S') &&
                          (rest[2] == 't' || rest[2] == 'T'))
                        zone = TT_BST;
                  break;
                case 'c': case 'C':
                  if (zone == TT_UNKNOWN &&
                          (rest[1] == 'd' || rest[1] == 'D') &&
                          (rest[2] == 't' || rest[2] == 'T'))
                        zone = TT_CDT;
                  else if (zone == TT_UNKNOWN &&
                                   (rest[1] == 's' || rest[1] == 'S') &&
                                   (rest[2] == 't' || rest[2] == 'T'))
                        zone = TT_CST;
                  break;
                case 'd': case 'D':
                  if (month == TT_UNKNOWN &&
                          (rest[1] == 'e' || rest[1] == 'E') &&
                          (rest[2] == 'c' || rest[2] == 'C'))
                        month = TT_DEC;
                  break;
                case 'e': case 'E':
                  if (zone == TT_UNKNOWN &&
                          (rest[1] == 'd' || rest[1] == 'D') &&
                          (rest[2] == 't' || rest[2] == 'T'))
                        zone = TT_EDT;
                  else if (zone == TT_UNKNOWN &&
                                   (rest[1] == 'e' || rest[1] == 'E') &&
                                   (rest[2] == 't' || rest[2] == 'T'))
                        zone = TT_EET;
                  else if (zone == TT_UNKNOWN &&
                                   (rest[1] == 's' || rest[1] == 'S') &&
                                   (rest[2] == 't' || rest[2] == 'T'))
                        zone = TT_EST;
                  break;
                case 'f': case 'F':
                  if (month == TT_UNKNOWN &&
                          (rest[1] == 'e' || rest[1] == 'E') &&
                          (rest[2] == 'b' || rest[2] == 'B'))
                        month = TT_FEB;
                  else if (dotw == TT_UNKNOWN &&
                                   (rest[1] == 'r' || rest[1] == 'R') &&
                                   (rest[2] == 'i' || rest[2] == 'I'))
                        dotw = TT_FRI;
                  break;
                case 'g': case 'G':
                  if (zone == TT_UNKNOWN &&
                          (rest[1] == 'm' || rest[1] == 'M') &&
                          (rest[2] == 't' || rest[2] == 'T'))
                        zone = TT_GMT;
                  break;
                case 'j': case 'J':
                  if (month == TT_UNKNOWN &&
                          (rest[1] == 'a' || rest[1] == 'A') &&
                          (rest[2] == 'n' || rest[2] == 'N'))
                        month = TT_JAN;
                  else if (zone == TT_UNKNOWN &&
                                   (rest[1] == 's' || rest[1] == 'S') &&
                                   (rest[2] == 't' || rest[2] == 'T'))
                        zone = TT_JST;
                  else if (month == TT_UNKNOWN &&
                                   (rest[1] == 'u' || rest[1] == 'U') &&
                                   (rest[2] == 'l' || rest[2] == 'L'))
                        month = TT_JUL;
                  else if (month == TT_UNKNOWN &&
                                   (rest[1] == 'u' || rest[1] == 'U') &&
                                   (rest[2] == 'n' || rest[2] == 'N'))
                        month = TT_JUN;
                  break;
                case 'm': case 'M':
                  if (month == TT_UNKNOWN &&
                          (rest[1] == 'a' || rest[1] == 'A') &&
                          (rest[2] == 'r' || rest[2] == 'R'))
                        month = TT_MAR;
                  else if (month == TT_UNKNOWN &&
                                   (rest[1] == 'a' || rest[1] == 'A') &&
                                   (rest[2] == 'y' || rest[2] == 'Y'))
                        month = TT_MAY;
                  else if (zone == TT_UNKNOWN &&
                                   (rest[1] == 'd' || rest[1] == 'D') &&
                                   (rest[2] == 't' || rest[2] == 'T'))
                        zone = TT_MDT;
                  else if (zone == TT_UNKNOWN &&
                                   (rest[1] == 'e' || rest[1] == 'E') &&
                                   (rest[2] == 't' || rest[2] == 'T'))
                        zone = TT_MET;
                  else if (dotw == TT_UNKNOWN &&
                                   (rest[1] == 'o' || rest[1] == 'O') &&
                                   (rest[2] == 'n' || rest[2] == 'N'))
                        dotw = TT_MON;
                  else if (zone == TT_UNKNOWN &&
                                   (rest[1] == 's' || rest[1] == 'S') &&
                                   (rest[2] == 't' || rest[2] == 'T'))
                        zone = TT_MST;
                  break;
                case 'n': case 'N':
                  if (month == TT_UNKNOWN &&
                          (rest[1] == 'o' || rest[1] == 'O') &&
                          (rest[2] == 'v' || rest[2] == 'V'))
                        month = TT_NOV;
                  else if (zone == TT_UNKNOWN &&
                                   (rest[1] == 's' || rest[1] == 'S') &&
                                   (rest[2] == 't' || rest[2] == 'T'))
                        zone = TT_NST;
                  break;
                case 'o': case 'O':
                  if (month == TT_UNKNOWN &&
                          (rest[1] == 'c' || rest[1] == 'C') &&
                          (rest[2] == 't' || rest[2] == 'T'))
                        month = TT_OCT;
                  break;
                case 'p': case 'P':
                  if (zone == TT_UNKNOWN &&
                          (rest[1] == 'd' || rest[1] == 'D') &&
                          (rest[2] == 't' || rest[2] == 'T'))
                        zone = TT_PDT;
                  else if (zone == TT_UNKNOWN &&
                                   (rest[1] == 's' || rest[1] == 'S') &&
                                   (rest[2] == 't' || rest[2] == 'T'))
                        zone = TT_PST;
                  break;
                case 's': case 'S':
                  if (dotw == TT_UNKNOWN &&
                          (rest[1] == 'a' || rest[1] == 'A') &&
                          (rest[2] == 't' || rest[2] == 'T'))
                        dotw = TT_SAT;
                  else if (month == TT_UNKNOWN &&
                                   (rest[1] == 'e' || rest[1] == 'E') &&
                                   (rest[2] == 'p' || rest[2] == 'P'))
                        month = TT_SEP;
                  else if (dotw == TT_UNKNOWN &&
                                   (rest[1] == 'u' || rest[1] == 'U') &&
                                   (rest[2] == 'n' || rest[2] == 'N'))
                        dotw = TT_SUN;
                  break;
                case 't': case 'T':
                  if (dotw == TT_UNKNOWN &&
                          (rest[1] == 'h' || rest[1] == 'H') &&
                          (rest[2] == 'u' || rest[2] == 'U'))
                        dotw = TT_THU;
                  else if (dotw == TT_UNKNOWN &&
                                   (rest[1] == 'u' || rest[1] == 'U') &&
                                   (rest[2] == 'e' || rest[2] == 'E'))
                        dotw = TT_TUE;
                  break;
                case 'u': case 'U':
                  if (zone == TT_UNKNOWN &&
                          (rest[1] == 't' || rest[1] == 'T') &&
                          !(rest[2] >= 'A' && rest[2] <= 'Z') &&
                          !(rest[2] >= 'a' && rest[2] <= 'z'))
                        /* UT is the same as GMT but UTx is not. */
                        zone = TT_GMT;
                  break;
                case 'w': case 'W':
                  if (dotw == TT_UNKNOWN &&
                          (rest[1] == 'e' || rest[1] == 'E') &&
                          (rest[2] == 'd' || rest[2] == 'D'))
                        dotw = TT_WED;
                  break;

                case '+': case '-':
                  {
                        const char *end;
                        int sign;
                        if (zone_offset != -1)
                          {
                                /* already got one... */
                                rest++;
                                break;
                          }
                        if (zone != TT_UNKNOWN && zone != TT_GMT)
                          {
                                /* GMT+0300 is legal, but PST+0300 is not. */
                                rest++;
                                break;
                          }

                        sign = ((*rest == '+') ? 1 : -1);
                        rest++; /* move over sign */
                        end = rest;
                        while (*end >= '0' && *end <= '9')
                          end++;
                        if (rest == end) /* no digits here */
                          break;

                        if ((end - rest) == 4)
                          /* offset in HHMM */
                          zone_offset = (((((rest[0]-'0')*10) + (rest[1]-'0')) * 60) +
                                                         (((rest[2]-'0')*10) + (rest[3]-'0')));
                        else if ((end - rest) == 2)
                          /* offset in hours */
                          zone_offset = (((rest[0]-'0')*10) + (rest[1]-'0')) * 60;
                        else if ((end - rest) == 1)
                          /* offset in hours */
                          zone_offset = (rest[0]-'0') * 60;
                        else
                          /* 3 or >4 */
                          break;

                        zone_offset *= sign;
                        zone = TT_GMT;
                        break;
                  }

                case '0': case '1': case '2': case '3': case '4':
                case '5': case '6': case '7': case '8': case '9':
                  {
                        int tmp_hour = -1;
                        int tmp_min = -1;
                        int tmp_sec = -1;
                        int tmp_usec = -1;
                        const char *end = rest + 1;
                        while (*end >= '0' && *end <= '9')
                          end++;

                        /* end is now the first character after a range of digits. */

                        if (*end == ':')
                          {
                                if (hour >= 0 && min >= 0) /* already got it */
                                  break;

                                /* We have seen "[0-9]+:", so this is probably HH:MM[:SS] */
                                if ((end - rest) > 2)
                                  /* it is [0-9][0-9][0-9]+: */
                                  break;
                                else if ((end - rest) == 2)
                                  tmp_hour = ((rest[0]-'0')*10 +
                                                          (rest[1]-'0'));
                                else
                                  tmp_hour = (rest[0]-'0');

                                /* move over the colon, and parse minutes */

                                rest = ++end;
                                while (*end >= '0' && *end <= '9')
                                  end++;

                                if (end == rest)
                                  /* no digits after first colon? */
                                  break;
                                else if ((end - rest) > 2)
                                  /* it is [0-9][0-9][0-9]+: */
                                  break;
                                else if ((end - rest) == 2)
                                  tmp_min = ((rest[0]-'0')*10 +
                                                         (rest[1]-'0'));
                                else
                                  tmp_min = (rest[0]-'0');

                                /* now go for seconds */
                                rest = end;
                                if (*rest == ':')
                                  rest++;
                                end = rest;
                                while (*end >= '0' && *end <= '9')
                                  end++;

                                if (end == rest)
                                  /* no digits after second colon - that's ok. */
                                  ;
                                else if ((end - rest) > 2)
                                  /* it is [0-9][0-9][0-9]+: */
                                  break;
                                else if ((end - rest) == 2)
                                  tmp_sec = ((rest[0]-'0')*10 +
                                                         (rest[1]-'0'));
                                else
                                  tmp_sec = (rest[0]-'0');

                                /* fractional second */
                                rest = end;
                                if (*rest == '.')
                                  {
                                    rest++;
                                    end++;
                                    tmp_usec = 0;
                                    /* use up to 6 digits, skip over the rest */
                                    while (*end >= '0' && *end <= '9')
                                      {
                                        if (end - rest < 6)
                                          tmp_usec = tmp_usec * 10 + *end - '0';
                                        end++;
                                      }
                                    int ndigits = end - rest;
                                    while (ndigits++ < 6)
                                      tmp_usec *= 10;
                                    rest = end;
                                  }

                                if (*rest == 'Z')
                                  {
                                    zone = TT_GMT;
                                    rest++;
                                  }
                                else if (tmp_hour <= 12)
                                  {
                                    /* If we made it here, we've parsed hour and min,
                                       and possibly sec, so the current token is a time.
                                       Now skip over whitespace and see if there's an AM
                                       or PM directly following the time.
                                    */
                                        const char *s = end;
                                        while (*s && (*s == ' ' || *s == '\t'))
                                          s++;
                                        if ((s[0] == 'p' || s[0] == 'P') &&
                                                (s[1] == 'm' || s[1] == 'M'))
                                          /* 10:05pm == 22:05, and 12:05pm == 12:05 */
                                          tmp_hour = (tmp_hour == 12 ? 12 : tmp_hour + 12);
                                        else if (tmp_hour == 12 &&
                                                         (s[0] == 'a' || s[0] == 'A') &&
                                                         (s[1] == 'm' || s[1] == 'M'))
                                          /* 12:05am == 00:05 */
                                          tmp_hour = 0;
                                  }

                                hour = tmp_hour;
                                min = tmp_min;
                                sec = tmp_sec;
                                usec = tmp_usec;
                                rest = end;
                                break;
                          }
                        else if ((*end == '/' || *end == '-') &&
                                         end[1] >= '0' && end[1] <= '9')
                          {
                                /* Perhaps this is 6/16/95, 16/6/95, 6-16-95, or 16-6-95
                                   or even 95-06-05 or 1995-06-22.
                                 */
                                int n1, n2, n3;
                                const char *s;

                                if (month != TT_UNKNOWN)
                                  /* if we saw a month name, this can't be. */
                                  break;

                                s = rest;

                                n1 = (*s++ - '0');                                /* first 1, 2 or 4 digits */
                                if (*s >= '0' && *s <= '9')
                                  {
                                    n1 = n1*10 + (*s++ - '0');

                                    if (*s >= '0' && *s <= '9')            /* optional digits 3 and 4 */
                                      {
                                        n1 = n1*10 + (*s++ - '0');
                                        if (*s < '0' || *s > '9')
                                          break;
                                        n1 = n1*10 + (*s++ - '0');
                                      }
                                  }

                                if (*s != '/' && *s != '-')                /* slash */
                                  break;
                                s++;

                                if (*s < '0' || *s > '9')                /* second 1 or 2 digits */
                                  break;
                                n2 = (*s++ - '0');
                                if (*s >= '0' && *s <= '9')
                                  n2 = n2*10 + (*s++ - '0');

                                if (*s != '/' && *s != '-')                /* slash */
                                  break;
                                s++;

                                if (*s < '0' || *s > '9')                /* third 1, 2, 4, or 5 digits */
                                  break;
                                n3 = (*s++ - '0');
                                if (*s >= '0' && *s <= '9')
                                  n3 = n3*10 + (*s++ - '0');

                                if (*s >= '0' && *s <= '9')            /* optional digits 3, 4, and 5 */
                                  {
                                        n3 = n3*10 + (*s++ - '0');
                                        if (*s < '0' || *s > '9')
                                          break;
                                        n3 = n3*10 + (*s++ - '0');
                                        if (*s >= '0' && *s <= '9')
                                          n3 = n3*10 + (*s++ - '0');
                                  }

                                if (*s == 'T' && s[1] >= '0' && s[1] <= '9')
                                  /* followed by ISO 8601 T delimiter and number is ok */
                                  ;
                                else if ((*s >= '0' && *s <= '9') ||
                                         (*s >= 'A' && *s <= 'Z') ||
                                         (*s >= 'a' && *s <= 'z'))
                                  /* but other alphanumerics are not ok */
                                  break;

                                /* Ok, we parsed three multi-digit numbers, with / or -
                                   between them.  Now decide what the hell they are
                                   (DD/MM/YY or MM/DD/YY or [YY]YY/MM/DD.)
                                 */

                                if (n1 > 31 || n1 == 0)  /* must be [YY]YY/MM/DD */
                                  {
                                        if (n2 > 12) break;
                                        if (n3 > 31) break;
                                        year = n1;
                                        if (year < 70)
                                            year += 2000;
                                        else if (year < 100)
                                            year += 1900;
                                        month = (TIME_TOKEN)(n2 + ((int)TT_JAN) - 1);
                                        date = n3;
                                        rest = s;
                                        break;
                                  }

                                if (n1 > 12 && n2 > 12)  /* illegal */
                                  {
                                        rest = s;
                                        break;
                                  }

                                if (n3 < 70)
                                    n3 += 2000;
                                else if (n3 < 100)
                                    n3 += 1900;

                                if (n1 > 12)  /* must be DD/MM/YY */
                                  {
                                        date = n1;
                                        month = (TIME_TOKEN)(n2 + ((int)TT_JAN) - 1);
                                        year = n3;
                                  }
                                else                  /* assume MM/DD/YY */
                                  {
                                        /* #### In the ambiguous case, should we consult the
                                           locale to find out the local default? */
                                        month = (TIME_TOKEN)(n1 + ((int)TT_JAN) - 1);
                                        date = n2;
                                        year = n3;
                                  }
                                rest = s;
                          }
                        else if ((*end >= 'A' && *end <= 'Z') ||
                                         (*end >= 'a' && *end <= 'z'))
                          /* Digits followed by non-punctuation - what's that? */
                          ;
                        else if ((end - rest) == 5)                /* five digits is a year */
                          year = (year < 0
                                          ? ((rest[0]-'0')*10000L +
                                                 (rest[1]-'0')*1000L +
                                                 (rest[2]-'0')*100L +
                                                 (rest[3]-'0')*10L +
                                                 (rest[4]-'0'))
                                          : year);
                        else if ((end - rest) == 4)                /* four digits is a year */
                          year = (year < 0
                                          ? ((rest[0]-'0')*1000L +
                                                 (rest[1]-'0')*100L +
                                                 (rest[2]-'0')*10L +
                                                 (rest[3]-'0'))
                                          : year);
                        else if ((end - rest) == 2)                /* two digits - date or year */
                          {
                                int n = ((rest[0]-'0')*10 +
                                                 (rest[1]-'0'));
                                /* If we don't have a date (day of the month) and we see a number
                                     less than 32, then assume that is the date.

                                         Otherwise, if we have a date and not a year, assume this is the
                                         year.  If it is less than 70, then assume it refers to the 21st
                                         century.  If it is two digits (>= 70), assume it refers to this
                                         century.  Otherwise, assume it refers to an unambiguous year.

                                         The world will surely end soon.
                                   */
                                if (date < 0 && n < 32)
                                  date = n;
                                else if (year < 0)
                                  {
                                        if (n < 70)
                                          year = 2000 + n;
                                        else if (n < 100)
                                          year = 1900 + n;
                                        else
                                          year = n;
                                  }
                                /* else what the hell is this. */
                          }
                        else if ((end - rest) == 1)                /* one digit - date */
                          date = (date < 0 ? (rest[0]-'0') : date);
                        /* else, three or more than five digits - what's that? */

                        break;
                  }   /* case '0' .. '9' */
                }   /* switch */

          /* Skip to the end of this token, whether we parsed it or not.
             Tokens are delimited by whitespace, or ,;-+/()[] but explicitly not .:
             'T' is also treated as delimiter when followed by a digit (ISO 8601).
           */
          while (*rest &&
                         *rest != ' ' && *rest != '\t' &&
                         *rest != ',' && *rest != ';' &&
                         *rest != '-' && *rest != '+' &&
                         *rest != '/' &&
                         *rest != '(' && *rest != ')' && *rest != '[' && *rest != ']' &&
                         !(*rest == 'T' && rest[1] >= '0' && rest[1] <= '9')
                )
                rest++;
          /* skip over uninteresting chars. */
        SKIP_MORE:
          while (*rest == ' ' || *rest == '\t' ||
                 *rest == ',' || *rest == ';' || *rest == '/' ||
                 *rest == '(' || *rest == ')' || *rest == '[' || *rest == ']')
                rest++;

          /* "-" is ignored at the beginning of a token if we have not yet
                 parsed a year (e.g., the second "-" in "30-AUG-1966"), or if
                 the character after the dash is not a digit. */         
          if (*rest == '-' && ((rest > string &&
              isalpha((unsigned char)rest[-1]) && year < 0) ||
              rest[1] < '0' || rest[1] > '9'))
                {
                  rest++;
                  goto SKIP_MORE;
                }

          /* Skip T that may precede ISO 8601 time. */
          if (*rest == 'T' && rest[1] >= '0' && rest[1] <= '9')
            rest++;
        }   /* while */

  if (zone != TT_UNKNOWN && zone_offset == -1)
        {
          switch (zone)
                {
                case TT_PST: zone_offset = -8 * 60; break;
                case TT_PDT: zone_offset = -8 * 60; dst_offset = 1 * 60; break;
                case TT_MST: zone_offset = -7 * 60; break;
                case TT_MDT: zone_offset = -7 * 60; dst_offset = 1 * 60; break;
                case TT_CST: zone_offset = -6 * 60; break;
                case TT_CDT: zone_offset = -6 * 60; dst_offset = 1 * 60; break;
                case TT_EST: zone_offset = -5 * 60; break;
                case TT_EDT: zone_offset = -5 * 60; dst_offset = 1 * 60; break;
                case TT_AST: zone_offset = -4 * 60; break;
                case TT_NST: zone_offset = -3 * 60 - 30; break;
                case TT_GMT: zone_offset =  0 * 60; break;
                case TT_BST: zone_offset =  0 * 60; dst_offset = 1 * 60; break;
                case TT_MET: zone_offset =  1 * 60; break;
                case TT_EET: zone_offset =  2 * 60; break;
                case TT_JST: zone_offset =  9 * 60; break;
                default:
                  PR_ASSERT (0);
                  break;
                }
        }

  /* If we didn't find a year, month, or day-of-the-month, we can't
         possibly parse this, and in fact, mktime() will do something random
         (I'm seeing it return "Tue Feb  5 06:28:16 2036", which is no doubt
         a numerologically significant date... */
  if (month == TT_UNKNOWN || date == -1 || year == -1 || year > PR_INT16_MAX)
      return PR_FAILURE;

  memset(result, 0, sizeof(*result));
  if (usec != -1)
        result->tm_usec = usec;
  if (sec != -1)
        result->tm_sec = sec;
  if (min != -1)
        result->tm_min = min;
  if (hour != -1)
        result->tm_hour = hour;
  if (date != -1)
        result->tm_mday = date;
  if (month != TT_UNKNOWN)
        result->tm_month = (((int)month) - ((int)TT_JAN));
  if (year != -1)
        result->tm_year = static_cast<PRInt16>(year);
  if (dotw != TT_UNKNOWN)
        result->tm_wday = static_cast<PRInt8>(((int)dotw) - ((int)TT_SUN));
  /*
   * Mainly to compute wday and yday, but normalized time is also required
   * by the check below that works around a Visual C++ 2005 mktime problem.
   */
  PR_NormalizeTime(result, PR_GMTParameters);
  /* The remaining work is to set the gmt and dst offsets in tm_params. */

  if (zone == TT_UNKNOWN && default_to_gmt)
        {
          /* No zone was specified, so pretend the zone was GMT. */
          zone = TT_GMT;
          zone_offset = 0;
        }

  if (zone_offset == -1)
         {
           /* no zone was specified, and we're to assume that everything
             is local. */
          struct tm localTime;
          time_t secs;

          PR_ASSERT(result->tm_month > -1 &&
                    result->tm_mday > 0 &&
                    result->tm_hour > -1 &&
                    result->tm_min > -1 &&
                    result->tm_sec > -1);

            /*
             * To obtain time_t from a tm structure representing the local
             * time, we call mktime().  However, we need to see if we are
             * on 1-Jan-1970 or before.  If we are, we can't call mktime()
             * because mktime() will crash on win16. In that case, we
             * calculate zone_offset based on the zone offset at
             * 00:00:00, 2 Jan 1970 GMT, and subtract zone_offset from the
             * date we are parsing to transform the date to GMT.  We also
             * do so if mktime() returns (time_t) -1 (time out of range).
           */

          /* month, day, hours, mins and secs are always non-negative
             so we dont need to worry about them. */
          if (result->tm_year >= 1970)
                {
                  localTime.tm_sec = result->tm_sec;
                  localTime.tm_min = result->tm_min;
                  localTime.tm_hour = result->tm_hour;
                  localTime.tm_mday = result->tm_mday;
                  localTime.tm_mon = result->tm_month;
                  localTime.tm_year = result->tm_year - 1900;
                  /* Set this to -1 to tell mktime "I don't care".  If you set
                     it to 0 or 1, you are making assertions about whether the
                     date you are handing it is in daylight savings mode or not;
                     and if you're wrong, it will "fix" it for you. */
                  localTime.tm_isdst = -1;

#if _MSC_VER == 1400  /* 1400 = Visual C++ 2005 (8.0) */
                  /*
                   * mktime will return (time_t) -1 if the input is a date
                   * after 23:59:59, December 31, 3000, US Pacific Time (not
                   * UTC as documented): 
                   * http://msdn.microsoft.com/en-us/library/d1y53h2a(VS.80).aspx
                   * But if the year is 3001, mktime also invokes the invalid
                   * parameter handler, causing the application to crash.  This
                   * problem has been reported in
                   * http://connect.microsoft.com/VisualStudio/feedback/ViewFeedback.aspx?FeedbackID=266036.
                   * We avoid this crash by not calling mktime if the date is
                   * out of range.  To use a simple test that works in any time
                   * zone, we consider year 3000 out of range as well.  (See
                   * bug 480740.)
                   */
                  if (result->tm_year >= 3000) {
                      /* Emulate what mktime would have done. */
                      errno = EINVAL;
                      secs = (time_t) -1;
                  } else {
                      secs = mktime(&localTime);
                  }
#else
                  secs = mktime(&localTime);
#endif
                  if (secs != (time_t) -1)
                    {
                      *result_imploded = (PRInt64)secs * PR_USEC_PER_SEC;
                      *result_imploded += result->tm_usec;
                      return PR_SUCCESS;
                    }
                }
                
                /* So mktime() can't handle this case.  We assume the
                   zone_offset for the date we are parsing is the same as
                   the zone offset on 00:00:00 2 Jan 1970 GMT. */
                secs = 86400;
                localtime_r(&secs, &localTime);
                zone_offset = localTime.tm_min
                              + 60 * localTime.tm_hour
                              + 1440 * (localTime.tm_mday - 2);
        }

  result->tm_params.tp_gmt_offset = zone_offset * 60;
  result->tm_params.tp_dst_offset = dst_offset * 60;

  *result_imploded = PR_ImplodeTime(result);
  return PR_SUCCESS;
}
