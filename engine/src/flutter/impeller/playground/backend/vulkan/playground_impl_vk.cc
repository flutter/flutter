// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/backend/vulkan/playground_impl_vk.h"

#include "flutter/fml/paths.h"
#include "impeller/renderer/backend/vulkan/vk.h"

#define GLFW_INCLUDE_VULKAN
#include <GLFW/glfw3.h>

#include "flutter/fml/logging.h"
#include "flutter/fml/mapping.h"
#include "impeller/entity/vk/entity_shaders_vk.h"
#include "impeller/entity/vk/modern_shaders_vk.h"
#include "impeller/fixtures/vk/fixtures_shaders_vk.h"
#include "impeller/playground/imgui/vk/imgui_shaders_vk.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/surface_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"
#include "impeller/renderer/vk/compute_shaders_vk.h"
#include "impeller/scene/shaders/vk/scene_shaders_vk.h"

namespace impeller {

static std::vector<std::shared_ptr<fml::Mapping>>
ShaderLibraryMappingsForPlayground() {
  return {
      std::make_shared<fml::NonOwnedMapping>(impeller_entity_shaders_vk_data,
                                             impeller_entity_shaders_vk_length),
      std::make_shared<fml::NonOwnedMapping>(impeller_modern_shaders_vk_data,
                                             impeller_modern_shaders_vk_length),
      std::make_shared<fml::NonOwnedMapping>(
          impeller_fixtures_shaders_vk_data,
          impeller_fixtures_shaders_vk_length),
      std::make_shared<fml::NonOwnedMapping>(impeller_imgui_shaders_vk_data,
                                             impeller_imgui_shaders_vk_length),
      std::make_shared<fml::NonOwnedMapping>(impeller_scene_shaders_vk_data,
                                             impeller_scene_shaders_vk_length),
      std::make_shared<fml::NonOwnedMapping>(
          impeller_compute_shaders_vk_data, impeller_compute_shaders_vk_length),
  };
}

void PlaygroundImplVK::DestroyWindowHandle(WindowHandle handle) {
  if (!handle) {
    return;
  }
  ::glfwDestroyWindow(reinterpret_cast<GLFWwindow*>(handle));
}

PlaygroundImplVK::PlaygroundImplVK(PlaygroundSwitches switches)
    : PlaygroundImpl(switches),
      concurrent_loop_(fml::ConcurrentMessageLoop::Create()),
      handle_(nullptr, &DestroyWindowHandle) {
  if (!::glfwVulkanSupported()) {
#ifdef TARGET_OS_MAC
    VALIDATION_LOG << "Attempted to initialize a Vulkan playground on macOS "
                      "where Vulkan cannot be found. It can be installed via "
                      "MoltenVK and make sure to install it globally so "
                      "dlopen can find it.";
#else
    VALIDATION_LOG << "Attempted to initialize a Vulkan playground on a system "
                      "that does not support Vulkan.";
#endif
    return;
  }

  ::glfwDefaultWindowHints();
  ::glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
  ::glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE);

  auto window = ::glfwCreateWindow(1, 1, "Test", nullptr, nullptr);
  if (!window) {
    VALIDATION_LOG << "Unable to create glfw window";
    return;
  }

  handle_.reset(window);

  ContextVK::Settings context_settings;
  context_settings.proc_address_callback =
      reinterpret_cast<PFN_vkGetInstanceProcAddr>(
          &::glfwGetInstanceProcAddress);
  context_settings.shader_libraries_data = ShaderLibraryMappingsForPlayground();
  context_settings.cache_directory = fml::paths::GetCachesDirectory();
  context_settings.worker_task_runner = concurrent_loop_->GetTaskRunner();
  context_settings.enable_validation = switches_.enable_vulkan_validation;

  auto context = ContextVK::Create(std::move(context_settings));

  if (!context || !context->IsValid()) {
    VALIDATION_LOG << "Could not create Vulkan context in the playground.";
    return;
  }

  VkSurfaceKHR vk_surface;
  auto res =
      vk::Result{::glfwCreateWindowSurface(context->GetInstance(),  // instance
                                           window,                  // window
                                           nullptr,                 // allocator
                                           &vk_surface              // surface
                                           )};
  if (res != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create surface for GLFW window: "
                   << vk::to_string(res);
    return;
  }

  vk::UniqueSurfaceKHR surface{vk_surface, context->GetInstance()};
  if (!context->SetWindowSurface(std::move(surface))) {
    VALIDATION_LOG << "Could not setup surface for context.";
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
  return handle_.get();
}

// |PlaygroundImpl|
std::unique_ptr<Surface> PlaygroundImplVK::AcquireSurfaceFrame(
    std::shared_ptr<Context> context) {
  ContextVK* context_vk = reinterpret_cast<ContextVK*>(context_.get());
  return context_vk->AcquireNextSurface();
}

}  // namespace impeller
