// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_VIEW_EMBEDDER_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_VIEW_EMBEDDER_H_

#include <map>
#include <memory>
#include <unordered_map>

#include "flutter/flow/embedded_views.h"
#include "flutter/fml/hash_combine.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/embedder/embedder_external_view.h"
#include "flutter/shell/platform/embedder/embedder_render_target_cache.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      The external view embedder used by the generic embedder API.
///             This class acts a proxy between the rasterizer and the embedder
///             when the rasterizer is rendering into multiple layers. It asks
///             the embedder for the render targets for the various layers the
///             rasterizer is rendering into, recycles the render targets as
///             necessary and converts rasterizer specific metadata into an
///             embedder friendly format so that it can present the layers
///             on-screen.
///
class EmbedderExternalViewEmbedder final : public ExternalViewEmbedder {
 public:
  using CreateRenderTargetCallback =
      std::function<std::unique_ptr<EmbedderRenderTarget>(
          GrDirectContext* context,
          const std::shared_ptr<impeller::AiksContext>& aiks_context,
          const FlutterBackingStoreConfig& config)>;
  using PresentCallback =
      std::function<bool(FlutterViewId view_id,
                         const std::vector<const FlutterLayer*>& layers)>;
  using SurfaceTransformationCallback = std::function<DlMatrix(void)>;

  //----------------------------------------------------------------------------
  /// @brief      Creates an external view embedder used by the generic embedder
  ///             API.
  ///
  /// @param[in] avoid_backing_store_cache If set, create_render_target_callback
  ///                                      will beinvoked every frame for every
  ///                                      engine composited layer. The result
  ///                                      will not cached.
  ///
  /// @param[in]  create_render_target_callback
  ///                                     The render target callback used to
  ///                                     request the render target for a layer.
  /// @param[in]  present_callback        The callback used to forward a
  ///                                     collection of layers (backed by
  ///                                     fulfilled render targets) to the
  ///                                     embedder for presentation.
  ///
  EmbedderExternalViewEmbedder(
      bool avoid_backing_store_cache,
      const CreateRenderTargetCallback& create_render_target_callback,
      const PresentCallback& present_callback,
      bool merge_raster_thread_on_platform_views = false,
      bool coalesce_overlay_layers = false,
      uint64_t platform_view_mutation_capabilities = 0);

  //----------------------------------------------------------------------------
  /// @brief      Collects the external view embedder.
  ///
  ~EmbedderExternalViewEmbedder() override;

  // |ExternalViewEmbedder|
  void CollectView(int64_t view_id) override;

  //----------------------------------------------------------------------------
  /// @brief      Sets the surface transformation callback used by the external
  ///             view embedder to ask the platform for the per frame root
  ///             surface transformation.
  ///
  /// @param[in]  surface_transformation_callback  The surface transformation
  ///                                              callback
  ///
  void SetSurfaceTransformationCallback(
      SurfaceTransformationCallback surface_transformation_callback);

  void SetMergeRasterThreadOnPlatformViews(
      bool merge_raster_thread_on_platform_views);

  void SetCoalesceOverlayLayers(bool coalesce_overlay_layers);

  void SetPlatformViewMutationCapabilities(
      uint64_t platform_view_mutation_capabilities);

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
      std::unique_ptr<EmbeddedViewParams> params) override;

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
  DlCanvas* GetRootCanvas() override;

  // |ExternalViewEmbedder|
  void Teardown() override;

  // |ExternalViewEmbedder|
  bool SupportsDynamicThreadMerging() override;

 private:
  // Default device pixel ratio before PrepareFlutterView is called.
  static constexpr double kDefaultDevicePixelRatio = 1.0;

  const bool avoid_backing_store_cache_;
  const CreateRenderTargetCallback create_render_target_callback_;
  const PresentCallback present_callback_;
  bool merge_raster_thread_on_platform_views_ = false;
  bool coalesce_overlay_layers_ = false;
  uint64_t platform_view_mutation_capabilities_ = 0;
  SurfaceTransformationCallback surface_transformation_callback_;
  DlISize pending_frame_size_;
  double pending_device_pixel_ratio_ = kDefaultDevicePixelRatio;
  DlMatrix pending_surface_transformation_;
  EmbedderExternalView::PendingViews pending_views_;
  std::vector<EmbedderExternalView::ViewIdentifier> composition_order_;
  // Number of platform views rendered in the previous frame, used to detect the
  // 0 -> >0 platform-view transition when merging threads.
  size_t previous_frame_view_count_ = 0;
  // True when the current pass is the first merged pass after a 0 -> >0
  // platform-view transition and should present only platform-view layers
  // before resubmitting.
  bool should_resubmit_frame_ = false;
  // The render target caches for views. Each key is a view ID.
  std::unordered_map<int64_t, EmbedderRenderTargetCache> render_target_caches_;

  void Reset();

  bool FrameHasPlatformLayers() const;

  size_t CountPlatformViews() const;

  DlMatrix GetSurfaceTransformation() const;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderExternalViewEmbedder);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_VIEW_EMBEDDER_H_
