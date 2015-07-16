// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/memory/memory_pressure_monitor_win.h"

#include "base/basictypes.h"
#include "base/memory/memory_pressure_listener.h"
#include "base/message_loop/message_loop.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace win {

namespace {

struct PressureSettings {
  int phys_left_mb;
  MemoryPressureListener::MemoryPressureLevel level;
};

}  // namespace

// This is outside of the anonymous namespace so that it can be seen as a friend
// to the monitor class.
class TestMemoryPressureMonitor : public MemoryPressureMonitor {
 public:
  using MemoryPressureMonitor::CalculateCurrentPressureLevel;
  using MemoryPressureMonitor::CheckMemoryPressure;

  static const DWORDLONG kMBBytes = 1024 * 1024;

  explicit TestMemoryPressureMonitor(bool large_memory)
      : mem_status_() {
    // Generate a plausible amount of memory.
    mem_status_.ullTotalPhys =
        static_cast<DWORDLONG>(GenerateTotalMemoryMb(large_memory)) * kMBBytes;

    // Rerun InferThresholds using the test fixture's GetSystemMemoryStatus.
    InferThresholds();
    // Stop the timer.
    StopObserving();
  }

  TestMemoryPressureMonitor(int system_memory_mb,
                            int moderate_threshold_mb,
                            int critical_threshold_mb)
      : MemoryPressureMonitor(moderate_threshold_mb, critical_threshold_mb),
        mem_status_() {
    // Set the amount of system memory.
    mem_status_.ullTotalPhys = static_cast<DWORDLONG>(
        system_memory_mb * kMBBytes);

    // Stop the timer.
    StopObserving();
  }

  virtual ~TestMemoryPressureMonitor() {}

  MOCK_METHOD1(OnMemoryPressure,
               void(MemoryPressureListener::MemoryPressureLevel level));

  // Generates an amount of total memory that is consistent with the requested
  // memory model.
  int GenerateTotalMemoryMb(bool large_memory) {
    int total_mb = 64;
    while (total_mb < MemoryPressureMonitor::kLargeMemoryThresholdMb)
      total_mb *= 2;
    if (large_memory)
      return total_mb * 2;
    return total_mb / 2;
  }

  // Sets up the memory status to reflect the provided absolute memory left.
  void SetMemoryFree(int phys_left_mb) {
    // ullTotalPhys is set in the constructor and not modified.

    // Set the amount of available memory.
    mem_status_.ullAvailPhys =
        static_cast<DWORDLONG>(phys_left_mb) * kMBBytes;
    DCHECK_LT(mem_status_.ullAvailPhys, mem_status_.ullTotalPhys);

    // These fields are unused.
    mem_status_.dwMemoryLoad = 0;
    mem_status_.ullTotalPageFile = 0;
    mem_status_.ullAvailPageFile = 0;
    mem_status_.ullTotalVirtual = 0;
    mem_status_.ullAvailVirtual = 0;
  }

  void SetNone() {
    SetMemoryFree(moderate_threshold_mb() + 1);
  }

  void SetModerate() {
    SetMemoryFree(moderate_threshold_mb() - 1);
  }

  void SetCritical() {
    SetMemoryFree(critical_threshold_mb() - 1);
  }

 private:
  bool GetSystemMemoryStatus(MEMORYSTATUSEX* mem_status) override {
    // Simply copy the memory status set by the test fixture.
    *mem_status = mem_status_;
    return true;
  }

  MEMORYSTATUSEX mem_status_;

  DISALLOW_COPY_AND_ASSIGN(TestMemoryPressureMonitor);
};

class WinMemoryPressureMonitorTest : public testing::Test {
 protected:
  void CalculateCurrentMemoryPressureLevelTest(
      TestMemoryPressureMonitor* monitor) {

    int mod = monitor->moderate_threshold_mb();
    monitor->SetMemoryFree(mod + 1);
    EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE,
              monitor->CalculateCurrentPressureLevel());

    monitor->SetMemoryFree(mod);
    EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_MODERATE,
              monitor->CalculateCurrentPressureLevel());

    monitor->SetMemoryFree(mod - 1);
    EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_MODERATE,
              monitor->CalculateCurrentPressureLevel());

    int crit = monitor->critical_threshold_mb();
    monitor->SetMemoryFree(crit + 1);
    EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_MODERATE,
              monitor->CalculateCurrentPressureLevel());

    monitor->SetMemoryFree(crit);
    EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_CRITICAL,
              monitor->CalculateCurrentPressureLevel());

    monitor->SetMemoryFree(crit - 1);
    EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_CRITICAL,
              monitor->CalculateCurrentPressureLevel());
  }

  base::MessageLoopForUI message_loop_;
};

// Tests the fundamental direct calculation of memory pressure with automatic
// small-memory thresholds.
TEST_F(WinMemoryPressureMonitorTest, CalculateCurrentMemoryPressureLevelSmall) {
  static const int kModerateMb =
      MemoryPressureMonitor::kSmallMemoryDefaultModerateThresholdMb;
  static const int kCriticalMb =
      MemoryPressureMonitor::kSmallMemoryDefaultCriticalThresholdMb;

  TestMemoryPressureMonitor monitor(false);  // Small-memory model.

  EXPECT_EQ(kModerateMb, monitor.moderate_threshold_mb());
  EXPECT_EQ(kCriticalMb, monitor.critical_threshold_mb());

  ASSERT_NO_FATAL_FAILURE(CalculateCurrentMemoryPressureLevelTest(&monitor));
}

