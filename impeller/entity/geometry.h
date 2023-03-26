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

  static std::unique_ptr<Geometry> MakeRRect(Rect rect, Scalar corner_radius);

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

  virtual GeometryResult GetPositionUVBuffer(Rect texture_coverage,
                                             Matrix effect_transform,
                                             const ContentContext& renderer,
                                             const Entity& entity,
                                             RenderPass& pass);

  virtual GeometryVertexType GetVertexType() const = 0;

  virtual std::optional<Rect> GetCoverage(const Matrix& transform) const = 0;
};

/// @brief A geometry that is created from a vertices object.
class VerticesGeometry : public Geometry {
 public:
  virtual GeometryResult GetPositionColorBuffer(const ContentContext& renderer,
                                                const Entity& entity,
                                                RenderPass& pass) = 0;

  virtual bool HasVertexColors() const = 0;

  virtual bool HasTextureCoordinates() const = 0;

  virtual std::optional<Rect> GetTextureCoordinateCoverge() const = 0;
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

  // |Geometry|
  GeometryResult GetPositionUVBuffer(Rect texture_coverage,
                                     Matrix effect_transform,
                                     const ContentContext& renderer,
                                     const Entity& entity,
                                     RenderPass& pass) override;

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

  // |Geometry|
  GeometryResult GetPositionUVBuffer(Rect texture_coverage,
                                     Matrix effect_transform,
                                     const ContentContext& renderer,
                                     const Entity& entity,
                                     RenderPass& pass) override;

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

  // |Geometry|
  GeometryResult GetPositionUVBuffer(Rect texture_coverage,
                                     Matrix effect_transform,
                                     const ContentContext& renderer,
                                     const Entity& entity,
                                     RenderPass& pass) override;

  Rect rect_;

  FML_DISALLOW_COPY_AND_ASSIGN(RectGeometry);
};

class RRectGeometry : public Geometry {
 public:
  explicit RRectGeometry(Rect rect, Scalar corner_radius);

  ~RRectGeometry();

 private:
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

  VertexBufferBuilder<Point> CreatePositionBuffer(const Entity& entity) const;

  Rect rect_;
  Scalar corner_radius_;

  FML_DISALLOW_COPY_AND_ASSIGN(RRectGeometry);
};

}  // namespace impeller
