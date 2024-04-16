// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "tessellator.h"

#include <memory>
#include <vector>

#include "third_party/libtess2/Include/tesselator.h"

namespace impeller {

void DestroyTessellator(TESStesselator* tessellator) {
  if (tessellator != nullptr) {
    ::tessDeleteTess(tessellator);
  }
}

using CTessellator =
    std::unique_ptr<TESStesselator, decltype(&DestroyTessellator)>;

static int ToTessWindingRule(FillType fill_type) {
  switch (fill_type) {
    case FillType::kOdd:
      return TESS_WINDING_ODD;
    case FillType::kNonZero:
      return TESS_WINDING_NONZERO;
  }
  return TESS_WINDING_ODD;
}

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

class LibtessTessellator {
 public:
  LibtessTessellator() : c_tessellator_(nullptr, &DestroyTessellator) {
    TESSalloc alloc = kAlloc;
    {
      // libTess2 copies the TESSalloc despite the non-const argument.
      CTessellator tessellator(::tessNewTess(&alloc), &DestroyTessellator);
      c_tessellator_ = std::move(tessellator);
    }
  }

  ~LibtessTessellator() {}

  enum class Result {
    kSuccess,
    kInputError,
    kTessellationError,
  };

  /// @brief A callback that returns the results of the tessellation.
  ///
  ///        The index buffer may not be populated, in which case [indices] will
  ///        be nullptr and indices_count will be 0.
  using BuilderCallback = std::function<bool(const float* vertices,
                                             size_t vertices_count,
                                             const uint16_t* indices,
                                             size_t indices_count)>;

  //----------------------------------------------------------------------------
  /// @brief      Generates filled triangles from the path. A callback is
  ///             invoked once for the entire tessellation.
  ///
  /// @param[in]  path  The path to tessellate.
  /// @param[in]  tolerance  The tolerance value for conversion of the path to
  ///                        a polyline. This value is often derived from the
  ///                        Matrix::GetMaxBasisLength of the CTM applied to the
  ///                        path for rendering.
  /// @param[in]  callback  The callback, return false to indicate failure.
  ///
  /// @return The result status of the tessellation.
  ///
  Result Tessellate(const Path& path,
                    Scalar tolerance,
                    const BuilderCallback& callback) {
    if (!callback) {
      return Result::kInputError;
    }

    std::unique_ptr<std::vector<Point>> buffer =
        std::make_unique<std::vector<Point>>();
    auto polyline = path.CreatePolyline(tolerance, std::move(buffer));

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

  CTessellator c_tessellator_;
};

PathBuilder* CreatePathBuilder() {
  return new PathBuilder();
}

void DestroyPathBuilder(PathBuilder* builder) {
  delete builder;
}

void MoveTo(PathBuilder* builder, Scalar x, Scalar y) {
  builder->MoveTo(Point(x, y));
}

void LineTo(PathBuilder* builder, Scalar x, Scalar y) {
  builder->LineTo(Point(x, y));
}

void CubicTo(PathBuilder* builder,
             Scalar x1,
             Scalar y1,
             Scalar x2,
             Scalar y2,
             Scalar x3,
             Scalar y3) {
  builder->CubicCurveTo(Point(x1, y1), Point(x2, y2), Point(x3, y3));
}

void Close(PathBuilder* builder) {
  builder->Close();
}

struct Vertices* Tessellate(PathBuilder* builder,
                            int fill_type,
                            Scalar tolerance) {
  auto path = builder->CopyPath(static_cast<FillType>(fill_type));
  std::vector<float> points;
  if (LibtessTessellator{}.Tessellate(
          path, tolerance,
          [&points](const float* vertices, size_t vertices_count,
                    const uint16_t* indices, size_t indices_count) {
            // Results are expected to be re-duplicated.
            std::vector<Point> raw_points;
            for (auto i = 0u; i < vertices_count * 2; i += 2) {
              raw_points.emplace_back(Point{vertices[i], vertices[i + 1]});
            }
            for (auto i = 0u; i < indices_count; i++) {
              auto point = raw_points[indices[i]];
              points.push_back(point.x);
              points.push_back(point.y);
            }
            return true;
          }) != LibtessTessellator::Result::kSuccess) {
    return nullptr;
  }

  Vertices* vertices = new Vertices();
  vertices->points = new float[points.size()];
  if (!vertices->points) {
    return nullptr;
  }
  vertices->length = points.size();
  std::copy(points.begin(), points.end(), vertices->points);
  return vertices;
}

void DestroyVertices(Vertices* vertices) {
  delete vertices->points;
  delete vertices;
}

}  // namespace impeller
