// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/embedded_views.h"

#include <cmath>

namespace flutter {

namespace {

// Strength of the position-based interpolation. Must match
// `interpolationStrength` in widgets/stretch_effect.dart and the
// `u_interpolation_strength` uniform supplied on the Android side.
constexpr DlScalar kInterpolationStrength = 0.7f;

// Maps an output (on-screen) normalized position to the source (content)
// normalized position for a single axis. This mirrors compute_streched_effect()
// in shaders/stretch_effect.frag with the normalized constants used there
// (stretch_affected_dist = 1, inverse_stretch_affected_dist = 1, viewport = 1),
// i.e. it is the *backward* map the interior shader performs. It is monotonically
// increasing in `in_pos`, including across the branch boundaries.
DlScalar StretchSourceFromOutput(DlScalar in_pos, DlScalar overscroll) {
  if (overscroll == 0.0f) {
    return in_pos;
  }
  const DlScalar distance_stretched = 1.0f / (1.0f + std::abs(overscroll));
  const DlScalar distance_diff = distance_stretched - 1.0f;
  if (overscroll > 0.0f) {
    if (in_pos <= 1.0f) {
      const DlScalar offset_pos = 1.0f - in_pos;
      // mix(1.0, offset_pos, kInterpolationStrength)
      const DlScalar pos_based_variation =
          (1.0f - kInterpolationStrength) + kInterpolationStrength * offset_pos;
      const DlScalar stretch_intensity = overscroll * pos_based_variation;
      return distance_stretched - offset_pos / (1.0f + stretch_intensity);
    }
    return distance_diff + in_pos;
  }
  // overscroll < 0: stretch_affected_dist_calc = viewport(1) - 1 = 0.
  if (in_pos >= 0.0f) {
    const DlScalar offset_pos = in_pos;
    const DlScalar pos_based_variation =
        (1.0f - kInterpolationStrength) + kInterpolationStrength * offset_pos;
    const DlScalar stretch_intensity = (-overscroll) * pos_based_variation;
    return 1.0f - (distance_stretched - offset_pos / (1.0f + stretch_intensity));
  }
  return -distance_diff + in_pos;
}

// Inverse of StretchSourceFromOutput: given a source (content) normalized
// position, returns the output (on-screen) normalized position. Found by
// bisection because the forward map has no convenient closed form. The bracket
// [-2, 2] comfortably contains the pre-image of any source in [0, 1] for
// |overscroll| <= 1.
DlScalar StretchOutputFromSource(DlScalar source, DlScalar overscroll) {
  if (overscroll == 0.0f) {
    return source;
  }
  DlScalar lo = -2.0f;
  DlScalar hi = 2.0f;
  for (int i = 0; i < 30; i++) {
    const DlScalar mid = (lo + hi) * 0.5f;
    if (StretchSourceFromOutput(mid, overscroll) < source) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) * 0.5f;
}

// Maps the [low, high] edges of one axis of a platform view through the stretch
// forward map, given the viewport's [vp_low, vp_size] extent on that axis.
void StretchAxis(DlScalar overscroll,
                 DlScalar vp_low,
                 DlScalar vp_size,
                 DlScalar& low,
                 DlScalar& high) {
  if (overscroll == 0.0f || vp_size <= 0.0f) {
    return;
  }
  const DlScalar source_low = (low - vp_low) / vp_size;
  const DlScalar source_high = (high - vp_low) / vp_size;
  low = vp_low + StretchOutputFromSource(source_low, overscroll) * vp_size;
  high = vp_low + StretchOutputFromSource(source_high, overscroll) * vp_size;
}

}  // namespace

DlRect EmbeddedViewParams::ApplyOverscrollStretch(
    const DlRect& natural_screen_rect,
    const MutatorsStack& mutators) {
  DlScalar x_stretch = 0.0f;
  DlScalar y_stretch = 0.0f;
  DlRect viewport_rect;
  bool has_stretch = false;
  for (auto it = mutators.Begin(); it != mutators.End(); ++it) {
    if ((*it)->GetType() == MutatorType::kOverscrollStretch) {
      const auto& stretch = (*it)->GetOverscrollStretch();
      x_stretch += stretch.x_stretch;
      y_stretch += stretch.y_stretch;
      // A single overscroll viewport is expected in practice (one scrollable
      // overscrolling at a time); if nested, the innermost wins.
      viewport_rect = stretch.viewport_rect;
      has_stretch = true;
    }
  }
  if (!has_stretch || (x_stretch == 0.0f && y_stretch == 0.0f) ||
      viewport_rect.IsEmpty()) {
    return natural_screen_rect;
  }

  DlScalar left = natural_screen_rect.GetLeft();
  DlScalar right = natural_screen_rect.GetRight();
  DlScalar top = natural_screen_rect.GetTop();
  DlScalar bottom = natural_screen_rect.GetBottom();

  StretchAxis(x_stretch, viewport_rect.GetLeft(), viewport_rect.GetWidth(), left,
              right);
  StretchAxis(y_stretch, viewport_rect.GetTop(), viewport_rect.GetHeight(), top,
              bottom);

  return DlRect::MakeLTRB(left, top, right, bottom);
}

DisplayListEmbedderViewSlice::DisplayListEmbedderViewSlice(DlRect view_bounds) {
  builder_ = std::make_unique<DisplayListBuilder>(
      /*bounds=*/view_bounds,
      /*prepare_rtree=*/true);
}

DlCanvas* DisplayListEmbedderViewSlice::canvas() {
  return builder_ ? builder_.get() : nullptr;
}

void DisplayListEmbedderViewSlice::end_recording() {
  display_list_ = builder_->Build();
  FML_DCHECK(display_list_->has_rtree());
  builder_ = nullptr;
}

const DlRegion& DisplayListEmbedderViewSlice::getRegion() const {
  return display_list_->rtree()->region();
}

void DisplayListEmbedderViewSlice::render_into(DlCanvas* canvas) {
  canvas->DrawDisplayList(display_list_);
}

void DisplayListEmbedderViewSlice::dispatch(DlOpReceiver& receiver) {
  display_list_->Dispatch(receiver);
}

bool DisplayListEmbedderViewSlice::is_empty() {
  return display_list_->GetBounds().IsEmpty();
}

bool DisplayListEmbedderViewSlice::recording_ended() {
  return builder_ == nullptr;
}

void ExternalViewEmbedder::CollectView(int64_t view_id) {}

void ExternalViewEmbedder::SubmitFlutterView(
    int64_t flutter_view_id,
    GrDirectContext* context,
    const std::shared_ptr<impeller::AiksContext>& aiks_context,
    std::unique_ptr<SurfaceFrame> frame) {
  frame->Submit();
}

bool ExternalViewEmbedder::SupportsDynamicThreadMerging() {
  return false;
}

void ExternalViewEmbedder::Teardown() {}

void MutatorsStack::PushClipRect(const DlRect& rect) {
  std::shared_ptr<Mutator> element = std::make_shared<Mutator>(rect);
  vector_.push_back(element);
}

void MutatorsStack::PushClipRRect(const DlRoundRect& rrect) {
  std::shared_ptr<Mutator> element = std::make_shared<Mutator>(rrect);
  vector_.push_back(element);
}

void MutatorsStack::PushClipRSE(const DlRoundSuperellipse& rrect) {
  std::shared_ptr<Mutator> element = std::make_shared<Mutator>(rrect);
  vector_.push_back(element);
}

void MutatorsStack::PushClipPath(const DlPath& path) {
  std::shared_ptr<Mutator> element = std::make_shared<Mutator>(path);
  vector_.push_back(element);
}

void MutatorsStack::PushTransform(const DlMatrix& matrix) {
  std::shared_ptr<Mutator> element = std::make_shared<Mutator>(matrix);
  vector_.push_back(element);
}

void MutatorsStack::PushOpacity(const uint8_t& alpha) {
  std::shared_ptr<Mutator> element = std::make_shared<Mutator>(alpha);
  vector_.push_back(element);
}

void MutatorsStack::PushBackdropFilter(
    const std::shared_ptr<DlImageFilter>& filter,
    const DlRect& filter_rect) {
  std::shared_ptr<Mutator> element =
      std::make_shared<Mutator>(filter, filter_rect);
  vector_.push_back(element);
}

void MutatorsStack::PushOverscrollStretch(DlScalar x_stretch,
                                          DlScalar y_stretch,
                                          const DlRect& viewport_rect) {
  std::shared_ptr<Mutator> element = std::make_shared<Mutator>(
      OverscrollStretchMutation{x_stretch, y_stretch, viewport_rect});
  vector_.push_back(element);
}

void MutatorsStack::PushPlatformViewClipRect(const DlRect& rect) {
  std::shared_ptr<Mutator> element =
      std::make_shared<Mutator>(BackdropClipRect(rect));
  vector_.push_back(element);
}
void MutatorsStack::PushPlatformViewClipRRect(const DlRoundRect& rrect) {
  std::shared_ptr<Mutator> element =
      std::make_shared<Mutator>(BackdropClipRRect(rrect));
  vector_.push_back(element);
}
void MutatorsStack::PushPlatformViewClipRSuperellipse(
    const DlRoundSuperellipse& rse) {
  std::shared_ptr<Mutator> element =
      std::make_shared<Mutator>(BackdropClipRSuperellipse(rse));
  vector_.push_back(element);
}
void MutatorsStack::PushPlatformViewClipPath(const DlPath& path) {
  std::shared_ptr<Mutator> element =
      std::make_shared<Mutator>(BackdropClipPath(path));
  vector_.push_back(element);
}

void MutatorsStack::Pop() {
  vector_.pop_back();
}

void MutatorsStack::PopTo(size_t stack_count) {
  while (vector_.size() > stack_count) {
    Pop();
  }
}

const std::vector<std::shared_ptr<Mutator>>::const_reverse_iterator
MutatorsStack::Top() const {
  return vector_.rend();
}

const std::vector<std::shared_ptr<Mutator>>::const_reverse_iterator
MutatorsStack::Bottom() const {
  return vector_.rbegin();
}

const std::vector<std::shared_ptr<Mutator>>::const_iterator
MutatorsStack::Begin() const {
  return vector_.begin();
}

const std::vector<std::shared_ptr<Mutator>>::const_iterator MutatorsStack::End()
    const {
  return vector_.end();
}

}  // namespace flutter
