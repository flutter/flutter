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

namespace shell {

class IOSSurfaceSoftware final : public IOSSurface,
                                 public GPUSurfaceSoftwareDelegate,
                                 public flow::ExternalViewEmbedder {
 public:
  IOSSurfaceSoftware(fml::scoped_nsobject<CALayer> layer,
                     FlutterPlatformViewsController* platform_views_controller);

  ~IOSSurfaceSoftware() override;

  // |shell::IOSSurface|
  bool IsValid() const override;

  // |shell::IOSSurface|
  bool ResourceContextMakeCurrent() override;

  // |shell::IOSSurface|
  void UpdateStorageSizeIfNecessary() override;

  // |shell::IOSSurface|
  std::unique_ptr<Surface> CreateGPUSurface() override;

  // |shell::GPUSurfaceSoftwareDelegate|
  sk_sp<SkSurface> AcquireBackingStore(const SkISize& size) override;

  // |shell::GPUSurfaceSoftwareDelegate|
  bool PresentBackingStore(sk_sp<SkSurface> backing_store) override;

  // |shell::GPUSurfaceSoftwareDelegate|
  flow::ExternalViewEmbedder* GetExternalViewEmbedder() override;

  // |flow::ExternalViewEmbedder|
  void BeginFrame(SkISize frame_size) override;

  // |flow::ExternalViewEmbedder|
  void PrerollCompositeEmbeddedView(int view_id) override;

  // |flow::ExternalViewEmbedder|
  std::vector<SkCanvas*> GetCurrentCanvases() override;

  // |flow::ExternalViewEmbedder|
  SkCanvas* CompositeEmbeddedView(int view_id, const flow::EmbeddedViewParams& params) override;

  // |flow::ExternalViewEmbedder|
  bool SubmitFrame(GrContext* context) override;

 private:
  fml::scoped_nsobject<CALayer> layer_;
  sk_sp<SkSurface> sk_surface_;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSSurfaceSoftware);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_SOFTWARE_H_
