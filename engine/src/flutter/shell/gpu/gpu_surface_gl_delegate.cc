// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/gpu/gpu_surface_gl_delegate.h"

#include "third_party/skia/include/gpu/gl/GrGLAssembleInterface.h"

namespace flutter {

bool GPUSurfaceGLDelegate::GLContextFBOResetAfterPresent() const {
  return false;
}

bool GPUSurfaceGLDelegate::UseOffscreenSurface() const {
  return false;
}

SkMatrix GPUSurfaceGLDelegate::GLContextSurfaceTransformation() const {
  SkMatrix matrix;
  matrix.setIdentity();
  return matrix;
}

GPUSurfaceGLDelegate::GLProcResolver GPUSurfaceGLDelegate::GetGLProcResolver()
    const {
  return nullptr;
}

static bool IsProcResolverOpenGLES(
    GPUSurfaceGLDelegate::GLProcResolver proc_resolver) {
  // Version string prefix that identifies an OpenGL ES implementation.
#define GPU_GL_VERSION 0x1F02
  constexpr char kGLESVersionPrefix[] = "OpenGL ES";

  using GLGetStringProc = const char* (*)(uint32_t);

  GLGetStringProc gl_get_string =
      reinterpret_cast<GLGetStringProc>(proc_resolver("glGetString"));

  FML_CHECK(gl_get_string)
      << "The GL proc resolver could not resolve glGetString";

  const char* gl_version_string = gl_get_string(GPU_GL_VERSION);

  FML_CHECK(gl_version_string)
      << "The GL proc resolver's glGetString(GL_VERSION) failed";

  return strncmp(gl_version_string, kGLESVersionPrefix,
                 strlen(kGLESVersionPrefix)) == 0;
}

static sk_sp<const GrGLInterface> CreateGLInterface(
    GPUSurfaceGLDelegate::GLProcResolver proc_resolver) {
  if (proc_resolver == nullptr) {
    // If there is no custom proc resolver, ask Skia to guess the native
    // interface. This often leads to interesting results on most platforms.
    return GrGLMakeNativeInterface();
  }

  struct ProcResolverContext {
    GPUSurfaceGLDelegate::GLProcResolver resolver;
  };

  ProcResolverContext context = {proc_resolver};

  GrGLGetProc gl_get_proc = [](void* context,
                               const char gl_proc_name[]) -> GrGLFuncPtr {
    auto proc_resolver_context =
        reinterpret_cast<ProcResolverContext*>(context);
    return reinterpret_cast<GrGLFuncPtr>(
        proc_resolver_context->resolver(gl_proc_name));
  };

  // glGetString indicates an OpenGL ES interface.
  if (IsProcResolverOpenGLES(proc_resolver)) {
    return GrGLMakeAssembledGLESInterface(&context, gl_get_proc);
  }

  // Fallback to OpenGL.
  if (auto interface = GrGLMakeAssembledGLInterface(&context, gl_get_proc)) {
    return interface;
  }

  FML_LOG(ERROR) << "Could not create a valid GL interface.";
  return nullptr;
}

sk_sp<const GrGLInterface> GPUSurfaceGLDelegate::GetGLInterface() const {
  return CreateGLInterface(GetGLProcResolver());
}

sk_sp<const GrGLInterface>
GPUSurfaceGLDelegate::GetDefaultPlatformGLInterface() {
  return CreateGLInterface(nullptr);
}

}  // namespace flutter
