// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/pipeline_compile_queue.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace impeller {

PipelineCompileQueue::~PipelineCompileQueue() {
  FinishAllJobs();
}

bool PipelineCompileQueue::PostJobForDescriptor(const PipelineDescriptor& desc,
                                                const fml::closure& job) {
  if (!job) {
    return false;
  }

  const Priority priority =
      desc.IsHighPriority() ? Priority::kHigh : Priority::kNormal;

  if (!AddJob(desc, job, priority)) {
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

bool PipelineCompileQueue::AddJob(const PipelineDescriptor& desc,
                                  const fml::closure& job,
                                  Priority priority) {
  Lock lock(pending_jobs_mutex_);
  // Priority is not part of a descriptor's identity, so a descriptor already
  // queued at one priority must not be queued again at another. Both closures
  // would fulfill the same promise.
  if (pending_jobs_.find(desc) != pending_jobs_.end() ||
      pending_high_priority_jobs_.find(desc) !=
          pending_high_priority_jobs_.end()) {
    return false;
  }
  auto& jobs = priority == Priority::kHigh ? pending_high_priority_jobs_  //
                                           : pending_jobs_;
  auto insertion_result = jobs.insert(std::make_pair(desc, job));
  return insertion_result.second;
}

bool PipelineCompileQueue::HasPendingJobs() {
  Lock lock(pending_jobs_mutex_);
  return !pending_high_priority_jobs_.empty() || !pending_jobs_.empty();
}

fml::closure PipelineCompileQueue::TakeNextJob() {
  Lock lock(pending_jobs_mutex_);
  // Always drain high priority jobs first. These are the pipelines needed to
  // render the first frame.
  auto& jobs = pending_high_priority_jobs_.empty()
                   ? pending_jobs_
                   : pending_high_priority_jobs_;
  if (jobs.empty()) {
    return nullptr;
  }
  auto job_iterator = jobs.begin();
  auto job = job_iterator->second;
  jobs.erase(job_iterator);
  return job;
}

fml::closure PipelineCompileQueue::TakeJob(const PipelineDescriptor& desc) {
  Lock lock(pending_jobs_mutex_);
  auto found = pending_high_priority_jobs_.find(desc);
  bool found_in_high_priority = found != pending_high_priority_jobs_.end();
  if (!found_in_high_priority) {
    found = pending_jobs_.find(desc);
    if (found == pending_jobs_.end()) {
      return nullptr;
    }
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
  if (found_in_high_priority) {
    pending_high_priority_jobs_.erase(found);
  } else {
    pending_jobs_.erase(found);
  }
  return job;
}

void PipelineCompileQueue::DoOneJob() {
  if (auto job = TakeNextJob()) {
    job();
  }
}

void PipelineCompileQueue::FinishAllJobs() {
  // This doesn't have to be fast. Just ensures the task queue is flushed when
  // the compile queue is shutting down with jobs still in it. Both priority
  // queues must be drained; leaving a job behind means its promise is never
  // fulfilled and any thread that later waits on it blocks forever.
  while (HasPendingJobs()) {
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
