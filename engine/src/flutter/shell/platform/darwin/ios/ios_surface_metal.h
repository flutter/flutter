// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_METAL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_METAL_H_

#include "flutter/fml/macros.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/gpu/gpu_surface_delegate.h"
#include "flutter/shell/gpu/gpu_surface_metal.h"
#include "flutter/shell/platform/darwin/ios/ios_surface.h"

@class CAMetalLayer;

namespace flutter {

class IOSSurfaceMetal final : public IOSSurface,
                              public GPUSurfaceDelegate,
                              public ExternalViewEmbedder {
 public:
  IOSSurfaceMetal(fml::scoped_nsobject<CAMetalLayer> layer,
                  FlutterPlatformViewsController* platform_views_controller);

  IOSSurfaceMetal(fml::scoped_nsobject<CAMetalLayer> layer);

  ~IOSSurfaceMetal() override;

  // |IOSSurface|
  bool IsValid() const override;

  // |IOSSurface|
  bool ResourceContextMakeCurrent() override;

  // |IOSSurface|
  void UpdateStorageSizeIfNecessary() override;

  // |IOSSurface|
  std::unique_ptr<Surface> CreateGPUSurface(GrContext* gr_context = nullptr) override;

  // |GPUSurfaceDelegate|
  flutter::ExternalViewEmbedder* GetExternalViewEmbedder() override;

  // |ExternalViewEmbedder|
  sk_sp<SkSurface> GetRootSurface() override;

  // |ExternalViewEmbedder|
  void CancelFrame() override;

  // |ExternalViewEmbedder|
  void BeginFrame(SkISize frame_size, GrContext* context) override;

  // |ExternalViewEmbedder|
  void PrerollCompositeEmbeddedView(int view_id,
                                    std::unique_ptr<flutter::EmbeddedViewParams> params) override;

  // |ExternalViewEmbedder|
  PostPrerollResult PostPrerollAction(fml::RefPtr<fml::GpuThreadMerger> gpu_thread_merger) override;

  // |ExternalViewEmbedder|
  std::vector<SkCanvas*> GetCurrentCanvases() override;

  // |ExternalViewEmbedder|
  SkCanvas* CompositeEmbeddedView(int view_id) override;

  // |ExternalViewEmbedder|
  bool SubmitFrame(GrContext* context) override;

 private:
  fml::scoped_nsobject<CAMetalLayer> layer_;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSSurfaceMetal);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_METAL_H_
