// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stdint.h>
#include <time.h>

#include "base/compiler_specific.h"
#include "base/third_party/nspr/prtime.h"
#include "base/time/time.h"
#include "testing/gtest/include/gtest/gtest.h"

using base::Time;

namespace {

// time_t representation of 15th Oct 2007 12:45:00 PDT
PRTime comparison_time_pdt = 1192477500 * Time::kMicrosecondsPerSecond;

// Time with positive tz offset and fractional seconds:
// 2013-07-08T11:28:12.441381+02:00
PRTime comparison_time_2 = INT64_C(1373275692441381);   // represented as GMT

// Specialized test fixture allowing time strings without timezones to be
// tested by comparing them to a known time in the local zone.
class PRTimeTest : public testing::Test {
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
    comparison_time_local_ =
        mktime(&local_comparison_tm) * Time::kMicrosecondsPerSecond;
    ASSERT_GT(comparison_time_local_, 0);

    const int microseconds = 441381;
    struct tm local_comparison_tm_2 = {
      12,           // second
      28,           // minute
      11,           // hour
      8,            // day of month
      7 - 1,        // month
      2013 - 1900,  // year
      0,            // day of week (ignored, output only)
      0,            // day of year (ignored, output only)
      -1            // DST in effect, -1 tells mktime to figure it out
    };
    comparison_time_local_2_ =
        mktime(&local_comparison_tm_2) * Time::kMicrosecondsPerSecond;
    ASSERT_GT(comparison_time_local_2_, 0);
    comparison_time_local_2_ += microseconds;
  }

  PRTime comparison_time_local_;
  PRTime comparison_time_local_2_;
};

// Tests the PR_ParseTimeString nspr helper function for
// a variety of time strings.
TEST_F(PRTimeTest, ParseTimeTest1) {
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

  PRTime current_time64 = static_cast<PRTime>(current_time) * PR_USEC_PER_SEC;

  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString(time_buf, PR_FALSE, &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
  EXPECT_EQ(current_time64, parsed_time);
}

TEST_F(PRTimeTest, ParseTimeTest2) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("Mon, 15 Oct 2007 19:45:00 GMT",
                                       PR_FALSE, &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
  EXPECT_EQ(comparison_time_pdt, parsed_time);
}

TEST_F(PRTimeTest, ParseTimeTest3) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("15 Oct 07 12:45:00", PR_FALSE,
                                       &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
  EXPECT_EQ(comparison_time_local_, parsed_time);
}

TEST_F(PRTimeTest, ParseTimeTest4) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("15 Oct 07 19:45 GMT", PR_FALSE,
                                       &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
  EXPECT_EQ(comparison_time_pdt, parsed_time);
}

TEST_F(PRTimeTest, ParseTimeTest5) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("Mon Oct 15 12:45 PDT 2007",
                                       PR_FALSE, &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
  EXPECT_EQ(comparison_time_pdt, parsed_time);
}

TEST_F(PRTimeTest, ParseTimeTest6) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("Monday, Oct 15, 2007 12:45 PM",
                                       PR_FALSE, &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
  EXPECT_EQ(comparison_time_local_, parsed_time);
}

TEST_F(PRTimeTest, ParseTimeTest7) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("10/15/07 12:45:00 PM", PR_FALSE,
                                       &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
  EXPECT_EQ(comparison_time_local_, parsed_time);
}

TEST_F(PRTimeTest, ParseTimeTest8) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("10/15/07 12:45:00. PM", PR_FALSE,
                                       &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
  EXPECT_EQ(comparison_time_local_, parsed_time);
}

TEST_F(PRTimeTest, ParseTimeTest9) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("10/15/07 12:45:00.0 PM", PR_FALSE,
                                       &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
  EXPECT_EQ(comparison_time_local_, parsed_time);
}

TEST_F(PRTimeTest, ParseTimeTest10) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("15-OCT-2007 12:45pm", PR_FALSE,
                                       &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
  EXPECT_EQ(comparison_time_local_, parsed_time);
}

TEST_F(PRTimeTest, ParseTimeTest11) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("16 Oct 2007 4:45-JST (Tuesday)",
                                       PR_FALSE, &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
  EXPECT_EQ(comparison_time_pdt, parsed_time);
}

// hh:mm timezone offset.
TEST_F(PRTimeTest, ParseTimeTest12) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("2013-07-08T11:28:12.441381+02:00",
                                       PR_FALSE, &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
  EXPECT_EQ(comparison_time_2, parsed_time);
}

// hhmm timezone offset.
TEST_F(PRTimeTest, ParseTimeTest13) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("2013-07-08T11:28:12.441381+0200",
                                       PR_FALSE, &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
  EXPECT_EQ(comparison_time_2, parsed_time);
}

// hh timezone offset.
TEST_F(PRTimeTest, ParseTimeTest14) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("2013-07-08T11:28:12.4413819+02",
                                       PR_FALSE, &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
  EXPECT_EQ(comparison_time_2, parsed_time);
}

// 5 digits fractional second.
TEST_F(PRTimeTest, ParseTimeTest15) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("2013-07-08T09:28:12.44138Z",
                                       PR_FALSE, &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
  EXPECT_EQ(comparison_time_2-1, parsed_time);
}

// Fractional seconds, local timezone.
TEST_F(PRTimeTest, ParseTimeTest16) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("2013-07-08T11:28:12.441381",
                                       PR_FALSE, &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
  EXPECT_EQ(comparison_time_local_2_, parsed_time);
}

// "Z" (=GMT) timezone.
TEST_F(PRTimeTest, ParseTimeTest17) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("2013-07-08T09:28:12.441381Z",
                                       PR_FALSE, &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
  EXPECT_EQ(comparison_time_2, parsed_time);
}

// "T" delimiter replaced by space.
TEST_F(PRTimeTest, ParseTimeTest18) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("2013-07-08 09:28:12.441381Z",
                                       PR_FALSE, &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
  EXPECT_EQ(comparison_time_2, parsed_time);
}

TEST_F(PRTimeTest, ParseTimeTestInvalid1) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("201-07-08T09:28:12.441381Z",
                                       PR_FALSE, &parsed_time);
  EXPECT_EQ(PR_FAILURE, result);
}

