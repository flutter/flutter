// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/tessellator/tessellator.h"
#include <cstdint>
#include <cstring>

#include "flutter/impeller/core/device_buffer.h"
#include "flutter/impeller/tessellator/path_tessellator.h"

namespace {
static constexpr int kPrecomputedDivisionCount = 1024;

static int kPrecomputedDivisions[kPrecomputedDivisionCount] = {
    // clang-format off
     1,  2,  3,  4,  4,  4,  5,  5,  5,  6,  6,  6,  7,  7,  7,  7,
     8,  8,  8,  8,  8,  9,  9,  9,  9,  9,  9, 10, 10, 10, 10, 10,
    10, 11, 11, 11, 11, 11, 11, 11, 12, 12, 12, 12, 12, 12, 12, 13,
    13, 13, 13, 13, 13, 13, 13, 14, 14, 14, 14, 14, 14, 14, 14, 14,
    15, 15, 15, 15, 15, 15, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16,
    16, 16, 16, 16, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 18, 18,
    18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 19, 19, 19, 19, 19, 19,
    19, 19, 19, 19, 19, 19, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20,
    20, 20, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21,
    22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 23, 23, 23,
    23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 24, 24, 24, 24,
    24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 25, 25, 25, 25, 25,
    25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 26, 26, 26, 26, 26,
    26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 27, 27, 27, 27,
    27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 28, 28, 28,
    28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 29,
    29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29,
    29, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30,
    30, 30, 30, 30, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
    31, 31, 31, 31, 31, 31, 31, 31, 32, 32, 32, 32, 32, 32, 32, 32,
    32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 32, 33, 33, 33,
    33, 33, 33, 33, 33, 33, 33, 33, 33, 33, 33, 33, 33, 33, 33, 33,
    33, 33, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34, 34,
    34, 34, 34, 34, 34, 34, 34, 35, 35, 35, 35, 35, 35, 35, 35, 35,
    35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 36, 36,
    36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36,
    36, 36, 36, 36, 36, 37, 37, 37, 37, 37, 37, 37, 37, 37, 37, 37,
    37, 37, 37, 37, 37, 37, 37, 37, 37, 37, 37, 37, 38, 38, 38, 38,
    38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38,
    38, 38, 38, 38, 38, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39,
    39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 40, 40,
    40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40,
    40, 40, 40, 40, 40, 40, 40, 41, 41, 41, 41, 41, 41, 41, 41, 41,
    41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41,
    41, 41, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42,
    42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 42, 43, 43, 43, 43,
    43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43,
    43, 43, 43, 43, 43, 43, 43, 43, 44, 44, 44, 44, 44, 44, 44, 44,
    44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44, 44,
    44, 44, 44, 44, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45,
    45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45, 45,
    45, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46,
    46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 47,
    47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47,
    47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 48, 48, 48,
    48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48,
    48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 49, 49, 49, 49,
    49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49,
    49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 50, 50, 50, 50, 50,
    50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50,
    50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 51, 51, 51, 51, 51,
    51, 51, 51, 51, 51, 51, 51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
    51, 51, 51, 51, 51, 51, 51, 51, 51, 51, 51, 51, 52, 52, 52, 52,
    52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
    52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 53, 53, 53,
    53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53,
    53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 54,
    54, 54, 54, 54, 54, 54, 54, 54, 54, 54, 54, 54, 54, 54, 54, 54,
    54, 54, 54, 54, 54, 54, 54, 54, 54, 54, 54, 54, 54, 54, 54, 54,
    54, 54, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55,
    55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55,
    55, 55, 55, 55, 55, 56, 56, 56, 56, 56, 56, 56, 56, 56, 56, 56,
    56, 56, 56, 56, 56, 56, 56, 56, 56, 56, 56, 56, 56, 56, 56, 56,
    56, 56, 56, 56, 56, 56, 56, 56, 56, 57, 57, 57, 57, 57, 57, 57,
    // clang-format on
};

static size_t ComputeQuadrantDivisions(impeller::Scalar pixel_radius) {
  if (pixel_radius <= 0.0) {
    return 1;
  }
  int radius_index = ceil(pixel_radius);
  if (radius_index < kPrecomputedDivisionCount) {
    return kPrecomputedDivisions[radius_index];
  }

  // For a circle with N divisions per quadrant, the maximum deviation of
  // the polgyon approximation from the true circle will be at the center
  // of the base of each triangular pie slice. We can compute that distance
  // by finding the midpoint of the line of the first slice and compare
  // its distance from the center of the circle to the radius. We will aim
  // to have the length of that bisector to be within |kCircleTolerance|
  // from the radius in pixels.
  //
  // Each vertex will appear at an angle of:
  //   theta(i) = (kPi / 2) * (i / N)  // for i in [0..N]
  // with each point falling at:
  //   point(i) = r * (cos(theta), sin(theta))
  // If we consider the unit circle to simplify the calculations below then
  // we need to scale the tolerance from its absolute quantity into a unit
  // circle fraction:
  //   k = tolerance / radius
  // Using this scaled tolerance below to avoid multiplying by the radius
  // throughout all of the math, we have:
  //   first point = (1, 0)   // theta(0) == 0
  //   theta = kPi / 2 / N    // theta(1)
  //   second point = (cos(theta), sin(theta)) = (c, s)
  //   midpoint = (first + second) * 0.5 = ((1 + c)/2, s/2)
  //   |midpoint| = sqrt((1 + c)*(1 + c)/4 + s*s/4)
  //     = sqrt((1 + c + c + c*c + s*s) / 4)
  //     = sqrt((1 + 2c + 1) / 4)
  //     = sqrt((2 + 2c) / 4)
  //     = sqrt((1 + c) / 2)
  //     = cos(theta / 2)     // using half-angle cosine formula
  //   error = 1 - |midpoint| = 1 - cos(theta / 2)
  //   cos(theta/2) = 1 - error
  //   theta/2 = acos(1 - error)
  //   kPi / 2 / N / 2 = acos(1 - error)
  //   kPi / 4 / acos(1 - error) = N
  // Since we need error <= k, we want divisions >= N, so we use:
  //   N = ceil(kPi / 4 / acos(1 - k))
  //
  // Math is confirmed in https://math.stackexchange.com/a/4132095
  // (keeping in mind that we are computing quarter circle divisions here)
  // which also points out a performance optimization that is accurate
  // to within an over-estimation of 1 division would be:
  //   N = ceil(kPi / 4 / sqrt(2 * k))
  // Since we have precomputed the divisions for radii up to 1024, we can
  // afford to be more accurate using the acos formula here for larger radii.
  double k = impeller::Tessellator::kCircleTolerance / pixel_radius;
  return ceil(impeller::kPiOver4 / std::acos(1 - k));
}

template <typename IndexT>
impeller::IndexType IndexTypeFor();
template <>
impeller::IndexType IndexTypeFor<uint32_t>() {
  return impeller::IndexType::k32bit;
}
template <>
impeller::IndexType IndexTypeFor<uint16_t>() {
  return impeller::IndexType::k16bit;
}

/// @brief A vertex writer that generates a triangle fan and requires primitive
/// restart.
template <typename IndexT>
class FanPathVertexWriter : public impeller::PathTessellator::VertexWriter {
 public:
  explicit FanPathVertexWriter(impeller::Point* point_buffer,
                               IndexT* index_buffer)
      : point_buffer_(point_buffer), index_buffer_(index_buffer) {}

