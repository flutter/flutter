/*
 * Copyright (C) 1999-2000 Harri Porten (porten@kde.org)
 * Copyright (C) 2006, 2007 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Google Inc. All rights reserved.
 * Copyright (C) 2010 Research In Motion Limited. All rights reserved.
 *
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
 * The Original Code is Mozilla Communicator client code, released
 * March 31, 1998.
 *
 * The Initial Developer of the Original Code is
 * Netscape Communications Corporation.
 * Portions created by the Initial Developer are Copyright (C) 1998
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either of the GNU General Public License Version 2 or later (the "GPL"),
 * or the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 */

#ifndef DateMath_h
#define DateMath_h

#include <stdint.h>
#include <string.h>
#include "wtf/text/WTFString.h"
#include "wtf/WTFExport.h"

namespace WTF {

WTF_EXPORT void initializeDates();

// Not really math related, but this is currently the only shared place to put these.
WTF_EXPORT double parseDateFromNullTerminatedCharacters(const char* dateString);
// dayOfWeek: [0, 6] 0 being Monday, day: [1, 31], month: [0, 11], year: ex: 2011, hours: [0, 23], minutes: [0, 59], seconds: [0, 59], utcOffset: [-720,720].
WTF_EXPORT String makeRFC2822DateString(unsigned dayOfWeek, unsigned day, unsigned month, unsigned year, unsigned hours, unsigned minutes, unsigned seconds, int utcOffset);

const char weekdayName[7][4] = { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" };
const char monthName[12][4] = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };
const char* const monthFullName[12] = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" };

const double minutesPerHour = 60.0;
const double secondsPerMinute = 60.0;
const double msPerSecond = 1000.0;
const double msPerMinute = 60.0 * 1000.0;
const double msPerHour = 60.0 * 60.0 * 1000.0;
const double msPerDay = 24.0 * 60.0 * 60.0 * 1000.0;

WTF_EXPORT bool isLeapYear(int year);

// Returns the number of days from 1970-01-01 to the specified date.
WTF_EXPORT double dateToDaysFrom1970(int year, int month, int day);
WTF_EXPORT int msToYear(double ms);
WTF_EXPORT int dayInYear(int year, int month, int day);
WTF_EXPORT int dayInYear(double ms, int year);
WTF_EXPORT int monthFromDayInYear(int dayInYear, bool leapYear);
WTF_EXPORT int dayInMonthFromDayInYear(int dayInYear, bool leapYear);

// Returns milliseconds with UTC and DST.
WTF_EXPORT double convertToLocalTime(double ms);

} // namespace WTF

using WTF::isLeapYear;
using WTF::dateToDaysFrom1970;
using WTF::dayInMonthFromDayInYear;
using WTF::dayInYear;
using WTF::minutesPerHour;
using WTF::monthFromDayInYear;
using WTF::msPerDay;
using WTF::msPerHour;
using WTF::msPerMinute;
using WTF::msPerSecond;
using WTF::msToYear;
using WTF::secondsPerMinute;
using WTF::parseDateFromNullTerminatedCharacters;
using WTF::makeRFC2822DateString;
using WTF::convertToLocalTime;

#endif // DateMath_h
