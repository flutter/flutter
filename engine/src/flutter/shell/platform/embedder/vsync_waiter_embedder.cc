// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/vsync_waiter_embedder.h"

#include <limits>
#include <map>
#include <mutex>

namespace flutter {
namespace {
struct PendingBaton {
  const VsyncWaiterEmbedder* owner;
  std::weak_ptr<VsyncWaiter> waiter;
};
struct BatonRegistry {
  std::mutex mutex;
  intptr_t next = 0;
  std::map<intptr_t, PendingBaton> pending;
};
BatonRegistry& Registry() {
  static BatonRegistry registry;
  return registry;
}
}  // namespace

VsyncWaiterEmbedder::VsyncWaiterEmbedder(
    const VsyncCallback& vsync_callback,
    const flutter::TaskRunners& task_runners)
    : VsyncWaiter(task_runners), vsync_callback_(vsync_callback) {
  FML_DCHECK(vsync_callback_);
}

VsyncWaiterEmbedder::~VsyncWaiterEmbedder() {
  auto& registry = Registry();
  std::scoped_lock lock(registry.mutex);
  for (auto it = registry.pending.begin(); it != registry.pending.end();) {
    if (it->second.owner == this) {
      it = registry.pending.erase(it);
    } else {
      ++it;
    }
  }
}

// |VsyncWaiter|
void VsyncWaiterEmbedder::AwaitVSync() {
  auto& registry = Registry();
  intptr_t baton;
  {
    std::scoped_lock lock(registry.mutex);
    // Never recycle an opaque token: a delayed callback must not reach a new
    // waiter whose allocation happens to reuse the same address.
    FML_CHECK(registry.next < std::numeric_limits<intptr_t>::max());
    baton = ++registry.next;
    registry.pending.emplace(baton, PendingBaton{this, shared_from_this()});
  }
  vsync_callback_(baton);
}

// static
bool VsyncWaiterEmbedder::OnEmbedderVsync(
    const flutter::TaskRunners& task_runners,
    intptr_t baton,
    fml::TimePoint frame_start_time,
    fml::TimePoint frame_target_time) {
  std::weak_ptr<VsyncWaiter> waiter;
  {
    auto& registry = Registry();
    std::scoped_lock lock(registry.mutex);
    auto found = registry.pending.find(baton);
    if (found == registry.pending.end()) {
      return false;
    }
    waiter = std::move(found->second.waiter);
    registry.pending.erase(found);
  }

  // If the time here is in the future, the contract for `FlutterEngineOnVsync`
  // says that the engine will only process the frame when the time becomes
  // current.
  task_runners.GetUITaskRunner()->PostTaskForTime(
      [frame_start_time, frame_target_time, waiter = std::move(waiter)]() {
        // Ownership is in the closure, including when shutdown discards it.
        auto vsync_waiter = waiter.lock();
        if (vsync_waiter) {
          vsync_waiter->FireCallback(frame_start_time, frame_target_time);
        }
      },
      frame_start_time);

  return true;
}

}  // namespace flutter
