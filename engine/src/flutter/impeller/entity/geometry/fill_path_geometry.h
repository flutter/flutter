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

/// @brief An abstract Geometry base class that produces fillable vertices for
///        the interior of any |PathSource| provided by the type-specific
///        subclass.
class FillPathSourceGeometry : public Geometry {
 public:
  ~FillPathSourceGeometry() override;

  // |Geometry|
  bool CoversArea(const Matrix& transform, const Rect& rect) const override;

 protected:
  explicit FillPathSourceGeometry(std::optional<Rect> inner_rect);

  /// The PathSource object that will be iterated to produce the filled
  /// vertices.
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

/// @brief A Geometry that produces fillable vertices from a |DlPath| object
///        using the |FillPathSourceGeometry| base class and the inherent
///        ability for a |DlPath| object to perform path iteration.
class FillPathGeometry final : public FillPathSourceGeometry {
 public:
  explicit FillPathGeometry(const flutter::DlPath& path,
                            std::optional<Rect> inner_rect = std::nullopt);

 protected:
  const PathSource& GetSource() const override;

 private:
  const flutter::DlPath path_;
};

/// @brief A Geometry that produces fillable vertices for the gap between
///        a pair of |RoundRect| objects using the |FillPathSourceGeometry|
///        base class.
class FillDiffRoundRectGeometry final : public FillPathSourceGeometry {
 public:
  explicit FillDiffRoundRectGeometry(const RoundRect& outer,
                                     const RoundRect& inner);

 protected:
  const PathSource& GetSource() const override;

 private:
  const DiffRoundRectPathSource source_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_FILL_PATH_GEOMETRY_H_
