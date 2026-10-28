// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_vulkan_snapshot.h"

#include <unistd.h>
#include <limits>
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
// DRM_FORMAT_ABGR8888: bytes R,G,B,A on little-endian Linux. A buffer copy
// provides an explicitly linear layout, so no image modifier assumptions are
// made about the optimal-tiling engine image.
constexpr uint32_t kAbgr8888 = 'A' | ('B' << 8) | ('2' << 16) | ('4' << 24);
}  // namespace

std::shared_ptr<FlVulkanSnapshot> FlVulkanSnapshot::Create(
    const Context& context,
    VkImage source,
    uint32_t width,
    uint32_t height,
    GError** error) {
  auto snapshot =
      std::shared_ptr<FlVulkanSnapshot>(new FlVulkanSnapshot(context));
  auto& self = *snapshot;
  // Align rows for importers without assuming that the image width is aligned.
  const uint64_t stride = (uint64_t(width) * 4 + 255) & ~uint64_t(255);
  if (!width || !height || stride > UINT32_MAX ||
      stride * height > std::numeric_limits<size_t>::max())
    return nullptr;
  const VkDeviceSize length = stride * height;
  auto device = context.device;
#define CALL(name) self.Proc<PFN_vk##name>("vk" #name)
  VkExternalMemoryBufferCreateInfo external = {
      VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_BUFFER_CREATE_INFO};
  external.handleTypes = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT;
  VkBufferCreateInfo info = {VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO};
  info.pNext = &external;
  info.size = length;
  info.usage = VK_BUFFER_USAGE_TRANSFER_DST_BIT;
  if (!Check(CALL(CreateBuffer)(device, &info, nullptr, &self.buffer_),
             "vkCreateBuffer(export)", error))
    return nullptr;
  VkMemoryRequirements requirements;
  CALL(GetBufferMemoryRequirements)(device, self.buffer_, &requirements);
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
  if (memory_type == UINT32_MAX)
    return nullptr;
  VkMemoryDedicatedAllocateInfo dedicated = {
      VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO};
  dedicated.buffer = self.buffer_;
  VkExportMemoryAllocateInfo export_info = {
      VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO};
  export_info.pNext = &dedicated;
  export_info.handleTypes = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT;
  VkMemoryAllocateInfo allocation = {VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO};
  allocation.pNext = &export_info;
  allocation.allocationSize = requirements.size;
  allocation.memoryTypeIndex = memory_type;
  if (!Check(CALL(AllocateMemory)(device, &allocation, nullptr, &self.memory_),
             "vkAllocateMemory(export)", error) ||
      !Check(CALL(BindBufferMemory)(device, self.buffer_, self.memory_, 0),
             "vkBindBufferMemory(export)", error))
    return nullptr;
  VkMemoryGetFdInfoKHR fd_info = {VK_STRUCTURE_TYPE_MEMORY_GET_FD_INFO_KHR};
  fd_info.memory = self.memory_;
  fd_info.handleType = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT;
  if (!Check(CALL(GetMemoryFdKHR)(device, &fd_info, &self.fd_),
             "vkGetMemoryFdKHR", error))
    return nullptr;

  VkCommandPool pool = VK_NULL_HANDLE;
  VkCommandBuffer command = VK_NULL_HANDLE;
  VkFence fence = VK_NULL_HANDLE;
  auto copy = [&]() {
    VkCommandPoolCreateInfo pool_info = {
        VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO};
    pool_info.queueFamilyIndex = context.queue_family;
    pool_info.flags = VK_COMMAND_POOL_CREATE_TRANSIENT_BIT;
    if (!Check(CALL(CreateCommandPool)(device, &pool_info, nullptr, &pool),
               "vkCreateCommandPool", error))
      return false;
    VkCommandBufferAllocateInfo command_info = {
        VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO};
    command_info.commandPool = pool;
    command_info.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    command_info.commandBufferCount = 1;
    if (!Check(CALL(AllocateCommandBuffers)(device, &command_info, &command),
               "vkAllocateCommandBuffers", error))
      return false;
    VkCommandBufferBeginInfo begin = {
        VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};
    begin.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
    if (!Check(CALL(BeginCommandBuffer)(command, &begin),
               "vkBeginCommandBuffer", error))
      return false;
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
    region.bufferRowLength = stride / 4;
    region.imageSubresource = {VK_IMAGE_ASPECT_COLOR_BIT, 0, 0, 1};
    region.imageExtent = {width, height, 1};
    CALL(CmdCopyImageToBuffer)(command, source, image.newLayout, self.buffer_,
                               1, &region);
    image.srcAccessMask = VK_ACCESS_TRANSFER_READ_BIT;
    image.dstAccessMask =
        VK_ACCESS_MEMORY_READ_BIT | VK_ACCESS_MEMORY_WRITE_BIT;
    image.oldLayout = VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
    image.newLayout = VK_IMAGE_LAYOUT_GENERAL;
    CALL(CmdPipelineBarrier)(command, VK_PIPELINE_STAGE_TRANSFER_BIT,
                             VK_PIPELINE_STAGE_ALL_COMMANDS_BIT, 0, 0, nullptr,
                             0, nullptr, 1, &image);
    // Make the copy host-visible for fallback before releasing the buffer to
    // foreign queues (GSK GL/Vulkan or the compositor's scanout device).
    VkBufferMemoryBarrier buffer = {VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER};
    buffer.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
    buffer.dstAccessMask = VK_ACCESS_HOST_READ_BIT;
    buffer.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    buffer.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    buffer.buffer = self.buffer_;
    buffer.size = VK_WHOLE_SIZE;
    CALL(CmdPipelineBarrier)(command, VK_PIPELINE_STAGE_TRANSFER_BIT,
                             VK_PIPELINE_STAGE_HOST_BIT, 0, 0, nullptr, 1,
                             &buffer, 0, nullptr);
    buffer.dstAccessMask = 0;
    buffer.srcQueueFamilyIndex = context.queue_family;
    buffer.dstQueueFamilyIndex = VK_QUEUE_FAMILY_FOREIGN_EXT;
    CALL(CmdPipelineBarrier)(command, VK_PIPELINE_STAGE_TRANSFER_BIT,
                             VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0,
                             nullptr, 1, &buffer, 0, nullptr);
    if (!Check(CALL(EndCommandBuffer)(command), "vkEndCommandBuffer", error))
      return false;
    VkFenceCreateInfo fence_info = {VK_STRUCTURE_TYPE_FENCE_CREATE_INFO};
    if (!Check(CALL(CreateFence)(device, &fence_info, nullptr, &fence),
               "vkCreateFence", error))
      return false;
    VkSubmitInfo submit = {VK_STRUCTURE_TYPE_SUBMIT_INFO};
    submit.commandBufferCount = 1;
    submit.pCommandBuffers = &command;
    if (!Check(context.submit(context.queue, 1, &submit, fence),
               "vkQueueSubmit(export)", error))
      return false;
    // Completion before publication avoids depending on implicit DMA-BUF fence
    // export. This immutable allocation is never reused while GTK retains it.
    return Check(CALL(WaitForFences)(device, 1, &fence, VK_TRUE, UINT64_MAX),
                 "vkWaitForFences(export)", error);
  };
  bool success = copy();
  if (fence)
    CALL(DestroyFence)(device, fence, nullptr);
  if (pool)
    CALL(DestroyCommandPool)(device, pool, nullptr);
  if (!success)
    return nullptr;
  self.descriptor_ = {width,
                      height,
                      kAbgr8888,
                      0,
                      TRUE,
                      1,
                      {{self.fd_, static_cast<guint>(stride), 0}}};
  return snapshot;
#undef CALL
}

