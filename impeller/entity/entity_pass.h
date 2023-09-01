// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <optional>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/core/texture.h"
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
  /// Elements are renderable items in the `EntityPass`. Each can either be an
  /// `Entity` or a child `EntityPass`.
  ///
  /// When the element is a child `EntityPass`, it may be rendered to an
  /// offscreen texture and converted into an `Entity` that draws the texture
  /// into the current pass, or its children may be collapsed into the current
  ///
  /// `EntityPass`. Elements are converted to Entities in
  /// `GetEntityForElement()`.
  using Element = std::variant<Entity, std::unique_ptr<EntityPass>>;

  static const std::string kCaptureDocumentName;

  using BackdropFilterProc = std::function<std::shared_ptr<FilterContents>(
      FilterInput::Ref,
      const Matrix& effect_transform,
      bool is_subpass)>;

  struct StencilCoverageLayer {
    std::optional<Rect> coverage;
    size_t stencil_depth;
  };

  using StencilCoverageStack = std::vector<StencilCoverageLayer>;

  EntityPass();

  ~EntityPass();

  void SetDelegate(std::shared_ptr<EntityPassDelegate> delgate);

  /// @brief  Set the bounds limit, which is provided by the user when creating
  ///         a SaveLayer. This is a hint that allows the user to communicate
  ///         that it's OK to not render content outside of the bounds.
  ///
  ///         For consistency with Skia, we effectively treat this like a
  ///         rectangle clip by forcing the subpass texture size to never exceed
  ///         it.
  void SetBoundsLimit(std::optional<Rect> bounds_limit);

  /// @brief  Get the bounds limit, which is provided by the user when creating
  ///         a SaveLayer.
  std::optional<Rect> GetBoundsLimit() const;

  size_t GetSubpassesDepth() const;

  std::unique_ptr<EntityPass> Clone() const;

  void AddEntity(Entity entity);

  void SetElements(std::vector<Element> elements);

  //----------------------------------------------------------------------------
  /// @brief  Appends a given pass as a subpass.
  ///
  EntityPass* AddSubpass(std::unique_ptr<EntityPass> pass);

  //----------------------------------------------------------------------------
  /// @brief  Merges a given pass into this pass. Useful for drawing
  ///         pre-recorded pictures that don't require rendering into a separate
  ///         subpass.
  ///
  void AddSubpassInline(std::unique_ptr<EntityPass> pass);

  EntityPass* GetSuperpass() const;

  bool Render(ContentContext& renderer,
              const RenderTarget& render_target) const;

  /// @brief  Iterate all elements (entities and subpasses) in this pass,
  ///         recursively including elements of child passes. The iteration
  ///         order is depth-first. Whenever a subpass elements is encountered,
  ///         it's included in the stream before its children.
  void IterateAllElements(const std::function<bool(Element&)>& iterator);

  //----------------------------------------------------------------------------
  /// @brief  Iterate all entities in this pass, recursively including entities
  ///         of child passes. The iteration order is depth-first.
  ///
  void IterateAllEntities(const std::function<bool(Entity&)>& iterator);

  //----------------------------------------------------------------------------
  /// @brief  Iterate all entities in this pass, recursively including entities
  ///         of child passes. The iteration order is depth-first and does not
  ///         allow modification of the entities.
  ///
  void IterateAllEntities(
      const std::function<bool(const Entity&)>& iterator) const;

  //----------------------------------------------------------------------------
  /// @brief  Iterate entities in this pass up until the first subpass is found.
  ///         This is useful for limiting look-ahead optimizations.
  ///
  /// @return Returns whether a subpass was encountered.
  ///
  bool IterateUntilSubpass(const std::function<bool(Entity&)>& iterator);

  //----------------------------------------------------------------------------
  /// @brief Return the number of elements on this pass.
  ///
  size_t GetElementCount() const;

  void SetTransformation(Matrix xformation);

  void SetStencilDepth(size_t stencil_depth);

  size_t GetStencilDepth();

  void SetBlendMode(BlendMode blend_mode);

  Color GetClearColor(ISize size = ISize::Infinite()) const;

  void SetBackdropFilter(BackdropFilterProc proc);

  void SetEnableOffscreenCheckerboard(bool enabled);

  std::optional<Rect> GetSubpassCoverage(
      const EntityPass& subpass,
      std::optional<Rect> coverage_limit) const;

  std::optional<Rect> GetElementsCoverage(
      std::optional<Rect> coverage_limit) const;

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

    static EntityResult Success(const Entity& e) { return {e, kSuccess}; }
    static EntityResult Failure() { return {{}, kFailure}; }
    static EntityResult Skip() { return {{}, kSkip}; }
  };

  EntityResult GetEntityForElement(const EntityPass::Element& element,
                                   ContentContext& renderer,
                                   Capture& capture,
                                   InlinePassContext& pass_context,
                                   ISize root_pass_size,
                                   Point global_pass_position,
                                   uint32_t pass_depth,
                                   StencilCoverageStack& stencil_coverage_stack,
                                   size_t stencil_depth_floor) const;

  //----------------------------------------------------------------------------
  /// @brief     OnRender is the internal command recording routine for
  ///            `EntityPass`. Its job is to walk through each `Element` which
  ///            was appended to the scene (either an `Entity` via `AddEntity()`
  ///            or a child `EntityPass` via `AddSubpass()`) and render them to
  ///            the given `pass_target`.
  /// @param[in]  renderer                 The Contents context, which manages
  ///                                      pipeline state.
  /// @param[in]  root_pass_size           The size of the texture being
  ///                                      rendered into at the root of the
  ///                                      `EntityPass` tree. This is the size
  ///                                      of the `RenderTarget` color
  ///                                      attachment passed to the public
  ///                                      `EntityPass::Render` method.
  /// @param[out] pass_target              Stores the render target that should
  ///                                      be used for rendering.
  /// @param[in]  global_pass_position     The position that this `EntityPass`
  ///                                      will be drawn to the parent pass
  ///                                      relative to the root pass origin.
  ///                                      Used for offsetting drawn `Element`s,
  ///                                      whose origins are all in root
  ///                                      pass/screen space,
  /// @param[in]  local_pass_position      The position that this `EntityPass`
  ///                                      will be drawn to the parent pass
  ///                                      relative to the parent pass origin.
  ///                                      Used for positioning backdrop
  ///                                      filters.
  /// @param[in]  pass_depth               The tree depth of the `EntityPass` at
  ///                                      render time. Only used for labeling
  ///                                      and debugging purposes. This can vary
  ///                                      depending on whether passes are
  ///                                      collapsed or not.
  /// @param[in]  stencil_coverage_stack   A global stack of coverage rectangles
  ///                                      for the stencil buffer at each depth.
  ///                                      Higher depths are more restrictive.
  ///                                      Used to cull Elements that we
  ///                                      know won't result in a visible
  ///                                      change.
  /// @param[in]  stencil_depth_floor      The stencil depth that a value of
  ///                                      zero corresponds to in the given
  ///                                      `pass_target` stencil buffer.
  ///                                      When new `pass_target`s are created
  ///                                      for subpasses, their stencils are
  ///                                      initialized at zero, and so this
  ///                                      value is used to offset Entity clip
  ///                                      depths to match the stencil.
  /// @param[in]  backdrop_filter_contents Optional. Is supplied, this contents
  ///                                      is rendered prior to anything else in
  ///                                      the `EntityPass`, offset by the
  ///                                      `local_pass_position`.
  /// @param[in]  collapsed_parent_pass    Optional. If supplied, this
  ///                                      `InlinePassContext` state is used to
  ///                                      begin rendering elements instead of
  ///                                      creating a new `RenderPass`. This
  ///                                      "collapses" the Elements into the
  ///                                      parent pass.
  ///
  bool OnRender(ContentContext& renderer,
                Capture& capture,
                ISize root_pass_size,
                EntityPassTarget& pass_target,
                Point global_pass_position,
                Point local_pass_position,
                uint32_t pass_depth,
                StencilCoverageStack& stencil_coverage_stack,
                size_t stencil_depth_floor = 0,
                std::shared_ptr<Contents> backdrop_filter_contents = nullptr,
                const std::optional<InlinePassContext::RenderPassResult>&
                    collapsed_parent_pass = std::nullopt) const;

  /// The list of renderable items in the scene. Each of these items is
  /// evaluated and recorded to an `EntityPassTarget` by the `OnRender` method.
  std::vector<Element> elements_;

  EntityPass* superpass_ = nullptr;
  Matrix xformation_;
  size_t stencil_depth_ = 0u;
  BlendMode blend_mode_ = BlendMode::kSourceOver;
  bool flood_clip_ = false;
  bool enable_offscreen_debug_checkerboard_ = false;
  std::optional<Rect> bounds_limit_;

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

  BackdropFilterProc backdrop_filter_proc_ = nullptr;

  std::shared_ptr<EntityPassDelegate> delegate_ =
      EntityPassDelegate::MakeDefault();

  FML_DISALLOW_COPY_AND_ASSIGN(EntityPass);
};

}  // namespace impeller
