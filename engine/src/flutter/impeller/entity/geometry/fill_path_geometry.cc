// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/entity/geometry/fill_path_geometry.h"

#include <array>
#include <cmath>
#include <cstring>
#include <vector>

#include "fml/logging.h"
#include "impeller/core/formats.h"
#include "impeller/core/vertex_buffer.h"
#include "impeller/entity/contents/content_context.h"
#include "impeller/entity/geometry/geometry.h"
#include "third_party/skia/include/core/SkPath.h"

namespace impeller {

namespace {
constexpr size_t kTessellatedPathCacheSize = 64u;
constexpr size_t kMaxCacheableBufferBytes = 65536u;

int SignOf(SkScalar x) {
  return x < 0.0f ? 1 : 0;
}

int CrossSign(const SkVector& a, const SkVector& b, SkScalar* out_cross = nullptr) {
  const SkScalar cross = a.fX * b.fY - a.fY * b.fX;
  if (out_cross) {
    *out_cross = cross;
  }
  if (cross > 0.0f) {
    return 1;
  }
  if (cross < 0.0f) {
    return -1;
  }
  return 0;
}

// Skia's SkPathPriv::ComputeConvexity tests the raw off-curve control polygon
// with zero tolerance. For RSuperellipse paths (built from two conics and a
// cubic circular arc per octant), the collinear control points at the conic
// join H and the C1 lookup-table tangent approximation at the conic-to-arc
// join J produce ~1e-7..1e-2 control-polygon cross-product sign flips even
// though every individual curve segment and the closed polygon of on-curve
// verb endpoints are strictly convex.
bool IsPiecewiseConvexSkPath(const SkPath& sk_path) {
  if (sk_path.isEmpty()) {
    return true;
  }
  const int verb_count = sk_path.countVerbs();
  if (verb_count < 3 || verb_count > 64) {
    return false;
  }

  std::vector<SkPoint> on_curve_pts;
  on_curve_pts.reserve(static_cast<size_t>(verb_count));

  SkPath::Iter iter(sk_path, false);
  SkPoint pts[4];
  int contour_count = 0;
  int curve_winding = 0;
  SkVector prev_out_vec = {0.0f, 0.0f};
  SkVector first_in_vec = {0.0f, 0.0f};

  auto check_join = [](const SkVector& u, const SkVector& v, int winding) -> bool {
    const SkScalar u_len2 = u.fX * u.fX + u.fY * u.fY;
    const SkScalar v_len2 = v.fX * v.fX + v.fY * v.fY;
    if (u_len2 == 0.0f || v_len2 == 0.0f) {
      return true;
    }
    const SkScalar dot = u.fX * v.fX + u.fY * v.fY;
    if (dot <= 0.0f) {
      return false;
    }
    const SkScalar cross = u.fX * v.fY - u.fY * v.fX;
    // Allow small C1 tangent-approximation discrepancies (|sin(theta)| <= 0.15)
    // at joins between convex curve segments while rejecting reflex corners.
    if (winding != 0 && cross * static_cast<SkScalar>(winding) < 0.0f) {
      const SkScalar max_sin_sq = 0.15f * 0.15f;
      if ((cross * cross) > max_sin_sq * u_len2 * v_len2) {
        return false;
      }
    }
    return true;
  };

  auto record_winding = [&curve_winding](int s) -> bool {
    if (s == 0) {
      return true;
    }
    if (curve_winding == 0) {
      curve_winding = s;
      return true;
    }
    return curve_winding == s;
  };

  for (;;) {
    SkPath::Verb verb = iter.next(pts);
    if (verb == SkPath::kDone_Verb) {
      break;
    }
    if (verb == SkPath::kMove_Verb) {
      if (contour_count > 0) {
        return false;
      }
      contour_count = 1;
      on_curve_pts.push_back(pts[0]);
      continue;
    }
    if (verb == SkPath::kClose_Verb) {
      continue;
    }
    if (contour_count != 1) {
      return false;
    }

    SkVector in_vec = {0.0f, 0.0f};
    SkVector out_vec = {0.0f, 0.0f};
    SkPoint end_pt = pts[0];

    switch (verb) {
      case SkPath::kLine_Verb: {
        in_vec = pts[1] - pts[0];
        out_vec = in_vec;
        end_pt = pts[1];
        break;
      }
      case SkPath::kQuad_Verb:
      case SkPath::kConic_Verb: {
        const SkVector v0 = pts[1] - pts[0];
        const SkVector v1 = pts[2] - pts[1];
        if (!record_winding(CrossSign(v0, v1))) {
          return false;
        }
        in_vec = v0;
        out_vec = v1;
        end_pt = pts[2];
        break;
      }
      case SkPath::kCubic_Verb: {
        const SkVector v0 = pts[1] - pts[0];
        const SkVector v1 = pts[2] - pts[1];
        const SkVector v2 = pts[3] - pts[2];
        if (!record_winding(CrossSign(v0, v1)) ||
            !record_winding(CrossSign(v1, v2)) ||
            !record_winding(CrossSign(v0, v2))) {
          return false;
        }
        in_vec = v0;
        out_vec = v2;
        end_pt = pts[3];
        break;
      }
      default:
        return false;
    }

    if (in_vec.fX == 0.0f && in_vec.fY == 0.0f &&
        out_vec.fX == 0.0f && out_vec.fY == 0.0f) {
      continue;
    }
    if (first_in_vec.fX == 0.0f && first_in_vec.fY == 0.0f) {
      first_in_vec = in_vec;
    } else if (!check_join(prev_out_vec, in_vec, curve_winding)) {
      return false;
    }
    prev_out_vec = out_vec;
    if (on_curve_pts.empty() || on_curve_pts.back() != end_pt) {
      on_curve_pts.push_back(end_pt);
    }
  }

  if (on_curve_pts.size() > 1 && on_curve_pts.back() == on_curve_pts.front()) {
    on_curve_pts.pop_back();
  }
  const size_t n = on_curve_pts.size();
  if (n < 3) {
    return false;
  }
  if (!check_join(prev_out_vec, first_in_vec, curve_winding)) {
    return false;
  }

  int dx_changes = 0;
  int dy_changes = 0;
  int last_sx = -1;
  int last_sy = -1;
  for (size_t pass = 0; pass < 2; ++pass) {
    const size_t limit = (pass == 0) ? n : 1;
    for (size_t i = 0; i < limit; ++i) {
      const SkPoint prev = on_curve_pts[(i + n - 1) % n];
      const SkPoint curr = on_curve_pts[i];
      const SkVector d = curr - prev;
      if (d.fX != 0.0f || d.fY != 0.0f) {
        const int sx = SignOf(d.fX);
        const int sy = SignOf(d.fY);
        if (last_sx != -1 && sx != last_sx) {
          ++dx_changes;
        }
        if (last_sy != -1 && sy != last_sy) {
          ++dy_changes;
        }
        if (dx_changes > 3 || dy_changes > 3) {
          return false;
        }
        last_sx = sx;
        last_sy = sy;
      }
    }
  }

  for (size_t i = 0; i < n; ++i) {
    const SkPoint p0 = on_curve_pts[(i + n - 1) % n];
    const SkPoint p1 = on_curve_pts[i];
    const SkPoint p2 = on_curve_pts[(i + 1) % n];
    if (!record_winding(CrossSign(p1 - p0, p2 - p1))) {
      return false;
    }
  }

  return curve_winding != 0;
}

struct CachedConvexityEntry {
  flutter::DlPath path;
  GeometryResult::Mode mode = GeometryResult::Mode::kNormal;
  bool valid = false;
};

struct ConvexityCache {
  std::array<CachedConvexityEntry, kTessellatedPathCacheSize> entries;
  size_t next_slot = 0u;
};

ConvexityCache& GetConvexityCache() {
  thread_local ConvexityCache cache;
  return cache;
}

struct CachedTessellatedPath {
  flutter::DlPath path;
  Scalar tolerance = 0.0f;
  bool supports_primitive_restart = false;
  bool supports_triangle_fan = false;
  std::vector<uint8_t> vertex_bytes;
  std::vector<uint8_t> index_bytes;
  size_t vertex_count = 0u;
  IndexType index_type = IndexType::kNone;
  GeometryResult::Mode mode = GeometryResult::Mode::kNormal;
  bool valid = false;
};

struct TessellatedPathCache {
  std::array<CachedTessellatedPath, kTessellatedPathCacheSize> entries;
  size_t next_slot = 0u;
};

TessellatedPathCache& GetTessellatedPathCache() {
  thread_local TessellatedPathCache cache;
  return cache;
}
}  // namespace

FillPathSourceGeometry::FillPathSourceGeometry(std::optional<Rect> inner_rect)
    : inner_rect_(inner_rect) {}

FillPathSourceGeometry::~FillPathSourceGeometry() {}

GeometryResult FillPathSourceGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  auto& data_host_buffer = renderer.GetTransientsDataBuffer();
  auto& indexes_host_buffer = renderer.GetTransientsIndexesBuffer();

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
      GetSource(), data_host_buffer, indexes_host_buffer,
      entity.GetTransform().GetMaxBasisLengthXY(),
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
                                        const IRect& rect) const {
  if (!inner_rect_.has_value()) {
    return false;
  }
  if (!transform.IsTranslationScaleOnly()) {
    return false;
  }
  Rect coverage = inner_rect_->TransformBounds(transform);
  return coverage.Contains(rect);
}

