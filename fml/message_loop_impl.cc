// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/message_loop_impl.h"

#include <algorithm>
#include <vector>

#include "flutter/fml/trace_event.h"
#include "lib/ftl/build_config.h"

#if OS_MACOSX

#include "flutter/fml/platform/darwin/message_loop_darwin.h"
using PlatformMessageLoopImpl = fml::MessageLoopDarwin;

#elif OS_ANDROID

#include "flutter/fml/platform/android/message_loop_android.h"
using PlatformMessageLoopImpl = fml::MessageLoopAndroid;

#elif OS_LINUX

#include "flutter/fml/platform/linux/message_loop_linux.h"
using PlatformMessageLoopImpl = fml::MessageLoopLinux;

#else

#error This platform does not have a message loop implementation.

#endif

namespace fml {

ftl::RefPtr<MessageLoopImpl> MessageLoopImpl::Create() {
  return ftl::MakeRefCounted<::PlatformMessageLoopImpl>();
}

MessageLoopImpl::MessageLoopImpl() : order_(0), terminated_(false) {}

MessageLoopImpl::~MessageLoopImpl() = default;

void MessageLoopImpl::PostTask(ftl::Closure task, ftl::TimePoint target_time) {
  FTL_DCHECK(task != nullptr);
  WakeUp(RegisterTaskAndGetNextWake(task, target_time));
}

void MessageLoopImpl::RunExpiredTasksNow() {
  WakeUp(RunExpiredTasksAndGetNextWake());
}

void MessageLoopImpl::AddTaskObserver(TaskObserver* observer) {
  FTL_DCHECK(observer != nullptr);
  FTL_DCHECK(MessageLoop::GetCurrent().GetLoopImpl().get() == this)
      << "Message loop task observer must be added on the same thread as the "
         "loop.";
  task_observers_.insert(observer);
}

void MessageLoopImpl::RemoveTaskObserver(TaskObserver* observer) {
  FTL_DCHECK(observer != nullptr);
  FTL_DCHECK(MessageLoop::GetCurrent().GetLoopImpl().get() == this)
      << "Message loop task observer must be removed from the same thread as "
         "the loop.";
  task_observers_.erase(observer);
}

void MessageLoopImpl::DoRun() {
  if (terminated_) {
    // Message loops may be run only once.
    return;
  }

  // Allow the implementation to do its thing.
  Run();

  // The message loop is shutting down. Check if there are expired tasks. This
  // is the last chance for expired tasks to be serviced.
  RunExpiredTasksNow();

  // The loop may have been implicitly terminated. This can happen if the
  // implementation supports termination via platform specific APIs or just
  // error conditions. Set the terminated flag manually.
  terminated_ = true;

  // When the message loop is in the process of shutting down, pending tasks
  // should be destructed on the message loop's thread. We have just returned
  // from the implementations |Run| method which we know is on the correct
  // thread. Drop all pending tasks on the floor.
  ftl::MutexLocker lock(&delayed_tasks_mutex_);
  delayed_tasks_ = {};
}

void MessageLoopImpl::DoTerminate() {
  terminated_ = true;
  Terminate();
}

ftl::TimePoint MessageLoopImpl::RegisterTaskAndGetNextWake(
    ftl::Closure task,
    ftl::TimePoint target_time) {
  if (terminated_) {
    // If the message loop has already been terminated, PostTask should destruct
    // |task| synchronously within this function.
    return ftl::TimePoint::Max();
  }
  FTL_DCHECK(task != nullptr);
  ftl::MutexLocker lock(&delayed_tasks_mutex_);
  delayed_tasks_.push({++order_, std::move(task), target_time});
  return delayed_tasks_.top().target_time;
}

ftl::TimePoint MessageLoopImpl::RunExpiredTasksAndGetNextWake() {
  TRACE_EVENT0("fml", "MessageLoop::RunExpiredTasks");
  std::vector<ftl::Closure> invocations;

  {
    ftl::MutexLocker lock(&delayed_tasks_mutex_);

    if (delayed_tasks_.empty()) {
      return ftl::TimePoint::Max();
    }

    auto now = ftl::TimePoint::Now();
    while (!delayed_tasks_.empty()) {
      const auto& top = delayed_tasks_.top();
      if (top.target_time > now) {
        break;
      }
      invocations.emplace_back(std::move(top.task));
      delayed_tasks_.pop();
    }
  }

  for (const auto& invocation : invocations) {
    invocation();
    for (const auto& observer : task_observers_) {
      observer->DidProcessTask();
    }
  }

  ftl::MutexLocker lock(&delayed_tasks_mutex_);
  return delayed_tasks_.empty() ? ftl::TimePoint::Max()
                                : delayed_tasks_.top().target_time;
}

}  // namespace fml
