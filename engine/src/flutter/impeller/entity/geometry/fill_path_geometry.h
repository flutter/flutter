// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_FILL_PATH_GEOMETRY_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_FILL_PATH_GEOMETRY_H_

#include <optional>

#include "flutter/display_list/geometry/dl_path.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/geometry/rect.h"

namespace impeller {

/// @brief A geometry that is created from a filled path object.
class FillPathGeometry final : public Geometry {
 public:
  explicit FillPathGeometry(const flutter::DlPath& path,
                            std::optional<Rect> inner_rect = std::nullopt);

  ~FillPathGeometry() override;

  // |Geometry|
  bool CoversArea(const Matrix& transform, const Rect& rect) const override;

 private:
  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const override;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

  // |Geometry|
  GeometryResult::Mode GetResultMode() const override;

  flutter::DlPath path_;
  std::optional<Rect> inner_rect_;

  FillPathGeometry(const FillPathGeometry&) = delete;

  FillPathGeometry& operator=(const FillPathGeometry&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_FILL_PATH_GEOMETRY_H_
