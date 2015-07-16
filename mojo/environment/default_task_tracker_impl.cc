// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/environment/default_task_tracker_impl.h"

#include "base/logging.h"
#include "mojo/common/task_tracker.h"

namespace mojo {
namespace internal {
namespace {

bool g_enabled = false;

TaskTrackingId StartTracking(const char* function_name,
                             const char* file_name,
                             int line_number,
                             const void* program_counter) {
  if (!g_enabled)
    return TaskTrackingId(0);

  return common::TaskTracker::StartTracking(function_name, file_name,
                                              line_number, program_counter);
}

void EndTracking(const TaskTrackingId id) {
  if (!g_enabled) {
    DCHECK_EQ(0, id);
    return;
  }

  common::TaskTracker::EndTracking(id);
}

void SetEnabled(bool enabled) {
  g_enabled = enabled;
}

const TaskTracker kDefaultTaskTracker = {&StartTracking,
                                         &EndTracking,
                                         &SetEnabled};

}  // namespace

const TaskTracker* GetDefaultTaskTrackerImpl() {
  return &kDefaultTaskTracker;
}

}  // namespace internal
}  // namespace mojo
