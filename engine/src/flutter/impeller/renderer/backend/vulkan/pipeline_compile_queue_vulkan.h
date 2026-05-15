// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_PIPELINE_COMPILE_QUEUE_VULKAN_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_PIPELINE_COMPILE_QUEUE_VULKAN_H_

#include "flutter/fml/closure.h"
#include "flutter/fml/task_runner.h"
#include "impeller/renderer/pipeline_compile_queue.h"

namespace impeller {

class PipelineCompileQueueVulkan : public PipelineCompileQueue {
 public:
  static std::shared_ptr<PipelineCompileQueueVulkan> Create(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner);

  explicit PipelineCompileQueueVulkan(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner);

  ~PipelineCompileQueueVulkan() override;

  PipelineCompileQueueVulkan(const PipelineCompileQueueVulkan&) = delete;

  PipelineCompileQueueVulkan& operator=(const PipelineCompileQueueVulkan&) =
      delete;

  //----------------------------------------------------------------------------
  /// @brief      Post a compile job for the specified descriptor.
  ///
  /// @param[in]  desc  The description
  /// @param[in]  job   The job
  ///
  /// @return     If the job was successfully posted to the parallel task
  /// runners.
  ///
  bool PostJobForDescriptor(const PipelineDescriptor& desc,
                            const fml::closure& job) override;

  //----------------------------------------------------------------------------
  /// @brief      Post a job to the worker task runner.
  ///
  /// @param[in]  job   The job
  ///
  void PostJob(const fml::closure& job) override;

 private:
  std::shared_ptr<fml::BasicTaskRunner> worker_task_runner_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_PIPELINE_COMPILE_QUEUE_VULKAN_H_
