// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_

#include <memory>
#include <optional>

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
  static std::shared_ptr<PipelineCompileQueueGLES> Create(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner);

  ~PipelineCompileQueueGLES();

  PipelineCompileQueueGLES(const PipelineCompileQueueGLES&) = delete;

  PipelineCompileQueueGLES& operator=(const PipelineCompileQueueGLES&) = delete;

  //----------------------------------------------------------------------------
  /// @brief      Post a compile job for the specified descriptor.
  ///
  ///             A job has two steps, `start` and `finish`, which are always
  ///             run in that order on the same thread. When the job is run by
  ///             the worker, `finish` is posted as a separate task to the
  ///             worker task runner, giving work started by `start` (such as
  ///             the driver linking a program) time to progress. That task
  ///             can't be performed eagerly. When the job is performed eagerly
  ///             (see `PerformJobEagerly`) or flushed because the queue is
  ///             being destroyed, both steps run back to back on the calling
  ///             thread.
  ///
  /// @param[in]  desc    The description
  /// @param[in]  start   The first step of the job
  /// @param[in]  finish  The second step of the job
  ///
  /// @return     If the job was successfully posted to the worker task runner.
  ///
  bool PostJobForDescriptor(const PipelineDescriptor& desc,
                            const fml::closure& start,
                            const fml::closure& finish);

  //----------------------------------------------------------------------------
  /// @brief      If the job has not yet been done, perform it eagerly on the
  ///             calling thread. This can be used in lieu of an idle wait for
  ///             the job completion on the calling thread.
  ///
  /// @param[in]  desc  The description
  ///
  void PerformJobEagerly(const PipelineDescriptor& desc);

 private:
  struct Job {
    fml::closure start;
    fml::closure finish;
  };

  explicit PipelineCompileQueueGLES(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner);

  /// Posts a task to the worker that performs the next pending job and then
  /// schedules a task for the next job in the queue.
  void ScheduleNextJob();

  /// Removes and returns the oldest pending job. If there are none, marks the
  /// queue as no longer processing and returns nullopt.
  std::optional<Job> TakeNextJob();

  /// Runs the start of the job and posts its finish as a separate task to the
  /// worker task runner. Must be called on the worker task runner.
  static void PerformJobOnWorker(
      const std::shared_ptr<fml::BasicTaskRunner>& worker_task_runner,
      const Job& job);

  /// Runs the start and finish of the job back to back on the calling thread.
  static void PerformJobImmediately(const Job& job);

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
