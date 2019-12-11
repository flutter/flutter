// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/skia_gpu_object.h"

#include "flutter/fml/message_loop.h"
#include "flutter/fml/trace_event.h"

namespace flutter {

SkiaUnrefQueue::SkiaUnrefQueue(fml::RefPtr<fml::TaskRunner> task_runner,
                               fml::TimeDelta delay,
                               fml::WeakPtr<GrContext> context)
    : task_runner_(std::move(task_runner)),
      drain_delay_(delay),
      drain_pending_(false),
      context_(context) {}

SkiaUnrefQueue::~SkiaUnrefQueue() {
  FML_DCHECK(objects_.empty());
}

void SkiaUnrefQueue::Unref(SkRefCnt* object) {
  std::scoped_lock lock(mutex_);
  objects_.push_back(object);
  if (!drain_pending_) {
    drain_pending_ = true;
    task_runner_->PostDelayedTask(
        [strong = fml::Ref(this)]() { strong->Drain(); }, drain_delay_);
  }
}

void SkiaUnrefQueue::Drain() {
  TRACE_EVENT0("flutter", "SkiaUnrefQueue::Drain");
  std::deque<SkRefCnt*> skia_objects;
  {
    std::scoped_lock lock(mutex_);
    objects_.swap(skia_objects);
    drain_pending_ = false;
  }

  for (SkRefCnt* skia_object : skia_objects) {
    skia_object->unref();
  }

  if (context_ && skia_objects.size() > 0) {
    context_->performDeferredCleanup(std::chrono::milliseconds(0));
  }
}

}  // namespace flutter
