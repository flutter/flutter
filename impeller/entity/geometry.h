// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/entity/contents/contents.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/solid_fill.vert.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/path.h"
#include "impeller/renderer/allocator.h"
#include "impeller/renderer/host_buffer.h"
#include "impeller/renderer/vertex_buffer.h"

namespace impeller {

class Tessellator;

struct GeometryResult {
  PrimitiveType type;
  VertexBuffer vertex_buffer;
  Matrix transform;
  bool prevent_overdraw;
};

enum GeometryVertexType {
  kPosition,
  kColor,
  kUV,
};

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

class Geometry {
 public:
  Geometry();

  virtual ~Geometry();

  static std::unique_ptr<Geometry> MakeFillPath(const Path& path);

  static std::unique_ptr<Geometry> MakeStrokePath(
      const Path& path,
      Scalar stroke_width = 0.0,
      Scalar miter_limit = 4.0,
      Cap stroke_cap = Cap::kButt,
      Join stroke_join = Join::kMiter);

  static std::unique_ptr<Geometry> MakeCover();

  static std::unique_ptr<Geometry> MakeRect(Rect rect);

  virtual GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                           const Entity& entity,
                                           RenderPass& pass) = 0;

  virtual GeometryVertexType GetVertexType() const = 0;

  virtual std::optional<Rect> GetCoverage(const Matrix& transform) const = 0;
};

/// @brief A geometry that is created from a vertices object.
class VerticesGeometry : public Geometry {
 public:
  virtual GeometryResult GetPositionColorBuffer(const ContentContext& renderer,
                                                const Entity& entity,
                                                RenderPass& pass) = 0;

  virtual GeometryResult GetPositionUVBuffer(const ContentContext& renderer,
                                             const Entity& entity,
                                             RenderPass& pass) = 0;

  virtual bool HasVertexColors() const = 0;
};

/// @brief A geometry that is created from a filled path object.
class FillPathGeometry : public Geometry {
 public:
  explicit FillPathGeometry(const Path& path);

  ~FillPathGeometry();

 private:
  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) override;

  // |Geometry|
  GeometryVertexType GetVertexType() const override;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

  Path path_;

  FML_DISALLOW_COPY_AND_ASSIGN(FillPathGeometry);
};

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
                         Scalar tolerance)>;
  using JoinProc =
      std::function<void(VertexBufferBuilder<VS::PerVertexData>& vtx_builder,
                         const Point& position,
                         const Point& start_offset,
                         const Point& end_offset,
                         Scalar miter_limit,
                         Scalar tolerance)>;

  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) override;

  // |Geometry|
  GeometryVertexType GetVertexType() const override;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

  static Scalar CreateBevelAndGetDirection(
      VertexBufferBuilder<SolidFillVertexShader::PerVertexData>& vtx_builder,
      const Point& position,
      const Point& start_offset,
      const Point& end_offset);

  static VertexBuffer CreateSolidStrokeVertices(const Path& path,
                                                HostBuffer& buffer,
                                                Scalar stroke_width,
                                                Scalar scaled_miter_limit,
                                                const JoinProc& join_proc,
                                                const CapProc& cap_proc,
                                                Scalar tolerance);

  static StrokePathGeometry::JoinProc GetJoinProc(Join stroke_join);

  static StrokePathGeometry::CapProc GetCapProc(Cap stroke_cap);

  Path path_;
  Scalar stroke_width_;
  Scalar miter_limit_;
  Cap stroke_cap_;
  Join stroke_join_;

  FML_DISALLOW_COPY_AND_ASSIGN(StrokePathGeometry);
};

/// @brief A geometry that implements "drawPaint" like behavior by covering
///        the entire render pass area.
class CoverGeometry : public Geometry {
 public:
  CoverGeometry();

  ~CoverGeometry();

 private:
  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) override;

  // |Geometry|
  GeometryVertexType GetVertexType() const override;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

  FML_DISALLOW_COPY_AND_ASSIGN(CoverGeometry);
};

class RectGeometry : public Geometry {
 public:
  explicit RectGeometry(Rect rect);

  ~RectGeometry();

 private:
  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) override;

  // |Geometry|
  GeometryVertexType GetVertexType() const override;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

  Rect rect_;

  FML_DISALLOW_COPY_AND_ASSIGN(RectGeometry);
};

}  // namespace impeller
