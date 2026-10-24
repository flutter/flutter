// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_FILTERS_STRETCH_FILTER_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_FILTERS_STRETCH_FILTER_CONTENTS_H_

#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/filters/inputs/filter_input.h"

namespace impeller {

class StretchFilterContents final : public FilterContents {
 public:
  StretchFilterContents();

  ~StretchFilterContents() override;

  void SetOverscroll(Scalar overscroll_x, Scalar overscroll_y);

  void SetInterpolationStrength(Scalar interpolation_strength);

  void SetStretchBounds(const Rect& stretch_bounds);

  // |FilterContents|
  std::optional<Rect> GetFilterSourceCoverage(
      const Matrix& effect_transform,
      const Rect& output_limit) const override;

 private:
  // |FilterContents|
  std::optional<Entity> RenderFilter(
      const FilterInput::Vector& input_textures,
      const ContentContext& renderer,
      const Entity& entity,
      const Matrix& effect_transform,
      const Rect& coverage,
      const std::optional<Rect>& coverage_hint) const override;

  Scalar overscroll_x_ = 0.0f;
  Scalar overscroll_y_ = 0.0f;
  Scalar interpolation_strength_ = 0.7f;
  Rect stretch_bounds_;

  StretchFilterContents(const StretchFilterContents&) = delete;

  StretchFilterContents& operator=(const StretchFilterContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_FILTERS_STRETCH_FILTER_CONTENTS_H_
