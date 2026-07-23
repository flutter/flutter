// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_MANAGER_H_

#include <gdk/gdk.h>
#include <glib-object.h>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/vulkan/procs/vulkan_proc_table.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlVulkanManager,
                     fl_vulkan_manager,
                     FL,
                     VULKAN_MANAGER,
                     GObject)

/**
 * FlVulkanManager:
 *
 * Manages the Vulkan instance, device, and queue for Flutter rendering.
 */

/**
 * fl_vulkan_manager_new:
 * @window: (optional): a #GdkWindow to create the surface for.
 *
 * Creates an object that manages Vulkan resources for Flutter rendering.
 *
 * Returns: a new #FlVulkanManager, or %NULL if Vulkan is not available.
 */
FlVulkanManager* fl_vulkan_manager_new(GdkWindow* window);

/**
 * fl_vulkan_manager_is_available:
 *
 * Checks if Vulkan rendering is available on this system.
 *
 * Returns: %TRUE if Vulkan is available.
 */
gboolean fl_vulkan_manager_is_available(void);

/**
 * fl_vulkan_manager_get_vulkan_version:
 * @manager: an #FlVulkanManager.
 *
 * Gets the Vulkan API version.
 *
 * Returns: the Vulkan API version.
 */
uint32_t fl_vulkan_manager_get_vulkan_version(FlVulkanManager* manager);

/**
 * fl_vulkan_manager_get_instance:
 * @manager: an #FlVulkanManager.
 *
 * Gets the Vulkan instance handle.
 *
 * Returns: the VkInstance handle.
 */
VkInstance fl_vulkan_manager_get_instance(FlVulkanManager* manager);

/**
 * fl_vulkan_manager_get_physical_device:
 * @manager: an #FlVulkanManager.
 *
 * Gets the Vulkan physical device handle.
 *
 * Returns: the VkPhysicalDevice handle.
 */
VkPhysicalDevice fl_vulkan_manager_get_physical_device(
    FlVulkanManager* manager);

/**
 * fl_vulkan_manager_get_device:
 * @manager: an #FlVulkanManager.
 *
 * Gets the Vulkan logical device handle.
 *
 * Returns: the VkDevice handle.
 */
VkDevice fl_vulkan_manager_get_device(FlVulkanManager* manager);

/**
 * fl_vulkan_manager_get_queue:
 * @manager: an #FlVulkanManager.
 *
 * Gets the Vulkan graphics queue handle.
 *
 * Returns: the VkQueue handle.
 */
VkQueue fl_vulkan_manager_get_queue(FlVulkanManager* manager);

/**
 * fl_vulkan_manager_get_queue_family_index:
 * @manager: an #FlVulkanManager.
 *
 * Gets the Vulkan graphics queue family index.
 *
 * Returns: the queue family index.
 */
uint32_t fl_vulkan_manager_get_queue_family_index(FlVulkanManager* manager);

/**
 * fl_vulkan_manager_get_surface:
 * @manager: an #FlVulkanManager.
 *
 * Gets the Vulkan surface handle.
 *
 * Returns: the VkSurfaceKHR handle.
 */
VkSurfaceKHR fl_vulkan_manager_get_surface(FlVulkanManager* manager);

/**
 * fl_vulkan_manager_release_surface:
 * @manager: an #FlVulkanManager.
 *
 * Returns the VkSurfaceKHR and relinquishes ownership. After this call the
 * manager will no longer destroy the surface - the caller (Impeller) is
 * responsible for its lifetime.
 *
 * Returns: the VkSurfaceKHR handle (VK_NULL_HANDLE on error).
 */
VkSurfaceKHR fl_vulkan_manager_release_surface(FlVulkanManager* manager);

/**
 * fl_vulkan_manager_get_proc_table:
 * @manager: an #FlVulkanManager.
 *
 * Gets the Vulkan proc table.
 *
 * Returns: a pointer to the #VulkanProcTable.
 */
vulkan::VulkanProcTable* fl_vulkan_manager_get_proc_table(
    FlVulkanManager* manager);

/**
 * fl_vulkan_manager_get_enabled_instance_extensions:
 * @manager: an #FlVulkanManager.
 * @count: (out): location to store the number of extensions.
 *
 * Gets the enabled instance extensions.
 *
 * Returns: an array of extension name strings.
 */
const char** fl_vulkan_manager_get_enabled_instance_extensions(
    FlVulkanManager* manager,
    size_t* count);

/**
 * fl_vulkan_manager_get_enabled_device_extensions:
 * @manager: an #FlVulkanManager.
 * @count: (out): location to store the number of extensions.
 *
 * Gets the enabled device extensions.
 *
 * Returns: an array of extension name strings.
 */
const char** fl_vulkan_manager_get_enabled_device_extensions(
    FlVulkanManager* manager,
    size_t* count);

/**
 * fl_vulkan_manager_get_instance_proc_address:
 * @manager: an #FlVulkanManager.
 * @instance: the VkInstance or VK_NULL_HANDLE.
 * @name: the name of the function to look up.
 *
 * Gets a Vulkan instance function pointer.
 *
 * Returns: the function pointer, or %NULL if not found.
 */
void* fl_vulkan_manager_get_instance_proc_address(FlVulkanManager* manager,
                                                  VkInstance instance,
                                                  const char* name);

/**
 * fl_vulkan_manager_acquire_queue_mutex:
 * @manager: an #FlVulkanManager.
 *
 * Acquires the queue mutex for thread-safe queue operations.
 */
void fl_vulkan_manager_acquire_queue_mutex(FlVulkanManager* manager);

