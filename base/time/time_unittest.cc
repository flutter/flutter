// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/time/time.h"

#include <stdint.h>
#include <time.h>
#include <limits>
#include <string>

#include "base/compiler_specific.h"
#include "base/logging.h"
#include "base/strings/stringprintf.h"
#include "base/threading/platform_thread.h"
#include "build/build_config.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

namespace {

// Specialized test fixture allowing time strings without timezones to be
// tested by comparing them to a known time in the local zone.
// See also pr_time_unittests.cc
class TimeTest : public testing::Test {
 protected:
  void SetUp() override {
    // Use mktime to get a time_t, and turn it into a PRTime by converting
    // seconds to microseconds.  Use 15th Oct 2007 12:45:00 local.  This
    // must be a time guaranteed to be outside of a DST fallback hour in
    // any timezone.
    struct tm local_comparison_tm = {
      0,            // second
      45,           // minute
      12,           // hour
      15,           // day of month
      10 - 1,       // month
      2007 - 1900,  // year
      0,            // day of week (ignored, output only)
      0,            // day of year (ignored, output only)
      -1            // DST in effect, -1 tells mktime to figure it out
    };

    time_t converted_time = mktime(&local_comparison_tm);
    ASSERT_GT(converted_time, 0);
    comparison_time_local_ = Time::FromTimeT(converted_time);

    // time_t representation of 15th Oct 2007 12:45:00 PDT
    comparison_time_pdt_ = Time::FromTimeT(1192477500);
  }

