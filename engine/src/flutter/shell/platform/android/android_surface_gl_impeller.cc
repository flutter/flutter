// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_surface_gl_impeller.h"

#include "flutter/fml/logging.h"
#include "flutter/impeller/renderer/backend/gles/context_gles.h"
#include "flutter/impeller/renderer/backend/gles/proc_table_gles.h"
#include "flutter/impeller/toolkit/egl/context.h"
#include "flutter/impeller/toolkit/egl/surface.h"
#include "flutter/shell/gpu/gpu_surface_gl_impeller.h"
#include "impeller/entity/gles/entity_shaders_gles.h"
#include "impeller/scene/shaders/gles/scene_shaders_gles.h"

namespace flutter {

class AndroidSurfaceGLImpeller::ReactorWorker final
    : public impeller::ReactorGLES::Worker {
 public:
  ReactorWorker() = default;

  // |impeller::ReactorGLES::Worker|
  ~ReactorWorker() override = default;

  // |impeller::ReactorGLES::Worker|
  bool CanReactorReactOnCurrentThreadNow(
      const impeller::ReactorGLES& reactor) const override {
    impeller::ReaderLock lock(mutex_);
    auto found = reactions_allowed_.find(std::this_thread::get_id());
    if (found == reactions_allowed_.end()) {
      return false;
    }
    return found->second;
  }

  void SetReactionsAllowedOnCurrentThread(bool allowed) {
    impeller::WriterLock lock(mutex_);
    reactions_allowed_[std::this_thread::get_id()] = allowed;
  }

 private:
  mutable impeller::RWMutex mutex_;
  std::map<std::thread::id, bool> reactions_allowed_ IPLR_GUARDED_BY(mutex_);

  FML_DISALLOW_COPY_AND_ASSIGN(ReactorWorker);
};

static std::shared_ptr<impeller::Context> CreateImpellerContext(
    const std::shared_ptr<impeller::ReactorGLES::Worker>& worker) {
  auto proc_table = std::make_unique<impeller::ProcTableGLES>(
      impeller::egl::CreateProcAddressResolver());

  if (!proc_table->IsValid()) {
    FML_LOG(ERROR) << "Could not create OpenGL proc table.";
    return nullptr;
  }

  std::vector<std::shared_ptr<fml::Mapping>> shader_mappings = {
      std::make_shared<fml::NonOwnedMapping>(
          impeller_entity_shaders_gles_data,
          impeller_entity_shaders_gles_length),
      std::make_shared<fml::NonOwnedMapping>(
          impeller_scene_shaders_gles_data, impeller_scene_shaders_gles_length),
  };

  auto context =
      impeller::ContextGLES::Create(std::move(proc_table), shader_mappings);
  if (!context) {
    FML_LOG(ERROR) << "Could not create OpenGLES Impeller Context.";
    return nullptr;
  }

  if (!context->AddReactorWorker(worker).has_value()) {
    FML_LOG(ERROR) << "Could not add reactor worker.";
    return nullptr;
  }
  FML_LOG(ERROR) << "Using the Impeller GL rendering backend.";
  return context;
}
AndroidSurfaceGLImpeller::AndroidSurfaceGLImpeller(
    const std::shared_ptr<AndroidContext>& android_context,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade)
    : AndroidSurface(android_context),
      reactor_worker_(std::shared_ptr<ReactorWorker>(new ReactorWorker())) {
  auto display = std::make_unique<impeller::egl::Display>();
  if (!display->IsValid()) {
    FML_DLOG(ERROR) << "Could not create EGL display.";
    return;
  }

  impeller::egl::ConfigDescriptor desc;
  desc.api = impeller::egl::API::kOpenGLES2;
  desc.color_format = impeller::egl::ColorFormat::kRGBA8888;
  desc.depth_bits = impeller::egl::DepthBits::kZero;
  desc.stencil_bits = impeller::egl::StencilBits::kEight;
  desc.samples = impeller::egl::Samples::kFour;

  desc.surface_type = impeller::egl::SurfaceType::kWindow;
  auto onscreen_config = display->ChooseConfig(desc);
  if (!onscreen_config) {
    FML_DLOG(ERROR) << "Could not choose onscreen config.";
    return;
  }

  desc.surface_type = impeller::egl::SurfaceType::kPBuffer;
  auto offscreen_config = display->ChooseConfig(desc);
  if (!offscreen_config) {
    FML_DLOG(ERROR) << "Could not choose offscreen config.";
    return;
  }

  auto onscreen_context = display->CreateContext(*onscreen_config, nullptr);
  if (!onscreen_context) {
    FML_DLOG(ERROR) << "Could not create onscreen context.";
    return;
  }

  auto offscreen_context =
      display->CreateContext(*offscreen_config, onscreen_context.get());
  if (!offscreen_context) {
    FML_DLOG(ERROR) << "Could not create offscreen context.";
    return;
  }

  auto offscreen_surface =
      display->CreatePixelBufferSurface(*offscreen_config, 1u, 1u);
  if (!offscreen_surface) {
    FML_DLOG(ERROR) << "Could not create offscreen surface.";
    return;
  }

  if (!offscreen_context->MakeCurrent(*offscreen_surface)) {
    FML_DLOG(ERROR) << "Could not make offscreen context current.";
    return;
  }

  auto impeller_context = CreateImpellerContext(reactor_worker_);

  if (!impeller_context) {
    FML_DLOG(ERROR) << "Could not create Impeller context.";
    return;
  }

  if (!offscreen_context->ClearCurrent()) {
    FML_DLOG(ERROR) << "Could not clear offscreen context.";
    return;
  }

  // Setup context listeners.
  impeller::egl::Context::LifecycleListener listener =
      [worker =
           reactor_worker_](impeller::egl ::Context::LifecycleEvent event) {
        switch (event) {
          case impeller::egl::Context::LifecycleEvent::kDidMakeCurrent:
            worker->SetReactionsAllowedOnCurrentThread(true);
            break;
          case impeller::egl::Context::LifecycleEvent::kWillClearCurrent:
            worker->SetReactionsAllowedOnCurrentThread(false);
            break;
        }
      };
  if (!onscreen_context->AddLifecycleListener(listener).has_value() ||
      !offscreen_context->AddLifecycleListener(listener).has_value()) {
    FML_DLOG(ERROR) << "Could not add lifecycle listeners";
  }

  display_ = std::move(display);
  onscreen_config_ = std::move(onscreen_config);
  offscreen_config_ = std::move(offscreen_config);
  offscreen_surface_ = std::move(offscreen_surface);
  onscreen_context_ = std::move(onscreen_context);
  offscreen_context_ = std::move(offscreen_context);
  impeller_context_ = std::move(impeller_context);

  // The onscreen surface will be acquired once the native window is set.

  is_valid_ = true;
}

AndroidSurfaceGLImpeller::~AndroidSurfaceGLImpeller() = default;

// |AndroidSurface|
bool AndroidSurfaceGLImpeller::IsValid() const {
  return is_valid_;
}

// |AndroidSurface|
std::unique_ptr<Surface> AndroidSurfaceGLImpeller::CreateGPUSurface(
    GrDirectContext* gr_context) {
  auto surface =
      std::make_unique<GPUSurfaceGLImpeller>(this,              // delegate
                                             impeller_context_  // context
      );
  if (!surface->IsValid()) {
    return nullptr;
  }
  return surface;
}

// |AndroidSurface|
void AndroidSurfaceGLImpeller::TeardownOnScreenContext() {
  GLContextClearCurrent();
  onscreen_surface_.reset();
}

// |AndroidSurface|
bool AndroidSurfaceGLImpeller::OnScreenSurfaceResize(const SkISize& size) {
  // The size is unused. It was added only for iOS where the sizes were
  // necessary to re-create auxiliary buffers (stencil, depth, etc.).
  return RecreateOnscreenSurfaceAndMakeOnscreenContextCurrent();
}

// |AndroidSurface|
bool AndroidSurfaceGLImpeller::ResourceContextMakeCurrent() {
  if (!offscreen_context_ || !offscreen_surface_) {
    return false;
  }

  return offscreen_context_->MakeCurrent(*offscreen_surface_);
}

// |AndroidSurface|
bool AndroidSurfaceGLImpeller::ResourceContextClearCurrent() {
  if (!offscreen_context_ || !offscreen_surface_) {
    return false;
  }

  return offscreen_context_->ClearCurrent();
}

// |AndroidSurface|
bool AndroidSurfaceGLImpeller::SetNativeWindow(
    fml::RefPtr<AndroidNativeWindow> window) {
  native_window_ = std::move(window);
  return RecreateOnscreenSurfaceAndMakeOnscreenContextCurrent();
}

// |AndroidSurface|
std::unique_ptr<Surface> AndroidSurfaceGLImpeller::CreateSnapshotSurface() {
  FML_UNREACHABLE();
}

// |AndroidSurface|
std::shared_ptr<impeller::Context>
AndroidSurfaceGLImpeller::GetImpellerContext() {
  return impeller_context_;
}

// |GPUSurfaceGLDelegate|
std::unique_ptr<GLContextResult>
AndroidSurfaceGLImpeller::GLContextMakeCurrent() {
  return std::make_unique<GLContextDefaultResult>(OnGLContextMakeCurrent());
}

bool AndroidSurfaceGLImpeller::OnGLContextMakeCurrent() {
  if (!onscreen_surface_ || !onscreen_context_) {
    return false;
  }

  return onscreen_context_->MakeCurrent(*onscreen_surface_);
}

// |GPUSurfaceGLDelegate|
bool AndroidSurfaceGLImpeller::GLContextClearCurrent() {
  if (!onscreen_surface_ || !onscreen_context_) {
    return false;
  }

  return onscreen_context_->ClearCurrent();
}

// |GPUSurfaceGLDelegate|
SurfaceFrame::FramebufferInfo
AndroidSurfaceGLImpeller::GLContextFramebufferInfo() const {
  auto info = SurfaceFrame::FramebufferInfo{};
  info.supports_readback = true;
  info.supports_partial_repaint = false;
  return info;
}

// |GPUSurfaceGLDelegate|
void AndroidSurfaceGLImpeller::GLContextSetDamageRegion(
    const std::optional<SkIRect>& region) {
  // Not supported.
}

// |GPUSurfaceGLDelegate|
bool AndroidSurfaceGLImpeller::GLContextPresent(
    const GLPresentInfo& present_info) {
  // The FBO ID is superfluous and was introduced for iOS where the default
  // framebuffer was not FBO0.
  if (!onscreen_surface_) {
    return false;
  }
  return onscreen_surface_->Present();
}

// |GPUSurfaceGLDelegate|
GLFBOInfo AndroidSurfaceGLImpeller::GLContextFBO(GLFrameInfo frame_info) const {
  // FBO0 is the default window bound framebuffer in EGL environments.
  return GLFBOInfo{
      .fbo_id = 0,
  };
}

// |GPUSurfaceGLDelegate|
sk_sp<const GrGLInterface> AndroidSurfaceGLImpeller::GetGLInterface() const {
  return nullptr;
}

bool AndroidSurfaceGLImpeller::
    RecreateOnscreenSurfaceAndMakeOnscreenContextCurrent() {
  GLContextClearCurrent();
  if (!native_window_) {
    return false;
  }
  onscreen_surface_.reset();
  auto onscreen_surface = display_->CreateWindowSurface(
      *onscreen_config_, native_window_->handle());
  if (!onscreen_surface) {
    FML_DLOG(ERROR) << "Could not create onscreen surface.";
    return false;
  }
  onscreen_surface_ = std::move(onscreen_surface);
  return OnGLContextMakeCurrent();
}

}  // namespace flutter