/**
 * fl_vulkan_manager_release_queue_mutex:
 * @manager: an #FlVulkanManager.
 *
 * Releases the queue mutex.
 */
void fl_vulkan_manager_release_queue_mutex(FlVulkanManager* manager);

/**
 * fl_vulkan_manager_get_window:
 * @manager: a #FlVulkanManager.
 *
 * Gets the GDK window associated with this Vulkan manager.
 *
 * Returns: the #GdkWindow, or %NULL if none.
 */
GdkWindow* fl_vulkan_manager_get_window(FlVulkanManager* manager);

/**
 * fl_vulkan_manager_set_subsurface_position:
 * @manager: a #FlVulkanManager.
 * @x: X offset in logical pixels from the toplevel window origin.
 * @y: Y offset in logical pixels from the toplevel window origin.
 *
 * On Wayland, repositions the Vulkan rendering subsurface within the toplevel
 * window. This is needed because the VkSurface lives on a child wl_surface
 * that must be positioned below the GTK header bar. On X11, this is a no-op.
 */
void fl_vulkan_manager_set_subsurface_position(FlVulkanManager* manager,
                                               gint x,
                                               gint y);

/**
 * fl_vulkan_manager_get_memory_properties:
 * @manager: a #FlVulkanManager.
 *
 * Gets the cached physical device memory properties. These are queried once
 * during initialization and cached to avoid redundant API calls per
 * backing store allocation (per GPUOpen best practices).
 *
 * Returns: a pointer to the cached VkPhysicalDeviceMemoryProperties.
 */
const VkPhysicalDeviceMemoryProperties* fl_vulkan_manager_get_memory_properties(
    FlVulkanManager* manager);

/**
 * fl_vulkan_manager_defer_image_destruction:
 * @manager: a #FlVulkanManager.
 * @image: the VkImage to destroy later.
 * @memory: the VkDeviceMemory to free later.
 *
 * Enqueues a VkImage and its backing memory for deferred destruction.
 * The resources will be destroyed on the next call to
 * fl_vulkan_manager_process_deferred_deletions(), which should be called
 * after a GPU fence guarantees the resources are no longer in use.
 */
void fl_vulkan_manager_defer_image_destruction(FlVulkanManager* manager,
                                               VkImage image,
                                               VkDeviceMemory memory);

/**
 * fl_vulkan_manager_process_deferred_deletions:
 * @manager: a #FlVulkanManager.
 *
 * Destroys all VkImages and frees all VkDeviceMemory that were previously
 * enqueued via fl_vulkan_manager_defer_image_destruction(). Call this after
 * a fence wait guarantees the GPU is no longer using these resources.
 */
void fl_vulkan_manager_process_deferred_deletions(FlVulkanManager* manager);

/**
 * fl_vulkan_manager_ensure_swapchain:
 * @manager: a #FlVulkanManager.
 * @width: the desired swapchain width in pixels.
 * @height: the desired swapchain height in pixels.
 *
 * Creates or recreates the Vulkan swapchain to match the given dimensions.
 * If the swapchain already exists with the correct size, this is a no-op.
 *
 * Must be called on the raster thread.
 *
 * Returns: %TRUE if the swapchain is ready.
 */
gboolean fl_vulkan_manager_ensure_swapchain(FlVulkanManager* manager,
                                            uint32_t width,
                                            uint32_t height);

/**
 * fl_vulkan_manager_acquire_image:
 * @manager: a #FlVulkanManager.
 * @width: the desired frame width in pixels.
 * @height: the desired frame height in pixels.
 *
 * Acquires the next swapchain image for rendering. Ensures the swapchain
 * matches the requested size, recreating it if necessary. Blocks until
 * the image is available.
 *
 * Must be called on the raster thread.
 *
 * Returns: a #FlutterVulkanImage with the acquired image handle and format.
 *   On failure, the image handle will be 0.
 */
FlutterVulkanImage fl_vulkan_manager_acquire_image(FlVulkanManager* manager,
                                                   uint32_t width,
                                                   uint32_t height);

/**
 * fl_vulkan_manager_present_image:
 * @manager: a #FlVulkanManager.
 * @image: the VkImage to present (reserved for future non-swapchain path).
 * @format: the VkFormat of the image (reserved for future non-swapchain path).
 *
 * Transitions the current swapchain image from VK_IMAGE_LAYOUT_GENERAL to
 * VK_IMAGE_LAYOUT_PRESENT_SRC_KHR and submits it for presentation. Uses
 * per-image semaphores for GPU-GPU synchronization and fences for CPU-side
 * command buffer reuse tracking.
 *
 * Must be called on the raster thread.
 *
 * Returns: %TRUE if presentation succeeded.
 */
gboolean fl_vulkan_manager_present_image(FlVulkanManager* manager,
                                         VkImage image,
                                         VkFormat format);

/**
 * fl_vulkan_manager_wait_idle:
 * @manager: a #FlVulkanManager.
 *
 * Waits for the Vulkan device to become idle. Use before shutdown to
 * ensure all GPU work is complete.
 */
void fl_vulkan_manager_wait_idle(FlVulkanManager* manager);

/**
 * fl_vulkan_manager_shutdown:
 * @manager: a #FlVulkanManager.
 *
 * Signals the Vulkan manager to stop accepting new acquire/present requests.
 * After this call, acquire_image and present_image return immediately with
 * failure. Also waits for any in-flight GPU work to complete.
 *
 * Call this before shutting down the Flutter engine to prevent the raster
 * thread from using Vulkan resources during teardown.
 */
void fl_vulkan_manager_shutdown(FlVulkanManager* manager);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VULKAN_MANAGER_H_
