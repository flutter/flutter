// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/backend/vulkan/playground_impl_vk.h"

#include "impeller/renderer/backend/vulkan/vk.h"

#include <GLFW/glfw3.h>

#include "flutter/fml/logging.h"
#include "flutter/fml/mapping.h"
#include "impeller/entity/vk/entity_shaders_vk.h"
#include "impeller/fixtures/vk/fixtures_shaders_vk.h"
#include "impeller/playground/imgui/vk/imgui_shaders_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/surface_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"

namespace impeller {

static std::vector<std::shared_ptr<fml::Mapping>>
ShaderLibraryMappingsForPlayground() {
  return {
      std::make_shared<fml::NonOwnedMapping>(impeller_entity_shaders_vk_data,
                                             impeller_entity_shaders_vk_length),
      std::make_shared<fml::NonOwnedMapping>(
          impeller_fixtures_shaders_vk_data,
          impeller_fixtures_shaders_vk_length),
      std::make_shared<fml::NonOwnedMapping>(impeller_imgui_shaders_vk_data,
                                             impeller_imgui_shaders_vk_length),

  };
}

PlaygroundImplVK::PlaygroundImplVK()
    : concurrent_loop_(fml::ConcurrentMessageLoop::Create()) {
  if (!::glfwVulkanSupported()) {
    VALIDATION_LOG << "Attempted to initialize a Vulkan playground on a system "
                      "that does not support Vulkan.";
    return;
  }
  auto context = ContextVK::Create(reinterpret_cast<PFN_vkGetInstanceProcAddr>(
                                       &::glfwGetInstanceProcAddress),    //
                                   ShaderLibraryMappingsForPlayground(),  //
                                   nullptr,                               //
                                   concurrent_loop_->GetTaskRunner(),     //
                                   "Playground Library"                   //
  );

  if (!context || !context->IsValid()) {
    VALIDATION_LOG << "Could not create Vulkan context in the playground.";
    return;
  }

  context_ = std::move(context);
}

PlaygroundImplVK::~PlaygroundImplVK() = default;

// |PlaygroundImpl|
std::shared_ptr<Context> PlaygroundImplVK::GetContext() const {
  return context_;
}

// |PlaygroundImpl|
PlaygroundImpl::WindowHandle PlaygroundImplVK::GetWindowHandle() const {
  FML_UNREACHABLE();
}

// |PlaygroundImpl|
std::unique_ptr<Surface> PlaygroundImplVK::AcquireSurfaceFrame(
    std::shared_ptr<Context> context) {
  FML_UNREACHABLE();
}

}  // namespace impeller
