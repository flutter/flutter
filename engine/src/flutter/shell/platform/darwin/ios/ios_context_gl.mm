// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_context_gl.h"

#import <OpenGLES/EAGL.h>

#include "flutter/shell/common/shell_io_manager.h"
#include "flutter/shell/gpu/gpu_surface_gl_delegate.h"
#import "flutter/shell/platform/darwin/ios/ios_external_texture_gl.h"

namespace flutter {

IOSContextGL::IOSContextGL() {
  resource_context_.reset([[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3]);
  if (resource_context_ != nullptr) {
    context_.reset([[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3
                                         sharegroup:resource_context_.get().sharegroup]);
  } else {
    resource_context_.reset([[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]);
    context_.reset([[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2
                                         sharegroup:resource_context_.get().sharegroup]);
  }
}

IOSContextGL::~IOSContextGL() = default;

std::unique_ptr<IOSRenderTargetGL> IOSContextGL::CreateRenderTarget(
    fml::scoped_nsobject<CAEAGLLayer> layer) {
  return std::make_unique<IOSRenderTargetGL>(std::move(layer), context_);
}

// |IOSContext|
sk_sp<GrDirectContext> IOSContextGL::CreateResourceContext() {
  if (![EAGLContext setCurrentContext:resource_context_.get()]) {
    FML_DLOG(INFO) << "Could not make resource context current on IO thread. Async texture uploads "
                      "will be disabled. On Simulators, this is expected.";
    return nullptr;
  }

  return ShellIOManager::CreateCompatibleResourceLoadingContext(
      GrBackend::kOpenGL_GrBackend, GPUSurfaceGLDelegate::GetDefaultPlatformGLInterface());
}

// |IOSContext|
std::unique_ptr<GLContextResult> IOSContextGL::MakeCurrent() {
  return std::make_unique<GLContextSwitch>(
      std::make_unique<IOSSwitchableGLContext>(context_.get()));
}

// |IOSContext|
std::unique_ptr<Texture> IOSContextGL::CreateExternalTexture(
    int64_t texture_id,
    fml::scoped_nsobject<NSObject<FlutterTexture>> texture) {
  return std::make_unique<IOSExternalTextureGL>(texture_id, std::move(texture));
}

}  // namespace flutter
