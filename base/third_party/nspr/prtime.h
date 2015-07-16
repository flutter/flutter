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
 *---------------------------------------------------------------------------
 *
 * prtime.h --
 *
 *     NSPR date and time functions
 * CVS revision 3.10
 * This file contains definitions of NSPR's basic types required by
 * prtime.cc. These types have been copied over from the following NSPR
 * files prtime.h, prtypes.h(CVS revision 3.35), prlong.h(CVS revision 3.13)
 *
 *---------------------------------------------------------------------------
 */

#ifndef BASE_PRTIME_H__
#define BASE_PRTIME_H__

#include <stdint.h>

#include "base/base_export.h"

typedef int8_t PRInt8;
typedef int16_t PRInt16;
typedef int32_t PRInt32;
typedef int64_t PRInt64;
typedef int PRIntn;

typedef PRIntn PRBool;
#define PR_TRUE 1
#define PR_FALSE 0

typedef enum { PR_FAILURE = -1, PR_SUCCESS = 0 } PRStatus;

#define PR_ASSERT DCHECK
#define PR_CALLBACK
#define PR_INT16_MAX 32767
#define NSPR_API(__type) extern __type

/**********************************************************************/
/************************* TYPES AND CONSTANTS ************************/
/**********************************************************************/

#define PR_MSEC_PER_SEC		1000UL
#define PR_USEC_PER_SEC		1000000UL
#define PR_NSEC_PER_SEC		1000000000UL
#define PR_USEC_PER_MSEC	1000UL
#define PR_NSEC_PER_MSEC	1000000UL

/*
 * PRTime --
 *
 *     NSPR represents basic time as 64-bit signed integers relative
 *     to midnight (00:00:00), January 1, 1970 Greenwich Mean Time (GMT).
 *     (GMT is also known as Coordinated Universal Time, UTC.)
 *     The units of time are in microseconds. Negative times are allowed
 *     to represent times prior to the January 1970 epoch. Such values are
 *     intended to be exported to other systems or converted to human
 *     readable form.
 *
 *     Notes on porting: PRTime corresponds to time_t in ANSI C.  NSPR 1.0
 *     simply uses PRInt64.
 */

typedef PRInt64 PRTime;

/*
 * Time zone and daylight saving time corrections applied to GMT to
 * obtain the local time of some geographic location
 */

typedef struct PRTimeParameters {
    PRInt32 tp_gmt_offset;     /* the offset from GMT in seconds */
    PRInt32 tp_dst_offset;     /* contribution of DST in seconds */
} PRTimeParameters;

/*
 * PRExplodedTime --
 *
 *     Time broken down into human-readable components such as year, month,
 *     day, hour, minute, second, and microsecond.  Time zone and daylight
 *     saving time corrections may be applied.  If they are applied, the
 *     offsets from the GMT must be saved in the 'tm_params' field so that
 *     all the information is available to reconstruct GMT.
 *
 *     Notes on porting: PRExplodedTime corrresponds to struct tm in
 *     ANSI C, with the following differences:
 *       - an additional field tm_usec;
 *       - replacing tm_isdst by tm_params;
 *       - the month field is spelled tm_month, not tm_mon;
 *       - we use absolute year, AD, not the year since 1900.
 *     The corresponding type in NSPR 1.0 is called PRTime.  Below is
 *     a table of date/time type correspondence in the three APIs:
 *         API          time since epoch          time in components
 *       ANSI C             time_t                  struct tm
 *       NSPR 1.0           PRInt64                   PRTime
 *       NSPR 2.0           PRTime                  PRExplodedTime
 */

typedef struct PRExplodedTime {
    PRInt32 tm_usec;		    /* microseconds past tm_sec (0-99999)  */
    PRInt32 tm_sec;             /* seconds past tm_min (0-61, accomodating
                                   up to two leap seconds) */	
    PRInt32 tm_min;             /* minutes past tm_hour (0-59) */
    PRInt32 tm_hour;            /* hours past tm_day (0-23) */
    PRInt32 tm_mday;            /* days past tm_mon (1-31, note that it
				                starts from 1) */
    PRInt32 tm_month;           /* months past tm_year (0-11, Jan = 0) */
    PRInt16 tm_year;            /* absolute year, AD (note that we do not
				                count from 1900) */

    PRInt8 tm_wday;		        /* calculated day of the week
				                (0-6, Sun = 0) */
    PRInt16 tm_yday;            /* calculated day of the year
				                (0-365, Jan 1 = 0) */

    PRTimeParameters tm_params;  /* time parameters used by conversion */
} PRExplodedTime;

/*
 * PRTimeParamFn --
 *
 *     A function of PRTimeParamFn type returns the time zone and
 *     daylight saving time corrections for some geographic location,
 *     given the current time in GMT.  The input argument gmt should
 *     point to a PRExplodedTime that is in GMT, i.e., whose
 *     tm_params contains all 0's.
 *
 *     For any time zone other than GMT, the computation is intended to
 *     consist of two steps:
 *       - Figure out the time zone correction, tp_gmt_offset.  This number
 *         usually depends on the geographic location only.  But it may
 *         also depend on the current time.  For example, all of China
 *         is one time zone right now.  But this situation may change
 *         in the future.
 *       - Figure out the daylight saving time correction, tp_dst_offset.
 *         This number depends on both the geographic location and the
 *         current time.  Most of the DST rules are expressed in local
 *         current time.  If so, one should apply the time zone correction
 *         to GMT before applying the DST rules.
 */

typedef PRTimeParameters (PR_CALLBACK *PRTimeParamFn)(const PRExplodedTime *gmt);

/**********************************************************************/
/****************************** FUNCTIONS *****************************/
/**********************************************************************/

NSPR_API(PRTime)
PR_ImplodeTime(const PRExplodedTime *exploded);

/*
 * Adjust exploded time to normalize field overflows after manipulation.
 * Note that the following fields of PRExplodedTime should not be
 * manipulated:
 *   - tm_month and tm_year: because the number of days in a month and
 *     number of days in a year are not constant, it is ambiguous to
 *     manipulate the month and year fields, although one may be tempted
 *     to.  For example, what does "a month from January 31st" mean?
 *   - tm_wday and tm_yday: these fields are calculated by NSPR.  Users
 *     should treat them as "read-only".
 */

NSPR_API(void) PR_NormalizeTime(
    PRExplodedTime *exploded, PRTimeParamFn params);

/**********************************************************************/
/*********************** TIME PARAMETER FUNCTIONS *********************/
/**********************************************************************/

/* Time parameters that represent Greenwich Mean Time */
NSPR_API(PRTimeParameters) PR_GMTParameters(const PRExplodedTime *gmt);

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

/*
 * This is the only funtion that should be called from outside base, and only
 * from the unit test.
 */

BASE_EXPORT PRStatus PR_ParseTimeString (
	const char *string,
	PRBool default_to_gmt,
	PRTime *result);

#endif  // BASE_PRTIME_H__
