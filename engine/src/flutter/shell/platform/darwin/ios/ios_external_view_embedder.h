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

// class IOSExternalView {
// public:
//     IOSExternalView(const DlISize& frame_size,
//                     std::unique_ptr<Surface> rendering_surface,
//                     const std::shared_ptr<impeller::AiksContext>& context
//                 );

//     ~IOSExternalView();

//     std::unique_ptr<SurfaceFrame> MakeSurfaceFrame();

//     DlCanvas* Canvas();
// private:
//     std::unique_ptr<SurfaceFrame> AcquireFrameFromCAMetalLayer(
//       const GPUSurfaceMetalDelegate* delegate,
//       const DlISize& frame_size);

//     const DlISize render_surface_size_;
//     const GPUSurfaceMetalDelegate* delegate_;
//     std::shared_ptr<impeller::AiksContext> aiks_context_;
//     id<MTLTexture> last_texture_;
//     // TODO(38466): Refactor GPU surface APIs take into account the fact that an
//     // external view embedder may want to render to the root surface. This is a
//     // hack to make avoid allocating resources for the root surface when an
//     // external view embedder is present.
//     // bool render_to_surface_ = true;
//     bool disable_partial_repaint_ = false;
//     // Accumulated damage for each framebuffer; Key is address of underlying
//     // MTLTexture for each drawable
//     std::shared_ptr<std::map<void*, DlIRect>> damage_ =
//         std::make_shared<std::map<void*, DlIRect>>();
//     std::shared_ptr<impeller::SwapchainTransientsMTL> swapchain_transients_;

//     std::unique_ptr<Surface> rendering_surface_;
//     std::unique_ptr<SurfaceFrame> surface_frame_;
// };

class IOSExternalViewEmbedder : public ExternalViewEmbedder {
public:
  using GetIOSRenderingSurfaceCallback =
      std::function<Surface*(
          int64_t flutter_view_id)>;

  IOSExternalViewEmbedder(
      __weak FlutterPlatformViewsController* platform_views_controller,
      const std::shared_ptr<IOSContext>& context,
      const GetIOSRenderingSurfaceCallback& get_ios_rendering_surface_callback);

  // |ExternalViewEmbedder|
  virtual ~IOSExternalViewEmbedder() override;

 private:
  __weak FlutterPlatformViewsController* platform_views_controller_;
  std::shared_ptr<IOSContext> ios_context_;
  const GetIOSRenderingSurfaceCallback get_ios_rendering_surface_callback_;
  DlISize pending_frame_size_;
  std::unique_ptr<SurfaceFrame> pending_frame_;

  void CollectView(int64_t view_id) override;

  // |ExternalViewEmbedder|
  DlCanvas* GetRootCanvas() override;

  DlCanvas* GetRootCanvas(int64_t flutter_view_id) override;

  // |ExternalViewEmbedder|
  void CancelFrame() override;

  bool SkipFrame(int64_t flutter_view_id) override;

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
  void PushVisitedPlatformView(int64_t view_id) override;

  std::unique_ptr<SurfaceFrame> AcquireRootFrame(int64_t flutter_view_id) override;

  void Reset();

  FML_DISALLOW_COPY_AND_ASSIGN(IOSExternalViewEmbedder);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_EXTERNAL_VIEW_EMBEDDER_H_
