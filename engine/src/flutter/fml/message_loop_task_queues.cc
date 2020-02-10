// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/fml/message_loop_task_queues.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/message_loop_impl.h"

#include <iostream>

namespace fml {

std::mutex MessageLoopTaskQueues::creation_mutex_;

const size_t TaskQueueId::kUnmerged = ULONG_MAX;

fml::RefPtr<MessageLoopTaskQueues> MessageLoopTaskQueues::instance_;

TaskQueueEntry::TaskQueueEntry()
    : owner_of(_kUnmerged), subsumed_by(_kUnmerged) {
  wakeable = NULL;
  task_observers = TaskObservers();
  delayed_tasks = DelayedTaskQueue();
}

fml::RefPtr<MessageLoopTaskQueues> MessageLoopTaskQueues::GetInstance() {
  std::scoped_lock creation(creation_mutex_);
  if (!instance_) {
    instance_ = fml::MakeRefCounted<MessageLoopTaskQueues>();
  }
  return instance_;
}

TaskQueueId MessageLoopTaskQueues::CreateTaskQueue() {
  std::lock_guard guard(queue_mutex_);
  TaskQueueId loop_id = TaskQueueId(task_queue_id_counter_);
  ++task_queue_id_counter_;
  queue_entries_[loop_id] = std::make_unique<TaskQueueEntry>();
  return loop_id;
}

MessageLoopTaskQueues::MessageLoopTaskQueues()
    : task_queue_id_counter_(0), order_(0) {}

MessageLoopTaskQueues::~MessageLoopTaskQueues() = default;

void MessageLoopTaskQueues::Dispose(TaskQueueId queue_id) {
  std::lock_guard guard(queue_mutex_);
  const auto& queue_entry = queue_entries_.at(queue_id);
  FML_DCHECK(queue_entry->subsumed_by == _kUnmerged);
  TaskQueueId subsumed = queue_entry->owner_of;
  queue_entries_.erase(queue_id);
  if (subsumed != _kUnmerged) {
    queue_entries_.erase(subsumed);
  }
}

void MessageLoopTaskQueues::DisposeTasks(TaskQueueId queue_id) {
  std::lock_guard guard(queue_mutex_);
  const auto& queue_entry = queue_entries_.at(queue_id);
  FML_DCHECK(queue_entry->subsumed_by == _kUnmerged);
  TaskQueueId subsumed = queue_entry->owner_of;
  queue_entry->delayed_tasks = {};
  if (subsumed != _kUnmerged) {
    queue_entries_.at(subsumed)->delayed_tasks = {};
  }
}

void MessageLoopTaskQueues::RegisterTask(TaskQueueId queue_id,
                                         const fml::closure& task,
                                         fml::TimePoint target_time) {
  std::lock_guard guard(queue_mutex_);
  size_t order = order_++;
  const auto& queue_entry = queue_entries_.at(queue_id);
  queue_entry->delayed_tasks.push({order, task, target_time});
  TaskQueueId loop_to_wake = queue_id;
  if (queue_entry->subsumed_by != _kUnmerged) {
    loop_to_wake = queue_entry->subsumed_by;
  }
  WakeUpUnlocked(loop_to_wake,
                 queue_entry->delayed_tasks.top().GetTargetTime());
}

bool MessageLoopTaskQueues::HasPendingTasks(TaskQueueId queue_id) const {
  std::lock_guard guard(queue_mutex_);
  return HasPendingTasksUnlocked(queue_id);
}

void MessageLoopTaskQueues::GetTasksToRunNow(
    TaskQueueId queue_id,
    FlushType type,
    std::vector<fml::closure>& invocations) {
  std::lock_guard guard(queue_mutex_);
  if (!HasPendingTasksUnlocked(queue_id)) {
    return;
  }

  const auto now = fml::TimePoint::Now();

  while (HasPendingTasksUnlocked(queue_id)) {
    TaskQueueId top_queue = _kUnmerged;
    const auto& top = PeekNextTaskUnlocked(queue_id, top_queue);
    if (top.GetTargetTime() > now) {
      break;
    }
    invocations.emplace_back(top.GetTask());
    queue_entries_.at(top_queue)->delayed_tasks.pop();
    if (type == FlushType::kSingle) {
      break;
    }
  }

  if (!HasPendingTasksUnlocked(queue_id)) {
    WakeUpUnlocked(queue_id, fml::TimePoint::Max());
  } else {
    WakeUpUnlocked(queue_id, GetNextWakeTimeUnlocked(queue_id));
  }
}

void MessageLoopTaskQueues::WakeUpUnlocked(TaskQueueId queue_id,
                                           fml::TimePoint time) const {
  if (queue_entries_.at(queue_id)->wakeable) {
    queue_entries_.at(queue_id)->wakeable->WakeUp(time);
  }
}

size_t MessageLoopTaskQueues::GetNumPendingTasks(TaskQueueId queue_id) const {
  std::lock_guard guard(queue_mutex_);
  const auto& queue_entry = queue_entries_.at(queue_id);
  if (queue_entry->subsumed_by != _kUnmerged) {
    return 0;
  }

  size_t total_tasks = 0;
  total_tasks += queue_entry->delayed_tasks.size();

  TaskQueueId subsumed = queue_entry->owner_of;
  if (subsumed != _kUnmerged) {
    const auto& subsumed_entry = queue_entries_.at(subsumed);
    total_tasks += subsumed_entry->delayed_tasks.size();
  }
  return total_tasks;
}

void MessageLoopTaskQueues::AddTaskObserver(TaskQueueId queue_id,
                                            intptr_t key,
                                            const fml::closure& callback) {
  std::lock_guard guard(queue_mutex_);
  FML_DCHECK(callback != nullptr) << "Observer callback must be non-null.";
  queue_entries_.at(queue_id)->task_observers[key] = callback;
}

void MessageLoopTaskQueues::RemoveTaskObserver(TaskQueueId queue_id,
                                               intptr_t key) {
  std::lock_guard guard(queue_mutex_);
  queue_entries_.at(queue_id)->task_observers.erase(key);
}

std::vector<fml::closure> MessageLoopTaskQueues::GetObserversToNotify(
    TaskQueueId queue_id) const {
  std::lock_guard guard(queue_mutex_);
  std::vector<fml::closure> observers;

  if (queue_entries_.at(queue_id)->subsumed_by != _kUnmerged) {
    return observers;
  }

  for (const auto& observer : queue_entries_.at(queue_id)->task_observers) {
    observers.push_back(observer.second);
  }

  TaskQueueId subsumed = queue_entries_.at(queue_id)->owner_of;
  if (subsumed != _kUnmerged) {
    for (const auto& observer : queue_entries_.at(subsumed)->task_observers) {
      observers.push_back(observer.second);
    }
  }

  return observers;
}

void MessageLoopTaskQueues::SetWakeable(TaskQueueId queue_id,
                                        fml::Wakeable* wakeable) {
  std::lock_guard guard(queue_mutex_);
  FML_CHECK(!queue_entries_.at(queue_id)->wakeable)
      << "Wakeable can only be set once.";
  queue_entries_.at(queue_id)->wakeable = wakeable;
}

bool MessageLoopTaskQueues::Merge(TaskQueueId owner, TaskQueueId subsumed) {
  if (owner == subsumed) {
    return true;
  }
  std::lock_guard guard(queue_mutex_);
  auto& owner_entry = queue_entries_.at(owner);
  auto& subsumed_entry = queue_entries_.at(subsumed);

  if (owner_entry->owner_of == subsumed) {
    return true;
  }

  std::vector<TaskQueueId> owner_subsumed_keys = {
      owner_entry->owner_of, owner_entry->subsumed_by, subsumed_entry->owner_of,
      subsumed_entry->subsumed_by};

  for (auto key : owner_subsumed_keys) {
    if (key != _kUnmerged) {
      return false;
    }
  }

  owner_entry->owner_of = subsumed;
  subsumed_entry->subsumed_by = owner;

  if (HasPendingTasksUnlocked(owner)) {
    WakeUpUnlocked(owner, GetNextWakeTimeUnlocked(owner));
  }

  return true;
}

bool MessageLoopTaskQueues::Unmerge(TaskQueueId owner) {
  std::lock_guard guard(queue_mutex_);
  const auto& owner_entry = queue_entries_.at(owner);
  const TaskQueueId subsumed = owner_entry->owner_of;
  if (subsumed == _kUnmerged) {
    return false;
  }

  queue_entries_.at(subsumed)->subsumed_by = _kUnmerged;
  owner_entry->owner_of = _kUnmerged;

  if (HasPendingTasksUnlocked(owner)) {
    WakeUpUnlocked(owner, GetNextWakeTimeUnlocked(owner));
  }

  if (HasPendingTasksUnlocked(subsumed)) {
    WakeUpUnlocked(subsumed, GetNextWakeTimeUnlocked(subsumed));
  }

  return true;
}

bool MessageLoopTaskQueues::Owns(TaskQueueId owner,
                                 TaskQueueId subsumed) const {
  std::lock_guard guard(queue_mutex_);
  return subsumed == queue_entries_.at(owner)->owner_of || owner == subsumed;
}

// Subsumed queues will never have pending tasks.
// Owning queues will consider both their and their subsumed tasks.
bool MessageLoopTaskQueues::HasPendingTasksUnlocked(
    TaskQueueId queue_id) const {
  const auto& entry = queue_entries_.at(queue_id);
  bool is_subsumed = entry->subsumed_by != _kUnmerged;
  if (is_subsumed) {
    return false;
  }

  if (!entry->delayed_tasks.empty()) {
    return true;
  }

  const TaskQueueId subsumed = entry->owner_of;
  if (subsumed == _kUnmerged) {
    // this is not an owner and queue is empty.
    return false;
  } else {
    return !queue_entries_.at(subsumed)->delayed_tasks.empty();
  }
}

fml::TimePoint MessageLoopTaskQueues::GetNextWakeTimeUnlocked(
    TaskQueueId queue_id) const {
  TaskQueueId tmp = _kUnmerged;
  return PeekNextTaskUnlocked(queue_id, tmp).GetTargetTime();
}

const DelayedTask& MessageLoopTaskQueues::PeekNextTaskUnlocked(
    TaskQueueId owner,
    TaskQueueId& top_queue_id) const {
  FML_DCHECK(HasPendingTasksUnlocked(owner));
  const auto& entry = queue_entries_.at(owner);
  const TaskQueueId subsumed = entry->owner_of;
  if (subsumed == _kUnmerged) {
    top_queue_id = owner;
    return entry->delayed_tasks.top();
  }

  const auto& owner_tasks = entry->delayed_tasks;
  const auto& subsumed_tasks = queue_entries_.at(subsumed)->delayed_tasks;

  // we are owning another task queue
  const bool subsumed_has_task = !subsumed_tasks.empty();
  const bool owner_has_task = !owner_tasks.empty();
  if (owner_has_task && subsumed_has_task) {
    const auto owner_task = owner_tasks.top();
    const auto subsumed_task = subsumed_tasks.top();
    if (owner_task > subsumed_task) {
      top_queue_id = subsumed;
    } else {
      top_queue_id = owner;
    }
  } else if (owner_has_task) {
    top_queue_id = owner;
  } else {
    top_queue_id = subsumed;
  }
  return queue_entries_.at(top_queue_id)->delayed_tasks.top();
}

}  // namespace fml
