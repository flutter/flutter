// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/environment/lib/scoped_task_tracking.h"

#include "mojo/public/cpp/environment/environment.h"

namespace mojo {
namespace internal {

ScopedTaskTracking::ScopedTaskTracking(const char* function_name,
                                       const char* file_name,
                                       int line,
                                       const void* program_counter)
    : id_(Environment::GetDefaultTaskTracker()->StartTracking(
          function_name,
          file_name,
          line,
          program_counter)) {
}

ScopedTaskTracking::ScopedTaskTracking(const char* function_name,
                                       const char* file_name,
                                       int line)
    : id_(Environment::GetDefaultTaskTracker()->StartTracking(function_name,
                                                              file_name,
                                                              line,
                                                              nullptr)) {
}

ScopedTaskTracking::~ScopedTaskTracking() {
  Environment::GetDefaultTaskTracker()->EndTracking(id_);
}

}  // namespace internal
}  // namespace mojo
