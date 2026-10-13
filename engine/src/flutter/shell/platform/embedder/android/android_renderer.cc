// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/android/android_renderer.h"

#include <android/api-level.h>

#include <memory>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/impeller/renderer/backend/vulkan/context_vk.h"
#include "flutter/shell/platform/embedder/android/android_context_dynamic_impeller.h"
#include "flutter/shell/platform/embedder/android/android_context_gl_impeller.h"
#include "flutter/shell/platform/embedder/android/android_context_vk_impeller.h"
#include "flutter/shell/platform/embedder/android/android_surface_dynamic_impeller.h"
#include "flutter/shell/platform/embedder/android/android_surface_gl_impeller.h"

#if !SLIMPELLER
#include "flutter/shell/platform/embedder/android/android_context_gl_skia.h"
#include "flutter/shell/platform/embedder/android/android_surface_gl_skia.h"
#include "flutter/shell/platform/embedder/android/android_surface_software.h"
#endif  // !SLIMPELLER

#if IMPELLER_ENABLE_VULKAN  // b/258506856 for why this is behind an if
#include "flutter/shell/platform/embedder/android/android_surface_vk_impeller.h"
#endif

namespace flutter {

namespace {

static constexpr int kMinAPILevelHCPP = 34;

AndroidContext::ContextSettings CreateContextSettings(
    const Settings& p_settings) {
  AndroidContext::ContextSettings settings;
  settings.enable_gpu_tracing = p_settings.enable_vulkan_gpu_tracing;
  settings.enable_validation = p_settings.enable_vulkan_validation;
  settings.enable_surface_control = p_settings.enable_surface_control;
  return settings;
}
}  // namespace

AndroidSurfaceFactoryImpl::AndroidSurfaceFactoryImpl(
    const std::shared_ptr<AndroidContext>& context,
    bool enable_impeller,
    bool lazy_shader_mode,
    CreateSurfaceTransaction create_transaction)
    : android_context_(context),
      enable_impeller_(enable_impeller),
      lazy_shader_mode_(lazy_shader_mode),
      create_transaction_(std::move(create_transaction)) {}

AndroidSurfaceFactoryImpl::~AndroidSurfaceFactoryImpl() = default;

std::unique_ptr<AndroidSurface> AndroidSurfaceFactoryImpl::CreateSurface() {
  if (android_context_->IsDynamicSelection()) {
    auto cast_ptr = std::static_pointer_cast<AndroidContextDynamicImpeller>(
        android_context_);
    return std::make_unique<AndroidSurfaceDynamicImpeller>(cast_ptr,
                                                           create_transaction_);
  }
  switch (android_context_->RenderingApi()) {
#if !SLIMPELLER
    case AndroidRenderingAPI::kSoftware:
      return std::make_unique<AndroidSurfaceSoftware>();
    case AndroidRenderingAPI::kSkiaOpenGLES:
      return std::make_unique<AndroidSurfaceGLSkia>(
          std::static_pointer_cast<AndroidContextGLSkia>(android_context_));
#endif  // !SLIMPELLER
    case AndroidRenderingAPI::kImpellerOpenGLES:
      return std::make_unique<AndroidSurfaceGLImpeller>(
          std::static_pointer_cast<AndroidContextGLImpeller>(android_context_));
    case AndroidRenderingAPI::kImpellerVulkan:
      return std::make_unique<AndroidSurfaceVKImpeller>(
          std::static_pointer_cast<AndroidContextVKImpeller>(android_context_),
          create_transaction_);
    case AndroidRenderingAPI::kImpellerAutoselect: {
      auto cast_ptr = std::static_pointer_cast<AndroidContextDynamicImpeller>(
          android_context_);
      return std::make_unique<AndroidSurfaceDynamicImpeller>(
          cast_ptr, create_transaction_);
    }
  }
  FML_UNREACHABLE();
}

static std::shared_ptr<flutter::AndroidContext> CreateAndroidContext(
    const flutter::TaskRunners& task_runners,
    AndroidRenderingAPI android_rendering_api,
    bool enable_opengl_gpu_tracing,
    const AndroidContext::ContextSettings& settings,
    std::shared_ptr<fml::BasicTaskRunner> io_task_runner) {
  switch (android_rendering_api) {
#if !SLIMPELLER
    case AndroidRenderingAPI::kSoftware:
      return std::make_shared<AndroidContext>(AndroidRenderingAPI::kSoftware);
    case AndroidRenderingAPI::kSkiaOpenGLES:
      return std::make_unique<AndroidContextGLSkia>(
          fml::MakeRefCounted<AndroidEnvironmentGL>(),  //
          task_runners                                  //
      );
#endif  // !SLIMPELLER
    case AndroidRenderingAPI::kImpellerVulkan:
      return std::make_unique<AndroidContextVKImpeller>(settings);
    case AndroidRenderingAPI::kImpellerOpenGLES:
      return std::make_unique<AndroidContextGLImpeller>(
          std::make_unique<impeller::egl::Display>(), enable_opengl_gpu_tracing,
          std::move(io_task_runner));
    case AndroidRenderingAPI::kImpellerAutoselect:
      // Determine if we're using GL or Vulkan.
      return std::make_unique<AndroidContextDynamicImpeller>(
          settings, std::move(io_task_runner));
  }
  FML_UNREACHABLE();
}

AndroidRenderer::AndroidRenderer(
    const TaskRunners& task_runners,
    const Settings& settings,
    AndroidRenderingAPI rendering_api,
    std::shared_ptr<fml::BasicTaskRunner> io_task_runner,
    CreateSurfaceTransaction create_transaction)
    : AndroidRenderer(task_runners,
                      settings,
                      CreateAndroidContext(task_runners,
                                           rendering_api,
                                           settings.enable_opengl_gpu_tracing,
                                           CreateContextSettings(settings),
                                           std::move(io_task_runner)),
                      std::move(create_transaction)) {}

AndroidRenderer::AndroidRenderer(
    const TaskRunners& task_runners,
    const Settings& settings,
    std::shared_ptr<AndroidContext> android_context,
    CreateSurfaceTransaction create_transaction)
    : task_runners_(task_runners),
      android_context_(std::move(android_context)) {
  if (android_context_) {
    FML_CHECK(android_context_->IsValid())
        << "Could not create surface from invalid Android context.";
    surface_factory_ = std::make_shared<AndroidSurfaceFactoryImpl>(
        android_context_,                           //
        settings.enable_impeller,                   //
        settings.impeller_enable_lazy_shader_mode,  //
        std::move(create_transaction)               //
    );
    android_surface_ = surface_factory_->CreateSurface();
    android_meets_hcpp_criteria_ =
        settings.enable_surface_control &&
        android_get_device_api_level() >= kMinAPILevelHCPP &&
        settings.enable_impeller;
    FML_CHECK(android_surface_ && android_surface_->IsValid())
        << "Could not create an OpenGL, Vulkan or Software surface to set "
           "up "
           "rendering.";
  }
}

AndroidRenderer::~AndroidRenderer() = default;

bool AndroidRenderer::SetNativeWindow(
    fml::RefPtr<AndroidNativeWindow> native_window) {
  if (!android_surface_) {
    return false;
  }
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetRasterTaskRunner(),
      [&latch, surface = android_surface_.get(),
       native_window = std::move(native_window)]() {
        surface->SetNativeWindow(native_window);
        latch.Signal();
      });
  latch.Wait();
  return true;
}

