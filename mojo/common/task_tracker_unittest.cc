// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/common/task_tracker.h"

#include "base/tracked_objects.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace common {
namespace test {

class TaskTrackerTest : public testing::Test {
 public:
  void SetUp() override {
    tracked_objects::ThreadData::InitializeAndSetTrackingStatus(
        tracked_objects::ThreadData::PROFILING_ACTIVE);
  }

  void TearDown() override {
    tracked_objects::ThreadData::InitializeAndSetTrackingStatus(
        tracked_objects::ThreadData::DEACTIVATED);
  }
};

TEST_F(TaskTrackerTest, Nesting) {
  intptr_t id0 = TaskTracker::StartTracking("Foo", "foo.cc", 1, nullptr);
  intptr_t id1 = TaskTracker::StartTracking("Bar", "bar.cc", 1, nullptr);
  TaskTracker::EndTracking(id1);
  TaskTracker::EndTracking(id0);

  tracked_objects::ProcessDataSnapshot snapshot;
  tracked_objects::ThreadData::Snapshot(0, &snapshot);

  // Nested one is ignored.
  EXPECT_EQ(1U, snapshot.phased_snapshots[0].tasks.size());
}

TEST_F(TaskTrackerTest, Twice) {
  intptr_t id0 = TaskTracker::StartTracking("Foo", "foo.cc", 1, nullptr);
  TaskTracker::EndTracking(id0);
  intptr_t id1 = TaskTracker::StartTracking("Bar", "bar.cc", 1, nullptr);
  TaskTracker::EndTracking(id1);

  tracked_objects::ProcessDataSnapshot snapshot;
  tracked_objects::ThreadData::Snapshot(0, &snapshot);

  EXPECT_EQ(2U, snapshot.phased_snapshots[0].tasks.size());
}

}  // namespace test
}  // namespace common
}  // namespace mojo
