// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/synchronization/sync_switch.h"

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
