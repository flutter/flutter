// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_GL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_GL_H_

#include "flutter/shell/gpu/gpu_surface_gl.h"
#include "flutter/shell/platform/darwin/ios/ios_gl_context.h"
#include "flutter/shell/platform/darwin/ios/ios_surface.h"
#include "lib/ftl/macros.h"

@class CAEAGLLayer;

namespace shell {

class IOSSurfaceGL : public IOSSurface, public GPUSurfaceGLDelegate {
 public:
  IOSSurfaceGL(PlatformView::SurfaceConfig surface_config, CAEAGLLayer* layer);

  ~IOSSurfaceGL() override;

  bool IsValid() const override;

  bool ResourceContextMakeCurrent() override;

  void UpdateStorageSizeIfNecessary() override;

  std::unique_ptr<Surface> CreateGPUSurface() override;

  bool GLContextMakeCurrent() override;

  bool GLContextClearCurrent() override;

  bool GLContextPresent() override;

  intptr_t GLContextFBO() const override;

  bool SurfaceSupportsSRGB() const override;

 private:
  IOSGLContext context_;

  FTL_DISALLOW_COPY_AND_ASSIGN(IOSSurfaceGL);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_GL_H_
