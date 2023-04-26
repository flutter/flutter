// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_COMPOSITOR_CONTEXT_H_
#define FLUTTER_FLOW_COMPOSITOR_CONTEXT_H_

#include <memory>
#include <string>

#include "flutter/common/graphics/texture.h"
#include "flutter/flow/diff_context.h"
#include "flutter/flow/embedded_views.h"
#include "flutter/flow/instrumentation.h"
#include "flutter/flow/layer_snapshot_store.h"
#include "flutter/flow/raster_cache.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/raster_thread_merger.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

namespace flutter {

class LayerTree;

enum class RasterStatus {
  // Frame has been successfully rasterized.
  kSuccess,
  // Frame is submitted twice. This is only used on Android when
  // switching the background surface to FlutterImageView.
  //
  // On Android, the first frame doesn't make the image available
  // to the ImageReader right away. The second frame does.
  //
  // TODO(egarciad): https://github.com/flutter/flutter/issues/65652
  kResubmit,
  // Frame is dropped and a new frame with the same layer tree is
  // attempted.
  //
  // This is currently used to wait for the thread merger to merge
  // the raster and platform threads.
  //
  // Since the thread merger may be disabled,
  kSkipAndRetry,
  // Frame has been successfully rasterized, but "there are additional items in
  // the pipeline waiting to be consumed. This is currently
  // only used when thread configuration change occurs.
  kEnqueuePipeline,
  // Failed to rasterize the frame.
  kFailed,
  // Layer tree was discarded due to LayerTreeDiscardCallback or inability to
  // access the GPU.
  kDiscarded,
  // Drawing was yielded to allow the correct thread to draw as a result of the
  // RasterThreadMerger.
  kYielded,
};

class FrameDamage {
 public:
  // Sets previous layer tree for calculating frame damage. If not set, entire
  // frame will be repainted.
  void SetPreviousLayerTree(const LayerTree* prev_layer_tree) {
    prev_layer_tree_ = prev_layer_tree;
  }

  // Adds additional damage (accumulated for double / triple buffering).
  // This is area that will be repainted alongside any changed part.
  void AddAdditionalDamage(const SkIRect& damage) {
    additional_damage_.join(damage);
  }

  // Specifies clip rect alignment.
  void SetClipAlignment(int horizontal, int vertical) {
    horizontal_clip_alignment_ = horizontal;
    vertical_clip_alignment_ = vertical;
  }

  // Calculates clip rect for current rasterization. This is diff of layer tree
  // and previous layer tree + any additional provided damage.
  // If previous layer tree is not specified, clip rect will be nullopt,
  // but the paint region of layer_tree will be calculated so that it can be
  // used for diffing of subsequent frames.
  std::optional<SkRect> ComputeClipRect(flutter::LayerTree& layer_tree,
                                        bool has_raster_cache);

  // See Damage::frame_damage.
  std::optional<SkIRect> GetFrameDamage() const {
    return damage_ ? std::make_optional(damage_->frame_damage) : std::nullopt;
  }

  // See Damage::buffer_damage.
  std::optional<SkIRect> GetBufferDamage() {
    return (damage_ && !ignore_damage_)
               ? std::make_optional(damage_->buffer_damage)
               : std::nullopt;
  }

  // Remove reported buffer_damage to inform clients that a partial repaint
  // should not be performed on this frame.
  // frame_damage is required to correctly track accumulated damage for
  // subsequent frames.
  void Reset() { ignore_damage_ = true; }

 private:
  SkIRect additional_damage_ = SkIRect::MakeEmpty();
  std::optional<Damage> damage_;
  const LayerTree* prev_layer_tree_ = nullptr;
  int vertical_clip_alignment_ = 1;
  int horizontal_clip_alignment_ = 1;
  bool ignore_damage_ = false;
};

class CompositorContext {
 public:
  class ScopedFrame {
   public:
    ScopedFrame(CompositorContext& context,
                GrDirectContext* gr_context,
                DlCanvas* canvas,
                ExternalViewEmbedder* view_embedder,
                const SkMatrix& root_surface_transformation,
                bool instrumentation_enabled,
                bool surface_supports_readback,
                fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger,
                DisplayListBuilder* display_list_builder,
                impeller::AiksContext* aiks_context);

