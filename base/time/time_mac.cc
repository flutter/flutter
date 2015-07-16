// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/time/time.h"

#include <CoreFoundation/CFDate.h>
#include <CoreFoundation/CFTimeZone.h>
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <stdint.h>
#include <sys/sysctl.h>
#include <sys/time.h>
#include <sys/types.h>
#include <time.h>

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/mac/mach_logging.h"
#include "base/mac/scoped_cftyperef.h"
#include "base/mac/scoped_mach_port.h"
#include "base/numerics/safe_conversions.h"

namespace {

int64_t ComputeCurrentTicks() {
#if defined(OS_IOS)
  // On iOS mach_absolute_time stops while the device is sleeping. Instead use
  // now - KERN_BOOTTIME to get a time difference that is not impacted by clock
  // changes. KERN_BOOTTIME will be updated by the system whenever the system
  // clock change.
  struct timeval boottime;
  int mib[2] = {CTL_KERN, KERN_BOOTTIME};
  size_t size = sizeof(boottime);
  int kr = sysctl(mib, arraysize(mib), &boottime, &size, NULL, 0);
  DCHECK_EQ(KERN_SUCCESS, kr);
  base::TimeDelta time_difference = base::Time::Now() -
      (base::Time::FromTimeT(boottime.tv_sec) +
       base::TimeDelta::FromMicroseconds(boottime.tv_usec));
  return time_difference.InMicroseconds();
#else
  static mach_timebase_info_data_t timebase_info;
  if (timebase_info.denom == 0) {
    // Zero-initialization of statics guarantees that denom will be 0 before
    // calling mach_timebase_info.  mach_timebase_info will never set denom to
    // 0 as that would be invalid, so the zero-check can be used to determine
    // whether mach_timebase_info has already been called.  This is
    // recommended by Apple's QA1398.
    kern_return_t kr = mach_timebase_info(&timebase_info);
    MACH_DCHECK(kr == KERN_SUCCESS, kr) << "mach_timebase_info";
  }

  // mach_absolute_time is it when it comes to ticks on the Mac.  Other calls
  // with less precision (such as TickCount) just call through to
  // mach_absolute_time.

  // timebase_info converts absolute time tick units into nanoseconds.  Convert
  // to microseconds up front to stave off overflows.
  base::CheckedNumeric<uint64_t> result(
      mach_absolute_time() / base::Time::kNanosecondsPerMicrosecond);
  result *= timebase_info.numer;
  result /= timebase_info.denom;

  // Don't bother with the rollover handling that the Windows version does.
  // With numer and denom = 1 (the expected case), the 64-bit absolute time
  // reported in nanoseconds is enough to last nearly 585 years.
  return base::checked_cast<int64_t>(result.ValueOrDie());
#endif  // defined(OS_IOS)
}

int64_t ComputeThreadTicks() {
#if defined(OS_IOS)
  NOTREACHED();
  return 0;
#else
  base::mac::ScopedMachSendRight thread(mach_thread_self());
  mach_msg_type_number_t thread_info_count = THREAD_BASIC_INFO_COUNT;
  thread_basic_info_data_t thread_info_data;

  if (thread.get() == MACH_PORT_NULL) {
    DLOG(ERROR) << "Failed to get mach_thread_self()";
    return 0;
  }

  kern_return_t kr = thread_info(
      thread,
      THREAD_BASIC_INFO,
      reinterpret_cast<thread_info_t>(&thread_info_data),
      &thread_info_count);
  MACH_DCHECK(kr == KERN_SUCCESS, kr) << "thread_info";

  base::CheckedNumeric<int64_t> absolute_micros(
      thread_info_data.user_time.seconds);
  absolute_micros *= base::Time::kMicrosecondsPerSecond;
  absolute_micros += thread_info_data.user_time.microseconds;
  return absolute_micros.ValueOrDie();
#endif  // defined(OS_IOS)
}

}  // namespace

