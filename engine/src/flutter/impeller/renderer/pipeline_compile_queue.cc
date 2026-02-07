// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/pipeline_compile_queue.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace impeller {

std::shared_ptr<PipelineCompileQueue> PipelineCompileQueue::Create(
    std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner) {
  return std::shared_ptr<PipelineCompileQueue>(
      new PipelineCompileQueue(std::move(worker_task_runner)));
}

PipelineCompileQueue::PipelineCompileQueue(
    std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner)
    : worker_task_runner_(std::move(worker_task_runner)) {}

PipelineCompileQueue::~PipelineCompileQueue() {
  FinishAllJobs();
}

bool PipelineCompileQueue::PostJobForDescriptor(const PipelineDescriptor& desc,
                                                const fml::closure& job) {
  if (!job) {
    return false;
  }

  {
    Lock lock(pending_jobs_mutex_);
    auto insertion_result = pending_jobs_.insert(std::make_pair(desc, job));
    if (!insertion_result.second) {
      // This bit is being extremely conservative. If insertion did not take
      // place, someone gave the compile queue a job for the same description.
      // This is highly unusual but technically not impossible. Just run the job
      // eagerly.
      FML_LOG(ERROR) << "Got multiple compile jobs for the same descriptor. "
                        "Running eagerly.";
      // Don't invoke the job here has there are we have currently acquired a
      // mutex.
      worker_task_runner_->PostTask(job);
      return true;
    }
  }

  worker_task_runner_->PostTask([weak_queue = weak_from_this()]() {
    if (auto queue = weak_queue.lock()) {
      queue->DoOneJob();
    }
  });
  return true;
}

fml::closure PipelineCompileQueue::TakeNextJob() {
  Lock lock(pending_jobs_mutex_);
  if (pending_jobs_.empty()) {
    return nullptr;
  }
  auto job_iterator = pending_jobs_.begin();
  auto job = job_iterator->second;
  pending_jobs_.erase(job_iterator);
  return job;
}

fml::closure PipelineCompileQueue::TakeJob(const PipelineDescriptor& desc) {
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

void PipelineCompileQueue::DoOneJob() {
  if (auto job = TakeNextJob()) {
    job();
  }
}

void PipelineCompileQueue::FinishAllJobs() {
  // This doesn't have to be fast. Just ensures the task queue is flushed when
  // the compile queue is shutting down with jobs still in it.
  while (true) {
    bool has_jobs = false;
    {
      Lock lock(pending_jobs_mutex_);
      has_jobs = !pending_jobs_.empty();
    }
    if (!has_jobs) {
      return;
    }
    // Allow any remaining worker threads to take jobs from this queue.
    DoOneJob();
  }
}

void PipelineCompileQueue::PerformJobEagerly(const PipelineDescriptor& desc) {
  if (auto job = TakeJob(desc)) {
    job();
  }
}

}  // namespace impeller
