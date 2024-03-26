// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_ENTITY_PASS_CLIP_STACK_H_
#define FLUTTER_IMPELLER_ENTITY_ENTITY_PASS_CLIP_STACK_H_

#include "impeller/entity/contents/contents.h"

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
  /// Create a new [EntityPassClipStack] with an initialized coverage rect.
  explicit EntityPassClipStack(const Rect& initial_coverage_rect);

  ~EntityPassClipStack() = default;

  std::optional<Rect> CurrentClipCoverage() const;

  void PushSubpass(std::optional<Rect> subpass_coverage, size_t clip_depth);

  void PopSubpass();

  bool HasCoverage() const;

  /// Returns true if entity should be rendered.
  bool AppendClipCoverage(Contents::ClipCoverage clip_coverage,
                          Entity& entity,
                          size_t clip_depth_floor,
                          Point global_pass_position);

  // Visible for testing.
  void RecordEntity(const Entity& entity, Contents::ClipCoverage::Type type);

  // Visible for testing.
  const std::vector<Entity>& GetReplayEntities() const;

  // Visible for testing.
  const std::vector<ClipCoverageLayer> GetClipCoverageLayers() const;

 private:
  struct SubpassState {
    std::vector<Entity> rendered_clip_entities;
    std::vector<ClipCoverageLayer> clip_coverage;
  };

  SubpassState& GetCurrentSubpassState();

  std::vector<SubpassState> subpass_state_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_ENTITY_PASS_CLIP_STACK_H_
