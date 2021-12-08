// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/tessellator.h"

#include "third_party/libtess2/Include/tesselator.h"

namespace impeller {

Tessellator::Tessellator(FillType type) : fill_type_(type) {}

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

static void DestroyTessellator(TESStesselator* tessellator) {
  if (tessellator != nullptr) {
    ::tessDeleteTess(tessellator);
  }
}

bool Tessellator::Tessellate(const std::vector<Point>& contours,
                             VertexCallback callback) const {
  if (!callback) {
    return false;
  }

  using CTessellator =
      std::unique_ptr<TESStesselator, decltype(&DestroyTessellator)>;

  CTessellator tessellator(
      ::tessNewTess(nullptr /* the default ::malloc based allocator */),
      DestroyTessellator);

  if (!tessellator) {
    return false;
  }

  constexpr int kVertexSize = 2;
  constexpr int kPolygonSize = 3;

  //----------------------------------------------------------------------------
  /// Feed contour information to the tessellator.
  ///
  static_assert(sizeof(Point) == 2 * sizeof(float));
  ::tessAddContour(tessellator.get(),  // the C tessellator
                   kVertexSize,        //
                   contours.data(),    //
                   sizeof(Point),      //
                   contours.size()     //
  );

  //----------------------------------------------------------------------------
  /// Let's tessellate.
  ///
  auto result = ::tessTesselate(tessellator.get(),              // tessellator
                                ToTessWindingRule(fill_type_),  // winding
                                TESS_POLYGONS,                  // element type
                                kPolygonSize,                   // polygon size
                                kVertexSize,                    // vertex size
                                nullptr  // normal (null is automatic)
  );

  if (result != 1) {
    return false;
  }

  // TODO(csg): This copy can be elided entirely for the current use case.
  std::vector<Point> points;
  std::vector<uint32_t> indices;

  int vertexItemCount = tessGetVertexCount(tessellator.get()) * kVertexSize;
  auto vertices = tessGetVertices(tessellator.get());
  for (int i = 0; i < vertexItemCount; i += 2) {
    points.emplace_back(vertices[i], vertices[i + 1]);
  }

  int elementItemCount = tessGetElementCount(tessellator.get()) * kPolygonSize;
  auto elements = tessGetElements(tessellator.get());
  for (int i = 0; i < elementItemCount; i++) {
    indices.emplace_back(elements[i]);
  }

  for (auto index : indices) {
    auto vtx = points[index];
    callback(vtx);
  }

  return true;
}

WindingOrder Tessellator::GetFrontFaceWinding() const {
  return WindingOrder::kClockwise;
}

}  // namespace impeller
