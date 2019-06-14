// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/fml/message_loop_task_queue.h"
#include "flutter/fml/message_loop_impl.h"

namespace fml {

MessageLoopTaskQueue::MessageLoopTaskQueue() : order_(0) {}

MessageLoopTaskQueue::~MessageLoopTaskQueue() = default;

void MessageLoopTaskQueue::Dispose() {
  std::lock_guard<std::mutex> lock(delayed_tasks_mutex_);
  delayed_tasks_ = {};
}

void MessageLoopTaskQueue::RegisterTask(fml::closure task,
                                        fml::TimePoint target_time) {
  std::lock_guard<std::mutex> lock(delayed_tasks_mutex_);
  delayed_tasks_.push({++order_, std::move(task), target_time});
  WakeUp(delayed_tasks_.top().GetTargetTime());
}

bool MessageLoopTaskQueue::HasPendingTasks() {
  std::lock_guard<std::mutex> lock(delayed_tasks_mutex_);
  return !delayed_tasks_.empty();
}

void MessageLoopTaskQueue::GetTasksToRunNow(
    FlushType type,
    std::vector<fml::closure>& invocations) {
  std::lock_guard<std::mutex> lock(delayed_tasks_mutex_);

  const auto now = fml::TimePoint::Now();
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

  if (delayed_tasks_.empty()) {
    WakeUp(fml::TimePoint::Max());
  } else {
    WakeUp(delayed_tasks_.top().GetTargetTime());
  }
}

void MessageLoopTaskQueue::WakeUp(fml::TimePoint time) {
  if (wakeable_) {
    wakeable_->WakeUp(time);
  }
}

size_t MessageLoopTaskQueue::GetNumPendingTasks() {
  std::lock_guard<std::mutex> lock(delayed_tasks_mutex_);
  return delayed_tasks_.size();
}

void MessageLoopTaskQueue::AddTaskObserver(intptr_t key,
                                           fml::closure callback) {
  std::lock_guard<std::mutex> observers_lock(observers_mutex_);
  task_observers_[key] = std::move(callback);
}

void MessageLoopTaskQueue::RemoveTaskObserver(intptr_t key) {
  std::lock_guard<std::mutex> observers_lock(observers_mutex_);
  task_observers_.erase(key);
}

void MessageLoopTaskQueue::NotifyObservers() {
  std::lock_guard<std::mutex> observers_lock(observers_mutex_);
  for (const auto& observer : task_observers_) {
    observer.second();
  }
}

// Thread safety analysis disabled as it does not account for defered locks.
void MessageLoopTaskQueue::Swap(MessageLoopTaskQueue& other)
    FML_NO_THREAD_SAFETY_ANALYSIS {
  // task_observers locks
  std::unique_lock<std::mutex> o1(observers_mutex_, std::defer_lock);
  std::unique_lock<std::mutex> o2(other.observers_mutex_, std::defer_lock);

  // delayed_tasks locks
  std::unique_lock<std::mutex> d1(delayed_tasks_mutex_, std::defer_lock);
  std::unique_lock<std::mutex> d2(other.delayed_tasks_mutex_, std::defer_lock);

  std::lock(o1, o2, d1, d2);

  std::swap(task_observers_, other.task_observers_);
  std::swap(delayed_tasks_, other.delayed_tasks_);
}

void MessageLoopTaskQueue::SetWakeable(fml::Wakeable* wakeable) {
  wakeable_ = wakeable;
}

}  // namespace fml
