// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/i18n/time_formatting.h"

#include "base/i18n/rtl.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/utf_string_conversions.h"
#include "base/time/time.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "third_party/icu/source/common/unicode/uversion.h"
#include "third_party/icu/source/i18n/unicode/calendar.h"
#include "third_party/icu/source/i18n/unicode/timezone.h"

namespace base {
namespace {

const Time::Exploded kTestDateTimeExploded = {
  2011, 4, 6, 30, // Sat, Apr 30, 2011
  15, 42, 7, 0    // 15:42:07.000
};

base::string16 GetShortTimeZone() {
  scoped_ptr<icu::TimeZone> zone(icu::TimeZone::createDefault());
  icu::UnicodeString name;
  zone->getDisplayName(true, icu::TimeZone::SHORT, name);
  return base::string16(name.getBuffer(), name.length());
}

TEST(TimeFormattingTest, TimeFormatTimeOfDayDefault12h) {
  // Test for a locale defaulted to 12h clock.
  // As an instance, we use third_party/icu/source/data/locales/en.txt.
  i18n::SetICUDefaultLocale("en_US");

  Time time(Time::FromLocalExploded(kTestDateTimeExploded));
  string16 clock24h(ASCIIToUTF16("15:42"));
  string16 clock12h_pm(ASCIIToUTF16("3:42 PM"));
  string16 clock12h(ASCIIToUTF16("3:42"));

  // The default is 12h clock.
  EXPECT_EQ(clock12h_pm, TimeFormatTimeOfDay(time));
  EXPECT_EQ(k12HourClock, GetHourClockType());
  // k{Keep,Drop}AmPm should not affect for 24h clock.
  EXPECT_EQ(clock24h,
            TimeFormatTimeOfDayWithHourClockType(time,
                                                 k24HourClock,
                                                 kKeepAmPm));
  EXPECT_EQ(clock24h,
            TimeFormatTimeOfDayWithHourClockType(time,
                                                 k24HourClock,
                                                 kDropAmPm));
  // k{Keep,Drop}AmPm affects for 12h clock.
  EXPECT_EQ(clock12h_pm,
            TimeFormatTimeOfDayWithHourClockType(time,
                                                 k12HourClock,
                                                 kKeepAmPm));
  EXPECT_EQ(clock12h,
            TimeFormatTimeOfDayWithHourClockType(time,
                                                 k12HourClock,
                                                 kDropAmPm));
}

TEST(TimeFormattingTest, TimeFormatTimeOfDayDefault24h) {
  // Test for a locale defaulted to 24h clock.
  // As an instance, we use third_party/icu/source/data/locales/en_GB.txt.
  i18n::SetICUDefaultLocale("en_GB");

  Time time(Time::FromLocalExploded(kTestDateTimeExploded));
  string16 clock24h(ASCIIToUTF16("15:42"));
  string16 clock12h_pm(ASCIIToUTF16("3:42 pm"));
  string16 clock12h(ASCIIToUTF16("3:42"));

  // The default is 24h clock.
  EXPECT_EQ(clock24h, TimeFormatTimeOfDay(time));
  EXPECT_EQ(k24HourClock, GetHourClockType());
  // k{Keep,Drop}AmPm should not affect for 24h clock.
  EXPECT_EQ(clock24h,
            TimeFormatTimeOfDayWithHourClockType(time,
                                                 k24HourClock,
                                                 kKeepAmPm));
  EXPECT_EQ(clock24h,
            TimeFormatTimeOfDayWithHourClockType(time,
                                                 k24HourClock,
                                                 kDropAmPm));
  // k{Keep,Drop}AmPm affects for 12h clock.
  EXPECT_EQ(clock12h_pm,
            TimeFormatTimeOfDayWithHourClockType(time,
                                                 k12HourClock,
                                                 kKeepAmPm));
  EXPECT_EQ(clock12h,
            TimeFormatTimeOfDayWithHourClockType(time,
                                                 k12HourClock,
                                                 kDropAmPm));
}

TEST(TimeFormattingTest, TimeFormatTimeOfDayJP) {
  // Test for a locale that uses different mark than "AM" and "PM".
  // As an instance, we use third_party/icu/source/data/locales/ja.txt.
  i18n::SetICUDefaultLocale("ja_JP");

  Time time(Time::FromLocalExploded(kTestDateTimeExploded));
  string16 clock24h(ASCIIToUTF16("15:42"));
  string16 clock12h_pm(WideToUTF16(L"\x5348\x5f8c" L"3:42"));
  string16 clock12h(ASCIIToUTF16("3:42"));

  // The default is 24h clock.
  EXPECT_EQ(clock24h, TimeFormatTimeOfDay(time));
  EXPECT_EQ(k24HourClock, GetHourClockType());
  // k{Keep,Drop}AmPm should not affect for 24h clock.
  EXPECT_EQ(clock24h,
            TimeFormatTimeOfDayWithHourClockType(time,
                                                 k24HourClock,
                                                 kKeepAmPm));
  EXPECT_EQ(clock24h,
            TimeFormatTimeOfDayWithHourClockType(time,
                                                 k24HourClock,
                                                 kDropAmPm));
  // k{Keep,Drop}AmPm affects for 12h clock.
  EXPECT_EQ(clock12h_pm,
            TimeFormatTimeOfDayWithHourClockType(time,
                                                 k12HourClock,
                                                 kKeepAmPm));
  EXPECT_EQ(clock12h,
            TimeFormatTimeOfDayWithHourClockType(time,
                                                 k12HourClock,
                                                 kDropAmPm));
}

TEST(TimeFormattingTest, TimeFormatDateUS) {
  // See third_party/icu/source/data/locales/en.txt.
  // The date patterns are "EEEE, MMMM d, y", "MMM d, y", and "M/d/yy".
  i18n::SetICUDefaultLocale("en_US");

  Time time(Time::FromLocalExploded(kTestDateTimeExploded));

  EXPECT_EQ(ASCIIToUTF16("Apr 30, 2011"), TimeFormatShortDate(time));
  EXPECT_EQ(ASCIIToUTF16("4/30/11"), TimeFormatShortDateNumeric(time));

  EXPECT_EQ(ASCIIToUTF16("4/30/11, 3:42:07 PM"),
            TimeFormatShortDateAndTime(time));
  EXPECT_EQ(ASCIIToUTF16("4/30/11, 3:42:07 PM ") + GetShortTimeZone(),
            TimeFormatShortDateAndTimeWithTimeZone(time));

  EXPECT_EQ(ASCIIToUTF16("Saturday, April 30, 2011 at 3:42:07 PM"),
            TimeFormatFriendlyDateAndTime(time));

  EXPECT_EQ(ASCIIToUTF16("Saturday, April 30, 2011"),
            TimeFormatFriendlyDate(time));
}

TEST(TimeFormattingTest, TimeFormatDateGB) {
  // See third_party/icu/source/data/locales/en_GB.txt.
  // The date patterns are "EEEE, d MMMM y", "d MMM y", and "dd/MM/yyyy".
  i18n::SetICUDefaultLocale("en_GB");

  Time time(Time::FromLocalExploded(kTestDateTimeExploded));

  EXPECT_EQ(ASCIIToUTF16("30 Apr 2011"), TimeFormatShortDate(time));
  EXPECT_EQ(ASCIIToUTF16("30/04/2011"), TimeFormatShortDateNumeric(time));
  EXPECT_EQ(ASCIIToUTF16("30/04/2011, 15:42:07"),
            TimeFormatShortDateAndTime(time));
  EXPECT_EQ(ASCIIToUTF16("30/04/2011, 15:42:07 ") + GetShortTimeZone(),
            TimeFormatShortDateAndTimeWithTimeZone(time));
  EXPECT_EQ(ASCIIToUTF16("Saturday, 30 April 2011 at 15:42:07"),
            TimeFormatFriendlyDateAndTime(time));
  EXPECT_EQ(ASCIIToUTF16("Saturday, 30 April 2011"),
            TimeFormatFriendlyDate(time));
}

}  // namespace
}  // namespace base
