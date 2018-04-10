// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_MESSAGE_LOOP_IMPL_H_
#define FLUTTER_FML_MESSAGE_LOOP_IMPL_H_

#include <atomic>
#include <deque>
#include <mutex>
#include <queue>
#include <set>
#include <utility>

#include "flutter/fml/message_loop.h"
#include "lib/fxl/functional/closure.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/memory/ref_counted.h"
#include "lib/fxl/time/time_point.h"

namespace fml {

class MessageLoopImpl : public fxl::RefCountedThreadSafe<MessageLoopImpl> {
 public:
  static fxl::RefPtr<MessageLoopImpl> Create();

  virtual ~MessageLoopImpl();

  virtual void Run() = 0;

  virtual void Terminate() = 0;

  virtual void WakeUp(fxl::TimePoint time_point) = 0;

  void PostTask(fxl::Closure task, fxl::TimePoint target_time);

  void AddTaskObserver(TaskObserver* observer);

  void RemoveTaskObserver(TaskObserver* observer);

  void DoRun();

  void DoTerminate();

  // Exposed for the embedder shell which allows clients to poll for events
  // instead of dedicating a thread to the message loop.
  void RunExpiredTasksNow();

 protected:
  MessageLoopImpl();

 private:
  struct DelayedTask {
    size_t order;
    fxl::Closure task;
    fxl::TimePoint target_time;

    DelayedTask(size_t p_order,
                fxl::Closure p_task,
                fxl::TimePoint p_target_time)
        : order(p_order), task(std::move(p_task)), target_time(p_target_time) {}
  };

  struct DelayedTaskCompare {
    bool operator()(const DelayedTask& a, const DelayedTask& b) {
      return a.target_time == b.target_time ? a.order > b.order
                                            : a.target_time > b.target_time;
    }
  };

  using DelayedTaskQueue = std::
      priority_queue<DelayedTask, std::deque<DelayedTask>, DelayedTaskCompare>;

  std::set<TaskObserver*> task_observers_;
  std::mutex delayed_tasks_mutex_;
  DelayedTaskQueue delayed_tasks_;
  size_t order_;
  std::atomic_bool terminated_;

  void RegisterTask(fxl::Closure task, fxl::TimePoint target_time);

  void RunExpiredTasks();

  FXL_DISALLOW_COPY_AND_ASSIGN(MessageLoopImpl);
};

}  // namespace fml

#endif  // FLUTTER_FML_MESSAGE_LOOP_IMPL_H_