FillPathFromSourceGeometry::FillPathFromSourceGeometry(const PathSource& source)
    : FillPathSourceGeometry(std::nullopt), source_(source) {}

const PathSource& FillPathFromSourceGeometry::GetSource() const {
  return source_;
}

FillPathGeometry::FillPathGeometry(const flutter::DlPath& path,
                                   std::optional<Rect> inner_rect)
    : FillPathSourceGeometry(inner_rect), path_(path) {}

const PathSource& FillPathGeometry::GetSource() const {
  return path_;
}

GeometryResult::Mode FillPathGeometry::GetResultMode() const {
  const auto& bounding_box = path_.GetBounds();
  if (path_.IsConvex() || bounding_box.IsEmpty()) {
    return GeometryResult::Mode::kNormal;
  }

  auto& cache = GetConvexityCache();
  for (const auto& entry : cache.entries) {
    if (entry.valid && entry.path == path_) {
      return entry.mode;
    }
  }

  GeometryResult::Mode mode;
  if (IsPiecewiseConvexSkPath(path_.GetSkPath())) {
    mode = GeometryResult::Mode::kNormal;
  } else {
    switch (path_.GetFillType()) {
      case FillType::kNonZero:
        mode = GeometryResult::Mode::kNonZero;
        break;
      case FillType::kOdd:
        mode = GeometryResult::Mode::kEvenOdd;
        break;
    }
  }

  auto& slot = cache.entries[cache.next_slot];
  cache.next_slot = (cache.next_slot + 1u) % kTessellatedPathCacheSize;
  slot.path = path_;
  slot.mode = mode;
  slot.valid = true;
  return mode;
}

