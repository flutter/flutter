// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/resource_manager_vk.h"

#include "flutter/fml/thread.h"
#include "flutter/fml/trace_event.h"

namespace impeller {

std::shared_ptr<ResourceManagerVK> ResourceManagerVK::Create() {
  return std::shared_ptr<ResourceManagerVK>(new ResourceManagerVK());
}

ResourceManagerVK::ResourceManagerVK() : waiter_([&]() { Main(); }) {}

ResourceManagerVK::~ResourceManagerVK() {
  Terminate();
  waiter_.join();
}

void ResourceManagerVK::Main() {
  fml::Thread::SetCurrentThreadName(
      fml::Thread::ThreadConfig{"io.flutter.impeller.resource_manager"});

  bool should_exit = false;
  while (!should_exit) {
    std::unique_lock lock(reclaimables_mutex_);

    // Wait until there are reclaimable resource or if the manager should be
    // torn down.
    reclaimables_cv_.wait(
        lock, [&]() { return !reclaimables_.empty() || should_exit_; });

    // Don't reclaim resources when the lock is being held as this may gate
    // further reclaimables from being registered.
    Reclaimables resources_to_collect;
    std::swap(resources_to_collect, reclaimables_);

    // We can't read the ivar outside the lock. Read it here instead.
    should_exit = should_exit_;

    // We know what to collect. Unlock before doing anything else.
    lock.unlock();

    // Claim all resources while tracing.
    {
      TRACE_EVENT0("Impeller", "ReclaimResources");
      resources_to_collect.clear();  // Redundant because of scope but here so
                                     // we can add a trace around it.
    }
  }
}

void ResourceManagerVK::Reclaim(std::unique_ptr<ResourceVK> resource) {
  if (!resource) {
    return;
  }
  {
    std::scoped_lock lock(reclaimables_mutex_);
    reclaimables_.emplace_back(std::move(resource));
  }
  reclaimables_cv_.notify_one();
}

void ResourceManagerVK::Terminate() {
  {
    std::scoped_lock lock(reclaimables_mutex_);
    should_exit_ = true;
  }
  reclaimables_cv_.notify_one();
}

}  // namespace impeller
