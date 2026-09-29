// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_MANAGER_H_

#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

#include "flutter/fml/build_config.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/android_rendering_selector.h"
#include "flutter/shell/platform/embedder/embedder.h"

#if FML_OS_ANDROID
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <android/native_window.h>
#else
// Stubs and type aliases for host unit testing
typedef void* EGLDisplay;
typedef void* EGLConfig;
typedef void* EGLContext;
typedef void* EGLSurface;
typedef int32_t EGLint;
struct ANativeWindow;
#ifndef EGL_NO_DISPLAY
#define EGL_NO_DISPLAY ((EGLDisplay)0)
#endif
#ifndef EGL_NO_CONTEXT
#define EGL_NO_CONTEXT ((EGLContext)0)
#endif
#ifndef EGL_NO_SURFACE
#define EGL_NO_SURFACE ((EGLSurface)0)
#endif
#ifndef EGL_DEFAULT_DISPLAY
#define EGL_DEFAULT_DISPLAY ((EGLDisplay)0)
#endif
#endif  // FML_OS_ANDROID

#include <vulkan/vulkan.h>
#if !defined(VK_USE_PLATFORM_ANDROID_KHR)
typedef VkFlags VkAndroidSurfaceCreateFlagsKHR;
typedef struct VkAndroidSurfaceCreateInfoKHR {
  VkStructureType sType;
  const void* pNext;
  VkAndroidSurfaceCreateFlagsKHR flags;
  struct ANativeWindow* window;
} VkAndroidSurfaceCreateInfoKHR;
typedef VkResult(VKAPI_PTR* PFN_vkCreateAndroidSurfaceKHR)(
    VkInstance instance,
    const VkAndroidSurfaceCreateInfoKHR* pCreateInfo,
    const VkAllocationCallbacks* pAllocator,
    VkSurfaceKHR* pSurface);
#ifndef VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR
#define VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR \
  ((VkStructureType)1000008000)
#endif
#endif

namespace flutter {

struct AndroidSurfaceDimensions {
  int32_t width = 0;
  int32_t height = 0;
};

/// @brief Manages platform window and graphics rendering contexts (EGL, Vulkan,
///        Software) for the Flutter Android Embedder, handling thread-safe
///        lifecycle, resource context pooling, and surface presentation.
class AndroidSurfaceManager {
 public:
  /// Creates a new surface manager configured for the specified rendering API.
  static std::unique_ptr<AndroidSurfaceManager> Create(
      AndroidRenderingAPI rendering_api);

  explicit AndroidSurfaceManager(AndroidRenderingAPI rendering_api);
  virtual ~AndroidSurfaceManager();

  AndroidRenderingAPI GetRenderingAPI() const { return rendering_api_; }

  /// Returns true if graphics subsystem was initialized successfully.
  bool IsValid() const;

  /// Associates the manager with a native window (e.g. from SurfaceView /
  /// SurfaceTexture). Thread-safe.
  bool SetNativeWindow(ANativeWindow* window, bool is_fake_window = false);

  /// Detaches and releases the native window reference. Thread-safe.
  void ClearNativeWindow();

  /// Returns current native window pointer. Thread-safe.
  ANativeWindow* GetNativeWindow() const;

  /// Returns dimensions of currently attached native window.
  AndroidSurfaceDimensions GetNativeWindowSize() const;

  /// Returns true if this manager is backed by a fake window (in unit testing).
  bool IsFakeWindow() const;

  // ---------------------------------------------------------------------------
  // OpenGL ES / EGL Lifecycle Methods
  // ---------------------------------------------------------------------------

  /// Makes the onscreen EGL context and surface current on the calling thread.
  bool MakeCurrent();

  /// If the onscreen EGL surface is currently bound on the calling thread,
  /// binds the fallback pbuffer (or surfaceless) surface to the onscreen
  /// context so that another thread can safely replace the onscreen window
  /// surface.
  void BindOffscreenPbufferIfCurrent();

  /// Clears the current EGL context and surface on the calling thread.
  bool ClearCurrent();

  /// Makes the offscreen/resource EGL context current on the calling thread.
  bool MakeResourceCurrent();

  /// Swaps buffers on the onscreen surface.
  virtual bool Present();

  /// Blits an offscreen FBO to FBO 0 of the current onscreen surface and
  /// swaps buffers.
  virtual bool BlitAndPresentOnscreenSurface(uint32_t offscreen_fbo,
                                             size_t width,
                                             size_t height);

  /// Clears the current onscreen surface to transparent and swaps buffers.
  virtual bool ClearAndPresentOnscreenSurface();

  /// Returns the current FBO (typically 0 for onscreen window surfaces).
  uint32_t GetFBO() const;

  /// Returns the EGLDisplay handle.
  EGLDisplay GetEGLDisplay() const;

  /// Returns the EGLConfig handle.
  EGLConfig GetEGLConfig() const { return egl_config_; }

  /// Returns the resource EGLContext handle.
  EGLContext GetResourceContext() const;

