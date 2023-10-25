// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/entity/geometry/geometry.h"

namespace impeller {

/// @brief A geometry that is created from a stroked path object.
class StrokePathGeometry : public Geometry {
 public:
  StrokePathGeometry(const Path& path,
                     Scalar stroke_width,
                     Scalar miter_limit,
                     Cap stroke_cap,
                     Join stroke_join);

  ~StrokePathGeometry();

  Scalar GetStrokeWidth() const;

  Scalar GetMiterLimit() const;

  Cap GetStrokeCap() const;

  Join GetStrokeJoin() const;

 private:
  using VS = SolidFillVertexShader;

  using CapProc =
      std::function<void(VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                         const Point& position,
                         const Point& offset,
                         Scalar scale,
                         bool reverse)>;
  using JoinProc =
      std::function<void(VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                         const Point& position,
                         const Point& start_offset,
                         const Point& end_offset,
                         Scalar miter_limit,
                         Scalar scale)>;

  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) override;

  // |Geometry|
  GeometryResult GetPositionUVBuffer(Rect texture_coverage,
                                     Matrix effect_transform,
                                     const ContentContext& renderer,
                                     const Entity& entity,
                                     RenderPass& pass) override;

  // |Geometry|
  GeometryVertexType GetVertexType() const override;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

  bool SkipRendering() const;

  static Scalar CreateBevelAndGetDirection(
      VertexBufferBuilder<SolidFillVertexShader::PerVertexData>& vtx_builder,
      const Point& position,
      const Point& start_offset,
      const Point& end_offset);

  static VertexBufferBuilder<SolidFillVertexShader::PerVertexData>
  CreateSolidStrokeVertices(const Path& path,
                            Scalar stroke_width,
                            Scalar scaled_miter_limit,
                            const JoinProc& join_proc,
                            const CapProc& cap_proc,
                            Scalar scale);

  static StrokePathGeometry::JoinProc GetJoinProc(Join stroke_join);

  static StrokePathGeometry::CapProc GetCapProc(Cap stroke_cap);

  Path path_;
  Scalar stroke_width_;
  Scalar miter_limit_;
  Cap stroke_cap_;
  Join stroke_join_;

  StrokePathGeometry(const StrokePathGeometry&) = delete;

  StrokePathGeometry& operator=(const StrokePathGeometry&) = delete;
};

}  // namespace impeller