  ~FanPathVertexWriter() = default;

  size_t GetIndexCount() const { return index_count_; }
  size_t GetPointCount() const { return count_; }

  void EndContour() override {
    if (count_ == 0) {
      return;
    }
    index_buffer_[index_count_++] = static_cast<IndexT>(-1);
  }

  void Write(impeller::Point point) override {
    index_buffer_[index_count_++] = count_;
    point_buffer_[count_++] = point;
  }

 private:
  size_t count_ = 0;
  size_t index_count_ = 0;
  impeller::Point* point_buffer_ = nullptr;
  IndexT* index_buffer_ = nullptr;
};

/// @brief A vertex writer that generates a triangle strip and requires
///        primitive restart.
template <typename IndexT>
class StripPathVertexWriter : public impeller::PathTessellator::VertexWriter {
 public:
  explicit StripPathVertexWriter(impeller::Point* point_buffer,
                                 IndexT* index_buffer)
      : point_buffer_(point_buffer), index_buffer_(index_buffer) {}

  ~StripPathVertexWriter() = default;

  size_t GetIndexCount() const { return index_count_; }
  size_t GetPointCount() const { return count_; }

  void EndContour() override {
    if (count_ == 0u || contour_start_ == count_ - 1) {
      // Empty or first contour.
      return;
    }

    size_t start = contour_start_;
    size_t end = count_ - 1;

    index_buffer_[index_count_++] = start;

    size_t a = start + 1;
    size_t b = end;
    while (a < b) {
      index_buffer_[index_count_++] = a;
      index_buffer_[index_count_++] = b;
      a++;
      b--;
    }
    if (a == b) {
      index_buffer_[index_count_++] = a;
    }

    contour_start_ = count_;
    index_buffer_[index_count_++] = static_cast<IndexT>(-1);
  }

