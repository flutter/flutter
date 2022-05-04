// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/solid_stroke.vert.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/path_component.h"
#include "impeller/geometry/point.h"

namespace impeller {

class SolidStrokeContents final : public Contents {
 public:
  enum class Cap {
    kButt,
    kRound,
    kSquare,
  };

  enum class Join {
    kMiter,
    kRound,
    kBevel,
  };

  using CapProc = std::function<void(
      VertexBufferBuilder<SolidStrokeVertexShader::PerVertexData>& vtx_builder,
      const Point& position,
      const Point& normal,
      const SmoothingApproximation& smoothing)>;
  using JoinProc = std::function<void(
      VertexBufferBuilder<SolidStrokeVertexShader::PerVertexData>& vtx_builder,
      const Point& position,
      const Point& start_normal,
      const Point& end_normal,
      Scalar miter_limit,
      const SmoothingApproximation& smoothing)>;

  SolidStrokeContents();

  ~SolidStrokeContents() override;

  void SetPath(Path path);

  void SetColor(Color color);

  const Color& GetColor() const;

  void SetStrokeSize(Scalar size);

  Scalar GetStrokeSize() const;

  void SetStrokeMiter(Scalar miter_limit);

  Scalar GetStrokeMiter();

  void SetStrokeCap(Cap cap);

  Cap GetStrokeCap();

  void SetStrokeJoin(Join join);

  Join GetStrokeJoin();

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

 private:
  Path path_;

  Color color_;
  Scalar stroke_size_ = 0.0;
  Scalar miter_limit_ = 4.0;

  Cap cap_;
  CapProc cap_proc_;

  Join join_;
  JoinProc join_proc_;

  FML_DISALLOW_COPY_AND_ASSIGN(SolidStrokeContents);
};

}  // namespace impeller
