// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/fml/message_loop_task_queues.h"
#include "flutter/fml/merged_queues_runner.cc"
#include "flutter/fml/message_loop_impl.h"

namespace fml {

std::mutex MessageLoopTaskQueues::creation_mutex_;
const size_t TaskQueueId::kUnmerged = ULONG_MAX;
const TaskQueueId MessageLoopTaskQueues::_kUnmerged =
    TaskQueueId(TaskQueueId::kUnmerged);
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
  TaskQueueId loop_id = TaskQueueId(task_queue_id_counter_);
  ++task_queue_id_counter_;

  observers_mutexes_.push_back(std::make_unique<std::mutex>());
  delayed_tasks_mutexes_.push_back(std::make_unique<std::mutex>());
  wakeable_mutexes_.push_back(std::make_unique<std::mutex>());

  task_observers_.push_back(TaskObservers());
  delayed_tasks_.push_back(DelayedTaskQueue());
  wakeables_.push_back(NULL);

  owner_to_subsumed_.push_back(_kUnmerged);
  subsumed_to_owner_.push_back(_kUnmerged);

  return loop_id;
}

MessageLoopTaskQueues::MessageLoopTaskQueues()
    : task_queue_id_counter_(0), order_(0) {}

MessageLoopTaskQueues::~MessageLoopTaskQueues() = default;

void MessageLoopTaskQueues::Dispose(TaskQueueId queue_id) {
  MergedQueuesRunner merged_tasks = MergedQueuesRunner(*this, queue_id);
  merged_tasks.InvokeMerged(
      [&](TaskQueueId queue_id) { delayed_tasks_[queue_id] = {}; });
}

void MessageLoopTaskQueues::RegisterTask(TaskQueueId queue_id,
                                         fml::closure task,
                                         fml::TimePoint target_time) {
  std::scoped_lock lock(GetMutex(queue_id, MutexType::kTasks));
  size_t order = order_++;
  delayed_tasks_[queue_id].push({order, std::move(task), target_time});
  TaskQueueId loop_to_wake = queue_id;
  if (subsumed_to_owner_[queue_id] != _kUnmerged) {
    loop_to_wake = subsumed_to_owner_[queue_id];
  }
  WakeUp(loop_to_wake, delayed_tasks_[queue_id].top().GetTargetTime());
}

bool MessageLoopTaskQueues::HasPendingTasks(TaskQueueId queue_id) {
  MergedQueuesRunner merged_tasks = MergedQueuesRunner(*this, queue_id);
  return HasPendingTasksUnlocked(queue_id);
}

void MessageLoopTaskQueues::GetTasksToRunNow(
    TaskQueueId queue_id,
    FlushType type,
    std::vector<fml::closure>& invocations) {
  MergedQueuesRunner merged_tasks = MergedQueuesRunner(*this, queue_id);

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
    invocations.emplace_back(std::move(top.GetTask()));
    delayed_tasks_[top_queue].pop();
    if (type == FlushType::kSingle) {
      break;
    }
  }

  if (!HasPendingTasksUnlocked(queue_id)) {
    WakeUp(queue_id, fml::TimePoint::Max());
  } else {
    WakeUp(queue_id, GetNextWakeTimeUnlocked(queue_id));
  }
}

void MessageLoopTaskQueues::WakeUp(TaskQueueId queue_id, fml::TimePoint time) {
  std::scoped_lock lock(GetMutex(queue_id, MutexType::kWakeables));
  if (wakeables_[queue_id]) {
    wakeables_[queue_id]->WakeUp(time);
  }
}

size_t MessageLoopTaskQueues::GetNumPendingTasks(TaskQueueId queue_id) {
  MergedQueuesRunner merged_tasks = MergedQueuesRunner(*this, queue_id);
  if (subsumed_to_owner_[queue_id] != _kUnmerged) {
    return 0;
  }
  size_t total_tasks = 0;
  merged_tasks.InvokeMerged(
      [&](TaskQueueId queue) { total_tasks += delayed_tasks_[queue].size(); });
  return total_tasks;
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
  MergedQueuesRunner merged_observers =
      MergedQueuesRunner(*this, queue_id, MutexType::kObservers);

  merged_observers.InvokeMerged([&](TaskQueueId queue) {
    for (const auto& observer : task_observers_[queue]) {
      observer.second();
    }
  });
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

  std::scoped_lock lock(o1, o2, t1, t2);

  std::swap(task_observers_[primary], task_observers_[secondary]);
  std::swap(delayed_tasks_[primary], delayed_tasks_[secondary]);
}

