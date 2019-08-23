// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_PIPELINE_H_
#define FLUTTER_SHELL_COMMON_PIPELINE_H_

#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_counted.h"
#include "flutter/fml/synchronization/semaphore.h"
#include "flutter/fml/trace_event.h"

#include <deque>
#include <memory>
#include <mutex>

namespace flutter {

enum class PipelineConsumeResult {
  NoneAvailable,
  Done,
  MoreAvailable,
};

size_t GetNextPipelineTraceID();

/// A thread-safe queue of resources for a single consumer and a single
/// producer.
template <class R>
class Pipeline : public fml::RefCountedThreadSafe<Pipeline<R>> {
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
        TRACE_EVENT_ASYNC_END0("flutter", "PipelineItem", trace_id_);
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
      TRACE_EVENT_ASYNC_BEGIN0("flutter", "PipelineItem", trace_id_);
      TRACE_EVENT_ASYNC_BEGIN0("flutter", "PipelineProduce", trace_id_);
    }

    FML_DISALLOW_COPY_AND_ASSIGN(ProducerContinuation);
  };

  explicit Pipeline(uint32_t depth)
      : depth_(depth), empty_(depth), available_(0), inflight_(0) {}

  ~Pipeline() = default;

  bool IsValid() const { return empty_.IsValid() && available_.IsValid(); }

  ProducerContinuation Produce() {
    if (!empty_.TryWait()) {
      return {};
    }
    ++inflight_;
    FML_TRACE_COUNTER("flutter", "Pipeline Depth",
                      reinterpret_cast<int64_t>(this),      //
                      "frames in flight", inflight_.load()  //
    );

    return ProducerContinuation{
        std::bind(&Pipeline::ProducerCommit, this, std::placeholders::_1,
                  std::placeholders::_2),  // continuation
        GetNextPipelineTraceID()};         // trace id
  }

  // Pushes task to the front of the pipeline.
  //
  // If we exceed the depth completing this continuation, we drop the
  // last frame to preserve the depth of the pipeline.
  //
  // Note: Use |Pipeline::Produce| where possible. This should only be
  // used to en-queue high-priority resources.
  ProducerContinuation ProduceToFront() {
    return ProducerContinuation{
        std::bind(&Pipeline::ProducerCommitFront, this, std::placeholders::_1,
                  std::placeholders::_2),  // continuation
        GetNextPipelineTraceID()};         // trace id
  }

  using Consumer = std::function<void(ResourcePtr)>;

  FML_WARN_UNUSED_RESULT
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
      std::scoped_lock lock(queue_mutex_);
      std::tie(resource, trace_id) = std::move(queue_.front());
      queue_.pop_front();
      items_count = queue_.size();
    }

    {
      TRACE_EVENT0("flutter", "PipelineConsume");
      consumer(std::move(resource));
    }

    empty_.Signal();
    --inflight_;

    TRACE_FLOW_END("flutter", "PipelineItem", trace_id);
    TRACE_EVENT_ASYNC_END0("flutter", "PipelineItem", trace_id);

    return items_count > 0 ? PipelineConsumeResult::MoreAvailable
                           : PipelineConsumeResult::Done;
  }

 private:
  const uint32_t depth_;
  fml::Semaphore empty_;
  fml::Semaphore available_;
  std::atomic<int> inflight_;
  std::mutex queue_mutex_;
  std::deque<std::pair<ResourcePtr, size_t>> queue_;

  void ProducerCommit(ResourcePtr resource, size_t trace_id) {
    {
      std::scoped_lock lock(queue_mutex_);
      queue_.emplace_back(std::move(resource), trace_id);
    }

    // Ensure the queue mutex is not held as that would be a pessimization.
    available_.Signal();
  }

  void ProducerCommitFront(ResourcePtr resource, size_t trace_id) {
    {
      std::scoped_lock lock(queue_mutex_);
      queue_.emplace_front(std::move(resource), trace_id);
      while (queue_.size() > depth_) {
        queue_.pop_back();
      }
    }

    // Ensure the queue mutex is not held as that would be a pessimization.
    available_.Signal();
  }

  FML_DISALLOW_COPY_AND_ASSIGN(Pipeline);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_PIPELINE_H_
