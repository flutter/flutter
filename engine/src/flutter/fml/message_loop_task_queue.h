// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_MESSAGE_LOOP_TASK_QUEUE_H_
#define FLUTTER_FML_MESSAGE_LOOP_TASK_QUEUE_H_

#include <map>
#include <mutex>
#include <vector>

#include "flutter/fml/closure.h"
#include "flutter/fml/delayed_task.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_counted.h"
#include "flutter/fml/synchronization/thread_annotations.h"
#include "flutter/fml/wakeable.h"

namespace fml {

enum class FlushType {
  kSingle,
  kAll,
};

// This class keeps track of all the tasks and observers that
// need to be run on it's MessageLoopImpl. This also wakes up the
// loop at the required times.
class MessageLoopTaskQueue {
 public:
  // Lifecycle.

  MessageLoopTaskQueue();

  ~MessageLoopTaskQueue();

  void Dispose();

  // Tasks methods.

  void RegisterTask(fml::closure task, fml::TimePoint target_time);

  bool HasPendingTasks();

  void GetTasksToRunNow(FlushType type, std::vector<fml::closure>& invocations);

  size_t GetNumPendingTasks();

  // Observers methods.

  void AddTaskObserver(intptr_t key, fml::closure callback);

  void RemoveTaskObserver(intptr_t key);

  void NotifyObservers();

  // Misc.

  void Swap(MessageLoopTaskQueue& other);

  void SetWakeable(fml::Wakeable* wakeable);

 private:
  void WakeUp(fml::TimePoint time);

  Wakeable* wakeable_ = NULL;

  std::mutex observers_mutex_;
  std::map<intptr_t, fml::closure> task_observers_
      FML_GUARDED_BY(observers_mutex_);

  std::mutex delayed_tasks_mutex_;
  DelayedTaskQueue delayed_tasks_ FML_GUARDED_BY(delayed_tasks_mutex_);
  size_t order_ FML_GUARDED_BY(delayed_tasks_mutex_);

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(MessageLoopTaskQueue);
};

}  // namespace fml

#endif  // FLUTTER_FML_MESSAGE_LOOP_TASK_QUEUE_H_