void MessageLoopTaskQueues::SetWakeable(TaskQueueId queue_id,
                                        fml::Wakeable* wakeable) {
  std::scoped_lock lock(GetMutex(queue_id, MutexType::kWakeables));
  FML_CHECK(!wakeables_[queue_id]) << "Wakeable can only be set once.";
  wakeables_[queue_id] = wakeable;
}

bool MessageLoopTaskQueues::Merge(TaskQueueId owner, TaskQueueId subsumed) {
  // task_observers locks
  std::mutex& o1 = GetMutex(owner, MutexType::kObservers);
  std::mutex& o2 = GetMutex(subsumed, MutexType::kObservers);

  // delayed_tasks locks
  std::mutex& t1 = GetMutex(owner, MutexType::kTasks);
  std::mutex& t2 = GetMutex(subsumed, MutexType::kTasks);

  std::scoped_lock lock(o1, o2, t1, t2);

  if (owner == subsumed) {
    return true;
  }

  if (owner_to_subsumed_[owner] == subsumed) {
    return true;
  }

  std::vector<TaskQueueId> owner_subsumed_keys = {
      owner_to_subsumed_[owner], owner_to_subsumed_[subsumed],
      subsumed_to_owner_[owner], subsumed_to_owner_[subsumed]};

  for (auto key : owner_subsumed_keys) {
    if (key != _kUnmerged) {
      return false;
    }
  }

  owner_to_subsumed_[owner] = subsumed;
  subsumed_to_owner_[subsumed] = owner;

  if (HasPendingTasksUnlocked(owner)) {
    WakeUp(owner, GetNextWakeTimeUnlocked(owner));
  }

  return true;
}

bool MessageLoopTaskQueues::Unmerge(TaskQueueId owner) {
  MergedQueuesRunner merged_observers =
      MergedQueuesRunner(*this, owner, MutexType::kObservers);
  MergedQueuesRunner merged_tasks =
      MergedQueuesRunner(*this, owner, MutexType::kTasks);

  const TaskQueueId subsumed = owner_to_subsumed_[owner];
  if (subsumed == _kUnmerged) {
    return false;
  }

  subsumed_to_owner_[subsumed] = _kUnmerged;
  owner_to_subsumed_[owner] = _kUnmerged;

  if (HasPendingTasksUnlocked(owner)) {
    WakeUp(owner, GetNextWakeTimeUnlocked(owner));
  }

  if (HasPendingTasksUnlocked(subsumed)) {
    WakeUp(subsumed, GetNextWakeTimeUnlocked(subsumed));
  }

  return true;
}

bool MessageLoopTaskQueues::Owns(TaskQueueId owner, TaskQueueId subsumed) {
  MergedQueuesRunner merged_observers = MergedQueuesRunner(*this, owner);
  return subsumed == owner_to_subsumed_[owner] || owner == subsumed;
}

// Subsumed queues will never have pending tasks.
// Owning queues will consider both their and their subsumed tasks.
bool MessageLoopTaskQueues::HasPendingTasksUnlocked(TaskQueueId queue_id) {
  if (subsumed_to_owner_[queue_id] != _kUnmerged) {
    return false;
  }

  if (!delayed_tasks_[queue_id].empty()) {
    return true;
  }

  const TaskQueueId subsumed = owner_to_subsumed_[queue_id];
  if (subsumed == _kUnmerged) {
    // this is not an owner and queue is empty.
    return false;
  } else {
    return !delayed_tasks_[subsumed].empty();
  }
}

fml::TimePoint MessageLoopTaskQueues::GetNextWakeTimeUnlocked(
    TaskQueueId queue_id) {
  TaskQueueId tmp = _kUnmerged;
  return PeekNextTaskUnlocked(queue_id, tmp).GetTargetTime();
}

const DelayedTask& MessageLoopTaskQueues::PeekNextTaskUnlocked(
    TaskQueueId owner,
    TaskQueueId& top_queue_id) {
  FML_DCHECK(HasPendingTasksUnlocked(owner));
  const TaskQueueId subsumed = owner_to_subsumed_[owner];
  if (subsumed == _kUnmerged) {
    top_queue_id = owner;
    return delayed_tasks_[owner].top();
  }
  // we are owning another task queue
  const bool subsumed_has_task = !delayed_tasks_[subsumed].empty();
  const bool owner_has_task = !delayed_tasks_[owner].empty();
  if (owner_has_task && subsumed_has_task) {
    const auto owner_task = delayed_tasks_[owner].top();
    const auto subsumed_task = delayed_tasks_[subsumed].top();
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
  return delayed_tasks_[top_queue_id].top();
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
