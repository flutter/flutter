// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_AIKS_EXPERIMENTAL_CANVAS_H_
#define FLUTTER_IMPELLER_AIKS_EXPERIMENTAL_CANVAS_H_

#include <memory>
#include <optional>
#include <vector>

#include "impeller/aiks/canvas.h"
#include "impeller/aiks/image_filter.h"
#include "impeller/aiks/paint.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/entity_pass.h"

namespace impeller {

class ExperimentalCanvas : public Canvas {
 public:
  ExperimentalCanvas(ContentContext& renderer, RenderTarget& render_target);

  ExperimentalCanvas(ContentContext& renderer,
                     RenderTarget& render_target,
                     Rect cull_rect);

  ExperimentalCanvas(ContentContext& renderer,
                     RenderTarget& render_target,
                     IRect cull_rect);

  ~ExperimentalCanvas() override = default;

  void Save() override;

  void SaveLayer(const Paint& paint,
                 std::optional<Rect> bounds = std::nullopt,
                 const std::shared_ptr<ImageFilter>& backdrop_filter = nullptr,
                 ContentBoundsPromise bounds_promise =
                     ContentBoundsPromise::kUnknown) override;

  bool Restore() override;

  void EndReplay() {
    FML_DCHECK(inline_pass_contexts_.size() == 1u);
    inline_pass_contexts_.back()->EndPass();
    render_passes_.clear();
    inline_pass_contexts_.clear();
    renderer_.GetRenderTargetCache()->End();

    Reset();
    Initialize(initial_cull_rect_);
  }

  void DrawTextFrame(const std::shared_ptr<TextFrame>& text_frame,
                     Point position,
                     const Paint& paint) override;

  struct SaveLayerState {
    Paint paint;
    Rect coverage;
  };

 private:
  ContentContext& renderer_;
  RenderTarget& render_target_;
  std::vector<std::unique_ptr<InlinePassContext>> inline_pass_contexts_;
  std::vector<std::unique_ptr<EntityPassTarget>> entity_pass_targets_;
  std::vector<SaveLayerState> save_layer_state_;
  std::vector<std::shared_ptr<RenderPass>> render_passes_;

  void SetupRenderPass();

  void AddEntityToCurrentPass(Entity entity) override;

  Point GetGlobalPassPosition() {
    if (save_layer_state_.empty()) {
      return Point(0, 0);
    }
    return save_layer_state_.back().coverage.GetOrigin();
  }

  ExperimentalCanvas(const ExperimentalCanvas&) = delete;

  ExperimentalCanvas& operator=(const ExperimentalCanvas&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_AIKS_EXPERIMENTAL_CANVAS_H_
