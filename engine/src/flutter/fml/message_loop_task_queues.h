// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_MESSAGE_LOOP_TASK_QUEUES_H_
#define FLUTTER_FML_MESSAGE_LOOP_TASK_QUEUES_H_

#include <map>
#include <mutex>
#include <vector>

#include "flutter/fml/closure.h"
#include "flutter/fml/delayed_task.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_counted.h"
#include "flutter/fml/synchronization/shared_mutex.h"
#include "flutter/fml/wakeable.h"

namespace fml {

class TaskQueueId {
 public:
  static const size_t kUnmerged;

  explicit TaskQueueId(size_t value) : value_(value) {}

  operator int() const { return value_; }

 private:
  size_t value_ = kUnmerged;
};

static const TaskQueueId _kUnmerged = TaskQueueId(TaskQueueId::kUnmerged);

// This is keyed by the |TaskQueueId| and contains all the queue
// components that make up a single TaskQueue.
class TaskQueueEntry {
 public:
  using TaskObservers = std::map<intptr_t, fml::closure>;
  Wakeable* wakeable;
  TaskObservers task_observers;
  DelayedTaskQueue delayed_tasks;

  // Note: Both of these can be _kUnmerged, which indicates that
  // this queue has not been merged or subsumed. OR exactly one
  // of these will be _kUnmerged, if owner_of is _kUnmerged, it means
  // that the queue has been subsumed or else it owns another queue.
  TaskQueueId owner_of;
  TaskQueueId subsumed_by;

  TaskQueueEntry();

 private:
  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(TaskQueueEntry);
};

enum class FlushType {
  kSingle,
  kAll,
};

// This class keeps track of all the tasks and observers that
// need to be run on it's MessageLoopImpl. This also wakes up the
// loop at the required times.
class MessageLoopTaskQueues
    : public fml::RefCountedThreadSafe<MessageLoopTaskQueues> {
 public:
  // Lifecycle.

  static fml::RefPtr<MessageLoopTaskQueues> GetInstance();

  TaskQueueId CreateTaskQueue();

  void Dispose(TaskQueueId queue_id);

  void DisposeTasks(TaskQueueId queue_id);

  // Tasks methods.

  void RegisterTask(TaskQueueId queue_id,
                    const fml::closure& task,
                    fml::TimePoint target_time);

  bool HasPendingTasks(TaskQueueId queue_id) const;

  fml::closure GetNextTaskToRun(TaskQueueId queue_id, fml::TimePoint from_time);

  size_t GetNumPendingTasks(TaskQueueId queue_id) const;

  // Observers methods.

  void AddTaskObserver(TaskQueueId queue_id,
                       intptr_t key,
                       const fml::closure& callback);

  void RemoveTaskObserver(TaskQueueId queue_id, intptr_t key);

  std::vector<fml::closure> GetObserversToNotify(TaskQueueId queue_id) const;

  // Misc.

  void SetWakeable(TaskQueueId queue_id, fml::Wakeable* wakeable);

  // Invariants for merge and un-merge
  //  1. RegisterTask will always submit to the queue_id that is passed
  //     to it. It is not aware of whether a queue is merged or not. Same with
  //     task observers.
  //  2. When we get the tasks to run now, we look at both the queue_ids
  //     for the owner, subsumed will spin.
  //  3. Each task queue can only be merged and subsumed once.
  //
  //  Methods currently aware of the merged state of the queues:
  //  HasPendingTasks, GetNextTaskToRun, GetNumPendingTasks

  // This method returns false if either the owner or subsumed has already been
  // merged with something else.
  bool Merge(TaskQueueId owner, TaskQueueId subsumed);

  // Will return false if the owner has not been merged before.
  bool Unmerge(TaskQueueId owner);

  // Returns true if owner owns the subsumed task queue.
  bool Owns(TaskQueueId owner, TaskQueueId subsumed) const;

 private:
  class MergedQueuesRunner;

  MessageLoopTaskQueues();

  ~MessageLoopTaskQueues();

  void WakeUpUnlocked(TaskQueueId queue_id, fml::TimePoint time) const;

  bool HasPendingTasksUnlocked(TaskQueueId queue_id) const;

  const DelayedTask& PeekNextTaskUnlocked(TaskQueueId owner,
                                          TaskQueueId& top_queue_id) const;

  fml::TimePoint GetNextWakeTimeUnlocked(TaskQueueId queue_id) const;

  static std::mutex creation_mutex_;
  static fml::RefPtr<MessageLoopTaskQueues> instance_;

  mutable std::mutex queue_mutex_;
  std::map<TaskQueueId, std::unique_ptr<TaskQueueEntry>> queue_entries_;

  size_t task_queue_id_counter_;

  std::atomic_int order_;

  FML_FRIEND_MAKE_REF_COUNTED(MessageLoopTaskQueues);
  FML_FRIEND_REF_COUNTED_THREAD_SAFE(MessageLoopTaskQueues);
  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(MessageLoopTaskQueues);
};

}  // namespace fml

#endif  // FLUTTER_FML_MESSAGE_LOOP_TASK_QUEUES_H_
