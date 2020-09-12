// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_PIPELINE_H_
#define FLUTTER_SHELL_COMMON_PIPELINE_H_

#include <deque>
#include <memory>
#include <mutex>

#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_counted.h"
#include "flutter/fml/synchronization/semaphore.h"
#include "flutter/fml/trace_event.h"

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

    [[nodiscard]] bool Complete(ResourcePtr resource) {
      bool result = false;
      if (continuation_) {
        result = continuation_(std::move(resource), trace_id_);
        continuation_ = nullptr;
        TRACE_EVENT_ASYNC_END0("flutter", "PipelineProduce", trace_id_);
        TRACE_FLOW_STEP("flutter", "PipelineItem", trace_id_);
      }
      return result;
    }

    operator bool() const { return continuation_ != nullptr; }

   private:
    friend class Pipeline;
    using Continuation = std::function<bool(ResourcePtr, size_t)>;

    Continuation continuation_;
    size_t trace_id_;

    ProducerContinuation(const Continuation& continuation, size_t trace_id)
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

  // Create a `ProducerContinuation` that will only push the task if the queue
  // is empty.
  // Prefer using |Produce|. ProducerContinuation returned by this method
  // doesn't guarantee that the frame will be rendered.
  ProducerContinuation ProduceIfEmpty() {
    if (!empty_.TryWait()) {
      return {};
    }
    ++inflight_;
    FML_TRACE_COUNTER("flutter", "Pipeline Depth",
                      reinterpret_cast<int64_t>(this),      //
                      "frames in flight", inflight_.load()  //
    );

    return ProducerContinuation{
        std::bind(&Pipeline::ProducerCommitIfEmpty, this, std::placeholders::_1,
                  std::placeholders::_2),  // continuation
        GetNextPipelineTraceID()};         // trace id
  }

  using Consumer = std::function<void(ResourcePtr)>;

  /// @note Procedure doesn't copy all closures.
  [[nodiscard]] PipelineConsumeResult Consume(const Consumer& consumer) {
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

  bool ProducerCommit(ResourcePtr resource, size_t trace_id) {
    {
      std::scoped_lock lock(queue_mutex_);
      queue_.emplace_back(std::move(resource), trace_id);
    }

    // Ensure the queue mutex is not held as that would be a pessimization.
    available_.Signal();
    return true;
  }

  bool ProducerCommitIfEmpty(ResourcePtr resource, size_t trace_id) {
    {
      std::scoped_lock lock(queue_mutex_);
      if (!queue_.empty()) {
        // Bail if the queue is not empty, opens up spaces to produce other
        // frames.
        empty_.Signal();
        return false;
      }
      queue_.emplace_back(std::move(resource), trace_id);
    }

    // Ensure the queue mutex is not held as that would be a pessimization.
    available_.Signal();
    return true;
  }

  FML_DISALLOW_COPY_AND_ASSIGN(Pipeline);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_PIPELINE_H_
