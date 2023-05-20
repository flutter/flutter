// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_context_vulkan_impeller.h"

#include "flutter/fml/paths.h"
#include "flutter/impeller/entity/vk/entity_shaders_vk.h"
#include "flutter/impeller/entity/vk/modern_shaders_vk.h"
#include "flutter/impeller/renderer/backend/vulkan/context_vk.h"
#include "flutter/impeller/scene/shaders/vk/scene_shaders_vk.h"

namespace flutter {

static std::shared_ptr<impeller::Context> CreateImpellerContext(
    const fml::RefPtr<vulkan::VulkanProcTable>& proc_table,
    std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner,
    bool enable_vulkan_validation) {
  std::vector<std::shared_ptr<fml::Mapping>> shader_mappings = {
      std::make_shared<fml::NonOwnedMapping>(impeller_entity_shaders_vk_data,
                                             impeller_entity_shaders_vk_length),
      std::make_shared<fml::NonOwnedMapping>(impeller_scene_shaders_vk_data,
                                             impeller_scene_shaders_vk_length),
      std::make_shared<fml::NonOwnedMapping>(impeller_modern_shaders_vk_data,
                                             impeller_modern_shaders_vk_length),
  };

  PFN_vkGetInstanceProcAddr instance_proc_addr =
      proc_table->NativeGetInstanceProcAddr();

  impeller::ContextVK::Settings settings;
  settings.proc_address_callback = instance_proc_addr;
  settings.shader_libraries_data = std::move(shader_mappings);
  settings.cache_directory = fml::paths::GetCachesDirectory();
  settings.worker_task_runner = std::move(worker_task_runner);
  settings.enable_validation = enable_vulkan_validation;
  return impeller::ContextVK::Create(std::move(settings));
}

AndroidContextVulkanImpeller::AndroidContextVulkanImpeller(
    bool enable_validation,
    std::shared_ptr<fml::ConcurrentTaskRunner> worker_task_runner)
    : AndroidContext(AndroidRenderingAPI::kVulkan),
      proc_table_(fml::MakeRefCounted<vulkan::VulkanProcTable>()) {
  auto impeller_context = CreateImpellerContext(
      proc_table_, std::move(worker_task_runner), enable_validation);
  SetImpellerContext(impeller_context);
  is_valid_ =
      proc_table_->HasAcquiredMandatoryProcAddresses() && impeller_context;
}

AndroidContextVulkanImpeller::~AndroidContextVulkanImpeller() = default;

bool AndroidContextVulkanImpeller::IsValid() const {
  return is_valid_;
}

}  // namespace flutter
