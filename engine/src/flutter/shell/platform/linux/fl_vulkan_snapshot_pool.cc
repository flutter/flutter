// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_vulkan_snapshot_pool.h"

#include <gio/gio.h>
#include <poll.h>
#include <unistd.h>

#include <limits>

#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/linux/fl_linux_gtk4_debug.h"

namespace flutter {
namespace {
bool Check(VkResult result, const char* operation, GError** error) {
  if (result == VK_SUCCESS)
    return true;
  g_set_error(error, g_quark_from_static_string("fl-vulkan-snapshot-error"),
              result, "%s failed (VkResult %d)", operation, result);
  return false;
}
constexpr uint32_t kAbgr8888 = 'A' | ('B' << 8) | ('2' << 16) | ('4' << 24);
}  // namespace

FlVulkanSnapshotBuffer::FlVulkanSnapshotBuffer(
    const FlVulkanDeviceContext& context)
    : context(context) {}

bool FlVulkanSnapshotBuffer::Initialize(uint32_t width,
                                        uint32_t height,
                                        GError** error) {
  TRACE_EVENT0("flutter", "VulkanSnapshotAllocate");
  const uint64_t stride = (uint64_t(width) * 4 + 255) & ~uint64_t(255);
  if (!width || !height || width > context.max_image_dimension ||
      height > context.max_image_dimension || stride > UINT32_MAX ||
      stride * height > std::numeric_limits<size_t>::max()) {
    g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT,
                        "Invalid Vulkan snapshot dimensions");
    return false;
  }
  const VkDeviceSize length = stride * height;
  auto device = context.device;
#define CALL(name) Proc<PFN_vk##name>("vk" #name)
  VkExternalMemoryBufferCreateInfo external = {
      VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_BUFFER_CREATE_INFO};
  external.handleTypes = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT;
  VkBufferCreateInfo info = {VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO};
  info.pNext = &external;
  info.size = length;
  info.usage = VK_BUFFER_USAGE_TRANSFER_DST_BIT;
  if (!Check(CALL(CreateBuffer)(device, &info, nullptr, &buffer),
             "vkCreateBuffer(export)", error))
    return false;
  VkMemoryRequirements requirements;
  CALL(GetBufferMemoryRequirements)(device, buffer, &requirements);
  uint32_t memory_type = UINT32_MAX;
  // Host accessibility guarantees a fallback even if GTK rejects import after
  // the engine has reused its source image. Prefer device-local memory too.
  for (VkMemoryPropertyFlags flags :
       {VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
            VK_MEMORY_PROPERTY_HOST_COHERENT_BIT |
            VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
        VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
            VK_MEMORY_PROPERTY_HOST_COHERENT_BIT}) {
    for (uint32_t i = 0; i < context.memory.memoryTypeCount; i++) {
      if ((requirements.memoryTypeBits & (1u << i)) &&
          (context.memory.memoryTypes[i].propertyFlags & flags) == flags) {
        memory_type = i;
        break;
      }
    }
    if (memory_type != UINT32_MAX)
      break;
  }
  if (memory_type == UINT32_MAX) {
    g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED,
                        "No coherent DMA-BUF export memory");
    return false;
  }
  VkMemoryDedicatedAllocateInfo dedicated = {
      VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO};
  dedicated.buffer = buffer;
  VkExportMemoryAllocateInfo export_info = {
      VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO};
  export_info.pNext = &dedicated;
  export_info.handleTypes = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT;
  VkMemoryAllocateInfo allocation = {VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO};
  allocation.pNext = &export_info;
  allocation.allocationSize = requirements.size;
  allocation.memoryTypeIndex = memory_type;
  if (!Check(CALL(AllocateMemory)(device, &allocation, nullptr, &memory),
             "vkAllocateMemory(export)", error) ||
      !Check(CALL(BindBufferMemory)(device, buffer, memory, 0),
             "vkBindBufferMemory(export)", error))
    return false;
  allocation_size = requirements.size;
  VkMemoryGetFdInfoKHR fd_info = {VK_STRUCTURE_TYPE_MEMORY_GET_FD_INFO_KHR};
  fd_info.memory = memory;
  fd_info.handleType = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT;
  if (!Check(CALL(GetMemoryFdKHR)(device, &fd_info, &fd), "vkGetMemoryFdKHR",
             error))
    return false;

  VkCommandPoolCreateInfo pool_info = {
      VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO};
  pool_info.queueFamilyIndex = context.queue_family;
  pool_info.flags = VK_COMMAND_POOL_CREATE_TRANSIENT_BIT;
  if (!Check(
          CALL(CreateCommandPool)(device, &pool_info, nullptr, &command_pool),
          "vkCreateCommandPool", error))
    return false;
  VkCommandBufferAllocateInfo command_info = {
      VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO};
  command_info.commandPool = command_pool;
  command_info.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
  command_info.commandBufferCount = 1;
  if (!Check(CALL(AllocateCommandBuffers)(device, &command_info, &command),
             "vkAllocateCommandBuffers", error))
    return false;
  VkFenceCreateInfo fence_info = {VK_STRUCTURE_TYPE_FENCE_CREATE_INFO};
  if (!Check(CALL(CreateFence)(device, &fence_info, nullptr, &fence),
             "vkCreateFence", error))
    return false;
  descriptor = {width,
                height,
                kAbgr8888,
                0,
                TRUE,
                1,
                {{fd, static_cast<guint>(stride), 0}}};
  return true;
}

