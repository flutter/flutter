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

Tessellator::Tessellator() : c_tessellator_(nullptr, &DestroyTessellator) {
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
    case FillType::kPositive:
      return TESS_WINDING_POSITIVE;
    case FillType::kNegative:
      return TESS_WINDING_NEGATIVE;
    case FillType::kAbsGeqTwo:
      return TESS_WINDING_ABS_GEQ_TWO;
  }
  return TESS_WINDING_ODD;
}

Tessellator::Result Tessellator::Tessellate(
    FillType fill_type,
    const Path::Polyline& polyline,
    const BuilderCallback& callback) const {
  if (!callback) {
    return Result::kInputError;
  }

  if (polyline.points.empty()) {
    return Result::kInputError;
  }

  auto tessellator = c_tessellator_.get();
  if (!tessellator) {
    return Result::kTessellationError;
  }

  constexpr int kVertexSize = 2;
  constexpr int kPolygonSize = 3;

  // If we have a larger polyline and the fill type is non-zero, we can split
  // the tessellation up per contour. Since in general the complexity is at
  // least nlog(n), this speeds up the processes substantially.
  if (polyline.contours.size() > kMultiContourThreshold &&
      fill_type == FillType::kNonZero) {
    std::vector<Point> points;
    std::vector<float> data;

    //----------------------------------------------------------------------------
    /// Feed contour information to the tessellator.
    ///
    size_t total = 0u;
    static_assert(sizeof(Point) == 2 * sizeof(float));
    for (size_t contour_i = 0; contour_i < polyline.contours.size();
         contour_i++) {
      size_t start_point_index, end_point_index;
      std::tie(start_point_index, end_point_index) =
          polyline.GetContourPointBounds(contour_i);

      ::tessAddContour(tessellator,  // the C tessellator
                       kVertexSize,  //
                       polyline.points.data() + start_point_index,  //
                       sizeof(Point),                               //
                       end_point_index - start_point_index          //
      );

      //----------------------------------------------------------------------------
      /// Let's tessellate.
      ///
      auto result = ::tessTesselate(tessellator,  // tessellator
                                    ToTessWindingRule(fill_type),  // winding
                                    TESS_POLYGONS,  // element type
                                    kPolygonSize,   // polygon size
                                    kVertexSize,    // vertex size
                                    nullptr  // normal (null is automatic)
      );

      if (result != 1) {
        return Result::kTessellationError;
      }

      int vertex_item_count = tessGetVertexCount(tessellator) * kVertexSize;
      auto vertices = tessGetVertices(tessellator);
      for (int i = 0; i < vertex_item_count; i += 2) {
        points.emplace_back(vertices[i], vertices[i + 1]);
      }

      int element_item_count = tessGetElementCount(tessellator) * kPolygonSize;
      auto elements = tessGetElements(tessellator);
      total += element_item_count;
      for (int i = 0; i < element_item_count; i++) {
        data.emplace_back(points[elements[i]].x);
        data.emplace_back(points[elements[i]].y);
      }
      points.clear();
    }
    if (!callback(data.data(), total, nullptr, 0u)) {
      return Result::kInputError;
    }
  } else {
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
                       polyline.points.data() + start_point_index,  //
                       sizeof(Point),                               //
                       end_point_index - start_point_index          //
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
      for (int i = 0; i < vertex_item_count; i += 2) {
        points.emplace_back(vertices[i], vertices[i + 1]);
      }

      int element_item_count = tessGetElementCount(tessellator) * kPolygonSize;
      auto elements = tessGetElements(tessellator);
      for (int i = 0; i < element_item_count; i++) {
        data.emplace_back(points[elements[i]].x);
        data.emplace_back(points[elements[i]].y);
      }
      if (!callback(data.data(), element_item_count, nullptr, 0u)) {
        return Result::kInputError;
      }
    }
  }

  return Result::kSuccess;
}

void DestroyTessellator(TESStesselator* tessellator) {
  if (tessellator != nullptr) {
    ::tessDeleteTess(tessellator);
  }
}

}  // namespace impeller
