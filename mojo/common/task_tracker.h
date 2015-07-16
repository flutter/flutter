// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_COMMON_TASK_TRACKER_H_
#define MOJO_COMMON_TASK_TRACKER_H_

#include <stdint.h>

namespace mojo {
namespace common {

class TaskTracker {
 public:
  static intptr_t StartTracking(const char* function_name,
                                const char* file_name,
                                int line_number,
                                const void* program_counter);
  static void EndTracking(intptr_t id);
  static void Enable();
};

}  // namespace common
}  // namespace mojo

#endif  // MOJO_COMMON_TASK_TRACKER_H_
