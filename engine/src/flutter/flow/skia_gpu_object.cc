// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/skia_gpu_object.h"

#include "flutter/fml/message_loop.h"

namespace flow {

SkiaUnrefQueue::SkiaUnrefQueue(fml::RefPtr<fml::TaskRunner> task_runner,
                               fml::TimeDelta delay)
    : task_runner_(std::move(task_runner)),
      drain_delay_(delay),
      drain_pending_(false) {}

SkiaUnrefQueue::~SkiaUnrefQueue() {
  Drain();
}

void SkiaUnrefQueue::Unref(SkRefCnt* object) {
  std::lock_guard<std::mutex> lock(mutex_);
  objects_.push_back(object);
  if (!drain_pending_) {
    drain_pending_ = true;
    task_runner_->PostDelayedTask(
        [strong = fml::Ref(this)]() { strong->Drain(); }, drain_delay_);
  }
}

void SkiaUnrefQueue::Drain() {
  std::deque<SkRefCnt*> skia_objects;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    objects_.swap(skia_objects);
    drain_pending_ = false;
  }

  for (SkRefCnt* skia_object : skia_objects) {
    skia_object->unref();
  }
}

}  // namespace flow
