// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_

#include <memory>

#include "flutter/fml/closure.h"
#include "flutter/fml/task_runner.h"
#include "impeller/base/comparable.h"
#include "impeller/base/thread.h"
#include "impeller/renderer/pipeline_compile_queue.h"
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
    : public PipelineCompileQueue,
      public std::enable_shared_from_this<PipelineCompileQueueGLES> {
 public:
  static std::shared_ptr<PipelineCompileQueueGLES> Create(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner);

  ~PipelineCompileQueueGLES() override;

  PipelineCompileQueueGLES(const PipelineCompileQueueGLES&) = delete;

  PipelineCompileQueueGLES& operator=(const PipelineCompileQueueGLES&) = delete;

  // |PipelineCompileQueue|
  bool PostJobForDescriptor(const PipelineDescriptor& desc,
                            const fml::closure& job) override;

  // |PipelineCompileQueue|
  void PerformJobEagerly(const PipelineDescriptor& desc) override;

 private:
  explicit PipelineCompileQueueGLES(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner);

  /// Posts a task to the worker that performs the next pending job and then
  /// schedules itself again. Stops once the queue is empty.
  void ScheduleNextJob();

  /// Removes and returns the oldest pending job. If there are none, marks the
  /// queue as no longer processing and returns null.
  fml::closure TakeNextJob();

  std::shared_ptr<fml::BasicTaskRunner> worker_task_runner_;
  Mutex mutex_;
  absl::linked_hash_map<PipelineDescriptor,
                        fml::closure,
                        ComparableHash<PipelineDescriptor>,
                        ComparableEqual<PipelineDescriptor>>
      pending_jobs_ IPLR_GUARDED_BY(mutex_);
  bool is_processing_ IPLR_GUARDED_BY(mutex_) = false;
  size_t priorities_elevated_ IPLR_GUARDED_BY(mutex_) = 0;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_