void AndroidRenderer::SwapNativeWindow(
    fml::RefPtr<AndroidNativeWindow> native_window) {
  if (!android_surface_) {
    return;
  }
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetRasterTaskRunner(),
      [&latch, surface = android_surface_.get(),
       native_window = std::move(native_window)]() {
        surface->TeardownOnScreenContext();
        surface->SetNativeWindow(native_window);
        latch.Signal();
      });
  latch.Wait();
}

void AndroidRenderer::TeardownSurface() {
  if (!android_surface_) {
    return;
  }
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetRasterTaskRunner(),
      [&latch, surface = android_surface_.get()]() {
        surface->TeardownOnScreenContext();
        latch.Signal();
      });
  latch.Wait();
}

void AndroidRenderer::ResizeSurface(const DlISize& size) {
  if (!android_surface_) {
    return;
  }
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      task_runners_.GetRasterTaskRunner(),  //
      [&latch, surface = android_surface_.get(), size]() {
        surface->OnScreenSurfaceResize(size);
        latch.Signal();
      });
  latch.Wait();
}

std::unique_ptr<Surface> AndroidRenderer::CreateRenderingSurface() {
  if (!android_surface_) {
    return nullptr;
  }
  return android_surface_->CreateGPUSurface(
      android_context_->GetMainSkiaContext().get());
}

std::unique_ptr<SnapshotSurfaceProducer>
AndroidRenderer::CreateSnapshotSurfaceProducer() {
  if (!android_surface_) {
    return nullptr;
  }
  return std::make_unique<AndroidSnapshotSurfaceProducer>(*android_surface_);
}

bool AndroidRenderer::MakeResourceContextCurrent() const {
  if (!android_surface_) {
    return false;
  }
  return android_surface_->ResourceContextMakeCurrent();
}

void AndroidRenderer::ReleaseResourceContext() const {
  if (android_surface_) {
    android_surface_->ResourceContextClearCurrent();
  }
}

std::shared_ptr<impeller::Context> AndroidRenderer::GetImpellerContext() const {
  if (android_surface_) {
    return android_surface_->GetImpellerContext();
  }
  return android_context_->GetImpellerContext();
}

bool AndroidRenderer::IsSurfaceControlEnabled() const {
  // This needs to know if we're actually using HCPP.
  return android_meets_hcpp_criteria_ &&
         android_context_->RenderingApi() ==
             AndroidRenderingAPI::kImpellerVulkan &&
         impeller::ContextVK::Cast(*android_context_->GetImpellerContext())
             .GetShouldEnableSurfaceControlSwapchain();
}

void AndroidRenderer::SetupImpellerContext() {
  android_context_->SetupImpellerContext();
  android_surface_->SetupImpellerSurface();
}

}  // namespace flutter
