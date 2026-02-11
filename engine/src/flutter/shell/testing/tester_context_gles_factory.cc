// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/testing/tester_context_gles_factory.h"

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <EGL/eglplatform.h>
#include <cstring>
#include <memory>
#include <vector>

#include "flutter/common/graphics/gl_context_switch.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/message_loop.h"
#include "flutter/shell/gpu/gpu_surface_gl_delegate.h"
#include "flutter/shell/gpu/gpu_surface_gl_impeller.h"
#include "flutter/testing/test_swangle_utils.h"
#include "flutter/testing/test_swiftshader_utils.h"
#include "impeller/entity/gles/entity_shaders_gles.h"
#include "impeller/entity/gles/framebuffer_blend_shaders_gles.h"
#include "impeller/entity/gles/modern_shaders_gles.h"
#include "impeller/renderer/backend/gles/context_gles.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"
#include "third_party/abseil-cpp/absl/status/statusor.h"

namespace flutter {

namespace {

class TesterGLContext : public SwitchableGLContext {
 public:
  TesterGLContext(EGLDisplay display, EGLSurface surface, EGLContext context)
      : display_(display), surface_(surface), context_(context) {}

  bool SetCurrent() override {
    return ::eglMakeCurrent(display_, surface_, surface_, context_) == EGL_TRUE;
  }

  bool RemoveCurrent() override {
    ::eglMakeCurrent(display_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
    return true;
  }

 private:
  EGLDisplay display_;
  EGLSurface surface_;
  EGLContext context_;
};

class TesterGLESDelegate : public GPUSurfaceGLDelegate {
 public:
  static absl::StatusOr<TesterGLESDelegate> Create() {
    EGLDisplay display = flutter::testing::CreateSwangleDisplay();
    if (display == EGL_NO_DISPLAY) {
      return absl::InternalError("Could not create EGL display.");
    }

    if (::eglInitialize(display, nullptr, nullptr) != EGL_TRUE) {
      return absl::InternalError("Could not initialize EGL display.");
    }

    EGLint num_config = 0;
    const EGLint attribute_list[] = {EGL_RED_SIZE,
                                     8,
                                     EGL_GREEN_SIZE,
                                     8,
                                     EGL_BLUE_SIZE,
                                     8,
                                     EGL_ALPHA_SIZE,
                                     8,
                                     EGL_DEPTH_SIZE,
                                     24,
                                     EGL_STENCIL_SIZE,
                                     8,
                                     EGL_SURFACE_TYPE,
                                     EGL_PBUFFER_BIT,
                                     EGL_CONFORMANT,
                                     EGL_OPENGL_ES2_BIT,
                                     EGL_RENDERABLE_TYPE,
                                     EGL_OPENGL_ES2_BIT,
                                     EGL_NONE};

    EGLConfig config = nullptr;
    if (::eglChooseConfig(display, attribute_list, &config, 1, &num_config) !=
            EGL_TRUE ||
        num_config != 1) {
      return absl::InternalError("Could not choose EGL config.");
    }

    const EGLint context_attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2,
                                         EGL_NONE};

    EGLContext context =
        ::eglCreateContext(display, config, EGL_NO_CONTEXT, context_attributes);
    if (context == EGL_NO_CONTEXT) {
      return absl::InternalError("Could not create EGL context.");
    }

    // Create a pbuffer surface to make current
    const EGLint surface_attributes[] = {EGL_WIDTH, 1, EGL_HEIGHT, 1, EGL_NONE};
    EGLSurface surface =
        ::eglCreatePbufferSurface(display, config, surface_attributes);
    if (surface == EGL_NO_SURFACE) {
      ::eglDestroyContext(display, context);
      return absl::InternalError("Could not create EGL pbuffer surface.");
    }

    return TesterGLESDelegate(display, context, surface);
  }

  TesterGLESDelegate(TesterGLESDelegate&& other)
      : display_(other.display_),
        context_(other.context_),
        surface_(other.surface_) {
    other.display_ = EGL_NO_DISPLAY;
    other.context_ = EGL_NO_CONTEXT;
    other.surface_ = EGL_NO_SURFACE;
  }

  virtual ~TesterGLESDelegate() {
    if (display_ != EGL_NO_DISPLAY) {
      if (surface_ != EGL_NO_SURFACE) {
        ::eglDestroySurface(display_, surface_);
      }
      if (context_ != EGL_NO_CONTEXT) {
        ::eglDestroyContext(display_, context_);
      }
      ::eglTerminate(display_);
    }
  }

  bool IsContextCurrent() const { return ::eglGetCurrentContext() == context_; }

  // |GPUSurfaceGLDelegate|
  std::unique_ptr<GLContextResult> GLContextMakeCurrent() override {
    if (IsContextCurrent()) {
      return std::make_unique<GLContextDefaultResult>(true);
    }

    // Set the current context by instantiating a GLContextSwitch with a
    // TesterGLContext. This clears the current context on destruction of the
    // GLContextSwitch.
    return std::make_unique<GLContextSwitch>(
        std::make_unique<TesterGLContext>(display_, surface_, context_));
  }

  // |GPUSurfaceGLDelegate|
  bool GLContextClearCurrent() override {
    return ::eglMakeCurrent(display_, EGL_NO_SURFACE, EGL_NO_SURFACE,
                            EGL_NO_CONTEXT) == EGL_TRUE;
  }

