// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_ENTITY_PASS_CLIP_STACK_H_
#define FLUTTER_IMPELLER_ENTITY_ENTITY_PASS_CLIP_STACK_H_

#include "impeller/entity/contents/contents.h"
#include "impeller/entity/entity.h"
#include "impeller/geometry/rect.h"

namespace impeller {

struct ClipCoverageLayer {
  std::optional<Rect> coverage;
  size_t clip_depth;
};

/// @brief A class that tracks all clips that have been recorded in the current
///        entity pass stencil.
///
///        These clips are replayed when restoring the backdrop so that the
///        stencil buffer is left in an identical state.
class EntityPassClipStack {
 public:
  struct ReplayResult {
    Entity entity;
    std::optional<Rect> clip_coverage;
  };

  struct ClipStateResult {
    /// Whether or not the Entity should be rendered. If false, the Entity may
    /// be safely skipped.
    bool should_render = false;
    /// Whether or not the current clip coverage changed during the call to
    /// `ApplyClipState`.
    bool clip_did_change = false;
  };

  /// Create a new [EntityPassClipStack] with an initialized coverage rect.
  explicit EntityPassClipStack(const Rect& initial_coverage_rect);

  ~EntityPassClipStack() = default;

  std::optional<Rect> CurrentClipCoverage() const;

  void PushSubpass(std::optional<Rect> subpass_coverage, size_t clip_depth);

  void PopSubpass();

  bool HasCoverage() const;

  /// @brief  Applies the current clip state to an Entity. If the given Entity
  ///         is a clip operation, then the clip state is updated accordingly.
  ClipStateResult ApplyClipState(Contents::ClipCoverage global_clip_coverage,
                                 Entity& entity,
                                 size_t clip_depth_floor,
                                 Point global_pass_position);

  // Visible for testing.
  void RecordEntity(const Entity& entity,
                    Contents::ClipCoverage::Type type,
                    std::optional<Rect> clip_coverage);

  // Visible for testing.
  const std::vector<ReplayResult>& GetReplayEntities() const;

  // Visible for testing.
  const std::vector<ClipCoverageLayer> GetClipCoverageLayers() const;

 private:
  struct SubpassState {
    std::vector<ReplayResult> rendered_clip_entities;
    std::vector<ClipCoverageLayer> clip_coverage;
  };

  SubpassState& GetCurrentSubpassState();

  std::vector<SubpassState> subpass_state_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_ENTITY_PASS_CLIP_STACK_H_
