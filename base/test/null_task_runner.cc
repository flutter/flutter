// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/null_task_runner.h"

namespace base {

NullTaskRunner::NullTaskRunner() {}

NullTaskRunner::~NullTaskRunner() {}

bool NullTaskRunner::PostDelayedTask(
    const tracked_objects::Location& from_here,
    const base::Closure& task,
    base::TimeDelta delay) {
  return false;
}

bool NullTaskRunner::PostNonNestableDelayedTask(
    const tracked_objects::Location& from_here,
    const base::Closure& task,
    base::TimeDelta delay) {
  return false;
}

bool NullTaskRunner::RunsTasksOnCurrentThread() const {
  return true;
}

}  // namespace base
