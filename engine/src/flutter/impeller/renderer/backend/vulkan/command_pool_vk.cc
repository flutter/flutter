// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/command_pool_vk.h"

#include <memory>
#include <optional>
#include <utility>

#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/resource_manager_vk.h"

#include "impeller/renderer/backend/vulkan/vk.h"  // IWYU pragma: keep.
#include "vulkan/vulkan_enums.hpp"
#include "vulkan/vulkan_handles.hpp"
#include "vulkan/vulkan_structs.hpp"

namespace impeller {

// Holds the command pool in a background thread, recycling it when not in use.
class BackgroundCommandPoolVK final {
 public:
  BackgroundCommandPoolVK(BackgroundCommandPoolVK&&) = default;

  // The recycler also recycles command buffers that were never used, up to a
  // limit of 16 per frame. This number was somewhat arbitrarily chosen.
  static constexpr size_t kUnusedCommandBufferLimit = 16u;

  explicit BackgroundCommandPoolVK(
      vk::UniqueCommandPool&& pool,
      std::vector<vk::UniqueCommandBuffer>&& buffers,
      size_t unused_count,
      std::weak_ptr<CommandPoolRecyclerVK> recycler)
      : pool_(std::move(pool)),
        buffers_(std::move(buffers)),
        unused_count_(unused_count),
        recycler_(std::move(recycler)) {}

  ~BackgroundCommandPoolVK() {
    auto const recycler = recycler_.lock();

    // Not only does this prevent recycling when the context is being destroyed,
    // but it also prevents the destructor from effectively being called twice;
    // once for the original BackgroundCommandPoolVK() and once for the moved
    // BackgroundCommandPoolVK().
    if (!recycler) {
      // Context is dying - release Vulkan handles without making API calls.
      // The VkDevice may already be destroyed; calling vkFreeCommandBuffers
      // or vkDestroyCommandPool with stale handles causes validation errors
      // (VUID-vkFreeCommandBuffers-commandPool-parameter).
      for (auto& buffer : buffers_) {
        buffer.release();
      }
      pool_.release();
      return;
    }
    // If there are many unused command buffers, release some of them and
    // trim the command pool.
    bool should_trim = unused_count_ > kUnusedCommandBufferLimit;
    recycler->Reclaim(std::move(pool_), std::move(buffers_),
                      /*should_trim=*/should_trim);
  }

 private:
  BackgroundCommandPoolVK(const BackgroundCommandPoolVK&) = delete;

  BackgroundCommandPoolVK& operator=(const BackgroundCommandPoolVK&) = delete;

  vk::UniqueCommandPool pool_;

