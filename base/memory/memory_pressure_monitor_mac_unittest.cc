// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/memory/memory_pressure_monitor_mac.h"

#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace mac {

class TestMemoryPressureMonitor : public MemoryPressureMonitor {
 public:
  using MemoryPressureMonitor::MemoryPressureLevelForMacMemoryPressure;

  TestMemoryPressureMonitor() { }

 private:
  DISALLOW_COPY_AND_ASSIGN(TestMemoryPressureMonitor);
};

TEST(MacMemoryPressureMonitorTest, MemoryPressureFromMacMemoryPressure) {
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE,
            TestMemoryPressureMonitor::
                MemoryPressureLevelForMacMemoryPressure(
                    DISPATCH_MEMORYPRESSURE_NORMAL));
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_MODERATE,
            TestMemoryPressureMonitor::
                MemoryPressureLevelForMacMemoryPressure(
                    DISPATCH_MEMORYPRESSURE_WARN));
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_CRITICAL,
            TestMemoryPressureMonitor::
                MemoryPressureLevelForMacMemoryPressure(
                    DISPATCH_MEMORYPRESSURE_CRITICAL));
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE,
            TestMemoryPressureMonitor::
                MemoryPressureLevelForMacMemoryPressure(0));
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE,
            TestMemoryPressureMonitor::
                MemoryPressureLevelForMacMemoryPressure(3));
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE,
            TestMemoryPressureMonitor::
                MemoryPressureLevelForMacMemoryPressure(5));
  EXPECT_EQ(MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE,
            TestMemoryPressureMonitor::
                MemoryPressureLevelForMacMemoryPressure(-1));
}

TEST(MacMemoryPressureMonitorTest, CurrentMemoryPressure) {
  TestMemoryPressureMonitor monitor;
  MemoryPressureListener::MemoryPressureLevel memory_pressure =
      monitor.GetCurrentPressureLevel();
  EXPECT_TRUE(memory_pressure ==
                  MemoryPressureListener::MEMORY_PRESSURE_LEVEL_NONE ||
              memory_pressure ==
                  MemoryPressureListener::MEMORY_PRESSURE_LEVEL_MODERATE ||
              memory_pressure ==
                  MemoryPressureListener::MEMORY_PRESSURE_LEVEL_CRITICAL);
}

}  // namespace mac
}  // namespace base
