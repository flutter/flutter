// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// FlVulkanManager manages Vulkan resources for the Linux embedder.
//
// The primary code path (Impeller + KHR swapchain) uses:
//   - Vulkan instance, device, and queue setup (always active)
//   - VkSurfaceKHR creation for the platform window (X11 or Wayland)
//   - The surface handle is passed to Impeller's SurfaceContextVK, which
//     owns the swapchain internally
//
// Legacy/fallback code paths (currently unused) include:
//   - Embedder-delegate swapchain management (acquire_image / present_image)
//   - Used if the engine ever needs compositor-driven Vulkan without Impeller

// Include GDK first to get GDK_WINDOWING_* macros defined
#include <gdk/gdk.h>

// X11 headers must be included BEFORE Vulkan headers because
// vulkan_interface.h undefs X11 types (Bool, Status, etc.) after
// including vulkan.h.
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#ifdef GDK_WINDOWING_WAYLAND
#include <gdk/gdkwayland.h>
#endif

#include "flutter/shell/platform/linux/fl_vulkan_manager.h"

#include <dlfcn.h>

#include <algorithm>
#include <cstring>
#include <set>
#include <string>
#include <utility>
#include <vector>

#ifdef GDK_WINDOWING_WAYLAND
#include <wayland-client.h>
#endif

#include "flutter/fml/logging.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/vulkan/procs/vulkan_handle.h"
#include "flutter/vulkan/procs/vulkan_proc_table.h"

// Interval (in frames) between periodic DeviceWaitIdle calls on Mesa dzn.
// At 60 FPS this is roughly every 10 seconds.
static constexpr uint32_t kDznDeviceWaitInterval = 600;

// Maximum wl_compositor interface version to bind.
static constexpr uint32_t kMaxWlCompositorVersion = 4;

// Device name prefix for the Mesa Dozen (dzn) D3D12 translation layer.
static constexpr char kDznDeviceName[] = "Microsoft Direct3D12";

struct _FlVulkanManager {
  GObject parent_instance;

  fml::RefPtr<vulkan::VulkanProcTable> vk;

  VkInstance instance;
  VkPhysicalDevice physical_device;
  VkDevice device;
  VkQueue queue;
  uint32_t queue_family_index;
  VkSurfaceKHR surface;

  // True after release_surface() has been called. When set, the manager's
  // compositor-managed swapchain functions (ensure_swapchain, acquire_image,
  // present_image) must not be called, as Impeller owns the surface.
  gboolean surface_released;

  uint32_t vulkan_version;

  GdkWindow* window;

  std::vector<const char*> enabled_instance_extensions;
  std::vector<const char*> enabled_device_extensions;

  // Mutex for thread-safe queue operations.
  GMutex queue_mutex;

#ifdef GDK_WINDOWING_WAYLAND
  // Wayland subsurface for content-area rendering.
  // The Vulkan surface is created on child_surface (not the toplevel)
  // so that the swapchain only covers the content area below the header bar.
  struct wl_compositor* wl_compositor_iface;
  struct wl_subcompositor* wl_subcompositor_iface;
  struct wl_surface* child_surface;
  struct wl_subsurface* subsurface;
#endif

  // Cached physical device memory properties.
  // Queried once during initialization to avoid redundant API calls
  // during backing store allocation.
  VkPhysicalDeviceMemoryProperties memory_properties;

  // Deferred image destruction queue.
  // Images are pushed here by collect_backing_store and destroyed later
  // after the GPU fence guarantees they are no longer in use.
  std::vector<std::pair<VkImage, VkDeviceMemory>> deferred_deletions;
  GMutex deferred_mutex;

  // Swapchain management for Impeller non-compositor path.
  VkSwapchainKHR swapchain;
  std::vector<VkImage> swapchain_images;
  VkFormat swapchain_format;
  VkExtent2D swapchain_extent;
  uint32_t current_image_index;
  VkFence acquire_fence;

  // Set to TRUE during shutdown to prevent the raster thread from
  // acquiring/presenting images while Vulkan resources are being destroyed.
  // Accessed atomically via g_atomic_int_set/g_atomic_int_get because it
  // is written by the UI thread (shutdown) and read by the raster thread
  // (acquire_image / present_image).
  gint shutting_down;

  // TRUE when running on Mesa's Dozen (dzn) D3D12 translation layer.
  // dzn has known internal resource leaks when processing high volumes
  // of fence create/destroy and command pool reset cycles. A periodic
  // DeviceWaitIdle workaround is used to give dzn a chance to reclaim
  // leaked D3D12 resources and prevent premature device removal.
  gboolean is_dzn_device;

  // Frame counter for periodic dzn workarounds.
  uint32_t frame_counter;

  // Command pool for layout transition command buffers.
  VkCommandPool present_command_pool;

  // Per-swapchain-image resources for present layout transitions.
  // Each swapchain image gets its own command buffer, semaphore, and fence
  // to enable frame pipelining without QueueWaitIdle.
  struct PresentImageResources {
    VkCommandBuffer command_buffer;
    VkSemaphore semaphore;  // Signaled by transition submit, waited by present.
    VkFence fence;          // Signaled by transition submit, waited by CPU
                            // before command buffer reuse.
    gboolean fence_submitted;
  };
  std::vector<PresentImageResources> present_resources;
};

G_DEFINE_TYPE(FlVulkanManager, fl_vulkan_manager, G_TYPE_OBJECT)

#ifdef GDK_WINDOWING_WAYLAND
static void registry_handler(void* data,
                             struct wl_registry* registry,
                             uint32_t id,
                             const char* interface,
                             uint32_t version) {
  FlVulkanManager* self = static_cast<FlVulkanManager*>(data);
  if (strcmp(interface, "wl_compositor") == 0) {
    self->wl_compositor_iface = static_cast<struct wl_compositor*>(
        wl_registry_bind(registry, id, &wl_compositor_interface,
                         std::min(version, kMaxWlCompositorVersion)));
  } else if (strcmp(interface, "wl_subcompositor") == 0) {
    self->wl_subcompositor_iface = static_cast<struct wl_subcompositor*>(
        wl_registry_bind(registry, id, &wl_subcompositor_interface, 1));
  }
}

static void registry_remover(void* data,
                             struct wl_registry* registry,
                             uint32_t id) {
  // No action needed for removal.
}

static const struct wl_registry_listener registry_listener = {
    registry_handler,
    registry_remover,
};
#endif  // GDK_WINDOWING_WAYLAND

// Enumerates all available Vulkan instance extensions once and returns them
// as a set for efficient lookup.
static std::set<std::string> get_available_instance_extensions(
    vulkan::VulkanProcTable& vk) {
  std::set<std::string> result_set;
  uint32_t count = 0;
  VkResult result =
      vk.EnumerateInstanceExtensionProperties(nullptr, &count, nullptr);
  if (result != VK_SUCCESS || count == 0) {
    return result_set;
  }

  std::vector<VkExtensionProperties> extensions(count);
  result = vk.EnumerateInstanceExtensionProperties(nullptr, &count,
                                                   extensions.data());
  if (result != VK_SUCCESS) {
    return result_set;
  }

  for (const auto& ext : extensions) {
    result_set.insert(ext.extensionName);
  }
  return result_set;
}

static bool check_device_extension(vulkan::VulkanProcTable& vk,
                                   VkPhysicalDevice device,
                                   const char* extension_name) {
  uint32_t count = 0;
  VkResult result =
      vk.EnumerateDeviceExtensionProperties(device, nullptr, &count, nullptr);
  if (result != VK_SUCCESS || count == 0) {
    return false;
  }

  std::vector<VkExtensionProperties> extensions(count);
  result = vk.EnumerateDeviceExtensionProperties(device, nullptr, &count,
                                                 extensions.data());
  if (result != VK_SUCCESS) {
    return false;
  }

  for (const auto& ext : extensions) {
    if (strcmp(ext.extensionName, extension_name) == 0) {
      return true;
    }
  }
  return false;
}

