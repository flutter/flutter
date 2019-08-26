// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_VIEW_EMBEDDER_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_VIEW_EMBEDDER_H_

#include <map>
#include <unordered_map>

#include "flutter/flow/embedded_views.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/common/canvas_spy.h"
#include "flutter/shell/platform/embedder/embedder_render_target.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

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
          GrContext* context,
          const FlutterBackingStoreConfig& config)>;
  using PresentCallback =
      std::function<bool(const std::vector<const FlutterLayer*>& layers)>;

  //----------------------------------------------------------------------------
  /// @brief      Creates an external view embedder used by the generic embedder
  ///             API.
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
      CreateRenderTargetCallback create_render_target_callback,
      PresentCallback present_callback);

  //----------------------------------------------------------------------------
  /// @brief      Collects the external view embedder.
  ///
  ~EmbedderExternalViewEmbedder() override;

 private:
  // |ExternalViewEmbedder|
  void CancelFrame() override;

  // |ExternalViewEmbedder|
  void BeginFrame(SkISize frame_size, GrContext* context) override;

  // |ExternalViewEmbedder|
  void PrerollCompositeEmbeddedView(
      int view_id,
      std::unique_ptr<EmbeddedViewParams> params) override;

  // |ExternalViewEmbedder|
  std::vector<SkCanvas*> GetCurrentCanvases() override;

  // |ExternalViewEmbedder|
  SkCanvas* CompositeEmbeddedView(int view_id) override;

  // |ExternalViewEmbedder|
  bool SubmitFrame(GrContext* context) override;

  // |ExternalViewEmbedder|
  sk_sp<SkSurface> GetRootSurface() override;

 private:
  using ViewIdentifier = int64_t;
  struct RegistryKey {
    ViewIdentifier view_identifier = 0;
    SkISize size = SkISize::Make(0, 0);

    RegistryKey(ViewIdentifier view_identifier,
                const FlutterBackingStoreConfig& config)
        : view_identifier(view_identifier),
          size(SkISize::Make(config.size.width, config.size.height)) {}

    struct Hash {
      constexpr std::size_t operator()(RegistryKey const& key) const {
        return key.view_identifier;
      };
    };

    struct Equal {
      constexpr bool operator()(const RegistryKey& lhs,
                                const RegistryKey& rhs) const {
        return lhs.view_identifier == rhs.view_identifier &&
               lhs.size == rhs.size;
      }
    };
  };

  const CreateRenderTargetCallback create_render_target_callback_;
  const PresentCallback present_callback_;
  using Registry = std::unordered_map<RegistryKey,
                                      std::shared_ptr<EmbedderRenderTarget>,
                                      RegistryKey::Hash,
                                      RegistryKey::Equal>;

  SkISize pending_frame_size_ = SkISize::Make(0, 0);
  std::map<ViewIdentifier, std::unique_ptr<SkPictureRecorder>>
      pending_recorders_;
  std::map<ViewIdentifier, std::unique_ptr<CanvasSpy>> pending_canvas_spies_;
  std::map<ViewIdentifier, EmbeddedViewParams> pending_params_;
  std::vector<ViewIdentifier> composition_order_;
  std::shared_ptr<EmbedderRenderTarget> root_render_target_;
  Registry registry_;

  void Reset();

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderExternalViewEmbedder);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_EXTERNAL_VIEW_EMBEDDER_H_