  // These are retained because the destructor of the C++ UniqueCommandBuffer
  // wrapper type will attempt to reset the cmd buffer, and doing so may be a
  // thread safety violation as this may happen on the fence waiter thread.
  std::vector<vk::UniqueCommandBuffer> buffers_;
  const size_t unused_count_;
  std::weak_ptr<CommandPoolRecyclerVK> recycler_;
};

CommandPoolVK::~CommandPoolVK() {
  if (!pool_) {
    return;
  }

  auto const context = context_.lock();
  if (!context) {
    // Context is dying - release Vulkan handles without making API calls.
    for (auto& buffer : collected_buffers_) {
      buffer.release();
    }
    for (auto& buffer : unused_command_buffers_) {
      buffer.release();
    }
    pool_.release();
    return;
  }
  auto const recycler = context->GetCommandPoolRecycler();
  if (!recycler) {
    for (auto& buffer : collected_buffers_) {
      buffer.release();
    }
    for (auto& buffer : unused_command_buffers_) {
      buffer.release();
    }
    pool_.release();
    return;
  }
  // Any unused command buffers are added to the set of used command buffers.
  // both will be reset to the initial state when the pool is reset.
  size_t unused_count = unused_command_buffers_.size();
  for (auto i = 0u; i < unused_command_buffers_.size(); i++) {
    collected_buffers_.push_back(std::move(unused_command_buffers_[i]));
  }
  unused_command_buffers_.clear();

  auto reset_pool_when_dropped = BackgroundCommandPoolVK(
      std::move(pool_), std::move(collected_buffers_), unused_count, recycler);

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
  if (!unused_command_buffers_.empty()) {
    vk::UniqueCommandBuffer buffer = std::move(unused_command_buffers_.back());
    unused_command_buffers_.pop_back();
    return buffer;
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
  for (auto& buffer : unused_command_buffers_) {
    buffer.release();
  }
  unused_command_buffers_.clear();
  collected_buffers_.clear();
}

void CommandPoolVK::AbandonForDriverCrash() {
  Lock lock(pool_mutex_);
  if (!pool_) {
    return;
  }
  // The AMD driver non-conformantly frees the VkCommandPool and its child
  // VkCommandBuffer handles internally when vkQueueSubmit returns
  // VK_ERROR_OUT_OF_HOST_MEMORY. Calling vkDestroyCommandPool or
  // vkFreeCommandBuffers on these already-invalid handles causes validation
  // layer errors and an access-violation crash inside the driver. Release
  // the C++ ownership handles without invoking any Vulkan destroy/free calls.
  pool_.release();
  for (auto& buffer : collected_buffers_) {
    buffer.release();
  }
  for (auto& buffer : unused_command_buffers_) {
    buffer.release();
  }
  unused_command_buffers_.clear();
  collected_buffers_.clear();
}

// Associates a resource with a thread and context.
using CommandPoolMap =
    std::unordered_map<uint64_t, std::shared_ptr<CommandPoolVK>>;

// CommandPoolVK Lifecycle:
// 1. End of frame will reset the command pool (clearing this on a thread).
//    There will still be references to the command pool from the uncompleted
//    command buffers.
// 2. The last reference to the command pool will be released from the fence
//    waiter thread, which will schedule a task on the resource
//    manager thread, which in turn will reset the command pool and make it
//    available for reuse ("recycle").
static thread_local std::unique_ptr<CommandPoolMap> tls_command_pool_map;

// Map each context to a list of all thread-local command pools associated
// with that context.
static Mutex g_all_pools_map_mutex;
static std::unordered_map<
    uint64_t,
    std::unordered_map<std::thread::id, std::weak_ptr<CommandPoolVK>>>
    g_all_pools_map IPLR_GUARDED_BY(g_all_pools_map_mutex);

CommandPoolRecyclerVK::CommandPoolRecyclerVK(
    const std::shared_ptr<ContextVK>& context)
    : context_(context), context_hash_(context->GetHash()) {}

// Visible for testing.
// Returns the number of pools in g_all_pools_map for the given context.
int CommandPoolRecyclerVK::GetGlobalPoolCount(const ContextVK& context) {
  Lock all_pools_lock(g_all_pools_map_mutex);
  auto it = g_all_pools_map.find(context.GetHash());
  return it != g_all_pools_map.end() ? it->second.size() : 0;
}

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
  auto const it = pool_map.find(context_hash_);
  if (it != pool_map.end()) {
    return it->second;
  }

  // Otherwise, create a new resource and return it.
  auto data = Create();
  if (!data || !data->pool) {
    return nullptr;
  }

  auto const resource = std::make_shared<CommandPoolVK>(
      std::move(data->pool), std::move(data->buffers), context_);
  pool_map.emplace(context_hash_, resource);

  {
    Lock all_pools_lock(g_all_pools_map_mutex);
    g_all_pools_map[context_hash_][std::this_thread::get_id()] = resource;
  }

  return resource;
}

// TODO(matanlurey): Return a status_or<> instead of nullopt when we have one.
std::optional<CommandPoolRecyclerVK::RecycledData>
CommandPoolRecyclerVK::Create() {
  // If we can reuse a command pool and its buffers, do so.
  if (auto data = Reuse()) {
    return data;
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
  return CommandPoolRecyclerVK::RecycledData{.pool = std::move(pool),
                                             .buffers = {}};
}

std::optional<CommandPoolRecyclerVK::RecycledData>
CommandPoolRecyclerVK::Reuse() {
  // If there are no recycled pools, return nullopt.
  Lock recycled_lock(recycled_mutex_);
  if (recycled_.empty()) {
    return std::nullopt;
  }

  // Otherwise, remove and return a recycled pool.
  auto data = std::move(recycled_.back());
  recycled_.pop_back();
  return std::move(data);
}

void CommandPoolRecyclerVK::Reclaim(
    vk::UniqueCommandPool&& pool,
    std::vector<vk::UniqueCommandBuffer>&& buffers,
    bool should_trim) {
  // Reset the pool on a background thread.
  auto strong_context = context_.lock();
  if (!strong_context) {
    // Release all handles to prevent RAII from calling vk API with dead device.
    for (auto& buf : buffers) {
      buf.release();
    }
    pool.release();
    return;
  }
  auto device = strong_context->GetDevice();
  vk::CommandPoolResetFlags flags;
  if (should_trim) {
    flags = vk::CommandPoolResetFlagBits::eReleaseResources;
  }
  // Release buffer handles BEFORE resetCommandPool. resetCommandPool
  // implicitly returns all allocated command buffers to the pool, making
  // the old VkCommandBuffer handles invalid. Letting RAII call
  // vkFreeCommandBuffers on them afterwards is redundant at best and
  // dangerous at worst (stale-handle use).
  for (auto& buf : buffers) {
    buf.release();
  }
  buffers.clear();
  const auto result = device.resetCommandPool(pool.get(), flags);
  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not reset command pool: " << vk::to_string(result);
  }

  // Move the pool to the recycled list, capping at 8 to prevent unbounded
  // host memory growth. Without a cap, heavy workloads (text rendering
  // stress) can accumulate dozens of recycled pools, each consuming
  // significant driver-internal memory.
  Lock recycled_lock(recycled_mutex_);
  static constexpr size_t kMaxRecycledCommandPools = 8;
  while (recycled_.size() >= kMaxRecycledCommandPools) {
    auto& old = recycled_.front();
    // Explicitly release buffer handles BEFORE destroying pool to prevent
    // vkFreeCommandBuffers from using a potentially-stale pool handle.
    // After resetCommandPool the buffers are already returned to the pool,
    // so vkFreeCommandBuffers is redundant. Skipping it avoids a window
    // where the pool handle could be reused by the driver.
    for (auto& buf : old.buffers) {
      buf.release();
    }
    old.buffers.clear();
    recycled_.erase(recycled_.begin());
  }
  recycled_.push_back(
      RecycledData{.pool = std::move(pool), .buffers = std::move(buffers)});
}

void CommandPoolRecyclerVK::Dispose() {
  CommandPoolMap* pool_map = tls_command_pool_map.get();
  if (pool_map) {
    pool_map->erase(context_hash_);
  }

  {
    Lock all_pools_lock(g_all_pools_map_mutex);
    auto found = g_all_pools_map.find(context_hash_);
    if (found != g_all_pools_map.end()) {
      found->second.erase(std::this_thread::get_id());
    }
  }
}

void CommandPoolRecyclerVK::DestroyThreadLocalPools() {
  // Delete the context's entry in this thread's command pool map.
  if (tls_command_pool_map.get()) {
    tls_command_pool_map.get()->erase(context_hash_);
  }

  // Destroy all other thread-local CommandPoolVK instances associated with
  // this context.
  Lock all_pools_lock(g_all_pools_map_mutex);
  auto found = g_all_pools_map.find(context_hash_);
  if (found != g_all_pools_map.end()) {
    for (auto& [thread_id, weak_pool] : found->second) {
      auto pool = weak_pool.lock();
      if (!pool) {
        continue;
      }
      // Delete all objects held by this pool. The destroyed pool will still
      // remain in its thread's TLS map until that thread exits.
      pool->Destroy();
    }
    g_all_pools_map.erase(found);
  }
}

}  // namespace impeller