  void Write(impeller::Point point) override {
    point_buffer_[count_++] = point;
  }

 private:
  size_t count_ = 0;
  size_t index_count_ = 0;
  size_t contour_start_ = 0;
  impeller::Point* point_buffer_ = nullptr;
  IndexT* index_buffer_ = nullptr;
};

/// @brief A vertex writer that has no hardware requirements.
template <typename IndexT>
class GLESPathVertexWriter : public impeller::PathTessellator::VertexWriter {
 public:
  explicit GLESPathVertexWriter(std::vector<impeller::Point>& points,
                                std::vector<IndexT>& indices)
      : points_(points), indices_(indices) {}

  ~GLESPathVertexWriter() = default;

  void EndContour() override {
    if (points_.size() == 0u || contour_start_ == points_.size() - 1) {
      // Empty or first contour.
      return;
    }

    auto start = contour_start_;
    auto end = points_.size() - 1;
    // All filled paths are drawn as if they are closed, but if
    // there is an explicit close then a lineTo to the origin
    // is inserted. This point isn't strictly necesary to
    // correctly render the shape and can be dropped.
    if (points_[end] == points_[start]) {
      end--;
    }

    // Triangle strip break for subsequent contours
    if (contour_start_ != 0) {
      auto back = indices_.back();
      indices_.push_back(back);
      indices_.push_back(start);
      indices_.push_back(start);

      // If the contour has an odd number of points, insert an extra point when
      // bridging to the next contour to preserve the correct triangle winding
      // order.
      if (previous_contour_odd_points_) {
        indices_.push_back(start);
      }
    } else {
      indices_.push_back(start);
    }

    size_t a = start + 1;
    size_t b = end;
    while (a < b) {
      indices_.push_back(a);
      indices_.push_back(b);
      a++;
      b--;
    }
    if (a == b) {
      indices_.push_back(a);
      previous_contour_odd_points_ = false;
    } else {
      previous_contour_odd_points_ = true;
    }
    contour_start_ = points_.size();
  }

  void Write(impeller::Point point) override { points_.push_back(point); }

 private:
  bool previous_contour_odd_points_ = false;
  size_t contour_start_ = 0u;
  std::vector<impeller::Point>& points_;
  std::vector<IndexT>& indices_;
};

template <typename IndexT>
void DoTessellateConvexInternal(const impeller::PathSource& path,
                                std::vector<impeller::Point>& point_buffer,
                                std::vector<IndexT>& index_buffer,
                                impeller::Scalar tolerance) {
  point_buffer.clear();
  index_buffer.clear();

  GLESPathVertexWriter writer(point_buffer, index_buffer);

  impeller::PathTessellator::PathToFilledVertices(path, writer, tolerance);
}

}  // namespace

namespace impeller {

template <typename IndexT>
class ConvexTessellatorImpl : public Tessellator::ConvexTessellator {
 public:
  ConvexTessellatorImpl() {
    point_buffer_.reserve(2048);
    index_buffer_.reserve(2048);
  }

