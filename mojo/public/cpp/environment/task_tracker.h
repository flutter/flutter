// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_ENVIRONMENT_TASK_TRACKER_H_
#define MOJO_PUBLIC_CPP_ENVIRONMENT_TASK_TRACKER_H_

#include <stdint.h>

namespace mojo {

typedef intptr_t TaskTrackingId;

// Interface for wiring task-level profiling. This API is mainly used by the
// generated interface implementation.
struct TaskTracker {
  // Start tracking. The returned id must be reclaimed through |EndTracking()|.
  TaskTrackingId (*StartTracking)(const char* function_name,
                                  const char* file_name,
                                  int line_number,
                                  const void* program_counter);
  // Finish tracking. The |id| is one that is returned from |StartTracking()|.
  void (*EndTracking)(const TaskTrackingId id);
  // Enable or disable tracking. It is disabled by default.
  void (*SetEnabled)(bool enabled);
};

}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_ENVIRONMENT_TASK_TRACKER_H_
