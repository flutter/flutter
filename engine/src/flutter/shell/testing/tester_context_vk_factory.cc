// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/testing/tester_context_vk_factory.h"

#include <vector>

#include "flutter/fml/mapping.h"
#include "flutter/fml/paths.h"
#include "flutter/vulkan/swiftshader_path.h"
#include "impeller/base/validation.h"
#include "impeller/entity/vk/entity_shaders_vk.h"
#include "impeller/entity/vk/framebuffer_blend_shaders_vk.h"
#include "impeller/entity/vk/modern_shaders_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/surface_context_vk.h"
#include "impeller/renderer/vk/compute_shaders_vk.h"
#include "shell/gpu/gpu_surface_vulkan_impeller.h"

namespace flutter {

namespace {
std::vector<std::shared_ptr<fml::Mapping>> ShaderLibraryMappings() {
  return {
      std::make_shared<fml::NonOwnedMapping>(impeller_entity_shaders_vk_data,
                                             impeller_entity_shaders_vk_length),
      std::make_shared<fml::NonOwnedMapping>(impeller_modern_shaders_vk_data,
                                             impeller_modern_shaders_vk_length),
      std::make_shared<fml::NonOwnedMapping>(
          impeller_framebuffer_blend_shaders_vk_data,
          impeller_framebuffer_blend_shaders_vk_length),
      std::make_shared<fml::NonOwnedMapping>(
          impeller_compute_shaders_vk_data, impeller_compute_shaders_vk_length),
  };
}

class TesterContextVK : public TesterContext {
 public:
  TesterContextVK() = default;

  ~TesterContextVK() override {
    if (context_) {
      context_->Shutdown();
    }
  }

  bool Initialize(bool enable_validation) {
    InitializeVulkanProcTable();
    if (!proc_table_) {
      VALIDATION_LOG << "Could not initialize Vulkan proc table.";
      return false;
    }

    impeller::ContextVK::Settings context_settings;
    context_settings.proc_address_callback = proc_table_->GetInstanceProcAddr;
    context_settings.shader_libraries_data = ShaderLibraryMappings();
    context_settings.cache_directory = fml::paths::GetCachesDirectory();
    context_settings.enable_validation = enable_validation;

    context_ = impeller::ContextVK::Create(std::move(context_settings));
    if (!context_ || !context_->IsValid()) {
      VALIDATION_LOG << "Could not create Vulkan context.";
      return false;
    }

    impeller::vk::SurfaceKHR vk_surface;
    impeller::vk::HeadlessSurfaceCreateInfoEXT surface_create_info;
    auto res = context_->GetInstance().createHeadlessSurfaceEXT(
        &surface_create_info,  // surface create info
        nullptr,               // allocator
        &vk_surface            // surface
    );
    if (res != impeller::vk::Result::eSuccess) {
      VALIDATION_LOG << "Could not create surface for tester "
                     << impeller::vk::to_string(res);
      return false;
    }

    impeller::vk::UniqueSurfaceKHR surface{vk_surface, context_->GetInstance()};
    surface_context_ = context_->CreateSurfaceContext();
    if (!surface_context_->SetWindowSurface(std::move(surface),
                                            impeller::ISize{1, 1})) {
      VALIDATION_LOG << "Could not set up surface for context.";
      return false;
    }
    return true;
  }

  // |TesterContext|
  std::shared_ptr<impeller::Context> GetImpellerContext() const override {
    return context_;
  }

  // |TesterContext|
  std::unique_ptr<Surface> CreateRenderingSurface() override {
    FML_DCHECK(context_);
    auto surface =
        std::make_unique<GPUSurfaceVulkanImpeller>(nullptr, surface_context_);
    FML_DCHECK(surface->IsValid());
    return surface;
  }

 private:
  fml::RefPtr<vulkan::VulkanProcTable> proc_table_;
  std::shared_ptr<impeller::ContextVK> context_;
  std::shared_ptr<impeller::SurfaceContextVK> surface_context_;

  void InitializeVulkanProcTable() {
    const auto executable_directory_path =
        fml::paths::GetExecutableDirectoryPath();
    FML_CHECK(executable_directory_path.first);
    auto icd_directory = executable_directory_path.second;
    if (icd_directory.ends_with("exe.unstripped")) {
      icd_directory = fml::paths::GetDirectoryName(icd_directory);
    }
    std::string icd_path =
        fml::paths::JoinPaths({icd_directory, VULKAN_SO_PATH});

    proc_table_ =
        fml::MakeRefCounted<vulkan::VulkanProcTable>(icd_path.c_str());

    if (!proc_table_->HasAcquiredMandatoryProcAddresses()) {
      proc_table_ = nullptr;
    }
  }
};

}  // namespace

std::unique_ptr<TesterContext> TesterContextVKFactory::Create(
    bool enable_validation) {
  auto context = std::make_unique<TesterContextVK>();
  if (!context->Initialize(enable_validation)) {
    return nullptr;
  }
  return context;
}

}  // namespace flutter
