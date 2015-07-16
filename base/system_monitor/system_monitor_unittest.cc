// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/system_monitor/system_monitor.h"

#include "base/message_loop/message_loop.h"
#include "base/run_loop.h"
#include "base/test/mock_devices_changed_observer.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

namespace {

class SystemMonitorTest : public testing::Test {
 protected:
  SystemMonitorTest() {
    system_monitor_.reset(new SystemMonitor);
  }

  MessageLoop message_loop_;
  scoped_ptr<SystemMonitor> system_monitor_;

 private:
  DISALLOW_COPY_AND_ASSIGN(SystemMonitorTest);
};

TEST_F(SystemMonitorTest, DeviceChangeNotifications) {
  const int kObservers = 5;

  testing::Sequence mock_sequencer[kObservers];
  MockDevicesChangedObserver observers[kObservers];
  for (int index = 0; index < kObservers; ++index) {
    system_monitor_->AddDevicesChangedObserver(&observers[index]);

    EXPECT_CALL(observers[index],
                OnDevicesChanged(SystemMonitor::DEVTYPE_UNKNOWN))
        .Times(3)
        .InSequence(mock_sequencer[index]);
  }

  system_monitor_->ProcessDevicesChanged(SystemMonitor::DEVTYPE_UNKNOWN);
  RunLoop().RunUntilIdle();

  system_monitor_->ProcessDevicesChanged(SystemMonitor::DEVTYPE_UNKNOWN);
  system_monitor_->ProcessDevicesChanged(SystemMonitor::DEVTYPE_UNKNOWN);
  RunLoop().RunUntilIdle();
}

}  // namespace

}  // namespace base
