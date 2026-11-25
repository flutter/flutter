// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_EXTERNAL_VIEW_EMBEDDER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_EXTERNAL_VIEW_EMBEDDER_H_

#include <unordered_map>
#include <vector>

#include "flutter/flow/embedded_views.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"

namespace flutter {

class IOSExternalViewEmbedder : public ExternalViewEmbedder {
 public:
  IOSExternalViewEmbedder(
      __weak FlutterPlatformViewsController* platform_views_controller,
      const std::shared_ptr<IOSContext>& context);

  // |ExternalViewEmbedder|
  virtual ~IOSExternalViewEmbedder() override;

 private:
  __weak FlutterPlatformViewsController* platform_views_controller_;
  std::shared_ptr<IOSContext> ios_context_;

#pragma mark - Frame state

  // `PrepareFlutterView` resets this state at the start of each frame.
  // This state is only accessed on the raster thread.

  // The size of the current onscreen surface in physical pixels.
  DlISize frame_size_;

  // The device pixel ratio of the current frame.
  double device_pixel_ratio_ = 0;

  // The IDs of the platform views in the current frame, in composition order.
  std::vector<int64_t> composition_order_;

  // The composition parameters for each platform view in the current frame,
  // keyed by view ID.
  std::unordered_map<int64_t, EmbeddedViewParams> composition_params_;

  // The platform view's |EmbedderViewSlice| keyed off the view id, which
  // contains any subsequent operation until the next platform view or the end
  // of the last leaf node in the layer tree.
  std::unordered_map<int64_t, std::unique_ptr<EmbedderViewSlice>> slices_;

  // The IDs of the platform views visited during layer tree composition.
  std::vector<int64_t> visited_platform_views_;

  // Clears the composition order, composition parameters, slices, and visited
  // platform views.
  void ResetFrameState();

#pragma mark - ExternalViewEmbedder

  // |ExternalViewEmbedder|
  DlCanvas* GetRootCanvas() override;

  // |ExternalViewEmbedder|
  void CancelFrame() override;

  // |ExternalViewEmbedder|
  void BeginFrame(GrDirectContext* context,
                  const fml::RefPtr<fml::RasterThreadMerger>&
                      raster_thread_merger) override;

  // |ExternalViewEmbedder|
  void PrepareFlutterView(DlISize frame_size,
                          double device_pixel_ratio) override;

  // |ExternalViewEmbedder|
  void PrerollCompositeEmbeddedView(
      int64_t view_id,
      std::unique_ptr<flutter::EmbeddedViewParams> params) override;

  // |ExternalViewEmbedder|
  DlCanvas* CompositeEmbeddedView(int64_t view_id) override;

  // |ExternalViewEmbedder|
  void SubmitFlutterView(
      int64_t flutter_view_id,
      GrDirectContext* context,
      const std::shared_ptr<impeller::AiksContext>& aiks_context,
      std::unique_ptr<SurfaceFrame> frame) override;

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
