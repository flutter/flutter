// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_EXTERNAL_VIEW_EMBEDDER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_EXTERNAL_VIEW_EMBEDDER_H_

#include "flutter/impeller/display_list/aiks_context.h"
#include "flutter/impeller/renderer/backend/metal/context_mtl.h"
#include "flutter/impeller/renderer/backend/metal/swapchain_transients_mtl.h"
#include "flutter/shell/gpu/gpu_surface_metal_delegate.h"
#include "flutter/shell/platform/darwin/ios/ios_context.h"
#include "third_party/skia/include/gpu/ganesh/mtl/GrMtlTypes.h"
#include "flutter/flow/embedded_views.h"
#include "flutter/flow/surface.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"

namespace flutter {

class IOSSurfacesManager;

class IOSExternalViewEmbedder : public ExternalViewEmbedder {
public:
  using CreateSurfaceFrameCallback =
      std::function<std::unique_ptr<SurfaceFrame>(
          int64_t flutter_view_id, DlISize& frame_size)>;

  IOSExternalViewEmbedder(
      __weak FlutterPlatformViewsController* platform_views_controller,
      const std::shared_ptr<IOSContext>& context,
      const CreateSurfaceFrameCallback& create_surface_frame_callback);

  // |ExternalViewEmbedder|
  virtual ~IOSExternalViewEmbedder() override;

 private:
  __weak FlutterPlatformViewsController* platform_views_controller_;
  std::shared_ptr<IOSContext> ios_context_;
  const CreateSurfaceFrameCallback create_surface_frame_callback_;
  std::unique_ptr<SurfaceFrame> pending_frame_;

  void CollectView(int64_t view_id) override;

  // |ExternalViewEmbedder|
  DlCanvas* GetRootCanvas() override;

  // |ExternalViewEmbedder|
  void CancelFrame() override;

  // |ExternalViewEmbedder|
  void BeginFrame(GrDirectContext* context,
                  const fml::RefPtr<fml::RasterThreadMerger>&
                      raster_thread_merger) override;

  // |ExternalViewEmbedder|
  void PrepareFlutterView(int64_t flutter_view_id,
                          DlISize frame_size,
                          double device_pixel_ratio) override;

  // |ExternalViewEmbedder|
  void PrerollCompositeEmbeddedView(
      int64_t view_id,
      std::unique_ptr<flutter::EmbeddedViewParams> params) override;

  // |ExternalViewEmbedder|
  PostPrerollResult PostPrerollAction(
      const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger)
      override;

  // |ExternalViewEmbedder|
  DlCanvas* CompositeEmbeddedView(int64_t view_id) override;

  // |ExternalViewEmbedder|
  void SubmitFlutterView(
      int64_t flutter_view_id,
      GrDirectContext* context,
      const std::shared_ptr<impeller::AiksContext>& aiks_context,
      std::unique_ptr<SurfaceFrame> frame) override;

  // |ExternalViewEmbedder|
  void EndFrame(bool should_resubmit_frame,
                const fml::RefPtr<fml::RasterThreadMerger>&
                    raster_thread_merger) override;

  // |ExternalViewEmbedder|
  bool SupportsDynamicThreadMerging() override;

  // |ExternalViewEmbedder|
  void PushFilterToVisitedPlatformViews(
      const std::shared_ptr<DlImageFilter>& filter,
      const DlRect& filter_rect) override;

  // |ExternalViewEmbedder|
  void PushClipRectToVisitedPlatformViews(const DlRect& clip_rect) override;

  // |ExternalViewEmbedder|
  void PushClipRRectToVisitedPlatformViews(
      const DlRoundRect& clip_rrect) override;

  // |ExternalViewEmbedder|
  void PushClipRSuperellipseToVisitedPlatformViews(
      const DlRoundSuperellipse& clip_rse) override;

  // |ExternalViewEmbedder|
  void PushClipPathToVisitedPlatformViews(const DlPath& clip_path) override;

  // |ExternalViewEmbedder|
  void PushVisitedPlatformView(int64_t view_id) override;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSExternalViewEmbedder);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_EXTERNAL_VIEW_EMBEDDER_H_
