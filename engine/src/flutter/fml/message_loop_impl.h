// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_MESSAGE_LOOP_IMPL_H_
#define FLUTTER_FML_MESSAGE_LOOP_IMPL_H_

#include <atomic>
#include <deque>
#include <queue>
#include <utility>

#include "flutter/fml/message_loop.h"
#include "lib/ftl/functional/closure.h"
#include "lib/ftl/macros.h"
#include "lib/ftl/memory/ref_counted.h"
#include "lib/ftl/synchronization/mutex.h"
#include "lib/ftl/synchronization/thread_annotations.h"
#include "lib/ftl/time/time_point.h"

namespace fml {

class MessageLoopImpl : public ftl::RefCountedThreadSafe<MessageLoopImpl> {
 public:
  static ftl::RefPtr<MessageLoopImpl> Create();

  virtual ~MessageLoopImpl();

  virtual void Run() = 0;

  virtual void Terminate() = 0;

  virtual void WakeUp(ftl::TimePoint time_point) = 0;

  void PostTask(ftl::Closure task, ftl::TimePoint target_time);

  void SetTaskObserver(MessageLoop::TaskObserver observer);

  void DoRun();

  void DoTerminate();

 protected:
  MessageLoopImpl();

  void RunExpiredTasksNow();

 private:
  struct DelayedTask {
    size_t order;
    ftl::Closure task;
    ftl::TimePoint target_time;

    DelayedTask(size_t p_order,
                ftl::Closure p_task,
                ftl::TimePoint p_target_time)
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

  MessageLoop::TaskObserver task_observer_;
  ftl::Mutex delayed_tasks_mutex_;
  DelayedTaskQueue delayed_tasks_ FTL_GUARDED_BY(delayed_tasks_mutex_);
  size_t order_ FTL_GUARDED_BY(delayed_tasks_mutex_);
  std::atomic_bool terminated_;

  FTL_WARN_UNUSED_RESULT
  ftl::TimePoint RegisterTaskAndGetNextWake(ftl::Closure task,
                                            ftl::TimePoint target_time);

  FTL_WARN_UNUSED_RESULT
  ftl::TimePoint RunExpiredTasksAndGetNextWake();

  FTL_DISALLOW_COPY_AND_ASSIGN(MessageLoopImpl);
};

}  // namespace fml

#endif  // FLUTTER_FML_MESSAGE_LOOP_IMPL_H_
