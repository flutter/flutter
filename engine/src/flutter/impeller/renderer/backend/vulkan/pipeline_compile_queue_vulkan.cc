// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/pipeline_compile_queue_vulkan.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace impeller {

std::shared_ptr<PipelineCompileQueueVulkan> PipelineCompileQueueVulkan::Create(
    std::shared_ptr<fml::BasicTaskRunner> worker_task_runner) {
  return std::shared_ptr<PipelineCompileQueueVulkan>(
      new PipelineCompileQueueVulkan(std::move(worker_task_runner)));
}

PipelineCompileQueueVulkan::PipelineCompileQueueVulkan(
    std::shared_ptr<fml::BasicTaskRunner> worker_task_runner)
    : PipelineCompileQueue(),
      worker_task_runner_(std::move(worker_task_runner)) {}

PipelineCompileQueueVulkan::~PipelineCompileQueueVulkan() {}

void PipelineCompileQueueVulkan::OnJobAdded() {
  PostJob([weak_queue = weak_from_this()]() {
    if (auto queue = std::static_pointer_cast<PipelineCompileQueueVulkan>(
            weak_queue.lock())) {
      queue->DoOneJob();
    }
  });
}

void PipelineCompileQueueVulkan::PostJob(const fml::closure& job) {
  if (!job) {
    return;
  }

  worker_task_runner_->PostTask(job);
}

}  // namespace impeller
