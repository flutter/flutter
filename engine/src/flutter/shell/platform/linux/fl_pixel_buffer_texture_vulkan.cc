// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_pixel_buffer_texture_vulkan.h"

#include <cstring>
#include <limits>

namespace {
bool Check(VkResult result, const char* operation, GError** error) {
  if (result == VK_SUCCESS)
    return true;
  g_set_error(error, g_quark_from_static_string("fl-vulkan-texture-error"),
              result, "%s failed (VkResult %d)", operation, result);
  return false;
}
struct Texture {
  flutter::FlVulkanDeviceContext context;
  VkImage image = VK_NULL_HANDLE;
  VkDeviceMemory memory = VK_NULL_HANDLE;
  template <typename T>
  T Proc(const char* name) {
    return reinterpret_cast<T>(context.get_proc(context.device, name));
  }
  uint32_t MemoryType(uint32_t bits, VkMemoryPropertyFlags flags) {
    for (uint32_t i = 0; i < context.memory.memoryTypeCount; i++) {
      if ((bits & (1u << i)) &&
          (context.memory.memoryTypes[i].propertyFlags & flags) == flags)
        return i;
    }
    return UINT32_MAX;
  }
  ~Texture() {
    if (image)
      Proc<PFN_vkDestroyImage>("vkDestroyImage")(context.device, image,
                                                 nullptr);
    if (memory)
      Proc<PFN_vkFreeMemory>("vkFreeMemory")(context.device, memory, nullptr);
  }
};
}  // namespace

