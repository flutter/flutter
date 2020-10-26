// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_EXTERNAL_VIEW_EMBEDDER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_EXTERNAL_VIEW_EMBEDDER_H_

#include "flutter/flow/embedded_views.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"

namespace flutter {

class IOSExternalViewEmbedder : public ExternalViewEmbedder {
 public:
  IOSExternalViewEmbedder(const std::shared_ptr<FlutterPlatformViewsController>&
                              platform_views_controller,
                          std::shared_ptr<IOSContext> context);

  // |ExternalViewEmbedder|
  virtual ~IOSExternalViewEmbedder() override;

 private:
  const std::shared_ptr<FlutterPlatformViewsController>&
      platform_views_controller_;
  std::shared_ptr<IOSContext> ios_context_;

  // |ExternalViewEmbedder|
  SkCanvas* GetRootCanvas() override;

  // |ExternalViewEmbedder|
  void CancelFrame() override;

  // |ExternalViewEmbedder|
  void BeginFrame(
      SkISize frame_size,
      GrDirectContext* context,
      double device_pixel_ratio,
      fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) override;

  // |ExternalViewEmbedder|
  void PrerollCompositeEmbeddedView(
      int view_id,
      std::unique_ptr<flutter::EmbeddedViewParams> params) override;

  // |ExternalViewEmbedder|
  PostPrerollResult PostPrerollAction(
      fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) override;

  // |ExternalViewEmbedder|
  std::vector<SkCanvas*> GetCurrentCanvases() override;

  // |ExternalViewEmbedder|
  SkCanvas* CompositeEmbeddedView(int view_id) override;

  // |ExternalViewEmbedder|
  void SubmitFrame(GrDirectContext* context,
                   std::unique_ptr<SurfaceFrame> frame) override;

  // |ExternalViewEmbedder|
  void EndFrame(
      bool should_resubmit_frame,
      fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger) override;

  // |ExternalViewEmbedder|
  bool SupportsDynamicThreadMerging() override;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSExternalViewEmbedder);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_EXTERNAL_VIEW_EMBEDDER_H_