bool FlVulkanSnapshotBuffer::Copy(VkImage source, GError** error) {
  TRACE_EVENT0("flutter", "VulkanSnapshotCopy");
  auto device = context.device;
  const auto width = descriptor.width;
  const auto height = descriptor.height;
  if (!Check(CALL(ResetCommandPool)(device, command_pool, 0),
             "vkResetCommandPool", error) ||
      !Check(CALL(ResetFences)(device, 1, &fence), "vkResetFences", error))
    return false;
  VkCommandBufferBeginInfo begin = {
      VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};
  begin.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
  if (!Check(CALL(BeginCommandBuffer)(command, &begin), "vkBeginCommandBuffer",
             error))
    return false;
  // GTK has released every texture lease. Reacquire foreign queue ownership
  // before overwriting an allocation published by a previous frame.
  if (foreign_owned) {
    VkBufferMemoryBarrier acquire = {VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER};
    acquire.dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
    acquire.srcQueueFamilyIndex = VK_QUEUE_FAMILY_FOREIGN_EXT;
    acquire.dstQueueFamilyIndex = context.queue_family;
    acquire.buffer = buffer;
    acquire.size = VK_WHOLE_SIZE;
    CALL(CmdPipelineBarrier)(command, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
                             VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, nullptr, 1,
                             &acquire, 0, nullptr);
  }
  VkImageMemoryBarrier image = {VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER};
  image.srcAccessMask = VK_ACCESS_MEMORY_WRITE_BIT;
  image.dstAccessMask = VK_ACCESS_TRANSFER_READ_BIT;
  image.oldLayout = VK_IMAGE_LAYOUT_GENERAL;
  image.newLayout = VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
  image.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
  image.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
  image.image = source;
  image.subresourceRange = {VK_IMAGE_ASPECT_COLOR_BIT, 0, 1, 0, 1};
  CALL(CmdPipelineBarrier)(command, VK_PIPELINE_STAGE_ALL_COMMANDS_BIT,
                           VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, nullptr, 0,
                           nullptr, 1, &image);
  VkBufferImageCopy region = {};
  region.bufferRowLength = descriptor.planes[0].stride / 4;
  region.imageSubresource = {VK_IMAGE_ASPECT_COLOR_BIT, 0, 0, 1};
  region.imageExtent = {width, height, 1};
  CALL(CmdCopyImageToBuffer)(command, source, image.newLayout, buffer, 1,
                             &region);
  image.srcAccessMask = VK_ACCESS_TRANSFER_READ_BIT;
  image.dstAccessMask = VK_ACCESS_MEMORY_READ_BIT | VK_ACCESS_MEMORY_WRITE_BIT;
  image.oldLayout = VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
  image.newLayout = VK_IMAGE_LAYOUT_GENERAL;
  CALL(CmdPipelineBarrier)(command, VK_PIPELINE_STAGE_TRANSFER_BIT,
                           VK_PIPELINE_STAGE_ALL_COMMANDS_BIT, 0, 0, nullptr, 0,
                           nullptr, 1, &image);
  // Make the copy host-visible for fallback before releasing the buffer to
  // foreign queues (GSK GL/Vulkan or the compositor's scanout device).
  VkBufferMemoryBarrier visibility = {VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER};
  visibility.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
  visibility.dstAccessMask = VK_ACCESS_HOST_READ_BIT;
  visibility.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
  visibility.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
  visibility.buffer = buffer;
  visibility.size = VK_WHOLE_SIZE;
  CALL(CmdPipelineBarrier)(command, VK_PIPELINE_STAGE_TRANSFER_BIT,
                           VK_PIPELINE_STAGE_HOST_BIT, 0, 0, nullptr, 1,
                           &visibility, 0, nullptr);
  visibility.dstAccessMask = 0;
  visibility.srcQueueFamilyIndex = context.queue_family;
  visibility.dstQueueFamilyIndex = VK_QUEUE_FAMILY_FOREIGN_EXT;
  CALL(CmdPipelineBarrier)(command, VK_PIPELINE_STAGE_TRANSFER_BIT,
                           VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0, nullptr,
                           1, &visibility, 0, nullptr);
  if (!Check(CALL(EndCommandBuffer)(command), "vkEndCommandBuffer", error))
    return false;

  VkSubmitInfo submit = {VK_STRUCTURE_TYPE_SUBMIT_INFO};
  submit.commandBufferCount = 1;
  submit.pCommandBuffers = &command;
  if (!Check(context.submit(context.queue, 1, &submit, fence),
             "vkQueueSubmit(export)", error))
    return false;
  // Host completion remains mandatory before publication and source reuse.
  // On a wait error, quiesce the queue before retiring the command resources.
  VkResult result;
  {
    TRACE_EVENT0("flutter", "VulkanSnapshotFenceWait");
    result = CALL(WaitForFences)(device, 1, &fence, VK_TRUE, UINT64_MAX);
  }
  if (!Check(result, "vkWaitForFences(export)", error)) {
    CALL(QueueWaitIdle)(context.queue);
    return false;
  }
  foreign_owned = true;
  return true;
}

