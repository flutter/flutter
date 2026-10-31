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
#include "impeller/renderer/pipeline_descriptor.h"
#include "third_party/abseil-cpp/absl/container/linked_hash_map.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      A task queue designed for managing compilation of pipeline state
///             objects for Vulkan backend.
///
///             Every job added to the queue posts a task to the (typically
///             concurrent) worker task runner, so compile jobs may run in
///             parallel. Each task performs the oldest pending job at the time
///             it runs.
///
class PipelineCompileQueueVulkan final
    : public std::enable_shared_from_this<PipelineCompileQueueVulkan> {
 public:
  static std::shared_ptr<PipelineCompileQueueVulkan> Create(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner);

  ~PipelineCompileQueueVulkan();

  PipelineCompileQueueVulkan(const PipelineCompileQueueVulkan&) = delete;

  PipelineCompileQueueVulkan& operator=(const PipelineCompileQueueVulkan&) =
      delete;

  //----------------------------------------------------------------------------
  /// @brief      Post a compile job for the specified descriptor.
  ///
  /// @param[in]  desc  The description
  /// @param[in]  job   The job
  ///
  /// @return     If the job was successfully posted to the worker task runner.
  ///
  bool PostJobForDescriptor(const PipelineDescriptor& desc,
                            const fml::closure& job);

  //----------------------------------------------------------------------------
  /// @brief      If the task has not yet been done, perform it eagerly on the
  ///             calling thread. This can be used in lieu of an idle wait for
  ///             the task completion on the calling thread.
  ///
  /// @param[in]  desc  The description
  ///
  void PerformJobEagerly(const PipelineDescriptor& desc);

 private:
  explicit PipelineCompileQueueVulkan(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner);

  /// Removes and returns the oldest pending job, or null if there are none.
  fml::closure TakeNextJob();

  std::shared_ptr<fml::BasicTaskRunner> worker_task_runner_;
  Mutex mutex_;
  absl::linked_hash_map<PipelineDescriptor,
                        fml::closure,
                        ComparableHash<PipelineDescriptor>,
                        ComparableEqual<PipelineDescriptor>>
      pending_jobs_ IPLR_GUARDED_BY(mutex_);
  size_t priorities_elevated_ IPLR_GUARDED_BY(mutex_) = 0;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_PIPELINE_COMPILE_QUEUE_VULKAN_H_
