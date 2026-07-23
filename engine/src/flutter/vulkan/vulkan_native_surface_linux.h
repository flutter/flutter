// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_VULKAN_VULKAN_NATIVE_SURFACE_LINUX_H_
#define FLUTTER_VULKAN_VULKAN_NATIVE_SURFACE_LINUX_H_

#include "flutter/fml/build_config.h"
#include "flutter/fml/macros.h"

#ifndef FML_OS_LINUX
#error "vulkan_native_surface_linux.h is only available on Linux"
#endif
#include "vulkan_native_surface.h"

// Forward declarations for X11
typedef struct _XDisplay Display;
typedef unsigned long Window;

// Forward declarations for Wayland
struct wl_display;
struct wl_surface;

namespace vulkan {

/// Supported Linux windowing system types.
enum class LinuxWindowingSystem {
  kX11,
  kWayland,
};

/// A Vulkan native surface implementation for Linux, supporting both
/// X11 and Wayland windowing systems.
class VulkanNativeSurfaceLinux : public VulkanNativeSurface {
 public:
  /// Create a native surface for X11.
  ///
  /// @param display  The X11 display connection. Not owned by this instance.
  /// @param window   The X11 window.
  /// @param width    The width of the window in pixels.
  /// @param height   The height of the window in pixels.
  VulkanNativeSurfaceLinux(Display* display,
                           Window window,
                           int32_t width,
                           int32_t height);

  /// Create a native surface for Wayland.
  ///
  /// @param display  The Wayland display connection. Not owned by this
  /// instance.
  /// @param surface  The Wayland surface. Not owned by this instance.
  /// @param width    The width of the surface in pixels.
  /// @param height   The height of the surface in pixels.
  VulkanNativeSurfaceLinux(wl_display* display,
                           wl_surface* surface,
                           int32_t width,
                           int32_t height);

  ~VulkanNativeSurfaceLinux() override;

  // |VulkanNativeSurface|
  const char* GetExtensionName() const override;

  // |VulkanNativeSurface|
  VkSurfaceKHR CreateSurfaceHandle(
      VulkanProcTable& vk,
      const VulkanHandle<VkInstance>& instance) const override;

  // |VulkanNativeSurface|
  bool IsValid() const override;

  // |VulkanNativeSurface|
  SkISize GetSize() const override;

  /// Returns the windowing system type.
  LinuxWindowingSystem GetWindowingSystem() const { return windowing_system_; }

 private:
  LinuxWindowingSystem windowing_system_;

  // X11 members
  Display* x11_display_ = nullptr;
  Window x11_window_ = 0;

  // Wayland members
  wl_display* wayland_display_ = nullptr;
  wl_surface* wayland_surface_ = nullptr;

  // Surface dimensions
  int32_t width_ = 0;
  int32_t height_ = 0;

  bool valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(VulkanNativeSurfaceLinux);
};

}  // namespace vulkan

#endif  // FLUTTER_VULKAN_VULKAN_NATIVE_SURFACE_LINUX_H_
