// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_vulkan_manager.h"
#include "flutter/shell/platform/linux/fl_linux_gtk4_debug.h"

#include <dlfcn.h>
#define VK_NO_PROTOTYPES
#include <vulkan/vulkan.h>

#include <cmath>
#include <cstring>
#include <limits>
#include <map>
#include <memory>
#include <mutex>
#include <vector>

namespace {

GQuark error_quark() {
  return g_quark_from_static_string("fl-vulkan-error");
}

bool check(VkResult result, const char* operation, GError** error) {
  if (result == VK_SUCCESS) {
    return true;
  }
  g_set_error(error, error_quark(), result, "%s failed (VkResult %d)",
              operation, result);
  return false;
}

// Resolver callbacks have no user data once passed through Vulkan's own
// vkGet*ProcAddr functions. Keep the loader resident and synchronize all queues
// registered by this backend. This also covers multiple engines in one process.
struct Loader {
  void* module = dlopen("libvulkan.so.1", RTLD_NOW | RTLD_LOCAL);
  PFN_vkGetInstanceProcAddr instance_proc = nullptr;
  PFN_vkGetDeviceProcAddr device_proc = nullptr;
  Loader() {
    if (module != nullptr) {
      instance_proc = reinterpret_cast<PFN_vkGetInstanceProcAddr>(
          dlsym(module, "vkGetInstanceProcAddr"));
      device_proc = reinterpret_cast<PFN_vkGetDeviceProcAddr>(
          dlsym(module, "vkGetDeviceProcAddr"));
    }
  }
};

Loader& loader() {
  static Loader value;
  return value;
}

struct QueueFunctions {
  PFN_vkQueueSubmit submit;
  PFN_vkQueueWaitIdle wait_idle;
};
std::mutex queue_mutex;
std::map<VkQueue, QueueFunctions> queues;
std::map<VkDevice, PFN_vkDeviceWaitIdle> device_wait_functions;

VKAPI_ATTR VkResult VKAPI_CALL device_wait_idle(VkDevice device) {
  std::lock_guard<std::mutex> lock(queue_mutex);
  auto it = device_wait_functions.find(device);
  return it == device_wait_functions.end() ? VK_ERROR_INITIALIZATION_FAILED
                                           : it->second(device);
}

VKAPI_ATTR VkResult VKAPI_CALL queue_submit(VkQueue queue,
                                            uint32_t count,
                                            const VkSubmitInfo* submits,
                                            VkFence fence) {
  std::lock_guard<std::mutex> lock(queue_mutex);
  auto it = queues.find(queue);
  return it == queues.end() ? VK_ERROR_INITIALIZATION_FAILED
                            : it->second.submit(queue, count, submits, fence);
}

VKAPI_ATTR VkResult VKAPI_CALL queue_wait_idle(VkQueue queue) {
  std::lock_guard<std::mutex> lock(queue_mutex);
  auto it = queues.find(queue);
  return it == queues.end() ? VK_ERROR_INITIALIZATION_FAILED
                            : it->second.wait_idle(queue);
}

VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL instance_proc(VkInstance instance,
                                                       const char* name);
VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL device_proc(VkDevice device,
                                                     const char* name);

PFN_vkVoidFunction intercept(const char* name) {
  if (strcmp(name, "vkGetInstanceProcAddr") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(instance_proc);
  }
  if (strcmp(name, "vkGetDeviceProcAddr") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(device_proc);
  }
  if (strcmp(name, "vkDeviceWaitIdle") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(device_wait_idle);
  }
  if (strcmp(name, "vkQueueSubmit") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(queue_submit);
  }
  if (strcmp(name, "vkQueueWaitIdle") == 0) {
    return reinterpret_cast<PFN_vkVoidFunction>(queue_wait_idle);
  }
  return nullptr;
}

VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL instance_proc(VkInstance instance,
                                                       const char* name) {
  auto replacement = intercept(name);
  return replacement != nullptr ? replacement
                                : loader().instance_proc(instance, name);
}

VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL device_proc(VkDevice device,
                                                     const char* name) {
  auto replacement = intercept(name);
  return replacement != nullptr ? replacement
                                : loader().device_proc(device, name);
}

// Only enable extensions whose features are enabled below. Impeller infers its
// feature chain from the extension list supplied in the embedder configuration.
const char* instance_extensions[] = {VK_KHR_SURFACE_EXTENSION_NAME,
                                     "VK_KHR_wayland_surface"};
const char* device_extensions[] = {VK_KHR_SWAPCHAIN_EXTENSION_NAME};

#define DEVICE_FUNCTIONS(F)      \
  F(DestroyDevice)               \
  F(CreateImage)                 \
  F(DestroyImage)                \
  F(GetImageMemoryRequirements)  \
  F(AllocateMemory)              \
  F(FreeMemory)                  \
  F(BindImageMemory)             \
  F(CreateBuffer)                \
  F(DestroyBuffer)               \
  F(GetBufferMemoryRequirements) \
  F(BindBufferMemory)            \
  F(MapMemory)                   \
  F(UnmapMemory)                 \
  F(CreateCommandPool)           \
  F(DestroyCommandPool)          \
  F(AllocateCommandBuffers)      \
  F(FreeCommandBuffers)          \
  F(BeginCommandBuffer)          \
  F(EndCommandBuffer)            \
  F(CmdPipelineBarrier)          \
  F(CmdCopyImageToBuffer)        \
  F(CreateFence)                 \
  F(DestroyFence)                \
  F(WaitForFences)

struct State {
  VkInstance instance = VK_NULL_HANDLE;
  VkPhysicalDevice physical_device = VK_NULL_HANDLE;
  VkDevice device = VK_NULL_HANDLE;
  VkQueue queue = VK_NULL_HANDLE;
  uint32_t queue_family = 0;
  VkPhysicalDeviceMemoryProperties memory_properties = {};
  VkCommandPool command_pool = VK_NULL_HANDLE;
#define DECLARE(name) PFN_vk##name name = nullptr;
  DEVICE_FUNCTIONS(DECLARE)
#undef DECLARE
  ~State() {
    if (device != VK_NULL_HANDLE) {
      queue_wait_idle(queue);
      if (command_pool != VK_NULL_HANDLE) {
        DestroyCommandPool(device, command_pool, nullptr);
      }
      {
        std::lock_guard<std::mutex> lock(queue_mutex);
        queues.erase(queue);
        device_wait_functions.erase(device);
      }
      DestroyDevice(device, nullptr);
    }
    if (instance != VK_NULL_HANDLE) {
      auto destroy = reinterpret_cast<PFN_vkDestroyInstance>(
          loader().instance_proc(instance, "vkDestroyInstance"));
      destroy(instance, nullptr);
    }
  }