  Time comparison_time_local_;
  Time comparison_time_pdt_;
};

// Test conversions to/from time_t and exploding/unexploding.
TEST_F(TimeTest, TimeT) {
  // C library time and exploded time.
  time_t now_t_1 = time(NULL);
  struct tm tms;
#if defined(OS_WIN)
  localtime_s(&tms, &now_t_1);
#elif defined(OS_POSIX)
  localtime_r(&now_t_1, &tms);
#endif

  // Convert to ours.
  Time our_time_1 = Time::FromTimeT(now_t_1);
  Time::Exploded exploded;
  our_time_1.LocalExplode(&exploded);

  // This will test both our exploding and our time_t -> Time conversion.
  EXPECT_EQ(tms.tm_year + 1900, exploded.year);
  EXPECT_EQ(tms.tm_mon + 1, exploded.month);
  EXPECT_EQ(tms.tm_mday, exploded.day_of_month);
  EXPECT_EQ(tms.tm_hour, exploded.hour);
  EXPECT_EQ(tms.tm_min, exploded.minute);
  EXPECT_EQ(tms.tm_sec, exploded.second);

  // Convert exploded back to the time struct.
  Time our_time_2 = Time::FromLocalExploded(exploded);
  EXPECT_TRUE(our_time_1 == our_time_2);

  time_t now_t_2 = our_time_2.ToTimeT();
  EXPECT_EQ(now_t_1, now_t_2);

  EXPECT_EQ(10, Time().FromTimeT(10).ToTimeT());
  EXPECT_EQ(10.0, Time().FromTimeT(10).ToDoubleT());

  // Conversions of 0 should stay 0.
  EXPECT_EQ(0, Time().ToTimeT());
  EXPECT_EQ(0, Time::FromTimeT(0).ToInternalValue());
}

// Test conversions to/from javascript time.
TEST_F(TimeTest, JsTime) {
  Time epoch = Time::FromJsTime(0.0);
  EXPECT_EQ(epoch, Time::UnixEpoch());
  Time t = Time::FromJsTime(700000.3);
  EXPECT_EQ(700.0003, t.ToDoubleT());
  t = Time::FromDoubleT(800.73);
  EXPECT_EQ(800730.0, t.ToJsTime());
}

#if defined(OS_POSIX)
TEST_F(TimeTest, FromTimeVal) {
  Time now = Time::Now();
  Time also_now = Time::FromTimeVal(now.ToTimeVal());
  EXPECT_EQ(now, also_now);
}
#endif  // OS_POSIX

TEST_F(TimeTest, FromExplodedWithMilliseconds) {
  // Some platform implementations of FromExploded are liable to drop
  // milliseconds if we aren't careful.
  Time now = Time::NowFromSystemTime();
  Time::Exploded exploded1 = {0};
  now.UTCExplode(&exploded1);
  exploded1.millisecond = 500;
  Time time = Time::FromUTCExploded(exploded1);
  Time::Exploded exploded2 = {0};
  time.UTCExplode(&exploded2);
  EXPECT_EQ(exploded1.millisecond, exploded2.millisecond);
}

TEST_F(TimeTest, ZeroIsSymmetric) {
  Time zero_time(Time::FromTimeT(0));
  EXPECT_EQ(0, zero_time.ToTimeT());

  EXPECT_EQ(0.0, zero_time.ToDoubleT());
}

TEST_F(TimeTest, LocalExplode) {
  Time a = Time::Now();
  Time::Exploded exploded;
  a.LocalExplode(&exploded);

  Time b = Time::FromLocalExploded(exploded);

  // The exploded structure doesn't have microseconds, and on Mac & Linux, the
  // internal OS conversion uses seconds, which will cause truncation. So we
  // can only make sure that the delta is within one second.
  EXPECT_TRUE((a - b) < TimeDelta::FromSeconds(1));
}

TEST_F(TimeTest, UTCExplode) {
  Time a = Time::Now();
  Time::Exploded exploded;
  a.UTCExplode(&exploded);

  Time b = Time::FromUTCExploded(exploded);
  EXPECT_TRUE((a - b) < TimeDelta::FromSeconds(1));
}

TEST_F(TimeTest, LocalMidnight) {
  Time::Exploded exploded;
  Time::Now().LocalMidnight().LocalExplode(&exploded);
  EXPECT_EQ(0, exploded.hour);
  EXPECT_EQ(0, exploded.minute);
  EXPECT_EQ(0, exploded.second);
  EXPECT_EQ(0, exploded.millisecond);
}

TEST_F(TimeTest, ParseTimeTest1) {
  time_t current_time = 0;
  time(&current_time);

  const int BUFFER_SIZE = 64;
  struct tm local_time = {0};
  char time_buf[BUFFER_SIZE] = {0};
#if defined(OS_WIN)
  localtime_s(&local_time, &current_time);
  asctime_s(time_buf, arraysize(time_buf), &local_time);
#elif defined(OS_POSIX)
  localtime_r(&current_time, &local_time);
  asctime_r(&local_time, time_buf);
#endif

  Time parsed_time;
  EXPECT_TRUE(Time::FromString(time_buf, &parsed_time));
  EXPECT_EQ(current_time, parsed_time.ToTimeT());
}

TEST_F(TimeTest, DayOfWeekSunday) {
  Time time;
  EXPECT_TRUE(Time::FromString("Sun, 06 May 2012 12:00:00 GMT", &time));
  Time::Exploded exploded;
  time.UTCExplode(&exploded);
  EXPECT_EQ(0, exploded.day_of_week);
}

TEST_F(TimeTest, DayOfWeekWednesday) {
  Time time;
  EXPECT_TRUE(Time::FromString("Wed, 09 May 2012 12:00:00 GMT", &time));
  Time::Exploded exploded;
  time.UTCExplode(&exploded);
  EXPECT_EQ(3, exploded.day_of_week);
}

TEST_F(TimeTest, DayOfWeekSaturday) {
  Time time;
  EXPECT_TRUE(Time::FromString("Sat, 12 May 2012 12:00:00 GMT", &time));
  Time::Exploded exploded;
  time.UTCExplode(&exploded);
  EXPECT_EQ(6, exploded.day_of_week);
}

TEST_F(TimeTest, ParseTimeTest2) {
  Time parsed_time;
  EXPECT_TRUE(Time::FromString("Mon, 15 Oct 2007 19:45:00 GMT", &parsed_time));
  EXPECT_EQ(comparison_time_pdt_, parsed_time);
}

TEST_F(TimeTest, ParseTimeTest3) {
  Time parsed_time;
  EXPECT_TRUE(Time::FromString("15 Oct 07 12:45:00", &parsed_time));
  EXPECT_EQ(comparison_time_local_, parsed_time);
}

TEST_F(TimeTest, ParseTimeTest4) {
  Time parsed_time;
  EXPECT_TRUE(Time::FromString("15 Oct 07 19:45 GMT", &parsed_time));
  EXPECT_EQ(comparison_time_pdt_, parsed_time);
}

TEST_F(TimeTest, ParseTimeTest5) {
  Time parsed_time;
  EXPECT_TRUE(Time::FromString("Mon Oct 15 12:45 PDT 2007", &parsed_time));
  EXPECT_EQ(comparison_time_pdt_, parsed_time);
}

TEST_F(TimeTest, ParseTimeTest6) {
  Time parsed_time;
  EXPECT_TRUE(Time::FromString("Monday, Oct 15, 2007 12:45 PM", &parsed_time));
  EXPECT_EQ(comparison_time_local_, parsed_time);
}

TEST_F(TimeTest, ParseTimeTest7) {
  Time parsed_time;
  EXPECT_TRUE(Time::FromString("10/15/07 12:45:00 PM", &parsed_time));
  EXPECT_EQ(comparison_time_local_, parsed_time);
}

TEST_F(TimeTest, ParseTimeTest8) {
  Time parsed_time;
  EXPECT_TRUE(Time::FromString("15-OCT-2007 12:45pm", &parsed_time));
  EXPECT_EQ(comparison_time_local_, parsed_time);
}

TEST_F(TimeTest, ParseTimeTest9) {
  Time parsed_time;
  EXPECT_TRUE(Time::FromString("16 Oct 2007 4:45-JST (Tuesday)", &parsed_time));
  EXPECT_EQ(comparison_time_pdt_, parsed_time);
}

TEST_F(TimeTest, ParseTimeTest10) {
  Time parsed_time;
  EXPECT_TRUE(Time::FromString("15/10/07 12:45", &parsed_time));
  EXPECT_EQ(parsed_time, comparison_time_local_);
}

// Test some of edge cases around epoch, etc.
TEST_F(TimeTest, ParseTimeTestEpoch0) {
  Time parsed_time;

  // time_t == epoch == 0
  EXPECT_TRUE(Time::FromString("Thu Jan 01 01:00:00 +0100 1970",
                               &parsed_time));
  EXPECT_EQ(0, parsed_time.ToTimeT());
  EXPECT_TRUE(Time::FromString("Thu Jan 01 00:00:00 GMT 1970",
                               &parsed_time));
  EXPECT_EQ(0, parsed_time.ToTimeT());
}

TEST_F(TimeTest, ParseTimeTestEpoch1) {
  Time parsed_time;

  // time_t == 1 second after epoch == 1
  EXPECT_TRUE(Time::FromString("Thu Jan 01 01:00:01 +0100 1970",
                               &parsed_time));
  EXPECT_EQ(1, parsed_time.ToTimeT());
  EXPECT_TRUE(Time::FromString("Thu Jan 01 00:00:01 GMT 1970",
                               &parsed_time));
  EXPECT_EQ(1, parsed_time.ToTimeT());
}

TEST_F(TimeTest, ParseTimeTestEpoch2) {
  Time parsed_time;

  // time_t == 2 seconds after epoch == 2
  EXPECT_TRUE(Time::FromString("Thu Jan 01 01:00:02 +0100 1970",
                               &parsed_time));
  EXPECT_EQ(2, parsed_time.ToTimeT());
  EXPECT_TRUE(Time::FromString("Thu Jan 01 00:00:02 GMT 1970",
                               &parsed_time));
  EXPECT_EQ(2, parsed_time.ToTimeT());
}

TEST_F(TimeTest, ParseTimeTestEpochNeg1) {
  Time parsed_time;

  // time_t == 1 second before epoch == -1
  EXPECT_TRUE(Time::FromString("Thu Jan 01 00:59:59 +0100 1970",
                               &parsed_time));
  EXPECT_EQ(-1, parsed_time.ToTimeT());
  EXPECT_TRUE(Time::FromString("Wed Dec 31 23:59:59 GMT 1969",
                               &parsed_time));
  EXPECT_EQ(-1, parsed_time.ToTimeT());
}

// If time_t is 32 bits, a date after year 2038 will overflow time_t and
// cause timegm() to return -1.  The parsed time should not be 1 second
// before epoch.
TEST_F(TimeTest, ParseTimeTestEpochNotNeg1) {
  Time parsed_time;

  EXPECT_TRUE(Time::FromString("Wed Dec 31 23:59:59 GMT 2100",
                               &parsed_time));
  EXPECT_NE(-1, parsed_time.ToTimeT());
}

TEST_F(TimeTest, ParseTimeTestEpochNeg2) {
  Time parsed_time;

  // time_t == 2 seconds before epoch == -2
  EXPECT_TRUE(Time::FromString("Thu Jan 01 00:59:58 +0100 1970",
                               &parsed_time));
  EXPECT_EQ(-2, parsed_time.ToTimeT());
  EXPECT_TRUE(Time::FromString("Wed Dec 31 23:59:58 GMT 1969",
                               &parsed_time));
  EXPECT_EQ(-2, parsed_time.ToTimeT());
}

TEST_F(TimeTest, ParseTimeTestEpoch1960) {
  Time parsed_time;

  // time_t before Epoch, in 1960
  EXPECT_TRUE(Time::FromString("Wed Jun 29 19:40:01 +0100 1960",
                               &parsed_time));
  EXPECT_EQ(-299999999, parsed_time.ToTimeT());
  EXPECT_TRUE(Time::FromString("Wed Jun 29 18:40:01 GMT 1960",
                               &parsed_time));
  EXPECT_EQ(-299999999, parsed_time.ToTimeT());
  EXPECT_TRUE(Time::FromString("Wed Jun 29 17:40:01 GMT 1960",
                               &parsed_time));
  EXPECT_EQ(-300003599, parsed_time.ToTimeT());
}

TEST_F(TimeTest, ParseTimeTestEmpty) {
  Time parsed_time;
  EXPECT_FALSE(Time::FromString("", &parsed_time));
}

TEST_F(TimeTest, ParseTimeTestInvalidString) {
  Time parsed_time;
  EXPECT_FALSE(Time::FromString("Monday morning 2000", &parsed_time));
}

TEST_F(TimeTest, ExplodeBeforeUnixEpoch) {
  static const int kUnixEpochYear = 1970;  // In case this changes (ha!).
  Time t;
  Time::Exploded exploded;

  t = Time::UnixEpoch() - TimeDelta::FromMicroseconds(1);
  t.UTCExplode(&exploded);
  EXPECT_TRUE(exploded.HasValidValues());
  // Should be 1969-12-31 23:59:59 999 milliseconds (and 999 microseconds).
  EXPECT_EQ(kUnixEpochYear - 1, exploded.year);
  EXPECT_EQ(12, exploded.month);
  EXPECT_EQ(31, exploded.day_of_month);
  EXPECT_EQ(23, exploded.hour);
  EXPECT_EQ(59, exploded.minute);
  EXPECT_EQ(59, exploded.second);
  EXPECT_EQ(999, exploded.millisecond);

  t = Time::UnixEpoch() - TimeDelta::FromMicroseconds(1000);
  t.UTCExplode(&exploded);
  EXPECT_TRUE(exploded.HasValidValues());
  // Should be 1969-12-31 23:59:59 999 milliseconds.
  EXPECT_EQ(kUnixEpochYear - 1, exploded.year);
  EXPECT_EQ(12, exploded.month);
  EXPECT_EQ(31, exploded.day_of_month);
  EXPECT_EQ(23, exploded.hour);
  EXPECT_EQ(59, exploded.minute);
  EXPECT_EQ(59, exploded.second);
  EXPECT_EQ(999, exploded.millisecond);

  t = Time::UnixEpoch() - TimeDelta::FromMicroseconds(1001);
  t.UTCExplode(&exploded);
  EXPECT_TRUE(exploded.HasValidValues());
  // Should be 1969-12-31 23:59:59 998 milliseconds (and 999 microseconds).
  EXPECT_EQ(kUnixEpochYear - 1, exploded.year);
  EXPECT_EQ(12, exploded.month);
  EXPECT_EQ(31, exploded.day_of_month);
  EXPECT_EQ(23, exploded.hour);
  EXPECT_EQ(59, exploded.minute);
  EXPECT_EQ(59, exploded.second);
  EXPECT_EQ(998, exploded.millisecond);

  t = Time::UnixEpoch() - TimeDelta::FromMilliseconds(1000);
  t.UTCExplode(&exploded);
  EXPECT_TRUE(exploded.HasValidValues());
  // Should be 1969-12-31 23:59:59.
  EXPECT_EQ(kUnixEpochYear - 1, exploded.year);
  EXPECT_EQ(12, exploded.month);
  EXPECT_EQ(31, exploded.day_of_month);
  EXPECT_EQ(23, exploded.hour);
  EXPECT_EQ(59, exploded.minute);
  EXPECT_EQ(59, exploded.second);
  EXPECT_EQ(0, exploded.millisecond);

  t = Time::UnixEpoch() - TimeDelta::FromMilliseconds(1001);
  t.UTCExplode(&exploded);
  EXPECT_TRUE(exploded.HasValidValues());
  // Should be 1969-12-31 23:59:58 999 milliseconds.
  EXPECT_EQ(kUnixEpochYear - 1, exploded.year);
  EXPECT_EQ(12, exploded.month);
  EXPECT_EQ(31, exploded.day_of_month);
  EXPECT_EQ(23, exploded.hour);
  EXPECT_EQ(59, exploded.minute);
  EXPECT_EQ(58, exploded.second);
  EXPECT_EQ(999, exploded.millisecond);

  // Make sure we still handle at/after Unix epoch correctly.
  t = Time::UnixEpoch();
  t.UTCExplode(&exploded);
  EXPECT_TRUE(exploded.HasValidValues());
  // Should be 1970-12-31 00:00:00 0 milliseconds.
  EXPECT_EQ(kUnixEpochYear, exploded.year);
  EXPECT_EQ(1, exploded.month);
  EXPECT_EQ(1, exploded.day_of_month);
  EXPECT_EQ(0, exploded.hour);
  EXPECT_EQ(0, exploded.minute);
  EXPECT_EQ(0, exploded.second);
  EXPECT_EQ(0, exploded.millisecond);

  t = Time::UnixEpoch() + TimeDelta::FromMicroseconds(1);
  t.UTCExplode(&exploded);
  EXPECT_TRUE(exploded.HasValidValues());
  // Should be 1970-01-01 00:00:00 0 milliseconds (and 1 microsecond).
  EXPECT_EQ(kUnixEpochYear, exploded.year);
  EXPECT_EQ(1, exploded.month);
  EXPECT_EQ(1, exploded.day_of_month);
  EXPECT_EQ(0, exploded.hour);
  EXPECT_EQ(0, exploded.minute);
  EXPECT_EQ(0, exploded.second);
  EXPECT_EQ(0, exploded.millisecond);

  t = Time::UnixEpoch() + TimeDelta::FromMicroseconds(1000);
  t.UTCExplode(&exploded);
  EXPECT_TRUE(exploded.HasValidValues());
  // Should be 1970-01-01 00:00:00 1 millisecond.
  EXPECT_EQ(kUnixEpochYear, exploded.year);
  EXPECT_EQ(1, exploded.month);
  EXPECT_EQ(1, exploded.day_of_month);
  EXPECT_EQ(0, exploded.hour);
  EXPECT_EQ(0, exploded.minute);
  EXPECT_EQ(0, exploded.second);
  EXPECT_EQ(1, exploded.millisecond);

  t = Time::UnixEpoch() + TimeDelta::FromMilliseconds(1000);
  t.UTCExplode(&exploded);
  EXPECT_TRUE(exploded.HasValidValues());
  // Should be 1970-01-01 00:00:01.
  EXPECT_EQ(kUnixEpochYear, exploded.year);
  EXPECT_EQ(1, exploded.month);
  EXPECT_EQ(1, exploded.day_of_month);
  EXPECT_EQ(0, exploded.hour);
  EXPECT_EQ(0, exploded.minute);
  EXPECT_EQ(1, exploded.second);
  EXPECT_EQ(0, exploded.millisecond);

  t = Time::UnixEpoch() + TimeDelta::FromMilliseconds(1001);
  t.UTCExplode(&exploded);
  EXPECT_TRUE(exploded.HasValidValues());
  // Should be 1970-01-01 00:00:01 1 millisecond.
  EXPECT_EQ(kUnixEpochYear, exploded.year);
  EXPECT_EQ(1, exploded.month);
  EXPECT_EQ(1, exploded.day_of_month);
  EXPECT_EQ(0, exploded.hour);
  EXPECT_EQ(0, exploded.minute);
  EXPECT_EQ(1, exploded.second);
  EXPECT_EQ(1, exploded.millisecond);
}

TEST_F(TimeTest, TimeDeltaMax) {
  TimeDelta max = TimeDelta::Max();
  EXPECT_TRUE(max.is_max());
  EXPECT_EQ(max, TimeDelta::Max());
  EXPECT_GT(max, TimeDelta::FromDays(100 * 365));
  EXPECT_GT(max, TimeDelta());
}

TEST_F(TimeTest, TimeDeltaMaxConversions) {
  TimeDelta t = TimeDelta::Max();
  EXPECT_EQ(std::numeric_limits<int64>::max(), t.ToInternalValue());

  EXPECT_EQ(std::numeric_limits<int>::max(), t.InDays());
  EXPECT_EQ(std::numeric_limits<int>::max(), t.InHours());
  EXPECT_EQ(std::numeric_limits<int>::max(), t.InMinutes());
  EXPECT_EQ(std::numeric_limits<double>::infinity(), t.InSecondsF());
  EXPECT_EQ(std::numeric_limits<int64>::max(), t.InSeconds());
  EXPECT_EQ(std::numeric_limits<double>::infinity(), t.InMillisecondsF());
  EXPECT_EQ(std::numeric_limits<int64>::max(), t.InMilliseconds());
  EXPECT_EQ(std::numeric_limits<int64>::max(), t.InMillisecondsRoundedUp());

  t = TimeDelta::FromDays(std::numeric_limits<int>::max());
  EXPECT_TRUE(t.is_max());

  t = TimeDelta::FromHours(std::numeric_limits<int>::max());
  EXPECT_TRUE(t.is_max());

  t = TimeDelta::FromMinutes(std::numeric_limits<int>::max());
  EXPECT_TRUE(t.is_max());

  t = TimeDelta::FromSeconds(std::numeric_limits<int64>::max());
  EXPECT_TRUE(t.is_max());

  t = TimeDelta::FromMilliseconds(std::numeric_limits<int64>::max());
  EXPECT_TRUE(t.is_max());

  t = TimeDelta::FromSecondsD(std::numeric_limits<double>::infinity());
  EXPECT_TRUE(t.is_max());

  t = TimeDelta::FromMillisecondsD(std::numeric_limits<double>::infinity());
  EXPECT_TRUE(t.is_max());

  t = TimeDelta::FromMicroseconds(std::numeric_limits<int64>::max());
  EXPECT_TRUE(t.is_max());
}

TEST_F(TimeTest, Max) {
  Time max = Time::Max();
  EXPECT_TRUE(max.is_max());
  EXPECT_EQ(max, Time::Max());
  EXPECT_GT(max, Time::Now());
  EXPECT_GT(max, Time());
}

TEST_F(TimeTest, MaxConversions) {
  Time t = Time::Max();
  EXPECT_EQ(std::numeric_limits<int64>::max(), t.ToInternalValue());

  t = Time::FromDoubleT(std::numeric_limits<double>::infinity());
  EXPECT_TRUE(t.is_max());
  EXPECT_EQ(std::numeric_limits<double>::infinity(), t.ToDoubleT());

  t = Time::FromJsTime(std::numeric_limits<double>::infinity());
  EXPECT_TRUE(t.is_max());
  EXPECT_EQ(std::numeric_limits<double>::infinity(), t.ToJsTime());

  t = Time::FromTimeT(std::numeric_limits<time_t>::max());
  EXPECT_TRUE(t.is_max());
  EXPECT_EQ(std::numeric_limits<time_t>::max(), t.ToTimeT());

#if defined(OS_POSIX)
  struct timeval tval;
  tval.tv_sec = std::numeric_limits<time_t>::max();
  tval.tv_usec = static_cast<suseconds_t>(Time::kMicrosecondsPerSecond) - 1;
  t = Time::FromTimeVal(tval);
  EXPECT_TRUE(t.is_max());
  tval = t.ToTimeVal();
  EXPECT_EQ(std::numeric_limits<time_t>::max(), tval.tv_sec);
  EXPECT_EQ(static_cast<suseconds_t>(Time::kMicrosecondsPerSecond) - 1,
      tval.tv_usec);
#endif

#if defined(OS_MACOSX)
  t = Time::FromCFAbsoluteTime(std::numeric_limits<CFAbsoluteTime>::infinity());
  EXPECT_TRUE(t.is_max());
  EXPECT_EQ(std::numeric_limits<CFAbsoluteTime>::infinity(),
            t.ToCFAbsoluteTime());
#endif

#if defined(OS_WIN)
  FILETIME ftime;
  ftime.dwHighDateTime = std::numeric_limits<DWORD>::max();
  ftime.dwLowDateTime = std::numeric_limits<DWORD>::max();
  t = Time::FromFileTime(ftime);
  EXPECT_TRUE(t.is_max());
  ftime = t.ToFileTime();
  EXPECT_EQ(std::numeric_limits<DWORD>::max(), ftime.dwHighDateTime);
  EXPECT_EQ(std::numeric_limits<DWORD>::max(), ftime.dwLowDateTime);
#endif
}

#if defined(OS_MACOSX)
TEST_F(TimeTest, TimeTOverflow) {
  Time t = Time::FromInternalValue(std::numeric_limits<int64>::max() - 1);
  EXPECT_FALSE(t.is_max());
  EXPECT_EQ(std::numeric_limits<time_t>::max(), t.ToTimeT());
}
#endif

#if defined(OS_ANDROID)
TEST_F(TimeTest, FromLocalExplodedCrashOnAndroid) {
  // This crashed inside Time:: FromLocalExploded() on Android 4.1.2.
  // See http://crbug.com/287821
  Time::Exploded midnight = {2013,  // year
                             10,    // month
                             0,     // day_of_week
                             13,    // day_of_month
                             0,     // hour
                             0,     // minute
                             0,     // second
  };
  // The string passed to putenv() must be a char* and the documentation states
  // that it 'becomes part of the environment', so use a static buffer.
  static char buffer[] = "TZ=America/Santiago";
  putenv(buffer);
  tzset();
  Time t = Time::FromLocalExploded(midnight);
  EXPECT_EQ(1381633200, t.ToTimeT());
}
#endif  // OS_ANDROID

TEST(TimeTicks, Deltas) {
  for (int index = 0; index < 50; index++) {
    TimeTicks ticks_start = TimeTicks::Now();
    base::PlatformThread::Sleep(base::TimeDelta::FromMilliseconds(10));
    TimeTicks ticks_stop = TimeTicks::Now();
    TimeDelta delta = ticks_stop - ticks_start;
    // Note:  Although we asked for a 10ms sleep, if the
    // time clock has a finer granularity than the Sleep()
    // clock, it is quite possible to wakeup early.  Here
    // is how that works:
    //      Time(ms timer)      Time(us timer)
    //          5                   5010
    //          6                   6010
    //          7                   7010
    //          8                   8010
    //          9                   9000
    // Elapsed  4ms                 3990us
    //
    // Unfortunately, our InMilliseconds() function truncates
    // rather than rounds.  We should consider fixing this
    // so that our averages come out better.
    EXPECT_GE(delta.InMilliseconds(), 9);
    EXPECT_GE(delta.InMicroseconds(), 9000);
    EXPECT_EQ(delta.InSeconds(), 0);
  }
}

static void HighResClockTest(TimeTicks (*GetTicks)()) {
  // IsHighResolution() is false on some systems.  Since the product still works
  // even if it's false, it makes this entire test questionable.
  if (!TimeTicks::IsHighResolution())
    return;

  // Why do we loop here?
  // We're trying to measure that intervals increment in a VERY small amount
  // of time --  less than 15ms.  Unfortunately, if we happen to have a
  // context switch in the middle of our test, the context switch could easily
  // exceed our limit.  So, we iterate on this several times.  As long as we're
  // able to detect the fine-granularity timers at least once, then the test
  // has succeeded.

  const int kTargetGranularityUs = 15000;  // 15ms

  bool success = false;
  int retries = 100;  // Arbitrary.
  TimeDelta delta;
  while (!success && retries--) {
    TimeTicks ticks_start = GetTicks();
    // Loop until we can detect that the clock has changed.  Non-HighRes timers
    // will increment in chunks, e.g. 15ms.  By spinning until we see a clock
    // change, we detect the minimum time between measurements.
    do {
      delta = GetTicks() - ticks_start;
    } while (delta.InMilliseconds() == 0);

    if (delta.InMicroseconds() <= kTargetGranularityUs)
      success = true;
  }

  // In high resolution mode, we expect to see the clock increment
  // in intervals less than 15ms.
  EXPECT_TRUE(success);
}

TEST(TimeTicks, HighRes) {
  HighResClockTest(&TimeTicks::Now);
}

// Fails frequently on Android http://crbug.com/352633 with:
// Expected: (delta_thread.InMicroseconds()) > (0), actual: 0 vs 0
#if defined(OS_ANDROID)
#define MAYBE_ThreadNow DISABLED_ThreadNow
#else
#define MAYBE_ThreadNow ThreadNow
#endif
TEST(ThreadTicks, MAYBE_ThreadNow) {
  if (ThreadTicks::IsSupported()) {
    TimeTicks begin = TimeTicks::Now();
    ThreadTicks begin_thread = ThreadTicks::Now();
    // Make sure that ThreadNow value is non-zero.
    EXPECT_GT(begin_thread, ThreadTicks());
    // Sleep for 10 milliseconds to get the thread de-scheduled.
    base::PlatformThread::Sleep(base::TimeDelta::FromMilliseconds(10));
    ThreadTicks end_thread = ThreadTicks::Now();
    TimeTicks end = TimeTicks::Now();
    TimeDelta delta = end - begin;
    TimeDelta delta_thread = end_thread - begin_thread;
    // Make sure that some thread time have elapsed.
    EXPECT_GT(delta_thread.InMicroseconds(), 0);
    // But the thread time is at least 9ms less than clock time.
    TimeDelta difference = delta - delta_thread;
    EXPECT_GE(difference.InMicroseconds(), 9000);
  }
}

TEST(TraceTicks, NowFromSystemTraceTime) {
  // Re-use HighRes test for now since clock properties are identical.
  using NowFunction = TimeTicks (*)(void);
  HighResClockTest(reinterpret_cast<NowFunction>(&TraceTicks::Now));
}

TEST(TimeTicks, SnappedToNextTickBasic) {
  base::TimeTicks phase = base::TimeTicks::FromInternalValue(4000);
  base::TimeDelta interval = base::TimeDelta::FromMicroseconds(1000);
  base::TimeTicks timestamp;

  // Timestamp in previous interval.
  timestamp = base::TimeTicks::FromInternalValue(3500);
  EXPECT_EQ(4000,
            timestamp.SnappedToNextTick(phase, interval).ToInternalValue());

  // Timestamp in next interval.
  timestamp = base::TimeTicks::FromInternalValue(4500);
  EXPECT_EQ(5000,
            timestamp.SnappedToNextTick(phase, interval).ToInternalValue());

  // Timestamp multiple intervals before.
  timestamp = base::TimeTicks::FromInternalValue(2500);
  EXPECT_EQ(3000,
            timestamp.SnappedToNextTick(phase, interval).ToInternalValue());

  // Timestamp multiple intervals after.
  timestamp = base::TimeTicks::FromInternalValue(6500);
  EXPECT_EQ(7000,
            timestamp.SnappedToNextTick(phase, interval).ToInternalValue());

  // Timestamp on previous interval.
  timestamp = base::TimeTicks::FromInternalValue(3000);
  EXPECT_EQ(3000,
            timestamp.SnappedToNextTick(phase, interval).ToInternalValue());

  // Timestamp on next interval.
  timestamp = base::TimeTicks::FromInternalValue(5000);
  EXPECT_EQ(5000,
            timestamp.SnappedToNextTick(phase, interval).ToInternalValue());

  // Timestamp equal to phase.
  timestamp = base::TimeTicks::FromInternalValue(4000);
  EXPECT_EQ(4000,
            timestamp.SnappedToNextTick(phase, interval).ToInternalValue());
}

TEST(TimeTicks, SnappedToNextTickOverflow) {
  // int(big_timestamp / interval) < 0, so this causes a crash if the number of
  // intervals elapsed is attempted to be stored in an int.
  base::TimeTicks phase = base::TimeTicks::FromInternalValue(0);
  base::TimeDelta interval = base::TimeDelta::FromMicroseconds(4000);
  base::TimeTicks big_timestamp =
      base::TimeTicks::FromInternalValue(8635916564000);

  EXPECT_EQ(8635916564000,
            big_timestamp.SnappedToNextTick(phase, interval).ToInternalValue());
  EXPECT_EQ(8635916564000,
            big_timestamp.SnappedToNextTick(big_timestamp, interval)
                .ToInternalValue());
}

TEST(TimeDelta, FromAndIn) {
  EXPECT_TRUE(TimeDelta::FromDays(2) == TimeDelta::FromHours(48));
  EXPECT_TRUE(TimeDelta::FromHours(3) == TimeDelta::FromMinutes(180));
  EXPECT_TRUE(TimeDelta::FromMinutes(2) == TimeDelta::FromSeconds(120));
  EXPECT_TRUE(TimeDelta::FromSeconds(2) == TimeDelta::FromMilliseconds(2000));
  EXPECT_TRUE(TimeDelta::FromMilliseconds(2) ==
              TimeDelta::FromMicroseconds(2000));
  EXPECT_TRUE(TimeDelta::FromSecondsD(2.3) ==
              TimeDelta::FromMilliseconds(2300));
  EXPECT_TRUE(TimeDelta::FromMillisecondsD(2.5) ==
              TimeDelta::FromMicroseconds(2500));
  EXPECT_EQ(13, TimeDelta::FromDays(13).InDays());
  EXPECT_EQ(13, TimeDelta::FromHours(13).InHours());
  EXPECT_EQ(13, TimeDelta::FromMinutes(13).InMinutes());
  EXPECT_EQ(13, TimeDelta::FromSeconds(13).InSeconds());
  EXPECT_EQ(13.0, TimeDelta::FromSeconds(13).InSecondsF());
  EXPECT_EQ(13, TimeDelta::FromMilliseconds(13).InMilliseconds());
  EXPECT_EQ(13.0, TimeDelta::FromMilliseconds(13).InMillisecondsF());
  EXPECT_EQ(13, TimeDelta::FromSecondsD(13.1).InSeconds());
  EXPECT_EQ(13.1, TimeDelta::FromSecondsD(13.1).InSecondsF());
  EXPECT_EQ(13, TimeDelta::FromMillisecondsD(13.3).InMilliseconds());
  EXPECT_EQ(13.3, TimeDelta::FromMillisecondsD(13.3).InMillisecondsF());
  EXPECT_EQ(13, TimeDelta::FromMicroseconds(13).InMicroseconds());
}

#if defined(OS_POSIX)
TEST(TimeDelta, TimeSpecConversion) {
  struct timespec result = TimeDelta::FromSeconds(0).ToTimeSpec();
  EXPECT_EQ(result.tv_sec, 0);
  EXPECT_EQ(result.tv_nsec, 0);

  result = TimeDelta::FromSeconds(1).ToTimeSpec();
  EXPECT_EQ(result.tv_sec, 1);
  EXPECT_EQ(result.tv_nsec, 0);

  result = TimeDelta::FromMicroseconds(1).ToTimeSpec();
  EXPECT_EQ(result.tv_sec, 0);
  EXPECT_EQ(result.tv_nsec, 1000);

  result = TimeDelta::FromMicroseconds(
      Time::kMicrosecondsPerSecond + 1).ToTimeSpec();
  EXPECT_EQ(result.tv_sec, 1);
  EXPECT_EQ(result.tv_nsec, 1000);
}
#endif  // OS_POSIX

// Our internal time format is serialized in things like databases, so it's
// important that it's consistent across all our platforms.  We use the 1601
// Windows epoch as the internal format across all platforms.
TEST(TimeDelta, WindowsEpoch) {
  Time::Exploded exploded;
  exploded.year = 1970;
  exploded.month = 1;
  exploded.day_of_week = 0;  // Should be unusued.
  exploded.day_of_month = 1;
  exploded.hour = 0;
  exploded.minute = 0;
  exploded.second = 0;
  exploded.millisecond = 0;
  Time t = Time::FromUTCExploded(exploded);
  // Unix 1970 epoch.
  EXPECT_EQ(INT64_C(11644473600000000), t.ToInternalValue());

  // We can't test 1601 epoch, since the system time functions on Linux
  // only compute years starting from 1900.
}

// We could define this separately for Time, TimeTicks and TimeDelta but the
// definitions would be identical anyway.
template <class Any>
std::string AnyToString(Any any) {
  std::ostringstream oss;
  oss << any;
  return oss.str();
}

TEST(TimeDelta, Magnitude) {
  const int64 zero = 0;
  EXPECT_EQ(TimeDelta::FromMicroseconds(zero),
            TimeDelta::FromMicroseconds(zero).magnitude());

  const int64 one = 1;
  const int64 negative_one = -1;
  EXPECT_EQ(TimeDelta::FromMicroseconds(one),
            TimeDelta::FromMicroseconds(one).magnitude());
  EXPECT_EQ(TimeDelta::FromMicroseconds(one),
            TimeDelta::FromMicroseconds(negative_one).magnitude());

  const int64 max_int64_minus_one = std::numeric_limits<int64>::max() - 1;
  const int64 min_int64_plus_two = std::numeric_limits<int64>::min() + 2;
  EXPECT_EQ(TimeDelta::FromMicroseconds(max_int64_minus_one),
            TimeDelta::FromMicroseconds(max_int64_minus_one).magnitude());
  EXPECT_EQ(TimeDelta::FromMicroseconds(max_int64_minus_one),
            TimeDelta::FromMicroseconds(min_int64_plus_two).magnitude());
}


TEST(TimeDelta, NumericOperators) {
  double d = 0.5;
  EXPECT_EQ(TimeDelta::FromMilliseconds(500),
            TimeDelta::FromMilliseconds(1000) * d);
  EXPECT_EQ(TimeDelta::FromMilliseconds(2000),
            TimeDelta::FromMilliseconds(1000) / d);
  EXPECT_EQ(TimeDelta::FromMilliseconds(500),
            TimeDelta::FromMilliseconds(1000) *= d);
  EXPECT_EQ(TimeDelta::FromMilliseconds(2000),
            TimeDelta::FromMilliseconds(1000) /= d);
  EXPECT_EQ(TimeDelta::FromMilliseconds(500),
            d * TimeDelta::FromMilliseconds(1000));

  float f = 0.5;
  EXPECT_EQ(TimeDelta::FromMilliseconds(500),
            TimeDelta::FromMilliseconds(1000) * f);
  EXPECT_EQ(TimeDelta::FromMilliseconds(2000),
            TimeDelta::FromMilliseconds(1000) / f);
  EXPECT_EQ(TimeDelta::FromMilliseconds(500),
            TimeDelta::FromMilliseconds(1000) *= f);
  EXPECT_EQ(TimeDelta::FromMilliseconds(2000),
            TimeDelta::FromMilliseconds(1000) /= f);
  EXPECT_EQ(TimeDelta::FromMilliseconds(500),
            f * TimeDelta::FromMilliseconds(1000));


  int i = 2;
  EXPECT_EQ(TimeDelta::FromMilliseconds(2000),
            TimeDelta::FromMilliseconds(1000) * i);
  EXPECT_EQ(TimeDelta::FromMilliseconds(500),
            TimeDelta::FromMilliseconds(1000) / i);
  EXPECT_EQ(TimeDelta::FromMilliseconds(2000),
            TimeDelta::FromMilliseconds(1000) *= i);
  EXPECT_EQ(TimeDelta::FromMilliseconds(500),
            TimeDelta::FromMilliseconds(1000) /= i);
  EXPECT_EQ(TimeDelta::FromMilliseconds(2000),
            i * TimeDelta::FromMilliseconds(1000));

  int64_t i64 = 2;
  EXPECT_EQ(TimeDelta::FromMilliseconds(2000),
            TimeDelta::FromMilliseconds(1000) * i64);
  EXPECT_EQ(TimeDelta::FromMilliseconds(500),
            TimeDelta::FromMilliseconds(1000) / i64);
  EXPECT_EQ(TimeDelta::FromMilliseconds(2000),
            TimeDelta::FromMilliseconds(1000) *= i64);
  EXPECT_EQ(TimeDelta::FromMilliseconds(500),
            TimeDelta::FromMilliseconds(1000) /= i64);
  EXPECT_EQ(TimeDelta::FromMilliseconds(2000),
            i64 * TimeDelta::FromMilliseconds(1000));


  EXPECT_EQ(TimeDelta::FromMilliseconds(500),
            TimeDelta::FromMilliseconds(1000) * 0.5);
  EXPECT_EQ(TimeDelta::FromMilliseconds(2000),
            TimeDelta::FromMilliseconds(1000) / 0.5);
  EXPECT_EQ(TimeDelta::FromMilliseconds(500),
            TimeDelta::FromMilliseconds(1000) *= 0.5);
  EXPECT_EQ(TimeDelta::FromMilliseconds(2000),
            TimeDelta::FromMilliseconds(1000) /= 0.5);
  EXPECT_EQ(TimeDelta::FromMilliseconds(500),
            0.5 * TimeDelta::FromMilliseconds(1000));

  EXPECT_EQ(TimeDelta::FromMilliseconds(2000),
            TimeDelta::FromMilliseconds(1000) * 2);
  EXPECT_EQ(TimeDelta::FromMilliseconds(500),
            TimeDelta::FromMilliseconds(1000) / 2);
  EXPECT_EQ(TimeDelta::FromMilliseconds(2000),
            TimeDelta::FromMilliseconds(1000) *= 2);
  EXPECT_EQ(TimeDelta::FromMilliseconds(500),
            TimeDelta::FromMilliseconds(1000) /= 2);
  EXPECT_EQ(TimeDelta::FromMilliseconds(2000),
            2 * TimeDelta::FromMilliseconds(1000));
}

bool IsMin(TimeDelta delta) {
  return (-delta).is_max();
}

TEST(TimeDelta, Overflows) {
  // Some sanity checks.
  EXPECT_TRUE(TimeDelta::Max().is_max());
  EXPECT_TRUE(IsMin(-TimeDelta::Max()));
  EXPECT_GT(TimeDelta(), -TimeDelta::Max());

  TimeDelta large_delta = TimeDelta::Max() - TimeDelta::FromMilliseconds(1);
  TimeDelta large_negative = -large_delta;
  EXPECT_GT(TimeDelta(), large_negative);
  EXPECT_FALSE(large_delta.is_max());
  EXPECT_FALSE(IsMin(-large_negative));
  TimeDelta one_second = TimeDelta::FromSeconds(1);

  // Test +, -, * and / operators.
  EXPECT_TRUE((large_delta + one_second).is_max());
  EXPECT_TRUE(IsMin(large_negative + (-one_second)));
  EXPECT_TRUE(IsMin(large_negative - one_second));
  EXPECT_TRUE((large_delta - (-one_second)).is_max());
  EXPECT_TRUE((large_delta * 2).is_max());
  EXPECT_TRUE(IsMin(large_delta * -2));
  EXPECT_TRUE((large_delta / 0.5).is_max());
  EXPECT_TRUE(IsMin(large_delta / -0.5));

  // Test +=, -=, *= and /= operators.
  TimeDelta delta = large_delta;
  delta += one_second;
  EXPECT_TRUE(delta.is_max());
  delta = large_negative;
  delta += -one_second;
  EXPECT_TRUE(IsMin(delta));

  delta = large_negative;
  delta -= one_second;
  EXPECT_TRUE(IsMin(delta));
  delta = large_delta;
  delta -= -one_second;
  EXPECT_TRUE(delta.is_max());

  delta = large_delta;
  delta *= 2;
  EXPECT_TRUE(delta.is_max());
  delta = large_negative;
  delta *= 1.5;
  EXPECT_TRUE(IsMin(delta));

  delta = large_delta;
  delta /= 0.5;
  EXPECT_TRUE(delta.is_max());
  delta = large_negative;
  delta /= 0.5;
  EXPECT_TRUE(IsMin(delta));

  // Test operations with Time and TimeTicks.
  EXPECT_TRUE((large_delta + Time::Now()).is_max());
  EXPECT_TRUE((large_delta + TimeTicks::Now()).is_max());
  EXPECT_TRUE((Time::Now() + large_delta).is_max());
  EXPECT_TRUE((TimeTicks::Now() + large_delta).is_max());

  Time time_now = Time::Now();
  EXPECT_EQ(one_second, (time_now + one_second) - time_now);
  EXPECT_EQ(-one_second, (time_now - one_second) - time_now);

  TimeTicks ticks_now = TimeTicks::Now();
  EXPECT_EQ(-one_second, (ticks_now - one_second) - ticks_now);
  EXPECT_EQ(one_second, (ticks_now + one_second) - ticks_now);
}

TEST(TimeDeltaLogging, DCheckEqCompiles) {
  DCHECK_EQ(TimeDelta(), TimeDelta());
}

TEST(TimeDeltaLogging, EmptyIsZero) {
  TimeDelta zero;
  EXPECT_EQ("0s", AnyToString(zero));
}

TEST(TimeDeltaLogging, FiveHundredMs) {
  TimeDelta five_hundred_ms = TimeDelta::FromMilliseconds(500);
  EXPECT_EQ("0.5s", AnyToString(five_hundred_ms));
}

TEST(TimeDeltaLogging, MinusTenSeconds) {
  TimeDelta minus_ten_seconds = TimeDelta::FromSeconds(-10);
  EXPECT_EQ("-10s", AnyToString(minus_ten_seconds));
}

TEST(TimeDeltaLogging, DoesNotMessUpFormattingFlags) {
  std::ostringstream oss;
  std::ios_base::fmtflags flags_before = oss.flags();
  oss << TimeDelta();
  EXPECT_EQ(flags_before, oss.flags());
}

TEST(TimeDeltaLogging, DoesNotMakeStreamBad) {
  std::ostringstream oss;
  oss << TimeDelta();
  EXPECT_TRUE(oss.good());
}

TEST(TimeLogging, DCheckEqCompiles) {
  DCHECK_EQ(Time(), Time());
}

TEST(TimeLogging, ChromeBirthdate) {
  Time birthdate;
  ASSERT_TRUE(Time::FromString("Tue, 02 Sep 2008 09:42:18 GMT", &birthdate));
  EXPECT_EQ("2008-09-02 09:42:18.000 UTC", AnyToString(birthdate));
}

TEST(TimeLogging, DoesNotMessUpFormattingFlags) {
  std::ostringstream oss;
  std::ios_base::fmtflags flags_before = oss.flags();
  oss << Time();
  EXPECT_EQ(flags_before, oss.flags());
}

TEST(TimeLogging, DoesNotMakeStreamBad) {
  std::ostringstream oss;
  oss << Time();
  EXPECT_TRUE(oss.good());
}

TEST(TimeTicksLogging, DCheckEqCompiles) {
  DCHECK_EQ(TimeTicks(), TimeTicks());
}

TEST(TimeTicksLogging, ZeroTime) {
  TimeTicks zero;
  EXPECT_EQ("0 bogo-microseconds", AnyToString(zero));
}

TEST(TimeTicksLogging, FortyYearsLater) {
  TimeTicks forty_years_later =
      TimeTicks() + TimeDelta::FromDays(365.25 * 40);
  EXPECT_EQ("1262304000000000 bogo-microseconds",
            AnyToString(forty_years_later));
}

TEST(TimeTicksLogging, DoesNotMessUpFormattingFlags) {
  std::ostringstream oss;
  std::ios_base::fmtflags flags_before = oss.flags();
  oss << TimeTicks();
  EXPECT_EQ(flags_before, oss.flags());
}

TEST(TimeTicksLogging, DoesNotMakeStreamBad) {
  std::ostringstream oss;
  oss << TimeTicks();
  EXPECT_TRUE(oss.good());
}

}  // namespace

}  // namespace base