static uint32_t find_graphics_queue_family(vulkan::VulkanProcTable& vk,
                                           VkPhysicalDevice device) {
  uint32_t count = 0;
  vk.GetPhysicalDeviceQueueFamilyProperties(device, &count, nullptr);

  std::vector<VkQueueFamilyProperties> queue_families(count);
  vk.GetPhysicalDeviceQueueFamilyProperties(device, &count,
                                            queue_families.data());

  for (uint32_t i = 0; i < count; i++) {
    if (queue_families[i].queueFlags & VK_QUEUE_GRAPHICS_BIT) {
      return i;
    }
  }

  return UINT32_MAX;
}

static VkPhysicalDevice select_physical_device(vulkan::VulkanProcTable& vk,
                                               VkInstance instance,
                                               VkSurfaceKHR surface) {
  uint32_t count = 0;
  VkResult result = vk.EnumeratePhysicalDevices(instance, &count, nullptr);
  if (result != VK_SUCCESS || count == 0) {
    FML_LOG(ERROR) << "No Vulkan physical devices found.";
    return VK_NULL_HANDLE;
  }

  std::vector<VkPhysicalDevice> devices(count);
  result = vk.EnumeratePhysicalDevices(instance, &count, devices.data());
  if (result != VK_SUCCESS) {
    FML_LOG(ERROR) << "Failed to enumerate Vulkan physical devices.";
    return VK_NULL_HANDLE;
  }

  // Prefer discrete GPU, fall back to any device with graphics support.
  // D3D12 translation layers (Mesa dzn) report as discrete but are not fully
  // conformant and fail on many Impeller operations. Deprioritize them.
  VkPhysicalDevice discrete_device = VK_NULL_HANDLE;
  VkPhysicalDevice integrated_device = VK_NULL_HANDLE;
  VkPhysicalDevice d3d12_device = VK_NULL_HANDLE;

  for (const auto& device : devices) {
    // Check for graphics queue support.
    uint32_t queue_family = find_graphics_queue_family(vk, device);
    if (queue_family == UINT32_MAX) {
      continue;
    }

    // Check for swapchain extension support.
    if (!check_device_extension(vk, device, VK_KHR_SWAPCHAIN_EXTENSION_NAME)) {
      continue;
    }

    // Check surface support.
    VkBool32 surface_support = VK_FALSE;
    if (surface != VK_NULL_HANDLE) {
      VkResult surface_result = vk.GetPhysicalDeviceSurfaceSupportKHR(
          device, queue_family, surface, &surface_support);
      if (surface_result != VK_SUCCESS) {
        FML_LOG(WARNING) << "GetPhysicalDeviceSurfaceSupportKHR failed (result="
                         << surface_result << "), skipping device.";
        continue;
      }
      if (!surface_support) {
        continue;
      }
    }

    VkPhysicalDeviceProperties properties;
    vk.GetPhysicalDeviceProperties(device, &properties);

    // Deprioritize D3D12 translation layers (Mesa dzn). They report as
    // discrete but are non-conformant and cause ErrorOutOfHostMemory on
    // many Impeller Vulkan operations.
    if (strstr(properties.deviceName, "Direct3D12") != nullptr) {
      if (d3d12_device == VK_NULL_HANDLE) {
        d3d12_device = device;
        FML_DLOG(INFO) << "Found D3D12 translation layer (deprioritized): "
                       << properties.deviceName;
      }
      continue;
    }

    if (properties.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) {
      discrete_device = device;
      FML_DLOG(INFO) << "Found discrete GPU: " << properties.deviceName;
    } else if (integrated_device == VK_NULL_HANDLE) {
      integrated_device = device;
      FML_DLOG(INFO) << "Found integrated/other GPU: " << properties.deviceName;
    }
  }

  if (discrete_device != VK_NULL_HANDLE) {
    return discrete_device;
  }
  if (integrated_device != VK_NULL_HANDLE) {
    return integrated_device;
  }
  // Only use D3D12 translation layer as last resort.
  return d3d12_device;
}

