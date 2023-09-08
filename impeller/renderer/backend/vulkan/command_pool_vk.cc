// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/command_pool_vk.h"

#include <map>
#include <unordered_map>
#include <vector>

#include "flutter/fml/thread_local.h"
#include "impeller/base/thread.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"

namespace impeller {

using CommandPoolMap = std::map<uint64_t, std::shared_ptr<CommandPoolVK>>;
FML_THREAD_LOCAL fml::ThreadLocalUniquePtr<CommandPoolMap> tls_command_pool;

static Mutex g_all_pools_mutex;
static std::unordered_map<const ContextVK*,
                          std::vector<std::weak_ptr<CommandPoolVK>>>
    g_all_pools IPLR_GUARDED_BY(g_all_pools_mutex);

std::shared_ptr<CommandPoolVK> CommandPoolVK::GetThreadLocal(
    const ContextVK* context) {
  if (!context) {
    return nullptr;
  }
  if (tls_command_pool.get() == nullptr) {
    tls_command_pool.reset(new CommandPoolMap());
  }
  CommandPoolMap& pool_map = *tls_command_pool.get();
  auto found = pool_map.find(context->GetHash());
  if (found != pool_map.end() && found->second->IsValid()) {
    return found->second;
  }
  auto pool = std::shared_ptr<CommandPoolVK>(new CommandPoolVK(context));
  if (!pool->IsValid()) {
    return nullptr;
  }
  pool_map[context->GetHash()] = pool;
  {
    Lock pool_lock(g_all_pools_mutex);
    g_all_pools[context].push_back(pool);
  }
  return pool;
}

void CommandPoolVK::ClearAllPools(const ContextVK* context) {
  if (tls_command_pool.get()) {
    tls_command_pool.get()->erase(context->GetHash());
  }
  Lock pool_lock(g_all_pools_mutex);
  if (auto found = g_all_pools.find(context); found != g_all_pools.end()) {
    for (auto& weak_pool : found->second) {
      auto pool = weak_pool.lock();
      if (!pool) {
        // The pool has already died because the thread died.
        continue;
      }
      // The pool is reset but its reference in the TLS map remains till the
      // thread dies.
      pool->Reset();
    }
    g_all_pools.erase(found);
  }
}

CommandPoolVK::CommandPoolVK(const ContextVK* context)
    : owner_id_(std::this_thread::get_id()) {
  vk::CommandPoolCreateInfo pool_info;

  pool_info.queueFamilyIndex = context->GetGraphicsQueue()->GetIndex().family;
  pool_info.flags = vk::CommandPoolCreateFlagBits::eTransient |
                    vk::CommandPoolCreateFlagBits::eResetCommandBuffer;
  auto pool = context->GetDevice().createCommandPoolUnique(pool_info);
  if (pool.result != vk::Result::eSuccess) {
    return;
  }

  device_holder_ = context->GetDeviceHolder();
  graphics_pool_ = std::move(pool.value);
  is_valid_ = true;
}

CommandPoolVK::~CommandPoolVK() = default;

bool CommandPoolVK::IsValid() const {
  return is_valid_;
}

void CommandPoolVK::Reset() {
  {
    Lock lock(buffers_to_collect_mutex_);
    graphics_pool_.reset();

    // When the command pool is destroyed, all of its command buffers are freed.
    // Handles allocated from that pool are now invalid and must be discarded.
    for (vk::UniqueCommandBuffer& buffer : buffers_to_collect_) {
      buffer.release();
    }
    buffers_to_collect_.clear();
  }

  for (vk::UniqueCommandBuffer& buffer : recycled_buffers_) {
    buffer.release();
  }
  recycled_buffers_.clear();

  is_valid_ = false;
}

vk::UniqueCommandBuffer CommandPoolVK::CreateGraphicsCommandBuffer() {
  std::shared_ptr<const DeviceHolder> strong_device = device_holder_.lock();
  if (!strong_device) {
    return {};
  }
  FML_DCHECK(std::this_thread::get_id() == owner_id_);
  {
    Lock lock(buffers_to_collect_mutex_);
    GarbageCollectBuffersIfAble();
  }

  if (!recycled_buffers_.empty()) {
    vk::UniqueCommandBuffer result = std::move(recycled_buffers_.back());
    recycled_buffers_.pop_back();
    return result;
  }

  vk::CommandBufferAllocateInfo alloc_info;
  alloc_info.commandPool = graphics_pool_.get();
  alloc_info.commandBufferCount = 1u;
  alloc_info.level = vk::CommandBufferLevel::ePrimary;
  auto [result, buffers] =
      strong_device->GetDevice().allocateCommandBuffersUnique(alloc_info);
  if (result != vk::Result::eSuccess) {
    return {};
  }
  return std::move(buffers[0]);
}

void CommandPoolVK::CollectGraphicsCommandBuffer(
    vk::UniqueCommandBuffer buffer) {
  Lock lock(buffers_to_collect_mutex_);
  if (!graphics_pool_) {
    // If the command pool has already been destroyed, then its command buffers
    // have been freed and are now invalid.
    buffer.release();
  }
  buffers_to_collect_.emplace_back(std::move(buffer));
  GarbageCollectBuffersIfAble();
}

void CommandPoolVK::GarbageCollectBuffersIfAble() {
  if (std::this_thread::get_id() != owner_id_) {
    return;
  }

  for (auto& buffer : buffers_to_collect_) {
    buffer->reset();
    recycled_buffers_.emplace_back(std::move(buffer));
  }

  buffers_to_collect_.clear();
}

}  // namespace impeller