GeometryResult FillPathGeometry::GetPositionBuffer(
    const ContentContext& renderer,
    const Entity& entity,
    RenderPass& pass) const {
  const auto& bounding_box = path_.GetBounds();
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

  auto& data_host_buffer = renderer.GetTransientsDataBuffer();
  auto& indexes_host_buffer = renderer.GetTransientsIndexesBuffer();

  const bool supports_primitive_restart =
      renderer.GetDeviceCapabilities().SupportsPrimitiveRestart();
  const bool supports_triangle_fan =
      renderer.GetDeviceCapabilities().SupportsTriangleFan() &&
      supports_primitive_restart;
  const Scalar tolerance = entity.GetTransform().GetMaxBasisLengthXY();

  auto& cache = GetTessellatedPathCache();
  for (const auto& entry : cache.entries) {
    if (entry.valid && entry.tolerance == tolerance &&
        entry.supports_primitive_restart == supports_primitive_restart &&
        entry.supports_triangle_fan == supports_triangle_fan &&
        entry.path == path_) {
      if (entry.vertex_count == 0u) {
        return GeometryResult{
            .type = supports_triangle_fan ? PrimitiveType::kTriangleFan
                                          : PrimitiveType::kTriangleStrip,
            .vertex_buffer =
                VertexBuffer{
                    .vertex_buffer = {},
                    .index_buffer = {},
                    .vertex_count = 0u,
                    .index_type = entry.index_type,
                },
            .transform = entity.GetShaderTransform(pass),
            .mode = entry.mode,
        };
      }

      BufferView point_buffer = data_host_buffer.Emplace(
          entry.vertex_bytes.data(), entry.vertex_bytes.size(), alignof(Point));
      BufferView index_buffer;
      if (entry.index_type != IndexType::kNone) {
        const size_t index_align = (entry.index_type == IndexType::k32bit)
                                       ? alignof(uint32_t)
                                       : alignof(uint16_t);
        index_buffer = indexes_host_buffer.Emplace(
            entry.index_bytes.data(), entry.index_bytes.size(), index_align);
      }

      return GeometryResult{
          .type = supports_triangle_fan ? PrimitiveType::kTriangleFan
                                        : PrimitiveType::kTriangleStrip,
          .vertex_buffer =
              VertexBuffer{
                  .vertex_buffer = std::move(point_buffer),
                  .index_buffer = std::move(index_buffer),
                  .vertex_count = entry.vertex_count,
                  .index_type = entry.index_type,
              },
          .transform = entity.GetShaderTransform(pass),
          .mode = entry.mode,
      };
    }
  }

  VertexBuffer vertex_buffer = renderer.GetTessellator().TessellateConvex(
      path_, data_host_buffer, indexes_host_buffer, tolerance,
      /*supports_primitive_restart=*/supports_primitive_restart,
      /*supports_triangle_fan=*/supports_triangle_fan);
  const GeometryResult::Mode mode = GetResultMode();

  if (vertex_buffer.vertex_count > 0u && vertex_buffer.vertex_buffer &&
      vertex_buffer.index_buffer) {
    const size_t index_elem_size =
        (vertex_buffer.index_type == IndexType::k32bit) ? sizeof(uint32_t)
                                                        : sizeof(uint16_t);
    const Range& v_range = vertex_buffer.vertex_buffer.GetRange();
    const Range& i_range = vertex_buffer.index_buffer.GetRange();
    const size_t used_index_bytes =
        std::min(i_range.length, vertex_buffer.vertex_count * index_elem_size);
    if (v_range.length <= kMaxCacheableBufferBytes &&
        used_index_bytes <= kMaxCacheableBufferBytes) {
      auto& slot = cache.entries[cache.next_slot];
      cache.next_slot = (cache.next_slot + 1u) % kTessellatedPathCacheSize;
      slot.path = path_;
      slot.tolerance = tolerance;
      slot.supports_primitive_restart = supports_primitive_restart;
      slot.supports_triangle_fan = supports_triangle_fan;
      slot.mode = mode;

      const uint8_t* v_src =
          vertex_buffer.vertex_buffer.GetBuffer()->OnGetContents() +
          v_range.offset;
      const uint8_t* i_src =
          vertex_buffer.index_buffer.GetBuffer()->OnGetContents() +
          i_range.offset;

      // When rendering a single-contour triangle strip with primitive restart
      // (only a trailing -1 restart sentinel at the end of the index buffer),
      // pre-expand the indexed vertices into a contiguous unindexed triangle
      // strip so cached draws use glDrawArrays without binding an index buffer.
      bool expanded_unindexed = false;
      if (!supports_triangle_fan && supports_primitive_restart &&
          vertex_buffer.index_type == IndexType::k16bit &&
          vertex_buffer.vertex_count >= 4u) {
        const auto* pts = reinterpret_cast<const Point*>(v_src);
        const size_t max_pts = v_range.length / sizeof(Point);
        const auto* idxs = reinterpret_cast<const uint16_t*>(i_src);
        const size_t idx_count = vertex_buffer.vertex_count;
        if (idxs[idx_count - 1u] == 0xFFFFu) {
          bool single_contour = true;
          for (size_t k = 0; k + 1u < idx_count; ++k) {
            if (idxs[k] == 0xFFFFu || idxs[k] >= max_pts) {
              single_contour = false;
              break;
            }
          }
          if (single_contour) {
            const size_t strip_count = idx_count - 1u;
            slot.vertex_bytes.resize(strip_count * sizeof(Point));
            auto* dst_pts = reinterpret_cast<Point*>(slot.vertex_bytes.data());
            for (size_t k = 0; k < strip_count; ++k) {
              dst_pts[k] = pts[idxs[k]];
            }
            slot.index_bytes.clear();
            slot.vertex_count = strip_count;
            slot.index_type = IndexType::kNone;
            expanded_unindexed = true;
          }
        }
      }

      if (!expanded_unindexed) {
        slot.vertex_bytes.assign(v_src, v_src + v_range.length);
        slot.index_bytes.assign(i_src, i_src + used_index_bytes);
        slot.vertex_count = vertex_buffer.vertex_count;
        slot.index_type = vertex_buffer.index_type;
      }
      slot.valid = true;
    }
  }

  return GeometryResult{
      .type = supports_triangle_fan ? PrimitiveType::kTriangleFan
                                    : PrimitiveType::kTriangleStrip,
      .vertex_buffer = std::move(vertex_buffer),
      .transform = entity.GetShaderTransform(pass),
      .mode = mode,
  };
}

FillDiffRoundRectGeometry::FillDiffRoundRectGeometry(const RoundRect& outer,
                                                     const RoundRect& inner)
    : FillPathSourceGeometry(std::nullopt), source_(outer, inner) {}

const PathSource& FillDiffRoundRectGeometry::GetSource() const {
  return source_;
}

}  // namespace impeller
