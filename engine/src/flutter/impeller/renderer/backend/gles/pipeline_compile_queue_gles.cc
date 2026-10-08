// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/pipeline_compile_queue_gles.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace impeller {

std::shared_ptr<PipelineCompileQueueGLES> PipelineCompileQueueGLES::Create(
    std::shared_ptr<fml::BasicTaskRunner> worker_task_runner) {
  if (!worker_task_runner) {
    return nullptr;
  }
  return std::shared_ptr<PipelineCompileQueueGLES>(
      new PipelineCompileQueueGLES(std::move(worker_task_runner)));
}

PipelineCompileQueueGLES::PipelineCompileQueueGLES(
    std::shared_ptr<fml::BasicTaskRunner> worker_task_runner)
    : worker_task_runner_(std::move(worker_task_runner)) {}

PipelineCompileQueueGLES::~PipelineCompileQueueGLES() {
  FinishAllJobs();
}

bool PipelineCompileQueueGLES::PostJobForDescriptor(
    const PipelineDescriptor& desc,
    const fml::closure& job) {
  if (!job) {
    return false;
  }

  if (!AddJob(desc, job)) {
    // This bit is being extremely conservative. If insertion did not take
    // place, someone gave the compile queue a job for the same description.
    // This is highly unusual but technically not impossible. Just run the job
    // eagerly.
    FML_LOG(WARNING) << "Got multiple compile jobs for the same descriptor. "
                        "Running eagerly.";
    PostJob(job);
    return true;
  }

  OnJobAdded();
  return true;
}

void PipelineCompileQueueGLES::PerformJobEagerly(
    const PipelineDescriptor& desc) {
  if (auto job = TakeJob(desc)) {
    job();
  }
}

void PipelineCompileQueueGLES::PostJob(const fml::closure& job) {
  if (!job) {
    return;
  }

  worker_task_runner_->PostTask(job);
}

void PipelineCompileQueueGLES::OnJobAdded() {
  // To prevent potential deadlocks and reduce lock contention, avoid calling
  // external or virtual methods (such as DrainPendingJobs, which posts tasks
  // to the task runner) while holding a mutex. Instead, minimize the scope of
  // the lock by using a local boolean flag to trigger the draining process
  // outside the lock block.
  bool should_drain = false;
  {
    Lock lock(processing_mutex_);
    if (!is_processing_) {
      is_processing_ = true;
      should_drain = true;
    }
  }
  if (should_drain) {
    DrainPendingJobs();
  }
}

void PipelineCompileQueueGLES::DrainPendingJobs() {
  PostJob([weak_queue = weak_from_this()]() {
    if (auto queue = weak_queue.lock()) {
      queue->DoOneJob();
      {
        Lock lock(queue->processing_mutex_);
        if (!queue->HasPendingJobs()) {
          queue->is_processing_ = false;
          return;
        }
      }
      queue->DrainPendingJobs();
    }
  });
}

bool PipelineCompileQueueGLES::AddJob(const PipelineDescriptor& desc,
                                      const fml::closure& job) {
  Lock lock(pending_jobs_mutex_);
  auto insertion_result = pending_jobs_.insert(std::make_pair(desc, job));
  return insertion_result.second;
}

bool PipelineCompileQueueGLES::HasPendingJobs() {
  Lock lock(pending_jobs_mutex_);
  return !pending_jobs_.empty();
}

fml::closure PipelineCompileQueueGLES::TakeNextJob() {
  Lock lock(pending_jobs_mutex_);
  if (pending_jobs_.empty()) {
    return nullptr;
  }
  auto job_iterator = pending_jobs_.begin();
  auto job = job_iterator->second;
  pending_jobs_.erase(job_iterator);
  return job;
}

fml::closure PipelineCompileQueueGLES::TakeJob(const PipelineDescriptor& desc) {
  Lock lock(pending_jobs_mutex_);
  auto found = pending_jobs_.find(desc);
  if (found == pending_jobs_.end()) {
    return nullptr;
  }
  // The pipeline compile job was somewhere in the task queue. However, a
  // rendering operation needed the job to be done ASAP. Instead of waiting for
  // the pipeline compile queue to eventually get to finishing job, the thread
  // waiting on the job just decided to take the job from the queue and do it
  // itself. If there were jobs ahead of this one, it means that they were
  // mis-prioritized. This counter dumps the number of job re-prioritizations.
  priorities_elevated_++;
  FML_TRACE_COUNTER("impeller", "PipelineCompileQueue",
                    reinterpret_cast<int64_t>(this),  // Trace Counter ID
                    "PrioritiesElevated", priorities_elevated_);
  auto job = found->second;
  pending_jobs_.erase(found);
  return job;
}

void PipelineCompileQueueGLES::DoOneJob() {
  if (auto job = TakeNextJob()) {
    job();
  }
}

void PipelineCompileQueueGLES::FinishAllJobs() {
  // This doesn't have to be fast. Just ensures the task queue is flushed when
  // the compile queue is shutting down with jobs still in it.
  while (HasPendingJobs()) {
    DoOneJob();
  }
}

}  // namespace impeller
