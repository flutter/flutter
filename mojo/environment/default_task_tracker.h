// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_ENVIRONMENT_DEFAULT_TASK_TRACKER_H_
#define MOJO_ENVIRONMENT_DEFAULT_TASK_TRACKER_H_

namespace mojo {

struct TaskTracker;

namespace internal {

extern const TaskTracker kDefaultTaskTracker;

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_ENVIRONMENT_DEFAULT_TASK_TRACKER_H_