  // ---------------------------------------------------------------------------
  // Software Surface Lifecycle Methods
  // ---------------------------------------------------------------------------

  /// Presents a software-rendered pixel buffer to the native window.
  bool PresentSoftware(const void* allocation, size_t row_bytes, size_t height);

  // ---------------------------------------------------------------------------
  // Vulkan Lifecycle Methods
  // ---------------------------------------------------------------------------

  /// Returns true if the Vulkan subsystem was initialized successfully.
  bool InitializeVulkan();

  /// Returns true if the Vulkan instance and device were initialized.
  bool IsVulkanInitialized() const { return vk_instance_ != VK_NULL_HANDLE; }

  /// Returns the native VkInstance handle.
  VkInstance GetVulkanInstance() const { return vk_instance_; }

  /// Tears down the Vulkan instance and device resources.
  void TeardownVulkan();

  /// Populates the Vulkan renderer config struct for engine startup.
  void PopulateVulkanRendererConfig(FlutterVulkanRendererConfig* config);

  /// Acquires the next swapchain image for rendering.
  FlutterVulkanImage GetNextImage(const FlutterFrameInfo* frame_info);

  /// Presents the rendered image to the swapchain.
  virtual bool PresentImage(const FlutterVulkanImage* image);

  /// Resolves Vulkan function pointers dynamically.
  void* GetInstanceProcAddress(FlutterVulkanInstanceHandle instance,
                               const char* name);

  // ---------------------------------------------------------------------------
  // Embedder C-API Configuration Helpers
  // ---------------------------------------------------------------------------

  /// Populates OpenGL renderer config for
  /// FlutterEngineInitialize/FlutterEngineRun.
  void PopulateGLRendererConfig(FlutterOpenGLRendererConfig* config);

  /// Populates Software renderer config for
  /// FlutterEngineInitialize/FlutterEngineRun.
  void PopulateSoftwareRendererConfig(FlutterSoftwareRendererConfig* config);

  // ---------------------------------------------------------------------------
  // Overlay Surface & Offscreen Framebuffer Management
  // ---------------------------------------------------------------------------

  struct OffscreenFBO {
    uint32_t fbo = 0;
    uint32_t texture = 0;
    size_t width = 0;
    size_t height = 0;
  };

  /// Acquires an offscreen framebuffer object for rendering overlays.
  OffscreenFBO AcquireOffscreenFBO(size_t width, size_t height);

  /// Releases an offscreen framebuffer object back to the pool.
  void ReleaseOffscreenFBO(const OffscreenFBO& fbo);

  /// Blits the contents of offscreen_fbo to overlay_window and swaps its
  /// buffers.
  bool BlitAndSwapOverlaySurface(ANativeWindow* overlay_window,
                                 uint32_t offscreen_fbo,
                                 size_t width,
                                 size_t height);

  /// Destroys all cached overlay EGLSurfaces.
  void DestroyOverlaySurfaces();

 private:
  const AndroidRenderingAPI rendering_api_;
  mutable std::mutex window_mutex_;
  ANativeWindow* native_window_ = nullptr;
  bool is_fake_window_ = false;
  bool is_valid_ = false;

  // EGL state
  EGLDisplay egl_display_ = EGL_NO_DISPLAY;
  EGLConfig egl_config_ = nullptr;
  EGLContext egl_onscreen_context_ = EGL_NO_CONTEXT;
  EGLContext egl_resource_context_ = EGL_NO_CONTEXT;
  EGLSurface egl_onscreen_surface_ = EGL_NO_SURFACE;
  EGLSurface egl_onscreen_pbuffer_surface_ = EGL_NO_SURFACE;
  EGLSurface egl_resource_pbuffer_surface_ = EGL_NO_SURFACE;
  bool has_surfaceless_context_ = false;

  mutable std::mutex offscreen_fbo_mutex_;
  std::vector<OffscreenFBO> offscreen_fbo_pool_;

  mutable std::mutex overlay_surfaces_mutex_;
#if FML_OS_ANDROID
  std::unordered_map<ANativeWindow*, EGLSurface> overlay_egl_surfaces_;
#endif

  // Vulkan state
  void* vulkan_lib_handle_ = nullptr;
  uint32_t vk_version_ = VK_API_VERSION_1_1;
  VkInstance vk_instance_ = VK_NULL_HANDLE;
  VkPhysicalDevice vk_physical_device_ = VK_NULL_HANDLE;
  VkDevice vk_device_ = VK_NULL_HANDLE;
  uint32_t vk_graphics_queue_family_index_ = 0;
  VkQueue vk_queue_ = VK_NULL_HANDLE;
  VkSurfaceKHR vk_surface_ = VK_NULL_HANDLE;
  VkSwapchainKHR vk_swapchain_ = VK_NULL_HANDLE;
  VkSurfaceFormatKHR vk_surface_format_ = {};
  VkExtent2D vk_swapchain_extent_ = {0, 0};
  std::vector<VkImage> vk_swapchain_images_;
  std::vector<VkCommandBuffer> vk_command_buffers_;
  VkCommandPool vk_command_pool_ = VK_NULL_HANDLE;
  VkFence vk_acquire_fence_ = VK_NULL_HANDLE;
  uint32_t current_image_index_ = 0;

