// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SYNCHRONIZATION_PIPELINE_H_
#define SYNCHRONIZATION_PIPELINE_H_

#include "flutter/glue/trace_event.h"
#include "flutter/synchronization/pipeline.h"
#include "flutter/synchronization/semaphore.h"
#include "lib/fxl/functional/closure.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/memory/ref_counted.h"
#include "lib/fxl/synchronization/mutex.h"
#include "lib/fxl/synchronization/thread_annotations.h"

#include <memory>
#include <queue>

namespace flutter {

enum class PipelineConsumeResult {
  NoneAvailable,
  Done,
  MoreAvailable,
};

template <class R>
class Pipeline : public fxl::RefCountedThreadSafe<Pipeline<R>> {
 public:
  using Resource = R;
  using ResourcePtr = std::unique_ptr<Resource>;

  /// Denotes a spot in the pipeline reserved for the producer to finish
  /// preparing a completed pipeline resource.
  class ProducerContinuation {
   public:
    ProducerContinuation() : trace_id_(0) {}

    ProducerContinuation(ProducerContinuation&& other)
        : continuation_(other.continuation_), trace_id_(other.trace_id_) {
      other.continuation_ = nullptr;
      other.trace_id_ = 0;
    }

    ProducerContinuation& operator=(ProducerContinuation&& other) {
      std::swap(continuation_, other.continuation_);
      std::swap(trace_id_, other.trace_id_);
      return *this;
    }

    ~ProducerContinuation() {
      if (continuation_) {
        continuation_(nullptr, trace_id_);
        TRACE_EVENT_ASYNC_END0("flutter", "PipelineProduce", trace_id_);
        // The continuation is being dropped on the floor. End the flow.
        TRACE_FLOW_END("flutter", "PipelineItem", trace_id_);
      }
    }

    void Complete(ResourcePtr resource) {
      if (continuation_) {
        continuation_(std::move(resource), trace_id_);
        continuation_ = nullptr;
        TRACE_EVENT_ASYNC_END0("flutter", "PipelineProduce", trace_id_);
        TRACE_FLOW_STEP("flutter", "PipelineItem", trace_id_);
      }
    }

    operator bool() const { return continuation_ != nullptr; }

   private:
    friend class Pipeline;
    using Continuation = std::function<void(ResourcePtr, size_t)>;

    Continuation continuation_;
    size_t trace_id_;

    ProducerContinuation(Continuation continuation, size_t trace_id)
        : continuation_(continuation), trace_id_(trace_id) {
      TRACE_FLOW_BEGIN("flutter", "PipelineItem", trace_id_);
      TRACE_EVENT_ASYNC_BEGIN0("flutter", "PipelineProduce", trace_id_);
    }

    FXL_DISALLOW_COPY_AND_ASSIGN(ProducerContinuation);
  };

  explicit Pipeline(uint32_t depth)
      : empty_(depth), available_(0), last_trace_id_(0) {}

  ~Pipeline() = default;

  bool IsValid() const { return empty_.IsValid() && available_.IsValid(); }

  ProducerContinuation Produce() {
    if (!empty_.TryWait()) {
      return {};
    }

    return ProducerContinuation{
        std::bind(&Pipeline::ProducerCommit, this, std::placeholders::_1,
                  std::placeholders::_2),  // continuation
        ++last_trace_id_};                 // trace id
  }

  using Consumer = std::function<void(ResourcePtr)>;

  FXL_WARN_UNUSED_RESULT
  PipelineConsumeResult Consume(Consumer consumer) {
    if (consumer == nullptr) {
      return PipelineConsumeResult::NoneAvailable;
    }

    if (!available_.TryWait()) {
      return PipelineConsumeResult::NoneAvailable;
    }

    ResourcePtr resource;
    size_t trace_id = 0;
    size_t items_count = 0;

    {
      fxl::MutexLocker lock(&queue_mutex_);
      std::tie(resource, trace_id) = std::move(queue_.front());
      queue_.pop();
      items_count = queue_.size();
    }

    {
      TRACE_EVENT0("flutter", "PipelineConsume");
      consumer(std::move(resource));
    }

    empty_.Signal();

    TRACE_FLOW_END("flutter", "PipelineItem", trace_id);

    return items_count > 0 ? PipelineConsumeResult::MoreAvailable
                           : PipelineConsumeResult::Done;
  }

 private:
  Semaphore empty_;
  Semaphore available_;
  fxl::Mutex queue_mutex_;
  std::queue<std::pair<ResourcePtr, size_t>> queue_
      FXL_GUARDED_BY(queue_mutex_);
  std::atomic_size_t last_trace_id_;

  void ProducerCommit(ResourcePtr resource, size_t trace_id) {
    {
      fxl::MutexLocker lock(&queue_mutex_);
      queue_.emplace(std::move(resource), trace_id);
    }

    // Ensure the queue mutex is not held as that would be a pessimization.
    available_.Signal();
  }

  FXL_DISALLOW_COPY_AND_ASSIGN(Pipeline);
};

}  // namespace flutter

#endif  // SYNCHRONIZATION_PIPELINE_H_
