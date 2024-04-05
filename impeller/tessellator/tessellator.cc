// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/tessellator/tessellator.h"

#include "third_party/libtess2/Include/tesselator.h"

namespace impeller {

static void* HeapAlloc(void* userData, unsigned int size) {
  return malloc(size);
}

static void* HeapRealloc(void* userData, void* ptr, unsigned int size) {
  return realloc(ptr, size);
}

static void HeapFree(void* userData, void* ptr) {
  free(ptr);
}

// Note: these units are "number of entities" for bucket size and not in KB.
static const TESSalloc kAlloc = {
    HeapAlloc, HeapRealloc, HeapFree, 0, /* =userData */
    16,                                  /* =meshEdgeBucketSize */
    16,                                  /* =meshVertexBucketSize */
    16,                                  /* =meshFaceBucketSize */
    16,                                  /* =dictNodeBucketSize */
    16,                                  /* =regionBucketSize */
    0                                    /* =extraVertices */
};

Tessellator::Tessellator()
    : point_buffer_(std::make_unique<std::vector<Point>>()),
      c_tessellator_(nullptr, &DestroyTessellator) {
  point_buffer_->reserve(2048);
  TESSalloc alloc = kAlloc;
  {
    // libTess2 copies the TESSalloc despite the non-const argument.
    CTessellator tessellator(::tessNewTess(&alloc), &DestroyTessellator);
    c_tessellator_ = std::move(tessellator);
  }
}

Tessellator::~Tessellator() = default;

static int ToTessWindingRule(FillType fill_type) {
  switch (fill_type) {
    case FillType::kOdd:
      return TESS_WINDING_ODD;
    case FillType::kNonZero:
      return TESS_WINDING_NONZERO;
  }
  return TESS_WINDING_ODD;
}

Tessellator::Result Tessellator::Tessellate(const Path& path,
                                            Scalar tolerance,
                                            const BuilderCallback& callback) {
  if (!callback) {
    return Result::kInputError;
  }

  point_buffer_->clear();
  auto polyline =
      path.CreatePolyline(tolerance, std::move(point_buffer_),
                          [this](Path::Polyline::PointBufferPtr point_buffer) {
                            point_buffer_ = std::move(point_buffer);
                          });

  auto fill_type = path.GetFillType();

  if (polyline.points->empty()) {
    return Result::kInputError;
  }

  auto tessellator = c_tessellator_.get();
  if (!tessellator) {
    return Result::kTessellationError;
  }

  constexpr int kVertexSize = 2;
  constexpr int kPolygonSize = 3;

  //----------------------------------------------------------------------------
  /// Feed contour information to the tessellator.
  ///
  static_assert(sizeof(Point) == 2 * sizeof(float));
  for (size_t contour_i = 0; contour_i < polyline.contours.size();
       contour_i++) {
    size_t start_point_index, end_point_index;
    std::tie(start_point_index, end_point_index) =
        polyline.GetContourPointBounds(contour_i);

    ::tessAddContour(tessellator,  // the C tessellator
                     kVertexSize,  //
                     polyline.points->data() + start_point_index,  //
                     sizeof(Point),                                //
                     end_point_index - start_point_index           //
    );
  }

  //----------------------------------------------------------------------------
  /// Let's tessellate.
  ///
  auto result = ::tessTesselate(tessellator,                   // tessellator
                                ToTessWindingRule(fill_type),  // winding
                                TESS_POLYGONS,                 // element type
                                kPolygonSize,                  // polygon size
                                kVertexSize,                   // vertex size
                                nullptr  // normal (null is automatic)
  );

  if (result != 1) {
    return Result::kTessellationError;
  }

  int element_item_count = tessGetElementCount(tessellator) * kPolygonSize;

  // We default to using a 16bit index buffer, but in cases where we generate
  // more tessellated data than this can contain we need to fall back to
  // dropping the index buffer entirely. Instead code could instead switch to
  // a uint32 index buffer, but this is done for simplicity with the other
  // fast path above.
  if (element_item_count < USHRT_MAX) {
    int vertex_item_count = tessGetVertexCount(tessellator);
    auto vertices = tessGetVertices(tessellator);
    auto elements = tessGetElements(tessellator);

    // libtess uses an int index internally due to usage of -1 as a sentinel
    // value.
    std::vector<uint16_t> indices(element_item_count);
    for (int i = 0; i < element_item_count; i++) {
      indices[i] = static_cast<uint16_t>(elements[i]);
    }
    if (!callback(vertices, vertex_item_count, indices.data(),
                  element_item_count)) {
      return Result::kInputError;
    }
  } else {
    std::vector<Point> points;
    std::vector<float> data;

    int vertex_item_count = tessGetVertexCount(tessellator) * kVertexSize;
    auto vertices = tessGetVertices(tessellator);
    points.reserve(vertex_item_count);
    for (int i = 0; i < vertex_item_count; i += 2) {
      points.emplace_back(vertices[i], vertices[i + 1]);
    }

    int element_item_count = tessGetElementCount(tessellator) * kPolygonSize;
    auto elements = tessGetElements(tessellator);
    data.reserve(element_item_count);
    for (int i = 0; i < element_item_count; i++) {
      data.emplace_back(points[elements[i]].x);
      data.emplace_back(points[elements[i]].y);
    }
    if (!callback(data.data(), element_item_count, nullptr, 0u)) {
      return Result::kInputError;
    }
  }

  return Result::kSuccess;
}

Path::Polyline Tessellator::CreateTempPolyline(const Path& path,
                                               Scalar tolerance) {
  FML_DCHECK(point_buffer_);
  point_buffer_->clear();
  auto polyline =
      path.CreatePolyline(tolerance, std::move(point_buffer_),
                          [this](Path::Polyline::PointBufferPtr point_buffer) {
                            point_buffer_ = std::move(point_buffer);
                          });
  return polyline;
}

std::vector<Point> Tessellator::TessellateConvex(const Path& path,
                                                 Scalar tolerance) {
  FML_DCHECK(point_buffer_);

  std::vector<Point> output;
  point_buffer_->clear();
  auto polyline =
      path.CreatePolyline(tolerance, std::move(point_buffer_),
                          [this](Path::Polyline::PointBufferPtr point_buffer) {
                            point_buffer_ = std::move(point_buffer);
                          });
  if (polyline.points->size() == 0) {
    return output;
  }

  output.reserve(polyline.points->size() +
                 (4 * (polyline.contours.size() - 1)));
  bool previous_contour_odd_points = false;
  for (auto j = 0u; j < polyline.contours.size(); j++) {
    auto [start, end] = polyline.GetContourPointBounds(j);
    auto first_point = polyline.GetPoint(start);

    // Some polygons will not self close and an additional triangle
    // must be inserted, others will self close and we need to avoid
    // inserting an extra triangle.
    if (polyline.GetPoint(end - 1) == first_point) {
      end--;
    }

    if (j > 0) {
      // Triangle strip break.
      output.emplace_back(output.back());
      output.emplace_back(first_point);
      output.emplace_back(first_point);

      // If the contour has an odd number of points, insert an extra point when
      // bridging to the next contour to preserve the correct triangle winding
      // order.
      if (previous_contour_odd_points) {
        output.emplace_back(first_point);
      }
    } else {
      output.emplace_back(first_point);
    }

    size_t a = start + 1;
    size_t b = end - 1;
    while (a < b) {
      output.emplace_back(polyline.GetPoint(a));
      output.emplace_back(polyline.GetPoint(b));
      a++;
      b--;
    }
    if (a == b) {
      previous_contour_odd_points = false;
      output.emplace_back(polyline.GetPoint(a));
    } else {
      previous_contour_odd_points = true;
    }
  }
  return output;
}

void DestroyTessellator(TESStesselator* tessellator) {
  if (tessellator != nullptr) {
    ::tessDeleteTess(tessellator);
  }
}

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

static size_t ComputeQuadrantDivisions(Scalar pixel_radius) {
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
  double k = Tessellator::kCircleTolerance / pixel_radius;
  return ceil(kPiOver4 / std::acos(1 - k));
}

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
  auto divisions =
      ComputeQuadrantDivisions(view_transform.GetMaxBasisLength() * radius);
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
        view_transform.GetMaxBasisLength() * radius + half_width);
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

EllipticalVertexGenerator Tessellator::RoundCapLine(
    const Matrix& view_transform,
    const Point& p0,
    const Point& p1,
    Scalar radius) {
  auto along = p1 - p0;
  auto length = along.GetLength();
  if (length > kEhCloseEnough) {
    auto divisions =
        ComputeQuadrantDivisions(view_transform.GetMaxBasisLength() * radius);
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
  auto divisions =
      ComputeQuadrantDivisions(view_transform.GetMaxBasisLength() * max_radius);
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
        view_transform.GetMaxBasisLength() * max_radius);
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
  // Quadrant 2 connecting with Quadrant 2:
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
