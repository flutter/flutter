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
class FillPathSourceGeometry : public Geometry {
 public:
  ~FillPathSourceGeometry() override;

  // |Geometry|
  bool CoversArea(const Matrix& transform, const Rect& rect) const override;

 protected:
  explicit FillPathSourceGeometry(std::optional<Rect> inner_rect);

  virtual const PathSource& GetSource() const = 0;

 private:
  // |Geometry|
  GeometryResult GetPositionBuffer(const ContentContext& renderer,
                                   const Entity& entity,
                                   RenderPass& pass) const override;

  // |Geometry|
  std::optional<Rect> GetCoverage(const Matrix& transform) const override;

  // |Geometry|
  GeometryResult::Mode GetResultMode() const override;

  std::optional<Rect> inner_rect_;

  FillPathSourceGeometry(const FillPathSourceGeometry&) = delete;

  FillPathSourceGeometry& operator=(const FillPathSourceGeometry&) = delete;
};

class FillPathGeometry final : public FillPathSourceGeometry {
 public:
  explicit FillPathGeometry(const flutter::DlPath& path,
                            std::optional<Rect> inner_rect = std::nullopt);

 protected:
  const PathSource& GetSource() const override;

 private:
  const flutter::DlPath path_;
};

class FillRoundRectGeometry final : public FillPathSourceGeometry {
 public:
  explicit FillRoundRectGeometry(const RoundRect& round_rect);

 protected:
  const PathSource& GetSource() const override;

 private:
  const RoundRectPathSource round_rect_source_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_FILL_PATH_GEOMETRY_H_
