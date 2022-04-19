// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/synchronization/sync_switch.h"

#include <thread>

#include "gtest/gtest.h"

using fml::SyncSwitch;

TEST(SyncSwitchTest, Basic) {
  SyncSwitch syncSwitch;
  bool switchValue = false;
  syncSwitch.Execute(SyncSwitch::Handlers()
                         .SetIfTrue([&] { switchValue = true; })
                         .SetIfFalse([&] { switchValue = false; }));
  EXPECT_FALSE(switchValue);
  syncSwitch.SetSwitch(true);
  syncSwitch.Execute(SyncSwitch::Handlers()
                         .SetIfTrue([&] { switchValue = true; })
                         .SetIfFalse([&] { switchValue = false; }));
  EXPECT_TRUE(switchValue);
}

TEST(SyncSwitchTest, NoopIfUndefined) {
  SyncSwitch syncSwitch;
  bool switchValue = false;
  syncSwitch.Execute(SyncSwitch::Handlers());
  EXPECT_FALSE(switchValue);
}

TEST(SyncSwitchTest, SharedLock) {
  SyncSwitch syncSwitch;
  syncSwitch.SetSwitch(true);
  bool switchValue1 = false;
  bool switchValue2 = false;

  std::thread thread1([&] {
    syncSwitch.Execute(
        SyncSwitch::Handlers()
            .SetIfTrue([&] {
              switchValue1 = true;

              std::thread thread2([&]() {
                syncSwitch.Execute(
                    SyncSwitch::Handlers()
                        .SetIfTrue([&] { switchValue2 = true; })
                        .SetIfFalse([&] { switchValue2 = false; }));
              });
              thread2.join();
            })
            .SetIfFalse([&] { switchValue1 = false; }));
  });
  thread1.join();
  EXPECT_TRUE(switchValue1);
  EXPECT_TRUE(switchValue2);
}
