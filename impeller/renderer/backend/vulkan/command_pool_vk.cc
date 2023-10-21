// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/command_pool_vk.h"

#include <memory>
#include <optional>
#include <utility>

#include "fml/macros.h"
#include "fml/thread_local.h"
#include "fml/trace_event.h"
#include "impeller/renderer/backend/vulkan/resource_manager_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"  // IWYU pragma: keep.
#include "vulkan/vulkan_structs.hpp"

namespace impeller {

// Holds the command pool in a background thread, recyling it when not in use.
class BackgroundCommandPoolVK final {
 public:
  BackgroundCommandPoolVK(BackgroundCommandPoolVK&&) = default;

  explicit BackgroundCommandPoolVK(
      vk::UniqueCommandPool&& pool,
      std::vector<vk::UniqueCommandBuffer>&& buffers,
      std::weak_ptr<CommandPoolRecyclerVK> recycler)
      : pool_(std::move(pool)),
        buffers_(std::move(buffers)),
        recycler_(std::move(recycler)) {}

  ~BackgroundCommandPoolVK() {
    auto const recycler = recycler_.lock();

    // Not only does this prevent recycling when the context is being destroyed,
    // but it also prevents the destructor from effectively being called twice;
    // once for the original BackgroundCommandPoolVK() and once for the moved
    // BackgroundCommandPoolVK().
    if (!recycler) {
      return;
    }
    buffers_.clear();

    recycler->Reclaim(std::move(pool_));
  }

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(BackgroundCommandPoolVK);

  vk::UniqueCommandPool pool_;

