// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/impeller/entity/geometry/round_rect_geometry.h"

namespace impeller {

RoundRectGeometry::RoundRectGeometry(const Rect& bounds, const Size& radii)
    : bounds_(bounds), radii_(radii) {}

RoundRectGeometry::~RoundRectGeometry() = default;

GeometryResult RoundRectGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  return ComputePositionGeometry(renderer,
                                 renderer.GetTessellator().FilledRoundRect(
                                     entity.GetTransform(), bounds_, radii_),
                                 entity, pass);
}

std::optional<Rect> RoundRectGeometry::GetCoverage(
    const Matrix& transform) const {
  return bounds_.TransformBounds(transform);
}

bool RoundRectGeometry::CoversArea(const Matrix& transform,
                                   const Rect& rect) const {
  if (!transform.IsTranslationScaleOnly()) {
    return false;
  }
  bool flat_on_tb = bounds_.GetWidth() > radii_.width * 2;
  bool flat_on_lr = bounds_.GetHeight() > radii_.height * 2;
  if (!flat_on_tb && !flat_on_lr) {
    return false;
  }
  // We either transform the bounds and delta-transform the radii,
  // or we compute the vertical and horizontal bounds and then
  // transform each. Either way there are 2 transform operations.
  // We could also get a weaker answer by computing just the
  // "inner rect" and only doing a coverage analysis on that,
  // but this process will produce more culling results.
  if (flat_on_tb) {
    Rect vertical_bounds = bounds_.Expand(Size{-radii_.width, 0});
    Rect coverage = vertical_bounds.TransformBounds(transform);
    if (coverage.Contains(rect)) {
      return true;
    }
  }
  if (flat_on_lr) {
    Rect horizontal_bounds = bounds_.Expand(Size{0, -radii_.height});
    Rect coverage = horizontal_bounds.TransformBounds(transform);
    if (coverage.Contains(rect)) {
      return true;
    }
  }
  return false;
}

bool RoundRectGeometry::IsAxisAlignedRect() const {
  return false;
}

FillRoundRectGeometry::FillRoundRectGeometry(const RoundRect& round_rect)
    : FillPathSourceGeometry(std::nullopt), round_rect_source_(round_rect) {}

const PathSource& FillRoundRectGeometry::GetSource() const {
  return round_rect_source_;
}

bool FillRoundRectGeometry::CoversArea(const Matrix& transform,
                                       const Rect& rect) const {
  // Similar procedure to |RoundRectGeometry| except that we have different
  // radii at every corner.
  if (!transform.IsTranslationScaleOnly()) {
    return false;
  }
  const RoundRect& round_rect = round_rect_source_.GetRoundRect();

  const Rect& bounds = round_rect.GetBounds();
  const RoundingRadii& radii = round_rect.GetRadii();

  Scalar left_margin = std::max(radii.top_left.width, radii.bottom_left.width);
  Scalar right_margin =
      std::max(radii.top_right.width, radii.bottom_right.width);
  Scalar top_margin = std::max(radii.top_left.height, radii.top_right.height);
  Scalar bottom_margin =
      std::max(radii.bottom_left.height, radii.bottom_right.height);

  bool flat_on_tb = bounds.GetWidth() > left_margin + right_margin;
  bool flat_on_lr = bounds.GetHeight() > top_margin + bottom_margin;
  if (!flat_on_tb && !flat_on_lr) {
    return false;
  }
  // We either transform the bounds and delta-transform the radii,
  // or we compute the vertical and horizontal bounds and then
  // transform each. Either way there are 2 transform operations.
  // We could also get a weaker answer by computing just the
  // "inner rect" and only doing a coverage analysis on that,
  // but this process will produce more culling results.
  if (flat_on_tb) {
    Rect vertical_bounds = bounds.Expand(-left_margin, 0, -right_margin, 0);
    Rect coverage = vertical_bounds.TransformBounds(transform);
    if (coverage.Contains(rect)) {
      return true;
    }
  }
  if (flat_on_lr) {
    Rect horizontal_bounds = bounds.Expand(0, -top_margin, 0, -bottom_margin);
    Rect coverage = horizontal_bounds.TransformBounds(transform);
    if (coverage.Contains(rect)) {
      return true;
    }
  }
  return false;
}

StrokeRoundRectGeometry::StrokeRoundRectGeometry(
    const RoundRect& round_rect,
    const StrokeParameters& parameters)
    : StrokePathSourceGeometry(parameters), round_rect_source_(round_rect) {}

const PathSource& StrokeRoundRectGeometry::GetSource() const {
  return round_rect_source_;
}

}  // namespace impeller