  // |GPUSurfaceGLDelegate|
  bool GLContextPresent(const GLPresentInfo& present_info) override {
    return true;
  }

  // |GPUSurfaceGLDelegate|
  GLFBOInfo GLContextFBO(GLFrameInfo frame_info) const override {
    return GLFBOInfo{0, std::nullopt};
  }

  // |GPUSurfaceGLDelegate|
  SurfaceFrame::FramebufferInfo GLContextFramebufferInfo() const override {
    return SurfaceFrame::FramebufferInfo{.supports_readback = true};
  }

 private:
  TesterGLESDelegate(EGLDisplay display, EGLContext context, EGLSurface surface)
      : display_(display), context_(context), surface_(surface) {}

  EGLDisplay display_ = EGL_NO_DISPLAY;
  EGLContext context_ = EGL_NO_CONTEXT;
  EGLSurface surface_ = EGL_NO_SURFACE;

  FML_DISALLOW_COPY_AND_ASSIGN(TesterGLESDelegate);
};

class TesterGLESWorker : public impeller::ReactorGLES::Worker {
 public:
  explicit TesterGLESWorker(TesterGLESDelegate* delegate)
      : delegate_(delegate) {}

  bool CanReactorReactOnCurrentThreadNow(
      const impeller::ReactorGLES& reactor) const override {
    if (delegate_->IsContextCurrent()) {
      return true;
    }
    std::unique_ptr<GLContextResult> result = delegate_->GLContextMakeCurrent();
    if (!result->GetResult()) {
      return false;
    }
    // Move the result into a TaskObserver to ensure it is destroyed (and the
    // current egl context cleared) at the end of the current task.
    fml::MessageLoop::GetCurrent().AddTaskObserver(
        reinterpret_cast<intptr_t>(this),
        fml::MakeCopyable([this, result = std::move(result)]() {
          fml::MessageLoop::GetCurrent().RemoveTaskObserver(
              reinterpret_cast<intptr_t>(this));
        }));
    return true;
  }

 private:
  TesterGLESDelegate* delegate_;
};

class TesterContextGLES : public TesterContext {
 public:
  TesterContextGLES() = default;

  ~TesterContextGLES() override {
    if (context_) {
      std::shared_ptr<impeller::Context> raw_context = context_;
      raw_context->Shutdown();
    }
  }

  bool Initialize() {
    auto delegate_status = TesterGLESDelegate::Create();
    if (!delegate_status.ok()) {
      FML_LOG(ERROR) << delegate_status.status().message();
      return false;
    }
    delegate_ = std::make_unique<TesterGLESDelegate>(
        std::move(delegate_status.value()));

    auto switch_result = delegate_->GLContextMakeCurrent();
    if (!switch_result->GetResult()) {
      FML_LOG(ERROR) << "Could not make GLES context current.";
      return false;
    }

    auto resolver = [](const char* name) -> void* {
      return reinterpret_cast<void*>(eglGetProcAddress(name));
    };

    auto gl = std::make_unique<impeller::ProcTableGLES>(resolver);
    if (!gl->IsValid()) {
      FML_LOG(ERROR) << "Could not create valid proc table.";
      return false;
    }

    std::vector<std::shared_ptr<fml::Mapping>> shader_mappings = {
        std::make_shared<fml::NonOwnedMapping>(
            impeller_entity_shaders_gles_data,
            impeller_entity_shaders_gles_length),
        std::make_shared<fml::NonOwnedMapping>(
            impeller_modern_shaders_gles_data,
            impeller_modern_shaders_gles_length),
        std::make_shared<fml::NonOwnedMapping>(
            impeller_framebuffer_blend_shaders_gles_data,
            impeller_framebuffer_blend_shaders_gles_length),
    };
    context_ = impeller::ContextGLES::Create(impeller::Flags{}, std::move(gl),
                                             shader_mappings, false);

    if (!context_ ||
        !static_cast<std::shared_ptr<impeller::Context>>(context_)->IsValid()) {
      FML_LOG(ERROR) << "Could not create OpenGLES context.";
      return false;
    }

    worker_ = std::make_shared<TesterGLESWorker>(delegate_.get());
    context_->AddReactorWorker(worker_);

    return true;
  }

  // |TesterContext|
  std::shared_ptr<impeller::Context> GetImpellerContext() const override {
    return context_;
  }

  // |TesterContext|
  std::unique_ptr<Surface> CreateRenderingSurface() override {
    auto surface = std::make_unique<GPUSurfaceGLImpeller>(
        delegate_.get(), context_, /*render_to_surface=*/true);
    if (!surface->IsValid()) {
      return nullptr;
    }
    return surface;
  }

 private:
  std::unique_ptr<TesterGLESDelegate> delegate_;
  std::shared_ptr<TesterGLESWorker> worker_;
  std::shared_ptr<impeller::ContextGLES> context_;
};

}  // namespace

std::unique_ptr<TesterContext> TesterContextGLESFactory::Create() {
  flutter::testing::SetupSwiftshaderOnce(true);
  auto context = std::make_unique<TesterContextGLES>();
  if (!context->Initialize()) {
    FML_LOG(ERROR) << "Unable to create TesterContextGLESFactory";
    return nullptr;
  }
  return context;
}

}  // namespace flutter
