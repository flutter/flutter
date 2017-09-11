// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/common/threads.h"
#include "flutter/lib/ui/painting/utils.h"

namespace blink {

namespace {

constexpr fxl::TimeDelta kDrainDelay = fxl::TimeDelta::FromMilliseconds(250);

}  // anonymous namespace

SkiaUnrefQueue::SkiaUnrefQueue()
    : drain_pending_(false) {}

SkiaUnrefQueue SkiaUnrefQueue::instance_;

SkiaUnrefQueue& SkiaUnrefQueue::Get() {
  return instance_;
}

void SkiaUnrefQueue::Unref(SkRefCnt* object) {
  fxl::MutexLocker lock(&mutex_);
  objects_.push_back(object);
  if (!drain_pending_) {
    drain_pending_ = true;
    Threads::IO()->PostDelayedTask([this] { Drain(); },
                                   kDrainDelay);
  }
}

void SkiaUnrefQueue::Drain() {
  std::deque<SkRefCnt*> skia_objects;
  {
    fxl::MutexLocker lock(&mutex_);
    objects_.swap(skia_objects);
    drain_pending_ = false;
  }

  for (SkRefCnt* skia_object : skia_objects) {
    skia_object->unref();
  }
}

}  // namespace blink