  VertexBuffer TessellateConvex(const PathSource& path,
                                HostBuffer& data_host_buffer,
                                HostBuffer& indexes_host_buffer,
                                Scalar tolerance,
                                bool supports_primitive_restart,
                                bool supports_triangle_fan) override {
    if (supports_primitive_restart) {
      // Primitive Restart.
      const auto [point_count, contour_count] =
          PathTessellator::CountFillStorage(path, tolerance);
      BufferView point_buffer = data_host_buffer.Emplace(
          nullptr, sizeof(Point) * point_count, alignof(Point));
      BufferView index_buffer = indexes_host_buffer.Emplace(
          nullptr, sizeof(IndexT) * (point_count + contour_count),
          alignof(IndexT));

      auto* points_ptr =
          reinterpret_cast<Point*>(point_buffer.GetBuffer()->OnGetContents() +
                                   point_buffer.GetRange().offset);
      auto* indices_ptr =
          reinterpret_cast<IndexT*>(index_buffer.GetBuffer()->OnGetContents() +
                                    index_buffer.GetRange().offset);

      auto tessellate_path = [&](auto& writer) {
        PathTessellator::PathToFilledVertices(path, writer, tolerance);
        FML_DCHECK(writer.GetPointCount() <= point_count);
        FML_DCHECK(writer.GetIndexCount() <= (point_count + contour_count));
        point_buffer.GetBuffer()->Flush(point_buffer.GetRange());
        index_buffer.GetBuffer()->Flush(index_buffer.GetRange());

        return VertexBuffer{
            .vertex_buffer = std::move(point_buffer),
            .index_buffer = std::move(index_buffer),
            .vertex_count = writer.GetIndexCount(),
            .index_type = IndexTypeFor<IndexT>(),
        };
      };

      if (supports_triangle_fan) {
        FanPathVertexWriter writer(points_ptr, indices_ptr);
        return tessellate_path(writer);
      } else {
        StripPathVertexWriter writer(points_ptr, indices_ptr);
        return tessellate_path(writer);
      }
    }

    DoTessellateConvexInternal(path, point_buffer_, index_buffer_, tolerance);

    if (point_buffer_.empty()) {
      return VertexBuffer{
          .vertex_buffer = {},
          .index_buffer = {},
          .vertex_count = 0u,
          .index_type = IndexTypeFor<IndexT>(),
      };
    }

    BufferView vertex_buffer = data_host_buffer.Emplace(
        point_buffer_.data(), sizeof(Point) * point_buffer_.size(),
        alignof(Point));

    BufferView index_buffer = indexes_host_buffer.Emplace(
        index_buffer_.data(), sizeof(IndexT) * index_buffer_.size(),
        alignof(IndexT));

    return VertexBuffer{
        .vertex_buffer = std::move(vertex_buffer),
        .index_buffer = std::move(index_buffer),
        .vertex_count = index_buffer_.size(),
        .index_type = IndexTypeFor<IndexT>(),
    };
  }

