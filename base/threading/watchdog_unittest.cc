// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/threading/watchdog.h"

#include "base/logging.h"
#include "base/synchronization/spin_wait.h"
#include "base/threading/platform_thread.h"
#include "base/time/time.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

namespace {

//------------------------------------------------------------------------------
// Provide a derived class to facilitate testing.

class WatchdogCounter : public Watchdog {
 public:
  WatchdogCounter(const TimeDelta& duration,
                  const std::string& thread_watched_name,
                  bool enabled)
      : Watchdog(duration, thread_watched_name, enabled),
        alarm_counter_(0) {
  }

  ~WatchdogCounter() override {}

  void Alarm() override {
    alarm_counter_++;
    Watchdog::Alarm();
  }

  int alarm_counter() { return alarm_counter_; }

 private:
  int alarm_counter_;

  DISALLOW_COPY_AND_ASSIGN(WatchdogCounter);
};

class WatchdogTest : public testing::Test {
 public:
  void SetUp() override { Watchdog::ResetStaticData(); }
};

}  // namespace

//------------------------------------------------------------------------------
// Actual tests

// Minimal constructor/destructor test.
TEST_F(WatchdogTest, StartupShutdownTest) {
  Watchdog watchdog1(TimeDelta::FromMilliseconds(300), "Disabled", false);
  Watchdog watchdog2(TimeDelta::FromMilliseconds(300), "Enabled", true);
}

// Test ability to call Arm and Disarm repeatedly.
TEST_F(WatchdogTest, ArmDisarmTest) {
  Watchdog watchdog1(TimeDelta::FromMilliseconds(300), "Disabled", false);
  watchdog1.Arm();
  watchdog1.Disarm();
  watchdog1.Arm();
  watchdog1.Disarm();

  Watchdog watchdog2(TimeDelta::FromMilliseconds(300), "Enabled", true);
  watchdog2.Arm();
  watchdog2.Disarm();
  watchdog2.Arm();
  watchdog2.Disarm();
}

// Make sure a basic alarm fires when the time has expired.
TEST_F(WatchdogTest, AlarmTest) {
  WatchdogCounter watchdog(TimeDelta::FromMilliseconds(10), "Enabled", true);
  watchdog.Arm();
  SPIN_FOR_TIMEDELTA_OR_UNTIL_TRUE(TimeDelta::FromMinutes(5),
                                   watchdog.alarm_counter() > 0);
  EXPECT_EQ(1, watchdog.alarm_counter());
}

// Make sure a basic alarm fires when the time has expired.
TEST_F(WatchdogTest, AlarmPriorTimeTest) {
  WatchdogCounter watchdog(TimeDelta(), "Enabled2", true);
  // Set a time in the past.
  watchdog.ArmSomeTimeDeltaAgo(TimeDelta::FromSeconds(2));
  // It should instantly go off, but certainly in less than 5 minutes.
  SPIN_FOR_TIMEDELTA_OR_UNTIL_TRUE(TimeDelta::FromMinutes(5),
                                   watchdog.alarm_counter() > 0);

  EXPECT_EQ(1, watchdog.alarm_counter());
}

// Make sure a disable alarm does nothing, even if we arm it.
TEST_F(WatchdogTest, ConstructorDisabledTest) {
  WatchdogCounter watchdog(TimeDelta::FromMilliseconds(10), "Disabled", false);
  watchdog.Arm();
  // Alarm should not fire, as it was disabled.
  PlatformThread::Sleep(TimeDelta::FromMilliseconds(500));
  EXPECT_EQ(0, watchdog.alarm_counter());
}

// Make sure Disarming will prevent firing, even after Arming.
TEST_F(WatchdogTest, DisarmTest) {
  WatchdogCounter watchdog(TimeDelta::FromSeconds(1), "Enabled3", true);

  TimeTicks start = TimeTicks::Now();
  watchdog.Arm();
  // Sleep a bit, but not past the alarm point.
  PlatformThread::Sleep(TimeDelta::FromMilliseconds(100));
  watchdog.Disarm();
  TimeTicks end = TimeTicks::Now();

  if (end - start > TimeDelta::FromMilliseconds(500)) {
    LOG(WARNING) << "100ms sleep took over 500ms, making the results of this "
                 << "timing-sensitive test suspicious.  Aborting now.";
    return;
  }

  // Alarm should not have fired before it was disarmed.
  EXPECT_EQ(0, watchdog.alarm_counter());

  // Sleep past the point where it would have fired if it wasn't disarmed,
  // and verify that it didn't fire.
  PlatformThread::Sleep(TimeDelta::FromSeconds(1));
  EXPECT_EQ(0, watchdog.alarm_counter());

  // ...but even after disarming, we can still use the alarm...
  // Set a time greater than the timeout into the past.
  watchdog.ArmSomeTimeDeltaAgo(TimeDelta::FromSeconds(10));
  // It should almost instantly go off, but certainly in less than 5 minutes.
  SPIN_FOR_TIMEDELTA_OR_UNTIL_TRUE(TimeDelta::FromMinutes(5),
                                   watchdog.alarm_counter() > 0);

  EXPECT_EQ(1, watchdog.alarm_counter());
}

}  // namespace base
