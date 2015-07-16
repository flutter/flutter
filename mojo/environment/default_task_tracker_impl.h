// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_ENVIRONMENT_DEFAULT_TASK_TRACKER_IMPL_H_
#define MOJO_ENVIRONMENT_DEFAULT_TASK_TRACKER_IMPL_H_

#include "mojo/public/cpp/environment/task_tracker.h"

namespace mojo {
namespace internal {

const TaskTracker* GetDefaultTaskTrackerImpl();

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_ENVIRONMENT_DEFAULT_TASK_TRACKER_IMPL_H_