static bool initialize_vulkan(FlVulkanManager* self) {
  // Create and initialize the proc table.
  self->vk = fml::MakeRefCounted<vulkan::VulkanProcTable>();
  if (!self->vk->HasAcquiredMandatoryProcAddresses()) {
    FML_LOG(ERROR) << "Failed to acquire mandatory Vulkan functions.";
    self->vk = nullptr;
    return false;
  }

  // Determine required instance extensions based on windowing system.
  self->enabled_instance_extensions.push_back(VK_KHR_SURFACE_EXTENSION_NAME);
  auto available_extensions = get_available_instance_extensions(*self->vk);

#ifdef GDK_WINDOWING_X11
  if (self->window != nullptr &&
      GDK_IS_X11_DISPLAY(gdk_window_get_display(self->window))) {
    if (available_extensions.count(VK_KHR_XLIB_SURFACE_EXTENSION_NAME)) {
      self->enabled_instance_extensions.push_back(
          VK_KHR_XLIB_SURFACE_EXTENSION_NAME);
    } else {
      FML_LOG(ERROR) << "VK_KHR_xlib_surface extension not available.";
      return false;
    }
  }
#endif

#ifdef GDK_WINDOWING_WAYLAND
  if (self->window != nullptr &&
      GDK_IS_WAYLAND_DISPLAY(gdk_window_get_display(self->window))) {
    if (available_extensions.count(VK_KHR_WAYLAND_SURFACE_EXTENSION_NAME)) {
      self->enabled_instance_extensions.push_back(
          VK_KHR_WAYLAND_SURFACE_EXTENSION_NAME);
    } else {
      FML_LOG(ERROR) << "VK_KHR_wayland_surface extension not available.";
      return false;
    }
  }
#endif

  // Verify that a WSI extension was added (X11 or Wayland).
  // In headless mode (window == nullptr), WSI extensions are not required.
  if (self->window != nullptr &&
      self->enabled_instance_extensions.size() <= 1) {
    FML_LOG(ERROR) << "No WSI extension available (neither X11 nor Wayland "
                   << "surface support compiled in).";
    return false;
  }

  // Get Vulkan version.
  self->vulkan_version = VK_API_VERSION_1_0;
  if (self->vk->EnumerateInstanceVersion != nullptr) {
    if (self->vk->EnumerateInstanceVersion(&self->vulkan_version) !=
        VK_SUCCESS) {
      self->vulkan_version = VK_API_VERSION_1_0;
    }
  }

  // Impeller requires Vulkan 1.1 as minimum. Fall back early rather than
  // failing deep inside Impeller's context setup.
  if (self->vulkan_version < VK_API_VERSION_1_1) {
    FML_LOG(ERROR) << "Vulkan 1.1 or later is required (found "
                   << VK_VERSION_MAJOR(self->vulkan_version) << "."
                   << VK_VERSION_MINOR(self->vulkan_version)
                   << "). Falling back to OpenGL.";
    return false;
  }

  // Create Vulkan instance.
  VkApplicationInfo app_info = {
      .sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
      .pNext = nullptr,
      .pApplicationName = "Flutter",
      .applicationVersion = VK_MAKE_VERSION(1, 0, 0),
      .pEngineName = "Flutter Engine",
      .engineVersion = VK_MAKE_VERSION(1, 0, 0),
      .apiVersion = self->vulkan_version,
  };

  VkInstanceCreateInfo instance_info = {
      .sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
      .pNext = nullptr,
      .flags = 0,
      .pApplicationInfo = &app_info,
      .enabledLayerCount = 0,
      .ppEnabledLayerNames = nullptr,
      .enabledExtensionCount =
          static_cast<uint32_t>(self->enabled_instance_extensions.size()),
      .ppEnabledExtensionNames = self->enabled_instance_extensions.data(),
  };

  VkResult result =
      self->vk->CreateInstance(&instance_info, nullptr, &self->instance);
  if (result != VK_SUCCESS) {
    FML_LOG(ERROR) << "Failed to create Vulkan instance.";
    return false;
  }

  // Non-owning handle - only used for proc address setup, not resource
  // lifetime management.
  vulkan::VulkanHandle<VkInstance> instance_handle(self->instance, nullptr);
  if (!self->vk->SetupInstanceProcAddresses(instance_handle)) {
    FML_LOG(ERROR) << "Failed to setup instance proc addresses.";
    return false;
  }

  // Create surface if window is provided.
  if (self->window != nullptr) {
#ifdef GDK_WINDOWING_X11
    if (GDK_IS_X11_DISPLAY(gdk_window_get_display(self->window))) {
      VkXlibSurfaceCreateInfoKHR surface_info = {
          .sType = VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR,
          .pNext = nullptr,
          .flags = 0,
          .dpy = gdk_x11_display_get_xdisplay(
              gdk_window_get_display(self->window)),
          .window = gdk_x11_window_get_xid(self->window),
      };

      result = self->vk->CreateXlibSurfaceKHR(self->instance, &surface_info,
                                              nullptr, &self->surface);
      if (result != VK_SUCCESS) {
        FML_LOG(ERROR) << "Failed to create X11 Vulkan surface.";
        return false;
      }
    }
#endif

#ifdef GDK_WINDOWING_WAYLAND
    if (GDK_IS_WAYLAND_DISPLAY(gdk_window_get_display(self->window))) {
      struct wl_display* wl_display = gdk_wayland_display_get_wl_display(
          gdk_window_get_display(self->window));

      // Get wl_compositor and wl_subcompositor from the Wayland registry.
      struct wl_registry* registry = wl_display_get_registry(wl_display);
      wl_registry_add_listener(registry, &registry_listener, self);
      wl_display_roundtrip(wl_display);
      wl_registry_destroy(registry);

      if (self->wl_compositor_iface == nullptr ||
          self->wl_subcompositor_iface == nullptr) {
        FML_LOG(ERROR) << "Failed to bind wl_compositor or wl_subcompositor.";
        return false;
      }

      // Create a child wl_surface and make it a subsurface of the toplevel.
      // This ensures the Vulkan swapchain only covers the content area
      // (below the GTK header bar), not the entire decorated window.
      struct wl_surface* parent_surface =
          gdk_wayland_window_get_wl_surface(self->window);

      self->child_surface =
          wl_compositor_create_surface(self->wl_compositor_iface);
      if (self->child_surface == nullptr) {
        FML_LOG(ERROR) << "Failed to create child wl_surface.";
        return false;
      }

      self->subsurface = wl_subcompositor_get_subsurface(
          self->wl_subcompositor_iface, self->child_surface, parent_surface);
      if (self->subsurface == nullptr) {
        FML_LOG(ERROR) << "Failed to create wl_subsurface.";
        return false;
      }

      // Use desync mode so the subsurface updates independently.
      wl_subsurface_set_desync(self->subsurface);
      // Initial position at (0,0); fl_view will update this after realization.
      wl_subsurface_set_position(self->subsurface, 0, 0);

      // Set an empty input region on the child surface so that all pointer
      // and keyboard events pass through to the parent GTK surface.
      // The Vulkan surface is purely for rendering output.
      // Per the Wayland protocol (wayland-book.com/surfaces-in-depth/
      // surface-regions.html), set_input_region is the standard mechanism
      // for controlling which parts of a surface accept input.
      struct wl_region* empty_region =
          wl_compositor_create_region(self->wl_compositor_iface);
      wl_surface_set_input_region(self->child_surface, empty_region);
      wl_region_destroy(empty_region);

      // Hint to the Wayland compositor that this surface is fully opaque.
      // This allows the compositor to skip blending and skip rendering
      // any surfaces occluded behind ours, improving system-wide performance.
      struct wl_region* opaque_region =
          wl_compositor_create_region(self->wl_compositor_iface);
      wl_region_add(opaque_region, 0, 0, INT32_MAX, INT32_MAX);
      wl_surface_set_opaque_region(self->child_surface, opaque_region);
      wl_region_destroy(opaque_region);

      wl_surface_commit(self->child_surface);

      // Create the Vulkan surface on the child wl_surface, not the toplevel.
      VkWaylandSurfaceCreateInfoKHR surface_info = {
          .sType = VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR,
          .pNext = nullptr,
          .flags = 0,
          .display = wl_display,
          .surface = self->child_surface,
      };

      result = self->vk->CreateWaylandSurfaceKHR(self->instance, &surface_info,
                                                 nullptr, &self->surface);
      if (result != VK_SUCCESS) {
        FML_LOG(ERROR) << "Failed to create Wayland Vulkan surface.";
        return false;
      }
    }
#endif
  }

  // Select physical device.
  self->physical_device =
      select_physical_device(*self->vk, self->instance, self->surface);
  if (self->physical_device == VK_NULL_HANDLE) {
    FML_LOG(ERROR) << "No suitable Vulkan physical device found.";
    return false;
  }

  // Detect Mesa Dozen (dzn) D3D12 translation layer.
  // dzn devices have deviceName starting with "Microsoft Direct3D12".
  {
    VkPhysicalDeviceProperties props;
    self->vk->GetPhysicalDeviceProperties(self->physical_device, &props);
    if (strncmp(props.deviceName, kDznDeviceName, sizeof(kDznDeviceName) - 1) ==
        0) {
      self->is_dzn_device = TRUE;
      FML_DLOG(INFO) << "Running on Mesa Dozen (dzn) D3D12 translation layer. "
                     << "Periodic DeviceWaitIdle workaround enabled.";
    }
  }

  // Find graphics queue family.
  self->queue_family_index =
      find_graphics_queue_family(*self->vk, self->physical_device);
  if (self->queue_family_index == UINT32_MAX) {
    FML_LOG(ERROR) << "No graphics queue family found.";
    return false;
  }

  // Prepare device extensions.
  self->enabled_device_extensions.push_back(VK_KHR_SWAPCHAIN_EXTENSION_NAME);

  // Enable optional extensions that Impeller checks for.
  if (check_device_extension(
          *self->vk, self->physical_device,
          VK_EXT_PIPELINE_CREATION_FEEDBACK_EXTENSION_NAME)) {
    self->enabled_device_extensions.push_back(
        VK_EXT_PIPELINE_CREATION_FEEDBACK_EXTENSION_NAME);
  }

  // Query device features that Impeller needs.
  // Impeller's ContextVK calls GetEnabledDeviceFeatures() which queries the
  // physical device and assumes those features are enabled on the VkDevice.
  // These features must be enabled here; otherwise Impeller shaders fail at
  // vkEndCommandBuffer (the driver rejects commands using disabled features).
  VkPhysicalDeviceFeatures2 device_features2 = {
      .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2,
  };

  VkPhysicalDevice16BitStorageFeatures storage_16bit_features = {
      .sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_16BIT_STORAGE_FEATURES,
  };
  device_features2.pNext = &storage_16bit_features;

  // Query what the physical device supports via vkGetPhysicalDeviceFeatures2.
  // This function is core in Vulkan 1.1+ or available via
  // VK_KHR_get_physical_device_properties2.
  auto vkGetPhysicalDeviceFeatures2Fn =
      reinterpret_cast<PFN_vkGetPhysicalDeviceFeatures2>(
          self->vk->GetInstanceProcAddr(self->instance,
                                        "vkGetPhysicalDeviceFeatures2"));
  if (vkGetPhysicalDeviceFeatures2Fn == nullptr) {
    // Try the KHR extension version.
    vkGetPhysicalDeviceFeatures2Fn =
        reinterpret_cast<PFN_vkGetPhysicalDeviceFeatures2>(
            self->vk->GetInstanceProcAddr(self->instance,
                                          "vkGetPhysicalDeviceFeatures2KHR"));
  }

  if (vkGetPhysicalDeviceFeatures2Fn != nullptr) {
    vkGetPhysicalDeviceFeatures2Fn(self->physical_device, &device_features2);
  } else {
    // Fallback: query basic features only.
    self->vk->GetPhysicalDeviceFeatures(self->physical_device,
                                        &device_features2.features);
  }

  // Create logical device with the queried features chained via pNext.
  float queue_priority = 1.0f;
  VkDeviceQueueCreateInfo queue_info = {
      .sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
      .pNext = nullptr,
      .flags = 0,
      .queueFamilyIndex = self->queue_family_index,
      .queueCount = 1,
      .pQueuePriorities = &queue_priority,
  };

  VkDeviceCreateInfo device_info = {
      .sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
      .pNext = &device_features2,
      .flags = 0,
      .queueCreateInfoCount = 1,
      .pQueueCreateInfos = &queue_info,
      .enabledLayerCount = 0,
      .ppEnabledLayerNames = nullptr,
      .enabledExtensionCount =
          static_cast<uint32_t>(self->enabled_device_extensions.size()),
      .ppEnabledExtensionNames = self->enabled_device_extensions.data(),
      .pEnabledFeatures = nullptr,  // Using pNext chain instead.
  };

  result = self->vk->CreateDevice(self->physical_device, &device_info, nullptr,
                                  &self->device);
  if (result != VK_SUCCESS) {
    FML_LOG(ERROR) << "Failed to create Vulkan logical device.";
    return false;
  }

  // Non-owning handle - only used for proc address setup.
  vulkan::VulkanHandle<VkDevice> device_handle(self->device, nullptr);
  if (!self->vk->SetupDeviceProcAddresses(device_handle)) {
    FML_LOG(ERROR) << "Failed to setup device proc addresses.";
    return false;
  }

  // Get the graphics queue.
  self->vk->GetDeviceQueue(self->device, self->queue_family_index, 0,
                           &self->queue);

  // Cache physical device memory properties once.
  // This avoids querying vkGetPhysicalDeviceMemoryProperties on every
  // backing store allocation (per GPUOpen best practice: minimize
  // redundant API calls).
  self->vk->GetPhysicalDeviceMemoryProperties(self->physical_device,
                                              &self->memory_properties);

  // Create a command pool for present layout transitions.
  // Individual command buffers are allocated per swapchain image in
  // ensure_swapchain to enable frame pipelining.
  VkCommandPoolCreateInfo pool_info = {
      .sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
      .pNext = nullptr,
      .flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
      .queueFamilyIndex = self->queue_family_index,
  };
  result = self->vk->CreateCommandPool(self->device, &pool_info, nullptr,
                                       &self->present_command_pool);
  if (result != VK_SUCCESS) {
    FML_LOG(ERROR) << "Failed to create present command pool.";
    return false;
  }

  return true;
}

