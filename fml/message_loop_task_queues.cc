// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/fml/message_loop_task_queues.h"
#include "flutter/fml/message_loop_impl.h"

namespace fml {

std::mutex MessageLoopTaskQueues::creation_mutex_;
fml::RefPtr<MessageLoopTaskQueues> MessageLoopTaskQueues::instance_;

fml::RefPtr<MessageLoopTaskQueues> MessageLoopTaskQueues::GetInstance() {
  std::scoped_lock creation(creation_mutex_);
  if (!instance_) {
    instance_ = fml::MakeRefCounted<MessageLoopTaskQueues>();
  }
  return instance_;
}

TaskQueueId MessageLoopTaskQueues::CreateTaskQueue() {
  std::scoped_lock creation(queue_meta_mutex_);
  TaskQueueId loop_id = task_queue_id_counter_;
  ++task_queue_id_counter_;

  observers_mutexes_.push_back(std::make_unique<std::mutex>());
  delayed_tasks_mutexes_.push_back(std::make_unique<std::mutex>());
  wakeable_mutexes_.push_back(std::make_unique<std::mutex>());

  task_observers_.push_back(TaskObservers());
  delayed_tasks_.push_back(DelayedTaskQueue());
  wakeables_.push_back(NULL);

  return loop_id;
}

MessageLoopTaskQueues::MessageLoopTaskQueues()
    : task_queue_id_counter_(0), order_(0) {}

MessageLoopTaskQueues::~MessageLoopTaskQueues() = default;

void MessageLoopTaskQueues::Dispose(TaskQueueId queue_id) {
  std::scoped_lock lock(GetMutex(queue_id, MutexType::kTasks));
  delayed_tasks_[queue_id] = {};
}

void MessageLoopTaskQueues::RegisterTask(TaskQueueId queue_id,
                                         fml::closure task,
                                         fml::TimePoint target_time) {
  std::scoped_lock lock(GetMutex(queue_id, MutexType::kTasks));
  size_t order = order_++;
  delayed_tasks_[queue_id].push({order, std::move(task), target_time});
  WakeUp(queue_id, delayed_tasks_[queue_id].top().GetTargetTime());
}

bool MessageLoopTaskQueues::HasPendingTasks(TaskQueueId queue_id) {
  std::scoped_lock lock(GetMutex(queue_id, MutexType::kTasks));
  return !delayed_tasks_[queue_id].empty();
}

void MessageLoopTaskQueues::GetTasksToRunNow(
    TaskQueueId queue_id,
    FlushType type,
    std::vector<fml::closure>& invocations) {
  std::scoped_lock lock(GetMutex(queue_id, MutexType::kTasks));

  const auto now = fml::TimePoint::Now();
  DelayedTaskQueue& tasks = delayed_tasks_[queue_id];

  while (!tasks.empty()) {
    const auto& top = tasks.top();
    if (top.GetTargetTime() > now) {
      break;
    }
    invocations.emplace_back(std::move(top.GetTask()));
    tasks.pop();
    if (type == FlushType::kSingle) {
      break;
    }
  }

  if (tasks.empty()) {
    WakeUp(queue_id, fml::TimePoint::Max());
  } else {
    WakeUp(queue_id, tasks.top().GetTargetTime());
  }
}

void MessageLoopTaskQueues::WakeUp(TaskQueueId queue_id, fml::TimePoint time) {
  std::scoped_lock lock(GetMutex(queue_id, MutexType::kWakeables));
  if (wakeables_[queue_id]) {
    wakeables_[queue_id]->WakeUp(time);
  }
}

size_t MessageLoopTaskQueues::GetNumPendingTasks(TaskQueueId queue_id) {
  std::scoped_lock lock(GetMutex(queue_id, MutexType::kTasks));
  return delayed_tasks_[queue_id].size();
}

void MessageLoopTaskQueues::AddTaskObserver(TaskQueueId queue_id,
                                            intptr_t key,
                                            fml::closure callback) {
  std::scoped_lock lock(GetMutex(queue_id, MutexType::kObservers));
  task_observers_[queue_id][key] = std::move(callback);
}

void MessageLoopTaskQueues::RemoveTaskObserver(TaskQueueId queue_id,
                                               intptr_t key) {
  std::scoped_lock lock(GetMutex(queue_id, MutexType::kObservers));
  task_observers_[queue_id].erase(key);
}

void MessageLoopTaskQueues::NotifyObservers(TaskQueueId queue_id) {
  std::scoped_lock lock(GetMutex(queue_id, MutexType::kObservers));
  for (const auto& observer : task_observers_[queue_id]) {
    observer.second();
  }
}

// Thread safety analysis disabled as it does not account for defered locks.
void MessageLoopTaskQueues::Swap(TaskQueueId primary, TaskQueueId secondary)
    FML_NO_THREAD_SAFETY_ANALYSIS {
  // task_observers locks
  std::mutex& o1 = GetMutex(primary, MutexType::kObservers);
  std::mutex& o2 = GetMutex(secondary, MutexType::kObservers);

  // delayed_tasks locks
  std::mutex& t1 = GetMutex(primary, MutexType::kTasks);
  std::mutex& t2 = GetMutex(secondary, MutexType::kTasks);

  std::scoped_lock(o1, o2, t1, t2);

  std::swap(task_observers_[primary], task_observers_[secondary]);
  std::swap(delayed_tasks_[primary], delayed_tasks_[secondary]);
}

void MessageLoopTaskQueues::SetWakeable(TaskQueueId queue_id,
                                        fml::Wakeable* wakeable) {
  std::scoped_lock lock(GetMutex(queue_id, MutexType::kWakeables));
  wakeables_[queue_id] = wakeable;
}

std::mutex& MessageLoopTaskQueues::GetMutex(TaskQueueId queue_id,
                                            MutexType type) {
  std::scoped_lock lock(queue_meta_mutex_);
  if (type == MutexType::kTasks) {
    return *delayed_tasks_mutexes_[queue_id];
  } else if (type == MutexType::kObservers) {
    return *observers_mutexes_[queue_id];
  } else {
    return *wakeable_mutexes_[queue_id];
  }
}

}  // namespace fml
