// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/vsync_waiter_embedder.h"

namespace flutter {

VsyncWaiterEmbedder::VsyncWaiterEmbedder(const VsyncCallback& vsync_callback,
                                         flutter::TaskRunners task_runners)
    : VsyncWaiter(std::move(task_runners)), vsync_callback_(vsync_callback) {
  FML_DCHECK(vsync_callback_);
}

VsyncWaiterEmbedder::~VsyncWaiterEmbedder() = default;

// |VsyncWaiter|
void VsyncWaiterEmbedder::AwaitVSync() {
  auto* weak_waiter = new std::weak_ptr<VsyncWaiter>(shared_from_this());
  vsync_callback_(reinterpret_cast<intptr_t>(weak_waiter));
}

// static
bool VsyncWaiterEmbedder::OnEmbedderVsync(intptr_t baton,
                                          fml::TimePoint frame_start_time,
                                          fml::TimePoint frame_target_time) {
  if (baton == 0) {
    return false;
  }

  auto* weak_waiter = reinterpret_cast<std::weak_ptr<VsyncWaiter>*>(baton);
  auto strong_waiter = weak_waiter->lock();
  delete weak_waiter;

  if (!strong_waiter) {
    return false;
  }

  strong_waiter->FireCallback(frame_start_time, frame_target_time);
  return true;
}

}  // namespace flutter