FlVulkanSnapshotBuffer::~FlVulkanSnapshotBuffer() {
  auto device = context.device;
  if (fence)
    CALL(DestroyFence)(device, fence, nullptr);
  if (command_pool)
    CALL(DestroyCommandPool)(device, command_pool, nullptr);
  if (fd >= 0)
    close(fd);
  if (buffer)
    CALL(DestroyBuffer)(device, buffer, nullptr);
  if (memory)
    CALL(FreeMemory)(device, memory, nullptr);
}
#undef CALL

FlVulkanSnapshotPool::FlVulkanSnapshotPool(const FlVulkanDeviceContext& context,
                                           size_t capacity)
    : context_(context), capacity_(capacity) {}

std::shared_ptr<FlVulkanSnapshotPool> FlVulkanSnapshotPool::Create(
    const FlVulkanDeviceContext& context,
    size_t capacity) {
  return std::shared_ptr<FlVulkanSnapshotPool>(
      new FlVulkanSnapshotPool(context, capacity),
      [](FlVulkanSnapshotPool* pool) {
        // The last lease can disappear inside GTK's texture release callback.
        // Keep final Vulkan cleanup off that callback and independent of engine
        // task runners, which may already have been destroyed.
        g_autoptr(GTask) task = g_task_new(nullptr, nullptr, nullptr, nullptr);
        g_task_set_task_data(task, pool, nullptr);
        g_task_run_in_thread(
            task, [](GTask* task, gpointer, gpointer data, GCancellable*) {
              delete static_cast<FlVulkanSnapshotPool*>(data);
              g_task_return_boolean(task, TRUE);
            });
      });
}

