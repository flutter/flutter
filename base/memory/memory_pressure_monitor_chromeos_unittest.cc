// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/memory/memory_pressure_monitor_chromeos.h"

#include "base/basictypes.h"
#include "base/memory/memory_pressure_listener.h"
#include "base/message_loop/message_loop.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace chromeos {

namespace {

// True if the memory notifier got called.
// Do not read/modify value directly.
bool on_memory_pressure_called = false;

// If the memory notifier got called, this is the memory pressure reported.
MemoryPressureListener::MemoryPressureLevel on_memory_pressure_level =
    MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE;

// Processes OnMemoryPressure calls.
void OnMemoryPressure(MemoryPressureListener::MemoryPressureLevel level) {
  on_memory_pressure_called = true;
  on_memory_pressure_level = level;
}

// Resets the indicator for memory pressure.
void ResetOnMemoryPressureCalled() {
  on_memory_pressure_called = false;
}

// Returns true when OnMemoryPressure was called (and resets it).
bool WasOnMemoryPressureCalled() {
  bool b = on_memory_pressure_called;
  ResetOnMemoryPressureCalled();
  return b;
}

}  // namespace

class TestMemoryPressureMonitor : public MemoryPressureMonitor {
 public:
  TestMemoryPressureMonitor()
      : MemoryPressureMonitor(THRESHOLD_DEFAULT),
        memory_in_percent_override_(0) {
    // Disable any timers which are going on and set a special memory reporting
    // function.
    StopObserving();
  }
  ~TestMemoryPressureMonitor() override {}

  void SetMemoryInPercentOverride(int percent) {
    memory_in_percent_override_ = percent;
  }

  void CheckMemoryPressureForTest() {
    CheckMemoryPressure();
  }

 private:
  int GetUsedMemoryInPercent() override {
    return memory_in_percent_override_;
  }

  int memory_in_percent_override_;
  DISALLOW_COPY_AND_ASSIGN(TestMemoryPressureMonitor);
};

// This test tests the various transition states from memory pressure, looking
// for the correct behavior on event reposting as well as state updates.
TEST(ChromeOSMemoryPressureMonitorTest, CheckMemoryPressure) {
  base::MessageLoopForUI message_loop;
  scoped_ptr<TestMemoryPressureMonitor> monitor(
      new TestMemoryPressureMonitor);
  scoped_ptr<MemoryPressureListener> listener(
      new MemoryPressureListener(base::Bind(&OnMemoryPressure)));
  // Checking the memory pressure while 0% are used should not produce any
  // events.
  monitor->SetMemoryInPercentOverride(0);
  ResetOnMemoryPressureCalled();

  monitor->CheckMemoryPressureForTest();
  message_loop.RunUntilIdle();
  EXPECT_FALSE(WasOnMemoryPressureCalled());
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE,
            monitor->GetCurrentPressureLevel());

  // Setting the memory level to 80% should produce a moderate pressure level.
  monitor->SetMemoryInPercentOverride(80);
  monitor->CheckMemoryPressureForTest();
  message_loop.RunUntilIdle();
  EXPECT_TRUE(WasOnMemoryPressureCalled());
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_MODERATE,
            monitor->GetCurrentPressureLevel());
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_MODERATE,
            on_memory_pressure_level);

  // We need to check that the event gets reposted after a while.
  int i = 0;
  for (; i < 100; i++) {
    monitor->CheckMemoryPressureForTest();
    message_loop.RunUntilIdle();
    EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_MODERATE,
              monitor->GetCurrentPressureLevel());
    if (WasOnMemoryPressureCalled()) {
      EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_MODERATE,
                on_memory_pressure_level);
      break;
    }
  }
  // Should be more then 5 and less then 100.
  EXPECT_LE(5, i);
  EXPECT_GE(99, i);

  // Setting the memory usage to 99% should produce critical levels.
  monitor->SetMemoryInPercentOverride(99);
  monitor->CheckMemoryPressureForTest();
  message_loop.RunUntilIdle();
  EXPECT_TRUE(WasOnMemoryPressureCalled());
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_CRITICAL,
            on_memory_pressure_level);
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_CRITICAL,
            monitor->GetCurrentPressureLevel());

  // Calling it again should immediately produce a second call.
  monitor->CheckMemoryPressureForTest();
  message_loop.RunUntilIdle();
  EXPECT_TRUE(WasOnMemoryPressureCalled());
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_CRITICAL,
            on_memory_pressure_level);
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_CRITICAL,
            monitor->GetCurrentPressureLevel());

  // When lowering the pressure again we should not get an event, but the
  // pressure should go back to moderate.
  monitor->SetMemoryInPercentOverride(80);
  monitor->CheckMemoryPressureForTest();
  message_loop.RunUntilIdle();
  EXPECT_FALSE(WasOnMemoryPressureCalled());
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_MODERATE,
            monitor->GetCurrentPressureLevel());

  // We should need exactly the same amount of calls as before, before the next
  // call comes in.
  int j = 0;
  for (; j < 100; j++) {
    monitor->CheckMemoryPressureForTest();
    message_loop.RunUntilIdle();
    EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_MODERATE,
              monitor->GetCurrentPressureLevel());
    if (WasOnMemoryPressureCalled()) {
      EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_MODERATE,
                on_memory_pressure_level);
      break;
    }
  }
  // We should have needed exactly the same amount of checks as before.
  EXPECT_EQ(j, i);
}

}  // namespace chromeos
}  // namespace base
