// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_PENDING_TASK_H_
#define BASE_PENDING_TASK_H_

#include <queue>

#include "base/base_export.h"
#include "base/callback.h"
#include "base/location.h"
#include "base/time/time.h"
#include "base/tracking_info.h"

namespace base {

// Contains data about a pending task. Stored in TaskQueue and DelayedTaskQueue
// for use by classes that queue and execute tasks.
struct BASE_EXPORT PendingTask : public TrackingInfo {
  PendingTask(const tracked_objects::Location& posted_from,
              const Closure& task);
  PendingTask(const tracked_objects::Location& posted_from,
              const Closure& task,
              TimeTicks delayed_run_time,
              bool nestable);
  ~PendingTask();

  // Used to support sorting.
  bool operator<(const PendingTask& other) const;

  // The task to run.
  Closure task;

  // The site this PendingTask was posted from.
  tracked_objects::Location posted_from;

  // Secondary sort key for run time.
  int sequence_num;

  // OK to dispatch from a nested loop.
  bool nestable;

  // Needs high resolution timers.
  bool is_high_res;
};

// Wrapper around std::queue specialized for PendingTask which adds a Swap
// helper method.
class BASE_EXPORT TaskQueue : public std::queue<PendingTask> {
 public:
  void Swap(TaskQueue* queue);
};

// PendingTasks are sorted by their |delayed_run_time| property.
typedef std::priority_queue<base::PendingTask> DelayedTaskQueue;

}  // namespace base

#endif  // BASE_PENDING_TASK_H_
