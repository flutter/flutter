// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_SHADOW_PATH_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_SHADOW_PATH_GEOMETRY_H_

#ifdef NDEBUG
#define EXPORT_SKIA_SHADOW false
#else  // NDEBUG
#define EXPORT_SKIA_SHADOW true
#endif

#if EXPORT_SKIA_SHADOW
#include "flutter/display_list/geometry/dl_path.h"
#endif

#include "flutter/impeller/entity/geometry/geometry.h"
#include "flutter/impeller/geometry/path_source.h"
#include "flutter/impeller/tessellator/tessellator.h"

namespace impeller {

class ShadowVertices {
 public:
  static std::shared_ptr<ShadowVertices> Make(std::vector<Point> vertices,
                                              std::vector<uint16_t> indices,
                                              std::vector<Scalar> gaussians) {
    return std::make_shared<ShadowVertices>(
        std::move(vertices), std::move(indices), std::move(gaussians));
  }

  constexpr ShadowVertices(std::vector<Point> vertices,
                           std::vector<uint16_t> indices,
                           std::vector<Scalar> gaussians)
      : vertices_(std::move(vertices)),
        indices_(std::move(indices)),
        gaussians_(std::move(gaussians)) {}

  size_t GetVertexCount() const { return vertices_.size(); }
  size_t GetIndexCount() const { return indices_.size(); }

  const std::vector<Point>& GetVertices() const { return vertices_; }
  const std::vector<uint16_t>& GetIndices() const { return indices_; }
  const std::vector<Scalar>& GetGaussians() const { return gaussians_; }

  bool IsEmpty() const { return vertices_.empty(); }
  std::optional<Rect> GetBounds() const;

 private:
  const std::vector<Point> vertices_;
  const std::vector<uint16_t> indices_;
  const std::vector<Scalar> gaussians_;
};

class ShadowPathGeometry : public Geometry {
 public:
  ShadowPathGeometry(Tessellator& tessellator,
                     const Matrix& matrix,
                     const PathSource& source,
                     Scalar occluder_height);

  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const override;

  bool CanRender() const;

  /// Returns true if this shadow has no effect, is not visible.
  bool IsEmpty() const;

  const std::shared_ptr<ShadowVertices>& GetShadowVertices() const;

  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

  static std::shared_ptr<ShadowVertices> MakeAmbientShadowVertices(
      Tessellator& tessellator,
      const PathSource& source,
      Scalar occluder_height,
      const Matrix& matrix);

#if EXPORT_SKIA_SHADOW
  static std::shared_ptr<ShadowVertices> MakeAmbientShadowVerticesSkia(
      const flutter::DlPath& source,
      Scalar occluder_height,
      const Matrix& matrix);
#endif

 private:
  const std::shared_ptr<ShadowVertices> shadow_vertices_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_SHADOW_PATH_GEOMETRY_H_
