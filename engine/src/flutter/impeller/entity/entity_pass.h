// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <optional>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/entity_pass_delegate.h"
#include "impeller/entity/inline_pass_context.h"
#include "impeller/renderer/render_target.h"
#include "impeller/typographer/lazy_glyph_atlas.h"

namespace impeller {

class ContentContext;

class EntityPass {
 public:
  using Element = std::variant<Entity, std::unique_ptr<EntityPass>>;
  using BackdropFilterProc = std::function<std::shared_ptr<FilterContents>(
      FilterInput::Ref,
      const Matrix& effect_transform,
      bool is_subpass)>;

  EntityPass();

  ~EntityPass();

  void SetDelegate(std::unique_ptr<EntityPassDelegate> delgate);

  size_t GetSubpassesDepth() const;

  std::unique_ptr<EntityPass> Clone() const;

  void AddEntity(Entity entity);

  void SetElements(std::vector<Element> elements);

  EntityPass* AddSubpass(std::unique_ptr<EntityPass> pass);

  EntityPass* GetSuperpass() const;

  bool Render(ContentContext& renderer,
              const RenderTarget& render_target) const;

  void IterateAllEntities(const std::function<bool(Entity&)>& iterator);

  void SetTransformation(Matrix xformation);

  void SetStencilDepth(size_t stencil_depth);

  void SetBlendMode(BlendMode blend_mode);

  void SetBackdropFilter(std::optional<BackdropFilterProc> proc);

  std::optional<Rect> GetSubpassCoverage(
      const EntityPass& subpass,
      std::optional<Rect> coverage_crop) const;

  std::optional<Rect> GetElementsCoverage(
      std::optional<Rect> coverage_crop) const;

 private:
  struct EntityResult {
    enum Status {
      /// The entity was successfully resolved and can be rendered.
      kSuccess,
      /// An unexpected rendering error occurred while resolving the Entity.
      kFailure,
      /// The entity should be skipped because rendering it will contribute
      /// nothing to the frame.
      kSkip,
    };

    /// @brief  The resulting entity that should be rendered. If `std::nullopt`,
    ///         there is nothing to render.
    Entity entity;
    /// @brief  This is set to `false` if there was an unexpected rendering
    ///         error while resolving the Entity.
    Status status = kFailure;

    static EntityResult Success(Entity e) { return {e, kSuccess}; }
    static EntityResult Failure() { return {{}, kFailure}; }
    static EntityResult Skip() { return {{}, kSkip}; }
  };

  EntityResult GetEntityForElement(const EntityPass::Element& element,
                                   ContentContext& renderer,
                                   InlinePassContext& pass_context,
                                   ISize root_pass_size,
                                   Point position,
                                   uint32_t pass_depth,
                                   size_t stencil_depth_floor) const;

  bool OnRender(ContentContext& renderer,
                ISize root_pass_size,
                const RenderTarget& render_target,
                Point position,
                Point parent_position,
                uint32_t pass_depth,
                size_t stencil_depth_floor = 0,
                std::shared_ptr<Contents> backdrop_filter_contents = nullptr,
                std::optional<InlinePassContext::RenderPassResult>
                    collapsed_parent_pass = std::nullopt) const;

  std::vector<Element> elements_;

  EntityPass* superpass_ = nullptr;
  Matrix xformation_;
  size_t stencil_depth_ = 0u;
  BlendMode blend_mode_ = BlendMode::kSourceOver;
  bool cover_whole_screen_ = false;

  /// These values are incremented whenever something is added to the pass that
  /// requires reading from the backdrop texture. Currently, this can happen in
  /// the following scenarios:
  ///   1. An entity with an "advanced blend" is added to the pass.
  ///   2. A subpass with a backdrop filter is added to the pass.
  /// These are tracked as separate values because we may ignore
  /// blend_reads_from_pass_texture_ if the device supports framebuffer based
  /// advanced blends.
  uint32_t advanced_blend_reads_from_pass_texture_ = 0;
  uint32_t backdrop_filter_reads_from_pass_texture_ = 0;

  uint32_t GetTotalPassReads(ContentContext& renderer) const;

  std::optional<BackdropFilterProc> backdrop_filter_proc_ = std::nullopt;

  std::unique_ptr<EntityPassDelegate> delegate_ =
      EntityPassDelegate::MakeDefault();

  FML_DISALLOW_COPY_AND_ASSIGN(EntityPass);
};

struct CanvasStackEntry {
  Matrix xformation;
  size_t stencil_depth = 0u;
  bool is_subpass = false;
  bool contains_clips = false;
};

}  // namespace impeller
