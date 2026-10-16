// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/pipeline_compile_queue_vulkan.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace impeller {

std::shared_ptr<PipelineCompileQueueVulkan> PipelineCompileQueueVulkan::Create(
    std::shared_ptr<fml::BasicTaskRunner> worker_task_runner) {
  if (!worker_task_runner) {
    return nullptr;
  }
  return std::shared_ptr<PipelineCompileQueueVulkan>(
      new PipelineCompileQueueVulkan(std::move(worker_task_runner)));
}

PipelineCompileQueueVulkan::PipelineCompileQueueVulkan(
    std::shared_ptr<fml::BasicTaskRunner> worker_task_runner)
    : worker_task_runner_(std::move(worker_task_runner)) {}

PipelineCompileQueueVulkan::~PipelineCompileQueueVulkan() {
  // Flush any jobs still pending. Tasks already posted to the worker only hold
  // a weak reference to the queue and become no-ops.
  while (auto job = TakeNextJob()) {
    job();
  }
}

bool PipelineCompileQueueVulkan::PostJobForDescriptor(
    const PipelineDescriptor& desc,
    const fml::closure& job) {
  if (!job) {
    return false;
  }

  bool inserted = false;
  {
    Lock lock(mutex_);
    inserted = pending_jobs_.insert({desc, job}).second;
  }

  if (!inserted) {
    // This bit is being extremely conservative. If insertion did not take
    // place, someone gave the compile queue a job for the same description.
    // This is highly unusual but technically not impossible. Just run the job
    // eagerly.
    FML_LOG(WARNING) << "Got multiple compile jobs for the same descriptor. "
                        "Running eagerly.";
    worker_task_runner_->PostTask(job);
    return true;
  }

  worker_task_runner_->PostTask([weak_queue = weak_from_this()]() {
    if (auto queue = weak_queue.lock()) {
      if (auto next_job = queue->TakeNextJob()) {
        next_job();
      }
    }
  });
  return true;
}

void PipelineCompileQueueVulkan::PerformJobEagerly(
    const PipelineDescriptor& desc) {
  fml::closure job;
  {
    Lock lock(mutex_);
    auto found = pending_jobs_.find(desc);
    if (found == pending_jobs_.end()) {
      return;
    }
    // The pipeline compile job was somewhere in the task queue. However, a
    // rendering operation needed the job to be done ASAP. Instead of waiting
    // for the pipeline compile queue to eventually get to finishing job, the
    // thread waiting on the job just decided to take the job from the queue and
    // do it itself. If there were jobs ahead of this one, it means that they
    // were mis-prioritized. This counter dumps the number of job
    // re-prioritizations.
    priorities_elevated_++;
    FML_TRACE_COUNTER("impeller", "PipelineCompileQueue",
                      reinterpret_cast<int64_t>(this),  // Trace Counter ID
                      "PrioritiesElevated", priorities_elevated_);
    job = std::move(found->second);
    pending_jobs_.erase(found);
  }
  job();
}

fml::closure PipelineCompileQueueVulkan::TakeNextJob() {
  Lock lock(mutex_);
  if (pending_jobs_.empty()) {
    return nullptr;
  }
  auto job_iterator = pending_jobs_.begin();
  auto job = std::move(job_iterator->second);
  pending_jobs_.erase(job_iterator);
  return job;
}

}  // namespace impeller
