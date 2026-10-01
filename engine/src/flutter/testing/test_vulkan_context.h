// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TESTING_TEST_VULKAN_CONTEXT_H_
#define FLUTTER_TESTING_TEST_VULKAN_CONTEXT_H_

#include <string>
#include <vector>

#include "flutter/display_list/geometry/dl_geometry_types.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/testing/test_vulkan_image.h"
#include "flutter/vulkan/procs/vulkan_proc_table.h"
#include "flutter/vulkan/vulkan_application.h"
#include "flutter/vulkan/vulkan_device.h"

#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"

namespace flutter::testing {

class TestVulkanContext : public fml::RefCountedThreadSafe<TestVulkanContext> {
 public:
  TestVulkanContext();
  ~TestVulkanContext();

  std::optional<TestVulkanImage> CreateImage(const DlISize& size) const;

  sk_sp<GrDirectContext> GetGrDirectContext() const;

  /// The instance and device extensions this context enabled, in the form
  /// `FlutterVulkanRendererConfig` takes them. Impeller's embedder path checks
  /// its requirements against these lists rather than querying the driver.
  const std::vector<const char*>& GetEnabledInstanceExtensions() const {
    return enabled_instance_extension_names_;
  }
  const std::vector<const char*>& GetEnabledDeviceExtensions() const {
    return enabled_device_extension_names_;
  }

 private:
  fml::RefPtr<vulkan::VulkanProcTable> vk_;
  std::unique_ptr<vulkan::VulkanApplication> application_;
  std::unique_ptr<vulkan::VulkanDevice> device_;

  std::vector<std::string> enabled_instance_extensions_;
  std::vector<std::string> enabled_device_extensions_;
  std::vector<const char*> enabled_instance_extension_names_;
  std::vector<const char*> enabled_device_extension_names_;

  std::unique_ptr<vulkan::VulkanDevice> CreateLogicalDevice();

  sk_sp<GrDirectContext> context_;

  friend class EmbedderTestContextVulkan;
  friend class EmbedderConfigBuilder;

  FML_FRIEND_MAKE_REF_COUNTED(TestVulkanContext);
  FML_FRIEND_REF_COUNTED_THREAD_SAFE(TestVulkanContext);
  FML_DISALLOW_COPY_AND_ASSIGN(TestVulkanContext);
};

}  // namespace flutter::testing

#endif  // FLUTTER_TESTING_TEST_VULKAN_CONTEXT_H_
