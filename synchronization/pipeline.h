// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SYNCHRONIZATION_PIPELINE_H_
#define SYNCHRONIZATION_PIPELINE_H_

#include "lib/ftl/macros.h"
#include "lib/ftl/memory/ref_counted.h"
#include "lib/ftl/synchronization/mutex.h"
#include "lib/ftl/functional/closure.h"
#include "flutter/synchronization/semaphore.h"
#include "flutter/synchronization/pipeline.h"
#include "flutter/glue/trace_event.h"

#include <memory>
#include <queue>

namespace flutter {

enum class PipelineConsumeResult {
  NoneAvailable,
  Done,
  MoreAvailable,
};

template <class R>
class Pipeline : public ftl::RefCountedThreadSafe<Pipeline<R>> {
 public:
  using Resource = R;
  using ResourcePtr = std::unique_ptr<Resource>;

  /// Denotes a spot in the pipeline reserved for the producer to finish
  /// preparing a completed pipeline resource.
  class ProducerContinuation {
   public:
    ProducerContinuation() = default;

    ProducerContinuation(ProducerContinuation&& other)
        : continuation_(other.continuation_) {
      other.continuation_ = nullptr;
    }

    ProducerContinuation& operator=(ProducerContinuation&& other) {
      std::swap(continuation_, other.continuation_);
      return *this;
    }

    ~ProducerContinuation() {
      if (continuation_) {
        continuation_(nullptr);
      }
    }

    void Complete(ResourcePtr resource) {
      if (continuation_) {
        continuation_(std::move(resource));
        continuation_ = nullptr;
      }
    }

    operator bool() const { return continuation_ != nullptr; }

   private:
    friend class Pipeline;

    std::function<void(ResourcePtr)> continuation_;

    ProducerContinuation(std::function<void(ResourcePtr)> continuation)
        : continuation_(continuation) {}

    FTL_DISALLOW_COPY_AND_ASSIGN(ProducerContinuation);
  };

  explicit Pipeline(uint32_t depth) : empty_(depth), available_(0) {}

  ~Pipeline() = default;

  bool IsValid() const { return empty_.IsValid() && available_.IsValid(); }

  ProducerContinuation Produce() {
    if (!empty_.TryWait()) {
      return {};
    }

    return {std::bind(&Pipeline::ProducerCommit, this, std::placeholders::_1)};
  }

  using Consumer = std::function<void(ResourcePtr)>;

  FTL_WARN_UNUSED_RESULT
  PipelineConsumeResult Consume(Consumer consumer) {
    if (consumer == nullptr) {
      return PipelineConsumeResult::NoneAvailable;
    }

    if (!available_.TryWait()) {
      return PipelineConsumeResult::NoneAvailable;
    }

    ResourcePtr resource;
    size_t items_count = 0;

    {
      ftl::MutexLocker lock(&queue_mutex_);
      resource = std::move(queue_.front());
      queue_.pop();
      items_count = queue_.size();
    }

    {
      TRACE_EVENT0("flutter", "PipelineConsume");
      consumer(std::move(resource));
    }

    empty_.Signal();

    return items_count > 0 ? PipelineConsumeResult::MoreAvailable
                           : PipelineConsumeResult::Done;
  }

 private:
  Semaphore empty_;
  Semaphore available_;
  ftl::Mutex queue_mutex_;
  std::queue<ResourcePtr> queue_;

  void ProducerCommit(ResourcePtr resource) {
    {
      ftl::MutexLocker lock(&queue_mutex_);
      queue_.emplace(std::move(resource));
    }

    // Ensure the queue mutex is not held as that would be a pessimization.
    available_.Signal();
  }

  FTL_DISALLOW_COPY_AND_ASSIGN(Pipeline);
};

}  // namespace flutter

#endif  // SYNCHRONIZATION_PIPELINE_H_