  uint32_t memory_type(uint32_t bits, VkMemoryPropertyFlags flags) const {
    for (uint32_t i = 0; i < memory_properties.memoryTypeCount; i++) {
      if ((bits & (1u << i)) &&
          (memory_properties.memoryTypes[i].propertyFlags & flags) == flags) {
        return i;
      }
    }
    return UINT32_MAX;
  }
};

struct Frame {
  std::shared_ptr<State> state;
  VkImage image = VK_NULL_HANDLE;
  VkDeviceMemory memory = VK_NULL_HANDLE;
  FlutterVulkanImage flutter_image = {};
  uint32_t width = 0;
  uint32_t height = 0;
  ~Frame() {
    // Collection happens after the engine releases the render target. Readback
    // finishes before presentation returns, so GTK never retains this image.
    if (image != VK_NULL_HANDLE) {
      state->DestroyImage(state->device, image, nullptr);
    }
    if (memory != VK_NULL_HANDLE) {
      state->FreeMemory(state->device, memory, nullptr);
    }
  }
};

bool initialize(State& state, GError** error) {
  if (loader().instance_proc == nullptr || loader().device_proc == nullptr) {
    g_set_error_literal(error, error_quark(), 0, "Vulkan loader unavailable");
    return false;
  }
  auto create_instance = reinterpret_cast<PFN_vkCreateInstance>(
      loader().instance_proc(nullptr, "vkCreateInstance"));
  VkApplicationInfo app = {VK_STRUCTURE_TYPE_APPLICATION_INFO};
  app.pApplicationName = "Flutter GTK4";
  app.apiVersion = VK_API_VERSION_1_1;
  VkInstanceCreateInfo info = {VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO};
  info.pApplicationInfo = &app;
  info.enabledExtensionCount = G_N_ELEMENTS(instance_extensions);
  info.ppEnabledExtensionNames = instance_extensions;
  if (!check(create_instance(&info, nullptr, &state.instance),
             "vkCreateInstance (Vulkan 1.1)", error)) {
    return false;
  }
#define INSTANCE(name)                        \
  auto name = reinterpret_cast<PFN_vk##name>( \
      loader().instance_proc(state.instance, "vk" #name))
  INSTANCE(EnumeratePhysicalDevices);
  INSTANCE(GetPhysicalDeviceProperties);
  INSTANCE(GetPhysicalDeviceQueueFamilyProperties);
  INSTANCE(GetPhysicalDeviceFeatures2);
  INSTANCE(GetPhysicalDeviceMemoryProperties);
  INSTANCE(CreateDevice);
  uint32_t count = 0;
  if (!check(EnumeratePhysicalDevices(state.instance, &count, nullptr),
             "vkEnumeratePhysicalDevices", error)) {
    return false;
  }
  std::vector<VkPhysicalDevice> devices(count);
  if (!check(EnumeratePhysicalDevices(state.instance, &count, devices.data()),
             "vkEnumeratePhysicalDevices", error)) {
    return false;
  }
  // Prefer hardware; the loader's order breaks ties. A compute-capable graphics
  // queue is mandatory because Flutter GPU dispatches through this same queue.
  int best_score = -1;
  for (auto physical : devices) {
    VkPhysicalDeviceProperties properties;
    GetPhysicalDeviceProperties(physical, &properties);
    if (properties.apiVersion < VK_API_VERSION_1_1) {
      continue;
    }
    uint32_t families = 0;
    GetPhysicalDeviceQueueFamilyProperties(physical, &families, nullptr);
    std::vector<VkQueueFamilyProperties> queue_properties(families);
    GetPhysicalDeviceQueueFamilyProperties(physical, &families,
                                           queue_properties.data());
    for (uint32_t i = 0; i < families; i++) {
      const auto required = VK_QUEUE_GRAPHICS_BIT | VK_QUEUE_COMPUTE_BIT;
      if (queue_properties[i].queueCount == 0 ||
          (queue_properties[i].queueFlags & required) != required) {
        continue;
      }
      int score = properties.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU
                      ? 2
                  : properties.deviceType == VK_PHYSICAL_DEVICE_TYPE_CPU ? 0
                                                                         : 1;
      if (score > best_score) {
        state.physical_device = physical;
        state.queue_family = i;
        best_score = score;
      }
    }
  }
  if (state.physical_device == VK_NULL_HANDLE) {
    g_set_error_literal(error, error_quark(), 0,
                        "No Vulkan 1.1 graphics/compute device available");
    return false;
  }
  VkPhysicalDeviceProperties selected_properties;
  GetPhysicalDeviceProperties(state.physical_device, &selected_properties);
  flutter_linux_gtk4_dbg(
      "vulkan-device", "name=%s type=%u api=%u", selected_properties.deviceName,
      selected_properties.deviceType, selected_properties.apiVersion);
  VkPhysicalDevice16BitStorageFeatures storage = {
      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_16BIT_STORAGE_FEATURES};
  VkPhysicalDeviceFeatures2 features = {
      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2};
  features.pNext = &storage;
  GetPhysicalDeviceFeatures2(state.physical_device, &features);
  // Match CapabilitiesVK::GetEnabledDeviceFeatures. No optional device
  // extensions are advertised, so their feature structures must stay absent.
  VkPhysicalDeviceFeatures enabled = {};
  enabled.fillModeNonSolid = features.features.fillModeNonSolid;
  enabled.samplerAnisotropy = features.features.samplerAnisotropy;
  enabled.textureCompressionETC2 = features.features.textureCompressionETC2;
  enabled.textureCompressionASTC_LDR =
      features.features.textureCompressionASTC_LDR;
  enabled.textureCompressionBC = features.features.textureCompressionBC;
  VkPhysicalDevice16BitStorageFeatures enabled_storage = {
      VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_16BIT_STORAGE_FEATURES};
  enabled_storage.uniformAndStorageBuffer16BitAccess =
      storage.uniformAndStorageBuffer16BitAccess;
  float priority = 1.0f;
  VkDeviceQueueCreateInfo queue_info = {
      VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO};
  queue_info.queueFamilyIndex = state.queue_family;
  queue_info.queueCount = 1;
  queue_info.pQueuePriorities = &priority;
  VkDeviceCreateInfo device_info = {VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO};
  device_info.pNext = &enabled_storage;
  device_info.pEnabledFeatures = &enabled;
  device_info.queueCreateInfoCount = 1;
  device_info.pQueueCreateInfos = &queue_info;
  device_info.enabledExtensionCount = G_N_ELEMENTS(device_extensions);
  device_info.ppEnabledExtensionNames = device_extensions;
  if (!check(CreateDevice(state.physical_device, &device_info, nullptr,
                          &state.device),
             "vkCreateDevice", error)) {
    return false;
  }
#define LOAD(name)                                     \
  state.name = reinterpret_cast<PFN_vk##name>(         \
      loader().device_proc(state.device, "vk" #name)); \
  g_assert(state.name != nullptr);
  DEVICE_FUNCTIONS(LOAD)
#undef LOAD
  auto get_queue = reinterpret_cast<PFN_vkGetDeviceQueue>(
      loader().device_proc(state.device, "vkGetDeviceQueue"));
  get_queue(state.device, state.queue_family, 0, &state.queue);
  {
    std::lock_guard<std::mutex> lock(queue_mutex);
    device_wait_functions[state.device] =
        reinterpret_cast<PFN_vkDeviceWaitIdle>(
            loader().device_proc(state.device, "vkDeviceWaitIdle"));
    queues[state.queue] = {
        reinterpret_cast<PFN_vkQueueSubmit>(
            loader().device_proc(state.device, "vkQueueSubmit")),
        reinterpret_cast<PFN_vkQueueWaitIdle>(
            loader().device_proc(state.device, "vkQueueWaitIdle"))};
  }
  GetPhysicalDeviceMemoryProperties(state.physical_device,
                                    &state.memory_properties);
  VkCommandPoolCreateInfo pool = {VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO};
  pool.queueFamilyIndex = state.queue_family;
  pool.flags = VK_COMMAND_POOL_CREATE_TRANSIENT_BIT;
  return check(state.CreateCommandPool(state.device, &pool, nullptr,
                                       &state.command_pool),
               "vkCreateCommandPool", error);
#undef INSTANCE
}
}  // namespace

struct _FlVulkanManager {
  GObject parent_instance;
  std::shared_ptr<State>* state;
};

G_DEFINE_TYPE(FlVulkanManager, fl_vulkan_manager, G_TYPE_OBJECT)

static void fl_vulkan_manager_finalize(GObject* object) {
  auto* self = FL_VULKAN_MANAGER(object);
  delete self->state;
  G_OBJECT_CLASS(fl_vulkan_manager_parent_class)->finalize(object);
}

static void fl_vulkan_manager_class_init(FlVulkanManagerClass* klass) {
  G_OBJECT_CLASS(klass)->finalize = fl_vulkan_manager_finalize;
}

static void fl_vulkan_manager_init(FlVulkanManager* self) {
  self->state = new std::shared_ptr<State>();
}

FlVulkanManager* fl_vulkan_manager_new() {
  return FL_VULKAN_MANAGER(g_object_new(fl_vulkan_manager_get_type(), nullptr));
}

gboolean fl_vulkan_manager_initialize(FlVulkanManager* self,
                                      FlutterVulkanRendererConfig* config,
                                      GError** error) {
  g_return_val_if_fail(FL_IS_VULKAN_MANAGER(self), FALSE);
  if (!*self->state) {
    auto state = std::make_shared<State>();
    if (!initialize(*state, error)) {
      return FALSE;
    }
    *self->state = std::move(state);
  }
  auto& state = **self->state;
  *config = {};
  config->struct_size = sizeof(*config);
  config->version = VK_API_VERSION_1_1;
  config->instance = state.instance;
  config->physical_device = state.physical_device;
  config->device = state.device;
  config->queue = state.queue;
  config->queue_family_index = state.queue_family;
  config->enabled_instance_extension_count = G_N_ELEMENTS(instance_extensions);
  config->enabled_instance_extensions = instance_extensions;
  config->enabled_device_extension_count = G_N_ELEMENTS(device_extensions);
  config->enabled_device_extensions = device_extensions;
  config->get_instance_proc_address_callback =
      [](void*, FlutterVulkanInstanceHandle instance,
         const char* name) -> void* {
    return reinterpret_cast<void*>(
        instance_proc(static_cast<VkInstance>(instance), name));
  };
  // The compositor owns presentation; these callbacks are required by the
  // embedder configuration but must never acquire or present a second image.
  config->get_next_image_callback = [](void*, const FlutterFrameInfo*) {
    return FlutterVulkanImage{sizeof(FlutterVulkanImage), 0, 0};
  };
  config->present_image_callback = [](void*, const FlutterVulkanImage*) {
    return false;
  };
  return TRUE;
}

gboolean fl_vulkan_manager_create_backing_store(
    FlVulkanManager* self,
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store) {
  g_return_val_if_fail(FL_IS_VULKAN_MANAGER(self), FALSE);
  const double width = config->size.width;
  const double height = config->size.height;
  if (!*self->state || !std::isfinite(width) || !std::isfinite(height) ||
      width < 1 || height < 1 || width > INT32_MAX || height > INT32_MAX ||
      width != floor(width) || height != floor(height) ||
      width * height > std::numeric_limits<size_t>::max() / 4) {
    return FALSE;
  }
  auto frame = std::make_unique<Frame>();
  frame->state = *self->state;
  frame->width = width;
  frame->height = height;
  auto& state = *frame->state;
  VkImageCreateInfo info = {VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO};
  info.imageType = VK_IMAGE_TYPE_2D;
  info.format = VK_FORMAT_R8G8B8A8_UNORM;
  info.extent = {frame->width, frame->height, 1};
  info.mipLevels = 1;
  info.arrayLayers = 1;
  info.samples = VK_SAMPLE_COUNT_1_BIT;
  info.tiling = VK_IMAGE_TILING_OPTIMAL;
  info.usage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT |
               VK_IMAGE_USAGE_SAMPLED_BIT | VK_IMAGE_USAGE_TRANSFER_SRC_BIT |
               VK_IMAGE_USAGE_TRANSFER_DST_BIT;
  if (state.CreateImage(state.device, &info, nullptr, &frame->image) !=
      VK_SUCCESS) {
    return FALSE;
  }
  VkMemoryRequirements requirements;
  state.GetImageMemoryRequirements(state.device, frame->image, &requirements);
  VkMemoryAllocateInfo allocation = {VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO};
  allocation.allocationSize = requirements.size;
  allocation.memoryTypeIndex = state.memory_type(
      requirements.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
  if (allocation.memoryTypeIndex == UINT32_MAX ||
      state.AllocateMemory(state.device, &allocation, nullptr,
                           &frame->memory) != VK_SUCCESS ||
      state.BindImageMemory(state.device, frame->image, frame->memory, 0) !=
          VK_SUCCESS) {
    return FALSE;
  }
  frame->flutter_image = {sizeof(FlutterVulkanImage),
                          reinterpret_cast<uint64_t>(frame->image),
                          VK_FORMAT_R8G8B8A8_UNORM};
  backing_store->type = kFlutterBackingStoreTypeVulkan;
  backing_store->vulkan.struct_size = sizeof(FlutterVulkanBackingStore);
  backing_store->vulkan.image = &frame->flutter_image;
  backing_store->vulkan.user_data = frame.release();
  backing_store->vulkan.destruction_callback = [](void*) {
    // The compositor collection callback owns the allocation.
  };
  return TRUE;
}

void fl_vulkan_manager_collect_backing_store(const FlutterBackingStore* store) {
  delete static_cast<Frame*>(store->vulkan.user_data);
}

GBytes* fl_vulkan_backing_store_read_pixels(const FlutterBackingStore* store,
                                            size_t* width,
                                            size_t* height,
                                            GError** error) {
  auto* frame = static_cast<Frame*>(store->vulkan.user_data);
  auto& s = *frame->state;
  const size_t length = static_cast<size_t>(frame->width) * frame->height * 4;
  VkBuffer buffer = VK_NULL_HANDLE;
  VkDeviceMemory memory = VK_NULL_HANDLE;
  VkCommandBuffer command = VK_NULL_HANDLE;
  VkFence fence = VK_NULL_HANDLE;
  GBytes* bytes = nullptr;
  // Readback and its command pool are raster-thread-only. The queue itself is
  // shared with engine worker threads, so submissions use the injected lock.
  auto run = [&]() -> bool {
    VkBufferCreateInfo buffer_info = {VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO};
    buffer_info.size = length;
    buffer_info.usage = VK_BUFFER_USAGE_TRANSFER_DST_BIT;
    if (!check(s.CreateBuffer(s.device, &buffer_info, nullptr, &buffer),
               "vkCreateBuffer", error))
      return false;
    VkMemoryRequirements requirements;
    s.GetBufferMemoryRequirements(s.device, buffer, &requirements);
    VkMemoryAllocateInfo allocation = {VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO};
    allocation.allocationSize = requirements.size;
    allocation.memoryTypeIndex = s.memory_type(
        requirements.memoryTypeBits, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
                                         VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
    if (allocation.memoryTypeIndex == UINT32_MAX) {
      g_set_error_literal(error, error_quark(), 0,
                          "No coherent readback memory");
      return false;
    }
    if (!check(s.AllocateMemory(s.device, &allocation, nullptr, &memory),
               "vkAllocateMemory", error) ||
        !check(s.BindBufferMemory(s.device, buffer, memory, 0),
               "vkBindBufferMemory", error))
      return false;
    VkCommandBufferAllocateInfo command_info = {
        VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO};
    command_info.commandPool = s.command_pool;
    command_info.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    command_info.commandBufferCount = 1;
    if (!check(s.AllocateCommandBuffers(s.device, &command_info, &command),
               "vkAllocateCommandBuffers", error))
      return false;
    VkCommandBufferBeginInfo begin = {
        VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO};
    begin.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
    if (!check(s.BeginCommandBuffer(command, &begin), "vkBeginCommandBuffer",
               error))
      return false;
    // Wrapped compositor attachments finish in GENERAL (SurfaceVK's final
    // layout). Restore it after the copy so cached backing stores remain valid.
    VkImageMemoryBarrier barrier = {VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER};
    barrier.srcAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
    barrier.dstAccessMask = VK_ACCESS_TRANSFER_READ_BIT;
    barrier.oldLayout = VK_IMAGE_LAYOUT_GENERAL;
    barrier.newLayout = VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
    barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
    barrier.image = frame->image;
    barrier.subresourceRange = {VK_IMAGE_ASPECT_COLOR_BIT, 0, 1, 0, 1};
    s.CmdPipelineBarrier(command, VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
                         VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, nullptr, 0,
                         nullptr, 1, &barrier);
    VkBufferImageCopy copy = {};
    copy.imageSubresource = {VK_IMAGE_ASPECT_COLOR_BIT, 0, 0, 1};
    copy.imageExtent = {frame->width, frame->height, 1};
    s.CmdCopyImageToBuffer(command, frame->image,
                           VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, buffer, 1,
                           &copy);
    barrier.srcAccessMask = VK_ACCESS_TRANSFER_READ_BIT;
    barrier.dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
    barrier.oldLayout = VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
    barrier.newLayout = VK_IMAGE_LAYOUT_GENERAL;
    s.CmdPipelineBarrier(command, VK_PIPELINE_STAGE_TRANSFER_BIT,
                         VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT, 0, 0,
                         nullptr, 0, nullptr, 1, &barrier);
    if (!check(s.EndCommandBuffer(command), "vkEndCommandBuffer", error))
      return false;
    VkFenceCreateInfo fence_info = {VK_STRUCTURE_TYPE_FENCE_CREATE_INFO};
    if (!check(s.CreateFence(s.device, &fence_info, nullptr, &fence),
               "vkCreateFence", error))
      return false;
    VkSubmitInfo submit = {VK_STRUCTURE_TYPE_SUBMIT_INFO};
    submit.commandBufferCount = 1;
    submit.pCommandBuffers = &command;
    if (!check(queue_submit(s.queue, 1, &submit, fence), "vkQueueSubmit",
               error))
      return false;
    // The fence also establishes transfer-write visibility to coherent host
    // memory. Never release a pending command buffer, even on device loss.
    if (!check(s.WaitForFences(s.device, 1, &fence, VK_TRUE, UINT64_MAX),
               "vkWaitForFences", error))
      return false;
    void* mapped = nullptr;
    if (!check(s.MapMemory(s.device, memory, 0, length, 0, &mapped),
               "vkMapMemory", error))
      return false;
    bytes = g_bytes_new(mapped, length);
    s.UnmapMemory(s.device, memory);
    return true;
  };
  run();
  if (fence)
    s.DestroyFence(s.device, fence, nullptr);
  if (command)
    s.FreeCommandBuffers(s.device, s.command_pool, 1, &command);
  if (buffer)
    s.DestroyBuffer(s.device, buffer, nullptr);
  if (memory)
    s.FreeMemory(s.device, memory, nullptr);
  *width = frame->width;
  *height = frame->height;
  return bytes;
}
