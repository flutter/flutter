// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_context_vulkan_impeller.h"

#include "flutter/fml/paths.h"
#include "flutter/impeller/entity/vk/entity_shaders_vk.h"
#include "flutter/impeller/entity/vk/framebuffer_blend_shaders_vk.h"
#include "flutter/impeller/entity/vk/modern_shaders_vk.h"
#include "flutter/impeller/renderer/backend/vulkan/context_vk.h"

#if IMPELLER_ENABLE_3D
#include "flutter/impeller/scene/shaders/vk/scene_shaders_vk.h"  // nogncheck
#endif  // IMPELLER_ENABLE_3D

namespace flutter {

static std::shared_ptr<impeller::Context> CreateImpellerContext(
    const fml::RefPtr<vulkan::VulkanProcTable>& proc_table,
    bool enable_vulkan_validation,
    bool enable_gpu_tracing) {
  std::vector<std::shared_ptr<fml::Mapping>> shader_mappings = {
      std::make_shared<fml::NonOwnedMapping>(impeller_entity_shaders_vk_data,
                                             impeller_entity_shaders_vk_length),
      std::make_shared<fml::NonOwnedMapping>(
          impeller_framebuffer_blend_shaders_vk_data,
          impeller_framebuffer_blend_shaders_vk_length),
#if IMPELLER_ENABLE_3D
      std::make_shared<fml::NonOwnedMapping>(impeller_scene_shaders_vk_data,
                                             impeller_scene_shaders_vk_length),
#endif
      std::make_shared<fml::NonOwnedMapping>(impeller_modern_shaders_vk_data,
                                             impeller_modern_shaders_vk_length),
  };

  PFN_vkGetInstanceProcAddr instance_proc_addr =
      proc_table->NativeGetInstanceProcAddr();

  impeller::ContextVK::Settings settings;
  settings.proc_address_callback = instance_proc_addr;
  settings.shader_libraries_data = std::move(shader_mappings);
  settings.cache_directory = fml::paths::GetCachesDirectory();
  settings.enable_validation = enable_vulkan_validation;
  settings.enable_gpu_tracing = enable_gpu_tracing;

  auto context = impeller::ContextVK::Create(std::move(settings));

  if (context && impeller::CapabilitiesVK::Cast(*context->GetCapabilities())
                     .AreValidationsEnabled()) {
    FML_LOG(IMPORTANT) << "Using the Impeller rendering backend (Vulkan with "
                          "Validation Layers).";
  } else {
    FML_LOG(IMPORTANT) << "Using the Impeller rendering backend (Vulkan).";
  }

  return context;
}

AndroidContextVulkanImpeller::AndroidContextVulkanImpeller(
    bool enable_validation,
    bool enable_gpu_tracing)
    : AndroidContext(AndroidRenderingAPI::kVulkan),
      proc_table_(fml::MakeRefCounted<vulkan::VulkanProcTable>()) {
  auto impeller_context =
      CreateImpellerContext(proc_table_, enable_validation, enable_gpu_tracing);
  SetImpellerContext(impeller_context);
  is_valid_ =
      proc_table_->HasAcquiredMandatoryProcAddresses() && impeller_context;
}

AndroidContextVulkanImpeller::~AndroidContextVulkanImpeller() = default;

bool AndroidContextVulkanImpeller::IsValid() const {
  return is_valid_;
}

}  // namespace flutter