static void fl_vulkan_manager_dispose(GObject* object) {
  FlVulkanManager* self = FL_VULKAN_MANAGER(object);

  // Mark as shutting down to prevent the raster thread from issuing new
  // acquire/present calls while resources are torn down.
  g_atomic_int_set(&self->shutting_down, TRUE);

  if (self->device != VK_NULL_HANDLE && self->vk) {
    self->vk->DeviceWaitIdle(self->device);
  }

  // Process deferred deletions BEFORE destroying the device.
  if (self->vk && self->device != VK_NULL_HANDLE) {
    g_mutex_lock(&self->deferred_mutex);
    for (auto& [image, memory] : self->deferred_deletions) {
      if (image != VK_NULL_HANDLE) {
        self->vk->DestroyImage(self->device, image, nullptr);
      }
      if (memory != VK_NULL_HANDLE) {
        self->vk->FreeMemory(self->device, memory, nullptr);
      }
    }
    self->deferred_deletions.clear();
    g_mutex_unlock(&self->deferred_mutex);
  }

  // Clean up per-image present resources (semaphores, fences).
  // Command buffers are freed automatically when the pool is destroyed.
  if (self->vk && self->device != VK_NULL_HANDLE) {
    for (auto& res : self->present_resources) {
      if (res.semaphore != VK_NULL_HANDLE) {
        self->vk->DestroySemaphore(self->device, res.semaphore, nullptr);
      }
      if (res.fence != VK_NULL_HANDLE) {
        self->vk->DestroyFence(self->device, res.fence, nullptr);
      }
    }
  }
  self->present_resources.clear();

  // Destroy present command pool (frees all command buffers automatically).
  if (self->present_command_pool != VK_NULL_HANDLE && self->vk) {
    self->vk->DestroyCommandPool(self->device, self->present_command_pool,
                                 nullptr);
    self->present_command_pool = VK_NULL_HANDLE;
  }

  // Clean up swapchain resources.
  if (self->acquire_fence != VK_NULL_HANDLE && self->vk) {
    self->vk->DestroyFence(self->device, self->acquire_fence, nullptr);
    self->acquire_fence = VK_NULL_HANDLE;
  }
  if (self->swapchain != VK_NULL_HANDLE && self->vk) {
    self->vk->DestroySwapchainKHR(self->device, self->swapchain, nullptr);
    self->swapchain = VK_NULL_HANDLE;
  }
  self->swapchain_images.clear();

  if (self->surface != VK_NULL_HANDLE && self->vk) {
    self->vk->DestroySurfaceKHR(self->instance, self->surface, nullptr);
    self->surface = VK_NULL_HANDLE;
  }

  if (self->device != VK_NULL_HANDLE && self->vk) {
    self->vk->DestroyDevice(self->device, nullptr);
    self->device = VK_NULL_HANDLE;
  }

  if (self->instance != VK_NULL_HANDLE && self->vk) {
    self->vk->DestroyInstance(self->instance, nullptr);
    self->instance = VK_NULL_HANDLE;
  }

  self->enabled_instance_extensions.clear();
  self->enabled_device_extensions.clear();
  self->vk = nullptr;

#ifdef GDK_WINDOWING_WAYLAND
  // Destroy Wayland resources BEFORE unreffing the window, because the
  // Wayland display connection may be invalidated when the last window
  // reference is dropped.
  if (self->subsurface != nullptr) {
    wl_subsurface_destroy(self->subsurface);
    self->subsurface = nullptr;
  }
  if (self->child_surface != nullptr) {
    wl_surface_destroy(self->child_surface);
    self->child_surface = nullptr;
  }
  if (self->wl_subcompositor_iface != nullptr) {
    wl_subcompositor_destroy(self->wl_subcompositor_iface);
    self->wl_subcompositor_iface = nullptr;
  }
  if (self->wl_compositor_iface != nullptr) {
    wl_compositor_destroy(self->wl_compositor_iface);
    self->wl_compositor_iface = nullptr;
  }
#endif

  if (self->window != nullptr) {
    g_object_unref(self->window);
    self->window = nullptr;
  }

  g_mutex_clear(&self->queue_mutex);
  g_mutex_clear(&self->deferred_mutex);

  G_OBJECT_CLASS(fl_vulkan_manager_parent_class)->dispose(object);
}

static void fl_vulkan_manager_finalize(GObject* object) {
  FlVulkanManager* self = FL_VULKAN_MANAGER(object);
  // Explicitly destruct C++ members whose destructors would not be called
  // by GObject's raw memory deallocation. The RefPtr and vector contents
  // are already cleaned up in dispose; this frees the backing buffers.
  self->vk.~RefPtr();
  self->enabled_instance_extensions.~vector();
  self->enabled_device_extensions.~vector();
  self->swapchain_images.~vector();
  self->deferred_deletions.~vector();
  self->present_resources.~vector();
  G_OBJECT_CLASS(fl_vulkan_manager_parent_class)->finalize(object);
}

static void fl_vulkan_manager_class_init(FlVulkanManagerClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_vulkan_manager_dispose;
  G_OBJECT_CLASS(klass)->finalize = fl_vulkan_manager_finalize;
}

