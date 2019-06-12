// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/fml/message_loop_impl.h"

#include <algorithm>
#include <vector>

#include "flutter/fml/build_config.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

#if OS_MACOSX
#include "flutter/fml/platform/darwin/message_loop_darwin.h"
#elif OS_ANDROID
#include "flutter/fml/platform/android/message_loop_android.h"
#elif OS_LINUX
#include "flutter/fml/platform/linux/message_loop_linux.h"
#elif OS_WIN
#include "flutter/fml/platform/win/message_loop_win.h"
#endif

namespace fml {

fml::RefPtr<MessageLoopImpl> MessageLoopImpl::Create() {
#if OS_MACOSX
  return fml::MakeRefCounted<MessageLoopDarwin>();
#elif OS_ANDROID
  return fml::MakeRefCounted<MessageLoopAndroid>();
#elif OS_LINUX
  return fml::MakeRefCounted<MessageLoopLinux>();
#elif OS_WIN
  return fml::MakeRefCounted<MessageLoopWin>();
#else
  return nullptr;
#endif
}

MessageLoopImpl::MessageLoopImpl() : order_(0), terminated_(false) {}

MessageLoopImpl::~MessageLoopImpl() = default;

void MessageLoopImpl::PostTask(fml::closure task, fml::TimePoint target_time) {
  FML_DCHECK(task != nullptr);
  RegisterTask(task, target_time);
}

void MessageLoopImpl::AddTaskObserver(intptr_t key, fml::closure callback) {
  FML_DCHECK(callback != nullptr);
  FML_DCHECK(MessageLoop::GetCurrent().GetLoopImpl().get() == this)
      << "Message loop task observer must be added on the same thread as the "
         "loop.";
  std::lock_guard<std::mutex> observers_lock(observers_mutex_);
  task_observers_[key] = std::move(callback);
}

void MessageLoopImpl::RemoveTaskObserver(intptr_t key) {
  FML_DCHECK(MessageLoop::GetCurrent().GetLoopImpl().get() == this)
      << "Message loop task observer must be removed from the same thread as "
         "the loop.";
  std::lock_guard<std::mutex> observers_lock(observers_mutex_);
  task_observers_.erase(key);
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

// Thread safety analysis disabled as it does not account for defered locks.
void MessageLoopImpl::SwapTaskQueues(const fml::RefPtr<MessageLoopImpl>& other)
    FML_NO_THREAD_SAFETY_ANALYSIS {
  if (terminated_ || other->terminated_) {
    return;
  }

  // task_flushing locks
  std::unique_lock<std::mutex> t1(tasks_flushing_mutex_, std::defer_lock);
  std::unique_lock<std::mutex> t2(other->tasks_flushing_mutex_,
                                  std::defer_lock);

  // task_observers locks
  std::unique_lock<std::mutex> o1(observers_mutex_, std::defer_lock);
  std::unique_lock<std::mutex> o2(other->observers_mutex_, std::defer_lock);

  // delayed_tasks locks
  std::unique_lock<std::mutex> d1(delayed_tasks_mutex_, std::defer_lock);
  std::unique_lock<std::mutex> d2(other->delayed_tasks_mutex_, std::defer_lock);

  std::lock(t1, t2, o1, o2, d1, d2);

  std::swap(task_observers_, other->task_observers_);
  std::swap(delayed_tasks_, other->delayed_tasks_);
}

void MessageLoopImpl::RegisterTask(fml::closure task,
                                   fml::TimePoint target_time) {
  FML_DCHECK(task != nullptr);
  if (terminated_) {
    // If the message loop has already been terminated, PostTask should destruct
    // |task| synchronously within this function.
    return;
  }
  std::lock_guard<std::mutex> lock(delayed_tasks_mutex_);
  delayed_tasks_.push({++order_, std::move(task), target_time});
  WakeUp(delayed_tasks_.top().GetTargetTime());
}

void MessageLoopImpl::FlushTasks(FlushType type) {
  TRACE_EVENT0("fml", "MessageLoop::FlushTasks");
  std::vector<fml::closure> invocations;

  // We are grabbing this lock here as a proxy to indicate
  // that we are running tasks and will invoke the
  // "right" observers, we are trying to avoid the scenario
  // where:
  // gather invocations -> Swap -> execute invocations
  // will lead us to run invocations on the wrong thread.
  std::lock_guard<std::mutex> task_flush_lock(tasks_flushing_mutex_);

  {
    std::lock_guard<std::mutex> lock(delayed_tasks_mutex_);

    if (delayed_tasks_.empty()) {
      return;
    }

    auto now = fml::TimePoint::Now();
    while (!delayed_tasks_.empty()) {
      const auto& top = delayed_tasks_.top();
      if (top.GetTargetTime() > now) {
        break;
      }
      invocations.emplace_back(std::move(top.GetTask()));
      delayed_tasks_.pop();
      if (type == FlushType::kSingle) {
        break;
      }
    }

    WakeUp(delayed_tasks_.empty() ? fml::TimePoint::Max()
                                  : delayed_tasks_.top().GetTargetTime());
  }

  for (const auto& invocation : invocations) {
    invocation();
    std::lock_guard<std::mutex> observers_lock(observers_mutex_);
    for (const auto& observer : task_observers_) {
      observer.second();
    }
  }
}

void MessageLoopImpl::RunExpiredTasksNow() {
  FlushTasks(FlushType::kAll);
}

void MessageLoopImpl::RunSingleExpiredTaskNow() {
  FlushTasks(FlushType::kSingle);
}

}  // namespace fml
