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
      std::function<bool(const std::vector<const FlutterLayer*>& layers)>;
  using SurfaceTransformationCallback = std::function<SkMatrix(void)>;

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
      bool enable_impeller);

  //----------------------------------------------------------------------------
  /// @brief      Collects the external view embedder.
  ///
  ~EmbedderExternalViewEmbedder() override;

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

 private:
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
      int64_t view_id,
      std::unique_ptr<EmbeddedViewParams> params) override;

  // |ExternalViewEmbedder|
  DlCanvas* CompositeEmbeddedView(int64_t view_id) override;

  // |ExternalViewEmbedder|
  void SubmitFrame(GrDirectContext* context,
                   const std::shared_ptr<impeller::AiksContext>& aiks_context,
                   std::unique_ptr<SurfaceFrame> frame) override;

  // |ExternalViewEmbedder|
  DlCanvas* GetRootCanvas() override;

 private:
  bool enable_impeller_ = false;
  const bool avoid_backing_store_cache_;
  const CreateRenderTargetCallback create_render_target_callback_;
  const PresentCallback present_callback_;
  SurfaceTransformationCallback surface_transformation_callback_;
  SkISize pending_frame_size_ = SkISize::Make(0, 0);
  double pending_device_pixel_ratio_ = 1.0;
  SkMatrix pending_surface_transformation_;
  EmbedderExternalView::PendingViews pending_views_;
  std::vector<EmbedderExternalView::ViewIdentifier> composition_order_;
  EmbedderRenderTargetCache render_target_cache_;

  void Reset();

  SkMatrix GetSurfaceTransformation() const;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderExternalViewEmbedder);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_VIEW_EMBEDDER_H_