static void fl_vulkan_manager_init(FlVulkanManager* self) {
  self->vk = nullptr;
  self->instance = VK_NULL_HANDLE;
  self->physical_device = VK_NULL_HANDLE;
  self->device = VK_NULL_HANDLE;
  self->queue = VK_NULL_HANDLE;
  self->queue_family_index = UINT32_MAX;
  self->surface = VK_NULL_HANDLE;
  self->surface_released = FALSE;
  self->vulkan_version = 0;
  self->window = nullptr;
#ifdef GDK_WINDOWING_WAYLAND
  self->wl_compositor_iface = nullptr;
  self->wl_subcompositor_iface = nullptr;
  self->child_surface = nullptr;
  self->subsurface = nullptr;
#endif
  g_mutex_init(&self->queue_mutex);
  g_mutex_init(&self->deferred_mutex);
  self->swapchain = VK_NULL_HANDLE;
  self->swapchain_format = VK_FORMAT_UNDEFINED;
  self->swapchain_extent = {0, 0};
  self->current_image_index = UINT32_MAX;
  self->acquire_fence = VK_NULL_HANDLE;
  g_atomic_int_set(&self->shutting_down, FALSE);
  self->is_dzn_device = FALSE;
  self->frame_counter = 0;
  self->present_command_pool = VK_NULL_HANDLE;
}

FlVulkanManager* fl_vulkan_manager_new(GdkWindow* window) {
  FlVulkanManager* self =
      FL_VULKAN_MANAGER(g_object_new(fl_vulkan_manager_get_type(), nullptr));

  if (window != nullptr) {
    self->window = GDK_WINDOW(g_object_ref(window));
  }

  if (!initialize_vulkan(self)) {
    g_object_unref(self);
    return nullptr;
  }

  return self;
}

gboolean fl_vulkan_manager_is_available() {
  // Thread-safe one-time initialization using GLib's g_once pattern.
  static gsize initialized = 0;
  static gboolean available = FALSE;

  if (g_once_init_enter(&initialized)) {
    // Try to load the Vulkan library.
    void* vulkan_lib = dlopen("libvulkan.so.1", RTLD_NOW | RTLD_LOCAL);
    if (vulkan_lib == nullptr) {
      vulkan_lib = dlopen("libvulkan.so", RTLD_NOW | RTLD_LOCAL);
    }

    if (vulkan_lib != nullptr) {
      // Check for vkCreateInstance and verify Vulkan 1.1+ is available.
      // Impeller requires Vulkan 1.1 as minimum, so skip Vulkan entirely
      // if only 1.0 is available to avoid confusing fallback messages.
      auto create_instance = reinterpret_cast<PFN_vkCreateInstance>(
          dlsym(vulkan_lib, "vkCreateInstance"));
      if (create_instance != nullptr) {
        auto enumerate_version =
            reinterpret_cast<PFN_vkEnumerateInstanceVersion>(
                dlsym(vulkan_lib, "vkEnumerateInstanceVersion"));
        if (enumerate_version != nullptr) {
          uint32_t version = VK_API_VERSION_1_0;
          if (enumerate_version(&version) == VK_SUCCESS &&
              version >= VK_API_VERSION_1_1) {
            available = TRUE;
          }
        }
        // vkEnumerateInstanceVersion not available means Vulkan 1.0 only.
      }
      dlclose(vulkan_lib);
    }

    g_once_init_leave(&initialized, 1);
  }

  return available;
}

uint32_t fl_vulkan_manager_get_vulkan_version(FlVulkanManager* manager) {
  g_return_val_if_fail(FL_IS_VULKAN_MANAGER(manager), 0);
  return manager->vulkan_version;
}

VkInstance fl_vulkan_manager_get_instance(FlVulkanManager* manager) {
  g_return_val_if_fail(FL_IS_VULKAN_MANAGER(manager), VK_NULL_HANDLE);
  return manager->instance;
}

VkPhysicalDevice fl_vulkan_manager_get_physical_device(
    FlVulkanManager* manager) {
  g_return_val_if_fail(FL_IS_VULKAN_MANAGER(manager), VK_NULL_HANDLE);
  return manager->physical_device;
}

VkDevice fl_vulkan_manager_get_device(FlVulkanManager* manager) {
  g_return_val_if_fail(FL_IS_VULKAN_MANAGER(manager), VK_NULL_HANDLE);
  return manager->device;
}

VkQueue fl_vulkan_manager_get_queue(FlVulkanManager* manager) {
  g_return_val_if_fail(FL_IS_VULKAN_MANAGER(manager), VK_NULL_HANDLE);
  return manager->queue;
}

uint32_t fl_vulkan_manager_get_queue_family_index(FlVulkanManager* manager) {
  g_return_val_if_fail(FL_IS_VULKAN_MANAGER(manager), UINT32_MAX);
  return manager->queue_family_index;
}

VkSurfaceKHR fl_vulkan_manager_get_surface(FlVulkanManager* manager) {
  g_return_val_if_fail(FL_IS_VULKAN_MANAGER(manager), VK_NULL_HANDLE);
  return manager->surface;
}

VkSurfaceKHR fl_vulkan_manager_release_surface(FlVulkanManager* manager) {
  g_return_val_if_fail(FL_IS_VULKAN_MANAGER(manager), VK_NULL_HANDLE);
  VkSurfaceKHR s = manager->surface;
  manager->surface = VK_NULL_HANDLE;
  manager->surface_released = TRUE;
  return s;
}

vulkan::VulkanProcTable* fl_vulkan_manager_get_proc_table(
    FlVulkanManager* manager) {
  g_return_val_if_fail(FL_IS_VULKAN_MANAGER(manager), nullptr);
  return manager->vk.get();
}

const char** fl_vulkan_manager_get_enabled_instance_extensions(
    FlVulkanManager* manager,
    size_t* count) {
  g_return_val_if_fail(FL_IS_VULKAN_MANAGER(manager), nullptr);
  g_return_val_if_fail(count != nullptr, nullptr);
  *count = manager->enabled_instance_extensions.size();
  return manager->enabled_instance_extensions.data();
}

const char** fl_vulkan_manager_get_enabled_device_extensions(
    FlVulkanManager* manager,
    size_t* count) {
  g_return_val_if_fail(FL_IS_VULKAN_MANAGER(manager), nullptr);
  g_return_val_if_fail(count != nullptr, nullptr);
  *count = manager->enabled_device_extensions.size();
  return manager->enabled_device_extensions.data();
}

void* fl_vulkan_manager_get_instance_proc_address(FlVulkanManager* manager,
                                                  VkInstance instance,
                                                  const char* name) {
  g_return_val_if_fail(FL_IS_VULKAN_MANAGER(manager), nullptr);
  g_return_val_if_fail(name != nullptr, nullptr);

  if (!manager->vk) {
    return nullptr;
  }

  return reinterpret_cast<void*>(
      manager->vk->GetInstanceProcAddr(instance, name));
}

void fl_vulkan_manager_acquire_queue_mutex(FlVulkanManager* manager) {
  g_return_if_fail(FL_IS_VULKAN_MANAGER(manager));
  g_mutex_lock(&manager->queue_mutex);
}

void fl_vulkan_manager_release_queue_mutex(FlVulkanManager* manager) {
  g_return_if_fail(FL_IS_VULKAN_MANAGER(manager));
  g_mutex_unlock(&manager->queue_mutex);
}

GdkWindow* fl_vulkan_manager_get_window(FlVulkanManager* manager) {
  g_return_val_if_fail(FL_IS_VULKAN_MANAGER(manager), nullptr);
  return manager->window;
}

void fl_vulkan_manager_set_subsurface_position(FlVulkanManager* manager,
                                               gint x,
                                               gint y) {
  g_return_if_fail(FL_IS_VULKAN_MANAGER(manager));
#ifdef GDK_WINDOWING_WAYLAND
  if (manager->subsurface != nullptr) {
    wl_subsurface_set_position(manager->subsurface, x, y);
    // Commit the child surface to apply the position change.
    if (manager->child_surface != nullptr) {
      wl_surface_commit(manager->child_surface);
    }
  }
#endif
}