// Tests the fundamental direct calculation of memory pressure with automatic
// large-memory thresholds.
TEST_F(WinMemoryPressureMonitorTest, CalculateCurrentMemoryPressureLevelLarge) {
  static const int kModerateMb =
      MemoryPressureMonitor::kLargeMemoryDefaultModerateThresholdMb;
  static const int kCriticalMb =
      MemoryPressureMonitor::kLargeMemoryDefaultCriticalThresholdMb;

  TestMemoryPressureMonitor monitor(true);  // Large-memory model.

  EXPECT_EQ(kModerateMb, monitor.moderate_threshold_mb());
  EXPECT_EQ(kCriticalMb, monitor.critical_threshold_mb());

  ASSERT_NO_FATAL_FAILURE(CalculateCurrentMemoryPressureLevelTest(&monitor));
}

// Tests the fundamental direct calculation of memory pressure with manually
// specified threshold levels.
TEST_F(WinMemoryPressureMonitorTest,
       CalculateCurrentMemoryPressureLevelCustom) {
  static const int kSystemMb = 512;
  static const int kModerateMb = 256;
  static const int kCriticalMb = 128;

  TestMemoryPressureMonitor monitor(kSystemMb, kModerateMb, kCriticalMb);

  EXPECT_EQ(kModerateMb, monitor.moderate_threshold_mb());
  EXPECT_EQ(kCriticalMb, monitor.critical_threshold_mb());

  ASSERT_NO_FATAL_FAILURE(CalculateCurrentMemoryPressureLevelTest(&monitor));
}

// This test tests the various transition states from memory pressure, looking
// for the correct behavior on event reposting as well as state updates.
TEST_F(WinMemoryPressureMonitorTest, CheckMemoryPressure) {
  // Large-memory.
  testing::StrictMock<TestMemoryPressureMonitor> monitor(true);
  MemoryPressureListener listener(
      base::Bind(&TestMemoryPressureMonitor::OnMemoryPressure,
                 base::Unretained(&monitor)));

  // Checking the memory pressure at 0% load should not produce any
  // events.
  monitor.SetNone();
  monitor.CheckMemoryPressure();
  message_loop_.RunUntilIdle();
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE,
            monitor.GetCurrentPressureLevel());

  // Setting the memory level to 80% should produce a moderate pressure level.
  EXPECT_CALL(monitor,
              OnMemoryPressure(MemoryPressureListener::
                                   MEMORY_PRESSURE_LEVEL_MODERATE));
  monitor.SetModerate();
  monitor.CheckMemoryPressure();
  message_loop_.RunUntilIdle();
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_MODERATE,
            monitor.GetCurrentPressureLevel());
  testing::Mock::VerifyAndClearExpectations(&monitor);

  // Check that the event gets reposted after a while.
  for (int i = 0; i < monitor.kModeratePressureCooldownCycles; ++i) {
    if (i + 1 == monitor.kModeratePressureCooldownCycles) {
      EXPECT_CALL(monitor,
                  OnMemoryPressure(MemoryPressureListener::
                                       MEMORY_PRESSURE_LEVEL_MODERATE));
    }
    monitor.CheckMemoryPressure();
    message_loop_.RunUntilIdle();
    EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_MODERATE,
              monitor.GetCurrentPressureLevel());
    testing::Mock::VerifyAndClearExpectations(&monitor);
  }

  // Setting the memory usage to 99% should produce critical levels.
  EXPECT_CALL(monitor,
              OnMemoryPressure(MemoryPressureListener::
                                   MEMORY_PRESSURE_LEVEL_CRITICAL));
  monitor.SetCritical();
  monitor.CheckMemoryPressure();
  message_loop_.RunUntilIdle();
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_CRITICAL,
            monitor.GetCurrentPressureLevel());
  testing::Mock::VerifyAndClearExpectations(&monitor);

  // Calling it again should immediately produce a second call.
  EXPECT_CALL(monitor,
              OnMemoryPressure(MemoryPressureListener::
                                   MEMORY_PRESSURE_LEVEL_CRITICAL));
  monitor.CheckMemoryPressure();
  message_loop_.RunUntilIdle();
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_CRITICAL,
            monitor.GetCurrentPressureLevel());
  testing::Mock::VerifyAndClearExpectations(&monitor);

  // When lowering the pressure again there should be a notification and the
  // pressure should go back to moderate.
  EXPECT_CALL(monitor,
              OnMemoryPressure(MemoryPressureListener::
                                   MEMORY_PRESSURE_LEVEL_MODERATE));
  monitor.SetModerate();
  monitor.CheckMemoryPressure();
  message_loop_.RunUntilIdle();
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_MODERATE,
            monitor.GetCurrentPressureLevel());
  testing::Mock::VerifyAndClearExpectations(&monitor);

  // Check that the event gets reposted after a while.
  for (int i = 0; i < monitor.kModeratePressureCooldownCycles; ++i) {
    if (i + 1 == monitor.kModeratePressureCooldownCycles) {
      EXPECT_CALL(monitor,
                  OnMemoryPressure(MemoryPressureListener::
                                       MEMORY_PRESSURE_LEVEL_MODERATE));
    }
    monitor.CheckMemoryPressure();
    message_loop_.RunUntilIdle();
    EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_MODERATE,
              monitor.GetCurrentPressureLevel());
    testing::Mock::VerifyAndClearExpectations(&monitor);
  }

  // Going down to no pressure should not produce an notification.
  monitor.SetNone();
  monitor.CheckMemoryPressure();
  message_loop_.RunUntilIdle();
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE,
            monitor.GetCurrentPressureLevel());
  testing::Mock::VerifyAndClearExpectations(&monitor);
}

}  // namespace win
}  // namespace base
