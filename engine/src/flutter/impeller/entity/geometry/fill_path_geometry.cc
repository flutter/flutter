// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/fill_path_geometry.h"

#include "fml/logging.h"
#include "impeller/core/formats.h"
#include "impeller/core/vertex_buffer.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/geometry/geometry.h"

namespace impeller {

FillPathSourceGeometry::FillPathSourceGeometry(std::optional<Rect> inner_rect)
    : inner_rect_(inner_rect) {}

FillPathSourceGeometry::~FillPathSourceGeometry() {}

GeometryResult FillPathSourceGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  auto& host_buffer = renderer.GetTransientsBuffer();

  const auto& bounding_box = GetSource().GetBounds();
  if (bounding_box.IsEmpty()) {
    return GeometryResult{
        .type = PrimitiveType::kTriangle,
        .vertex_buffer =
            VertexBuffer{
                .vertex_buffer = {},
                .vertex_count = 0,
                .index_type = IndexType::k16bit,
            },
        .transform = pass.GetOrthographicTransform() * entity.GetTransform(),
    };
  }

  bool supports_primitive_restart =
      renderer.GetDeviceCapabilities().SupportsPrimitiveRestart();
  bool supports_triangle_fan =
      renderer.GetDeviceCapabilities().SupportsTriangleFan() &&
      supports_primitive_restart;
  VertexBuffer vertex_buffer = renderer.GetTessellator().TessellateConvex(
      GetSource(), host_buffer, entity.GetTransform().GetMaxBasisLengthXY(),
      /*supports_primitive_restart=*/supports_primitive_restart,
      /*supports_triangle_fan=*/supports_triangle_fan);

  return GeometryResult{
      .type = supports_triangle_fan ? PrimitiveType::kTriangleFan
                                    : PrimitiveType::kTriangleStrip,
      .vertex_buffer = std::move(vertex_buffer),
      .transform = entity.GetShaderTransform(pass),
      .mode = GetResultMode(),
  };
}

GeometryResult::Mode FillPathSourceGeometry::GetResultMode() const {
  const PathSource& source = GetSource();
  const auto& bounding_box = source.GetBounds();
  if (source.IsConvex() || bounding_box.IsEmpty()) {
    return GeometryResult::Mode::kNormal;
  }

  switch (source.GetFillType()) {
    case FillType::kNonZero:
      return GeometryResult::Mode::kNonZero;
    case FillType::kOdd:
      return GeometryResult::Mode::kEvenOdd;
  }

  FML_UNREACHABLE();
}

std::optional<Rect> FillPathSourceGeometry::GetCoverage(
    const Matrix& transform) const {
  return GetSource().GetBounds().TransformAndClipBounds(transform);
}

bool FillPathSourceGeometry::CoversArea(const Matrix& transform,
                                        const Rect& rect) const {
  if (!inner_rect_.has_value()) {
    return false;
  }
  if (!transform.IsTranslationScaleOnly()) {
    return false;
  }
  Rect coverage = inner_rect_->TransformBounds(transform);
  return coverage.Contains(rect);
}

FillPathGeometry::FillPathGeometry(const flutter::DlPath& path,
                                   std::optional<Rect> inner_rect)
    : FillPathSourceGeometry(inner_rect), path_(path) {}

const PathSource& FillPathGeometry::GetSource() const {
  return path_;
}

ArcFillPathGeometry::ArcFillPathGeometry(const flutter::DlPath& path,
                                         const Rect& oval_bounds)
    : FillPathSourceGeometry(std::nullopt),
      path_(path),
      oval_bounds_(oval_bounds) {}

const PathSource& ArcFillPathGeometry::GetSource() const {
  return path_;
}

std::optional<Rect> ArcFillPathGeometry::GetCoverage(
    const Matrix& transform) const {
  return GetSource()
      .GetBounds()
      .IntersectionOrEmpty(oval_bounds_)
      .TransformAndClipBounds(transform);
}

FillDiffRoundRectGeometry::FillDiffRoundRectGeometry(const RoundRect& outer,
                                                     const RoundRect& inner)
    : FillPathSourceGeometry(std::nullopt), source_(outer, inner) {}

const PathSource& FillDiffRoundRectGeometry::GetSource() const {
  return source_;
}

}  // namespace impeller