namespace base {

// The Time routines in this file use Mach and CoreFoundation APIs, since the
// POSIX definition of time_t in Mac OS X wraps around after 2038--and
// there are already cookie expiration dates, etc., past that time out in
// the field.  Using CFDate prevents that problem, and using mach_absolute_time
// for TimeTicks gives us nice high-resolution interval timing.

// Time -----------------------------------------------------------------------

// Core Foundation uses a double second count since 2001-01-01 00:00:00 UTC.
// The UNIX epoch is 1970-01-01 00:00:00 UTC.
// Windows uses a Gregorian epoch of 1601.  We need to match this internally
// so that our time representations match across all platforms.  See bug 14734.
//   irb(main):010:0> Time.at(0).getutc()
//   => Thu Jan 01 00:00:00 UTC 1970
//   irb(main):011:0> Time.at(-11644473600).getutc()
//   => Mon Jan 01 00:00:00 UTC 1601
static const int64 kWindowsEpochDeltaSeconds = INT64_C(11644473600);

// static
const int64 Time::kWindowsEpochDeltaMicroseconds =
    kWindowsEpochDeltaSeconds * Time::kMicrosecondsPerSecond;

// Some functions in time.cc use time_t directly, so we provide an offset
// to convert from time_t (Unix epoch) and internal (Windows epoch).
// static
const int64 Time::kTimeTToMicrosecondsOffset = kWindowsEpochDeltaMicroseconds;

// static
Time Time::Now() {
  return FromCFAbsoluteTime(CFAbsoluteTimeGetCurrent());
}

// static
Time Time::FromCFAbsoluteTime(CFAbsoluteTime t) {
  COMPILE_ASSERT(std::numeric_limits<CFAbsoluteTime>::has_infinity,
                 numeric_limits_infinity_is_undefined_when_not_has_infinity);
  if (t == 0)
    return Time();  // Consider 0 as a null Time.
  if (t == std::numeric_limits<CFAbsoluteTime>::infinity())
    return Max();
  return Time(static_cast<int64>(
      (t + kCFAbsoluteTimeIntervalSince1970) * kMicrosecondsPerSecond) +
      kWindowsEpochDeltaMicroseconds);
}

CFAbsoluteTime Time::ToCFAbsoluteTime() const {
  COMPILE_ASSERT(std::numeric_limits<CFAbsoluteTime>::has_infinity,
                 numeric_limits_infinity_is_undefined_when_not_has_infinity);
  if (is_null())
    return 0;  // Consider 0 as a null Time.
  if (is_max())
    return std::numeric_limits<CFAbsoluteTime>::infinity();
  return (static_cast<CFAbsoluteTime>(us_ - kWindowsEpochDeltaMicroseconds) /
      kMicrosecondsPerSecond) - kCFAbsoluteTimeIntervalSince1970;
}

// static
Time Time::NowFromSystemTime() {
  // Just use Now() because Now() returns the system time.
  return Now();
}

// static
Time Time::FromExploded(bool is_local, const Exploded& exploded) {
  CFGregorianDate date;
  date.second = exploded.second +
      exploded.millisecond / static_cast<double>(kMillisecondsPerSecond);
  date.minute = exploded.minute;
  date.hour = exploded.hour;
  date.day = exploded.day_of_month;
  date.month = exploded.month;
  date.year = exploded.year;

  base::ScopedCFTypeRef<CFTimeZoneRef> time_zone(
      is_local ? CFTimeZoneCopySystem() : NULL);
  CFAbsoluteTime seconds = CFGregorianDateGetAbsoluteTime(date, time_zone) +
      kCFAbsoluteTimeIntervalSince1970;
  return Time(static_cast<int64>(seconds * kMicrosecondsPerSecond) +
      kWindowsEpochDeltaMicroseconds);
}

void Time::Explode(bool is_local, Exploded* exploded) const {
  // Avoid rounding issues, by only putting the integral number of seconds
  // (rounded towards -infinity) into a |CFAbsoluteTime| (which is a |double|).
  int64 microsecond = us_ % kMicrosecondsPerSecond;
  if (microsecond < 0)
    microsecond += kMicrosecondsPerSecond;
  CFAbsoluteTime seconds = ((us_ - microsecond) / kMicrosecondsPerSecond) -
                           kWindowsEpochDeltaSeconds -
                           kCFAbsoluteTimeIntervalSince1970;

  base::ScopedCFTypeRef<CFTimeZoneRef> time_zone(
      is_local ? CFTimeZoneCopySystem() : NULL);
  CFGregorianDate date = CFAbsoluteTimeGetGregorianDate(seconds, time_zone);
  // 1 = Monday, ..., 7 = Sunday.
  int cf_day_of_week = CFAbsoluteTimeGetDayOfWeek(seconds, time_zone);

  exploded->year = date.year;
  exploded->month = date.month;
  exploded->day_of_week = cf_day_of_week % 7;
  exploded->day_of_month = date.day;
  exploded->hour = date.hour;
  exploded->minute = date.minute;
  // Make sure seconds are rounded down towards -infinity.
  exploded->second = floor(date.second);
  // Calculate milliseconds ourselves, since we rounded the |seconds|, making
  // sure to round towards -infinity.
  exploded->millisecond =
      (microsecond >= 0) ? microsecond / kMicrosecondsPerMillisecond :
                           (microsecond - kMicrosecondsPerMillisecond + 1) /
                               kMicrosecondsPerMillisecond;
}

// TimeTicks ------------------------------------------------------------------

// static
TimeTicks TimeTicks::Now() {
  return TimeTicks(ComputeCurrentTicks());
}

// static
bool TimeTicks::IsHighResolution() {
  return true;
}

// static
ThreadTicks ThreadTicks::Now() {
  return ThreadTicks(ComputeThreadTicks());
}

// static
TraceTicks TraceTicks::Now() {
  return TraceTicks(ComputeCurrentTicks());
}

}  // namespace base
