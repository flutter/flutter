// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/entity_pass_clip_stack.h"

#include "flutter/fml/logging.h"
#include "impeller/entity/contents/clip_contents.h"
#include "impeller/entity/entity.h"

namespace impeller {

EntityPassClipStack::EntityPassClipStack(const Rect& initial_coverage_rect) {
  subpass_state_.push_back(SubpassState{
      .clip_coverage =
          {
              {ClipCoverageLayer{
                  .coverage = initial_coverage_rect,
                  .clip_height = 0,
              }},
          },
  });
}

std::optional<Rect> EntityPassClipStack::CurrentClipCoverage() const {
  return subpass_state_.back().clip_coverage.back().coverage;
}

bool EntityPassClipStack::HasCoverage() const {
  return !subpass_state_.back().clip_coverage.empty();
}

void EntityPassClipStack::PushSubpass(std::optional<Rect> subpass_coverage,
                                      size_t clip_height) {
  subpass_state_.push_back(SubpassState{
      .clip_coverage =
          {
              ClipCoverageLayer{.coverage = subpass_coverage,
                                .clip_height = clip_height},
          },
  });
  next_replay_index_ = 0;
}

void EntityPassClipStack::PopSubpass() {
  subpass_state_.pop_back();
  next_replay_index_ = subpass_state_.back().rendered_clip_entities.size();
}

const std::vector<ClipCoverageLayer>
EntityPassClipStack::GetClipCoverageLayers() const {
  return subpass_state_.back().clip_coverage;
}

EntityPassClipStack::ClipStateResult EntityPassClipStack::ApplyClipState(
    Contents::ClipCoverage global_clip_coverage,
    Entity& entity,
    size_t clip_height_floor,
    Point global_pass_position) {
  ClipStateResult result = {.should_render = false, .clip_did_change = false};

  auto& subpass_state = GetCurrentSubpassState();
  switch (global_clip_coverage.type) {
    case Contents::ClipCoverage::Type::kNoChange:
      break;
    case Contents::ClipCoverage::Type::kAppend: {
      auto maybe_coverage = CurrentClipCoverage();

      // Compute the previous clip height.
      size_t previous_clip_height = 0;
      if (!subpass_state.clip_coverage.empty()) {
        previous_clip_height = subpass_state.clip_coverage.back().clip_height;
      } else {
        // If there is no clip coverage, then the previous clip height is the
        // clip height floor.
        previous_clip_height = clip_height_floor;
      }

      if (!maybe_coverage.has_value()) {
        // Running this append op won't impact the clip buffer because the
        // whole screen is already being clipped, so skip it.
        return result;
      }
      auto op = maybe_coverage.value();

      // If the new clip coverage is bigger than the existing coverage for
      // intersect clips, we do not need to change the clip region.
      if (!global_clip_coverage.is_difference_or_non_square &&
          global_clip_coverage.coverage.has_value() &&
          global_clip_coverage.coverage.value().Contains(op)) {
        subpass_state.clip_coverage.push_back(ClipCoverageLayer{
            .coverage = op, .clip_height = previous_clip_height + 1});

        return result;
      }

      subpass_state.clip_coverage.push_back(
          ClipCoverageLayer{.coverage = global_clip_coverage.coverage,
                            .clip_height = previous_clip_height + 1});
      result.clip_did_change = true;

      FML_DCHECK(subpass_state.clip_coverage.back().clip_height ==
                 subpass_state.clip_coverage.front().clip_height +
                     subpass_state.clip_coverage.size() - 1);

    } break;
    case Contents::ClipCoverage::Type::kRestore: {
      ClipRestoreContents* restore_contents =
          reinterpret_cast<ClipRestoreContents*>(entity.GetContents().get());
      size_t restore_height = restore_contents->GetRestoreHeight();

      if (subpass_state.clip_coverage.back().clip_height <= restore_height) {
        // Drop clip restores that will do nothing.
        return result;
      }

      auto restoration_index =
          restore_height - subpass_state.clip_coverage.front().clip_height;
      FML_DCHECK(restoration_index < subpass_state.clip_coverage.size());

      // We only need to restore the area that covers the coverage of the
      // clip rect at target height + 1.
      std::optional<Rect> restore_coverage =
          (restoration_index + 1 < subpass_state.clip_coverage.size())
              ? subpass_state.clip_coverage[restoration_index + 1].coverage
              : std::nullopt;
      if (restore_coverage.has_value()) {
        // Make the coverage rectangle relative to the current pass.
        restore_coverage = restore_coverage->Shift(-global_pass_position);
      }
      subpass_state.clip_coverage.resize(restoration_index + 1);
      result.clip_did_change = true;

      // Skip all clip restores when stencil-then-cover is enabled.
      if (subpass_state.clip_coverage.back().coverage.has_value()) {
        RecordEntity(entity, global_clip_coverage.type, Rect());
      }
      return result;

    } break;
  }

  RecordEntity(entity, global_clip_coverage.type,
               subpass_state.clip_coverage.back().coverage);

  result.should_render = true;
  return result;
}

void EntityPassClipStack::RecordEntity(const Entity& entity,
                                       Contents::ClipCoverage::Type type,
                                       std::optional<Rect> clip_coverage) {
  auto& subpass_state = GetCurrentSubpassState();
  switch (type) {
    case Contents::ClipCoverage::Type::kNoChange:
      return;
    case Contents::ClipCoverage::Type::kAppend:
      FML_DCHECK(next_replay_index_ ==
                 subpass_state.rendered_clip_entities.size())
          << "Not all clips have been replayed before appending new clip.";
      subpass_state.rendered_clip_entities.push_back(
          {.entity = entity.Clone(), .clip_coverage = clip_coverage});
      next_replay_index_++;
      break;
    case Contents::ClipCoverage::Type::kRestore:
      FML_DCHECK(next_replay_index_ <=
                 subpass_state.rendered_clip_entities.size());
      if (!subpass_state.rendered_clip_entities.empty()) {
        subpass_state.rendered_clip_entities.pop_back();

        if (next_replay_index_ > subpass_state.rendered_clip_entities.size()) {
          next_replay_index_ = subpass_state.rendered_clip_entities.size();
        }
      }
      break;
  }
}

EntityPassClipStack::SubpassState&
EntityPassClipStack::GetCurrentSubpassState() {
  return subpass_state_.back();
}

const std::vector<EntityPassClipStack::ReplayResult>&
EntityPassClipStack::GetReplayEntities() const {
  return subpass_state_.back().rendered_clip_entities;
}

void EntityPassClipStack::ActivateClipReplay() {
  next_replay_index_ = 0;
}

const EntityPassClipStack::ReplayResult*
EntityPassClipStack::GetNextReplayResult(size_t current_clip_depth) {
  if (next_replay_index_ >=
      subpass_state_.back().rendered_clip_entities.size()) {
    // No clips need to be replayed.
    return nullptr;
  }
  ReplayResult* next_replay =
      &subpass_state_.back().rendered_clip_entities[next_replay_index_];
  if (next_replay->entity.GetClipDepth() < current_clip_depth) {
    // The next replay clip doesn't affect the current entity, so don't replay
    // it yet.
    return nullptr;
  }

  next_replay_index_++;
  return next_replay;
}

}  // namespace impeller