FlVulkanSnapshot::~FlVulkanSnapshot() {
  if (fd_ >= 0)
    close(fd_);
  if (buffer_)
    Proc<PFN_vkDestroyBuffer>("vkDestroyBuffer")(context_.device, buffer_,
                                                 nullptr);
  if (memory_)
    Proc<PFN_vkFreeMemory>("vkFreeMemory")(context_.device, memory_, nullptr);
}

GdkTexture* FlVulkanSnapshot::CreateTexture(GdkDisplay* display,
                                            bool* imported,
                                            GError** error) {
  *imported = false;
  if (display && fl_gtk_runtime_dmabuf_format_supported(
                     display, descriptor_.fourcc, descriptor_.modifier)) {
    auto* reference = new std::shared_ptr<FlVulkanSnapshot>(shared_from_this());
    g_autoptr(GError) import_error = nullptr;
    GdkTexture* texture = fl_gtk_runtime_build_dmabuf_texture(
        display, &descriptor_,
        [](gpointer data) {
          delete static_cast<std::shared_ptr<FlVulkanSnapshot>*>(data);
        },
        reference, &import_error);
    if (texture) {
      *imported = true;
      return texture;
    }
    delete reference;
    flutter_linux_gtk4_dbg("vulkan-dmabuf", "import-failed=%s",
                           import_error ? import_error->message : "unknown");
  }
  void* mapped = nullptr;
  size_t length = size_t(descriptor_.planes[0].stride) * descriptor_.height;
  if (!Check(Proc<PFN_vkMapMemory>("vkMapMemory")(context_.device, memory_, 0,
                                                  length, 0, &mapped),
             "vkMapMemory(export fallback)", error))
    return nullptr;
  g_autoptr(GBytes) bytes = g_bytes_new(mapped, length);
  Proc<PFN_vkUnmapMemory>("vkUnmapMemory")(context_.device, memory_);
  return gdk_memory_texture_new(descriptor_.width, descriptor_.height,
                                GDK_MEMORY_R8G8B8A8_PREMULTIPLIED, bytes,
                                descriptor_.planes[0].stride);
}
}  // namespace flutter
