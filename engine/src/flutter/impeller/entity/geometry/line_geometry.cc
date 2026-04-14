// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/line_geometry.h"
#include "impeller/entity/contents/pipelines.h"
#include "impeller/entity/geometry/geometry.h"

namespace impeller {

LineGeometry::LineGeometry(Point p0, Point p1, const StrokeParameters& stroke)
    : p0_(p0), p1_(p1), width_(stroke.width), cap_(stroke.cap) {
  FML_DCHECK(width_ >= 0);
}

LineGeometry::~LineGeometry() = default;

Scalar LineGeometry::ComputePixelHalfWidth(const Matrix& transform,
                                           Scalar width) {
  Scalar max_basis = transform.GetMaxBasisLengthXY();
  if (max_basis == 0) {
    return {};
  }

  Scalar min_size = kMinStrokeSize / max_basis;
  return std::max(width, min_size) * 0.5f;
}

Vector2 LineGeometry::ComputeAlongVector(const Matrix& transform,
                                         bool allow_zero_length,
                                         Point p0,
                                         Point p1,
                                         Scalar width) {
  Scalar stroke_half_width = ComputePixelHalfWidth(transform, width);
  if (stroke_half_width < kEhCloseEnough) {
    return {};
  }

  auto along = p1 - p0;
  Scalar length = along.GetLength();
  if (length < kEhCloseEnough) {
    if (!allow_zero_length) {
      // We won't enclose any pixels unless the endpoints are extended
      return {};
    }
    return {stroke_half_width, 0};
  } else {
    return along * stroke_half_width / length;
  }
}

bool LineGeometry::ComputeCorners(Point corners[4],
                                  const Matrix& transform,
                                  bool extend_endpoints,
                                  Point p0,
                                  Point p1,
                                  Scalar width) {
  auto along = ComputeAlongVector(transform, extend_endpoints, p0, p1, width);
  if (along.IsZero()) {
    return false;
  }

  auto across = Vector2(along.y, -along.x);
  corners[0] = p0 - across;
  corners[1] = p1 - across;
  corners[2] = p0 + across;
  corners[3] = p1 + across;
  if (extend_endpoints) {
    corners[0] -= along;
    corners[1] += along;
    corners[2] -= along;
    corners[3] += along;
  }
  return true;
}

Scalar LineGeometry::ComputeAlphaCoverage(const Matrix& entity) const {
  return Geometry::ComputeStrokeAlphaCoverage(entity, width_);
}

namespace {
/// Minimizes the err when rounding to the closest 0.5 value.
/// If we round up, it drops down a half.  If we round down it bumps up a half.
Scalar RoundToHalf(Scalar x) {
  Scalar whole;
  std::modf(x, &whole);
  return whole + 0.5;
}
}  // namespace

GeometryResult LineGeometry::GetPositionBuffer(const ContentContext& renderer,
                                               const Entity& entity,
                                               RenderPass& pass) const {
  using VT = SolidFillVertexShader::PerVertexData;

  Matrix transform = entity.GetTransform();
  auto radius = ComputePixelHalfWidth(transform, width_);

  Point p0 = p0_;
  Point p1 = p1_;

  // Hairline pixel alignment.
  if (width_ == 0.f && transform.IsTranslationScaleOnly()) {
    p0 = transform * p0_;
    p1 = transform * p1_;
    transform = Matrix();
    if (std::fabs(p0.x - p1.x) < kEhCloseEnough) {
      p0.x = RoundToHalf(p0.x);
      p1.x = p0.x;
    } else if (std::fabs(p0.y - p1.y) < kEhCloseEnough) {
      p0.y = RoundToHalf(p0.y);
      p1.y = p0.y;
    }
  }

  Entity fixed_transform = entity.Clone();
  fixed_transform.SetTransform(transform);

  if (cap_ == Cap::kRound) {
    auto generator =
        renderer.GetTessellator().RoundCapLine(transform, p0, p1, radius);
    return ComputePositionGeometry(renderer, generator, fixed_transform, pass);
  }

  Point corners[4];
  if (!ComputeCorners(corners, transform, cap_ == Cap::kSquare, p0, p1,
                      width_)) {
    return kEmptyResult;
  }

  auto& data_host_buffer = renderer.GetTransientsDataBuffer();

  size_t count = 4;
  BufferView vertex_buffer = data_host_buffer.Emplace(
      count * sizeof(VT), alignof(VT), [&corners](uint8_t* buffer) {
        auto vertices = reinterpret_cast<VT*>(buffer);
        for (auto& corner : corners) {
          *vertices++ = {
              .position = corner,
          };
        }
      });

  return GeometryResult{
      .type = PrimitiveType::kTriangleStrip,
      .vertex_buffer =
          {
              .vertex_buffer = vertex_buffer,
              .vertex_count = count,
              .index_type = IndexType::kNone,
          },
      .transform = fixed_transform.GetShaderTransform(pass),
  };
}

std::optional<Rect> LineGeometry::GetCoverage(const Matrix& transform) const {
  Point corners[4];
  // Note: MSAA boolean doesn't matter for coverage computation.
  if (!ComputeCorners(corners, transform, cap_ != Cap::kButt, p0_, p1_,
                      width_)) {
    return {};
  }

  for (int i = 0; i < 4; i++) {
    corners[i] = transform * corners[i];
  }
  return Rect::MakePointBounds(std::begin(corners), std::end(corners));
}

bool LineGeometry::CoversArea(const Matrix& transform, const Rect& rect) const {
  if (!transform.IsTranslationScaleOnly() || !IsAxisAlignedRect()) {
    return false;
  }
  auto coverage = GetCoverage(transform);
  return coverage.has_value() ? coverage->Contains(rect) : false;
}

bool LineGeometry::IsAxisAlignedRect() const {
  return cap_ != Cap::kRound && (p0_.x == p1_.x || p0_.y == p1_.y);
}

}  // namespace impeller
