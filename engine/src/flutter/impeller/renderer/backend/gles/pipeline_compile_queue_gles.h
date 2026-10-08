// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_

#include <functional>
#include <memory>

#include "flutter/fml/closure.h"
#include "flutter/fml/task_runner.h"
#include "impeller/base/comparable.h"
#include "impeller/base/thread.h"
#include "impeller/renderer/pipeline_descriptor.h"
#include "third_party/abseil-cpp/absl/container/linked_hash_map.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      A task queue designed for managing compilation of pipeline state
///             objects for OpenGL ES backend.
///
///             Jobs are processed sequentially in insertion order: at most one
///             task is outstanding on the worker task runner at a time, and
///             each task performs a single job before scheduling the next one.
///             This prevents pipeline compilation from monopolizing the worker
///             (IO) task runner, letting other tasks interleave between jobs.
///
class PipelineCompileQueueGLES final
    : public std::enable_shared_from_this<PipelineCompileQueueGLES> {
 public:
  //----------------------------------------------------------------------------
  /// A compile job.
  ///
  /// @param[in]  eager  `false` if the job is being run by the queue on the
  ///                    worker task runner. `true` if it is being run
  ///                    immediately on the calling thread because the caller
  ///                    is about to wait on it (see `PerformJobEagerly`), or
  ///                    because the queue is being destroyed. Eager jobs must
  ///                    finish all of their work on the calling thread.
  ///
  using Job = std::function<void(bool eager)>;

  static std::shared_ptr<PipelineCompileQueueGLES> Create(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner);

  ~PipelineCompileQueueGLES();

  PipelineCompileQueueGLES(const PipelineCompileQueueGLES&) = delete;

  PipelineCompileQueueGLES& operator=(const PipelineCompileQueueGLES&) = delete;

  //----------------------------------------------------------------------------
  /// @brief      Post a compile job for the specified descriptor.
  ///
  /// @param[in]  desc  The description
  /// @param[in]  job   The job
  ///
  /// @return     If the job was successfully posted to the worker task runner.
  ///
  bool PostJobForDescriptor(const PipelineDescriptor& desc, const Job& job);

  //----------------------------------------------------------------------------
  /// @brief      If the job has not yet been done, perform it eagerly on the
  ///             calling thread. This can be used in lieu of an idle wait for
  ///             the job completion on the calling thread.
  ///
  /// @param[in]  desc  The description
  ///
  void PerformJobEagerly(const PipelineDescriptor& desc);

  //----------------------------------------------------------------------------
  /// @brief      Posts a task directly to the worker task runner, bypassing the
  ///             job queue. Unlike jobs, the task can't be performed eagerly.
  ///
  /// @param[in]  task  The task
  ///
  void PostTask(const fml::closure& task);

 private:
  explicit PipelineCompileQueueGLES(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner);

  /// Posts a task to the worker that performs the next pending job and then
  /// schedules a task for the next job in the queue.
  void ScheduleNextJob();

  /// Removes and returns the oldest pending job. If there are none, marks the
  /// queue as no longer processing and returns null.
  Job TakeNextJob();

  std::shared_ptr<fml::BasicTaskRunner> worker_task_runner_;
  Mutex mutex_;
  absl::linked_hash_map<PipelineDescriptor,
                        Job,
                        ComparableHash<PipelineDescriptor>,
                        ComparableEqual<PipelineDescriptor>>
      pending_jobs_ IPLR_GUARDED_BY(mutex_);
  bool is_processing_ IPLR_GUARDED_BY(mutex_) = false;
  size_t priorities_elevated_ IPLR_GUARDED_BY(mutex_) = 0;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_