 private:
  std::vector<Point> point_buffer_;
  std::vector<IndexT> index_buffer_;
};

Tessellator::Tessellator(bool supports_32bit_primitive_indices)
    : stroke_points_(kPointArenaSize) {
  if (supports_32bit_primitive_indices) {
    convex_tessellator_ = std::make_unique<ConvexTessellatorImpl<uint32_t>>();
  } else {
    convex_tessellator_ = std::make_unique<ConvexTessellatorImpl<uint16_t>>();
  }
}

Tessellator::~Tessellator() = default;

std::vector<Point>& Tessellator::GetStrokePointCache() {
  return stroke_points_;
}

Tessellator::Trigs Tessellator::GetTrigsForDeviceRadius(Scalar pixel_radius) {
  return GetTrigsForDivisions(ComputeQuadrantDivisions(pixel_radius));
}

VertexBuffer Tessellator::TessellateConvex(const PathSource& path,
                                           HostBuffer& data_host_buffer,
                                           HostBuffer& indexes_host_buffer,
                                           Scalar tolerance,
                                           bool supports_primitive_restart,
                                           bool supports_triangle_fan) {
  return convex_tessellator_->TessellateConvex(
      path, data_host_buffer, indexes_host_buffer, tolerance,
      supports_primitive_restart, supports_triangle_fan);
}

void Tessellator::TessellateConvexInternal(const PathSource& path,
                                           std::vector<Point>& point_buffer,
                                           std::vector<uint16_t>& index_buffer,
                                           Scalar tolerance) {
  DoTessellateConvexInternal(path, point_buffer, index_buffer, tolerance);
}

Tessellator::Trigs::Trigs(Scalar pixel_radius)
    : Tessellator::Trigs(ComputeQuadrantDivisions(pixel_radius)) {}

void Tessellator::Trigs::init(size_t divisions) {
  if (!trigs_.empty()) {
    return;
  }

  // Either not cached yet, or we are using the temp storage...
  trigs_.reserve(divisions + 1);

  double angle_scale = kPiOver2 / divisions;

  trigs_.emplace_back(1.0, 0.0);
  for (size_t i = 1; i < divisions; i++) {
    trigs_.emplace_back(Radians(i * angle_scale));
  }
  trigs_.emplace_back(0.0, 1.0);
}

Tessellator::Trigs Tessellator::GetTrigsForDivisions(size_t divisions) {
  return divisions < Tessellator::kCachedTrigCount
             ? Trigs(precomputed_trigs_[divisions], divisions)
             : Trigs(divisions);
}

using TessellatedVertexProc = Tessellator::TessellatedVertexProc;
using EllipticalVertexGenerator = Tessellator::EllipticalVertexGenerator;
using ArcVertexGenerator = Tessellator::ArcVertexGenerator;

EllipticalVertexGenerator::EllipticalVertexGenerator(
    EllipticalVertexGenerator::GeneratorProc& generator,
    Trigs&& trigs,
    PrimitiveType triangle_type,
    size_t vertices_per_trig,
    Data&& data)
    : impl_(generator),
      trigs_(std::move(trigs)),
      data_(data),
      vertices_per_trig_(vertices_per_trig) {}

EllipticalVertexGenerator Tessellator::FilledCircle(
    const Matrix& view_transform,
    const Point& center,
    Scalar radius) {
  size_t divisions =
      ComputeQuadrantDivisions(view_transform.GetMaxBasisLengthXY() * radius);
  return EllipticalVertexGenerator(Tessellator::GenerateFilledCircle,
                                   GetTrigsForDivisions(divisions),
                                   PrimitiveType::kTriangleStrip, 4,
                                   {
                                       .reference_centers = {center, center},
                                       .radii = {radius, radius},
                                       .half_width = -1.0f,
                                   });
}

EllipticalVertexGenerator Tessellator::StrokedCircle(
    const Matrix& view_transform,
    const Point& center,
    Scalar radius,
    Scalar half_width) {
  if (half_width > 0) {
    auto divisions = ComputeQuadrantDivisions(
        view_transform.GetMaxBasisLengthXY() * radius + half_width);
    return EllipticalVertexGenerator(Tessellator::GenerateStrokedCircle,
                                     GetTrigsForDivisions(divisions),
                                     PrimitiveType::kTriangleStrip, 8,
                                     {
                                         .reference_centers = {center, center},
                                         .radii = {radius, radius},
                                         .half_width = half_width,
                                     });
  } else {
    return FilledCircle(view_transform, center, radius);
  }
}

ArcVertexGenerator::ArcVertexGenerator(const Arc::Iteration& iteration,
                                       Trigs&& trigs,
                                       const Rect& oval_bounds,
                                       bool use_center,
                                       bool supports_triangle_fans)
    : iteration_(iteration),
      trigs_(std::move(trigs)),
      oval_bounds_(oval_bounds),
      use_center_(use_center),
      half_width_(-1.0f),
      cap_(Cap::kButt),
      supports_triangle_fans_(supports_triangle_fans) {}

ArcVertexGenerator::ArcVertexGenerator(const Arc::Iteration& iteration,
                                       Trigs&& trigs,
                                       const Rect& oval_bounds,
                                       Scalar half_width,
                                       Cap cap)
    : iteration_(iteration),
      trigs_(std::move(trigs)),
      oval_bounds_(oval_bounds),
      use_center_(false),
      half_width_(half_width),
      cap_(cap),
      supports_triangle_fans_(false) {}

PrimitiveType ArcVertexGenerator::GetTriangleType() const {
  return (half_width_ < 0 && supports_triangle_fans_)
             ? PrimitiveType::kTriangleFan
             : PrimitiveType::kTriangleStrip;
}

size_t ArcVertexGenerator::GetVertexCount() const {
  size_t count = iteration_.GetPointCount();
  if (half_width_ > 0) {
    FML_DCHECK(!use_center_);
    FML_DCHECK(cap_ != Cap::kRound);
    count *= 2;
    if (cap_ == Cap::kSquare) {
      count += 4;
    }
  } else if (supports_triangle_fans_) {
    if (use_center_) {
      count++;
    }
  } else {
    // corrugated triangle fan
    count += (count + 1) / 2;
  }
  return count;
}

void ArcVertexGenerator::GenerateVertices(
    const TessellatedVertexProc& proc) const {
  if (half_width_ > 0) {
    FML_DCHECK(!use_center_);
    Tessellator::GenerateStrokedArc(trigs_, iteration_, oval_bounds_,
                                    half_width_, cap_, proc);
  } else if (supports_triangle_fans_) {
    Tessellator::GenerateFilledArcFan(trigs_, iteration_, oval_bounds_,
                                      use_center_, proc);
  } else {
    Tessellator::GenerateFilledArcStrip(trigs_, iteration_, oval_bounds_,
                                        use_center_, proc);
  }
}

ArcVertexGenerator Tessellator::FilledArc(const Matrix& view_transform,
                                          const Arc& arc,
                                          bool supports_triangle_fans) {
  size_t divisions = ComputeQuadrantDivisions(
      view_transform.GetMaxBasisLengthXY() * arc.GetOvalSize().MaxDimension());

  return ArcVertexGenerator(
      arc.ComputeIterations(divisions), GetTrigsForDivisions(divisions),
      arc.GetOvalBounds(), arc.IncludeCenter(), supports_triangle_fans);
};

ArcVertexGenerator Tessellator::StrokedArc(const Matrix& view_transform,
                                           const Arc& arc,
                                           Cap cap,
                                           Scalar half_width) {
  FML_DCHECK(half_width > 0);
  FML_DCHECK(arc.IsPerfectCircle());
  FML_DCHECK(!arc.IncludeCenter());
  size_t divisions =
      ComputeQuadrantDivisions(view_transform.GetMaxBasisLengthXY() *
                               (arc.GetOvalSize().MaxDimension() + half_width));

  return ArcVertexGenerator(arc.ComputeIterations(divisions),
                            GetTrigsForDivisions(divisions),
                            arc.GetOvalBounds(), half_width, cap);
}

EllipticalVertexGenerator Tessellator::RoundCapLine(
    const Matrix& view_transform,
    const Point& p0,
    const Point& p1,
    Scalar radius) {
  auto along = p1 - p0;
  auto length = along.GetLength();
  if (length > kEhCloseEnough) {
    auto divisions =
        ComputeQuadrantDivisions(view_transform.GetMaxBasisLengthXY() * radius);
    return EllipticalVertexGenerator(Tessellator::GenerateRoundCapLine,
                                     GetTrigsForDivisions(divisions),
                                     PrimitiveType::kTriangleStrip, 4,
                                     {
                                         .reference_centers = {p0, p1},
                                         .radii = {radius, radius},
                                         .half_width = -1.0f,
                                     });
  } else {
    return FilledCircle(view_transform, p0, radius);
  }
}

EllipticalVertexGenerator Tessellator::FilledEllipse(
    const Matrix& view_transform,
    const Rect& bounds) {
  if (bounds.IsSquare()) {
    return FilledCircle(view_transform, bounds.GetCenter(),
                        bounds.GetWidth() * 0.5f);
  }
  auto max_radius = bounds.GetSize().MaxDimension();
  auto divisions = ComputeQuadrantDivisions(
      view_transform.GetMaxBasisLengthXY() * max_radius);
  auto center = bounds.GetCenter();
  return EllipticalVertexGenerator(Tessellator::GenerateFilledEllipse,
                                   GetTrigsForDivisions(divisions),
                                   PrimitiveType::kTriangleStrip, 4,
                                   {
                                       .reference_centers = {center, center},
                                       .radii = bounds.GetSize() * 0.5f,
                                       .half_width = -1.0f,
                                   });
}

EllipticalVertexGenerator Tessellator::FilledRoundRect(
    const Matrix& view_transform,
    const Rect& bounds,
    const Size& radii) {
  if (radii.width * 2 < bounds.GetWidth() ||
      radii.height * 2 < bounds.GetHeight()) {
    auto max_radius = radii.MaxDimension();
    auto divisions = ComputeQuadrantDivisions(
        view_transform.GetMaxBasisLengthXY() * max_radius);
    auto upper_left = bounds.GetLeftTop() + radii;
    auto lower_right = bounds.GetRightBottom() - radii;
    return EllipticalVertexGenerator(Tessellator::GenerateFilledRoundRect,
                                     GetTrigsForDivisions(divisions),
                                     PrimitiveType::kTriangleStrip, 4,
                                     {
                                         .reference_centers =
                                             {
                                                 upper_left,
                                                 lower_right,
                                             },
                                         .radii = radii,
                                         .half_width = -1.0f,
                                     });
  } else {
    return FilledEllipse(view_transform, bounds);
  }
}

void Tessellator::GenerateFilledCircle(
    const Trigs& trigs,
    const EllipticalVertexGenerator::Data& data,
    const TessellatedVertexProc& proc) {
  auto center = data.reference_centers[0];
  auto radius = data.radii.width;

  FML_DCHECK(center == data.reference_centers[1]);
  FML_DCHECK(radius == data.radii.height);
  FML_DCHECK(data.half_width < 0);

  // Quadrant 1 connecting with Quadrant 4:
  for (auto& trig : trigs) {
    auto offset = trig * radius;
    proc({center.x - offset.x, center.y + offset.y});
    proc({center.x - offset.x, center.y - offset.y});
  }

  // The second half of the circle should be iterated in reverse, but
  // we can instead iterate forward and swap the x/y values of the
  // offset as the angles should be symmetric and thus should generate
  // symmetrically reversed trig vectors.
  // Quadrant 2 connecting with Quadrant 3:
  for (auto& trig : trigs) {
    auto offset = trig * radius;
    proc({center.x + offset.y, center.y + offset.x});
    proc({center.x + offset.y, center.y - offset.x});
  }
}

void Tessellator::GenerateStrokedCircle(
    const Trigs& trigs,
    const EllipticalVertexGenerator::Data& data,
    const TessellatedVertexProc& proc) {
  auto center = data.reference_centers[0];

  FML_DCHECK(center == data.reference_centers[1]);
  FML_DCHECK(data.radii.IsSquare());
  FML_DCHECK(data.half_width > 0 && data.half_width < data.radii.width);

  auto outer_radius = data.radii.width + data.half_width;
  auto inner_radius = data.radii.width - data.half_width;

  // Zig-zag back and forth between points on the outer circle and the
  // inner circle. Both circles are evaluated at the same number of
  // quadrant divisions so the points for a given division should match
  // 1 for 1 other than their applied radius.

  // Quadrant 1:
  for (auto& trig : trigs) {
    auto outer = trig * outer_radius;
    auto inner = trig * inner_radius;
    proc({center.x - outer.x, center.y - outer.y});
    proc({center.x - inner.x, center.y - inner.y});
  }

  // The even quadrants of the circle should be iterated in reverse, but
  // we can instead iterate forward and swap the x/y values of the
  // offset as the angles should be symmetric and thus should generate
  // symmetrically reversed trig vectors.
  // Quadrant 2:
  for (auto& trig : trigs) {
    auto outer = trig * outer_radius;
    auto inner = trig * inner_radius;
    proc({center.x + outer.y, center.y - outer.x});
    proc({center.x + inner.y, center.y - inner.x});
  }

  // Quadrant 3:
  for (auto& trig : trigs) {
    auto outer = trig * outer_radius;
    auto inner = trig * inner_radius;
    proc({center.x + outer.x, center.y + outer.y});
    proc({center.x + inner.x, center.y + inner.y});
  }

  // Quadrant 4:
  for (auto& trig : trigs) {
    auto outer = trig * outer_radius;
    auto inner = trig * inner_radius;
    proc({center.x - outer.y, center.y + outer.x});
    proc({center.x - inner.y, center.y + inner.x});
  }
}

void Tessellator::GenerateFilledArcFan(const Trigs& trigs,
                                       const Arc::Iteration& iteration,
                                       const Rect& oval_bounds,
                                       bool use_center,
                                       const TessellatedVertexProc& proc) {
  Point center = oval_bounds.GetCenter();
  Size radii = oval_bounds.GetSize() * 0.5f;

  if (use_center) {
    proc(center);
  }
  proc(center + iteration.start * radii);
  for (size_t i = 0; i < iteration.quadrant_count; i++) {
    auto quadrant = iteration.quadrants[i];
    for (size_t j = quadrant.start_index; j < quadrant.end_index; j++) {
      proc(center + trigs[j] * quadrant.axis * radii);
    }
  }
  proc(center + iteration.end * radii);
}

void Tessellator::GenerateFilledArcStrip(const Trigs& trigs,
                                         const Arc::Iteration& iteration,
                                         const Rect& oval_bounds,
                                         bool use_center,
                                         const TessellatedVertexProc& proc) {
  Point center = oval_bounds.GetCenter();
  Size radii = oval_bounds.GetSize() * 0.5f;

  Point origin;
  if (use_center) {
    origin = center;
  } else {
    Point midpoint = (iteration.start + iteration.end) * 0.5f;
    origin = center + midpoint * radii;
  }

  proc(origin);
  proc(center + iteration.start * radii);
  bool insert_origin = false;
  for (size_t i = 0; i < iteration.quadrant_count; i++) {
    auto quadrant = iteration.quadrants[i];
    for (size_t j = quadrant.start_index; j < quadrant.end_index; j++) {
      if (insert_origin) {
        proc(origin);
      }
      insert_origin = !insert_origin;
      proc(center + trigs[j] * quadrant.axis * radii);
    }
  }
  if (insert_origin) {
    proc(origin);
  }
  proc(center + iteration.end * radii);
}

void Tessellator::GenerateStrokedArc(const Trigs& trigs,
                                     const Arc::Iteration& iteration,
                                     const Rect& oval_bounds,
                                     Scalar half_width,
                                     Cap cap,
                                     const TessellatedVertexProc& proc) {
  Point center = oval_bounds.GetCenter();
  Size base_radii = oval_bounds.GetSize() * 0.5f;
  Size inner_radii = base_radii - Size(half_width, half_width);
  Size outer_radii = base_radii + Size(half_width, half_width);

  FML_DCHECK(cap != Cap::kRound);
  if (cap == Cap::kSquare) {
    Vector2 offset =
        Vector2{iteration.start.y, -iteration.start.x} * half_width;
    proc(center + iteration.start * inner_radii + offset);
    proc(center + iteration.start * outer_radii + offset);
  }
  proc(center + iteration.start * inner_radii);
  proc(center + iteration.start * outer_radii);
  for (size_t i = 0; i < iteration.quadrant_count; i++) {
    auto quadrant = iteration.quadrants[i];
    for (size_t j = quadrant.start_index; j < quadrant.end_index; j++) {
      proc(center + trigs[j] * quadrant.axis * inner_radii);
      proc(center + trigs[j] * quadrant.axis * outer_radii);
    }
  }
  proc(center + iteration.end * inner_radii);
  proc(center + iteration.end * outer_radii);
  if (cap == Cap::kSquare) {
    Vector2 offset = Vector2{-iteration.end.y, iteration.end.x} * half_width;
    proc(center + iteration.end * inner_radii + offset);
    proc(center + iteration.end * outer_radii + offset);
  }
}

void Tessellator::GenerateRoundCapLine(
    const Trigs& trigs,
    const EllipticalVertexGenerator::Data& data,
    const TessellatedVertexProc& proc) {
  auto p0 = data.reference_centers[0];
  auto p1 = data.reference_centers[1];
  auto radius = data.radii.width;

  FML_DCHECK(radius == data.radii.height);
  FML_DCHECK(data.half_width < 0);

  auto along = p1 - p0;
  along *= radius / along.GetLength();
  auto across = Point(-along.y, along.x);

  for (auto& trig : trigs) {
    auto relative_along = along * trig.cos;
    auto relative_across = across * trig.sin;
    proc(p0 - relative_along + relative_across);
    proc(p0 - relative_along - relative_across);
  }

  // The second half of the round caps should be iterated in reverse, but
  // we can instead iterate forward and swap the sin/cos values as they
  // should be symmetric.
  for (auto& trig : trigs) {
    auto relative_along = along * trig.sin;
    auto relative_across = across * trig.cos;
    proc(p1 + relative_along + relative_across);
    proc(p1 + relative_along - relative_across);
  }
}

void Tessellator::GenerateFilledEllipse(
    const Trigs& trigs,
    const EllipticalVertexGenerator::Data& data,
    const TessellatedVertexProc& proc) {
  auto center = data.reference_centers[0];
  auto radii = data.radii;

  FML_DCHECK(center == data.reference_centers[1]);
  FML_DCHECK(data.half_width < 0);

  // Quadrant 1 connecting with Quadrant 4:
  for (auto& trig : trigs) {
    auto offset = trig * radii;
    proc({center.x - offset.x, center.y + offset.y});
    proc({center.x - offset.x, center.y - offset.y});
  }

  // The second half of the circle should be iterated in reverse, but
  // we can instead iterate forward and swap the x/y values of the
  // offset as the angles should be symmetric and thus should generate
  // symmetrically reversed trig vectors.
  // Quadrant 2 connecting with Quadrant 2:
  for (auto& trig : trigs) {
    auto offset = Point(trig.sin * radii.width, trig.cos * radii.height);
    proc({center.x + offset.x, center.y + offset.y});
    proc({center.x + offset.x, center.y - offset.y});
  }
}

void Tessellator::GenerateFilledRoundRect(
    const Trigs& trigs,
    const EllipticalVertexGenerator::Data& data,
    const TessellatedVertexProc& proc) {
  Scalar left = data.reference_centers[0].x;
  Scalar top = data.reference_centers[0].y;
  Scalar right = data.reference_centers[1].x;
  Scalar bottom = data.reference_centers[1].y;
  auto radii = data.radii;

  FML_DCHECK(data.half_width < 0);

  // Quadrant 1 connecting with Quadrant 4:
  for (auto& trig : trigs) {
    auto offset = trig * radii;
    proc({left - offset.x, bottom + offset.y});
    proc({left - offset.x, top - offset.y});
  }

  // The second half of the round rect should be iterated in reverse, but
  // we can instead iterate forward and swap the x/y values of the
  // offset as the angles should be symmetric and thus should generate
  // symmetrically reversed trig vectors.
  // Quadrant 2 connecting with Quadrant 2:
  for (auto& trig : trigs) {
    auto offset = Point(trig.sin * radii.width, trig.cos * radii.height);
    proc({right + offset.x, bottom + offset.y});
    proc({right + offset.x, top - offset.y});
  }
}

}  // namespace impeller
