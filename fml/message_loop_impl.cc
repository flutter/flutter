// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/message_loop_impl.h"

#include <algorithm>
#include <vector>

#include "flutter/fml/trace_event.h"
#include "lib/fxl/build_config.h"

#if OS_MACOSX

#include "flutter/fml/platform/darwin/message_loop_darwin.h"
using PlatformMessageLoopImpl = fml::MessageLoopDarwin;

#elif OS_ANDROID

#include "flutter/fml/platform/android/message_loop_android.h"
using PlatformMessageLoopImpl = fml::MessageLoopAndroid;

#elif OS_LINUX

#include "flutter/fml/platform/linux/message_loop_linux.h"
using PlatformMessageLoopImpl = fml::MessageLoopLinux;

#elif OS_WIN

#include "flutter/fml/platform/win/message_loop_win.h"
using PlatformMessageLoopImpl = fml::MessageLoopWin;

#else

#error This platform does not have a message loop implementation.

#endif

namespace fml {

fxl::RefPtr<MessageLoopImpl> MessageLoopImpl::Create() {
  return fxl::MakeRefCounted<::PlatformMessageLoopImpl>();
}

MessageLoopImpl::MessageLoopImpl() : order_(0), terminated_(false) {}

MessageLoopImpl::~MessageLoopImpl() = default;

void MessageLoopImpl::PostTask(fxl::Closure task, fxl::TimePoint target_time) {
  FXL_DCHECK(task != nullptr);
  RegisterTask(task, target_time);
}

void MessageLoopImpl::RunExpiredTasksNow() {
  RunExpiredTasks();
}

void MessageLoopImpl::AddTaskObserver(TaskObserver* observer) {
  FXL_DCHECK(observer != nullptr);
  FXL_DCHECK(MessageLoop::GetCurrent().GetLoopImpl().get() == this)
      << "Message loop task observer must be added on the same thread as the "
         "loop.";
  task_observers_.insert(observer);
}

void MessageLoopImpl::RemoveTaskObserver(TaskObserver* observer) {
  FXL_DCHECK(observer != nullptr);
  FXL_DCHECK(MessageLoop::GetCurrent().GetLoopImpl().get() == this)
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

  // The loop may have been implicitly terminated. This can happen if the
  // implementation supports termination via platform specific APIs or just
  // error conditions. Set the terminated flag manually.
  terminated_ = true;

  // The message loop is shutting down. Check if there are expired tasks. This
  // is the last chance for expired tasks to be serviced. Make sure the
  // terminated flag is already set so we don't accrue additional tasks now.
  RunExpiredTasksNow();

  // When the message loop is in the process of shutting down, pending tasks
  // should be destructed on the message loop's thread. We have just returned
  // from the implementations |Run| method which we know is on the correct
  // thread. Drop all pending tasks on the floor.
  std::lock_guard<std::mutex> lock(delayed_tasks_mutex_);
  delayed_tasks_ = {};
}

void MessageLoopImpl::DoTerminate() {
  terminated_ = true;
  Terminate();
}

void MessageLoopImpl::RegisterTask(fxl::Closure task,
                                   fxl::TimePoint target_time) {
  FXL_DCHECK(task != nullptr);
  if (terminated_) {
    // If the message loop has already been terminated, PostTask should destruct
    // |task| synchronously within this function.
    return;
  }
  std::lock_guard<std::mutex> lock(delayed_tasks_mutex_);
  delayed_tasks_.push({++order_, std::move(task), target_time});
  WakeUp(delayed_tasks_.top().target_time);
}

void MessageLoopImpl::RunExpiredTasks() {
  TRACE_EVENT0("fml", "MessageLoop::RunExpiredTasks");
  std::vector<fxl::Closure> invocations;

  {
    std::lock_guard<std::mutex> lock(delayed_tasks_mutex_);

    if (delayed_tasks_.empty()) {
      return;
    }

    auto now = fxl::TimePoint::Now();
    while (!delayed_tasks_.empty()) {
      const auto& top = delayed_tasks_.top();
      if (top.target_time > now) {
        break;
      }
      invocations.emplace_back(std::move(top.task));
      delayed_tasks_.pop();
    }

    WakeUp(delayed_tasks_.empty() ? fxl::TimePoint::Max()
                                  : delayed_tasks_.top().target_time);
  }

  for (const auto& invocation : invocations) {
    invocation();
    for (const auto& observer : task_observers_) {
      observer->DidProcessTask();
    }
  }
}

}  // namespace fml
