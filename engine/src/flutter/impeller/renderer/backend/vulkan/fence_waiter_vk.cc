// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/fence_waiter_vk.h"

#include <chrono>

#include "flutter/fml/thread.h"
#include "flutter/fml/trace_event.h"

namespace impeller {

FenceWaiterVK::FenceWaiterVK(std::weak_ptr<DeviceHolder> device_holder)
    : device_holder_(std::move(device_holder)) {
  waiter_thread_ = std::make_unique<std::thread>([&]() { Main(); });
  is_valid_ = true;
}

FenceWaiterVK::~FenceWaiterVK() {
  Terminate();
  if (waiter_thread_) {
    waiter_thread_->join();
  }
}

bool FenceWaiterVK::IsValid() const {
  return is_valid_;
}

bool FenceWaiterVK::AddFence(vk::UniqueFence fence,
                             const fml::closure& callback) {
  if (!IsValid() || !fence || !callback) {
    return false;
  }
  {
    std::scoped_lock lock(wait_set_mutex_);
    wait_set_[MakeSharedVK(std::move(fence))] = callback;
  }
  wait_set_cv_.notify_one();
  return true;
}

void FenceWaiterVK::Main() {
  fml::Thread::SetCurrentThreadName(
      fml::Thread::ThreadConfig{"io.flutter.impeller.fence_waiter"});

  using namespace std::literals::chrono_literals;

  while (true) {
    std::unique_lock lock(wait_set_mutex_);

    wait_set_cv_.wait(lock, [&]() { return !wait_set_.empty() || terminate_; });

    auto device_holder = device_holder_.lock();
    if (!device_holder) {
      break;
    }

    auto wait_set = TrimAndCreateWaitSetLocked(device_holder);

    lock.unlock();

    if (!wait_set.has_value()) {
      break;
    }
    if (wait_set->empty()) {
      continue;
    }

    auto result = device_holder->GetDevice().waitForFences(
        wait_set->size(),                        // fences count
        wait_set->data(),                        // fences
        false,                                   // wait for all
        std::chrono::nanoseconds{100ms}.count()  // timeout (ns)
    );
    if (!(result == vk::Result::eSuccess || result == vk::Result::eTimeout)) {
      break;
    }
  }
}

std::optional<std::vector<vk::Fence>> FenceWaiterVK::TrimAndCreateWaitSetLocked(
    const std::shared_ptr<DeviceHolder>& device_holder) {
  if (terminate_) {
    return std::nullopt;
  }
  TRACE_EVENT0("impeller", "TrimFences");
  std::vector<vk::Fence> fences;
  fences.reserve(wait_set_.size());
  for (auto it = wait_set_.begin(); it != wait_set_.end();) {
    switch (device_holder->GetDevice().getFenceStatus(it->first->Get())) {
      case vk::Result::eSuccess:  // Signalled.
        it->second();
        it = wait_set_.erase(it);
        break;
      case vk::Result::eNotReady:  // Un-signalled.
        fences.push_back(it->first->Get());
        it++;
        break;
      default:
        return std::nullopt;
    }
  }
  return fences;
}

void FenceWaiterVK::Terminate() {
  {
    std::scoped_lock lock(wait_set_mutex_);
    terminate_ = true;
  }
  wait_set_cv_.notify_one();
}

}  // namespace impeller