  std::vector<std::string> enabled_instance_extensions_;
  std::vector<const char*> enabled_instance_extensions_ptrs_;
  std::vector<std::string> enabled_device_extensions_;
  std::vector<const char*> enabled_device_extensions_ptrs_;

  // Vulkan function pointers
  PFN_vkGetInstanceProcAddr vk_get_instance_proc_addr_fn_ = nullptr;
  PFN_vkCreateInstance vk_create_instance_fn_ = nullptr;
  PFN_vkDestroyInstance vk_destroy_instance_fn_ = nullptr;
  PFN_vkEnumerateInstanceExtensionProperties
      vk_enumerate_instance_extension_properties_fn_ = nullptr;
  PFN_vkEnumerateInstanceLayerProperties
      vk_enumerate_instance_layer_properties_fn_ = nullptr;
  PFN_vkEnumeratePhysicalDevices vk_enumerate_physical_devices_fn_ = nullptr;
  PFN_vkGetPhysicalDeviceProperties vk_get_physical_device_properties_fn_ =
      nullptr;
  PFN_vkGetPhysicalDeviceQueueFamilyProperties
      vk_get_physical_device_queue_family_properties_fn_ = nullptr;
  PFN_vkEnumerateDeviceExtensionProperties
      vk_enumerate_device_extension_properties_fn_ = nullptr;
  PFN_vkCreateDevice vk_create_device_fn_ = nullptr;
  PFN_vkDestroyDevice vk_destroy_device_fn_ = nullptr;
  PFN_vkGetDeviceQueue vk_get_device_queue_fn_ = nullptr;
  PFN_vkDeviceWaitIdle vk_device_wait_idle_fn_ = nullptr;
  PFN_vkQueueWaitIdle vk_queue_wait_idle_fn_ = nullptr;
  PFN_vkCreateAndroidSurfaceKHR vk_create_android_surface_khr_fn_ = nullptr;
  PFN_vkDestroySurfaceKHR vk_destroy_surface_khr_fn_ = nullptr;
  PFN_vkGetPhysicalDeviceSurfaceSupportKHR
      vk_get_physical_device_surface_support_khr_fn_ = nullptr;
  PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR
      vk_get_physical_device_surface_capabilities_khr_fn_ = nullptr;
  PFN_vkGetPhysicalDeviceSurfaceFormatsKHR
      vk_get_physical_device_surface_formats_khr_fn_ = nullptr;
  PFN_vkGetPhysicalDeviceSurfacePresentModesKHR
      vk_get_physical_device_surface_present_modes_khr_fn_ = nullptr;
  PFN_vkCreateSwapchainKHR vk_create_swapchain_khr_fn_ = nullptr;
  PFN_vkDestroySwapchainKHR vk_destroy_swapchain_khr_fn_ = nullptr;
  PFN_vkGetSwapchainImagesKHR vk_get_swapchain_images_khr_fn_ = nullptr;
  PFN_vkAcquireNextImageKHR vk_acquire_next_image_khr_fn_ = nullptr;
  PFN_vkQueuePresentKHR vk_queue_present_khr_fn_ = nullptr;
  PFN_vkCreateCommandPool vk_create_command_pool_fn_ = nullptr;
  PFN_vkDestroyCommandPool vk_destroy_command_pool_fn_ = nullptr;
  PFN_vkAllocateCommandBuffers vk_allocate_command_buffers_fn_ = nullptr;
  PFN_vkFreeCommandBuffers vk_free_command_buffers_fn_ = nullptr;
  PFN_vkBeginCommandBuffer vk_begin_command_buffer_fn_ = nullptr;
  PFN_vkEndCommandBuffer vk_end_command_buffer_fn_ = nullptr;
  PFN_vkResetCommandBuffer vk_reset_command_buffer_fn_ = nullptr;
  PFN_vkCmdPipelineBarrier vk_cmd_pipeline_barrier_fn_ = nullptr;
  PFN_vkQueueSubmit vk_queue_submit_fn_ = nullptr;
  PFN_vkCreateFence vk_create_fence_fn_ = nullptr;
  PFN_vkDestroyFence vk_destroy_fence_fn_ = nullptr;
  PFN_vkWaitForFences vk_wait_for_fences_fn_ = nullptr;
  PFN_vkResetFences vk_reset_fences_fn_ = nullptr;

  bool InitializeEGL();
  void TeardownEGL();
  bool CreateOrUpdateOnscreenSurfaceLocked();
  void DestroyOnscreenSurfaceLocked();
  bool CreateOrUpdateVulkanSurfaceLocked();
  void DestroyVulkanSurfaceLocked();
  void DestroyVulkanSwapchainLocked();

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidSurfaceManager);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_MANAGER_H_
