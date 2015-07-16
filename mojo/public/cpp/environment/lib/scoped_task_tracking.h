// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_ENVIRONMENT_LIB_SCOPED_TASK_TRACKING_H_
#define MOJO_PUBLIC_CPP_ENVIRONMENT_LIB_SCOPED_TASK_TRACKING_H_

#include "mojo/public/cpp/environment/task_tracker.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace internal {

// An RAII wrapper for |TaskTrackingId|.
class ScopedTaskTracking {
 public:
  ScopedTaskTracking(const char* function_name,
                     const char* file_name,
                     int line,
                     const void* program_counter);
  ScopedTaskTracking(const char* function_name,
                     const char* file_name,
                     int line);
  ~ScopedTaskTracking();

 private:
  TaskTrackingId id_;
  MOJO_DISALLOW_COPY_AND_ASSIGN(ScopedTaskTracking);
};

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_ENVIRONMENT_SCOPED_TASK_TRACKING_H_
