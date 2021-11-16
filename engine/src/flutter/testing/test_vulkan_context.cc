// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "test_vulkan_context.h"

#include "flutter/vulkan/vulkan_proc_table.h"

#ifdef OS_MACOSX
#define VULKAN_SO_PATH "libvk_swiftshader.dylib"
#elif OS_WIN
#define VULKAN_SO_PATH "vk_swiftshader.dll"
#else
#define VULKAN_SO_PATH "libvk_swiftshader.so"
#endif

namespace flutter {

TestVulkanContext::TestVulkanContext() : valid_(false) {
  vk_ = fml::MakeRefCounted<vulkan::VulkanProcTable>(VULKAN_SO_PATH);
  if (!vk_ || !vk_->HasAcquiredMandatoryProcAddresses()) {
    FML_DLOG(ERROR) << "Proc table has not acquired mandatory proc addresses.";
    return;
  }

  application_ = std::unique_ptr<vulkan::VulkanApplication>(
      new vulkan::VulkanApplication(*vk_, "Flutter Unittests", {}));
  if (!application_->IsValid()) {
    FML_DLOG(ERROR) << "Failed to initialize basic Vulkan state.";
    return;
  }
  if (!vk_->AreInstanceProcsSetup()) {
    FML_DLOG(ERROR) << "Failed to acquire full proc table.";
    return;
  }

  logical_device_ = application_->AcquireFirstCompatibleLogicalDevice();
  if (!logical_device_ || !logical_device_->IsValid()) {
    FML_DLOG(ERROR) << "Failed to create compatible logical device.";
    return;
  }

  valid_ = true;
}

TestVulkanContext::~TestVulkanContext() = default;

bool TestVulkanContext::IsValid() {
  return valid_;
}

}  // namespace flutter