TEST_F(PRTimeTest, ParseTimeTestInvalid2) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("2013-007-08T09:28:12.441381Z",
                                       PR_FALSE, &parsed_time);
  EXPECT_EQ(PR_FAILURE, result);
}

TEST_F(PRTimeTest, ParseTimeTestInvalid3) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("2013-07-008T09:28:12.441381Z",
                                       PR_FALSE, &parsed_time);
  EXPECT_EQ(PR_FAILURE, result);
}

// This test should not crash when compiled with Visual C++ 2005 (see
// http://crbug.com/4387).
TEST_F(PRTimeTest, ParseTimeTestOutOfRange) {
  PRTime parsed_time = 0;
  // Note the lack of timezone in the time string.  The year has to be 3001.
  // The date has to be after 23:59:59, December 31, 3000, US Pacific Time, so
  // we use January 2, 3001 to make sure it's after the magic maximum in any
  // timezone.
  PRStatus result = PR_ParseTimeString("Sun Jan  2 00:00:00 3001",
                                       PR_FALSE, &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
}

TEST_F(PRTimeTest, ParseTimeTestNotNormalized1) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("Mon Oct 15 12:44:60 PDT 2007",
                                       PR_FALSE, &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
  EXPECT_EQ(comparison_time_pdt, parsed_time);
}

TEST_F(PRTimeTest, ParseTimeTestNotNormalized2) {
  PRTime parsed_time = 0;
  PRStatus result = PR_ParseTimeString("Sun Oct 14 36:45 PDT 2007",
                                       PR_FALSE, &parsed_time);
  EXPECT_EQ(PR_SUCCESS, result);
  EXPECT_EQ(comparison_time_pdt, parsed_time);
}

}  // namespace
