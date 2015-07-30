// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/environment/lib/default_task_tracker.h"

#include "mojo/public/cpp/environment/task_tracker.h"

namespace mojo {

namespace {

//
// The standalone task tracker does nothing.
//

TaskTrackingId StartTracking(const char* function_name,
                             const char* file_name,
                             int line_number,
                             const void* program_counter) {
  return TaskTrackingId(0);
}

void EndTracking(const TaskTrackingId id) {
}

void SetEnabled(bool enabled) {
}

}  // namespace

namespace internal {

const TaskTracker kDefaultTaskTracker = {&StartTracking,
                                         &EndTracking,
                                         &SetEnabled};

}  // namespace internal

}  // namespace mojo
