// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_PIPELINE_COMPILE_QUEUE_VULKAN_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_PIPELINE_COMPILE_QUEUE_VULKAN_H_

#include "flutter/fml/closure.h"
#include "flutter/fml/task_runner.h"
#include "impeller/renderer/pipeline_compile_queue.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      A task queue designed for managing compilation of pipeline state
///             objects for Vulkan backend.
///
///             This subclass uses a fml::BasicTaskRunner as the worker task
///             runner and dispatches compile jobs directly without sequential
///             processing constraints.
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
class PipelineCompileQueueVulkan : public PipelineCompileQueue {
 public:
  static std::shared_ptr<PipelineCompileQueueVulkan> Create(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner);

  ~PipelineCompileQueueVulkan() override;

  PipelineCompileQueueVulkan(const PipelineCompileQueueVulkan&) = delete;

  PipelineCompileQueueVulkan& operator=(const PipelineCompileQueueVulkan&) =
      delete;

  void PostJob(const fml::closure& job) override;

  void OnJobAdded() override;

 private:
  explicit PipelineCompileQueueVulkan(
      std::shared_ptr<fml::BasicTaskRunner> worker_task_runner);
  std::shared_ptr<fml::BasicTaskRunner> worker_task_runner_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_PIPELINE_COMPILE_QUEUE_VULKAN_H_
