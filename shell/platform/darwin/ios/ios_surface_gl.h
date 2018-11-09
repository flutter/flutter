// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_GL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_GL_H_

#include "flutter/fml/macros.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/gpu/gpu_surface_gl.h"
#include "flutter/shell/platform/darwin/ios/ios_gl_context.h"
#include "flutter/shell/platform/darwin/ios/ios_gl_render_target.h"
#include "flutter/shell/platform/darwin/ios/ios_surface.h"

@class CAEAGLLayer;

namespace shell {

class IOSSurfaceGL : public IOSSurface,
                     public GPUSurfaceGLDelegate,
                     public flow::ExternalViewEmbedder {
 public:
  IOSSurfaceGL(fml::scoped_nsobject<CAEAGLLayer> layer,
               FlutterPlatformViewsController* platform_views_controller);

  IOSSurfaceGL(fml::scoped_nsobject<CAEAGLLayer> layer, std::shared_ptr<IOSGLContext> context);

  ~IOSSurfaceGL() override;

  bool IsValid() const override;

  bool ResourceContextMakeCurrent() override;

  void UpdateStorageSizeIfNecessary() override;

  std::unique_ptr<Surface> CreateGPUSurface() override;

  std::unique_ptr<Surface> CreateSecondaryGPUSurface(GrContext* gr_context);

  bool GLContextMakeCurrent() override;

  bool GLContextClearCurrent() override;

  bool GLContextPresent() override;

  intptr_t GLContextFBO() const override;

  bool UseOffscreenSurface() const override;

  // |shell::GPUSurfaceGLDelegate|
  flow::ExternalViewEmbedder* GetExternalViewEmbedder() override;

  // |flow::ExternalViewEmbedder|
  void SetFrameSize(SkISize frame_size) override;

  // |flow::ExternalViewEmbedder|
  void PrerollCompositeEmbeddedView(int view_id) override;

  // |flow::ExternalViewEmbedder|
  std::vector<SkCanvas*> GetCurrentCanvases() override;

  // |flow::ExternalViewEmbedder|
  SkCanvas* CompositeEmbeddedView(int view_id, const flow::EmbeddedViewParams& params) override;

  // |flow::ExternalViewEmbedder|
  virtual bool SubmitFrame(GrContext* context) override;

 private:
  std::shared_ptr<IOSGLContext> context_;
  std::unique_ptr<IOSGLRenderTarget> render_target_;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSSurfaceGL);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_GL_H_
