// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_GPU_GPU_SURFACE_VULKAN_DELEGATE_H_
#define FLUTTER_SHELL_GPU_GPU_SURFACE_VULKAN_DELEGATE_H_

#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/vulkan/vulkan_proc_table.h"

namespace flutter {

class GPUSurfaceVulkanDelegate {
 public:
  ~GPUSurfaceVulkanDelegate();

  // Obtain a reference to the Vulkan implementation's proc table.
  virtual fml::RefPtr<vulkan::VulkanProcTable> vk() = 0;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_GPU_GPU_SURFACE_VULKAN_DELEGATE_H_
