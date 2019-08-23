// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_SOFTWARE_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_SOFTWARE_H_

#include "flutter/flow/embedded_views.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/gpu/gpu_surface_software.h"
#include "flutter/shell/platform/darwin/ios/ios_surface.h"

@class CALayer;

namespace flutter {

class IOSSurfaceSoftware final : public IOSSurface,
                                 public GPUSurfaceSoftwareDelegate,
                                 public ExternalViewEmbedder {
 public:
  IOSSurfaceSoftware(fml::scoped_nsobject<CALayer> layer,
                     FlutterPlatformViewsController* platform_views_controller);

  ~IOSSurfaceSoftware() override;

  // |IOSSurface|
  bool IsValid() const override;

  // |IOSSurface|
  bool ResourceContextMakeCurrent() override;

  // |IOSSurface|
  void UpdateStorageSizeIfNecessary() override;

  // |IOSSurface|
  std::unique_ptr<Surface> CreateGPUSurface(GrContext* gr_context = nullptr) override;

  // |GPUSurfaceSoftwareDelegate|
  sk_sp<SkSurface> AcquireBackingStore(const SkISize& size) override;

  // |GPUSurfaceSoftwareDelegate|
  bool PresentBackingStore(sk_sp<SkSurface> backing_store) override;

  // |GPUSurfaceSoftwareDelegate|
  ExternalViewEmbedder* GetExternalViewEmbedder() override;

  // |ExternalViewEmbedder|
  sk_sp<SkSurface> GetRootSurface() override;

  // |ExternalViewEmbedder|
  void CancelFrame() override;

  // |ExternalViewEmbedder|
  void BeginFrame(SkISize frame_size, GrContext* context) override;

  // |ExternalViewEmbedder|
  void PrerollCompositeEmbeddedView(int view_id,
                                    std::unique_ptr<EmbeddedViewParams> params) override;

  // |ExternalViewEmbedder|
  std::vector<SkCanvas*> GetCurrentCanvases() override;

  // |ExternalViewEmbedder|
  SkCanvas* CompositeEmbeddedView(int view_id) override;

  // |ExternalViewEmbedder|
  bool SubmitFrame(GrContext* context) override;

 private:
  fml::scoped_nsobject<CALayer> layer_;
  sk_sp<SkSurface> sk_surface_;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSSurfaceSoftware);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_SOFTWARE_H_
