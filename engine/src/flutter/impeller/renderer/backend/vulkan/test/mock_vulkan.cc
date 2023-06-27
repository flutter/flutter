// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/test/mock_vulkan.h"

namespace impeller {
namespace testing {

namespace {

struct MockCommandBuffer {
  explicit MockCommandBuffer(
      std::shared_ptr<std::vector<std::string>> called_functions)
      : called_functions_(std::move(called_functions)) {}
  std::shared_ptr<std::vector<std::string>> called_functions_;
};

struct MockDevice {
  MockDevice() : called_functions_(new std::vector<std::string>()) {}
  MockCommandBuffer* NewCommandBuffer() {
    std::unique_ptr<MockCommandBuffer> buffer =
        std::make_unique<MockCommandBuffer>(called_functions_);
    MockCommandBuffer* result = buffer.get();
    command_buffers_.emplace_back(std::move(buffer));
    return result;
  }
  std::shared_ptr<std::vector<std::string>> called_functions_;
  std::vector<std::unique_ptr<MockCommandBuffer>> command_buffers_;
};

void noop() {}

VkResult vkEnumerateInstanceExtensionProperties(
    const char* pLayerName,
    uint32_t* pPropertyCount,
    VkExtensionProperties* pProperties) {
  if (!pProperties) {
    *pPropertyCount = 2;

  } else {
    strcpy(pProperties[0].extensionName, "VK_KHR_surface");
    pProperties[0].specVersion = 0;
    strcpy(pProperties[1].extensionName, "VK_MVK_macos_surface");
    pProperties[1].specVersion = 0;
  }
  return VK_SUCCESS;
}

VkResult vkEnumerateInstanceLayerProperties(uint32_t* pPropertyCount,
                                            VkLayerProperties* pProperties) {
  *pPropertyCount = 0;
  return VK_SUCCESS;
}

VkResult vkEnumeratePhysicalDevices(VkInstance instance,
                                    uint32_t* pPhysicalDeviceCount,
                                    VkPhysicalDevice* pPhysicalDevices) {
  if (!pPhysicalDevices) {
    *pPhysicalDeviceCount = 1;
  } else {
    pPhysicalDevices[0] = reinterpret_cast<VkPhysicalDevice>(0xfeedface);
  }
  return VK_SUCCESS;
}

void vkGetPhysicalDeviceFormatProperties(
    VkPhysicalDevice physicalDevice,
    VkFormat format,
    VkFormatProperties* pFormatProperties) {
  if (format == VK_FORMAT_B8G8R8A8_UNORM) {
    pFormatProperties->optimalTilingFeatures =
        static_cast<VkFormatFeatureFlags>(
            vk::FormatFeatureFlagBits::eColorAttachment);
  } else if (format == VK_FORMAT_S8_UINT) {
    pFormatProperties->optimalTilingFeatures =
        static_cast<VkFormatFeatureFlags>(
            vk::FormatFeatureFlagBits::eDepthStencilAttachment);
  }
}

void vkGetPhysicalDeviceProperties(VkPhysicalDevice physicalDevice,
                                   VkPhysicalDeviceProperties* pProperties) {
  pProperties->limits.framebufferColorSampleCounts =
      static_cast<VkSampleCountFlags>(VK_SAMPLE_COUNT_1_BIT |
                                      VK_SAMPLE_COUNT_4_BIT);
  pProperties->limits.maxImageDimension2D = 4096;
}

void vkGetPhysicalDeviceQueueFamilyProperties(
    VkPhysicalDevice physicalDevice,
    uint32_t* pQueueFamilyPropertyCount,
    VkQueueFamilyProperties* pQueueFamilyProperties) {
  if (!pQueueFamilyProperties) {
    *pQueueFamilyPropertyCount = 1;
  } else {
    pQueueFamilyProperties[0].queueCount = 3;
    pQueueFamilyProperties[0].queueFlags = static_cast<VkQueueFlags>(
        VK_QUEUE_TRANSFER_BIT | VK_QUEUE_COMPUTE_BIT | VK_QUEUE_GRAPHICS_BIT);
  }
}

VkResult vkEnumerateDeviceExtensionProperties(
    VkPhysicalDevice physicalDevice,
    const char* pLayerName,
    uint32_t* pPropertyCount,
    VkExtensionProperties* pProperties) {
  if (!pProperties) {
    *pPropertyCount = 1;
  } else {
    strcpy(pProperties[0].extensionName, "VK_KHR_swapchain");
    pProperties[0].specVersion = 0;
  }
  return VK_SUCCESS;
}

VkResult vkCreateDevice(VkPhysicalDevice physicalDevice,
                        const VkDeviceCreateInfo* pCreateInfo,
                        const VkAllocationCallbacks* pAllocator,
                        VkDevice* pDevice) {
  *pDevice = reinterpret_cast<VkDevice>(new MockDevice());
  return VK_SUCCESS;
}

VkResult vkCreateInstance(const VkInstanceCreateInfo* pCreateInfo,
                          const VkAllocationCallbacks* pAllocator,
                          VkInstance* pInstance) {
  *pInstance = reinterpret_cast<VkInstance>(0xbaadf00d);
  return VK_SUCCESS;
}

void vkGetPhysicalDeviceMemoryProperties(
    VkPhysicalDevice physicalDevice,
    VkPhysicalDeviceMemoryProperties* pMemoryProperties) {
  pMemoryProperties->memoryTypeCount = 1;
  pMemoryProperties->memoryTypes[0].heapIndex = 0;
  // pMemoryProperties->memoryTypes[0].propertyFlags =
  //     VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT |
  //     VK_MEMORY_PROPERTY_DEVICE_COHERENT_BIT_AMD;
  pMemoryProperties->memoryHeapCount = 1;
  pMemoryProperties->memoryHeaps[0].size = 1024 * 1024 * 1024;
  pMemoryProperties->memoryHeaps[0].flags = 0;
}

VkResult vkCreatePipelineCache(VkDevice device,
                               const VkPipelineCacheCreateInfo* pCreateInfo,
                               const VkAllocationCallbacks* pAllocator,
                               VkPipelineCache* pPipelineCache) {
  MockDevice* mock_device = reinterpret_cast<MockDevice*>(device);
  mock_device->called_functions_->push_back("vkCreatePipelineCache");
  *pPipelineCache = reinterpret_cast<VkPipelineCache>(0xb000dead);
  return VK_SUCCESS;
}

VkResult vkCreateCommandPool(VkDevice device,
                             const VkCommandPoolCreateInfo* pCreateInfo,
                             const VkAllocationCallbacks* pAllocator,
                             VkCommandPool* pCommandPool) {
  *pCommandPool = reinterpret_cast<VkCommandPool>(0xc0de0001);
  return VK_SUCCESS;
}

VkResult vkAllocateCommandBuffers(
    VkDevice device,
    const VkCommandBufferAllocateInfo* pAllocateInfo,
    VkCommandBuffer* pCommandBuffers) {
  MockDevice* mock_device = reinterpret_cast<MockDevice*>(device);
  *pCommandBuffers =
      reinterpret_cast<VkCommandBuffer>(mock_device->NewCommandBuffer());
  return VK_SUCCESS;
}

VkResult vkBeginCommandBuffer(VkCommandBuffer commandBuffer,
                              const VkCommandBufferBeginInfo* pBeginInfo) {
  return VK_SUCCESS;
}

VkResult vkCreateImage(VkDevice device,
                       const VkImageCreateInfo* pCreateInfo,
                       const VkAllocationCallbacks* pAllocator,
                       VkImage* pImage) {
  *pImage = reinterpret_cast<VkImage>(0xD0D0CACA);
  return VK_SUCCESS;
}

void vkGetImageMemoryRequirements2KHR(
    VkDevice device,
    const VkImageMemoryRequirementsInfo2* pInfo,
    VkMemoryRequirements2* pMemoryRequirements) {
  pMemoryRequirements->memoryRequirements.size = 1024;
  pMemoryRequirements->memoryRequirements.memoryTypeBits = 1;
}

VkResult vkAllocateMemory(VkDevice device,
                          const VkMemoryAllocateInfo* pAllocateInfo,
                          const VkAllocationCallbacks* pAllocator,
                          VkDeviceMemory* pMemory) {
  *pMemory = reinterpret_cast<VkDeviceMemory>(0xCAFEB0BA);
  return VK_SUCCESS;
}

VkResult vkBindImageMemory(VkDevice device,
                           VkImage image,
                           VkDeviceMemory memory,
                           VkDeviceSize memoryOffset) {
  return VK_SUCCESS;
}

VkResult vkCreateImageView(VkDevice device,
                           const VkImageViewCreateInfo* pCreateInfo,
                           const VkAllocationCallbacks* pAllocator,
                           VkImageView* pView) {
  *pView = reinterpret_cast<VkImageView>(0xFEE1DEAD);
  return VK_SUCCESS;
}

VkResult vkCreateBuffer(VkDevice device,
                        const VkBufferCreateInfo* pCreateInfo,
                        const VkAllocationCallbacks* pAllocator,
                        VkBuffer* pBuffer) {
  *pBuffer = reinterpret_cast<VkBuffer>(0xDEADDEAD);
  return VK_SUCCESS;
}

void vkGetBufferMemoryRequirements2KHR(
    VkDevice device,
    const VkBufferMemoryRequirementsInfo2* pInfo,
    VkMemoryRequirements2* pMemoryRequirements) {
  pMemoryRequirements->memoryRequirements.size = 1024;
  pMemoryRequirements->memoryRequirements.memoryTypeBits = 1;
}

VkResult vkBindBufferMemory(VkDevice device,
                            VkBuffer buffer,
                            VkDeviceMemory memory,
                            VkDeviceSize memoryOffset) {
  return VK_SUCCESS;
}

VkResult vkCreateRenderPass(VkDevice device,
                            const VkRenderPassCreateInfo* pCreateInfo,
                            const VkAllocationCallbacks* pAllocator,
                            VkRenderPass* pRenderPass) {
  *pRenderPass = reinterpret_cast<VkRenderPass>(0x12341234);
  return VK_SUCCESS;
}

VkResult vkCreateDescriptorSetLayout(
    VkDevice device,
    const VkDescriptorSetLayoutCreateInfo* pCreateInfo,
    const VkAllocationCallbacks* pAllocator,
    VkDescriptorSetLayout* pSetLayout) {
  *pSetLayout = reinterpret_cast<VkDescriptorSetLayout>(0x77777777);
  return VK_SUCCESS;
}

VkResult vkCreatePipelineLayout(VkDevice device,
                                const VkPipelineLayoutCreateInfo* pCreateInfo,
                                const VkAllocationCallbacks* pAllocator,
                                VkPipelineLayout* pPipelineLayout) {
  *pPipelineLayout = reinterpret_cast<VkPipelineLayout>(0x88888888);
  return VK_SUCCESS;
}

VkResult vkCreateGraphicsPipelines(
    VkDevice device,
    VkPipelineCache pipelineCache,
    uint32_t createInfoCount,
    const VkGraphicsPipelineCreateInfo* pCreateInfos,
    const VkAllocationCallbacks* pAllocator,
    VkPipeline* pPipelines) {
  MockDevice* mock_device = reinterpret_cast<MockDevice*>(device);
  mock_device->called_functions_->push_back("vkCreateGraphicsPipelines");
  *pPipelines = reinterpret_cast<VkPipeline>(0x99999999);
  return VK_SUCCESS;
}

void vkDestroyDevice(VkDevice device, const VkAllocationCallbacks* pAllocator) {
  MockDevice* mock_device = reinterpret_cast<MockDevice*>(device);
  mock_device->called_functions_->push_back("vkDestroyDevice");
  delete reinterpret_cast<MockDevice*>(device);
}

void vkDestroyPipeline(VkDevice device,
                       VkPipeline pipeline,
                       const VkAllocationCallbacks* pAllocator) {
  MockDevice* mock_device = reinterpret_cast<MockDevice*>(device);
  mock_device->called_functions_->push_back("vkDestroyPipeline");
}

VkResult vkCreateShaderModule(VkDevice device,
                              const VkShaderModuleCreateInfo* pCreateInfo,
                              const VkAllocationCallbacks* pAllocator,
                              VkShaderModule* pShaderModule) {
  MockDevice* mock_device = reinterpret_cast<MockDevice*>(device);
  mock_device->called_functions_->push_back("vkCreateShaderModule");
  *pShaderModule = reinterpret_cast<VkShaderModule>(0x11111111);
  return VK_SUCCESS;
}

void vkDestroyShaderModule(VkDevice device,
                           VkShaderModule shaderModule,
                           const VkAllocationCallbacks* pAllocator) {
  MockDevice* mock_device = reinterpret_cast<MockDevice*>(device);
  mock_device->called_functions_->push_back("vkDestroyShaderModule");
}

void vkDestroyPipelineCache(VkDevice device,
                            VkPipelineCache pipelineCache,
                            const VkAllocationCallbacks* pAllocator) {
  MockDevice* mock_device = reinterpret_cast<MockDevice*>(device);
  mock_device->called_functions_->push_back("vkDestroyPipelineCache");
}

void vkCmdBindPipeline(VkCommandBuffer commandBuffer,
                       VkPipelineBindPoint pipelineBindPoint,
                       VkPipeline pipeline) {
  MockCommandBuffer* mock_command_buffer =
      reinterpret_cast<MockCommandBuffer*>(commandBuffer);
  mock_command_buffer->called_functions_->push_back("vkCmdBindPipeline");
}

void vkCmdSetStencilReference(VkCommandBuffer commandBuffer,
                              VkStencilFaceFlags faceMask,
                              uint32_t reference) {
  MockCommandBuffer* mock_command_buffer =
      reinterpret_cast<MockCommandBuffer*>(commandBuffer);
  mock_command_buffer->called_functions_->push_back("vkCmdSetStencilReference");
}

void vkCmdSetScissor(VkCommandBuffer commandBuffer,
                     uint32_t firstScissor,
                     uint32_t scissorCount,
                     const VkRect2D* pScissors) {
  MockCommandBuffer* mock_command_buffer =
      reinterpret_cast<MockCommandBuffer*>(commandBuffer);
  mock_command_buffer->called_functions_->push_back("vkCmdSetScissor");
}

void vkCmdSetViewport(VkCommandBuffer commandBuffer,
                      uint32_t firstViewport,
                      uint32_t viewportCount,
                      const VkViewport* pViewports) {
  MockCommandBuffer* mock_command_buffer =
      reinterpret_cast<MockCommandBuffer*>(commandBuffer);
  mock_command_buffer->called_functions_->push_back("vkCmdSetViewport");
}

PFN_vkVoidFunction GetMockVulkanProcAddress(VkInstance instance,
                                            const char* pName) {
  if (strcmp("vkEnumerateInstanceExtensionProperties", pName) == 0) {
    return (PFN_vkVoidFunction)vkEnumerateInstanceExtensionProperties;
  } else if (strcmp("vkEnumerateInstanceLayerProperties", pName) == 0) {
    return (PFN_vkVoidFunction)vkEnumerateInstanceLayerProperties;
  } else if (strcmp("vkEnumeratePhysicalDevices", pName) == 0) {
    return (PFN_vkVoidFunction)vkEnumeratePhysicalDevices;
  } else if (strcmp("vkGetPhysicalDeviceFormatProperties", pName) == 0) {
    return (PFN_vkVoidFunction)vkGetPhysicalDeviceFormatProperties;
  } else if (strcmp("vkGetPhysicalDeviceProperties", pName) == 0) {
    return (PFN_vkVoidFunction)vkGetPhysicalDeviceProperties;
  } else if (strcmp("vkGetPhysicalDeviceQueueFamilyProperties", pName) == 0) {
    return (PFN_vkVoidFunction)vkGetPhysicalDeviceQueueFamilyProperties;
  } else if (strcmp("vkEnumerateDeviceExtensionProperties", pName) == 0) {
    return (PFN_vkVoidFunction)vkEnumerateDeviceExtensionProperties;
  } else if (strcmp("vkCreateDevice", pName) == 0) {
    return (PFN_vkVoidFunction)vkCreateDevice;
  } else if (strcmp("vkCreateInstance", pName) == 0) {
    return (PFN_vkVoidFunction)vkCreateInstance;
  } else if (strcmp("vkGetPhysicalDeviceMemoryProperties", pName) == 0) {
    return (PFN_vkVoidFunction)vkGetPhysicalDeviceMemoryProperties;
  } else if (strcmp("vkCreatePipelineCache", pName) == 0) {
    return (PFN_vkVoidFunction)vkCreatePipelineCache;
  } else if (strcmp("vkCreateCommandPool", pName) == 0) {
    return (PFN_vkVoidFunction)vkCreateCommandPool;
  } else if (strcmp("vkAllocateCommandBuffers", pName) == 0) {
    return (PFN_vkVoidFunction)vkAllocateCommandBuffers;
  } else if (strcmp("vkBeginCommandBuffer", pName) == 0) {
    return (PFN_vkVoidFunction)vkBeginCommandBuffer;
  } else if (strcmp("vkCreateImage", pName) == 0) {
    return (PFN_vkVoidFunction)vkCreateImage;
  } else if (strcmp("vkGetInstanceProcAddr", pName) == 0) {
    return (PFN_vkVoidFunction)GetMockVulkanProcAddress;
  } else if (strcmp("vkGetDeviceProcAddr", pName) == 0) {
    return (PFN_vkVoidFunction)GetMockVulkanProcAddress;
  } else if (strcmp("vkGetImageMemoryRequirements2KHR", pName) == 0 ||
             strcmp("vkGetImageMemoryRequirements2", pName) == 0) {
    return (PFN_vkVoidFunction)vkGetImageMemoryRequirements2KHR;
  } else if (strcmp("vkAllocateMemory", pName) == 0) {
    return (PFN_vkVoidFunction)vkAllocateMemory;
  } else if (strcmp("vkBindImageMemory", pName) == 0) {
    return (PFN_vkVoidFunction)vkBindImageMemory;
  } else if (strcmp("vkCreateImageView", pName) == 0) {
    return (PFN_vkVoidFunction)vkCreateImageView;
  } else if (strcmp("vkCreateBuffer", pName) == 0) {
    return (PFN_vkVoidFunction)vkCreateBuffer;
  } else if (strcmp("vkGetBufferMemoryRequirements2KHR", pName) == 0 ||
             strcmp("vkGetBufferMemoryRequirements2", pName) == 0) {
    return (PFN_vkVoidFunction)vkGetBufferMemoryRequirements2KHR;
  } else if (strcmp("vkBindBufferMemory", pName) == 0) {
    return (PFN_vkVoidFunction)vkBindBufferMemory;
  } else if (strcmp("vkCreateRenderPass", pName) == 0) {
    return (PFN_vkVoidFunction)vkCreateRenderPass;
  } else if (strcmp("vkCreateDescriptorSetLayout", pName) == 0) {
    return (PFN_vkVoidFunction)vkCreateDescriptorSetLayout;
  } else if (strcmp("vkCreatePipelineLayout", pName) == 0) {
    return (PFN_vkVoidFunction)vkCreatePipelineLayout;
  } else if (strcmp("vkCreateGraphicsPipelines", pName) == 0) {
    return (PFN_vkVoidFunction)vkCreateGraphicsPipelines;
  } else if (strcmp("vkDestroyDevice", pName) == 0) {
    return (PFN_vkVoidFunction)vkDestroyDevice;
  } else if (strcmp("vkDestroyPipeline", pName) == 0) {
    return (PFN_vkVoidFunction)vkDestroyPipeline;
  } else if (strcmp("vkCreateShaderModule", pName) == 0) {
    return (PFN_vkVoidFunction)vkCreateShaderModule;
  } else if (strcmp("vkDestroyShaderModule", pName) == 0) {
    return (PFN_vkVoidFunction)vkDestroyShaderModule;
  } else if (strcmp("vkDestroyPipelineCache", pName) == 0) {
    return (PFN_vkVoidFunction)vkDestroyPipelineCache;
  } else if (strcmp("vkCmdBindPipeline", pName) == 0) {
    return (PFN_vkVoidFunction)vkCmdBindPipeline;
  } else if (strcmp("vkCmdSetStencilReference", pName) == 0) {
    return (PFN_vkVoidFunction)vkCmdSetStencilReference;
  } else if (strcmp("vkCmdSetScissor", pName) == 0) {
    return (PFN_vkVoidFunction)vkCmdSetScissor;
  } else if (strcmp("vkCmdSetViewport", pName) == 0) {
    return (PFN_vkVoidFunction)vkCmdSetViewport;
  }
  return noop;
}

}  // namespace

std::shared_ptr<ContextVK> CreateMockVulkanContext(void) {
  ContextVK::Settings settings;
  auto message_loop = fml::ConcurrentMessageLoop::Create();
  settings.proc_address_callback = GetMockVulkanProcAddress;
  return ContextVK::Create(std::move(settings));
}

std::shared_ptr<std::vector<std::string>> GetMockVulkanFunctions(
    VkDevice device) {
  MockDevice* mock_device = reinterpret_cast<MockDevice*>(device);
  return mock_device->called_functions_;
}

}  // namespace testing
}  // namespace impeller
