// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_SKIA_GPU_OBJECT_H_
#define FLUTTER_FLOW_SKIA_GPU_OBJECT_H_

#include <mutex>
#include <queue>

#include "flutter/fml/memory/ref_counted.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/task_runner.h"
#include "third_party/skia/include/core/SkRefCnt.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

namespace flutter {

// A queue that holds Skia objects that must be destructed on the given task
// runner.
class SkiaUnrefQueue : public fml::RefCountedThreadSafe<SkiaUnrefQueue> {
 public:
  void Unref(SkRefCnt* object);

  // Usually, the drain is called automatically. However, during IO manager
  // shutdown (when the platform side reference to the OpenGL context is about
  // to go away), we may need to pre-emptively drain the unref queue. It is the
  // responsibility of the caller to ensure that no further unrefs are queued
  // after this call.
  void Drain();

 private:
  const fml::RefPtr<fml::TaskRunner> task_runner_;
  const fml::TimeDelta drain_delay_;
  std::mutex mutex_;
  std::deque<SkRefCnt*> objects_;
  bool drain_pending_;
  fml::WeakPtr<GrDirectContext> context_;

  // The `GrDirectContext* context` is only used for signaling Skia to
  // performDeferredCleanup. It can be nullptr when such signaling is not needed
  // (e.g., in unit tests).
  SkiaUnrefQueue(fml::RefPtr<fml::TaskRunner> task_runner,
                 fml::TimeDelta delay,
                 fml::WeakPtr<GrDirectContext> context = {});

  ~SkiaUnrefQueue();

  FML_FRIEND_REF_COUNTED_THREAD_SAFE(SkiaUnrefQueue);
  FML_FRIEND_MAKE_REF_COUNTED(SkiaUnrefQueue);
  FML_DISALLOW_COPY_AND_ASSIGN(SkiaUnrefQueue);
};

/// An object whose deallocation needs to be performed on an specific unref
/// queue. The template argument U need to have a call operator that returns
/// that unref queue.
template <class T>
class SkiaGPUObject {
 public:
  using SkiaObjectType = T;

  SkiaGPUObject() = default;
  SkiaGPUObject(sk_sp<SkiaObjectType> object, fml::RefPtr<SkiaUnrefQueue> queue)
      : object_(std::move(object)), queue_(std::move(queue)) {
    FML_DCHECK(object_);
  }
  SkiaGPUObject(SkiaGPUObject&&) = default;
  ~SkiaGPUObject() { reset(); }

  SkiaGPUObject& operator=(SkiaGPUObject&&) = default;

  sk_sp<SkiaObjectType> get() const { return object_; }

  void reset() {
    if (object_ && queue_) {
      queue_->Unref(object_.release());
    }
    queue_ = nullptr;
    FML_DCHECK(object_ == nullptr);
  }

 private:
  sk_sp<SkiaObjectType> object_;
  fml::RefPtr<SkiaUnrefQueue> queue_;

  FML_DISALLOW_COPY_AND_ASSIGN(SkiaGPUObject);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_SKIA_GPU_OBJECT_H_