const VkPhysicalDeviceMemoryProperties* fl_vulkan_manager_get_memory_properties(
    FlVulkanManager* manager) {
  g_return_val_if_fail(FL_IS_VULKAN_MANAGER(manager), nullptr);
  return &manager->memory_properties;
}

void fl_vulkan_manager_defer_image_destruction(FlVulkanManager* manager,
                                               VkImage image,
                                               VkDeviceMemory memory) {
  g_return_if_fail(FL_IS_VULKAN_MANAGER(manager));
  g_mutex_lock(&manager->deferred_mutex);
  manager->deferred_deletions.emplace_back(image, memory);
  g_mutex_unlock(&manager->deferred_mutex);
}

void fl_vulkan_manager_process_deferred_deletions(FlVulkanManager* manager) {
  g_return_if_fail(FL_IS_VULKAN_MANAGER(manager));

  g_mutex_lock(&manager->deferred_mutex);
  if (manager->deferred_deletions.empty()) {
    g_mutex_unlock(&manager->deferred_mutex);
    return;
  }

  // Move to a local list so the mutex is not held during destruction.
  auto pending = std::move(manager->deferred_deletions);
  // No need to call clear() - moved-from vector is guaranteed empty.
  g_mutex_unlock(&manager->deferred_mutex);

  VkDevice device = fl_vulkan_manager_get_device(manager);
  vulkan::VulkanProcTable* vk = fl_vulkan_manager_get_proc_table(manager);
  if (vk == nullptr || device == VK_NULL_HANDLE) {
    return;
  }

  for (auto& [image, memory] : pending) {
    if (image != VK_NULL_HANDLE) {
      vk->DestroyImage(device, image, nullptr);
    }
    if (memory != VK_NULL_HANDLE) {
      vk->FreeMemory(device, memory, nullptr);
    }
  }
}

gboolean fl_vulkan_manager_ensure_swapchain(FlVulkanManager* self,
                                            uint32_t width,
                                            uint32_t height) {
  g_return_val_if_fail(FL_IS_VULKAN_MANAGER(self), FALSE);

  // After release_surface(), the surface is owned by Impeller and
  // the compositor-managed swapchain path must not be used.
  if (self->surface_released) {
    FML_LOG(ERROR) << "ensure_swapchain called after surface was released "
                      "to Impeller - this is a bug.";
    return FALSE;
  }

  if (width == 0 || height == 0) {
    return FALSE;
  }

  if (g_atomic_int_get(&self->shutting_down)) {
    return FALSE;
  }

  if (self->surface == VK_NULL_HANDLE) {
    FML_LOG(ERROR) << "Cannot create swapchain: no VkSurface.";
    return FALSE;
  }

  // Query surface capabilities to determine the actual surface extent.
  // This must come first so the real surface size is known before deciding
  // whether to recreate.
  VkSurfaceCapabilitiesKHR caps;
  VkResult result = self->vk->GetPhysicalDeviceSurfaceCapabilitiesKHR(
      self->physical_device, self->surface, &caps);
  if (result != VK_SUCCESS) {
    FML_LOG(ERROR) << "GetPhysicalDeviceSurfaceCapabilitiesKHR failed: "
                   << result;
    return FALSE;
  }

  // Determine the actual extent for the swapchain.
  // On X11, currentExtent is the window size and MUST be used.
  // On Wayland, currentExtent may be UINT32_MAX, indicating the compositor
  // allows the application to choose the extent.
  VkExtent2D extent;
  if (caps.currentExtent.width != UINT32_MAX) {
    extent = caps.currentExtent;
  } else {
    extent.width = std::max(caps.minImageExtent.width,
                            std::min(width, caps.maxImageExtent.width));
    extent.height = std::max(caps.minImageExtent.height,
                             std::min(height, caps.maxImageExtent.height));
  }

  if (extent.width == 0 || extent.height == 0) {
    return FALSE;
  }

  // If existing swapchain matches the surface's actual size, nothing to do.
  if (self->swapchain != VK_NULL_HANDLE &&
      self->swapchain_extent.width == extent.width &&
      self->swapchain_extent.height == extent.height) {
    return TRUE;
  }

  // Wait for device idle before recreating swapchain.
  // This ensures no command buffers reference old swapchain images.
  if (self->swapchain != VK_NULL_HANDLE) {
    self->vk->DeviceWaitIdle(self->device);

    // Clean up per-image present resources from old swapchain.
    for (auto& res : self->present_resources) {
      if (res.semaphore != VK_NULL_HANDLE) {
        self->vk->DestroySemaphore(self->device, res.semaphore, nullptr);
      }
      if (res.fence != VK_NULL_HANDLE) {
        self->vk->DestroyFence(self->device, res.fence, nullptr);
      }
    }
    self->present_resources.clear();

    // Destroy and recreate the command pool to free all previously allocated
    // command buffers. This prevents unbounded accumulation across swapchain
    // recreations. Re-creation is safe because DeviceWaitIdle has completed.
    if (self->present_command_pool != VK_NULL_HANDLE) {
      self->vk->DestroyCommandPool(self->device, self->present_command_pool,
                                   nullptr);
      VkCommandPoolCreateInfo pool_info = {
          .sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
          .pNext = nullptr,
          .flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
          .queueFamilyIndex = self->queue_family_index,
      };
      result = self->vk->CreateCommandPool(self->device, &pool_info, nullptr,
                                           &self->present_command_pool);
      if (result != VK_SUCCESS) {
        FML_LOG(ERROR) << "Failed to recreate present command pool.";
        self->present_command_pool = VK_NULL_HANDLE;
        return FALSE;
      }
    }
  }

  // Choose surface format (prefer B8G8R8A8_UNORM).
  uint32_t format_count = 0;
  result = self->vk->GetPhysicalDeviceSurfaceFormatsKHR(
      self->physical_device, self->surface, &format_count, nullptr);
  if (result != VK_SUCCESS || format_count == 0) {
    FML_LOG(ERROR) << "No surface formats available (result=" << result << ").";
    return FALSE;
  }
  std::vector<VkSurfaceFormatKHR> formats(format_count);
  result = self->vk->GetPhysicalDeviceSurfaceFormatsKHR(
      self->physical_device, self->surface, &format_count, formats.data());
  if (result != VK_SUCCESS) {
    FML_LOG(ERROR) << "GetPhysicalDeviceSurfaceFormatsKHR failed: " << result;
    return FALSE;
  }

  VkSurfaceFormatKHR chosen_format = formats[0];
  for (const auto& fmt : formats) {
    if (fmt.format == VK_FORMAT_B8G8R8A8_UNORM) {
      chosen_format = fmt;
      break;
    }
  }

  // Choose present mode (prefer mailbox for low latency, fallback to FIFO).
  uint32_t mode_count = 0;
  result = self->vk->GetPhysicalDeviceSurfacePresentModesKHR(
      self->physical_device, self->surface, &mode_count, nullptr);
  if (result != VK_SUCCESS || mode_count == 0) {
    FML_LOG(ERROR) << "No present modes available (result=" << result << ").";
    return FALSE;
  }
  std::vector<VkPresentModeKHR> modes(mode_count);
  result = self->vk->GetPhysicalDeviceSurfacePresentModesKHR(
      self->physical_device, self->surface, &mode_count, modes.data());
  if (result != VK_SUCCESS) {
    FML_LOG(ERROR) << "GetPhysicalDeviceSurfacePresentModesKHR failed: "
                   << result;
    return FALSE;
  }

  VkPresentModeKHR present_mode = VK_PRESENT_MODE_FIFO_KHR;
  for (const auto& m : modes) {
    if (m == VK_PRESENT_MODE_MAILBOX_KHR) {
      present_mode = m;
      break;
    }
  }

  // Image count: one more than minimum for triple buffering.
  uint32_t image_count = caps.minImageCount + 1;
  if (caps.maxImageCount > 0 && image_count > caps.maxImageCount) {
    image_count = caps.maxImageCount;
  }

  // Determine composite alpha.
  VkCompositeAlphaFlagBitsKHR composite_alpha =
      VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR;
  if (caps.supportedCompositeAlpha & VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR) {
    composite_alpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
  }

  VkSwapchainKHR old_swapchain = self->swapchain;

  // Build the image usage flags. Always require color attachment and transfer.
  // Only add input attachment if the surface actually supports it - some
  // drivers (especially software-based ones) may not.
  VkImageUsageFlags image_usage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT |
                                  VK_IMAGE_USAGE_TRANSFER_SRC_BIT |
                                  VK_IMAGE_USAGE_TRANSFER_DST_BIT;
  if (caps.supportedUsageFlags & VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT) {
    image_usage |= VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT;
  }

  VkSwapchainCreateInfoKHR create_info = {
      .sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
      .pNext = nullptr,
      .flags = 0,
      .surface = self->surface,
      .minImageCount = image_count,
      .imageFormat = chosen_format.format,
      .imageColorSpace = chosen_format.colorSpace,
      .imageExtent = extent,
      .imageArrayLayers = 1,
      .imageUsage = image_usage,
      .imageSharingMode = VK_SHARING_MODE_EXCLUSIVE,
      .queueFamilyIndexCount = 0,
      .pQueueFamilyIndices = nullptr,
      .preTransform = caps.currentTransform,
      .compositeAlpha = composite_alpha,
      .presentMode = present_mode,
      .clipped = VK_TRUE,
      .oldSwapchain = old_swapchain,
  };

  result = self->vk->CreateSwapchainKHR(self->device, &create_info, nullptr,
                                        &self->swapchain);
  if (old_swapchain != VK_NULL_HANDLE) {
    self->vk->DestroySwapchainKHR(self->device, old_swapchain, nullptr);
  }
  if (result != VK_SUCCESS) {
    FML_LOG(ERROR) << "CreateSwapchainKHR failed: " << result;
    self->swapchain = VK_NULL_HANDLE;
    return FALSE;
  }

  // Get swapchain images.
  uint32_t swapchain_image_count = 0;
  result = self->vk->GetSwapchainImagesKHR(self->device, self->swapchain,
                                           &swapchain_image_count, nullptr);
  if (result != VK_SUCCESS || swapchain_image_count == 0) {
    FML_LOG(ERROR) << "GetSwapchainImagesKHR (count) failed: " << result;
    return FALSE;
  }
  self->swapchain_images.resize(swapchain_image_count);
  result = self->vk->GetSwapchainImagesKHR(self->device, self->swapchain,
                                           &swapchain_image_count,
                                           self->swapchain_images.data());
  if (result != VK_SUCCESS) {
    FML_LOG(ERROR) << "GetSwapchainImagesKHR (data) failed: " << result;
    return FALSE;
  }

  self->swapchain_format = chosen_format.format;

  // Create acquire fence if needed.
  if (self->acquire_fence == VK_NULL_HANDLE) {
    VkFenceCreateInfo fence_info = {
        .sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
        .pNext = nullptr,
        .flags = 0,
    };
    result = self->vk->CreateFence(self->device, &fence_info, nullptr,
                                   &self->acquire_fence);
    if (result != VK_SUCCESS) {
      FML_LOG(ERROR) << "Failed to create acquire fence: " << result;
      return FALSE;
    }
  }

  // Allocate per-image present resources for frame pipelining.
  // Each swapchain image gets its own command buffer, semaphore, and fence
  // so that the present layout transition can be submitted without
  // QueueWaitIdle.
  self->present_resources.resize(swapchain_image_count);

  std::vector<VkCommandBuffer> cmd_buffers(swapchain_image_count);
  VkCommandBufferAllocateInfo cmd_alloc_info = {
      .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
      .pNext = nullptr,
      .commandPool = self->present_command_pool,
      .level = VK_COMMAND_BUFFER_LEVEL_PRIMARY,
      .commandBufferCount = swapchain_image_count,
  };
  result = self->vk->AllocateCommandBuffers(self->device, &cmd_alloc_info,
                                            cmd_buffers.data());
  if (result != VK_SUCCESS) {
    FML_LOG(ERROR) << "Failed to allocate present command buffers.";
    return FALSE;
  }

  for (uint32_t i = 0; i < swapchain_image_count; i++) {
    self->present_resources[i].command_buffer = cmd_buffers[i];
    self->present_resources[i].fence_submitted = FALSE;

    VkSemaphoreCreateInfo sem_info = {
        .sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
        .pNext = nullptr,
        .flags = 0,
    };
    result = self->vk->CreateSemaphore(self->device, &sem_info, nullptr,
                                       &self->present_resources[i].semaphore);
    if (result != VK_SUCCESS) {
      FML_LOG(ERROR) << "Failed to create present semaphore.";
      return FALSE;
    }

    VkFenceCreateInfo fence_info = {
        .sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
        .pNext = nullptr,
        .flags = 0,
    };
    result = self->vk->CreateFence(self->device, &fence_info, nullptr,
                                   &self->present_resources[i].fence);
    if (result != VK_SUCCESS) {
      FML_LOG(ERROR) << "Failed to create present fence.";
      return FALSE;
    }
  }

  // All resources created successfully. Set the extent to signal that the
  // swapchain is ready. Setting this only on success ensures that a failure
  // at any earlier step forces full swapchain recreation on the next call.
  self->swapchain_extent = extent;
  return TRUE;
}