std::shared_ptr<FlVulkanSnapshotBuffer> FlVulkanSnapshotPool::Copy(
    VkImage source,
    uint32_t width,
    uint32_t height,
    GError** error) {
  FlVulkanSnapshotBuffer* buffer = nullptr;
  std::vector<std::unique_ptr<FlVulkanSnapshotBuffer>> retired;
  {
    std::scoped_lock lock(mutex_);
    for (auto it = slots_.begin(); it != slots_.end();) {
      auto* slot = it->get();
      if (!slot->busy && (!slot->healthy || slot->descriptor.width != width ||
                          slot->descriptor.height != height)) {
        retired.push_back(std::move(*it));
        it = slots_.erase(it);
        continue;
      }
      if (!buffer && !slot->busy) {
        // Texture release is the lifetime boundary. Also avoid overwriting a
        // DMA-BUF with outstanding implicit reader fences; never block here.
        pollfd descriptor = {slot->fd, POLLOUT, 0};
        if (poll(&descriptor, 1, 0) == 1 && (descriptor.revents & POLLOUT) &&
            !(descriptor.revents & (POLLERR | POLLNVAL))) {
          buffer = slot;
          slot->busy = true;
          stats_.reuses++;
          if (stats_.reuses % 120 == 0) {
            flutter_linux_gtk4_dbg(
                "vulkan-snapshot-pool",
                "slots=%zu allocations=%zu reuses=%zu exhausted=%zu",
                slots_.size(), stats_.allocations, stats_.reuses,
                stats_.exhaustions);
          }
        }
      }
      ++it;
    }
    if (!buffer && slots_.size() >= capacity_) {
      stats_.exhaustions++;
      g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_WOULD_BLOCK,
                          "Vulkan snapshot pool is busy");
      return nullptr;
    }
  }
  // Retire obsolete sizes on the raster thread, outside the release mutex.
  retired.clear();
  if (!buffer) {
    auto allocation = std::make_unique<FlVulkanSnapshotBuffer>(context_);
    if (!allocation->Initialize(width, height, error))
      return nullptr;
    buffer = allocation.get();
    std::scoped_lock lock(mutex_);
    slots_.push_back(std::move(allocation));
    stats_.allocations++;
    flutter_linux_gtk4_dbg("vulkan-snapshot-pool",
                           "allocate slots=%zu total=%zu", slots_.size(),
                           stats_.allocations);
  }
  std::shared_ptr<FlVulkanSnapshotBuffer> lease(
      buffer, [pool = shared_from_this()](FlVulkanSnapshotBuffer* buffer) {
        pool->Release(buffer);
      });
  if (!buffer->Copy(source, error)) {
    buffer->healthy = false;
    return nullptr;
  }
  return lease;
}

void FlVulkanSnapshotPool::Release(FlVulkanSnapshotBuffer* buffer) {
  std::scoped_lock lock(mutex_);
  buffer->busy = false;
}

FlVulkanSnapshotPool::Stats FlVulkanSnapshotPool::stats() const {
  std::scoped_lock lock(mutex_);
  auto result = stats_;
  result.slots = slots_.size();
  for (const auto& slot : slots_)
    result.memory_bytes += slot->allocation_size;
  return result;
}

FlVulkanSnapshotPool::~FlVulkanSnapshotPool() {
  flutter_linux_gtk4_dbg("vulkan-snapshot-pool",
                         "destroy allocations=%zu reuses=%zu exhausted=%zu",
                         stats_.allocations, stats_.reuses, stats_.exhaustions);
}
}  // namespace flutter