    virtual ~ScopedFrame();

    DlCanvas* canvas() { return canvas_; }

    DisplayListBuilder* display_list_builder() const {
      return display_list_builder_;
    }

    ExternalViewEmbedder* view_embedder() { return view_embedder_; }

    CompositorContext& context() const { return context_; }

    const SkMatrix& root_surface_transformation() const {
      return root_surface_transformation_;
    }

    bool surface_supports_readback() { return surface_supports_readback_; }

    GrDirectContext* gr_context() const { return gr_context_; }

    impeller::AiksContext* aiks_context() const { return aiks_context_; }

    virtual RasterStatus Raster(LayerTree& layer_tree,
                                bool ignore_raster_cache,
                                FrameDamage* frame_damage);

   private:
    void PaintLayerTreeSkia(flutter::LayerTree& layer_tree,
                            std::optional<SkRect> clip_rect,
                            bool needs_save_layer,
                            bool ignore_raster_cache);

    void PaintLayerTreeImpeller(flutter::LayerTree& layer_tree,
                                std::optional<SkRect> clip_rect,
                                bool ignore_raster_cache);

    CompositorContext& context_;
    GrDirectContext* gr_context_;
    DlCanvas* canvas_;
    DisplayListBuilder* display_list_builder_;
    impeller::AiksContext* aiks_context_;
    ExternalViewEmbedder* view_embedder_;
    const SkMatrix& root_surface_transformation_;
    const bool instrumentation_enabled_;
    const bool surface_supports_readback_;
    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger_;

    FML_DISALLOW_COPY_AND_ASSIGN(ScopedFrame);
  };

  CompositorContext();

  explicit CompositorContext(Stopwatch::RefreshRateUpdater& updater);

  virtual ~CompositorContext();

  virtual std::unique_ptr<ScopedFrame> AcquireFrame(
      GrDirectContext* gr_context,
      DlCanvas* canvas,
      ExternalViewEmbedder* view_embedder,
      const SkMatrix& root_surface_transformation,
      bool instrumentation_enabled,
      bool surface_supports_readback,
      fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger,
      DisplayListBuilder* display_list_builder,
      impeller::AiksContext* aiks_context);

  void OnGrContextCreated();

  void OnGrContextDestroyed();

  RasterCache& raster_cache() { return raster_cache_; }

  std::shared_ptr<TextureRegistry> texture_registry() {
    return texture_registry_;
  }

  const Stopwatch& raster_time() const { return raster_time_; }

  Stopwatch& ui_time() { return ui_time_; }

  LayerSnapshotStore& snapshot_store() { return layer_snapshot_store_; }

 private:
  RasterCache raster_cache_;
  std::shared_ptr<TextureRegistry> texture_registry_;
  Stopwatch raster_time_;
  Stopwatch ui_time_;
  LayerSnapshotStore layer_snapshot_store_;

  /// Only used by default constructor of `CompositorContext`.
  FixedRefreshRateUpdater fixed_refresh_rate_updater_;

  void BeginFrame(ScopedFrame& frame, bool enable_instrumentation);

  void EndFrame(ScopedFrame& frame, bool enable_instrumentation);

  /// @brief  Whether Impeller shouild attempt a partial repaint.
  ///         The Impeller backend requires an additional blit pass, which may
  ///         not be worthwhile if the damage region is large.
  static bool ShouldPerformPartialRepaint(std::optional<SkRect> damage_rect,
                                          SkISize layer_tree_size);

  FML_DISALLOW_COPY_AND_ASSIGN(CompositorContext);
};

}  // namespace flutter

#endif  // FLUTTER_FLOW_COMPOSITOR_CONTEXT_H_
