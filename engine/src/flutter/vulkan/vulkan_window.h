// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_VULKAN_VULKAN_WINDOW_H_
#define FLUTTER_VULKAN_VULKAN_WINDOW_H_

#include <memory>
#include <tuple>
#include <utility>
#include <vector>

#include "flutter/vulkan/vulkan_proc_table.h"
#include "lib/fxl/compiler_specific.h"
#include "lib/fxl/macros.h"
#include "third_party/skia/include/core/SkRefCnt.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/GrContext.h"
#include "third_party/skia/include/gpu/vk/GrVkBackendContext.h"

namespace vulkan {

class VulkanNativeSurface;
class VulkanDevice;
class VulkanSurface;
class VulkanSwapchain;
class VulkanImage;
class VulkanApplication;
class VulkanBackbuffer;

class VulkanWindow {
 public:
  VulkanWindow(fxl::RefPtr<VulkanProcTable> proc_table,
               std::unique_ptr<VulkanNativeSurface> native_surface);

  ~VulkanWindow();

  bool IsValid() const;

  GrContext* GetSkiaGrContext();

  sk_sp<SkSurface> AcquireSurface();

  bool SwapBuffers();

 private:
  bool valid_;
  fxl::RefPtr<VulkanProcTable> vk;
  // Note: The order of objects here is important because the
  // GrVkBackendContext assumes ownership of the device and instance handles.
  sk_sp<GrVkBackendContext> skia_vk_backend_context_;
  std::unique_ptr<VulkanApplication> application_;
  std::unique_ptr<VulkanDevice> logical_device_;
  std::unique_ptr<VulkanSurface> surface_;
  std::unique_ptr<VulkanSwapchain> swapchain_;
  sk_sp<GrContext> skia_gr_context_;

  bool CreateSkiaGrContext();

  sk_sp<GrVkBackendContext> CreateSkiaBackendContext();

  FXL_WARN_UNUSED_RESULT
  bool RecreateSwapchain();

  FXL_DISALLOW_COPY_AND_ASSIGN(VulkanWindow);
};

}  // namespace vulkan

#endif  // FLUTTER_VULKAN_VULKAN_WINDOW_H_
