// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/fml/message_loop_task_queues.h"

namespace fml {

// RAII class for managing merged locks.
class MessageLoopTaskQueues::MergedQueuesRunner {
 public:
  // TODO (kaushikiska): refactor mutexes out side of MessageLoopTaskQueues
  // for better DI.
  MergedQueuesRunner(MessageLoopTaskQueues& task_queues,
                     TaskQueueId owner,
                     MutexType type = MutexType::kTasks)
      : owner_(owner),
        subsumed_(task_queues_._kUnmerged),
        task_queues_(task_queues),
        type_(type) {
    task_queues_.GetMutex(owner, type).lock();
    subsumed_ = task_queues_.owner_to_subsumed_[owner];
    if (isMerged(subsumed_)) {
      task_queues_.GetMutex(subsumed_, type).lock();
    }
  }

  // First invokes on owner and then subsumed (if present).
  void InvokeMerged(std::function<void(const TaskQueueId)> closure) {
    closure(owner_);
    if (isMerged(subsumed_)) {
      closure(subsumed_);
    }
  }

  ~MergedQueuesRunner() {
    if (isMerged(subsumed_)) {
      task_queues_.GetMutex(subsumed_, type_).unlock();
    }
    task_queues_.GetMutex(owner_, type_).unlock();
  }

 private:
  bool isMerged(TaskQueueId queue_id) {
    return queue_id != MessageLoopTaskQueues::_kUnmerged;
  }

  const TaskQueueId owner_;
  TaskQueueId subsumed_;
  MessageLoopTaskQueues& task_queues_;
  const MutexType type_;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(MergedQueuesRunner);
};

}  // namespace fml
