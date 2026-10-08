// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_PIPELINE_COMPILE_QUEUE_VULKAN_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_PIPELINE_COMPILE_QUEUE_VULKAN_H_

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
///             objects for Vulkan backend.
///
///             This implementation uses a fml::BasicTaskRunner as the worker
///             task runner and dispatches compile jobs directly without
///             sequential processing constraints.
///
///             Key characteristics:
///             - Uses std::shared_ptr<fml::BasicTaskRunner> for
///             worker_task_runner_
///             - Dispatches jobs directly to the task runner in OnJobAdded()
///             - Does not implement sequential processing like GLES version
///
///             The Vulkan backend benefits from the parallel nature of pipeline
///             compilation, allowing multiple compile jobs to be processed
///             concurrently through the task runner.
///
class PipelineCompileQueueVulkan final
    : public PipelineCompileQueue,
      public std::enable_shared_from_this<PipelineCompileQueueVulkan> {
 public:
  static std::shared_ptr<PipelineCompileQueueVulkan> Create(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner);

  ~PipelineCompileQueueVulkan() override;

  PipelineCompileQueueVulkan(const PipelineCompileQueueVulkan&) = delete;

  PipelineCompileQueueVulkan& operator=(const PipelineCompileQueueVulkan&) =
      delete;

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
  explicit PipelineCompileQueueVulkan(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner);

  /// Posts a task to the worker task runner that performs one pending job.
  void OnJobAdded();

  /// Adds a job for the descriptor. Returns false if one already exists.
  bool AddJob(const PipelineDescriptor& desc, const fml::closure& job);

  bool HasPendingJobs();

  fml::closure TakeJob(const PipelineDescriptor& desc);

  fml::closure TakeNextJob();

  void DoOneJob();

  void FinishAllJobs();

  std::shared_ptr<fml::BasicTaskRunner> worker_task_runner_;
  Mutex pending_jobs_mutex_;
  absl::linked_hash_map<PipelineDescriptor,
                        fml::closure,
                        ComparableHash<PipelineDescriptor>,
                        ComparableEqual<PipelineDescriptor>>
      pending_jobs_ IPLR_GUARDED_BY(pending_jobs_mutex_);
  size_t priorities_elevated_ IPLR_GUARDED_BY(pending_jobs_mutex_) = {};
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_PIPELINE_COMPILE_QUEUE_VULKAN_H_
