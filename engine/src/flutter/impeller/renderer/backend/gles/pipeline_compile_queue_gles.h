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
///             This implementation uses a fml::TaskRunner as the worker task
///             runner and implements a sequential job processing mechanism to
///             prevent blocking the IO task runner.
///
///             Key characteristics:
///             - Uses fml::RefPtr<fml::TaskRunner> for worker_task_runner_
///             - Processes jobs sequentially: loads one job at a time before
///               proceeding to the next, preventing IO task runner blocking
///             - Uses DrainPendingJobs() to recursively process jobs one by one
///             - Employs is_processing_ flag and processing_mutex_ to control
///               sequential processing
///
///             The sequential processing ensures that pipeline compilation jobs
///             do not overwhelm the task runner, which is particularly
///             important for GLES backend where resource loading patterns
///             differ from Vulkan.
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

  //----------------------------------------------------------------------------
  /// @brief      Post a job directly to the worker task runner, bypassing the
  ///             pending job queue.
  ///
  /// @param[in]  job  The job closure to post. Null closures are ignored.
  ///
  void PostJob(const fml::closure& job);

 private:
  explicit PipelineCompileQueueGLES(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner);

  /// Starts draining the pending jobs if a drain is not already in progress.
  void OnJobAdded();

  /// Executes one pending job and reposts itself until no jobs remain.
  void DrainPendingJobs();

  /// Adds a job for the descriptor. Returns false if one already exists.
  bool AddJob(const PipelineDescriptor& desc, const fml::closure& job);

  bool HasPendingJobs();

  fml::closure TakeJob(const PipelineDescriptor& desc);

  fml::closure TakeNextJob();

  void DoOneJob();

  void FinishAllJobs();

  std::shared_ptr<fml::BasicTaskRunner> worker_task_runner_;
  Mutex processing_mutex_;
  bool is_processing_ IPLR_GUARDED_BY(processing_mutex_) = false;
  Mutex pending_jobs_mutex_;
  absl::linked_hash_map<PipelineDescriptor,
                        fml::closure,
                        ComparableHash<PipelineDescriptor>,
                        ComparableEqual<PipelineDescriptor>>
      pending_jobs_ IPLR_GUARDED_BY(pending_jobs_mutex_);
  size_t priorities_elevated_ IPLR_GUARDED_BY(pending_jobs_mutex_) = {};
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_PIPELINE_COMPILE_QUEUE_GLES_H_
