// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/common/debug_marker_manager.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gl/gl_mock.h"

namespace gpu {
namespace gles2 {

class DebugMarkerManagerTest : public testing::Test {
 protected:
  void SetUp() override {}

  void TearDown() override {}

  DebugMarkerManager manager_;
};

TEST_F(DebugMarkerManagerTest, Basic) {
  // Test we can get root
  EXPECT_STREQ("", manager_.GetMarker().c_str());
  // Test it's safe to pop an empty stack.
  manager_.PopGroup();
  // Test we can still get root.
  EXPECT_STREQ("", manager_.GetMarker().c_str());
  // Test setting a marker.
  manager_.SetMarker("mark1");
  EXPECT_STREQ(".mark1", manager_.GetMarker().c_str());
  manager_.SetMarker("mark2");
  EXPECT_STREQ(".mark2", manager_.GetMarker().c_str());
  // Test pushing a group.
  manager_.PushGroup("abc");
  EXPECT_STREQ(".abc", manager_.GetMarker().c_str());
  // Test setting a marker on the group
  manager_.SetMarker("mark3");
  EXPECT_STREQ(".abc.mark3", manager_.GetMarker().c_str());
  manager_.SetMarker("mark4");
  EXPECT_STREQ(".abc.mark4", manager_.GetMarker().c_str());
  // Test pushing a 2nd group.
  manager_.PushGroup("def");
  EXPECT_STREQ(".abc.def", manager_.GetMarker().c_str());
  // Test setting a marker on the group
  manager_.SetMarker("mark5");
  EXPECT_STREQ(".abc.def.mark5", manager_.GetMarker().c_str());
  manager_.SetMarker("mark6");
  EXPECT_STREQ(".abc.def.mark6", manager_.GetMarker().c_str());
  // Test poping 2nd group.
  manager_.PopGroup();
  EXPECT_STREQ(".abc.mark4", manager_.GetMarker().c_str());
  manager_.PopGroup();
  EXPECT_STREQ(".mark2", manager_.GetMarker().c_str());
  manager_.PopGroup();
  EXPECT_STREQ(".mark2", manager_.GetMarker().c_str());
}

}  // namespace gles2
}  // namespace gpu


