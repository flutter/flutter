// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_SHADOW_PATH_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_SHADOW_PATH_GEOMETRY_H_

#include "flutter/impeller/entity/geometry/geometry.h"
#include "flutter/impeller/geometry/path_source.h"
#include "flutter/impeller/tessellator/tessellator.h"

namespace impeller {

/// A class to hold a vertex mesh for rendering shadows. The vertices are
/// each associated with a gaussian coefficent that represents where that
/// vertex lives in the shadow from a value of 1.0 (at the edge of or fully
/// in the darkest part of the umbra) to 0.0 at the edge of or fully outside
/// the penumbra).
///
/// The vertices are also associated with a vector of indices that assemble
/// them into a mesh that covers the full umbra and penumbra of the shape.
///
/// The mesh is usually intended to be rendered at device (pixel) resolution.
class ShadowVertices {
 public:
  static const std::shared_ptr<ShadowVertices> kEmpty;

  static std::shared_ptr<ShadowVertices> Make(std::vector<Point> vertices,
                                              std::vector<uint16_t> indices,
                                              std::vector<Scalar> gaussians) {
    return std::make_shared<ShadowVertices>(
        std::move(vertices), std::move(indices), std::move(gaussians));
  }

  constexpr ShadowVertices() {}

  constexpr ShadowVertices(std::vector<Point> vertices,
                           std::vector<uint16_t> indices,
                           std::vector<Scalar> gaussians)
      : vertices_(std::move(vertices)),
        indices_(std::move(indices)),
        gaussians_(std::move(gaussians)) {}

  /// The count of the unique (duplicates minimized) vertices in the mesh.
  /// This number is also the count of gaussian coefficients in the mesh
  /// since the two are assigned 1:1.
  size_t GetVertexCount() const { return vertices_.size(); }

  /// The count of the indices that define the mesh.
  size_t GetIndexCount() const { return indices_.size(); }

  const std::vector<Point>& GetVertices() const { return vertices_; }
  const std::vector<uint16_t>& GetIndices() const { return indices_; }
  const std::vector<Scalar>& GetGaussians() const { return gaussians_; }

  /// True if and only if there was no shadow for the shape and therefore
  /// no mesh to generate.
  bool IsEmpty() const { return vertices_.empty(); }

  std::optional<Rect> GetBounds() const;

  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const;

 private:
  const std::vector<Point> vertices_;
  const std::vector<uint16_t> indices_;
  const std::vector<Scalar> gaussians_;
};

/// A class to compute and return the |ShadowVertices| for a path source
/// viewed under a given transform. The |occluder_height| is measured in
/// device pixels. The geometry of the |PathSource| is transformed by the
/// indicated matrix to produce a device space set of vertices, and the
/// shadow mesh is inset and outset by the indicated |occluder_height|
/// without any adjustment for the matrix. The results are un-transformed
/// and returned back iin the |ShadowVertices| in the original coordinate
/// system.
class ShadowPathGeometry {
 public:
  ShadowPathGeometry(Tessellator& tessellator,
                     const Matrix& matrix,
                     const PathSource& source,
                     Scalar occluder_height);

  bool CanRender() const;

  /// Returns true if this shadow has no effect, is not visible.
  bool IsEmpty() const;

  /// Returns a reference to the generated vertices, or null if the algorithm
  /// failed to produce a mesh.
  const std::shared_ptr<ShadowVertices>& GetShadowVertices() const;

  /// Takes (returns the only copy of via std::move) the shadow vertices
  /// or null if the algorithm failed to produce a mesh.
  const std::shared_ptr<ShadowVertices> TakeShadowVertices();

  /// Constructs a shadow mesh for the given |PathSource| at the given
  /// |matrix| and with the indicated device-space |occluder_height|.
  /// The tessellator is used to get a cached set of |Trigs| for the
  /// radii associated with the mesh around various corners in the path.
  static std::shared_ptr<ShadowVertices> MakeAmbientShadowVertices(
      Tessellator& tessellator,
      const PathSource& source,
      Scalar occluder_height,
      const Matrix& matrix);

 private:
  std::shared_ptr<ShadowVertices> shadow_vertices_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_SHADOW_PATH_GEOMETRY_H_
