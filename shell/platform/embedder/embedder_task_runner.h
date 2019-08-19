// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_TASK_RUNNER_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_TASK_RUNNER_H_

#include <mutex>
#include <unordered_map>

#include "flutter/fml/macros.h"
#include "flutter/fml/synchronization/thread_annotations.h"
#include "flutter/fml/task_runner.h"

namespace flutter {

class EmbedderTaskRunner final : public fml::TaskRunner {
 public:
  struct DispatchTable {
    std::function<void(EmbedderTaskRunner* task_runner,
                       uint64_t task_baton,
                       fml::TimePoint target_time)>
        post_task_callback;
    std::function<bool(void)> runs_task_on_current_thread_callback;
  };

  EmbedderTaskRunner(DispatchTable table);

  ~EmbedderTaskRunner() override;

  bool PostTask(uint64_t baton);

  // |fml::TaskRunner|
  void PostTask(fml::closure task) override;

  // |fml::TaskRunner|
  void PostTaskForTime(fml::closure task, fml::TimePoint target_time) override;

  // |fml::TaskRunner|
  void PostDelayedTask(fml::closure task, fml::TimeDelta delay) override;

  // |fml::TaskRunner|
  bool RunsTasksOnCurrentThread() override;

  // |fml::TaskRunner|
  fml::TaskQueueId GetTaskQueueId() override;

 private:
  DispatchTable dispatch_table_;
  std::mutex tasks_mutex_;
  uint64_t last_baton_ FML_GUARDED_BY(tasks_mutex_);
  std::unordered_map<uint64_t, fml::closure> pending_tasks_
      FML_GUARDED_BY(tasks_mutex_);
  fml::TaskQueueId placeholder_id_;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderTaskRunner);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_TASK_RUNNER_H_