gboolean fl_pixel_buffer_texture_populate_vulkan(
    FlPixelBufferTexture* texture,
    FlVulkanManager* manager,
    uint32_t width,
    uint32_t height,
    FlutterVulkanExternalTexture* output,
    GError** error) {
  auto context = fl_vulkan_manager_get_device_context(manager);
  if (!context.lifetime)
    return FALSE;
  auto* klass = FL_PIXEL_BUFFER_TEXTURE_GET_CLASS(texture);
  const uint8_t* pixels = nullptr;
  if (!klass->copy_pixels ||
      !klass->copy_pixels(texture, &pixels, &width, &height, error))
    return FALSE;
  // Reject dimensions before issuing any Vulkan allocation.
  if (!pixels || !width || !height || width > context.max_image_dimension ||
      height > context.max_image_dimension ||
      uint64_t(width) * height > std::numeric_limits<size_t>::max() / 4)
    return FALSE;
  auto image = std::make_unique<Texture>();
  image->context = context;
  auto device = context.device;
#define CALL(name) image->Proc<PFN_vk##name>("vk" #name)
  VkImageCreateInfo image_info = {VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO};
  image_info.imageType = VK_IMAGE_TYPE_2D;
  image_info.format = VK_FORMAT_R8G8B8A8_UNORM;
  image_info.extent = {width, height, 1};
  image_info.mipLevels = 1;
  image_info.arrayLayers = 1;
  image_info.samples = VK_SAMPLE_COUNT_1_BIT;
  image_info.tiling = VK_IMAGE_TILING_OPTIMAL;
  image_info.usage =
      VK_IMAGE_USAGE_SAMPLED_BIT | VK_IMAGE_USAGE_TRANSFER_DST_BIT;
  if (!Check(CALL(CreateImage)(device, &image_info, nullptr, &image->image),
             "vkCreateImage(texture)", error))
    return FALSE;
  VkMemoryRequirements requirements;
  CALL(GetImageMemoryRequirements)(device, image->image, &requirements);
  VkMemoryAllocateInfo allocation = {VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO};
  allocation.allocationSize = requirements.size;
  allocation.memoryTypeIndex = image->MemoryType(
      requirements.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
  if (allocation.memoryTypeIndex == UINT32_MAX ||
      !Check(CALL(AllocateMemory)(device, &allocation, nullptr, &image->memory),
             "vkAllocateMemory(texture)", error) ||
      !Check(CALL(BindImageMemory)(device, image->image, image->memory, 0),
             "vkBindImageMemory(texture)", error))
    return FALSE;
  const VkDeviceSize length = VkDeviceSize(width) * height * 4;
  VkBuffer buffer = VK_NULL_HANDLE;
  VkDeviceMemory staging = VK_NULL_HANDLE;
  VkCommandPool pool = VK_NULL_HANDLE;
  VkFence fence = VK_NULL_HANDLE;
  auto upload = [&]() {
    VkBufferCreateInfo buffer_info = {VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO};
    buffer_info.size = length;
    buffer_info.usage = VK_BUFFER_USAGE_TRANSFER_SRC_BIT;
    if (!Check(CALL(CreateBuffer)(device, &buffer_info, nullptr, &buffer),
               "vkCreateBuffer(texture)", error))
      return false;
    CALL(GetBufferMemoryRequirements)(device, buffer, &requirements);
    allocation.allocationSize = requirements.size;
    allocation.memoryTypeIndex = image->MemoryType(
        requirements.memoryTypeBits, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
                                         VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
    if (allocation.memoryTypeIndex == UINT32_MAX ||
        !Check(CALL(AllocateMemory)(device, &allocation, nullptr, &staging),
               "vkAllocateMemory(staging)", error) ||
        !Check(CALL(BindBufferMemory)(device, buffer, staging, 0),
               "vkBindBufferMemory(staging)", error))
      return false;
    void* mapped = nullptr;
    if (!Check(CALL(MapMemory)(device, staging, 0, length, 0, &mapped),
               "vkMapMemory(staging)", error))
      return false;
    memcpy(mapped, pixels, length);
    CALL(UnmapMemory)(device, staging);
    VkCommandPoolCreateInfo pool_info = {
        VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO};
    pool_info.queueFamilyIndex = context.queue_family;
    pool_info.flags = VK_COMMAND_POOL_CREATE_TRANSIENT_BIT;
    if (!Check(CALL(CreateCommandPool)(device, &pool_info, nullptr, &pool),
               "vkCreateCommandPool(texture)", error))
      return false;
    VkCommandBufferAllocateInfo command_info = {
        VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO};
    command_info.commandPool = pool;
    command_info.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    command_info.commandBufferCount = 1;
    VkCommandBuffer command;
    if (!Check(CALL(AllocateCommandBuffers)(device, &command_info, &command),
               "vkAllocateCommandBuffers(texture)", error))
      return false;
    VkCommandBufferBeginInfo begin = {
        VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};
    begin.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
    if (!Check(CALL(BeginCommandBuffer)(command, &begin),
               "vkBeginCommandBuffer(texture)", error))
      return false;
    VkImageMemoryBarrier barrier = {VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER};
    barrier.dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
    barrier.oldLayout = VK_IMAGE_LAYOUT_UNDEFINED;
    barrier.newLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
    barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier.image = image->image;
    barrier.subresourceRange = {VK_IMAGE_ASPECT_COLOR_BIT, 0, 1, 0, 1};
    CALL(CmdPipelineBarrier)(command, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
                             VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, nullptr, 0,
                             nullptr, 1, &barrier);
    VkBufferImageCopy region = {};
    region.imageSubresource = {VK_IMAGE_ASPECT_COLOR_BIT, 0, 0, 1};
    region.imageExtent = {width, height, 1};
    CALL(CmdCopyBufferToImage)(command, buffer, image->image,
                               VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1,
                               &region);
    barrier.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
    barrier.dstAccessMask = VK_ACCESS_SHADER_READ_BIT;
    barrier.oldLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
    barrier.newLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
    CALL(CmdPipelineBarrier)(command, VK_PIPELINE_STAGE_TRANSFER_BIT,
                             VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0, 0,
                             nullptr, 0, nullptr, 1, &barrier);
    if (!Check(CALL(EndCommandBuffer)(command), "vkEndCommandBuffer(texture)",
               error))
      return false;
    VkFenceCreateInfo fence_info = {VK_STRUCTURE_TYPE_FENCE_CREATE_INFO};
    if (!Check(CALL(CreateFence)(device, &fence_info, nullptr, &fence),
               "vkCreateFence(texture)", error))
      return false;
    VkSubmitInfo submit = {VK_STRUCTURE_TYPE_SUBMIT_INFO};
    submit.commandBufferCount = 1;
    submit.pCommandBuffers = &command;
    if (!Check(context.submit(context.queue, 1, &submit, fence),
               "vkQueueSubmit(texture)", error))
      return false;
    return Check(CALL(WaitForFences)(device, 1, &fence, VK_TRUE, UINT64_MAX),
                 "vkWaitForFences(texture)", error);
  };
  bool success = upload();
  if (fence)
    CALL(DestroyFence)(device, fence, nullptr);
  if (pool)
    CALL(DestroyCommandPool)(device, pool, nullptr);
  if (buffer)
    CALL(DestroyBuffer)(device, buffer, nullptr);
  if (staging)
    CALL(FreeMemory)(device, staging, nullptr);
  if (!success)
    return FALSE;
  *output = {sizeof(*output),
             reinterpret_cast<uint64_t>(image->image),
             VK_FORMAT_R8G8B8A8_UNORM,
             image.get(),
             [](void* data) { delete static_cast<Texture*>(data); },
             width,
             height};
  image.release();
  return TRUE;
#undef CALL
}