FlutterVulkanImage fl_vulkan_manager_acquire_image(FlVulkanManager* self,
                                                   uint32_t width,
                                                   uint32_t height) {
  FlutterVulkanImage flutter_image = {};
  flutter_image.struct_size = sizeof(FlutterVulkanImage);

  g_return_val_if_fail(FL_IS_VULKAN_MANAGER(self), flutter_image);

  if (g_atomic_int_get(&self->shutting_down)) {
    return flutter_image;
  }

  // Ensure swapchain exists and matches the surface's actual size.
  if (!fl_vulkan_manager_ensure_swapchain(self, width, height)) {
    FML_LOG(ERROR) << "Failed to ensure swapchain for " << width << "x"
                   << height;
    return flutter_image;
  }

  // If the swapchain extent does not match the requested size, skip this frame.
  // This happens during rapid resize when the Vulkan surface's actual size
  // (caps.currentExtent) is transiently different from the engine's window
  // metrics. Impeller creates render passes at the requested size, so a
  // mismatch would cause Vulkan validation errors or driver crashes.
  // Returning an empty image causes GPUSurfaceVulkanImpeller::AcquireFrame
  // to return nullptr, which drops this frame. The engine will retry on the
  // next VSync when the sizes have converged.
  if (self->swapchain_extent.width != width ||
      self->swapchain_extent.height != height) {
    return flutter_image;
  }

  // Reset the fence before acquiring.
  self->vk->ResetFences(self->device, 1, &self->acquire_fence);

  // Acquire next swapchain image with a fence.
  VkResult result = self->vk->AcquireNextImageKHR(
      self->device, self->swapchain, UINT64_MAX, VK_NULL_HANDLE,
      self->acquire_fence, &self->current_image_index);

  if (result == VK_ERROR_OUT_OF_DATE_KHR || result == VK_SUBOPTIMAL_KHR) {
    // Swapchain needs recreation - force it by zeroing stored extent.
    self->swapchain_extent = {0, 0};
    if (!fl_vulkan_manager_ensure_swapchain(self, width, height)) {
      return flutter_image;
    }
    // After recreation, check size match again.
    if (self->swapchain_extent.width != width ||
        self->swapchain_extent.height != height) {
      return flutter_image;
    }
    self->vk->ResetFences(self->device, 1, &self->acquire_fence);
    result = self->vk->AcquireNextImageKHR(
        self->device, self->swapchain, UINT64_MAX, VK_NULL_HANDLE,
        self->acquire_fence, &self->current_image_index);
  }

  if (result != VK_SUCCESS) {
    FML_LOG(ERROR) << "AcquireNextImageKHR failed: " << result;
    return flutter_image;
  }

  // Wait for the image to be available.
  self->vk->WaitForFences(self->device, 1, &self->acquire_fence, VK_TRUE,
                          UINT64_MAX);

  // Wait for this image's previous present transition to complete before
  // allowing Impeller to render into it again. This provides critical
  // backpressure: without it, the CPU can submit new frames faster than
  // the GPU processes them, causing unbounded accumulation of in-flight
  // command buffers, fences, and tracked resources in the FenceWaiterVK
  // thread - eventually exhausting the D3D12 device on dzn.
  // With N swapchain images, this naturally limits in-flight frames to N.
  if (self->current_image_index < self->present_resources.size()) {
    auto& res = self->present_resources[self->current_image_index];
    if (res.fence_submitted) {
      self->vk->WaitForFences(self->device, 1, &res.fence, VK_TRUE, UINT64_MAX);
      self->vk->ResetFences(self->device, 1, &res.fence);
      res.fence_submitted = FALSE;
    }
  }

  flutter_image.image = reinterpret_cast<uint64_t>(
      self->swapchain_images[self->current_image_index]);
  flutter_image.format = static_cast<uint32_t>(self->swapchain_format);
  return flutter_image;
}

