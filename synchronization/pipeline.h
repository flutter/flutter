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

  explicit Pipeline(uint32_t depth) : empty_(depth), available_(0) {}

  ~Pipeline() {}

  bool IsValid() const { return empty_.IsValid() && available_.IsValid(); }

  using Producer = std::function<ResourcePtr(void)>;

  FTL_WARN_UNUSED_RESULT
  bool Produce(Producer producer) {
    if (producer == nullptr) {
      return false;
    }

    if (!empty_.TryWait()) {
      return false;
    }

    ResourcePtr resource;

    {
      TRACE_EVENT0("flutter", "PipelineProduce");
      resource = producer();
    }

    {
      ftl::MutexLocker lock(&queue_mutex_);
      queue_.emplace(std::move(resource));
    }

    available_.Signal();

    return true;
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

  FTL_DISALLOW_COPY_AND_ASSIGN(Pipeline);
};

}  // namespace flutter

#endif  // SYNCHRONIZATION_PIPELINE_H_
