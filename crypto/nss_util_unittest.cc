// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/nss_util.h"

#include <prtime.h>

#include "base/time/time.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace crypto {

TEST(NSSUtilTest, PRTimeConversion) {
  EXPECT_EQ(base::Time::UnixEpoch(), PRTimeToBaseTime(0));
  EXPECT_EQ(0, BaseTimeToPRTime(base::Time::UnixEpoch()));

  PRExplodedTime prxtime;
  prxtime.tm_params.tp_gmt_offset = 0;
  prxtime.tm_params.tp_dst_offset = 0;
  base::Time::Exploded exploded;
  exploded.year = prxtime.tm_year = 2011;
  exploded.month = 12;
  prxtime.tm_month = 11;
  // PRExplodedTime::tm_wday is a smaller type than Exploded::day_of_week, so
  // assigning the two in this order instead of the reverse avoids potential
  // warnings about type downcasting.
  exploded.day_of_week = prxtime.tm_wday = 0;  // Should be unused.
  exploded.day_of_month = prxtime.tm_mday = 10;
  exploded.hour = prxtime.tm_hour = 2;
  exploded.minute = prxtime.tm_min = 52;
  exploded.second = prxtime.tm_sec = 19;
  exploded.millisecond = 342;
  prxtime.tm_usec = 342000;

  PRTime pr_time = PR_ImplodeTime(&prxtime);
  base::Time base_time = base::Time::FromUTCExploded(exploded);

  EXPECT_EQ(base_time, PRTimeToBaseTime(pr_time));
  EXPECT_EQ(pr_time, BaseTimeToPRTime(base_time));
}

}  // namespace crypto
