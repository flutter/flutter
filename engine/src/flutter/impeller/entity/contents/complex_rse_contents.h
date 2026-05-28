// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_COMPLEX_RSE_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_COMPLEX_RSE_CONTENTS_H_

#include <memory>
#include <optional>

#include "flutter/impeller/entity/contents/color_source_contents.h"
#include "flutter/impeller/entity/contents/contents.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/round_superellipse_param.h"
#include "impeller/geometry/stroke_parameters.h"

namespace impeller {

/// A contents class that renders asymmetric rounded superellipses using SDFs.
///
/// Separated from 'UberSDFContents' to reduce uniform bloat
class ComplexRoundedSuperellipseContents : public ColorSourceContents {
 public:
  static std::unique_ptr<ComplexRoundedSuperellipseContents> Make(
      Color color,
      const Rect& bounds,
      const RoundSuperellipseParam& round_superellipse_params,
      std::optional<StrokeParameters> stroke);

  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  const Geometry* GetGeometry() const override;

 private:
  explicit ComplexRoundedSuperellipseContents(
      Color color,
      const Rect& bounds,
      const RoundSuperellipseParam& round_superellipse_params,
      std::optional<StrokeParameters> stroke);

  Color color_;
  Rect bounds_;
  RoundSuperellipseParam round_superellipse_params_;
  std::optional<StrokeParameters> stroke_;
  std::unique_ptr<Geometry> geometry_;

  ComplexRoundedSuperellipseContents(
      const ComplexRoundedSuperellipseContents&) = delete;

  ComplexRoundedSuperellipseContents& operator=(
      const ComplexRoundedSuperellipseContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_COMPLEX_RSE_CONTENTS_H_