  // These are retained because the destructor of the C++ UniqueCommandBuffer
  // wrapper type will attempt to reset the cmd buffer, and doing so may be a
  // thread safety violation as this may happen on the fence waiter thread.
  std::vector<vk::UniqueCommandBuffer> buffers_;
  std::weak_ptr<CommandPoolRecyclerVK> recycler_;
};

CommandPoolVK::~CommandPoolVK() {
  if (!pool_) {
    return;
  }

  auto const context = context_.lock();
  if (!context) {
    return;
  }
  auto const recycler = context->GetCommandPoolRecycler();
  if (!recycler) {
    return;
  }

  auto reset_pool_when_dropped = BackgroundCommandPoolVK(
      std::move(pool_), std::move(collected_buffers_), recycler);

  UniqueResourceVKT<BackgroundCommandPoolVK> pool(
      context->GetResourceManager(), std::move(reset_pool_when_dropped));
}

// TODO(matanlurey): Return a status_or<> instead of {} when we have one.
vk::UniqueCommandBuffer CommandPoolVK::CreateCommandBuffer() {
  auto const context = context_.lock();
  if (!context) {
    return {};
  }

  Lock lock(pool_mutex_);
  if (!pool_) {
    return {};
  }

  auto const device = context->GetDevice();
  vk::CommandBufferAllocateInfo info;
  info.setCommandPool(pool_.get());
  info.setCommandBufferCount(1u);
  info.setLevel(vk::CommandBufferLevel::ePrimary);
  auto [result, buffers] = device.allocateCommandBuffersUnique(info);
  if (result != vk::Result::eSuccess) {
    return {};
  }
  return std::move(buffers[0]);
}

void CommandPoolVK::CollectCommandBuffer(vk::UniqueCommandBuffer&& buffer) {
  Lock lock(pool_mutex_);
  if (!pool_) {
    // If the command pool has already been destroyed, then its buffers have
    // already been freed.
    buffer.release();
    return;
  }
  collected_buffers_.push_back(std::move(buffer));
}

void CommandPoolVK::Destroy() {
  Lock lock(pool_mutex_);
  pool_.reset();

  // When the command pool is destroyed, all of its command buffers are freed.
  // Handles allocated from that pool are now invalid and must be discarded.
  for (auto& buffer : collected_buffers_) {
    buffer.release();
  }
  collected_buffers_.clear();
}

// Associates a resource with a thread and context.
using CommandPoolMap =
    std::unordered_map<uint64_t, std::shared_ptr<CommandPoolVK>>;
FML_THREAD_LOCAL fml::ThreadLocalUniquePtr<CommandPoolMap> tls_command_pool_map;

// Map each context to a list of all thread-local command pools associated
// with that context.
static Mutex g_all_pools_map_mutex;
static std::unordered_map<const ContextVK*,
                          std::vector<std::weak_ptr<CommandPoolVK>>>
    g_all_pools_map IPLR_GUARDED_BY(g_all_pools_map_mutex);

// TODO(matanlurey): Return a status_or<> instead of nullptr when we have one.
std::shared_ptr<CommandPoolVK> CommandPoolRecyclerVK::Get() {
  auto const strong_context = context_.lock();
  if (!strong_context) {
    return nullptr;
  }

  // If there is a resource in used for this thread and context, return it.
  if (!tls_command_pool_map.get()) {
    tls_command_pool_map.reset(new CommandPoolMap());
  }
  CommandPoolMap& pool_map = *tls_command_pool_map.get();
  auto const hash = strong_context->GetHash();
  auto const it = pool_map.find(hash);
  if (it != pool_map.end()) {
    return it->second;
  }

  // Otherwise, create a new resource and return it.
  auto pool = Create();
  if (!pool) {
    return nullptr;
  }

  auto const resource =
      std::make_shared<CommandPoolVK>(std::move(*pool), context_);
  pool_map.emplace(hash, resource);

  {
    Lock all_pools_lock(g_all_pools_map_mutex);
    g_all_pools_map[strong_context.get()].push_back(resource);
  }

  return resource;
}

// TODO(matanlurey): Return a status_or<> instead of nullopt when we have one.
std::optional<vk::UniqueCommandPool> CommandPoolRecyclerVK::Create() {
  // If we can reuse a command pool, do so.
  if (auto pool = Reuse()) {
    return pool;
  }

  // Otherwise, create a new one.
  auto context = context_.lock();
  if (!context) {
    return std::nullopt;
  }
  vk::CommandPoolCreateInfo info;
  info.setQueueFamilyIndex(context->GetGraphicsQueue()->GetIndex().family);
  info.setFlags(vk::CommandPoolCreateFlagBits::eTransient);

  auto device = context->GetDevice();
  auto [result, pool] = device.createCommandPoolUnique(info);
  if (result != vk::Result::eSuccess) {
    return std::nullopt;
  }
  return std::move(pool);
}

std::optional<vk::UniqueCommandPool> CommandPoolRecyclerVK::Reuse() {
  // If there are no recycled pools, return nullopt.
  Lock recycled_lock(recycled_mutex_);
  if (recycled_.empty()) {
    return std::nullopt;
  }

  // Otherwise, remove and return a recycled pool.
  auto pool = std::move(recycled_.back());
  recycled_.pop_back();
  return std::move(pool);
}

void CommandPoolRecyclerVK::Reclaim(vk::UniqueCommandPool&& pool) {
  TRACE_EVENT0("impeller", "ReclaimCommandPool");

  // Reset the pool on a background thread.
  auto strong_context = context_.lock();
  if (!strong_context) {
    return;
  }
  auto device = strong_context->GetDevice();
  device.resetCommandPool(pool.get());

  // Move the pool to the recycled list.
  Lock recycled_lock(recycled_mutex_);
  recycled_.push_back(std::move(pool));
}

CommandPoolRecyclerVK::~CommandPoolRecyclerVK() {
  // Ensure all recycled pools are reclaimed before this is destroyed.
  Dispose();
}

void CommandPoolRecyclerVK::Dispose() {
  CommandPoolMap* pool_map = tls_command_pool_map.get();
  if (pool_map) {
    pool_map->clear();
  }
}

void CommandPoolRecyclerVK::DestroyThreadLocalPools(const ContextVK* context) {
  // Delete the context's entry in this thread's command pool map.
  if (tls_command_pool_map.get()) {
    tls_command_pool_map.get()->erase(context->GetHash());
  }

  // Destroy all other thread-local CommandPoolVK instances associated with
  // this context.
  Lock all_pools_lock(g_all_pools_map_mutex);
  auto found = g_all_pools_map.find(context);
  if (found != g_all_pools_map.end()) {
    for (auto& weak_pool : found->second) {
      auto pool = weak_pool.lock();
      if (!pool) {
        continue;
      }
      // Delete all objects held by this pool.  The destroyed pool will still
      // remain in its thread's TLS map until that thread exits.
      pool->Destroy();
    }
    g_all_pools_map.erase(found);
  }
}

}  // namespace impeller
