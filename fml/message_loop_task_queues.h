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
#include "flutter/fml/synchronization/thread_annotations.h"
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

  // Tasks methods.

  void RegisterTask(TaskQueueId queue_id,
                    fml::closure task,
                    fml::TimePoint target_time);

  bool HasPendingTasks(TaskQueueId queue_id);

  void GetTasksToRunNow(TaskQueueId queue_id,
                        FlushType type,
                        std::vector<fml::closure>& invocations);

  size_t GetNumPendingTasks(TaskQueueId queue_id);

  // Observers methods.

  void AddTaskObserver(TaskQueueId queue_id,
                       intptr_t key,
                       fml::closure callback);

  void RemoveTaskObserver(TaskQueueId queue_id, intptr_t key);

  void NotifyObservers(TaskQueueId queue_id);

  // Misc.

  void Swap(TaskQueueId primary, TaskQueueId secondary);

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
  //  HasPendingTasks, GetTasksToRunNow, GetNumPendingTasks

  // This method returns false if either the owner or subsumed has already been
  // merged with something else.
  bool Merge(TaskQueueId owner, TaskQueueId subsumed);

  // Will return false if the owner has not been merged before.
  bool Unmerge(TaskQueueId owner);

  // Returns true if owner owns the subsumed task queue.
  bool Owns(TaskQueueId owner, TaskQueueId subsumed);

 private:
  class MergedQueuesRunner;

  enum class MutexType {
    kTasks,
    kObservers,
    kWakeables,
  };

  using Mutexes = std::vector<std::unique_ptr<std::mutex>>;
  using TaskObservers = std::map<intptr_t, fml::closure>;

  MessageLoopTaskQueues();

  ~MessageLoopTaskQueues();

  void WakeUp(TaskQueueId queue_id, fml::TimePoint time);

  bool HasPendingTasksUnlocked(TaskQueueId queue_id);

  const DelayedTask& PeekNextTaskUnlocked(TaskQueueId queue_id,
                                          TaskQueueId& top_queue_id);

  fml::TimePoint GetNextWakeTimeUnlocked(TaskQueueId queue_id);

  std::mutex& GetMutex(TaskQueueId queue_id, MutexType type);

  static std::mutex creation_mutex_;
  static fml::RefPtr<MessageLoopTaskQueues> instance_
      FML_GUARDED_BY(creation_mutex_);

  std::mutex queue_meta_mutex_;

  size_t task_queue_id_counter_ FML_GUARDED_BY(queue_meta_mutex_);

  Mutexes observers_mutexes_ FML_GUARDED_BY(queue_meta_mutex_);
  Mutexes delayed_tasks_mutexes_ FML_GUARDED_BY(queue_meta_mutex_);
  Mutexes wakeable_mutexes_ FML_GUARDED_BY(queue_meta_mutex_);

  // These are guarded by their corresponding `Mutexes`
  std::vector<Wakeable*> wakeables_;
  std::vector<TaskObservers> task_observers_;
  std::vector<DelayedTaskQueue> delayed_tasks_;

  static const TaskQueueId _kUnmerged;
  // These are guarded by delayed_tasks_mutexes_
  std::vector<TaskQueueId> owner_to_subsumed_;
  std::vector<TaskQueueId> subsumed_to_owner_;

  std::atomic_int order_;

  FML_FRIEND_MAKE_REF_COUNTED(MessageLoopTaskQueues);
  FML_FRIEND_REF_COUNTED_THREAD_SAFE(MessageLoopTaskQueues);
  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(MessageLoopTaskQueues);
};

}  // namespace fml

#endif  // FLUTTER_FML_MESSAGE_LOOP_TASK_QUEUES_H_
