// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/testing/tester_context_gles_factory.h"

#define EGL_EGL_PROTOTYPES 1
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <EGL/eglplatform.h>
#include <cstring>
#include <memory>
#include <vector>

#include "flutter/fml/logging.h"
#include "flutter/fml/mapping.h"
#include "flutter/shell/gpu/gpu_surface_gl_delegate.h"
#include "flutter/shell/gpu/gpu_surface_gl_impeller.h"
#include "impeller/renderer/backend/gles/context_gles.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"

namespace flutter {

namespace {

bool HasExtension(const char* extensions, const char* name) {
  const char* r = strstr(extensions, name);
  auto len = strlen(name);
  // check that the extension name is terminated by space or null terminator
  return r != nullptr && (r[len] == ' ' || r[len] == 0);
}

EGLDisplay CreateSwangleDisplay() {
  const char* extensions = ::eglQueryString(EGL_NO_DISPLAY, EGL_EXTENSIONS);
  if (!extensions) {
    // If we can't query extensions, we might be on a platform that doesn't
    // support no-display queries, or EGL is just broken. Try default display as
    // fallback? But we specifically want Swangle (SwiftShader/ANGLE).
    return EGL_NO_DISPLAY;
  }

  // We expect EGL_EXT_platform_base for Swangle.
  if (!HasExtension(extensions, "EGL_EXT_platform_base")) {
    FML_LOG(ERROR) << "EGL_EXT_platform_base not supported.";
    return EGL_NO_DISPLAY;
  }

  PFNEGLGETPLATFORMDISPLAYEXTPROC egl_get_platform_display_EXT =
      reinterpret_cast<PFNEGLGETPLATFORMDISPLAYEXTPROC>(
          eglGetProcAddress("eglGetPlatformDisplayEXT"));

  if (!egl_get_platform_display_EXT) {
    FML_LOG(ERROR) << "eglGetPlatformDisplayEXT not available.";
    return EGL_NO_DISPLAY;
  }

  // Try SwiftShader first
  const EGLint swiftshader_config[] = {
      EGL_PLATFORM_ANGLE_TYPE_ANGLE,
      EGL_PLATFORM_ANGLE_TYPE_VULKAN_ANGLE,
      EGL_PLATFORM_ANGLE_DEVICE_TYPE_ANGLE,
      EGL_PLATFORM_ANGLE_DEVICE_TYPE_SWIFTSHADER_ANGLE,
      EGL_NONE,
  };

  EGLDisplay display = egl_get_platform_display_EXT(
      EGL_PLATFORM_ANGLE_ANGLE,
      reinterpret_cast<EGLNativeDisplayType*>(EGL_DEFAULT_DISPLAY),
      swiftshader_config);

  if (display != EGL_NO_DISPLAY) {
    return display;
  }

  // Fallback?
  return EGL_NO_DISPLAY;
}

}  // namespace

class TesterGLESDelegate : public GPUSurfaceGLDelegate {
 public:
  TesterGLESDelegate() {
    display_ = CreateSwangleDisplay();
    if (display_ == EGL_NO_DISPLAY) {
      FML_LOG(ERROR) << "Could not create EGL display.";
      return;
    }

    if (::eglInitialize(display_, nullptr, nullptr) != EGL_TRUE) {
      FML_LOG(ERROR) << "Could not initialize EGL display.";
      return;
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

    if (::eglChooseConfig(display_, attribute_list, &config_, 1, &num_config) !=
            EGL_TRUE ||
        num_config != 1) {
      FML_LOG(ERROR) << "Could not choose EGL config.";
      return;
    }

    const EGLint context_attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2,
                                         EGL_NONE};

    context_ = ::eglCreateContext(display_, config_, EGL_NO_CONTEXT,
                                  context_attributes);
    if (context_ == EGL_NO_CONTEXT) {
      FML_LOG(ERROR) << "Could not create EGL context.";
      return;
    }

    // Create a pbuffer surface to make current
    const EGLint surface_attributes[] = {EGL_WIDTH, 1, EGL_HEIGHT, 1, EGL_NONE};
    surface_ = ::eglCreatePbufferSurface(display_, config_, surface_attributes);
    if (surface_ == EGL_NO_SURFACE) {
      FML_LOG(ERROR) << "Could not create EGL pbuffer surface.";
      return;
    }
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

  bool IsValid() const {
    return context_ != EGL_NO_CONTEXT && surface_ != EGL_NO_SURFACE;
  }

  // |GPUSurfaceGLDelegate|
  std::unique_ptr<GLContextResult> GLContextMakeCurrent() override {
    if (!IsValid()) {
      return std::make_unique<GLContextDefaultResult>(false);
    }
    EGLBoolean result =
        ::eglMakeCurrent(display_, surface_, surface_, context_);
    return std::make_unique<GLContextDefaultResult>(result == EGL_TRUE);
  }

  // |GPUSurfaceGLDelegate|
  bool GLContextClearCurrent() override {
    return ::eglMakeCurrent(display_, EGL_NO_SURFACE, EGL_NO_SURFACE,
                            EGL_NO_CONTEXT) == EGL_TRUE;
  }

  // |GPUSurfaceGLDelegate|
  bool GLContextPresent(const GLPresentInfo& present_info) override {
    return true;  // PBuffer doesn't present? Or maybe eglSwapBuffers?
    // For pbuffer, eglSwapBuffers is usually valid but doesn't do much on
    // screen. return ::eglSwapBuffers(display_, surface_) == EGL_TRUE;
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
  EGLDisplay display_ = EGL_NO_DISPLAY;
  EGLConfig config_ = nullptr;
  EGLContext context_ = EGL_NO_CONTEXT;
  EGLSurface surface_ = EGL_NO_SURFACE;
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
    delegate_ = std::make_unique<TesterGLESDelegate>();
    if (!delegate_->IsValid()) {
      FML_LOG(ERROR) << "Could not create GLES delegate.";
      return false;
    }

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

    std::vector<std::shared_ptr<fml::Mapping>> shader_mappings = {};
    context_ = impeller::ContextGLES::Create(impeller::Flags{}, std::move(gl),
                                             shader_mappings, false);

    if (!context_ ||
        !static_cast<std::shared_ptr<impeller::Context>>(context_)->IsValid()) {
      FML_LOG(ERROR) << "Could not create OpenGLES context.";
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
    // Render to surface is true?
    // For offscreen testing, we might still want to say "true" to create
    // ON-SCREEN surface abstraction but backed by the delegate's FBO/Surface.
    auto surface = std::make_unique<GPUSurfaceGLImpeller>(
        delegate_.get(), context_, /*render_to_surface=*/true);
    if (!surface->IsValid()) {
      return nullptr;
    }
    return surface;
  }

 private:
  std::shared_ptr<impeller::ContextGLES> context_;
  std::unique_ptr<TesterGLESDelegate> delegate_;
};

std::unique_ptr<TesterContext> TesterContextGLESFactory::Create() {
  auto context = std::make_unique<TesterContextGLES>();
  if (!context->Initialize()) {
    return nullptr;
  }
  return context;
}

}  // namespace flutter
