// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_TEST_VULKAN_CONTEXT_H_
#define FLUTTER_TESTING_TEST_VULKAN_CONTEXT_H_

#include "flutter/vulkan/vulkan_application.h"
#include "flutter/vulkan/vulkan_device.h"
#include "flutter/vulkan/vulkan_proc_table.h"

namespace flutter {

/// @brief  Utility class to create a Vulkan device context, a corresponding
///         Skia context, and device resources.
class TestVulkanContext {
 public:
  TestVulkanContext();
  ~TestVulkanContext();
  bool IsValid();

 private:
  bool valid_ = false;
  fml::RefPtr<vulkan::VulkanProcTable> vk_;
  std::unique_ptr<vulkan::VulkanApplication> application_;
  std::unique_ptr<vulkan::VulkanDevice> logical_device_;

  FML_DISALLOW_COPY_AND_ASSIGN(TestVulkanContext);
};

}  // namespace flutter

#endif  // FLUTTER_TESTING_TEST_VULKAN_CONTEXT_H_