gboolean fl_vulkan_manager_present_image(FlVulkanManager* self,
                                         VkImage image,
                                         VkFormat format) {
  g_return_val_if_fail(FL_IS_VULKAN_MANAGER(self), FALSE);

  // image and format are reserved for a future non-swapchain present path.
  // The current implementation uses swapchain_images[current_image_index].
  (void)image;
  (void)format;

  if (g_atomic_int_get(&self->shutting_down)) {
    return FALSE;
  }

  if (self->swapchain == VK_NULL_HANDLE ||
      self->current_image_index == UINT32_MAX) {
    return FALSE;
  }

  if (self->current_image_index >= self->present_resources.size()) {
    FML_LOG(ERROR) << "Image index out of range for present resources.";
    return FALSE;
  }

  auto& res = self->present_resources[self->current_image_index];

  // The present fence for this image was already waited on and reset in
  // acquire_image before Impeller rendered into it. No need to wait here.

  // Record the layout transition: GENERAL -> PRESENT_SRC_KHR.
  // Impeller's render pass leaves the resolve texture (swapchain image) in
  // VK_IMAGE_LAYOUT_GENERAL (see ComputeFinalLayout in
  // render_pass_builder_vk.cc - for is_swapchain=true images, finalLayout is
  // eGeneral). The embedder is responsible for transitioning to
  // PRESENT_SRC_KHR.
  self->vk->ResetCommandBuffer(res.command_buffer, 0);

  VkCommandBufferBeginInfo begin_info = {
      .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
      .pNext = nullptr,
      .flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
      .pInheritanceInfo = nullptr,
  };
  VkResult result =
      self->vk->BeginCommandBuffer(res.command_buffer, &begin_info);
  if (result != VK_SUCCESS) {
    FML_LOG(ERROR) << "BeginCommandBuffer for present transition failed: "
                   << result;
    return FALSE;
  }

  VkImageMemoryBarrier barrier = {
      .sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
      .pNext = nullptr,
      .srcAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
      .dstAccessMask = 0,
      .oldLayout = VK_IMAGE_LAYOUT_GENERAL,
      .newLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
      .srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
      .dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
      .image = self->swapchain_images[self->current_image_index],
      .subresourceRange =
          {
              .aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
              .baseMipLevel = 0,
              .levelCount = 1,
              .baseArrayLayer = 0,
              .layerCount = 1,
          },
  };

  self->vk->CmdPipelineBarrier(res.command_buffer,
                               VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
                               VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0, 0,
                               nullptr, 0, nullptr, 1, &barrier);

  result = self->vk->EndCommandBuffer(res.command_buffer);
  if (result != VK_SUCCESS) {
    FML_LOG(ERROR) << "EndCommandBuffer for present transition failed: "
                   << result;
    return FALSE;
  }

  // Submit the transition, signaling a semaphore for the present engine
  // and a fence for CPU-side command buffer reuse tracking.
  // No QueueWaitIdle needed - the semaphore provides GPU-GPU synchronization.
  g_mutex_lock(&self->queue_mutex);

  VkSubmitInfo submit_info = {
      .sType = VK_STRUCTURE_TYPE_SUBMIT_INFO,
      .pNext = nullptr,
      .waitSemaphoreCount = 0,
      .pWaitSemaphores = nullptr,
      .pWaitDstStageMask = nullptr,
      .commandBufferCount = 1,
      .pCommandBuffers = &res.command_buffer,
      .signalSemaphoreCount = 1,
      .pSignalSemaphores = &res.semaphore,
  };

  result = self->vk->QueueSubmit(self->queue, 1, &submit_info, res.fence);
  if (result != VK_SUCCESS) {
    g_mutex_unlock(&self->queue_mutex);
    FML_LOG(ERROR) << "QueueSubmit for present transition failed: " << result;
    return FALSE;
  }
  res.fence_submitted = TRUE;

  // Present the image, waiting on the transition semaphore.
  // The presentation engine will not read the image until the semaphore
  // is signaled, ensuring the layout transition is complete.
  VkPresentInfoKHR present_info = {
      .sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
      .pNext = nullptr,
      .waitSemaphoreCount = 1,
      .pWaitSemaphores = &res.semaphore,
      .swapchainCount = 1,
      .pSwapchains = &self->swapchain,
      .pImageIndices = &self->current_image_index,
      .pResults = nullptr,
  };

  result = self->vk->QueuePresentKHR(self->queue, &present_info);
  g_mutex_unlock(&self->queue_mutex);

  if (result == VK_ERROR_OUT_OF_DATE_KHR || result == VK_SUBOPTIMAL_KHR) {
    // Mark for swapchain recreation on next acquire.
    self->swapchain_extent = {0, 0};
    return TRUE;  // Not a fatal error.
  }

  // Periodic DeviceWaitIdle for Mesa Dozen (dzn) D3D12 translation layer.
  // Impeller creates 1-2 VkFences fresh per frame (in CommandQueueVK::Submit)
  // that are destroyed after the GPU signals them. On dzn, each maps to a
  // D3D12 fence. dzn has internal resource leaks in its fence and command
  // allocator handling: at 60fps, ~5400+ create/destroy cycles over 90s
  // accumulate leaked D3D12 resources, causing "D3D12: Removing Device".
  // Confirmed NOT an Impeller or embedder leak: llvmpipe (CPU Vulkan) runs
  // indefinitely without issues - only dzn crashes.
  // Calling DeviceWaitIdle periodically forces dzn to drain all pending
  // D3D12 work and reclaim internal resources (command allocators, descriptor
  // heaps, staging buffers). The ~1ms stall every 10 seconds is imperceptible.
  if (self->is_dzn_device) {
    self->frame_counter++;
    if (self->frame_counter >= kDznDeviceWaitInterval) {
      self->vk->DeviceWaitIdle(self->device);
      self->frame_counter = 0;
    }
  }

  return result == VK_SUCCESS;
}

void fl_vulkan_manager_wait_idle(FlVulkanManager* self) {
  g_return_if_fail(FL_IS_VULKAN_MANAGER(self));
  if (self->device != VK_NULL_HANDLE && self->vk) {
    self->vk->DeviceWaitIdle(self->device);
  }
}

void fl_vulkan_manager_shutdown(FlVulkanManager* self) {
  g_return_if_fail(FL_IS_VULKAN_MANAGER(self));
  // Prevent the raster thread from acquiring/presenting images.
  // After this call, acquire_image/present_image return immediately.
  g_atomic_int_set(&self->shutting_down, TRUE);
  // Wait for any in-flight GPU work to finish.
  if (self->device != VK_NULL_HANDLE && self->vk) {
    self->vk->DeviceWaitIdle(self->device);
  }
}
