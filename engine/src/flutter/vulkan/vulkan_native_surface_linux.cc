// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vulkan_native_surface_linux.h"

#include "flutter/fml/logging.h"

// Vulkan headers must be included after the native windowing system headers
// are forward-declared. The actual includes happen via vulkan_proc_table.h.

namespace vulkan {

VulkanNativeSurfaceLinux::VulkanNativeSurfaceLinux(Display* display,
                                                   Window window,
                                                   int32_t width,
                                                   int32_t height)
    : windowing_system_(LinuxWindowingSystem::kX11),
      x11_display_(display),
      x11_window_(window),
      width_(width),
      height_(height) {
  if (x11_display_ == nullptr || x11_window_ == 0) {
    FML_LOG(ERROR) << "Invalid X11 display or window.";
    return;
  }
  if (width_ <= 0 || height_ <= 0) {
    FML_LOG(ERROR) << "Invalid surface dimensions: " << width_ << "x"
                   << height_;
    return;
  }
  valid_ = true;
}

VulkanNativeSurfaceLinux::VulkanNativeSurfaceLinux(wl_display* display,
                                                   wl_surface* surface,
                                                   int32_t width,
                                                   int32_t height)
    : windowing_system_(LinuxWindowingSystem::kWayland),
      wayland_display_(display),
      wayland_surface_(surface),
      width_(width),
      height_(height) {
  if (wayland_display_ == nullptr || wayland_surface_ == nullptr) {
    FML_LOG(ERROR) << "Invalid Wayland display or surface.";
    return;
  }
  if (width_ <= 0 || height_ <= 0) {
    FML_LOG(ERROR) << "Invalid surface dimensions: " << width_ << "x"
                   << height_;
    return;
  }
  valid_ = true;
}

VulkanNativeSurfaceLinux::~VulkanNativeSurfaceLinux() = default;

const char* VulkanNativeSurfaceLinux::GetExtensionName() const {
  switch (windowing_system_) {
    case LinuxWindowingSystem::kX11:
      // https://registry.khronos.org/vulkan/specs/1.3-extensions/man/html/VK_KHR_xlib_surface.html
      return VK_KHR_XLIB_SURFACE_EXTENSION_NAME;
    case LinuxWindowingSystem::kWayland:
      // https://registry.khronos.org/vulkan/specs/1.3-extensions/man/html/VK_KHR_wayland_surface.html
      return VK_KHR_WAYLAND_SURFACE_EXTENSION_NAME;
  }
  FML_UNREACHABLE();
  return nullptr;
}

VkSurfaceKHR VulkanNativeSurfaceLinux::CreateSurfaceHandle(
    VulkanProcTable& vk,
    const VulkanHandle<VkInstance>& instance) const {
  if (!vk.IsValid() || !instance) {
    FML_LOG(ERROR) << "Invalid Vulkan proc table or instance.";
    return VK_NULL_HANDLE;
  }

  if (!valid_) {
    FML_LOG(ERROR) << "Cannot create surface from invalid native surface.";
    return VK_NULL_HANDLE;
  }

  VkSurfaceKHR surface = VK_NULL_HANDLE;

  switch (windowing_system_) {
    case LinuxWindowingSystem::kX11: {
      if (!vk.CreateXlibSurfaceKHR) {
        FML_LOG(ERROR) << "vkCreateXlibSurfaceKHR is not available.";
        return VK_NULL_HANDLE;
      }
      const VkXlibSurfaceCreateInfoKHR create_info = {
          .sType = VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR,
          .pNext = nullptr,
          .flags = 0,
          .dpy = x11_display_,
          .window = x11_window_,
      };

      if (VK_CALL_LOG_ERROR(vk.CreateXlibSurfaceKHR(
              instance, &create_info, nullptr, &surface)) != VK_SUCCESS) {
        FML_LOG(ERROR) << "Failed to create X11 Vulkan surface.";
        return VK_NULL_HANDLE;
      }
      break;
    }
    case LinuxWindowingSystem::kWayland: {
      if (!vk.CreateWaylandSurfaceKHR) {
        FML_LOG(ERROR) << "vkCreateWaylandSurfaceKHR is not available.";
        return VK_NULL_HANDLE;
      }
      const VkWaylandSurfaceCreateInfoKHR create_info = {
          .sType = VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR,
          .pNext = nullptr,
          .flags = 0,
          .display = wayland_display_,
          .surface = wayland_surface_,
      };

      if (VK_CALL_LOG_ERROR(vk.CreateWaylandSurfaceKHR(
              instance, &create_info, nullptr, &surface)) != VK_SUCCESS) {
        FML_LOG(ERROR) << "Failed to create Wayland Vulkan surface.";
        return VK_NULL_HANDLE;
      }
      break;
    }
  }

  return surface;
}

bool VulkanNativeSurfaceLinux::IsValid() const {
  return valid_;
}

SkISize VulkanNativeSurfaceLinux::GetSize() const {
  return valid_ ? SkISize::Make(width_, height_) : SkISize::Make(0, 0);
}

}  // namespace vulkan
